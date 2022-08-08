/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

pragma solidity ^0.8.15;

contract SimpleStorage {
    uint256 data;

    function set(uint256 _data) external {
        data = _data;
    }

    function read() external view returns (uint256) {
        return data;
    }
}