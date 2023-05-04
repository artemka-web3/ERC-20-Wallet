// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Trading.sol";

// DAI SEPOLIA TOKEN = 0x82fb927676b53b6eE07904780c7be9b4B50dB80b
// LINK SEPOLIA TOKEN = 0xb227f007804c16546Bd054dfED2E7A1fD5437678
// DAI SEPOLIA HOLDER = 0xaC72905626c913a3225b233aFd3fAD382a7e5eFa

// ETH DAI ADDR = 0x6B175474E89094C44Da98b954EedeAC495271d0F
// ETH LINK ADDR = 0x514910771AF9Ca656af840dff83E8264EcF986CA
// ETH DAI HOLDER = 0x692fd9d0C2A00E66BF809fDc6DceA5107F5c9f86


contract TradingTest is Test {
    event DepositLINK(uint indexed linkAmount, uint indexed linkPrice);
    event WithdrawLINK(uint indexed linkSpent, uint indexed linkPrice);


    Trading public tradingContract;
    address public daiHolder = 0x692fd9d0C2A00E66BF809fDc6DceA5107F5c9f86;
    address constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    IERC20 private link = IERC20(LINK);
    IERC20 private dai = IERC20(DAI);

    function setUp() public {
        vm.prank(daiHolder);
        tradingContract = new Trading();
    }


    function testSingleHopSwapFromUser() public {
        vm.startPrank(daiHolder);
        console.log("DAI BEFORE: ", dai.balanceOf(daiHolder));
        console.log("LINK BEFORE: ", link.balanceOf(daiHolder));
        dai.approve(address(tradingContract), 2000);
        uint amountOut = tradingContract.singleHopSwapFromUser(DAI, LINK, 3000, 2000);
        console.log("DAI AFTER: ", dai.balanceOf(daiHolder));
        console.log("LINK AFTER: ", link.balanceOf(daiHolder));
        console.log("LINK amount from swap:", amountOut);
        vm.stopPrank();
    }
    function testDepositLINK() public {
        // DO THE SWAP START - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        vm.startPrank(daiHolder);
        dai.approve(address(tradingContract), 2000);
        uint linkAmountOut = tradingContract.singleHopSwapFromUser(DAI, LINK, 3000, 2000);
        // DO THE SWAP END - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        link.approve(address(tradingContract), linkAmountOut);

        vm.expectEmit(true, true, false, false);
        emit DepositLINK(linkAmountOut, uint(tradingContract.getLINKLatestPrice()));
        tradingContract.depositLINK(linkAmountOut);
        console.log("Contract LINK balance: ", link.balanceOf(address(tradingContract)));
    }
    function testWithdrawLINK() public {
        // DO THE SWAP START - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        vm.startPrank(daiHolder);
        dai.approve(address(tradingContract), 2000);
        uint linkAmountOut = tradingContract.singleHopSwapFromUser(DAI, LINK, 3000, 2000);
        // DO THE SWAP END - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        // DO THE DEPOSIT LINK START  - - - - -- - - -- - - - - - - - - - - - - - - - - 
        link.approve(address(tradingContract), linkAmountOut);
        tradingContract.depositLINK(linkAmountOut);
        // DO THE DEPOSIT LINK STOP  - - - - -- - - -- - - - - - - - - - - - - - - - - -
        vm.stopPrank();

        vm.startPrank(daiHolder);
        console.log("daiHolder DAI amount before withdrawal: ", dai.balanceOf(daiHolder));
        console.log("daiHolder LINK amount before withdrawal: ", link.balanceOf(daiHolder));
        vm.expectEmit(true, true, false, false);
        emit WithdrawLINK(linkAmountOut, uint(tradingContract.getLINKLatestPrice()));
        tradingContract.withdrawLINK(linkAmountOut);
        console.log("daiHolder DAI amount after withdrawal: ", dai.balanceOf(daiHolder));
        console.log("daiHolder LINK amount after withdrawal: ", link.balanceOf(daiHolder));
    }

}