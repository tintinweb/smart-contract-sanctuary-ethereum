// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract TypeAndVersionInterface {
  function typeAndVersion() external pure virtual returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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
pragma solidity ^0.8.0;

import {TypeAndVersionInterface} from "chainlink/contracts/src/v0.8/interfaces/TypeAndVersionInterface.sol";

abstract contract OCR2Abstract is TypeAndVersionInterface {
    // Maximum number of oracles the offchain reporting protocol is designed for
    uint256 internal constant maxNumOracles = 31;

    /**
     * @notice triggers a new run of the offchain reporting protocol
     * @param previousConfigBlockNumber block in which the previous config was set, to simplify historic analysis
     * @param configDigest configDigest of this configuration
     * @param configCount ordinal number of this config setting among all config settings over the life of this contract
     * @param signers ith element is address ith oracle uses to sign a report
     * @param transmitters ith element is address ith oracle uses to transmit a report via the transmit method
     * @param f maximum number of faulty/dishonest oracles the protocol can tolerate while still working correctly
     * @param onchainConfig serialized configuration used by the contract (and possibly oracles)
     * @param offchainConfigVersion version of the serialization format used for "offchainConfig" parameter
     * @param offchainConfig serialized configuration used by the oracles exclusively and only passed through the contract
     */
    event ConfigSet(
        uint32 previousConfigBlockNumber,
        bytes32 configDigest,
        uint64 configCount,
        address[] signers,
        address[] transmitters,
        uint8 f,
        bytes onchainConfig,
        uint64 offchainConfigVersion,
        bytes offchainConfig
    );

    /**
     * @notice sets offchain reporting protocol configuration incl. participating oracles
     * @param signers addresses with which oracles sign the reports
     * @param transmitters addresses oracles use to transmit the reports
     * @param f number of faulty oracles the system can tolerate
     * @param onchainConfig serialized configuration used by the contract (and possibly oracles)
     * @param offchainConfigVersion version number for offchainEncoding schema
     * @param offchainConfig serialized configuration used by the oracles exclusively and only passed through the contract
     */
    function setConfig(
        address[] memory signers,
        address[] memory transmitters,
        uint8 f,
        bytes memory onchainConfig,
        uint64 offchainConfigVersion,
        bytes memory offchainConfig
    ) external virtual;

    /**
     * @notice information about current offchain reporting protocol configuration
     * @return configCount ordinal number of current config, out of all configs applied to this contract so far
     * @return blockNumber block at which this config was set
     * @return configDigest domain-separation tag for current config (see _configDigestFromConfigData)
     */
    function latestConfigDetails()
        external
        view
        virtual
        returns (
            uint32 configCount,
            uint32 blockNumber,
            bytes32 configDigest
        );

    function _configDigestFromConfigData(
        uint256 chainId,
        address contractAddress,
        uint64 configCount,
        address[] memory signers,
        address[] memory transmitters,
        uint8 f,
        bytes memory onchainConfig,
        uint64 offchainConfigVersion,
        bytes memory offchainConfig
    ) internal pure returns (bytes32) {
        uint256 h = uint256(
            keccak256(
                abi.encode(
                    chainId,
                    contractAddress,
                    configCount,
                    signers,
                    transmitters,
                    f,
                    onchainConfig,
                    offchainConfigVersion,
                    offchainConfig
                )
            )
        );
        uint256 prefixMask = type(uint256).max << (256 - 16); // 0xFFFF00..00
        uint256 prefix = 0x0001 << (256 - 16); // 0x000100..00
        return bytes32((prefix & prefixMask) | (h & ~prefixMask));
    }

    /**
    * @notice optionally emited to indicate the latest configDigest and epoch for
     which a report was successfully transmited. Alternatively, the contract may
     use latestConfigDigestAndEpoch with scanLogs set to false.
  */
    event Transmitted(bytes32 configDigest, uint32 epoch);

    /**
     * @notice optionally returns the latest configDigest and epoch for which a
     report was successfully transmitted. Alternatively, the contract may return
     scanLogs set to true and use Transmitted events to provide this information
     to offchain watchers.
   * @return scanLogs indicates whether to rely on the configDigest and epoch
     returned or whether to scan logs for the Transmitted event instead.
   * @return configDigest
   * @return epoch
   */
    function latestConfigDigestAndEpoch()
        external
        view
        virtual
        returns (
            bool scanLogs,
            bytes32 configDigest,
            uint32 epoch
        );

    /**
     * @notice transmit is called to post a new report to the contract
     * @param report serialized report, which the signatures are signing.
     * @param rs ith element is the R components of the ith signature on report. Must have at most maxNumOracles entries
     * @param ss ith element is the S components of the ith signature on report. Must have at most maxNumOracles entries
     * @param rawVs ith element is the the V component of the ith signature
     */
    function transmit(
        // NOTE: If these parameters are changed, expectedMsgDataLength and/or
        // TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT need to be changed accordingly
        bytes32[3] calldata reportContext,
        bytes calldata report,
        bytes32[] calldata rs,
        bytes32[] calldata ss,
        bytes32 rawVs // signatures
    ) external virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ConfirmedOwner} from "chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import {OCR2Abstract} from "./OCR2Abstract.sol";
