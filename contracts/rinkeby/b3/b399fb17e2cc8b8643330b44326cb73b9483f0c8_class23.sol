/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

pragma solidity ^0.4.24;
contract class23{
        uint256 public integer_1 = 1;
        uint256 public integer_2 = 2;
        string public string_1;

        /*定義一個事件，後續可無限呼叫使用*/
        event setNumber(string _from);
       //事件  事件名稱  你要記錄的東西

        function function_3(string x)public {
            string_1 = x;
            emit setNumber(string_1);
        //每次呼叫這一次的事件，就使用emit (= 呼叫這event)
        //emit 在新版上一定要加，在舊版的event是不用加入。
        }
}