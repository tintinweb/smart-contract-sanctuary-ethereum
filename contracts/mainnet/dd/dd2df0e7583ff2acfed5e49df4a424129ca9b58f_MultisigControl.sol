//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "./IMultisigControl.sol";

/// @title MultisigControl
/// @author Vega Protocol
/// @notice This contract enables validators, through a multisignature process, to run functions on contracts by consensus
contract MultisigControl is IMultisigControl {
    constructor() {
        // set initial threshold to 50%
        threshold = 500;
        signers[msg.sender] = true;
        signer_count++;
        emit SignerAdded(msg.sender, 0);
    }

    uint16 threshold;
    uint8 signer_count;
    mapping(address => bool) public signers;
    mapping(uint256 => bool) used_nonces;

    /**************************FUNCTIONS*********************/
    /// @notice Sets threshold of signatures that must be met before function is executed.
    /// @param new_threshold New threshold value
    /// @param nonce Vega-assigned single-use number that provides replay attack protection
    /// @param signatures Vega-supplied signature bundle of a validator-signed order
    /// @notice See MultisigControl for more about signatures
    /// @notice Ethereum has no decimals, threshold is % * 10 so 50% == 500 100% == 1000
    /// @notice signatures are OK if they are >= threshold count of total valid signers
    /// @dev Emits ThresholdSet event
    function set_threshold(
        uint16 new_threshold,
        uint256 nonce,
        bytes calldata signatures
    ) external override {
        require(new_threshold < 1000 && new_threshold > 0, "new threshold outside range");
        bytes memory message = abi.encode(new_threshold, nonce, "set_threshold");
        require(verify_signatures(signatures, message, nonce), "bad signatures");
        threshold = new_threshold;
        emit ThresholdSet(new_threshold, nonce);
    }

    /// @notice Adds new valid signer and adjusts signer count.
    /// @param new_signer New signer address
    /// @param nonce Vega-assigned single-use number that provides replay attack protection
    /// @param signatures Vega-supplied signature bundle of a validator-signed order
    /// @notice See MultisigControl for more about signatures
    /// @dev Emits 'SignerAdded' event
    function add_signer(
        address new_signer,
        uint256 nonce,
        bytes calldata signatures
    ) external override {
        bytes memory message = abi.encode(new_signer, nonce, "add_signer");
        require(!signers[new_signer], "signer already exists");
        require(verify_signatures(signatures, message, nonce), "bad signatures");
        signers[new_signer] = true;
        signer_count++;
        emit SignerAdded(new_signer, nonce);
    }

    /// @notice Removes currently valid signer and adjusts signer count.
    /// @param old_signer Address of signer to be removed.
    /// @param nonce Vega-assigned single-use number that provides replay attack protection
    /// @param signatures Vega-supplied signature bundle of a validator-signed order
    /// @notice See MultisigControl for more about signatures
    /// @dev Emits 'SignerRemoved' event
    function remove_signer(
        address old_signer,
        uint256 nonce,
        bytes calldata signatures
    ) external override {
        bytes memory message = abi.encode(old_signer, nonce, "remove_signer");
        require(signers[old_signer], "signer doesn't exist");
        require(verify_signatures(signatures, message, nonce), "bad signatures");
        signers[old_signer] = false;
        signer_count--;
        emit SignerRemoved(old_signer, nonce);
    }

    /// @notice Burn an nonce before it gets used by a user. Useful in case the validators needs to prevents a malicious user to do un-permitted action.
    /// @param nonce Vega-assigned single-use number that provides replay attack protection
    /// @param signatures Vega-supplied signature bundle of a validator-signed order
    /// @notice See MultisigControl for more about signatures
    /// @dev Emits 'NonceBurnt' event
    function burn_nonce(uint256 nonce, bytes calldata signatures) external override {
        bytes memory message = abi.encode(nonce, "burn_nonce");
        require(verify_signatures(signatures, message, nonce), "bad signatures");
        emit NonceBurnt(nonce);
    }

    /// @notice Verifies a signature bundle and returns true only if the threshold of valid signers is met,
    /// @notice this is a function that any function controlled by Vega MUST call to be securely controlled by the Vega network
    /// @notice message to hash to sign follows this pattern:
    /// @notice abi.encode( abi.encode(param1, param2, param3, ... , nonce, function_name_string), validating_contract_or_submitter_address);
    /// @notice Note that validating_contract_or_submitter_address is the submitting party. If on MultisigControl contract itself, it's the submitting ETH address
    /// @notice if function on bridge that then calls Multisig, then it's the address of that contract
    /// @notice Note also the embedded encoding, this is required to verify what function/contract the function call goes to
    /// @return Returns true if valid signatures are over the threshold
    function verify_signatures(
        bytes calldata signatures,
        bytes memory message,
        uint256 nonce
    ) public override returns (bool) {
        require(signatures.length % 65 == 0, "bad sig length");
        require(signatures.length > 0, "must contain at least 1 sig");
        require(!used_nonces[nonce], "nonce already used");

        uint8 size = 0;
        address[] memory signers_temp = new address[](signer_count);

        bytes32 message_hash = keccak256(abi.encode(message, msg.sender));
        uint256 offset;
        assembly {
            offset := signatures.offset
        }
        for (uint256 msg_idx = 0; msg_idx < signatures.length; msg_idx += 65) {
            //recover address from that msg
            bytes32 r;
            bytes32 s;
            uint8 v;
            assembly {
                // first 32 bytes, after the length prefix
                r := calldataload(add(offset, msg_idx))
                // second 32 bytes
                s := calldataload(add(add(offset, msg_idx), 32))
                // final byte (first byte of the next 32 bytes)
                v := byte(0, calldataload(add(add(offset, msg_idx), 64)))
            }
            // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
            // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
            // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
            // signatures from current libraries generate a unique signature with an s-value in the lower half order.
            //
            // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
            // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
            // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
            // these malleable signatures as well.
            require(
                uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
                "Malleable signature error"
            );
            if (v < 27) v += 27;

            address recovered_address = ecrecover(message_hash, v, r, s);

            if (signers[recovered_address] && !has_signed(signers_temp, recovered_address, size)) {
                signers_temp[size] = recovered_address;
                size++;
            }
        }

        used_nonces[nonce] = ((uint256(size) * 1000) / (uint256(signer_count))) > threshold;
        return used_nonces[nonce];
    }

    function has_signed(
        address[] memory signers_temp,
        address signer,
        uint8 size
    ) private pure returns (bool) {
        for (uint256 i; i < size; i++) {
            if (signers_temp[i] == signer) {
                return true;
            }
        }
        return false;
    }

    /// @return Number of valid signers
    function get_valid_signer_count() external view override returns (uint8) {
        return signer_count;
    }

    /// @return Current threshold
    function get_current_threshold() external view override returns (uint16) {
        return threshold;
    }

    /// @param signer_address target potential signer address
    /// @return true if address provided is valid signer
    function is_valid_signer(address signer_address) external view override returns (bool) {
        return signers[signer_address];
    }

    /// @param nonce Nonce to lookup
    /// @return true if nonce has been used
    function is_nonce_used(uint256 nonce) external view override returns (bool) {
        return used_nonces[nonce];
    }
}

