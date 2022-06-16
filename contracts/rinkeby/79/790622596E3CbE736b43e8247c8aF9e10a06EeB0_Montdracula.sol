/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// SPDX-License-Identifier: GPL-3.0

// File: contracts/Contdracula.sol



pragma solidity ^0.8.0;


contract  Contdracula{

    uint256 stored_money;
    address public owner;

    constructor(address _owner)  {
      stored_money = 0;   
      owner= _owner;
   }

    function deposit(uint256 value) public payable{
        require(value == 10**16, "The price received is invalid");
        stored_money = stored_money+value;
    }

    function retrieve() public{
        payable(owner).transfer(stored_money);
    }
}
// File: contracts/Montdracula.sol



pragma solidity ^0.8.0;


contract  Montdracula{

    uint256 public storedmoney;
    address owner;
    event ContDraculaCreated(address _monttx, uint256 _amount);

    constructor()  {
      storedmoney = 0;   
      owner= msg.sender;
   }

    function create() public payable returns(bool){
        Contdracula da = new Contdracula(msg.sender);
        da.deposit(msg.value);
        emit ContDraculaCreated(address(da), msg.value);
        return true;
    }

    function retrieve() public payable{
        payable(owner).transfer(storedmoney);
    }
}