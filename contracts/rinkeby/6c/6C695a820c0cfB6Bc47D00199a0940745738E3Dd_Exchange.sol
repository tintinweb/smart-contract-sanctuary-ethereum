/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;


interface ISeraph {
    function checkEnter(address, bytes4, bytes calldata, uint256) external;
    function checkLeave(bytes4) external;
}

abstract contract SeraphProtected {

    ISeraph constant public seraph = ISeraph(0xfBCfDBf1d7105612280EB5b482366408b92922Ad);

    modifier withSeraph() {
        seraph.checkEnter(msg.sender, msg.sig, msg.data, 0);
        _;
        seraph.checkLeave(msg.sig);
    }

    modifier withSeraphPayable() {
        seraph.checkEnter(msg.sender, msg.sig, msg.data, msg.value);
        _;
        seraph.checkLeave(msg.sig);
    }
}

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
abstract contract Ownable is Context, SeraphProtected {
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
    function renounceOwnership() public virtual onlyOwner withSeraph{
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner withSeraph 
    {
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

// File: DEX/DEX.sol


pragma solidity ^0.8.2;


/**
*  Smart contract enabling funding and exchanging of DevCoin.
*  The rate is defined by the owner of the contract, but it will never be less than ICO price.
*  The price of token in ETH is 1/rate. Eg for 1 Eth the sender will get rate number of tokens.
*/
contract Exchange is Ownable {

  uint public ICO_RATE = 1000*1e18; // tokens for 1 eth
  uint public rate = 1000*1e18; // tokens for 1 eth
  IERC20 public token;

  event BuyToken(address user, uint amount, uint costWei, uint balance);
  event SellToken(address user, uint amount, uint costWei, uint balance);

  /**
  * constructor
  */
  constructor (address tokenContractAddr)  {
    token = IERC20(tokenContractAddr);
  }

  /**
  * Fallback function. Used to load the exchange with ether
  */
  receive () external payable {}

  /**
  * Sender requests to buy [amount] of tokens from the contract.
  * Sender needs to send enough ether to buy the tokens at a price of amount / rate
  */
  function buyToken(uint amount) payable public returns (bool success) {
    // ensure enough tokens are owned by the depositor
    uint costWei = (amount * 1 ether) / rate;
    require(msg.value >= costWei);
    assert(token.transfer(msg.sender, amount));
    emit BuyToken(msg.sender, amount, costWei, token.balanceOf(msg.sender));
    uint change = msg.value - costWei;
    if (change >= 1) payable(msg.sender).transfer(change);
    return true;
  }

  /**
  *  Sender requests to sell [amount] of tokens to the contract in return of Eth.
  */
  function sellToken(uint amount) public returns (bool success) {
    // ensure enough funds
    uint costWei = (amount * 1 ether) / rate;
    require(address(this).balance >= costWei);
    assert(token.transferFrom(msg.sender, address(this), amount));
    payable(msg.sender).transfer(costWei);
    emit SellToken(msg.sender, amount, costWei, token.balanceOf(msg.sender));
    return true;
  }

  function updateRate(uint newRate) onlyOwner withSeraph public returns (bool success) {
    // make sure rate is never less than ICO rate
    require(newRate >= ICO_RATE);
    rate = newRate;
    return true;
  }
}