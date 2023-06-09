// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library Adder{

    function add(uint[] memory seeds) internal pure returns(uint)
    {    
        uint sum = 0;
        for(uint i = 0; i<seeds.length; i++)
        {
            sum += seeds[i];
        }
        return sum;
    }
     function sum(uint a, uint b) internal  returns(uint)
    {    
        return a+b;
    }
    
}


contract Data {
//生日
    struct People {
        uint256 id;
        bytes name; //名称
        uint256 ages; //年龄
        bool sex; //性别
        uint256 birthTime; //出生时间
        uint16[] playMonths; //每年玩的月数
        uint256[][] playMonthDays; //每月玩的日期（1-31），1,3,5
    }
    mapping(uint256 => People) peopleMap; //用户游玩数据
}




/**
 * 复杂类型
 * 一维数组,传参，返回参数
 * 二位数组,传参，返回参数
 * 结构体：包含原始类型及以为数组，二位数组；,传参，返回参数
 * 结构体配置，及结构体数组配置,传参，返回参数
 */
// import "./ComplexTypeData.sol";
// contract ComplexType is ComplexTypeData {
contract DataMain is Data{
     //返回对象
    event OperateLog(string functionName, bytes32 value);
    uint256 private total;
    string private greeting;
    //function to access the library
    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function sum(uint[] memory data)external pure returns(uint)
    {
       uint sum;
       sum = Adder.add(data);
       return sum;
    }
    function getUser(uint256 id) public view returns (People memory) {
        People memory people = peopleMap[id];
        return people;
    }
}