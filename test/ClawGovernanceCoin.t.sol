// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { Test, console } from "forge-std/Test.sol";
import { ClawGovernanceCoin } from "../src/ClawGovernanceCoin.sol";
import { ClawGovernanceStaking } from "../src/ClawGovernanceStaking.sol";
import { MockERC20 } from "./mocks/MockERC20.sol";
import "../src/CrabStableCoin.sol";
import {DeployCrab} from "../script/DeployCrab.s.sol";
import { HelperConfig } from "../script/HelperConfig.s.sol";
import "../src/CrabEngine.sol";


contract ClawGovernanceCoinTest is Test {
    DeployCrab crabDeployer;
    HelperConfig helperConfig;
    ClawGovernanceCoin claw;
    ClawGovernanceStaking stakedClaw;
    CrabStableCoin crabStableCoin;
    MockERC20 mockERC20;
    CrabEngine crabEngine;
    address wethUsdPriceFeed;
    address weth;
    address dummyToken = address(0x1); // Dummy token address for testing
    address user1;
    address user2;
    address user3;
    address deployer;

    function setUp() public virtual {
        
        //deploy crabenigne
        crabDeployer = new DeployCrab();
        (crabStableCoin, crabEngine, claw, stakedClaw, helperConfig) = crabDeployer.run();
        (wethUsdPriceFeed, weth, , , , , ) = helperConfig.activeNetworkConfig();
        // ---  

        user1 = address(1);
        user2 = address(2);
        user3 = address(3);
        user3 = address(4);
        deployer = address(4);

        // deploying contracts and minting for user
        vm.startBroadcast(deployer);
        mockERC20 = new MockERC20("MockERC20", "MOCK");
        // get the stakedcoin address
        claw = new ClawGovernanceCoin();
        claw.mint(user1, 12_000); // Mint 12000 stablecoins to user1
        claw.mint(user2, 5000); // Mint 5000 stablecoins to user2
        vm.stopBroadcast();
        
    }

    function _makeProposal(address user) internal returns (uint256) {
        vm.startBroadcast(user);
        uint256 proposalId = claw.propose(dummyToken, 70);
        vm.stopBroadcast();
        return proposalId;
    }

    // function testPropose() public {
    //     console.log("testPropose");
    //     uint256 totalStakedAmount = stakedClaw.totalStakedAmount();
    //     console.log("totalStakedAmount: %s", totalStakedAmount);
    //     uint256 proposalId = claw.propose(weth, 50);
    //     (bool executed, address proposer, uint256 ltv,,,) = claw.getProposal(proposalId);

    //     assertEq(executed, false, "Executed is not correct");
    //     assertEq(proposer, user1, "Proposer is not correct");
    //     assertEq(ltv, 70, "LTV is not correct");
    // }

    // function testVote() public {
    //     // create a new proposal
    //     uint256 proposalId = _makeProposal(user1);

    //     //  Vote on the proposal
    //     vm.startPrank(user2);
    //     claw.vote(proposalId);
    //     vm.stopPrank();

    //     (,,,, uint256 yesVotes,,) = claw.proposals(proposalId);
    //     assertEq(yesVotes, 17_000, "Vote was not recorded");
    // }

    // function testRevertDoubleVote() public {
    //     // create a new proposal
    //     uint256 proposalId = _makeProposal(user1);

    //     //  Vote on the proposal
    //     vm.startPrank(user2);
    //     claw.vote(proposalId);
    //     vm.stopPrank();

    //     (,,,, uint256 yesVotes,,) = claw.proposals(proposalId);
    //     assertEq(yesVotes, 17_000, "Vote was not recorded");

    //     // should revert if user votes again
    //     vm.startPrank(user2);
    //     vm.expectRevert("User has already voted on this proposal");
    //     claw.vote(proposalId);
    //     vm.stopPrank();
    // }

    // function testRevertNoTokenToVote() public {
    //     // create a new proposal
    //     uint256 proposalId = _makeProposal(user1);

    //     //  Vote on the proposal
    //     vm.startPrank(user3);
    //     vm.expectRevert("No governance tokens to vote with");
    //     claw.vote(proposalId);
    //     vm.stopPrank();
    // }

    function testBurn() public {
        claw = new ClawGovernanceCoin();
        address account = address(this);
        uint256 amountToMint = 1000;
        uint256 amountToBurn = 500;

        claw.mint(account, amountToMint);
        uint256 initialBalance = claw.balanceOf(account);

        claw.burn(amountToBurn);

        uint256 finalBalance = claw.balanceOf(account);
        assert(finalBalance == initialBalance - amountToBurn);
    }

    function testMint() public {
        claw = new ClawGovernanceCoin();
        address recipient = address(this);
        uint256 initialBalance = claw.balanceOf(recipient);
        uint256 amountToMint = 1000;

        claw.mint(recipient, amountToMint);

        uint256 finalBalance = claw.balanceOf(recipient);
        assert(finalBalance == initialBalance + amountToMint);
    }
}
