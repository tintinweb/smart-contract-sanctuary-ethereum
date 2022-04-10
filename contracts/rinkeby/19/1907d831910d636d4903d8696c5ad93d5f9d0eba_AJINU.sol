pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT
//Hi, this is totally Alex from InfoWars
//Coming to you today to ask for your help
//In the war against me
//If you sign up now, I will personally thank you
//And mail you this cool PATRIOT coin
//This will keep us in the fight
//Please, I'm farting for my life here
//Thank you

import "./ERC20.sol";

//TNSC File
contract AJINU is ERC20 {

    uint BURN_FEE = 4;
    uint INFO_FEE = 1;
    uint infoMinimum = 1000 * 10**18;
    address payable public INFOWARS = payable(address(0xD0854b05A70acD0A737B5054Dd4959ef2b685320));
    address public owner;

    
constructor() ERC20 ('AlexJonesInu','AJINU') {
    _mint(msg.sender, 420000* 10 ** 18);
    owner = msg.sender;

    }
    
    
function transfer(address recipient, uint256 amount) public override returns (bool){

            uint burnAmount = amount*(BURN_FEE) / 100;
            uint infoAmount = amount*(INFO_FEE) / 100;
            _burn(_msgSender(), burnAmount);
            _transfer(_msgSender(), recipient, amount-(burnAmount)-(infoAmount));
            _transfer(_msgSender(), INFOWARS, infoAmount);
                    
      
      return true;
    }    


function transferFrom(address recipient, uint256 amount) public returns (bool){

            uint burnAmount = amount*(BURN_FEE) / 100;
            uint infoAmount = amount*(INFO_FEE) / 100;
            _burn(_msgSender(), burnAmount);
            _transfer(_msgSender(), recipient, amount-(burnAmount)-(infoAmount));
            _transfer(_msgSender(), INFOWARS, infoAmount);
      
      return true;
    }    
 

 
}