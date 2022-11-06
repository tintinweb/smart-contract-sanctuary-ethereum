/**
 *Submitted for verification at Etherscan.io on 2022-11-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
// import "hardhat/console.sol";

contract Payable {
    address payable public owner;
    constructor() payable {
        owner = payable(msg.sender);
    }

    event log(uint length);

    function deposit() public payable {}

    function notPayable() public {}

    function withdraw() public {
        uint amount = address(this).balance;
        owner.transfer(amount);
    }

    function transferArr(address[] memory _tos, uint _amount) public {
        // uint[] memory array8 = new uint[](5);
        // console.log("length",_tos[0]);
        for(uint i=0;i<_tos.length;i++){
            payable(_tos[i]).transfer(_amount); 
            //["0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB","0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db","0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678","0x17F6AD8Ef982297579C203069C1DbfFE4348c372","0x617F2E2fD72FD9D5503197092aC168c91465E7f2","0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2","0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB","0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db","0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678","0x17F6AD8Ef982297579C203069C1DbfFE4348c372","0x617F2E2fD72FD9D5503197092aC168c91465E7f2","0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2"]
            //["0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB","0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db","0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678","0x17F6AD8Ef982297579C203069C1DbfFE4348c372","0x617F2E2fD72FD9D5503197092aC168c91465E7f2","0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2",]
        }
        emit log(_tos.length);
    }
    function transferOne(address payable _to , uint _amount) public {
        _to.transfer(_amount);
        emit log(1);
    }

    function getBalance(address a1) public payable returns(uint){
        return address(a1).balance;
    }
}