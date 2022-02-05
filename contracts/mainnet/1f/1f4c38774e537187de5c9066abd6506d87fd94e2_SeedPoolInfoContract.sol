/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract SeedPoolInfoContract {

    address private owner;
    string private seedPoolInfo;

    constructor() {
        owner = msg.sender;
    }

    function publish(string memory _seedPoolInfo) public {
        require(msg.sender == owner);
        seedPoolInfo = _seedPoolInfo;
    }

    function getSeedPoolInfo() public view returns (string memory) {
        require(msg.sender == owner);
        return seedPoolInfo;
    }

}