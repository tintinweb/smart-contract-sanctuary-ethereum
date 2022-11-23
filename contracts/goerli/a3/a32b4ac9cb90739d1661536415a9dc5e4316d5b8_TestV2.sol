/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract TestV2 {
    uint[] test;
    uint public count;
    bool public lock;  

    function push(uint num) mutex public {
        require(!CheckList(test, num), "Already pushed");
        test.push(num);
        count++;
    }

    function pop(uint num) mutex public {
        uint index = checkIndex(test, num);
        if(index == test.length) {
            test.pop();
            count--;
        } else {
            remove(test, index);
            count--;
        }
    }
    
    function remove(uint[] storage _numArray, uint index) internal {
        require(_numArray.length > index, "Out of bounds");
        for (uint256 i = index; i < _numArray.length - 1;) {
            unchecked {
                _numArray[i] = _numArray[i+1];
                i+=1;
            }
        }
        _numArray.pop(); // delete the last item
    }

    function viewArray() view public returns(uint[] memory) {
        return test;
    }

    function checkIndex(uint[] storage _numArray, uint checkNum) internal view returns(uint) {
        uint index = _numArray.length;
        for(uint i; i < index;) {
            if(_numArray[i] == checkNum) {  
                return i;
            }
            unchecked {
                i+=1;
            }
        }
        return index + 1;
    }

	function CheckList(uint[] storage _numArray, uint checkNum) internal view returns(bool) {
        bool result = false;
        uint index = _numArray.length;
        for(uint i; i < index;) {
            if(_numArray[i] == checkNum) {  
                result = true;
            }
            unchecked {
                i+=1;
            }
        }
        return result;
    }

    modifier mutex() {
        require(!lock, "Currently Locked All");
        lock = true;
        _;
        lock = false;
    }
}