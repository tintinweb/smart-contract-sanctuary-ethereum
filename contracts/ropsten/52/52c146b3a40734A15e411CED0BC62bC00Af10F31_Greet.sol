/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

pragma solidity 0.8.10;


contract Greet {
   string  greteeng;

   function  showGreeting() public view returns(string memory) {
       return greteeng;
   } 

    function setGreteeng(string memory _greteeng) public {
        greteeng = _greteeng;
    }
}