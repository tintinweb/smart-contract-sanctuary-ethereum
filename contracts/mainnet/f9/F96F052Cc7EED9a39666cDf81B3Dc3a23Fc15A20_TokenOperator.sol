//SPDX-License-Identifier: MIT
//author: Evabase core team
pragma solidity 0.8.16;
import "./interfaces/IOriConfig.sol";
import "./interfaces/ITokenOperator.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/ILicenseToken.sol";
import "./interfaces/IDerivativeToken.sol";
import "./interfaces/IMintFeeSettler.sol";
import "./interfaces/IOriFactory.sol";
import "./interfaces/IApproveAuthorization.sol";
import "./lib/ConsiderationStructs.sol";
import "./lib/ConsiderationConstants.sol";
import "./lib/ConfigHelper.sol";
import "./lib/OriginMulticall.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "./interfaces/IBatchAction.sol";

/**
 * @title NFT Mint  Manager
 * @author ace
 * @notice Just work for Mint or Burn token.
 */
contract TokenOperator is ITokenOperator, IERC1155Receiver, OriginMulticall {
    using ConfigHelper for IOriConfig;
    IOriConfig internal constant _CONFIG = IOriConfig(CONFIG);

    /*
     * @dev Returns the mint fee settler address.
     * If no Mint fee is charged, return the zero address.
     */
    function settlementHouse() external view returns (address) {
        return _CONFIG.settlementHouse();
    }

    /*
     * @dev Returns the ori config address.
     */
    function config() external pure returns (address) {
        return address(_CONFIG);
    }

    function receiveApproveAuthorization(ApproveAuthorization[] calldata approves) external {
        for (uint256 i = 0; i < approves.length; i++) {
            address tokenAdd = approves[i].token;
            IApproveAuthorization(tokenAdd).approveForAllAuthorization(
                approves[i].from,
                approves[i].to,
                approves[i].validAfter,
                approves[i].validBefore,
                approves[i].salt,
                approves[i].signature
            );
        }
    }

    /**
     * @notice calcute the mint fee for license token.
     * @dev The default formula see `allowMint` function.
     *
     *  >    Fee (ETH) =  BaseFactor  * amount * (expiredAt - now)
     *
     * @param amount is the amount of minted.
     * @param expiredAt is the expiration tiem of the given license token `token`.`id`.
     */
    function calculateMintFee(uint256 amount, uint64 expiredAt) public view returns (uint256) {
        uint256 baseF = _CONFIG.mintFeeBP();
        // solhint-disable-next-line not-rely-on-time
        return ((baseF * amount * (expiredAt - block.timestamp)) / 1 days);
    }

    /**
     * @notice Deploy dtoken smart contract & Creates `amount` tokens of token, and assigns them to `msg.sender`.
     * @param meta is the token meta information.
     *
     * Requirements:
     *
     * - If `msg.sender` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function createDerivativeToNew(
        string memory dName,
        string memory dSymbol,
        uint256 amount,
        bytes calldata meta
    ) external {
        address dToken = _factory().deployDerivative721(dName, dSymbol);
        _createDerivative(ITokenActionable(dToken), amount, meta);
    }

    /**
     * @notice Creates `amount` tokens of token, and assigns them to `_msgsender()`.
     *
     * Requirements:
     *
     * - `token` must be enabled on ori protocol.
     * - If `_msgsender()` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function createDerivative(
        ITokenActionable dToken,
        uint256 amount,
        bytes calldata meta
    ) external {
        bool isLic = _factory().requireRegistration(address(dToken));
        if (isLic) revert invalidTokenType();

        _createDerivative(dToken, amount, meta);
    }

    function createLicense(
        address originToken,
        uint256 amount,
        bytes calldata meta
    ) external payable {
        IOriFactory factory = _factory();
        address license = factory.licenseToken(originToken);
        if (license == address(0)) {
            factory.createOrignPair(originToken);
            license = factory.licenseToken(originToken);
            if (license == address(0)) revert notFoundLicenseToken();
        }
        _createLicense(ITokenActionable(license), amount, meta);
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `_msgsender()`.
     *
     * Requirements:
     * - `token` must be enabled on ori protocol.
     * - If `_msgsender()` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function mint(
        ITokenActionable token,
        uint256 id,
        uint256 amount
    ) external payable {
        _mint(token, id, amount);
    }

    /**
     * @dev Destroys `amount` tokens of `token` type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `token` must be enabled on ori protocol.
     */
    function burn(
        ITokenActionable token,
        uint256 id,
        uint256 amount
    ) external {
        _factory().requireRegistration(address(token));
        token.burn(_msgsender(), id, amount);
    }

    function _mint(
        ITokenActionable token,
        uint256 id,
        uint256 amount
    ) internal {
        bool isLic = _factory().requireRegistration(address(token));
        address origin = token.originToken();
        if (isLic) {
            LicenseMeta memory lMeta = ILicenseToken(address(token)).meta(id);
            require(lMeta.earnPoint <= _CONFIG.maxEarnBP(), "over 10%");
            _handellicenseMintFee(amount, lMeta.expiredAt);
        } else {
            DerivativeMeta memory dmeta = IDerivativeToken(address(token)).meta(id);
            _useLicese(dmeta.licenses, origin);
        }

        token.mint(_msgsender(), id, amount);
        emit Mint(msg.sender, address(token), id, amount);
    }

    function _createLicense(
        ITokenActionable token,
        uint256 amount,
        bytes calldata meta
    ) internal {
        (uint256 originTokenId, uint256 earnPoint, uint64 expiredAt) = abi.decode(meta, (uint256, uint16, uint64));
        require(earnPoint <= _CONFIG.maxEarnBP(), "over 10%");
        //must have 721 origin NFT
        address origin = token.originToken();
        if (IERC165(origin).supportsInterface(ERC721_IDENTIFIER)) {
            require(IERC721(origin).ownerOf(originTokenId) == _msgsender(), "origin NFT721 is 0");
        } else if (IERC165(origin).supportsInterface(ERC1155_IDENTIFIER)) {
            require(IERC1155(origin).balanceOf(_msgsender(), originTokenId) > 0, "otoken's amount=0");
        } else {
            revert notSupportNftTypeError();
        }
        _handellicenseMintFee(amount, expiredAt);
        token.create(_msgsender(), meta, amount);
        emit Mint(msg.sender, address(token), token.nonce() - 1, amount);
    }

    function _createDerivative(
        ITokenActionable token,
        uint256 amount,
        bytes calldata meta
    ) internal {
        address origin = token.originToken();
        (NFT[] memory licenses, , ) = abi.decode(meta, (NFT[], uint256, uint256));
        _useLicese(licenses, origin);
        token.create(_msgsender(), meta, amount);
        emit Mint(msg.sender, address(token), token.nonce() - 1, amount);
    }

    //Note that when OToken is 0 address
    function _useLicese(NFT[] memory licenses, address origin) internal {
        require(licenses.length > 0, "invalid length");
        bool isHaveOrigin = origin == address(0);
        //use licese to create
        for (uint256 i = 0; i < licenses.length; i++) {
            IERC1155(licenses[i].token).safeTransferFrom(_msgsender(), address(this), licenses[i].id, 1, "");
            if (!isHaveOrigin) {
                isHaveOrigin = origin == ITokenActionable(licenses[i].token).originToken();
            }
        }

        require(isHaveOrigin, "need match license");
    }

    function _handellicenseMintFee(uint256 amount, uint64 expiredAt) internal {
        address feeTo = _CONFIG.mintFeeReceiver();
        if (feeTo == address(0)) {
            Address.sendValue(payable(msg.sender), msg.value);
        } else {
            uint256 totalFee = calculateMintFee(amount, expiredAt);
            require(msg.value >= totalFee, "invalid fee");
            Address.sendValue(payable(feeTo), totalFee);
            if (msg.value > totalFee) {
                Address.sendValue(payable(msg.sender), msg.value - totalFee);
            }
        }
    }

    function _factory() internal view returns (IOriFactory) {
        address factory = _CONFIG.oriFactory();
        require(factory != address(0), "factory is empty");
        return IOriFactory(factory);
    }

    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    //solhint-disable no-unused-vars
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    //solhint-disable no-unused-vars
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == ERC1155_TOKEN_RECEIVER_IDENTIFIER;
    }
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;

