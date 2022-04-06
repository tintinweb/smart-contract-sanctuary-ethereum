//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract WidgetInterface {

   function getHealth() public view returns(uint256) {}
   function checkApprove(address appAddress) public view returns(bool) {}

}
contract asker{
    // address public targetAddress;
    WidgetInterface public target;

    function setInterface(address targetaddress) public{
        target = WidgetInterface(targetaddress);
    }

    function sendNothing() public view returns(uint256){
        return target.getHealth();
    }

    function Ifapproved(address _a) public view returns(bool){
        return target.checkApprove(_a);
    }

}