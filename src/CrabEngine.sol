// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { OracleLib, AggregatorV3Interface } from "./libraries/OracleLib.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { CrabStableCoin } from "./CrabStableCoin.sol";
import { ICDP } from "./interfaces/ICDP.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { console } from "forge-std/Test.sol";


import "forge-std/console.sol";

/*
 * @title CrabEngine
 * @author sheepGhosty & bLnk
 *
 * The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == $1 peg at all times.
 * This is a stablecoin with the properties:
  * - Dollar Pegged
 * - Algorithmically Stable
 *
 * @notice This contract is the core of the Crab Decentralized Stablecoin system. It handles all the logic
 * for minting and redeeming Crab, as well as depositing and withdrawing collateral.
 * @notice This contract is based on the MakerDAO DSS system
 */
contract CrabEngine is ReentrancyGuard, ICDP {
    ///////////////////
    // Errors
    ///////////////////
    error CrabEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
    error CrabEngine__NeedsMoreThanZero();
    error CrabEngine__TokenNotAllowed(address token);
    error CrabEngine__TransferFailed();
    error CrabEngine__MintFailed();

    ///////////////////
    // Types & interfaces
    ///////////////////
    using OracleLib for AggregatorV3Interface;
    using SafeERC20 for IERC20;

    /// the stablecoin interface
    CrabStableCoin private immutable i_crabStableCoin;

    /// @dev struct that holds collateral token metadata
    struct CollateralToken {
        address priceFeedAddress;
        uint8 decimals;
        uint8 ltvRatio;
    }

    /// @dev struct that holds borrow information for the user
    struct UserBorrows {
        uint256 lastPaidAt; // last time fees were accumulated
        uint256 borrowAmount; // total borrowed value without interest
        uint256 debt; // owed fees
        uint256 refreshedAt; // time at which fees were last calculated
    }

    ///////////////////
    // State Variables
    ///////////////////
    /// @dev Mapping of token address to collateral token struct
    mapping(address tokenAddress => CollateralToken) private s_collateralTokenData;

    /// @dev Mapping of token address to price feed address
    mapping(address collateralToken => address priceFeed) private s_priceFeeds;

    /// @dev Amount of collateral deposited by user
    mapping(address user => mapping(address collateralToken => uint256 amount)) public s_collateralDeposited;

    /// @dev collateral token address to ltv ratio allowed in percentage
    mapping(address => uint256) private s_collateralTokenAndRatio;

    // @dev mapping to hold user borrow info for each user
    mapping(address => UserBorrows) public s_userBorrows;

    /// @dev the types of collateral tokens crab supports
    /// we're expecting weth, usdc, and solana atm
    address[] private s_typesOfCollateralTokens;

    /// @dev the total debt of the protocol
    uint256 private s_protocolDebtInCrab;

    /// @dev fee variables
    uint256 private constant INTEREST_PER_SHARE_PER_SECOND = 3_170_979_198; // positionSize/10 = positionSize *
        // seconds_per_year * interestPerSharePerSec

    /// @dev vars related to precision during oracle use
    uint256 private constant PRECISION = 1e18;
    uint256 private constant EQUALIZER_PRECISION = 1e10;

    /// @dev liquidation reward constant 5%
    uint256 private constant LIQUIDATION_REWARD = 500;

    ///////////////////
    // Events
    ///////////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);
    /// @dev if redeemFrom != redeemedTo, then it was liquidated
    event CollateralRedeemed(address indexed redeemFrom, address indexed redeemTo, address token, uint256 amount);
    event CrabTokenBorrowed(address indexed to, uint256 indexed amount);
    event BorrowedAmountRepaid(address indexed from, uint256 indexed amount);

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
    constructor(
        address[] memory tokenAddresses,
        address[] memory priceFeedAddresses,
        uint8[] memory priceFeedDecimals,
        uint8[] memory tvlRatios,
        address crabAddress
    ) {
        if (
            tokenAddresses.length != priceFeedAddresses.length || tokenAddresses.length != tvlRatios.length
                || tokenAddresses.length != priceFeedDecimals.length
        ) {
            revert CrabEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
        }
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            address tokenAddress = tokenAddresses[i];
            address priceFeedAddress = priceFeedAddresses[i];
            uint8 priceFeedDecimal = priceFeedDecimals[i];
            uint8 tvlRatio = tvlRatios[i];

            s_collateralTokenData[tokenAddress] = CollateralToken(priceFeedAddress, priceFeedDecimal, tvlRatio);
            // todo keeping these for now need to come back and probably remove them
            s_collateralTokenAndRatio[tokenAddresses[i]] = tvlRatios[i];
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_typesOfCollateralTokens.push(tokenAddresses[i]);
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
        IERC20(collateralToken).safeTransferFrom(msg.sender, address(this), amount);
        emit CollateralDeposited(msg.sender, collateralToken, amount);
    }

    /**
     * @dev Withdraw the specified collateral from the caller's position.
     *
     * @param collateralTokenAddress the token to withdraw from collateral.
     * @param amount the amount of collateral to withdraw.
     */
    function withdrawCollateral(
        address collateralTokenAddress,
        uint256 amount
    )
        external
        moreThanZero(amount)
        isAllowedToken(collateralTokenAddress)
        nonReentrant
    {
        uint256 amountOfCrabBorrowed = getUserCrabBalance(msg.sender);
        if (amountOfCrabBorrowed > 0) {
            CollateralToken memory tokenData = s_collateralTokenData[collateralTokenAddress];
            // todo definitely precision errors
            uint256 remainingCollateralValueAfterWithdrawal = (
                s_collateralDeposited[msg.sender][collateralTokenAddress] - amount
            ) * getPriceInUSDForTokens(collateralTokenAddress, 1);
            uint256 collateralValueRequiredToKeepltv =
                (remainingCollateralValueAfterWithdrawal - amountOfCrabBorrowed) * tokenData.ltvRatio / 100;
            if (collateralValueRequiredToKeepltv > remainingCollateralValueAfterWithdrawal) {
                revert("Withdrawal would violate LTV ratio");
            }
        }
        s_collateralDeposited[msg.sender][collateralTokenAddress] -= amount;
        IERC20(collateralTokenAddress).safeTransfer(msg.sender, amount);
        emit CollateralRedeemed(msg.sender, msg.sender, collateralTokenAddress, amount);
    }

    /**
     * @dev Borrow protocol stablecoins against the caller's collateral.
     *
     * @notice The caller is not allowed to exceed the ltv ratio for their basket of collateral.
     *
     * @param amount the amount to borrow.
     */
    function borrow(uint256 amount) external moreThanZero(amount) nonReentrant {
        uint256 maxBorrow = getTotalBorrowableAmount();

        // first time borrowing
        if (s_userBorrows[msg.sender].borrowAmount == 0) {
            require(amount < maxBorrow, "Amount exceeds collateral borrow value");

            s_userBorrows[msg.sender].borrowAmount = amount;
            // set initial borrow date
            s_userBorrows[msg.sender].lastPaidAt = block.timestamp;
            s_protocolDebtInCrab += amount;

            bool minted = i_crabStableCoin.mint(msg.sender, amount);
            if (minted != true) {
                revert CrabEngine__MintFailed();
            }
            emit CrabTokenBorrowed(msg.sender, amount);
        } /* user borrowing for the 2nd (or more) time*/ else {
            require(
                amount + s_userBorrows[msg.sender].borrowAmount < maxBorrow, "Amount exceeds collateral borrow value"
            );

            _calculateFeeForPosition(msg.sender);
            s_userBorrows[msg.sender].borrowAmount += amount;
            s_userBorrows[msg.sender].lastPaidAt = block.timestamp;
            s_protocolDebtInCrab += amount;

            bool minted = i_crabStableCoin.mint(msg.sender, amount);
            if (minted != true) {
                revert CrabEngine__MintFailed();
            }
            emit CrabTokenBorrowed(msg.sender, amount);
        }
    }

    /**
     * @dev Repay protocol stablecoins from the caller's debt.
     *
     * @param amount the amount to repay.
     */
    function repay(uint256 amount) external moreThanZero(amount) nonReentrant {
        uint256 secondsSince = block.timestamp - s_userBorrows[msg.sender].refreshedAt;
        require(secondsSince <= OracleLib.TIMEOUT, "Stale fee. Refresh fee by calling getUserOwedAmount first.");

        uint256 amountOfCrabBorrowed = s_userBorrows[msg.sender].borrowAmount;
        uint256 owedFees = s_userBorrows[msg.sender].debt;

        // checks if the user has enough borrowed amount
        if (amountOfCrabBorrowed + owedFees < amount) {
            revert("Insufficient borrowed amount");
        }

        if (amountOfCrabBorrowed + owedFees != amount) {
            revert("User must payback the EXACT amount owed.");
        }

        // update borrowed balance and reset user
        s_protocolDebtInCrab -= amountOfCrabBorrowed;
        delete s_userBorrows[msg.sender];

        // transfers the crab to the engine
        bool success = i_crabStableCoin.transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert CrabEngine__TransferFailed();
        }
        // burn crabTokens
        i_crabStableCoin.burn(amount);

        emit BorrowedAmountRepaid(msg.sender, amount);
    }

    ///////////////////
    // Public Functions
    ///////////////////

    //@todo add onlyOwner
    function addCoinAndFeed(address coin, address feed, uint8 ltv, uint8 decimals) public {
        s_collateralTokenData[coin] = CollateralToken(feed, ltv, decimals);
    }

    /**
     * @dev Gets the total borrowable amount for the caller.
     *
     */
    function getTotalBorrowableAmount() public view returns (uint256 amount) {
        for (uint256 i = 0; i < s_typesOfCollateralTokens.length; i++) {
            address token = s_typesOfCollateralTokens[i];
            uint256 tokenAmount = s_collateralDeposited[msg.sender][token];
            uint256 fullPrice = getPriceInUSDForTokens(token, tokenAmount);

            amount += fullPrice / s_collateralTokenAndRatio[token];
        }
    }

    /**
     * @dev Gets user's owed amount.
     *
     */
    function getUserOwedAmount() public returns (uint256) {
        return s_userBorrows[msg.sender].borrowAmount + _calculateFeeForPosition(msg.sender);
    }

    /**
     * @dev gets the usd price for the tokens the protocol
     *
     * @param token the supported token
     * @param tokenAmount the amount of tokens
     */
    function getPriceInUSDForTokens(address token, uint256 tokenAmount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_collateralTokenData[token].priceFeedAddress);
        (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();
        //TEST IDEA fuzz this line here
        return ((uint256(price) * EQUALIZER_PRECISION) * tokenAmount) / PRECISION;
    }

    ///////////////////
    // Private Functions
    ///////////////////

    /**
     * @dev Calculates the fee for the user's position. Also sets refreshedAt for the user and add fee to their debt.
     *
     * @param user the user address to calculate the fee for.
     */
    function _calculateFeeForPosition(address user) private returns (uint256 totalFee) {
        require(s_userBorrows[user].borrowAmount != 0, "User is yet to borrow anything.");
        s_userBorrows[user].refreshedAt = block.timestamp;
        totalFee = s_userBorrows[user].borrowAmount * (block.timestamp - s_userBorrows[user].lastPaidAt)
            * INTEREST_PER_SHARE_PER_SECOND;
        s_userBorrows[user].debt += totalFee;
    }

    /**
     * @dev gets the current crab balance of the user
     *
     * @param user address of the users
     */
    function getUserCrabBalance(address user) public view returns (uint256) {
        return s_userBorrows[user].borrowAmount;
    }
}
