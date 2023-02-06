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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IKEY3Validator {
    function validate(string memory name) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IKEY3Validator.sol";

contract KEY3Validator is IKEY3Validator, Ownable {
    mapping(IKEY3Validator => bool) public validatorMapping;
    IKEY3Validator[] public validators;
    mapping(bytes32 => bool) private _reserveds;

    function validate(string memory name_) public view returns (bool) {
        bytes32 hash = keccak256(bytes(name_));
        if (_reserveds[hash]) {
            return false;
        }
        for (uint i = 0; i < validators.length; i++) {
            IKEY3Validator validator = validators[i];
            if (
                address(validator) != address(0) && validatorMapping[validator]
            ) {
                if (!validator.validate(name_)) {
                    return false;
                }
            }
        }

        return true;
    }

    function addValidator(IKEY3Validator validator_) public onlyOwner {
        validatorMapping[validator_] = true;
        (bool exist, ) = _exists(validator_);
        if (!exist) {
            validators.push(validator_);
        }
    }

    function _exists(IKEY3Validator validator_)
        internal
        view
        returns (bool, uint)
    {
        for (uint i = 0; i < validators.length; i++) {
            if (validators[i] == validator_) {
                return (true, i);
            }
        }

        return (false, 0);
    }

    function removeValidator(IKEY3Validator validator_) public onlyOwner {
        validatorMapping[validator_] = false;
    }

    function addToReserveds(string[] memory names_) public onlyOwner {
        for (uint256 i = 0; i < names_.length; i++) {
            bytes32 hash = keccak256(bytes(names_[i]));
            _reserveds[hash] = true;
        }
    }

    function removeFromReserveds(string[] memory names_) public onlyOwner {
        for (uint256 i = 0; i < names_.length; i++) {
            bytes32 hash = keccak256(bytes(names_[i]));
            delete _reserveds[hash];
        }
    }
}