// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;


interface IClawGovernanceCoin {

    /**
     * @dev Create a proposal for an ltv ratio for a supported collateral token.
     * Requires that the proposer holds > 1% of the totalSupply of the governance token.
     *
     * @notice proposer automatically votes for the proposal with their entire balance.
     *
     * @param token the supported collateral token for which to propose a ltv ratio for.
     * @param ltv the proposed ltv ratio.
     * @return proposalId the id of the proposal.
     */
    function propose(address token, uint256 ltv) external returns (uint256 proposalId);

    /**
     * @dev Vote for a proposal with the governance token balance of the caller.
     * Requires that the proposal corresponding to the proposalId is currently active.
     *
     * @param proposalId the id corresponding to the proposal to vote for.
     */
    function vote(uint256 proposalId) external;

}