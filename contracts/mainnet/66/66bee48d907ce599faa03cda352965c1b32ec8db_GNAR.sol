pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT
//Hey! Reaady to fucking SHRED?
//So are we!
//That's why we created GnarInu
//The only dog based token ready to FUCK your MOM.
//The waves are here
//Surf's up sluts
//t.me/GNARINU

import "./ERC20.sol";

contract GNAR is ERC20 {

    uint BURN_FEE = 1;
    uint bakeMinimum = 1000 * 10**18;
    address public owner;

    
constructor() ERC20 ('GnarInu','GNARINU') {
    _mint(msg.sender, 100000* 10 ** 18);
    owner = msg.sender;

    }
    
    
function transfer(address recipient, uint256 amount) public override returns (bool){

            uint burnAmount = amount*(BURN_FEE) / 100;
            _burn(_msgSender(), burnAmount);
            _transfer(_msgSender(), recipient, amount-(burnAmount));

                    
      
      return true;
    }    


function transferFrom(address recipient, uint256 amount) public returns (bool){

            uint burnAmount = amount*(BURN_FEE) / 100;
            _burn(_msgSender(), burnAmount);
            _transfer(_msgSender(), recipient, amount-(burnAmount));

      
      return true;
    }    
 

 
}