/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
 
contract EtherStore {

    uint256 public withdrawalLimit = 1 ether;
    mapping(address => uint256) public lastWithdrawTime;
    mapping(address => uint256) public balances;

    function depositFunds() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdrawFunds (uint256 _weiToWithdraw) public returns (bool success) {
        require(balances[msg.sender] >= _weiToWithdraw);
        ( success, ) = msg.sender.call{value: _weiToWithdraw}("");
        balances[msg.sender] = balances[msg.sender] - _weiToWithdraw;
        return success;
    }
    
    function getBalance_1 () public returns (uint256){
      return address(this).balance;
    }
}