/**
 * @title Ori Config Center
 * @author ysqi
 * @notice  Manage all configs for ori protocol.
 * each config the type of item key is bytes32, the item value type is bytes32 too.
 */
interface IOriConfig {
    /*
     * @notice White list change event
     * @param key
     * @param value is the new value.
     */
    event ChangeWhite(address indexed key, bool value);

    /*
     * @notice Configuration change event
     * @param key
     * @param value is the new value.
     */
    event Changed(bytes32 indexed key, bytes32 value);

    /*
     * @notice Configuration change event
     * @param key
     * @param value is the new value.
     */
    event ChangedBytes(bytes32 indexed key, bytes value);

    /**
     * @dev Returns the value of the given configuration item.
     */
    function get(bytes32 key) external view returns (bytes32);

    /**
     * @dev Returns value of the given configuration item.
     * Safely convert the bytes32 value to address before returning.
     */
    function getAddress(bytes32 key) external view returns (address);

    /**
     * @dev Returns value of the given configuration item.
     */
    function getUint256(bytes32 key) external view returns (uint256);

    /**
     * @notice Reset the configuration item value to an address.
     *
     * Emits an `Changed` event.
     *
     * Requirements:
     *
     * - Only the administrator can call it.
     *
     * @param key is the key of configuration item.
     * @param value is the new value of the given item `key`.
     */
    function resetAddress(bytes32 key, address value) external;

