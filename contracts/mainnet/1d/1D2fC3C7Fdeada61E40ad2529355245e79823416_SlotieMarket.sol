// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface ISlotieAssetManager {
     function transferERC721(
        address asset,
        address sender,
        address recipient,
        uint256 tokenId
    ) external;
    function transferERC20(
        address asset,
        address sender,
        address recipient,
        uint256 amount
    ) external;
    function transferETH(
        address recipient,
        uint256 amount
    ) external payable;
}

contract SlotieMarket is Ownable, Pausable {
    using ECDSA for bytes32;

    /// +++++++++++++++++++++++++
    /// @notice STORAGE VARIABLES
    /// +++++++++++++++++++++++++

    ISlotieAssetManager public slotieAssetManager;

    /// @notice The accepted collections in the marketplace
    mapping(address => bool) public supportedCollections;

    /// @notice Maps a listing signature to its valid state
    mapping(bytes => bool) public isListingDropped;

    /// @notice Maps an offer signature to its valid state
    mapping(bytes => bool) public isOfferDropped;

    /// @notice Identifier used to identify listing signatures
    bytes32 public listingSignatureIdentifier = keccak256("SLOTIE-LISTING");

    /// @notice Identifier used to identify offer signatures
    bytes32 public offerSignatureIdentifier = keccak256("SLOTIE-OFFER");

    /// @notice Address of Slotie platform fee receiver
    address public platformFeeReceiver;

    /// @notice Platform fee multiplier denoted in 100_000
    uint256 public platformFeeMultiplier;

    address public WETH;

    /// ++++++++++++++
    /// @notice EVENTS
    /// ++++++++++++++

    /// @dev Emits when a listing is matched
    /// @param collection The nft collection
    /// @param seller The creator of the listing
    /// @param recipient The user matching the listing
    /// @param tokenId The token id of the listed nft
    /// @param expiration The expiration timestamp of the listing
    /// @param ethAmount The payment value of the NFT
    /// @param randomSalt The random salt used to create the listing signature
    /// @param signatureHash The hash of the listing signature
    event BoughtListing(
        address collection,
        address seller,
        address recipient,
        uint tokenId,  
        uint expiration,
        uint ethAmount, 
        bytes32 randomSalt,
        bytes32 signatureHash

    );

     /// @dev Emits when an offer is matched
    /// @param collection The nft collection
    /// @param seller The creator of the listing
    /// @param recipient The user matching the listing
    /// @param tokenId The token id of the listed nft
    /// @param expiration The expiration timestamp of the listing
    /// @param ethAmount The payment value of the NFT
    /// @param randomSalt The random salt used to create the offer signature
    /// @param signatureHash The hash of the listing signature
    event BidAccepted(
        address collection,
        address seller,
        address recipient,
        uint tokenId,
        uint expiration,
        uint ethAmount, 
        bytes32 randomSalt,
        bytes32 signatureHash
    );

    /// @dev Emits when a listing is dropped
    /// @param signatureHash The hash of the listing signature
    event Delist(
        bytes32 signatureHash
    );

    /// @dev Emits when an offer is dropped
    /// @param signatureHash The hash of the listing signature
    event WithdrawBid(
        bytes32 signatureHash
    );

    /**
     * @notice Constructor
     */
    constructor(
        address _weth,
        address _feeReceiver,
        uint256 _feeMultiplier,
        address slotie,
        address slotieJunior
    ) {
        WETH = _weth;
        platformFeeReceiver = _feeReceiver;
        platformFeeMultiplier = _feeMultiplier;
        supportedCollections[slotie] = true;
        supportedCollections[slotieJunior] = true;
    }

    /// ++++++++++++++++++++++++++++++
    /// @notice SIGNATURE VERIFICATION
    /// ++++++++++++++++++++++++++++++

    function createSignedMessage(bytes memory encodedData) internal pure returns (bytes32) {
        return keccak256(encodedData).toEthSignedMessageHash();
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    function requireValidListingSignature(
        address seller,
        address collectionIdentifier,
        uint tokenId,
        uint256 listingExpirationTimestamp,
        uint256 ethAmount,
        bytes32 randomSalt,
        bytes memory signature
    ) internal view {
        bytes32 message = createSignedMessage(
            abi.encodePacked(
                listingSignatureIdentifier,
                collectionIdentifier,
                tokenId,
                listingExpirationTimestamp,
                ethAmount,
                randomSalt
            )
        );
        address signer = recoverSigner(message, signature);
        require(signer == seller, "Invalid listing signature");
    }

    function requireValidOfferSignature(
        address buyer,
        address collectionIdentifier,
        uint tokenId,
        uint256 offerExpirationTimestamp,
        uint256 ethAmount,
        bytes32 randomSalt,
        bytes memory signature
    ) internal view {
        bytes32 message = createSignedMessage(
            abi.encodePacked(
                offerSignatureIdentifier,
                collectionIdentifier,
                tokenId,
                offerExpirationTimestamp,
                ethAmount,
                randomSalt
            )
        );
        address signer = recoverSigner(message, signature);
        require(signer == buyer, "Invalid offer signature");
    }


    /// ++++++++++++++
    /// @notice CHECKS
    /// ++++++++++++++

    /**
     * @notice Checks if a collection is supported in the marketplace
     *
     * @dev Reverts if collection is not supported
     *
     * @param collection An address representing the collection to check
     */
    modifier onlySupportedCollections(address collection) {
        require(supportedCollections[collection], "Collection not supported");
        _;
    }

    /// +++++++++++++++++++++++++
    /// @notice PRIVATE FUNCTIONS
    /// +++++++++++++++++++++++++
    
    /**
     * @notice Computes the royalty on an arbitrary token amount.
     *
     * @param value An integer representing the token value
     * @param multiplier An integer representing the royalty percentage
     *
     * @return royalty The royalty amount
     */
    function computeRoyalty(uint value, uint multiplier) private pure returns (uint) {
        return value * multiplier / 100_000;
    }

    /**
     * @notice Executes a payment of an accepted currency.
     *
     * @param collection An address representing the nft collection.
     * Used to determine royalties data
     * @param sender The address of the paying wallet
     * @param recipient The address of the receiving wallet
     * @param amount The transfer amount
     */
    function payWithWETHApplyingRoyalties(
        address collection,
        address sender, 
        address recipient, 
        uint amount 
    ) private {
        uint256 totalRoyalties;
        if (platformFeeMultiplier > 0) {
            uint256 platformAmount = computeRoyalty(amount, platformFeeMultiplier);
            slotieAssetManager.transferERC20(WETH, sender, platformFeeReceiver, platformAmount);
            totalRoyalties += platformAmount;
        }

        amount = amount - totalRoyalties;
        slotieAssetManager.transferERC20(WETH, sender, recipient, amount);
    }

    /**
     * @notice Executes a payment of eth.
     *
     * @param collection An address representing the nft collection.
     * Used to determine royalties data
     * @param recipient The address of the receiving wallet
     * @param amount The transfer amount
     */
    function payWithEthApplyingRoyalties(
        address collection, 
        address recipient, 
        uint amount
    ) private {
        uint256 totalRoyalties;
        if (platformFeeMultiplier > 0) {
            uint256 platformAmount = computeRoyalty(amount, platformFeeMultiplier);
            slotieAssetManager.transferETH{ value: platformAmount }(platformFeeReceiver, platformAmount);
            totalRoyalties += platformAmount;
        }

        amount = amount - totalRoyalties;
        slotieAssetManager.transferETH{ value: amount }(recipient, amount);
    }

    /// ++++++++++++++++++++++++++++
    /// @notice MANAGEMENT FUNCTIONS
    /// ++++++++++++++++++++++++++++

    /**
     * @notice Allows owner to change the paused state of the marketplace
     *
     * @param _isActive A boolean representing the paused state of the contract.
     */
    function setActive(bool _isActive) external onlyOwner {
        if (_isActive) {           
            Pausable._unpause();
        } else {
            Pausable._pause();
        }
    }

    function setSlotieAssetManager(address manager) external onlyOwner {
        require(manager != address(0), "Invalid address");
        require(address(slotieAssetManager) == address(0), "SlotieAssetManager already set");
        slotieAssetManager = ISlotieAssetManager(manager);
    }

    function setPlatformFeeReceiver(address receiver) external onlyOwner {
        require(receiver != address(0), "Invalid address");
        platformFeeReceiver = receiver;
    }

    function setPlatformFeeMultiplier(uint multiplier) external onlyOwner {
        require(multiplier <= 100_000, "Invalid multiplier");
        platformFeeMultiplier = multiplier;
    }

    /// ++++++++++++++++++++++++++++++
    /// @notice LISTINGS
    /// ++++++++++++++++++++++++++++++

    /**
     * @notice Allows a user to delist their NFT
     *
     * @param collectionIdentifier The address of the slotie or slotie junior collection    
     * @param tokenId The id of the nft being bought
     * @param listingExpirationTimestamp The timestamp where the listing are invalid
     * @param ethAmount The amounts of eth paid
     * @param randomSalt A random salt to prevent replay attacks
     * @param signature The listing signature
     */
    function delist(
        address collectionIdentifier,
        uint256 tokenId,
        uint256 listingExpirationTimestamp,
        uint256 ethAmount,
        bytes32 randomSalt,
        bytes memory signature
    ) external 
      whenNotPaused
    {
        /// @dev Checks
        require(!isListingDropped[signature], "Listing inactive");
        requireValidListingSignature(
            msg.sender,
            collectionIdentifier,
            tokenId,
            listingExpirationTimestamp,
            ethAmount,
            randomSalt,
            signature
        );
        
        /// @dev Effects
        isListingDropped[signature] = true;

        emit Delist(
            keccak256(signature)
        );
    }

    /**
     * @notice Allows a user to buy a listed NFT
     *
     * @dev Called by buyer
     *
     * @param collectionIdentifier The address of the NFT's collection
     * @param seller The address of the user created the listing
     * @param tokenId The id of the nft being bought
     * @param listingExpirationTimestamp The timestamp where the listing is invalid
     * @param ethAmount The amount of currency paid
     * @param randomSalt A random salt to prevent replay attacks
     * @param signature The listing signature
     */
    function buySingleListing(
        address collectionIdentifier,
        address seller,
        uint tokenId,
        uint256 listingExpirationTimestamp,
        uint256 ethAmount,
        bytes32 randomSalt,
        bytes memory signature
    ) public 
      payable 
      whenNotPaused 
      onlySupportedCollections(collectionIdentifier) {
        /// @dev Checks
        require(!isListingDropped[signature], "Listing inactive");
        require(msg.value >= ethAmount, "Insufficient payment");   
        require(listingExpirationTimestamp == 0 || listingExpirationTimestamp > block.timestamp, "Listing expired");               
        require(msg.sender != seller, "Cannot buy from self");
        requireValidListingSignature(
            seller,
            collectionIdentifier,
            tokenId,
            listingExpirationTimestamp,
            ethAmount,
            randomSalt,
            signature
        );

        /// @dev Effects
        isListingDropped[signature] = true;

        /// @dev Interactions
        payWithEthApplyingRoyalties(
            collectionIdentifier, 
            seller, 
            ethAmount 
        );
        slotieAssetManager.transferERC721(
            collectionIdentifier,
            seller,
            msg.sender, 
            tokenId
        );

        emit BoughtListing(
            collectionIdentifier, 
            seller,  
            msg.sender, 
            tokenId, 
            listingExpirationTimestamp,
            ethAmount,
            randomSalt,
            keccak256(signature)
        );
    }

    /// +++++++++++++++++++++++++
    /// @notice OFFERS
    /// +++++++++++++++++++++++++

    
    /**
     * @notice Allows a user to withdraw one or more bids
     *
     * @param collectionIdentifier The address of the NFT's collections
     * @param tokenId The ids of the nfts being bought
     * @param offerExpirationTimestamp The timestamps where the offers are invalid
     * @param ethAmount The amounts of currency paid
     * @param randomSalt A random salt to prevent replay attacks
     * @param signature The offer signatures
     */
    function withdrawBid(
        address collectionIdentifier,
        uint tokenId,
        uint256 offerExpirationTimestamp,
        uint256 ethAmount,
        bytes32 randomSalt,
        bytes memory signature
    ) external 
      whenNotPaused 
    {
        /// @dev Checks
        require(supportedCollections[collectionIdentifier], "Collection not supported");
        require(!isOfferDropped[signature], "Listing inactive");
        requireValidOfferSignature(
            msg.sender,
            collectionIdentifier,
            tokenId,
            offerExpirationTimestamp,
            ethAmount,
            randomSalt,
            signature
        );
        
        /// @dev Effects
        isOfferDropped[signature] = true;

        emit WithdrawBid(
            keccak256(signature)
        );
    }

    /**
     * @notice Allows a user to accept a bid on their NFT
     *
     * @dev Called by seller
     *
     * @param collectionIdentifier The address of the NFT's collection
     * @param buyer The address of the user that the offer
     * @param tokenId The id of the nft being bought
     * @param offerExpirationTimestamp The timestamp where the offer is invalid
     * @param ethAmount The amount of currency paid
     * @param randomSalt A random salt to prevent replay attacks
     * @param signature The offer signature
     */
    function acceptBid(
        address collectionIdentifier,
        address buyer,
        uint tokenId,
        uint256 offerExpirationTimestamp,
        uint256 ethAmount,
        bytes32 randomSalt,
        bytes memory signature
    ) external 
      whenNotPaused
      onlySupportedCollections(collectionIdentifier)
    {
        /// @dev Checks
        require(!isOfferDropped[signature], "Offer inactive");
        require(offerExpirationTimestamp == 0 || offerExpirationTimestamp > block.timestamp, "Offer expired");
        require(msg.sender != buyer, "Cannot buy from self");
        requireValidOfferSignature(
                buyer,
                collectionIdentifier,
                tokenId,
                offerExpirationTimestamp,
                ethAmount,
                randomSalt,
                signature
        );

        /// @dev Effects
        isOfferDropped[signature] = true;

        /// @dev Interactions
        payWithWETHApplyingRoyalties(
            WETH,
            buyer, 
            msg.sender, 
            ethAmount
         );

        slotieAssetManager.transferERC721(
            collectionIdentifier,
            msg.sender,
            buyer, 
            tokenId
        );

        emit BidAccepted(
            collectionIdentifier, 
            msg.sender,  
            buyer, 
            tokenId, 
            offerExpirationTimestamp,
            ethAmount,
            randomSalt,
            keccak256(signature)
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}