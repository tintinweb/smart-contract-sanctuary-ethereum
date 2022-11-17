/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
contract todo
{
   struct llist
   {  
       uint no ;         // note no.
       string cont ;        // content
       address own ;         //  owner address
       bool iscom ;            // completed or not
       uint ttim ;              // time of creation
   }
               
    mapping ( address => uint) public num ;             
    mapping ( address => llist[]) public num2 ;
  
      modifier  realowner(address owner)
      {
            require( msg.sender == owner);
            _;
      }

    function real( string memory _contect) public

    {
        if (  num[msg.sender] > 99)

        revert();

        else
        {   uint x = num[msg.sender]  ;   
           llist memory la = llist( x+1, _contect,payable(msg.sender),false,block.timestamp);  // x+1 becuase array starts from 0 but notes serial no. must start from 1
           num2[msg.sender].push(la) ;
           num[msg.sender]++ ;
        }
     }

    function sts(uint a ,  address g ) public realowner(g)
     {    llist[]  storage li = num2[msg.sender] ;  // storage to storage  so creates a reference 
          uint z = num[msg.sender]  ;

            if (a > z)
         revert();

            else if (li[a-1].iscom == true)
            revert();

            else
           { li[a-1].iscom = true ;     // updates value in actual array since it is a reference
                    
           }
     
     }  
       
}