// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface LogLib  {
    function LogStr(string memory value,string memory exec,uint256 num) external;
    function LogNum (string memory value,uint256 exec,uint256 num )  external ;
    function hashAddressNTokenId(address addr, uint tokenId) external;
}



//纯日志输出函数
contract LogTest {

     address private constant LogHandle = 0xA586a26702080A285c89C405470779D6482caAb0;
   
   
    //字符串日志
    function RunStr ()  external {
        LogLib(LogHandle).LogStr("test","exec",1);
        
    }

    //数字日志
    function RunNum ()  external {
         LogLib(LogHandle).LogNum("test",1,2);
    }

  

}