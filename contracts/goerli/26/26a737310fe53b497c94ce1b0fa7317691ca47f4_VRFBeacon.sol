// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VRFBeaconOCR} from "./VRFBeaconOCR.sol";
import {VRFBeaconDKGClient, DKG} from "./VRFBeaconDKGClient.sol";
import {IVRFCoordinatorProducerAPI} from "./IVRFCoordinatorProducerAPI.sol";
import {LinkTokenInterface} from "./vendor/ocr2-contracts/interfaces/LinkTokenInterface.sol";

contract VRFBeacon is VRFBeaconOCR, VRFBeaconDKGClient {
    /// @param link address of the link token
    /// @param coordinator address of VRF contract
    /// @param keyProvider address of the DKG contract
    /// @param keyID identifier of the distributed key used for the VRF
    constructor(
        LinkTokenInterface link,
        IVRFCoordinatorProducerAPI coordinator,
        DKG keyProvider,
        bytes32 keyID
    ) VRFBeaconOCR(link, coordinator) VRFBeaconDKGClient(keyProvider, keyID) {}
}

/* XXX: Could the DKG key chain workflow be used to malleate the VRF output? */

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VRFBeaconReport} from "./VRFBeaconReport.sol";
import {OwnerIsCreator} from "./vendor/ocr2-contracts/OwnerIsCreator.sol";
import {LinkTokenInterface} from "./vendor/ocr2-contracts/interfaces/LinkTokenInterface.sol";
import {AccessControllerInterface} from "./vendor/ocr2-contracts/interfaces/AccessControllerInterface.sol";
import {LinkTokenInterface} from "./vendor/ocr2-contracts/interfaces/LinkTokenInterface.sol";
import {IVRFCoordinatorProducerAPI} from "./IVRFCoordinatorProducerAPI.sol";
import {ChainSpecificUtil} from "./ChainSpecificUtil.sol";

