/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

pragma solidity ^0.4.24;
contract class23{
        uint256 public integer_1 = 1;
        uint256 public integer_2 = 2;
        string public string_1;
    
        event setNumber(string _from);
        //事件 事件名稱 紀錄的東西

  
        function function_3(string x)public {
            string_1 = x;
            emit setNumber(string_1);
            //emit 呼叫事件
        }
}