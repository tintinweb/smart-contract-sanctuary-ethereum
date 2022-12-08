/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

// File: ITM_Test/test.sol

pragma solidity ^0.8.13;

contract test {

    struct Info {
        string description;
        uint256 timestamp;
    }

    mapping(address => Info) public UserInfo;

    function setUserInfo(string memory _description, uint256 _timestamp) public {
       
    }

    function encodeString(string memory _description) public pure returns (bytes memory) {
        return abi.encode(_description);
    }

    function decodeString(bytes memory _data) public pure returns (string memory res) {
        res = abi.decode(_data, (string));
    }
}

// 0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000037373730000000000000000000000000000000000000000000000000000000000