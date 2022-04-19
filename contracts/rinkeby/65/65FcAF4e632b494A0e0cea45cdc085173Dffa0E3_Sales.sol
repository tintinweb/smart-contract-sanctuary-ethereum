//SPDX-License-Identifier: MIT
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


contract Sales is Ownable
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

    constructor(IERC20 _tokenAddress,/*uint256 _usdPerEthRate,*/uint256 _initTokenPerUSDRate) public 
    {
        
        /*
            PhaseIndex: 
            0 = Private Seed Sales
            1 = ICO
            2 = CEX
            3 = DEX
        */
        phaseIndex = 0;

        require(_initTokenPerUSDRate > 0,"Rate not found..");
        token = _tokenAddress; //new SANDOToken("SANDO","SANDO");
        rate[phaseIndex] = _initTokenPerUSDRate; //1200000000000000; //0.0012;
        //usdPerEth = _usdPerEthRate;
        _owner=msg.sender;
        OwnerTokenAddress = address(_tokenAddress);
        
    }

    function getOwnerToken() public returns(address){
        bytes memory payload = abi.encodeWithSignature("_owner()","");  
        (bool success, bytes memory result)= address(this).call(payload);

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

    function setUsdPerEthRate(uint _usdPerEthRate) external onlyOwner {
        require(_usdPerEthRate>0,"Rate not found..");
        usdPerEth = _usdPerEthRate;
    }

    mapping (uint => uint256) rate;

    function setTokenPerWeiRate(uint _TokenPerWeiRate) external onlyOwner {
        require(_TokenPerWeiRate>0,"Rate not found..");
        rate[phaseIndex] = _TokenPerWeiRate;
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

    /*
      send ether and get tokens in exchange; 1 token == 1 ether

        ETH                 = 1000000000000000000 WEI
        ICO                 = 50000000000000000000000000000000 Token
        USD Values          = ICO *0.0168

        USD Per ETH         = 30947.9295115 USD
                            = 30948 USD

        MAX Values of ICO   = 840,000,000,000,000,000,000,000,000,000 ETH / (30948 USD/ETH)
                            = 27,142,365,038,923,292,172,175,270.72433 WEI
                            = 27,142,365.03892329217217527072433 WEI
        Price Rate          = 27142365 WEI Per TOKEN

        Input Token         = (Input amount SANDO Toeken) * 38774812713
        Values of Token     = WEI

    */

    /*
     rate = (Price of usdc per ETH) / 
     send ether and get tokens in exchange; 1 ether = 1 token * rate
     */
    function buy() payable public 
    {
      uint256 amountTobuy = msg.value*rate[phaseIndex];
      uint256 salesBalance =  token.balanceOf(address(this)); //token.balanceOf(SalesWallet);
      require(amountTobuy > 0, "You need to send some ether");
      require(amountTobuy <= salesBalance, "Not enough tokens in the reserve");
      token.transfer(msg.sender, amountTobuy);
      emit Bought(phaseOfsales, amountTobuy);
    }


    function sell(uint256 amount) public // send tokens to get ether back
    {
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