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
    error CrabEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
    error CrabEngine__NeedsMoreThanZero();
    error CrabEngine__TokenNotAllowed(address token);
    error CrabEngine__TransferFailed();
    error CrabEngine__BreaksHealthFactor(uint256 healthFactorValue);
    error CrabEngine__MintFailed();
    error CrabEngine__HealthFactorOk();
    error CrabEngine__HealthFactorNotImproved();

    ///////////////////
    // Types
    ///////////////////
    using OracleLib for AggregatorV3Interface;

    ///////////////////
    // State Variables
    ///////////////////
    CrabStableCoin private immutable crabStableCoin;

    uint256 private constant LIQUIDATION_THRESHOLD = 50; // This means you need to be 200% over-collateralized
    uint256 private constant LIQUIDATION_BONUS = 10; // This means you get assets at a 10% discount when liquidating
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant FEED_PRECISION = 1e8;

    /// @dev Mapping of token address to price feed address
    mapping(address collateralToken => address priceFeed) private s_priceFeeds;
    /// @dev Amount of collateral deposited by user
    mapping(address user => mapping(address collateralToken => uint256 amount)) private s_collateralDeposited;
    /// @dev Amount of crab minted by user
    mapping(address user => uint256 amount) private s_CrabMinted;
    /// @dev If we know exactly how many tokens we have, we could make this immutable!
    address[] private s_collateralTokens;

    ///////////////////
    // Events
    ///////////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);
    // if redeemFrom != redeemedTo, then it was liquidated
    event CollateralRedeemed(address indexed redeemFrom, address indexed redeemTo, address token, uint256 amount);

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

    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address crabAddress) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert CrabEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
        }
        // These feeds will be the USD pairs
        // For example ETH / USD or MKR / USD
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }
        crabStableCoin = CrabStableCoin(crabAddress);
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
    function depositCollateral(address collateralToken, uint256 amount) external {
        require(s_priceFeeds[collateralToken] != address(0), "Collateral token not allowed");
        require(amount > 0, "Amount must be more than zero");
        s_collateralDeposited[msg.sender][collateralToken] += amount;
        require(IERC20(collateralToken).transferFrom(msg.sender, address(this), amount), "Transfer failed");
        emit CollateralDeposited(msg.sender, collateralToken, amount);
    }

    /**
     * @dev Withdraw the specified collateral from the caller's position.
     *
     * @param collateralToken the token to withdraw from collateral.
     * @param amount the amount of collateral to withdraw.
     */
    function withdrawCollateral(address collateralToken, uint256 amount) external {
        require(s_priceFeeds[collateralToken] != address(0), "Collateral token not allowed");
        require(amount > 0, "Amount must be more than zero");
        require(s_collateralDeposited[msg.sender][collateralToken] >= amount, "Amount exceeds deposited collateral");
        s_collateralDeposited[msg.sender][collateralToken] -= amount;
        require(IERC20(collateralToken).transfer(msg.sender, amount), "Transfer failed");
        emit CollateralRedeemed(msg.sender, msg.sender, collateralToken, amount);
    }

    /**
     * @dev Borrow protocol stablecoins against the caller's collateral.
     *
     * @notice The caller is not allowed to exceed the ltv ratio for their basket of collateral.
     *
     * @param amount the amount to borrow.
     */
    function borrow(uint256 amount) external {
        require(amount > 0, "Amount must be more than zero");
        uint256 healthFactorValue = CrabEngine__MintFailed(msg.sender);
        require(healthFactorValue >= MIN_HEALTH_FACTOR, "Health factor too low");
        require(mintCrab(msg.sender, amount), "Mint failed");
    }

    /**
     * @dev Repay protocol stablecoins from the caller's debt.
     *
     * @param amount the amount to repay.
     */
    function repay(uint256 amount) external {
        require(amount > 0, "Amount must be more than zero");
        require(_burn(msg.sender, amount), "Burn failed");
    }

    ///////////////////
    // Public Functions
    ///////////////////

    /*
     * @param amountCrabToMint: The amount of Crab you want to mint
     * You can only mint Crab if you hav enough collateral
     */
    function mintCrab(uint256 amountCrabToMint) public moreThanZero(amountCrabToMint) nonReentrant {
        s_CrabMinted[msg.sender] += amountCrabToMint;
        // todo: check if health factor is broken
        //revertIfHealthFactorIsBroken(msg.sender);
        bool minted = crabStableCoin.mint(msg.sender, amountCrabToMint);

        if (minted != true) {
            revert CrabEngine__MintFailed();
        }
    }

    ///////////////////
    // Private Functions
    ///////////////////

    function _burnCrab(uint256 amountCrabToBurn, address onBehalfOf, address crabFrom) private {
        s_CrabMinted[onBehalfOf] -= amountCrabToBurn;

        bool success = crabStableCoin.transferFrom(crabFrom, address(this), amountCrabToBurn);
        // this check might be unnecessary
        if (!success) {
            revert CrabEngine__TransferFailed();
        }
        crabStableCoin.burn(amountCrabToBurn);
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    // External & Public View & Pure Functions
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    function getPrecision() external pure returns (uint256) {
        return PRECISION;
    }

    function getAdditionalFeedPrecision() external pure returns (uint256) {
        return ADDITIONAL_FEED_PRECISION;
    }

    function getLiquidationThreshold() external pure returns (uint256) {
        return LIQUIDATION_THRESHOLD;
    }

    function getLiquidationBonus() external pure returns (uint256) {
        return LIQUIDATION_BONUS;
    }

    function getLiquidationPrecision() external pure returns (uint256) {
        return LIQUIDATION_PRECISION;
    }

    function getMinHealthFactor() external pure returns (uint256) {
        return MIN_HEALTH_FACTOR;
    }

    function getCollateralTokens() external view returns (address[] memory) {
        return s_collateralTokens;
    }

    function getCrab() external view returns (address) {
        return address(crabStableCoin);
    }

    function getCollateralTokenPriceFeed(address token) external view returns (address) {
        return s_priceFeeds[token];
    }

    // todo maybe needed, not sure yet
    // function getHealthFactor(address user) external view returns (uint256) {
    //     return _healthFactor(user);
    // }
}
