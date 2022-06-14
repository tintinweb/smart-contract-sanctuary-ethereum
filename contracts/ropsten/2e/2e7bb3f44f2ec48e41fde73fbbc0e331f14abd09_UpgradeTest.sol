// pragma solidity >=0.4.22 <0.9.0;

// contract UpgradeTest {
//     uint256 private initValue;

//     function store(uint256 value) public {
//         initValue = value;
//     }
//     function add(uint256 x, uint256 y) public view returns(uint256){
//         uint256 sum = initValue + x + y;
//         return sum;
//     }
// }
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
contract UpgradeTest {
    uint256 private value;
 
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
}