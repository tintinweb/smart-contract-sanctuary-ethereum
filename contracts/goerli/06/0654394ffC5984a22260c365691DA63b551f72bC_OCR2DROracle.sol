// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./interfaces/OCR2DRClientInterface.sol";
import "./interfaces/OCR2DROracleInterface.sol";
import "../ocr2/OCR2Base.sol";

/**
 * @title OCR2DR oracle contract
 * @dev THIS CONTRACT HAS NOT GONE THROUGH ANY SECURITY REVIEW. DO NOT USE IN PROD.
 */
contract OCR2DROracle is OCR2DROracleInterface, OCR2Base {
    event OracleRequest(bytes32 requestId, bytes data);
    event OracleResponse(bytes32 requestId);
    event UserCallbackError(bytes32 requestId, string reason);
    event UserCallbackRawError(bytes32 requestId, bytes lowLevelData);

    error EmptyRequestData();
    error InconsistentReportData();
    error EmptyPublicKey();
    error EmptyBillingRegistry();
    error InvalidRequestID();
    error InvalidSender();

    bytes private s_donPublicKey;
    OCR2DRRegistryInterface private s_registry;
    mapping(address => bool) public s_senders;

    constructor() OCR2Base(true) {}

    function addSender(address addr) external onlyOwner() {
        s_senders[addr] = true;
    }

    /**
     * @notice The type and version of this contract
     * @return Type and version string
     */
    function typeAndVersion() external pure override returns (string memory) {
        return "OCR2DROracle 0.0.0";
    }

    /**
     * @inheritdoc OCR2DROracleInterface
     */
    function getRegistry() external view override returns (address) {
        return address(s_registry);
    }

    /**
     * @inheritdoc OCR2DROracleInterface
     */
    function setRegistry(address registryAddress) external override onlyOwner {
        if (registryAddress == address(0)) {
            revert EmptyBillingRegistry();
        }
        s_registry = OCR2DRRegistryInterface(registryAddress);
    }

    /**
     * @inheritdoc OCR2DROracleInterface
     */
    function getDONPublicKey() external view override returns (bytes memory) {
        return s_donPublicKey;
    }

    /**
     * @inheritdoc OCR2DROracleInterface
     */
    function setDONPublicKey(bytes calldata donPublicKey)
        external
        override
        onlyOwner
    {
        if (donPublicKey.length == 0) {
            revert EmptyPublicKey();
        }
        s_donPublicKey = donPublicKey;
    }

    /**
     * @inheritdoc OCR2DROracleInterface
     */
    function getRequiredFee(
        bytes calldata, /* data */
        OCR2DRRegistryInterface.RequestBilling memory /* billing */
    ) public pure override returns (uint96) {
        // NOTE: Optionally, compute additional fee split between oracles here
        // e.g. 0.1 LINK * s_transmitters.length
        return 0;
    }

    /**
     * @inheritdoc OCR2DROracleInterface
     */
    function estimateCost(
        uint64 subscriptionId,
        bytes calldata data,
        uint32 gasLimit
    ) external view override registryIsSet returns (uint96) {
        OCR2DRRegistryInterface.RequestBilling
            memory billing = OCR2DRRegistryInterface.RequestBilling(
                subscriptionId,
                msg.sender,
                gasLimit
            );
        uint96 requiredFee = getRequiredFee(data, billing);
        return s_registry.estimateCost(data, billing, requiredFee);
    }

    /**
     * @inheritdoc OCR2DROracleInterface
     */
    function sendRequest(
        uint64 subscriptionId,
        bytes calldata data,
        uint32 gasLimit
    ) external override registryIsSet returns (bytes32) {
        if (!s_senders[tx.origin]) {
        revert InvalidSender();
        }
        if (data.length == 0) {
            revert EmptyRequestData();
        }
        bytes32 requestId = s_registry.startBilling(
            data,
            OCR2DRRegistryInterface.RequestBilling(
                subscriptionId,
                msg.sender,
                gasLimit
            )
        );
        emit OracleRequest(requestId, data);
        return requestId;
    }

    function _beforeSetConfig(uint8 _f, bytes memory _onchainConfig)
        internal
        override
    {}

    function _afterSetConfig(uint8 _f, bytes memory _onchainConfig)
        internal
        override
    {}

    function _validateReport(
        bytes32, /* configDigest */
        uint40, /* epochAndRound */
        bytes memory /* report */
    ) internal pure override returns (bool) {
        // validate within _report to save gas
        return true;
    }

    function _report(
        uint256 initialGas,
        address transmitter,
        uint8 signerCount,
        address[maxNumOracles] memory signers,
        bytes calldata report
    ) internal override registryIsSet {
        bytes32[] memory requestIds;
        bytes[] memory results;
        bytes[] memory errors;
        (requestIds, results, errors) = abi.decode(
            report,
            (bytes32[], bytes[], bytes[])
        );
        if (
            requestIds.length != results.length &&
            requestIds.length != errors.length
        ) {
            revert ReportInvalid();
        }

        uint256 reportValidationGasShare = (initialGas - gasleft()) /
            signerCount;

        for (uint256 i = 0; i < requestIds.length; i++) {
            try
                s_registry.fulfillAndBill(
                    requestIds[i],
                    results[i],
                    errors[i],
                    transmitter,
                    signers,
                    signerCount,
                    reportValidationGasShare,
                    gasleft()
                )
            returns (bool success) {
                if (success) {
                    emit OracleResponse(requestIds[i]);
                } else {
                    emit UserCallbackError(requestIds[i], "error in callback");
                }
            } catch (bytes memory reason) {
                emit UserCallbackRawError(requestIds[i], reason);
            }
        }
    }

    /**
     * @dev Reverts if the the registry is not set
     */
    modifier registryIsSet() {
        if (address(s_registry) == address(0)) {
            revert EmptyBillingRegistry();
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/dev/ocr2/OCR2Abstract.sol";

/**
 * @notice Onchain verification of reports from the offchain reporting protocol
 * @dev THIS CONTRACT HAS NOT GONE THROUGH ANY SECURITY REVIEW. DO NOT USE IN PROD.
 * @dev For details on its operation, see the offchain reporting protocol design
 * doc, which refers to this contract as simply the "contract".
 * @dev This contract is meant to aid rapid development of new applications based on OCR2.
 * However, for actual production contracts, it is expected that most of the logic of this contract
 * will be folded directly into the application contract. Inheritance prevents us from doing lots
 * of juicy storage layout optimizations, leading to a substantial increase in gas cost.
 */
abstract contract OCR2Base is ConfirmedOwner, OCR2Abstract {
    error ReportInvalid();

    bool internal immutable i_uniqueReports;

    constructor(bool uniqueReports) ConfirmedOwner(msg.sender) {
        i_uniqueReports = uniqueReports;
    }

    uint256 private constant maxUint32 = (1 << 32) - 1;

    // Storing these fields used on the hot path in a ConfigInfo variable reduces the
    // retrieval of all of them to a single SLOAD. If any further fields are
    // added, make sure that storage of the struct still takes at most 32 bytes.
    struct ConfigInfo {
        bytes32 latestConfigDigest;
        uint8 f; // TODO: could be optimized by squeezing into one slot
        uint8 n;
    }
    ConfigInfo internal s_configInfo;

    // incremented each time a new config is posted. This count is incorporated
    // into the config digest, to prevent replay attacks.
    uint32 internal s_configCount;
    uint32 internal s_latestConfigBlockNumber; // makes it easier for offchain systems
    // to extract config from logs.

    // Used for s_oracles[a].role, where a is an address, to track the purpose
    // of the address, or to indicate that the address is unset.
    enum Role {
        // No oracle role has been set for address a
        Unset,
        // Signing address for the s_oracles[a].index'th oracle. I.e., report
        // signatures from this oracle should ecrecover back to address a.
        Signer,
        // Transmission address for the s_oracles[a].index'th oracle. I.e., if a
        // report is received by OCR2Aggregator.transmit in which msg.sender is
        // a, it is attributed to the s_oracles[a].index'th oracle.
        Transmitter
    }

    struct Oracle {
        uint8 index; // Index of oracle in s_signers/s_transmitters
        Role role; // Role of the address which mapped to this struct
    }

    mapping(address => Oracle) /* signer OR transmitter address */
        internal s_oracles;

    // s_signers contains the signing address of each oracle
    address[] internal s_signers;

    // s_transmitters contains the transmission address of each oracle,
    // i.e. the address the oracle actually sends transactions to the contract from
    address[] internal s_transmitters;

    /*
     * Config logic
     */

    // Reverts transaction if config args are invalid
    modifier checkConfigValid(
        uint256 _numSigners,
        uint256 _numTransmitters,
        uint256 _f
    ) {
        require(_numSigners <= maxNumOracles, "too many signers");
        require(_f > 0, "f must be positive");
        require(
            _numSigners == _numTransmitters,
            "oracle addresses out of registration"
        );
        require(_numSigners > 3 * _f, "faulty-oracle f too high");
        _;
    }

    struct SetConfigArgs {
        address[] signers;
        address[] transmitters;
        uint8 f;
        bytes onchainConfig;
        uint64 offchainConfigVersion;
        bytes offchainConfig;
    }

    /// @inheritdoc OCR2Abstract
    function latestConfigDigestAndEpoch()
        external
        view
        virtual
        override
        returns (
            bool scanLogs,
            bytes32 configDigest,
            uint32 epoch
        )
    {
        return (true, bytes32(0), uint32(0));
    }

    /**
     * @notice sets offchain reporting protocol configuration incl. participating oracles
     * @param _signers addresses with which oracles sign the reports
     * @param _transmitters addresses oracles use to transmit the reports
     * @param _f number of faulty oracles the system can tolerate
     * @param _onchainConfig encoded on-chain contract configuration
     * @param _offchainConfigVersion version number for offchainEncoding schema
     * @param _offchainConfig encoded off-chain oracle configuration
     */
    function setConfig(
        address[] memory _signers,
        address[] memory _transmitters,
        uint8 _f,
        bytes memory _onchainConfig,
        uint64 _offchainConfigVersion,
        bytes memory _offchainConfig
    )
        external
        override
        checkConfigValid(_signers.length, _transmitters.length, _f)
        onlyOwner
    {
        SetConfigArgs memory args = SetConfigArgs({
            signers: _signers,
            transmitters: _transmitters,
            f: _f,
            onchainConfig: _onchainConfig,
            offchainConfigVersion: _offchainConfigVersion,
            offchainConfig: _offchainConfig
        });

        _beforeSetConfig(args.f, args.onchainConfig);

        while (s_signers.length != 0) {
            // remove any old signer/transmitter addresses
            uint256 lastIdx = s_signers.length - 1;
            address signer = s_signers[lastIdx];
            address transmitter = s_transmitters[lastIdx];
            delete s_oracles[signer];
            delete s_oracles[transmitter];
            s_signers.pop();
            s_transmitters.pop();
        }

        for (uint256 i = 0; i < args.signers.length; ++i) {
            // add new signer/transmitter addresses
            require(
                s_oracles[args.signers[i]].role == Role.Unset,
                "repeated signer address"
            );
            s_oracles[args.signers[i]] = Oracle(uint8(i), Role.Signer);
            require(
                s_oracles[args.transmitters[i]].role == Role.Unset,
                "repeated transmitter address"
            );
            s_oracles[args.transmitters[i]] = Oracle(
                uint8(i),
                Role.Transmitter
            );
            s_signers.push(args.signers[i]);
            s_transmitters.push(args.transmitters[i]);
        }
        s_configInfo.f = args.f;
        uint32 previousConfigBlockNumber = s_latestConfigBlockNumber;
        s_latestConfigBlockNumber = uint32(block.number);
        s_configCount += 1;
        {
            s_configInfo.latestConfigDigest = configDigestFromConfigData(
                block.chainid,
                address(this),
                s_configCount,
                args.signers,
                args.transmitters,
                args.f,
                args.onchainConfig,
                args.offchainConfigVersion,
                args.offchainConfig
            );
        }
        s_configInfo.n = uint8(args.signers.length);

        emit ConfigSet(
            previousConfigBlockNumber,
            s_configInfo.latestConfigDigest,
            s_configCount,
            args.signers,
            args.transmitters,
            args.f,
            args.onchainConfig,
            args.offchainConfigVersion,
            args.offchainConfig
        );

        _afterSetConfig(args.f, args.onchainConfig);
    }

    function configDigestFromConfigData(
        uint256 _chainId,
        address _contractAddress,
        uint64 _configCount,
        address[] memory _signers,
        address[] memory _transmitters,
        uint8 _f,
        bytes memory _onchainConfig,
        uint64 _encodedConfigVersion,
        bytes memory _encodedConfig
    ) internal pure returns (bytes32) {
        uint256 h = uint256(
            keccak256(
                abi.encode(
                    _chainId,
                    _contractAddress,
                    _configCount,
                    _signers,
                    _transmitters,
                    _f,
                    _onchainConfig,
                    _encodedConfigVersion,
                    _encodedConfig
                )
            )
        );
        uint256 prefixMask = type(uint256).max << (256 - 16); // 0xFFFF00..00
        uint256 prefix = 0x0001 << (256 - 16); // 0x000100..00
        return bytes32((prefix & prefixMask) | (h & ~prefixMask));
    }

    /**
     * @notice information about current offchain reporting protocol configuration
     * @return configCount ordinal number of current config, out of all configs applied to this contract so far
     * @return blockNumber block at which this config was set
     * @return configDigest domain-separation tag for current config (see configDigestFromConfigData)
     */
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
            s_configCount,
            s_latestConfigBlockNumber,
            s_configInfo.latestConfigDigest
        );
    }

    /**
     * @return list of addresses permitted to transmit reports to this contract
     * @dev The list will match the order used to specify the transmitter during setConfig
     */
    function transmitters() external view returns (address[] memory) {
        return s_transmitters;
    }

    function _beforeSetConfig(uint8 _f, bytes memory _onchainConfig)
        internal
        virtual;

    function _afterSetConfig(uint8 _f, bytes memory _onchainConfig)
        internal
        virtual;

    /**
     * @dev hook to allow additional validation of the report by the extending contract
     * @param configDigest separation tag for current config (see configDigestFromConfigData)
     * @param epochAndRound 27 byte padding, 4-byte epoch and 1-byte round
     * @param report serialized report
     */
    function _validateReport(
        bytes32 configDigest,
        uint40 epochAndRound,
        bytes memory report
    ) internal virtual returns (bool);

    /**
     * @dev hook called after the report has been fully validated
     * for the extending contract to handle additional logic, such as oracle payment
     * @param initialGas the amount of gas before validation
     * @param transmitter the address of the account that submitted the report
     * @param signers the addresses of all signing accounts
     * @param report serialized report
     */
    function _report(
        uint256 initialGas,
        address transmitter,
        uint8 signerCount,
        address[maxNumOracles] memory signers,
        bytes calldata report
    ) internal virtual;

    // The constant-length components of the msg.data sent to transmit.
    // See the "If we wanted to call sam" example on for example reasoning
    // https://solidity.readthedocs.io/en/v0.7.2/abi-spec.html
    uint16 private constant TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT =
        4 + // function selector
            32 *
            3 + // 3 words containing reportContext
            32 + // word containing start location of abiencoded report value
            32 + // word containing location start of abiencoded rs value
            32 + // word containing start location of abiencoded ss value
            32 + // rawVs value
            32 + // word containing length of report
            32 + // word containing length rs
            32 + // word containing length of ss
            0; // placeholder

    function requireExpectedMsgDataLength(
        bytes calldata report,
        bytes32[] calldata rs,
        bytes32[] calldata ss
    ) private pure {
        // calldata will never be big enough to make this overflow
        uint256 expected = uint256(TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT) +
            report.length + // one byte pure entry in _report
            rs.length *
            32 + // 32 bytes per entry in _rs
            ss.length *
            32 + // 32 bytes per entry in _ss
            0; // placeholder
        require(msg.data.length == expected, "calldata length mismatch");
    }

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
    ) external override {
        uint256 initialGas = gasleft(); // This line must come first

        {
            // reportContext consists of:
            // reportContext[0]: ConfigDigest
            // reportContext[1]: 27 byte padding, 4-byte epoch and 1-byte round
            // reportContext[2]: ExtraHash
            bytes32 configDigest = reportContext[0];
            uint32 epochAndRound = uint32(uint256(reportContext[1]));

            if (!_validateReport(configDigest, epochAndRound, report)) {
                revert ReportInvalid();
            }

            emit Transmitted(configDigest, uint32(epochAndRound >> 8));

            ConfigInfo memory configInfo = s_configInfo;
            require(
                configInfo.latestConfigDigest == configDigest,
                "configDigest mismatch"
            );

            requireExpectedMsgDataLength(report, rs, ss);

            uint256 expectedNumSignatures;
            if (i_uniqueReports) {
                expectedNumSignatures = (configInfo.n + configInfo.f) / 2 + 1;
            } else {
                expectedNumSignatures = configInfo.f + 1;
            }

            require(
                rs.length == expectedNumSignatures,
                "wrong number of signatures"
            );
            require(rs.length == ss.length, "signatures out of registration");

            Oracle memory transmitter = s_oracles[msg.sender];
            require( // Check that sender is authorized to report
                transmitter.role == Role.Transmitter &&
                    msg.sender == s_transmitters[transmitter.index],
                "unauthorized transmitter"
            );
        }

        address[maxNumOracles] memory signed;
        uint8 signerCount = 0;

        {
            // Verify signatures attached to report
            bytes32 h = keccak256(
                abi.encodePacked(keccak256(report), reportContext)
            );

            Oracle memory o;
            for (uint256 i = 0; i < rs.length; ++i) {
                address signer = ecrecover(
                    h,
                    uint8(rawVs[i]) + 27,
                    rs[i],
                    ss[i]
                );
                o = s_oracles[signer];
                require(
                    o.role == Role.Signer,
                    "address not authorized to sign"
                );
                require(signed[o.index] == address(0), "non-unique signature");
                signed[o.index] = signer;
                signerCount += 1;
            }
        }

        _report(initialGas, msg.sender, signerCount, signed, report);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./OCR2DRRegistryInterface.sol";

/**
 * @title OCR2DR oracle interface.
 */
interface OCR2DROracleInterface {
    /**
     * @notice Gets the stored billing registry address
     * @return registryAddress The address of OCR2DR billing registry contract
     */
    function getRegistry() external view returns (address);

    /**
     * @notice Sets the stored billing registry address
     * @param registryAddress The address of OCR2DR billing registry contract
     */
    function setRegistry(address registryAddress) external;

    /**
     * @notice Returns DON secp256k1 public key used to encrypt secrets
     * @dev All Oracles nodes have the corresponding private key
     * needed to decrypt the secrets encrypted with the public key
     * @return publicKey DON's public key
     */
    function getDONPublicKey() external view returns (bytes memory);

    /**
     * @notice Sets DON secp256k1 public key used to encrypt secrets
     * @dev Used to rotate the key
     * @param donPublicKey New public key
     */
    function setDONPublicKey(bytes calldata donPublicKey) external;

    /**
     * @notice Determine the fee charged by the DON that will be split between signing Node Operators for servicing the request
     * @param data Encoded OCR2DR request data, use OCR2DRClient API to encode a request
     * @param billing The request's billing configuration
     * @return fee Cost in Juels (1e18) of LINK
     */
    function getRequiredFee(
        bytes calldata data,
        OCR2DRRegistryInterface.RequestBilling calldata billing
    ) external view returns (uint96);

    /**
     * @notice Estimate the total cost that will be charged to a subscription to make a request: gas re-imbursement, plus DON fee, plus Registry fee
     * @param subscriptionId A unique subscription ID allocated by billing system,
     * a client can make requests from different contracts referencing the same subscription
     * @param data Encoded OCR2DR request data, use OCR2DRClient API to encode a request
     * @param gasLimit Gas limit for the fulfillment callback
     * @return billedCost Cost in Juels (1e18) of LINK
     */
    function estimateCost(
        uint64 subscriptionId,
        bytes calldata data,
        uint32 gasLimit
    ) external view returns (uint96);

    /**
     * @notice Sends a request (encoded as data) using the provided subscriptionId
     * @param subscriptionId A unique subscription ID allocated by billing system,
     * a client can make requests from different contracts referencing the same subscription
     * @param data Encoded OCR2DR request data, use OCR2DRClient API to encode a request
     * @param gasLimit Gas limit for the fulfillment callback
     * @return requestId A unique request identifier (unique per oracle)
     */
    function sendRequest(
        uint64 subscriptionId,
        bytes calldata data,
        uint32 gasLimit
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/**
 * @title OCR2DR client interface.
 */
interface OCR2DRClientInterface {
    /**
     * @notice Returns DON secp256k1 public key used to encrypt secrets
     * @dev All Oracles nodes have the corresponding private key
     * needed to decrypt the secrets encrypted with the public key
     * @return publicKey DON's public key
     */
    function getDONPublicKey() external view returns (bytes memory);

    /**
     * @notice OCR2DR response handler called by the designated oracle.
     * @param requestId The requestId returned by OCR2DRClient.sendRequest().
     * @param response Aggregated response from the user code.
     * @param err Aggregated error either from the user code or from the execution pipeline.
     * Either response or error parameter will be set, but never both.
     */
    function handleOracleFulfillment(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) external;
}

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

import "../../interfaces/TypeAndVersionInterface.sol";

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
pragma solidity ^0.8.6;

/**
 * @title OCR2DR billing subscription registry interface.
 */
interface OCR2DRRegistryInterface {
    struct RequestBilling {
        // a unique subscription ID allocated by billing system,
        uint64 subscriptionId;
        // the client contract that initiated the request to the DON
        // to use the subscription it must be added as a consumer on the subscription
        address client;
        // customer specified gas limit for the fulfillment callback
        uint32 gasLimit;
    }

    /**
     * @notice Get configuration relevant for making requests
     * @return uint32 global max for request gas limit
     * @return address[] list of registered DONs
     */
    function getRequestConfig()
        external
        view
        returns (uint32, address[] memory);

    /**
     * @notice Determine the charged fee that will be paid to the Registry owner
     * @param data Encoded OCR2DR request data, use OCR2DRClient API to encode a request
     * @param billing The request's billing configuration
     * @return fee Cost in Juels (1e18) of LINK
     */
    function getRequiredFee(
        bytes calldata data,
        OCR2DRRegistryInterface.RequestBilling memory billing
    ) external view returns (uint96);

    /**
     * @notice Estimate the total cost to make a request: gas re-imbursement, plus DON fee, plus Registry fee
     * @param data Encoded OCR2DR request data, use OCR2DRClient API to encode a request
     * @param billing The request's billing configuration
     * @param donRequiredFee Fee charged by the DON that is paid to Oracle Node
     * @return billedCost Cost in Juels (1e18) of LINK
     */
    function estimateCost(
        bytes calldata data,
        OCR2DRRegistryInterface.RequestBilling memory billing,
        uint96 donRequiredFee
    ) external view returns (uint96);

    /**
     * @notice Initiate the billing process for an OCR2DR request
     * @param data Encoded OCR2DR request data, use OCR2DRClient API to encode a request
     * @param billing Billing configuration for the request
     * @return requestId - A unique identifier of the request. Can be used to match a request to a response in fulfillRequest.
     * @dev Only callable by an OCR2DROracle that has been approved on the Registry
     */
    function startBilling(bytes calldata data, RequestBilling calldata billing)
        external
        returns (bytes32);

    /**
     * @notice Finalize billing process for an OCR2DR request by sending a callback to the Client contract and then charging the subscription
     * @param requestId identifier for the request that was generated by the Registry in the beginBilling commitment
     * @param response response data from DON consensus
     * @param err error from DON consensus
     * @param transmitter the Oracle who sent the report
     * @param signers the Oracles who had a part in generating the report
     * @param signerCount the number of signers on the report
     * @param reportValidationGas the amount of gas used for the report validation. Cost is split by all fulfillments on the report.
     * @param initialGas the initial amount of gas that should be used as a baseline to charge the single fulfillment for execution cost
     * @return success whether the callback was successsful
     * @dev Only callable by OCR2DROracles that have been approved on the Registry
     * @dev simulated offchain to determine if sufficient balance is present to fulfill the request
     */
    function fulfillAndBill(
        bytes32 requestId,
        bytes calldata response,
        bytes calldata err,
        address transmitter,
        address[31] memory signers, // 31 comes from OCR2Abstract.sol's maxNumOracles constant
        uint8 signerCount,
        uint256 reportValidationGas,
        uint256 initialGas
    ) external returns (bool success);
}