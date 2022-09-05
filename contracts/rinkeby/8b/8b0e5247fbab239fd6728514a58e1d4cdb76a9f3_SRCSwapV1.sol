/**
 *Submitted for verification at Etherscan.io on 2022-09-05
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
//    function renounceOwnership() public virtual onlyOwner {
//        _transferOwnership(address(0));
//    }

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

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: Vendor/ChainlinkPriceFeed.sol


pragma solidity ^0.8.4;
// Kovan鏈的 ETH / USD，priceFeed=0x9326BFA02ADD2366b30bacB125260Af641031331
// Rinkeby鏈的 USDC / USD，priceFeed=0xa24de01df22b63d23Ebc1882a5E3d4ec0d907bFB
// Rinkeby鏈的 DAI / USD	0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF


// [email protected] v1.0.2
abstract contract ChainlinkPriceFeed {

    AggregatorV3Interface private _priceFeed;

    constructor(address chainlinkPriceFeed) {
        _priceFeed = AggregatorV3Interface(chainlinkPriceFeed);        
    }
    
    // 設定新的查價地址
    function setChainlinkPriceFeed(address newAddress) public {
        _priceFeed = AggregatorV3Interface(newAddress);
    }

    // 查詢貨幣類型
    function getChainlinkDescription() public view returns (string memory) {
        return _priceFeed.description();
    }

    // 該報價的價格精度
    function getDecimals() internal view returns (uint8) {
        return _priceFeed.decimals();
    }

    // 當前貨幣的18位精度報價
    function getTokenPrice() internal view returns(uint256) {
        // 取報價
        (, int256 answer, , , ) = _priceFeed.latestRoundData();
        // 轉精度18位
        return uint256(answer) * (10 ** (18-getDecimals()));
    }

    // 該貨幣的美金價值 (精度18)
    function usdPerUSDT(uint256 amountOfUSDT) public view virtual returns (uint256 amountOfUSD) {               
        return getTokenPrice() * amountOfUSDT / (10 ** 18);         
    }

    // 單位美金可以買多少該貨幣 (精度18)
    function usdtPerUSD(uint256 amountOfUSD) public view virtual returns (uint256 amountOfToken) {               
        return (10 ** 18) * amountOfUSD / getTokenPrice() ;
    }   
}    
// File: ICQIERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ICQIERC20 {
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

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external; 
    

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external;

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);


    function mint(address to, uint256 amount) external;
}

// File: Vendor/SRCSwapV1.sol


pragma solidity ^0.8.4;

// import "../SnakeRiderCoin.sol";


// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


// [email protected] v1.0.7
contract SRCSwapV1 is Ownable, ChainlinkPriceFeed {

    ICQIERC20 srcToken;
    ICQIERC20 usdtToken;

    uint256 public usdPerSRC =    34000000000000000;
        
    event SwapSRCtoUSDT(address user, uint256 amountOfSRC, uint256 amountOfUSDT);    

    constructor(address srcTokenAddress, address usdtTokenAddress,address chainlinkPriceFeed ) ChainlinkPriceFeed(chainlinkPriceFeed){
        srcToken = ICQIERC20(srcTokenAddress);        
        usdtToken = ICQIERC20(usdtTokenAddress);
    }

    // 設定新的兌換價格
    function setUsdPerSRC(uint256 newPrice) public {
        usdPerSRC = newPrice;
    }

    // 一枚SRC可以換多少USDT，並經過CL的價格換算
    function usdtPerSRC() public view returns (uint256) {
        return ChainlinkPriceFeed.usdtPerUSD(usdPerSRC);        
    }

    // SRC與其他貨幣兌換的精度
    function _decimals() private pure returns (uint8) {
        return 18;
    }

    // 顯示SRC合約地址
    function showSRCAddress() public view returns (address) {
        return address(srcToken);
    }

    // 顯示USDT合約地址
    function showUSDTAddress() public view returns (address) {
        return address(usdtToken);
    }

    // 查詢 USDT餘額
    function balanceOfUSDT() public view returns(uint256) {
        uint256 vendorBalance = usdtToken.balanceOf(address(this)); 
        return vendorBalance;
    }

    // 查詢 MATIC餘額
    function balanceOfMATIC() public view returns(uint) {
        return address(this).balance;
    }

    // 從 SRC 兌換成 USDT (必須先通過SRC approve)
    function swapSRCtoUSDT(uint256 amountOfSRC) public returns (uint256 currentAmountOfUSDT) {
        require(amountOfSRC > 0, "Specify an amount of token greater than zero");

        uint256 userSRCBalance = srcToken.balanceOf(msg.sender);
        require(userSRCBalance >= amountOfSRC, "You have insufficient tokens");

        // SRC的美元價值，固定匯率 1SRC = 0.034USD 約 1TWD
        uint256 amountOfUSD = (10 ** usdtToken.decimals()) * amountOfSRC *  usdPerSRC / ( 10 **_decimals() ) /  (10 ** srcToken.decimals()) ; 
        // 美元價值轉換USDT數量
        currentAmountOfUSDT = ChainlinkPriceFeed.usdtPerUSD(amountOfUSD);
        // 檢查水庫資金是否足夠
        require(balanceOfUSDT() >= currentAmountOfUSDT, "Vendor has insufficient funds(USDT)");
        // 收走SRC (burn)
        srcToken.burnFrom(msg.sender, amountOfSRC);
        // 發送USDT
        (bool sentUSDT) = usdtToken.transfer(msg.sender, currentAmountOfUSDT);
        require(sentUSDT, "Failed to transfer tokens(USDT) from vendor to user");

        emit SwapSRCtoUSDT(msg.sender, amountOfSRC , currentAmountOfUSDT);

        return currentAmountOfUSDT;
    }  

    // 測試
    function test_swapSRCtoUSDT(uint256 amountOfSRC) public view returns (uint256 currentAmountOfUSDT) {
        require(amountOfSRC > 0, "Specify an amount of token greater than zero");

        uint256 userSRCBalance = srcToken.balanceOf(msg.sender);
        require(userSRCBalance >= amountOfSRC, "You have insufficient tokens");

        // SRC的美元價值，固定匯率 1SRC = 0.034USD 約 1TWD
        uint256 amountOfUSD = (10 ** usdtToken.decimals()) * amountOfSRC *  usdPerSRC / ( 10 **_decimals() ) /  (10 ** srcToken.decimals()) ; 
        // 美元價值轉換USDT數量
        currentAmountOfUSDT = ChainlinkPriceFeed.usdtPerUSD(amountOfUSD);

        return currentAmountOfUSDT;
    }
    
    // 提取MATIC
    function withdrawOfMATIC() public onlyOwner {
        uint256 ownerBalance = address(this).balance;
        require(ownerBalance > 0, "No MATIC present in Vendor");
        (bool sent,) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to withdraw");
    }

    // 提取 USDT
    function withdrawOfUSDT(uint256 amountOfUSDT) public onlyOwner {        
        uint256 ownerBalance = usdtToken.balanceOf(address(this));
        require(ownerBalance > amountOfUSDT, "Vendor has insufficient funds");        
        (bool sentUSDT) = usdtToken.transfer(owner(), amountOfUSDT);
        require(sentUSDT, "Failed to transfer tokens from user to vendor");
    }    


    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}    
}