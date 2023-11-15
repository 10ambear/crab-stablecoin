// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { ERC20Burnable, ERC20 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/*
 * @title CrabStableCoin
 * @author Sheepghosty & bLnk
 * Collateral: Exogenous
 * Minting (Stability Mechanism): Decentralized (Algorithmic)
 * Value (Relative Stability): Anchored (Pegged to USD)
 * Collateral Type: Crypto
 *
 * This is the contract meant to be owned by CrabEngine. It is a ERC20 token that can 
 * be minted and burned by the CrabEngine smart contract.
 */
contract CrabStableCoin is ERC20Burnable, Ownable {
    error CrabStableCoin__AmountMustBeMoreThanZero();
    error CrabStableCoin__BurnAmountExceedsBalance();
    error CrabStableCoin__NotZeroAddress();

    constructor() ERC20("Crab stable coin", "CRAB") Ownable(msg.sender) { }

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert CrabStableCoin__AmountMustBeMoreThanZero();
        }
        if (balance < _amount) {
            revert CrabStableCoin__BurnAmountExceedsBalance();
        }
        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert CrabStableCoin__NotZeroAddress();
        }
        if (_amount <= 0) {
            revert CrabStableCoin__AmountMustBeMoreThanZero();
        }
        _mint(_to, _amount);
        return true;
    }
}
