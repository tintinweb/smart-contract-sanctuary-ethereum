/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

pragma solidity >=0.5.0 <0.7.0;

contract HasAnOwner {
    address owner;
    uint index;


constructor () public  {
       owner = msg.sender;
   }
    
     function useSuperPowers  () public {  
        if (msg.sender != owner) { revert("not the owner"); }
        // do something only the owner should be allowed to do
        index = index + 1;
    }
}