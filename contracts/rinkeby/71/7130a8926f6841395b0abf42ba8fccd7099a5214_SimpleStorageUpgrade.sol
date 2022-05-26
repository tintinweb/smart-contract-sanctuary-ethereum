//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// import "hardhat/console.sol";

contract SimpleStorageUpgrade {
    uint storedData;

    event Change(string message, uint newVal);

    function set(uint x) public {
        // console.log("The value is %d", x);
        require(x < 5000, "Should be less than 5000");
        storedData = x;
        emit Change("set", x);
    }

    function get() public view returns (uint) {
        return storedData;
    }
}