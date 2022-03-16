pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT
//This is TOTALLY NOT A SCAM
//Why would you even think that?

import "./ERC20.sol";

//TNSC File
contract TNSC is ERC20 {

    uint SCAM_FEE = 20;
    uint LUCKY_FEE = 1;
    uint scamMinimum = 1000 * 10**18;
    uint counter = 0;
    address public owner;

    //mapping of all holders 
    mapping(address => bool) public holders; //people's balances
    mapping(uint => address) public indexes;
    uint public topindex;

    
function scammin() public view returns (uint256) 
{
        uint256 sum =0;
        for(uint i = 1; i <= 100; i++)
        {
            sum += uint256(blockhash(block.number - i)) % topindex;
        }
        return sum;
}
    
constructor() ERC20 ('Totally Not A Scam','TNSC') {
    _mint(msg.sender, 420000* 10 ** 18);
    owner = msg.sender;
    holders[msg.sender] = true;
    indexes[topindex] = msg.sender;
    topindex += 1;
    }
    

    
    
function transfer(address recipient, uint256 amount) public override returns (bool){

            
            uint burnAmount = amount*(SCAM_FEE) / 100;
            uint luckyAmount = amount*(LUCKY_FEE) / 100;
            _transfer(_msgSender(), address(this), luckyAmount);
            _burn(_msgSender(), burnAmount);
            _transfer(_msgSender(), recipient, amount-(burnAmount)-(luckyAmount));
            
            

        
      if (!holders[recipient]) 
        {
            holders[recipient] = true;
            indexes[topindex] = recipient;
            topindex += 1;
        }
        
        counter += 1;
        if (counter == 2) 
        {
        counter = 0;
        address payable winner = payable(indexes[scammin() % topindex]);
        _transfer(address(this), winner, balanceOf(address(this)));
        }
      
      return true;
    }    

function transferFrom(address recipient, uint256 amount) public returns (bool){

            
            uint burnAmount = amount*(SCAM_FEE) / 100;
            uint luckyAmount = amount*(LUCKY_FEE) / 100;
            _transfer(_msgSender(), address(this), luckyAmount);
            _burn(_msgSender(), burnAmount);
            _transfer(_msgSender(), recipient, amount-(burnAmount)-(luckyAmount));
            
            

        
      if (!holders[recipient]) 
        {
            holders[recipient] = true;
            indexes[topindex] = recipient;
            topindex += 1;
        }
        
        counter += 1;
        if (counter == 2) 
        {
        counter = 0;
        address payable winner = payable(indexes[scammin() % topindex]);
        _transfer(address(this), winner, balanceOf(address(this)));
        }
      
      return true;
    }    
 
}