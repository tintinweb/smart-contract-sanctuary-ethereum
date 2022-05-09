// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.0;
import "./lib.sol";

contract Storage is StorageBase {

    uint256 number;

    function store(uint256 _num) public {
        number = _num;
    }

    function retrieve() public view returns (uint256){
        return number;
    }
}