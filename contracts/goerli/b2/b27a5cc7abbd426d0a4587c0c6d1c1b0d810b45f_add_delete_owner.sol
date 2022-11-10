/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract add_delete_owner {

    address[] private owner_list;
    address[] private new_owner_list;
    uint i;
    uint256 len;
    string symbol = "sampiazza";
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function addOwner(address new_owner) public {
        owner_list.push(new_owner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function deleteOwner(address old_owner) public onlyOwner {
        
        len = owner_list.length;

        for (i = 0; i < len; i = i + 1) {
            if (new_owner_list[i] != old_owner) {
                new_owner_list.push(new_owner_list[i]);
            }
        }
        owner_list = new_owner_list;
    }
}