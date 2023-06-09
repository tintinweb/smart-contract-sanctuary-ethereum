// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma abicoder v2;
import "./Initializable.sol";
contract V2 is Initializable {
    struct ExtraUint{
        bool isInitialized;
        uint8 data1;
        uint16 data2;
        uint32 data3;
        uint64 data4;
        uint128 data5;
    }
    struct People{
        string name;
        string gender;
        uint256 age;
        ExtraUint eu;
    }
    uint256 total;
    mapping(uint256 => People) students;
    function initialize() public initializer {
        total = 0;
    }
    function add(People calldata people) public {
        students[total++] = people;
    }
    function find(uint256 id) public view returns (People memory){
        return students[id];
    }
    function updateScore(uint256 id, uint8 score) public {
        require(id < total, "!id");
        students[id].eu.data1 = score;
    }
}