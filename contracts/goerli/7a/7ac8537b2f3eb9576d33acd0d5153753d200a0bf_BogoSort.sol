/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

pragma solidity ^0.8.0;

contract BogoSort {
    uint[] public array;

    constructor(uint[] memory _elements) {
        array = _elements;
    }

    function sort() public {
        array = bogo(array);
    }

    function bogo(uint[] memory _array) private view returns(uint[] memory) {
        while (!isSorted(_array)) {
            _array = shuffle(_array);
        }
        return _array;
    }

    function isSorted(uint[] memory _array) private pure returns(bool) {
        for (uint i = 0; i < _array.length - 1; i++) {
            if (!(_array[i] <= _array[i+1])) {
                return false;
            }
        }
        return true;
    }

    function shuffle(uint[] memory _array) private view returns(uint[] memory) {
        for (uint i = 0; i < _array.length; i++) {
			uint nonce = random(i);
			uint temp = _array[nonce];
			_array[nonce] = _array[i];
			_array[i] = temp;
        }
        return _array;
    }

    function random(uint _nonce) public view returns (uint) {
        uint temp = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _nonce)));
        while (temp > 10) {
            temp = temp / 10;
        }
        return temp;
    }
}