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
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "../interfaces/IUTXO.sol";

import "../libs/UTXOArray.sol";
import "../libs/UTXOPaginator.sol";

contract EthereumUTXO is IUTXO {
    using ECDSA for bytes32;
    using ECDSA for bytes;

    using UTXOArray for UTXOArray.Array;
    using Paginator for UTXOArray.Array;

    uint256 public constant MAX_UTXOS = 10;

    UTXOArray.Array internal UTXOs;

    function deposit(address token_, Output[] calldata outputs_) external override {
        require(outputs_.length > 0, "EthereumUTXO: empty outputs");
        require(outputs_.length <= MAX_UTXOS, "EthereumUTXO: too many outputs");

        uint256 amount_ = _getTotalAmount(outputs_);

        IERC20(token_).transferFrom(msg.sender, address(this), amount_);

        UTXOs.addOutputs(token_, outputs_);
    }

    function withdraw(Input memory input_, address to_) external override {
        if (input_.id >= UTXOs.length()) {
            revert UtxoNotFound();
        }

        UTXO memory utxo_ = UTXOs.at(input_.id);
        require(!utxo_.isSpent, "EthereumUTXO: UTXO has been spent");

        bytes memory data_ = abi.encodePacked(input_.id, to_);
        require(
            utxo_.owner == keccak256(data_).toEthSignedMessageHash().recover(input_.signature),
            "EthereumUTXO: invalid signature"
        );

        UTXOs.remove(input_.id);

        IERC20(utxo_.token).transfer(to_, utxo_.amount);
    }

    function transfer(Input[] memory inputs_, Output[] memory outputs_) external override {
        require(outputs_.length != 0, "EthereumUTXO: outputs can not be empty");
        require(inputs_.length != 0, "EthereumUTXO: inputs can not be empty");

        uint256 outAmount_ = 0;
        uint256 inAmount_ = 0;

        bytes memory data_;
        for (uint i = 0; i < outputs_.length; i++) {
            outAmount_ += outputs_[i].amount;
            data_ = abi.encodePacked(data_, outputs_[i].amount, outputs_[i].owner);
        }

        uint256 UTXOsLength_ = UTXOs.length();

        if (inputs_[0].id >= UTXOsLength_) {
            revert UtxoNotFound();
        }
        address token_ = UTXOs._values[inputs_[0].id].token;

        for (uint i = 0; i < inputs_.length; i++) {
            if (inputs_[i].id >= UTXOsLength_) {
                revert UtxoNotFound();
            }

            UTXO memory utxo_ = UTXOs._values[inputs_[i].id];

            require(token_ == utxo_.token, "EthereumUTXO: UTXO token mismatch");
            require(!utxo_.isSpent, "EthereumUTXO: UTXO has been spent");
            require(
                utxo_.owner ==
                    keccak256(abi.encodePacked(inputs_[i].id, data_))
                        .toEthSignedMessageHash()
                        .recover(inputs_[i].signature),
                "EthereumUTXO: invalid signature"
            );

            inAmount_ += utxo_.amount;
            UTXOs._values[inputs_[i].id].isSpent = true;
        }

        require(inAmount_ == outAmount_, "EthereumUTXO: input and output amount mismatch");

        UTXOs.addOutputs(token_, outputs_);
    }

    function listUTXOs(
        uint256 offset_,
        uint256 limit_
    ) external view override returns (UTXO[] memory) {
        return UTXOs.part(offset_, limit_);
    }

    function listUTXOsByAddress(
        address address_,
        uint256 offset_,
        uint256 limit_
    ) external view override returns (UTXO[] memory) {
        return UTXOs.partByAddress(address_, offset_, limit_);
    }

    function getUTXOsLength() external view override returns (uint256) {
        return UTXOs.length();
    }

    function getUTXOById(uint256 id_) external view override returns (UTXO memory) {
        if (id_ >= UTXOs.length()) {
            revert UtxoNotFound();
        }

        return UTXOs._values[id_];
    }

    function getUTXOByIds(uint256[] memory ids_) external view override returns (UTXO[] memory) {
        return UTXOs.getUTXOByIds(ids_);
    }

    function _getTotalAmount(Output[] calldata outputs_) private pure returns (uint256 result) {
        for (uint i = 0; i < outputs_.length; i++) {
            result += outputs_[i].amount;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title UTXO-ERC20 interface
 */
interface IUTXO {
    /**
     * @dev Structure that represents a UTXO in the contract state.
     *
     * Contains the following information:
     *  - `id`: unique identifier of the UTXO
     *  - `token`: address of the token stored in the UTXO
     *  - `amount`: amount of the token stored in the UTXO
     *  - `owner`: address of the owner of the UTXO
     *  - `isSpent`: flag indicating if the UTXO has been spent
     */
    struct UTXO {
        uint256 id;
        address token;
        uint256 amount;
        address owner;
        bool isSpent;
    }

    /**
     * @dev Structure that represents an Output for creating a UTXO.
     *
     * Contains the following information:
     *  - `amount`: amount of the token to be stored in the UTXO
     *  - `owner`: address of the owner of the UTXO
     */
    struct Output {
        uint256 amount;
        address owner;
    }

    /**
     * @dev Structure that represents an Input for spending a UTXO.
     *
     * Contains the following information:
     *  - `id`: unique identifier of the UTXO to be spent
     *  - `signature`: signature signed by the owner of the UTXO, proving ownership
     *
     * The signed data always contains the `id` of the UTXO to be spent.
     * If the operation is a transfer, the signed data also includes concatenated data from the Outputs.
     * If the operation is a withdraw, the signed data also includes the address of the receiver.
     */
    struct Input {
        uint256 id;
        bytes signature;
    }

    error UtxoNotFound();

    /**
     * @dev Deposits an ERC20 token to the contract by creating UTXOs.
     * Before depositing, ensure that the transfer is approved on the token contract.
     *
     * @param token_ Address of the ERC20 token to be deposited.
     * @param outputs_ Array of Output structs containing information about the UTXOs to be created.
     */
    function deposit(address token_, Output[] memory outputs_) external;

    /**
     * @dev Withdraws an ERC20 token from the contract by spending a UTXO.
     *
     * @param input_ Input struct containing information about the UTXO to be spent.
     * @param to_ Address to withdraw the tokens to.
     */
    function withdraw(Input memory input_, address to_) external;

    /**
     * @dev Transfers an ERC20 token from one UTXO to another
     * by spending the source UTXOs and creating the target UTXOs.
     *
     * @param inputs_ Array of Input structs containing information about the UTXOs to be spent.
     * @param outputs_ Array of Output structs containing information about the UTXOs to be created.
     */
    function transfer(Input[] memory inputs_, Output[] memory outputs_) external;

    /**
     * @dev Returns a list of UTXO objects in the storage, starting from the offset and up to the limit.
     * @param offset_ The position in UTXO array from which the list will start.
     * @param limit_ The maximum number of UTXOs in the list.
     * @return The list of UTXOs.
     */
    function listUTXOs(uint256 offset_, uint256 limit_) external view returns (UTXO[] memory);

    /**
     * @dev Returns a list of UTXO objects in the storage owned by the specified address,
     * starting from the offset and limited by the limit.
     * @param address_ The address of the UTXO owner.
     * @param offset_ The position in UTXO array from which the list will start.
     * @param limit_ The maximum number of UTXOs in the list.
     * @return The list of UTXOs owned by the specified address.
     */
    function listUTXOsByAddress(
        address address_,
        uint256 offset_,
        uint256 limit_
    ) external view returns (UTXO[] memory);

    /**
     * @dev Returns the length of the UTXO array.
     * @return The length of the UTXO array.
     */
    function getUTXOsLength() external view returns (uint256);

    /**
     * @dev Returns the UTXO object with the specified ID from the UTXO array.
     * @param id_ The ID of the UTXO.
     * @return The UTXO object with the specified ID.
     */
    function getUTXOById(uint256 id_) external view returns (UTXO memory);

    /**
     * @dev Returns the list of UTXO objects with the specified IDs from the UTXO array.
     * @param ids_ The IDs of the UTXOs.
     * @return The list of UTXO objects with the specified IDs.
     */
    function getUTXOByIds(uint256[] memory ids_) external view returns (UTXO[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../interfaces/IUTXO.sol";

/**
 *  @notice A library for managing an UTXO set
 */
library UTXOArray {
    struct Array {
        IUTXO.UTXO[] _values;
    }

    function addOutputs(
        Array storage array,
        address token_,
        IUTXO.Output[] memory outputs_
    ) internal {
        uint id_ = array._values.length;

        for (uint i = 0; i < outputs_.length; i++) {
            array._values.push(
                IUTXO.UTXO(id_++, token_, outputs_[i].amount, outputs_[i].owner, false)
            );
        }
    }

    function remove(Array storage array, uint256 id_) internal {
        array._values[id_].isSpent = true;
    }

    function getUTXOByIds(
        Array storage array,
        uint256[] memory ids_
    ) internal view returns (IUTXO.UTXO[] memory utxos) {
        utxos = new IUTXO.UTXO[](ids_.length);

        uint256 length_ = array._values.length;
        for (uint256 i = 0; i < ids_.length; i++) {
            if (ids_[i] >= length_) {
                revert IUTXO.UtxoNotFound();
            }

            utxos[i] = array._values[ids_[i]];
        }
    }

    function length(Array storage array) internal view returns (uint256) {
        return array._values.length;
    }

    function at(Array storage array, uint256 index_) internal view returns (IUTXO.UTXO memory) {
        return array._values[index_];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Vector.sol";
import "./UTXOArray.sol";

/**
 *  @notice Library for UTXO pagination.
 */
library Paginator {
    using Vector for Vector.Vector;
    using UTXOArray for UTXOArray.Array;

    /**
     *  @notice Returns part of an array.
     *
     *  Examples:
     *  - part([4, 5, 6, 7], 0, 4) will return [4, 5, 6, 7]
     *  - part([4, 5, 6, 7], 2, 4) will return [6, 7]
     *  - part([4, 5, 6, 7], 2, 1) will return [6]
     *
     *  @param array Storage array.
     *  @param offset_ Offset, index in an array.
     *  @param limit_ Number of elements after the `offset`.
     */
    function part(
        UTXOArray.Array storage array,
        uint256 offset_,
        uint256 limit_
    ) internal view returns (IUTXO.UTXO[] memory list_) {
        uint256 to_ = _handleIncomingParametersForPart(array.length(), offset_, limit_);

        list_ = new IUTXO.UTXO[](to_ - offset_);

        for (uint256 i = offset_; i < to_; i++) {
            list_[i - offset_] = array.at(i);
        }
    }

    /**
     * @dev Returns a list of UTXO objects in the storage array owned by the specified address,
     * starting from the offset and up to the limit.
     * @param array The UTXO array.
     * @param user_ The address of the UTXO owner.
     * @param offset_ The position in UTXO array from which the list will start.
     * @param limit_ The maximum number of UTXO in the list.
     * @return list_ The list of unspent UTXO owned by the specified address.
     */
    function partByAddress(
        UTXOArray.Array storage array,
        address user_,
        uint256 offset_,
        uint256 limit_
    ) internal view returns (IUTXO.UTXO[] memory) {
        uint256 to_ = _handleIncomingParametersForPart(array.length(), offset_, limit_);

        Vector.Vector memory vector_ = Vector.init();

        for (uint256 i = offset_; i < to_; i++) {
            if (array.at(i).owner == user_ && !array.at(i).isSpent) {
                vector_.push(bytes32(uint256(array.at(i).id)));
            }
        }

        return array.getUTXOByIds(vector_.toUint256Array());
    }

    function _handleIncomingParametersForPart(
        uint256 length_,
        uint256 offset_,
        uint256 limit_
    ) private pure returns (uint256 to_) {
        to_ = offset_ + limit_;

        if (to_ > length_) {
            to_ = length_;
        }

        if (offset_ > to_) {
            to_ = offset_;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Vector {
    struct Vector {
        uint256 _allocation;
        uint256 _dataPointer;
    }

    function init() internal pure returns (Vector memory self) {
        self._allocation = 5;
        self._dataPointer = _allocate(5);
    }

    function init(uint256 length_) internal pure returns (Vector memory self) {
        uint256 dataPointer_ = _allocate(length_ + 1);

        self._allocation = length_ + 1;
        self._dataPointer = dataPointer_;

        assembly {
            mstore(dataPointer_, length_)
        }
    }

    function init(bytes32[] memory array_) internal pure returns (Vector memory self) {
        assembly {
            mstore(self, add(mload(array_), 0x1))
            mstore(add(self, 0x20), array_)
        }
    }

    function push(Vector memory self, bytes32 value_) internal pure {
        uint256 length_ = length(self);

        if (length_ + 1 == self._allocation) {
            _resize(self, self._allocation * 2);
        }

        assembly {
            let dataPointer_ := mload(add(self, 0x20))

            mstore(dataPointer_, add(length_, 0x1))
            mstore(add(dataPointer_, add(mul(length_, 0x20), 0x20)), value_)
        }
    }

    function pop(Vector memory self) internal pure {
        uint256 length_ = length(self);

        require(length_ > 0, "Vector: empty vector");

        assembly {
            mstore(mload(add(self, 0x20)), sub(length_, 0x1))
        }
    }

    function set(Vector memory self, uint256 index_, bytes32 value_) internal pure {
        _requireInBounds(self, index_);

        assembly {
            mstore(add(mload(add(self, 0x20)), add(mul(index_, 0x20), 0x20)), value_)
        }
    }

    function at(Vector memory self, uint256 index_) internal pure returns (bytes32 value_) {
        _requireInBounds(self, index_);

        assembly {
            value_ := mload(add(mload(add(self, 0x20)), add(mul(index_, 0x20), 0x20)))
        }
    }

    function length(Vector memory self) internal pure returns (uint256 length_) {
        assembly {
            length_ := mload(mload(add(self, 0x20)))
        }
    }

    function toArray(Vector memory self) internal pure returns (bytes32[] memory array_) {
        assembly {
            array_ := mload(add(self, 0x20))
        }
    }

    function toUint256Array(Vector memory self) internal pure returns (uint256[] memory array_) {
        assembly {
            array_ := mload(add(self, 0x20))
        }
    }

    function _resize(Vector memory self, uint256 newAllocation_) private pure {
        uint256 newDataPointer_ = _allocate(newAllocation_);

        assembly {
            let oldDataPointer_ := mload(add(self, 0x20))
            let length_ := mload(oldDataPointer_)

            for {
                let i := 0
            } lt(i, add(mul(length_, 0x20), 0x20)) {
                i := add(i, 0x20)
            } {
                mstore(add(newDataPointer_, i), mload(add(oldDataPointer_, i)))
            }

            mstore(self, newAllocation_)
            mstore(add(self, 0x20), newDataPointer_)
        }
    }

    function _requireInBounds(Vector memory self, uint256 index_) private pure {
        require(index_ < length(self), "Vector: out of bounds");
    }

    function _allocate(uint256 allocation_) private pure returns (uint256 pointer_) {
        assembly {
            pointer_ := mload(0x40)
            mstore(0x40, add(pointer_, mul(allocation_, 0x20)))
        }
    }
}