import {IValidator} from "./interfaces/IValidator.sol";
import {TypeAndVersionInterface} from "chainlink/contracts/src/v0.8/interfaces/TypeAndVersionInterface.sol";
import {IERC165} from "openzeppelin-contracts/interfaces/IERC165.sol";

/*
 * The validator contract is used to verify offchain reports signed
 * by DONs.  A report consists of a price, block number and feed Id.  It
 * represents the observed price of an asset at a specified block number for
 * a feed.  The validator contract is used to verify that such reports have
 * been signed by the correct signers.
 **/
contract Validator is IValidator, ConfirmedOwner, OCR2Abstract {
    // The first byte of the mask can be 0, because we only ever have 31 oracles
    uint256 internal constant ORACLE_MASK =
        0x0001010101010101010101010101010101010101010101010101010101010101;

    enum Role {
        // Default role for an oracle address.  This means that the oracle address
        // is not a signer
        Unset,
        // Role given to an oracle address that is allowed to sign feed data
        Signer
    }

    struct Oracle {
        // Index of oracle in a configuration
        uint8 index;
        // The oracle's role
        Role role;
    }

    struct Config {
        // Fault tolerance
        uint8 f;
        // Map of signer addresses to oracles
        mapping(address => Oracle) oracles;
    }

    struct ValidatorState {
        // The number of times a new configuration
        /// has been set
        uint32 numConfigsSet;
        // The block number of the block the last time
        /// the configuration was updated.
        uint32 latestConfigBlockNumber;
        // The latest epoch a report was verified for
        uint32 latestEpoch;
        // The latest digest of the configuration parameters
        bytes32 latestConfigDigest;
    }

    /// @notice This event is emitted when a new report is verified.
    /// It is used to keep a historical record of verified reports.
    event ReportVerified(bytes32 feedId, bytes32 reportHash, address requester);

    /// @notice The feed ID this validator validates reports for
    bytes32 private immutable i_feedId;

    /// @notice A historical record of all previously set
    /// configurations
    mapping(bytes32 => Config) internal s_verificationDataConfigs;

    /// @notice Holds the latest state of the validator
    ValidatorState private s_latestValidatorState;

    /// @param feedId The feed ID to identify this validator with
    constructor(bytes32 feedId) ConfirmedOwner(msg.sender) {
        require(feedId != bytes32(""), "empty feed ID");
        i_feedId = feedId;
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool isValidator)
    {
        return interfaceId == this.verify.selector;
    }

    /// @inheritdoc TypeAndVersionInterface
    function typeAndVersion() external pure override returns (string memory) {
        return "Validator 0.0.1";
    }

    /// @notice Returns the ID of the feed this validator contract verifies reports for
    /// @return feedId The ID of the feed this validator verifies reports for.  This
    /// Id must match the ID set in the node's job spec.
    function getFeedId() external view returns (bytes32 feedId) {
        return i_feedId;
    }

    /// @inheritdoc IValidator
    function verify(bytes calldata chainlinkBlob, address sender)
        external
        override
        returns (bytes memory response)
    {
        require(
            s_latestValidatorState.latestConfigDigest != bytes32(""),
            "configuration not set"
        );

        (
            bytes32[3] memory reportContext,
            bytes memory rawReport,
            bytes32[] memory rs,
            bytes32[] memory ss,
            bytes32 rawVs
        ) = abi.decode(
                chainlinkBlob,
                (bytes32[3], bytes, bytes32[], bytes32[], bytes32)
            );
        bytes32 feedId;
        assembly {
            // The feed ID is at the front of the report.
            // The first 32 bits of the report is the length of the report
            // so we skip over that to get the Feed ID from the next 32 bits.
            feedId := mload(add(rawReport, 0x20))
        }

        require(feedId == i_feedId, "report has an incorrect feedId");

        // reportContext consists of:
        // reportContext[0]: ConfigDigest
        // reportContext[1]: 27 byte padding, 4-byte epoch and 1-byte round
        // reportContext[2]: ExtraHash
        bytes32 configDigest = reportContext[0];
        require(
            s_verificationDataConfigs[configDigest].f > 0,
            "digest not set"
        );

        uint32 epochAndRound = uint32(uint256(reportContext[1]));

        uint32 epoch = uint32(epochAndRound >> 8);
        if (epoch > s_latestValidatorState.latestEpoch) {
            s_latestValidatorState.latestEpoch = epoch;
        }

        uint256 expectedNumSignatures = s_verificationDataConfigs[configDigest]
            .f + 1;
        require(
            rs.length == expectedNumSignatures,
            "wrong number of signatures"
        );
        require(rs.length == ss.length, "signatures out of registration");

        bytes32 hashedReport = keccak256(rawReport);

        _verifySignatures(
            hashedReport,
            reportContext,
            rs,
            ss,
            rawVs,
            configDigest
        );
        emit ReportVerified(feedId, hashedReport, sender);
        return rawReport;
    }

    /**
     * @notice Verififies that a report has been signed by the correct
     * signers and that enough signers have signed the reports.
     * @param hashedReport The keccak256 hash of the raw report's bytes
     * @param reportContext The context the report was signed in
     * @param rs ith element is the R components of the ith signature on report. Must have at most maxNumOracles entries
     * @param ss ith element is the S components of the ith signature on report. Must have at most maxNumOracles entries
     * @param rawVs ith element is the the V component of the ith signature
     ** @param configDigest The config digest the report was signed for
     **/
    function _verifySignatures(
        bytes32 hashedReport,
        bytes32[3] memory reportContext,
        bytes32[] memory rs,
        bytes32[] memory ss,
        bytes32 rawVs,
        bytes32 configDigest
    ) private view {
        bytes32 h = keccak256(abi.encodePacked(hashedReport, reportContext));
        // i-th byte counts number of sigs made by i-th signer
        uint256 signedCount;

        Oracle memory o;
        Config storage config = s_verificationDataConfigs[configDigest];
        address signerAddress;
        for (uint256 i = 0; i < rs.length; i++) {
            signerAddress = ecrecover(h, uint8(rawVs[i]) + 27, rs[i], ss[i]);
            o = config.oracles[signerAddress];
            require(o.role == Role.Signer, "address not authorized to sign");
            unchecked {
                signedCount += 1 << (8 * o.index);
            }
        }

        require(
            signedCount & ORACLE_MASK == signedCount,
            "non-unique signature"
        );
    }

    //***************************//
    // Repurposed OCR2 Functions //
    //***************************//

    // Reverts transaction if config args are invalid
    modifier checkConfigValid(uint256 numSigners, uint256 f) {
        require(f > 0, "f must be positive");
        require(numSigners > 3 * f, "faulty-oracle f too high");
        _;
    }

    /// @inheritdoc OCR2Abstract
    /// @dev transmitters parameter not used but is required to conform to the
    /// OCR2Abstract abstract contract.
    function setConfig(
        address[] memory signers,
        address[] memory transmitters,
        uint8 f,
        bytes memory onchainConfig,
        uint64 offchainConfigVersion,
        bytes memory offchainConfig
    ) external override checkConfigValid(signers.length, f) onlyOwner {
        bytes32 configDigest = _configDigestFromConfigData(
            block.chainid,
            address(this),
            s_latestValidatorState.numConfigsSet,
            signers,
            transmitters,
            f,
            onchainConfig,
            offchainConfigVersion,
            offchainConfig
        );

        s_verificationDataConfigs[configDigest].f = f;
        for (uint8 i; i < signers.length; i++) {
            address signerAddr = signers[i];
            require(signerAddr != address(0), "zero address signer");
            require(
                s_verificationDataConfigs[configDigest]
                    .oracles[signerAddr]
                    .role == Role.Unset,
                "duplicate signers"
            );
            s_verificationDataConfigs[configDigest].oracles[
                signerAddr
            ] = Oracle({role: Role.Signer, index: i});
        }

        emit ConfigSet(
            s_latestValidatorState.latestConfigBlockNumber,
            configDigest,
            s_latestValidatorState.numConfigsSet,
            signers,
            transmitters,
            f,
            onchainConfig,
            offchainConfigVersion,
            offchainConfig
        );

        s_latestValidatorState.latestConfigBlockNumber = uint32(block.number);
        s_latestValidatorState.numConfigsSet++;
        s_latestValidatorState.latestConfigDigest = configDigest;
    }

    /// @inheritdoc OCR2Abstract
    function latestConfigDigestAndEpoch()
        external
        view
        override
        returns (
            bool scanLogs,
            bytes32 configDigest,
            uint32 epoch
        )
    {
        return (
            false,
            s_latestValidatorState.latestConfigDigest,
            s_latestValidatorState.latestEpoch
        );
    }

    /// @inheritdoc OCR2Abstract
    function latestConfigDetails()
        external
        view
        override
        returns (
            uint32 configCount,
            uint32 blockNumber,
            bytes32 configDigest
        )
    {
        return (
            s_latestValidatorState.numConfigsSet,
            s_latestValidatorState.latestConfigBlockNumber,
            s_latestValidatorState.latestConfigDigest
        );
    }

    /// @inheritdoc OCR2Abstract
    /// @dev This function does not do anything but is required to conform to the OCR2Abstract contract.
    function transmit(
        // NOTE: If these parameters are changed, expectedMsgDataLength and/or
        // TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT need to be changed accordingly
        bytes32[3] calldata, /**reportContext**/
        bytes calldata, /**report**/
        bytes32[] calldata, /**rs**/
        bytes32[] calldata, /**ss**/
        bytes32 /**rawVs**/ // signatures
    ) external pure override {
        revert("transmit function disabled");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC165} from "openzeppelin-contracts/interfaces/IERC165.sol";

interface IValidator is IERC165 {
    /**
     * @notice Verifies that the data encoded has been signed
     * correctly by routing to the correct validator.
     * @param chainlinkBlob The encoded data to be verified.
     * @param requester The original address that requested to verify the contract.
     * This is only used for logging purposes.
     * @dev Verification is typically only done through the proxy contract so
     * we can't just use msg.sender to log the requester as the msg.sender
     * contract will always be the proxy.
     * @return response The encoded verified response.
     */
    function verify(bytes memory chainlinkBlob, address requester)
        external
        returns (bytes memory response);
}