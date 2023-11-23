// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { ERC20Burnable, ERC20 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IClawGovernanceCoin } from "./interfaces/IClawGovernanceCoin.sol";

contract ClawGovernanceCoin is ERC20, ERC20Burnable, Ownable, IClawGovernanceCoin {
    error ClawGovCoin__AmountMustBeMoreThanZero();
    error ClawGovCoin__BurnAmountExceedsBalance();
    error ClawGovCoin__NotZeroAddress();

    // Define a struct for the proposal
    struct Proposal {
        address proposer;
        address token;
        uint256 ltv;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 endTime;
    }

    // Define a mapping to store the proposals
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    // Define a mapping to track if an address has already voted for a proposal
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // Define a mapping to track the last address an address voted from
    mapping(address => address) public lastVotedFrom;

    constructor() ERC20("Claw governance", "CLAW") Ownable(msg.sender) { }

    function propose(address token, uint256 ltv) external returns (uint256 proposalId) {
        uint256 totalTokenBalanceForSender = balanceOf(msg.sender);
        uint256 onePercentTotalSupplyOfToken = totalSupply() / 100;

        // Check if the user has at least 1% of the total supply
        require(totalTokenBalanceForSender > onePercentTotalSupplyOfToken, "Must hold more than 1% of the totalSupply");

        proposalId = proposalCount++;
        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            token: token,
            ltv: ltv,
            yesVotes: 0,
            noVotes: 0,
            endTime: block.timestamp + 5 days
        });

        // Automatically vote for the proposal with the entire balance
        vote(proposalId);
    }

    function vote(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];

        // Check if the proposal has ended
        require(block.timestamp < proposal.endTime, "Proposal has ended");

        // using balanceof to check the user's complete balance
        uint256 voterBalance = balanceOf(msg.sender);
        require(voterBalance > 0, "No governance tokens to vote with");

        // Check if the user has already voted on this proposal
        require(!hasVoted[proposalId][msg.sender], "User has already voted on this proposal");

        // Record the user's vote and update the proposal's yes votes without actually transferring tokens
        proposal.yesVotes += voterBalance;
        hasVoted[proposalId][msg.sender] = true;
    }

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert ClawGovCoin__AmountMustBeMoreThanZero();
        }
        if (balance < _amount) {
            revert ClawGovCoin__BurnAmountExceedsBalance();
        }
        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert ClawGovCoin__NotZeroAddress();
        }
        if (_amount <= 0) {
            revert ClawGovCoin__AmountMustBeMoreThanZero();
        }
        _mint(_to, _amount);
        return true;
    }

    function getProposal(uint256 proposalId)
        public
        view
        returns (address proposer, uint256 ltv, uint256 yesVotes, uint256 noVotes, uint256 endTime)
    {
        Proposal memory proposal = proposals[proposalId];
        return (proposal.proposer, proposal.ltv, proposal.yesVotes, proposal.noVotes, proposal.endTime);
    }
}
