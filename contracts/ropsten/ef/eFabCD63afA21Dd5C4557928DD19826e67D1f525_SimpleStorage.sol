/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

pragma solidity ^0.8.4;

contract SimpleStorage {
    uint data;

    function updateData(uint _data) external {
        data = _data;
    }

    function readData() external view returns(uint){
        return data;
    }
}