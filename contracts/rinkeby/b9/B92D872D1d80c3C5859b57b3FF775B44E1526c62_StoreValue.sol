/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

// SPDX-Licence-Indentifier: MIT

pragma solidity 0.6.0;

contract StoreValue {
    uint256 myValue = 5;

    function store(uint256 _myValue) public {
        myValue = _myValue;
    }

    function retrieve() public view returns (uint256) {
        return myValue;
    }
}