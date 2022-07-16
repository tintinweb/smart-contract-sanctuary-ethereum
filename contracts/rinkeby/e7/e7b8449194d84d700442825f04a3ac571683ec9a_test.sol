/**
 *Submitted for verification at Etherscan.io on 2022-07-16
*/

// File: test.sol


pragma solidity ^0.8.7;

contract test {
    uint8 constant MAX_SEARCH_RANGE = 1;
    uint256 public counter;
    STRUCT[] public arrayOfStruct;

    mapping(bytes32 => uint256) public searchingMap;

    struct STRUCT{
        bytes32 fileHash;  // 檔案的Hash value
        address owner;     // 存證者的Wallet Address
        uint256 timestamp; // 存證當時的Block timestamp (時間戳記)
    }

    // STRUCT private myStruct;

    function attest(bytes32 _fileHash, address _owner) public {
        // 資料存入arrayOfStruct
        arrayOfStruct.push(
            STRUCT(_fileHash, _owner, block.timestamp)
        );

        // 將fileHash映射到指定整數 (即索引值)
        searchingMap[_fileHash] = counter++;
    }

    // function batchSearch(uint256 lowerBoundTime, uint256 upperBoundTime) public returns ()

    function attestForTesting(bytes32 _fileHash, address _owner, uint256 loop) public {

        for(uint i = 0; i < loop; i++) {
            // 資料存入arrayOfStruct
            arrayOfStruct.push(
                STRUCT(_fileHash, _owner, block.timestamp)
            );

            // 將fileHash映射到指定整數 (即索引值)
            searchingMap[_fileHash] = counter++;
        }
        
    }
}