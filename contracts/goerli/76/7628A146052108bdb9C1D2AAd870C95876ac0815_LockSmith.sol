// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

interface Locksmither {
    function createOwnerMint721Key(
        address newOwner,
        string memory name,
        string memory symbol,
        string memory baseURL,
        bool soulbound
    ) external returns (address);

    function createVerifiedMint721Key(
        address newOwner,
        string memory name,
        string memory symbol,
        string memory baseURL,
        address verifiedSigner,
        uint256 mintPrice,
        uint256 maxPerUser,
        bool soulbound
    ) external returns (address);

    function createOwnerMint1155Key(
        address newOwner,
        string memory tokenName,
        string memory tokenSymbol,
        string memory baseURL,
        bool soulbound
    ) external returns (address);
}

contract LockSmith is Ownable {
    address private _owner721LockSmith;
    address private _verified721LockSmith;
    address private _owner1155LockSmith;

    constructor(
        address owner721LockSmith,
        address verified721LockSmith,
        address owner1155LockSmith
    ) {
        _owner721LockSmith = owner721LockSmith;
        _verified721LockSmith = verified721LockSmith;
        _owner1155LockSmith = owner1155LockSmith;
    }

    event NewKeyDeployed(address keyAddress, address owner);

    function createOwnerMint721Key(
        string memory name,
        string memory symbol,
        string memory baseURL,
        bool soulbound
    ) external returns (address newKey) {
        address key = Locksmither(_owner721LockSmith).createOwnerMint721Key(
            _msgSender(),
            name,
            symbol,
            baseURL,
            soulbound
        );

        emit NewKeyDeployed(key, _msgSender());
        return address(key);
    }

    function createVerifiedMint721Key(
        string memory name,
        string memory symbol,
        string memory baseURL,
        address verifiedSigner,
        uint256 mintPrice,
        uint256 maxPerUser,
        bool soulbound
    ) external returns (address newKey) {
        address key = Locksmither(_verified721LockSmith)
            .createVerifiedMint721Key(
                _msgSender(),
                name,
                symbol,
                baseURL,
                verifiedSigner,
                mintPrice,
                maxPerUser,
                soulbound
            );
        emit NewKeyDeployed(key, _msgSender());
        return address(key);
    }

    function createOwnerMint1155Key(
        string memory tokenName,
        string memory tokenSymbol,
        string memory baseURL,
        bool soulbound
    ) external returns (address newKey) {
        address key = Locksmither(_owner1155LockSmith).createOwnerMint1155Key(
            _msgSender(),
            tokenName,
            tokenSymbol,
            baseURL,
            soulbound
        );

        emit NewKeyDeployed(key, _msgSender());
        return address(key);
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