/**
 *Submitted for verification at Etherscan.io on 2022-06-04
*/

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.7.6;

contract SocialDeployer {

    mapping(address => string) internal avatar;
    mapping(address => string) internal name;
    mapping(address => bool) internal registred;

    function register() public {
        registred[msg.sender] = true;
    }

    modifier _isRegistred() {
        require(registred[msg.sender]);
        _;
    }

    function setAvatar(string calldata _avatarURI) public _isRegistred {
        name[msg.sender] = _avatarURI;
    }

    function getAvatar(address _address) public view returns (string memory){
        return name[_address];
    }

    function setUsername(string calldata _name) public _isRegistred {
        name[msg.sender] = _name;
    }

    function getUsername(address _address) public view returns (string memory){
        return name[_address];
    }

}