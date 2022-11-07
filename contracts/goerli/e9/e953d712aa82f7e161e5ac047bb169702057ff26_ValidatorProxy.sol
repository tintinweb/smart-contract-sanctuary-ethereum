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
import {IValidatorProxy} from "./interfaces/IValidatorProxy.sol";
import {IValidator} from "./interfaces/IValidator.sol";
import {OCR2Abstract} from "./OCR2Abstract.sol";
import {IERC165} from "openzeppelin-contracts/interfaces/IERC165.sol";

contract ValidatorProxy is IValidatorProxy, ConfirmedOwner {
    /// @notice This event is emitted whenever a new validator contract is added
    /// @param configDigest The config digest that was added
    /// @param validatorAddr The Validator contract address set for a config digest
    event ValidatorAdded(bytes32 configDigest, address validatorAddr);

    /// @notice Mapping between config digests and validators
    mapping(bytes32 => address) private s_validators;

    constructor() ConfirmedOwner(msg.sender) {}

    modifier onlyValidValidator(address validatorAddr) {
        _validateValidatorAddr(validatorAddr);
        _;
    }

    /// @inheritdoc IValidatorProxy
    /// @dev Contract skips checking whether or not the current validator
    /// is valid as it checks this before a new validator is set.
    function verify(bytes calldata chainlinkBlob)
        external
        override
        returns (bytes memory validatorResponse)
    {
        bytes32 configDigest;
        assembly {
            // The chainlinkBlob should always have the report context first,
            // which will have the config digest at the beginning.
            // First 4 calldata bytes is the function selector
            // Next 32 calldata bytes is the position to the blob argument
            // Next 32 calldata bytes is the length of the blob argument
            // The next 32 * 3 = 96 bytes is the report context so the next
            // 32 bytes is the config digest as it will always be first.
            // config digest position = 4 + 32 + 32 = 68
            configDigest := calldataload(0x44)
        }
        address validatorAddr = s_validators[configDigest];
        require(validatorAddr != address(0), "validator not found");
        IValidator validator = IValidator(validatorAddr);
        return validator.verify(chainlinkBlob, msg.sender);
    }

    /// @inheritdoc IValidatorProxy
    function addValidator(bytes32 configDigest, address validatorAddr)
        external
        override
        onlyOwner
        onlyValidValidator(validatorAddr)
    {
        require(configDigest != bytes32(""), "config digest not set");
        s_validators[configDigest] = validatorAddr;
        emit ValidatorAdded(configDigest, validatorAddr);
    }

    /// @inheritdoc IValidatorProxy
    function getValidator(bytes32 configDigest)
        external
        view
        override
        returns (address)
    {
        return s_validators[configDigest];
    }

    function _validateValidatorAddr(address validatorAddr) internal view {
        require(validatorAddr != address(0), "zero address");
        require(
            IERC165(validatorAddr).supportsInterface(
                IValidator.verify.selector
            ),
            "not validator"
        );
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IValidatorProxy {
    /**
     * @notice Verifies that the data encoded has been signed
     * correctly by routing to the correct validator.
     * @param chainlinkBlob The encoded data to be verified.
     * @return validatorResponse The encoded response from the validator.
     */
    function verify(bytes memory chainlinkBlob)
        external
        returns (bytes memory validatorResponse);

    /**
     * @notice Adds a new validator for a config digest
     * @param configDigest The config digest to set
     * @param validatorAddr The address of the valdiator contract that verifies
     * reports for a given config digest.
     */
    function addValidator(bytes32 configDigest, address validatorAddr) external;

    /**
     * @notice Retrieves the validator address that verifies reports
     * for a config digest.
     * @param configDigest The config digest to query for
     */
    function getValidator(bytes32 configDigest)
        external
        view
        returns (address validatorAddr);
}