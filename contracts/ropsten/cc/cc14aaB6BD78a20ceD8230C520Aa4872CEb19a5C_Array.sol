// SPDX-License-Identifier: NONE
pragma solidity 0.8.9;

contract Array {
    uint256[] public arr = [1, 2, 3, 4];
    uint256[4] public arrWidth = [1, 2, 3, 4];
    address public ower;
    uint256 public x;

    constructor(uint256 _x) {
        ower = msg.sender;
        x = _x;
    }

    modifier checkoutOwner() {
        require(ower == msg.sender, "verify failed");
        _;
    }
    modifier checkoutLength(uint256 _lenght) {
        require(_lenght <= arr.length - 1, "length failed");
        _;
    }

    function removeArr(uint256 _index)
        external
        checkoutOwner
        checkoutLength(_index)
    {
        for (uint256 i = _index; i < arr.length - 1; i++) {
            arr[i] = arr[i + 1];
        }
        arr.pop();
    }

    function removeWay(uint256 _index)
        external
        checkoutOwner
        checkoutLength(_index)
    {
        arr[_index] = arr[arr.length - 1];
        arr.pop();
    }

    function addArr(uint256 value) external payable checkoutOwner {
        arr.push(value);
    }

    function deleteArr(uint256 _index) external checkoutOwner {
        delete arr[_index];
        assert(arr[_index] == 0);
    }
}