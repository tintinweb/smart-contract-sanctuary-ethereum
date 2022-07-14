/**
 *Submitted for verification at Etherscan.io on 2022-07-12
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// File: @openzeppelin/contracts/interfaces/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;


// File: mcube.sol


pragma solidity ^0.8.0;



contract MFLIXSale is Ownable {
    mapping(address => uint256) private _balances;

    address public admin;
    address private mcubeAddress;
    address private tokenAddress;
    uint256 private _totalSold;
    uint256 private _preTotalSold;
    uint256 private _icoTotalSold;
    uint256 private pricePerToken;
    uint256 private pricePerBNB;
    uint256 private presaleAmount;
    uint256 private icosaleAmount;

    mapping(address => bool) whitelistedAddresses;
    mapping(address => bool) adminAddresses;

    uint256 public presaleStartTimestamp;
    uint256 public presaleEndTimestamp;
    uint256 public presalePriceDAI;
    uint256 public presalePriceBNB;


    constructor(address _admin,address _mcubeAddress,address _tokenAddress,uint256 _pricePerToken,uint256 _pricePerBNB, uint256 _presaleAmount, uint256 _icosaleAmount) {
        admin = _admin;
        mcubeAddress = _mcubeAddress;
        tokenAddress = _tokenAddress;
        pricePerToken = _pricePerToken;
        pricePerBNB = _pricePerBNB;
        presaleAmount = _presaleAmount;
        icosaleAmount = _icosaleAmount;
    }
  function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function setPriceToken(uint256 _price) public onlyOwner{
    pricePerToken = _price;
    }

    function getPriceToken() public view virtual returns (uint256){
        return pricePerToken;
    }

    function getPriceBNB() public view virtual returns (uint256){
        return pricePerBNB;
    }

    function setPriceBNB(uint256 _price) public onlyOwner{
    pricePerBNB = _price;
    }

    function getpresaleAmount () public view virtual returns (uint256){
        return presaleAmount;
    }

    function geticosaleAmount () public view virtual returns (uint256){
        return icosaleAmount;
    }

    function setpresaleAmount (uint256 _setpresaleAmount) public onlyOwner{
        presaleAmount = _setpresaleAmount;
    }

    function seticosaleAmount (uint256 _seticosaleAmount) public onlyOwner{
        icosaleAmount = _seticosaleAmount;
    }

    function totalSold () public view virtual returns (uint256){
        return _totalSold;
    }   

    function preTotalSold () public view virtual returns (uint256){
        return _preTotalSold;
    }

    function icoTotalSold () public view virtual returns (uint256){
        return _icoTotalSold;
    }

    function addAdminUser(address[] memory _addressAdmin) public onlyOwner {
        uint size = _addressAdmin.length;
        for(uint256 i=0; i< size; i++){
            address adminUser = _addressAdmin[i];
            adminAddresses[adminUser] = true;
        }
    }

    function verifyAdmin(address _addressAdmin) public view returns(bool) {
      bool adminIsWhitelisted = adminAddresses[_addressAdmin];
      return adminIsWhitelisted;
    }

    modifier onlyAdmin() {
      require(adminAddresses[msg.sender], "You are not a Admin.");
      _;
    }

    function setPreToken (uint256 _presaleStartTimestamp, uint256 _presaleEndTimestamp,uint256 _presalePriceDAI,uint256 _presalePriceBNB) public onlyOwner{  
      presaleStartTimestamp = _presaleStartTimestamp;
      presaleEndTimestamp = _presaleEndTimestamp;
      presalePriceDAI = _presalePriceDAI;
      presalePriceBNB = _presalePriceBNB;
    }

    function presaleBuyTokenWithDAI(uint256 amount) public onlyWhitelisted{  
      require(presaleStartTimestamp <= block.timestamp, "Presale starttime is over");
      require(presaleEndTimestamp >= block.timestamp, "Presale endtime is over");
      require(amount >= presalePriceDAI,"Amount should be greater than Price.");
      IERC20(tokenAddress).transferFrom(msg.sender, admin, amount);
      uint256 tokenAmount = amount / presalePriceDAI;
      require(presaleAmount >= tokenAmount * 10**uint(18),"Presale amount token is over."); 
      _totalSold += tokenAmount;
      _preTotalSold += tokenAmount;
      IERC20(mcubeAddress).transfer(msg.sender, tokenAmount * 10**uint(18));
    }

/*     function presaleBuyTokenWithBNB() public payable onlyWhitelisted{  
      require(presaleStartTimestamp <= block.timestamp, "Presale starttime is over");
      require(presaleEndTimestamp >= block.timestamp, "Presale endtime is over");
      require(msg.value > 0,"Amount should be greater than Zero.");
      uint256 tokenAmount = msg.value * presalePriceBNB;
      require(presaleAmount >= tokenAmount * 10**uint(18),"Presale amount token is over."); 
      _totalSold += tokenAmount;
      _preTotalSold += tokenAmount;
      IERC20(mcubeAddress).transfer(msg.sender, tokenAmount * 10**uint(18));
    } */

    function preSaleBuyTokenWithBNB() external payable onlyWhitelisted returns(uint256 amount){
      return preSaleTransferBNB(msg.value,msg.sender);
    } 
    function preSaleTransferBNB(uint256 _amount, address _sender) internal returns(uint256 _txAmount){
      require(presaleStartTimestamp <= block.timestamp, "Presale starttime is over");
      require(presaleEndTimestamp >= block.timestamp, "Presale endtime is over");
      require(_amount >0,"Amount should be greater than Zero.");
      uint tokenBuyAmount = _amount * presalePriceBNB;

        // checking the net balance
      uint netBalance = IERC20(mcubeAddress).balanceOf(address(this));
      require(netBalance > tokenBuyAmount,"Insufficient token balance.");
      require(presaleAmount >= tokenBuyAmount * 10**uint(18),"Pre Sale amount token is over."); 

      _totalSold += tokenBuyAmount;
        //transferring the required amount to sender
      bool transactionStatus = IERC20(mcubeAddress).transfer(_sender, tokenBuyAmount);

      require(transactionStatus,"Transaction failed.");

        // //transferring bnb to masterAccountAddess
      require(address(this).balance >= _amount,"Transaction balace has not replicated yet.");        
      payable(admin).transfer(_amount);

       // emit BuyGftUsingBNB(_sender, tokenBuyAmount, _amount);
      return tokenBuyAmount;
    }

    function buyTokenWithDAI (uint256 amount) public onlyWhitelisted{  
      require(amount>=pricePerToken,"Amount should be greater than Price.");  
      IERC20(tokenAddress).transferFrom(msg.sender,admin,amount);
      uint256 tokenAmount = amount / pricePerToken;
      require(icosaleAmount >= tokenAmount * 10**uint(18),"icosale amount token is over."); 
      _totalSold += tokenAmount;
      _icoTotalSold += tokenAmount;
      IERC20(mcubeAddress).transfer(msg.sender,tokenAmount * 10**uint(18));
    }

