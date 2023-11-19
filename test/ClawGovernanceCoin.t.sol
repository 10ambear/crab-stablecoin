// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { Test } from "forge-std/Test.sol";
import { ClawGovernanceCoin } from "../src/ClawGovernanceCoin.sol";
import { MockERC20 } from "./mocks/MockERC20.sol";

contract ClawGovernanceCoinTest is Test {
    ClawGovernanceCoin coin;
    MockERC20 mockERC20;
    address dummyToken = address(0x1); // Dummy token address for testing
    address user1;

    function setUp() public virtual {
        user1 = address(1);
        mockERC20 = new MockERC20("MockERC20", "MOCK");
        coin = new ClawGovernanceCoin();
        coin.mint(address(this), 10_000); // Mint 10000 tokens to this contract
    }

    function testPropose() public {
        uint256 initialProposalCount = coin.proposalCount();
        uint256 proposalId = coin.propose(dummyToken, 70);
        uint256 finalProposalCount = coin.proposalCount();

        assertEq(finalProposalCount, initialProposalCount + 1, "Proposal count did not increase after propose");

        (address proposer, address token, uint256 ltv,,, bool active,) = coin.proposals(proposalId);
        assertEq(proposer, address(this), "Proposer is not correct");
        assertEq(token, dummyToken, "Token is not correct");
        assertEq(ltv, 70, "LTV is not correct");
        assertTrue(active, "Proposal is not active");
    }

    // function testVote() public {

    // }

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
