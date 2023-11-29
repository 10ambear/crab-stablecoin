// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { ERC20Burnable, ERC20 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IGovStake } from "./interfaces/IGovStake.sol";
import { ClawGovernanceCoin } from "./ClawGovernanceCoin.sol";

contract ClawGovernanceStaking is ERC20, ERC20Burnable, Ownable, IGovStake {
    error ClawStakingGovCoin__AmountMustBeMoreThanZero();
    error ClawStakingGovCoin__BurnAmountExceedsBalance();
    error ClawStakingGovCoin__NotZeroAddress();

    ClawGovernanceCoin private immutable i_clawGovernanceCoin;

    // user -> staked amount
    mapping(address => uint256) public stakes;

    // total staked amount
    uint256 public totalStakedAmount;

    constructor(address governanceCoinAddress) ERC20("Claw governance stake", "stCLAW") Ownable(msg.sender) {
        i_clawGovernanceCoin = ClawGovernanceCoin(governanceCoinAddress);
    }

    /**
     * @dev stake governance tokens for rewards
     *
     * @param amount the amount of governcance tokens a user wants to stake
     */
    function stake(uint256 amount) external {
        // Check if the amount is more than 0
        require(amount > 0, "Amount must be more than 0");
        // Update the user's stake, the tokens never actually leave the contract
        // as per the spec "when they are staked the tokens are transferred into
        // the Staker contract and held for the user"
        stakes[msg.sender] += amount;
        totalStakedAmount += amount;

        // Transfer ClawGovernanceCoin tokens from the user to this contract
        i_clawGovernanceCoin.transferFrom(msg.sender, address(this), amount);
    }

    /**
     * @dev unstake your governance tokens
     *
     * @param amount the amount of governcance tokens a user wants to stake
     */
    function unstake(uint256 amount) external {
        // Check if the amount is more than 0
        require(amount > 0, "Amount must be more than 0");

        // Check if the user has enough staked tokens
        require(stakes[msg.sender] >= amount, "Not enough staked tokens");

        // Update the user's stake
        stakes[msg.sender] -= amount;
        totalStakedAmount -= amount;

        // transfer ClawGovernanceCoin tokens to the user
        i_clawGovernanceCoin.transferFrom(address(this), msg.sender, amount);
    }

    function claim() external {
        uint256 userStakingRewards;
        // todo no idea how i'd do this
        uint256 protoclAccumulatedInterestFeesDuringStakePeriond;
        uint256 userStakedAmount = stakes[msg.sender];
        uint256 _totalStakedAmount = totalStakedAmount;

        userStakingRewards = protoclAccumulatedInterestFeesDuringStakePeriond * userStakedAmount / _totalStakedAmount;

        // todo transfer stablecoins lel this contract has no stable coins?
    }

    // private functions
    function getStake(address user) public view returns (uint256) {
        return stakes[user];
    }

    function getTotalStakedAmount() public view returns (uint256) {
        return totalStakedAmount;
    }
}