/*     function buyTokenWithBNB() payable public  onlyWhitelisted {  
      require(msg.value > 0,"Amount should be greater than Zero.");  
      uint256 tokenBuyAmount = msg.value * pricePerBNB;
      uint netBalance = mcubeAddress.balanceOf(address(this));
      require(netBalance > tokenBuyAmount,"Insufficient token balance.");
      require(icosaleAmount >= tokenBuyAmount * 10**uint(18),"icosale amount token is over."); 
      _totalSold += tokenBuyAmount;
      _icoTotalSold += tokenBuyAmount;
      IERC20(mcubeAddress).transfer(msg.sender,tokenBuyAmount * 10**uint(18));
      payable(admin).transfer(_amount);
    } */
    
    function buyTokenWithBNB() external payable onlyWhitelisted returns(uint256 amount){
      return transferBNB(msg.value,msg.sender);
    } 
    function transferBNB(uint256 _amount, address _sender) internal returns(uint256 _txAmount){
      require(_amount >0,"Amount should be greater than Zero.");
      uint tokenBuyAmount = _amount * pricePerBNB;

        // checking the net balance
      uint netBalance = IERC20(mcubeAddress).balanceOf(address(this));
      require(netBalance > tokenBuyAmount,"Insufficient token balance.");
      require(icosaleAmount >= tokenBuyAmount * 10**uint(18),"ico sale amount token is over."); 

      _totalSold += tokenBuyAmount;
        //transferring the required amount to sender
      bool transactionStatus = IERC20(mcubeAddress).transfer(_sender, tokenBuyAmount);

      require(transactionStatus,"Transaction failed.");

        // //transferring bnb to masterAccountAddess
      require(address(this).balance >= _amount,"Transaction balace has not replicated yet.");        
      payable(admin).transfer(_amount);

       // emit BuyGftUsingBNB(_sender, tokenBuyAmount, _amount);
      return tokenBuyAmount;
    }


    function withdrawToken (uint256 tokenAmount) external onlyOwner{   
        IERC20(mcubeAddress).transfer(msg.sender,tokenAmount);  
    }

    modifier isWhitelisted(address _address) {
      require(whitelistedAddresses[_address], "Whitelist: You need to be whitelisted");
      _;
    }

    modifier onlyWhitelisted() {
      require(whitelistedAddresses[msg.sender], "Whitelist: You need to be whitelisted");
      _;
    }

    function addWhitelistUser(address _addressToWhitelist) public onlyAdmin {
      whitelistedAddresses[_addressToWhitelist] = true;
    }

    function verifyUser(address _whitelistedAddress) public view returns(bool) {
      bool userIsWhitelisted = whitelistedAddresses[_whitelistedAddress];
      return userIsWhitelisted;
    }

    function batchWhitelist(address[] memory _addressToWhitelist) public onlyAdmin {
      uint size = _addressToWhitelist.length;
    
      for(uint256 i=0; i< size; i++){
          address user = _addressToWhitelist[i];
          whitelistedAddresses[user] = true;
      }
 }

}