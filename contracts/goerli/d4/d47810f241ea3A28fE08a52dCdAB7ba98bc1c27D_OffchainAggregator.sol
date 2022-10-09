/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

pragma solidity 0.6.9;

/**
 * @title The Owned contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract Owned {

  address public owner;
  address private pendingOwner;

  event OwnershipTransferRequested(
    address indexed from,
    address indexed to
  );
  event OwnershipTransferred(
    address indexed from,
    address indexed to
  );

  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address _to)
    external
    onlyOwner()
  {
    pendingOwner = _to;

    emit OwnershipTransferRequested(owner, _to);
  }

  /**
   * @dev Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership()
    external
  {
    require(msg.sender == pendingOwner, "Must be proposed owner");

    address oldOwner = owner;
    owner = msg.sender;
    pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @dev Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "Only callable by owner");
    _;
  }

}

contract OffchainAggregator is Owned {

  uint256 constant private maxUint32 = (1 << 32) - 1;

  // Name of the feed
  string internal s_description;

  // Answers are stored in fixed-point format, with this many digits of precision
  uint8 immutable public  s_decimals;

  // Lowest answer the system is allowed to report in response to transmissions
  int192 immutable public minAnswer;

  // Highest answer the system is allowed to report in response to transmissions
  int192 immutable public maxAnswer;

  // Transmission records the answer from the transmit transaction at time timestamp
  struct Transmission {
    int192 answer; // 192 bits ought to be enough for anyone
    uint64 timestamp;
  }
  mapping(uint32 /* aggregator round ID */ => Transmission) internal s_transmissions;

  // Transmitters
  address[] internal s_transmitters;

  //
  uint32 s_latestRoundId;

  //
  string constant private V3_NO_DATA_ERROR = "No data present";

  constructor(
    int192 _minAnswer,
    int192 _maxAnswer,
    uint8 _decimals,
    string memory _description
    ) 
    public Owned() 
  {
    s_decimals = _decimals;
    s_description = _description;
    minAnswer = _minAnswer;
    maxAnswer = _maxAnswer;
    s_latestRoundId = 0;
  }

  function description()
    external
    view
    returns (string memory)
  {
      return s_description;
  }

  function decimals()
    external
    view
    returns (uint8)
  {
    return s_decimals;
  }

  /**
   * @notice median from the most recent report
   */
  function latestAnswer()
    public
    view
    virtual
    returns (int256)
  {
    return s_transmissions[s_latestRoundId].answer;
  }

  /**
   * @notice timestamp of block in which last report was transmitted
   */
  function latestTimestamp()
    public
    view
    virtual
    returns (uint256)
  {
    return s_transmissions[s_latestRoundId].timestamp;
  }

  /**
   * @notice Aggregator round (NOT OCR round) in which last report was transmitted
   */
  function latestRound()
    public
    view
    virtual
    returns (uint256)
  {
    return s_latestRoundId;
  }

  /**
   * @notice median of report from given aggregator round (NOT OCR round)
   * @param _roundId the aggregator round of the target report
   */
  function getAnswer(uint256 _roundId)
    public
    view
    virtual
    returns (int256)
  {
    if (_roundId > 0xFFFFFFFF) { return 0; }
    return s_transmissions[uint32(_roundId)].answer;
  }

/*
 * @notice details for the given aggregator round
 * @param _roundId target aggregator round (NOT OCR round). Must fit in uint32
 * @return roundId _roundId
 * @return answer median of report from given _roundId
 * @return startedAt timestamp of block in which report from given _roundId was transmitted
 * @return updatedAt timestamp of block in which report from given _roundId was transmitted
 * @return answeredInRound _roundId
 */
  function getRoundData(uint80 _roundId)
    public
    view
    virtual
    returns (
      uint80 roundId,
      int256 answer,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    require(_roundId <= 0xFFFFFFFF, V3_NO_DATA_ERROR);
    Transmission memory transmission = s_transmissions[uint32(_roundId)];
    return (
      _roundId,
      transmission.answer,
      transmission.timestamp,
      _roundId
    );
  }

  /*
   * @notice aggregator details for the most recently transmitted report
   * @return roundId aggregator round of latest report (NOT OCR round)
   * @return answer median of latest report
   * @return startedAt timestamp of block containing latest report
   * @return updatedAt timestamp of block containing latest report
   * @return answeredInRound aggregator round of latest report
   */
  function latestRoundData()
    public
    view
    virtual
    returns (
      uint80 roundId,
      int256 answer,
      uint256 updatedAt
    )
  {
    roundId = s_latestRoundId;

    // Skipped for compatability with existing FluxAggregator in which latestRoundData never reverts.
    // require(roundId != 0, V3_NO_DATA_ERROR);

    Transmission memory transmission = s_transmissions[uint32(roundId)];
    return (
      roundId,
      transmission.answer,
      transmission.timestamp
    );
  }

  //
  function setTransmitters(
    address[] calldata _transmitters
  )
  external
  onlyOwner()
  {
    while (s_transmitters.length != 0) { // remove any old transmitter addresses
      s_transmitters.pop();
    }

    for (uint i = 0; i < _transmitters.length; i++) { // add new signer/transmitter addresses
      s_transmitters.push(_transmitters[i]);
    }
  }

  /**
   * @return list of addresses permitted to transmit reports to this contract

   * @dev The list will match the order used to specify the transmitter during setConfig
   */
  function transmitters()
    external
    view
    returns(address[] memory)
  {
      return s_transmitters;
  }

  modifier onlyTransmitter() {
    uint8 flag = 0;
    for(uint i = 0; i < s_transmitters.length; i++) {
      if (s_transmitters[i] == msg.sender) {
        flag = 1;
        continue;
      }
    }
    require(flag != 0, "transmitter need to be authorized");
    _;
  }

  //
  function transmit(
    int192 _answer
  )
    onlyTransmitter 
    external
  {
    require(minAnswer <= _answer && _answer <= maxAnswer, "answer is out of min-max range");

    s_latestRoundId = s_latestRoundId + 1;
    s_transmissions[s_latestRoundId] = Transmission(_answer, uint64(block.timestamp));
  }
}