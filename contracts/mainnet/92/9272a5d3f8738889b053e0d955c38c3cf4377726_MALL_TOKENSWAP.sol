/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

pragma solidity >=0.8.0;
// SPDX-License-Identifier: BSD-3-Clause

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor()  {
    owner = msg.sender;
  }


  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public returns(bool){
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    return true;
  }
  
}

interface Library {
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function balanceOf(address) external returns (uint256);
}

contract MALL_TOKENSWAP is Ownable {
    
    event Bridged(address holder, uint amount, uint newAmount);
    
    /* @dev
    Contract addresses
    */
    address public constant deposit = 0x0C72C6fa50422aeA10B49e12Fe460103d0fa9c3e;
    address public constant withdraw = 0xE31Fe8478e8EFC5416B750cF7a452E613D8b20B6;
    
    /* @dev
    Enable / Disable the bridge
    */
    bool public enabled = true;
    
     /* @dev
        FUNCTIONS:
    */
    function changeState(bool _new) public onlyOwner returns(bool){
        enabled = _new;
        return true;
    }
    
    function swap(uint amount) public returns (bool){
        require(enabled , "Bridge is disabled");
        require(amount > 0, "Min 0");
        require(Library(deposit).transferFrom(msg.sender, address(this), amount), "Deposit err");
        require(Library(withdraw).transfer(msg.sender, amount), "Withdraw err");
        
        emit Bridged(msg.sender, amount, amount);
        return true;
    }
    
    function getDeposited() public onlyOwner returns(bool){
        uint amount = Library(deposit).balanceOf(address(this));
        require(Library(deposit).transfer(owner, amount), "Err1");
        return true;
    }

    function getUnused() public onlyOwner returns(bool){
        uint amount = Library(withdraw).balanceOf(address(this));
        require(Library(withdraw).transfer(owner, amount), "Err2");
        return true;
    }
}