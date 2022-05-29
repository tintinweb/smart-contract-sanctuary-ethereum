/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

pragma solidity ^0.8.7;

contract NoFreeLoaders{
     bool private shouldRun=true;
     address private  owner;
    constructor(){
        owner=msg.sender;
    }

    function canIrun() public view returns(bool){
        return shouldRun;        
    }

    function toggleShouldRun()public{
        require(msg.sender==owner,"Not Authorized");
        shouldRun=!shouldRun;

    }



}