/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

// File contracts/interfaces/IOwnable.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IOwnable {
    error NotOwner();
    error InvalidOwner();

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;
}


// File contracts/interfaces/IAxelarAuth.sol

interface IAxelarAuth is IOwnable {
    function validateProof(bytes32 messageHash, bytes calldata proof) external returns (bool currentOperators);

    function transferOperatorship(bytes calldata params) external;
}


// File contracts/interfaces/IAxelarAuthWeighted.sol

interface IAxelarAuthWeighted is IAxelarAuth {
    error InvalidOperators();
    error InvalidThreshold();
    error DuplicateOperators();
    error MalformedSigners();
    error LowSignaturesWeight();
    error InvalidWeights();

    event OperatorshipTransferred(address[] newOperators, uint256[] newWeights, uint256 newThreshold);

    function currentEpoch() external view returns (uint256);

    function hashForEpoch(uint256 epoch) external view returns (bytes32);

    function epochForHash(bytes32 hash) external view returns (uint256);
}


// File contracts/ECDSA.sol

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    error InvalidSignatureLength();
    error InvalidS();
    error InvalidV();
    error InvalidSignature();

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
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address signer) {
        // Check the signature length
        if (signature.length != 65) revert InvalidSignatureLength();

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

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) revert InvalidS();

        if (v != 27 && v != 28) revert InvalidV();

        // If the signature is valid (and not malleable), return the signer address
        if ((signer = ecrecover(hash, v, r, s)) == address(0)) revert InvalidSignature();
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', hash));
    }
}


// File contracts/Ownable.sol

abstract contract Ownable is IOwnable {
    address public owner;

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        if (owner != msg.sender) revert NotOwner();

        _;
    }

    function transferOwnership(address newOwner) external virtual onlyOwner {
        if (newOwner == address(0)) revert InvalidOwner();

        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


// File contracts/auth/AxelarAuthWeighted.sol

contract AxelarAuthWeighted is Ownable, IAxelarAuthWeighted {
    uint256 public currentEpoch;
    mapping(uint256 => bytes32) public hashForEpoch;
    mapping(bytes32 => uint256) public epochForHash;

    uint8 internal constant OLD_KEY_RETENTION = 16;

    constructor(bytes[] memory recentOperators) {
        for (uint256 i; i < recentOperators.length; ++i) {
            _transferOperatorship(recentOperators[i]);
        }
    }

    /**************************\
    |* External Functionality *|
    \**************************/

    /// @dev This function takes messageHash and proof data and reverts if proof is invalid
    /// @return True if provided operators are the current ones
    function validateProof(bytes32 messageHash, bytes calldata proof) external view returns (bool) {
        (address[] memory operators, uint256[] memory weights, uint256 threshold, bytes[] memory signatures) = abi.decode(
            proof,
            (address[], uint256[], uint256, bytes[])
        );

        bytes32 operatorsHash = keccak256(abi.encode(operators, weights, threshold));
        uint256 operatorsEpoch = epochForHash[operatorsHash];
        uint256 epoch = currentEpoch;

        if (operatorsEpoch == 0 || epoch - operatorsEpoch >= OLD_KEY_RETENTION) revert InvalidOperators();

        _validateSignatures(messageHash, operators, weights, threshold, signatures);

        return operatorsEpoch == epoch;
    }

    /***********************\
    |* Owner Functionality *|
    \***********************/

    function transferOperatorship(bytes calldata params) external onlyOwner {
        _transferOperatorship(params);
    }

    /**************************\
    |* Internal Functionality *|
    \**************************/

    function _transferOperatorship(bytes memory params) internal {
        (address[] memory newOperators, uint256[] memory newWeights, uint256 newThreshold) = abi.decode(
            params,
            (address[], uint256[], uint256)
        );
        uint256 operatorsLength = newOperators.length;
        uint256 weightsLength = newWeights.length;

        // operators must be sorted binary or alphabetically in lower case
        if (operatorsLength == 0 || !_isSortedAscAndContainsNoDuplicate(newOperators)) revert InvalidOperators();

        if (weightsLength != operatorsLength) revert InvalidWeights();

        uint256 totalWeight = 0;
        for (uint256 i = 0; i < weightsLength; ++i) {
            totalWeight += newWeights[i];
        }
        if (newThreshold == 0 || totalWeight < newThreshold) revert InvalidThreshold();

        bytes32 newOperatorsHash = keccak256(params);

        if (epochForHash[newOperatorsHash] > 0) revert DuplicateOperators();

        uint256 epoch = currentEpoch + 1;
        currentEpoch = epoch;
        hashForEpoch[epoch] = newOperatorsHash;
        epochForHash[newOperatorsHash] = epoch;

        emit OperatorshipTransferred(newOperators, newWeights, newThreshold);
    }

    function _validateSignatures(
        bytes32 messageHash,
        address[] memory operators,
        uint256[] memory weights,
        uint256 threshold,
        bytes[] memory signatures
    ) internal pure {
        uint256 operatorsLength = operators.length;
        uint256 operatorIndex = 0;
        uint256 weight = 0;
        // looking for signers within operators
        // assuming that both operators and signatures are sorted
        for (uint256 i = 0; i < signatures.length; ++i) {
            address signer = ECDSA.recover(messageHash, signatures[i]);
            // looping through remaining operators to find a match
            for (; operatorIndex < operatorsLength && signer != operators[operatorIndex]; ++operatorIndex) {}
            // checking if we are out of operators
            if (operatorIndex == operatorsLength) revert MalformedSigners();
            // return if weight sum above threshold
            weight += weights[operatorIndex];
            // weight needs to reach or surpass threshold
            if (weight >= threshold) return;
            // increasing operators index if match was found
            ++operatorIndex;
        }
        // if weight sum below threshold
        revert LowSignaturesWeight();
    }

    function _isSortedAscAndContainsNoDuplicate(address[] memory accounts) internal pure returns (bool) {
        for (uint256 i; i < accounts.length - 1; ++i) {
            if (accounts[i] >= accounts[i + 1]) {
                return false;
            }
        }

        return accounts[0] != address(0);
    }
}