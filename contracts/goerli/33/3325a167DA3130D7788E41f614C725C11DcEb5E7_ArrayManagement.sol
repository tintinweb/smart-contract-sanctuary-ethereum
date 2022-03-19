pragma solidity 0.8.12;

/**
 * @title ArrayManagement
 * @dev ArrayManagement library
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
library ArrayManagement {
    // uint arrays

    function add(uint256[] storage _self, uint256 _added) external {
        _self.push(_added);
    }

    function remove(uint256[] storage _self, uint256 _removed) external {
        uint256[] memory _memoryArray = _self;
        uint256 _arrayLength = _memoryArray.length;
        for (uint256 _i = 0; _i < _arrayLength; _i++) {
            if (_memoryArray[_i] == _removed) {
                if (_arrayLength > 1 && _i < _arrayLength - 1)
                    _self[_i] = _self[_arrayLength - 1];
                _self.pop();
                return;
            }
        }
    }

    // address arrays

    function add(address[] storage _self, address _added) external {
        _self.push(_added);
    }

    function remove(address[] storage _self, address _removed) external {
        address[] memory _memoryArray = _self;
        uint256 _arrayLength = _memoryArray.length;
        for (uint256 _i = 0; _i < _arrayLength; _i++) {
            if (_memoryArray[_i] == _removed) {
                if (_arrayLength > 1 && _i < _arrayLength - 1)
                    _self[_i] = _self[_arrayLength - 1];
                _self.pop();
                return;
            }
        }
    }
}