pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "./dependencies/TheGraph/IController.sol";
import "./dependencies/TheGraph/IStaking.sol";
import "./dependencies/TheGraph/IDisputeManager.sol";
import "./SubgraphBridgeHelpers.sol";

/**
 * @title SubgraphBridge
 * @dev SubgraphBridge is a contract that allows us to bridge subgraph data from The Graph's Decentralized Network to Ethereum in a cryptoeconomically secure manner.
 * @author Soulbound Labs (Connor Dunham, Alexander Gusev, and Jordan Rein)
 */
contract SubgraphBridgeManager is SubgraphBridgeManagerHelpers {
    address public theGraphStaking;
    address public theGraphDisputeManager;

    /**
    @notice A mapping storing blockhashes -> blocknumber
    */
    mapping(bytes32 => uint256) public pinnedBlocks;

    /**
    @notice A mapping storing subgraphBridgID -> SubgraphBridge
     */
    mapping(bytes32 => SubgraphBridge) public subgraphBridges;

    /**
     *@notice A mapping storing subgraphBridgeID -> RequestCID -> SubgraphBridgeProposals
     */
    mapping(bytes32 => mapping(bytes32 => SubgraphBridgeProposals))
        public subgraphBridgeProposals;

    /**
     *@notice A mapping storing subgraphBridgeID -> RequestCID -> ResponseData (encoded as uint256)
     */
    mapping(bytes32 => mapping(bytes32 => uint256)) public subgraphBridgeData;

    /**
     *@notice A mapping storing requestCID -> DisputeID Array
     */
    mapping(bytes32 => bytes32[]) public queryDisputes;

    event SubgraphQueryDisputeCreated(
        bytes32 indexed subgraphBridgeID,
        bytes32 indexed requestCID,
        bytes32 disputeID
    );

    event SubgraphBridgeCreation(
        address bridgeCreator,
        bytes32 subgraphBridgeId,
        bytes32 subgraphDeploymentID,
        bytes queryFirstChunk,
        bytes queryLastChunk,
        uint256 responseDataType,
        uint208 proposalFreezePeriod,
        uint16 responseDataOffset,
        uint256 minimumSlashableGRT
    );

    event SubgraphResponseAdded(
        address queryBridger,
        bytes32 subgraphBridgeID,
        bytes32 subgraphDeploymentID,
        string response,
        bytes attestationData
    );

    event QueryResultFinalized(
        bytes32 subgraphBridgeID,
        bytes32 requestCID,
        string response
    );

    constructor(address staking, address disputeManager) {
        theGraphStaking = staking;
        theGraphDisputeManager = disputeManager;
    }

    // ============================================================
    // PUBLIC FUNCTIONS TO BE USED BY THE MASSES
    // ============================================================

    /**
     *@notice creates a query bridge
     *@param subgraphBridge the subgraph bridge to be created
     */
    function createSubgraphBridge(SubgraphBridge memory subgraphBridge) public {
        bytes32 subgraphBridgeID = _subgraphBridgeID(subgraphBridge); // set the subgraphId to the hashed SubgraphBridge
        subgraphBridges[subgraphBridgeID] = subgraphBridge;
        emit SubgraphBridgeCreation(
            msg.sender,
            subgraphBridgeID,
            subgraphBridge.subgraphDeploymentID,
            subgraphBridge.queryFirstChunk,
            subgraphBridge.queryLastChunk,
            uint256(subgraphBridge.responseDataType),
            subgraphBridge.proposalFreezePeriod,
            subgraphBridge.responseDataOffset,
            subgraphBridge.minimumSlashableGRT
        );
    }

    /**
     *@notice this function is used to provide an attestation for a query
     *@param blockNumber, the block number of the block that the request was made for
     *@param subgraphBridgeID, the ID of the subgraph bridge
     *@param response, the response of the query
     *@param attestationData the attestation of the response
     */

    function postSubgraphResponse(
        uint256 blockNumber,
        bytes32 subgraphBridgeID,
        string calldata response,
        bytes calldata attestationData
    ) public {
        bytes32 blockHash = blockhash(blockNumber);

        require(pinnedBlocks[blockHash] != 0, "Block not pinned");

        require(
            subgraphBridges[subgraphBridgeID].responseDataOffset != 0,
            "query bridge doesn't exist"
        );

        IDisputeManager.Attestation memory attestation = parseAttestation(
            attestationData
        );
        require(
            queryAndResponseMatchAttestation(
                blockHash,
                subgraphBridgeID,
                response,
                attestation
            ),
            "query/response != attestation"
        );

        // get indexer's slashable stake from staking contract
        address attestationIndexer = IDisputeManager(theGraphDisputeManager)
            .getAttestationIndexer(attestation);
        uint256 indexerStake = IStaking(theGraphStaking).getIndexerStakedTokens(
            attestationIndexer
        );

        require(indexerStake > 0, "indexer doesn't have slashable stake");

        SubgraphBridgeProposals storage proposals = subgraphBridgeProposals[
            subgraphBridgeID
        ][attestation.requestCID];

        if (
            proposals
                .stake[attestation.responseCID]
                .totalStake
                .attestationStake == 0
        ) {
            proposals.proposalCount = proposals.proposalCount + 1;
        }
        // if this is the first proposal, use this block number to start the dispute window
        uint256 firstBlockNumber = proposals.responseProposals.length > 0
            ? proposals.responseProposals[0].proposalBlockNumber
            : block.number;

        proposals.responseProposals.push(
            ResponseProposal(
                attestation.responseCID,
                attestationData,
                firstBlockNumber
            )
        );

        // update stake values
        proposals
            .stake[attestation.responseCID]
            .accountStake[attestationIndexer]
            .attestationStake = indexerStake;

        proposals.stake[attestation.responseCID].totalStake.attestationStake =
            proposals
                .stake[attestation.responseCID]
                .totalStake
                .attestationStake +
            indexerStake;

        proposals.totalStake.attestationStake =
            proposals.totalStake.attestationStake +
            indexerStake;

        // loop over all of the responseProposals and check if the responseCID is equal for all of them, if not open a new conflict
        for (uint256 i; i < proposals.responseProposals.length; i++) {
            bytes32 _responseCID = proposals.responseProposals[i].responseCID;
            if (attestation.responseCID != _responseCID) {
                // create a query dispute
                createQueryDispute(
                    subgraphBridgeID,
                    attestation.requestCID,
                    attestation.responseCID, //responseCID of this proposal
                    _responseCID, //responseCID of the conflicting proposal
                    i, // index of the conflicting proposal
                    proposals.responseProposals.length - 1 // index of the submitted proposal
                );
            }
        }

        emit SubgraphResponseAdded(
            msg.sender,
            subgraphBridgeID,
            attestation.subgraphDeploymentID,
            response,
            attestationData
        );
    }

    /**
     *@notice this function allows you to use a non disputed query response after the dispute period has ended
     *@param subgraphBridgeID, the ID of the subgraph bridge
     *@param response, the response of the query
     *@param attestationData, the attestation of the response
     */

    function certifySubgraphResponse(
        bytes32 subgraphBridgeID,
        string calldata response,
        bytes calldata attestationData // contains cid of response and request
    ) public {
        IDisputeManager.Attestation memory attestation = parseAttestation(
            attestationData
        );
        bytes32 requestCID = attestation.requestCID;
        require(
            !isQueryDisputed(attestation.requestCID),
            "certifySubgraphResponse: There is a query dispute for this request"
        );

        uint208 proposalFreezePeriod = subgraphBridges[subgraphBridgeID]
            .proposalFreezePeriod;

        uint256 minimumSlashableGRT = subgraphBridges[subgraphBridgeID]
            .minimumSlashableGRT;

        SubgraphBridgeProposals storage proposals = subgraphBridgeProposals[
            subgraphBridgeID
        ][requestCID];

        require(
            proposals.proposalCount >= 1,
            "proposalCount must be at least 1"
        );

        uint256 proposalFirstBlock = proposals
            .responseProposals[0]
            .proposalBlockNumber;

        require(
            proposalFirstBlock + proposalFreezePeriod <= block.number,
            "proposal still frozen"
        );

        bytes32 responseCID = keccak256(abi.encodePacked(response));

        require(
            proposals.stake[responseCID].totalStake.attestationStake >
                minimumSlashableGRT,
            "not enough stake"
        );

        _extractData(subgraphBridgeID, requestCID, response);
        emit QueryResultFinalized(subgraphBridgeID, requestCID, response);
    }

    // ============================================================
    // INTERNAL AND HELPER FUNCTIONS
    // ============================================================

    /**
     *@notice this function is used to open a dispute for two conflicting proposals
     *@param subgraphBridgeID, the ID of the subgraph bridge
     *@param requestCID, the CID of the request
     *@param responseCID1, the CID of the first response
     *@param responseCID2, the CID of the second response
     *@param attestationIndex1, the index of the attestation for the first response within subgraphBridgeProposals
     *@param attestationIndex2, the index of the attestation for the second response within subgraphBridgeProposals
     */
    function createQueryDispute(
        bytes32 subgraphBridgeID,
        bytes32 requestCID,
        bytes32 responseCID1,
        bytes32 responseCID2,
        uint256 attestationIndex1,
        uint256 attestationIndex2
    ) internal returns (bytes32 disputeID1, bytes32 disputeID2) {
        require(
            subgraphBridges[subgraphBridgeID].responseDataOffset != 0,
            "query bridge doesn't exist"
        );

        SubgraphBridgeProposals storage proposals = subgraphBridgeProposals[
            subgraphBridgeID
        ][requestCID];

        require(
            proposals.stake[responseCID1].totalStake.attestationStake > 0,
            "responseCID1 doesn't exist"
        );
        require(
            proposals.stake[responseCID2].totalStake.attestationStake > 0,
            "responseCID2 doesn't exist"
        );

        require(
            responseCID1 != responseCID2,
            "responseCID1 and responseCID2 are the same"
        );

        bytes memory attestationBytes1 = proposals
            .responseProposals[attestationIndex1]
            .attestationData;

        bytes memory attestationBytes2 = proposals
            .responseProposals[attestationIndex2]
            .attestationData;

        // open a dispute in the dispute manager contract
        (bytes32 _disputeID1, bytes32 _disputeID2) = IDisputeManager(
            theGraphDisputeManager
        ).createQueryDisputeConflict(attestationBytes1, attestationBytes2);

        // push the disputeIDs to the disputeID array
        queryDisputes[requestCID].push(_disputeID1);
        queryDisputes[requestCID].push(_disputeID2);

        // emit a SubgrapuQueryDisputed event for both disputes
        emit SubgraphQueryDisputeCreated(
            subgraphBridgeID,
            requestCID,
            _disputeID1
        );

        emit SubgraphQueryDisputeCreated(
            subgraphBridgeID,
            requestCID,
            _disputeID2
        );
        return (_disputeID1, _disputeID2);
    }

    /**
     *@notice this function checks if a query is being disputed
     *@param requestCID the requestCID of the query
     *@return true if the query is being disputed, false if not
     */
    function isQueryDisputed(bytes32 requestCID) public view returns (bool) {
        for (uint256 i = 0; i < queryDisputes[requestCID].length; i++) {
            if (
                IDisputeManager(theGraphDisputeManager).isDisputeCreated(
                    queryDisputes[requestCID][i]
                )
            ) {
                return true;
            }
        }
        return false;
    }

    /**
     @notice this function is used to pin a blockhash to a blocknumber
     @param blockNumber the blocknumber to pin the blockhash to
     */
    function pinBlockHash(uint256 blockNumber) public {
        require(
            blockNumber > block.number - 256,
            "Pinned block must be within the last 256 blocks"
        );
        require(
            pinnedBlocks[blockhash(blockNumber)] == 0,
            "pinBlockHash: already pinned!"
        );
        pinnedBlocks[blockhash(blockNumber)] = blockNumber;
    }

    //TODO: HANDLE ALL DATA TYPES
    /**
     *@notice this function takes in a subgraphBridgeID, a requestCID, and a responseCID and extracts the data from the responseCID and stores it in the subgraphBridgeData mapping
     *@param subgraphBridgeID, the ID of the subgraph bridge
     *@param requestCID, the CID of the request
     *@param response, the response string from the subgraph
     */
    function _extractData(
        bytes32 subgraphBridgeID,
        bytes32 requestCID,
        string calldata response
    ) private {
        BridgeDataType _type = subgraphBridges[subgraphBridgeID]
            .responseDataType;

        if (_type == BridgeDataType.UINT) {
            subgraphBridgeData[subgraphBridgeID][requestCID] = _uintFromString(
                response,
                subgraphBridges[subgraphBridgeID].responseDataOffset
            );
        } else if (_type == BridgeDataType.ADDRESS) {
            //DO SOMETHING ELSE
            /*
            subgraphBridgeData[subgraphBridgeID][requestCID] = _addressFromString(
                response,
                subgraphBridges[subgraphBridgeID].responseDataOffset
            );
            */
        } else if (_type == BridgeDataType.BYTES32) {
            //DO ANOTHER THING
            subgraphBridgeData[subgraphBridgeID][requestCID] = uint256(
                _bytes32FromString(
                    response,
                    subgraphBridges[subgraphBridgeID].responseDataOffset
                )
            );
        }
    }

    /**
     *@notice this function checks if a query for a subgraphBridgeId matches the attestation
     *@param blockHash, the blockhash we are serving data for
     *@param subgraphBridgeID, the subgraph bridge id
     *@param response, the response from the subgraph query
     *@param attestation, the attestation from the indexer
     *@return bool, returns true if everything matches, fails otherwise
     */
    function queryAndResponseMatchAttestation(
        bytes32 blockHash,
        bytes32 subgraphBridgeID,
        string calldata response,
        IDisputeManager.Attestation memory attestation
    ) public view returns (bool) {
        require(
            attestation.requestCID ==
                _generateQueryRequestCID(blockHash, subgraphBridgeID),
            "queryAndResponseMatchAttestation: RequestCID Doesn't Match"
        );
        require(
            attestation.responseCID == keccak256(abi.encodePacked(response)),
            "queryAndResponseMatchAttestation: ResponseCID Doesn't Match"
        );
        require(
            subgraphBridges[subgraphBridgeID].subgraphDeploymentID ==
                attestation.subgraphDeploymentID,
            "queryAndResponseMatchAttestation: SubgraphDeploymentID Doesn't Match"
        );
        return true;
    }

    /**
     * @dev Parse the bytes attestation into a struct from `_data`.
     * @return Attestation struct
     */
    function parseAttestation(bytes memory _data)
        public
        pure
        returns (IDisputeManager.Attestation memory)
    {
        // Check attestation data length
        require(
            _data.length == ATTESTATION_SIZE_BYTES,
            "Attestation must be 161 bytes long"
        );

        // Decode receipt
        (
            bytes32 requestCID,
            bytes32 responseCID,
            bytes32 subgraphDeploymentID
        ) = abi.decode(_data, (bytes32, bytes32, bytes32));

        // Decode signature
        // Signature is expected to be in the order defined in the Attestation struct
        bytes32 r = _toBytes32(_data, SIG_R_OFFSET);
        bytes32 s = _toBytes32(_data, SIG_S_OFFSET);
        uint8 v = _toUint8(_data, SIG_V_OFFSET);

        return
            IDisputeManager.Attestation(
                requestCID,
                responseCID,
                subgraphDeploymentID,
                r,
                s,
                v
            );
    }

    /**
     *@dev this function generates the requestCID for the query at a blocknumber
     *@param _blockhash, the blockchash we are querying
     *@param _subgraphBridgeId, the id of the subgraphBridge
     *@return the keccak256 hash of the request
     */
    function _generateQueryRequestCID(
        bytes32 _blockhash,
        bytes32 _subgraphBridgeId
    ) public view returns (bytes32) {
        SubgraphBridge storage bridge = subgraphBridges[_subgraphBridgeId];

        bytes memory firstChunk = bridge.queryFirstChunk;
        bytes memory blockHash = toHexBytes(_blockhash);
        bytes memory lastChunk = bridge.queryLastChunk;
        return keccak256(bytes.concat(firstChunk, blockHash, lastChunk));
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

// we are putting all of the internal and internal functions in this contract

contract SubgraphBridgeManagerHelpers {
    // Attestation size is the sum of the receipt (96) + signature (65)
    uint256 internal constant ATTESTATION_SIZE_BYTES =
        RECEIPT_SIZE_BYTES + SIG_SIZE_BYTES;
    uint256 internal constant RECEIPT_SIZE_BYTES = 96;

    uint256 internal constant SIG_R_LENGTH = 32;
    uint256 internal constant SIG_S_LENGTH = 32;
    uint256 internal constant SIG_V_LENGTH = 1;
    uint256 internal constant SIG_R_OFFSET = RECEIPT_SIZE_BYTES;
    uint256 internal constant SIG_S_OFFSET = RECEIPT_SIZE_BYTES + SIG_R_LENGTH;
    uint256 internal constant SIG_V_OFFSET =
        RECEIPT_SIZE_BYTES + SIG_R_LENGTH + SIG_S_LENGTH;
    uint256 internal constant SIG_SIZE_BYTES =
        SIG_R_LENGTH + SIG_S_LENGTH + SIG_V_LENGTH;

    uint256 internal constant UINT8_BYTE_LENGTH = 1;
    uint256 internal constant BYTES32_BYTE_LENGTH = 32;
    uint256 internal constant BLOCKHASH_LENGTH = 66;

    uint256 MAX_UINT_256 =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // stored in mapping where (ID == attestation.requestCID)
    struct SubgraphBridgeProposals {
        // {attestation.responseCID} -> {stake}
        mapping(bytes32 => BridgeStake) stake;
        ResponseProposal[] responseProposals;
        BridgeStakeTokens totalStake;
        uint256 proposalCount;
    }

    struct ResponseProposal {
        bytes32 responseCID;
        bytes attestationData;
        uint256 proposalBlockNumber;
    }

    struct BridgeStake {
        BridgeStakeTokens totalStake;
        mapping(address => BridgeStakeTokens) accountStake;
    }

    struct BridgeStakeTokens {
        uint256 attestationStake; // Slashable GRT staked by indexers via the staking contract
        uint256 tokenStake; // GRT staked by oracles through Subgraph Bridge contract
    }

    // TODO: Create a function to decode this data.
    enum BridgeDataType {
        ADDRESS,
        BYTES32,
        UINT
        // todo: string
    }

    struct SubgraphBridge {
        // QUERY AND RESPONSE CONFIG
        bytes queryFirstChunk; // the first bit of the query up to where the blockhash starts
        bytes queryLastChunk; // the last bit of the query from where the blockhash ends to the end of query
        BridgeDataType responseDataType; // data type to be extracted from graphQL response string
        bytes32 subgraphDeploymentID; // subgraph being queried
        // DISPUTE HANLDING CONFIG
        uint208 proposalFreezePeriod; // undisputed queries can only be executed after this many blocks
        uint16 responseDataOffset; // index where the data starts in the response string
        uint256 minimumSlashableGRT; // minimum slashable GRT staked by indexers in order for undisputed proposal to pass
    }

    function _subgraphBridgeID(SubgraphBridge memory subgraphBridge)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(subgraphBridge));
    }

    function _bytes32FromString(string calldata fullString, uint16 dataOffset)
        public
        pure
        returns (bytes32)
    {
        string memory blockHashSlice = string(
            fullString[dataOffset:dataOffset + 64]
        );
        return _bytes32FromHex(blockHashSlice);
    }

    function _uintFromString(string calldata str, uint256 offset)
        public
        view
        returns (uint256)
    {
        (uint256 val, ) = _uintFromByteString(bytes(str), offset);
        return val;
    }

    // takes a full query string or response string and extracts a uint of unknown length beginning at the specified index
    function _uintFromByteString(bytes memory bString, uint256 offset)
        public
        view
        returns (uint256 value, uint256 depth)
    {
        bytes1 char = bString[offset];
        bool isEscapeChar = (char == 0x7D || char == 0x2C || char == 0x22); // ,}"
        if (isEscapeChar) {
            return (0, 0);
        }

        bool isDigit = (uint8(char) >= 48) && (uint8(char) <= 57); // 0-9
        require(isDigit, "invalid char");

        (uint256 trailingVal, uint256 trailingDepth) = _uintFromByteString(
            bString,
            offset + 1
        );
        return (
            trailingVal + (uint8(char) - 48) * 10**(trailingDepth),
            trailingDepth + 1
        );
    }

    // Convert an hexadecimal character to raw byte
    function _fromHexChar(uint8 c) public pure returns (uint8 _rawByte) {
        if (bytes1(c) >= bytes1("0") && bytes1(c) <= bytes1("9")) {
            return c - uint8(bytes1("0"));
        }
        if (bytes1(c) >= bytes1("a") && bytes1(c) <= bytes1("f")) {
            return 10 + c - uint8(bytes1("a"));
        }
    }

    // Convert hexadecimal string to raw bytes32
    function _bytes32FromHex(string memory s)
        public
        pure
        returns (bytes32 result)
    {
        bytes memory ss = bytes(s);
        require(ss.length == 64, "length of hex string must be 64");
        bytes memory bytesResult = new bytes(32);
        for (uint256 i = 0; i < ss.length / 2; ++i) {
            bytesResult[i] = bytes1(
                _fromHexChar(uint8(ss[2 * i])) *
                    16 +
                    _fromHexChar(uint8(ss[2 * i + 1]))
            );
        }

        assembly {
            result := mload(add(bytesResult, 32))
        }
    }

    /**
     * @dev Parse a uint8 from `_bytes` starting at offset `_start`.
     * @return uint8 value
     */
    function _toUint8(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint8)
    {
        require(
            _bytes.length >= (_start + UINT8_BYTE_LENGTH),
            "Bytes: out of bounds"
        );
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    /**
     * @dev Parse a bytes32 from `_bytes` starting at offset `_start`.
     * @return bytes32 value
     */
    function _toBytes32(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (bytes32)
    {
        require(
            _bytes.length >= (_start + BYTES32_BYTE_LENGTH),
            "Bytes: out of bounds"
        );
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function toHex16(bytes16 data) internal pure returns (bytes32 result) {
        result =
            (bytes32(data) &
                0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000) |
            ((bytes32(data) &
                0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >>
                64);
        result =
            (result &
                0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000) |
            ((result &
                0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >>
                32);
        result =
            (result &
                0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000) |
            ((result &
                0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >>
                16);
        result =
            (result &
                0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000) |
            ((result &
                0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >>
                8);
        result =
            ((result &
                0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >>
                4) |
            ((result &
                0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >>
                8);
        result = bytes32(
            0x3030303030303030303030303030303030303030303030303030303030303030 +
                uint256(result) +
                (((uint256(result) +
                    0x0606060606060606060606060606060606060606060606060606060606060606) >>
                    4) &
                    // 0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) * 7);
                    0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) *
                39
        );
    }

    function toHexBytes(bytes32 data) public pure returns (bytes memory) {
        return
            abi.encodePacked(
                "0x",
                toHex16(bytes16(data)),
                toHex16(bytes16(data << 128))
            );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface IController {
    function getGovernor() external view returns (address);

    // -- Registry --

    function setContractProxy(bytes32 _id, address _contractAddress) external;

    function unsetContractProxy(bytes32 _id) external;

    function updateController(bytes32 _id, address _controller) external;

    function getContractProxy(bytes32 _id) external view returns (address);

    // -- Pausing --

    function setPartialPaused(bool _partialPaused) external;

    function setPaused(bool _paused) external;

    function setPauseGuardian(address _newPauseGuardian) external;

    function paused() external view returns (bool);

    function partialPaused() external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;
pragma abicoder v2;

interface IDisputeManager {
    // -- Dispute --

    enum DisputeType {
        Null,
        IndexingDispute,
        QueryDispute
    }

    // Disputes contain info necessary for the Arbitrator to verify and resolve
    struct Dispute {
        address indexer;
        address fisherman;
        uint256 deposit;
        bytes32 relatedDisputeID;
        DisputeType disputeType;
    }

    // -- Attestation --

    // Receipt content sent from indexer in response to request
    struct Receipt {
        bytes32 requestCID;
        bytes32 responseCID;
        bytes32 subgraphDeploymentID;
    }

    // Attestation sent from indexer in response to a request
    struct Attestation {
        bytes32 requestCID;
        bytes32 responseCID;
        bytes32 subgraphDeploymentID;
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    // -- Configuration --

    function setArbitrator(address _arbitrator) external;

    function setMinimumDeposit(uint256 _minimumDeposit) external;

    function setFishermanRewardPercentage(uint32 _percentage) external;

    function setSlashingPercentage(uint32 _qryPercentage, uint32 _idxPercentage)
        external;

    // -- Getters --

    function isDisputeCreated(bytes32 _disputeID) external view returns (bool);

    function encodeHashReceipt(Receipt memory _receipt)
        external
        view
        returns (bytes32);

    function areConflictingAttestations(
        Attestation memory _attestation1,
        Attestation memory _attestation2
    ) external pure returns (bool);

    function getAttestationIndexer(Attestation memory _attestation)
        external
        view
        returns (address);

    // -- Dispute --

    function createQueryDispute(
        bytes calldata _attestationData,
        uint256 _deposit
    ) external returns (bytes32);

    function createQueryDisputeConflict(
        bytes calldata _attestationData1,
        bytes calldata _attestationData2
    ) external returns (bytes32, bytes32);

    function createIndexingDispute(address _allocationID, uint256 _deposit)
        external
        returns (bytes32);

    function acceptDispute(bytes32 _disputeID) external;

    function rejectDispute(bytes32 _disputeID) external;

    function drawDispute(bytes32 _disputeID) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./IStakingData.sol";

interface IStaking is IStakingData {
    // -- Allocation Data --

    /**
     * @dev Possible states an allocation can be
     * States:
     * - Null = indexer == address(0)
     * - Active = not Null && tokens > 0
     * - Closed = Active && closedAtEpoch != 0
     * - Finalized = Closed && closedAtEpoch + channelDisputeEpochs > now()
     * - Claimed = not Null && tokens == 0
     */
    enum AllocationState {
        Null,
        Active,
        Closed,
        Finalized,
        Claimed
    }

    // -- Configuration --

    function setMinimumIndexerStake(uint256 _minimumIndexerStake) external;

    function setThawingPeriod(uint32 _thawingPeriod) external;

    function setCurationPercentage(uint32 _percentage) external;

    function setProtocolPercentage(uint32 _percentage) external;

    function setChannelDisputeEpochs(uint32 _channelDisputeEpochs) external;

    function setMaxAllocationEpochs(uint32 _maxAllocationEpochs) external;

    function setRebateRatio(uint32 _alphaNumerator, uint32 _alphaDenominator) external;

    function setDelegationRatio(uint32 _delegationRatio) external;

    function setDelegationParameters(
        uint32 _indexingRewardCut,
        uint32 _queryFeeCut,
        uint32 _cooldownBlocks
    ) external;

    function setDelegationParametersCooldown(uint32 _blocks) external;

    function setDelegationUnbondingPeriod(uint32 _delegationUnbondingPeriod) external;

    function setDelegationTaxPercentage(uint32 _percentage) external;

    function setSlasher(address _slasher, bool _allowed) external;

    function setAssetHolder(address _assetHolder, bool _allowed) external;

    // -- Operation --

    function setOperator(address _operator, bool _allowed) external;

    function isOperator(address _operator, address _indexer) external view returns (bool);

    // -- Staking --

    function stake(uint256 _tokens) external;

    function stakeTo(address _indexer, uint256 _tokens) external;

    function unstake(uint256 _tokens) external;

    function slash(
        address _indexer,
        uint256 _tokens,
        uint256 _reward,
        address _beneficiary
    ) external;

    function withdraw() external;

    function setRewardsDestination(address _destination) external;

    // -- Delegation --

    function delegate(address _indexer, uint256 _tokens) external returns (uint256);

    function undelegate(address _indexer, uint256 _shares) external returns (uint256);

    function withdrawDelegated(address _indexer, address _newIndexer) external returns (uint256);

    // -- Channel management and allocations --

    function allocate(
        bytes32 _subgraphDeploymentID,
        uint256 _tokens,
        address _allocationID,
        bytes32 _metadata,
        bytes calldata _proof
    ) external;

    function allocateFrom(
        address _indexer,
        bytes32 _subgraphDeploymentID,
        uint256 _tokens,
        address _allocationID,
        bytes32 _metadata,
        bytes calldata _proof
    ) external;

    function closeAllocation(address _allocationID, bytes32 _poi) external;

    function closeAllocationMany(CloseAllocationRequest[] calldata _requests) external;

    function closeAndAllocate(
        address _oldAllocationID,
        bytes32 _poi,
        address _indexer,
        bytes32 _subgraphDeploymentID,
        uint256 _tokens,
        address _allocationID,
        bytes32 _metadata,
        bytes calldata _proof
    ) external;

    function collect(uint256 _tokens, address _allocationID) external;

    function claim(address _allocationID, bool _restake) external;

    function claimMany(address[] calldata _allocationID, bool _restake) external;

    // -- Getters and calculations --

    function hasStake(address _indexer) external view returns (bool);

    function getIndexerStakedTokens(address _indexer) external view returns (uint256);

    function getIndexerCapacity(address _indexer) external view returns (uint256);

    function getAllocation(address _allocationID) external view returns (Allocation memory);

    function getAllocationState(address _allocationID) external view returns (AllocationState);

    function isAllocation(address _allocationID) external view returns (bool);

    function getSubgraphAllocatedTokens(bytes32 _subgraphDeploymentID)
        external
        view
        returns (uint256);

    function getDelegation(address _indexer, address _delegator)
        external
        view
        returns (Delegation memory);

    function isDelegator(address _indexer, address _delegator) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface IStakingData {
    /**
     * @dev Allocate GRT tokens for the purpose of serving queries of a subgraph deployment
     * An allocation is created in the allocate() function and consumed in claim()
     */
    struct Allocation {
        address indexer;
        bytes32 subgraphDeploymentID;
        uint256 tokens; // Tokens allocated to a SubgraphDeployment
        uint256 createdAtEpoch; // Epoch when it was created
        uint256 closedAtEpoch; // Epoch when it was closed
        uint256 collectedFees; // Collected fees for the allocation
        uint256 effectiveAllocation; // Effective allocation when closed
        uint256 accRewardsPerAllocatedToken; // Snapshot used for reward calc
    }

    /**
     * @dev Represents a request to close an allocation with a specific proof of indexing.
     * This is passed when calling closeAllocationMany to define the closing parameters for
     * each allocation.
     */
    struct CloseAllocationRequest {
        address allocationID;
        bytes32 poi;
    }

    // -- Delegation Data --

    /**
     * @dev Delegation pool information. One per indexer.
     */
    struct DelegationPool {
        uint32 cooldownBlocks; // Blocks to wait before updating parameters
        uint32 indexingRewardCut; // in PPM
        uint32 queryFeeCut; // in PPM
        uint256 updatedAtBlock; // Block when the pool was last updated
        uint256 tokens; // Total tokens as pool reserves
        uint256 shares; // Total shares minted in the pool
        mapping(address => Delegation) delegators; // Mapping of delegator => Delegation
    }

    /**
     * @dev Individual delegation data of a delegator in a pool.
     */
    struct Delegation {
        uint256 shares; // Shares owned by a delegator in the pool
        uint256 tokensLocked; // Tokens locked for undelegation
        uint256 tokensLockedUntil; // Block when locked tokens can be withdrawn
    }
}