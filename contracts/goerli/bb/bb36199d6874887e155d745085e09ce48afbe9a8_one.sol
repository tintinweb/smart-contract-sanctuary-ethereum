/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ~0.8.6;

contract one {

    string public  _name;
    address[] iion;

    event for_Receive(uint, uint);
    event for_Fallback(address, uint);

    receive() external payable {
        emit for_Receive(msg.value, gasleft());
    }

    fallback() external payable {
        emit for_Fallback(msg.sender, msg.value);
    }

    constructor() {
        _name = "liyuechun";
    }

    function modifyName(string memory name, address[] memory path) external returns (address[] memory lion){

        string memory name1 = name;
        bytes(name1)[0] = 'L';
        iion[0] = path[0];
        path[0] = iion[0];
        lion = iion;
    }
}