// SPDX-License-Identifier: MIT
// 0xb1d80815212a191d2576d5b2d25ed6db86905e00
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./interfaces/IMetaeraToken.sol";
import "./interfaces/IERC20.sol";
import "./lib/LibArtwork.sol";
import "./base/WhiteListRole.sol";

/// @title NFT艺术品购买合约
/// @notice NFT艺术品购买接口
contract MetaeraBuy is ReentrancyGuard, WhiteListRole, Ownable, Pausable {
    /// @dev MetaeraToken 合约
    IMetaeraToken public _metaToken;
    /// @dev USDT合约
    IERC20 _usdt;
    /// @dev USDT收款钱包地址
    address public _usdtWallet;
    /// @dev artwork id => ArtworkOnSaleInfo
    mapping(uint256 => LibArtwork.ArtworkOnSaleInfo) public _artworkOnSaleInfos;
    mapping(uint256 => mapping(address => uint256)) public _hasPurchased;

    /// @dev Require that the caller must be an EOA account if not whitelisted.
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "not eoa");
        _;
    }

    /// @notice 艺术品在售事件
    /// @param artworkId 艺术品ID
    /// @param onSaleInfo 在售信息
    event ArtworkOnSale(uint256 indexed artworkId, LibArtwork.ArtworkOnSaleInfo onSaleInfo);

    /// @notice 艺术品购买事件
    /// @param artworkId 艺术品ID
    /// @param count 铸造数量
    /// @param nonce 流水号
    event ArtworkBuyNow(uint256 indexed artworkId, uint32 indexed count, uint256 indexed nonce);

    /// @dev 初始化MetaeraToken合约地址和USDT钱包地址
    /// @param  metaToken MetaeraToken合约地址
    /// @param  usdt USDT合约地址
    /// @param  usdtWallet USDT钱包地址
    constructor(address metaToken, address usdt, address usdtWallet) WhiteListRole("MetaeraBuy", "1.0") {
        setMetaeraToken(metaToken);
        setUSDTContract(usdt);
        setUSDTWallet(usdtWallet);
    }

    /// @dev 设置MetaeraToken合约地址
    /// @param  metaToken MetaeraToken合约地址
    function setMetaeraToken(address metaToken) public onlyOwner {
        _metaToken = IMetaeraToken(metaToken);
    }

    /// @dev 设置USDT合约地址
    /// @param  usdt USDT合约地址
    function setUSDTContract(address usdt) public onlyOwner {
        _usdt = IERC20(usdt);
    }

    /// @dev 设置接收销售金额的USDT钱包地址
    /// @param  usdtWallet USDT钱包地址
    function setUSDTWallet(address usdtWallet) public onlyOwner {
        _usdtWallet = usdtWallet;
    }

    /// @dev 设置白名单校验人
    /// @param  signer 校验人
    function setWhiteListSigner(address signer) public onlyOwner {
        _setWhiteListSigner(signer);
    }

    /// @dev 获取流水号
    /// @param account 账号
    function getNonce(address account) public view returns(uint256) {
        return _getNonce(account);
    }

    /// @dev 设置艺术品在售
    /// @param  artworkId 艺术品ID
    /// @param  onSaleInfo 艺术品在售信息
    function putOnSale(
        uint256 artworkId,
        LibArtwork.ArtworkOnSaleInfo memory onSaleInfo
    ) public onlyOwner {
        require(onSaleInfo.receiver != address(0), "receiver cannot be zero");
        require(onSaleInfo.endTime >= onSaleInfo.startTime, "endTime should >= startTime!");
        _artworkOnSaleInfos[artworkId] = onSaleInfo;
        emit ArtworkOnSale(artworkId, onSaleInfo);
    }

    /// @dev 设置艺术品在售
    /// @param  artworkId 艺术品ID
    /// @param  publicState 公售状态（1表示公售）
    function putOnSalePublic(
        uint256 artworkId,
        uint32 publicState
    ) public onlyOwner {
        LibArtwork.ArtworkOnSaleInfo memory onSaleInfo = _artworkOnSaleInfos[artworkId];
        require(onSaleInfo.receiver != address(0), "artwork not on sale!");
        onSaleInfo.publicState = publicState;
        _artworkOnSaleInfos[artworkId] = onSaleInfo;
        emit ArtworkOnSale(artworkId, onSaleInfo);
    }

    /// @notice 购买艺术品
    /// @param  artworkId 艺术品ID
    /// @param  signature 签名
    function buyNow(
        uint256 artworkId,
        bytes memory signature
    ) external onlyEOA nonReentrant whenNotPaused {
        require(_verifySignedMessage(_msgSender(), artworkId, signature), "signature verify failed!");
        LibArtwork.ArtworkOnSaleInfo memory onSaleInfo = _artworkOnSaleInfos[artworkId];
        _buyArtwork(artworkId, onSaleInfo);
    }

    /// @notice 购买艺术品（公售）
    /// @param  artworkId 艺术品ID
    function publicBuy(
        uint256 artworkId
    ) external onlyEOA nonReentrant whenNotPaused {        
        LibArtwork.ArtworkOnSaleInfo memory onSaleInfo = _artworkOnSaleInfos[artworkId];
        //检查艺术品在售状态
        require(onSaleInfo.publicState == 1, "artwork sale not public!");
        _buyArtwork(artworkId, onSaleInfo);
    }

    /// @notice 获取链ID
    function getChainID() public view returns (uint256) {
        return _getChainId();
    }

    /// ------------------------------- PRIVATE --------------------------------

    function _buyArtwork(
        uint256 artworkId,
        LibArtwork.ArtworkOnSaleInfo memory onSaleInfo
    ) internal {        
        //检查艺术品在售状态
        require(onSaleInfo.receiver != address(0), "artwork not on sale!");
        require(onSaleInfo.startTime <= block.timestamp, "artwork sale not started yet!");
        require(onSaleInfo.endTime >= block.timestamp, "artwork sale is already ended!");
        require(_hasPurchased[artworkId][_msgSender()] == 0, "sender has purchased");
        _transferUSDT(onSaleInfo);
        _metaToken.releaseArtworkForReceiver(_msgSender(), artworkId, 1);
        emit ArtworkBuyNow(artworkId, 1, _getNonce(_msgSender()));
        _updateNonce(_msgSender());
        _hasPurchased[artworkId][_msgSender()] = 1;
    }

    /// @notice 转账销售金额到USDT钱包
    function _transferUSDT(LibArtwork.ArtworkOnSaleInfo memory onSaleInfo) internal {
        _usdt.transferFrom(_msgSender(), _usdtWallet, onSaleInfo.takeAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibArtwork {
    struct Artwork {
        address creator;
        uint32 releaseCount;
        uint32 totalSupply;
    }

    struct ArtworkOnSaleInfo {
        address receiver;  // NFT接收者地址
        uint256 takeAmount; //价格
        uint256 startTime; // timestamp in seconds
        uint256 endTime;
        uint32 publicState; //公售状态（1表示公售）
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/LibArtwork.sol";

/// @title Interface of TRLab NFT core contract
/// @author Joe
/// @notice This is the interface of TRLab NFT core contract
interface IMetaeraToken {
    /// @notice 铸造NFT事件.
    /// @param nftOwner NFT拥有者.
    /// @param artworkId 艺术品ID.
    /// @param tokenIds NFT ID.
    event ArtworkReleaseCreated(
        address indexed nftOwner,
        uint256 indexed artworkId,
        uint256[] tokenIds
    );

    /// @notice This event emits when an artwork has been burned.
    /// @param artworkId uint256 the id of the burned artwork.
    event ArtworkBurned(uint256 indexed artworkId);

    /// @dev 获取NFT发行量
    function totalSupply() external view returns (uint256);

    /// @dev 设置元数据URI
    function setURI(string memory URI) external;

    /// @dev 设置艺术品存储合约地址. 只有合约拥有者调用
    /// @param  storeAddress 艺术品存储合约地址
    function setStoreAddress(address storeAddress) external;

    /// @dev 设置授权的创建者. 只有合约拥有者调用.
    function setApprovedCreator(address[] calldata creators, bool ok) external;

    /// @notice 获取艺术品
    /// @param  artworkId 艺术品ID
    function getArtwork(uint256 artworkId) external view returns (LibArtwork.Artwork memory artwork);

    /// @notice 创建艺术品
    /// @param  artworkId 艺术品ID
    /// @param  supply 总发行量
    function createArtwork(
        uint256 artworkId,
        uint32 supply
    ) external;

    /// @notice 铸造艺术品的NFT
    /// @param  artworkId 艺术品ID
    /// @param  count 铸造NFT数量
    function releaseArtwork(
        uint256 artworkId,
        uint32 count
    ) external;

    /// @notice 铸造艺术品的NFT. 由MetaeraBuy合约调用.
    /// @param  receiver NFT接收者
    /// @param  artworkId 艺术品ID
    /// @param  count 铸造NFT数量
    function releaseArtworkForReceiver(
        address receiver,
        uint256 artworkId,
        uint32 count
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface for IERC20
interface IERC20 {
	function balanceOf(address addr) external view returns(uint);
	function transferFrom(address from, address to, uint value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract WhiteListRole is EIP712 {
    /// @dev account address => nonce
    mapping(address => uint256) private _whiteList;
    address private _signer;

    constructor(string memory name, string memory version) EIP712(name, version) {
    }

    /// @notice 验证签名
    /// @param  from 请求者
    /// @param  value 艺术品ID
    /// @param  signature 签名
    function _verifySignedMessage(
        address from,
        uint256 value,
        bytes memory signature
    ) internal view returns (bool) {
        uint256 nonce = _getNonce(from);
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
        keccak256("Metaera(address from,uint256 value,uint256 nonce)"),
            from,
            value,
            nonce
        )));
        address signer = ECDSA.recover(digest, signature);
        return signer == _signer;
    }

    /// @notice 获取流水号
    /// @param  account 请求者
    function _getNonce(address account) internal view returns(uint256) {
        return _whiteList[account];
    }

    /// @dev 设置白名单校验人
    /// @param  signer 校验人
    function _setWhiteListSigner(address signer) internal {
        _signer = signer;
    }

    /// @notice 更新流水号
    /// @param  account 请求者
    function _updateNonce(address account) internal {
        _whiteList[account] = _whiteList[account]+1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

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
        _CACHED_CHAIN_ID = _getChainId();
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    function _getChainId() internal view returns (uint256) {
        // return 1337;
        return block.chainid;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && _getChainId() == _CACHED_CHAIN_ID) {
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
        return keccak256(abi.encode(typeHash, nameHash, versionHash, _getChainId(), address(this)));
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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