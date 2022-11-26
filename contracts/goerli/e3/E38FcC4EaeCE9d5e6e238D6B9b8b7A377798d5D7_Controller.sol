/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

pragma solidity ^0.8.17;
//SPDX-License-Identifier: MIT

interface Swap {
    function buyToken(address token, uint amountWei, uint slippage) external;
    function sellToken(address token, uint fraction, uint slippage) external;
    function withdrawAllETH() external;
    function withdrawToken(address token) external;
}

contract Controller {

    Swap private constant boss = Swap(0x29052D68eFe762AE1a6611010028c1B9f5E71FD9);
    address private me;

    constructor() {
        me = msg.sender;
    }

    modifier onlyMe() {
        require(msg.sender == me, "No access sir!"); _;
    }

    function changeMe(address newMe) public onlyMe() {
        me = newMe;
    }
    
    function buy(address token, uint amountWei, uint slippage) public onlyMe() {
        boss.buyToken(token, amountWei, slippage);
    }

    function sell(address token, uint fraction, uint slippage) public onlyMe() {
        boss.sellToken(token, fraction, slippage);
    }

    function withdrawAllETH() public onlyMe() {
        boss.withdrawAllETH();
    }

    function withdrawToken(address token) public onlyMe() {
        boss.withdrawToken(token);
    }

}