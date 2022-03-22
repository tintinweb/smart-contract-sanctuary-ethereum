/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Event{
        uint256 public integer_1 = 1;
        uint256 public integer_2 = 2;
        string public string_1;
    
        // event setString(string _str);
  
        // function function_3(string calldata x)public returns(string memory){
        //     string_1 = x;
        //     emit setString(string_1);
        //     return(x);
        // }
        
        string public name;
        event setNameEvent (string name1);
        
        function setName(string calldata _name)public
        {

            name = _name;
            emit setNameEvent(name);

        }

}