/// @title Container for OCR functionality ancillary to VRF service
/// @dev Changes to OCR protocol should probably be reflected here
contract VRFBeaconOCR is VRFBeaconReport {
    /// @param link address of the LINK contract
    /// @param coordinator address of the VRF coordinator contract
    constructor(LinkTokenInterface link, IVRFCoordinatorProducerAPI coordinator)
        VRFBeaconReport(link, coordinator)
    {}

    struct SetConfigArgs {
        address[] signers;
        address[] transmitters;
        uint8 f;
        bytes onchainConfig;
        uint64 offchainConfigVersion;
        bytes offchainConfig;
    }

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
        address[] calldata signers,
        address[] calldata transmitters,
        uint8 f,
        bytes calldata onchainConfig,
        uint64 offchainConfigVersion,
        bytes calldata offchainConfig
    ) external onlyOwner {
        require(signers.length <= maxNumOracles, "too many oracles");
        require(
            signers.length == transmitters.length,
            "oracle length mismatch"
        );
        require(3 * f < signers.length, "faulty-oracle f too high");
        _requirePositiveF(f);

        SetConfigArgs memory args = SetConfigArgs({
            signers: signers,
            transmitters: transmitters,
            f: f,
            onchainConfig: onchainConfig, /*version*/
            offchainConfigVersion: offchainConfigVersion,
            offchainConfig: offchainConfig
        });

        s_hotVars.latestEpochAndRound = 0;
        _payOracles();

        // remove any old signer/transmitter addresses
        uint256 oldLength = s_signersList.length;
        for (uint256 i = 0; i < oldLength; i++) {
            address signer = s_signersList[i];
            address transmitter = s_transmittersList[i];
            delete s_signers[signer];
            delete s_transmitters[transmitter];
        }
        delete s_signersList;
        delete s_transmittersList;

        // add new signer/transmitter addresses
        for (uint256 i = 0; i < args.signers.length; i++) {
            require(
                !s_signers[args.signers[i]].active,
                "repeated signer address"
            );
            s_signers[args.signers[i]] = Signer({
                active: true,
                index: uint8(i)
            });
            require(
                !s_transmitters[args.transmitters[i]].active,
                "repeated transmitter address"
            );
            s_transmitters[args.transmitters[i]] = Transmitter({
                active: true,
                index: uint8(i),
                paymentJuels: 0
            });
        }
        s_signersList = args.signers;
        s_transmittersList = args.transmitters;

        s_hotVars.f = args.f;
        uint32 previousConfigBlockNumber = s_latestConfigBlockNumber;
        s_latestConfigBlockNumber = uint32(ChainSpecificUtil.getBlockNumber());
        uint32 configCount = s_configCount + 1;
        s_configCount = configCount;
        bytes32 latestConfigDigest = _configDigestFromConfigData(
            block.chainid,
            address(this),
            configCount,
            args.signers,
            args.transmitters,
            args.f,
            args.onchainConfig,
            args.offchainConfigVersion,
            args.offchainConfig
        );
        s_configInfo.latestConfigDigest = latestConfigDigest;
        emit ConfigSet(
            previousConfigBlockNumber,
            latestConfigDigest,
            configCount,
            args.signers,
            args.transmitters,
            args.f,
            args.onchainConfig,
            args.offchainConfigVersion,
            args.offchainConfig
        );

        uint32 latestAggregatorRoundId = s_hotVars.latestAggregatorRoundId;
        for (uint256 i = 0; i < args.signers.length; i++) {
            s_rewardFromAggregatorRoundId[i] = latestAggregatorRoundId;
        }

        _setContract(onchainConfig);
    }

    function _setContract(bytes calldata onchainConfig) internal {
        _setConfirmationDelays(onchainConfig);
    }

    function _setConfirmationDelays(bytes calldata onchainConfig) internal {
        // TODO(alx): Contract instantiation fails if constant NUM_CONF_DELAYS is
        // used, here. File a bug on solc?
        uint256 expectedLength = 32 * 8; // NUM_CONF_DELAYS=8
        if (onchainConfig.length != expectedLength) {
            revert OffchainConfigHasWrongLength(onchainConfig, expectedLength);
        }
        ConfirmationDelay[NUM_CONF_DELAYS] memory confDelays = abi.decode(
            onchainConfig,
            // TODO(alx): solc can't handle a named constant, here.
            // (NUM_CONF_DELAYS) File a bug?
            (ConfirmationDelay[8])
        );
        assert(NUM_CONF_DELAYS == 8); // explicit const above is correct?
        COORDINATOR.setConfirmationDelays(confDelays);
    }

    error UnknownConfigVersion(uint64 occVersion);
    error OffchainConfigHasWrongLength(bytes config, uint256 expectedLength);

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

    function latestConfigDigestAndEpoch()
        external
        view
        returns (
            bool scanLogs,
            bytes32 configDigest,
            uint32 epoch
        )
    {
        return (false, s_configInfo.latestConfigDigest, epochOfLastReport);
    }

    function latestConfigDetails()
        external
        view
        returns (
            uint32 configCount,
            uint32 blockNumber,
            bytes32 configDigest
        )
    {
        return (
            configCount,
            s_latestConfigBlockNumber,
            s_configInfo.latestConfigDigest
        );
    }

    // Storing these fields used on the hot path in a ConfigInfo variable reduces the
    // retrieval of all of them to a single SLOAD. If any further fields are
    // added, make sure that storage of the struct still takes at most 32 bytes.
    struct ConfigInfo {
        bytes32 latestConfigDigest;
        uint8 f;
        uint8 n;
    }
    ConfigInfo internal s_configInfo;

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
        bytes memory hMsg = abi.encode(
            _chainId,
            _contractAddress,
            _configCount,
            _signers,
            _transmitters,
            _f,
            _onchainConfig,
            _encodedConfigVersion,
            _encodedConfig
        );
        uint256 h = uint256(keccak256(hMsg));
        uint256 prefixMask = type(uint256).max << (256 - 16); // 0xFFFF00..00
        uint256 prefix = 0x0001 << (256 - 16); // 0x000100..00
        return bytes32((prefix & prefixMask) | (h & ~prefixMask));
    }

    // Maximum number of oracles the offchain reporting protocol is designed for
    uint256 internal constant maxNumOracles = 31;

    uint32 epochOfLastReport; // epoch at the time of the last-reported distributed key

    function transmit(
        // reportContext consists of:
        // reportContext[0]: ConfigDigest
        // reportContext[1]: 27 byte padding, 4-byte epoch and 1-byte round
        // reportContext[2]: ExtraHash
        bytes32[3] calldata reportContext,
        bytes calldata report,
        // ECDSA signatures
        bytes32[] calldata rs,
        bytes32[] calldata ss,
        bytes32 rawVs
    ) external {
        // NOTE: If the arguments to this function are changed, _requireExpectedMsgDataLength and/or
        // TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT need to be changed accordingly
        uint256 initialGas = gasleft(); // This line must come first

        HotVars memory hotVars = s_hotVars;

        uint40 epochAndRound = uint40(uint256(reportContext[1]));

        require(s_transmitters[msg.sender].active, "unauthorized transmitter");

        require(
            s_configInfo.latestConfigDigest == reportContext[0],
            "configDigest mismatch"
        );

        _requireExpectedMsgDataLength(report, rs, ss);

        require(rs.length == hotVars.f + 1, "wrong number of signatures");
        require(rs.length == ss.length, "signatures out of registration");

        // Verify signatures attached to report
        {
            bytes32 h = keccak256(
                abi.encodePacked(keccak256(report), reportContext)
            );

            // i-th byte counts number of sigs made by i-th signer
            uint256 signedCount = 0;

            Signer memory signer;
            for (uint256 i = 0; i < rs.length; i++) {
                address signerAddress = ecrecover(
                    h,
                    uint8(rawVs[i]) + 27,
                    rs[i],
                    ss[i]
                );
                signer = s_signers[signerAddress];
                require(signer.active, "signature error");
                unchecked {
                    signedCount += 1 << (8 * signer.index);
                }
            }

            // The first byte of the mask can be 0, because we only ever have 31 oracles
            require(
                signedCount &
                    0x0001010101010101010101010101010101010101010101010101010101010101 ==
                    signedCount,
                "duplicate signer"
            );
        }

        uint192 juelsPerFeeCoin = _report(
            hotVars,
            reportContext[0],
            epochAndRound,
            report
        );

        _payTransmitter(
            hotVars,
            juelsPerFeeCoin,
            uint32(initialGas),
            msg.sender
        );
    }

    struct Transmitter {
        bool active;
        // Index of oracle in s_signersList/s_transmittersList
        uint8 index;
        // juels-denominated payment for transmitters, covering gas costs incurred
        // by the transmitter plus additional rewards. The entire LINK supply (1e9
        // LINK = 1e27 Juels) will always fit into a uint96.
        uint96 paymentJuels;
    }
    mapping(address => Transmitter) /* transmitter address */
        internal s_transmitters;

    struct Signer {
        bool active;
        // Index of oracle in s_signersList/s_transmittersList
        uint8 index;
    }
    mapping(address => Signer) /* signer address */
        internal s_signers;

    // s_signersList contains the signing address of each oracle
    address[] internal s_signersList;

    // s_transmittersList contains the transmission address of each oracle,
    // i.e. the address the oracle actually sends transactions to the contract from
    address[] internal s_transmittersList;

    // We assume that all oracles contribute observations to all rounds. this
    // variable tracks (per-oracle) from what round an oracle should be rewarded,
    // i.e. the oracle gets (latestAggregatorRoundId -
    // rewardFromAggregatorRoundId) * reward
    uint32[maxNumOracles] internal s_rewardFromAggregatorRoundId;

    // The constant-length components of the msg.data sent to transmit.
    // See the "If we wanted to call sam" example on for example reasoning
    // https://solidity.readthedocs.io/en/v0.7.2/abi-spec.html
    uint256 private constant TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT =
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

    // Make sure the calldata length matches the inputs. Otherwise, the
    // transmitter could append an arbitrarily long (up to gas-block limit)
    // string of 0 bytes, which we would reimburse at a rate of 16 gas/byte, but
    // which would only cost the transmitter 4 gas/byte.
    function _requireExpectedMsgDataLength(
        bytes calldata report,
        bytes32[] calldata rs,
        bytes32[] calldata ss
    ) private pure {
        // calldata will never be big enough to make this overflow
        uint256 expected = TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT +
            report.length + // one byte pure entry in report
            rs.length *
            32 + // 32 bytes per entry in rs
            ss.length *
            32 + // 32 bytes per entry in ss
            0; // placeholder
        require(msg.data.length == expected, "calldata length mismatch");
    }

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

    /***************************************************************************
     * Section: Payee Management
     **************************************************************************/

    // Addresses at which oracles want to receive payments, by transmitter address
    mapping(address => address) /* transmitter */ /* payment address */
        internal s_payees;

    // Payee addresses which must be approved by the owner
    mapping(address => address) /* transmitter */ /* payment address */
        internal s_proposedPayees;

    /**
     * @notice emitted when a transfer of an oracle's payee address has been initiated
     * @param transmitter address from which the oracle sends reports to the transmit method
     * @param current the payeee address for the oracle, prior to this setting
     * @param proposed the proposed new payee address for the oracle
     */
    event PayeeshipTransferRequested(
        address indexed transmitter,
        address indexed current,
        address indexed proposed
    );

    /**
     * @notice emitted when a transfer of an oracle's payee address has been completed
     * @param transmitter address from which the oracle sends reports to the transmit method
     * @param current the payeee address for the oracle, prior to this setting
     */
    event PayeeshipTransferred(
        address indexed transmitter,
        address indexed previous,
        address indexed current
    );

    /**
     * @notice sets the payees for transmitting addresses
     * @param transmitters addresses oracles use to transmit the reports
     * @param payees addresses of payees corresponding to list of transmitters
     * @dev must be called by owner
     * @dev cannot be used to change payee addresses, only to initially populate them
     */
    function setPayees(
        address[] calldata transmitters,
        address[] calldata payees
    ) external onlyOwner {
        require(
            transmitters.length == payees.length,
            "transmitters.size != payees.size"
        );

        for (uint256 i = 0; i < transmitters.length; i++) {
            address transmitter = transmitters[i];
            address payee = payees[i];
            address currentPayee = s_payees[transmitter];
            bool zeroedOut = currentPayee == address(0);
            require(zeroedOut || currentPayee == payee, "payee already set");
            s_payees[transmitter] = payee;

            if (currentPayee != payee) {
                emit PayeeshipTransferred(transmitter, currentPayee, payee);
            }
        }
    }

    /**
     * @notice first step of payeeship transfer (safe transfer pattern)
     * @param transmitter transmitter address of oracle whose payee is changing
     * @param proposed new payee address
     * @dev can only be called by payee address
     */
    function transferPayeeship(address transmitter, address proposed) external {
        require(
            msg.sender == s_payees[transmitter],
            "only current payee can update"
        );
        require(msg.sender != proposed, "cannot transfer to self");

        address previousProposed = s_proposedPayees[transmitter];
        s_proposedPayees[transmitter] = proposed;

        if (previousProposed != proposed) {
            emit PayeeshipTransferRequested(transmitter, msg.sender, proposed);
        }
    }

    /**
     * @notice second step of payeeship transfer (safe transfer pattern)
     * @param transmitter transmitter address of oracle whose payee is changing
     * @dev can only be called by proposed new payee address
     */
    function acceptPayeeship(address transmitter) external {
        require(
            msg.sender == s_proposedPayees[transmitter],
            "only proposed payees can accept"
        );

        address currentPayee = s_payees[transmitter];
        s_payees[transmitter] = msg.sender;
        s_proposedPayees[transmitter] = address(0);

        emit PayeeshipTransferred(transmitter, currentPayee, msg.sender);
    }

    /***************************************************************************
     * Section: BillingAccessController Management
     **************************************************************************/

    // Controls who can change billing parameters. A billingAdmin is not able to
    // affect any OCR protocol settings and therefore cannot tamper with the
    // liveness or integrity of a data feed. However, a billingAdmin can set
    // faulty billing parameters causing oracles to be underpaid, or causing them
    // to be paid so much that further calls to setConfig, setBilling,
    // setLinkToken will always fail due to the contract being underfunded.
    AccessControllerInterface internal s_billingAccessController;

    /**
     * @notice emitted when a new access-control contract is set
     * @param old the address prior to the current setting
     * @param current the address of the new access-control contract
     */
    event BillingAccessControllerSet(
        AccessControllerInterface old,
        AccessControllerInterface current
    );

    function _setBillingAccessController(
        AccessControllerInterface billingAccessController
    ) internal {
        AccessControllerInterface oldController = s_billingAccessController;
        if (billingAccessController != oldController) {
            s_billingAccessController = billingAccessController;
            emit BillingAccessControllerSet(
                oldController,
                billingAccessController
            );
        }
    }

    /**
     * @notice sets billingAccessController
     * @param _billingAccessController new billingAccessController contract address
     * @dev only owner can call this
     */
    function setBillingAccessController(
        AccessControllerInterface _billingAccessController
    ) external onlyOwner {
        _setBillingAccessController(_billingAccessController);
    }

    /**
     * @notice gets billingAccessController
     * @return address of billingAccessController contract
     */
    function getBillingAccessController()
        external
        view
        returns (AccessControllerInterface)
    {
        return s_billingAccessController;
    }

    /***************************************************************************
     * Section: Billing Configuration
     **************************************************************************/

    /**
     * @notice emitted when billing parameters are set
     * @param maximumGasPriceGwei highest gas price for which transmitter will be compensated
     * @param reasonableGasPriceGwei transmitter will receive reward for gas prices under this value
     * @param observationPaymentGjuels reward to oracle for contributing an observation to a successfully transmitted report
     * @param transmissionPaymentGjuels reward to transmitter of a successful report
     * @param accountingGas gas overhead incurred by accounting logic
     */
    event BillingSet(
        uint32 maximumGasPriceGwei,
        uint32 reasonableGasPriceGwei,
        uint32 observationPaymentGjuels,
        uint32 transmissionPaymentGjuels,
        uint24 accountingGas
    );

    /**
     * @notice sets billing parameters
     * @param maximumGasPriceGwei highest gas price for which transmitter will be compensated
     * @param reasonableGasPriceGwei transmitter will receive reward for gas prices under this value
     * @param observationPaymentGjuels reward to oracle for contributing an observation to a successfully transmitted report
     * @param transmissionPaymentGjuels reward to transmitter of a successful report
     * @param accountingGas gas overhead incurred by accounting logic
     * @dev access control provided by billingAccessController
     */
    function setBilling(
        uint32 maximumGasPriceGwei,
        uint32 reasonableGasPriceGwei,
        uint32 observationPaymentGjuels,
        uint32 transmissionPaymentGjuels,
        uint24 accountingGas
    ) external {
        AccessControllerInterface access = s_billingAccessController;
        require(
            msg.sender == owner() || access.hasAccess(msg.sender, msg.data),
            "Only owner&billingAdmin can call"
        );
        _payOracles();

        s_hotVars.maximumGasPriceGwei = maximumGasPriceGwei;
        s_hotVars.reasonableGasPriceGwei = reasonableGasPriceGwei;
        s_hotVars.observationPaymentGjuels = observationPaymentGjuels;
        s_hotVars.transmissionPaymentGjuels = transmissionPaymentGjuels;
        s_hotVars.accountingGas = accountingGas;

        emit BillingSet(
            maximumGasPriceGwei,
            reasonableGasPriceGwei,
            observationPaymentGjuels,
            transmissionPaymentGjuels,
            accountingGas
        );
    }

    /**
     * @notice gets billing parameters
     * @param maximumGasPriceGwei highest gas price for which transmitter will be compensated
     * @param reasonableGasPriceGwei transmitter will receive reward for gas prices under this value
     * @param observationPaymentGjuels reward to oracle for contributing an observation to a successfully transmitted report
     * @param transmissionPaymentGjuels reward to transmitter of a successful report
     * @param accountingGas gas overhead of the accounting logic
     */
    function getBilling()
        external
        view
        returns (
            uint32 maximumGasPriceGwei,
            uint32 reasonableGasPriceGwei,
            uint32 observationPaymentGjuels,
            uint32 transmissionPaymentGjuels,
            uint24 accountingGas
        )
    {
        return (
            s_hotVars.maximumGasPriceGwei,
            s_hotVars.reasonableGasPriceGwei,
            s_hotVars.observationPaymentGjuels,
            s_hotVars.transmissionPaymentGjuels,
            s_hotVars.accountingGas
        );
    }

    /***************************************************************************
     * Section: Payments and Withdrawals
     **************************************************************************/

    /**
     * @notice withdraws an oracle's payment from the contract
     * @param transmitter the transmitter address of the oracle
     * @dev must be called by oracle's payee address
     */
    function withdrawPayment(address transmitter) external {
        require(msg.sender == s_payees[transmitter], "Only payee can withdraw");
        _payOracle(transmitter);
    }

    /**
     * @notice query an oracle's payment amount, denominated in juels
     * @param transmitterAddress the transmitter address of the oracle
     */
    function owedPayment(address transmitterAddress)
        public
        view
        returns (uint256)
    {
        Transmitter memory transmitter = s_transmitters[transmitterAddress];
        if (!transmitter.active) {
            return 0;
        }
        // safe from overflow:
        // s_hotVars.latestAggregatorRoundId - s_rewardFromAggregatorRoundId[transmitter.index] <= 2**32
        // s_hotVars.observationPaymentGjuels <= 2**32
        // 1 gwei <= 2**32
        // hence juelsAmount <= 2**96
        uint256 juelsAmount = uint256(
            s_hotVars.latestAggregatorRoundId -
                s_rewardFromAggregatorRoundId[transmitter.index]
        ) *
            uint256(s_hotVars.observationPaymentGjuels) *
            (1 gwei);
        juelsAmount += transmitter.paymentJuels;
        return juelsAmount;
    }

    /**
     * @notice emitted when an oracle has been paid LINK
     * @param transmitter address from which the oracle sends reports to the transmit method
     * @param payee address to which the payment is sent
     * @param amount amount of LINK sent
     * @param linkToken address of the LINK token contract
     */
    event OraclePaid(
        address indexed transmitter,
        address indexed payee,
        uint256 amount,
        LinkTokenInterface indexed linkToken
    );

    // _payOracle pays out transmitter's balance to the corresponding payee, and zeros it out
    function _payOracle(address transmitterAddress) internal {
        Transmitter memory transmitter = s_transmitters[transmitterAddress];
        if (!transmitter.active) {
            return;
        }
        uint256 juelsAmount = owedPayment(transmitterAddress);
        if (juelsAmount > 0) {
            address payee = s_payees[transmitterAddress];
            // Poses no re-entrancy issues, because LINK.transfer does not yield
            // control flow.
            s_rewardFromAggregatorRoundId[transmitter.index] = s_hotVars
                .latestAggregatorRoundId;
            s_transmitters[transmitterAddress].paymentJuels = 0;
            COORDINATOR.transferLink(payee, juelsAmount);
            emit OraclePaid(transmitterAddress, payee, juelsAmount, LINK);
        }
    }

    // _payOracles pays out all transmitters, and zeros out their balances.
    //
    // It's much more gas-efficient to do this as a single operation, to avoid
    // hitting storage too much.
    function _payOracles() internal {
        unchecked {
            LinkTokenInterface linkToken = LINK;
            uint32 latestAggregatorRoundId = s_hotVars.latestAggregatorRoundId;
            uint32[maxNumOracles]
                memory rewardFromAggregatorRoundId = s_rewardFromAggregatorRoundId;
            address[] memory transmitters = s_transmittersList;
            uint256 numTransmitters = transmitters.length;
            address[] memory payees = new address[](numTransmitters);
            uint256[] memory paymentsInJuels = new uint256[](numTransmitters);
            uint256 count = 0;
            for (
                uint256 transmitteridx = 0;
                transmitteridx < numTransmitters;
                transmitteridx++
            ) {
                uint256 reimbursementAmountJuels = s_transmitters[
                    transmitters[transmitteridx]
                ].paymentJuels;
                s_transmitters[transmitters[transmitteridx]].paymentJuels = 0;
                uint256 obsCount = latestAggregatorRoundId -
                    rewardFromAggregatorRoundId[transmitteridx];
                uint256 juelsAmount = obsCount *
                    uint256(s_hotVars.observationPaymentGjuels) *
                    (1 gwei) +
                    reimbursementAmountJuels;
                if (juelsAmount > 0) {
                    address payee = s_payees[transmitters[transmitteridx]];
                    payees[count] = payee;
                    paymentsInJuels[count] = juelsAmount;
                    rewardFromAggregatorRoundId[
                        transmitteridx
                    ] = latestAggregatorRoundId;
                    count++;
                    // In terms of code readability, oracles are not paid until
                    // the COORDINATOR.batchTransferLink call at the bottom.
                    // However, since EVM transactions either fully complete or
                    // fully revert (including events), the events are emitted
                    // inside this for-loop before COORDINATOR.batchTransferLink
                    // to reduce gas cost of creating another loop and reading
                    // from memory
                    emit OraclePaid(
                        transmitters[transmitteridx],
                        payee,
                        juelsAmount,
                        linkToken
                    );
                }
            }
            // Truncate the paymentsInJuels and payees to their true lengths.
            if (count != paymentsInJuels.length) {
                assembly {
                    // mstore sets the first memory slot of the arrays (their lenghts)
                    // to the number of valid payees.
                    mstore(paymentsInJuels, count)
                    mstore(payees, count)
                }
            }
            // "Zero" the accounting storage variables
            s_rewardFromAggregatorRoundId = rewardFromAggregatorRoundId;
            if (paymentsInJuels.length > 0) {
                // Poses no re-entrancy issues, because LINK.transfer does not yield
                // control flow.
                COORDINATOR.batchTransferLink(payees, paymentsInJuels);
            }
        }
    }

    /**
     * @notice withdraw any available funds left in the contract, up to amount, after accounting for the funds due to participants in past reports
     * @param recipient address to send funds to
     * @param amount maximum amount to withdraw, denominated in LINK-wei.
     * @dev access control provided by billingAccessController
     */
    function withdrawFunds(address recipient, uint256 amount) external {
        require(
            msg.sender == owner() ||
                s_billingAccessController.hasAccess(msg.sender, msg.data),
            "Only owner&billingAdmin can call"
        );
        uint256 linkDue = _totalLinkDue();
        uint256 linkBalance = COORDINATOR.getTotalLinkBalance();
        require(linkBalance >= linkDue, "insufficient balance");
        COORDINATOR.transferLink(
            recipient,
            _min(linkBalance - linkDue, amount)
        );
    }

    // Total LINK due to participants in past reports (denominated in Juels).
    function _totalLinkDue() internal view returns (uint256 linkDue) {
        // Argument for overflow safety: We do all computations in
        // uint256s. The inputs to linkDue are:
        // - the <= 31 observation rewards each of which has less than
        //   64 bits (32 bits for observationPaymentGjuels, 32 bits
        //   for wei/gwei conversion). Hence 69 bits are sufficient for this part.
        // - the <= 31 gas reimbursements, each of which consists of at most 96
        //   bits. Hence 101 bits are sufficient for this part.
        // So we never need more than 102 bits.

        address[] memory transmitters = s_transmittersList;
        uint256 n = transmitters.length;

        uint32 latestAggregatorRoundId = s_hotVars.latestAggregatorRoundId;
        uint32[maxNumOracles]
            memory rewardFromAggregatorRoundId = s_rewardFromAggregatorRoundId;
        for (uint256 i = 0; i < n; i++) {
            linkDue += latestAggregatorRoundId - rewardFromAggregatorRoundId[i];
        }
        // Convert observationPaymentGjuels to uint256, or this overflows!
        linkDue *= uint256(s_hotVars.observationPaymentGjuels) * (1 gwei);
        for (uint256 i = 0; i < n; i++) {
            linkDue += uint256(s_transmitters[transmitters[i]].paymentJuels);
        }
    }

    /**
     * @notice allows oracles to check that sufficient LINK balance is available
     * @return availableBalance LINK available on this contract, after accounting for outstanding obligations. can become negative
     */
    function linkAvailableForPayment()
        external
        view
        returns (int256 availableBalance)
    {
        // there are at most one billion LINK, so this cast is safe
        int256 balance = int256(COORDINATOR.getTotalLinkBalance());
        // according to the argument in the definition of _totalLinkDue,
        // _totalLinkDue is never greater than 2**102, so this cast is safe
        int256 due = int256(_totalLinkDue());
        // safe from overflow according to above sizes
        return int256(balance) - int256(due);
    }

    /**
     * @notice number of observations oracle is due to be reimbursed for
     * @param transmitterAddress address used by oracle for signing or transmitting reports
     */
    function oracleObservationCount(address transmitterAddress)
        external
        view
        returns (uint32)
    {
        Transmitter memory transmitter = s_transmitters[transmitterAddress];
        if (!transmitter.active) {
            return 0;
        }
        return
            s_hotVars.latestAggregatorRoundId -
            s_rewardFromAggregatorRoundId[transmitter.index];
    }

    /***************************************************************************
     * Section: Transmitter Payment
     **************************************************************************/

    // Gas price at which the transmitter should be reimbursed, in gwei/gas
    function _reimbursementGasPriceGwei(
        uint256 txGasPriceGwei,
        uint256 reasonableGasPriceGwei,
        uint256 maximumGasPriceGwei
    ) internal pure returns (uint256) {
        // this happens on the path for transmissions. we'd rather pay out
        // a wrong reward than risk a liveness failure due to a revert.
        unchecked {
            // Reward the transmitter for choosing an efficient gas price: if they manage
            // to come in lower than considered reasonable, give them half the savings.
            uint256 gasPriceGwei = txGasPriceGwei;
            if (txGasPriceGwei < reasonableGasPriceGwei) {
                // Give transmitter half the savings for coming in under the reasonable gas price
                gasPriceGwei += (reasonableGasPriceGwei - txGasPriceGwei) / 2;
            }
            // Don't reimburse a gas price higher than maximumGasPriceGwei
            return _min(gasPriceGwei, maximumGasPriceGwei);
        }
    }

    // gas reimbursement due the transmitter, in wei
    function _transmitterGasCostWei(
        uint256 initialGas,
        uint256 gasPriceGwei,
        uint256 callDataGas,
        uint256 accountingGas,
        uint256 leftGas
    ) internal pure returns (uint256) {
        // this happens on the path for transmissions. we'd rather pay out
        // a wrong reward than risk a liveness failure due to a revert.
        unchecked {
            require(initialGas >= leftGas, "leftGas cannot exceed initialGas"); /* XXX: Failing on this line? */
            uint256 usedGas = initialGas -
                leftGas + // observed gas usage
                callDataGas +
                accountingGas; // estimated gas usage
            uint256 fullGasCostWei = usedGas * gasPriceGwei * (1 gwei);
            return fullGasCostWei;
        }
    }

    function _payTransmitter(
        HotVars memory hotVars,
        uint192 juelsPerFeeCoin,
        uint32 initialGas,
        address transmitter
    ) internal virtual {
        // this happens on the path for transmissions. we'd rather pay out
        // a wrong reward than risk a liveness failure due to a revert.
        unchecked {
            // we can't deal with negative juelsPerFeeCoin, better to just not pay
            if (juelsPerFeeCoin < 0) {
                return;
            }

            // Reimburse transmitter of the report for gas usage
            uint256 gasPriceGwei = _reimbursementGasPriceGwei(
                tx.gasprice / (1 gwei), // convert to ETH-gwei units
                hotVars.reasonableGasPriceGwei,
                hotVars.maximumGasPriceGwei
            );
            // The following is only an upper bound, as it ignores the cheaper cost for
            // 0 bytes. Safe from overflow, because calldata just isn't that long.
            uint256 callDataGasCost = 16 * msg.data.length;
            uint256 gasLeft = gasleft();
            uint256 gasCostEthWei = _transmitterGasCostWei(
                uint256(initialGas),
                gasPriceGwei,
                callDataGasCost,
                hotVars.accountingGas,
                gasLeft
            );

            // Even if we assume absurdly large values, this still does not overflow. With
            // - usedGas <= 1'000'000 gas <= 2**20 gas
            // - weiPerGas <= 1'000'000 gwei <= 2**50 wei
            // - hence gasCostEthWei <= 2**70
            // - juelsPerFeeCoin <= 2**96 (more than the entire supply)
            // we still fit into 166 bits
            uint256 gasCostJuels = (gasCostEthWei * uint192(juelsPerFeeCoin)) /
                1e18;

            uint96 oldTransmitterPaymentJuels = s_transmitters[transmitter]
                .paymentJuels;
            uint96 newTransmitterPaymentJuels = uint96(
                uint256(oldTransmitterPaymentJuels) +
                    gasCostJuels +
                    uint256(hotVars.transmissionPaymentGjuels) *
                    (1 gwei)
            );

            // overflow *should* never happen, but if it does, let's not persist it.
            if (newTransmitterPaymentJuels < oldTransmitterPaymentJuels) {
                return;
            }
            s_transmitters[transmitter]
                .paymentJuels = newTransmitterPaymentJuels;
        }
    }

    /***************************************************************************
     * Section: TypeAndVersionInterface
     **************************************************************************/

    function typeAndVersion() external pure virtual returns (string memory) {
        return "VRFBeacon 1.0.0-alpha";
    }

    /***************************************************************************
     * Section: Helper Functions
     **************************************************************************/

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (a < b) {
                return a;
            }
            return b;
        }
    }

    function _requirePositiveF(uint256 f) internal pure virtual {
        require(0 < f, "f must be positive");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {DKGClient} from "./DKGClient.sol";
import {DKG} from "./DKG.sol";

contract VRFBeaconDKGClient is DKGClient {
    DKG s_keyProvider;
    bytes32 public s_keyID;
    bytes32 public s_provingKeyHash;

    constructor(DKG _keyProvider, bytes32 _keyID) {
        s_keyProvider = _keyProvider;
        s_keyID = _keyID;
    }

    function newKeyRequested() external override fromKeyProvider {
        bytes32 zero;
        s_provingKeyHash = zero;
    }

    function keyGenerated(KeyData memory kd) external override fromKeyProvider {
        s_provingKeyHash = keccak256(abi.encodePacked(kd.publicKey));
    }

    /// @dev fromKeyProvider errors unless the modified function is called by the
    /// @dev designated key provider.
    modifier fromKeyProvider() {
        DKG keyProvider = s_keyProvider;
        if (msg.sender != address(keyProvider)) {
            revert KeyInfoMustComeFromProvider(
                msg.sender,
                address(keyProvider)
            );
        }
        _;
    }

    /// @notice Emitted when key data is sent from wrong address
    /// @param sender address which sent the key data
    /// @param keyProvider address from which key data must be sent
    error KeyInfoMustComeFromProvider(address sender, address keyProvider);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VRFBeaconTypes} from "./VRFBeaconTypes.sol";

// Interface used by VRF output producers such as VRFBeacon
// Exposes methods for processing VRF outputs and paying appropriate EOA
// The methods are only callable by producers
abstract contract IVRFCoordinatorProducerAPI is VRFBeaconTypes {
    /// @dev processes VRF outputs for given blockHeight and blockHash
    /// @dev also fulfills callbacks
    function processVRFOutputs(
        VRFOutput[] calldata vrfOutputs,
        uint192 juelsPerFeeCoin,
        uint64 blockHeight,
        bytes32 blockHash
    ) external virtual returns (OutputServed[] memory);

    /// @dev transfers LINK to recipient
    /// @dev reverts when there are not enough funds
    function transferLink(address recipient, uint256 juelsAmount)
        external
        virtual;

    /// @dev transfer LINK to multiple recipients
    /// @dev reverts when there are not enough funds or number of recipients and
    /// @dev paymentsInJuels are not as expected
    function batchTransferLink(
        address[] calldata recipients,
        uint256[] calldata paymentsInJuels
    ) external virtual;

    /// @dev returns total Link balance in the contract in juels
    function getTotalLinkBalance()
        external
        view
        virtual
        returns (uint256 balance);

    /// @dev sets allowed confirmation delays
    function setConfirmationDelays(
        ConfirmationDelay[NUM_CONF_DELAYS] calldata confDelays
    ) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining);

    function approve(address spender, uint256 value)
        external
        returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function decreaseApproval(address spender, uint256 addedValue)
        external
        returns (bool success);

    function increaseApproval(address spender, uint256 subtractedValue)
        external;

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(address to, uint256 value)
        external
        returns (bool success);

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ECCArithmetic} from "./ECCArithmetic.sol";
import {VRFBeaconTypes} from "./VRFBeaconTypes.sol";
import {OwnerIsCreator} from "./vendor/ocr2-contracts/OwnerIsCreator.sol";
import {IVRFCoordinatorProducerAPI} from "./IVRFCoordinatorProducerAPI.sol";
import {LinkTokenInterface} from "./vendor/ocr2-contracts/interfaces/LinkTokenInterface.sol";
import {ChainSpecificUtil} from "./ChainSpecificUtil.sol";
import {Debug} from "./Debug.sol"; /* XXX:  */

