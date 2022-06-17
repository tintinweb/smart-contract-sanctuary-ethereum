// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/**
 * WEDREAM ESCROW CONTRACT
 * Learn more about this Project on https://auction.wedream.world/
 */

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./BidValidator.sol";
import "./LibBid.sol";


contract WedreamEscrow is BidValidator, IERC721Receiver, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter public tokenRegistryId;

    uint256 public withdrawalLockedUntil;
    uint256 public auctionStartsAt;
    uint256 public auctionEndsAt;
    uint256 public escrowSharePercentage;

    mapping(uint256 => TokenRegistryEntry) public tokenRegistry;
    mapping(address => uint256[]) public tokenIdsByAddress;
    mapping(address => uint256) public tokenCountByAddress;

    struct TokenRegistryEntry {
        address tokenContract;
        uint256 tokenIdentifier;
        address tokenOwner;
        uint256 minimumPrice;
    }

    // Events
    event TokenWithdrawal(
        uint256 tokenRegistryId,
        address tokenContract,
        uint256 tokenIdentifier,
        address withdrawalInitiator,
        address withdrawalReceiver
    );

    event MinmumPriceChange(
        uint256 tokenRegistryId,
        uint256 oldMiniumPrice,
        uint256 newMiniumPrice,
        address priceChanger
    );

    event FulfillBid(
        uint256 tokenRegistryId,
        address tokenContract,
        uint256 tokenIdentifier,
        address tokenReceiver,
        uint256 minimumPrice,
        uint256 paidAmount
    );

    constructor() public {
        ESCROW_WALLET = 0x901E0FDaf9326A7B962793d2518aB4cC6E4FeF04;
        escrowSharePercentage = 250;
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}. Also registers token in our TokenRegistry.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address, // operator not required
        address tokenOwnerAddress,
        uint256 tokenIdentifier,
        bytes memory
    ) public virtual override returns (bytes4) {
        tokenRegistryId.increment();
        tokenRegistry[tokenRegistryId.current()] = TokenRegistryEntry(
            msg.sender,
            tokenIdentifier,
            tokenOwnerAddress,
            0
        );
        tokenIdsByAddress[tokenOwnerAddress].push(tokenRegistryId.current());
        tokenCountByAddress[tokenOwnerAddress]++;
        return this.onERC721Received.selector;
    }

    /**
     * @dev Function withdrawal a specific token from the registry.
     * Requirements:
     * - Token must be owned by this contract.
     * - Token was owned by msg.sender before.
     * - It is allowed to withdrawal tokens at this moment.
     *
     * @param _tokenRegistryId Id in the token registry
     * @param _tokenContract ERC721 Contract Address
     * @param _tokenIdentifier Identifier of token on the contract
     */
    function withdrawalToken(
        uint256 _tokenRegistryId,
        address _tokenContract,
        uint256 _tokenIdentifier
    ) public virtual {
        require(
            tokenRegistry[_tokenRegistryId].tokenOwner == msg.sender,
            "WedreamEscrow: Invalid Sender"
        );

        require(
            tokenRegistry[_tokenRegistryId].tokenIdentifier ==
                _tokenIdentifier &&
                tokenRegistry[_tokenRegistryId].tokenContract == _tokenContract,
            "WedreamEscrow: Invalid Registry Entry"
        );

        require(
            (block.timestamp < auctionStartsAt ||
                withdrawalLockedUntil < block.timestamp),
            "WedreamEscrow: Withdrawal currently not allowed"
        );

        transferToken(
            tokenRegistry[_tokenRegistryId].tokenContract,
            tokenRegistry[_tokenRegistryId].tokenIdentifier,
            tokenRegistry[_tokenRegistryId].tokenOwner
        );

        emit TokenWithdrawal(
            _tokenRegistryId,
            tokenRegistry[_tokenRegistryId].tokenContract,
            tokenRegistry[_tokenRegistryId].tokenIdentifier,
            msg.sender,
            tokenRegistry[_tokenRegistryId].tokenOwner
        );

        delete tokenRegistry[_tokenRegistryId];
    }

    /**
     * @dev Function to set the token on sale and add a minimum price. Tokens
     * with minimum Price 0 are not allowed to be sold.
     *
     * Requirements:
     * - `msg.sender` needs to be owner of token in our registry
     * - Withdrawals are allowed / Auction is not running
     *
     * @param _tokenRegistryId Id in the token registry
     * @param _tokenContract ERC721 Contract Address
     * @param _tokenIdentifier Identifier of token on the contract
     * @param minimumPrice New minimum price in wei
     */
    function setMinimumPrice(
        uint256 _tokenRegistryId,
        address _tokenContract,
        uint256 _tokenIdentifier,
        uint256 minimumPrice
    ) external {
        require(
            tokenRegistry[_tokenRegistryId].tokenOwner == msg.sender,
            "WedreamEscrow: Invalid Sender"
        );
        require(
            tokenRegistry[_tokenRegistryId].tokenIdentifier ==
                _tokenIdentifier &&
                tokenRegistry[_tokenRegistryId].tokenContract == _tokenContract,
            "WedreamEscrow: Invalid Registry Entry"
        );
        require(
            (block.timestamp < auctionStartsAt ||
                withdrawalLockedUntil < block.timestamp),
            "WedreamEscrow: Minimum Price Change is currently not allowed"
        );

        uint256 oldPrice = tokenRegistry[_tokenRegistryId].minimumPrice;
        tokenRegistry[_tokenRegistryId].minimumPrice = minimumPrice;

        emit MinmumPriceChange(
            _tokenRegistryId,
            oldPrice,
            minimumPrice,
            msg.sender
        );
    }

    /**
     * @dev Function to set the token on sale and add a minimum price. Tokens
     * with minimum Price 0 are not allowed to be sold. This is a Emergency Function.
     *
     * Requirements:
     * - `msg.sender` needs to admin of contract
     *
     * @param _tokenRegistryId Id in the token registry
     * @param _tokenContract ERC721 Contract Address
     * @param _tokenIdentifier Identifier of token on the contract
     * @param minimumPrice New minimum price in wei
     */
    function adminSetMinimumPrice(
        uint256 _tokenRegistryId,
        address _tokenContract,
        uint256 _tokenIdentifier,
        uint256 minimumPrice
    ) external onlyOwner {
        require(
            tokenRegistry[_tokenRegistryId].tokenIdentifier ==
                _tokenIdentifier &&
                tokenRegistry[_tokenRegistryId].tokenContract == _tokenContract,
            "WedreamEscrow: Invalid Registry Entry"
        );

        uint256 oldPrice = tokenRegistry[_tokenRegistryId].minimumPrice;
        tokenRegistry[_tokenRegistryId].minimumPrice = minimumPrice;

        emit MinmumPriceChange(
            _tokenRegistryId,
            oldPrice,
            minimumPrice,
            msg.sender
        );
    }

    /**
     * @dev Function to change the Auction Period and withdrawal Locking
     * Requirements:
     * - `msg.sender` needs to admin of contract
     * - Dates must be in right order _auctionStartsAt < _auctionEndsAt < _withdrawalLockedUntil
     *
     * @param _auctionStartsAt Timestamp when auction starts (no minimum price changes, no withdrawals)
     * @param _auctionEndsAt Timestamp when auction ends (earlierst when the bids can be fulfilled)
     * @param _withdrawalLockedUntil Timestamp until when previous token owner withdrawal and minimum price changes are not possible
     */
    function adminChangePeriods(
        uint256 _auctionStartsAt,
        uint256 _auctionEndsAt,
        uint256 _withdrawalLockedUntil
    ) external onlyOwner {
        require(
            (_auctionStartsAt < _auctionEndsAt && _auctionEndsAt < _withdrawalLockedUntil),
            "WedreamEscrow: Invalid dates order"
        );
        auctionStartsAt = _auctionStartsAt;
        auctionEndsAt = _auctionEndsAt;
        withdrawalLockedUntil = _withdrawalLockedUntil;
    }

    /**
     * @dev Function to change the escrow share percentage
     *
     * Requirements:
     * - `msg.sender` needs to admin of contract
     * - _escrowSharePercentage can't be more than 10000 (=100%)
     * @param _escrowSharePercentage basis points of share that is sent to the contract owner, default: 250 (=2.5%)
     */
    function adminChangeEscrowSharePercentage(
        uint256 _escrowSharePercentage
    ) external onlyOwner {
        require(
            (_escrowSharePercentage <= 10000),
            "WedreamEscrow: Invalid share percentage (> 10000)"
        );
        escrowSharePercentage = _escrowSharePercentage;
    }

    /**
     * @dev ESCROW_WALLET is used to verify bids integrity. With this function the owner can change it.
     *
     * Requirements:
     * - `msg.sender` needs to admin of contract
     *
     * @param _escrow_wallet Public Address of Signer Wallet
     */
    function adminChangeEscrowWallet(
        address _escrow_wallet
    ) external onlyOwner {
        ESCROW_WALLET = _escrow_wallet;
    }

    /**
     * @dev Withrawal all Funds sent to the contract to Owner.
     * Should never happen but just in case...
     *
     * Requirements:
     * - `msg.sender` needs to be Owner and payable
     */
    function adminWithdrawalEth() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    /**
     * @dev Emergency Admin function to withdrawal a specific token from the registry.
     * Requirements:
     * - Token must be owned by this contract.
     * - msg.sender is owner.
     *
     * @param _tokenRegistryId Id in the token registry.
     * @param _tokenContract ERC721 Contract Address
     * @param _tokenIdentifier Identifier of token on the contract
     */
    function adminWithdrawalToken(
        uint256 _tokenRegistryId,
        address _tokenContract,
        uint256 _tokenIdentifier
    ) public virtual onlyOwner {
        require(
            tokenRegistry[_tokenRegistryId].tokenIdentifier ==
                _tokenIdentifier &&
                tokenRegistry[_tokenRegistryId].tokenContract == _tokenContract,
            "WedreamEscrow: Invalid Registry Entry"
        );

        transferToken(
            tokenRegistry[_tokenRegistryId].tokenContract,
            tokenRegistry[_tokenRegistryId].tokenIdentifier,
            tokenRegistry[_tokenRegistryId].tokenOwner
        );

        emit TokenWithdrawal(
            _tokenRegistryId,
            tokenRegistry[_tokenRegistryId].tokenContract,
            tokenRegistry[_tokenRegistryId].tokenIdentifier,
            msg.sender,
            tokenRegistry[_tokenRegistryId].tokenOwner
        );

        delete tokenRegistry[_tokenRegistryId];
    }

    /**
     * @dev Function for auction winner to fulfill the bid. Token is exchanged with ETH minus {escrowSharePercentage} fee
     * Requirements:
     * - minimumPrice needs to be more than 0
     * - ETH send must match the bid value
     * - transaction needs to be sent by the bidder wallet
     * - TokenContract and TokenIdentifier has to match our TokenRegistryEntry
     * - Auction must have ended
     *
     * @param acceptedBidSignature id in the token registry signed by ESCROW_WALLET
     * @param bidData Struct of Bid
     */
    function fulfillBid(
        bytes memory acceptedBidSignature,
        LibBid.Bid memory bidData
    ) public payable {

        require(
            tokenRegistry[bidData.tokenRegistryId].minimumPrice > 0,
            "WedreamEscrow: Token is not on Sale"
        );
        require(
            msg.value >= tokenRegistry[bidData.tokenRegistryId].minimumPrice,
            "WedreamEscrow: Reserve Price not met"
        );
        require(
            msg.value == bidData.amount,
            "WedreamEscrow: Amount send does not match bid"
        );
        require(
            msg.sender == bidData.winnerWallet,
            "WedreamEscrow: Wrong Wallet"
        );
        require(
            tokenRegistry[bidData.tokenRegistryId].tokenContract ==
                bidData.tokenContract,
            "WedreamEscrow: Mismatch of Token Data (Contract)"
        );
        require(
            tokenRegistry[bidData.tokenRegistryId].tokenIdentifier ==
                bidData.tokenIdentifier,
            "WedreamEscrow: Mismatch of Token Data (Identifier)"
        );

        require(
            (auctionEndsAt < block.timestamp),
            "WedreamEscrow: Auction still running"
        );

        validateBid(bidData, acceptedBidSignature);

        uint256 totalReceived = msg.value;
        uint256 escrowPayout = (totalReceived * escrowSharePercentage) / 10000;
        uint256 ownerPayout = totalReceived - escrowPayout;
        payable(owner()).transfer(escrowPayout);
        payable(tokenRegistry[bidData.tokenRegistryId].tokenOwner).transfer(ownerPayout);


        transferToken(
            tokenRegistry[bidData.tokenRegistryId].tokenContract,
            tokenRegistry[bidData.tokenRegistryId].tokenIdentifier,
            msg.sender
        );

        emit FulfillBid(
            bidData.tokenRegistryId,
            tokenRegistry[bidData.tokenRegistryId].tokenContract,
            tokenRegistry[bidData.tokenRegistryId].tokenIdentifier,
            msg.sender,
            tokenRegistry[bidData.tokenRegistryId].minimumPrice,
            msg.value
        );

        delete tokenRegistry[bidData.tokenRegistryId];
    }

    /**
     * @dev Function to send a Token owned by this contract to an address
     * Requirements:
     * - Token must be owned by this contract.
     *
     * @param tokenContractAddress ERC721 Contract Address
     * @param tokenIdentifier Identifier on the token contract
     * @param tokenReceiver Receiver of the NFT
     */
    function transferToken(
        address tokenContractAddress,
        uint256 tokenIdentifier,
        address tokenReceiver
    ) private {
        require(
            IERC721(tokenContractAddress).ownerOf(tokenIdentifier) ==
                address(this),
            "WedreamEscrow: NFT is not owned by Escrow Contract"
        );

        IERC721(tokenContractAddress).safeTransferFrom(
            address(this),
            tokenReceiver,
            tokenIdentifier
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @dev Bid Struct definition used to validate EIP712.
 *
 */
library LibBid {
    bytes32 private constant BID_TYPE =
        keccak256(
            "Bid(address winnerWallet,address tokenContract,uint256 tokenIdentifier,uint256 tokenRegistryId,uint256 amount)"
        );

    struct Bid {
        address winnerWallet;
        address tokenContract;
        uint256 tokenIdentifier;
        uint256 tokenRegistryId;
        uint256 amount;
    }

    function bidHash(Bid memory bid) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    BID_TYPE,
                    bid.winnerWallet,
                    bid.tokenContract,
                    bid.tokenIdentifier,
                    bid.tokenRegistryId,
                    bid.amount
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./LibBid.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

/**
 * @dev EIP712 based contract module which validates a Bid.
 * The signer is {ESCROW_WALLET} and checks for integrity of
 * the bid. {bid} is struct defined in LibBid.
 *
 */
abstract contract BidValidator is EIP712 {
    constructor() EIP712("WedreamEscrow", "1") {}

    // Wallet that signs our bides
    address public ESCROW_WALLET;

    /**
     * @dev Validates if {bid} was signed by {ESCROW_WALLET} and created {signature}.
     *
     * @param bid Struct with bid properties
     * @param signature Signature to decode and compare
     */
    function validateBid(LibBid.Bid memory bid, bytes memory signature)
        internal
        view
    {
        bytes32 bidHash = LibBid.bidHash(bid);
        bytes32 digest = _hashTypedDataV4(bidHash);
        address signer = ECDSA.recover(digest, signature);

        require(
            signer == ESCROW_WALLET,
            "BidValidator: Bid signature verification error"
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

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
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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