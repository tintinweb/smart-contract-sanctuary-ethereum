// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./Utils.sol";

struct ArcanaTokenInfo {
    uint256 tokenId;
    uint256 gene;
    string metadataHash;
    uint256 attributes;
}

interface IBurnableArcanaToken {
    function ownerOf(uint256 tokenId) external returns (address);
    function tokens(uint256 tokenId) external returns (ArcanaTokenInfo memory);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
}

interface IMintableShardToken {
    function mint(address to, uint256 id, uint256 amount) external;
}

contract Decomposer is Ownable, IERC721Receiver {

    IBurnableArcanaToken public arcanaToken;
    IMintableShardToken public shardToken;

    struct Job {
        uint256 id;
        address owner;
        uint256 tokenId;
        uint256 beginTimestamp;
        uint256 endTimestamp;
        bool ongoing;
    }

    event JobUpdated(uint256 jobId, string action);  // begin | complete | cancel

    mapping(uint256 => Job) private jobs;
    uint256 public numberOfAllJobs;
    mapping(address => uint256[]) private _ownedJobs;
    mapping(address => uint256) public numberOfIncompleteJobs;
    uint256[] private _allJobs;

    // 分解期間の乱択のためのテーブル（平均8.7h）
    uint32[] private DURATION_SECS = [
        300, 458, 700, 1070, 1634, 2496, 3813, 5825,
        8899, 13595, 20768, 31727, 48468, 74044, 113114, 172800
    ];
    uint16[] private DURATION_SECS_BOUNDS = [
        4096, 8192, 12288, 16384, 20480, 24576, 28672, 32768,
        36864, 40960, 45056, 49152, 53248, 57344, 61440  //, 65536
    ];
    uint256 private constant DURATION_SECS_SALT = 0x4f0632eba0cd48d1642ca90ea60a61e0a3ae94199cbcf67578ec12165cb84ea5;

    // Shard生成数の乱択のためのテーブル（平均6）
    uint8[] private SHARD_NUMS = [
        1, 2, 3, 4, 5, 6, 7, 9, 11, 14, 17, 21, 26, 32, 40, 50
    ];
    uint16[] private SHARD_NUMS_BOUNDS = [
        9116, 18075, 26578, 34371, 41269, 47166, 52035, 55917,
        58906, 61129, 62726, 63833, 64575, 65055, 65355  //, 65536
    ];
    uint256 private constant SHARD_NUMS_SALT = 0xe715231cec7d4ace54757033a785e28b6b426cad6a24186989706e9a07a1f3fc;

    /// @notice Arcanaトークンを設定する
    function setArcanaToken(address tokenAddress) public onlyOwner {
        arcanaToken = IBurnableArcanaToken(tokenAddress);
    }

    /// @notice Shardトークンを設定する
    function setShardToken(address tokenAddress) public onlyOwner {
        shardToken = IMintableShardToken(tokenAddress);
    }

    /// @notice Arcanaの分解を開始する
    /// @return 分解ジョブのID
    /** @dev
    処理概要：
    * ArcanaトークンをownerからDecomposerに転送
    * ロック期間をランダムに決定（5分～2日、geenをseedにする）
    * 分解ジョブを生成
    * 未完了ジョブ数を加算
    事前条件： approve済・sender == token-owner
    事後条件： 分解ジョブが生成されている
    */
    function beginDecompose(uint256 tokenId) public returns (uint256)
    {
        address tokenOwner = arcanaToken.ownerOf(tokenId);
        require(msg.sender == tokenOwner, "Decomposer: sender is not owner of the token");
        arcanaToken.safeTransferFrom(tokenOwner, address(this), tokenId);
        ArcanaTokenInfo memory tokenInfo = arcanaToken.tokens(tokenId);
        uint256 jobId = numberOfAllJobs + 1;
        uint256 duration = _getRandomDuration(tokenInfo.gene);
        jobs[jobId] = Job(
            jobId,
            tokenOwner,
            tokenId,
            block.timestamp,
            block.timestamp + duration,
            true
        );
        _allJobs.push(jobId);
        _ownedJobs[msg.sender].push(jobId);
        numberOfAllJobs++;
        numberOfIncompleteJobs[msg.sender]++;
        emit JobUpdated(jobId, "begin");
        return jobId;
    }

    /// @notice 分解を中断する。
    /** @dev
    処理概要：
    * Arcanaトークンをownerに転送（返却）
    * 分解ジョブを終了済としてマーク（ongoing=False）
    * 未完了ジョブ数を減算
    事前条件： jobIdが有効, sender == job-owner, job.ongoing == true
    事後条件： 分解ジョブが中断されている
    */
    function cancelDecompose(uint256 jobId) public {
        Job storage job = jobs[jobId];
        require(job.id != 0, "Decomposer: invalid job id");
        require(job.owner == msg.sender, "Decomposer: sender is not owner of the token");
        require(job.ongoing, "Decomposer: decomposing has already been completed or canceled.");
        arcanaToken.transferFrom(address(this), job.owner, job.tokenId);
        job.ongoing = false;
        numberOfIncompleteJobs[msg.sender] -= 1;
        emit JobUpdated(jobId, "cancel");
    }

    /// @notice 所定時間が経過した分解ジョブを完了する
    /** @dev
    処理概要：
    * 獲得するShardの数をランダムに決定（1個～50個、geenをseedにする）
    * Shardトークンをmint
    * Arcanaトークンをburn
    * 分解ジョブを終了済としてマーク（ongoing=False）
    * 未完了ジョブ数を減算
    事前条件： jobIdが有効, sender == job-owner, job.ongoing == true, timestamp >= job.endTimestamp
    事後条件： 分解ジョブが完了し、ownerのShardが加算されている
    */
    function endDecompose(uint256 jobId) public {
        Job storage job = jobs[jobId];
        require(job.id != 0, "Decomposer: invalid job id");
        require(job.owner == msg.sender, "Decomposer: sender is not owner of the token");
        require(job.ongoing, "Decomposer: decomposing has already been completed or canceled.");
        require(job.endTimestamp <= block.timestamp, "Decomposer: still under decomposing");
        ArcanaTokenInfo memory tokenInfo = arcanaToken.tokens(job.tokenId);
        uint8 shardNum = _getRandomShardNum(tokenInfo.gene);
        shardToken.mint(job.owner, tokenInfo.gene, shardNum);
        arcanaToken.burn(job.tokenId);
        job.ongoing = false;
        numberOfIncompleteJobs[msg.sender] -= 1;
        emit JobUpdated(jobId, "complete");
    }

    /// @notice 完了済ジョブを含む全ての分解ジョブの数を取得する
    function numberOfJobs(address owner) public view returns (uint256)
    {
        return _ownedJobs[owner].length;
    }

    /// @notice 分解ジョブの状態（分解中のArcanaのID、開始時刻、終了時刻）を取得する
    function getState(uint256 jobId) public view returns (Job memory)
    {
        Job storage job = jobs[jobId];
        require(job.id != 0, "Decomposer: invalid job id");
        return job;
    }

    function jobByIndex(uint256 index) public view returns (uint256)
    {
        require(index < numberOfAllJobs, "Decomposer: global index out of bounds");
        return _allJobs[index];
    }

    function jobOfOwnerByIndex(address owner, uint256 index) public view returns (uint256)
    {
        require(owner != address(0), "Decomposer: address zero is not a valid owner");
        require(index < numberOfJobs(owner), "Decomposer: owner index out of bounds");
        return _ownedJobs[owner][index];
    }

    /// @notice IERC721Receiver
    bytes4 private constant IFID_IERC721Receiver = 0x150b7a02;
    function onERC721Received(address operator, address, uint256, bytes calldata) external view returns (bytes4)
    {
        require(operator == address(this), "Decomposer: transfer by other address");
        return bytes4(IFID_IERC721Receiver);
    }

    // INTERNAL FUNCTIONS

    function _getRandomDuration(uint256 gene) internal view returns (uint32)
    {
        return DURATION_SECS[_randomChoice(gene ^ DURATION_SECS_SALT, DURATION_SECS_BOUNDS)];
    }

    function _getRandomShardNum(uint256 gene) internal view returns (uint8)
    {
        return SHARD_NUMS[_randomChoice(gene ^ SHARD_NUMS_SALT, SHARD_NUMS_BOUNDS)];
    }

    function _randomChoice(uint256 seed, uint16[] memory bounds) internal pure returns (uint256)
    {
        uint16 value = uint16(uint256(keccak256(abi.encode(seed))) & uint256(0xffff));
        for (uint256 idx = 0; idx < bounds.length; idx++) {
            if (value < bounds[idx]) {
                return idx;
            }
        }
        return bounds.length;
    }

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

/// @notice 管理者権限の実装
abstract contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not owner");
        _;
    }

    function transferOwnership(address _newOwner) public virtual onlyOwner {
        require(
            _newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        owner = _newOwner;
    }
}

