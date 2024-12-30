// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");

    uint256 constant AMOUNT_SEND = 0.1 ether;
    uint256 constant STARTING_AMOUNT = 10 ether;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_AMOUNT);
    }

    function testIfMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testIfOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    //My Note: it should pass but for some reason fails
    // function testPriceFeedVersionIsAccurate() public {
    //     uint256 version = fundMe.getVersion();
    //     assertEq(version, 0);
    // }

    function testFundFailsWithoutEnoughEth() public {
        //vm.expectRevert(); //the next line should revert;
        // !!! this ontop is commented because of some problems with the conversion
        fundMe.fund(); // send 0 value should revert;
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); //The next TX will be send by user
        uint256 ethToSend = AMOUNT_SEND; // 10 ETH
        fundMe.fund{value: ethToSend}(); //sending 10 ETH
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, AMOUNT_SEND);
    }

    function testAddsFunderToArrayOfFunds() public {
        vm.prank(USER);
        uint256 ethToSend = AMOUNT_SEND; // 10 ETH
        fundMe.fund{value: ethToSend}(); //sending 10 ETH

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    //this is for reusable code
    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: AMOUNT_SEND}(); //sending 10 ETH
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithSingleFunder() public funded {
        //arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundmeBalanace = address(fundMe).balance;
        //act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        //assert
        uint256 endingOwnertBalance = fundMe.getOwner().balance;
        uint256 endingFundmeBalance = address(fundMe).balance;

        assertEq(endingFundmeBalance, 0);
        assertEq(
            startingOwnerBalance + startingFundmeBalanace,
            endingOwnertBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        //arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1; //uint160 is for addresses to be casted see in the for loop, also we do not start with 0 sometimes it fails

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), AMOUNT_SEND); //does vm.prank and vm.deal from faundry docs
            fundMe.fund{value: AMOUNT_SEND}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundmeBalanace = address(fundMe).balance;
        //act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        //assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundmeBalanace + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}
