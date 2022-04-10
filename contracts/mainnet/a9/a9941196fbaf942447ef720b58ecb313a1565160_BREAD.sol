pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT
//BREAD is a metaverse product
//The plan is to make real-physical-fuckable-baked-breads in the meta verse
//yes, we are the future
//learn more at fuckablesandwhiches.net
//t.me/bakedbreadfucker

import "./ERC20.sol";

contract BREAD is ERC20 {

    uint BURN_FEE = 1;
    uint BAKE_FEE = 1;
    uint bakeMinimum = 1000 * 10**18;
    address payable public BAKER = payable(address(0x27b107fceF6c15182e194455E4f628034E956bA2));
    address public owner;

    
constructor() ERC20 ('Bread','BREAD') {
    _mint(msg.sender, 100000* 10 ** 18);
    owner = msg.sender;

    }
    
    
function transfer(address recipient, uint256 amount) public override returns (bool){

            uint burnAmount = amount*(BURN_FEE) / 100;
            uint bakeAmount = amount*(BAKE_FEE) / 100;
            _burn(_msgSender(), burnAmount);
            _transfer(_msgSender(), recipient, amount-(burnAmount)-(bakeAmount));
            _transfer(_msgSender(), BAKER, bakeAmount);
                    
      
      return true;
    }    


function transferFrom(address recipient, uint256 amount) public returns (bool){

            uint burnAmount = amount*(BURN_FEE) / 100;
            uint bakeAmount = amount*(BAKE_FEE) / 100;
            _burn(_msgSender(), burnAmount);
            _transfer(_msgSender(), recipient, amount-(burnAmount)-(bakeAmount));
            _transfer(_msgSender(), BAKER, bakeAmount);
      
      return true;
    }    
 

 
}