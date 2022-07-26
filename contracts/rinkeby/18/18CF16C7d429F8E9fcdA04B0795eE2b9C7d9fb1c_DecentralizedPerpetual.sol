pragma solidity >= 0.8.0;

// SPDX-License-Identifier: Apache-2.0.


import "./Storage.sol";

abstract contract ConditionalTransfer is Storage {
    using SafeERC20Upgradeable for IERC20Upgradeable;

	event LogConditionalTransferProofReg(
		uint256 recieverL2Key,
		uint256 senderL2Key,
        uint64 amount,
		bytes32 condition);

	function getConditionalTransferHash(
		uint256 recieverL2Key,
		uint256 senderL2Key,
        uint64 amount
	) internal view returns (bytes32 h) {
		h = keccak256(abi.encode(
			"CONDITIONAL_TRANSFER",
			block.timestamp,
			recieverL2Key,
			senderL2Key,
        	amount
		));
	}

    function conditionalTransferRegProof(
		uint256 recieverL2Key,
		uint256 senderL2Key,
        uint64 amount
    ) internal {
		bytes32 cond = getConditionalTransferHash(
			recieverL2Key,
			senderL2Key,
        	amount
		);

		require(!proofRegister[cond], "pae"); //  "proof already exit"
		proofRegister[cond] = true;

        emit LogConditionalTransferProofReg(
			recieverL2Key,
			senderL2Key,
        	amount,
			cond
		);
    }

    function condTransfer(
		address reciever,
		uint256 recieverL2Key,
		uint256 senderL2Key,
		uint64 amount
	) external nonReentrant {
		require(ethKeys[recieverL2Key] == reciever);

        collateralToken.safeTransfer(reciever, amount);

		conditionalTransferRegProof(recieverL2Key, senderL2Key, amount);
	}
}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0


