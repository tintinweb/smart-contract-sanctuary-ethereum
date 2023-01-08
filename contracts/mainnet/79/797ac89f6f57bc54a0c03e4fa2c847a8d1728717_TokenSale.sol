/**
 *Submitted for verification at Etherscan.io on 2023-01-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17; 


//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
    
contract ownable {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor()  {
        owner = payable(msg.sender);
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) external onlyOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;   
    }

}
 

interface IERC20
{
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
} 

//USDT has different interface as it does not follow ERC20 standard
interface IUSDT
{
    function transfer(address _to, uint256 _amount) external;
    function transferFrom(address _from, address _to, uint256 _amount) external;
} 

 
//****************************************************************************//
//---------------------        MAIN CODE STARTS HERE     ---------------------//
//****************************************************************************//

contract TokenSale is ownable {

    // token price for USDT in 6 decimals
  uint256 public tokensPerUSDT = 142857142 ; // 142.85 tokens for 1 USDT, which is approx 0.007 USDT price per token

  IUSDT public  USDTToken;
  IERC20 public erc20Token;

  bool public buyEnabled = true;    // by default buy is enabled
  bool public sellEnabled;          // by default sell is disabled
  
  // Event that log buy operation
  event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens, uint256 _tokensPerUSDT);
  event SellTokens(address seller, uint256 amountOfTokens, uint256 amountOfETH, uint256 _tokensPerUSDT);


  constructor(IUSDT _USDTToken, IERC20 _CEIToken) {
       USDTToken = _USDTToken;
       erc20Token = _CEIToken;
    }



  /**
  * @notice Allow users to buy token for ETH
  */
  function buyTokens(uint256 USDTamount) external returns (bool) {
    
    // Check if buying is enabled or not
    require(buyEnabled, "Buying is disabled");

    uint256 amountToBuy = USDTamount * 1e12 * tokensPerUSDT/1e6;

    //transfer USDT from user to this contract
    USDTToken.transferFrom(msg.sender,owner, USDTamount);
    // Transfer token to the msg.sender
    erc20Token.transfer(msg.sender, amountToBuy);

    // emit the event
    emit BuyTokens(msg.sender, USDTamount, amountToBuy, tokensPerUSDT);

    return true;
  }

 /**
 * @notice Allow users to sell tokens
 * @notice Owner has to enable this in order for this to work
 */
 function sellTokens(uint256 tokenAmountToSell) external {
    
    // Check if selling is enabled or not
    require(sellEnabled, "Selling is disabled");

    // Check that the Vendor's balance is enough to do the swap
    uint256 amountOfUSDTToTransfer = tokenAmountToSell / (tokensPerUSDT*1e12/1e6);

    erc20Token.transferFrom(msg.sender, owner, tokenAmountToSell);

    USDTToken.transfer(msg.sender, amountOfUSDTToTransfer);

    emit SellTokens(msg.sender, tokenAmountToSell, amountOfUSDTToTransfer, tokensPerUSDT);   

  }



  /**
  * @notice Allow the owner of the contract to do admin functions
  */
  function withdrawTokens(IERC20 _tokenaddress,uint256 _amount) external onlyOwner {
    _tokenaddress.transfer(msg.sender, _amount);
  }

  function withdrawUSDT(uint256 _amount) external onlyOwner {
    USDTToken.transfer(msg.sender, _amount);
  }
  function setTokenprice(uint256 _price) external onlyOwner{
        tokensPerUSDT = _price;
   }
   function updateBuySellStatus(bool buyStatus, bool sellStatus) external onlyOwner{
        buyEnabled = buyStatus;
        sellEnabled = sellStatus;
    }

}