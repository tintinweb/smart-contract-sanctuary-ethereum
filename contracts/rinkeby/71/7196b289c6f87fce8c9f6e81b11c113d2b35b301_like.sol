/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

pragma solidity 0.8.0;

contract like {
    uint pizza;
    uint pizzahate;
    uint hamburger;
    uint hamburgerhate;
    
    function get1() public {
        pizza = pizza+1;
    }
        function get2() public  {
            pizzahate = pizzahate+1;
        }
        function get3 () public  {
            hamburger = hamburger+1;
        } 
        function get4 () public {
            hamburgerhate = hamburgerhate+1;
        }
          function getlikeUnlike() public view returns(uint,uint,uint,uint){
          return(pizza,pizzahate,hamburger,hamburgerhate);
          }
}