import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { SafeERC20Upgradeable, IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./verifier/I_Verifier.sol";
import "./libs/ReentrancyGuard.sol";


import "./Operations.sol";
import "./Governance.sol";


bytes32 constant EMPTY_STRING_KECCAK = keccak256("");
uint64 constant DEPOSIT_LOWER_BOUND = (1 << 63);

struct SyntheticAssetInfo {
    uint64 resolution;
    uint32 risk_factor;
    bytes12 asset_name;
    bytes oracle_price_signers_pubkey_hash;
}

/// @title Storage Contract
contract Storage is Governance, ReentrancyGuard {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    
    event LogNewGlobalConfigHash(bytes32 configHash);
    
    mapping(uint256 => uint256) public pendingDeposits;
    mapping(uint256 => uint256) public pendingWithdrawals;

    // map l2 key => timestamp.
    mapping(uint256 => uint256) public cancellationRequests;

    // map forced Action Request Hash => timestatmp
    mapping(bytes32 => uint256) forcedActionRequests;

    // Mapping for timelocked actions.
    // A actionKey => activation time.
    mapping (bytes32 => uint256) actionsTimeLock;

    // Mapping from layer2 public key to the Ethereum public key of its owner.
    // 1. used to valid withdraw request
    // 2. allows registering many different l2keys to same eth address ?
    //     2.1 user might wanna both validum and rollup account.
    //     2.2 API user might wanna multiple account.
    mapping(uint256 => address) public ethKeys;
    modifier onlyKeyOwner(uint256 ownerKey) {
        require(msg.sender == ethKeys[ownerKey], "Not ethKey Owner");
        _;
    }

    // for conditional transfer
    mapping(bytes32 => bool) proofRegister;

    mapping(uint256 => bool) escapesUsed;
    mapping(address => bool) operators;
    mapping(address => bool) public dacs;


    uint256 public DacRegisterTime;
    uint256 public newGlobalConfigValidBlockNum;
    uint256 DEPOSIT_CANCEL_TIMELOCK;
    uint256 FORCED_ACTION_EXPIRE_TIME;

    /* block chain root hash */
    bytes32 public accountRoot;
    bytes32 public orderStateHash;

    bytes32 public globalConfigHash;
    bytes32 public newGlobalConfigHash;
    
    uint32 public dacNum;
    uint32 constant MIN_SIGNATURE_MEMBER = 3;
    
    uint32 TIMELOCK_GLOBAL_CONFIG_CHANGE;
    uint32 public MIN_DAC_MEMBER;

    uint32 TIMELOCK_DAC_REG;
    uint16 public MAX_NUMBER_ORACLES;
    uint16 MAX_ASSETS_COUNT;

    uint8 systemTokenDecimal;
    uint8 public innerDecimal;

    bool public DacRegisterActive;
    bool stateFrozen;

    address pendingDacMember;
    address userAdmin;

    I_Verifier public verifier;
    I_Verifier public escapeVerifier;
    IERC20Upgradeable public collateralToken;

    function addForceRequest(bytes32 req) internal {
		require(forcedActionRequests[req] == 0, "rap0"); // REQUEST_ALREADY_PENDING
		forcedActionRequests[req] = block.timestamp;
    }

    function cancelForceRequest(bytes32 req) internal {
        delete forcedActionRequests[req];
    }

    function freeze(bytes32 req) public {
		require(forcedActionRequests[req] != 0 && forcedActionRequests[req] + FORCED_ACTION_EXPIRE_TIME > block.timestamp, "ftne0");  // "freeze timestamp not expired!"
		stateFrozen = true;
    }

    modifier onlyFrozen() {
        require(stateFrozen, "STATE_NOT_FROZEN");
        _;
    }

    modifier onlyActive() {
        require(!stateFrozen, "STATE_FROZEN");
        _;
    }
    
    
    function resetGlobalConfigValidBlockNum() internal {
        newGlobalConfigValidBlockNum = ~uint256(0);
    }
    function is_pending_global_config() internal view returns (bool) {
        return newGlobalConfigValidBlockNum != ~uint256(0);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



interface I_Verifier {

    function verifyAggregatedBlockProof(
        uint256[16] memory _subproofs_limbs,
        uint256[] memory _recursiveInput,
        uint256[] memory _proof,
        uint8[] memory _vkIndexes,
        uint256[] memory _individual_vks_inputs
    ) external view returns (bool);
}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    /// @dev Address of lock flag variable.
    /// @dev Flag is placed at random memory location to not interfere with Storage contract.
    uint256 private constant LOCK_FLAG_ADDRESS = 0x8e94fed44239eb2314ab7a406345e6c5a8f0ccedf3b600de3d004e672c33abf4; // keccak256("ReentrancyGuard") - 1;

    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/566a774222707e424896c0c390a84dc3c13bdcb2/contracts/security/ReentrancyGuard.sol
    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    function initializeReentrancyGuard() internal {
        uint256 lockSlotOldValue;

        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange every call to nonReentrant
        // will be cheaper.
        assembly {
            lockSlotOldValue := sload(LOCK_FLAG_ADDRESS)
            sstore(LOCK_FLAG_ADDRESS, _NOT_ENTERED)
        }

        // Check that storage slot for reentrancy guard is empty to rule out possibility of slot conflict
        require(lockSlotOldValue == 0, "1B");
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        uint256 _status;
        assembly {
            _status := sload(LOCK_FLAG_ADDRESS)
        }

        // On the first call to nonReentrant, _notEntered will be true
        require(_status == _NOT_ENTERED);

        // Any calls to nonReentrant after this point will fail
        assembly {
            sstore(LOCK_FLAG_ADDRESS, _ENTERED)
        }

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        assembly {
            sstore(LOCK_FLAG_ADDRESS, _NOT_ENTERED)
        }
    }
}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./libs/Bytes.sol";

library Operations {
    /// @notice operation type
    enum OpType {
        Noop,    // 0
        Deposit,
        ForceTrade,
        ForceWithdraw,
        Withdraw,
        Trade,
        Transfer,
        ConditionalTransfer,
        FundingTick,
        OraclePriceTick,
        Liquidate,
        Deleverage
    }

    struct DepositOrWithdraw {
        uint24 accountId;
        uint160 l2Key;
        uint64 amount;
    }

    function readDepositOrWithdrawPubdata(bytes memory _data, uint256 offset) internal pure returns (DepositOrWithdraw memory parsed) {
        (offset, parsed.accountId) = Bytes.readUInt24(_data, offset);   // accountId
        (offset, parsed.l2Key) = Bytes.readUInt160(_data, offset);      // l2Key
        (offset, parsed.amount) = Bytes.readUInt64(_data, offset);      // amount
    }

    uint256 constant FORCED_WITHDRAWAL_PUBDATA_BYTES = 33;
    uint256 constant CONDITIONAL_TRANSFER_PUBDATA_BYTES = 54;
    uint32 constant DEPOSIT_WITHDRAW_PUBDATA_BYTES = 31 ;

    uint32 constant ACCOUNT_COLLATERAL_BALANCE_PUBDATA_BYTES = 11 ;
    uint32 constant ACCOUNT_POSITION_PUBDATA_BYTES = 13 ;

    uint8 constant OP_TYPE_BYTES = 1;

    // Withdraw pubdata
    struct Withdraw {
        uint8 opType;    // 0x04
        uint24 accountId;
        uint160 l2Key;
        uint64 amount;
    }

    // ForcedWithdrawal pubdata
    struct ForcedWithdrawal {
        uint8 opType;    // 0x03
        uint24 accountId;
        uint160 l2Key;
        uint64 amount;
        uint8 isSuccess;
    }

    /// Deserialize forcedWithdrawal pubdata
    function readForcedWithdrawalPubdata(bytes memory _data, uint256 offset) internal pure returns (ForcedWithdrawal memory parsed) {
        offset += OP_TYPE_BYTES;
        (offset, parsed.accountId) = Bytes.readUInt24(_data, offset);   // accountId
        (offset, parsed.l2Key) = Bytes.readUInt160(_data, offset);      // l2Key
        (offset, parsed.amount) = Bytes.readUInt64(_data, offset);      // amount
        parsed.isSuccess = uint8(_data[offset++]);
    }

    struct ConditionalTransfer {
        uint8 opType;    // 0x07
        uint24 fromAccountId;
        uint24 toAccountId;
        uint64 collateralAmount;
        uint64 fee;
        bytes31 condition;
    }

    function readConditionalTransferPubdata(bytes memory _data, uint256 offset) internal pure returns (ConditionalTransfer memory parsed) {
        offset += OP_TYPE_BYTES;
        (offset, parsed.fromAccountId) = Bytes.readUInt24(_data, offset);   // accountId
        (offset, parsed.toAccountId) = Bytes.readUInt24(_data, offset);   // accountId
        (offset, parsed.collateralAmount) = Bytes.readUInt64(_data, offset);      // amount
        (offset, parsed.fee) = Bytes.readUInt64(_data, offset);      // amount
        parsed.condition = bytes31(_data[offset++]);    // TODO : fix
    }


}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title Governance Contract
abstract contract Governance {
    /// @notice Governor changed
    event NewGovernor(address newGovernor);
    event ValidatorStatusUpdate(address validatorAddress, bool isActive);

    mapping(address => bool) public validators;
    address public networkGovernor;
    

    function initGovernor(address governor, address validator) internal {
        networkGovernor = governor;
        validators[validator] = true;
    }

    modifier onlyGovernor() {
        require(msg.sender == networkGovernor, "require Governor");
        _;
    }

    /// @notice Change current governor
    /// @param _newGovernor Address of the new governor
    function changeGovernor(address _newGovernor) external onlyGovernor {
        if (networkGovernor != _newGovernor) {
            networkGovernor = _newGovernor;
            emit NewGovernor(_newGovernor);
        }
    }

    function setValidator(address _validator, bool _active) external onlyGovernor {
        if (validators[_validator] != _active) {
            validators[_validator] = _active;
            emit ValidatorStatusUpdate(_validator, _active);
        }
    }

    modifier onlyValidator() {
        require(validators[msg.sender] == true, "require Validator");
        _;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



// Functions named bytesToX, except bytesToBytes20, where X is some type of size N < 32 (size of one word)
// implements the following algorithm:
// f(bytes memory input, uint offset) -> X out
// where byte representation of out is N bytes from input at the given offset
// 1) We compute memory location of the word W such that last N bytes of W is input[offset..offset+N]
// W_address = input + 32 (skip stored length of bytes) + offset - (32 - N) == input + offset + N
// 2) We load W from memory into out, last N bytes of W are placed into out

library Bytes {

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x2)
    function bytesToUInt16(bytes memory _bytes, uint256 _start) internal pure returns (uint16 r) {
        uint256 offset = _start + 0x2;
        require(_bytes.length >= offset, "T");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x3)
    function bytesToUInt24(bytes memory _bytes, uint256 _start) internal pure returns (uint24 r) {
        uint256 offset = _start + 0x3;
        require(_bytes.length >= offset, "U");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x4)
    function bytesToUInt32(bytes memory _bytes, uint256 _start) internal pure returns (uint32 r) {
        uint256 offset = _start + 0x4;
        require(_bytes.length >= offset, "V");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x4)
    function bytesToUInt64(bytes memory _bytes, uint256 _start) internal pure returns (uint64 r) {
        uint256 offset = _start + 0x8;
        require(_bytes.length >= offset, "V64");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x10)
    function bytesToUInt128(bytes memory _bytes, uint256 _start) internal pure returns (uint128 r) {
        uint256 offset = _start + 0x10;
        require(_bytes.length >= offset, "W");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x14)
    function bytesToUInt160(bytes memory _bytes, uint256 _start) internal pure returns (uint160 r) {
        uint256 offset = _start + 0x14;
        require(_bytes.length >= offset, "X");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x20)
    function bytesToBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32 r) {
        uint256 offset = _start + 0x20;
        require(_bytes.length >= offset, "Y");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_offset + 2)
    function readUInt16(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint16 r) {
        new_offset = _offset + 2;
        r = bytesToUInt16(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 3)
    function readUInt24(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint24 r) {
        new_offset = _offset + 3;
        r = bytesToUInt24(_data, _offset);
    }

    function readUInt64(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint64 r) {
        new_offset = _offset + 8;
        r = bytesToUInt64(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readUInt160(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint160 r) {
        new_offset = _offset + 20;
        r = bytesToUInt160(_data, _offset);
    }

    // Convert bytes to ASCII hex representation
    function bytesToHexASCIIBytes(bytes memory _input) internal pure returns (bytes memory _output) {
        bytes memory outStringBytes = new bytes(_input.length * 2);

        // code in `assembly` construction is equivalent of the next code:
        // for (uint i = 0; i < _input.length; ++i) {
        //     outStringBytes[i*2] = halfByteToHex(_input[i] >> 4);
        //     outStringBytes[i*2+1] = halfByteToHex(_input[i] & 0x0f);
        // }
        assembly {
            let input_curr := add(_input, 0x20)
            let input_end := add(input_curr, mload(_input))

            for {
                let out_curr := add(outStringBytes, 0x20)
            } lt(input_curr, input_end) {
                input_curr := add(input_curr, 0x01)
                out_curr := add(out_curr, 0x02)
            } {
                let curr_input_byte := shr(0xf8, mload(input_curr))
            // here outStringByte from each half of input byte calculates by the next:
            //
            // "FEDCBA9876543210" ASCII-encoded, shifted and automatically truncated.
            // outStringByte = byte (uint8 (0x66656463626139383736353433323130 >> (uint8 (_byteHalf) * 8)))
                mstore(
                out_curr,
                shl(0xf8, shr(mul(shr(0x04, curr_input_byte), 0x08), 0x66656463626139383736353433323130))
                )
                mstore(
                add(out_curr, 0x01),
                shl(0xf8, shr(mul(and(0x0f, curr_input_byte), 0x08), 0x66656463626139383736353433323130))
                )
            }
        }
        return outStringBytes;
    }
}

pragma solidity >= 0.8.12;

// SPDX-License-Identifier: MIT OR Apache-2.0


import "./Storage.sol";
import "./Config.sol";

abstract contract UpdateState is Config, Storage {

    event LogWithdrawalAllowed(
        uint256 l2Key,
        uint256 amount
    );

    event BlockUpdate(uint32 firstBlock, uint32 lastBlock);

    struct GlobalFunding {
        uint64[] index;      // per asset when block have funding_tick transaction
        uint256 indexHashOrTimeStamp;  // if index.length==0, = bytes32 hash, else uint32 timestamp
    }

    struct CommitBlockInfo {
        uint32 blockNumber;
        uint32 timestamp;

        bytes32 accountRoot;                // root hash of account
        bytes32 validiumAccountRoot;        // for rollup merkle path, rollupAccount could be restore from pubData
        bytes32 orderRoot;

        GlobalFunding globalFunding;
        bytes32 oraclePriceHash;
        bytes32 orderStateHash;             // include funding index, oracle price, orderRoot
        bytes32 all_data_commitment;        // account Full Data Hash

        uint32 blockChunkSize;              // per pubdata type(balance/position/onchain) padding zero
        bytes collateralBalancePubData;     // per account [accountId, collateral_balance]
        bytes positonPubData;               // per account [accountId, asset_id, balance]
        bytes onchainPubData;               // per onchain operation (deposit/withdraw/...) [op_type, ...]
    }

    struct ProofInput {
        uint256[] recursiveInput;
        uint256[] proof;
        uint256[] commitments;
        uint8[] vkIndexes;
        uint256[16] subproofsLimbs;
    }

    function getPadLen(
        uint256 realSize,
        uint32 alignSize
    ) internal pure returns (uint256 padLen) {
        padLen = realSize % alignSize;
        if (padLen != 0) {
            padLen = alignSize - padLen;
        } else if (realSize == 0) {
            padLen = alignSize;
        }
    }

    function pubdataPadCommitment(
        bytes calldata pubdata,
        uint32 alignSize
    ) internal pure returns (bytes32 commitment) {
        uint256 padLen = getPadLen(pubdata.length, alignSize);
        if (padLen != 0) {
            bytes memory padZero = new bytes(padLen);
            commitment = sha256(bytes.concat(pubdata, padZero));
        } else {
            commitment = sha256(pubdata);
        }
    }

    function createBlockCommitment(
        bytes32 oldAccountRoot,
        bytes32 oldOrderStateHash,
        bytes32 newOrderStateHash,
        CommitBlockInfo calldata newBlock
    ) internal view returns (bytes32 commitment) {
        bytes32 h = sha256(abi.encodePacked(uint256(newBlock.blockNumber), oldAccountRoot));
        h = sha256(bytes.concat(h, newBlock.accountRoot));
        h = sha256(bytes.concat(h, oldOrderStateHash));
        h = sha256(bytes.concat(h, newOrderStateHash));
        h = sha256(bytes.concat(h, globalConfigHash));
        h = sha256(bytes.concat(h, newBlock.validiumAccountRoot));

        uint32 alignSize = newBlock.blockChunkSize * Operations.ACCOUNT_COLLATERAL_BALANCE_PUBDATA_BYTES;
        bytes32 rollup_col_commitment = pubdataPadCommitment(newBlock.collateralBalancePubData, alignSize);

        alignSize = newBlock.blockChunkSize * Operations.ACCOUNT_POSITION_PUBDATA_BYTES;
        bytes32 rollup_assets_commitment = pubdataPadCommitment(newBlock.positonPubData, alignSize);

        bytes32 rollup_data_commitment = sha256(bytes.concat(rollup_col_commitment, rollup_assets_commitment));
        bytes32 account_data_commitment = sha256(bytes.concat(rollup_data_commitment, newBlock.all_data_commitment));
        h = sha256(bytes.concat(h, account_data_commitment));

        alignSize = newBlock.blockChunkSize * Operations.DEPOSIT_WITHDRAW_PUBDATA_BYTES;
        bytes32 onchain_commitment = pubdataPadCommitment(newBlock.onchainPubData, alignSize);
        commitment = sha256(bytes.concat(h, onchain_commitment));
    }

    function postProcess(
        bytes calldata pubData
    ) internal {
        uint256 offset = 0;
        uint256 factor = 10 ** (systemTokenDecimal - innerDecimal);

        while (offset < pubData.length) {

            Operations.DepositOrWithdraw memory op = Operations.readDepositOrWithdrawPubdata(pubData, offset);
            if (op.amount > DEPOSIT_LOWER_BOUND) {
                uint256 innerAmount = (uint256(op.amount) - DEPOSIT_LOWER_BOUND);
                pendingDeposits[op.l2Key] -= innerAmount * factor;
            } else {
                uint256 innerAmount = (DEPOSIT_LOWER_BOUND - uint256(op.amount));
                uint256 externalAmount = innerAmount * factor;
                pendingWithdrawals[op.l2Key] += externalAmount;
                emit LogWithdrawalAllowed(op.l2Key, externalAmount);
            }
            
            offset += Operations.DEPOSIT_WITHDRAW_PUBDATA_BYTES;
        }
    }

    function encodePackU64Array(
        uint64[] memory a, uint start, uint padLen, uint64 padValue
    ) internal pure returns(bytes memory data) {
        for(uint i = start; i< start + padLen; i++){
            if (i < a.length) {
                data = abi.encodePacked(data, a[i]);
            } else {
                data = abi.encodePacked(data, padValue);
            }
        }
    }

    function getOrderStateHash(
        CommitBlockInfo calldata b,
        uint64[] memory oracle_price
    ) internal view returns (bytes32 newOrderStateHash) {
        if (oracle_price.length == 0 && b.globalFunding.index.length == 0) {
            return b.orderStateHash;
        }

        bytes32 oraclePriceHash = b.oraclePriceHash;
        if (oracle_price.length != 0) {
            bytes memory encode_data = encodePackU64Array(oracle_price, 0, MAX_ASSETS_COUNT, 0);
            oraclePriceHash = sha256(encode_data);
        }

        bytes32 globalFundingIndexHash;
        if (b.globalFunding.index.length != 0) {
            uint32 timestamp = uint32(b.globalFunding.indexHashOrTimeStamp);
            bytes memory encode_data = abi.encodePacked(timestamp, encodePackU64Array(b.globalFunding.index, 0, MAX_ASSETS_COUNT, 1 << 63));
            globalFundingIndexHash = sha256(encode_data);
        } else {
            globalFundingIndexHash = bytes32(b.globalFunding.indexHashOrTimeStamp);
        }

        bytes32 global_state_hash = sha256(abi.encodePacked(uint32(b.timestamp), globalFundingIndexHash, oraclePriceHash));
        newOrderStateHash = sha256(bytes.concat(b.orderRoot, global_state_hash));
    }

    function verifyProofCommitment(
        CommitBlockInfo[] calldata _newBlocks,
        uint256[] calldata proof_commitments,
        uint64[] calldata lastestOraclePrice
    ) internal returns (bytes32 curOrderStateHash) {
        bytes32 curAccountRoot = accountRoot;
        curOrderStateHash = orderStateHash;
        for (uint256 i = 0; i < _newBlocks.length; ++i) {
            if (is_pending_global_config() && _newBlocks[i].blockNumber >= newGlobalConfigValidBlockNum) {
                resetGlobalConfigValidBlockNum();
                globalConfigHash = newGlobalConfigHash;
                emit LogNewGlobalConfigHash(newGlobalConfigHash);
            }

            // Create block commitment, and check with proof commitment
            uint64[] memory oraclePrice;
            if (i == _newBlocks.length - 1) {
                oraclePrice = lastestOraclePrice;
            }
            bytes32 newOrderStateHash = getOrderStateHash(_newBlocks[i], oraclePrice);
            bytes32 commitment = createBlockCommitment(curAccountRoot, curOrderStateHash, newOrderStateHash, _newBlocks[i]);
            require(proof_commitments[i] & INPUT_MASK == uint256(commitment) & INPUT_MASK, "proof commitment invalid");

            curAccountRoot = _newBlocks[i].accountRoot;
            curOrderStateHash = newOrderStateHash;
        }
    }

    function verifyValidiumSignature(
        CommitBlockInfo[] calldata newBlocks,
        bytes[] calldata validium_signature
    ) internal view {
        bytes32 concatValdiumHash = EMPTY_STRING_KECCAK;
        for (uint256 i = 0; i < newBlocks.length; ++i) {
            concatValdiumHash = keccak256(bytes.concat(concatValdiumHash, newBlocks[i].all_data_commitment));
        }

        bytes memory message = bytes.concat(
                "\x19Ethereum Signed Message:\n66",
                "0x",
                Bytes.bytesToHexASCIIBytes(abi.encodePacked(concatValdiumHash))
        );
        bytes32 msgHash = keccak256(message);

        uint32 sig_dac_num = 0;
        address[MIN_SIGNATURE_MEMBER] memory signers;
        for (uint256 i = 0; i < validium_signature.length; ++i) {
            address signer = ECDSA.recover(msgHash, validium_signature[i]);
            require(dacs[signer], "notDac");

            uint256 j;
            for (j = 0; j < sig_dac_num; ++j) {
                if (signers[j] == signer) {
                    break;
                }
            }

            if (j != sig_dac_num) { // ignore same signer
                continue;
            }


            signers[sig_dac_num++] = signer;
            if (sig_dac_num == MIN_SIGNATURE_MEMBER) {
                // ignore additional signature.
                break;
            }
        }
        require(sig_dac_num >= MIN_SIGNATURE_MEMBER, "sig3");
    }

    function updateBlocks(
        CommitBlockInfo[] calldata _newBlocks,
        bytes[] calldata validium_signature,
        ProofInput calldata _proof,
        uint64[] calldata lastestOraclePrice
    ) external onlyValidator onlyActive nonReentrant {

        require (_newBlocks.length >= 1);
        verifyValidiumSignature(_newBlocks, validium_signature);
        bytes32 newOrderStateHash = verifyProofCommitment(_newBlocks, _proof.commitments, lastestOraclePrice);

        // block prove
        require(verifier.verifyAggregatedBlockProof(
                            _proof.subproofsLimbs,
                            _proof.recursiveInput,
                            _proof.proof,
                            _proof.vkIndexes,
                            _proof.commitments), "p");

        //postprocess onchain operation
        for (uint256 i = 0; i < _newBlocks.length; ++i) {
            postProcess(_newBlocks[i].onchainPubData);
        }

        // update block status
        accountRoot = _newBlocks[_newBlocks.length - 1].accountRoot;
        orderStateHash = newOrderStateHash;
        emit BlockUpdate(_newBlocks[0].blockNumber,
                         _newBlocks[_newBlocks.length - 1].blockNumber);
    }

}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title configuration constants
contract Config {
    /// @dev Bit mask to apply for verifier public input before verifying.
    uint256 constant INPUT_MASK = (~uint256(0) >> 3);
}

pragma solidity >= 0.8.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT OR Apache-2.0




import "./plonk/KeysWithPlonkVerifier.sol";
import "../Config.sol";

// Hardcoded constants to avoid accessing store
contract Verifier is KeysWithPlonkVerifier, Config {
    function initialize() external {}

    function verifyAggregatedBlockProof(
        uint256[16] memory _subproofs_limbs,
        uint256[] memory _recursiveInput,
        uint256[] memory _proof,
        uint8[] memory _vkIndexes,
        uint256[] memory _individual_vks_inputs
    ) external view returns (bool) {
        for (uint256 i = 0; i < _individual_vks_inputs.length; ++i) {
            uint256 commitment = _individual_vks_inputs[i];
            _individual_vks_inputs[i] = commitment & INPUT_MASK;
        }
        VerificationKey memory vk = getVkAggregated(uint32(_vkIndexes.length));

        return
        verify_serialized_proof_with_recursion(
            _recursiveInput,
            _proof,
            VK_TREE_ROOT,
            VK_MAX_INDEX,
            _vkIndexes,
            _individual_vks_inputs,
            _subproofs_limbs,
            vk
        );
    }
}

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT OR Apache-2.0





import "./PlonkCore.sol";

// Hardcoded constants to avoid accessing store
contract KeysWithPlonkVerifier is VerifierWithDeserialize {

    uint256 constant VK_TREE_ROOT = 0x0b2e6d446421a9b4127640d60f8d8d1d6fc791961532e671747b3c30dbfdd921;
    uint8 constant VK_MAX_INDEX = 2;

    function getVkAggregated(uint32 _proofs) internal pure returns (VerificationKey memory vk) {
        if (_proofs == uint32(1)) { return getVkAggregated1(); }
        else if (_proofs == uint32(4)) { return getVkAggregated4(); }
        else if (_proofs == uint32(8)) { return getVkAggregated8(); }
        else if (_proofs == uint32(18)) { return getVkAggregated18(); }
    }

    
    function getVkAggregated1() internal pure returns(VerificationKey memory vk) {
        vk.domain_size = 4194304;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x18c95f1ae6514e11a1b30fd7923947c5ffcec5347f16e91b4dd654168326bede);
        vk.gate_setup_commitments[0] = PairingsBn254.new_g1(
            0x19fbd6706b4cbde524865701eae0ae6a270608a09c3afdab7760b685c1c6c41b,
            0x25082a191f0690c175cc9af1106c6c323b5b5de4e24dc23be1e965e1851bca48
        );
        vk.gate_setup_commitments[1] = PairingsBn254.new_g1(
            0x16c02d9ca95023d1812a58d16407d1ea065073f02c916290e39242303a8a1d8e,
            0x230338b422ce8533e27cd50086c28cb160cf05a7ae34ecd5899dbdf449dc7ce0
        );
        vk.gate_setup_commitments[2] = PairingsBn254.new_g1(
            0x1db0d133243750e1ea692050bbf6068a49dc9f6bae1f11960b6ce9e10adae0f5,
            0x12a453ed0121ae05de60848b4374d54ae4b7127cb307372e14e8daf5097c5123
        );
        vk.gate_setup_commitments[3] = PairingsBn254.new_g1(
            0x1062ed5e86781fd34f78938e5950c2481a79f132085d2bc7566351ddff9fa3b7,
            0x2fd7aac30f645293cc99883ab57d8c99a518d5b4ab40913808045e8653497346
        );
        vk.gate_setup_commitments[4] = PairingsBn254.new_g1(
            0x062755048bb95739f845e8659795813127283bf799443d62fea600ae23e7f263,
            0x2af86098beaa241281c78a454c5d1aa6e9eedc818c96cd1e6518e1ac2d26aa39
        );
        vk.gate_setup_commitments[5] = PairingsBn254.new_g1(
            0x0994e25148bbd25be655034f81062d1ebf0a1c2b41e0971434beab1ae8101474,
            0x27cc8cfb1fafd13068aeee0e08a272577d89f8aa0fb8507aabbc62f37587b98f
        );
        vk.gate_setup_commitments[6] = PairingsBn254.new_g1(
            0x044edf69ce10cfb6206795f92c3be2b0d26ab9afd3977b789840ee58c7dbe927,
            0x2a8aa20c106f8dc7e849bc9698064dcfa9ed0a4050d794a1db0f13b0ee3def37
        );
        vk.gate_selector_commitments[0] = PairingsBn254.new_g1(
            0x136967f1a2696db05583a58dbf8971c5d9d1dc5f5c97e88f3b4822aa52fefa1c,
            0x127b41299ea5c840c3b12dbe7b172380f432b7b63ce3b004750d6abb9e7b3b7a
        );
        vk.gate_selector_commitments[1] = PairingsBn254.new_g1(
            0x02fd5638bf3cc2901395ad1124b951e474271770a337147a2167e9797ab9d951,
            0x0fcb2e56b077c8461c36911c9252008286d782e96030769bf279024fc81d412a
        );
        vk.copy_permutation_commitments[0] = PairingsBn254.new_g1(
            0x1865c60ecad86f81c6c952445707203c9c7fdace3740232ceb704aefd5bd45b3,
            0x2f35e29b39ec8bb054e2cff33c0299dd13f8c78ea24a07622128a7444aba3f26
        );
        vk.copy_permutation_commitments[1] = PairingsBn254.new_g1(
            0x2a86ec9c6c1f903650b5abbf0337be556b03f79aecc4d917e90c7db94518dde6,
            0x15b1b6be641336eebd58e7991be2991debbbd780e70c32b49225aa98d10b7016
        );
        vk.copy_permutation_commitments[2] = PairingsBn254.new_g1(
            0x213e42fcec5297b8e01a602684fcd412208d15bdac6b6331a8819d478ba46899,
            0x03223485f4e808a3b2496ae1a3c0dfbcbf4391cffc57ee01e8fca114636ead18
        );
        vk.copy_permutation_commitments[3] = PairingsBn254.new_g1(
            0x2e9b02f8cf605ad1a36e99e990a07d435de06716448ad53053c7a7a5341f71e1,
            0x2d6fdf0bc8bd89112387b1894d6f24b45dcb122c09c84344b6fc77a619dd1d59
        );
        vk.copy_permutation_non_residues[0] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000005
        );
        vk.copy_permutation_non_residues[1] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000007
        );
        vk.copy_permutation_non_residues[2] = PairingsBn254.new_fr(
            0x000000000000000000000000000000000000000000000000000000000000000a
        );

        vk.g2_x = PairingsBn254.new_g2(
            [0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1,
            0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0],
            [0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4,
            0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55]
        );
    }
    
    function getVkAggregated4() internal pure returns(VerificationKey memory vk) {
        vk.domain_size = 8388608;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x1283ba6f4b7b1a76ba2008fe823128bea4adb9269cbfd7c41c223be65bc60863);
        vk.gate_setup_commitments[0] = PairingsBn254.new_g1(
            0x2988e24b15bce9a1e3a4d1d9a8f7c7a65db6c29fd4c6f4afe1a3fbd954d4b4b6,
            0x0bdb6e5ba27a22e03270c7c71399b866b28d7cec504d30e665d67be58e306e12
        );
        vk.gate_setup_commitments[1] = PairingsBn254.new_g1(
            0x20f3d30d3a91a7419d658f8c035e42a811c9f75eac2617e65729033286d36089,
            0x07ac91e8194eb78a9db537e9459dd6ca26bef8770dde54ac3dd396450b1d4cfe
        );
        vk.gate_setup_commitments[2] = PairingsBn254.new_g1(
            0x0311872bab6df6e9095a9afe40b12e2ed58f00cc88835442e6b4cf73fb3e147d,
            0x2cdfc5b5e73737809b54644b2f96494f8fcc1dd0fb440f64f44930b432c4542d
        );
        vk.gate_setup_commitments[3] = PairingsBn254.new_g1(
            0x28fd545b1e960d2eff3142271affa4096ef724212031fdabe22dd4738f36472b,
            0x2c743150ee9894ff3965d8f1129399a3b89a1a9289d4cfa904b0a648d3a8a9fa
        );
        vk.gate_setup_commitments[4] = PairingsBn254.new_g1(
            0x2c283ce950eee1173b78657e57c80658a8398e7970a9a45b20cd39aff16ad61a,
            0x081c003cbd09f7c3e0d723d6ebbaf432421c188d5759f5ee8ff1ee1dc357d4a8
        );
        vk.gate_setup_commitments[5] = PairingsBn254.new_g1(
            0x2eb50a2dd293a71a0c038e958c5237bd7f50b2f0c9ee6385895a553de1517d43,
            0x15fdc2b5b28fc351f987b98aa6caec7552cefbafa14e6651061eec4f41993b65
        );
        vk.gate_setup_commitments[6] = PairingsBn254.new_g1(
            0x17a9403e5c846c1ca5e767c89250113aa156fdb1f026aa0b4db59c09d06816ec,
            0x2512241972ca3ee4839ac72a4cab39ddb413a7553556abd7909284b34ee73f6b
        );
        vk.gate_selector_commitments[0] = PairingsBn254.new_g1(
            0x09edd69c8baa7928b16615e993e3032bc8cbf9f42bfa3cf28caba1078d371edb,
            0x12e5c39148af860a87b14ae938f33eafa91deeb548cda4cc23ed9ba3e6e496b8
        );
        vk.gate_selector_commitments[1] = PairingsBn254.new_g1(
            0x0e25c0027706ca3fd3daae849f7c50ec88d4d030da02452001dec7b554cc71b4,
            0x2421da0ca385ff7ba9e5ae68890655669248c8c8187e67d12b2a7ae97e2cff8b
        );
        vk.copy_permutation_commitments[0] = PairingsBn254.new_g1(
            0x151536359fe184567bce57379833f6fae485e5cc9bc27423d83d281aaf2701df,
            0x116beb145bc27faae5a8ae30c28040d3baafb3ea47360e528227b94adb9e4f26
        );
        vk.copy_permutation_commitments[1] = PairingsBn254.new_g1(
            0x23ee338093db23364a6e44acfb60d810a4c4bd6565b185374f7840152d3ae82c,
            0x0f6714f3ee113b9dfb6b653f04bf497602588b16b96ac682d9a5dd880a0aa601
        );
        vk.copy_permutation_commitments[2] = PairingsBn254.new_g1(
            0x05860b0ea3c6f22150812aee304bf35e1a95cfa569a8da52b42dba44a122378a,
            0x19e5a9f3097289272e65e842968752c5355d1cdb2d3d737050e4dfe32ebe1e41
        );
        vk.copy_permutation_commitments[3] = PairingsBn254.new_g1(
            0x3046881fcbe369ac6f99fea8b9505de85ded3de3bc445060be4bc6ef651fa352,
            0x06fe14c1dd6c2f2b48aebeb6fd525573d276b2e148ad25e75c57a58588f755ec
        );
        vk.copy_permutation_non_residues[0] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000005
        );
        vk.copy_permutation_non_residues[1] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000007
        );
        vk.copy_permutation_non_residues[2] = PairingsBn254.new_fr(
            0x000000000000000000000000000000000000000000000000000000000000000a
        );

        vk.g2_x = PairingsBn254.new_g2(
            [0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1,
            0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0],
            [0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4,
            0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55]
        );
    }
    
    function getVkAggregated8() internal pure returns(VerificationKey memory vk) {
        vk.domain_size = 16777216;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x1951441010b2b95a6e47a6075066a50a036f5ba978c050f2821df86636c0facb);
        vk.gate_setup_commitments[0] = PairingsBn254.new_g1(
            0x218bdb295b7207114aeea948e2d3baef158d4057812f94005d8ff54341b6ce6f,
            0x1398585c039ba3cf336687301e95fbbf6b0638d31c64b1d815bb49091d0c1aad
        );
        vk.gate_setup_commitments[1] = PairingsBn254.new_g1(
            0x2e40b8a98e688c9e00f607a64520a850d35f277dc0b645628494337bb75870e8,
            0x2da4ef753cc4869e53cff171009dbffea9166b8ffbafd17783d712278a79f13e
        );
        vk.gate_setup_commitments[2] = PairingsBn254.new_g1(
            0x1b638de3c6cc2e0badc48305ee3533678a45f52edf30277303551128772303a2,
            0x2794c375cbebb7c28379e8abf42d529a1c291319020099935550c83796ba14ac
        );
        vk.gate_setup_commitments[3] = PairingsBn254.new_g1(
            0x189cd01d67b44cf2c1e10765c69adaafd6a5929952cf55732e312ecf00166956,
            0x15976c99ef2c911bd3a72c9613b7fe9e66b03dd8963bfed705c96e3e88fdb1af
        );
        vk.gate_setup_commitments[4] = PairingsBn254.new_g1(
            0x0745a77052dc66afc61163ec3737651e5b846ca7ec7fae1853515d0f10a51bd9,
            0x2bd27ecf4fb7f5053cc6de3ddb7a969fac5150a6fb5555ca917d16a7836e4c0a
        );
        vk.gate_setup_commitments[5] = PairingsBn254.new_g1(
            0x2787aea173d07508083893b02ea962be71c3b628d1da7d7c4db0def49f73ad8f,
            0x22fdc951a97dc2ac7d8292a6c263898022f4623c643a56b9265b33c72e628886
        );
        vk.gate_setup_commitments[6] = PairingsBn254.new_g1(
            0x0aafe35c49634858e44e9af259cac47a6f8402eb870f9f95217dcb8a33a73e64,
            0x1b47a7641a7c918784e84fc2494bfd8014ebc77069b94650d25cb5e25fbb7003
        );
        vk.gate_selector_commitments[0] = PairingsBn254.new_g1(
            0x11cfc3fe28dfd5d663d53ceacc5ec620da85ae5aa971f0f003f57e75cd05bf9f,
            0x28b325f30984634fc46c6750f402026d4ff43e5325cbe34d35bf8ac4fc9cc533
        );
        vk.gate_selector_commitments[1] = PairingsBn254.new_g1(
            0x2ada816636b9447def36e35dd3ab0e3f7a8bbe3ae32a5a4904dee3fc26e58015,
            0x2cd12d1a50aaadef4e19e1b1955c932e992e688c2883da862bd7fad17aae66f6
        );
        vk.copy_permutation_commitments[0] = PairingsBn254.new_g1(
            0x20cc506f273be4d114cbf2807c14a769d03169168892e2855cdfa78c3095c89d,
            0x08f99d338aee985d780d036473c624de9fd7960b2a4a7ad361c8c125cf11899e
        );
        vk.copy_permutation_commitments[1] = PairingsBn254.new_g1(
            0x01260265d3b1167eac1030f3d04326f08a1f2bb1e026e54afec844e3729386e2,
            0x16d75b53ec2552c63e84ea5f4bfe1507c3198045875457c1d9295d6699f39d56
        );
        vk.copy_permutation_commitments[2] = PairingsBn254.new_g1(
            0x1f4d73c63d163c3f5ef1b5caa41988cacbdbca38334e8f54d7ee9bbbb622e200,
            0x2f48f5f93d9845526ef0348f1c3def63cfc009645eb2a95d1746c7941e888a78
        );
        vk.copy_permutation_commitments[3] = PairingsBn254.new_g1(
            0x1dbd386fe258366222becc570a7f6405b25ff52818b93bdd54eaa20a6b22025a,
            0x2b2b4e978ac457d752f50b02609bd7d2054286b963821b2ec7cd3dd1507479fa
        );
        vk.copy_permutation_non_residues[0] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000005
        );
        vk.copy_permutation_non_residues[1] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000007
        );
        vk.copy_permutation_non_residues[2] = PairingsBn254.new_fr(
            0x000000000000000000000000000000000000000000000000000000000000000a
        );

        vk.g2_x = PairingsBn254.new_g2(
            [0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1,
            0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0],
            [0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4,
            0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55]
        );
    }
    
    function getVkAggregated18() internal pure returns(VerificationKey memory vk) {
        vk.domain_size = 33554432;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x0d94d63997367c97a8ed16c17adaae39262b9af83acb9e003f94c217303dd160);
        vk.gate_setup_commitments[0] = PairingsBn254.new_g1(
            0x0eab7c0217fbc357eb9e2622da6e5df9a99e5fa8dbaaf6b45a7136bbc49704c0,
            0x00199f1c9e2ef5efbec5e3792cb6db0d6211e2da57e2e5a7cf91fb4037bd0013
        );
        vk.gate_setup_commitments[1] = PairingsBn254.new_g1(
            0x020c5ecdbb37b9f99b131cdfd0fec8c5565985599093db03d85a9bcd75a8a186,
            0x0be3b767834382739f1309adedb540ce5261b7038c168d32619a6e6333974b1b
        );
        vk.gate_setup_commitments[2] = PairingsBn254.new_g1(
            0x092fc8636803f28250ac33b8ea688b37cf0718f83c82a1ce7bca70e7c8643b93,
            0x10c907fcb34fb6e9d4e334428e8226ba84e5977a7dc1ada2509cc6cf445123ca
        );
        vk.gate_setup_commitments[3] = PairingsBn254.new_g1(
            0x1f66b77eaae034cf3646e0c32418a1dfecb3bf090cc271aad0d64ba327758b29,
            0x2b8766fbe83c45b39e274998a000cf59e7332800025e7af711368c6b7ea11cd9
        );
        vk.gate_setup_commitments[4] = PairingsBn254.new_g1(
            0x017336a15f6e61def3ec02f139a0972c4272e126ac40d49ed10d447db6857643,
            0x22cc7cb62310a031acd86dd1a9ea18ee55e1b6a4fbf1c2d64ca9a7cc6458ed7a
        );
        vk.gate_setup_commitments[5] = PairingsBn254.new_g1(
            0x057992ff5d056557b795ab7e6964fab546fdcd8b5c1d3718e4f619e1091ef9a0,
            0x026916de04486781c504fb054e0b3755dd4836b610973e0ca092b35810ed3698
        );
        vk.gate_setup_commitments[6] = PairingsBn254.new_g1(
            0x252a53377145970214c9af5cd95c5fdd72e4d890b96d5ab31ef7736b2280aaa3,
            0x2a1ccbea423d1a58325c4d0e5aa01a6a2a7c7fbaa61fb8f3669f720dfb4dfd4d
        );
        vk.gate_selector_commitments[0] = PairingsBn254.new_g1(
            0x17da1e8102c91916c778e89d737bdc8a14f4dfcf14fc89896f921dfc81e98556,
            0x1b9571239471b65bc5d4bcc3b1b3831bcc6986ad4d1417292dc3067ae632b796
        );
        vk.gate_selector_commitments[1] = PairingsBn254.new_g1(
            0x242b5b8848746eb790629cf0853e256249d83cad8e189d474ed3a5c56b5a92be,
            0x2ca4e4882f0d7408ba134458945a2dd7cbced64e735fd42c9204eaf8608c58cc
        );
        vk.copy_permutation_commitments[0] = PairingsBn254.new_g1(
            0x281ccb20cea7001ae0d3ef5deedc46db687f1493cd77631dc2c16275b96f677a,
            0x24bede6b53ee4762939dbabb5947023d3ab31b00a1d14bcb6a5da69d7ce0d67e
        );
        vk.copy_permutation_commitments[1] = PairingsBn254.new_g1(
            0x1e72df4c2223fb15e72862350f51994b7f381a829a00b21535b04e8c342c15e7,
            0x22b7bb45c2e3b957952824beee1145bfcb5d2c575636266ad44032c1ae24e1ea
        );
        vk.copy_permutation_commitments[2] = PairingsBn254.new_g1(
            0x0059ea736670b355b3b6479db53d9b19727aa128514dee7d6c6788e80233452f,
            0x24718998fb0ff667c66457f6558ff028352b2d55cb86a07a0c11fc3c2753df38
        );
        vk.copy_permutation_commitments[3] = PairingsBn254.new_g1(
            0x0bee5ac3770c7603b2ccbc9e10a0ceafa231e77dde3fd6b9d514958ae7c200e8,
            0x11339336bbdafda32635c143b7bd0c4cdb7b7948489d75240c89ca2a440ef39c
        );
        vk.copy_permutation_non_residues[0] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000005
        );
        vk.copy_permutation_non_residues[1] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000007
        );
        vk.copy_permutation_non_residues[2] = PairingsBn254.new_fr(
            0x000000000000000000000000000000000000000000000000000000000000000a
        );

        vk.g2_x = PairingsBn254.new_g2(
            [0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1,
            0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0],
            [0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4,
            0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55]
        );
    }
    

}

