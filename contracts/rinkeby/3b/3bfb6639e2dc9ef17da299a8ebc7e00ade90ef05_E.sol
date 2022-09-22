/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

pragma solidity 0.8.0;

contract E {
  
    function add(uint a,uint b) public view returns(uint) {
        return a+b ; 
        }
        function minus(int a,int b) public view returns(int) {
            return a-b ;
        }
        function mul(uint a, uint b) public view returns(uint) {
            return a*b ;
        }
        function div(uint a, uint b) public view returns(uint,uint) {
            return (a/b,a%b);
        }
        }