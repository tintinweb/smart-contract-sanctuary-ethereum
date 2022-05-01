/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// [12, 3, 4, 5, 3, 44, 2, 12, 3, 4, 5, 21, 46, 1, 2, 12]
contract GasSaving {
    uint256 public total;
    // start - 54279
    function sumIfEvenAndLessThan99_0(uint256[] memory nums) external {
        for (uint256 i = 0; i < nums.length; i += 1) {
            bool isEven = nums[i] % 2 == 0;
            bool isLessThan99 = nums[i] < 99;
            if (isEven && isLessThan99) {
                total += nums[i];
            }
        }
    }

    // 参数从 memory 改为 calldata - 51858
    function sumIfEvenAndLessThan99_1(uint256[] calldata nums) external {
        for (uint256 i = 0; i < nums.length; i += 1) {
            bool isEven = nums[i] % 2 == 0;
            bool isLessThan99 = nums[i] < 99;
            if (isEven && isLessThan99) {
                total += nums[i];
            }
        }
    }

    // 循环内高频写入的状态变量拷贝到内存中 - 51428
    function sumIfEvenAndLessThan99_2(uint256[] calldata nums) external {
        uint256 _total = total;
        for (uint256 i = 0; i < nums.length; i += 1) {
            bool isEven = nums[i] % 2 == 0;
            bool isLessThan99 = nums[i] < 99;
            if (isEven && isLessThan99) {
                _total += nums[i];
            }
        }
        total = _total;
    }

    // 合并判断条件，减少内部变量 - 50870
    function sumIfEvenAndLessThan99_3(uint256[] calldata nums) external {
        uint256 _total = total;
        for (uint256 i = 0; i < nums.length; i += 1) {
            if (nums[i] % 2 == 0 && nums[i] < 99) {
                _total += nums[i];
            }
        }
        total = _total;
    }

    // 循环自增变量优化 - 50258
    function sumIfEvenAndLessThan99_4(uint256[] calldata nums) external {
        uint256 _total = total;
        for (uint256 i = 0; i < nums.length; ++i) {
            if (nums[i] % 2 == 0 && nums[i] < 99) {
                _total += nums[i];
            }
        }
        total = _total;
    }

    // 将数组元素加载到内存 - 50109
    function sumIfEvenAndLessThan99_5(uint256[] calldata nums) external {
        uint256 _total = total;
        for (uint256 i = 0; i < nums.length; ++i) {
            uint256 num = nums[i];
            if (num % 2 == 0 && num < 99) {
                _total += num;
            }
        }
        total = _total;
    }

    // 将数长度加载到内存 - 50072
    function sumIfEvenAndLessThan99_6(uint256[] calldata nums) external {
        uint256 _total = total;
        uint256 len = nums.length;
        for (uint256 i = 0; i < len; ++i) {
            uint256 num = nums[i];
            if (num % 2 == 0 && num < 99) {
                _total += num;
            }
        }
        total = _total;
    }
}