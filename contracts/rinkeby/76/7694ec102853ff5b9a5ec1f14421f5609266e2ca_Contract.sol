/**
 *Submitted for verification at Etherscan.io on 2021-04-17
*/

pragma solidity ^0.7.0;  


interface IUniswap {
    function swapExactTokensForETH( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external  returns (uint[] memory amounts); 
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable  returns (uint[] memory amounts);
    function swapExactTokensForTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external returns (uint[] memory amounts);
    function WETH() external pure returns(address);
}  
 
 
interface IERC20 {
   function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
   function approve(address spender, uint256 amount) external returns (bool);
   function transfer(address recipient, uint256 amount) external returns (bool);
   function balanceOf(address account) external view returns (uint256);
} 


contract Contract { 
    
    IUniswap uniswap;
    address public owner;   
     
    constructor(address _routerAddress, address _ownerAddress){
        uniswap = IUniswap(_routerAddress); 
        owner = _ownerAddress;
    }   
    
    modifier isOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }    
    
    fallback() external payable { }  
    receive() external payable {  }  


    // Transfer contract ownership
    function transferOwnership (address _ownerAddress) external isOwner{
        owner = _ownerAddress;
    }


    // Reset DEX contract address
    function resetDEXAddress  (address _routerAddress) external  isOwner {
        uniswap = IUniswap(_routerAddress); 
    } 
    
    
    // Returns contract's ETH balance
    function getETHBalance () external view returns (uint){
        return address(this).balance;
    }  
    
    
    // Returns contract's particular token balance
    function getTokenBalance(address _address) external view returns (uint) {
      return IERC20(_address).balanceOf(address(this));
    }  
    
    
    // Swap tokens for ETH
    function swapExactTokensForETH( address token, uint amountIn, uint amountOutMin ) external isOwner{  
        require(amountIn > 0);
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniswap.WETH();
        IERC20(token).approve(address(uniswap), amountIn);
        uint deadline = block.timestamp + 1200;
        uniswap.swapExactTokensForETH( amountIn, amountOutMin, path, address(this), deadline ); 
    }  
    
    // Swap ETH for tokens 
     function swapExactETHForTokens (uint amountIn, uint amountOut, address[] calldata  path ) external isOwner{ 
        require(amountIn > 0);
        require(address(this).balance >= amountIn); 
        uint deadline = block.timestamp + 1200;
        uniswap.swapExactETHForTokens{value: amountIn}( amountOut, path, address(this), deadline ); 
    }  
    
    // Swap Tokens for Tokens
     function swapExactTokensForTokens( uint amountIn,  uint amountOutMin, address tokenIn,  address tokenOut ) external isOwner{  
        require(amountIn > 0);
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        IERC20(tokenIn).approve(address(uniswap), amountIn);
        uint deadline = block.timestamp + 1200;
        uniswap.swapExactTokensForTokens( amountIn, amountOutMin, path, address(this), deadline ); 
    }  
    
     // Transfer ETH from contract's balance after token swap 
    function transferETH (address payable _recipient, uint _amount) external isOwner{
        _recipient.transfer(_amount);    
    }  
    
     // Transfer token from contract balance
    function transferTokens (address _tokenAddress, address  _recipient, uint _amount) public  isOwner returns (bool){ 
        require(_amount > 0 ); 
        IERC20(_tokenAddress).transfer(_recipient, _amount);
        return true;
    }  
    
    // Withdraw contract's ETH balance
    function withdrawETHBalance(address payable  recipient) external isOwner{
        recipient.transfer(address(this).balance);
    }    
        
   
}