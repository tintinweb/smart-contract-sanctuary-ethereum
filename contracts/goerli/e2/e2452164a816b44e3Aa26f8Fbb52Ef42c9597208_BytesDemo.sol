/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;
contract BytesDemo {
    bytes public a;
    function setA(bytes memory _data) public {
        a = _data;
    }
    function addToA(bytes1 _data) public {
        a.push(_data);
    }
    function setAIndex(uint _index, bytes1 _data) public {
        if (_index >= a.length) {
            addToA(_data);      
        }
        else {
            a[_index] = _data;
        }
     }
     function getALength() public view returns (uint) {
         return a.length;
     } 
     function concatA(bytes memory _data) public {
         a = bytes.concat(a,bytes1 (0x20), _data);
     }
     function func1() view public returns (bytes memory) {
        bytes memory temp = a;
        func2(temp);
        return temp; 
    }
    function func2(bytes memory _data) pure private {
        _data[0] = 0xcd;
    }
    function func3 () public {
        bytes storage temp = a;
        temp[0] = 0xff;
    }
}