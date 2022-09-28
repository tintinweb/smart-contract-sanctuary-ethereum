/**
 *Submitted for verification at Etherscan.io on 2022-09-28
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

contract SmartMoney {
    uint public moneyReceived;

    receive() external payable {
        moneyReceived += msg.value;
    }

    fallback() external payable {
        moneyReceived += msg.value;
    }

    function viewContractBalance() public view returns(uint){
        return address(this).balance;
    }

    function deposit() payable public {
        moneyReceived += msg.value;
    }

    function withdrawAll() public {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawToAddr(address addr) public {
        payable(addr).transfer(address(this).balance);
    }

}