/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// hevm: flattened sources of src/truth/darwinia/POSALightClient.sol
// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.7.6;
pragma abicoder v2;

////// src/interfaces/ILightClient.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.7.6; */

interface ILightClient {
    function merkle_root() external view returns (bytes32);
}

////// src/spec/POSACommitmentScheme.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.7.6; */
/* pragma abicoder v2; */

contract POSACommitmentScheme {
    // keccak256(
    //     "Commitment(uint32 block_number,bytes32 message_root,uint256 nonce)"
    // );
    bytes32 internal constant COMMIT_TYPEHASH = 0xaca824a0c4edb3b2c17f33fea9cb21b33c7ee16c8e634c36b3bf851c9de7a223;

    /// The Commitment contains the message_root with block_number that is used for message verify
    /// @param block_number block number for the given commitment
    /// @param message_root Darwnia message root commitment hash
    struct Commitment {
        uint32 block_number;
        bytes32 message_root;
        uint256 nonce;
    }

    function hash(Commitment memory c)
        internal
        pure
        returns (bytes32)
    {
        // Encode and hash the Commitment
        return keccak256(
            abi.encode(
                COMMIT_TYPEHASH,
                c.block_number,
                c.message_root,
                c.nonce
            )
        );
    }
}

////// src/utils/ECDSA.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.7.6; */

/// @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
///
/// These functions can be used to verify that a message was signed by the holder
/// of the private keys of a given address.
library ECDSA {

    /// @dev Returns the address that signed a hashed message (`hash`) with
    /// `signature`. This address can then be used for verification purposes.
    ///
    /// The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
    /// this function rejects them by requiring the `s` value to be in the lower
    /// half order, and the `v` value to be either 27 or 28.
    ///
    /// IMPORTANT: `hash` _must_ be the result of a hash operation for the
    /// verification to be secure: it is possible to craft signatures that
    /// recover to arbitrary addresses for non-hashed data. A safe way to ensure
    /// this is by receiving a hash of the original message (which may otherwise
    /// be too long), and then calling {toEthSignedMessageHash} on it.
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }
    /// @dev Returns the address that signed a hashed message (`hash`) with
    /// `signature`. This address can then be used for verification purposes.
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        // Check the signature length
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098)
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);

        return recover(hash, v, r, s);
    }

    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /// @dev Returns an Ethereum Signed Message, created from a `hash`. This
    /// replicates the behavior of the
    /// https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
    /// JSON-RPC method.
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /// @dev Returns an Ethereum Signed Typed Data, created from a
    /// `domainSeparator` and a `structHash`. This produces hash corresponding
    /// to the one signed with the
    /// https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
    /// JSON-RPC method as part of EIP-712.
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

////// src/truth/darwinia/EcdsaAuthority.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.7.6; */
/* pragma abicoder v2; */

/* import "../../utils/ECDSA.sol"; */

