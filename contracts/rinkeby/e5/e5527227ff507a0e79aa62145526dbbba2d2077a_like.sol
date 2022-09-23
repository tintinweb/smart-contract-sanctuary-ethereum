/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

pragma solidity 0.8.0;

contract like {
    uint pizza;
    uint pizzahate;
    uint hamburger;
    uint hamburgerhate;
    
    function get1(uint a) public returns(uint) {
        pizza = 0;
        return pizza+a;
    }
        function get2(uint b) public returns(uint) {
            pizzahate = 0;
            return pizzahate+b;
        }
        function get3 (uint c) public returns(uint) {
            hamburger = 0;
            return hamburger+1;
        } 
        function get4 (uint d) public returns(uint) {
            hamburgerhate = 0;
            return hamburgerhate+1;
        }
}