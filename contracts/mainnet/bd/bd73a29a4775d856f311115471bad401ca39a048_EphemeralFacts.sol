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

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "./interfaces/IRelicReceiver.sol";
import "./interfaces/IReliquary.sol";
import "./interfaces/IProver.sol";
import "./interfaces/IBatchProver.sol";
import "./interfaces/IEphemeralFacts.sol";
import "./lib/Callbacks.sol";

/**
 * @title EphemeralFacts
 * @author Theori, Inc.
 * @notice EphemeralFacts provides delivery of ephemeral facts: facts which are
 *         passed directly to external receivers, rather than stored in the
 *         Reliquary. It also allows placing bounties on specific fact proof
 *         requests, which can be used to build a fact proving relay system.
 *         Batch provers are supported, enabling an efficient request + relay
 *         system using proof aggregation.
 */
contract EphemeralFacts is IEphemeralFacts {
    IReliquary immutable reliquary;

    /// @dev track the bounty associated with each fact request
    mapping(bytes32 => uint256) bounties;

    constructor(IReliquary _reliquary) {
        reliquary = _reliquary;
    }

    /**
     * @dev computes the unique requestId for this fact request, used to track bounties
     * @param account the account associated with the fact
     * @param sig the fact signature
     * @param context context about the fact receiver callback
     */
    function requestId(
        address account,
        FactSignature sig,
        ReceiverContext memory context
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(account, sig, context));
    }

    /**
     * @notice delivers the fact to the receiver, claiming any pending bounty on the request
     * @param context the contract to receive the fact
     * @param fact the fact information
     */
    function deliverFact(ReceiverContext calldata context, Fact memory fact) internal {
        bytes32 rid = requestId(fact.account, fact.sig, context);
        uint256 bounty = bounties[rid];
        require(
            context.initiator == msg.sender || bounty > 0,
            "cannot specify an initiator which didn't request the fact"
        );
        if (bounty > 0) {
            delete bounties[rid];
            emit BountyPaid(bounty, rid, msg.sender);
            payable(msg.sender).transfer(bounty);
        }
        bytes memory data = abi.encodeWithSelector(
            IRelicReceiver.receiveFact.selector,
            context.initiator,
            fact,
            context.extra
        );
        (bool success, bytes memory result) = Callbacks.callWithExactGas(
            context.gasLimit,
            address(context.receiver),
            data
        );
        if (success) {
            emit ReceiveSuccess(context.receiver, rid);
        } else if (context.requireSuccess) {
            Callbacks.revertWithData(result);
        } else {
            emit ReceiveFailure(context.receiver, rid);
        }
    }

    /**
     * @notice proves a fact ephemerally and provides it to the receiver
     * @param context the ReceiverContext for delivering the fact
     * @param prover the prover module to use, must implement IProver
     * @param proof the proof to pass to the prover
     */
    function proveEphemeral(
        ReceiverContext calldata context,
        address prover,
        bytes calldata proof
    ) external payable {
        // reverts if the prover doesn't exist or is revoked
        reliquary.checkProver(reliquary.provers(prover));

        // reverts if the prover doesn't support standard interface
        require(
            IERC165(prover).supportsInterface(type(IProver).interfaceId),
            "Prover doesn't implement IProver"
        );

        Fact memory fact = IProver(prover).prove{value: msg.value}(proof, false);
        deliverFact(context, fact);
    }

    /**
     * @notice proves a batch of facts ephemerally and provides them to the receivers
     * @param contexts the ReceiverContexts for delivering the facts
     * @param prover the prover module to use, must implement IBatchProver
     * @param proof the proof to pass to the prover
     */
    function batchProveEphemeral(
        ReceiverContext[] calldata contexts,
        address prover,
        bytes calldata proof
    ) external payable {
        // reverts if the prover doesn't exist or is revoked
        reliquary.checkProver(reliquary.provers(prover));

        // reverts if the prover doesn't support standard interface
        require(
            IERC165(prover).supportsInterface(type(IBatchProver).interfaceId),
            "Prover doesn't implement IBatchProver"
        );

        Fact[] memory facts = IBatchProver(prover).proveBatch{value: msg.value}(proof, false);
        require(facts.length == contexts.length);

        for (uint256 i = 0; i < facts.length; i++) {
            deliverFact(contexts[i], facts[i]);
        }
    }

    /**
     * @notice requests a fact to be proven asynchronously and passed to the receiver,
     * @param account the account associated with the fact
     * @param sigData the fact data which determines the fact signature (class is assumed to be NO_FEE)
     * @param receiver the contract to receive the fact
     * @param data the extra data to pass to the receiver
     * @param gasLimit the maxmium gas used by the receiver
     * @dev msg.value is added to the bounty for this fact request,
     *      incentivizing somebody to prove it
     */
    function requestFact(
        address account,
        bytes calldata sigData,
        IRelicReceiver receiver,
        bytes calldata data,
        uint256 gasLimit
    ) external payable {
        FactSignature sig = Facts.toFactSignature(Facts.NO_FEE, sigData);

        // create the receiver context for the fact proof request
        // note that initiator and requireSuccess are hardcoded
        ReceiverContext memory context = ReceiverContext(
            msg.sender,
            receiver,
            data,
            gasLimit,
            false
        );

        uint256 bounty = bounties[requestId(account, sig, context)] += msg.value;
        emit FactRequested(FactDescription(account, sigData), context, bounty);
    }
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

