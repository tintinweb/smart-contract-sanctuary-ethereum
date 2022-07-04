/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

// File: test.sol


pragma solidity ^0.8.7;

contract test {
    
    bytes[] public arrayOfBytes;
    STRUCT[] public arrayOfStruct;

    mapping(bytes32 => uint256) public myMapping;

    struct STRUCT{
        bytes32 fileHash;  // 檔案的Hash value
        address owner;     // 存證者的Wallet Address
        uint256 timestamp; // 存證當時的Block timestamp (時間戳記)
    }

    STRUCT private myStruct;

    function encode(bytes32 _fileHash, address _owner) public {
        arrayOfBytes.push(abi.encode(STRUCT(_fileHash, _owner, block.timestamp)));
    }

    function decode(uint256 index) public view returns (bytes32, address, uint256) {
        bytes memory data = arrayOfBytes[index];      
        return abi.decode(data, (bytes32, address, uint256));
    }

    function storeArrayOfStruct(bytes32 _fileHash, address _owner) public {
        arrayOfStruct.push(STRUCT(_fileHash, _owner, block.timestamp));
    }
    
    
}