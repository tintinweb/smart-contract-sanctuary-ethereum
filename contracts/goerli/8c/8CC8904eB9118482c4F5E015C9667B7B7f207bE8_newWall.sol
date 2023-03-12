/**
 *Submitted for verification at Etherscan.io on 2023-03-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

contract newWall {
    mapping(address=>uint)public balanceLadger;

    function sendMoney() public payable{
        balanceLadger[msg.sender] = msg.value;
    }

    function getBalance()public view returns(uint){
        return address(this).balance;  
    }

    function withdrowBal(address payable to) public{
        to.transfer(balanceLadger[to]);
        balanceLadger[to]=0;
    }
}