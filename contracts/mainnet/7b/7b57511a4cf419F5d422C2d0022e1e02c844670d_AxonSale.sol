// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AxonSale is Ownable{
  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////////////////////////
  event newSaleEvent(uint256 e_price, uint256 e_amount, uint256 e_time);
  event newBuyEvent(uint256 e_price, uint256 e_amount, uint256 e_total);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////////////////////////

  uint256 private s_currentPrice;
  uint256 private s_currentAmountToSale;
  uint256 private s_currentEndTime;
  uint256 private s_currentSold;

  uint256 private s_totalsold;

  IERC20 public immutable DAI_CONTRACT;
  IERC20 public s_axonTokenContract;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Constructor
  ////////////////////////////////////////////////////////////////////////////////////////////////// 

  constructor (address p_daiAddress) {
    DAI_CONTRACT = IERC20(p_daiAddress);    
  }

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Public functions
  //////////////////////////////////////////////////////////////////////////////////////////////////   

  // => View functions

  function getPrice() public view returns(uint256) {
    return s_currentPrice;
  }

  function getAmountPrice(uint256 p_amount) public view returns(uint256) {
    uint256 amountDai = (s_currentPrice / 1000000000000000) * p_amount;
    return amountDai / (1 ether / 1000000000000000);
  }

  function getAmountToSale() public view returns(uint256) {
    return s_currentAmountToSale;
  }

  function getAmountOnSale() public view returns(uint256) {
    return s_currentAmountToSale - s_currentSold;
  }

  function canBuy() public view returns(bool) {
    return (s_currentAmountToSale > s_currentSold) && (block.timestamp <= s_currentEndTime);
  }

  function getAmountSold() public view returns(uint256) {
    return s_currentSold;
  }

  function getTotalAmountSold() public view returns(uint256) {
    return s_totalsold;
  }

  function getTime() public view returns(uint256) {
    return s_currentEndTime;
  }

  function totalCurrentDai() public view returns(uint256) {
    return DAI_CONTRACT.balanceOf(address(this));
  }

  // => Set functions

  function setAxonToken(address p_axonToken) public onlyOwner returns(bool) {
    s_axonTokenContract = IERC20(p_axonToken);

    return true;
  }

  function newSale(uint256 p_price, uint256 p_amount, uint256 p_durationSeconds) public onlyOwner returns(bool) {
    require(block.timestamp > s_currentEndTime, "The previous sale has not yet ended");
    require(p_amount <= s_axonTokenContract.balanceOf(address(this)), "The contract does not have enough balance");
    require(p_price >= 1000000000000000, "Insufficient price");

    s_currentPrice = p_price;
    s_currentAmountToSale = p_amount;
    s_currentEndTime = block.timestamp + p_durationSeconds;
    delete s_currentSold;

    emit newSaleEvent(p_price, p_amount, block.timestamp + p_durationSeconds);

    return true;
  }

  function deleteSale() public onlyOwner returns(bool) {
    
    _deleteSale();
    return true;
  }

  function buyTokens(uint256 p_amount) public returns(bool) {
    require(block.timestamp <= s_currentEndTime, "The sale is over");
    require(s_currentSold + p_amount <= s_currentAmountToSale, "Cant buy more of total sale");

    uint256 amountDai = (s_currentPrice / 1000000000000000) * p_amount;
    amountDai = amountDai / (1 ether / 1000000000000000);

    s_currentSold += p_amount;
    s_totalsold += p_amount;

    require(DAI_CONTRACT.transferFrom(msg.sender, address(this), amountDai), "Failed Dai payment");
    require(s_axonTokenContract.transfer(msg.sender, p_amount), "Failed Axon transfer");

    emit newBuyEvent(s_currentPrice, p_amount, amountDai);

    return true;
  }

  function withdrawDai(address to) public onlyOwner returns(bool) {
    DAI_CONTRACT.transfer(to, DAI_CONTRACT.balanceOf(address(this)));

    return true;
  }

  function withdrawAxon() public onlyOwner returns(bool) {
    _deleteSale();
    s_axonTokenContract.transfer(msg.sender, s_axonTokenContract.balanceOf(address(this)));

    return true;
  }

  function _deleteSale() internal {
    delete s_currentPrice;
    delete s_currentAmountToSale;
    delete s_currentEndTime;
    delete s_currentSold;
  }

}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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