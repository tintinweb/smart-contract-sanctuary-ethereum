//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface INFT {
    function mintSilver(address) external;

    function batchMintSilver(address[] memory) external;
}

contract Sale is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public sold;

    INFT public nft;

    mapping(address => Counters.Counter) private purchaseHistory;
    mapping(address => bool) public whitelist;

    uint256 private prePrice = 0.09 ether;
    uint256 private price = 0.12 ether;
    uint256 private soldLimit = 999;
    uint256 public preOpenTime = 1652443200; // 2022/05/13 21:00:00+09:00
    uint256 public openTime = 1652616000; // 2022/05/15 21:00:00+09:00

    constructor(address _nft) {
        nft = INFT(_nft);
    }

    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    modifier onlyWhitelist() {
        require(whitelist[_msgSender()], "only whitelist.");
        _;
    }

    function setWhitelist(address[] memory _addrs, bool _isWhitelist) external onlyOwner {
        for (uint256 i = 0; i < _addrs.length; i++) {
            whitelist[_addrs[i]] = _isWhitelist;
        }
    }

    modifier walletLimit(uint8 _amount) {
        for (uint8 i = 0; i < _amount; i++) {
            purchaseHistory[_msgSender()].increment();
        }
        require(purchaseHistory[_msgSender()].current() <= 2, "reached limit");
        _;
    }

    function setSetting(
        uint256 _prePrice,
        uint256 _price,
        uint256 _soldLimit,
        uint256 _preOpenTime,
        uint256 _openTime
    ) external onlyOwner {
        prePrice = _prePrice;
        price = _price;
        soldLimit = _soldLimit;
        preOpenTime = _preOpenTime;
        openTime = _openTime;
    }

    function buyPre(uint8 _amount) external payable onlyWhitelist walletLimit(_amount) {
        require(hasPreOpened(), "not opened");
        require(!hasOpened(), "closed");
        require(msg.value == prePrice * _amount, "invalid value");

        _mint(_amount);
    }

    function buy(uint8 _amount) external payable walletLimit(_amount) {
        require(hasOpened(), "not opened");
        require(msg.value == price * _amount, "invalid value");

        _mint(_amount);
    }

    function _mint(uint8 _amount) internal {
        require(_amount == 1 || _amount == 2, "invalid amount");
        require(sold.current() + _amount <= soldLimit, "sold out");

        sold.increment();
        if (_amount == 1) {
            nft.mintSilver(_msgSender());
        } else {
            sold.increment();

            address[] memory receivers = new address[](2);
            receivers[0] = _msgSender();
            receivers[1] = _msgSender();
            nft.batchMintSilver(receivers);
        }
    }

    function hasPreOpened() public view returns (bool) {
        return preOpenTime <= block.timestamp;
    }

    function hasOpened() public view returns (bool) {
        return openTime <= block.timestamp;
    }

    function remain() public view returns (uint256) {
        return soldLimit - sold.current();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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