    /**
     * @notice Reset the configuration item value to a uint256.
     *
     * Emits an `Changed` event.
     *
     * Requirements:
     *
     * - Only the administrator can call it.
     *
     * @param key is the key of configuration item.
     * @param value is the new value of the given item `key`.
     */
    function resetUint256(bytes32 key, uint256 value) external;

    /**
     * @notice Reset the configuration item value to a bytes32.
     *
     * Emits an `Changed` event.
     *
     * Requirements:
     *
     * - Only the administrator can call it.
     *
     * @param key is the key of configuration item.
     * @param value is the new value of the given item `key`.
     */
    function reset(bytes32 key, bytes32 value) external;

    /**
     * @dev Returns the bytes.
     */
    function getBytes(bytes32 key) external view returns (bytes memory);

    /**
     * @notice  set the configuration item value to a bytes.
     *
     * Emits an `ChangedBytes` event.
     *
     * Requirements:
     *
     * - Only the administrator can call it.
     *
     * @param key is the key of configuration item.
     * @param value is the new value of the given item `key`.
     */
    function setBytes(bytes32 key, bytes memory value) external;
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity ^0.8.0;

import "../lib/ConsiderationStructs.sol";
import "./ITokenActionable.sol";
import "./IMintFeeSettler.sol";
import "../lib/ConsiderationEnums.sol";

/**
 * @title NFT Mint  Manager
 * @author ysqi
 * @notice Just work for Mint or Burn token.
 */
interface ITokenOperator {
    event Mint(address indexed to, address indexed token, uint256 tokenId, uint256 amount);

    /*
     * @dev Returns the mint fee settler address.
     * If no Mint fee is charged, return the zero address.
     */
    function settlementHouse() external view returns (address);

    /*
     * @dev Returns the ori config address.
     */
    function config() external view returns (address);

    function receiveApproveAuthorization(ApproveAuthorization[] calldata approves) external;