import "../lib/Facts.sol";

pragma solidity >=0.8.12;

/**
 * @title IBatchProver
 * @author Theori, Inc.
 * @notice IBatchProver is a standard interface implemented by some Relic provers.
 *         Supports proving multiple facts ephemerally or proving and storing
 *         them in the Reliquary.
 */
interface IBatchProver {
    /**
     * @notice prove multiple facts ephemerally
     * @param proof the encoded proof, depends on the prover implementation
     * @param store whether to store the facts in the reliquary
     * @return facts the proven facts' information
     */
    function proveBatch(bytes calldata proof, bool store)
        external
        payable
        returns (Fact[] memory facts);
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

import "./IRelicReceiver.sol";

interface IEphemeralFacts {
    struct ReceiverContext {
        address initiator;
        IRelicReceiver receiver;
        bytes extra;
        uint256 gasLimit;
        bool requireSuccess;
    }

    struct FactDescription {
        address account;
        bytes sigData;
    }

    event FactRequested(FactDescription desc, ReceiverContext context, uint256 bounty);

    event ReceiveSuccess(IRelicReceiver receiver, bytes32 requestId);

    event ReceiveFailure(IRelicReceiver receiver, bytes32 requestId);

    event BountyPaid(uint256 bounty, bytes32 requestId, address relayer);

    /**
     * @notice proves a fact ephemerally and provides it to the receiver
     * @param context the ReceiverContext for delivering the fact
     * @param prover the prover module to use, must implement IProver
     * @param proof the proof to pass to the prover
     */
    function proveEphemeral(
        ReceiverContext calldata context,
        address prover,
        bytes calldata proof
    ) external payable;

    /**
     * @notice proves a batch of facts ephemerally and provides them to the receivers
     * @param contexts the ReceiverContexts for delivering the facts
     * @param prover the prover module to use, must implement IBatchProver
     * @param proof the proof to pass to the prover
     */
    function batchProveEphemeral(
        ReceiverContext[] calldata contexts,
        address prover,
        bytes calldata proof
    ) external payable;

    /**
     * @notice requests a fact to be proven asynchronously and passed to the receiver,
     * @param account the account associated with the fact
     * @param sigData the fact data which determines the fact signature (class is assumed to be NO_FEE)
     * @param receiver the contract to receive the fact
     * @param data the extra data to pass to the receiver
     * @param gasLimit the maxmium gas used by the receiver
     * @dev msg.value is added to the bounty for this fact request,
     *      incentivizing somebody to prove it
     */
    function requestFact(
        address account,
        bytes calldata sigData,
        IRelicReceiver receiver,
        bytes calldata data,
        uint256 gasLimit
    ) external payable;
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

import "../lib/Facts.sol";

pragma solidity >=0.8.12;

/**
 * @title IProver
 * @author Theori, Inc.
 * @notice IProver is a standard interface implemented by some Relic provers.
 *         Supports proving a fact ephemerally or proving and storing it in the
 *         Reliquary.
 */
interface IProver {
    /**
     * @notice prove a fact ephemerally
     * @param proof the encoded proof, depends on the prover implementation
     * @param store whether to store the facts in the reliquary
     * @return fact the proven fact information
     */
    function prove(bytes calldata proof, bool store) external payable returns (Fact memory fact);
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

import "../lib/Facts.sol";

/**
 * @title IRelicReceiver
 * @author Theori, Inc.
 * @notice IRelicReceiver has callbacks to receives ephemeral facts from Relic
 */
interface IRelicReceiver {
    /**
     * @notice receives an ephemeral fact from Relic
     * @param initiator the account which initiated the fact proving
     * @param fact the proven fact information
     * @param data extra data passed from the initiator - this data may come
     *        from untrusted parties and thus should be validated
     */
    function receiveFact(
        address initiator,
        Fact calldata fact,
        bytes calldata data
    ) external;
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "../lib/Facts.sol";

interface IReliquary {
    event NewProver(address prover, uint64 version);
    event PendingProverAdded(address prover, uint64 version, uint64 timestamp);
    event ProverRevoked(address prover, uint64 version);
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    struct ProverInfo {
        uint64 version;
        FeeInfo feeInfo;
        bool revoked;
    }

