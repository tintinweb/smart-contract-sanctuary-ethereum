/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; //0.8.12  >=0.8.7 <0.9.0

//EVM Ethereum Virtual Machine
// Avalanche, Fantom, Polygon

// //类似其它语言的类
contract SimpleStorage {
    //bool ,boolean
    //uint(无符号整数，表示这个数字不是可正可负的，只能是正数) uint8 就是分配了8个bit  最大为uint256,//如果不写就默认256  //把分配空间显式的写出来是一个好习惯
    //int 可以表示正数或者负数
    //address 表示地址 就和小狐狸那个地址一样
    //bytes

    // bool hasFavNum = true;//定义一个boolean类型的变量 , 并且赋值为true
    // uint hasFavNum1 = 12;//定义一个uint类型的变量 , 并且赋值为12 //默认为 256个bit
    // uint256 hasFavNum2 = 12;//定义一个uint类型的变量 , 并且赋值为12 //默认为 256个bit  //最低可以设置8个bit，因为8bit是一个byte ， 按照byte来增加空间：uint8 16 32  一直到uint256最多
    // int256 favNum = 5;//定义一个int类型的变量 , 并且赋值为5 //同上 默认为 256个bit
    // int256 favNum2 = -5;//定义一个int类型的变量 , 并且赋值为-5 //同上 默认为 256个bit
    // string favNumText = "Five"; //string是一种bytes ，只能存文本
    // address myAddress=0xcAc206483884A9261061c45Eb29DFD32489Eaea6;
    // bytes32 fBytes = "cat111";//cat是一个string，但是可以自动转化为bytes //默认为bytes32（32也是最大值：https://docs.soliditylang.org/en/latest/types.html#fixed-size-byte-arrays） //bytes变量通常是“0x”开头然后一些随机数字和字母 0x1234562asd11 //bytes32 代表分配32个byte   //不能bytes64，因为bytes32是被允许分配的最多空间

    // uint256 favoriteNumber; //默认值是null  在 solidity 中是0 //所以这里相当于自动赋值为0

    // uint256 internal hasFavNum2; // // 默认为internal // 标识只对本和约和继承合约可见
    // uint256 public hasFavNum3; // 带有public的变量，可以看作是一个返回uint256的view函数    //相当于有一个  getter函数   所以部署后  合约上会看到按钮
    uint256 hasFavNum3; // 带有public的变量，可以看作是一个返回uint256的view函数    //相当于有一个  getter函数   所以部署后  合约上会看到按钮

    function store(uint256 _num) public virtual {
        hasFavNum3 = _num;
    }

    function store2(uint256 _num) public returns (uint256) {
        hasFavNum3 = _num;
        uint256 testVar = 5;

        return hasFavNum3 + testVar;
    }

    //solidity中 view pure 标识函数不需要消耗gas
    //view函数不允许修改任何状态，因为只是读区块链数据，   记住：只有更改状态的时候才支付gas，发交易
    //调用view函数是免费的，除非你在消耗gas的函数中使用他
    function retrieve() public view returns (uint256) {
        return hasFavNum3;
    }

    //有点类似 类的写法，定义结构体 然后根据结构体生成新的
    People public p1 = People({name: "xxx", age: 18});

    People public p2 = People(28, "xiaoming"); //这种方式 要注意每个字段的顺序 和 结构体保证一致 否则报错

    // uint256[] public numberlist;
    People[] public peoples;

    //字典， 类似js中的map对象，  存得是key-val键值对
    //string=>uint256 表明存的对应类型 键为string  值为uint256
    mapping(string => uint256) public nameToAge;

    struct People {
        uint256 age;
        string name;
    }

    //calldata 是不可以修改的临时变量 如果用这个，函数内就不能修改传进来的参数，否则报错
    //memory  是可以修改的临时变量
    //storage  //是可以修改的永久变量  定义变量时，默认为这个   例如  uint256 hasFavNum2;  //默认就是storage

    //为什么uint256不用指定 memory？  因为solidity自动知道uint256的位置，知道对于这个函数，uint256将只是在记忆中，
    //然而它不知道字符串将是什么，字符串实际是字节数组，因为字符串是一个数组，我们需要添加这个内存位，因为我们需要确定数组的数据位置，

    //数组、结构或映射 都需要这么处理：在函数形参变量前面添加 关键字

    //为什么不能用storage？ 因为这个变量（_name） 实际上并没有被存储在任何地方

    //这里唯一接受的两个是： calldata 、 memory
    function addPerson(string memory _name, uint256 _age) public {
        // _name = "12";  //memory 可以修改，  calldata不可以

        //添加方式一：
        // peoples.push(People(_age,_name)); //这种要注意顺序， age和定义结构体那里 放在第一个， name在第二个，不然会报错

        // //添加方式二：
        // People memory newPerson = People({age:_age,name:_name});
        // peoples.push(newPerson);

        //添加方式三：
        // People memory newPerson = People(_age,_name); //注意顺序
        // peoples.push(newPerson);

        peoples.push(People(_age, _name)); //这种是最好的  甚至不需要 memory关键字

        nameToAge[_name] = _age;
    }
}