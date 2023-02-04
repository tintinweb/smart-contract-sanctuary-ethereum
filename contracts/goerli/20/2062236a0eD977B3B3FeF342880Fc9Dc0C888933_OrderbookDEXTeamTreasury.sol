// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import { IOrderbookDEXTeamTreasury } from "./interfaces/IOrderbookDEXTeamTreasury.sol";
import { OrderbookDEXTeamTreasuryUtil }
    from "@theorderbookdex/orderbook-dex/contracts/utils/OrderbookDEXTeamTreasuryUtil.sol";
import { IOrderbook } from "@theorderbookdex/orderbook-dex/contracts/interfaces/IOrderbook.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

contract OrderbookDEXTeamTreasury is IOrderbookDEXTeamTreasury, EIP712 {
    using Address for address;

    struct Fee {
        uint32  version;
        uint256 fee;
    }

    /**
     * Name. Used for EIP712 signatures.
     */
    string constant NAME = "OrderbookDEXTeamTreasury";

    /**
     * Version. Used for EIP712 signatures.
     */
    string constant VERSION = "1";

    /**
     * Accounts allowed to sign and call fund administration functions.
     */
    mapping(address => address) private _signers;

    /**
     * How many signatures are required for an action that requires authorization.
     */
    uint256 private immutable _signaturesRequired;

    /**
     * The time that has to elapse for the execution of a scheduled action.
     */
    uint256 private immutable _executionDelay;

    /**
     * The next nonce for the execution of any of the functions which require one.
     */
    uint256 _nonce;

    /**
     * The current fee applied to orderbooks of a specific version.
     */
    mapping(uint32 => uint256) _fee;

    /**
     * The current fee applied to orderbooks of a specific version.
     */
    mapping(uint32 => ScheduledFee) _scheduledFee;

    /**
     * Constructor.
     *
     * @param signers_            accounts allowed to sign and call fund administration functions
     * @param signaturesRequired_ how many signatures are required for an action that requires authorization
     * @param executionDelay_     the time that has to elapse for the execution of a scheduled action
     */
    constructor(
        address[] memory signers_,
        uint256          signaturesRequired_,
        uint256          executionDelay_
    )
        EIP712(NAME, VERSION)
    {
        if (signaturesRequired_ >= signers_.length) {
            revert NotEnoughSigners();
        }

        address prevSigner = address(0);

        for (uint256 i; i < signers_.length; i++) {
            if (signers_[i] == address(0)) {
                revert InvalidSigner();
            }

            if (signers_[i] < prevSigner) {
                revert SignersOutOfOrder();
            }

            if (signers_[i] == prevSigner) {
                revert DuplicateSigner();
            }

            _signers[signers_[i]] = signers_[i];
            emit SignerAdded(signers_[i]);

            prevSigner = signers_[i];
        }

        _signaturesRequired = signaturesRequired_;
        _executionDelay = executionDelay_;
    }

    bytes32 constant REPLACE_SIGNER_TYPEHASH = keccak256(
        "ReplaceSigner("
            "address executor,"
            "uint256 nonce,"
            "address signerToRemove,"
            "address signerToAdd,"
            "uint256 deadline"
        ")"
    );

    function replaceSigner(
        address          signerToRemove,
        address          signerToAdd,
        uint256          deadline,
        bytes[] calldata signatures
    ) external onlySigner validUntil(deadline) {
        if (signerToAdd == address(0)) {
            revert InvalidSigner();
        }

        if (_signers[signerToRemove] != signerToRemove) {
            revert SignerToRemoveIsNotASigner();
        }

        if (_signers[signerToAdd] == signerToAdd) {
            revert SignerToAddIsAlreadyASigner();
        }

        address executor = msg.sender;
        uint256 nonce_ = _nonce;
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            REPLACE_SIGNER_TYPEHASH,
            executor,
            nonce_,
            signerToRemove,
            signerToAdd,
            deadline
        )));

        checkSignatures(executor, signatures, digest);

        _nonce = nonce_ + 1;
        _signers[signerToRemove] = address(0);
        _signers[signerToAdd] = signerToAdd;

        emit SignerRemoved(signerToRemove);
        emit SignerAdded(signerToAdd);
    }

    bytes32 constant SCHEDULE_CHANGE_FEE_TYPEHASH = keccak256(
        "ScheduleChangeFee("
            "address executor,"
            "uint256 nonce,"
             "uint32 version,"
            "uint256 fee,"
            "uint256 deadline"
        ")"
    );

    function scheduleChangeFee(
        uint32           version,
        uint256          fee_,
        uint256          deadline,
        bytes[] calldata signatures
    ) external onlySigner validUntil(deadline) {
        if (fee_ > OrderbookDEXTeamTreasuryUtil.MAX_FEE) {
            revert InvalidFee();
        }

        address executor = msg.sender;
        uint256 nonce_ = _nonce;
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            SCHEDULE_CHANGE_FEE_TYPEHASH,
            executor,
            nonce_,
            version,
            fee_,
            deadline
        )));

        checkSignatures(executor, signatures, digest);

        uint256 time = block.timestamp + _executionDelay;

        _nonce = nonce_ + 1;
        _scheduledFee[version] = ScheduledFee(fee_, time);

        emit FeeChangeScheduled(version, fee_, time);
    }

    bytes32 constant CHANGE_FEE_TYPEHASH = keccak256(
        "ChangeFee("
            "address executor,"
            "uint256 nonce,"
             "uint32 version,"
            "uint256 fee,"
            "uint256 deadline"
        ")"
    );

    function changeFee(
        uint32           version,
        uint256          fee_,
        uint256          deadline,
        bytes[] calldata signatures
    ) external onlySigner validUntil(deadline) {
        if (fee_ > _fee[version]) {
            ScheduledFee memory scheduledFee_ = _scheduledFee[version];

            if (fee_ > scheduledFee_.fee) {
                revert CannotChangeFee();
            }

            if (block.timestamp < scheduledFee_.time) {
                revert CannotChangeFee();
            }
        }

        address executor = msg.sender;
        uint256 nonce_ = _nonce;
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            CHANGE_FEE_TYPEHASH,
            executor,
            nonce_,
            version,
            fee_,
            deadline
        )));

        checkSignatures(executor, signatures, digest);

        _nonce = nonce_ + 1;
        _fee[version] = fee_;
        delete _scheduledFee[version];

        emit FeeChanged(version, fee_);
    }

    function claimFees(IOrderbook[] calldata orderbooks) external onlySigner {
        for (uint256 i; i < orderbooks.length; i++) {
            if (!address(orderbooks[i]).isContract()) {
                continue;
            }
            try orderbooks[i].claimFees() {
                continue;
            } catch {
                continue;
            }
        }
    }

    bytes32 constant CALL_TYPEHASH = keccak256(
        "Call("
            "address executor,"
            "uint256 nonce,"
            "address target,"
              "bytes data,"
            "uint256 value,"
            "uint256 deadline"
        ")"
    );

    function call(
        address          target,
        bytes calldata   data,
        uint256          value,
        uint256          deadline,
        bytes[] calldata signatures
    ) external onlySigner validUntil(deadline) {
        address executor = msg.sender;
        uint256 nonce_ = _nonce;
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            CALL_TYPEHASH,
            executor,
            nonce_,
            target,
            keccak256(data),
            value,
            deadline
        )));

        checkSignatures(executor, signatures, digest);

        _nonce = nonce_ + 1;

        target.functionCallWithValue(data, value);
    }

    bytes32 constant MULTICALL_TYPEHASH = keccak256(
        "Multicall("
            "address executor,"
            "uint256 nonce,"
             "Call[] calls,"
            "uint256 deadline"
        ")"
        "Call("
            "address target,"
              "bytes data,"
            "uint256 value"
        ")"
    );
    bytes32 constant MULTICALL_CALL_TYPEHASH = keccak256(
        "Call("
            "address target,"
              "bytes data,"
            "uint256 value"
        ")"
    );

    function multicall(
        Call[] calldata  calls,
        uint256          deadline,
        bytes[] calldata signatures
    ) external onlySigner validUntil(deadline) {
        address executor = msg.sender;
        uint256 nonce_ = _nonce;
        bytes32[] memory callsHashes = new bytes32[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            callsHashes[i] = keccak256(abi.encode(
                MULTICALL_CALL_TYPEHASH,
                calls[i].target,
                keccak256(calls[i].data),
                calls[i].value
            ));
        }
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            MULTICALL_TYPEHASH,
            executor,
            nonce_,
            keccak256(abi.encodePacked(callsHashes)),
            deadline
        )));

        checkSignatures(executor, signatures, digest);

        _nonce = nonce_ + 1;

        for (uint256 i = 0; i < calls.length; i++) {
            calls[i].target.functionCallWithValue(calls[i].data, calls[i].value);
        }
    }

    function signers(address account) external view returns (bool) {
        return _signers[account] == account;
    }

    function signaturesRequired() external view returns (uint256) {
        return _signaturesRequired;
    }

    function executionDelay() external view returns (uint256) {
        return _executionDelay;
    }

    function nonce() external view returns (uint256) {
        return _nonce;
    }

    function fee(uint32 version) external view returns (uint256) {
        return _fee[version];
    }

    function scheduledFee(uint32 version) external view returns (ScheduledFee memory) {
        return _scheduledFee[version];
    }

    receive() external payable {}

    /**
     * Check the signatures used to call a function.
     *
     * @param executor   the account calling the function
     * @param signatures the signatures to check
     * @param digest     the hash for the structured data
     */
    function checkSignatures(
        address          executor,
        bytes[] calldata signatures,
        bytes32          digest
    ) internal view {
        if (signatures.length < _signaturesRequired) {
            revert NotEnoughSignatures();
        }

        address prevSigner = address(0);

        for (uint256 i; i < signatures.length; i++) {
            address signer = ECDSA.recover(digest, signatures[i]);

            if (signer < prevSigner) {
                revert SignaturesOutOfOrder();
            }

            if (signer == prevSigner) {
                revert DuplicateSignature();
            }

            if (signer == executor) {
                revert CannotSelfSign();
            }

            if (_signers[signer] != signer) {
                revert InvalidSignature();
            }

            prevSigner = signer;
        }
    }

    /**
     * Modifier for functions that can only be called by a signer.
     */
    modifier onlySigner() {
        if (_signers[msg.sender] != msg.sender) {
            revert Unauthorized();
        }
        _;
    }

    /**
     * Modifier for functions that have a deadline.
     */
    modifier validUntil(uint256 deadline) {
        if (deadline < block.timestamp) {
            revert AfterDeadline();
        }
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import { IOrderbookDEXTeamTreasury as IOrderbookDEXTeamTreasury_ }
    from "@theorderbookdex/orderbook-dex/contracts/interfaces/IOrderbookDEXTeamTreasury.sol";
import { IOrderbook } from "@theorderbookdex/orderbook-dex/contracts/interfaces/IOrderbook.sol";

interface IOrderbookDEXTeamTreasury is IOrderbookDEXTeamTreasury_ {
    /**
     * Scheduled fee change.
     */
    struct ScheduledFee {
        /**
         * The fee.
         */
        uint256 fee;

        /**
         * The time the change of fee is scheduled for.
         */
        uint256 time;
    }

    /**
     * A contract function call.
     */
    struct Call {
        address target;
        bytes   data;
        uint256 value;
    }

    /**
     * Event emitted when a signer is added.
     *
     * @param signer the signer added
     */
    event SignerAdded(address signer);

    /**
     * Event emitted when a signer is removed.
     *
     * @param signer the signer removed
     */
    event SignerRemoved(address signer);

    /**
     * Event emitted when a change of fee is scheduled.
     *
     * @param version the orderbook version
     * @param fee     the fee
     * @param time    the time the change of fee is scheduled for
     */
    event FeeChangeScheduled(uint32 version, uint256 fee, uint256 time);

    /**
     * Event emitted when a fee is changed.
     *
     * @param version the orderbook version
     * @param fee     the fee
     */
    event FeeChanged(uint32 version, uint256 fee);

    /**
     * Error thrown when calling functions that the sender has not been authorized to call.
     */
    error Unauthorized();

    /**
     * Error thrown when a function has been called after its deadline.
     */
    error AfterDeadline();

    /**
     * Error thrown when a function is called with less than the signatures required.
     */
    error NotEnoughSignatures();

    /**
     * Error thrown when a function is called with a signature by the account calling the function.
     */
    error CannotSelfSign();

    /**
     * Error thrown when signatures are not sorted by signer address.
     */
    error SignaturesOutOfOrder();

    /**
     * Error thrown when a function is called with more than one signature from the same account.
     */
    error DuplicateSignature();

    /**
     * Error thrown when a function is called with an invalid signature.
     */
    error InvalidSignature();

    /**
     * Error thrown when deploying with not enough signers.
     *
     * In other words, when signatures required is equal or larger to the amount of signers,
     * therefore it wouldn't ever be possible to provide that amount of signatures.
     */
    error NotEnoughSigners();

    /**
     * Error thrown when trying to remove a signer that is not signer.
     */
    error SignerToRemoveIsNotASigner();

    /**
     * Error thrown when trying to add a signer that is already a signer.
     */
    error SignerToAddIsAlreadyASigner();

    /**
     * Error thrown when unable to change fee.
     *
     * Check changeFee() for reasons why a change of fee might fail.
     */
    error CannotChangeFee();

    /**
     * Error thrown when trying to change fee above max fee.
     */
    error InvalidFee();

    /**
     * Error thrown when trying to set zero address as signer.
     */
    error InvalidSigner();

    /**
     * Error thrown when signers are not sorted by address.
     */
    error SignersOutOfOrder();

    /**
     * Error thrown when there is a signer appears twice.
     */
    error DuplicateSigner();

    /**
     * Schedule a change of fee for an orderbook version.
     *
     * There can only be one pending change of fee per orderbook version. Calling this function again will cancel
     * pending changes and reset the timer for the orderbook version.
     *
     * Only a signer can call this.
     *
     * Requires the signatures of others to execute. Signatures must be sorted by signer address.
     *
     * Signatures must follow EIP-712 spec for the following data structure:
     *
     *     ScheduleChangeFee(
     *       address executor,
     *       uint256 nonce,
     *       uint32  version,
     *       uint256 fee,
     *       uint256 deadline
     *     )
     *
     * @param version    the orderbook version
     * @param fee        the fee
     * @param deadline   the timestamp until which the operation remains valid
     * @param signatures the signatures authorizing the operation
     */
    function scheduleChangeFee(
        uint32           version,
        uint256          fee,
        uint256          deadline,
        bytes[] calldata signatures
    ) external;

    /**
     * Replace a signer by another.
     *
     * Only a signer can call this.
     *
     * Requires the signatures of others to execute. Signatures must be sorted by signer address.
     *
     * Signatures must follow EIP-712 spec for the following data structure:
     *
     *     ReplaceSigner(
     *       address executor,
     *       uint256 nonce,
     *       address signerToRemove,
     *       address signerToAdd,
     *       uint256 deadline
     *     )
     *
     * @param signerToRemove the signer to remove
     * @param signerToAdd    the signer to add
     * @param deadline       the timestamp until which the operation remains valid
     * @param signatures     the signatures authorizing the operation
     */
    function replaceSigner(
        address          signerToRemove,
        address          signerToAdd,
        uint256          deadline,
        bytes[] calldata signatures
    ) external;

    /**
     * Change the fee for an orderbook version.
     *
     * Increase of fees must be scheduled beforehand.
     *
     * A change of fee will cancel any pending change of fee for the orderbook version.
     *
     * Only a signer can call this.
     *
     * Requires the signatures of others to execute. Signatures must be sorted by signer address.
     *
     * Signatures must follow EIP-712 spec for the following data structure:
     *
     *     ChangeFee(
     *       address executor,
     *       uint256 nonce,
     *       uint32  version,
     *       uint256 fee,
     *       uint256 deadline
     *     )
     *
     * @param version    the orderbook version
     * @param fee        the fee
     * @param deadline   the timestamp until which the operation remains valid
     * @param signatures the signatures authorizing the operation
     */
    function changeFee(
        uint32           version,
        uint256          fee,
        uint256          deadline,
        bytes[] calldata signatures
    ) external;

    /**
     * Claim fees from orderbooks.
     *
     * Only a signer can call this.
     *
     * Does not require signatures from other signers.
     *
     * It will ignore any error from attempting to claim fees from an orderbook and continue to the next orderbook.
     *
     * @param orderbooks the orderbooks from which to claim fees
     */
    function claimFees(IOrderbook[] calldata orderbooks) external;

    /**
     * Call another contract.
     *
     * Only a signer can call this.
     *
     * Requires the signatures of others to execute. Signatures must be sorted by signer address.
     *
     * Signatures must follow EIP-712 spec for the following data structure:
     *
     *     Call(
     *       address executor,
     *       uint256 nonce,
     *       address target,
     *       bytes   data,
     *       uint256 value,
     *       uint256 deadline
     *     )
     *
     * @param target     the contract to call
     * @param data       the call data
     * @param value      the eth sent with call
     * @param deadline   the timestamp until which the operation remains valid
     * @param signatures the signatures authorizing the operation
     */
    function call(
        address          target,
        bytes calldata   data,
        uint256          value,
        uint256          deadline,
        bytes[] calldata signatures
    ) external;

    /**
     * Call another contract.
     *
     * Only a signer can call this.
     *
     * Requires the signatures of others to execute. Signatures must be sorted by signer address.
     *
     * Signatures must follow EIP-712 spec for the following data structure:
     *
     *     Multicall(
     *       address executor,
     *       uint256 nonce,
     *       Call[]  calls,
     *       uint256 deadline
     *     )
     *     Call(
     *       address target,
     *       bytes   data,
     *       uint256 value
     *     )
     *
     * @param calls      the calls to execute
     * @param deadline   the timestamp until which the operation remains valid
     * @param signatures the signatures authorizing the operation
     */
    function multicall(
        Call[] calldata  calls,
        uint256          deadline,
        bytes[] calldata signatures
    ) external;

    /**
     * Indicates if an address is a signer.
     *
     * @param  account  the account to check
     * @return isSigner true if the account is a signer
     */
    function signers(address account) external view returns (bool isSigner);

    /**
     * How many signatures are required for an action that requires authorization.
     *
     * The executor of the action is NOT counted as a signer.
     *
     * @return signaturesRequired the amount of signatures required
     */
    function signaturesRequired() external view returns (uint256 signaturesRequired);

    /**
     * The time that has to elapse for the execution of a scheduled action.
     *
     * @return executionDelay the time that has to elapse for the execution of a scheduled action
     */
    function executionDelay() external view returns (uint256 executionDelay);

    /**
     * The next nonce for the execution of any of the functions which require one.
     *
     * Nonces are sequential.
     *
     * @return nonce the nonce
     */
    function nonce() external view returns (uint256 nonce);

    /**
     * Scheduled fee change.
     *
     * @param  version the orderbook version of the scheduled fee change
     * @return fee     the scheduled fee change
     */
    function scheduledFee(uint32 version) external view returns (ScheduledFee memory fee);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import { IOrderbookDEXTeamTreasury } from "../interfaces/IOrderbookDEXTeamTreasury.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

library OrderbookDEXTeamTreasuryUtil {
    using Address for address;

    /**
     * Max fee.
     */
    uint256 constant MAX_FEE = 0.005 ether;

    /**
     * The current fee applied to orderbooks of a specific version.
     *
     * @param  treasury the Orderbook DEX Team Treasury
     * @param  version  the orderbook version
     * @return fee      the fee
     */
    function safeFee(IOrderbookDEXTeamTreasury treasury, uint32 version) internal view returns (uint256 fee) {
        if (!address(treasury).isContract()) {
            return 0;
        }
        try treasury.fee{ gas: 10000 }(version) returns (uint256 fee_) {
            if (fee_ > MAX_FEE) {
                fee = MAX_FEE;
            } else {
                fee = fee_;
            }
        } catch {
            fee = 0;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import { IOrderbookDEXTeamTreasury } from "./IOrderbookDEXTeamTreasury.sol";

/**
 * Orderbook exchange for a token pair.
 */
interface IOrderbook {
    /**
     * Claim collected fees.
     *
     * This can only be called by the Orderbook DEX Team Treasury contract.
     */
    function claimFees() external;

    /**
     * The orderbook version.
     *
     * From right to left, the first two digits is the patch version, the second two digits the minor version,
     * and the rest is the major version, for example the value 10203 corresponds to version 1.2.3.
     *
     * @return version the orderbook version
     */
    function version() external view returns (uint32 version);

    /**
     * The token being traded.
     *
     * @return tradedToken the token being traded
     */
    function tradedToken() external view returns (address tradedToken);

    /**
     * The token given in exchange and used for pricing.
     *
     * @return baseToken the token given in exchange and used for pricing
     */
    function baseToken() external view returns (address baseToken);

    /**
     * The size of a contract in tradedToken.
     *
     * @return contractSize the size of a contract in tradedToken
     */
    function contractSize() external view returns (uint256 contractSize);

    /**
     * The price tick in baseToken.
     *
     * All prices are multiples of this value.
     *
     * @return priceTick the price tick in baseToken
     */
    function priceTick() external view returns (uint256 priceTick);

    /**
     * The ask price in baseToken.
     *
     * @return askPrice the ask price in baseToken
     */
    function askPrice() external view returns (uint256 askPrice);

    /**
     * The bid price in baseToken.
     *
     * @return bidPrice the bid price in baseToken
     */
    function bidPrice() external view returns (uint256 bidPrice);

    /**
     * The next available sell price point.
     *
     * @param  price         an available sell price point
     * @return nextSellPrice the next available sell price point
     */
    function nextSellPrice(uint256 price) external view returns (uint256 nextSellPrice);

    /**
     * The next available buy price point.
     *
     * @param  price        an available buy price point
     * @return nextBuyPrice the next available buy price point
     */
    function nextBuyPrice(uint256 price) external view returns (uint256 nextBuyPrice);

    /**
     * The Orderbook DEX Treasury.
     *
     * @return treasury the Orderbook DEX Treasury
     */
    function treasury() external view returns (IOrderbookDEXTeamTreasury treasury);

    /**
     * The total collected fees that have not yet been claimed.
     *
     * @return collectedTradedToken the amount in traded token
     * @return collectedBaseToken   the amount in base token
     */
    function collectedFees() external view returns (uint256 collectedTradedToken, uint256 collectedBaseToken);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

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
        InvalidSignatureV // Deprecated in v4.8
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
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
            return toHexString(value, Math.log256(value) + 1);
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * Orderbook DEX Team Treasury.
 */
interface IOrderbookDEXTeamTreasury {
    /**
     * The current fee applied to orderbooks of a specific version.
     *
     * The fee is returned as a fixed point decimal value with 18 decimal digits in base 10 (same as ETH).
     *
     * This function should not use more than 10,000 gas. Failing to do so will be interpreted as the fee being 0.
     *
     * This function should not revert. Failing to do so will be interpreted as the fee being 0.
     *
     * The should not be higher than 0.005, if it is higher 0.005 will be used.
     *
     * @param  version the orderbook version
     * @return fee     the fee
     */
    function fee(uint32 version) external view returns (uint256 fee);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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