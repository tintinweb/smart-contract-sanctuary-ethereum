//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./TypesAndDecoders.sol";

abstract contract CaveatEnforcer {
    function enforceCaveat(
        bytes calldata terms,
        Transaction calldata tx,
        bytes32 delegationHash
    ) public virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// import "hardhat/console.sol";
import {EIP712DOMAIN_TYPEHASH} from "./TypesAndDecoders.sol";
import {Delegation, Invocation, Invocations, SignedInvocation, SignedDelegation} from "./CaveatEnforcer.sol";
import {DelegatableCore} from "./DelegatableCore.sol";
import {IDelegatable} from "./interfaces/IDelegatable.sol";

abstract contract Delegatable is IDelegatable, DelegatableCore {
    /// @notice The hash of the domain separator used in the EIP712 domain hash.
    bytes32 public immutable domainHash;

    /**
     * @notice Delegatable Constructor
     * @param contractName string - The name of the contract
     * @param version string - The version of the contract
     */
    constructor(string memory contractName, string memory version) {
        domainHash = getEIP712DomainHash(
            contractName,
            version,
            block.chainid,
            address(this)
        );
    }

    /* ===================================================================================== */
    /* External Functions                                                                    */
    /* ===================================================================================== */

    /// @inheritdoc IDelegatable
    function getDelegationTypedDataHash(Delegation memory delegation)
        public
        view
        returns (bytes32)
    {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainHash,
                GET_DELEGATION_PACKETHASH(delegation)
            )
        );
        return digest;
    }

    /// @inheritdoc IDelegatable
    function getInvocationsTypedDataHash(Invocations memory invocations)
        public
        view
        returns (bytes32)
    {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainHash,
                GET_INVOCATIONS_PACKETHASH(invocations)
            )
        );
        return digest;
    }

    function getEIP712DomainHash(
        string memory contractName,
        string memory version,
        uint256 chainId,
        address verifyingContract
    ) public pure returns (bytes32) {
        bytes memory encoded = abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(contractName)),
            keccak256(bytes(version)),
            chainId,
            verifyingContract
        );
        return keccak256(encoded);
    }

    function verifyDelegationSignature(SignedDelegation memory signedDelegation)
        public
        view
        virtual
        override(IDelegatable, DelegatableCore)
        returns (address)
    {
        Delegation memory delegation = signedDelegation.delegation;
        bytes32 sigHash = getDelegationTypedDataHash(delegation);
        address recoveredSignatureSigner = recover(
            sigHash,
            signedDelegation.signature
        );
        return recoveredSignatureSigner;
    }

    function verifyInvocationSignature(SignedInvocation memory signedInvocation)
        public
        view
        returns (address)
    {
        bytes32 sigHash = getInvocationsTypedDataHash(
            signedInvocation.invocations
        );
        address recoveredSignatureSigner = recover(
            sigHash,
            signedInvocation.signature
        );
        return recoveredSignatureSigner;
    }

    // --------------------------------------
    // WRITES
    // --------------------------------------

    /// @inheritdoc IDelegatable
    function contractInvoke(Invocation[] calldata batch)
        external
        override
        returns (bool)
    {
        return _invoke(batch, msg.sender);
    }

    /// @inheritdoc IDelegatable
    function invoke(SignedInvocation[] calldata signedInvocations)
        external
        override
        returns (bool success)
    {
        for (uint256 i = 0; i < signedInvocations.length; i++) {
            SignedInvocation calldata signedInvocation = signedInvocations[i];
            address invocationSigner = verifyInvocationSignature(
                signedInvocation
            );
            _enforceReplayProtection(
                invocationSigner,
                signedInvocations[i].invocations.replayProtection
            );
            _invoke(signedInvocation.invocations.batch, invocationSigner);
        }
    }

    /* ===================================================================================== */
    /* Internal Functions                                                                    */
    /* ===================================================================================== */
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import {EIP712Decoder, EIP712DOMAIN_TYPEHASH} from "./TypesAndDecoders.sol";
import {Delegation, Invocation, Invocations, SignedInvocation, SignedDelegation, Transaction, ReplayProtection, CaveatEnforcer} from "./CaveatEnforcer.sol";

