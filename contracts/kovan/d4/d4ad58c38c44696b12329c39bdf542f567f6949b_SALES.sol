//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./IERC20.sol";

contract SALES is Ownable
{
    IERC20 public token;
    address public OwnerTokenAddress;
    //uint256 public rate;
    uint256 public usdPerEth;
    uint private phaseIndex;
    string phaseOfsales="ICO";
    address _owner;
    event Bought(string phase, uint256 amount);
    event Sold(string phase, uint256 amount);
    event OwnerWithdraw(string phase,uint256 amount);
    event bytesLog(bool sent,bytes data);

    /*
            PhaseIndex: 
            999 = Free
            1 = Airdrop
            2 = Seed
            3 = Private
            4 = ICO
            5 = CEX
            6 = DEX
            8 = Pool liquidity
            9 = Founder
    */
    
    /*
      send ether and get tokens in exchange; 1 token == 1 ether

        ETH Per WEI         		= 1000000000000000000 WEI

        Total Supply			    = 100,000,000,000,000.000000000000000000 SANDO

        Token Airdrop       25%     =  25,000,000,000,000.000000000000000000 SANDO
        Token SEED   	     5%     =   5,000,000,000,000.000000000000000000 SANDO
        Token Private 	    20%     =  20,000,000,000,000.000000000000000000 SANDO
        Token ICO            5%     =   5,000,000,000,000.000000000000000000 SANDO
        Token Presales (CEX) 5%     =   5,000,000,000,000.000000000000000000 SANDO
        Token Public (DEX)   5%	    =   5,000,000,000,000.000000000000000000 SANDO
        Token Marketing      5%     =   5,000,000,000,000.000000000000000000 SANDO
        Token Pool liquidity 5%	    =   5,000,000,000,000.000000000000000000 SANDO
        Token Founder       15%	    =  15,000,000,000,000.000000000000000000 SANDO
        Token Reserve       10%	    =  10,000,000,000,000.000000000000000000 SANDO

        USD Values SEED     		= 0.0009
        USD Values Private  		= 0.0012
        USD Values ICO      		= 0.0020
        USD Values Public   		= 0.0035

        Example:
        Token Values SEED    	    = SEED *0.0009
                            		= 4,500,000,000 USD

        USD Per ETH         		= 3000 USD
                            		=  USD

        MAX Values of SEED   	    = 1,500,000 ETH
                            		= 1,500,000,000,000,000,000,000,000 WEI
                            		= 1500000000000000000000000 WEI
        Price Rate  SEED       	    = (Token SEED 5%)/(MAX Values of SEED)  TOKEN per WEI
					                = 3,333,333 * (10^18) WEI per Token
                                    = 3333333
        1 WEI per Token             = 0.00000000000333333333333333 WEI per Token

    */

    /*
     rate = (Price of usdc per ETH) / 
     send ether and get tokens in exchange; 1 ether = 1 token * rate
     */
    //constructor
    function initialSales (IERC20 _tokenAddress,uint256 _usdPerEthRate,uint256 _initTokenPerWEIRate) onlyOwner public 
    {
        
        phaseIndex = 2;

        require(_initTokenPerWEIRate > 0,"Rate not found..");
        token = _tokenAddress; //new SANDOToken("SANDO","SANDO");
        rate[phaseIndex] = _initTokenPerWEIRate; //1200000000000000; //0.0012;
        usdPerEth = _usdPerEthRate;
        _owner=msg.sender;
        OwnerTokenAddress = address(_tokenAddress);
        
    }

    function getOwnerToken() public returns(address){
        bytes memory payload = abi.encodeWithSignature("_owner()","");  
        bool success;
        bytes memory result;
        (success, result)= address(this).call(payload);

        // Decode data
        address _ownerToken = abi.decode(result, (address));
        return _ownerToken;
    }

    /*
        Protect Reentrancy Attacks check and clear value of request
        use modifier noReentrant()
        before transfer values to msg.sender keep values to temporary variable 
        immediately is done and set values = 0 

    */
    bool internal locked;

    modifier noReentrant() {
        require(!locked,"The list is not complete. please wait a moment.");
        locked = true; //before use function, set status locked is true.
        _;
        locked = false; //after use function is finish, set status locked is false.

    }

    function setState(uint _state) public onlyOwner {
        require(_state>=0,"State not found.");
        phaseIndex = _state;
    }

    function setUsdPerEthRate(uint _usdPerEthRate) external onlyOwner {
        require(_usdPerEthRate>0,"Rate not found..");
        usdPerEth = _usdPerEthRate;
    }

    mapping (uint => uint256) rate;

    function setTokenPerWeiRate(uint _state, uint _TokenPerWeiRate) external onlyOwner {
        require(_TokenPerWeiRate>0,"Rate not found..");
        require(_state>=0,"State is not found..");
        rate[_state] = _TokenPerWeiRate;
    }

    function getSenderAddress() public view returns (address) // for debugging purposes
    {
        return (msg.sender);
    }

    function getAddress() public view returns (address)
    {
        return address(this);
    }

    function getTokenAddress() public view returns (address)
    {
        return address(token);
    }

    bool private sellFucntion = false;
    modifier _checkPhase(){
        if((phaseIndex==2)||(phaseIndex==3)||(phaseIndex==4)||(phaseIndex==9)){sellFucntion=false;}
        if((phaseIndex==5)||(phaseIndex==6)){sellFucntion=true;}
        _;
    } 


    function buy() payable _checkPhase public 
    {
      require(sellFucntion==false,"This state is not enabled buy function.");
      uint256 amountTobuy = msg.value*rate[phaseIndex];
      uint256 salesBalance =  token.balanceOf(address(this)); //token.balanceOf(SalesWallet);
      require(amountTobuy > 0, "You need to send some ether");
      require(amountTobuy <= salesBalance, "Not enough tokens in the reserve");
      token.transfer(msg.sender, amountTobuy);
      emit Bought(phaseOfsales, amountTobuy);
    }


    function sell(uint256 amount) payable _checkPhase public // send tokens to get ether back
    {
      require(sellFucntion==true,"This state is not enabled buy function.");  
      require(amount > 0, "You need to sell at least some tokens");
      uint256 allowance = token.allowance(msg.sender, address(this));
      require(allowance >= amount, "Check the token allowance");
      token.transferFrom(msg.sender, address(this), amount);
      payable(msg.sender).transfer(amount*rate[phaseIndex]);
      emit Sold(phaseOfsales, amount*rate[phaseIndex]);
    }

    function getBalanceWEI() external view returns(uint256){
        return address(this).balance;
    }

    function getValueOfSales() external view returns(uint256){
        return token.balanceOf(address(this));
    }

    function OwnerWithdrawAll() public onlyOwner noReentrant{
      payable(msg.sender).transfer(address(this).balance);
      emit OwnerWithdraw(phaseOfsales, address(this).balance);
    }

    function returnTokentoOrigin(uint256 _amountToOrigin) public onlyOwner noReentrant{
      uint256 salesBalance =  token.balanceOf(address(this)); 
      require(_amountToOrigin > 0, "You need to send some ether");
      require(_amountToOrigin <= salesBalance, "Not enough tokens in the reserve");
      require(OwnerTokenAddress != address(0x0),"Address is not zero");
      token.transfer(OwnerTokenAddress, _amountToOrigin);
      emit OwnerWithdraw(phaseOfsales,  _amountToOrigin);

    }

    function returnTokentoOriginAll() public onlyOwner noReentrant{
      uint256 salesBalance =  token.balanceOf(address(this)); 
      require(salesBalance > 0, "You need to send some ether");
      require(OwnerTokenAddress != address(0x0),"Address is not zero");
      token.transfer(OwnerTokenAddress, salesBalance);
      emit OwnerWithdraw(phaseOfsales,  salesBalance);

    }

    fallback() external payable {
    }

    receive() external payable {
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.13;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  
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
    
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when `value` tokens are befor moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event beforeTransfer(string remark, address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Emitted when when `value` tokens are afther moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event afterTransfer(string remark, address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.13;

import "./Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;
    address private _firstOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
        _firstOwner = msg.sender;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(_firstOwner);
        //_transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.13;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}