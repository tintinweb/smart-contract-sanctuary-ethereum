// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library removeElementFromArray {
    function removeElement(address[] storage _array, address _element) public {
        uint index = 0;
        unchecked{
            for (uint256 i; i<_array.length; i++) {
                if (_array[i] == _element) {
                    index = i;
                    break;
                }
            }
            for (uint i = index; i < _array.length - 1; i++) {
            _array[i] = _array[i + 1];
            }
            _array.pop();
        }
    }
    function removeByIndex(address[] storage _array, uint _index) public{
        for (uint i = _index; i < _array.length - 1; i++) {
          _array[i] = _array[i + 1];
        }
        _array.pop();
    }
    function shift(address[] storage _array) public{
        unchecked {
            for (uint i = 0; i < _array.length - 1; i++) {
            _array[i] = _array[i + 1];
            }
            _array.pop();
        }
        
    }
}