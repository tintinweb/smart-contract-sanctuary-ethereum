/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT

//^0.8.17 或者  >=0.6.0<=0.9.0
pragma solidity ^0.8.7;

contract SimpleStorage {
    //public 代表能够被公众看到
    uint256 public number = 11;
    //默认值就是 0 不定义属性的话默认就是 内部 internal
    uint256 favoriteNumber;
    bool favoriteBool = false;
    string favoriteString = "sdadasdasdas";
    int256 favoriteInt = -54;
    int tesstint = 100;
    address favoriteAddress = 0xC69b3fF7F8f441882faA872a86cA6e18df3b5991;
    bytes32 favoriteByte = "cat";

    //储存数据  关键字 external public  private internal
    //  external  只有外部的合同可以调用本合同的不行 store()
    // internal     只有本合同的可以调用，外部的不行
    // public 所有可见可以调用
    // private 私有的只有本合同内的才可以看见和调用
    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
        //  uint256 number = 22;
    }

    // function store2(uint256 _favoriteNumber) public {
    //     // 找不到变量就会报错
    //    number;

    // }

    // retrieve(可以放参数) public  returns(返回的数据类型)   view  pure
    //view 只返回视图
    //pure 可以返回计算的结果
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // 对象用 struct 相当于 new  里面的元素可以用索引来进行操作
    struct People {
        uint256 favoriteNumber;
        string name;
    }
    People public persion = People({favoriteNumber: 22, name: "nick"});

    //数组   Peoples[这里可以限制数组的最大量]
    People[] public psersons;

    //function 来添加 元素 两种储存方式 memory（相当于堆内存） 只存在于合同中   storage（相当于持久化 硬盘）
    //string 叫字符串储存器
    function addPerson(string memory _username, uint256 _usernumber) public {
        // psersons.push(People({favoriteNumber:_usernumber,name:_username}));
        psersons.push(People(_usernumber, _username));
        // 还是要手动去取出来 就相当于 java map 的get方法
        nameToNumber[_username] = _usernumber;
    }

    //映射  mapping  这里设计的方法就是用来 控制映射类型的
    mapping(string => uint256) public nameToNumber;

    // function retrieve2(uint256 favoriteNumber) public pure {
    //       favoriteNumber+favoriteNumber;
    // }

    string public message = "hello World";

    // string两种储存方式 memory 和 storage
    function fn1() public view returns (string memory) {
        return message;
    }
}