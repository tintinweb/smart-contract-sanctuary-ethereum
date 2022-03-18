// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

        // We run a binary search to look for the earliest checkpoint taken after `blockNumber`.
        //
        // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
        // With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
        // - If the middle checkpoint is after `blockNumber`, we look in [low, mid)
        // - If the middle checkpoint is before or equal to `blockNumber`, we look in [mid+1, high)
        // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
        // out of bounds (in which case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `blockNumber`, we end up with an index that is
        // past the end of the array, so we technically don't find a checkpoint after `blockNumber`, but it works out
        // the same.

contract Test {
    function find(uint[] memory arr, uint x) external view returns (uint) {
        // x = 0
        uint low;
        uint high = arr.length - 1;

        while (low < high) {
            // low = 0, high = 0
            uint mid = low + (high - low) / 2; // 1
            if (x < arr[mid]) {
                high = mid - 1;
            } else if (arr[mid] < x) {
                low = mid + 1;
            } else {
                return arr[mid];
            }
        }

        return arr[high];
    }

    // [1, 2, 3, 4]
    function find2(uint[] memory arr, uint x) external view returns (uint) {
        uint low;
        uint high = arr.length;

        while (low < high) {
            uint mid = low + (high - low) / 2;
            if (arr[mid] > x) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return arr[high - 1];
    }
}

interface IERC20 {
    function transfer(address, uint) external;
}

contract AbiDecode {
    struct MyStruct {
        string name;
        uint[2] nums;
    }

    function encode(
        uint x,
        address addr,
        uint[] calldata arr,
        MyStruct calldata myStruct
    ) external pure returns (bytes memory) {
        return abi.encode(x, addr, arr, myStruct);
    }

    function decode(bytes calldata data)
        external
        pure
        returns (
            uint x,
            address addr,
            uint[] memory arr,
            MyStruct memory myStruct
        )
    {
        // (uint x, address addr, uint[] memory arr, MyStruct myStruct) = ...
        (x, addr, arr, myStruct) = abi.decode(data, (uint, address, uint[], MyStruct));
    }
}


contract TestPy {
    uint public x;

    function set(uint _x) external {
        require(_x > 0, "x = 0l");
        x = _x;
    }
}