abstract contract DelegatableCore is EIP712Decoder {
    /// @notice Account delegation nonce manager
    mapping(address => mapping(uint256 => uint256)) internal multiNonce;

    function getNonce(address intendedSender, uint256 queue)
        external
        view
        returns (uint256)
    {
        return multiNonce[intendedSender][queue];
    }

    function verifyDelegationSignature(SignedDelegation memory signedDelegation)
        public
        view
        virtual
        returns (address);

    function _enforceReplayProtection(
        address intendedSender,
        ReplayProtection memory protection
    ) internal {
        uint256 queue = protection.queue;
        uint256 nonce = protection.nonce;
        require(
            nonce == (multiNonce[intendedSender][queue] + 1),
            "DelegatableCore:nonce2-out-of-order"
        );
        multiNonce[intendedSender][queue] = nonce;
    }

    function _execute(
        address to,
        bytes memory data,
        uint256 gasLimit,
        address sender
    ) internal returns (bool success) {
        bytes memory full = abi.encodePacked(data, sender);
        assembly {
            success := call(gasLimit, to, 0, add(full, 0x20), mload(full), 0, 0)
        }
    }

    function _invoke(Invocation[] calldata batch, address sender)
        internal
        returns (bool success)
    {
        for (uint256 x = 0; x < batch.length; x++) {
            Invocation memory invocation = batch[x];
            address intendedSender;
            address canGrant;

            // If there are no delegations, this invocation comes from the signer
            if (invocation.authority.length == 0) {
                intendedSender = sender;
                canGrant = intendedSender;
            }

            bytes32 authHash = 0x0;

            for (uint256 d = 0; d < invocation.authority.length; d++) {
                SignedDelegation memory signedDelegation = invocation.authority[
                    d
                ];
                address delegationSigner = verifyDelegationSignature(
                    signedDelegation
                );

                // Implied sending account is the signer of the first delegation
                if (d == 0) {
                    intendedSender = delegationSigner;
                    canGrant = intendedSender;
                }

                require(
                    delegationSigner == canGrant,
                    "DelegatableCore:invalid-delegation-signer"
                );

                Delegation memory delegation = signedDelegation.delegation;
                require(
                    delegation.authority == authHash,
                    "DelegatableCore:invalid-authority-delegation-link"
                );

                // TODO: maybe delegations should have replay protection, at least a nonce (non order dependent),
                // otherwise once it's revoked, you can't give the exact same permission again.
                bytes32 delegationHash = GET_SIGNEDDELEGATION_PACKETHASH(
                    signedDelegation
                );

                // Each delegation can include any number of caveats.
                // A caveat is any condition that may reject a proposed transaction.
                // The caveats specify an external contract that is passed the proposed tx,
                // As well as some extra terms that are used to parameterize the enforcer.
                for (uint16 y = 0; y < delegation.caveats.length; y++) {
                    CaveatEnforcer enforcer = CaveatEnforcer(
                        delegation.caveats[y].enforcer
                    );
                    bool caveatSuccess = enforcer.enforceCaveat(
                        delegation.caveats[y].terms,
                        invocation.transaction,
                        delegationHash
                    );
                    require(caveatSuccess, "DelegatableCore:caveat-rejected");
                }

                // Store the hash of this delegation in `authHash`
                // That way the next delegation can be verified against it.
                authHash = delegationHash;
                canGrant = delegation.delegate;
            }

            // Here we perform the requested invocation.
            Transaction memory transaction = invocation.transaction;

            require(
                transaction.to == address(this),
                "DelegatableCore:invalid-invocation-target"
            );

            // TODO(@kames): Can we bubble up the error message from the enforcer? Why not? Optimizations?
            success = _execute(
                transaction.to,
                transaction.data,
                transaction.gasLimit,
                intendedSender
            );
            require(success, "DelegatableCore::execution-failed");
        }
    }

    function _msgSender() internal view virtual returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;
import "./libraries/ECRecovery.sol";

// BEGIN EIP712 AUTOGENERATED SETUP
struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
}

bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
);

struct Invocation {
    Transaction transaction;
    SignedDelegation[] authority;
}

bytes32 constant INVOCATION_TYPEHASH = keccak256(
    "Invocation(Transaction transaction,SignedDelegation[] authority)Caveat(address enforcer,bytes terms)Delegation(address delegate,bytes32 authority,Caveat[] caveats)SignedDelegation(Delegation delegation,bytes signature)Transaction(address to,uint256 gasLimit,bytes data)"
);

struct Invocations {
    Invocation[] batch;
    ReplayProtection replayProtection;
}

bytes32 constant INVOCATIONS_TYPEHASH = keccak256(
    "Invocations(Invocation[] batch,ReplayProtection replayProtection)Caveat(address enforcer,bytes terms)Delegation(address delegate,bytes32 authority,Caveat[] caveats)Invocation(Transaction transaction,SignedDelegation[] authority)ReplayProtection(uint nonce,uint queue)SignedDelegation(Delegation delegation,bytes signature)Transaction(address to,uint256 gasLimit,bytes data)"
);

struct SignedInvocation {
    Invocations invocations;
    bytes signature;
}

bytes32 constant SIGNEDINVOCATION_TYPEHASH = keccak256(
    "SignedInvocation(Invocations invocations,bytes signature)Caveat(address enforcer,bytes terms)Delegation(address delegate,bytes32 authority,Caveat[] caveats)Invocation(Transaction transaction,SignedDelegation[] authority)Invocations(Invocation[] batch,ReplayProtection replayProtection)ReplayProtection(uint nonce,uint queue)SignedDelegation(Delegation delegation,bytes signature)Transaction(address to,uint256 gasLimit,bytes data)"
);

struct Transaction {
    address to;
    uint256 gasLimit;
    bytes data;
}

bytes32 constant TRANSACTION_TYPEHASH = keccak256(
    "Transaction(address to,uint256 gasLimit,bytes data)"
);

struct ReplayProtection {
    uint256 nonce;
    uint256 queue;
}

bytes32 constant REPLAYPROTECTION_TYPEHASH = keccak256(
    "ReplayProtection(uint nonce,uint queue)"
);

struct Delegation {
    address delegate;
    bytes32 authority;
    Caveat[] caveats;
}

bytes32 constant DELEGATION_TYPEHASH = keccak256(
    "Delegation(address delegate,bytes32 authority,Caveat[] caveats)Caveat(address enforcer,bytes terms)"
);

struct Caveat {
    address enforcer;
    bytes terms;
}

bytes32 constant CAVEAT_TYPEHASH = keccak256(
    "Caveat(address enforcer,bytes terms)"
);

struct SignedDelegation {
    Delegation delegation;
    bytes signature;
}

