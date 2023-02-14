//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract ArrayMapping {

    mapping (uint256 => bool) public numberDidMint;

    // do this last, this is fancy
    mapping (uint256 => mapping (address => bool)) numberToAddressToBool;

    // note: accessing an address beyond the length returns 0x000000000,
    // the zero address, this is the default behavior of solidity
    address[] public addressArray;

    // note: accessing a number beyond the length returns 0
    // (solidity default beahvior)
    uint[] public numberArray;

    // For your testing convenience
    function addressArrayLength() view external returns (uint256) {
        return addressArray.length;
    }

    // For your testing convenience
    function numberArrayLength() view external returns (uint256) {
        return numberArray.length;
    }

    // updates the value for the key _num in the mapping
    function updateNumberDidMint(uint256 _num, bool _val) external {
        numberDidMint[_num] = _val;
    }

    // A function to update a nested array. It always uses the sender's wallet as the address, just for ease and testing.
    function updateNumberToAddressToBool(uint256 _num, bool _val) external {
        numberToAddressToBool[_num][msg.sender] = _val;
    }

    // A simple function to push a number to the end of the array
    function updateNumberArray(uint256 _n) external {
        numberArray.push(_n);
    }

    // A simple function that pushes any address (contract or wallet) to the end of the array
    function updateAddressArray(address _a) external {
        addressArray.push(_a);
    }

}