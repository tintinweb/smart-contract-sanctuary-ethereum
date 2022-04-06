//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract WidgetInterface {

   function getDays(uint256 id) public view returns(uint256) {}
   function getHunger(uint256 id) public view returns(uint256) {}
   function getHealth(uint256 id) public view returns(uint256) {}
   

}

contract FetchInfo{
    WidgetInterface public target;

    function setInterface(address targetaddress) public{
        target = WidgetInterface(targetaddress);
    }

    function FetchDays(uint256 id) public view returns(uint256){
        return target.getDays(id);
    }

    function FetchHunger(uint256 id) public view returns(uint256){
        return target.getHunger(id);
    }

    function FetchHealth(uint256 id) public view returns(uint256){
        return target.getHealth(id);
    }
}