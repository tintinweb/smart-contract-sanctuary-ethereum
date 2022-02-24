/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// File: contracts/Faucet_DFTY.sol



pragma solidity ^0.8.4;

interface IERC20 {
    
    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
 
}

contract DeftifyDFTYTokenFaucet {
    
    // The underlying token of the Faucet
    IERC20 token;
    
    // The address of the faucet owner
    address owner;
    
    // For rate limiting
    mapping(address=>uint256) nextRequestAt;
    
    // No. of tokens to send when requested
    uint256 faucetDripAmount = 50000;
    
    // Sets the addresses of the Owner and the underlying token
    constructor (address _tokenAddress, address _ownerAddress) {
        token = IERC20(_tokenAddress);
        owner = _ownerAddress;
    }   
    
    // Verifies whether the caller is the owner 
    modifier onlyOwner{
        require(msg.sender == owner,"FaucetError: Caller not owner");
        _;
    }
    
    // Sends the amount of token to the caller.
    function send() external {
        require(token.balanceOf(address(this)) > 1,"FaucetError: no token in this smart contract");
        require(nextRequestAt[msg.sender] < block.timestamp, "FaucetError: you request too fast, try again later");
        
        // Next request from the address can be made only after 5 minutes         
        nextRequestAt[msg.sender] = block.timestamp + (7200 minutes); 
        
        token.transfer(msg.sender,faucetDripAmount * 10**token.decimals());
    }  
    
    // Updates the underlying token address for the faucet
     function setTokenAddress(address _tokenAddr) external onlyOwner {
        token = IERC20(_tokenAddr);
    }    
    
    // Updates the drip rate
     function setFaucetDripAmount(uint256 _amount) external onlyOwner {
        faucetDripAmount = _amount;
    }
     
      
}