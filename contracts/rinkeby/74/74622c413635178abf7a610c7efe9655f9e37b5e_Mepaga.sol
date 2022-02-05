/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Mepaga {

    event Deposit(address sender, uint amount, uint balance);
    event Transfer(address to, uint amount, uint balance);
    event Withdraw(uint amount, uint balance);

    address private _owner;
    uint256 public cost = 0.03 ether;

    constructor(){
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Sai");
        _;
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function Balance() public view returns(uint){
        return address(this).balance;
    }
    
      function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
    }
    
    function deposit() public payable {
        require(msg.value >= cost, "Mais Grana");
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

}