/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

// File: contracts/Payment.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.5;


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

  function transfer(address to,uint256 amount) external returns (bool);
  


  function name() external view returns (string memory);
}

contract Payment {

    address owner;

    bool private contractState = true;

    uint256 public count;
    uint256 immutable decimals =10**18;
    uint256 private fee = 2;
    uint256 contractbal;


    error failed(string);
    error contract_paused();

    mapping(uint256 => address) merchantId;
    mapping(address => merchant) merchants;
    mapping(string =>address) public supportedTokens;

    event Paid(string paymentReferenceID,address _payer,uint256 amount, string _paymentTokenType);


    /**
    @notice merchants data
    @dev similar with an object, represents merchant
    */
    struct merchant
    {
        uint256 ID;
        uint256 transactionNumber;
        uint256 ethBalance;
        uint256 usdtBalance;
        uint256 daiBalance;
        address ethAddress;
        address usdtAddress;
        address daiAddress;     
    }

    /**
    @notice Will execute on deployment
    @dev initializes owner and owner stte variables
    */
    constructor( address _owner) {
        owner = _owner;
    }

    /**
    @notice modifier ensures only authorised merchant can access his data
    @param id merchants id
    */
    modifier onlyMerchant(uint256 id)
    {
      if(msg.sender != merchantId[id])
        {
            revert failed("Not_merchant");
        }
        _;
    }

    /**
    @notice modifier ensures its owner making the call
    */
    modifier onlyOwner
    {
        if(msg.sender != owner)
        {
            revert failed("Not Owner");
        }
        _;
    }

    /**
    @notice modifier checks if contract is paused
    */
    modifier state
    {
        if(contractState==false)
        {
            revert contract_paused(); /**paused("contract paused")*/
        }
        _;
    }


    function addToSupportedTokens(string memory _tokenName, address _tokenAddress) public state onlyOwner returns(string memory,address){
  supportedTokens[_tokenName]=_tokenAddress;
  return (_tokenName,_tokenAddress);

}


    /**
    @notice adds new merchant to contract
    @dev its assumed users can use the platform without perission from owner hence, no onlyOwner modifier
    @param receiveEth Ethereum address
    @param receiveUsdt Usdt address
    @param receiveDai Dai address
    */
    function addMerchant(address receiveEth, address receiveUsdt, address receiveDai)external state returns(string memory, uint256)
    {
        for(uint256 i = 0; i<=count;)
        {
            if(merchantId[i]==msg.sender)
            {
                revert failed("user exists");
            }
            unchecked{i++;}
        }
        if(receiveEth == address(0) || receiveUsdt == address(0) || receiveDai == address(0))
        {
            revert failed("invalid address");
        }
        count++;
        uint256 id = count;
        merchantId[id]= msg.sender;
        merchants[msg.sender]= merchant(id, 0, 0, 0,0, receiveEth, receiveUsdt, receiveDai);
        return ("your merhant id is", id); 
    }

    /**
    @notice changes merchants Eth address
    @param id merchants id
    @param addr new Eth address*/
    function changeEthAddress(uint256 id, address addr) external state onlyMerchant(id) returns(bool)
    {
        if(addr == address(0))
        {
            revert failed("invalid address");
        }
        merchants[msg.sender].ethAddress = addr;
        return true;
    }

    /**
    @notice changes merchants Usdt address
    @param id merchants id
    @param addr new Usdt address*/
    function changeUsdtAddress(uint256 id, address addr) external state onlyMerchant(id) returns(bool)
    {
        if(addr == address(0))
        {
            revert failed("invalid address");
        }
        merchants[msg.sender].usdtAddress = addr;
        return true;
    }

    /**
    @notice changes merchants dai address
    @param id merchants id
    @param addr new dai address*/
    function changeDaiAddress(uint256 id, address addr)external state onlyMerchant(id) returns(bool)
    {
        if(addr == address(0))
        {
            revert failed("invalid address");
        }
        merchants[msg.sender].daiAddress = addr;
        return true;
    }

    /**
    @notice shows the number of transactions a merchants has processed
    @param id merchants id
    */
    function numberOfTransactions(uint256 id)external view state returns(uint256, string memory)
    {
        return (merchants[merchantId[id]].transactionNumber, "Transactions");
    }
    
    //pay in Usdt
    function makePaymentUsdt(string memory _paymentReferenceID,uint256 _merchantId,uint256 _amount,string memory _paymentTokenType) external state returns(string memory paymentReferenceID,uint256 amount,string memory paymentToken) {
    uint256 _realAmount = _amount*decimals;

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
    contractbal += _charges;

    /**@notice transfer payment tokens to merchant and contract liquidity pool respectively*/
    /**@dev send fees to token liquidity pool*/
    merchants[merchantId[_merchantId]].usdtBalance += _newAmount;
    merchants[merchantId[_merchantId]].transactionNumber+=1;
    bool _sent = paymentTokenType.transferFrom(msg.sender,address(this), _realAmount);
    require(_sent,"Transaction failed! try again");
    emit Paid(_paymentReferenceID,msg.sender,_newAmount,_paymentTokenType);
    return (_paymentReferenceID,_newAmount,_paymentTokenType);
  }
  
  //pay in dai
   function makePaymentDai(string memory _paymentReferenceID,uint256 _merchantId,uint256 _amount,string memory _paymentTokenType) external state returns(string memory paymentReferenceID,uint256 amount,string memory paymentToken) {
    uint256 _realAmount = _amount*decimals;

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
    contractbal += _charges;

    /**@notice transfer payment tokens to merchant and contract liquidity pool respectively*/
    /**@dev send fees to token liquidity pool*/
    merchants[merchantId[_merchantId]].daiBalance += _newAmount;
    merchants[merchantId[_merchantId]].transactionNumber+=1;
    bool _sent = paymentTokenType.transferFrom(msg.sender,address(this), _realAmount);
    require(_sent,"Transaction failed! try again");
    emit Paid(_paymentReferenceID,msg.sender,_newAmount,_paymentTokenType);
    return (_paymentReferenceID,_newAmount,_paymentTokenType);
  }


  function withdrawUsdt(uint256 id, string calldata _paymentTokenType)external state onlyMerchant(id)
  {
    IERC20 paymentTokenType = IERC20(supportedTokens[_paymentTokenType]);
    uint256 _amount= merchants[merchantId[id]].usdtBalance;
    merchants[merchantId[id]].usdtBalance = 0;
     bool _sent = paymentTokenType.transfer(merchants[merchantId[id]].usdtAddress, _amount);
     require(_sent,"Transaction failed! try again");
  }

   function withdrawDai(uint256 id, string calldata _paymentTokenType)external state onlyMerchant(id)
  {
    IERC20 paymentTokenType = IERC20(supportedTokens[_paymentTokenType]);
     uint256 _amount= merchants[merchantId[id]].daiBalance;
    merchants[merchantId[id]].daiBalance = 0;
     bool _sent = paymentTokenType.transfer(merchants[merchantId[id]].daiAddress, _amount);
     require(_sent,"Transaction failed! try again");
  }

    /**
    @notice pauses contract functions
    @dev only owner has access
    */
    function pauseContract()external onlyOwner
    {
        contractState = false;
    }

    /**
    @notice continues contract functions
    @dev only owner has access
    */
    function continueContract()external onlyOwner
    {
        contractState = true;
    }


    function ownerWithdraw(string calldata _paymentTokenType)external onlyOwner
    {
        IERC20 paymentTokenType = IERC20(supportedTokens[_paymentTokenType]);
        uint256 bal = contractbal;
        contractbal=0;
        bool _sent =paymentTokenType.transfer(owner, bal);
         require(_sent ,"Transaction failed! try again");

    }



}