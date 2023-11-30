// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { ERC20Burnable, ERC20 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IGovStake } from "./interfaces/IGovStake.sol";
import { ClawGovernanceCoin } from "./ClawGovernanceCoin.sol";
import { CrabEngine } from "./CrabEngine.sol";

contract ClawGovernanceStaking is ERC20, ERC20Burnable, Ownable, IGovStake {
    error ClawStakingGovCoin__AmountMustBeMoreThanZero();
    error ClawStakingGovCoin__BurnAmountExceedsBalance();
    error ClawStakingGovCoin__NotZeroAddress();

    ClawGovernanceCoin private immutable i_clawGovernanceCoin;
    CrabEngine private immutable i_crabEngine;

    struct UserStake {
        uint256 stakeAmount;
        uint256 feesGeneratedAtStakingTime;
        uint256 accruedRewards;    // rewards accrued during staking period
    }

    // user -> staked amount
    mapping(address => UserStake) public stakes;

    // total staked amount
    uint256 public totalStakedAmount;

    constructor(address governanceCoinAddress, address crabEngineAddress) ERC20("Claw governance stake", "stCLAW") Ownable(msg.sender) {
        i_clawGovernanceCoin = ClawGovernanceCoin(governanceCoinAddress);
        i_crabEngine = CrabEngine(crabEngineAddress);
    }

    /**
     * @dev stake governance tokens for rewards
     *
     * @param amount the amount of governcance tokens a user wants to stake
     */
    function stake(uint256 amount) external {
        // Check if the amount is more than 0
        require(amount > 0, "Amount must be more than 0");
        
        uint256 fees = i_crabEngine.getGeneratedFees();
        // not first time staking
        if (stakes[msg.sender].stakeAmount != 0) {                    
            uint256 interest = fees - stakes[msg.sender].feesGeneratedAtStakingTime;
            stakes[msg.sender].accruedRewards += interest * stakes[msg.sender].stakeAmount / i_clawGovernanceCoin.balanceOf(address(this));
        }
        stakes[msg.sender].stakeAmount += amount;
        stakes[msg.sender].feesGeneratedAtStakingTime = fees;
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
        require(stakes[msg.sender].stakeAmount >= amount, "Not enough staked tokens");

        // get generated fees for the staking period
        uint256 fees = i_crabEngine.getGeneratedFees();
        uint256 interest = fees - stakes[msg.sender].feesGeneratedAtStakingTime;
        // precision?
        stakes[msg.sender].accruedRewards += interest * stakes[msg.sender].stakeAmount / i_clawGovernanceCoin.balanceOf(address(this));

        // Update the user's stake
        stakes[msg.sender].stakeAmount -= amount;
        stakes[msg.sender].feesGeneratedAtStakingTime = fees;      
        totalStakedAmount -= amount;

        i_clawGovernanceCoin.transferFrom(address(this), msg.sender, amount);
    }
    
    function claim() external {
        require(stakes[msg.sender].stakeAmount > 0 || stakes[msg.sender].accruedRewards > 0,
                "User has nothing to claim");

        // calculate final reward
        uint256 amountToClaim = stakes[msg.sender].accruedRewards;
        // set to 0 to prevent reentrency
        stakes[msg.sender].accruedRewards = 0;
        
        uint256 fees = i_crabEngine.getGeneratedFees();
        uint256 interest = fees - stakes[msg.sender].feesGeneratedAtStakingTime;
        amountToClaim += interest * stakes[msg.sender].stakeAmount / i_clawGovernanceCoin.balanceOf(address(this));        
        
        i_crabEngine.transferCrabToStaker(msg.sender, amountToClaim);
    }

    // private functions
    function getStake(address user) public view returns (uint256) {
        return stakes[user].stakeAmount;
    }

    function getTotalStakedAmount() public view returns (uint256) {
        return totalStakedAmount;
    }
}
