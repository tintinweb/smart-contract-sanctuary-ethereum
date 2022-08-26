/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

pragma solidity 0.8.10;

contract ExampleContract {
   
   event ExampleEvent(string val1, uint val2, bool val3);

   function exampleFunction(string memory val1, uint val2, bool val3) public {
       emit ExampleEvent(val1, val2, val3);
   }
}