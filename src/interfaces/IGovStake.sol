// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

interface IGovStake {
    /**
     * @dev Stake governance tokens and receive staked governance tokens.
     *
     * @param amount the amount of governance tokens to stake.
     */
    function stake(uint256 amount) external;

    /**
     * @dev Unstake staked governance tokens and receive governance tokens.
     *
     * @param amount the amount of staked governance tokens to unstake.
     */
    function unstake(uint256 amount) external;

    /**
     * @dev Claim pending rewards for staked governance tokens.
     */
    function claim() external;
}