pragma solidity >= 0.8.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT OR Apache-2.0




library PairingsBn254 {
    uint256 constant q_mod = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    uint256 constant r_mod = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant bn254_b_coeff = 3;

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    struct Fr {
        uint256 value;
    }

    function new_fr(uint256 fr) internal pure returns (Fr memory) {
        require(fr < r_mod);
        return Fr({value: fr});
    }

    function copy(Fr memory self) internal pure returns (Fr memory n) {
        n.value = self.value;
    }

    function assign(Fr memory self, Fr memory other) internal pure {
        self.value = other.value;
    }

    function inverse(Fr memory fr) internal view returns (Fr memory) {
        require(fr.value != 0);
        return pow(fr, r_mod - 2);
    }

    function add_assign(Fr memory self, Fr memory other) internal pure {
        self.value = addmod(self.value, other.value, r_mod);
    }

    function sub_assign(Fr memory self, Fr memory other) internal pure {
        self.value = addmod(self.value, r_mod - other.value, r_mod);
    }

    function mul_assign(Fr memory self, Fr memory other) internal pure {
        self.value = mulmod(self.value, other.value, r_mod);
    }

    function pow(Fr memory self, uint256 power) internal view returns (Fr memory) {
        uint256[6] memory input = [32, 32, 32, self.value, power, r_mod];
        uint256[1] memory result;
        bool success;
        assembly {
            success := staticcall(gas(), 0x05, input, 0xc0, result, 0x20)
        }
        require(success);
        return Fr({value: result[0]});
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }

    function new_g1(uint256 x, uint256 y) internal pure returns (G1Point memory) {
        return G1Point(x, y);
    }

    function new_g1_checked(uint256 x, uint256 y) internal pure returns (G1Point memory) {
        if (x == 0 && y == 0) {
            // point of infinity is (0,0)
            return G1Point(x, y);
        }

        // check encoding
        require(x < q_mod);
        require(y < q_mod);
        // check on curve
        uint256 lhs = mulmod(y, y, q_mod); // y^2
        uint256 rhs = mulmod(x, x, q_mod); // x^2
        rhs = mulmod(rhs, x, q_mod); // x^3
        rhs = addmod(rhs, bn254_b_coeff, q_mod); // x^3 + b
        require(lhs == rhs);

        return G1Point(x, y);
    }

    function new_g2(uint256[2] memory x, uint256[2] memory y) internal pure returns (G2Point memory) {
        return G2Point(x, y);
    }

    function copy_g1(G1Point memory self) internal pure returns (G1Point memory result) {
        result.X = self.X;
        result.Y = self.Y;
    }

    function P2() internal pure returns (G2Point memory) {
        // for some reason ethereum expects to have c1*v + c0 form

        return
        G2Point(
            [
            0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2,
            0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed
            ],
            [
            0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b,
            0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa
            ]
        );
    }

    function negate(G1Point memory self) internal pure {
        // The prime q in the base field F_q for G1
        if (self.Y == 0) {
            require(self.X == 0);
            return;
        }

        self.Y = q_mod - self.Y;
    }

    function point_add(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        point_add_into_dest(p1, p2, r);
        return r;
    }

    function point_add_assign(G1Point memory p1, G1Point memory p2) internal view {
        point_add_into_dest(p1, p2, p1);
    }

    function point_add_into_dest(
        G1Point memory p1,
        G1Point memory p2,
        G1Point memory dest
    ) internal view {
        if (p2.X == 0 && p2.Y == 0) {
            // we add zero, nothing happens
            dest.X = p1.X;
            dest.Y = p1.Y;
            return;
        } else if (p1.X == 0 && p1.Y == 0) {
            // we add into zero, and we add non-zero point
            dest.X = p2.X;
            dest.Y = p2.Y;
            return;
        } else {
            uint256[4] memory input;

            input[0] = p1.X;
            input[1] = p1.Y;
            input[2] = p2.X;
            input[3] = p2.Y;

            bool success = false;
            assembly {
                success := staticcall(gas(), 6, input, 0x80, dest, 0x40)
            }
            require(success);
        }
    }

    function point_sub_assign(G1Point memory p1, G1Point memory p2) internal view {
        point_sub_into_dest(p1, p2, p1);
    }

    function point_sub_into_dest(
        G1Point memory p1,
        G1Point memory p2,
        G1Point memory dest
    ) internal view {
        if (p2.X == 0 && p2.Y == 0) {
            // we subtracted zero, nothing happens
            dest.X = p1.X;
            dest.Y = p1.Y;
            return;
        } else if (p1.X == 0 && p1.Y == 0) {
            // we subtract from zero, and we subtract non-zero point
            dest.X = p2.X;
            dest.Y = q_mod - p2.Y;
            return;
        } else {
            uint256[4] memory input;

            input[0] = p1.X;
            input[1] = p1.Y;
            input[2] = p2.X;
            input[3] = q_mod - p2.Y;

            bool success = false;
            assembly {
                success := staticcall(gas(), 6, input, 0x80, dest, 0x40)
            }
            require(success);
        }
    }

    function point_mul(G1Point memory p, Fr memory s) internal view returns (G1Point memory r) {
        point_mul_into_dest(p, s, r);
        return r;
    }

    function point_mul_assign(G1Point memory p, Fr memory s) internal view {
        point_mul_into_dest(p, s, p);
    }

    function point_mul_into_dest(
        G1Point memory p,
        Fr memory s,
        G1Point memory dest
    ) internal view {
        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s.value;
        bool success;
        assembly {
            success := staticcall(gas(), 7, input, 0x60, dest, 0x40)
        }
        require(success);
    }

    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
        uint256 elements = p1.length;
        uint256 inputSize = elements * 6;
        uint256[] memory input = new uint256[](inputSize);
        for (uint256 i = 0; i < elements; i++) {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint256[1] memory out;
        bool success;
        assembly {
            success := staticcall(gas(), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
        }
        require(success);
        return out[0] != 0;
    }

    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
}

library TranscriptLibrary {
    // flip                    0xe000000000000000000000000000000000000000000000000000000000000000;
    uint256 constant FR_MASK = 0x1fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    uint32 constant DST_0 = 0;
    uint32 constant DST_1 = 1;
    uint32 constant DST_CHALLENGE = 2;

    struct Transcript {
        bytes32 state_0;
        bytes32 state_1;
        uint32 challenge_counter;
    }

    function new_transcript() internal pure returns (Transcript memory t) {
        t.state_0 = bytes32(0);
        t.state_1 = bytes32(0);
        t.challenge_counter = 0;
    }

    function update_with_u256(Transcript memory self, uint256 value) internal pure {
        bytes32 old_state_0 = self.state_0;
        self.state_0 = keccak256(abi.encodePacked(DST_0, old_state_0, self.state_1, value));
        self.state_1 = keccak256(abi.encodePacked(DST_1, old_state_0, self.state_1, value));
    }

    function update_with_fr(Transcript memory self, PairingsBn254.Fr memory value) internal pure {
        update_with_u256(self, value.value);
    }

    function update_with_g1(Transcript memory self, PairingsBn254.G1Point memory p) internal pure {
        update_with_u256(self, p.X);
        update_with_u256(self, p.Y);
    }

    function get_challenge(Transcript memory self) internal pure returns (PairingsBn254.Fr memory challenge) {
        bytes32 query = keccak256(abi.encodePacked(DST_CHALLENGE, self.state_0, self.state_1, self.challenge_counter));
        self.challenge_counter += 1;
        challenge = PairingsBn254.Fr({value: uint256(query) & FR_MASK});
    }
}

contract Plonk4VerifierWithAccessToDNext {
    uint256 constant r_mod = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    using PairingsBn254 for PairingsBn254.G1Point;
    using PairingsBn254 for PairingsBn254.G2Point;
    using PairingsBn254 for PairingsBn254.Fr;

    using TranscriptLibrary for TranscriptLibrary.Transcript;

    uint256 constant ZERO = 0;
    uint256 constant ONE = 1;
    uint256 constant TWO = 2;
    uint256 constant THREE = 3;
    uint256 constant FOUR = 4;

    uint256 constant STATE_WIDTH = 4;
    uint256 constant NUM_DIFFERENT_GATES = 2;
    uint256 constant NUM_SETUP_POLYS_FOR_MAIN_GATE = 7;
    uint256 constant NUM_SETUP_POLYS_RANGE_CHECK_GATE = 0;
    uint256 constant ACCESSIBLE_STATE_POLYS_ON_NEXT_STEP = 1;
    uint256 constant NUM_GATE_SELECTORS_OPENED_EXPLICITLY = 1;

    uint256 constant RECURSIVE_CIRCUIT_INPUT_COMMITMENT_MASK =
    0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant LIMB_WIDTH = 68;

    struct VerificationKey {
        uint256 domain_size;
        uint256 num_inputs;
        PairingsBn254.Fr omega;
        PairingsBn254.G1Point[NUM_SETUP_POLYS_FOR_MAIN_GATE + NUM_SETUP_POLYS_RANGE_CHECK_GATE] gate_setup_commitments;
        PairingsBn254.G1Point[NUM_DIFFERENT_GATES] gate_selector_commitments;
        PairingsBn254.G1Point[STATE_WIDTH] copy_permutation_commitments;
        PairingsBn254.Fr[STATE_WIDTH - 1] copy_permutation_non_residues;
        PairingsBn254.G2Point g2_x;
    }

    struct Proof {
        uint256[] input_values;
        PairingsBn254.G1Point[STATE_WIDTH] wire_commitments;
        PairingsBn254.G1Point copy_permutation_grand_product_commitment;
        PairingsBn254.G1Point[STATE_WIDTH] quotient_poly_commitments;
        PairingsBn254.Fr[STATE_WIDTH] wire_values_at_z;
        PairingsBn254.Fr[ACCESSIBLE_STATE_POLYS_ON_NEXT_STEP] wire_values_at_z_omega;
        PairingsBn254.Fr[NUM_GATE_SELECTORS_OPENED_EXPLICITLY] gate_selector_values_at_z;
        PairingsBn254.Fr copy_grand_product_at_z_omega;
        PairingsBn254.Fr quotient_polynomial_at_z;
        PairingsBn254.Fr linearization_polynomial_at_z;
        PairingsBn254.Fr[STATE_WIDTH - 1] permutation_polynomials_at_z;
        PairingsBn254.G1Point opening_at_z_proof;
        PairingsBn254.G1Point opening_at_z_omega_proof;
    }

    struct PartialVerifierState {
        PairingsBn254.Fr alpha;
        PairingsBn254.Fr beta;
        PairingsBn254.Fr gamma;
        PairingsBn254.Fr v;
        PairingsBn254.Fr u;
        PairingsBn254.Fr z;
        PairingsBn254.Fr[] cached_lagrange_evals;
    }

    function evaluate_lagrange_poly_out_of_domain(
        uint256 poly_num,
        uint256 domain_size,
        PairingsBn254.Fr memory omega,
        PairingsBn254.Fr memory at
    ) internal view returns (PairingsBn254.Fr memory res) {
        require(poly_num < domain_size);
        PairingsBn254.Fr memory one = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory omega_power = omega.pow(poly_num);
        res = at.pow(domain_size);
        res.sub_assign(one);
        require(res.value != 0); // Vanishing polynomial can not be zero at point `at`
        res.mul_assign(omega_power);

        PairingsBn254.Fr memory den = PairingsBn254.copy(at);
        den.sub_assign(omega_power);
        den.mul_assign(PairingsBn254.new_fr(domain_size));

        den = den.inverse();

        res.mul_assign(den);
    }

    function batch_evaluate_lagrange_poly_out_of_domain(
        uint256[] memory poly_nums,
        uint256 domain_size,
        PairingsBn254.Fr memory omega,
        PairingsBn254.Fr memory at
    ) internal view returns (PairingsBn254.Fr[] memory res) {
        PairingsBn254.Fr memory one = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory tmp_1 = PairingsBn254.new_fr(0);
        PairingsBn254.Fr memory tmp_2 = PairingsBn254.new_fr(domain_size);
        PairingsBn254.Fr memory vanishing_at_z = at.pow(domain_size);
        vanishing_at_z.sub_assign(one);
        // we can not have random point z be in domain
        require(vanishing_at_z.value != 0);
        PairingsBn254.Fr[] memory nums = new PairingsBn254.Fr[](poly_nums.length);
        PairingsBn254.Fr[] memory dens = new PairingsBn254.Fr[](poly_nums.length);
        // numerators in a form omega^i * (z^n - 1)
        // denoms in a form (z - omega^i) * N
        for (uint256 i = 0; i < poly_nums.length; i++) {
            tmp_1 = omega.pow(poly_nums[i]); // power of omega
            nums[i].assign(vanishing_at_z);
            nums[i].mul_assign(tmp_1);

            dens[i].assign(at); // (X - omega^i) * N
            dens[i].sub_assign(tmp_1);
            dens[i].mul_assign(tmp_2); // mul by domain size
        }

        PairingsBn254.Fr[] memory partial_products = new PairingsBn254.Fr[](poly_nums.length);
        partial_products[0].assign(PairingsBn254.new_fr(1));
        for (uint256 i = 1; i < dens.length ; i++) {
            partial_products[i].assign(dens[i - 1]);
            partial_products[i].mul_assign(partial_products[i-1]);
        }

        tmp_2.assign(partial_products[partial_products.length - 1]);
        tmp_2.mul_assign(dens[dens.length - 1]);
        tmp_2 = tmp_2.inverse(); // tmp_2 contains a^-1 * b^-1 (with! the last one)

        for (uint256 i = dens.length - 1; i < dens.length; i--) {
            tmp_1.assign(tmp_2); // all inversed
            tmp_1.mul_assign(partial_products[i]); // clear lowest terms
            tmp_2.mul_assign(dens[i]);
            dens[i].assign(tmp_1);
            if (i == 0) {
                break;
            }
        }

        for (uint256 i = 0; i < nums.length; i++) {
            nums[i].mul_assign(dens[i]);
        }

        return nums;
    }

    function evaluate_vanishing(uint256 domain_size, PairingsBn254.Fr memory at)
    internal
    view
    returns (PairingsBn254.Fr memory res)
    {
        res = at.pow(domain_size);
        res.sub_assign(PairingsBn254.new_fr(1));
    }

    function verify_at_z(
        PartialVerifierState memory state,
        Proof memory proof,
        VerificationKey memory vk
    ) internal view returns (bool) {
        PairingsBn254.Fr memory lhs = evaluate_vanishing(vk.domain_size, state.z);
        require(lhs.value != 0); // we can not check a polynomial relationship if point `z` is in the domain
        lhs.mul_assign(proof.quotient_polynomial_at_z);

        PairingsBn254.Fr memory quotient_challenge = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory rhs = PairingsBn254.copy(proof.linearization_polynomial_at_z);

        // public inputs
        PairingsBn254.Fr memory tmp = PairingsBn254.new_fr(0);
        PairingsBn254.Fr memory inputs_term = PairingsBn254.new_fr(0);
        for (uint256 i = 0; i < proof.input_values.length; i++) {
            tmp.assign(state.cached_lagrange_evals[i]);
            tmp.mul_assign(PairingsBn254.new_fr(proof.input_values[i]));
            inputs_term.add_assign(tmp);
        }

        inputs_term.mul_assign(proof.gate_selector_values_at_z[0]);
        rhs.add_assign(inputs_term);

        // now we need 5th power
        quotient_challenge.mul_assign(state.alpha);
        quotient_challenge.mul_assign(state.alpha);
        quotient_challenge.mul_assign(state.alpha);
        quotient_challenge.mul_assign(state.alpha);
        quotient_challenge.mul_assign(state.alpha);

        PairingsBn254.Fr memory z_part = PairingsBn254.copy(proof.copy_grand_product_at_z_omega);
        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            tmp.assign(proof.permutation_polynomials_at_z[i]);
            tmp.mul_assign(state.beta);
            tmp.add_assign(state.gamma);
            tmp.add_assign(proof.wire_values_at_z[i]);

            z_part.mul_assign(tmp);
        }

        tmp.assign(state.gamma);
        // we need a wire value of the last polynomial in enumeration
        tmp.add_assign(proof.wire_values_at_z[STATE_WIDTH - 1]);

        z_part.mul_assign(tmp);
        z_part.mul_assign(quotient_challenge);

        rhs.sub_assign(z_part);

        quotient_challenge.mul_assign(state.alpha);

        tmp.assign(state.cached_lagrange_evals[0]);
        tmp.mul_assign(quotient_challenge);

        rhs.sub_assign(tmp);

        return lhs.value == rhs.value;
    }

    function add_contribution_from_range_constraint_gates(
        PartialVerifierState memory state,
        Proof memory proof,
        PairingsBn254.Fr memory current_alpha
    ) internal pure returns (PairingsBn254.Fr memory res) {
        // now add contribution from range constraint gate
        // we multiply selector commitment by all the factors (alpha*(c - 4d)(c - 4d - 1)(..-2)(..-3) + alpha^2 * (4b - c)()()() + {} + {})

        PairingsBn254.Fr memory one_fr = PairingsBn254.new_fr(ONE);
        PairingsBn254.Fr memory two_fr = PairingsBn254.new_fr(TWO);
        PairingsBn254.Fr memory three_fr = PairingsBn254.new_fr(THREE);
        PairingsBn254.Fr memory four_fr = PairingsBn254.new_fr(FOUR);

        res = PairingsBn254.new_fr(0);
        PairingsBn254.Fr memory t0 = PairingsBn254.new_fr(0);
        PairingsBn254.Fr memory t1 = PairingsBn254.new_fr(0);
        PairingsBn254.Fr memory t2 = PairingsBn254.new_fr(0);

        for (uint256 i = 0; i < 3; i++) {
            current_alpha.mul_assign(state.alpha);

            // high - 4*low

            // this is 4*low
            t0 = PairingsBn254.copy(proof.wire_values_at_z[3 - i]);
            t0.mul_assign(four_fr);

            // high
            t1 = PairingsBn254.copy(proof.wire_values_at_z[2 - i]);
            t1.sub_assign(t0);

            // t0 is now t1 - {0,1,2,3}

            // first unroll manually for -0;
            t2 = PairingsBn254.copy(t1);

            // -1
            t0 = PairingsBn254.copy(t1);
            t0.sub_assign(one_fr);
            t2.mul_assign(t0);

            // -2
            t0 = PairingsBn254.copy(t1);
            t0.sub_assign(two_fr);
            t2.mul_assign(t0);

            // -3
            t0 = PairingsBn254.copy(t1);
            t0.sub_assign(three_fr);
            t2.mul_assign(t0);

            t2.mul_assign(current_alpha);

            res.add_assign(t2);
        }

        // now also d_next - 4a

        current_alpha.mul_assign(state.alpha);

        // high - 4*low

        // this is 4*low
        t0 = PairingsBn254.copy(proof.wire_values_at_z[0]);
        t0.mul_assign(four_fr);

        // high
        t1 = PairingsBn254.copy(proof.wire_values_at_z_omega[0]);
        t1.sub_assign(t0);

        // t0 is now t1 - {0,1,2,3}

        // first unroll manually for -0;
        t2 = PairingsBn254.copy(t1);

        // -1
        t0 = PairingsBn254.copy(t1);
        t0.sub_assign(one_fr);
        t2.mul_assign(t0);

        // -2
        t0 = PairingsBn254.copy(t1);
        t0.sub_assign(two_fr);
        t2.mul_assign(t0);

        // -3
        t0 = PairingsBn254.copy(t1);
        t0.sub_assign(three_fr);
        t2.mul_assign(t0);

        t2.mul_assign(current_alpha);

        res.add_assign(t2);

        return res;
    }

    function reconstruct_linearization_commitment(
        PartialVerifierState memory state,
        Proof memory proof,
        VerificationKey memory vk
    ) internal view returns (PairingsBn254.G1Point memory res) {
        // we compute what power of v is used as a delinearization factor in batch opening of
        // commitments. Let's label W(x) = 1 / (x - z) *
        // [
        // t_0(x) + z^n * t_1(x) + z^2n * t_2(x) + z^3n * t_3(x) - t(z)
        // + v (r(x) - r(z))
        // + v^{2..5} * (witness(x) - witness(z))
        // + v^{6} * (selector(x) - selector(z))
        // + v^{7..9} * (permutation(x) - permutation(z))
        // ]
        // W'(x) = 1 / (x - z*omega) *
        // [
        // + v^10 (z(x) - z(z*omega)) <- we need this power
        // + v^11 * (d(x) - d(z*omega))
        // ]
        //

        // we reconstruct linearization polynomial virtual selector
        // for that purpose we first linearize over main gate (over all it's selectors)
        // and multiply them by value(!) of the corresponding main gate selector
        res = PairingsBn254.copy_g1(vk.gate_setup_commitments[STATE_WIDTH + 1]); // index of q_const(x)

        PairingsBn254.G1Point memory tmp_g1 = PairingsBn254.P1();
        PairingsBn254.Fr memory tmp_fr = PairingsBn254.new_fr(0);

        // addition gates
        for (uint256 i = 0; i < STATE_WIDTH; i++) {
            tmp_g1 = vk.gate_setup_commitments[i].point_mul(proof.wire_values_at_z[i]);
            res.point_add_assign(tmp_g1);
        }

        // multiplication gate
        tmp_fr.assign(proof.wire_values_at_z[0]);
        tmp_fr.mul_assign(proof.wire_values_at_z[1]);
        tmp_g1 = vk.gate_setup_commitments[STATE_WIDTH].point_mul(tmp_fr);
        res.point_add_assign(tmp_g1);

        // d_next
        tmp_g1 = vk.gate_setup_commitments[STATE_WIDTH + 2].point_mul(proof.wire_values_at_z_omega[0]); // index of q_d_next(x)
        res.point_add_assign(tmp_g1);

        // multiply by main gate selector(z)
        res.point_mul_assign(proof.gate_selector_values_at_z[0]); // these is only one explicitly opened selector

        PairingsBn254.Fr memory current_alpha = PairingsBn254.new_fr(ONE);

        // calculate scalar contribution from the range check gate
        tmp_fr = add_contribution_from_range_constraint_gates(state, proof, current_alpha);
        tmp_g1 = vk.gate_selector_commitments[1].point_mul(tmp_fr); // selector commitment for range constraint gate * scalar
        res.point_add_assign(tmp_g1);

        // proceed as normal to copy permutation
        current_alpha.mul_assign(state.alpha); // alpha^5

        PairingsBn254.Fr memory alpha_for_grand_product = PairingsBn254.copy(current_alpha);

        // z * non_res * beta + gamma + a
        PairingsBn254.Fr memory grand_product_part_at_z = PairingsBn254.copy(state.z);
        grand_product_part_at_z.mul_assign(state.beta);
        grand_product_part_at_z.add_assign(proof.wire_values_at_z[0]);
        grand_product_part_at_z.add_assign(state.gamma);
        for (uint256 i = 0; i < vk.copy_permutation_non_residues.length; i++) {
            tmp_fr.assign(state.z);
            tmp_fr.mul_assign(vk.copy_permutation_non_residues[i]);
            tmp_fr.mul_assign(state.beta);
            tmp_fr.add_assign(state.gamma);
            tmp_fr.add_assign(proof.wire_values_at_z[i + 1]);

            grand_product_part_at_z.mul_assign(tmp_fr);
        }

        grand_product_part_at_z.mul_assign(alpha_for_grand_product);

        // alpha^n & L_{0}(z), and we bump current_alpha
        current_alpha.mul_assign(state.alpha);

        tmp_fr.assign(state.cached_lagrange_evals[0]);
        tmp_fr.mul_assign(current_alpha);

        grand_product_part_at_z.add_assign(tmp_fr);

        // prefactor for grand_product(x) is complete

        // add to the linearization a part from the term
        // - (a(z) + beta*perm_a + gamma)*()*()*z(z*omega) * beta * perm_d(X)
        PairingsBn254.Fr memory last_permutation_part_at_z = PairingsBn254.new_fr(1);
        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            tmp_fr.assign(state.beta);
            tmp_fr.mul_assign(proof.permutation_polynomials_at_z[i]);
            tmp_fr.add_assign(state.gamma);
            tmp_fr.add_assign(proof.wire_values_at_z[i]);

            last_permutation_part_at_z.mul_assign(tmp_fr);
        }

        last_permutation_part_at_z.mul_assign(state.beta);
        last_permutation_part_at_z.mul_assign(proof.copy_grand_product_at_z_omega);
        last_permutation_part_at_z.mul_assign(alpha_for_grand_product); // we multiply by the power of alpha from the argument

        // actually multiply prefactors by z(x) and perm_d(x) and combine them
        tmp_g1 = proof.copy_permutation_grand_product_commitment.point_mul(grand_product_part_at_z);
        tmp_g1.point_sub_assign(vk.copy_permutation_commitments[STATE_WIDTH - 1].point_mul(last_permutation_part_at_z));

        res.point_add_assign(tmp_g1);
        // multiply them by v immedately as linearization has a factor of v^1
        res.point_mul_assign(state.v);
        // res now contains contribution from the gates linearization and
        // copy permutation part

        // now we need to add a part that is the rest
        // for z(x*omega):
        // - (a(z) + beta*perm_a + gamma)*()*()*(d(z) + gamma) * z(x*omega)
    }

    function aggregate_commitments(
        PartialVerifierState memory state,
        Proof memory proof,
        VerificationKey memory vk
    ) internal view returns (PairingsBn254.G1Point[2] memory res) {
        PairingsBn254.G1Point memory d = reconstruct_linearization_commitment(state, proof, vk);

        PairingsBn254.Fr memory z_in_domain_size = state.z.pow(vk.domain_size);

        PairingsBn254.G1Point memory tmp_g1 = PairingsBn254.P1();

        PairingsBn254.Fr memory aggregation_challenge = PairingsBn254.new_fr(1);

        PairingsBn254.G1Point memory commitment_aggregation = PairingsBn254.copy_g1(proof.quotient_poly_commitments[0]);
        PairingsBn254.Fr memory tmp_fr = PairingsBn254.new_fr(1);
        for (uint256 i = 1; i < proof.quotient_poly_commitments.length; i++) {
            tmp_fr.mul_assign(z_in_domain_size);
            tmp_g1 = proof.quotient_poly_commitments[i].point_mul(tmp_fr);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        aggregation_challenge.mul_assign(state.v);
        commitment_aggregation.point_add_assign(d);

        for (uint256 i = 0; i < proof.wire_commitments.length; i++) {
            aggregation_challenge.mul_assign(state.v);
            tmp_g1 = proof.wire_commitments[i].point_mul(aggregation_challenge);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        for (uint256 i = 0; i < NUM_GATE_SELECTORS_OPENED_EXPLICITLY; i++) {
            aggregation_challenge.mul_assign(state.v);
            tmp_g1 = vk.gate_selector_commitments[0].point_mul(aggregation_challenge);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        for (uint256 i = 0; i < vk.copy_permutation_commitments.length - 1; i++) {
            aggregation_challenge.mul_assign(state.v);
            tmp_g1 = vk.copy_permutation_commitments[i].point_mul(aggregation_challenge);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        aggregation_challenge.mul_assign(state.v);
        // now do prefactor for grand_product(x*omega)
        tmp_fr.assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        commitment_aggregation.point_add_assign(proof.copy_permutation_grand_product_commitment.point_mul(tmp_fr));

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        tmp_g1 = proof.wire_commitments[STATE_WIDTH - 1].point_mul(tmp_fr);
        commitment_aggregation.point_add_assign(tmp_g1);

        // collect opening values
        aggregation_challenge = PairingsBn254.new_fr(1);

        PairingsBn254.Fr memory aggregated_value = PairingsBn254.copy(proof.quotient_polynomial_at_z);

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(proof.linearization_polynomial_at_z);
        tmp_fr.mul_assign(aggregation_challenge);
        aggregated_value.add_assign(tmp_fr);

        for (uint256 i = 0; i < proof.wire_values_at_z.length; i++) {
            aggregation_challenge.mul_assign(state.v);

            tmp_fr.assign(proof.wire_values_at_z[i]);
            tmp_fr.mul_assign(aggregation_challenge);
            aggregated_value.add_assign(tmp_fr);
        }

        for (uint256 i = 0; i < proof.gate_selector_values_at_z.length; i++) {
            aggregation_challenge.mul_assign(state.v);
            tmp_fr.assign(proof.gate_selector_values_at_z[i]);
            tmp_fr.mul_assign(aggregation_challenge);
            aggregated_value.add_assign(tmp_fr);
        }

        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            aggregation_challenge.mul_assign(state.v);

            tmp_fr.assign(proof.permutation_polynomials_at_z[i]);
            tmp_fr.mul_assign(aggregation_challenge);
            aggregated_value.add_assign(tmp_fr);
        }

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(proof.copy_grand_product_at_z_omega);
        tmp_fr.mul_assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        aggregated_value.add_assign(tmp_fr);

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(proof.wire_values_at_z_omega[0]);
        tmp_fr.mul_assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        aggregated_value.add_assign(tmp_fr);

        commitment_aggregation.point_sub_assign(PairingsBn254.P1().point_mul(aggregated_value));

        PairingsBn254.G1Point memory pair_with_generator = commitment_aggregation;
        pair_with_generator.point_add_assign(proof.opening_at_z_proof.point_mul(state.z));

        tmp_fr.assign(state.z);
        tmp_fr.mul_assign(vk.omega);
        tmp_fr.mul_assign(state.u);
        pair_with_generator.point_add_assign(proof.opening_at_z_omega_proof.point_mul(tmp_fr));

        PairingsBn254.G1Point memory pair_with_x = proof.opening_at_z_omega_proof.point_mul(state.u);
        pair_with_x.point_add_assign(proof.opening_at_z_proof);
        pair_with_x.negate();

        res[0] = pair_with_generator;
        res[1] = pair_with_x;

        return res;
    }

    function verify_initial(
        PartialVerifierState memory state,
        Proof memory proof,
        VerificationKey memory vk
    ) internal view returns (bool) {
        require(proof.input_values.length == vk.num_inputs);
        require(vk.num_inputs >= 1);
        TranscriptLibrary.Transcript memory transcript = TranscriptLibrary.new_transcript();
        for (uint256 i = 0; i < vk.num_inputs; i++) {
            transcript.update_with_u256(proof.input_values[i]);
        }

        for (uint256 i = 0; i < proof.wire_commitments.length; i++) {
            transcript.update_with_g1(proof.wire_commitments[i]);
        }

        state.beta = transcript.get_challenge();
        state.gamma = transcript.get_challenge();

        transcript.update_with_g1(proof.copy_permutation_grand_product_commitment);
        state.alpha = transcript.get_challenge();

        for (uint256 i = 0; i < proof.quotient_poly_commitments.length; i++) {
            transcript.update_with_g1(proof.quotient_poly_commitments[i]);
        }

        state.z = transcript.get_challenge();

        uint256[] memory lagrange_poly_numbers = new uint256[](vk.num_inputs);
        for (uint256 i = 0; i < lagrange_poly_numbers.length; i++) {
            lagrange_poly_numbers[i] = i;
        }

        state.cached_lagrange_evals = batch_evaluate_lagrange_poly_out_of_domain(
            lagrange_poly_numbers,
            vk.domain_size,
            vk.omega,
            state.z
        );

        bool valid = verify_at_z(state, proof, vk);

        if (valid == false) {
            return false;
        }

        transcript.update_with_fr(proof.quotient_polynomial_at_z);

        for (uint256 i = 0; i < proof.wire_values_at_z.length; i++) {
            transcript.update_with_fr(proof.wire_values_at_z[i]);
        }

        for (uint256 i = 0; i < proof.wire_values_at_z_omega.length; i++) {
            transcript.update_with_fr(proof.wire_values_at_z_omega[i]);
        }

        transcript.update_with_fr(proof.gate_selector_values_at_z[0]);

        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            transcript.update_with_fr(proof.permutation_polynomials_at_z[i]);
        }

        transcript.update_with_fr(proof.copy_grand_product_at_z_omega);
        transcript.update_with_fr(proof.linearization_polynomial_at_z);

        state.v = transcript.get_challenge();
        transcript.update_with_g1(proof.opening_at_z_proof);
        transcript.update_with_g1(proof.opening_at_z_omega_proof);
        state.u = transcript.get_challenge();

        return true;
    }

    // This verifier is for a PLONK with a state width 4
    // and main gate equation
    // q_a(X) * a(X) +
    // q_b(X) * b(X) +
    // q_c(X) * c(X) +
    // q_d(X) * d(X) +
    // q_m(X) * a(X) * b(X) +
    // q_constants(X)+
    // q_d_next(X) * d(X*omega)
    // where q_{}(X) are selectors a, b, c, d - state (witness) polynomials
    // q_d_next(X) "peeks" into the next row of the trace, so it takes
    // the same d(X) polynomial, but shifted

    function aggregate_for_verification(Proof memory proof, VerificationKey memory vk)
    internal
    view
    returns (bool valid, PairingsBn254.G1Point[2] memory part)
    {
        PartialVerifierState memory state;

        valid = verify_initial(state, proof, vk);

        if (valid == false) {
            return (valid, part);
        }

        part = aggregate_commitments(state, proof, vk);

        (valid, part);
    }

    function verify(Proof memory proof, VerificationKey memory vk) internal view returns (bool) {
        (bool valid, PairingsBn254.G1Point[2] memory recursive_proof_part) = aggregate_for_verification(proof, vk);
        if (valid == false) {
            return false;
        }

        valid = PairingsBn254.pairingProd2(
            recursive_proof_part[0],
            PairingsBn254.P2(),
            recursive_proof_part[1],
            vk.g2_x
        );

        return valid;
    }

    function verify_recursive(
        Proof memory proof,
        VerificationKey memory vk,
        uint256 recursive_vks_root,
        uint8 max_valid_index,
        uint8[] memory recursive_vks_indexes,
        uint256[] memory individual_vks_inputs,
        uint256[16] memory subproofs_limbs
    ) internal view returns (bool) {
        (uint256 recursive_input, PairingsBn254.G1Point[2] memory aggregated_g1s) =
        reconstruct_recursive_public_input(
            recursive_vks_root,
            max_valid_index,
            recursive_vks_indexes,
            individual_vks_inputs,
            subproofs_limbs
        );

        assert(recursive_input == proof.input_values[0]);

        (bool valid, PairingsBn254.G1Point[2] memory recursive_proof_part) = aggregate_for_verification(proof, vk);
        if (valid == false) {
            return false;
        }

        // aggregated_g1s = inner
        // recursive_proof_part = outer
        PairingsBn254.G1Point[2] memory combined = combine_inner_and_outer(aggregated_g1s, recursive_proof_part);

        valid = PairingsBn254.pairingProd2(combined[0], PairingsBn254.P2(), combined[1], vk.g2_x);

        return valid;
    }

    function combine_inner_and_outer(PairingsBn254.G1Point[2] memory inner, PairingsBn254.G1Point[2] memory outer)
    internal
    view
    returns (PairingsBn254.G1Point[2] memory result)
    {
        // reuse the transcript primitive
        TranscriptLibrary.Transcript memory transcript = TranscriptLibrary.new_transcript();
        transcript.update_with_g1(inner[0]);
        transcript.update_with_g1(inner[1]);
        transcript.update_with_g1(outer[0]);
        transcript.update_with_g1(outer[1]);
        PairingsBn254.Fr memory challenge = transcript.get_challenge();
        // 1 * inner + challenge * outer
        result[0] = PairingsBn254.copy_g1(inner[0]);
        result[1] = PairingsBn254.copy_g1(inner[1]);
        PairingsBn254.G1Point memory tmp = outer[0].point_mul(challenge);
        result[0].point_add_assign(tmp);
        tmp = outer[1].point_mul(challenge);
        result[1].point_add_assign(tmp);

        return result;
    }

    function reconstruct_recursive_public_input(
        uint256 recursive_vks_root,
        uint8 max_valid_index,
        uint8[] memory recursive_vks_indexes,
        uint256[] memory individual_vks_inputs,
        uint256[16] memory subproofs_aggregated
    ) internal pure returns (uint256 recursive_input, PairingsBn254.G1Point[2] memory reconstructed_g1s) {
        assert(recursive_vks_indexes.length == individual_vks_inputs.length);
        bytes memory concatenated = abi.encodePacked(recursive_vks_root);
        uint8 index;
        for (uint256 i = 0; i < recursive_vks_indexes.length; i++) {
            index = recursive_vks_indexes[i];
            assert(index <= max_valid_index);
            concatenated = abi.encodePacked(concatenated, index);
        }
        uint256 input;
        for (uint256 i = 0; i < recursive_vks_indexes.length; i++) {
            input = individual_vks_inputs[i];
            assert(input < r_mod);
            concatenated = abi.encodePacked(concatenated, input);
        }

        concatenated = abi.encodePacked(concatenated, subproofs_aggregated);

        bytes32 commitment = sha256(concatenated);
        recursive_input = uint256(commitment) & RECURSIVE_CIRCUIT_INPUT_COMMITMENT_MASK;

        reconstructed_g1s[0] = PairingsBn254.new_g1_checked(
            subproofs_aggregated[0] +
            (subproofs_aggregated[1] << LIMB_WIDTH) +
            (subproofs_aggregated[2] << (2 * LIMB_WIDTH)) +
            (subproofs_aggregated[3] << (3 * LIMB_WIDTH)),
            subproofs_aggregated[4] +
            (subproofs_aggregated[5] << LIMB_WIDTH) +
            (subproofs_aggregated[6] << (2 * LIMB_WIDTH)) +
            (subproofs_aggregated[7] << (3 * LIMB_WIDTH))
        );

        reconstructed_g1s[1] = PairingsBn254.new_g1_checked(
            subproofs_aggregated[8] +
            (subproofs_aggregated[9] << LIMB_WIDTH) +
            (subproofs_aggregated[10] << (2 * LIMB_WIDTH)) +
            (subproofs_aggregated[11] << (3 * LIMB_WIDTH)),
            subproofs_aggregated[12] +
            (subproofs_aggregated[13] << LIMB_WIDTH) +
            (subproofs_aggregated[14] << (2 * LIMB_WIDTH)) +
            (subproofs_aggregated[15] << (3 * LIMB_WIDTH))
        );

        return (recursive_input, reconstructed_g1s);
    }
}

contract VerifierWithDeserialize is Plonk4VerifierWithAccessToDNext {
    uint256 constant SERIALIZED_PROOF_LENGTH = 34;

    function deserialize_proof(uint256[] memory public_inputs, uint256[] memory serialized_proof)
    internal
    pure
    returns (Proof memory proof)
    {
        require(serialized_proof.length == SERIALIZED_PROOF_LENGTH);
        proof.input_values = new uint256[](public_inputs.length);
        for (uint256 i = 0; i < public_inputs.length; i++) {
            proof.input_values[i] = public_inputs[i];
        }

        uint256 j = 0;
        for (uint256 i = 0; i < STATE_WIDTH; i++) {
            proof.wire_commitments[i] = PairingsBn254.new_g1_checked(serialized_proof[j], serialized_proof[j + 1]);

            j += 2;
        }

        proof.copy_permutation_grand_product_commitment = PairingsBn254.new_g1_checked(
            serialized_proof[j],
            serialized_proof[j + 1]
        );
        j += 2;

        for (uint256 i = 0; i < STATE_WIDTH; i++) {
            proof.quotient_poly_commitments[i] = PairingsBn254.new_g1_checked(
                serialized_proof[j],
                serialized_proof[j + 1]
            );

            j += 2;
        }

        for (uint256 i = 0; i < STATE_WIDTH; i++) {
            proof.wire_values_at_z[i] = PairingsBn254.new_fr(serialized_proof[j]);

            j += 1;
        }

        for (uint256 i = 0; i < proof.wire_values_at_z_omega.length; i++) {
            proof.wire_values_at_z_omega[i] = PairingsBn254.new_fr(serialized_proof[j]);

            j += 1;
        }

        for (uint256 i = 0; i < proof.gate_selector_values_at_z.length; i++) {
            proof.gate_selector_values_at_z[i] = PairingsBn254.new_fr(serialized_proof[j]);

            j += 1;
        }

        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            proof.permutation_polynomials_at_z[i] = PairingsBn254.new_fr(serialized_proof[j]);

            j += 1;
        }

        proof.copy_grand_product_at_z_omega = PairingsBn254.new_fr(serialized_proof[j]);

        j += 1;

        proof.quotient_polynomial_at_z = PairingsBn254.new_fr(serialized_proof[j]);

        j += 1;

        proof.linearization_polynomial_at_z = PairingsBn254.new_fr(serialized_proof[j]);

        j += 1;

        proof.opening_at_z_proof = PairingsBn254.new_g1_checked(serialized_proof[j], serialized_proof[j + 1]);
        j += 2;

        proof.opening_at_z_omega_proof = PairingsBn254.new_g1_checked(serialized_proof[j], serialized_proof[j + 1]);
    }

    function verify_serialized_proof(
        uint256[] memory public_inputs,
        uint256[] memory serialized_proof,
        VerificationKey memory vk
    ) public view returns (bool) {
        require(vk.num_inputs == public_inputs.length);

        Proof memory proof = deserialize_proof(public_inputs, serialized_proof);

        bool valid = verify(proof, vk);

        return valid;
    }

    function verify_serialized_proof_with_recursion(
        uint256[] memory public_inputs,
        uint256[] memory serialized_proof,
        uint256 recursive_vks_root,
        uint8 max_valid_index,
        uint8[] memory recursive_vks_indexes,
        uint256[] memory individual_vks_inputs,
        uint256[16] memory subproofs_limbs,
        VerificationKey memory vk
    ) public view returns (bool) {
        require(vk.num_inputs == public_inputs.length);

        Proof memory proof = deserialize_proof(public_inputs, serialized_proof);

        bool valid =
        verify_recursive(
            proof,
            vk,
            recursive_vks_root,
            max_valid_index,
            recursive_vks_indexes,
            individual_vks_inputs,
            subproofs_limbs
        );

        return valid;
    }
}

