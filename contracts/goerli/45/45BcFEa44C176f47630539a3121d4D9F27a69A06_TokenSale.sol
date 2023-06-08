/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

pragma solidity 0.5.12;

/*
-------------------------------------------------------------------------------------------------
TRQ Token Sale Smart Contract
-------------------------------------------------------------------------------------------------
*/


//*******************************************************************//
//------------------------ SafeMath Library -------------------------//
//*******************************************************************//
/**
    * @title SafeMath
    * @dev Math operations with safety checks that throw on error
    */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }
    uint256 c = a * b;
    require(c / a == b, 'SafeMath mul failed');
    return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, 'SafeMath sub failed');
    return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath add failed');
    return c;
    }
}


// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ITRC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//

contract owned {
    address payable public owner;
    address payable internal newOwner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //this flow is to prevent transferring ownership to wrong wallet by mistake
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        //emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}




//****************************************************************************//
//---------------------        MAIN CODE STARTS HERE     ---------------------//
//****************************************************************************//

contract TokenSale is owned {

    using SafeMath for uint256;
    bool public safeguard;  //putting safeguard on will halt all non-owner functions
   
    
    uint256 public totalsale;
    uint256 public tokenPrice =100;
    uint256 public _decimals = 6;
    
   
    mapping (address => uint256) public _balance;
    mapping (address => uint256) public _balanceFreeze;

    address public tokenContract;
    address public usdtaccountAddress;
    uint256 public usdtamt;

    
    event Buytoken(address buyer, uint256 tokenAmount);


    constructor(address _tokenContract) public {
        require(_tokenContract!=address(0),"Invalid Address");        
        tokenContract=_tokenContract;
    }

    //fallback function just accepts incoming TRX
    function() external payable{}


    //display current trx amount in smart contract
    function viewTRXinContract() external view returns(uint256){
        return address(this).balance;
    }

    /**
     * Returns decimals of token
     */
    function decimals() public view returns(uint256){
        return _decimals;
    }
     /**
     * Buy Tokens.
     */
    function buyTokens(uint256 _token) external returns(string memory){
        //checking for safeguard
        require(!safeguard, 'safeguard failed');
        
        
        uint256 usdtAmount = (_token * tokenPrice) / 1e6;       
        
        ITRC20(usdtaccountAddress).transferFrom(msg.sender, owner, usdtAmount);

        ITRC20(tokenContract).transfer(msg.sender,_token);
       
        //logging event and return_
        totalsale = totalsale.add(_token);
       
    	emit Buytoken(msg.sender,usdtAmount);	
        return ("tokens are bought successfully");

    }

    
    function changeDecimal(uint256 _dec) public onlyOwner returns(bool){
        require(_dec>0,"Invalid Amount Passed");
        _decimals=_dec;
        return true;
    }

    function changeUSDTaccountAddress(address _usdtaccountAddress) public returns(bool){
        usdtaccountAddress=_usdtaccountAddress;
        return true;
    }

     /**
        * Change safeguard status on or off
        *
        * When safeguard is true, then all the non-owner functions will stop working.
        * When safeguard is false, then all the functions will resume working back again!
        */
    function changeSafeguardStatus() external onlyOwner {
        if (safeguard == false){
            safeguard = true;
        }
        else{
            safeguard = false;
        }
    }
  
    /**
     * Change token price. It should be in 1 precision. means 10  = 1 TRX.
     */
     function changeTokenPrice(uint256 _tokenPrice) external onlyOwner returns(string memory){
         tokenPrice = _tokenPrice;
         return "Token price updated successfully";
     }
    

    /* function withdrawTRC20Token(address _tokenaddress,uint256 _amount) public onlyOwner returns(bool){
         require(_tokenaddress!=address(0),"Invalid Address");
         require(_amount>0,"Invalid Amount"); 
         ITRC20(_tokenaddress).transfer(msg.sender,_amount);
         return true;
     }
    */

    

     

}