/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Counter {

    event CountUpdated(uint count, address sender);
    
    uint public count;
    string public name;

    function inc() external {
        count += 1;
        emit CountUpdated(count, msg.sender);
    }

    function dec() external {
        require(count > 0, "Count is alrealdy 0");
        count -=1;
        emit CountUpdated(count, msg.sender);
    }

    function setName(string memory _name) external {
        name = _name;
    }

    function getName() external view returns(string memory) {
        return name;
    } 
}