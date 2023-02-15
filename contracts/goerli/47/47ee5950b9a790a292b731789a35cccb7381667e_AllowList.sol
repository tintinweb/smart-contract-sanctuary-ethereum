// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable2Step.sol";

/*
    The AllowList contract is used to manage a list of addresses and attest each address certain attributes.
    Examples for possible attributes are: is KYCed, is american, is of age, etc.
    One AllowList managed by one entity (e.g. tokenize.it) can manage up to 252 different attributes, and one tier with 5 levels, and can be used by an unlimited number of other Tokens.
*/
contract AllowList is Ownable2Step {
    /**
    @dev Attributes are defined as bit mask, with the bit position encoding it's meaning and the bit's value whether this attribute is attested or not. 
        Example:
        - position 0: 1 = has been KYCed (0 = not KYCed)
        - position 1: 1 = is american citizen (0 = not american citizen)
        - position 2: 1 = is a penguin (0 = not a penguin)
        These meanings are not defined within code, neither in the token contract nor the allowList. Nevertheless, the definition used by the people responsible for both contracts MUST match, 
        or the token contract will not work as expected. E.g. if the allowList defines position 2 as "is a penguin", while the token contract uses position 2 as "is a hedgehog", then the tokens 
        might be sold to hedgehogs, which was never the intention.
        Here some examples of how requirements can be used in practice:
        value 0b0000000000000000000000000000000000000000000000000000000000000101, means "is KYCed and is a penguin"
        value 0b0000000000000000000000000000000000000000000000000000000000000111, means "is KYCed, is american and is a penguin"
        value 0b0000000000000000000000000000000000000000000000000000000000000000, means "has not proven any relevant attributes to the allowList operator" (default value)

        The highest four bits are defined as tiers as follows (depicted with less bits because 256 is a lot):
        - 0b0000000000000000000000000000000000000000000000000000000000000000 = tier 0 
        - 0b0001000000000000000000000000000000000000000000000000000000000000 = tier 1 
        - 0b0011000000000000000000000000000000000000000000000000000000000000 = tier 2 (and 1)
        - 0b0111000000000000000000000000000000000000000000000000000000000000 = tier 3 (and 2 and 1)
        - 0b1111000000000000000000000000000000000000000000000000000000000000 = tier 4 (and 3 and 2 and 1)
        This very simple definition allows for a maximum of 5 tiers, even though 4 bits are used for encoding. By sacrificing some space it can be implemented without code changes.

     */
    mapping(address => uint256) public map;

    event Set(address indexed key, uint256 value);

    /**
    @notice sets (or updates) the attributes for an address
    */
    function set(address _addr, uint256 _attributes) external onlyOwner {
        map[_addr] = _attributes;
        emit Set(_addr, _attributes);
    }

    /**
    @notice purges an address from the allowList
    @dev this is a convenience function, it is equivalent to calling set(_addr, 0)
    */
    function remove(address _addr) external onlyOwner {
        delete map[_addr];
        emit Set(_addr, 0);
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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
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