bytes32 constant SIGNEDDELEGATION_TYPEHASH = keccak256(
    "SignedDelegation(Delegation delegation,bytes signature)Caveat(address enforcer,bytes terms)Delegation(address delegate,bytes32 authority,Caveat[] caveats)"
);

// END EIP712 AUTOGENERATED SETUP

contract EIP712Decoder is ECRecovery {
    // BEGIN EIP712 AUTOGENERATED BODY. See scripts/typesToCode.js

    // function GET_EIP712DOMAIN_PACKETHASH(EIP712Domain memory _input)
    //     public
    //     pure
    //     returns (bytes32)
    // {
    //     bytes memory encoded = abi.encode(
    //         EIP712DOMAIN_TYPEHASH,
    //         _input.name,
    //         _input.version,
    //         _input.chainId,
    //         _input.verifyingContract
    //     );

    //     return keccak256(encoded);
    // }

    function GET_INVOCATION_PACKETHASH(Invocation memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            INVOCATION_TYPEHASH,
            GET_TRANSACTION_PACKETHASH(_input.transaction),
            GET_SIGNEDDELEGATION_ARRAY_PACKETHASH(_input.authority)
        );

        return keccak256(encoded);
    }

    function GET_SIGNEDDELEGATION_ARRAY_PACKETHASH(
        SignedDelegation[] memory _input
    ) public pure returns (bytes32) {
        bytes memory encoded;
        for (uint256 i = 0; i < _input.length; i++) {
            encoded = bytes.concat(
                encoded,
                GET_SIGNEDDELEGATION_PACKETHASH(_input[i])
            );
        }

        bytes32 hash = keccak256(encoded);
        return hash;
    }

    function GET_INVOCATIONS_PACKETHASH(Invocations memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            INVOCATIONS_TYPEHASH,
            GET_INVOCATION_ARRAY_PACKETHASH(_input.batch),
            GET_REPLAYPROTECTION_PACKETHASH(_input.replayProtection)
        );

        return keccak256(encoded);
    }

    function GET_INVOCATION_ARRAY_PACKETHASH(Invocation[] memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded;
        for (uint256 i = 0; i < _input.length; i++) {
            encoded = bytes.concat(
                encoded,
                GET_INVOCATION_PACKETHASH(_input[i])
            );
        }

        bytes32 hash = keccak256(encoded);
        return hash;
    }

    // function GET_SIGNEDINVOCATION_PACKETHASH(SignedInvocation memory _input)
    //     public
    //     pure
    //     returns (bytes32)
    // {
    //     bytes memory encoded = abi.encode(
    //         SIGNEDINVOCATION_TYPEHASH,
    //         GET_INVOCATIONS_PACKETHASH(_input.invocations),
    //         keccak256(_input.signature)
    //     );

    //     return keccak256(encoded);
    // }

    function GET_TRANSACTION_PACKETHASH(Transaction memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            TRANSACTION_TYPEHASH,
            _input.to,
            _input.gasLimit,
            keccak256(_input.data)
        );

        return keccak256(encoded);
    }

    function GET_REPLAYPROTECTION_PACKETHASH(ReplayProtection memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            REPLAYPROTECTION_TYPEHASH,
            _input.nonce,
            _input.queue
        );

        return keccak256(encoded);
    }

    function GET_DELEGATION_PACKETHASH(Delegation memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            DELEGATION_TYPEHASH,
            _input.delegate,
            _input.authority,
            GET_CAVEAT_ARRAY_PACKETHASH(_input.caveats)
        );

        return keccak256(encoded);
    }

    function GET_CAVEAT_ARRAY_PACKETHASH(Caveat[] memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded;
        for (uint256 i = 0; i < _input.length; i++) {
            encoded = bytes.concat(encoded, GET_CAVEAT_PACKETHASH(_input[i]));
        }

        bytes32 hash = keccak256(encoded);
        return hash;
    }

    function GET_CAVEAT_PACKETHASH(Caveat memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            CAVEAT_TYPEHASH,
            _input.enforcer,
            keccak256(_input.terms)
        );

        return keccak256(encoded);
    }

    function GET_SIGNEDDELEGATION_PACKETHASH(SignedDelegation memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            SIGNEDDELEGATION_TYPEHASH,
            GET_DELEGATION_PACKETHASH(_input.delegation),
            keccak256(_input.signature)
        );

        return keccak256(encoded);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../TypesAndDecoders.sol";

interface IDelegatable {
    /**
     * @notice Allows a smart contract to submit a batch of invocations for processing, allowing itself to be the delegate.
     * @param batch Invocation[] - The batch of invocations to process.
     * @return success bool - Whether the batch of invocations was successfully processed.
     */
    function contractInvoke(Invocation[] calldata batch)
        external
        returns (bool);

    /**
     * @notice Allows anyone to submit a batch of signed invocations for processing.
     * @param signedInvocations SignedInvocation[] - The batch of signed invocations to process.
     * @return success bool - Whether the batch of invocations was successfully processed.
     */
    function invoke(SignedInvocation[] calldata signedInvocations)
        external
        returns (bool success);

    /**
     * @notice Returns the typehash for this contract's delegation signatures.
     * @param delegation Delegation - The delegation to get the type of
     * @return bytes32 - The type of the delegation
     */
    function getDelegationTypedDataHash(Delegation memory delegation)
        external
        view
        returns (bytes32);

    /**
     * @notice Returns the typehash for this contract's invocation signatures.
     * @param invocations Invocations
     * @return bytes32 - The type of the Invocations
     */
    function getInvocationsTypedDataHash(Invocations memory invocations)
        external
        view
        returns (bytes32);

