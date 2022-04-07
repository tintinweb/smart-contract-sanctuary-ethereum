// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./Ownable.sol";  

interface IERC20 {  
   function issue(uint amount, address to) external;
   function transfer(address recipient, uint256 amount) external returns (bool);
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
        require(_value < maxAmount, 'Wrong value!');
        IERC20(token).issue(_value, _to );  
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