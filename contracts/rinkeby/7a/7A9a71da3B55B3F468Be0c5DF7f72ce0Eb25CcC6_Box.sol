// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
 
contract Box {
    uint256 internal value;
 
    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);
 
    // Stores a new value in the contract
    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }
 
    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }

    // Uncomment and redeploy to see the upgrade happen!
    // // Increments the stored value by 1
    // function increment() public {
    //     value = value + 1;
    //     emit ValueChanged(value);
    // }

    // Uncomment and redeploy to see the upgrade happen!
    // replace the "1" with a "2"
    function version() public pure returns (uint256) {
        return 1;
    }
}