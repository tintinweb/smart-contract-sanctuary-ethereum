//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MessageReceiver is Ownable {
    address[] public secondaryValidators;

    // Received messages
    mapping(bytes32 => bool) public messages;

    /**
     * Checks primary and secondary validators signatures and
     * saves parameter 'message' in messages
     */
    function receiveMessage(
        bytes32 message,
        bytes memory primarySignature,
        bytes memory secondarySignature
    ) public {
        require(block.chainid == uint8(message[1]), "Unexpected destination chain ID");
        require(!messages[message], "Message already received");
        address recoveredPrimaryAddress = recoverSigner(message, primarySignature);
        require(owner() == recoveredPrimaryAddress, "Invalid primary validators signature");

        address recoveredSecondaryAddress = recoverSigner(message, secondarySignature);
        require(
            isValidSecondaryAddress(recoveredSecondaryAddress),
            "Invalid secondary validators signature"
        );

        messages[message] = true;
    }

    function addSecondaryValidator(address _secondaryValidator) public onlyOwner {
        secondaryValidators.push(_secondaryValidator);
    }

    function removeSecondaryValidator(uint index) public onlyOwner {
        require(secondaryValidators.length > 1, "Last secondary validator cannot be removed");
        secondaryValidators[index] = secondaryValidators[secondaryValidators.length - 1];
        secondaryValidators.pop();
    }

    function getSecondaryValidatorsLength() public view returns (uint length) {
        return secondaryValidators.length;
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        require(sig.length == 65, "Incorrect signature length");

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function isValidSecondaryAddress(address secondaryAddress) private view returns (bool) {
        for (uint i = 0; i < secondaryValidators.length; i++) {
            if (secondaryValidators[i] == secondaryAddress) {
                return true;
            }
        }
        return false;
    }

    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedMessage = keccak256(abi.encodePacked(prefix, message));
        return ecrecover(prefixedMessage, v, r, s);
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