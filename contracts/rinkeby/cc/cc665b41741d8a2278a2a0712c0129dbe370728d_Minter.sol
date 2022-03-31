// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./Ownable.sol";  

interface IZEUR { 
   function transfer(address _to, uint256 _value) external returns (bool);
   function issue(uint amount) external;
} 
  

contract Minter is Ownable { 
    
    address public token;
    uint256 public maxAmount;
 
    constructor(
        address _token,
        uint256 _maxAmount  
    ) Ownable() {
        token = _token;
        maxAmount = _maxAmount;
    }  
  
    // Mints a new amount of tokens
    // these tokens will be transfered to recipient address
     function mint( address _to, uint256 _value ) external onlyOwner{
        require(_value > 0);
        require(_value < maxAmount);
        IZEUR(token).issue(_value);
        IZEUR(token).transfer(_to, _value);
        emit Mint(_to, _value); 
     }


    // Update token address
    function setToken(address _token) external  onlyOwner returns (bool){   
        token = _token;
        return true;
    }  

    // Update max mintable amount
    function setMaxAmount(uint256 _amount) external  onlyOwner returns (bool){   
        maxAmount = _amount;
        return true;
    }   

    // Called when new tokens are minted
    event Mint(address to, uint256 value);
       
}