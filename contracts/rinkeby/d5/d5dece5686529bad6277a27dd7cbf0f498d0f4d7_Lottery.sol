/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Lottery{

    address public manager;
    uint public price;
    address payable[] public players;
    event Buy(address indexed BuyLottery, uint value);
    event Winder(address indexed winder , uint reward);

    constructor(uint Price) {
         price = Price;
          manager = msg.sender;
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function buyLottery() public payable{
        require(manager != msg.sender,"you is Manager");
        require(msg.value == price ,"minimum 1 ether" );
        players.push(payable(msg.sender));
        emit Buy(msg.sender,msg.value);
    }

    function getPlayer() public view returns(uint){
        return players.length;
    }

    function random() public pure returns(uint test){
        uint _test = uint(keccak256("wow"));
        return _test;
  }
  function selectWiner() public {
      require(msg.sender == manager, "You not manager");
      require(getPlayer() >= 2 , "players mimimex 2");
      uint pickradom = random();
      uint selectIdex = pickradom % players.length;
      address payable winder;
      winder = players[selectIdex];
      emit Winder(winder,getBalance());
      winder.transfer(getBalance());
      players = new address payable[](0);
  }

}