/// @title Manages a set of relayers and a threshold to message commitment
/// @dev Stores the relayers and a threshold
contract EcdsaAuthority {
    /// @dev Nonce to prevent replay of update operations
    uint256 public nonce;
    /// @dev Count of all relayers
    uint256 internal count;
    /// @dev Number of required confirmations for update operations
    uint256 internal threshold;
    /// @dev Store all relayers in the linked list
    mapping(address => address) internal relayers;

    // keccak256(
    //     "chain_id | spec_name | :: | pallet_name"
    // );
    bytes32 private immutable DOMAIN_SEPARATOR;

    // Method Id of `add_relayer`
    // bytes4(keccak256("add_relayer(address,uint256)"))
    bytes4 private constant ADD_RELAYER_SIG = bytes4(0xb7aafe32);
    // Method Id of `remove_relayer`
    // bytes4(keccak256("remove_relayer(address,address,uint256)"))
    bytes4 private constant REMOVE_RELAYER_SIG = bytes4(0x8621d1fa);
    // Method Id of `swap_relayer`
    // bytes4(keccak256("swap_relayer(address,address,address)"))
    bytes4 private constant SWAP_RELAYER_SIG = bytes4(0xcb76085b);
    // Method Id of `change_threshold`
    // bytes4(keccak256("change_threshold(uint256)"))
    bytes4 private constant CHANGE_THRESHOLD_SIG = bytes4(0x3c823333);
    // keccak256(
    //     "ChangeRelayer(bytes4 sig,bytes params,uint256 nonce)"
    // );
    bytes32 private constant RELAY_TYPEHASH = 0x30a82982a8d5050d1c83bbea574aea301a4d317840a8c4734a308ffaa6a63bc8;
    address private constant SENTINEL = address(0x1);

    event AddedRelayer(address relayer);
    event RemovedRelayer(address relayer);
    event ChangedThreshold(uint256 threshold);

    /// @dev Sets initial immutable variable of contract.
    /// @param _domain_separator source chain domain_separator
    constructor(bytes32 _domain_separator) {
        DOMAIN_SEPARATOR = _domain_separator;
    }

    /// @dev initial storage of the proxy contract.
    /// @param _relayers List of relayers.
    /// @param _threshold Number of required confirmations for check commitment or change relayers.
    /// @param _nonce Nonce of initial state.
    function __ECDSA_init__(
        address[] memory _relayers,
        uint256 _threshold,
        uint256 _nonce
    ) internal {
        // Threshold can only be 0 at initialization.
        // Check ensures that setup function can only be called once.
        require(threshold == 0, "setup");
        // Validate that threshold is smaller than number of added relayers.
        require(_threshold <= _relayers.length, "!threshold");
        // There has to be at least one relayer.
        require(_threshold >= 1, "0");
        // Initializing relayers.
        address current = SENTINEL;
        for (uint256 i = 0; i < _relayers.length; i++) {
            // Relayer address cannot be null.
            address r = _relayers[i];
            require(r != address(0) && r != SENTINEL && r != address(this) && current != r, "!relayer");
            // No duplicate relayers allowed.
            require(relayers[r] == address(0), "duplicate");
            relayers[current] = r;
            current = r;
            emit AddedRelayer(r);
        }
        relayers[current] = SENTINEL;
        count = _relayers.length;
        threshold = _threshold;
        nonce = _nonce;
    }

    /// @dev Allows to add a new relayer to the registry and update the threshold at the same time.
    ///      This can only be done via multi-sig.
    /// @notice Adds the `relayer` to the registry and updates the threshold to `_threshold`.
    /// @param _relayer New relayer address.
    /// @param _threshold New threshold.
    /// @param _signatures The signatures of the relayers which to add new relayer and update the `threshold` .
    function add_relayer(
        address _relayer,
        uint256 _threshold,
        bytes[] memory _signatures
    ) external {
        // Relayer address cannot be null, the sentinel or the registry itself.
        require(_relayer != address(0) && _relayer != SENTINEL && _relayer != address(this), "!relayer");
        // No duplicate relayers allowed.
        require(relayers[_relayer] == address(0), "duplicate");
        _verify_relayer_signatures(ADD_RELAYER_SIG, abi.encode(_relayer, _threshold), _signatures);
        relayers[_relayer] = relayers[SENTINEL];
        relayers[SENTINEL] = _relayer;
        count++;
        emit AddedRelayer(_relayer);
        // Change threshold if threshold was changed.
        if (threshold != _threshold) _change_threshold(_threshold);
    }

    /// @dev Allows to remove a relayer from the registry and update the threshold at the same time.
    ///      This can only be done via multi-sig.
    /// @notice Removes the `relayer` from the registry and updates the threshold to `_threshold`.
    /// @param _prevRelayer Relayer that pointed to the relayer to be removed in the linked list
    /// @param _relayer Relayer address to be removed.
    /// @param _threshold New threshold.
    /// @param _signatures The signatures of the relayers which to remove a relayer and update the `threshold` .
    function remove_relayer(
        address _prevRelayer,
        address _relayer,
        uint256 _threshold,
        bytes[] memory _signatures
    ) external {
        // Only allow to remove a relayer, if threshold can still be reached.
        require(count - 1 >= _threshold, "!threshold");
        // Validate relayer address and check that it corresponds to relayer index.
        require(_relayer != address(0) && _relayer != SENTINEL, "!relayer");
        require(relayers[_prevRelayer] == _relayer, "!pair");
        _verify_relayer_signatures(REMOVE_RELAYER_SIG, abi.encode(_prevRelayer, _relayer, _threshold), _signatures);
        relayers[_prevRelayer] = relayers[_relayer];
        relayers[_relayer] = address(0);
        count--;
        emit RemovedRelayer(_relayer);
        // Change threshold if threshold was changed.
        if (threshold != _threshold) _change_threshold(_threshold);
    }

    /// @dev Allows to swap/replace a relayer from the registry with another address.
    ///      This can only be done via multi-sig.
    /// @notice Replaces the `oldRelayer` in the registry with `newRelayer`.
    /// @param _prevRelayer Relayer that pointed to the relayer to be replaced in the linked list
    /// @param _oldRelayer Relayer address to be replaced.
    /// @param _newRelayer New relayer address.
    /// @param _signatures The signatures of the guards which to swap/replace a relayer and update the `threshold` .
    function swap_relayer(
        address _prevRelayer,
        address _oldRelayer,
        address _newRelayer,
        bytes[] memory _signatures
    ) external {
        // Relayer address cannot be null, the sentinel or the registry itself.
        require(_newRelayer != address(0) && _newRelayer != SENTINEL && _newRelayer != address(this), "!relayer");
        // No duplicate guards allowed.
        require(relayers[_newRelayer] == address(0), "duplicate");
        // Validate oldRelayer address and check that it corresponds to relayer index.
        require(_oldRelayer != address(0) && _oldRelayer != SENTINEL, "!oldRelayer");
        require(relayers[_prevRelayer] == _oldRelayer, "!pair");
        _verify_relayer_signatures(SWAP_RELAYER_SIG, abi.encode(_prevRelayer, _oldRelayer, _newRelayer), _signatures);
        relayers[_newRelayer] = relayers[_oldRelayer];
        relayers[_prevRelayer] = _newRelayer;
        relayers[_oldRelayer] = address(0);
        emit RemovedRelayer(_oldRelayer);
        emit AddedRelayer(_newRelayer);
    }

    /// @dev Allows to update the number of required confirmations by relayers.
    ///      This can only be done via multi-sig.
    /// @notice Changes the threshold of the registry to `_threshold`.
    /// @param _threshold New threshold.
    /// @param _signatures The signatures of the guards which to update the `threshold` .
    function change_threshold(uint256 _threshold, bytes[] memory _signatures) external {
        _verify_relayer_signatures(CHANGE_THRESHOLD_SIG, abi.encode(_threshold), _signatures);
        _change_threshold(_threshold);
    }

    function _change_threshold(uint256 _threshold) private {
        // Validate that threshold is smaller than number of owners.
        require(_threshold <= count, "!threshold");
        // There has to be at least one guard.
        require(_threshold >= 1, "0");
        threshold = _threshold;
        emit ChangedThreshold(threshold);
    }

    function get_threshold() public view returns (uint256) {
        return threshold;
    }

    function is_relayer(address _relayer) public view returns (bool) {
        return _relayer != SENTINEL && relayers[_relayer] != address(0);
    }

    /// @dev Returns array of relayers.
    /// @return Array of relayers.
    function get_relayers() public view returns (address[] memory) {
        address[] memory array = new address[](count);

        // populate return array
        uint256 index = 0;
        address current = relayers[SENTINEL];
        while (current != SENTINEL) {
            array[index] = current;
            current = relayers[current];
            index++;
        }
        return array;
    }

    function _verify_relayer_signatures(
        bytes4 methodID,
        bytes memory params,
        bytes[] memory signatures
    ) private {
        bytes32 structHash =
            keccak256(
                abi.encode(
                    RELAY_TYPEHASH,
                    methodID,
                    params,
                    nonce
                )
            );
        _check_relayer_signatures(structHash, signatures);
        nonce++;
    }

    /// @dev Checks whether the signature provided is valid for the provided data, hash. Will revert otherwise.
    /// @param structHash The struct Hash of the data (could be either a message/commitment hash).
    /// @param signatures Signature data that should be verified. only ECDSA signature.
    ///  Signers need to be sorted in ascending order
    function _check_relayer_signatures(
        bytes32 structHash,
        bytes[] memory signatures
    ) internal view {
        // Load threshold to avoid multiple storage loads
        uint256 _threshold = threshold;
        // Check that a threshold is set
        require(_threshold > 0, "!threshold");
        bytes32 dataHash = encode_data_hash(structHash);
        _check_n_signatures(dataHash, signatures, _threshold);
    }

    /// @dev Checks whether the signature provided is valid for the provided data, hash. Will revert otherwise.
    /// @param dataHash Hash of the data (could be either a message hash or transaction hash).
    /// @param signatures Signature data that should be verified. only ECDSA signature.
    /// Signers need to be sorted in ascending order
    /// @param requiredSignatures Amount of required valid signatures.
    function _check_n_signatures(
        bytes32 dataHash,
        bytes[] memory signatures,
        uint256 requiredSignatures
    ) private view {
        // Check that the provided signature data is not too short
        require(signatures.length >= requiredSignatures, "signatures");
        // There cannot be an owner with address 0.
        address last = address(0);
        address current;
        for (uint256 i = 0; i < requiredSignatures; i++) {
            current = ECDSA.recover(dataHash, signatures[i]);
            require(current > last && relayers[current] != address(0) && current != SENTINEL, "!signer");
            last = current;
        }
    }

    function domain_separator() public view returns (bytes32) {
        return DOMAIN_SEPARATOR;
    }

    function encode_data_hash(bytes32 structHash) private view returns (bytes32) {
        return ECDSA.toTypedDataHash(domain_separator(), structHash);
    }
}

