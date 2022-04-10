pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT
//AppleFuck is a metaverse product
//The plan is to make real-physical-fuckable-sandwhiches in the meta verse
//yes, we are the future
//learn more at www.fuckablesandwhiches.com
//t.me/AppleFucker

import "./ERC20.sol";

contract APFKR is ERC20 {

    uint BURN_FEE = 10;
    address public owner;

    
constructor() ERC20 ('AppleFuck','APFKR') {
    _mint(msg.sender, 911420* 10 ** 18);
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