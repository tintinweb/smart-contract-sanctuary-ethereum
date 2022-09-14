// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;



contract Oracle {
    address public owner;
    uint private _oraclePrice = 997701199588776094;

    constructor() {
        owner = msg.sender;
    }

    function setPrice(uint _price) external {
        _oraclePrice = _price;
    }

    function get() external view returns (bool, uint) {
        return (true, _get());
    } 

    function _get() internal view returns (uint) {
        return _oraclePrice;
    }

    function _min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }

}