/// @notice 発行権限の実装
abstract contract Mintable {
    mapping(address => bool) public minters;

    constructor() {
        minters[msg.sender] = true;
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "Mintable: caller is not minter");
        _;
    }

    function setMinter(address newMinter, bool mintable) public virtual onlyMinter {
        require(
            newMinter != address(0),
            "Mintable: new minter is the zero address"
        );
        minters[newMinter] = mintable;
    }
}

/// @notice 焼却権限の実装
abstract contract Burnable {
    mapping(address => bool) public burners;

    constructor() {
        burners[msg.sender] = true;
    }

    modifier onlyBurner() {
        require(burners[msg.sender], "Burnable: caller is not burner");
        _;
    }

    function isBurner(address addr) public view returns(bool) {
        return burners[addr];
    }

    function setBurner(address newBurner, bool burnable) public virtual onlyBurner {
        require(
            newBurner != address(0),
            "Burnable: new burner is the zero address"
        );
        burners[newBurner] = burnable;
    }
}

/// @notice 署名の実装
abstract contract SupportSig is EIP712 {
    uint256 private MAX_NONCE_DIFFERENCE = 100 * 365 * 24 * 60 * 60;

    constructor(string memory name, string memory version) EIP712(name,version) {}
    
    function validNonce(uint256 nonce, uint256 lastNonce) internal view returns(bool) {
        return nonce > lastNonce && nonce - lastNonce < MAX_NONCE_DIFFERENCE;
    }
    function getChainId() public view returns(uint256) {
        return block.chainid;
    }
    
    function getSigner(bytes memory typedContents, bytes memory sig) internal view returns (address) {
        return ECDSA.recover(_hashTypedDataV4(keccak256(typedContents)), sig);
    }
}

/// @notice トークン更新履歴の実装
abstract contract SupportTokenUpdateHistory {

    struct  TokenUpdateHistoryItem {
        uint256 tokenId;
        uint256 updatedAt;
    }

    uint256 public tokenUpdateHistoryCount;
    TokenUpdateHistoryItem[] public tokenUpdateHistory;

    constructor() {
        TokenUpdateHistoryItem memory dummy;
        tokenUpdateHistory.push(dummy);  // 1-based index
    }

    function onTokenUpdated(uint256 tokenId) internal {
        tokenUpdateHistory.push(TokenUpdateHistoryItem(tokenId, block.timestamp));
        tokenUpdateHistoryCount++;
    }
}