/**
 *Submitted for verification at Etherscan.io on 2022-09-28
*/

// SPDX-License-Identifier: GPL-3.0
// 20220928
pragma solidity 0.8.0;

contract BBB {
    struct member{
        string id;
        bytes32 password;
    }
    mapping(string => member) memberMapping;

    function getHash(string memory _string) private view returns(bytes32) {
        return keccak256(bytes(_string));
    }

    function join(string memory _id, string memory _password) public returns(bool) {
        memberMapping[_id] = member(_id, getHash(_password));
        return true;
    }

    function login(string memory _id, string memory _password) public view returns(bool) {
        if(memberMapping[_id].password == getHash(_password)){
            return true;
        } else {
            return false;
        }
    }
}