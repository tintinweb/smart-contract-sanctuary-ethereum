// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAuthorizers.sol";

contract Authorizers is Ownable, IAuthorizers {
    struct Authorizer {
        uint256 index;
        bool isAuthorizer;
    }

    // mapping(address => bool) public authorizers;
    mapping(address => Authorizer) public authorizers;
    uint256 public authorizerCount = 0;
    uint256[] private vacatedAuthorizers;

    /**
     *@dev verify the signers address of a message
     *@param message - the the message that was signed
     *@param signature - the signature
     *@return address - the address of the signer
     */
    function recoverSigner(bytes32 message, bytes calldata signature)
        public
        pure
        returns (address)
    {
        require(signature.length == 65);
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);

        return ecrecover(message, v, r, s);
    }

    /**
     *@dev get the minimum signatures required to authorize a transaction
     *@return minimum number of signatures required
     */
    function minThreshold() public view returns (uint256) {
        if (authorizerCount < 3) return authorizerCount;
        uint256 i = authorizerCount / 3;
        uint256 r = authorizerCount % 3;
        if (r > 0) return (i * 2) + r;
        else {
            return i * 2;
        }
    }

    /**
     *@dev checks if parameters have the minimum number of required signatures
     *@param message - the message that is being authorized
     *@param signatures the concatenated signatures
     *@return bool - true if the message has been authorized, else false
     */
    function authorize(bytes32 message, bytes calldata signatures)
        external
        view
        override
        returns (bool)
    {
        require(signatures.length % 65 == 0, "Data not expected size");
        uint256 sigCount = signatures.length / 65;
        require(sigCount >= minThreshold(), "Sig count too low");
        bool[] memory used = new bool[](authorizerCount);
        for (uint256 x = 0; x < sigCount; x++) {
            //signature is x*65 starting index?
            //ends at start + 64
            uint256 index = x * 65;
            uint256 end = index + 65;

            address signer = recoverSigner(message, signatures[index:end]);
            //signer is an authorizer
            require(authorizers[signer].isAuthorizer, "Message Not Authorized");
            //This is authorizer is unique
            require(
                !used[authorizers[signer].index],
                "Duplicate Authorizer Used"
            );
            used[authorizers[signer].index] = true;
        }
        return true;
    }

    /**
     * @dev returns the message hash to be signed base on given parameters
     * @param _to - Address to the transaction is for
     * @param _amount - the Amount of tokens the transaction is for
     * @param _txid - The transaction Id of the Burn transaction on the 0Chain
     * @param _clientId - The ZCN clientID
     * @param _nonce - The nonce used in the signature
     * @return bytes32 - The Ethereum signature formatted hash
     */
    function messageHash(
        address _to,
        uint256 _amount,
        bytes calldata _txid,
        bytes calldata _clientId,
        uint256 _nonce
    ) external pure override returns (bytes32) {
        return
            prefixed(
                keccak256(
                    abi.encodePacked(_to, _amount, _txid, _clientId, _nonce)
                )
            );
    }

    /**
     *@dev the appends the ethereum signature prefix to the message hash
     *param hash - the hash of the message
     *return the prefixed message hash
     */
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    /**
     *@dev splits the signature into its component parts
     *param signature - the signature to split
     * returns v, r, s of the signature
     */
    function splitSignature(bytes memory signature)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        return (v, r, s);
    }

    /**
     *@dev adds an authorizer to the set of authorizers
     *@param newAuthorizer - the address of the authorizer to add
     */
    function addAuthorizers(address newAuthorizer) external onlyOwner {
        require(
            !authorizers[newAuthorizer].isAuthorizer,
            "Address is Already Authorizer"
        );
        if (vacatedAuthorizers.length > 0) {
            authorizers[newAuthorizer] = Authorizer(
                vacatedAuthorizers[vacatedAuthorizers.length - 1],
                true
            );
            vacatedAuthorizers.pop();
            authorizerCount += 1;
        } else {
            authorizers[newAuthorizer] = Authorizer(authorizerCount, true);
            authorizerCount += 1;
        }
    }

    /**
     *@dev removes an authorizer from the set of authorizers
     *@param _authorizer - the address of the authorizer to remove
     */
    function removeAuthorizers(address _authorizer) external onlyOwner {
        require(
            authorizers[_authorizer].isAuthorizer,
            "Address not an Authorizers"
        );
        authorizers[_authorizer].isAuthorizer = false;
        vacatedAuthorizers.push(authorizers[_authorizer].index);
        authorizerCount -= 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

library Message {
    struct Args {
        // The address to mint the tokens to
        address to;
        // The amount of tokens to mint
        uint256 amount;
        // The txid of the burn transaction on the 0chain
        bytes txid;
        // The ZCN client ID
        bytes clientId;
        // The burn nonce from ZCN used to sign the message
        uint256 nonce;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./Message.sol";

interface IAuthorizers {
    /**
     * @dev returns whether a message is authorized based on signatures
     * @param message - The message to be authorized
     * @param signatures - The signatures authorizing the message
     * @return boolean - True/False: The message is authorized?
     */
    function authorize(bytes32 message, bytes calldata signatures)
        external
        returns (bool);

    /**
     * @dev returns the message hash to be signed base on given parameters
     * @param _to - Address to the transaction is for
     * @param _amount - the Amount of tokens the transaction is for
     * @param _txid - The transaction Id of the Burn transaction on the 0Chain
     * @param _clientId - The ZCN clientID
     * @param _nonce - The nonce used in the signature
     * @return bytes32 - The Ethereum signature formatted hash
     */
    function messageHash(
        address _to,
        uint256 _amount,
        bytes calldata _txid,
        bytes calldata _clientId,
        uint256 _nonce
    ) external returns (bytes32);
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