    /**
     * @notice Creates `amount` tokens of token, and assigns them to `msg.sender`.
     * @param meta is the token meta information.
     *
     * Requirements:
     *
     * - `token` must be enabled on ori protocol.
     * - If `msg.sender` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function createDerivative(
        ITokenActionable token,
        uint256 amount,
        bytes calldata meta
    ) external;

    /**
     * @notice Deploy dtoken smart contract & Creates `amount` tokens of token, and assigns them to `msg.sender`.
     * @param meta is the token meta information.
     *
     * Requirements:
     *
     * - If `msg.sender` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function createDerivativeToNew(
        string memory dName,
        string memory dSymbol,
        uint256 amount,
        bytes calldata meta
    ) external;

    function createLicense(
        address originToken,
        uint256 amount,
        bytes calldata meta
    ) external payable;

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `msg.sender`.
     *
     * Requirements:
     * - `token` must be enabled on ori protocol.
     * - If `msg.sender` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function mint(
        ITokenActionable token,
        uint256 id,
        uint256 amount
    ) external payable;

    /**
     * @dev Destroys `amount` tokens of `token` type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `token` must be enabled on ori protocol.
     */
    function burn(
        ITokenActionable token,
        uint256 id,
        uint256 amount
    ) external;
}

interface ITOkenOperatorWithBatch is ITokenOperator {
    event BatchMint(address indexed to, address indexed token, uint256[] tokenIds, uint256[] amounts);

