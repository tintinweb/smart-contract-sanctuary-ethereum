/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;



// File: userCreate.sol

contract CreateID {
    
    event NewUser(address _address, uint256 _id);

    struct User {
        address _address;
        uint256 id;
    }

    User[] public user;

    mapping(address => uint256) addressToId;
    mapping(uint256 => address) idToAddress;

    function _pushToArray(address _address, uint256 _id) private {
        addressToId[_address] = _id;
        idToAddress[_id] = _address;
        user.push(User(_address, _id));
    }

    function _generateId(address _id) private pure returns (uint256) {
        uint256 id = uint256(keccak256(abi.encodePacked(_id)));
        return id;
    }

    function generateUser() public {
        uint256 id = _generateId(msg.sender);
        _pushToArray(msg.sender, id);

        emit NewUser(msg.sender, id);
    }
}