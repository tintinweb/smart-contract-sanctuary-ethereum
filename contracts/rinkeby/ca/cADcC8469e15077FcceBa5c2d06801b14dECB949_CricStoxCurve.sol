/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.7.0;


// 
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

// 
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

// 
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// 
contract CricStoxCurve is Ownable {
    using SafeMath for uint256;

    mapping (uint256 => uint256) public price;
    address public adminWallet;
    uint8 public leastSignificantDigits;
    uint256 public priceSetTill = 0;
    uint256 public forzenPriceTill = 0;

    constructor(address adminWallet_, uint8 leastSignificantDigits_) {
        adminWallet = address(adminWallet_);
        transferOwnership(adminWallet);
        leastSignificantDigits = leastSignificantDigits_;
    }

    function lookupPrice(uint256 totalSupply) external view returns (uint256) {
        uint256 lookupValue = totalSupply.div(10**leastSignificantDigits);
        uint256 currentPrice = price[lookupValue];
        uint256 deltaPrice = price[lookupValue + 1].sub(price[lookupValue]);
        deltaPrice = deltaPrice.mul((totalSupply.sub(lookupValue.mul(10**leastSignificantDigits))).div(10**leastSignificantDigits));
        currentPrice = currentPrice.add(deltaPrice);
        return currentPrice;
    }

    function setPrice(uint256 startingTotalSupply, uint256[] memory prices) external onlyOwner {
        require(startingTotalSupply <= priceSetTill);
        require(startingTotalSupply >= forzenPriceTill);
        for ( uint8 i = 0; i < prices.length; i++ ) {
            price[startingTotalSupply + i] = prices[i];
        }
        uint256 endingTotalSupply = startingTotalSupply.add(prices.length);
        if (endingTotalSupply > priceSetTill) {
            priceSetTill = endingTotalSupply;
        }
    }

    function freezePrice() external onlyOwner {
        forzenPriceTill = priceSetTill;
    }
}