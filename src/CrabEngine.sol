// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { OracleLib, AggregatorV3Interface } from "./libraries/OracleLib.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { CrabStableCoin } from "./CrabStableCoin.sol";
import { ICrabEngine } from "./interfaces/ICrabEngine.sol";

/*
 * @title CrabEngine
 * @author sheepGhosty & bLnk
 *
 * The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == $1 peg at all times.
 * This is a stablecoin with the properties:
 * - Exogenously Collateralized
 * - Dollar Pegged
 * - Algorithmically Stable
 *
 * @notice This contract is the core of the Crab Decentralized Stablecoin system. It handles all the logic
 * for minting and redeeming Crab, as well as depositing and withdrawing collateral.
 * @notice This contract is based on the MakerDAO DSS system
 */
contract CrabEngine is ReentrancyGuard, ICrabEngine {
    ///////////////////
    // Errors
    ///////////////////
    // todo make sure we delete the ones we don't use
    error CrabEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
    error CrabEngine__NeedsMoreThanZero();
    error CrabEngine__TokenNotAllowed(address token);
    error CrabEngine__TransferFailed();
    error CrabEngine__BreaksHealthFactor(uint256 healthFactorValue);
    error CrabEngine__MintFailed();

    ///////////////////
    // Types
    ///////////////////
    using OracleLib for AggregatorV3Interface;

    ///////////////////
    // State Variables
    ///////////////////
    CrabStableCoin private immutable i_crabStableCoin;

    // todo make sure we delete the ones we don't use
    /// @dev Mapping of token address to price feed address
    mapping(address collateralToken => address priceFeed) private s_priceFeeds;

    /// @dev Amount of collateral deposited by user
    mapping(address user => mapping(address collateralToken => uint256 amount)) private s_collateralDeposited;

    /// @dev users crab balance
    mapping(address user => uint256 amount) private s_userCrabBalance;

    /// @dev collateral token address to ltv ratio allowed in percentage
    mapping(address => uint256) private s_collateralTokenAndRatio;

    /// @dev amount borrowed by user
    mapping(address => uint256) private s_borrowedBalances;

    /// @dev If we know exactly how many tokens we have, we could make this immutable!
    address[] private s_collateralTokens;

    /// @dev the total debt of the protocol
    uint256 private s_totalDebt;

    uint256 private constant PRECISION = 1e18;
    uint256 private constant EQUALIZER_PRECISION = 1e10;

    ///////////////////
    // Events
    ///////////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);
    // if redeemFrom != redeemedTo, then it was liquidated
    event CollateralRedeemed(address indexed redeemFrom, address indexed redeemTo, address token, uint256 amount);
    event CrabTokenBorrowed(address indexed to, uint256 indexed amount);
    ///////////////////
    // Modifiers
    ///////////////////

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert CrabEngine__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert CrabEngine__TokenNotAllowed(token);
        }
        _;
    }

    ///////////////////
    // constructor
    ///////////////////

    //0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2] = 70; // Wrapped Ether
    //0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = 80; // USDC
    //0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9] = 50; // Solana
    constructor(
        address[] memory tokenAddresses,
        address[] memory priceFeedAddresses,
        uint256[] memory tvlRatios,
        address crabAddress
    ) {
        if (tokenAddresses.length != priceFeedAddresses.length && tokenAddresses.length != tvlRatios.length) {
            revert CrabEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
        }
        // These feeds will be the USD pairs
        // For example ETH / USD or MKR / USD
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_collateralTokenAndRatio[tokenAddresses[i]] = tvlRatios[i];
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }
        i_crabStableCoin = CrabStableCoin(crabAddress);
    }

    ///////////////////
    // External Functions
    ///////////////////

    /**
     * @dev Deposit the specified collateral into the caller's position.
     * Only supported collateralToken's are allowed.
     *
     * @param collateralToken the token to supply as collateral.
     * @param amount the amount of collateralToken to provide.
     */
    function depositCollateral(
        address collateralToken,
        uint256 amount
    )
        external
        moreThanZero(amount)
        isAllowedToken(collateralToken)
        nonReentrant
    {
        // update user collateral
        s_collateralDeposited[msg.sender][collateralToken] += amount;

        // transfer collateral from user to this contract
        bool success = IERC20(collateralToken).transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert CrabEngine__TransferFailed();
        }
        emit CollateralDeposited(msg.sender, collateralToken, amount);
    }

    /**
     * @dev Withdraw the specified collateral from the caller's position.
     *
     * @param collateralToken the token to withdraw from collateral.
     * @param amount the amount of collateral to withdraw.
     */
    function withdrawCollateral(
        address collateralToken,
        uint256 amount
    )
        external
        moreThanZero(amount)
        isAllowedToken(collateralToken)
        nonReentrant
    {
        // get the amount borrowed by the user
        uint256 borrowedAmount = s_borrowedBalances[msg.sender];

        // if the user borrowed funds
        // if the user borrowed funds
        if (borrowedAmount > 0) {
            // calculate the total value of the collateral that the user is withdrawing
            uint256 withdrawalValue =  _getPriceInUSDForTokens(collateralToken, amount);

            // calculate the remaining value of the collateral that the user has deposited
            uint256 remainingValue = s_collateralDeposited[msg.sender][collateralToken]
                * _getPriceInUSDForTokens(collateralToken, amount) - withdrawalValue;

            // calculate the new value of the loan that the user has outstanding
            uint256 newLoanValue = remainingValue * s_collateralTokenAndRatio[collateralToken] / 100;

            // check if the new value of the loan is less than the amount that the user has borrowed
            if (newLoanValue > borrowedAmount) {
                revert("Withdrawal would violate LTV ratio");
            }
        }

        // update user collateral
        s_collateralDeposited[msg.sender][collateralToken] -= amount;

        // transfer collateral from this contract to user
        bool success = IERC20(collateralToken).transfer(msg.sender, amount);
        if (!success) {
            revert CrabEngine__TransferFailed();
        }
        emit CollateralRedeemed(msg.sender, msg.sender, collateralToken, amount);
    }

    /**
     * @dev Borrow protocol stablecoins against the caller's collateral.
     *
     * @notice The caller is not allowed to exceed the ltv ratio for their basket of collateral.
     *
     * @param amount the amount to borrow.
     */
    function borrow(uint256 amount) external moreThanZero(amount) nonReentrant {
        // get the amount borrowed by the user
        uint256 borrowedAmount = s_borrowedBalances[msg.sender];

        // get the max amount a user can borrow
        uint256 maxBorrow = getTotalBorrowableAmount();
        require(amount < maxBorrow - borrowedAmount, "Amount exceeds collateral borrow value");

        // update borrowed balance and total debt
        s_borrowedBalances[msg.sender] += amount;
        s_totalDebt += amount;
        // mint crabTokens
        _mintCrab(amount);

        emit CrabTokenBorrowed(msg.sender, amount);
    }

    /**
     * @dev Repay protocol stablecoins from the caller's debt.
     *
     * @param amount the amount to repay.
     */
    function repay(uint256 amount) external moreThanZero(amount) nonReentrant {
        // get the amount borrowed by the user
        uint256 borrowedAmount = s_borrowedBalances[msg.sender];

        // checks if the user has enough borrowed amount
        if (borrowedAmount <= amount) {
            revert("Insufficient borrowed amount");
        }

        // update borrowed balance and total debt
        s_borrowedBalances[msg.sender] -= amount;
        s_totalDebt -= amount;

        // burn crabTokens
        _burnCrab(amount, msg.sender, msg.sender);

        // transfer crab from user to this contract
        bool success = i_crabStableCoin.transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert CrabEngine__TransferFailed();
        }

        // todo event
    }

    ///////////////////
    // Public Functions
    ///////////////////

    function getTotalBorrowableAmount() public view returns (uint256 amount) {
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 tokenAmount = s_collateralDeposited[msg.sender][token];
            uint256 fullPrice = _getPriceInUSDForTokens(token, tokenAmount);
            // TODO: Problems that can arise from precision?
            amount += fullPrice / s_collateralTokenAndRatio[token];
        }
    }

    ///////////////////
    // Private Functions
    ///////////////////

    // todo this  be a private function and should automatically mint as per the interface and mission 1 specs
    // leaving it for now though, can worry about it later
    /*
     * @param amountCrabToMint: The amount of Crab you want to mint
     * You can only mint Crab if you hav enough collateral
     */
    function _mintCrab(uint256 amountCrabToMint) private moreThanZero(amountCrabToMint) nonReentrant {
        s_userCrabBalance[msg.sender] += amountCrabToMint;
        bool minted = i_crabStableCoin.mint(msg.sender, amountCrabToMint);
        if (minted != true) {
            revert CrabEngine__MintFailed();
        }
    }

    function _burnCrab(uint256 amountCrabToBurn, address onBehalfOf, address crabFrom) private {
        s_userCrabBalance[onBehalfOf] -= amountCrabToBurn;

        bool success = i_crabStableCoin.transferFrom(crabFrom, address(this), amountCrabToBurn);
        // this check might be unnecessary
        if (!success) {
            revert CrabEngine__TransferFailed();
        }
        i_crabStableCoin.burn(amountCrabToBurn);
    }

    function _getPriceInUSDForTokens(address token, uint256 tokenAmount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();
        //TEST IDEA fuzz this line here
        return ((uint256(price) * EQUALIZER_PRECISION) * tokenAmount) / PRECISION;
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    // External & Public View & Pure Functions
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    function getCrabTokenForUser(address user) external view returns (uint256) {
        return s_userCrabBalance[user];
    }
}
