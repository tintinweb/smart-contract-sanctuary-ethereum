/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

pragma solidity ^0.4.24;
contract class23{
        string public string_1;
    
        event setNumber(string _from);
  
        function function_3(string x)public {
            string_1 = x;
            emit setNumber(string_1);
        }
}