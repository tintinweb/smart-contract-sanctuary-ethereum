// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./DKGClient.sol";
import "./Debug.sol";
import "./KeyDataStruct.sol";
import "./vendor/ocr2-contracts/OCR2Abstract.sol";
import "./vendor/ocr2-contracts/OwnerIsCreator.sol";

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
        s_latestConfigBlockNumber = uint32(block.number);
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

interface TypeAndVersionInterface {
    function typeAndVersion() external pure returns (string memory);
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