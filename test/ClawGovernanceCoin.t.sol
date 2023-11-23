// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { Test, console } from "forge-std/Test.sol";
import { ClawGovernanceCoin } from "../src/ClawGovernanceCoin.sol";
import { MockERC20 } from "./mocks/MockERC20.sol";

contract ClawGovernanceCoinTest is Test {
    ClawGovernanceCoin coin;
    MockERC20 mockERC20;
    address dummyToken = address(0x1); // Dummy token address for testing
    address user1;
    address user2;
    address user3;
    address deployer;

    function setUp() public virtual {
        user1 = address(1);
        user2 = address(2);
        user3 = address(3);
        user3 = address(4);
        deployer = address(4);

        // deploying contracts and minting for user
        vm.startBroadcast(deployer);
        mockERC20 = new MockERC20("MockERC20", "MOCK");
        coin = new ClawGovernanceCoin();
        coin.mint(user1, 12_000); // Mint 12000 tokens to user1
        coin.mint(user2, 5000); // Mint 5000 tokens to user2
        vm.stopBroadcast();
    }

    function _makeProposal(address user) internal returns (uint256) {
        vm.startBroadcast(user);
        uint256 proposalId = coin.propose(dummyToken, 70);
        vm.stopBroadcast();
        return proposalId;
    }

    function testPropose() public {
        uint256 initialProposalCount = coin.proposalCount();
        uint256 proposalId = _makeProposal(user1);
        uint256 finalProposalCount = coin.proposalCount();

        assertEq(finalProposalCount, initialProposalCount + 1, "Proposal count did not increase after propose");

        (address proposer, address token, uint256 ltv,,,) = coin.proposals(proposalId);

        assertEq(proposer, user1, "Proposer is not correct");
        assertEq(token, dummyToken, "Token is not correct");
        assertEq(ltv, 70, "LTV is not correct");
    }

    function testVote() public {
        // create a new proposal
        uint256 proposalId = _makeProposal(user1);

        //  Vote on the proposal
        vm.startPrank(user2);
        coin.vote(proposalId);
        vm.stopPrank();

        (,,, uint256 yesVotes,,) = coin.proposals(proposalId);
        assertEq(yesVotes, 17_000, "Vote was not recorded");
    }

    function testRevertDoubleVote() public {
        // create a new proposal
        uint256 proposalId = _makeProposal(user1);

        //  Vote on the proposal
        vm.startPrank(user2);
        coin.vote(proposalId);
        vm.stopPrank();

        (,,, uint256 yesVotes,,) = coin.proposals(proposalId);
        assertEq(yesVotes, 17_000, "Vote was not recorded");

        // should revert if user votes again
        vm.startPrank(user2);
        vm.expectRevert("User has already voted on this proposal");
        coin.vote(proposalId);
        vm.stopPrank();
    }

    function testRevertNoTokenToVote() public {
        // create a new proposal
        uint256 proposalId = _makeProposal(user1);

        //  Vote on the proposal
        vm.startPrank(user3);
        vm.expectRevert("No governance tokens to vote with");
        coin.vote(proposalId);
        vm.stopPrank();
    }

    function testBurn() public {
        coin = new ClawGovernanceCoin();
        address account = address(this);
        uint256 amountToMint = 1000;
        uint256 amountToBurn = 500;

        coin.mint(account, amountToMint);
        uint256 initialBalance = coin.balanceOf(account);

        coin.burn(amountToBurn);

        uint256 finalBalance = coin.balanceOf(account);
        assert(finalBalance == initialBalance - amountToBurn);
    }

    function testMint() public {
        coin = new ClawGovernanceCoin();
        address recipient = address(this);
        uint256 initialBalance = coin.balanceOf(recipient);
        uint256 amountToMint = 1000;

        coin.mint(recipient, amountToMint);

        uint256 finalBalance = coin.balanceOf(recipient);
        assert(finalBalance == initialBalance + amountToMint);
    }
}