contract Plonk4VerifierWithAccessToDNextOld {
    using PairingsBn254 for PairingsBn254.G1Point;
    using PairingsBn254 for PairingsBn254.G2Point;
    using PairingsBn254 for PairingsBn254.Fr;

    using TranscriptLibrary for TranscriptLibrary.Transcript;

    uint256 constant STATE_WIDTH_OLD = 4;
    uint256 constant ACCESSIBLE_STATE_POLYS_ON_NEXT_STEP_OLD = 1;

    struct VerificationKeyOld {
        uint256 domain_size;
        uint256 num_inputs;
        PairingsBn254.Fr omega;
        PairingsBn254.G1Point[STATE_WIDTH_OLD + 2] selector_commitments; // STATE_WIDTH for witness + multiplication + constant
        PairingsBn254.G1Point[ACCESSIBLE_STATE_POLYS_ON_NEXT_STEP_OLD] next_step_selector_commitments;
        PairingsBn254.G1Point[STATE_WIDTH_OLD] permutation_commitments;
        PairingsBn254.Fr[STATE_WIDTH_OLD - 1] permutation_non_residues;
        PairingsBn254.G2Point g2_x;
    }

    struct ProofOld {
        uint256[] input_values;
        PairingsBn254.G1Point[STATE_WIDTH_OLD] wire_commitments;
        PairingsBn254.G1Point grand_product_commitment;
        PairingsBn254.G1Point[STATE_WIDTH_OLD] quotient_poly_commitments;
        PairingsBn254.Fr[STATE_WIDTH_OLD] wire_values_at_z;
        PairingsBn254.Fr[ACCESSIBLE_STATE_POLYS_ON_NEXT_STEP_OLD] wire_values_at_z_omega;
        PairingsBn254.Fr grand_product_at_z_omega;
        PairingsBn254.Fr quotient_polynomial_at_z;
        PairingsBn254.Fr linearization_polynomial_at_z;
        PairingsBn254.Fr[STATE_WIDTH_OLD - 1] permutation_polynomials_at_z;
        PairingsBn254.G1Point opening_at_z_proof;
        PairingsBn254.G1Point opening_at_z_omega_proof;
    }

    struct PartialVerifierStateOld {
        PairingsBn254.Fr alpha;
        PairingsBn254.Fr beta;
        PairingsBn254.Fr gamma;
        PairingsBn254.Fr v;
        PairingsBn254.Fr u;
        PairingsBn254.Fr z;
        PairingsBn254.Fr[] cached_lagrange_evals;
    }

    function evaluate_lagrange_poly_out_of_domain_old(
        uint256 poly_num,
        uint256 domain_size,
        PairingsBn254.Fr memory omega,
        PairingsBn254.Fr memory at
    ) internal view returns (PairingsBn254.Fr memory res) {
        require(poly_num < domain_size);
        PairingsBn254.Fr memory one = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory omega_power = omega.pow(poly_num);
        res = at.pow(domain_size);
        res.sub_assign(one);
        require(res.value != 0); // Vanishing polynomial can not be zero at point `at`
        res.mul_assign(omega_power);

        PairingsBn254.Fr memory den = PairingsBn254.copy(at);
        den.sub_assign(omega_power);
        den.mul_assign(PairingsBn254.new_fr(domain_size));

        den = den.inverse();

        res.mul_assign(den);
    }

    function batch_evaluate_lagrange_poly_out_of_domain_old(
        uint256[] memory poly_nums,
        uint256 domain_size,
        PairingsBn254.Fr memory omega,
        PairingsBn254.Fr memory at
    ) internal view returns (PairingsBn254.Fr[] memory res) {
        PairingsBn254.Fr memory one = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory tmp_1 = PairingsBn254.new_fr(0);
        PairingsBn254.Fr memory tmp_2 = PairingsBn254.new_fr(domain_size);
        PairingsBn254.Fr memory vanishing_at_z = at.pow(domain_size);
        vanishing_at_z.sub_assign(one);
        // we can not have random point z be in domain
        require(vanishing_at_z.value != 0);
        PairingsBn254.Fr[] memory nums = new PairingsBn254.Fr[](poly_nums.length);
        PairingsBn254.Fr[] memory dens = new PairingsBn254.Fr[](poly_nums.length);
        // numerators in a form omega^i * (z^n - 1)
        // denoms in a form (z - omega^i) * N
        for (uint256 i = 0; i < poly_nums.length; i++) {
            tmp_1 = omega.pow(poly_nums[i]); // power of omega
            nums[i].assign(vanishing_at_z);
            nums[i].mul_assign(tmp_1);

            dens[i].assign(at); // (X - omega^i) * N
            dens[i].sub_assign(tmp_1);
            dens[i].mul_assign(tmp_2); // mul by domain size
        }

        PairingsBn254.Fr[] memory partial_products = new PairingsBn254.Fr[](poly_nums.length);
        partial_products[0].assign(PairingsBn254.new_fr(1));
        for (uint256 i = 1; i < dens.length ; i++) {
            partial_products[i].assign(dens[i - 1]);
            partial_products[i].mul_assign(partial_products[i-1]);
        }

        tmp_2.assign(partial_products[partial_products.length - 1]);
        tmp_2.mul_assign(dens[dens.length - 1]);
        tmp_2 = tmp_2.inverse(); // tmp_2 contains a^-1 * b^-1 (with! the last one)

        for (uint256 i = dens.length - 1; i < dens.length; i--) {
            tmp_1.assign(tmp_2); // all inversed
            tmp_1.mul_assign(partial_products[i]); // clear lowest terms
            tmp_2.mul_assign(dens[i]);
            dens[i].assign(tmp_1);
            if (i == 0) {
                break;
            }
        }

        for (uint256 i = 0; i < nums.length; i++) {
            nums[i].mul_assign(dens[i]);
        }

        return nums;
    }

    function evaluate_vanishing_old(uint256 domain_size, PairingsBn254.Fr memory at)
    internal
    view
    returns (PairingsBn254.Fr memory res)
    {
        res = at.pow(domain_size);
        res.sub_assign(PairingsBn254.new_fr(1));
    }

    function verify_at_z(
        PartialVerifierStateOld memory state,
        ProofOld memory proof,
        VerificationKeyOld memory vk
    ) internal view returns (bool) {
        PairingsBn254.Fr memory lhs = evaluate_vanishing_old(vk.domain_size, state.z);
        require(lhs.value != 0); // we can not check a polynomial relationship if point `z` is in the domain
        lhs.mul_assign(proof.quotient_polynomial_at_z);

        PairingsBn254.Fr memory quotient_challenge = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory rhs = PairingsBn254.copy(proof.linearization_polynomial_at_z);

        // public inputs
        PairingsBn254.Fr memory tmp = PairingsBn254.new_fr(0);
        for (uint256 i = 0; i < proof.input_values.length; i++) {
            tmp.assign(state.cached_lagrange_evals[i]);
            tmp.mul_assign(PairingsBn254.new_fr(proof.input_values[i]));
            rhs.add_assign(tmp);
        }

        quotient_challenge.mul_assign(state.alpha);

        PairingsBn254.Fr memory z_part = PairingsBn254.copy(proof.grand_product_at_z_omega);
        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            tmp.assign(proof.permutation_polynomials_at_z[i]);
            tmp.mul_assign(state.beta);
            tmp.add_assign(state.gamma);
            tmp.add_assign(proof.wire_values_at_z[i]);

            z_part.mul_assign(tmp);
        }

        tmp.assign(state.gamma);
        // we need a wire value of the last polynomial in enumeration
        tmp.add_assign(proof.wire_values_at_z[STATE_WIDTH_OLD - 1]);

        z_part.mul_assign(tmp);
        z_part.mul_assign(quotient_challenge);

        rhs.sub_assign(z_part);

        quotient_challenge.mul_assign(state.alpha);

        tmp.assign(state.cached_lagrange_evals[0]);
        tmp.mul_assign(quotient_challenge);

        rhs.sub_assign(tmp);

        return lhs.value == rhs.value;
    }

    function reconstruct_d(
        PartialVerifierStateOld memory state,
        ProofOld memory proof,
        VerificationKeyOld memory vk
    ) internal view returns (PairingsBn254.G1Point memory res) {
        // we compute what power of v is used as a delinearization factor in batch opening of
        // commitments. Let's label W(x) = 1 / (x - z) *
        // [
        // t_0(x) + z^n * t_1(x) + z^2n * t_2(x) + z^3n * t_3(x) - t(z)
        // + v (r(x) - r(z))
        // + v^{2..5} * (witness(x) - witness(z))
        // + v^(6..8) * (permutation(x) - permutation(z))
        // ]
        // W'(x) = 1 / (x - z*omega) *
        // [
        // + v^9 (z(x) - z(z*omega)) <- we need this power
        // + v^10 * (d(x) - d(z*omega))
        // ]
        //
        // we pay a little for a few arithmetic operations to not introduce another constant
        uint256 power_for_z_omega_opening = 1 + 1 + STATE_WIDTH_OLD + STATE_WIDTH_OLD - 1;
        res = PairingsBn254.copy_g1(vk.selector_commitments[STATE_WIDTH_OLD + 1]);

        PairingsBn254.G1Point memory tmp_g1 = PairingsBn254.P1();
        PairingsBn254.Fr memory tmp_fr = PairingsBn254.new_fr(0);

        // addition gates
        for (uint256 i = 0; i < STATE_WIDTH_OLD; i++) {
            tmp_g1 = vk.selector_commitments[i].point_mul(proof.wire_values_at_z[i]);
            res.point_add_assign(tmp_g1);
        }

        // multiplication gate
        tmp_fr.assign(proof.wire_values_at_z[0]);
        tmp_fr.mul_assign(proof.wire_values_at_z[1]);
        tmp_g1 = vk.selector_commitments[STATE_WIDTH_OLD].point_mul(tmp_fr);
        res.point_add_assign(tmp_g1);

        // d_next
        tmp_g1 = vk.next_step_selector_commitments[0].point_mul(proof.wire_values_at_z_omega[0]);
        res.point_add_assign(tmp_g1);

        // z * non_res * beta + gamma + a
        PairingsBn254.Fr memory grand_product_part_at_z = PairingsBn254.copy(state.z);
        grand_product_part_at_z.mul_assign(state.beta);
        grand_product_part_at_z.add_assign(proof.wire_values_at_z[0]);
        grand_product_part_at_z.add_assign(state.gamma);
        for (uint256 i = 0; i < vk.permutation_non_residues.length; i++) {
            tmp_fr.assign(state.z);
            tmp_fr.mul_assign(vk.permutation_non_residues[i]);
            tmp_fr.mul_assign(state.beta);
            tmp_fr.add_assign(state.gamma);
            tmp_fr.add_assign(proof.wire_values_at_z[i + 1]);

            grand_product_part_at_z.mul_assign(tmp_fr);
        }

        grand_product_part_at_z.mul_assign(state.alpha);

        tmp_fr.assign(state.cached_lagrange_evals[0]);
        tmp_fr.mul_assign(state.alpha);
        tmp_fr.mul_assign(state.alpha);

        grand_product_part_at_z.add_assign(tmp_fr);

        PairingsBn254.Fr memory grand_product_part_at_z_omega = state.v.pow(power_for_z_omega_opening);
        grand_product_part_at_z_omega.mul_assign(state.u);

        PairingsBn254.Fr memory last_permutation_part_at_z = PairingsBn254.new_fr(1);
        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            tmp_fr.assign(state.beta);
            tmp_fr.mul_assign(proof.permutation_polynomials_at_z[i]);
            tmp_fr.add_assign(state.gamma);
            tmp_fr.add_assign(proof.wire_values_at_z[i]);

            last_permutation_part_at_z.mul_assign(tmp_fr);
        }

        last_permutation_part_at_z.mul_assign(state.beta);
        last_permutation_part_at_z.mul_assign(proof.grand_product_at_z_omega);
        last_permutation_part_at_z.mul_assign(state.alpha);

        // add to the linearization
        tmp_g1 = proof.grand_product_commitment.point_mul(grand_product_part_at_z);
        tmp_g1.point_sub_assign(vk.permutation_commitments[STATE_WIDTH_OLD - 1].point_mul(last_permutation_part_at_z));

        res.point_add_assign(tmp_g1);
        res.point_mul_assign(state.v);

        res.point_add_assign(proof.grand_product_commitment.point_mul(grand_product_part_at_z_omega));
    }

    function verify_commitments(
        PartialVerifierStateOld memory state,
        ProofOld memory proof,
        VerificationKeyOld memory vk
    ) internal view returns (bool) {
        PairingsBn254.G1Point memory d = reconstruct_d(state, proof, vk);

        PairingsBn254.Fr memory z_in_domain_size = state.z.pow(vk.domain_size);

        PairingsBn254.G1Point memory tmp_g1 = PairingsBn254.P1();

        PairingsBn254.Fr memory aggregation_challenge = PairingsBn254.new_fr(1);

        PairingsBn254.G1Point memory commitment_aggregation = PairingsBn254.copy_g1(proof.quotient_poly_commitments[0]);
        PairingsBn254.Fr memory tmp_fr = PairingsBn254.new_fr(1);
        for (uint256 i = 1; i < proof.quotient_poly_commitments.length; i++) {
            tmp_fr.mul_assign(z_in_domain_size);
            tmp_g1 = proof.quotient_poly_commitments[i].point_mul(tmp_fr);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        aggregation_challenge.mul_assign(state.v);
        commitment_aggregation.point_add_assign(d);

        for (uint256 i = 0; i < proof.wire_commitments.length; i++) {
            aggregation_challenge.mul_assign(state.v);
            tmp_g1 = proof.wire_commitments[i].point_mul(aggregation_challenge);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        for (uint256 i = 0; i < vk.permutation_commitments.length - 1; i++) {
            aggregation_challenge.mul_assign(state.v);
            tmp_g1 = vk.permutation_commitments[i].point_mul(aggregation_challenge);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        aggregation_challenge.mul_assign(state.v);

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        tmp_g1 = proof.wire_commitments[STATE_WIDTH_OLD - 1].point_mul(tmp_fr);
        commitment_aggregation.point_add_assign(tmp_g1);

        // collect opening values
        aggregation_challenge = PairingsBn254.new_fr(1);

        PairingsBn254.Fr memory aggregated_value = PairingsBn254.copy(proof.quotient_polynomial_at_z);

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(proof.linearization_polynomial_at_z);
        tmp_fr.mul_assign(aggregation_challenge);
        aggregated_value.add_assign(tmp_fr);

        for (uint256 i = 0; i < proof.wire_values_at_z.length; i++) {
            aggregation_challenge.mul_assign(state.v);

            tmp_fr.assign(proof.wire_values_at_z[i]);
            tmp_fr.mul_assign(aggregation_challenge);
            aggregated_value.add_assign(tmp_fr);
        }

        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            aggregation_challenge.mul_assign(state.v);

            tmp_fr.assign(proof.permutation_polynomials_at_z[i]);
            tmp_fr.mul_assign(aggregation_challenge);
            aggregated_value.add_assign(tmp_fr);
        }

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(proof.grand_product_at_z_omega);
        tmp_fr.mul_assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        aggregated_value.add_assign(tmp_fr);

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(proof.wire_values_at_z_omega[0]);
        tmp_fr.mul_assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        aggregated_value.add_assign(tmp_fr);

        commitment_aggregation.point_sub_assign(PairingsBn254.P1().point_mul(aggregated_value));

        PairingsBn254.G1Point memory pair_with_generator = commitment_aggregation;
        pair_with_generator.point_add_assign(proof.opening_at_z_proof.point_mul(state.z));

        tmp_fr.assign(state.z);
        tmp_fr.mul_assign(vk.omega);
        tmp_fr.mul_assign(state.u);
        pair_with_generator.point_add_assign(proof.opening_at_z_omega_proof.point_mul(tmp_fr));

        PairingsBn254.G1Point memory pair_with_x = proof.opening_at_z_omega_proof.point_mul(state.u);
        pair_with_x.point_add_assign(proof.opening_at_z_proof);
        pair_with_x.negate();

        return PairingsBn254.pairingProd2(pair_with_generator, PairingsBn254.P2(), pair_with_x, vk.g2_x);
    }

    function verify_initial(
        PartialVerifierStateOld memory state,
        ProofOld memory proof,
        VerificationKeyOld memory vk
    ) internal view returns (bool) {
        require(proof.input_values.length == vk.num_inputs);
        require(vk.num_inputs >= 1);
        TranscriptLibrary.Transcript memory transcript = TranscriptLibrary.new_transcript();
        for (uint256 i = 0; i < vk.num_inputs; i++) {
            transcript.update_with_u256(proof.input_values[i]);
        }

        for (uint256 i = 0; i < proof.wire_commitments.length; i++) {
            transcript.update_with_g1(proof.wire_commitments[i]);
        }

        state.beta = transcript.get_challenge();
        state.gamma = transcript.get_challenge();

        transcript.update_with_g1(proof.grand_product_commitment);
        state.alpha = transcript.get_challenge();

        for (uint256 i = 0; i < proof.quotient_poly_commitments.length; i++) {
            transcript.update_with_g1(proof.quotient_poly_commitments[i]);
        }

        state.z = transcript.get_challenge();

        uint256[] memory lagrange_poly_numbers = new uint256[](vk.num_inputs);
        for (uint256 i = 0; i < lagrange_poly_numbers.length; i++) {
            lagrange_poly_numbers[i] = i;
        }

        state.cached_lagrange_evals = batch_evaluate_lagrange_poly_out_of_domain_old(
            lagrange_poly_numbers,
            vk.domain_size,
            vk.omega,
            state.z
        );

        bool valid = verify_at_z(state, proof, vk);

        if (valid == false) {
            return false;
        }

        for (uint256 i = 0; i < proof.wire_values_at_z.length; i++) {
            transcript.update_with_fr(proof.wire_values_at_z[i]);
        }

        for (uint256 i = 0; i < proof.wire_values_at_z_omega.length; i++) {
            transcript.update_with_fr(proof.wire_values_at_z_omega[i]);
        }

        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            transcript.update_with_fr(proof.permutation_polynomials_at_z[i]);
        }

        transcript.update_with_fr(proof.quotient_polynomial_at_z);
        transcript.update_with_fr(proof.linearization_polynomial_at_z);
        transcript.update_with_fr(proof.grand_product_at_z_omega);

        state.v = transcript.get_challenge();
        transcript.update_with_g1(proof.opening_at_z_proof);
        transcript.update_with_g1(proof.opening_at_z_omega_proof);
        state.u = transcript.get_challenge();

        return true;
    }

    // This verifier is for a PLONK with a state width 4
    // and main gate equation
    // q_a(X) * a(X) +
    // q_b(X) * b(X) +
    // q_c(X) * c(X) +
    // q_d(X) * d(X) +
    // q_m(X) * a(X) * b(X) +
    // q_constants(X)+
    // q_d_next(X) * d(X*omega)
    // where q_{}(X) are selectors a, b, c, d - state (witness) polynomials
    // q_d_next(X) "peeks" into the next row of the trace, so it takes
    // the same d(X) polynomial, but shifted

    function verify_old(ProofOld memory proof, VerificationKeyOld memory vk) internal view returns (bool) {
        PartialVerifierStateOld memory state;

        bool valid = verify_initial(state, proof, vk);

        if (valid == false) {
            return false;
        }

        valid = verify_commitments(state, proof, vk);

        return valid;
    }
}