/// @dev Search for "We trust the committee" for properties of the report which
/// @dev should be verified by committee members and the offchain monitoring
/// @dev system.
contract VRFBeaconReport is VRFBeaconTypes, OwnerIsCreator {
    LinkTokenInterface public immutable LINK;
    IVRFCoordinatorProducerAPI public immutable COORDINATOR;

    constructor(LinkTokenInterface link, IVRFCoordinatorProducerAPI coordinator)
    {
        LINK = link;
        COORDINATOR = coordinator;
    }

    /// @notice Report from offchain of VRF outputs
    /// @param juelsPerFeeCoin exchange rate for reimbursements
    /// @param recentBlockHeight height of chain-history domain separator
    /// @param recentBlockHash chain-history domain separator
    ///
    /// @dev recentBlockHeight cannot be older than any height in the outputs
    ///
    /// @dev recentBlockHeight must be less than 256 blocks old
    ///
    /// @dev recentBlockHash is used to ensure that the outputs pertain to the
    /// @dev chain history on which the Report is being processed. It prevents a
    /// @dev Report from being replayed on a fork where the outputs have changed.
    struct Report {
        VRFOutput[] outputs;
        uint192 juelsPerFeeCoin;
        uint64 recentBlockHeight; // Chain-history domain separator
        bytes32 recentBlockHash;
    }

    /// @notice Emitted when the recentBlockHash doesn't match the output of the
    /// @notice blockhash builtin function at recentBlockHeight.
    ///
    /// @dev The blockhash function might not match because it returns the zero
    /// @dev hash for heights more than 256 blocks in the past.
    ///
    /// @param providedHash the hash passed in the report, as blockHeight's hash
    /// @param onchainHash the hash at blockHeight, per blockhash() builtin
    /// @param blockHeight the height of the block for this hash
    error HistoryDomainSeparatorWrong(
        bytes32 providedHash,
        bytes32 onchainHash,
        uint64 blockHeight
    );

    function _report(
        HotVars memory hotVars,
        bytes32 configDigest,
        uint40 epochAndRound,
        bytes memory rawReport
    ) internal returns (uint192 juelsPerFeeCoin) {
        // We trust the committee to only sign off on reports which contain no
        // overage (i.e., no need to check that rawReport is exactly the length
        // required to represent report)
        Report memory report = abi.decode(rawReport, (Report));

        hotVars.latestEpochAndRound = epochAndRound;

        hotVars.latestAggregatorRoundId++;

        // persist updates to hotVars. Can update whole thing since it's one word
        s_hotVars = hotVars;

        bytes32 onchainHash = ChainSpecificUtil.getBlockhash(
            report.recentBlockHeight
        );
        if (report.recentBlockHash != onchainHash) {
            revert HistoryDomainSeparatorWrong(
                report.recentBlockHash,
                onchainHash,
                report.recentBlockHeight
            );
        }

        COORDINATOR.processVRFOutputs(
            report.outputs,
            report.juelsPerFeeCoin,
            report.recentBlockHeight,
            report.recentBlockHash
        );
        emit NewTransmission(
            hotVars.latestAggregatorRoundId,
            epochAndRound,
            msg.sender,
            report.juelsPerFeeCoin,
            configDigest
        );
        return report.juelsPerFeeCoin;
    }

    // Storing these fields used on the hot path in a HotVars variable reduces the
    // retrieval of all of them to a single SLOAD.
    struct HotVars {
        // maximum number of faulty oracles
        uint8 f;
        // epoch and round from OCR protocol.
        // 32 most sig bits for epoch, 8 least sig bits for round
        uint40 latestEpochAndRound;
        // Chainlink Aggregators expose a roundId to consumers. The offchain
        // reporting protocol does not use this id anywhere. We increment it
        // whenever a new transmission is made to provide callers with contiguous
        // ids for successive reports.
        uint32 latestAggregatorRoundId;
        // Highest compensated gas price, in gwei uints
        uint32 maximumGasPriceGwei;
        // If gas price is less (in gwei units), transmitter gets half the savings
        uint32 reasonableGasPriceGwei;
        // Fixed LINK reward for each observer
        uint32 observationPaymentGjuels;
        // Fixed reward for transmitter
        uint32 transmissionPaymentGjuels;
        // Overhead incurred by accounting logic
        uint24 accountingGas;
    }
    HotVars internal s_hotVars;

    event NewTransmission(
        uint32 indexed aggregatorRoundId,
        uint40 indexed epochAndRound,
        address transmitter,
        uint192 juelsPerFeeCoin,
        bytes32 configDigest
    );

    // External function forces abigen to expose types
    function exposeType(Report calldata) external {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwner.sol";

/**
 * @title The OwnerIsCreator contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract OwnerIsCreator is ConfirmedOwner {
    constructor() ConfirmedOwner(msg.sender) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AccessControllerInterface {
    function hasAccess(address user, bytes calldata data)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ArbSys} from "./vendor/nitro/207827de97/contracts/src/precompiles/ArbSys.sol";

//@dev A library that abstracts out opcodes that behave differently across chains.
//@dev The methods below return values that are pertinent to the given chain.
//@dev For instance, ChainSpecificUtil.getBlockNumber() returns L2 block number in L2 chains
library ChainSpecificUtil {
    address private constant ARBSYS_ADDR =
        address(0x0000000000000000000000000000000000000064);
    ArbSys private constant ARBSYS = ArbSys(ARBSYS_ADDR);
    uint256 private constant ARB_MAINNET_CHAIN_ID = 42161;
    uint256 private constant ARB_GOERLI_TESTNET_CHAIN_ID = 421613;

    function getBlockhash(uint64 blockNumber) internal view returns (bytes32) {
        uint256 chainid = block.chainid;
        if (
            chainid == ARB_MAINNET_CHAIN_ID ||
            chainid == ARB_GOERLI_TESTNET_CHAIN_ID
        ) {
            return ARBSYS.arbBlockHash(blockNumber);
        }
        return blockhash(blockNumber);
    }

    function getBlockNumber() internal view returns (uint256) {
        uint256 chainid = block.chainid;
        if (
            chainid == ARB_MAINNET_CHAIN_ID ||
            chainid == ARB_GOERLI_TESTNET_CHAIN_ID
        ) {
            return ARBSYS.arbBlockNumber();
        }
        return block.number;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./KeyDataStruct.sol";

// DKGClient's are called when there is new information about the keyID they are
// associated with.
//
// WARNING: IMPLEMENTATIONS **MUST** CHECK THAT CALLS COME FROM THE EXPECTED DKG CONTRACT
interface DKGClient is KeyDataStruct {
    // newKeyRequested is called when a new key is requested for the given keyID,
    // on the DKG contract.
    function newKeyRequested() external;

    // keyGenerated is called when key data for given keyID is reported on the DKG
    // contract.
    function keyGenerated(KeyData memory kd) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./DKGClient.sol";
import "./Debug.sol";
import "./KeyDataStruct.sol";
import "./vendor/ocr2-contracts/OCR2Abstract.sol";
import "./vendor/ocr2-contracts/OwnerIsCreator.sol";
import {ChainSpecificUtil} from "./ChainSpecificUtil.sol";

contract DKG is KeyDataStruct, OCR2Abstract, OwnerIsCreator, Debug {
    // keyIDClients lists the client contracts which must be contacted when a new
    // key is requested for a given keyID, or when the key is provided. These
    // lists are adjusted using addClient and removeClient.
    mapping(bytes32 => DKGClient[]) s_keyIDClients; /* keyID */

    mapping(bytes32 => mapping(bytes32 => KeyData)) s_keys; /* keyID */ /* config digest */

    // _report stores the key data from a report, and reports it via an event.
    //
    // See golang contract.KeyData#Marshal and contract.Unmarshal for format.
    function _report(
        bytes32 configDigest,
        uint40 epochAndRound,
        bytes memory report
    ) internal {
        bytes32 keyID;
        bytes memory key;
        bytes32[] memory hashes;
        (keyID, key, hashes) = abi.decode(report, (bytes32, bytes, bytes32[]));
        KeyData memory kd = KeyData(key, hashes);

        DKGClient[] memory clients = s_keyIDClients[keyID];
        for (uint256 i = 0; i < clients.length; i++) {
            try clients[i].keyGenerated(kd) {} catch (bytes memory errorData) {
                emit DKGClientError(clients[i], errorData);
            }
        }

        s_keys[keyID][configDigest] = kd;

        // If offchain processes were listening for this event, we could get rid of
        // the above storage, but for now that's a micro-optimization.
        emit KeyGenerated(configDigest, keyID, kd);

        // See, e.g.
        // https://github.com/smartcontractkit/offchain-reporting/blob/28dd19OffchainAggregator.sol#L343
        epochOfLastReport = uint32(epochAndRound >> 8);
    }

    // KeyGenerated is emmitted when a key is reported for the given configDigest/processID.
    event KeyGenerated(
        bytes32 indexed configDigest,
        bytes32 indexed keyID,
        KeyData key
    );

    event DKGClientError(DKGClient client, bytes errorData);

    function getKey(bytes32 _keyID, bytes32 _configDigest)
        external
        view
        returns (KeyData memory)
    {
        return s_keys[_keyID][_configDigest];
    }

    // addClient will add the given clientAddress to the list of clients which
    // should be updated when new key information is available for the given keyID
    function addClient(bytes32 keyID, DKGClient clientAddress)
        external
        onlyOwner
    {
        s_keyIDClients[keyID].push(clientAddress);
    }

    // removeClient removes all instances of clientAddress from the list for the
    // given keyID.
    function removeClient(bytes32 keyID, DKGClient clientAddress)
        external
        onlyOwner
    {
        DKGClient[] memory clients = s_keyIDClients[keyID];

        // Potentially overlong list with all instances of clientAddress removed
        DKGClient[] memory newClients = new DKGClient[](clients.length);
        uint256 found;
        for (uint256 i = 0; i < clients.length; i++) {
            if (clients[i] != clientAddress) {
                newClients[i - found] = clientAddress;
            } else {
                found++;
            }
        }

        // List of correct length with clientAddress removed. Could just bash the
        // length of newClients in assembly, instead, if this is too inefficient.
        DKGClient[] memory finalClients = new DKGClient[](
            clients.length - found
        );
        for (uint256 i = 0; i < clients.length - found; i++) {
            finalClients[i] = newClients[i];
        }
        s_keyIDClients[keyID] = finalClients;
    }

    // _afterSetConfig reports that a new key for the given keyID (encoded as the
    // only contents of the _onchainConfig) has been requested, via an event
    // emmission.
    function _afterSetConfig(
        uint8, /* _f */
        bytes memory _onchainConfig,
        bytes32 _configDigest
    ) internal {
        // convert _onchainConfig bytes to bytes32
        bytes32 keyID;
        bytes32 zero;
        require(_onchainConfig.length == 32, "wrong length for onchainConfig");
        assembly {
            keyID := mload(add(_onchainConfig, 0x20))
        }
        require(keyID != zero, "failed to copy keyID");

        KeyData memory zeroKey;
        s_keys[keyID][_configDigest] = zeroKey;

        DKGClient[] memory clients = s_keyIDClients[keyID];
        for (uint256 i = 0; i < clients.length; i++) {
            clients[i].newKeyRequested();
        }
    }

    // Following methods are mostly cribbed from OCR2Base.sol

    function _beforeSetConfig(uint8 _f, bytes memory _onchainConfig) internal {}

    function _payTransmitter(uint32 initialGas, address transmitter) internal {}

    function typeAndVersion() external pure override returns (string memory) {
        return "DKG 0.0.1";
    }

    uint32 epochOfLastReport; // epoch at the time of the last-reported distributed key

    uint256 private constant maxUint32 = (1 << 32) - 1;

    // Storing these fields used on the hot path in a ConfigInfo variable reduces the
    // retrieval of all of them to a single SLOAD. If any further fields are
    // added, make sure that storage of the struct still takes at most 32 bytes.
    struct ConfigInfo {
        bytes32 latestConfigDigest;
        uint8 f;
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
        return (false, s_configInfo.latestConfigDigest, epochOfLastReport);
    }

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
            configCount,
            s_latestConfigBlockNumber,
            s_configInfo.latestConfigDigest
        );
    }

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

        for (uint256 i = 0; i < args.signers.length; i++) {
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
        s_latestConfigBlockNumber = uint32(ChainSpecificUtil.getBlockNumber());
        s_configCount += 1;
        bytes32 lcd;
        {
            lcd = configDigestFromConfigData(
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
            s_configInfo.latestConfigDigest = lcd;
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

        _afterSetConfig(args.f, args.onchainConfig, lcd);
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

    // The constant-length components of the msg.data sent to transmit.
    // See the "If we wanted to call sam" example on for example reasoning
    // https://solidity.readthedocs.io/en/v0.7.2/abi-spec.html
    uint16 constant TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT =
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
            report.length + // one byte per entry in _report
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
            uint40 epochAndRound = uint40(uint256(reportContext[1]));

            _report(configDigest, epochAndRound, report);

            emit Transmitted(configDigest, uint32(epochAndRound >> 8));

            ConfigInfo memory configInfo = s_configInfo;
            require(
                configInfo.latestConfigDigest == configDigest,
                "configDigest mismatch"
            );

            requireExpectedMsgDataLength(report, rs, ss);
            _requireValidSignatures(
                reportContext,
                report,
                rs,
                ss,
                rawVs,
                configInfo
            );
        }

        assert(initialGas < maxUint32);
        _payTransmitter(uint32(initialGas), msg.sender);
    }

    function _requireValidSignatures(
        bytes32[3] calldata reportContext,
        bytes calldata report,
        bytes32[] calldata rs,
        bytes32[] calldata ss,
        bytes32 rawVs, // signatures
        ConfigInfo memory configInfo
    ) internal virtual {
        {
            uint256 expectedNumSignatures = (configInfo.n + configInfo.f) /
                2 +
                1; // require unique answer
            // require(rs.length == expectedNumSignatures, "wrong number of signatures");
            bytes memory numsigs = new bytes(1);
            numsigs[0] = bytes1(uint8(expectedNumSignatures));
            require(rs.length == expectedNumSignatures, bytesToString(numsigs));
            require(rs.length == ss.length, "signatures out of registration");

            Oracle memory transmitter = s_oracles[msg.sender];
            require( // Check that sender is authorized to report
                transmitter.role == Role.Transmitter &&
                    msg.sender == s_transmitters[transmitter.index],
                "unauthorized transmitter"
            );
        }

        {
            // Verify signatures attached to report
            bytes32 h = keccak256(
                abi.encodePacked(keccak256(report), reportContext)
            );
            bool[maxNumOracles] memory signed;

            Oracle memory o;
            for (uint256 i = 0; i < rs.length; i++) {
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
                require(!signed[o.index], "non-unique signature");
                signed[o.index] = true;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ECCArithmetic} from "./ECCArithmetic.sol";

// If these types are changed, the types in beaconObservation.proto and
// AbstractCostedCallbackRequest etc. probably need to change, too.
contract VRFBeaconTypes {
    type RequestID is uint48;
    RequestID constant MAX_REQUEST_ID = RequestID.wrap(type(uint48).max);
    uint8 public constant NUM_CONF_DELAYS = 8;
    uint256 internal constant MAX_NUM_ORACLES = 31;

    /// @dev With a beacon period of 15, using a uint32 here allows for roughly
    /// @dev 60B blocks, which would take roughly 2000 years on a chain with a 1s
    /// @dev block time.
    type SlotNumber is uint32;
    SlotNumber internal constant MAX_SLOT_NUMBER =
        SlotNumber.wrap(type(uint32).max);

    type ConfirmationDelay is uint24;
    ConfirmationDelay internal constant MAX_CONFIRMATION_DELAY =
        ConfirmationDelay.wrap(type(uint24).max);
    uint8 internal constant CONFIRMATION_DELAY_BYTE_WIDTH = 3;

    /// @dev Request metadata. Designed to fit in a single 32-byte word, to save
    /// @dev on storage/retrieval gas costs.
    struct BeaconRequest {
        SlotNumber slotNumber;
        ConfirmationDelay confirmationDelay;
        uint16 numWords;
        address requester; // Address which will eventually retrieve randomness
    }

    struct Callback {
        RequestID requestID;
        uint16 numWords;
        address requester;
        bytes arguments;
        uint64 subID;
        uint96 gasAllowance; // gas offered to callback method when called
        uint256 gasPrice;
        uint256 weiPerUnitLink;
    }

    struct CostedCallback {
        Callback callback;
        uint96 price; // nominal price charged for the callback
    }

    /// @dev configuration parameters for billing
    struct BillingConfig {
        // Penalty in percent (max 100) for unused gas in an allowance.
        uint8 unusedGasPenaltyPercent;
        // stalenessSeconds is how long before we consider the feed price to be
        // stale and fallback to fallbackWeiPerUnitLink.
        uint32 stalenessSeconds;
        // Estimated gas cost for a beacon fulfillment.
        uint32 redeemableRequestGasOverhead;
        // Estimated gas cost for a callback fulfillment (excludes gas allowance).
        uint32 callbackRequestGasOverhead;
        // Premium percentage charged.
        uint32 premiumPercentage;
        // Fallback LINK/ETH ratio.
        int256 fallbackWeiPerUnitLink;
    }

    // TODO(coventry): There is scope for optimization of the calldata gas cost,
    // here. The solidity lists can be replaced by something lower-level, where
    // the lengths are represented by something shorter, and there could be a
    // specialized part of the report which deals with fulfillments for blocks
    // which have already had their seeds reported.
    struct VRFOutput {
        uint64 blockHeight; // Beacon height this output corresponds to
        ConfirmationDelay confirmationDelay; // #blocks til offchain system response
        // VRF output for blockhash at blockHeight. If this is (0,0), indicates that
        // this is a request for callbacks for a pre-existing height, and the seed
        // should be sought from contract storage
        ECCArithmetic.G1Point vrfOutput;
        CostedCallback[] callbacks; // Contracts to callback with random outputs
    }

    struct OutputServed {
        uint64 height;
        ConfirmationDelay confirmationDelay;
        uint256 proofG1X;
        uint256 proofG1Y;
    }

    /// @dev Emitted when randomness is requested without a callback, for the
    /// @dev given beacon height. This signals to the offchain system that it
    /// @dev should provide the VRF output for that height
    ///
    /// @param nextBeaconOutputHeight height where VRF output should be provided
    /// @param confDelay num blocks offchain system should wait before responding
    event RandomnessRequested(
        uint64 indexed nextBeaconOutputHeight,
        ConfirmationDelay confDelay
    );

    /// @dev Emitted when randomness is requested with a callback, for the given
    /// @dev height, to the given address, which should contain a contract with a
    /// @dev fulfillRandomness(RequestID,uint256,bytes) method. This will be
    /// @dev called with the given RequestID, the uint256 output, and the given
    /// @dev bytes arguments.
    ///
    /// @param nextBeaconOutputHeight height where VRF output should be provided
    /// @param confDelay num blocks offchain system should wait before responding
    /// @param callback callback details
    /// @param subID subscription ID to bill
    event RandomnessFulfillmentRequested(
        uint64 nextBeaconOutputHeight,
        ConfirmationDelay confDelay,
        uint64 subID,
        Callback callback
    );

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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract ECCArithmetic {
    // constant term in affine curve equation: y²=x³+b
    uint256 constant B = 3;

    // Base field for G1 is 𝔽ₚ
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-196.md#specification
    uint256 constant P =
        // solium-disable-next-line indentation
        0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;

    // #E(𝔽ₚ), number of points on  G1/G2Add
    // https://github.com/ethereum/go-ethereum/blob/2388e42/crypto/bn256/cloudflare/constants.go#L23
    uint256 constant Q =
        0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;

    struct G1Point {
        uint256[2] p;
    }

    struct G2Point {
        uint256[4] p;
    }

    function checkPointOnCurve(G1Point memory p) internal pure {
        require(p.p[0] < P, "x not in F_P");
        require(p.p[1] < P, "y not in F_P");
        uint256 rhs = addmod(
            mulmod(mulmod(p.p[0], p.p[0], P), p.p[0], P),
            B,
            P
        );
        require(mulmod(p.p[1], p.p[1], P) == rhs, "point not on curve");
    }

    function _addG1(G1Point memory p1, G1Point memory p2)
        internal
        view
        returns (G1Point memory sum)
    {
        checkPointOnCurve(p1);
        checkPointOnCurve(p2);

        uint256[4] memory summands;
        summands[0] = p1.p[0];
        summands[1] = p1.p[1];
        summands[2] = p2.p[0];
        summands[3] = p2.p[1];
        uint256[2] memory result;
        uint256 callresult;
        assembly {
            // solhint-disable-line no-inline-assembly
            callresult := staticcall(
                // gas cost. https://eips.ethereum.org/EIPS/eip-1108 ,
                // https://github.com/ethereum/go-ethereum/blob/9d10856/params/protocol_params.go#L124
                150,
                // g1add https://github.com/ethereum/go-ethereum/blob/9d10856/core/vm/contracts.go#L89
                0x6,
                summands, // input
                0x80, // input length: 4 words
                result, // output
                0x40 // output length: 2 words
            )
        }
        require(callresult != 0, "addg1 call failed");
        sum.p[0] = result[0];
        sum.p[1] = result[1];
        return sum;
    }

    function addG1(G1Point memory p1, G1Point memory p2)
        internal
        view
        returns (G1Point memory)
    {
        G1Point memory sum = _addG1(p1, p2);
        // This failure is mathematically possible from a legitimate return
        // value, but vanishingly unlikely, and almost certainly instead
        // reflects a failure in the precompile.
        require(sum.p[0] != 0 && sum.p[1] != 0, "addg1 failed: zero ordinate");
        return sum;
    }

    // Coordinates for generator of G2.
    uint256 constant g2GenXA =
        0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2;
    uint256 constant g2GenXB =
        0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed;
    uint256 constant g2GenYA =
        0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b;
    uint256 constant g2GenYB =
        0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa;

    uint256 constant pairingGasCost = 34_000 * 2 + 45_000; // Gas cost as of Istanbul; see EIP-1108
    uint256 constant pairingPrecompileAddress = 0x8;
    uint256 constant pairingInputLength = 12 * 0x20;
    uint256 constant pairingOutputLength = 0x20;

    // discreteLogsMatch returns true iff signature = sk*base, where sk is the
    // secret key associated with pubkey, i.e. pubkey = sk*<G2 generator>
    //
    // This is used for signature/VRF verification. In actual use, g1Base is the
    // hash-to-curve to be signed/exponentiated, and pubkey is the public key
    // the signature pertains to.
    function discreteLogsMatch(
        G1Point memory g1Base,
        G1Point memory signature,
        G2Point memory pubkey
    ) internal view returns (bool) {
        // It is not necessary to check that the points are in their respective
        // groups; the pairing check fails if that's not the case.

        // Let g1, g2 be the canonical generators of G1, G2, respectively..
        // Let l be the (unknown) discrete log of g1Base w.r.t. the G1 generator.
        //
        // In the happy path, the result of the first pairing in the following
        // will be -l*log_{g2}(pubkey) * e(g1,g2) = -l * sk * e(g1,g2), of the
        // second will be sk * l * e(g1,g2) = l * sk * e(g1,g2). Thus the two
        // terms will cancel, and the pairing function will return one. See
        // EIP-197.
        G1Point[] memory g1s = new G1Point[](2);
        G2Point[] memory g2s = new G2Point[](2);
        g1s[0] = G1Point([g1Base.p[0], P - g1Base.p[1]]);
        g1s[1] = signature;
        g2s[0] = pubkey;
        g2s[1] = G2Point([g2GenXA, g2GenXB, g2GenYA, g2GenYB]);
        return pairing(g1s, g2s);
    }

    function negateG1(G1Point memory p)
        internal
        pure
        returns (G1Point memory neg)
    {
        neg.p[0] = p.p[0];
        neg.p[1] = P - p.p[1];
    }

    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    //
    // Cribbed from https://gist.github.com/BjornvdLaan/ca6dd4e3993e1ef392f363ec27fe74c4
    function pairing(G1Point[] memory p1, G2Point[] memory p2)
        internal
        view
        returns (bool)
    {
        require(p1.length == p2.length);
        uint256 elements = p1.length;
        uint256 inputSize = elements * 6;
        uint256[] memory input = new uint256[](inputSize);

        for (uint256 i = 0; i < elements; i++) {
            input[i * 6 + 0] = p1[i].p[0];
            input[i * 6 + 1] = p1[i].p[1];
            input[i * 6 + 2] = p2[i].p[0];
            input[i * 6 + 3] = p2[i].p[1];
            input[i * 6 + 4] = p2[i].p[2];
            input[i * 6 + 5] = p2[i].p[3];
        }

        uint256[1] memory out;
        bool success;

        assembly {
            success := staticcall(
                pairingGasCost,
                8,
                add(input, 0x20),
                mul(inputSize, 0x20),
                out,
                0x20
            )
        }
        require(success);
        return out[0] != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract Debug {
    // Cribbed from https://stackoverflow.com/questions/67893318/solidity-how-to-represent-bytes32-as-string
    function bytesToString(bytes memory _bytes)
        public
        pure
        returns (string memory)
    {
        uint8 i = 0;
        bytes memory bytesArray = new bytes(2 * _bytes.length);
        for (i = 0; i < bytesArray.length; i++) {
            uint8 _f = uint8(_bytes[i / 2] & 0x0f);
            uint8 _l = uint8(_bytes[i / 2] >> 4);

            bytesArray[i] = bytes1(toASCII(_l));
            i = i + 1;
            bytesArray[i] = bytes1(toASCII(_f));
        }
        return string(bytesArray);
    }

    function bytes32ToString(bytes32 s) public pure returns (string memory) {
        bytes memory b = new bytes(32);
        for (uint256 i = 0; i < 32; i++) {
            b[i] = s[i];
        }
        return bytesToString(b);
    }

    function addressToString(address a) public pure returns (string memory) {
        bytes memory b = new bytes(20);
        uint160 ia = uint160(a);
        for (uint8 i = 0; i < 20; i++) {
            b[19 - i] = bytes1(uint8(ia & 0xff));
            ia >>= 8;
        }
        return bytesToString(b);
    }

    function toASCII(uint8 _uint8) public pure returns (uint8) {
        if (_uint8 < 10) {
            return _uint8 + 48;
        } else {
            return _uint8 + 87;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
    constructor(address newOwner)
        ConfirmedOwnerWithProposal(newOwner, address(0))
    {}
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/**
 * @title System level functionality
 * @notice For use by contracts to interact with core L2-specific functionality.
 * Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064.
 */
interface ArbSys {
    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Get Arbitrum block hash (reverts unless currentBlockNum-256 <= arbBlockNum < currentBlockNum)
     * @return block hash
     */
    function arbBlockHash(uint256 arbBlockNum) external view returns (bytes32);

    /**
     * @notice Gets the rollup's unique chain identifier
     * @return Chain identifier as int
     */
    function arbChainID() external view returns (uint256);

    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external view returns (uint256);

    /**
     * @notice Returns 0 since Nitro has no concept of storage gas
     * @return uint 0
     */
    function getStorageGasAvailable() external view returns (uint256);

    /**
     * @notice (deprecated) check if current call is top level (meaning it was triggered by an EoA or a L1 contract)
     * @dev this call has been deprecated and may be removed in a future release
     * @return true if current execution frame is not a call by another L2 contract
     */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param unused argument no longer used
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address unused)
        external
        pure
        returns (address);

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty data.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination)
        external
        payable
        returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @dev it is not possible to execute on the L1 any L2-to-L1 transaction which contains data
     * to a contract address without any code (as enforced by the Bridge contract).
     * @param destination recipient address on L1
     * @param data (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata data)
        external
        payable
        returns (uint256);

    /**
     * @notice Get send Merkle tree state
     * @return size number of sends in the history
     * @return root root hash of the send history
     * @return partials hashes of partial subtrees in the send history tree
     */
    function sendMerkleTreeState()
        external
        view
        returns (
            uint256 size,
            bytes32 root,
            bytes32[] memory partials
        );

    /**
     * @notice creates a send txn from L2 to L1
     * @param position = (level << 192) + leaf = (0 << 192) + leaf = leaf
     */
    event L2ToL1Tx(
        address caller,
        address indexed destination,
        uint256 indexed hash,
        uint256 indexed position,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /// @dev DEPRECATED in favour of the new L2ToL1Tx event above after the nitro upgrade
    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint256 indexed uniqueId,
        uint256 indexed batchNumber,
        uint256 indexInBatch,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /**
     * @notice logs a merkle branch for proof synthesis
     * @param reserved an index meant only to align the 4th index with L2ToL1Transaction's 4th event
     * @param hash the merkle hash
     * @param position = (level << 192) + leaf
     */
    event SendMerkleUpdate(
        uint256 indexed reserved,
        bytes32 indexed hash,
        uint256 indexed position
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface KeyDataStruct {
    struct KeyData {
        bytes publicKey; // distrbuted key
        bytes32[] hashes; // hashes of shares used to construct key
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/TypeAndVersionInterface.sol";

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

interface TypeAndVersionInterface {
    function typeAndVersion() external pure returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
    function owner() external returns (address);

    function transferOwnership(address recipient) external;

    function acceptOwnership() external;
}