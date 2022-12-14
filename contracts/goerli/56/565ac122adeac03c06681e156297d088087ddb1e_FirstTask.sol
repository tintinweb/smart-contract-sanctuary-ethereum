/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

// SPDX-License-Identifier: MIT
// File: contracts/FirstTask.sol



pragma solidity >=0.8.12;

contract FirstTask {

    //uint256 public Amount; //10000
    string name = "AMD";
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256))  liazoragrer;
    address a = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4; // uint160

    function milionNstecnenq () public {

        balances[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = 1000000;
    }

    function Send (address user, uint256 amount) public {
        require(balances[msg.sender] >= amount, "msg.sender ic Hanel Amount");
            balances[msg.sender] -= amount;
            balances[user] += amount;
        
    }

    function returnAddress () public returns(address) {
            return msg.sender;
    }

    function showBalance (address user) public returns (uint256) {
        return balances[user];

    }   
     function Liazoragrel (address l1 , uint256 allouance) public {

         liazoragrer [msg.sender][l1] = allouance; 
    
     }
     function transferFrom(address from, address whom , uint256 amount) public {
         require(balances[from] >= amount , "Balance >= Amoun");
         require(liazoragrer[from][msg.sender] >= amount , "From + msg.sender >= amount" );

         balances[from ] -= amount;
         balances[whom] += amount;
         liazoragrer[from][msg.sender] -= amount ;

    }

    function Liazoragrel (address from ,address whom) public view returns (uint256) {
        return liazoragrer[from][whom];
                
    }

    

            
}