////// src/truth/darwinia/POSALightClient.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.7.6; */
/* pragma abicoder v2; */

/* import "./EcdsaAuthority.sol"; */
/* import "../../spec/POSACommitmentScheme.sol"; */
/* import "../../interfaces/ILightClient.sol"; */

contract POSALightClient is POSACommitmentScheme, EcdsaAuthority, ILightClient {
    event MessageRootImported(uint256 block_number, bytes32 message_root);

    uint256 internal latest_block_number;
    bytes32 internal latest_message_root;

    constructor(
        bytes32 _domain_separator,
        address[] memory _relayers,
        uint256 _threshold,
        uint256 _nonce
    ) EcdsaAuthority(_domain_separator) {
        __ECDSA_init__(_relayers, _threshold, _nonce);
    }

    function block_number() public view returns (uint256) {
        return latest_block_number;
    }

    function merkle_root() public view override returns (bytes32) {
        return latest_message_root;
    }

    /// @dev Import message commitment which signed by RelayAuthorities
    /// @param commitment contains the message_root with block_number that is used for message verify
    /// @param signatures The signatures of the relayers signed the commitment.
    function import_message_commitment(
        Commitment calldata commitment,
        bytes[] calldata signatures
    ) external {
        // Hash the commitment
        bytes32 commitment_hash = hash(commitment);
        // Commitment match the nonce of ecdsa-authority
        require(commitment.nonce == nonce, "!nonce");
        // Verify commitment signed by ecdsa-authority
        _check_relayer_signatures(commitment_hash, signatures);
        // Only import new block
        require(commitment.block_number > latest_block_number, "!new");
        latest_block_number = commitment.block_number;
        latest_message_root = commitment.message_root;
        emit MessageRootImported(commitment.block_number, commitment.message_root);
    }
}