    /**
     * @notice batch-operations version of `create`.
     *
     * Requirements:
     *
     * - `token` must be enabled on ori protocol.
     * - If `msg.sender` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function batchCreate(
        ITokenActionable token,
        uint256[] calldata amounts,
        bytes[] calldata metas
    ) external payable;

    /**
     * @dev batch-operations version of `mint`
     *
     * Requirements:
     * - `token` must be enabled on ori protocol.
     * - If `msg.sender` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     * - `ids` and `amounts` must have the same length.
     */
    function batchMint(
        ITokenActionable token,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external payable;

    /**
     * @dev batch-operations version of `burn`
     *
     * Requirements:
     *
     * - `token` must be enabled on ori protocol.
     * - `ids` and `amounts` must have the same length.
     */
    function batchBurn(
        ITokenActionable token,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external payable;
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

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;
import "./IApproveAuthorization.sol";
import "./ITokenActionable.sol";

/**
 * @title NFT License token
 * @author ysqi
 * @notice NFT License token protocol.
 */
interface ILicenseToken is IApproveAuthorization, ITokenActionable {
    function initialize(address creator, address origin) external;

    /**
     * @notice return the license meta data.
     *
     * Requirements:
     *
     * - `id` must be exist.
     * @param id is the token id.
     * @return LicenseMeta:
     *
     *    uint256 originTokenId;
     *    uint16 earnPoint;
     *    uint64 expiredAt;
     */
    function meta(uint256 id) external view returns (LicenseMeta calldata);

    /**
     * @notice return the license[] metas data.
     *
     * Requirements:
     *
     * - `id` must be exist.
     * @param ids is the token ids.
     * @return LicenseMetas:
     *
     *    uint256 originTokenId;
     *    uint16 earnPoint;
     *    uint64 expiredAt;
     */
    function metas(uint256[] memory ids) external view returns (LicenseMeta[] calldata);

    /*
     * @notice return whether NFT has expired.
     *
     * Requirements:
     *
     * - `id` must be exist.
     *
     * @param id is the token id.
     * @return bool returns whether NFT has expired.
     */
    function expired(uint256 id) external view returns (bool);
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;

import "../lib/ConsiderationStructs.sol";

/**
 * @title NFT Derivative token
 * @author ysqi
 * @notice NFT Derivative token protocol.
 */
interface IDerivativeToken {
    function initialize(
        address creator,
        address originToken,
        string memory name,
        string memory symbol
    ) external;

    /**
     * @notice return the Derivative[] metas data.
     *
     * Requirements:
     *
     * - `id` must be exist.
     * @param id is the token id.
     * @return DerivativeMeta
     */
    function meta(uint256 id) external view returns (DerivativeMeta calldata);

    /**
     * @notice return the license[] metas data.
     *
     * Requirements:
     *
     * - `id` must be exist.
     * @param ids is the token ids.
     * @return DerivativeMetas:
     *
     */
    function metas(uint256[] memory ids) external view returns (DerivativeMeta[] calldata);
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;

/**
 * @title  License Token Mint Fee Settler
 * @author ysqi
 * @notice Licens token mint fee management settlement center.
 */
interface IMintFeeSettler {
    /**
     * @notice Triggered when a Derivative contract is traded
     *
     * Requirements:
     *
     * 1. this Trade need allocation value
     * 2 .Settlement of the last required allocation
     * 3. Maintain records of pending settlements
     * 4. update total last Unclaim amount
     */
    function afterTokenTransfer(
        address op,
        address from,
        address to,
        uint256[] memory ids
    ) external;

    function afterTokenTransfer(
        address op,
        address from,
        address to,
        uint256 id
    ) external;

    /**
     * @notice settle the previous num times of records
     *
     */
    function settleLastUnclaim(uint32 num) external;
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;
import "../lib/ConsiderationEnums.sol";

/**
 * @title Ori Protocol NFT Token Factory
 * @author ysqi
 * @notice management License and Derivative NFT token.
 */
interface IOriFactory {
    event TokenEnabled(address token);
    event TokenDisabled(address token);
    event LicenseTokenDeployed(address originToken, address license);
    event DerivativeTokenDeployed(address originToken, address derivative);

    function requireRegistration(address token) external view returns (bool isLicense);

    function licenseToken(address originToken) external view returns (address);

    function derivativeToken(address originToken) external view returns (address);

    /**
     * @notice enable the given nft token.
     *
     * Emits an {TokenEnabled} event.
     *
     * Requirements:
     *
     * - The nft token `token` must been created by OriFactory.
     * - The `token` must be unenabled.
     * - Only the administrator can call it.
     *
     * @param token  is License or Derivative contract address.
     *
     */
    function enableToken(address token) external;

    /**
     * @notice disable the given nft token.
     *
     * Emits an {TokenDisabled} event.
     *
     * Requirements:
     *
     * - The `token` must be enabled.
     * - Only the administrator can call it.
     *
     * @param token  is License or Derivative contract address.
     *
     */
    function disableToken(address token) external;

    /**
     * @notice Create default license and derivative token contracts for the given NFT.
     * @dev Ori can deploy licenses and derivative contracts for every NFT contract.
     * Then each NFT's licens and derivatives will be stand-alone.
     * helping to analyz this NFT and makes the NFT managment structure clear and concise.
     *
     * Every one can call it to deploy license and derivative contracts for the given NFT.
     * but this created contracts is disabled, need the administrator to enable them.
     * them will be enabled immediately if the caller is an administrator.
     *
     * Emits a `LicenseTokenDeployed` and a `Derivative1155TokenDeployed` event.
     * And there are tow `TokenEnabled` events if the caller is an administrator.
     *
     *
     * Requirements:
     *
     * - The `originToken` must be NFT contract.
     * - Each NFT Token can only set one default license and derivative contract.
     *
     * @param originToken is the NFT contract.
     *
     */
    function createOrignPair(address originToken) external;

    /**
     * @notice Create a empty derivative NFT contract
     * @dev Allow every one to call it to create derivative NFT contract.
     * Only then can Ori whitelist it. and this new contract will be enabled immediately.
     *
     * Emits a `Derivative1155TokenDeployed` event. the event parameter `originToken` is zero.
     * And there are a `TokenEnabled` event if the caller is an administrator.
     */
    function deployDerivative721(string memory dName, string memory dSymbol) external returns (address token);

    function deployDerivative1155() external returns (address token);
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;

/**
 * @title  Atomic approve token
 * @author ysqi
 * @notice gives permission to transfer token to another account on this call.
 */
interface IApproveAuthorization {
    /**
     * @notice the `from` gives permission to `to` to transfer token to another account on this call.
     * The approval is cleared when the call is end.
     *
     * Emits an `AtomicApproved` event.
     *
     * Requirements:
     *
     * - `to` must be the same with `msg.sender`. and it must implement {IApproveSet-onAtomicApproveSet}, which is called after approve.
     * - `to` can't be the `from`.
     * - `nonce` can only be used once.
     * - The validity of this authorization operation must be between `validAfter` and `validBefore`.
     *
     * @param from        from's address (Authorizer)
     * @param to      to's address
     * @param validAfter    The time after which this is valid (unix time)
     * @param validBefore   The time before which this is valid (unix time)
     * @param salt          Unique salt
     * @param signature     the signature
     */
    function approveForAllAuthorization(
        address from,
        address to,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 salt,
        bytes memory signature
    ) external;
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;

import "./ConsiderationEnums.sol";

// NFT 标识
struct NFT {
    address token; //该 NFT 所在合约地址
    uint256 id; // 该 NFT ID 标识符
}

struct DerivativeMeta {
    NFT[] licenses; // 二创NFT所携带的 Licenses 清单
    uint256 supplyLimit; // 供给上限
    uint256 totalSupply; //当前总已供给数量
}

// License NFT 元数据
struct LicenseMeta {
    uint256 originTokenId; // License 所属 NFT
    uint16 earnPoint; // 单位是10000,原NFT持有人从二创NFT交易中赚取的交易额比例，100= 1%
    uint64 expiredAt; // 该 License 过期时间，过期后不能用于创建二仓作品
}

// approve sign data
struct ApproveAuthorization {
    address token;
    address from; //            from        from's address (Authorizer)
    address to; //     to's address
    uint256 validAfter; // The time after which this is valid (unix time)
    uint256 validBefore; // The time before which this is valid (unix time)
    bytes32 salt; // Unique salt
    bytes signature; //  the signature
}

//Store a pair of addresses
struct PairStruct {
    address licenseAddress;
    address derivativeAddress;
}

struct Settle {
    address recipient;
    uint256 value;
    uint256 index;
}

//SPDX-License-Identifier: MIT
//author: Evabase core team
pragma solidity 0.8.16;

// Operator Address For Newly created NFT contract operator for managing collections in Opensea
bytes32 constant CONFIG_OPERATPR_ALL_NFT_KEY = keccak256("CONFIG_OPERATPR_ALL_NFT");

//  Mint Settle Address
bytes32 constant CONFIG_DAFAULT_MINT_SETTLE_ADDRESS_KEY = keccak256("CONFIG_DAFAULT_MINT_SETTLE_ADDRESS");

bytes32 constant CONFIG_LICENSE_MINT_FEE_RECEIVER_KEY = keccak256("CONFIG_LICENSE_MINT_FEE_RECEIVER");

// nft edtior
bytes32 constant CONFIG_NFT_EDITOR_KEY = keccak256("CONFIG_NFT_EDITOR_ADDRESS");

// NFT Factory Contract Address
bytes32 constant CONFIG_NFTFACTORY_KEY = keccak256("CONFIG_NFTFACTORY_ADDRESS");

//Default owner address for NFT
bytes32 constant CONFIG_ORI_OWNER_KEY = keccak256("CONFIG_ORI_OWNER_ADDRESS");

// Default Mint Fee 0.00001 ETH
bytes32 constant CONFIG_LICENSE_MINT_FEE_KEY = keccak256("CONFIG_LICENSE_MINT_FEE_BP");

//Default Base url for NFT eg:https://ori-static.particle.network/
bytes32 constant CONFIG_NFT_BASE_URI_KEY = keccak256("CONFIG_NFT_BASE_URI");

//Default Contract URI  for NFT eg:https://ori-static.particle.network/
bytes32 constant CONFIG_NFT_BASE_CONTRACT_URL_KEY = keccak256("CONFIG_NFT_BASE_CONTRACT_URI");

// Max licese Earn Point Para
bytes32 constant CONFIG_MAX_LICENSE_EARN_POINT_KEY = keccak256("CONFIG_MAX_LICENSE_EARN_POINT");

bytes32 constant CONFIG_LICENSE_ERC1155_IMPL_KEY = keccak256("CONFIG_LICENSE_ERC1155_IMPL");
bytes32 constant CONFIG_DERIVATIVE_ERC721_IMPL_KEY = keccak256("CONFIG_DERIVATIVE_ERC721_IMPL");
bytes32 constant CONFIG_DERIVATIVE_ERC1155_IMPL_KEY = keccak256("CONFIG_DERIVATIVE_ERC1155_IMPL");

// salt=0x0000000000000000000000000000000000000000000000987654321123456789
address constant CONFIG = 0x94745d1a874253760Ca5B47dc3DB8E4185D7b8Dd;

// https://eips.ethereum.org/EIPS/eip-721
bytes4 constant ERC721_METADATA_IDENTIFIER = 0x5b5e139f;
bytes4 constant ERC721_IDENTIFIER = 0x80ac58cd;
// https://eips.ethereum.org/EIPS/eip-1155
bytes4 constant ERC1155_IDENTIFIER = 0xd9b67a26;
bytes4 constant ERC1155_TOKEN_RECEIVER_IDENTIFIER = 0x4e2312e0;

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;

import "../interfaces/IOriConfig.sol";
import "./ConsiderationConstants.sol";

library ConfigHelper {
    function oriFactory(IOriConfig cfg) internal view returns (address) {
        return cfg.getAddress(CONFIG_NFTFACTORY_KEY);
    }

    function isExchange(IOriConfig cfg, address acct) internal view returns (bool) {
        return cfg.getUint256(keccak256(abi.encode("EXCHANGE", acct))) == 1;
    }

    function oriAdmin(IOriConfig cfg) internal view returns (address) {
        return cfg.getAddress(CONFIG_ORI_OWNER_KEY);
    }

    function mintFeeReceiver(IOriConfig cfg) internal view returns (address) {
        return cfg.getAddress(CONFIG_LICENSE_MINT_FEE_RECEIVER_KEY);
    }

    function nftEditor(IOriConfig cfg) internal view returns (address) {
        return cfg.getAddress(CONFIG_NFT_EDITOR_KEY);
    }

    function operator(IOriConfig cfg) internal view returns (address) {
        return cfg.getAddress(CONFIG_OPERATPR_ALL_NFT_KEY);
    }

    function maxEarnBP(IOriConfig cfg) internal view returns (uint256) {
        return cfg.getUint256(CONFIG_MAX_LICENSE_EARN_POINT_KEY);
    }

    function mintFeeBP(IOriConfig cfg) internal view returns (uint256) {
        return cfg.getUint256(CONFIG_LICENSE_MINT_FEE_KEY);
    }

    function settlementHouse(IOriConfig cfg) internal view returns (address) {
        return cfg.getAddress(CONFIG_DAFAULT_MINT_SETTLE_ADDRESS_KEY);
    }
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;

import "../interfaces/OriErrors.sol";

/// @title Calling multiple methods
/// @author ysqi
/// @notice Supports calling multiple methods of this contract at once.
contract OriginMulticall {
    address private _multicallSender;

    /**
     * @notice Calling multiple methods of this contract at once.
     * @dev Each item of the `datas` array represents a method call.
     *
     * Each item data contains calldata and ETH value.
     * We call decode call data from item of `datas`.
     *
     *     (bytes memory data, uint256 value)= abi.decode(datas[i],(bytes,uint256));
     *
     * Will reverted if a call failed.
     *
     *
     *
     */
    function multicall(bytes[] calldata datas) external payable returns (bytes[] memory results) {
        require(_multicallSender == address(0), "reentrant call");
        // enter the multicall mode.
        _multicallSender = msg.sender;

        // call
        results = new bytes[](datas.length);
        for (uint256 i = 0; i < datas.length; i++) {
            (bytes memory data, uint256 value) = abi.decode(datas[i], (bytes, uint256));
            //solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory returndata) = address(this).call{value: value}(data);
            results[i] = _verifyCallResult(success, returndata);
        }
        // exit
        _multicallSender = address(0);
        return results;
    }

    function _msgsender() internal view returns (address) {
        // call from  multicall if _multicallSender is not the zero address.
        return _multicallSender != address(0) && msg.sender == address(this) ? _multicallSender : msg.sender;
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function _verifyCallResult(bool success, bytes memory returndata) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                //solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert UnknownLowLevelCallFailed();
            }
        }
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;
import "../lib/ConsiderationStructs.sol";

/**
 * @title define token mint or burn actions
 * @author ysqi
 * @notice Two types of Tokens within the Ori protocol need to support Mint and Burn operations.
 */
interface IBatchAction {
    /**
     * @dev batch-operations version of `create`.
     *
     * Requirements:
     *
     * - `metas` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function batchCreate(
        address to,
        bytes[] calldata metas,
        uint256[] calldata amounts
    ) external;

    /**
     * @dev batch-operations version of `mint`
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     * - `ids` and `amounts` must have the same length.
     */
    function batchMint(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external;

    /**
     * @dev batch-operations version of `burn`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     * - `ids` and `amounts` must have the same length.
     */
    function batchBurn(
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external;
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;
import "../lib/ConsiderationStructs.sol";

/**
 * @title define token mint or burn actions
 * @author ysqi
 * @notice Two types of Tokens within the Ori protocol need to support Mint and Burn operations.
 */
interface ITokenActionable {
    /*
     * @dev Returns the NFT operator address(ITokenOperator).
     * Only operator can mint or burn OriLicense/OriDerivative/ NFT.
     */

    function operator() external view returns (address);

    function creator() external view returns (address);

    /**
     * @dev Returns the editor of the current collection on Opensea.
     * this editor will be configured in the `IOriConfig` contract.
     */
    function owner() external view returns (address);

    /*
     * @dev Returns the OriLicense/OriDerivative slave NFT contract address.
     * If no origin NFT, returns zero address.
     */
    function originToken() external view returns (address);

    /**
     * @notice Creates `amount` tokens of token type `id`, and assigns them to `to`.
     * @param meta is the token meta information.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function create(
        address to,
        bytes calldata meta,
        uint256 amount
    ) external;

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external;

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external;

    /**
     *@dev Retruns the last tokenId of this token.
     */
    function nonce() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;

/**
 * @dev the standard of token
 */
enum TokenStandard {
    Unknow,
    // 1 - ERC20 Token
    ERC20,
    // 2 - ERC721 Token (NFT)
    ERC721,
    // 3 - ERC1155 Token (NFT)
    ERC1155
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
pragma solidity >=0.8.16;

/**
 * @dev Revert with an error when a signature that does not contain a v
 *      value of 27 or 28 has been supplied.
 *
 * @param v The invalid v value.
 */
error BadSignatureV(uint8 v);

/**
 * @dev Revert with an error when the signer recovered by the supplied
 *      signature does not match the offerer or an allowed EIP-1271 signer
 *      as specified by the offerer in the event they are a contract.
 */
error InvalidSigner();

/**
 * @dev Revert with an error when a signer cannot be recovered from the
 *      supplied signature.
 */
error InvalidSignature();

/**
 * @dev Revert with an error when an EIP-1271 call to an account fails.
 */
error BadContractSignature();

/**
 * @dev Revert with an error when low-level call with value failed without reason.
 */
error UnknownLowLevelCallFailed();

/**
 * @dev Errors that occur when NFT expires transfer
 */
error expiredError(uint256 id);

/**
 * @dev atomicApproveForAll:approve to op which no implementer
 */
error atomicApproveForAllNoImpl();

/**
 * @dev address in not contract
 */
error notContractError();

/**
 * @dev not support EIP NFT error
 */
error notSupportNftTypeError();

/**
 * @dev not support TokenKind  error
 */
error notSupportTokenKindError();

/**
 * @dev not support function  error
 */
error notSupportFunctionError();

error nftEditorIsEmpty();

error invalidTokenType();

error notFoundLicenseToken();

error amountIsZero();

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