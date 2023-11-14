// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract CrabToken is ERC20, Ownable {
    using SafeERC20 for IERC20;

    uint256 private totalDebt; 

    mapping(address => mapping(address => uint256)) public collateralBalances;
    mapping(address => uint256) public borrowedBalances;
    mapping(address => uint256) public collateralTokenAndRatio;
    

    // todo check ownable msg.sender implementation
    // todo oracle needs to check these prices
    constructor() ERC20("Crab token", "CRAB") Ownable(msg.sender) {
        collateralTokenAndRatio[0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2] = 70; // Wrapped Ether
        collateralTokenAndRatio[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = 80; // USDC
        collateralTokenAndRatio[0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9] = 50; // Solana
    }

    /**
     * @dev Deposit the specified collateral into the caller's position.
     * Only supported collateralToken's are allowed.
     *
     * @param collateralToken the token to supply as collateral.
     * @param amount the amount of collateralToken to provide.
     */
    function depositCollateral(address collateralToken, uint256 amount) external {
        
        // checks if the collateral token is supported
        uint256 ltvRatio = collateralTokenAndRatio[collateralToken];
        require(ltvRatio > 0, "Unsupported collateral token");

        uint256 totalCollateralValue = collateralBalances[msg.sender][collateralToken] + amount;
        uint256 borrowedAmount = borrowedBalances[msg.sender];
        // todo rounding errors and math
        require(totalCollateralValue >= borrowedAmount * ltvRatio / 100, "LTV ratio exceeded");

        collateralBalances[msg.sender][collateralToken] += amount;
        IERC20(collateralToken).transferFrom(msg.sender, address(this), amount);
    }

    /**
     * @dev Withdraw the specified collateral from the caller's position.
     *
     * @param collateralToken the token to withdraw from collateral.
     * @param amount the amount of collateral to withdraw.
     */
    function withdrawCollateral(address collateralToken, uint256 amount) external {
        require(collateralBalances[msg.sender][collateralToken] >= amount, "Insufficient collateral");

        uint256 ltvRatio = collateralTokenAndRatio[collateralToken];
        require(ltvRatio > 0, "Unsupported collateral token");

        uint256 totalCollateralValue = collateralBalances[msg.sender][collateralToken] - amount;
        uint256 borrowedAmount = borrowedBalances[msg.sender];
        require(totalCollateralValue >= borrowedAmount * ltvRatio / 100, "LTV ratio exceeded");

        collateralBalances[msg.sender][collateralToken] -= amount;
        IERC20(collateralToken).transfer(msg.sender, amount);
    }

    /**
     * @dev Borrow protocol stablecoins against the caller's collateral.
     *
     * @notice The caller is not allowed to exceed the ltv ratio for their basket of collateral.
     *
     * @param amount the amount to borrow.
     */
    function borrow(uint256 amount) external {
        totalDebt += amount;
        borrowedBalances[msg.sender] += amount;
        // todo Check that the caller's collateral is sufficient
        IERC20(address(this)).transfer(msg.sender, amount);
        
    }

    /**
     * @dev Repay protocol stablecoins from the caller's debt.
     *
     * @param amount the amount to repay.
     */
    function repay(uint256 amount) external {
        require(borrowedBalances[msg.sender] >= amount, "Insufficient debt");
        totalDebt -= amount;
        borrowedBalances[msg.sender] -= amount;
        IERC20(address(this)).transferFrom(msg.sender, address(this), amount);
    }
}
