//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract testdep {

    mapping (uint256 => uint256) public IdToTime;
    uint256[1968] public Health;
    uint256[1968] public Hunger;

    function AddIdToTime(uint256 id) public{
        IdToTime[id] = block.timestamp;
    }

    function setHealth(uint256 id, uint256 _health) public {
        Health[id] = _health;
    }
    function setHunger(uint256 id, uint256 _hunger) public {
        Hunger[id] = _hunger;
    }



   function getDays(uint256 id) public view returns(uint256) {
       return (block.timestamp - IdToTime[id])%60;
   }

   function getHunger(uint256 id) public view returns(uint256) {
       return Hunger[id];
   }
   function getHealth(uint256 id) public view returns(uint256) {
       return Health[id];
   }
   

}