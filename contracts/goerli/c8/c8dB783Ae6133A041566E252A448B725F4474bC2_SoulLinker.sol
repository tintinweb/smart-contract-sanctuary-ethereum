// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./dex/PaymentGateway.sol";
import "./interfaces/ISoulboundIdentity.sol";

/// @title Soul linker
/// @author Masa Finance
/// @notice Soul linker smart contract that let add links to a Soulbound token.
contract SoulLinker is PaymentGateway, EIP712 {
    /* ========== STATE VARIABLES =========================================== */

    ISoulboundIdentity public soulboundIdentity;

    // linked SBTs
    mapping(address => bool) public linkedSBT;
    address[] public linkedSBTs;

    uint256 public addPermissionPrice; // store permission price in stable coin
    uint256 public addPermissionPriceMASA; // store permission price in $MASA

    // token => tokenId => readerIdentityId => signatureDate => PermissionData
    mapping(address => mapping(uint256 => mapping(uint256 => mapping(uint256 => PermissionData))))
        private _permissions;
    mapping(address => mapping(uint256 => mapping(uint256 => uint256[])))
        private _permissionSignatureDates;

    struct PermissionData {
        uint256 ownerIdentityId;
        string data;
        uint256 expirationDate;
        bool isRevoked;
    }

    /* ========== INITIALIZE ================================================ */

    /// @notice Creates a new soul linker
    /// @param owner Owner of the smart contract
    /// @param _soulboundIdentity Soulbound identity smart contract
    /// @param _addPermissionPrice Store permission price in stable coin
    /// @param _addPermissionPriceMASA Store permission price in $MASA
    /// @param paymentParams Payment gateway params
    constructor(
        address owner,
        ISoulboundIdentity _soulboundIdentity,
        uint256 _addPermissionPrice,
        uint256 _addPermissionPriceMASA,
        PaymentParams memory paymentParams
    ) EIP712("SoulLinker", "1.0.0") PaymentGateway(owner, paymentParams) {
        require(address(_soulboundIdentity) != address(0), "ZERO_ADDRESS");

        soulboundIdentity = _soulboundIdentity;

        addPermissionPrice = _addPermissionPrice;
        addPermissionPriceMASA = _addPermissionPriceMASA;
    }

    /* ========== RESTRICTED FUNCTIONS ====================================== */

    /// @notice Sets the SoulboundIdentity contract address linked to this soul name
    /// @dev The caller must be the owner to call this function
    /// @param _soulboundIdentity Address of the SoulboundIdentity contract
    function setSoulboundIdentity(ISoulboundIdentity _soulboundIdentity)
        external
        onlyOwner
    {
        require(address(_soulboundIdentity) != address(0), "ZERO_ADDRESS");
        require(soulboundIdentity != _soulboundIdentity, "SAME_VALUE");
        soulboundIdentity = _soulboundIdentity;
    }

    /// @notice Adds an SBT to the list of linked SBTs
    /// @dev The caller must be the owner to call this function
    /// @param token Address of the SBT contract
    function addLinkedSBT(address token) external onlyOwner {
        require(address(token) != address(0), "ZERO_ADDRESS");
        require(!linkedSBT[token], "SBT_ALREADY_LINKED");

        linkedSBT[token] = true;
        linkedSBTs.push(token);
    }

    /// @notice Removes an SBT from the list of linked SBTs
    /// @dev The caller must be the owner to call this function
    /// @param token Address of the SBT contract
    function removeLinkedSBT(address token) external onlyOwner {
        require(linkedSBT[token], "SBT_NOT_LINKED");

        linkedSBT[token] = false;
        _removeLinkedSBT(token);
    }

    /// @notice Sets the price of store permission in stable coin
    /// @dev The caller must have the owner to call this function
    /// @param _addPermissionPrice New price of the store permission in stable coin
    function setAddPermissionPrice(uint256 _addPermissionPrice)
        external
        onlyOwner
    {
        require(addPermissionPrice != _addPermissionPrice, "SAME_VALUE");
        addPermissionPrice = _addPermissionPrice;
    }

    /// @notice Sets the price of store permission in $MASA
    /// @dev The caller must have the owner to call this function
    /// @param _addPermissionPriceMASA New price of the store permission in $MASA
    function setAddPermissionPriceMASA(uint256 _addPermissionPriceMASA)
        external
        onlyOwner
    {
        require(
            addPermissionPriceMASA != _addPermissionPriceMASA,
            "SAME_VALUE"
        );
        addPermissionPriceMASA = _addPermissionPriceMASA;
    }

    /* ========== MUTATIVE FUNCTIONS ======================================== */

    /// @notice Stores the permission, validating the signature of the given read link request
    /// @dev The token must be linked to this soul linker
    /// @param readerIdentityId Id of the identity of the reader
    /// @param ownerIdentityId Id of the identity of the owner of the SBT
    /// @param token Address of the SBT contract
    /// @param tokenId Id of the token
    /// @param data Data that owner wants to share
    /// @param signatureDate Signature date of the signature
    /// @param expirationDate Expiration date of the signature
    /// @param signature Signature of the read link request made by the owner
    function addPermission(
        uint256 readerIdentityId,
        uint256 ownerIdentityId,
        address token,
        uint256 tokenId,
        string memory data,
        uint256 signatureDate,
        uint256 expirationDate,
        bytes calldata signature
    ) external {
        require(linkedSBT[token], "SBT_NOT_LINKED");

        address identityOwner = soulboundIdentity.ownerOf(ownerIdentityId);
        address tokenOwner = IERC721Enumerable(token).ownerOf(tokenId);

        require(identityOwner == tokenOwner, "IDENTITY_OWNER_NOT_TOKEN_OWNER");
        require(identityOwner == _msgSender(), "CALLER_NOT_OWNER");
        require(expirationDate >= block.timestamp, "VALID_PERIOD_EXPIRED");
        require(
            _verify(
                _hash(
                    readerIdentityId,
                    ownerIdentityId,
                    token,
                    tokenId,
                    data,
                    signatureDate,
                    expirationDate
                ),
                signature,
                identityOwner
            ),
            "INVALID_SIGNATURE"
        );

        if (addPermissionPriceMASA > 0) {
            // if there is a price in $MASA, pay it without conversion rate
            _payWithMASA(addPermissionPriceMASA);
        } else {
            // pay with $MASA with conversion rate
            _pay(utilityToken, addPermissionPrice);
        }

        // token => tokenId => readerIdentityId => signatureDate => PermissionData
        _permissions[token][tokenId][readerIdentityId][
            signatureDate
        ] = PermissionData(ownerIdentityId, data, expirationDate, false);
        _permissionSignatureDates[token][tokenId][readerIdentityId].push(
            signatureDate
        );

        emit PermissionAdded(
            readerIdentityId,
            ownerIdentityId,
            token,
            tokenId,
            data,
            signatureDate,
            expirationDate
        );
    }

    /// @notice Revokes the permission
    /// @dev The token must be linked to this soul linker
    /// @param readerIdentityId Id of the identity of the reader
    /// @param ownerIdentityId Id of the identity of the owner of the SBT
    /// @param token Address of the SBT contract
    /// @param tokenId Id of the token
    /// @param signatureDate Signature date of the signature
    function revokePermission(
        uint256 readerIdentityId,
        uint256 ownerIdentityId,
        address token,
        uint256 tokenId,
        uint256 signatureDate
    ) external {
        address identityOwner = soulboundIdentity.ownerOf(ownerIdentityId);
        address tokenOwner = IERC721Enumerable(token).ownerOf(tokenId);

        require(identityOwner == tokenOwner, "IDENTITY_OWNER_NOT_TOKEN_OWNER");
        require(identityOwner == _msgSender(), "CALLER_NOT_OWNER");
        require(
            _permissions[token][tokenId][readerIdentityId][signatureDate]
                .isRevoked == false,
            "PERMISSION_ALREADY_REVOKED"
        );

        // token => tokenId => readerIdentityId => signatureDate => PermissionData
        _permissions[token][tokenId][readerIdentityId][signatureDate]
            .isRevoked = true;

        emit PermissionRevoked(
            readerIdentityId,
            ownerIdentityId,
            token,
            tokenId,
            signatureDate
        );
    }

    /* ========== VIEWS ===================================================== */

    /// @notice Returns the identityId owned by the given token
    /// @dev The token must be linked to this soul linker
    /// @param token Address of the SBT contract
    /// @param tokenId Id of the token
    /// @return Id of the identity
    function getIdentityId(address token, uint256 tokenId)
        external
        view
        returns (uint256)
    {
        address owner = IERC721Enumerable(token).ownerOf(tokenId);
        return soulboundIdentity.tokenOfOwner(owner);
    }

    /// @notice Returns the list of linked SBTs by a given SBT token
    /// @dev The token must be linked to this soul linker
    /// @param identityId Id of the identity
    /// @param token Address of the SBT contract
    /// @return List of linked SBTs
    function getSBTLinks(uint256 identityId, address token)
        external
        view
        returns (uint256[] memory)
    {
        require(linkedSBT[token], "SBT_NOT_LINKED");
        address owner = soulboundIdentity.ownerOf(identityId);

        return getSBTLinks(owner, token);
    }

    /// @notice Returns the list of linked SBTs by a given SBT token
    /// @dev The token must be linked to this soul linker
    /// @param owner Address of the owner of the identity
    /// @param token Address of the SBT contract
    /// @return List of linked SBTs
    function getSBTLinks(address owner, address token)
        public
        view
        returns (uint256[] memory)
    {
        require(linkedSBT[token], "SBT_NOT_LINKED");

        uint256 links = IERC721Enumerable(token).balanceOf(owner);
        uint256[] memory sbtLinks = new uint256[](links);
        for (uint256 i = 0; i < links; i++) {
            sbtLinks[i] = IERC721Enumerable(token).tokenOfOwnerByIndex(
                owner,
                i
            );
        }

        return sbtLinks;
    }

    /// @notice Returns the list of permission signature dates for a given SBT token and reader
    /// @param token Address of the SBT contract
    /// @param tokenId Id of the token
    /// @param readerIdentityId Id of the identity of the reader of the SBT
    /// @return List of linked SBTs
    function getPermissionSignatureDates(
        address token,
        uint256 tokenId,
        uint256 readerIdentityId
    ) public view returns (uint256[] memory) {
        return _permissionSignatureDates[token][tokenId][readerIdentityId];
    }

    /// @notice Returns the information of permission dates for a given SBT token and reader
    /// @param token Address of the SBT contract
    /// @param tokenId Id of the token
    /// @param readerIdentityId Id of the identity of the reader of the SBT
    /// @param signatureDate Signature date of the signature
    /// @return permissionData List of linked SBTs
    function getPermissionInfo(
        address token,
        uint256 tokenId,
        uint256 readerIdentityId,
        uint256 signatureDate
    ) public view returns (PermissionData memory) {
        return _permissions[token][tokenId][readerIdentityId][signatureDate];
    }

    /// @notice Validates the permission of the given read link request and returns the
    /// data that reader can read if the permission is valid
    /// @dev The token must be linked to this soul linker
    /// @param readerIdentityId Id of the identity of the reader
    /// @param ownerIdentityId Id of the identity of the owner of the SBT
    /// @param token Address of the SBT contract
    /// @param tokenId Id of the token
    /// @param signatureDate Signature date of the signature
    /// @return Data that the reader can read
    function validatePermission(
        uint256 readerIdentityId,
        uint256 ownerIdentityId,
        address token,
        uint256 tokenId,
        uint256 signatureDate
    ) external view returns (string memory) {
        require(linkedSBT[token], "SBT_NOT_LINKED");

        address identityReader = soulboundIdentity.ownerOf(readerIdentityId);
        address identityOwner = soulboundIdentity.ownerOf(ownerIdentityId);
        address tokenOwner = IERC721Enumerable(token).ownerOf(tokenId);

        PermissionData memory permission = _permissions[token][tokenId][
            readerIdentityId
        ][signatureDate];

        require(identityOwner == tokenOwner, "IDENTITY_OWNER_NOT_TOKEN_OWNER");
        require(identityReader == _msgSender(), "CALLER_NOT_READER");
        require(permission.expirationDate > 0, "PERMISSION_DOES_NOT_EXIST");
        require(
            permission.expirationDate >= block.timestamp,
            "VALID_PERIOD_EXPIRED"
        );
        require(permission.isRevoked == false, "PERMISSION_REVOKED");

        return permission.data;
    }

    /// @notice Returns the price for storing a permission
    /// @dev Returns the current pricing for storing a permission
    /// @return priceInUtilityToken Current price of storing a permission in utility token ($MASA)
    function getPriceForAddPermission()
        public
        view
        returns (uint256 priceInUtilityToken)
    {
        if (addPermissionPriceMASA > 0) {
            // if there is a price in $MASA, return it without conversion rate
            priceInUtilityToken = addPermissionPriceMASA;
        } else {
            // return $MASA with conversion rate
            priceInUtilityToken = _convertFromStableCoin(
                utilityToken,
                addPermissionPrice
            );
        }
    }

    /* ========== PRIVATE FUNCTIONS ========================================= */

    function _removeLinkedSBT(address token) internal {
        for (uint256 i = 0; i < linkedSBTs.length; i++) {
            if (linkedSBTs[i] == token) {
                linkedSBTs[i] = linkedSBTs[linkedSBTs.length - 1];
                linkedSBTs.pop();
                break;
            }
        }
    }

    function _hash(
        uint256 readerIdentityId,
        uint256 ownerIdentityId,
        address token,
        uint256 tokenId,
        string memory data,
        uint256 signatureDate,
        uint256 expirationDate
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "Link(uint256 readerIdentityId,uint256 ownerIdentityId,address token,uint256 tokenId,string data,uint256 signatureDate,uint256 expirationDate)"
                        ),
                        readerIdentityId,
                        ownerIdentityId,
                        token,
                        tokenId,
                        keccak256(bytes(data)),
                        signatureDate,
                        expirationDate
                    )
                )
            );
    }

    function _verify(
        bytes32 digest,
        bytes memory signature,
        address owner
    ) internal pure returns (bool) {
        return ECDSA.recover(digest, signature) == owner;
    }

    /* ========== MODIFIERS ================================================= */

    /* ========== EVENTS ==================================================== */

    event PermissionAdded(
        uint256 readerIdentityId,
        uint256 ownerIdentityId,
        address token,
        uint256 tokenId,
        string data,
        uint256 signatureDate,
        uint256 expirationDate
    );

    event PermissionRevoked(
        uint256 readerIdentityId,
        uint256 ownerIdentityId,
        address token,
        uint256 tokenId,
        uint256 signatureDate
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

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
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../interfaces/dex/IUniswapRouter.sol";

/// @title Pay using a Decentralized automated market maker (AMM) when needed
/// @author Masa Finance
/// @notice Smart contract to call a Dex AMM smart contract to pay to a reserve wallet recipient
/// @dev This smart contract will call the Uniswap Router interface, based on
/// https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router01.sol
abstract contract PaymentGateway is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct PaymentParams {
        address swapRouter; // Swap router address
        address wrappedNativeToken; // Wrapped native token address
        address stableCoin; // Stable coin to pay the fee in (USDC)
        address utilityToken; // Utility token to pay the fee in ($MASA)
        address reserveWallet; // Wallet that will receive the fee
    }

    /* ========== STATE VARIABLES =========================================== */

    address public swapRouter;
    address public wrappedNativeToken;

    address public stableCoin; // USDC
    address public utilityToken; // $MASA

    // other ERC20 tokens
    mapping(address => bool) public erc20token;
    address[] public erc20tokens;

    address public reserveWallet;

    /* ========== INITIALIZE ================================================ */

    /// @notice Creates a new Dex AMM
    /// @dev Creates a new Decentralized automated market maker (AMM) smart contract,
    // that will call the Uniswap Router interface
    /// @param owner Owner of the smart contract
    /// @param paymentParams Payment params
    constructor(address owner, PaymentParams memory paymentParams) {
        require(paymentParams.swapRouter != address(0), "ZERO_ADDRESS");
        require(paymentParams.wrappedNativeToken != address(0), "ZERO_ADDRESS");
        require(paymentParams.stableCoin != address(0), "ZERO_ADDRESS");
        require(paymentParams.utilityToken != address(0), "ZERO_ADDRESS");
        require(paymentParams.reserveWallet != address(0), "ZERO_ADDRESS");

        Ownable.transferOwnership(owner);

        swapRouter = paymentParams.swapRouter;
        wrappedNativeToken = paymentParams.wrappedNativeToken;
        stableCoin = paymentParams.stableCoin;
        utilityToken = paymentParams.utilityToken;
        reserveWallet = paymentParams.reserveWallet;
    }

    /* ========== RESTRICTED FUNCTIONS ====================================== */

    /// @notice Sets the swap router address
    /// @dev The caller must have the owner to call this function
    /// @param _swapRouter New swap router address
    function setSwapRouter(address _swapRouter) external onlyOwner {
        require(_swapRouter != address(0), "ZERO_ADDRESS");
        require(swapRouter != _swapRouter, "SAME_VALUE");
        swapRouter = _swapRouter;
    }

    /// @notice Sets the wrapped native token address
    /// @dev The caller must have the owner to call this function
    /// @param _wrappedNativeToken New wrapped native token address
    function setWrappedNativeToken(address _wrappedNativeToken)
        external
        onlyOwner
    {
        require(_wrappedNativeToken != address(0), "ZERO_ADDRESS");
        require(wrappedNativeToken != _wrappedNativeToken, "SAME_VALUE");
        wrappedNativeToken = _wrappedNativeToken;
    }

    /// @notice Sets the stable coin to pay the fee in (USDC)
    /// @dev The caller must have the owner to call this function
    /// @param _stableCoin New stable coin to pay the fee in
    function setStableCoin(address _stableCoin) external onlyOwner {
        require(_stableCoin != address(0), "ZERO_ADDRESS");
        require(stableCoin != _stableCoin, "SAME_VALUE");
        stableCoin = _stableCoin;
    }

    /// @notice Sets the utility token to pay the fee in ($MASA)
    /// @dev The caller must have the owner to call this function
    /// @param _utilityToken New utility token to pay the fee in
    function setUtilityToken(address _utilityToken) external onlyOwner {
        require(_utilityToken != address(0), "ZERO_ADDRESS");
        require(utilityToken != _utilityToken, "SAME_VALUE");
        utilityToken = _utilityToken;
    }

    /// @notice Adds a new ERC20 token as a valid payment method
    /// @dev The caller must have the owner to call this function
    /// @param _erc20token New ERC20 token to add
    function addErc20Token(address _erc20token) external onlyOwner {
        require(_erc20token != address(0), "ZERO_ADDRESS");
        require(!erc20token[_erc20token], "ALREADY_ADDED");

        erc20token[_erc20token] = true;
        erc20tokens.push(_erc20token);
    }

    /// @notice Removes an ERC20 token as a valid payment method
    /// @dev The caller must have the owner to call this function
    /// @param _erc20token ERC20 token to remove
    function removeErc20Token(address _erc20token) external onlyOwner {
        require(_erc20token != address(0), "ZERO_ADDRESS");
        require(erc20token[_erc20token], "NOT_EXISITING_ERC20TOKEN");

        erc20token[_erc20token] = false;
        for (uint256 i = 0; i < erc20tokens.length; i++) {
            if (erc20tokens[i] == _erc20token) {
                erc20tokens[i] = erc20tokens[erc20tokens.length - 1];
                erc20tokens.pop();
                break;
            }
        }
    }

    /// @notice Set the reserve wallet
    /// @dev Let change the reserve walled. It can be triggered by an authorized account.
    /// @param _reserveWallet New reserve wallet
    function setReserveWallet(address _reserveWallet) external onlyOwner {
        require(_reserveWallet != address(0), "ZERO_ADDRESS");
        require(_reserveWallet != reserveWallet, "SAME_VALUE");
        reserveWallet = _reserveWallet;
    }

    /* ========== MUTATIVE FUNCTIONS ======================================== */

    /* ========== VIEWS ===================================================== */

    /// @notice Returns all available payment methods
    /// @dev Returns the address of all available payment methods
    /// @return _nativeToken Address of the native token (ETH)
    /// @return _stableCoin Address of the stable coin (USDC)
    /// @return _utilityToken Address of the utility token ($MASA)
    /// @return _erc20tokens Array of all ERC20 tokens
    function getPaymentMethods()
        external
        view
        returns (
            address _nativeToken,
            address _stableCoin,
            address _utilityToken,
            address[] memory _erc20tokens
        )
    {
        return (address(0), stableCoin, utilityToken, erc20tokens);
    }

    /* ========== PRIVATE FUNCTIONS ========================================= */

    function _convertFromStableCoin(address token, uint256 amount)
        internal
        view
        returns (uint256)
    {
        require(
            token == wrappedNativeToken ||
                token == utilityToken ||
                erc20token[token],
            "INVALID_TOKEN"
        );
        return _estimateSwapAmount(token, stableCoin, amount);
    }

    /// @notice Performs the payment in any payment method
    /// @dev This method will transfer the funds to the reserve wallet, performing
    /// the swap if necessary
    /// @param paymentMethod Address of token that user want to pay
    /// @param amountInStableCoin Price to be paid in stable coin
    function _pay(address paymentMethod, uint256 amountInStableCoin) internal {
        if (amountInStableCoin == 0) return;
        if (paymentMethod == stableCoin) {
            // USDC
            IERC20(paymentMethod).safeTransferFrom(
                msg.sender,
                reserveWallet,
                amountInStableCoin
            );
        } else if (paymentMethod == address(0)) {
            // ETH
            uint256 swapAmout = _convertFromStableCoin(
                wrappedNativeToken,
                amountInStableCoin
            );
            require(msg.value >= swapAmout, "INVALID_PAYMENT_AMOUNT");
            (bool success, ) = payable(reserveWallet).call{value: swapAmout}(
                ""
            );
            require(success, "TRANSFER_FAILED");
            if (msg.value > swapAmout) {
                // return diff
                uint256 refund = msg.value.sub(swapAmout);
                (success, ) = payable(msg.sender).call{value: refund}("");
                require(success);
            }
        } else if (paymentMethod == utilityToken || erc20token[paymentMethod]) {
            // $MASA
            uint256 swapAmout = _convertFromStableCoin(
                paymentMethod,
                amountInStableCoin
            );
            IERC20(paymentMethod).safeTransferFrom(
                msg.sender,
                reserveWallet,
                swapAmout
            );
        } else {
            revert("INVALID_PAYMENT_METHOD");
        }
    }

    /// @notice Performs the payment in MASA
    /// @dev This method will transfer the funds to the reserve wallet, without
    /// performing any swap
    /// @param amountInMASA Price to be paid in MASA
    function _payWithMASA(uint256 amountInMASA) internal {
        // $MASA
        IERC20(utilityToken).safeTransferFrom(
            msg.sender,
            reserveWallet,
            amountInMASA
        );
    }

    function _estimateSwapAmount(
        address _fromToken,
        address _toToken,
        uint256 _amountOut
    ) private view returns (uint256) {
        uint256[] memory amounts;
        address[] memory path;
        path = _getPathFromTokenToToken(_fromToken, _toToken);
        amounts = IUniswapRouter(swapRouter).getAmountsIn(_amountOut, path);
        return amounts[0];
    }

    function _getPathFromTokenToToken(address fromToken, address toToken)
        private
        view
        returns (address[] memory)
    {
        if (fromToken == wrappedNativeToken || toToken == wrappedNativeToken) {
            address[] memory path = new address[](2);
            path[0] = fromToken == wrappedNativeToken
                ? wrappedNativeToken
                : fromToken;
            path[1] = toToken == wrappedNativeToken
                ? wrappedNativeToken
                : toToken;
            return path;
        } else {
            address[] memory path = new address[](3);
            path[0] = fromToken;
            path[1] = wrappedNativeToken;
            path[2] = toToken;
            return path;
        }
    }

    /* ========== MODIFIERS ================================================= */

    /* ========== EVENTS ==================================================== */
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.7;

import "../tokens/SBT/ISBT.sol";

import "./ISoulName.sol";

interface ISoulboundIdentity is ISBT {
    function mint(address to) external returns (uint256);

    function mintIdentityWithName(
        address to,
        string memory name,
        uint256 yearsPeriod,
        string memory _tokenURI
    ) external payable returns (uint256);

    function getSoulName() external view returns (ISoulName);

    function tokenOfOwner(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.7;

/// @title Uniswap Router interface
/// @author Masa Finance
/// @notice Interface of the Uniswap Router contract
/// @dev This interface is used to interact with the Uniswap Router contract,
/// and gets the most important functions of the contract. It's based on
/// https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router01.sol
interface IUniswapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface ISBT is IERC165 {
    /// @dev This emits when an SBT is newly minted.
    ///  This event emits when SBTs are created
    event Mint(address indexed _owner, uint256 indexed _tokenId);

    /// @dev This emits when an SBT is burned
    ///  This event emits when SBTs are destroyed
    event Burn(address indexed _owner, uint256 indexed _tokenId);

    /// @notice Count all SBTs assigned to an owner
    /// @dev SBTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of SBTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an SBT
    /// @dev SBTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an SBT
    /// @return The address of the owner of the SBT
    function ownerOf(uint256 _tokenId) external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.7;

interface ISoulName {
    function mint(
        address to,
        string memory name,
        uint256 yearsPeriod,
        string memory _tokenURI
    ) external returns (uint256);

    function getExtension() external view returns (string memory);

    function isAvailable(string memory name)
        external
        view
        returns (bool available);

    function getTokenData(string memory name)
        external
        view
        returns (
            string memory sbtName,
            bool linked,
            uint256 identityId,
            uint256 tokenId,
            uint256 expirationDate,
            bool active
        );

    function getTokenId(string memory name) external view returns (uint256);

    function getSoulNames(address owner)
        external
        view
        returns (string[] memory sbtNames);

    function getSoulNames(uint256 identityId)
        external
        view
        returns (string[] memory sbtNames);
}