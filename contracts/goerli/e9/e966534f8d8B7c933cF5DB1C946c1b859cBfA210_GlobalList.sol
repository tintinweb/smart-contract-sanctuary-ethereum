//SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.17;

import "./interfaces/IRule.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GlobalList is Ownable {
    mapping(address => bool) whitelist;
    mapping(address => bool) blacklist;

    event SetWhitelist(address[] indexed wallets, bool value);
    event SetBlacklist(address[] indexed wallets, bool value);

    constructor(address[] memory whitelist_, address[] memory blacklist_) {
        setWhitelist(whitelist_, true);
        setBlacklist(blacklist_, true);
        //to enable burning, zero address has to be whitelisted
        whitelist[address(0)] = true;
    }

    function isWhitelisted(address addr) external view returns (bool) {
        return whitelist[addr];
    }

    function isBlacklisted(address addr) external view returns (bool) {
        return blacklist[addr];
    }

    function setWhitelist(address[] memory whitelist_, bool value)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < whitelist_.length; i++) {
            whitelist[whitelist_[i]] = value;
        }
        emit SetWhitelist(whitelist_, value);
    }

    function setBlacklist(address[] memory blacklist_, bool value)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < blacklist_.length; i++) {
            blacklist[blacklist_[i]] = value;
        }
        emit SetBlacklist(blacklist_, value);
    }
}

//SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.17;


import "./IERC1404Wrapper.sol";


interface IRule is IERC1404Wrapper {
     /**
     * @dev Returns true if the restriction code exists, and false otherwise.
     */
     function canReturnTransferRestrictionCode(uint8 _restrictionCode)
        external
        view
        returns (bool);
}

//SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.17;

import "./IERC1404.sol";


interface IERC1404Wrapper is IERC1404 {
    /**
     * @dev Returns true if the transfer is valid, and false otherwise.
     */
    function validateTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (bool isValid);
}

//SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.17;


interface IERC1404 {
    /**
     * @dev See ERC-1404
     *
     */
    function detectTransferRestriction(
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (uint8);

    /**
     * @dev See ERC-1404
     *
     */
    function messageForTransferRestriction(uint8 _restrictionCode)
        external
        view
        returns (string memory);
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