contract VerifierWithDeserializeOld is Plonk4VerifierWithAccessToDNextOld {
    uint256 constant SERIALIZED_PROOF_LENGTH_OLD = 33;

    function deserialize_proof_old(uint256[] memory public_inputs, uint256[] memory serialized_proof)
    internal
    pure
    returns (ProofOld memory proof)
    {
        require(serialized_proof.length == SERIALIZED_PROOF_LENGTH_OLD);
        proof.input_values = new uint256[](public_inputs.length);
        for (uint256 i = 0; i < public_inputs.length; i++) {
            proof.input_values[i] = public_inputs[i];
        }

        uint256 j = 0;
        for (uint256 i = 0; i < STATE_WIDTH_OLD; i++) {
            proof.wire_commitments[i] = PairingsBn254.new_g1_checked(serialized_proof[j], serialized_proof[j + 1]);

            j += 2;
        }

        proof.grand_product_commitment = PairingsBn254.new_g1_checked(serialized_proof[j], serialized_proof[j + 1]);
        j += 2;

        for (uint256 i = 0; i < STATE_WIDTH_OLD; i++) {
            proof.quotient_poly_commitments[i] = PairingsBn254.new_g1_checked(
                serialized_proof[j],
                serialized_proof[j + 1]
            );

            j += 2;
        }

        for (uint256 i = 0; i < STATE_WIDTH_OLD; i++) {
            proof.wire_values_at_z[i] = PairingsBn254.new_fr(serialized_proof[j]);

            j += 1;
        }

        for (uint256 i = 0; i < proof.wire_values_at_z_omega.length; i++) {
            proof.wire_values_at_z_omega[i] = PairingsBn254.new_fr(serialized_proof[j]);

            j += 1;
        }

        proof.grand_product_at_z_omega = PairingsBn254.new_fr(serialized_proof[j]);

        j += 1;

        proof.quotient_polynomial_at_z = PairingsBn254.new_fr(serialized_proof[j]);

        j += 1;

        proof.linearization_polynomial_at_z = PairingsBn254.new_fr(serialized_proof[j]);

        j += 1;

        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            proof.permutation_polynomials_at_z[i] = PairingsBn254.new_fr(serialized_proof[j]);

            j += 1;
        }

        proof.opening_at_z_proof = PairingsBn254.new_g1_checked(serialized_proof[j], serialized_proof[j + 1]);
        j += 2;

        proof.opening_at_z_omega_proof = PairingsBn254.new_g1_checked(serialized_proof[j], serialized_proof[j + 1]);
    }
}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./Registration.sol";
import "./Depositor.sol";
import "./Withdrawer.sol";
import "./updateState.sol";
import "./globalConfig.sol";
import "./dac.sol";

