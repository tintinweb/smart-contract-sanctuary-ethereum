// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
//CallingParentConstructor
contract Ownable {
    

    address public Owner;

    constructor(){
        Owner=msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender==Owner,"NOT Owner");
        _;
    }
  
    function setOwner(address _user) onlyOwner() external returns(address){
        Owner=_user;
        return _user;
    }

    function other(address _user) external pure returns(address){

        return _user;

    }

}