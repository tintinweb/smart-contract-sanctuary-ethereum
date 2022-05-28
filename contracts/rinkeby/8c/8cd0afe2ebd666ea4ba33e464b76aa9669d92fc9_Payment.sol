/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

// File: contracts/Payment.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

/*
* @author Blockgames Devs
* @title Cryptopayments
*/


/**
    * @notice Interface for all supported crypto payments tokens
    * For stables tokens pegged to US dollar $ => usdt, busd, dai, usdc, ust
 */
interface IERC20{
/**
  * @dev Returns the amount of tokens owned by `account`.
  */
function balanceOf(address account) external view returns (uint256);
/**
  * @dev Returns the remaining number of tokens that `spender` will be
  * allowed to spend on behalf of `owner` through {transferFrom}. This is
  * zero by default.
  *
  * This value changes when {approve} or {transferFrom} are called.
  */
function allowance(address owner, address spender) external view returns (uint256);
/**
  * @dev Moves `amount` tokens from `from` to `to` using the
  * allowance mechanism. `amount` is then deducted from the caller's
  * allowance.
  *
  * Returns a boolean value indicating whether the operation succeeded.
  *
  * Emits a {Transfer} event.
  */
  function transferFrom(address from,address to,uint256 amount) external returns (bool);
  
  /**
  * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
  * `transferFrom`. This is semantically equivalent to an infinite approval.
  *
  * Requirements:
  *
  * - `spender` cannot be the zero address.
  */
  function approve(address spender, uint256 amount) external returns (bool);

  function name() external view returns (string memory);

  function decimals() external view returns (uint8);
}

contract Payment {
/**@notice address of contract owner */
address private owner;

uint256 immutable decimals = 10**18;
/**
  * @dev fees in percentage , charges on each transaction
*/
uint256 private fee = 2;

  bool private contractState;
   
/**
  *@dev mapping for support tokens for making payment
*/
mapping(string =>address) public supportedTokens;

/**
    *@dev Events to track payments
 */
event Paid(string paymentReferenceID,address _payer,uint256 amount, string _paymentTokenType);

  error failed(string);
  error contract_paused();  
    

    constructor(address _owner) {
        owner = _owner;
        contractState=true;
    }

    // @notice onlyOwner() modifier allows only the smart contract owner to use a function
    modifier onlyOwner(){
        require(msg.sender == owner, "You are not the Owner");
        _;
    }

    /**
     *@notice modifier checks that contract is not set to paused
     */
    modifier state
    {
        if(contractState==false)
        {
            revert contract_paused(); /**paused("contract paused")*/
        }
        _;
    }

    // @notice changeOwnership() function changes ownership of smart contract from one address to another
    function changeOwnership(address _newOwner) public onlyOwner(){
        require(_newOwner != address(0), "Invalid Address provided");
        require(_newOwner != owner, "You are already the owner");
            owner = _newOwner;
    }


    /**
  *@dev Add to tokens to list of supported tokens for payment
*/
function addToSupportedTokens(string memory _tokenName, address _tokenAddress) public state onlyOwner returns(string memory,address){
  checkToken(_tokenName, _tokenAddress);
  supportedTokens[_tokenName]=_tokenAddress;
  return (_tokenName,_tokenAddress);

}
  /**
   *@dev internal function to check that a token exists
   */
  function checkToken(string memory _tokenName, address _tokenAddress) internal view
  {
   if( keccak256(abi.encodePacked((IERC20(_tokenAddress).name()))) != keccak256(abi.encodePacked((_tokenName))))
   {
     revert failed("Invalid_Token");
   }
  } 
  
  /**
   *@dev returns the address of a supported token to front end
   */
  function getAddress(string calldata _tokenName)external state view returns(address)
  {
    if(supportedTokens[_tokenName]==address(0))
    {
      revert failed("Token doesn't exist in contract");
    }
    return supportedTokens[_tokenName];
  }
    
 /**
  * @notice functions to make payments to merchants
  * payment amount must be greater than zero for each token by the user
  * 
  */
  
  function makePayment(string memory _paymentReferenceID,address _merchant,uint256 _amount,string memory _paymentTokenType) external payable state returns(string memory paymentReferenceID,uint256 amount,string memory paymentToken) {
    uint256 _realAmount = _amount*decimals;

    /**@dev check validity of the merchants address*/
    require(_merchant != address(0),"Invalid address");

    /** @dev public Instance of the payment token type*/
    IERC20 paymentTokenType = IERC20(supportedTokens[_paymentTokenType]);

    /**@dev balance must be greater than zero and also be greater than the payment amount for this payment to effect */
    require(paymentTokenType.balanceOf(msg.sender) >= _realAmount,"Insufficient funds to carry out transaction!");
    require( _realAmount >0,"Payment Amount must be greater than zero");

    /**@dev Allowance for payment smart contract token available to spend */
    uint256 allowance = paymentTokenType.allowance(msg.sender, address(this));
    require(allowance >= _realAmount, "Check the token allowance");


    /**@dev calculate and subtract charges*/
    uint256 _charges = (fee *_realAmount)/100;
    uint256 _newAmount = _realAmount - _charges;

    /**@notice transfer payment tokens to merchant and contract liquidity pool respectively*/
    /**@dev send fees to token liquidity pool*/
    paymentTokenType.transferFrom(msg.sender,address(this), _charges);
    bool _sent = paymentTokenType.transferFrom(msg.sender,_merchant, _newAmount);
    require(_sent,"Transaction failed! try again");
    emit Paid(_paymentReferenceID,msg.sender,_newAmount,_paymentTokenType);
    return (_paymentReferenceID,_newAmount,_paymentTokenType);
  }
  
  /**
   *@notice pauses contract functions
   *@dev only owner has access
   */
  function pauseContract()external onlyOwner
    {
        contractState = false;
    }

    /**
     *@notice continues contract functions
     *@dev only owner has access
     */
    function continueContract()external onlyOwner
    {
        contractState = true;
    }
}