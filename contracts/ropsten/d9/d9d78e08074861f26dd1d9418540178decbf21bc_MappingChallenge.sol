/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

pragma solidity ^0.4.21;

contract MappingChallenge {
    bool public isOk = true;
    bool public isComplete = true;
    uint256[] map; 

    function set(uint256 key, uint256 value) public {
        // Expand dynamic array as needed
        if (map.length <= key) {
            map.length = key + 1;
        }

        map[key] = value;
    }

    function get(uint256 key) public view returns (uint256) {
        return map[key];
    }

    function setKey(uint256 key, uint256 value) public {
        map[key] = value;
    }

    function setOk(uint256 key, uint256 value) public {
        assembly {
            sstore(key, value)
        }
    }
    function setValue( uint256 value) public {
        assembly {
            sstore(0x0, value)
        }
    }
}