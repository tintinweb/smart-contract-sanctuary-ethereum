//SPDX-License-Identifier: MIT

/*

Skell-E-Mart Contract v1.0

*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IBones {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract SkellEMart is Ownable{
    
    struct Listing {
        uint256 price;
        uint256 supply;
    }

    IBones public Bones;

    address public marketAddress =  0xB15B530b35fBB9358DA3d60fbabc227887f8D591;

    mapping(string => Listing) public Listings;

    event Purchase(string discordId, address buyer);

//  ============= Functions =============

//  --------------- Admin ---------------

    function setListing(string memory _name, uint256 _price, uint256 _supply) public onlyOwner {
        Listings[_name].price = _price;
        Listings[_name].supply = _supply;
    }

    function setBonesContract (address _bones) public onlyOwner {
        Bones = IBones(_bones);
    }
    function setMarketAddress (address _market) public onlyOwner {
        marketAddress = _market;
    }

//  --------------- Public ---------------

    function buyItem(string memory _listing, string memory discordId) external {
        Bones.transferFrom(msg.sender, marketAddress, Listings[_listing].price);        
        Listings[_listing].supply = Listings[_listing].supply - 1;
        emit Purchase(discordId, msg.sender);
    }

    function getSupply(string memory _listing) public view returns (uint256) {
        return Listings[_listing].supply;
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