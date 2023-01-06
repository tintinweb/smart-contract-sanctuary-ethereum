/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


/// @title A contract for organization to mint soul-bounded ceritfication tokens to its members
/// @author PoJu Chen
contract MembershipToken {

    struct MBT {
        string identity;
        uint256 timestamp;
    }

    mapping (address => MBT) private members;

    string public name;
    address public operator;
    bytes32 private zeroHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    
    event Mint(address _member);
    event Burn(address _member);
    event Update(address _member);

    constructor(string memory _name) {
      name = _name;
      operator = msg.sender;
    }

    function _mint(string memory _identity, uint256 _timestamp) private pure returns(MBT memory){
        return MBT(_identity, _timestamp);
    }

    function mint(address _member, string memory _identity, uint256 _timestamp) external {
        require(keccak256(bytes(members[_member].identity)) == zeroHash, "Member already exists");
        require(msg.sender == operator, "Only operator can mint new members");
        members[_member] = _mint(_identity, _timestamp);
        emit Mint(_member);
    }

    function burn(address _member) external {
        require(msg.sender == _member || msg.sender == operator, "Only users and issuers have rights to delete their data");
        delete members[_member];
        emit Burn(_member);
    }

    function update(address _member, MBT memory _memberData) external {
        require(msg.sender == operator, "Only operator can update member data");
        require(keccak256(bytes(members[_member].identity)) != zeroHash, "Member does not exist");
        members[_member] = _memberData;
        emit Update(_member);
    }

    // 檢查兩個空字串(1. not in members[] , 2. address 本身就是 zero)
    function isMember(address _member) external view returns (bool) {
        if (keccak256(bytes(members[_member].identity)) == zeroHash) {
            return false;
        } else {
            return true;
        }
    }

    function getMember(address _member) external view returns (MBT memory) {
        return members[_member];
    }
}