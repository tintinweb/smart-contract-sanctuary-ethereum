/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

// SPDX-License-Identifier: MIT
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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// File: contracts/Contract_Slp.sol



pragma solidity ^0.8.0;





contract Contract_SLP is Ownable {

    uint256 public Pool_Start_Time;
    uint256 public Pool_END_Time;

    //Address of house LP Tokens
    IERC20 public BhETH;
    IERC20 public BhWETH;
    IERC20 public BhWBTC;   
    IERC20 public Pool_2;

    string bheth = "bheth";
    string bhweth = "bhweth";
    string bhwbtc = "bhwbtc";
    string pool = "pool2";

    //depositable tokens
    IERC20 private T_WETH;
    IERC20 private T_WBTC;
    string Coin = "ETH";
    string token_1 = "WETH";
    string token_2 = "WBTC";

    uint public hl = 10;   //half_life
    address payable contr_pool2;  //pool_2_contract_address
    
    //PriceFeed
    address USD_ETH = 0x0bF499444525a23E7Bb61997539725cA2e928138;
    // address USD_BTC = address(0);//put mainnet address;
    
    constructor() {
        T_WETH = IERC20(0x89075B4a29528bF5Be015946C8C0d23C6A9fc9A3);
        //need to verify this add token
        T_WBTC = IERC20(0xfB237dF8e64e3cA51EEF9c80F4F1DFD9946Bf1e8);    //8 bit

        BhETH = IERC20(0xe658D02023Aa43657A16DdB351Da094D48008293);
        BhWETH = IERC20(0x094b836e141161c3c4B47320B0750ef530746c5A);
        BhWBTC = IERC20(0x25cF4021D33fe27143de128bb8c35B83b49D0caF);

        Pool_2 = IERC20(0x8dF9084935C4895D854b51cFC36CC9bb44114A7e);

        Pool_Start_Time = block.timestamp;
        Pool_END_Time = block.timestamp + 180 days;  //6 months
    }

    function update_ad_pool2(address _pl2) public onlyOwner{
        contr_pool2 = payable(_pl2);
    }

    mapping(address => mapping(string => uint256)) public _LP_User;
    mapping(address => mapping(string => uint256)) public _LP_Rec;


    function add_coin_liquidity() public payable {




    }

    function Check_Allowance(uint _pid) external view returns (uint){
        if(_pid == 1 ) return T_WBTC.allowance(msg.sender,address(this));
        if(_pid == 2 ) return T_WETH.allowance(msg.sender,address(this));
        if(_pid == 3 ) return Pool_2.allowance(contr_pool2,address(this));
        else{
            revert("Select Correct Option!!");
        }
    }

    function EmergencyPause() external onlyOwner{
        BhETH.transfer(msg.sender,BhETH.balanceOf(address(this)));
        BhWETH.transfer(msg.sender,BhWETH.balanceOf(address(this)));
        BhWBTC.transfer(msg.sender,BhWBTC.balanceOf(address(this))); 
        Pool_2.transfer(msg.sender,Pool_2.balanceOf(address(this)));
        T_WBTC.transfer(msg.sender,T_WBTC.balanceOf(address(this)));
        T_WETH.transfer(msg.sender,T_WETH.balanceOf(address(this)));
        (bool os, ) = payable(msg.sender).call{value : address(this).balance}("");
        require(os,"Failed!!");
    }

    function extract_balance(uint _pid) external onlyOwner view returns (uint){
        if(_pid == 1 ) return BhETH.balanceOf(address(this));
        if(_pid == 2 ) return BhWETH.balanceOf(address(this));
        if(_pid == 3 ) return BhWBTC.balanceOf(address(this));
        if(_pid == 4 ) return Pool_2.balanceOf(address(this)); 
        if(_pid == 5 ) return T_WBTC.balanceOf(address(this)); 
        if(_pid == 6 ) return T_WETH.balanceOf(address(this));
        if(_pid == 7 ) return address(this).balance;
        else{
            revert("Select Correct Option!!");
        }
    }

    function USD_ETH_c() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(USD_ETH);
        (,int price,,,) = priceFeed.latestRoundData();
        return uint256(price);
    }

    // function USD_BTC_c() public view returns (uint256) {
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(USD_BTC);
    //     (,int price,,,) = priceFeed.latestRoundData();
    //     return uint256(price);
    // }

    function LT_ETH() public view returns (uint256){
        uint256 Price = USD_ETH_c();
        uint256 USD_10k = (10000 * Price);
        return USD_10k;
    } 

    // function LT_WBTC() public view returns (uint256){
    //     uint256 Price = USD_BTC_c();
    //     uint256 USD_10k = (10000 * Price);
    //     return USD_10k;
    // } 

    receive() external payable {}

}