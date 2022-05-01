/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

/**
 *Submitted for verification at BscScan.com on 2022-03-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


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

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


pragma solidity ^0.8.0;

contract IgniteIDO is Ownable, ReentrancyGuard {
    IERC20 tokenAddress;
    // mainnet: 0x10ED43C718714eb63d5aA57B78B54704E256024E
    //testnet: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
    IUniswapV2Router02 routerAddress;

    address public idoAdmin;
    mapping (address => bool)subAdmins;
    address public lpTokenReceiver;
    address private burnAddress = 0x000000000000000000000000000000000000dEaD;
    mapping(address=>bool) isWhitelisted;

    // TODO: suggestion TokenPrice as it's similar to tokenPrice
    uint256 public TokenPrice; //How many tokens per base token e.g 1 BNB = n amount of tokens
    uint256 public _phase =0;
    uint256 public SOFTCAP;
    uint256 public HARDCAP;
    uint256 public minimumContribution = 1e16;
    uint256 public tokenPrice; // measured in tokenUnits,
    uint256 public paidSpots;
    uint256 public GweiCollected = 0; //Gwei or jager for ETH/BNB
    uint256 public maxAmount;
    uint256 public tokenDecimals;
    uint256 public liquidityToLock;
    uint256 private contributorNumber=0;
    uint256 currentWhitelistUsers;

    bool public isActive; // sets initial flag to false
    bool public marketOn;

    mapping(address => BuyersData) public Buyers;

    //depends on the decimals, e.g if token has 18 decimals the calculation can be done directly
    struct BuyersData {
        uint256 contribution;
        uint256 owedTokens;
    }

    constructor(
        IERC20 _tokenAddress,
        IUniswapV2Router02 _routerAddress,
        address payable _idoAdmin,
        address _lpTokenReceiver,
        uint256 _paidSpots,
        uint256 _maxAmount,
        uint256 _tokenDecimals,
        uint256 _softcap,
        uint256 _hardcap,
        uint256 _liquidityToLock,
        uint256 _tokenPrice
    )  {
        routerAddress = _routerAddress;
        lpTokenReceiver = _lpTokenReceiver;
        tokenAddress = _tokenAddress;
        tokenDecimals = _tokenDecimals;
        idoAdmin = _idoAdmin;
        paidSpots = _paidSpots;//whitelistSpots
        maxAmount = _maxAmount;
        SOFTCAP = _softcap;
        HARDCAP = _hardcap;
        liquidityToLock = _liquidityToLock;
        tokenPrice =_tokenPrice;
    }
       function addToAdmin(address newAddress)public onlyOwner{
        subAdmins[newAddress] = true;
    }

    

    function cancelSale() public onlyOwner {
        _phase = 4;
    }
    function cancelSaleAdmin()external {
        require(subAdmins[msg.sender],"Not an admin");
        _phase = 4;
    }
    function withdrawBaseToken() public{
        require(_phase == 4,"not a refund phase");
        address payable currentUser = payable(msg.sender);
        BuyersData storage _contributionInfo = Buyers[msg.sender];
        uint256 userContribution = _contributionInfo.contribution;
        require(userContribution>0,"Not contributed");
        currentUser.transfer(userContribution);
        _contributionInfo.contribution = 0;

        

    }
    function startWhitelistedPhase() external onlyOwner{
        _phase = 1;
    }
    function addToWhitelistOwner (address newUser)public onlyOwner{
        require(currentWhitelistUsers<=paidSpots,"No more whitelist spots");
        isWhitelisted[newUser]=true;
        currentWhitelistUsers+=1;
    }
       function addToWhitelistAdmin (address newUser) external{
        require(subAdmins[msg.sender],"Not an admin");
        require(currentWhitelistUsers<=paidSpots,"No more whitelist spots");
        isWhitelisted[newUser]=true;
        currentWhitelistUsers+=1;
    }
    function returnWhitelistUsers()public view returns(uint256){
        return currentWhitelistUsers;
    }
    function userDepositsWhitelist()public payable nonReentrant{//Phase =1 whitelist phase
    require(_phase == 1,"presale not open yet");
    require(isWhitelisted[msg.sender],"Not whitelisted");
    require(msg.value<=maxAmount,"Contribution needs to be in the minimum buy/max buy range");
    require(address(this).balance + msg.value<=HARDCAP);
    BuyersData storage _contributionInfo = Buyers[msg.sender];
    uint256 amount_in = msg.value;
    uint256 tokensSold = amount_in * tokenPrice;
    _contributionInfo.contribution += msg.value;
    require(_contributionInfo.contribution+msg.value<=maxAmount,"Cant contribute anymore");
    _contributionInfo.owedTokens += tokensSold;
    GweiCollected += amount_in;
    contributorNumber+=1;
}
 
    function _UserDepositPublicPhase() public payable nonReentrant {//Phase =2 public phase
        require(_phase==2,"Not on public _phase yet");
        //require(_phase == 1 && tokenAddress.balanceOf(msg.sender)>minimumHoldings, "This function is only callable in _phase 1");//only holders are able to participate in _phase 1
        //require(msg.value < maximumPurchase&& msg.value > minimumContribution,"One of the following parameters is incorrect:MinimumAmount/MaxAmount");
        BuyersData storage _contributionInfo = Buyers[msg.sender];
        uint256 amount_in = msg.value;
        uint256 tokensSold = amount_in * tokenPrice;
        _contributionInfo.contribution += msg.value;
        _contributionInfo.owedTokens += tokensSold;
        GweiCollected += amount_in;
        contributorNumber+=1;
    }

    
  function _returnContributors() public view returns(uint256){
      return contributorNumber;
  }
  function checkContribution(address contributor) public view returns(uint256){
      BuyersData storage _contributionInfo = Buyers[contributor];
      return _contributionInfo.contribution;
  }

    function _remainingContractTokens() public view returns (uint256) {
        return tokenAddress.balanceOf(address(this));
    }
    function returnTotalAmountFunded() public view returns (uint256){
        return GweiCollected;
    }
    function returnContractAddress() public view returns (address){
        return address(tokenAddress);
    }
    function updateContractAddress(IERC20 newToken) public onlyOwner{
        tokenAddress = IERC20(newToken);
    }

    function _returnPhase() public view returns (uint256) {
        return _phase;
    }
    function enablePublicPhase()public onlyOwner{
        require(marketOn==false,"cant change _phase market already started");
        _phase = 2;

    }
    function returnHardCap() public view returns(uint256){
        return HARDCAP;
    }
      function returnSoftCap() public view returns(uint256){
        return SOFTCAP;
    }
    function returnRemainingTokensInContract() public view returns(uint256){
        return tokenAddress.balanceOf(address(this));
    }

    function _startMarket() public onlyOwner {
    /*
    Approve balance required from this contract to pcs liquidity factory
    
    finishes ido status
    creates liquidity in pcs
    forwards funds to project creator
    forwards mcf fee to mcf wallet
    locks liquidity
    */
    require(address(this).balance >=SOFTCAP,"market cant start, softcap not reached");
    uint256 amountForLiquidity = (address(this).balance) *liquidityToLock/100;

    addLiquidity(amountForLiquidity);
    _phase = 3;
    marketOn = true;
    uint256 remainingBaseBalance = address(this).balance;
    payable(idoAdmin).transfer(remainingBaseBalance);


   
    }
      function transferUnsold() public onlyOwner{
        uint256 remainingCrowdsaleBalance = tokenAddress.balanceOf(address(this));
        tokenAddress.transfer(idoAdmin,remainingCrowdsaleBalance);
    }
    function ownerBaseTransfer(address payable destination) public onlyOwner{
        uint256 currentBalance = address(this).balance;
        payable(destination).transfer(currentBalance);
    }
  
    
    function burnUnsold() public onlyOwner{
        uint256 remainingCrowdsaleBalance = tokenAddress.balanceOf(address(this));
        tokenAddress.transfer(burnAddress,remainingCrowdsaleBalance);
    }

    //Contract shouldnt accept bnb/eth/etc thru fallback functions, pending implementation if its the opposite
    receive() external payable {
        //NA
    }

    function _lockLiquidity() internal {
        /*liquidity Forwarder
pairs reserved amount and bnb to create liquidity pool
*/
    }

    function withdrawTokens() public {
        //uint256 currentTokenBalance = tokenAddress.balanceOf(address(this));
        BuyersData storage buyer = Buyers[msg.sender];
        require(_phase == 3 , "not ready to claim");
        uint256 tokensOwed = buyer.owedTokens;
        require(
            tokensOwed > 0,
            "No tokens to be transfered or contract empty"
        );
        tokenAddress.transfer(msg.sender, tokensOwed);
        buyer.owedTokens = 0;
    }

    function addLiquidity(uint256 bnbAmount) public onlyOwner {
        //uint256 amountOfBNB = address(this).balance;
        uint256 amountOFTokens = tokenAddress.balanceOf(address(this));

        IERC20(tokenAddress).approve(address(routerAddress), amountOFTokens);

        (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        ) = IUniswapV2Router02(routerAddress).addLiquidityETH{
                value: bnbAmount
            }(
                address(tokenAddress),
                amountOFTokens,
                0,
                0,
                lpTokenReceiver,
                block.timestamp + 1200
            );
    }
}