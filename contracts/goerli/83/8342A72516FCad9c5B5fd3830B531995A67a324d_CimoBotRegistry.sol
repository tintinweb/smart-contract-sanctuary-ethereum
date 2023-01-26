// SPDX-License-Identifier: MIT

// https://github.com/CinnamoonToken/cinamoon-contracts/tree/main/contracts/CimoBotRegistry

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@cimolabs/contracts/CimoBotRegistry/ICimoBotRegistry.sol";

/**
 * @dev CimoBotRegistry provides the registry of known snipers and MEV bots.
 *
 * Registry is updated and maintained by Cinnamoon ($CIMO) team on a daily basis. 
 * Our scripts are analyzing the blockchain transactions, building a list of potential snipers/MEVs.
 * Every potential bot address is manually reviewed
 *
 * You can find more info on https://cinnamoon.cc/cimo-bot-registry
 * CimoBotRegistry is open source and free to use. 
 */

contract CimoBotRegistry is Ownable, ICimoBotRegistry {
    struct AddressInfo {
        address _address;
        bool flag;
    }


    mapping(address => bool) private _isSniper;
    mapping(address => bool) private _isMEV;

    /**
     * @dev Param _addresses is an array of the address and the flag.
     * If true it flags the address as a sniper
     * if false it flags the address as not a sniper
     */
    function setSnipers(AddressInfo[] memory _addresses) public onlyOwner {
        for (uint256 i; i < _addresses.length; i++) {
            _isSniper[_addresses[i]._address] = _addresses[i].flag;
            emit SniperUpdated(_addresses[i]._address, _addresses[i].flag);
        }
    }

    /**
     * @dev Param _addresses is an array of the address and the flag.
     * If true it flags the address as a MEV bot
     * if false it flags the address as not a MEV bot
     */
    function setMEVs(AddressInfo[] memory _addresses) public onlyOwner {
        for (uint256 i; i < _addresses.length; i++) {
            _isMEV[_addresses[i]._address] = _addresses[i].flag;
            emit MEVUpdated(_addresses[i]._address, _addresses[i].flag);
        }
    }

    /**
     * @dev Returns true if the address is Sniper
     */
    function isSniper(address _address) public view returns (bool) {
        return _isSniper[_address];
    }

    /**
     * @dev Returns true if the address is MEV bot
     */
    function isMEV(address _address) public view returns (bool) {
        return _isMEV[_address];
    }

    /**
     * @dev Returns true if the address is either Sniper or MEV bot
     */
    function isBot(address _address) public view returns (bool) {
        return _isSniper[_address] || _isMEV[_address];
    }
}

// SPDX-License-Identifier: MIT

// https://github.com/CinnamoonToken/cinamoon-contracts/tree/main/contracts/CimoBotRegistry

pragma solidity ^0.8.17;

/**
 * @dev ICimoBotRegistry provides the registry of known snipers and MEV bots.
 *
 * Registry is updated and maintained by Cinnamoon ($CIMO) team on a daily basis.
 * Our scripts are analyzing the blockchain transactions, building a list of potential snipers/MEVs.
 * Every potential bot address is manually reviewed
 *
 * You can find more info on https://cinnamoon.cc/cimo-bot-registry
 * CimoBotRegistry is open source and free to use.
 */

interface ICimoBotRegistry {

    /**
     * @dev Emitted when `_address` is flaged as Sniper
     * `_flag` === true, `_address` is added to Sniper list
     * `_flag` === false, `_address` is removed from Sniper list
     */
    event SniperUpdated(address _address, bool _flag);


    /**
     * @dev Emitted when `_address` is flaged as MEV bot
     * `_flag` === true, `_address` is added to MEV bots list
     * `_flag` === false, `_address` is removed from MEV bots list
     */
    event MEVUpdated(address _address, bool _flag);

    /**
     * @dev Returns true if the address is Sniper
     */
    function isSniper(address _address) external view returns (bool);

    /**
     * @dev Returns true if the address is MEV bot
     */
    function isMEV(address _address) external view returns (bool);

    /**
     * @dev Returns true if the address is either Sniper or MEV bot
     */
    function isBot(address _address) external view returns (bool);
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