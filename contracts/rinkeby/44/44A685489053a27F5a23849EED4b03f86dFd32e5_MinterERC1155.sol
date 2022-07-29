// SPDX-License-Identifier: none

import "./interface/IERC1155ManagedSupply.sol";
import "./abstract/BaseRelayRecipient.sol";
import "./abstract/ReentrancyGuard.sol";
import "./abstract/Draft-EIP712.sol";

pragma solidity ^0.8.0;

contract MinterERC1155 is BaseRelayRecipient, EIP712, ReentrancyGuard{
    address public immutable nft;

    mapping(address => bool) private _claimed;
    mapping(address => claimParameter) private _claimLog;

    struct claimParameter{
        uint256 id;
        uint256 amount;
    }

    event claimNft(
        address indexed user,
        uint256 indexed id,
        uint256 indexed amount
    );

    constructor(
        address forwarder_,
        address nft_
    ) EIP712("MinterERC1155", "1") {
        nft = nft_;

        _setTrustedForwarder(forwarder_);
    }

    function userClaimed(
        address user
    ) public view virtual returns (bool) {
        return _claimed[user];
    }

    function userClaimLog(
        address user
    ) public view virtual returns (
        claimParameter memory
    ) {
        require(
            userClaimed(user),
            "MinterERC1155 : This user not claimed!"
        );
        
        return _claimLog[user];
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function claim(bytes32 claimHash) external virtual {
        uint256 getId = _getUnclaimed();
        _claim(getId, claimHash);
    }

    function _claim(
        uint256 id,
        bytes32 claimHash
    ) private {
        bytes32 hash = keccak256(
            abi.encodePacked(
                _domainSeparatorV4(),_msgSender()
            )
        );

        require(
            userClaimed(_msgSender()) == false,
            "MinterERC1155 : You are already claim!"
        );

        require(
            claimHash == hash,
            "MinterERC1155 : Your claim hash is invalid!"
        );
        
        IERC1155ManagedSupply(nft).mint(
            _msgSender(),
            id,
            1
        );
        _claimed[_msgSender()] = true;
        _claimLog[_msgSender()] = claimParameter(
            id,
            1
        );

        emit claimNft(
            _msgSender(),
            id,
            1
        );
    }

    function _getUnclaimed() private view returns(uint256) {
        unchecked{
            uint256 biggest;

            uint256 maxId = IERC1155ManagedSupply(nft).maxId();
            uint256[] memory listId = new uint256[](maxId+1);
            uint256[] memory remainingSupply = new uint256[](maxId+1);

            for(uint256 a; a <= maxId; a++){
                listId[a] = a;
                remainingSupply[a] = IERC1155ManagedSupply(nft).maxSupply(a) -
                IERC1155ManagedSupply(nft).totalSupply(a);
            }

            for(uint256 b = 1; b <= maxId; b++){
                if(remainingSupply[b - 1] >= remainingSupply[b]){
                    biggest = listId[b - 1];
                }else{
                    biggest = listId[b];
                }
            }

            return biggest;
        }
    }
}

// SPDX-License-Identifier: none

pragma solidity ^0.8.0;

interface IERC1155ManagedSupply {
  function addBatchMaxSupply(uint256[] memory ids, uint256[] memory amount) external;
  function addBatchMetadataHash(uint256[] memory ids, string[] memory hashes) external;
  function addMaxId(uint256 amount) external;
  function addMaxSupply(uint256 id, uint256 amount) external;
  function addMetadataHash(uint256 id, string memory hash) external;
  function balanceOf(address account, uint256 id) external view returns(uint256);
  function balanceOfBatch(address[] memory accounts, uint256[] memory ids) external view returns(uint256[] memory);
  function baseURI() external view returns(string memory);
  function burn(address account, uint256 id, uint256 value) external;
  function burnBatch(address account, uint256[] memory ids, uint256[] memory values) external;
  function exists(uint256 id) external view returns(bool);
  function isApprovedForAll(address account, address operator) external view returns(bool);
  function isManager(address user) external view returns(bool);
  function isTrustedForwarder(address forwarder) external view returns(bool);
  function maxId() external view returns(uint256);
  function maxSupply(uint256 id) external view returns(uint256);
  function mint(address account, uint256 id, uint256 value) external;
  function mintBatch(address account, uint256[] memory ids, uint256[] memory values) external;
  function name() external view returns(string memory);
  function nextId() external view returns(uint256 id);
  function owner() external view returns(address);
  function renounceOwnership() external;
  function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes calldata data) external;
  function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
  function setApprovalForAll(address operator, bool approved) external;
  function setManager(address user, bool status) external;
  function supportsInterface(bytes4 interfaceId) external view returns(bool);
  function symbol() external view returns(string memory);
  function totalSupply(uint256 id) external view returns(uint256);
  function transferOwnership(address newOwner) external;
  function trustedForwarder() external view returns(address);
  function uri(uint256 id) external view returns(string memory);
  function versionRecipient() external view returns(string memory);
}

import "./IRelayRecipient.sol";

// SPDX-License-Identifier: none

pragma solidity ^0.8.0;

abstract contract BaseRelayRecipient is IRelayRecipient {
    address private _trustedForwarder;
        string public override versionRecipient = "2.2.0";

    function trustedForwarder() public virtual view returns (address){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: none

pragma solidity ^0.8.0;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "../library/ECDSA.sol";

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

// SPDX-License-Identifier: none

pragma solidity ^0.8.0;

abstract contract IRelayRecipient {
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    function _msgSender() internal virtual view returns (address);

    function _msgData() internal virtual view returns (bytes calldata);

    function versionRecipient() external virtual view returns (string memory);
}

// SPDX-License-Identifier: none

pragma solidity ^0.8.0;

import "./Strings.sol";

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

    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

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

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: none

pragma solidity ^0.8.0;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
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