    enum FeeFlags {
        FeeNone,
        FeeNative,
        FeeCredits,
        FeeExternalDelegate,
        FeeExternalToken
    }

    struct FeeInfo {
        uint8 flags;
        uint16 feeCredits;
        // feeWei = feeWeiMantissa * pow(10, feeWeiExponent)
        uint8 feeWeiMantissa;
        uint8 feeWeiExponent;
        uint32 feeExternalId;
    }

    function ADD_PROVER_ROLE() external view returns (bytes32);

    function CREDITS_ROLE() external view returns (bytes32);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function DELAY() external view returns (uint64);

    function GOVERNANCE_ROLE() external view returns (bytes32);

    function SUBSCRIPTION_ROLE() external view returns (bytes32);

    function activateProver(address prover) external;

    function addCredits(address user, uint192 amount) external;

    function addProver(address prover, uint64 version) external;

    function addSubscriber(address user, uint64 ts) external;

    function assertValidBlockHash(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external payable;

    function assertValidBlockHashFromProver(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external view;

    function checkProveFactFee(address sender) external payable;

    function checkProver(ProverInfo memory prover) external pure;

    function credits(address user) external view returns (uint192);

    function debugValidBlockHash(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external view returns (bool);

    function debugVerifyFact(address account, FactSignature factSig)
        external
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        );

    function factFees(uint8)
        external
        view
        returns (
            uint8 flags,
            uint16 feeCredits,
            uint8 feeWeiMantissa,
            uint8 feeWeiExponent,
            uint32 feeExternalId
        );

    function feeAccounts(address)
        external
        view
        returns (uint64 subscriberUntilTime, uint192 credits);

    function feeExternals(uint256) external view returns (address);

    function getFact(address account, FactSignature factSig)
        external
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        );

    function getProveFactNativeFee(address prover) external view returns (uint256);

    function getProveFactTokenFee(address prover) external view returns (uint256);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function getVerifyFactNativeFee(FactSignature factSig) external view returns (uint256);

    function getVerifyFactTokenFee(FactSignature factSig) external view returns (uint256);

    function grantRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account) external view returns (bool);

    function initialized() external view returns (bool);

    function isSubscriber(address user) external view returns (bool);

    function pendingProvers(address) external view returns (uint64 timestamp, uint64 version);

    function provers(address) external view returns (ProverInfo memory);

    function removeCredits(address user, uint192 amount) external;

    function removeSubscriber(address user) external;

    function renounceRole(bytes32 role, address account) external;

    function resetFact(address account, FactSignature factSig) external;

    function revokeProver(address prover) external;

    function revokeRole(bytes32 role, address account) external;

    function setCredits(address user, uint192 amount) external;

    function setFact(
        address account,
        FactSignature factSig,
        bytes memory data
    ) external;

    function setFactFee(
        uint8 cls,
        FeeInfo memory feeInfo,
        address feeExternal
    ) external;

    function setInitialized() external;

    function setProverFee(
        address prover,
        FeeInfo memory feeInfo,
        address feeExternal
    ) external;

    function setValidBlockFee(FeeInfo memory feeInfo, address feeExternal) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function validBlockHash(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external payable returns (bool);

    function validBlockHashFromProver(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external view returns (bool);

    function verifyBlockFeeInfo()
        external
        view
        returns (
            uint8 flags,
            uint16 feeCredits,
            uint8 feeWeiMantissa,
            uint8 feeWeiExponent,
            uint32 feeExternalId
        );

    function verifyFact(address account, FactSignature factSig)
        external
        payable
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        );

    function verifyFactNoFee(address account, FactSignature factSig)
        external
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        );

