// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.5.16;
import "./GroupFeed.sol";


contract CollectionRegistry {

    address public admin;
    mapping(address => mapping(uint256 => address)) public getFeeds;
    mapping(address => bytes32) public getMerkleRoot;
    address[] public allFeeds;

    event MerkleRootChanged(address collection, bytes32 merkleRoot);
    event FeedCreated(address indexed collection, uint256 groupId, address feed, uint);
    event NewAdmin(address oldAdmin, address newAdmin);

    constructor() public {
        admin = msg.sender;
    }

    function setMerkleRoot(address collection, bytes32 _merkleRoot) public onlyAdmin() {
        // require(getMerkleRoot[collection] == bytes32(0), "CollectionRegistry: Merkle root already set");
        getMerkleRoot[collection] = _merkleRoot;
        emit MerkleRootChanged(collection, _merkleRoot);
    }

    function createFeed(address collection, uint256 groupId) external returns (address feed) {
        require(getFeeds[collection][groupId] == address(0), 'CollectionRegistry: FEED_EXISTS');
        feed = address(new GroupFeed());
        GroupFeed(feed).initialize(collection, groupId);
        getFeeds[collection][groupId] = feed;
        allFeeds.push(feed);
        emit FeedCreated(collection, groupId, feed, allFeeds.length);
    }

    function updateAnswer(address collection, uint256 groupId, int256 _answer) public onlyAdmin() {
        _updateAnswer(collection, groupId, _answer);
    }

    function _updateAnswer(address collection, uint256 groupId, int256 _answer) private {
        address feed = getFeeds[collection][groupId];
        if (feed == address(0)) {
            // create feed
            feed = this.createFeed(collection, groupId);
        }
        // require(feed != address(0), 'CollectionRegistry: FEED_NOT_EXISTS');
        GroupFeed(feed).updateAnswer(_answer);
    }

    function batchUpdateAnswer(address[] memory collection, uint256[] memory groupId, int256[] memory _answer) public onlyAdmin() {
        for (uint j = 0; j < collection.length; j++) {
            _updateAnswer(collection[j], groupId[j], _answer[j]);
        }
    }

    function verifyProof(
        bytes32 root,
        bytes32 leaf,
        bytes32[] memory proof
    )
        private
        pure
        returns (bool)
    {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }

    function getAssetPrice(address collection, uint256 tokenId, uint256 groupId, bytes32[] calldata merkleProof) external view returns (int256) {
        address feed = getFeeds[collection][groupId];
        bytes32 merkleRoot = getMerkleRoot[collection];
        require(feed != address(0), 'CollectionRegistry: FEED_NOT_EXISTS');
        require(merkleRoot != bytes32(0), "CollectionRegistry: Merkle root not set");
        // verify mapping tokenId -> groupId 
        bytes32 leaf = keccak256(abi.encodePacked(tokenId, groupId));
        bool valid = verifyProof(merkleRoot, leaf, merkleProof);
        require(valid, "CollectionRegistry: Valid proof required.");
        return GroupFeed(feed).latestAnswer();
    }

    function setAdmin(address newAdmin) external onlyAdmin() {
        address oldAdmin = admin;
        admin = newAdmin;
        emit NewAdmin(oldAdmin, newAdmin);
    }

    modifier onlyAdmin() {
      require(msg.sender == admin, "only admin may call");
      _;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.5.16;

import "./AggregatorV2V3Interface.sol";

contract GroupFeed is AggregatorV2V3Interface {
   
  uint256 public constant version = 0;

  uint8 public decimals;
  int256 public latestAnswer;
  uint256 public latestTimestamp;
  uint256 public latestRound;

  address public registry;
  address public collection;
  uint256 public groupId;

  mapping(uint256 => int256) public getAnswer;
  mapping(uint256 => uint256) public getTimestamp;
  mapping(uint256 => uint256) private getStartedAt;

  constructor() public {
    registry = msg.sender;
  }

  function initialize(address _collection, uint256 _groupId) external {
    require(msg.sender == registry, 'GroupFeed: FORBIDDEN');
    collection = _collection;
    groupId = _groupId;
  }

  function updateAnswer(int256 _answer) public onlyRegistry() {
    latestAnswer = _answer;
    latestTimestamp = block.timestamp;
    latestRound++;
    getAnswer[latestRound] = _answer;
    getTimestamp[latestRound] = block.timestamp;
    getStartedAt[latestRound] = block.timestamp;
  }

  function updateRoundData(
    uint80 _roundId,
    int256 _answer,
    uint256 _timestamp,
    uint256 _startedAt
  ) public  onlyRegistry() {
    latestRound = _roundId;
    latestAnswer = _answer;
    latestTimestamp = _timestamp;
    getAnswer[latestRound] = _answer;
    getTimestamp[latestRound] = _timestamp;
    getStartedAt[latestRound] = _startedAt;
  }

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return (_roundId, getAnswer[_roundId], getStartedAt[_roundId], getTimestamp[_roundId], _roundId);
  }

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return (
      uint80(latestRound),
      getAnswer[latestRound],
      getStartedAt[latestRound],
      getTimestamp[latestRound],
      uint80(latestRound)
    );
  }

  function description() external view returns (string memory) {
    return "v0.0.1/GroupFeed.sol";
  }

  modifier onlyRegistry() {
    require(msg.sender == registry, "only registry may call");
    _;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.5.16;

/**
 * @title The V2 & V3 Aggregator Interface
 * @notice Solidity V0.5 does not allow interfaces to inherit from other
 * interfaces so this contract is a combination of v0.5 AggregatorInterface.sol
 * and v0.5 AggregatorV3Interface.sol.
 */
interface AggregatorV2V3Interface {
  //
  // V2 Interface:
  //
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);

  //
  // V3 Interface:
  //
  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}