/**
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMWEMMMMMMMMMMMMMMMMMMMMMMMMMM...............MMMMMMMMMMMMM
MMMMMMLOVEMMMMMMMMMMMMMMMMMMMMMM...............MMMMMMMMMMMMM
MMMMMMMMMMHIXELMMMMMMMMMMMM....................MMMMMNNMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMM....................MMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMM88=........................+MMMMMMMMMM
MMMMMMMMMMMMMMMMM....................MMMMM...MMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMM....................MMMMM...MMMMMMMMMMMMMMM
MMMMMMMMMMMM.........................MM+..MMM....+MMMMMMMMMM
MMMMMMMMMNMM...................... ..MM?..MMM.. .+MMMMMMMMMM
MMMMNDDMM+........................+MM........MM..+MMMMMMMMMM
MMMMZ.............................+MM....................MMM
MMMMZ.............................+MM....................MMM
MMMMZ.............................+MM....................DDD
MMMMZ.............................+MM..ZMMMMMMMMMMMMMMMMMMMM
MMMMZ.............................+MM..ZMMMMMMMMMMMMMMMMMMMM
MM..............................MMZ....ZMMMMMMMMMMMMMMMMMMMM
MM............................MM.......ZMMMMMMMMMMMMMMMMMMMM
MM............................MM.......ZMMMMMMMMMMMMMMMMMMMM
MM......................ZMMMMM.......MMMMMMMMMMMMMMMMMMMMMMM
MM............... ......ZMMMMM.... ..MMMMMMMMMMMMMMMMMMMMMMM
MM...............MMMMM88~.........+MM..ZMMMMMMMMMMMMMMMMMMMM
MM.......$DDDDDDD.......$DDDDD..DDNMM..ZMMMMMMMMMMMMMMMMMMMM
MM.......$DDDDDDD.......$DDDDD..DDNMM..ZMMMMMMMMMMMMMMMMMMMM
MM.......ZMMMMMMM.......ZMMMMM..MMMMM..ZMMMMMMMMMMMMMMMMMMMM
MMMMMMMMM+.......MMMMM88NMMMMM..MMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMM+.......MMMMM88NMMMMM..MMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM*/