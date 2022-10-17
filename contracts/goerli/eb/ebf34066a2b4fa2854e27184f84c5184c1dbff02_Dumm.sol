/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

pragma solidity ^0.8.0;

contract Dumm {
    
    mapping(address => uint) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint currentBalance = balances[msg.sender];
        (bool result,) = msg.sender.call{value:currentBalance}("");
        require(result, "ERROR");
         balances[msg.sender]=0;
    }
    
    function checkBalance() external view returns(uint) {
        return address(this).balance;
    }
    
}