/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

// File: class.sol



pragma solidity ^0.8.7;

contract FirstClass{ 

    string count = "seojaemin";
    //uint 변수(변할수있는숫자)
    //string 문자열 

    function my_function() public view returns(string memory){    
        //펑션넣으면 view returns는 리드컨트랙이나  view returns없으면 롸이트컨트랙이 생김 
        return count;  //결과값
    }

}