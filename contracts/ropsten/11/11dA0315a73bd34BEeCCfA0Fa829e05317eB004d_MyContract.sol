/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract MyContract {

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    uint public gCount;     
    mapping(uint => g) public _gByIdx;
    
    struct g {
        uint gIdx;
        string gName;
    }

    event a(uint);  
    function creatA(string memory _gName) public {
        _gByIdx[gCount].gIdx = gCount;
        _gByIdx[gCount].gName = _gName;
        gCount++;
        emit a((gCount-1));
    }

    event b(string, uint);  
    function creatB(string memory _gName) public {
        _gByIdx[gCount].gIdx = gCount;
        _gByIdx[gCount].gName = _gName;
        gCount++;
        emit b( _gName, (gCount-1));
    }

    event c(string, string);  
    function creatC(string memory _gName) public {
        string memory idx_to_emit = uint2str(gCount);
        _gByIdx[gCount].gIdx = gCount;
        _gByIdx[gCount].gName = _gName;
        gCount++;
        emit c(idx_to_emit, _gName);
    }

}