/// @title main contract
contract DecentralizedPerpetual is Registration, Depositor, Withdrawer, UpdateState, GlobalConfig, Dac {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event TokenRecovery(address token, uint256 amount);

    struct params {
        I_Verifier verifierAddress;
        IERC20Upgradeable collateralToken;
        SyntheticAssetInfo[] synthetic_assets;
        bytes32 accountRoot;
        bytes32 orderStateHash;
        address userAdmin;
        address genesisGovernor;
        address genesisValidator;
        address[] dacMembers;
        uint8 innerDecimal;
        uint32 dac_reg_timelock;
        uint32 global_config_change_timelock;
        uint32 funding_validity_period;
        uint32 price_validity_period;
        uint64 max_funding_rate;
        uint16 max_asset_num;
        uint16 max_oracle_num;
        uint256 deposit_cancel_timelock;
        uint256 forced_action_expire_time;
    }

    function initialize(params calldata param) external {
        initializeReentrancyGuard();

        // genesis block state
        accountRoot      = param.accountRoot;
        orderStateHash   = param.orderStateHash;

        // verifier
        verifier = param.verifierAddress;

        // governor/validator/UserAdmin
        initGovernor(param.genesisGovernor, param.genesisValidator);
        userAdmin = param.userAdmin;

        // DAC
        MIN_DAC_MEMBER = 6;
        TIMELOCK_DAC_REG = param.dac_reg_timelock;
        for (uint256 i = 0; i < param.dacMembers.length; ++i) {
            addDac(param.dacMembers[i]);
        }
        require(dacNum >= MIN_DAC_MEMBER, "idmu");


        // global config
        MAX_ASSETS_COUNT = param.max_asset_num;
        MAX_NUMBER_ORACLES = param.max_oracle_num;
        TIMELOCK_GLOBAL_CONFIG_CHANGE = param.global_config_change_timelock;

        globalConfigHash = initGlobalConfig(
            param.synthetic_assets,
            param.funding_validity_period,
            param.price_validity_period,
            param.max_funding_rate,
            MAX_ASSETS_COUNT,
            MAX_NUMBER_ORACLES
            );
        resetGlobalConfigValidBlockNum();

        // system Token Config
        collateralToken = param.collateralToken;
        innerDecimal = param.innerDecimal;
        (bool success, bytes memory returndata) = address(collateralToken).call(abi.encodeWithSignature("decimals()"));
        require(success);
        systemTokenDecimal = abi.decode(returndata, (uint8));

        DEPOSIT_CANCEL_TIMELOCK = param.deposit_cancel_timelock;
        FORCED_ACTION_EXPIRE_TIME = param.forced_action_expire_time;

    }

    // function upgrade(bytes calldata args) onlyGovernor external {
    // }

    function registerAndDeposit(
        address ethAddr,
        uint256[] memory l2Keys,
        bytes calldata signature,
        uint32[] memory depositId,
        uint256[] memory amount
	) external payable {
        require(l2Keys.length == 2, "len0");
        require(depositId.length == 2, "len1");
        require(depositId.length == amount.length, "rad0");

        register(ethAddr, l2Keys, signature);

        for (uint256 i = 0; i < depositId.length; ++i) {
            deposit(l2Keys[depositId[i]], amount[i]);
        }
    }


    // allow to recovery wrong token sent to the contract
    function recoverWrongToken(address token, uint256 amount) external onlyGovernor nonReentrant {
        require(token != address(collateralToken), "cbrst");  // "Cannot be system token"
        if (token == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            IERC20Upgradeable(token).safeTransfer(address(msg.sender), amount);
        }
        emit TokenRecovery(token, amount);
    }


    receive() external payable {
    }
}

pragma solidity >= 0.8.12;

// SPDX-License-Identifier: Apache-2.0.


import "./Storage.sol";
import "./libs/Bytes.sol";

abstract contract Registration is Storage {
    event LogUserRegistered(address ethAddr, uint256[] l2Keys, address sender);
    
    function register(address ethAddr, uint256[] memory l2Keys, bytes calldata signature) public {
	    for (uint32 i = 0; i < l2Keys.length; ++i) {
            require(ethKeys[l2Keys[i]] == address(0), "l2Key already registered");
            ethKeys[l2Keys[i]] = ethAddr;
        }

        bytes32 concatKeyHash = EMPTY_STRING_KECCAK;
        for (uint256 i = 0; i < l2Keys.length; ++i) {
            concatKeyHash = keccak256(abi.encodePacked(concatKeyHash, l2Keys[i]));
        }

        bytes memory orig_msg = bytes.concat(abi.encode(ethAddr), concatKeyHash);

        bytes memory message = bytes.concat(
                "\x19Ethereum Signed Message:\n130",  // 10-th 130
                "0x", Bytes.bytesToHexASCIIBytes(orig_msg)
        );

        address signer = ECDSA.recover(keccak256(message), signature);
        require(signer == userAdmin, "User Register Sinature Invalid");

	    // for (uint32 i = 0; i < l2Keys.length; ++i) {
 	    //     ethKeys[l2Keys[i]] = ethAddr;
	    // }

        emit LogUserRegistered(ethAddr, l2Keys, msg.sender);
    }
}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: Apache-2.0.


import "./Storage.sol";

abstract contract Depositor is Storage {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    event LogDeposit(
        address ethAddr,
        uint256 l2Key,
        uint256 amount
    );

    event LogDepositCancel(uint256 l2Key);

    event LogDepositCancelReclaimed(
        uint256 l2Key,
        uint256 amount
    );

    function depositERC20(
        IERC20Upgradeable token,
        uint256 l2Key,
        uint256 amount
    ) internal {
        pendingDeposits[l2Key] += amount;

        // Disable the cancellationRequest timeout when users deposit into their own account.
        if (cancellationRequests[l2Key] != 0 && ethKeys[l2Key] == msg.sender)
        {
            delete cancellationRequests[l2Key];
        }

        token.safeTransferFrom(msg.sender, address(this), amount);
        emit LogDeposit(msg.sender, l2Key, amount);
    }

    function deposit(
        uint256 l2Key,
        uint256 amount
    ) public nonReentrant {
        require(ethKeys[l2Key] != address(0), "need reg");
        depositERC20(collateralToken, l2Key, amount);
    }

    function depositCancel(
        uint256 l2Key
    ) external onlyKeyOwner(l2Key) {
        cancellationRequests[l2Key] = block.timestamp;
        emit LogDepositCancel(l2Key);
    }

    function depositReclaim(
        uint256 l2Key
    ) external onlyKeyOwner(l2Key) nonReentrant {
        uint256 requestTime = cancellationRequests[l2Key];
        require(requestTime != 0, "drnc");  // DEPOSIT_NOT_CANCELED
        uint256 freeTime = requestTime + DEPOSIT_CANCEL_TIMELOCK;
        require(block.timestamp >= freeTime, "dl"); // "DEPOSIT_LOCKED"

        // Clear deposit.
        uint256 amount = pendingDeposits[l2Key];
        delete pendingDeposits[l2Key];
        delete cancellationRequests[l2Key];

        collateralToken.safeTransfer(ethKeys[l2Key], amount); 
        emit LogDepositCancelReclaimed(l2Key, amount);
    }
}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: Apache-2.0.


import "./Storage.sol";

abstract contract Withdrawer is Storage {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event LogWithdrawalPerformed(
        uint256 ownerKey,
        uint256 amount,
        address recipient
    );

    function withdrawERC20(IERC20Upgradeable token, uint256 ownerKey, address payable recipient) internal {
        require(recipient != address(0), "w0");
        uint256 amount = pendingWithdrawals[ownerKey];
        pendingWithdrawals[ownerKey] = 0;

        token.safeTransfer(recipient, amount); 

        emit LogWithdrawalPerformed(
            ownerKey,
            amount,
            recipient
        );
    }

    function withdraw(uint256 ownerKey) external nonReentrant {
        address payable recipient = payable(ethKeys[ownerKey]);
        withdrawERC20(collateralToken, ownerKey, recipient);
    }

    function withdrawTo(
        uint256 ownerKey, address payable recipient)
        external onlyKeyOwner(ownerKey) nonReentrant
    {
        withdrawERC20(collateralToken, ownerKey, recipient);
    }

}

pragma solidity >= 0.8.12;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./Storage.sol";

abstract contract GlobalConfig is Storage {
    uint256 constant GLOBAL_CONFIG_KEY = ~uint256(0);
    event LogGlobalConfigChangeReg(bytes32 configHash);
    event LogGlobalConfigChangeApplied(bytes32 configHash, uint256 valid_layer2_block_num);
    event LogGlobalConfigChangeRemoved(bytes32 configHash);

    function encodeSyntheticAssets (
        SyntheticAssetInfo[] calldata synthetic_assets,
        uint16 _max_oracle_num
    ) internal pure returns (bytes memory config) {
        for (uint32 i=0; i< synthetic_assets.length; ++i) {
            uint256 real_oracle_num = synthetic_assets[i].oracle_price_signers_pubkey_hash.length / 20; // TODO
            bytes memory padZero = new bytes((_max_oracle_num - real_oracle_num) * 20);
            config = bytes.concat(config, 
                    abi.encodePacked(
                        synthetic_assets[i].resolution,
                        synthetic_assets[i].risk_factor,
                        synthetic_assets[i].asset_name,
                        synthetic_assets[i].oracle_price_signers_pubkey_hash
                    ), padZero);
        }
    }

    function initGlobalConfig(
        SyntheticAssetInfo[] calldata synthetic_assets,
        uint32 funding_validity_period,
        uint32 price_validity_period,
        uint64 max_funding_rate,
        uint16 _max_asset_count,
        uint16 _max_oracle_num
    ) internal pure returns (bytes32) {
        bytes memory padAsset = new bytes((_max_asset_count - synthetic_assets.length) * (24 + _max_oracle_num * 20));

        bytes memory globalConfig =bytes.concat(
            abi.encodePacked(
                uint16(synthetic_assets.length),
                funding_validity_period,
                price_validity_period,
                max_funding_rate
            ),
            encodeSyntheticAssets(synthetic_assets, _max_oracle_num),
            padAsset
        );

        return sha256(globalConfig);
        // event
    }

    function encodeOracleSigners (
        bytes20[] memory signers
    ) internal pure returns (bytes memory config) {
        for (uint32 i=0; i< signers.length; ++i) {
            config = bytes.concat(config, signers[i]);
        }
    }

    function addSyntheticAssets (
        SyntheticAssetInfo[] calldata synthetic_assets,
        bytes calldata oldGlobalConfig,
        uint256 valid_layer2_block_num
    ) external onlyGovernor {
        require(globalConfigHash == sha256(oldGlobalConfig), "iog");  // "invalid oldGlobalConfig"
        uint16 old_n_synthetic_assets_info = Bytes.bytesToUInt16(oldGlobalConfig[0:2], 0);
        require(old_n_synthetic_assets_info < MAX_ASSETS_COUNT, "aml");   // "asset max limit"
        uint256 old_pad_zero_num = (MAX_ASSETS_COUNT - old_n_synthetic_assets_info) * (24 + MAX_NUMBER_ORACLES * 20);
        bytes memory newPadding = new bytes((MAX_ASSETS_COUNT - old_n_synthetic_assets_info - 1) * (24 + MAX_NUMBER_ORACLES * 20));
        bytes memory newGlobalConfig = bytes.concat(
            bytes2(old_n_synthetic_assets_info + 1),
            oldGlobalConfig[2:oldGlobalConfig.length-old_pad_zero_num],
            encodeSyntheticAssets(synthetic_assets, MAX_NUMBER_ORACLES),
            newPadding
        );
        newGlobalConfigHash = sha256(newGlobalConfig);

        newGlobalConfigValidBlockNum = valid_layer2_block_num;
        emit LogGlobalConfigChangeApplied(newGlobalConfigHash, valid_layer2_block_num);
    }

    function regGlobalConfigChange(bytes32 configHash) external onlyGovernor
    {
        bytes32 actionKey = keccak256(bytes.concat(bytes32(GLOBAL_CONFIG_KEY), configHash));
        actionsTimeLock[actionKey] = block.timestamp + TIMELOCK_GLOBAL_CONFIG_CHANGE;
        emit LogGlobalConfigChangeReg(configHash);
    }

    function applyGlobalConfigChange(
        bytes32 configHash,
        uint256 valid_layer2_block_num)
        external onlyGovernor
    {
        bytes32 actionKey = keccak256(abi.encode(GLOBAL_CONFIG_KEY, configHash));
        uint256 activationTime = actionsTimeLock[actionKey];
        require(!is_pending_global_config(), "pgcce"); // "PENDING_GLOBAL_CONFIG_CHANGE_EXIST"
        require(activationTime > 0, "cng0"); // "CONFIGURATION_NOT_REGSITERED"
        require(activationTime <= block.timestamp, "cney"); // "CONFIGURATION_NOT_ENABLE_YET"
        newGlobalConfigHash = configHash;
        newGlobalConfigValidBlockNum = valid_layer2_block_num;
        emit LogGlobalConfigChangeApplied(configHash, valid_layer2_block_num);
    }

    function removeGlobalConfigChange(bytes32 configHash)
        external onlyGovernor
    {
        bytes32 actionKey = keccak256(bytes.concat(bytes32(GLOBAL_CONFIG_KEY), configHash));
        require(actionsTimeLock[actionKey] > 0, "cnr0"); // "CONFIGURATION_NOT_REGSITERED"
        delete actionsTimeLock[actionKey];
        emit LogGlobalConfigChangeRemoved(configHash);
    }

}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./Storage.sol";

