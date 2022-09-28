// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

interface INFT {
    function factoryMint(address _to, uint256 _numberOfTokens) external;
}

contract NFTFactory is Ownable {
    bool public saleIsEnalbed;
    bool public privateSaleIsEnabled;
    uint256 public price;
    uint256 public privateSalePrice;
    mapping(address => bool) public whitelist;
    uint256 public maxToMint = 20;
    INFT public nft;

    constructor(address _nft) {
        nft = INFT(_nft);
    }

    function setSaleStatus() external onlyOwner {
        saleIsEnalbed = !saleIsEnalbed;
    }

    function setPrivateSaleStatus() external onlyOwner {
        privateSaleIsEnabled = !privateSaleIsEnabled;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setPrivateSalePrice(uint256 _price) external onlyOwner {
        privateSalePrice = _price;
    }

    function setWhitelist(address[] calldata _addrs, bool _value) external onlyOwner {
        for (uint256 i = 0; i < _addrs.length; i++) {
            whitelist[_addrs[i]] = _value;
        }
    }

    function setMaxToMint(uint256 _value) external onlyOwner {
        maxToMint = _value;
    }

    function mint(address _to, uint256 _numberOfTokens) external payable {
        require(saleIsEnalbed, "Sale not enabled.");
        require(_numberOfTokens <= maxToMint, "Exceeded max.");
        require(price * _numberOfTokens == msg.value, "Ether value is not correct.");
        nft.factoryMint(_to, _numberOfTokens);
    }

    function privateMint(address _to, uint256 _numberOfTokens) external payable {
        require(privateSaleIsEnabled, "Private sale not enabled.");
        require(_numberOfTokens <= maxToMint, "Exceeded max.");
        require(whitelist[_to], "Not whitelisted");
        require(privateSalePrice * _numberOfTokens == msg.value, "Ether value is not correct.");
        nft.factoryMint(_to, _numberOfTokens);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
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