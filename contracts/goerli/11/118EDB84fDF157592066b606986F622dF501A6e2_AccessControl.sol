// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract AccessControl {
    

    mapping(bytes32=> mapping(address=>bool)) public roles;
    bytes32 private admin=keccak256(abi.encodePacked("Admin"));  
    bytes32 public user=keccak256(abi.encodePacked("User"));

    modifier grant(bytes32 purview){
        require(roles[purview][msg.sender]);
        _;
    }

    constructor(){
        roles[admin][msg.sender]=true;
    }

     function _setGrant(bytes32 _purview,address _user) internal{
        roles[_purview][_user]=true;
    }

    function setGrant(bytes32 _purview,address _user) grant(admin) external{
        _setGrant(_purview,_user);
    }

    function removeGrant(bytes32 _purview,address _user) grant(admin) external{

        roles[_purview][_user]=false;

    }

}