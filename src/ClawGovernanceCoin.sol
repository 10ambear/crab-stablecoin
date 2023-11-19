// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

// Import OpenZeppelin's ERC20Votes contract
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ClawGovernanceCoin is ERC20 {

  // Define a struct for the proposal
  struct Proposal {
      address proposer;
      uint256 ltv;
      uint256 yesVotes;
      uint256 noVotes;
      bool active;
      uint256 endTime;
  }

  constructor() ERC20("Claw governance", "CLAW") { }

  // Define a mapping to store the proposals
  mapping(uint256 => Proposal) public proposals;
  uint256 public proposalCount;

  // Define a mapping to track if an address has already voted for a proposal
  mapping(uint256 => mapping(address => bool)) public hasVoted;

  // Define a mapping to track the last address an address voted from
  mapping(address => address) public lastVotedFrom;

  // Implement the propose function
  function propose(uint256 ltv) external {
      require(balanceOf(msg.sender) > totalSupply() / 100, "Must hold more than 1% of the totalSupply");

      uint256 proposalId = proposalCount++;
      proposals[proposalId] = Proposal({
          proposer: msg.sender,
          ltv: ltv,
          yesVotes: 0,
          noVotes: 0,
          active: true,
          endTime: block.timestamp + 5 days
      });

      // Automatically vote for the proposal with the entire balance
      vote(proposalId);
  }

  // Implement the vote function
  function vote(uint256 proposalId) public {
      Proposal storage proposal = proposals[proposalId];
      require(proposal.active, "Proposal must be active");
      require(block.timestamp < proposal.endTime, "Proposal voting period has ended");

      // Check if the voter has already voted for the proposal
      require(!hasVoted[proposalId][msg.sender], "Address already voted for this proposal");

      // Check if the voter has transferred their tokens since they last voted
      require(lastVotedFrom[msg.sender] == msg.sender, "Address has transferred tokens since they last voted");

      // Define the condition for a yes vote
      bool isYesVote = balanceOf(msg.sender) > totalSupply() / 2;

      // Increase the vote count
      if (isYesVote) {
          proposal.yesVotes += balanceOf(msg.sender);
      } else {
          proposal.noVotes += balanceOf(msg.sender);
      }

      // Mark the address as having voted for the proposal
      hasVoted[proposalId][msg.sender] = true;
  }
}