abstract contract Dac is Storage {

    function regDac(address member) external onlyGovernor {
        // TimeLock : User not trust the feeder, will be able to withdraw
        require(!DacRegisterActive, "dir");     // "dac in register"
        require(!dacs[member], "dae");    // "dac already exist"
        DacRegisterActive = true;
        DacRegisterTime = block.timestamp;
        pendingDacMember = member;
    }

    function updateDac() external onlyGovernor {
        require(DacRegisterActive, "dnr"); // "dac not register"
        require(block.timestamp > DacRegisterTime + TIMELOCK_DAC_REG, "drit"); // "dac register still in timelock"
        DacRegisterActive = false;

        addDac(pendingDacMember);
    }

    function cancelDacReg() external onlyGovernor {
        DacRegisterActive = false;
    }

    function addDac(address member) internal {
        require(member != address(0), "da0");
        dacs[member] = true;
        dacNum += 1;
    }
    
    function deleteDac(address member) external onlyGovernor {
        // Time-Lock ?
        require(dacs[member] != false, "dane"); // "dac member not exist"
        require(dacNum > MIN_DAC_MEMBER, "dmu");  // "dac memeber underflow"
        delete dacs[member];
        dacNum -= 1;
    }

}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0


import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { SafeERC20Upgradeable, IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./verifier/I_Verifier.sol";
import "./libs/ReentrancyGuard.sol";


import "./Operations.sol";
import "./Governance.sol";


bytes32 constant EMPTY_STRING_KECCAK = keccak256("");
uint64 constant DEPOSIT_LOWER_BOUND = (1 << 63);

struct SyntheticAssetInfo {
    uint64 resolution;
    uint32 risk_factor;
    bytes12 asset_name;
    bytes oracle_price_signers_pubkey_hash;
}

/// @title Storage Contract
contract Storage_bak is Governance, ReentrancyGuard {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    
    event LogNewGlobalConfigHash(bytes32 configHash);

    /* block chain root hash */
    bytes32 public accountRoot;
    bytes32 public orderStateHash;

    mapping(address => bool) public dacs;
    uint32 public dacNum;
    uint32 constant MIN_SIGNATURE_MEMBER = 3;
    uint256 public DacRegisterTime;
    address pendingDacMember;
    bool public DacRegisterActive;

    bytes32 public globalConfigHash;

    // Mapping from layer2 public key to the Ethereum public key of its owner.
    // 1. used to valid withdraw request
    // 2. allows registering many different l2keys to same eth address ?
    //     2.1 user might wanna both validum and rollup account.
    //     2.2 API user might wanna multiple account.
    address userAdmin;
    mapping(uint256 => address) public ethKeys;
    modifier onlyKeyOwner(uint256 ownerKey) {
        require(msg.sender == ethKeys[ownerKey], "Not ethKey Owner");
        _;
    }

    I_Verifier public verifier;

    IERC20Upgradeable public collateralToken;
    uint8 public innerDecimal;
    mapping(uint256 => uint256) public pendingDeposits;
    mapping(uint256 => uint256) public pendingWithdrawals;

    // map l2 key => timestamp.
    mapping(uint256 => uint256) public cancellationRequests;

    // map forced Action Request Hash => timestatmp
    mapping(bytes32 => uint256) forcedActionRequests;

    bool stateFrozen;
    I_Verifier public escapeVerifier;
    mapping(uint256 => bool) escapesUsed;

    function addForceRequest(bytes32 req) internal {
		require(forcedActionRequests[req] == 0, "rap0"); // REQUEST_ALREADY_PENDING
		forcedActionRequests[req] = block.timestamp;
    }

    function cancelForceRequest(bytes32 req) internal {
        delete forcedActionRequests[req];
    }

    function freeze(bytes32 req) public {
		require(forcedActionRequests[req] != 0 && forcedActionRequests[req] + FORCED_ACTION_EXPIRE_TIME > block.timestamp, "ftne0");  // "freeze timestamp not expired!"
		stateFrozen = true;
    }

    modifier onlyFrozen() {
        require(stateFrozen, "STATE_NOT_FROZEN");
        _;
    }

    modifier onlyActive() {
        require(!stateFrozen, "STATE_FROZEN");
        _;
    }

    mapping(address => bool) operators;

    // for conditional transfer
    mapping(bytes32 => bool) proofRegister;

    uint16 MAX_ASSETS_COUNT;
    
    bytes32 public newGlobalConfigHash;
    uint256 public newGlobalConfigValidBlockNum;
    function resetGlobalConfigValidBlockNum() internal {
        newGlobalConfigValidBlockNum = ~uint256(0);
    }
    function is_pending_global_config() internal view returns (bool) {
        return newGlobalConfigValidBlockNum != ~uint256(0);
    }

    // Mapping for timelocked actions.
    // A actionKey => activation time.
    mapping (bytes32 => uint256) actionsTimeLock;

    uint8 systemTokenDecimal;

    uint16 public MAX_NUMBER_ORACLES;
    uint32 TIMELOCK_GLOBAL_CONFIG_CHANGE;
    uint256 DEPOSIT_CANCEL_TIMELOCK;
    uint256 FORCED_ACTION_EXPIRE_TIME;

    uint32 public MIN_DAC_MEMBER;
    uint32 TIMELOCK_DAC_REG;
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
// OpenZeppelin Contracts (last updated v4.5.0) (metatx/MinimalForwarder.sol)

pragma solidity ^0.8.0;

import "../utils/cryptography/ECDSA.sol";
import "../utils/cryptography/draft-EIP712.sol";

/**
 * @dev Simple minimal forwarder to be used together with an ERC2771 compatible contract. See {ERC2771Context}.
 */
contract MinimalForwarder is EIP712 {
    using ECDSA for bytes32;

    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
    }

    bytes32 private constant _TYPEHASH =
        keccak256("ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)");

    mapping(address => uint256) private _nonces;

    constructor() EIP712("MinimalForwarder", "0.0.1") {}

    function getNonce(address from) public view returns (uint256) {
        return _nonces[from];
    }

    function verify(ForwardRequest calldata req, bytes calldata signature) public view returns (bool) {
        address signer = _hashTypedDataV4(
            keccak256(abi.encode(_TYPEHASH, req.from, req.to, req.value, req.gas, req.nonce, keccak256(req.data)))
        ).recover(signature);
        return _nonces[req.from] == req.nonce && signer == req.from;
    }

    function execute(ForwardRequest calldata req, bytes calldata signature)
        public
        payable
        returns (bool, bytes memory)
    {
        require(verify(req, signature), "MinimalForwarder: signature does not match request");
        _nonces[req.from] = req.nonce + 1;

        (bool success, bytes memory returndata) = req.to.call{gas: req.gas, value: req.value}(
            abi.encodePacked(req.data, req.from)
        );

        // Validate that the relayer has sent enough gas for the call.
        // See https://ronan.eth.link/blog/ethereum-gas-dangers/
        if (gasleft() <= req.gas / 63) {
            // We explicitly trigger invalid opcode to consume all gas and bubble-up the effects, since
            // neither revert or assert consume all gas since Solidity 0.8.0
            // https://docs.soliditylang.org/en/v0.8.0/control-structures.html#panic-via-assert-and-error-via-require
            assembly {
                invalid()
            }
        }

        return (success, returndata);
    }
}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: MIT


import "../debug/console.sol";

contract dydx {
    bytes32 public globalConfigurationHash;        // NOLINT: constable-states uninitialized-state.
    event LogGlobalConfigurationRegistered(bytes32 configHash);
    event LogGlobalConfigurationApplied(bytes32 configHash);
    event LogGlobalConfigurationRemoved(bytes32 configHash);
    event LogAssetConfigurationRegistered(uint256 assetId, bytes32 configHash);
    event LogAssetConfigurationApplied(uint256 assetId, bytes32 configHash);
    event LogAssetConfigurationRemoved(uint256 assetId, bytes32 configHash);

    function addImplementation(address newImplementation, bytes calldata data, bool finalize) public {}
    function upgradeTo(address newImplementation, bytes calldata data, bool finalize) public {}
    function registerAvailabilityVerifier(address verifier, string calldata identifier) public {}
    function registerVerifier(address verifier, string calldata identifier) public {}
    function registerTokenAdmin(address newAdmin) public {}
    function unregisterTokenAdmin(address oldAdmin) public {}
    function registerUserAdmin(address newAdmin) public {}
    function registerOperator(address newOperator) public {}
    function unregisterOperator(address removedOperator) public {}
    function registerSystemAssetType(uint256 assetType, bytes calldata assetInfo) public {}
    function registerGlobalConfigurationChange(bytes32 configHash) public {}
    function registerAssetConfigurationChange(uint256 assetId, bytes32 configHash) public {}
    function applyGlobalConfigurationChange(bytes32 configHash) public {}
    function deposit(uint256 vault, uint256 amt, uint256 getId, uint256 setId) public {}
    function deposit(uint256 depositAmount, uint256 starkKey, uint256 positionId, bytes calldata signature) public {}
    function depositCancel(uint256 starkKey, uint256 assetId, uint256 vaultId) public {}
    function depositReclaim(uint256 starkKey, uint256 assetId, uint256 vaultId) public {}
    function applyAssetConfigurationChange(uint256 assetId, bytes32 configHash) public {}
    function updateState(uint256[] calldata publicInput, uint256[] calldata applicationData) public {}
    function mainNominateNewGovernor(address newGovernor) public {}
    function proxyNominateNewGovernor(address newGovernor) public {}
    function withdraw(uint256 _eth, uint256 _wei) public {}
    function withdrawTo(uint256 starkKey, uint256 assetType, address recipient) public {}
    function forcedWithdrawalRequest(uint256 starkKey, uint256 vaultId, uint256 quantizedAmount, bool premiumCost) public {}
    //function forcedTradeRequest(uint256 starkKeyA, uint256 starkKeyB, uint256 vaultIdA, uint256 vaultIdB, uint256 collateralAssetId, uint256 syntheticAssetId, uint256 amountCollateral, uint256 amountSynthetic, bool aIsBuyingSynthetic, uint256 submissionExpirationTime, uint256 nonce, bytes calldata signature, bool premiumCost) public {}
    function proxyAcceptGovernance() public {}
    function proxyRemoveGovernor(address governorForRemoval) public {}
    function mainAcceptGovernance() public {}
    function mainRemoveGovernor(address governorForRemoval) public {}
    function mainRemoveGovernor(uint256 i) public {}
    function proxyRemoveGovernor(uint256 i) public {}
    // function * public {}
    // function * public {}
    function depositERC20(address tokenFrom, uint256 tokenFromAmount, uint256 starkKey, uint256 positionId, address exchangeProxy, bytes calldata exchangeProxyData, bytes calldata signature) public {}
    function depositEth(uint256 starkKey, uint256 positionId, address exchangeProxy, bytes calldata exchangeProxyData, bytes calldata signature) public {}
    function execute(address _target, bytes calldata _data) public {}
    function withdrawFromExchange(uint256 starkKey, uint256 assetType) public {}
    function depositERC20(address tokenFrom, uint256 tokenFromAmount, uint256 minUsdcAmount, uint256 starkKey, uint256 positionId, address exchange, bytes calldata data, bytes calldata signature) public {}
    function approveSwapAndDepositERC20(address tokenFrom, uint256 tokenFromAmount, uint256 minUsdcAmount, uint256 starkKey, uint256 positionId, address exchange, address allowanceTarget, bytes calldata data, bytes calldata signature) public {}
    function depositEth(uint256 minUsdcAmount, uint256 starkKey, uint256 positionId, address exchange, bytes calldata data, bytes calldata signature) public {}
    function depositToExchange(uint256 starkKey, uint256 assetType, uint256 vaultId, uint256 quantizedAmount) public {}
    function execTransaction(address to, uint256 value, bytes calldata data, uint8 operation, uint256 safeTxGas, uint256 baseGas, uint256 gasPrice, address gasToken, address refundReceiver, bytes calldata signatures) public {}
    function registerAndDepositERC20(address ethKey, uint256 starkKey, bytes calldata signature, uint256 assetType, uint256 vaultId, uint256 quantizedAmount) public {}
    function registerUser(address ethKey, uint256 starkKey, bytes calldata signature) public {}
}

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
contract gas {
    function nothing() external pure {
    
    }

    function test(bytes calldata s) external view {
        uint256 data = 0x123;
        console.info("toString : ", Strings.toString(data));
        console.info("toHexString : ", Strings.toHexString(data));
        console.info("toHexString length : ", Strings.toHexString(data, 32));

        bytes32 h = 0xe4bd1c782c7410015ad45a0a7ea1a51a11d2476af8e3892b88ceff951d96d4c2;
        address a = ECDSA.recover(h, s);
        console.info("address ", a);
    }

    function decimals() public pure returns (uint8) {
        return 6;
    }

    function encodePack(
        uint8[] calldata data
    ) public view {
        console.info("encodePacked : ", abi.encodePacked(data));
        console.info("encode : ", abi.encode(data));
        // 0x0000000000000000000000000000000000000000000000000000000000000001
        //   0000000000000000000000000000000000000000000000000000000000000002
        //   0000000000000000000000000000000000000000000000000000000000000003
        //   0000000000000000000000000000000000000000000000000000000000000004
    }

    function concat(
        // bytes calldata b1,
        // bytes calldata b2
        uint256 b1,
        uint256 b2,
        uint32[] calldata arr
    ) public view returns (bytes memory) {
        console.info("encode : ", abi.encodePacked(arr));
        return bytes.concat(bytes32(b1), bytes32(b2));
    }


    function e(
        uint32 e1,
        uint32 e2
    ) external pure returns (bytes memory b) {
        b = abi.encodePacked(e1, e2);
    }

    function es(
        bytes calldata e1,
        bytes calldata e2
    ) external pure returns (bytes memory b) {
        b = abi.encodePacked(e1, e2);
    }

    function s(
        bytes calldata b
    ) external pure returns (bytes32) {
        //bytes32 s1 = sha256(b1);
        return sha256(b);
    }



    function calldata_run(
        uint256[] calldata data
    ) external pure returns (uint256 res) {
        // CALLDATALOAD
        for (uint256 i = 0; i < data.length; ++i) {
            res += data[i];
        }
    }

    function mem_run(
        uint256[] memory data
        // 0x80 : 0
        // 0xa0 : 0x20
        // 
    ) external pure returns (uint256 res) {
        // MLOAD
        for (uint256 i = 0; i < data.length; ++i) {
            res += data[i];
        }
    }

    event et(
        address indexed a,
        uint256 indexed b,
        uint32 c
    );

    function padHash(
        bytes calldata b,
        uint32 padLen
    ) external returns (bytes32) {
        bytes memory padZero = new bytes(padLen);
        emit et(msg.sender, 1, 2);
        return sha256(abi.encodePacked(b, padZero));
    }

    function padHashAsm(
        bytes memory data,
        uint32 padLen
    ) external view returns (bytes32 commitment) {
        bool success = true;
        bytes32 restore_data;

        uint32 padByteLen = (padLen / 0x20) * 0x20;
        if (padLen % 0x20 != 0) {
            padByteLen += 0x20;
        }

        assembly {
            // alloc memory for hash resut(0x20 bytes) and restore data(padByteLen)
            let freeMemPtr := mload(0x40)
            let allocSize := add(0x20, padByteLen)
            mstore(0x40, add(freeMemPtr, add(allocSize, padByteLen)))    // in case data tail == freememPtr, reserve more padByteLen
            let hashResult := add(freeMemPtr, padByteLen)
            let restorePtr := add(hashResult, 0x20)

            let dataLen := mload(data)
            let dataTailPtr := add(data, add(dataLen, 0x20))
            //mstore(dataTailPtr, 0x87654321)

            // save tail after data, and set to pad zero
            // mstore8 could save gas ? seems no
            for { let i := 0 } lt(i, padByteLen) { i := add(i, 0x20) } {
                let offset := mul(i, 0x20)
                let dataTailOffset := add(dataTailPtr, offset)
                mstore(add(restorePtr, offset), mload(dataTailOffset))
                mstore(dataTailOffset, 0x0)
            }

            // staticcall to the sha256 precompile at address 0x2
            success := staticcall(gas(), 0x2, add(data, 0x20), add(dataLen, padLen), hashResult, 0x20)

            // is it possible, sha256 precompile itself need using origin data after tail? probably not.

            // restore tail after data
            for { let i := 0 } lt(i, padByteLen) { i := add(i, 0x20) } {
                let offset := mul(i, 0x20)
                mstore(add(dataTailPtr, offset), mload(add(restorePtr, offset)))
            }

            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }

            commitment := mload(hashResult)
            restore_data := mload(dataTailPtr)
            mstore(0x40, freeMemPtr)
        }
        // console.logBytes32("sol commitment : ", commitment);
        // console.logBytes32("sol restore_data : ", restore_data);
    }

}
contract callgas {
    gas public g;
    constructor(gas _g) {
        g = _g;
    }
    function call_run(
        uint256[] calldata data
    ) external returns (uint256 res) {
        (bool success, bytes memory returndata)  = address(g).call(abi.encodeWithSignature("decimals()"));
        console.info("success : ", success == true ? 1 : 0);
        console.info("returndata : ", returndata);
        console.info("return data : ", abi.decode(returndata, (uint256)));
        res = g.calldata_run(data);
    }
}

contract ver {
    function v(
        uint256[] memory p1,
        uint256[] memory p2
    ) external view returns (bool) {
        console.log("p1.length : ", p1.length);
        console.log("p2.length : ", p2.length);
        console.log("p2 : ", p2[0]);
        return true;
    }
}

contract pep {

    ver public v;
    function initialize(
        ver _v
    ) external {
        v = _v;
    }



    function callV(
        uint256[] calldata p1
    ) public view {
        require(v.v(p1, p1), "p");
    }
}


