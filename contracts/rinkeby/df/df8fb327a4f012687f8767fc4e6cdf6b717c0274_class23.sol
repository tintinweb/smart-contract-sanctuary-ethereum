/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

pragma solidity ^0.8.13;
contract class23{
        uint256 public integer_1 = 1;
        uint256 public integer_2 = 2;
        string public string_1;
    
        event setNumber(string _from);
  
        function function_3(string memory x)public {
            string_1 = x;
            emit setNumber(string_1);
        }
        event Transfer(address indexed _from, address indexed _to, uint256 _amount);
}