/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// SPDX-License-Identifier: GPL-3.0

// 明确编辑语言，以及编译器版本号
pragma solidity ^0.8.10;

// 智能合约是有contract关键字包裹，类似于其他语言中的类的概念，如c++/java/js中的class
contract Gretting {
    
    // 状态变量，真正上链的数据，修改需要钱，读取不需要花钱，其中：
    // string 数据类型
    // public 表示可以在链上读取（还有private和internal）
    // name 变量名
    string public name; 

    //public 表示可以在链上读取，private表示不能在链上读取，internal表示只能在自己和子合约中读取
    uint256 private age;

    // 只有引用数据类型才涉及到memory和storage关键字，bytes, array, map, struct, string
    // memory ：表示值类型，直接copy，修改时不会修改原始变量
    // storage : 表示引用类型，相当于传递指针，会同步修改原始变量

    //值类型的不需要上述两个关键字：uint, bool
    function getName() external view returns (string memory) {
        return name;
    }

    // 修改状态变量，需要消耗gas
    // _name是规范，使语义更加明确
    // external表示该方法只能在合约之外调用，当前合约不可以调用
    function setName(string memory _name, uint256 _age) external {
        age = _age;
        name = _name;
    }
}

contract HelloWorld {
    
}


/** C++
class Gretting {

}
*/