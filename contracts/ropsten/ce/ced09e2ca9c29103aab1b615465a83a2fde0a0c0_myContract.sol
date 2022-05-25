/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// SPDX-License-Identifier: MIT  // 版权声明 git的license

pragma solidity >=0.7.0 <0.9.0;  // 使用的编译器版本

// 合约
contract myContract {
    uint tony; // uint 无符号整型 uint8 到 uint256 uint是uint256缩写 默认是0； int 有符号整型
    uint tom = 0; // 
    uint jerry = 0;

    // view 只度函数  public 能被外部调用 returns 表示输出参数
    function inquireResult() public view returns (uint, uint, uint) {
        return (tony, tom, jerry);
    }

    function vote(bytes32 name) public {
        require(name != "tony" || name != "tom" || name != "jerry", "Invalid vote");
        if (name == "tony") {
            tony++;
        } else if (name == "tom") {
            tom++;
        } else if (name == "jerry") {
            jerry++;
        }
    }
}