    function getEIP712DomainHash(
        string memory contractName,
        string memory version,
        uint256 chainId,
        address verifyingContract
    ) external pure returns (bytes32);

    /**
     * @notice Verifies that the given invocation is valid.
     * @param signedInvocation - The signed invocation to verify
     * @return address - The address of the account authorizing this invocation to act on its behalf.
     */
    function verifyInvocationSignature(SignedInvocation memory signedInvocation)
        external
        view
        returns (address);

    /**
     * @notice Verifies that the given delegation is valid.
     * @param signedDelegation - The delegation to verify
     * @return address - The address of the account authorizing this delegation to act on its behalf.
     */
    function verifyDelegationSignature(SignedDelegation memory signedDelegation)
        external
        view
        returns (address);
}

pragma solidity ^0.8.15;

// SPDX-License-Identifier: MIT

contract ECRecovery {
    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory sig)
        internal
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        //Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import { LaborMarketManager } from "./LaborMarketManager.sol";

/// @dev Helper interfaces.
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract LaborMarket is LaborMarketManager {
    
    /**
     * @notice Creates a service request.
     * @param _pToken The address of the payment token.
     * @param _pTokenQ The quantity of the payment token.
     * @param _rTokenQ The quantity of the reputation token that can be earned.
     * @param _signalExp The signal deadline expiration.
     * @param _submissionExp The submission deadline expiration.
     * @param _enforcementExp The enforcement deadline expiration.
     * @param _requestUri The uri of the service request data.
     * Requirements:
     * - A user has to be conform to the reputational restrictions imposed by the labor market.
     */
    function submitRequest(
          address _pToken
        , uint256 _pTokenQ
        , uint256 _rTokenQ
        , uint256 _signalExp
        , uint256 _submissionExp
        , uint256 _enforcementExp
        , string calldata _requestUri
    ) 
        external 
        onlyDelegate 
        returns (
            uint256 requestId
        ) 
    {
        unchecked {
            ++serviceId;
        }

        // Keep accounting in mind for ERC20s with transfer fees.
        uint256 pTokenBefore = IERC20(_pToken).balanceOf(address(this));

        IERC20(_pToken).transferFrom(_msgSender(), address(this), _pTokenQ);

        uint256 pTokenAfter = IERC20(_pToken).balanceOf(address(this));

        ServiceRequest memory serviceRequest = ServiceRequest({
            serviceRequester: _msgSender(),
            pToken: _pToken,
            pTokenQ: (pTokenAfter - pTokenBefore),
            rTokenQ: _rTokenQ,
            signalExp: _signalExp,
            submissionExp: _submissionExp,
            enforcementExp: _enforcementExp,
            submissionCount: 0,
            uri: _requestUri
        });

        serviceRequests[serviceId] = serviceRequest;

        emit RequestConfigured(
            _msgSender(),
            serviceId,
            _requestUri,
            _pToken,
            _pTokenQ,
            _rTokenQ,
            _signalExp,
            _submissionExp,
            _enforcementExp
        );

        return serviceId;
    }

    /**
     * @notice Signals interest in fulfilling a service request.
     * @param _requestId The id of the service request.
     */
    function signal(
        uint256 _requestId
    ) 
        external 
        permittedParticipant 
    {
        require(
            block.timestamp <= serviceRequests[_requestId].signalExp,
            "LaborMarket::signal: Signal deadline passed."
        );
        require(
            !hasPerformed[_requestId][_msgSender()][HAS_SIGNALED],
            "LaborMarket::signal: Already signaled."
        );

        reputationModule.useReputation(_msgSender(), configuration.signalStake);

        hasPerformed[_requestId][_msgSender()][HAS_SIGNALED] = true;

        unchecked {
            ++signalCount[_requestId];
        }

        emit RequestSignal(_msgSender(), _requestId, configuration.signalStake);
    }

    /**
     * @notice Signals interest in reviewing a submission.
     * @param _requestId The id of the request a maintainer would like to review.
     * @param _quantity The amount of submissions a maintainer is willing to review.
     */
    function signalReview(
          uint256 _requestId
        , uint256 _quantity
    ) 
        external 
        onlyMaintainer 
    {
        ReviewPromise storage reviewPromise = reviewSignals[_requestId][_msgSender()];

        require(
            reviewPromise.remainder == 0,
            "LaborMarket::signalReview: Already signaled."
        );

        uint256 signalStake = _quantity * configuration.signalStake;

        reputationModule.useReputation(_msgSender(), signalStake);

        reviewPromise.total = _quantity;
        reviewPromise.remainder = _quantity;

        emit ReviewSignal(_msgSender(), _requestId, _quantity, signalStake);
    }

    /**
     * @notice Allows a service provider to fulfill a service request.
     * @param _requestId The id of the service request being fulfilled.
     * @param _uri The uri of the service submission data.
     */
    function provide(
          uint256 _requestId
        , string calldata _uri
    )
        external
        returns (
            uint256 submissionId
        )
    {
        require(
            block.timestamp <= serviceRequests[_requestId].submissionExp,
            "LaborMarket::provide: Submission deadline passed."
        );
        require(
            hasPerformed[_requestId][_msgSender()][HAS_SIGNALED],
            "LaborMarket::provide: Not signaled."
        );
        require(
            !hasPerformed[_requestId][_msgSender()][HAS_SUBMITTED],
            "LaborMarket::provide: Already submitted."
        );

        unchecked {
            ++serviceId;
            ++serviceRequests[_requestId].submissionCount;
        }

        serviceSubmissions[serviceId] = ServiceSubmission({
            serviceProvider: _msgSender(),
            requestId: _requestId,
            timestamp: block.timestamp,
            uri: _uri,
            scores: new uint256[](0),
            reviewed: false
        });

        hasPerformed[_requestId][_msgSender()][HAS_SUBMITTED] = true;

        reputationModule.mintReputation(_msgSender(), configuration.signalStake);

        emit RequestFulfilled(_msgSender(), _requestId, serviceId);

        return serviceId;
    }

    /**
     * @notice Allows a maintainer to review a service submission.
     * @param _requestId The id of the service request being fulfilled.
     * @param _submissionId The id of the service providers submission.
     * @param _score The score of the service submission.
     */
    function review(
          uint256 _requestId
        , uint256 _submissionId
        , uint256 _score
    ) 
        external
    {
        require(
            block.timestamp <= serviceRequests[_requestId].enforcementExp,
            "LaborMarket::review: Enforcement deadline passed."
        );

        require(
            reviewSignals[_requestId][_msgSender()].remainder > 0,
            "LaborMarket::review: Not signaled."
        );

        require(
            !hasPerformed[_submissionId][_msgSender()][HAS_REVIEWED],
            "LaborMarket::review: Already reviewed."
        );

        require(
            serviceSubmissions[_submissionId].serviceProvider != _msgSender(),
            "LaborMarket::review: Cannot review own submission."
        );

        _score = enforcementCriteria.review(_submissionId, _score);

        serviceSubmissions[_submissionId].scores.push(_score);

        if (!serviceSubmissions[_submissionId].reviewed)
            serviceSubmissions[_submissionId].reviewed = true;

        hasPerformed[_submissionId][_msgSender()][HAS_REVIEWED] = true;

        unchecked {
            --reviewSignals[_requestId][_msgSender()].remainder;
        }

        reputationModule.mintReputation(
            _msgSender(),
            configuration.signalStake
        );

        emit RequestReviewed(_msgSender(), _requestId, _submissionId, _score);
    }

    /**
     * @notice Allows a service provider to claim payment for a service submission.
     * @param _submissionId The id of the service providers submission.
     * @param _to The address to send the payment to.
     * @param _data The data to send with the payment.
     */
    function claim(
          uint256 _submissionId
        , address _to
        , bytes calldata _data
    ) 
        external 
        returns (
            uint256
        ) 
    {
        require(
            !hasPerformed[_submissionId][_msgSender()][HAS_CLAIMED],
            "LaborMarket::claim: Already claimed."
        );

        require(
            serviceSubmissions[_submissionId].reviewed,
            "LaborMarket::claim: Not reviewed."
        );

        require(
            serviceSubmissions[_submissionId].serviceProvider == _msgSender(),
            "LaborMarket::claim: Not service provider."
        );

        uint256 requestId = serviceSubmissions[_submissionId].requestId;

        require(
            block.timestamp >=
                serviceRequests[requestId]
                    .enforcementExp,
            "LaborMarket::claim: Enforcement deadline not passed."
        );

        uint256 pCurveIndex = (_data.length > 0)
            ? enforcementCriteria.verifyWithData(_submissionId, _data)
            : enforcementCriteria.verify(_submissionId, serviceRequests[requestId].pTokenQ);

        uint256 rCurveIndex = enforcementCriteria.verify(
            _submissionId, 
            serviceRequests[requestId].rTokenQ * 1e18 // Scale to 18 decimals for utilization with ERC20 specific math.
        );

        uint256 payAmount = paymentCurve.curvePoint(pCurveIndex);
        uint256 reputationAmount = paymentCurve.curvePoint(rCurveIndex) / 1e18; // Revert the 18 decimal scale.

        hasPerformed[_submissionId][_msgSender()][HAS_CLAIMED] = true;

        IERC20(
            serviceRequests[serviceSubmissions[_submissionId].requestId].pToken
        ).transfer(_to, payAmount);

        reputationModule.mintReputation(_msgSender(), reputationAmount);

        emit RequestPayClaimed(_msgSender(), requestId, _submissionId, payAmount, _to);

        return payAmount;
    }

    /**
     * @notice Allows a service requester to claim the remainder of funds not allocated to service providers.
     * @param _requestId The id of the service request.
     */
    function claimRemainder(
        uint256 _requestId
    ) 
        public 
    {
        require(
            serviceRequests[_requestId].serviceRequester == _msgSender(),
            "LaborMarket::claimRemainder: Not service requester."
        );
        require(
            block.timestamp >= serviceRequests[_requestId].enforcementExp,
            "LaborMarket::claimRemainder: Enforcement deadline not passed."
        );
        require(
            !hasPerformed[_requestId][_msgSender()][HAS_CLAIMED_REMAINDER],
            "LaborMarket::claimRemainder: Already claimed."
        );
        uint256 totalClaimable = enforcementCriteria.getRemainder(_requestId);

        hasPerformed[_requestId][_msgSender()][HAS_CLAIMED_REMAINDER] = true;

        IERC20(serviceRequests[_requestId].pToken).transfer(
            _msgSender(),
            totalClaimable
        );

        emit RemainderClaimed(_msgSender(), _requestId, totalClaimable);
    }

    /**
     * @notice Allows a maintainer to retrieve reputation that is stuck in review signals.
     * @param _requestId The id of the service request.
     */
    function retrieveReputation(
        uint256 _requestId
    ) 
        public 
    {
        require(
            reviewSignals[_requestId][_msgSender()].remainder > 0,
            "LaborMarket::retrieveReputation: No reputation to retrieve."
        );

        require(
            block.timestamp >
                serviceRequests[serviceSubmissions[serviceId].requestId].enforcementExp,
            "LaborMarket::retrieveReputation: Enforcement deadline not passed."
        );

        ReviewPromise storage reviewPromise = reviewSignals[_requestId][_msgSender()];

        require(
            reviewPromise.total >=
            serviceRequests[_requestId].submissionCount,
            "LaborMarket::retrieveReputation: Insufficient reviews."
        );

        reputationModule.mintReputation(
            _msgSender(),
            configuration.signalStake * reviewPromise.remainder
        );

        reviewPromise.total = 0;
        reviewPromise.remainder = 0;
    }

    /**
     * @notice Allows a service requester to withdraw a request.
     * @param _requestId The id of the service requesters request.
     * Requirements:
     * - The request must not have been signaled.
     */
    function withdrawRequest(
        uint256 _requestId
    ) 
        external 
    {
        require(
            serviceRequests[_requestId].serviceRequester == _msgSender(),
            "LaborMarket::withdrawRequest: Not service requester."
        );
        require(
            signalCount[_requestId] < 1,
            "LaborMarket::withdrawRequest: Already active."
        );
        address pToken = serviceRequests[_requestId].pToken;
        uint256 amount = serviceRequests[_requestId].pTokenQ;

        delete serviceRequests[_requestId];

        IERC20(pToken).transfer(_msgSender(), amount);

        emit RequestWithdrawn(_requestId);
    }

    /**
     * @notice Allows a service requester to edit a request.
     * @param _requestId The id of the service requesters request.
     * @param _pToken The address of the payment token.
     * @param _pTokenQ The quantity of payment tokens.
     * @param _rTokenQ The quantity of reputation tokens.
     * @param _signalExp The expiration of the signal period.
     * @param _submissionExp The expiration of the submission period.
     * @param _enforcementExp The expiration of the enforcement period.
     * @param _requestUri The uri of the request.
     * Requirements:
     * - The request must not have been signaled.
     */
    function editRequest(
          uint256 _requestId
        , address _pToken
        , uint256 _pTokenQ
        , uint256 _rTokenQ
        , uint256 _signalExp
        , uint256 _submissionExp
        , uint256 _enforcementExp
        , string calldata _requestUri
    )
        external
    {
        require(
            serviceRequests[_requestId].serviceRequester == _msgSender(),
            "LaborMarket::withdrawRequest: Not service requester."
        );
        require(
            signalCount[_requestId] < 1,
            "LaborMarket::withdrawRequest: Already active."
        );

        // Refund the prior payment token.
        IERC20(serviceRequests[_requestId].pToken).transfer(
            _msgSender(),
            serviceRequests[_requestId].pTokenQ
        );
    
        // Keep accounting in mind for ERC20s with transfer fees.
        uint256 pTokenBefore = IERC20(_pToken).balanceOf(address(this));

        IERC20(_pToken).transferFrom(_msgSender(), address(this), _pTokenQ);

        uint256 pTokenAfter = IERC20(_pToken).balanceOf(address(this));

        ServiceRequest memory serviceRequest = ServiceRequest({
            serviceRequester: _msgSender(),
            pToken: _pToken,
            pTokenQ: (pTokenAfter - pTokenBefore),
            rTokenQ: _rTokenQ,
            signalExp: _signalExp,
            submissionExp: _submissionExp,
            enforcementExp: _enforcementExp,
            submissionCount: 0,
            uri: _requestUri
        });

        serviceRequests[serviceId] = serviceRequest;

        emit RequestConfigured(
            _msgSender(),
            serviceId,
            _requestUri,
            _pToken,
            _pTokenQ,
            _rTokenQ,
            _signalExp,
            _submissionExp,
            _enforcementExp
        );
    }

    /**
     * @notice Allows a network governor to set the configuration.
     * @param _configuration The new configuration.
     * Requirements:
     * - The caller must be a governor at the network level.
     */
    function setConfiguration(
        LaborMarketConfiguration calldata _configuration
    )
        external
    {
        /// @dev Requires the caller to be a governor in the current network.
        network.validateGovernor(_msgSender());
        
        _setConfiguration(_configuration);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import { LaborMarketInterface } from "./interfaces/LaborMarketInterface.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ERC1155HolderUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import { ERC721HolderUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import { Delegatable, DelegatableCore } from "delegatable/Delegatable.sol";

/// @dev Helpers.
import { StringsUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

/// @dev Helper interfaces.
import { LaborMarketNetworkInterface } from "../Network/interfaces/LaborMarketNetworkInterface.sol";
import { EnforcementCriteriaInterface } from "../Modules/Enforcement/interfaces/EnforcementCriteriaInterface.sol";
import { PayCurveInterface } from "../Modules/Payment/interfaces/PayCurveInterface.sol";
import { ReputationModuleInterface } from "../Modules/Reputation/interfaces/ReputationModuleInterface.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @dev Supported interfaces.
import { IERC1155ReceiverUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import { IERC721ReceiverUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

contract LaborMarketManager is
    LaborMarketInterface,
    ERC1155HolderUpgradeable,
    ERC721HolderUpgradeable,
    Delegatable("LaborMarket", "v1.0.0"),
    ContextUpgradeable
{
    /// @dev Performable actions.
    bytes32 public constant HAS_SUBMITTED = keccak256("hasSubmitted");

    bytes32 public constant HAS_CLAIMED = keccak256("hasClaimed");

    bytes32 public constant HAS_CLAIMED_REMAINDER =
        keccak256("hasClaimedRemainder");

    bytes32 public constant HAS_REVIEWED = keccak256("hasReviewed");
    
    bytes32 public constant HAS_SIGNALED = keccak256("hasSignaled");

    /// @dev The network contract.
    LaborMarketNetworkInterface public network;

    /// @dev The enforcement criteria.
    EnforcementCriteriaInterface public enforcementCriteria;

    /// @dev The payment curve.
    PayCurveInterface public paymentCurve;

    /// @dev The reputation module.
    ReputationModuleInterface public reputationModule;

    /// @dev The configuration of the labor market.
    LaborMarketConfiguration public configuration;

    /// @dev The delegate badge.
    IERC1155 public delegateBadge;

    /// @dev The maintainer badge.
    IERC1155 public maintainerBadge;

    /// @dev Tracking the signals per service request.
    mapping(uint256 => uint256) public signalCount;

    /// @dev Tracking the service requests.
    mapping(uint256 => ServiceRequest) public serviceRequests;

    /// @dev Tracking the service submissions.
    mapping(uint256 => ServiceSubmission) public serviceSubmissions;

    /// @dev Tracking the review signals.
    mapping(uint256 => mapping(address => ReviewPromise)) public reviewSignals;

    /// @dev Tracking whether an action has been performed.
    mapping(uint256 => mapping(address => mapping(bytes32 => bool)))
        public hasPerformed;

    /// @dev The service request id counter.
    uint256 public serviceId;

    /// @notice emitted when labor market parameters are updated.
    event LaborMarketConfigured(
        LaborMarketConfiguration indexed configuration
    );

    /// @notice emitted when a new service request is made.
    event RequestConfigured(
          address indexed requester
        , uint256 indexed requestId
        , string indexed uri
        , address pToken
        , uint256 pTokenQ
        , uint256 rTokenQ
        , uint256 signalExp
        , uint256 submissionExp
        , uint256 enforcementExp
    );

    /// @notice emitted when a user signals a service request.
    event RequestSignal(
          address indexed signaler
        , uint256 indexed requestId
        , uint256 signalAmount
    );

    /// @notice emitted when a maintainer signals a review.
    event ReviewSignal(
          address indexed signaler
        , uint256 indexed requestId
        , uint256 indexed quantity
        , uint256 signalAmount
    );

    /// @notice emitted when a service request is withdrawn.
    event RequestWithdrawn(
        uint256 indexed requestId
    );

    /// @notice emitted when a service request is fulfilled.
    event RequestFulfilled(
          address indexed fulfiller
        , uint256 indexed requestId
        , uint256 indexed submissionId
    );

    /// @notice emitted when a service submission is reviewed
    event RequestReviewed(
          address reviewer
        , uint256 indexed requestId
        , uint256 indexed submissionId
        , uint256 indexed reviewScore
    );

    /// @notice emitted when a service submission is claimed.
    event RequestPayClaimed(
          address indexed claimer
        , uint256 indexed requestId
        , uint256 indexed submissionId
        , uint256 payAmount
        , address to
    );

    /// @notice emitted when a remainder is claimed.
    event RemainderClaimed(
          address indexed claimer
        , uint256 indexed requestId
        , uint256 remainderAmount
    );

    /// @notice Gates the permissions to create new requests.
    modifier onlyDelegate() {
        require(
            delegateBadge.balanceOf(
                _msgSender(),
                configuration.delegate.tokenId
            ) > 0,
            "LaborMarket::onlyDelegate: Not a delegate"
        );
        _;
    }

    /// @notice Gates the permissions to review submissions.
    modifier onlyMaintainer() {
        require(
            maintainerBadge.balanceOf(
                _msgSender(),
                configuration.maintainer.tokenId
            ) > 0,
            "LaborMarket::onlyMaintainer: Not a maintainer"
        );
        _;
    }

    /// @notice Gates the permissions to provide submissions based on reputation.
    modifier permittedParticipant() {
        uint256 availableRep = _getAvailableReputation();
        require((
                availableRep >= configuration.submitMin &&
                availableRep < configuration.submitMax
            ), "LaborMarket::permittedParticipant: Not a permitted participant"
        );
        _;
    }

    /// @notice Initialize the labor market.
    function initialize(
        LaborMarketConfiguration calldata _configuration
    )
        external
        override
        initializer
    {
        _setConfiguration(_configuration);
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the service request data.
     * @param _requestId The id of the service requesters request.
     */
    function getRequest(
        uint256 _requestId
    )
        external
        view
        returns (ServiceRequest memory)
    {
        return serviceRequests[_requestId];
    }

    /**
     * @notice Returns the service submission data.
     * @param _submissionId The id of the service providers submission.
     */
    function getSubmission(
        uint256 _submissionId
    )
        external
        view
        returns (ServiceSubmission memory)
    {
        return serviceSubmissions[_submissionId];
    }

    /**
     * @notice Returns the market configuration.
     */
    function getConfiguration()
        external
        view
        returns (LaborMarketConfiguration memory)
    {
        return configuration;
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL SETTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Handle all the logic for configuration of a LaborMarket.
     */
    function _setConfiguration(
        LaborMarketConfiguration calldata _configuration
    )
        internal
    {
        /// @dev Connect to the higher level network to pull the active states.
        network = LaborMarketNetworkInterface(_configuration.modules.network);

        /// @dev Configure the Labor Market state control.
        enforcementCriteria = EnforcementCriteriaInterface(
            _configuration.modules.enforcement
        );

        /// @dev Configure the Labor Market pay curve.
        paymentCurve = PayCurveInterface(_configuration.modules.payment);

        /// @dev Configure the Labor Market reputation module.
        reputationModule = ReputationModuleInterface(
            _configuration.modules.reputation
        );

        /// @dev Configure the Labor Market access control.
        delegateBadge = IERC1155(_configuration.delegate.token);
        maintainerBadge = IERC1155(_configuration.maintainer.token);

        /// @dev Configure the Labor Market parameters.
        configuration = _configuration;

        emit LaborMarketConfigured(_configuration);
    }
    /*//////////////////////////////////////////////////////////////
                            INTERNAL GETTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {ReputationModule-getAvailableReputation}
     */
    function _getAvailableReputation() internal view returns (uint256) {
        return
            reputationModule.getAvailableReputation(
                address(this),
                _msgSender()
            );
    }

    /**
     * @dev Delegatable ETH support
     */
    function _msgSender()
        internal
        view
        virtual
        override(DelegatableCore, ContextUpgradeable)
        returns (
            address sender
        )
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

interface LaborMarketConfigurationInterface {
    struct LaborMarketConfiguration {
        string marketUri;
        Modules modules;
        BadgePair delegate;
        BadgePair maintainer;
        BadgePair reputation;
        uint256 signalStake;
        uint256 submitMin;
        uint256 submitMax;
    }

    struct Modules {
        address network;
        address enforcement;
        address payment;
        address reputation;
    }

    struct BadgePair {
        address token;
        uint256 tokenId;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import { LaborMarketConfigurationInterface } from "./LaborMarketConfigurationInterface.sol";

interface LaborMarketInterface is LaborMarketConfigurationInterface {
    struct ServiceRequest {
        address serviceRequester;
        address pToken;
        uint256 pTokenQ;
        uint256 rTokenQ;
        uint256 signalExp;
        uint256 submissionExp;
        uint256 enforcementExp;
        uint256 submissionCount;
        string uri;
    }

    struct ServiceSubmission {
        address serviceProvider;
        uint256 requestId;
        uint256 timestamp;
        string uri;
        uint256[] scores;
        bool reviewed;
    }

    struct ReviewPromise {
        uint256 total;
        uint256 remainder;
    }

    function initialize(LaborMarketConfiguration calldata _configuration)
        external;

    function getSubmission(uint256 submissionId)
        external
        view
        returns (ServiceSubmission memory);

    function getRequest(uint256 requestId)
        external
        view
        returns (ServiceRequest memory);

    function getConfiguration()
        external
        view
        returns (LaborMarketConfiguration memory);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

interface EnforcementCriteriaInterface {
    function review(uint256 submissionId, uint256 score)
        external
        returns (uint256);

    function verify(uint256 submissionId, uint256 amount) external returns (uint256);

    function verifyWithData(uint256 submissionId, bytes calldata data)
        external
        returns (uint256);

    function getRemainder(uint256 requestId) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

interface PayCurveInterface {
    function curvePoint(uint256 x) 
        external 
        returns (
            uint256
        );
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

interface ReputationModuleInterface {
    struct MarketReputationConfig {
        address reputationToken;
        uint256 reputationTokenId;
    }

    struct DecayConfig {
        uint256 decayRate;
        uint256 decayInterval;
        uint256 decayStartEpoch;
    }

    struct ReputationAccountInfo {
        uint256 lastDecayEpoch;
        uint256 frozenUntilEpoch;
    }

    function useReputationModule(
          address _laborMarket
        , address _reputationToken
        , uint256 _reputationTokenId
    )
        external;
        
    function useReputation(
          address _account
        , uint256 _amount
    )
        external;

    function mintReputation(
          address _account
        , uint256 _amount
    )
        external;

    function freezeReputation(
          address _account
        , address _reputationToken
        , uint256 _reputationTokenId
        , uint256 _frozenUntilEpoch
    )
        external; 


    function setDecayConfig(
          address _reputationToken
        , uint256 _reputationTokenId
        , uint256 _decayRate
        , uint256 _decayInterval
        , uint256 _decayStartEpoch
    )
        external;

    function getAvailableReputation(
          address _laborMarket
        , address _account
    )
        external
        view
        returns (
            uint256
        );

    function getPendingDecay(
          address _laborMarket
        , address _account
    )
        external
        view
        returns (
            uint256
        );

    function getMarketReputationConfig(
        address _laborMarket
    )
        external
        view
        returns (
            MarketReputationConfig memory
        );
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import { LaborMarketConfigurationInterface } from "src/LaborMarket/interfaces/LaborMarketConfigurationInterface.sol";

interface LaborMarketNetworkInterface {

    function setCapacityImplementation(
        address _implementation
    )
        external;

    function setGovernorBadge(
        address _governorBadge,
        uint256 _governorTokenId
    ) external;

    function setReputationDecay(
          address _reputationModule
        , address _reputationToken
        , uint256 _reputationTokenId
        , uint256 _decayRate
        , uint256 _decayInterval
        , uint256 _decayStartEpoch
    )
        external;

    function validateGovernor(address _sender) 
        external 
        view;
}