    function verifyFactVersion(address account, FactSignature factSig)
        external
        payable
        returns (bool exists, uint64 version);

    function verifyFactVersionNoFee(address account, FactSignature factSig)
        external
        view
        returns (bool exists, uint64 version);

    function versions(uint64) external view returns (address);

    function withdrawFees(address token, address dest) external;
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

/**
 * @notice Helper for providing fair gas limits in callbacks, adapted from Chainlink
 */
library Callbacks {
    // 5k is plenty for an EXTCODESIZE call (2600) + warm CALL (100)
    // and some arithmetic operations.
    uint256 private constant GAS_FOR_CALL_EXACT_CHECK = 5_000;

    /**
     * @notice calls target address with exactly gasAmount gas and data as calldata
     *         or reverts if at least gasAmount gas is not available.
     * @param gasAmount the exact amount of gas to call with
     * @param target the address to call
     * @param data the calldata to pass
     * @return success whether the call succeeded
     */
    function callWithExactGas(
        uint256 gasAmount,
        address target,
        bytes memory data
    ) internal returns (bool success, bytes memory result) {
        // solhint-disable-next-line no-inline-assembly
        uint256 returnsize;
        assembly {
            function notEnoughGas() {
                // revert Error("not enough gas for call")
                mstore(0x00, hex"08c379a000000000000000000000000000000000000000000000000000000000")
                mstore(0x20, hex"0000002000000000000000000000000000000000000000000000000000000000")
                mstore(0x40, hex"0000001b6e6f7420656e6f7567682067617320666f722063616c6c0000000000")
                revert(0, 0x60)
            }
            function notContract() {
                // revert Error("call target not contract")
                mstore(0x00, hex"08c379a000000000000000000000000000000000000000000000000000000000")
                mstore(0x20, hex"0000002000000000000000000000000000000000000000000000000000000000")
                mstore(0x40, hex"0000001a63616c6c20746172676574206e6f74206120636f6e74726163740000")
                revert(0, 0x60)
            }
            let g := gas()
            // Compute g -= GAS_FOR_CALL_EXACT_CHECK and check for underflow
            // The gas actually passed to the callee is min(gasAmount, 63//64*gas available).
            // We want to ensure that we revert if gasAmount >  63//64*gas available
            // as we do not want to provide them with less, however that check itself costs
            // gas.  GAS_FOR_CALL_EXACT_CHECK ensures we have at least enough gas to be able
            // to revert if gasAmount >  63//64*gas available.
            if lt(g, GAS_FOR_CALL_EXACT_CHECK) {
                notEnoughGas()
            }
            g := sub(g, GAS_FOR_CALL_EXACT_CHECK)
            // if g - g//64 <= gasAmount, revert
            // (we subtract g//64 because of EIP-150)
            if iszero(gt(sub(g, div(g, 64)), gasAmount)) {
                notEnoughGas()
            }
            // solidity calls check that a contract actually exists at the destination, so we do the same
            if iszero(extcodesize(target)) {
                notContract()
            }
            // call and return whether we succeeded. ignore return data
            // call(gas,addr,value,argsOffset,argsLength,retOffset,retLength)
            success := call(gasAmount, target, 0, add(data, 0x20), mload(data), 0, 0)
            returnsize := returndatasize()
        }
        // copy the return data
        result = new bytes(returnsize);
        assembly {
            returndatacopy(add(result, 0x20), 0, returnsize)
        }
    }

    /**
     * @notice reverts the current call with the provided raw data
     * @param data the revert data to return
     */
    function revertWithData(bytes memory data) internal pure {
        assembly {
            revert(add(data, 0x20), mload(data))
        }
    }
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

type FactSignature is bytes32;

struct Fact {
    address account;
    FactSignature sig;
    bytes data;
}

library Facts {
    uint8 internal constant NO_FEE = 0;

    function toFactSignature(uint8 cls, bytes memory data) internal pure returns (FactSignature) {
        return FactSignature.wrap(bytes32((uint256(keccak256(data)) << 8) | cls));
    }

    function toFactClass(FactSignature factSig) internal pure returns (uint8) {
        return uint8(uint256(FactSignature.unwrap(factSig)));
    }
}