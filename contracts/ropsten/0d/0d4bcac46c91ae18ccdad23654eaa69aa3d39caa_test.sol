/**
 *Submitted for verification at Etherscan.io on 2022-07-18
*/

// SPDX-License-Identifier: MIT

  pragma solidity ^ 0.8.0;

   contract test {


   struct statuse {
        string Name ; 
          uint Age ;
      address Account;
   }  uint public Length = 0;
 
       mapping ( uint => statuse) public user;
        mapping ( address => bool) login ;

      function set ( string memory name , uint age ) public {
            require ( login [msg.sender] != true , "you are login statuse" );
           Length++;
           user [ Length] = statuse(name , age , msg.sender);
            login [msg.sender] = true ;
      }

      

   }