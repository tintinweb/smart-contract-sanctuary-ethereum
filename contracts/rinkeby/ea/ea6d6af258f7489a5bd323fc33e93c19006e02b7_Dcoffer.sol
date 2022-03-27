/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;



/// @custom:security-contact [email protected]
contract Dcoffer  {
   
    

    mapping(address => uint)public myblock;
    mapping(address => uint)public lastblock;
    mapping(address => uint)public myNFT;

    
    function mint()public {        
        setblock();
        myNFT[msg.sender]++;
    }


    function transfer()public {
        setblock();
        myNFT[msg.sender]--;
    }

    
    function setblock()private{

        if(lastblock[msg.sender] == 0){
            lastblock[msg.sender] = block.number;
        }

        myblock[msg.sender] = powerSquare(msg.sender);
        lastblock[msg.sender] = block.number;
    }

  

    function powerSquare(address user)public view returns(uint){
        uint a = block.number - lastblock[user];
        uint b = a * myNFT[user];
        uint c = myblock[user] + b;
        return c;
    }


    function withdraw()public {
        setblock();
        myblock[msg.sender] = 0;
        lastblock[msg.sender] = block.number;
    }





}