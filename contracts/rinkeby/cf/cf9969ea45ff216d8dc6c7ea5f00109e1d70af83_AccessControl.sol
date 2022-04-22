/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
//We have to specify what version of the compiler this code will use
contract AccessControl {
    //event for grantrole take role and address
    event GrantRole(bytes32 indexed role, address indexed account);
    //event for revokerole take role and address
    event RevokeRole(bytes32 indexed role, address indexed account);
    //role => account => bool
    //mapping 
    //maps for every roles
    mapping(bytes32 => mapping(address => bool)) public roles;
    
    //define admin roles should be constant
    bytes32 public constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    //define user roles should be constant
    bytes32 public constant USER = keccak256(abi.encodePacked("USER"));
  
    //modifier
    //who should not be authorized
    modifier onlyRole(bytes32 _role) {
        require(roles[_role][msg.sender], "not authorized");
        _;
    }
    //grant messege to the deployer of this contract for admin
    constructor() {
        _grantRoles(ADMIN, msg.sender);
    }
    //function for internal grantroles
    function _grantRoles(bytes32 _role, address _account) internal {
        roles[_role][_account] = true;
        ///@dev Emit GrantRole event
        emit GrantRole(_role, _account);
    }

    function grantRoles(bytes32 _role, address _account) onlyRole(ADMIN) external{
         _grantRoles(_role, _account);
    }
    //function for internal grantroles
    function revokeRoles(bytes32 _role, address _account) onlyRole(ADMIN) external{
        roles[_role][_account] = false;
        ///@dev Emit RevokeRole event
        emit RevokeRole(_role, _account);
    }

}