// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


//polygon
//0x1304c9c84f99cCBc80f325aA22fc530691DC91A9

//goerli
//0xd9c485FA7E789cDCF0648BFa7101F1B71657216e


interface LogLib {
    function LogStr(
        string memory msg1,
        string memory num1,
        uint256 num2
    ) external;

    function LogNum(
        string memory msg1,
        uint256 num1,
        uint256 num2
    ) external;

    function LogAddr(
        address target_addr,
        string memory msg1,
        uint256 num1,
        uint256 num2
    ) external;

    function logGroup(
        address target_addr,
        string memory msg1,
        string memory msg2,
        string memory msg3,
        string memory msg4,
        string memory msg5,
        uint256 num1,
        uint256 num2,
        uint256 num3
    ) external;

    function userId() external returns (uint256);

    function userSetTime() external;

    function userQueryTime() external returns (uint256);
}

//纯日志输出函数

contract LogTest {
    address private constant LogHandle =
        0xd9c485FA7E789cDCF0648BFa7101F1B71657216e;

    //字符串日志
    function RunStr() external {
        LogLib(LogHandle).LogStr("test", "exec", 1);
    }

    //数字日志
    function RunNum() external {
        LogLib(LogHandle).LogNum("test", 1, 2);
    }

    //地址操作日志
    function RunAddr() external {
        LogLib(LogHandle).LogAddr(msg.sender,"test", 1, 2);
    }

    //全局类型日志操作函数
        function RunGroup() external {
        LogLib(LogHandle).logGroup(msg.sender,"test1","test2","test3","test4","test5",1, 2,3);
    }
}