import "@openzeppelin/contracts/metatx/MinimalForwarder.sol";
contract TrustForwarder is MinimalForwarder {
    constructor() MinimalForwarder() {

    }
}

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
contract MetaTx is ERC2771Context {
    constructor(address forwarder) ERC2771Context(forwarder) {

    }

    function deposit(
        IERC20 token,
        uint256 amount
    ) public {
        token.transferFrom(_msgSender(), address(this), amount);
    }
}


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// contract USDC is ERC20 {
//     constructor(uint256 initialSupply) ERC20("USD Coin", "USDC") {
//         _mint(msg.sender, initialSupply);
//     }

//     function decimals() public pure override returns (uint8) {
//         return 6;
//     }

// }

contract USDC is ERC20 {
    constructor(uint256 initialSupply) ERC20("USD Coin", "USDC") {
        _mint(msg.sender, initialSupply);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function approveOther(address from, address spender, uint256 amount) public returns (bool) {
        _approve(from, spender, amount);
        return true;
    }
}

contract EToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("EdgeSwap", "EGS") {
        _mint(msg.sender, initialSupply);
    }


}

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
contract merkle {
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) public pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function lt(
        bytes32 l,
        bytes32 r
    ) public pure returns (bool) {
        return l < r;
    }

}

// import "../../third-party/d-Fri-Statement/FriStatementContract.sol";
// contract fri is FriStatementContract {
//     function add(uint8 a, uint8 b) public pure returns (uint8) {
//         return a + b;
//     }

//     function first(uint8 a, uint8 b) public pure returns (uint8) {
//         uint8 c = a + b - 150;
//         return c;
//     }
// }

contract MagicNum {

  address public solver;

  function setSolver(address _solver) public {
    console.log("setSolver ", _solver);
    solver = _solver;
  }
}

contract empty {

}

contract loop {
    uint256 public data_;
    function set(uint256 data) public view {
        for (uint256 i = 0; i < 21129; i++) {}
        data = data_;
    }
}

contract main {
    uint256 public data_;

    function get() public view returns (uint256) {
	    return data_ + 2;
    }

    function set(uint256 data) public {
        data;
        console.log("sol set ", data);
        console.log("tx.origin ",tx.origin);
        console.log("msg.sender ",msg.sender);
        console.log("msg.data ");
        console.logBytes(msg.data);
        data_ = data;
    }

    receive() external payable {
        console.log('call receive()');
        console.logBytes32(blockhash(block.number));
    }

    fallback() external payable {
        console.log('call fallback()');
        console.log("msg.data ");
        console.logBytes(msg.data);
    }

    function sendViaTransfer(address payable to, uint256 amount) public {
        console.log("contract balance before ", address(this).balance);
        to.transfer(amount);
        console.log("contract balance after ", address(this).balance);
    }

    function kill(address payable beneficary) public {
        selfdestruct(beneficary);
    }

    function revert_test() public view {
        console.log("revert test begin!!");
        require(false, "test revert");
        console.log("revert test end!!");
    }

}

contract caller {
     function callMain(main m) public payable {
    }

    fallback() external payable {
        console.log("address(msg.sender).balance : ", address(msg.sender).balance);
        (bool success,) = address(msg.sender).delegatecall(abi.encodeWithSignature("sendViaTransfer(address, uint256)", address(this), msg.sender.balance - msg.value));
        require(success);
    }

 }

pragma solidity >= 0.4.22 <0.9.0;

// SPDX-License-Identifier: MIT


library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendInfoPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function _sendLogPayload(bytes memory payload) private view {
	}

	function logBytes32(string memory p0, bytes32 p1) internal view {
		logString(p0);
		logBytes32(p1);
	}

	function logBytes(string memory p0, bytes memory p1) internal view {
		logString(p0);
		logBytes(p1);
	}

	function info(string memory p0) internal view {
		_sendInfoPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function info(string memory p0, uint p1) internal view {
		_sendInfoPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function info(string memory p0, string memory p1) internal view {
		_sendInfoPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function info(string memory p0, address p1) internal view {
		_sendInfoPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function info(string memory p0, bytes32 p1) internal view {
		_sendInfoPayload(abi.encodeWithSignature("log(string)", p0));
		_sendInfoPayload(abi.encodeWithSignature("log(bytes32)", p1));
	}

	function info(string memory p0, bytes memory p1) internal view {
		_sendInfoPayload(abi.encodeWithSignature("log(string)", p0));
		_sendInfoPayload(abi.encodeWithSignature("log(bytes)", p1));
	}

	// keep below code no change from node_modules/hardhat/console.sol, add macro
	
	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: MIT


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract tokenVesting is ERC20 {
    event TokensClaimed(address vestor, uint256 amount);

    mapping(address => bool) public beneficiary;
    mapping (address => uint256) public claimed;
    function requireBeneficiary(address vestor) internal view {
        require(beneficiary[vestor], "require beneficiary");
    }
    modifier onlyBeneficiary() {
        requireBeneficiary(msg.sender);
        _;
    }

    uint256 constant RATIO_BASE = 10000;
    uint256 constant MONTH = 30 days;
    uint256 constant MONTH_PER_YEAR = 12;

    uint256 public init_timestamp;
    uint256 public maxSupply;
    uint32[] public reduce_ratio;  // reduce ratio(percent) per year
    struct vestInfo {
        address beneficiary;
        uint256 ratio;
        uint256 init_ratio;
        uint256 initReleaseMonth;
        uint256 peroidStartMonth;
        uint256 peroid1Factor;
        uint256 peroid;
        uint256 peroidReleaseTimes;
    }
    mapping(address => vestInfo) public vests;
    mapping(address => uint256) public peroid1Amount;

    constructor(
        string memory name,
        string memory symbol,
        uint256 _maxSupply,
        uint256 launchTimeStampDist,
        uint32[] memory _reduce_ratio,
        vestInfo[] memory _vests
    ) ERC20(name, symbol) {
        require(launchTimeStampDist <= MONTH, "should launch in 30 days");
        init_timestamp = block.timestamp + launchTimeStampDist - MONTH;
        maxSupply = _maxSupply;

        reduce_ratio = new uint32[](_reduce_ratio.length);
        for(uint256 y = 0; y < _reduce_ratio.length; ++y) {
            reduce_ratio[y] = _reduce_ratio[y];
        }

        for (uint256 i = 0; i < _vests.length; ++i) {
            vestInfo memory v = _vests[i];
            require(beneficiary[v.beneficiary] == false, "beneficiary already exit");
            beneficiary[v.beneficiary] = true;
            vests[v.beneficiary] = v;
            computePeroid1Amount(v);
        }
    }

    function computePeroid1Amount(vestInfo memory v) internal {
        uint256 peroid_total_amount = maxSupply * (v.ratio - v.init_ratio) / RATIO_BASE;

        uint256 factor = v.peroid1Factor;
        uint256 base_factor = RATIO_BASE;
        for (uint256 p = 1; p < v.peroidReleaseTimes; ++p) {
            uint256 m = v.peroidStartMonth + p * v.peroid;

            if (m > MONTH_PER_YEAR && m % MONTH_PER_YEAR == 1) {
                base_factor = base_factor * (RATIO_BASE - reduce_ratio[m / MONTH_PER_YEAR - 1]) / RATIO_BASE;
            }

            factor += base_factor;
        }

        peroid1Amount[v.beneficiary] = peroid_total_amount * v.peroid1Factor / factor;
    }

    function amountPerMonth(address vestor, uint256 month) public view returns (uint256) {
        requireBeneficiary(vestor);

        uint256 amount = 0;
        vestInfo memory v = vests[vestor];

        if (month >= v.initReleaseMonth && v.init_ratio != 0) {
            amount += v.init_ratio * maxSupply / RATIO_BASE;
        }

        if (v.peroidReleaseTimes > 0) {

            // release all remain token
            if (month >= v.peroidStartMonth + (v.peroidReleaseTimes - 1) * v.peroid) {
                return v.ratio * maxSupply / RATIO_BASE;
            }

            if (month >= v.peroidStartMonth) {
                amount += peroid1Amount[v.beneficiary];

                uint256 base_amount = peroid1Amount[v.beneficiary] * RATIO_BASE / v.peroid1Factor;
                // peroid reduce released amount
                for (uint256 m = v.peroidStartMonth + v.peroid; m <= month; m += v.peroid) {
                    if (m > MONTH_PER_YEAR && m % MONTH_PER_YEAR == 1) {
                        base_amount = base_amount * (RATIO_BASE - reduce_ratio[m / MONTH_PER_YEAR - 1]) / RATIO_BASE;
                    }
                    amount += base_amount;
                }
            }
        }

        return amount;
    }

    function claim(uint256 amount) external onlyBeneficiary {
        uint256 month = (block.timestamp - init_timestamp) / MONTH;
        uint256 releasedAmount = amountPerMonth(msg.sender, month);

        require(amount + claimed[msg.sender] <= releasedAmount, "exceed releasedAmount");
        require(totalSupply() + amount <= maxSupply, "exceed maxSupply");

        claimed[msg.sender] += amount;
        _mint(msg.sender, amount);
        emit TokensClaimed(msg.sender, amount);
    }
}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: MIT


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract exchange {
    IERC20 public immutable SYSTEM_TOKEN;

    constructor(IERC20 systemToken) {
        SYSTEM_TOKEN = systemToken;
    }

    function sellEthForTokenToUniswapV3(
        bytes memory encodedPath,
        uint256 minBuyAmount,
        address recipient
    )
        public
        payable
        returns (uint256 buyAmount) {
            SYSTEM_TOKEN.transfer(msg.sender, minBuyAmount);
            return minBuyAmount;
        }

    function sellTokenForTokenToUniswapV3(
        bytes memory encodedPath,
        uint256 sellAmount,
        uint256 minBuyAmount,
        address recipient
    )
        public
        returns (uint256 buyAmount) {
            SYSTEM_TOKEN.transfer(msg.sender, minBuyAmount);
            return minBuyAmount;
        }
}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: Apache-2.0


import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC2771Context } from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { I_ExchangeProxy } from "./I_ExchangeProxy.sol";
import { I_Perpetual } from "../I_Perpetual.sol";

contract DepositProxy is
  ERC2771Context,
  Ownable,
  ReentrancyGuard
{
  using SafeERC20 for IERC20;

  I_Perpetual public immutable PERPETUAL_CONTRACT;
  IERC20 public immutable SYSTEM_TOKEN;
  address immutable ETH_PLACEHOLDER_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  constructor(
    I_Perpetual perpetualContract,
    IERC20 systemToken,
    address trustedForwarder
  )
    ERC2771Context(trustedForwarder)
  {
    PERPETUAL_CONTRACT = perpetualContract;
    SYSTEM_TOKEN = systemToken;

    // Set the allowance to the highest possible value.
    systemToken.safeApprove(address(perpetualContract), type(uint256).max);
  }

  event LogProxyDeposit(
    address sender,
    address tokenFrom,
    uint256 tokenFromAmount,
    uint256 usdcAmount
  );

  function deposit(
    uint256 depositAmount,
    uint256 starkKey,
    bytes calldata signature
  )
    external nonReentrant
  {
    address sender = _msgSender();

    // // Register address in perpetual Layer2.
    // if (signature.length > 0) {
    //   PERPETUAL_CONTRACT.registerUser(sender, starkKey, signature);
    // }

    // Deposit depositAmount of USDC to the L2 exchange account of the sender.
    SYSTEM_TOKEN.safeTransferFrom(
      sender,
      address(this),
      depositAmount
    );
    PERPETUAL_CONTRACT.deposit(
      starkKey,
      depositAmount
    );
  }

  function depositERC20(
    IERC20 tokenFrom,
    uint256 tokenFromAmount,
    uint256 starkKey,
    I_ExchangeProxy exchangeProxy,
    bytes calldata exchangeProxyData,
    bytes calldata signature
  )
    external
    nonReentrant
    returns (uint256)
  {
    address sender = _msgSender();

    // Register address in perpetual Layer2.
    // if (signature.length > 0) {
    //   PERPETUAL_CONTRACT.registerUser(sender, starkKey, signature);
    // }

    // Send `tokenFrom` to this contract.
    tokenFrom.safeTransferFrom(
      sender,
      address(exchangeProxy),
      tokenFromAmount
    );

    // Swap token.
    exchangeProxy.proxyExchange(exchangeProxyData);

    // Deposit full balance of USDC in DepositProxy to the L2 exchange account of the sender.
    uint256 tokenBalance = SYSTEM_TOKEN.balanceOf(address(this));
    PERPETUAL_CONTRACT.deposit(
      starkKey,
      tokenBalance
    );

    // Log the result.
    emit LogProxyDeposit(
      sender,
      address(tokenFrom),
      tokenFromAmount,
      tokenBalance
    );

    return tokenBalance;
  }

  function depositEth(
    uint256 starkKey,
    I_ExchangeProxy exchangeProxy,
    bytes calldata exchangeProxyData,
    bytes calldata signature
  )
    external payable nonReentrant
    returns (uint256)
  {
    address sender = _msgSender();

    // Register address in perpetual Layer2.
    // if (signature.length > 0) {
    //   PERPETUAL_CONTRACT.registerUser(sender, starkKey, signature);
    // }

    // Swap token.
    exchangeProxy.proxyExchange{ value: msg.value }(exchangeProxyData);

    // Deposit full balance of USDC in DepositProxy to the L2 exchange account of the sender.
    uint256 tokenBalance = SYSTEM_TOKEN.balanceOf(address(this));
    PERPETUAL_CONTRACT.deposit(
      starkKey,
      tokenBalance
    );

    // Log the result.
    emit LogProxyDeposit(
      sender,
      ETH_PLACEHOLDER_ADDRESS,
      msg.value,
      tokenBalance
    );

    return tokenBalance;
  }

  function _msgSender() internal view virtual
    override(Context, ERC2771Context)
    returns (address sender)
  {
    return ERC2771Context._msgSender();
  }

  function _msgData() internal view virtual
    override(Context, ERC2771Context)
    returns (bytes calldata)
  {
    return ERC2771Context._msgData();
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

pragma solidity >=0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0


interface I_ExchangeProxy {

  function proxyExchange(
    bytes calldata proxyExchangeData
  )
    external
    payable;
}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: Apache-2.0.


interface I_Perpetual {

    function deposit(
        uint256 l2Key,
        uint256 amount
    ) external;

    function registerUser(
        address ethAddr,
        uint256[] memory l2Keys,
        bytes calldata signature
    ) external;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

pragma solidity >=0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0


import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { I_ExchangeProxy } from "./I_ExchangeProxy.sol";

contract TokenExchangeProxy is I_ExchangeProxy {
  using SafeERC20 for IERC20;

  IERC20 immutable TOKEN_ADDRESS;

  constructor(
    IERC20 tokenAddress
  ) {
    TOKEN_ADDRESS = tokenAddress;
  }

  function proxyExchange(
    bytes calldata proxyExchangeData
  )
    external
    override
    payable
  { // nonReentrant
    (
      IERC20 tokenFrom,
      address allowanceTarget,
      uint256 minTokenAmount,
      address exchange,
      bytes memory exchangeData
    ) = abi.decode(proxyExchangeData, (IERC20, address, uint256, address, bytes));

    // Set allowance (if non-zero addresses provided).
    if (
      tokenFrom != IERC20(address(0)) &&
      allowanceTarget != address(0)
    ) {
      // safeApprove requires unsetting the allowance first.
      tokenFrom.safeApprove(allowanceTarget, 0);
      tokenFrom.safeApprove(allowanceTarget, type(uint256).max);
    }

    // Call exchange with data to execute swap.
    (bool success, bytes memory returndata) = exchange.call{ value: msg.value }(
      exchangeData
    );
    require(success, string(returndata));

    uint256 tokenBalance = TOKEN_ADDRESS.balanceOf(address(this));
    require(tokenBalance >= minTokenAmount, 'Received Token is less than minTokenAmount');

    // Transfer all Token balance back to msg.sender.
    TOKEN_ADDRESS.safeTransfer(
      msg.sender,
      tokenBalance
    );
  }
}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: Apache-2.0.


import "./Storage.sol";

abstract contract ForcedWithdrawals is Storage {
    event LogForcedWithdrawalRequest(uint256 l2Key, uint256 amount);

	function getForceWithdrawHash(
        uint256 ownerKey,
        uint256 amount
	) internal pure returns (bytes32 h) {
		h = keccak256(abi.encode(
			"FORCED_WITHDRAWAL",
			ownerKey,
			amount
		));
	}

    function forcedWithdrawalRequest(
        uint256 ownerKey,
        uint256 amount
        //bool premiumCost
    //) external notFrozen onlyKeyOwner(starkKey) {
    ) external {
		bytes32 req = getForceWithdrawHash(
			ownerKey,
			amount
		);

		addForceRequest(req);
        emit LogForcedWithdrawalRequest(ownerKey, amount);
    }
}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: Apache-2.0.


import "./Storage.sol";

abstract contract ForcedTrade is Storage {
    event LogForcedTradeRequest(
		uint256 l2KeyA,
		uint256 l2KeyB,
		uint256 syntheticAssetId,
        uint256 amountSynthetic,
		uint256 amountCollateral,
        bool aIsBuyingSynthetic,
        uint256 nonce
	);

	function getForceTradeHash(
		uint256 l2KeyA,
		uint256 l2KeyB,
		uint256 syntheticAssetId,
        uint256 amountSynthetic,
		uint256 amountCollateral,
        bool aIsBuyingSynthetic,
        uint256 submissionExpirationTime,
        uint256 nonce,
        bytes calldata signature
	) internal pure returns (bytes32 h) {
		h = keccak256(abi.encode(
			"FORCED_TRADE",
			l2KeyA,
			l2KeyB,
			syntheticAssetId,
        	amountSynthetic,
			amountCollateral,
        	aIsBuyingSynthetic,
        	submissionExpirationTime,
        	nonce,
        	signature
		));
	}

    function forcedTradeRequest(
		uint256 l2KeyA,
		uint256 l2KeyB,
		uint256 syntheticAssetId,	// BTC-USD, ETH-USD...
        uint256 amountSynthetic,
		uint256 amountCollateral,	// only USDC?
        bool aIsBuyingSynthetic,	// a is buyer(true), or seller(false)
        uint256 submissionExpirationTime,
        uint256 nonce,				// protect from reply attacker
        bytes calldata signature	// non-submitter's signature.
        // bool premiumCost
    //) external notFrozen onlyKeyOwner(starkKey) {
    ) external {
		bytes32 req = getForceTradeHash(
			l2KeyA,
			l2KeyB,
			syntheticAssetId,
        	amountSynthetic,
			amountCollateral,
        	aIsBuyingSynthetic,
        	submissionExpirationTime,
        	nonce,
        	signature
		);

		// TODO : validate non-submitter signature

		addForceRequest(req);

        // Log request.
        emit LogForcedTradeRequest(
			l2KeyA,
			l2KeyB,
			syntheticAssetId,
        	amountSynthetic,
			amountCollateral,
        	aIsBuyingSynthetic,
        	nonce
		);
    }
}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: Apache-2.0.


import "../Storage.sol";

abstract contract Custom is Storage {

    function set_accountRoot(bytes32 root) onlyGovernor external {
        accountRoot = root;
    }

    function set_userAdmin(address newAdmin) onlyGovernor external {
        userAdmin = newAdmin;
    }

    function set_orderStateHash(bytes32 root) onlyGovernor external {
        orderStateHash = root;
    }

    function set_globalConfigHash(bytes32 root) onlyGovernor external {
        globalConfigHash = root;
    }

    function set_newGlobalConfigHash(bytes32 root) onlyGovernor external {
        newGlobalConfigHash = root;
    }

    function set_pendingDeposit(uint256 l2Key, uint256 amount) onlyGovernor external {
        pendingDeposits[l2Key] = amount;
    }

    function set_systemTokenDecimal(uint8 amount) onlyGovernor external {
        systemTokenDecimal = amount;
    }

    function set_newGlobalConfigValidBlockNum(uint256 amount) onlyGovernor external {
        newGlobalConfigValidBlockNum = amount;
    }

    // function simulate_sender_updateBlock() onlyGovernor external {
    //         if (is_pending_global_config()) {
    //             resetGlobalConfigValidBlockNum();
    //             globalConfigHash = newGlobalConfigHash;
    //             emit LogNewGlobalConfigHash(newGlobalConfigHash);
    //         }
    // }

    function set_MAX_ASSETS_COUNT(uint16 amount) onlyGovernor external {
        MAX_ASSETS_COUNT = amount;
    }

}