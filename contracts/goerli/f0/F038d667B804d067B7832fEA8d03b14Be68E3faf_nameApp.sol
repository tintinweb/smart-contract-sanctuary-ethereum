// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract nameApp {
    string public appName;

    function set(string memory _appName) public {
        appName = _appName;
    }

    function get() public view returns(string memory) {
        return(appName);
    }
}