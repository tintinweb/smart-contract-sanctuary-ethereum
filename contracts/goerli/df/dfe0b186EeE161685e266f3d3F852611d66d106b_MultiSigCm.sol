// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

//SPDX-License-Identifier: MIT
//Cyril Maranber 11 2022 Scaffold eth multisig challenge
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MultiSigCm {
    using ECDSA for bytes32;

    address public self;
    uint8 public signRequired = 2;

    address[] members;
    enum Role {
        NULL,
        ADMIN,
        OFFICER,
        USER,
        GOD
    }
    struct Params {
        bytes callData;
        address to;
        uint256 amount;
        uint8 signRequired;
        uint256 txId;
    }

    mapping(address => Role) membersRoles;
    mapping(uint256 => bool) txSent; //when a txId is receive this mapping is set to true

    event NewSignerEvent(address signer, Role role);
    event RemovedSignerEvent(address signer);
    event SigneRequiredEvent(uint8 signerRequired);
    event TxSent(address to, uint256 value, bytes callData);

    modifier onlySelf() {
        require(msg.sender == self, "not self");
        _;
    }

    constructor() {
        self = address(this);
        members.push(0x97843608a00e2bbc75ab0C1911387E002565DEDE);
        membersRoles[0x97843608a00e2bbc75ab0C1911387E002565DEDE] = Role.GOD; //buildguild multisig
        members.push(0x67dFe20b5F8Bc81C64Ef121bF8e4228FB4CBC60B);
        membersRoles[0x67dFe20b5F8Bc81C64Ef121bF8e4228FB4CBC60B] = Role.GOD; //localhost
        members.push(0x34aA3F359A9D614239015126635CE7732c18fDF3);
        membersRoles[0x34aA3F359A9D614239015126635CE7732c18fDF3] = Role.ADMIN; //Austin
        members.push(0xB810b728E44df56eAf4Da93DDd08168B3660753f);
        membersRoles[0xB810b728E44df56eAf4Da93DDd08168B3660753f] = Role.ADMIN; //cyril
      
    }

    function isValidSignature(bytes32 _hash, bytes memory signature)
        internal view
        returns (uint8)
    {
        address signer = _hash.toEthSignedMessageHash().recover(signature);
        // sender = signer;
        for (uint8 i = 0; i < members.length; i++) {
            if (members[i] == signer) {
                if (membersRoles[signer] == Role.GOD) { return 255 ;} 
                return 1;
            }
        }
        return 0;
    }

    function getHash(
        bytes memory _callData,
        address _to,
        uint256 _amount,
        uint8 _signRequired,
        uint256 _txId
    ) public pure returns (bytes32 _hash) {
        // function getHash(uint8 _functionCalled, uint8 _signRequired) public pure returns (bytes32 _hash) {
        Params memory data;
        data.callData = _callData;
        data.to = _to;
        data.amount = _amount;
        data.signRequired = _signRequired;
        data.txId = _txId;
        return (keccak256(abi.encode(data)));
    }

    function execute(
        bytes calldata _callData,
        address _to,
        uint256 _amount,
        uint8 _signRequired,
        uint256 _txId,
        bytes[] memory signatures
    ) external returns (bytes memory results){
        // require(signatures.length >= signRequired, "not enough signaures !");
        require(txSent[_txId] == false, "transaction allready sent ! ");
        Params memory data;
        data.callData = _callData;
        data.to = _to;
        data.amount = _amount;
        data.signRequired = _signRequired;
        data.txId = _txId;
        bytes32 msgHash = keccak256(abi.encode(data));
        uint8 validSignature = 0;
        for (uint8 i = 0; i < signatures.length; i++) {
                if (isValidSignature(msgHash, signatures[i]) == 255) {
                    validSignature = 255;
                    break;
                    }
                else {
                    validSignature += isValidSignature(msgHash, signatures[i]);
                }
                if (validSignature >= signRequired) {
                    break;
                } //gas saving
            }
        require(validSignature >= signRequired, "not enough valide signatures !");
        txSent[_txId] = true; //to avoid to sent the same tx multiple times
        (bool s, bytes memory result) = _to.call{value :_amount}(_callData);
        require (s, "call tx Failed");
        emit TxSent(_to, _amount, _callData);
        return result;
    }

    function changeRole (address member, Role role) public {
        require (role != Role.NULL, "Cant set a null role !");
        require ((membersRoles[member] != Role.NULL), "not a memeber !");
        membersRoles[member] = role;
    }

    function addSigner(address _newSigner) public onlySelf {
        members.push(_newSigner);
        membersRoles[_newSigner] = Role.USER;
        emit NewSignerEvent(_newSigner, membersRoles[_newSigner]);
    }

    function removeSigner(address _Signer) public onlySelf {
        bool done = false;
        uint8 index;
        for (uint8 i = 0; i < members.length; i++) {
            if (members[i] == _Signer) {
                index = i;
                done = true;
            }
        }
        require(done, "Signer not fund");
        require(members.length > 1, "Last signer can't be removed !");
        membersRoles[members[index]] = Role.NULL; //erasing the member role
        for (uint256 i = index; i < members.length - 1; i++) {
            // shifting the element in the array from index to the last
            members[i] = members[i + 1];
        }
        members.pop(); //remove the last entry of the array
        if (signRequired > members.length && signRequired > 1) {
            signRequired--;
        } //should maybe use a require statement to be sure that there will never be more signature needed that members ??...
        emit RemovedSignerEvent(_Signer);
    }

    function setSignersRequired(uint8 _signRequired) public onlySelf {
        require(_signRequired <= members.length, "Can't have more signers than members");
        signRequired = _signRequired;
        emit SigneRequiredEvent(signRequired);
    }

    function getSigners() public view returns (address[] memory) {
        return members;
    }

    function getMemberRole(address member) public view returns (Role) {
        return membersRoles[member];
    }
    receive()external payable {}

    fallback() external payable {}
}