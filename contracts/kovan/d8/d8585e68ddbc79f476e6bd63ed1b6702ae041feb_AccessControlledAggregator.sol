/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

pragma solidity 0.6.6;
library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;
    return c;
  }
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    return c;
  }
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}
library SignedSafeMath {
  int256 constant private _INT256_MIN = -2**255;
  function mul(int256 a, int256 b) internal pure returns (int256) {
    if (a == 0) {
      return 0;
    }
    require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");
    int256 c = a * b;
    require(c / a == b, "SignedSafeMath: multiplication overflow");
    return c;
  }
  function div(int256 a, int256 b) internal pure returns (int256) {
    require(b != 0, "SignedSafeMath: division by zero");
    require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");
    int256 c = a / b;
    return c;
  }
  function sub(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a - b;
    require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");
    return c;
  }
  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");
    return c;
  }
  function avg(int256 _a, int256 _b)
    internal
    pure
    returns (int256)
  {
    if ((_a < 0 && _b > 0) || (_a > 0 && _b < 0)) {
      return add(_a, _b) / 2;
    }
    int256 remainder = (_a % 2 + _b % 2) / 2;
    return add(add(_a / 2, _b / 2), remainder);
  }
}
library Median {
  using SignedSafeMath for int256;
  int256 constant INT_MAX = 2**255-1;
  function calculate(int256[] memory list)
    internal
    pure
    returns (int256)
  {
    return calculateInplace(copy(list));
  }
  function calculateInplace(int256[] memory list)
    internal
    pure
    returns (int256)
  {
    require(0 < list.length, "list must not be empty");
    uint256 len = list.length;
    uint256 middleIndex = len / 2;
    if (len % 2 == 0) {
      int256 median1;
      int256 median2;
      (median1, median2) = quickselectTwo(list, 0, len - 1, middleIndex - 1, middleIndex);
      return SignedSafeMath.avg(median1, median2);
    } else {
      return quickselect(list, 0, len - 1, middleIndex);
    }
  }
  uint256 constant SHORTSELECTTWO_MAX_LENGTH = 7;
  function shortSelectTwo(
    int256[] memory list,
    uint256 lo,
    uint256 hi,
    uint256 k1,
    uint256 k2
  )
    private
    pure
    returns (int256 k1th, int256 k2th)
  {
    uint256 len = hi + 1 - lo;
    int256 x0 = list[lo + 0];
    int256 x1 = 1 < len ? list[lo + 1] : INT_MAX;
    int256 x2 = 2 < len ? list[lo + 2] : INT_MAX;
    int256 x3 = 3 < len ? list[lo + 3] : INT_MAX;
    int256 x4 = 4 < len ? list[lo + 4] : INT_MAX;
    int256 x5 = 5 < len ? list[lo + 5] : INT_MAX;
    int256 x6 = 6 < len ? list[lo + 6] : INT_MAX;
    if (x0 > x1) {(x0, x1) = (x1, x0);}
    if (x2 > x3) {(x2, x3) = (x3, x2);}
    if (x4 > x5) {(x4, x5) = (x5, x4);}
    if (x0 > x2) {(x0, x2) = (x2, x0);}
    if (x1 > x3) {(x1, x3) = (x3, x1);}
    if (x4 > x6) {(x4, x6) = (x6, x4);}
    if (x1 > x2) {(x1, x2) = (x2, x1);}
    if (x5 > x6) {(x5, x6) = (x6, x5);}
    if (x0 > x4) {(x0, x4) = (x4, x0);}
    if (x1 > x5) {(x1, x5) = (x5, x1);}
    if (x2 > x6) {(x2, x6) = (x6, x2);}
    if (x1 > x4) {(x1, x4) = (x4, x1);}
    if (x3 > x6) {(x3, x6) = (x6, x3);}
    if (x2 > x4) {(x2, x4) = (x4, x2);}
    if (x3 > x5) {(x3, x5) = (x5, x3);}
    if (x3 > x4) {(x3, x4) = (x4, x3);}
    uint256 index1 = k1 - lo;
    if (index1 == 0) {k1th = x0;}
    else if (index1 == 1) {k1th = x1;}
    else if (index1 == 2) {k1th = x2;}
    else if (index1 == 3) {k1th = x3;}
    else if (index1 == 4) {k1th = x4;}
    else if (index1 == 5) {k1th = x5;}
    else if (index1 == 6) {k1th = x6;}
    else {revert("k1 out of bounds");}
    uint256 index2 = k2 - lo;
    if (k1 == k2) {return (k1th, k1th);}
    else if (index2 == 0) {return (k1th, x0);}
    else if (index2 == 1) {return (k1th, x1);}
    else if (index2 == 2) {return (k1th, x2);}
    else if (index2 == 3) {return (k1th, x3);}
    else if (index2 == 4) {return (k1th, x4);}
    else if (index2 == 5) {return (k1th, x5);}
    else if (index2 == 6) {return (k1th, x6);}
    else {revert("k2 out of bounds");}
  }
  function quickselect(int256[] memory list, uint256 lo, uint256 hi, uint256 k)
    private
    pure
    returns (int256 kth)
  {
    require(lo <= k);
    require(k <= hi);
    while (lo < hi) {
      if (hi - lo < SHORTSELECTTWO_MAX_LENGTH) {
        int256 ignore;
        (kth, ignore) = shortSelectTwo(list, lo, hi, k, k);
        return kth;
      }
      uint256 pivotIndex = partition(list, lo, hi);
      if (k <= pivotIndex) {
        hi = pivotIndex;
      } else {
        lo = pivotIndex + 1;
      }
    }
    return list[lo];
  }
  function quickselectTwo(
    int256[] memory list,
    uint256 lo,
    uint256 hi,
    uint256 k1,
    uint256 k2
  )
    internal 
    pure
    returns (int256 k1th, int256 k2th)
  {
    require(k1 < k2);
    require(lo <= k1 && k1 <= hi);
    require(lo <= k2 && k2 <= hi);
    while (true) {
      if (hi - lo < SHORTSELECTTWO_MAX_LENGTH) {
        return shortSelectTwo(list, lo, hi, k1, k2);
      }
      uint256 pivotIdx = partition(list, lo, hi);
      if (k2 <= pivotIdx) {
        hi = pivotIdx;
      } else if (pivotIdx < k1) {
        lo = pivotIdx + 1;
      } else {
        assert(k1 <= pivotIdx && pivotIdx < k2);
        k1th = quickselect(list, lo, pivotIdx, k1);
        k2th = quickselect(list, pivotIdx + 1, hi, k2);
        return (k1th, k2th);
      }
    }
  }
  function partition(int256[] memory list, uint256 lo, uint256 hi)
    private
    pure
    returns (uint256)
  {
    int256 pivot = list[(lo + hi) / 2];
    lo -= 1; 
    hi += 1;
    while (true) {
      do {
        lo += 1;
      } while (list[lo] < pivot);
      do {
        hi -= 1;
      } while (list[hi] > pivot);
      if (lo < hi) {
        (list[lo], list[hi]) = (list[hi], list[lo]);
      } else {
        return hi;
      }
    }
  }
  function copy(int256[] memory list)
    private
    pure
    returns(int256[] memory)
  {
    int256[] memory list2 = new int256[](list.length);
    for (uint256 i = 0; i < list.length; i++) {
      list2[i] = list[i];
    }
    return list2;
  }
}
contract Owned {
  address payable public owner;
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
  function transferOwnership(address _to)
    external
    onlyOwner()
  {
    pendingOwner = _to;
    emit OwnershipTransferRequested(owner, _to);
  }
  function acceptOwnership()
    external
  {
    require(msg.sender == pendingOwner, "Must be proposed owner");
    address oldOwner = owner;
    owner = msg.sender;
    pendingOwner = address(0);
    emit OwnershipTransferred(oldOwner, msg.sender);
  }
  modifier onlyOwner() {
    require(msg.sender == owner, "Only callable by owner");
    _;
  }
}
library SafeMath128 {
  function add(uint128 a, uint128 b) internal pure returns (uint128) {
    uint128 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }
  function sub(uint128 a, uint128 b) internal pure returns (uint128) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint128 c = a - b;
    return c;
  }
  function mul(uint128 a, uint128 b) internal pure returns (uint128) {
    if (a == 0) {
      return 0;
    }
    uint128 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }
  function div(uint128 a, uint128 b) internal pure returns (uint128) {
    require(b > 0, "SafeMath: division by zero");
    uint128 c = a / b;
    return c;
  }
  function mod(uint128 a, uint128 b) internal pure returns (uint128) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}
library SafeMath32 {
  function add(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }
  function sub(uint32 a, uint32 b) internal pure returns (uint32) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint32 c = a - b;
    return c;
  }
  function mul(uint32 a, uint32 b) internal pure returns (uint32) {
    if (a == 0) {
      return 0;
    }
    uint32 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }
  function div(uint32 a, uint32 b) internal pure returns (uint32) {
    require(b > 0, "SafeMath: division by zero");
    uint32 c = a / b;
    return c;
  }
  function mod(uint32 a, uint32 b) internal pure returns (uint32) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}
library SafeMath64 {
  function add(uint64 a, uint64 b) internal pure returns (uint64) {
    uint64 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }
  function sub(uint64 a, uint64 b) internal pure returns (uint64) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint64 c = a - b;
    return c;
  }
  function mul(uint64 a, uint64 b) internal pure returns (uint64) {
    if (a == 0) {
      return 0;
    }
    uint64 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }
  function div(uint64 a, uint64 b) internal pure returns (uint64) {
    require(b > 0, "SafeMath: division by zero");
    uint64 c = a / b;
    return c;
  }
  function mod(uint64 a, uint64 b) internal pure returns (uint64) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}
interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);
  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}
interface AggregatorV3Interface {
  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);
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
interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}
interface AggregatorValidatorInterface {
  function validate(
    uint256 previousRoundId,
    int256 previousAnswer,
    uint256 currentRoundId,
    int256 currentAnswer
  ) external returns (bool);
}
interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}
contract FluxAggregator is AggregatorV2V3Interface, Owned {
  using SafeMath for uint256;
  using SafeMath128 for uint128;
  using SafeMath64 for uint64;
  using SafeMath32 for uint32;
  struct Round {
    int256 answer;
    uint64 startedAt;
    uint64 updatedAt;
    uint32 answeredInRound;
  }
  struct RoundDetails {
    int256[] submissions;
    uint32 maxSubmissions;
    uint32 minSubmissions;
    uint32 timeout;
    uint128 paymentAmount;
  }
  struct OracleStatus {
    uint128 withdrawable;
    uint32 startingRound;
    uint32 endingRound;
    uint32 lastReportedRound;
    uint32 lastStartedRound;
    int256 latestSubmission;
    uint16 index;
    address admin;
    address pendingAdmin;
  }
  struct Requester {
    bool authorized;
    uint32 delay;
    uint32 lastStartedRound;
  }
  struct Funds {
    uint128 available;
    uint128 allocated;
  }
  LinkTokenInterface public linkToken;
  AggregatorValidatorInterface public validator;
  uint128 public paymentAmount;
  uint32 public maxSubmissionCount;
  uint32 public minSubmissionCount;
  uint32 public restartDelay;
  uint32 public timeout;
  uint8 public override decimals;
  string public override description;
  int256 immutable public minSubmissionValue;
  int256 immutable public maxSubmissionValue;
  uint256 constant public override version = 3;
  uint256 constant private RESERVE_ROUNDS = 2;
  uint256 constant private MAX_ORACLE_COUNT = 77;
  uint32 constant private ROUND_MAX = 2**32-1;
  uint256 private constant VALIDATOR_GAS_LIMIT = 100000;
  string constant private V3_NO_DATA_ERROR = "No data present";
  uint32 private reportingRoundId;
  uint32 internal latestRoundId;
  mapping(address => OracleStatus) private oracles;
  mapping(uint32 => Round) internal rounds;
  mapping(uint32 => RoundDetails) internal details;
  mapping(address => Requester) internal requesters;
  address[] private oracleAddresses;
  Funds private recordedFunds;
  event AvailableFundsUpdated(
    uint256 indexed amount
  );
  event RoundDetailsUpdated(
    uint128 indexed paymentAmount,
    uint32 indexed minSubmissionCount,
    uint32 indexed maxSubmissionCount,
    uint32 restartDelay,
    uint32 timeout 
  );
  event OraclePermissionsUpdated(
    address indexed oracle,
    bool indexed whitelisted
  );
  event OracleAdminUpdated(
    address indexed oracle,
    address indexed newAdmin
  );
  event OracleAdminUpdateRequested(
    address indexed oracle,
    address admin,
    address newAdmin
  );
  event SubmissionReceived(
    int256 indexed submission,
    uint32 indexed round,
    address indexed oracle
  );
  event RequesterPermissionsSet(
    address indexed requester,
    bool authorized,
    uint32 delay
  );
  event ValidatorUpdated(
    address indexed previous,
    address indexed current
  );
  constructor(
    address _link,
    uint128 _paymentAmount,
    uint32 _timeout,
    address _validator,
    int256 _minSubmissionValue,
    int256 _maxSubmissionValue,
    uint8 _decimals,
    string memory _description
  ) public {
    linkToken = LinkTokenInterface(_link);
    updateFutureRounds(_paymentAmount, 0, 0, 0, _timeout);
    setValidator(_validator);
    minSubmissionValue = _minSubmissionValue;
    maxSubmissionValue = _maxSubmissionValue;
    decimals = _decimals;
    description = _description;
    rounds[0].updatedAt = uint64(block.timestamp.sub(uint256(_timeout)));
  }
  function submit(uint256 _roundId, int256 _submission)
    external
  {
    bytes memory error = validateOracleRound(msg.sender, uint32(_roundId));
    require(_submission >= minSubmissionValue, "value below minSubmissionValue");
    require(_submission <= maxSubmissionValue, "value above maxSubmissionValue");
    require(error.length == 0, string(error));
    oracleInitializeNewRound(uint32(_roundId));
    recordSubmission(_submission, uint32(_roundId));
    (bool updated, int256 newAnswer) = updateRoundAnswer(uint32(_roundId));
    payOracle(uint32(_roundId));
    deleteRoundDetails(uint32(_roundId));
    if (updated) {
      validateAnswer(uint32(_roundId), newAnswer);
    }
  }
  function changeOracles(
    address[] calldata _removed,
    address[] calldata _added,
    address[] calldata _addedAdmins,
    uint32 _minSubmissions,
    uint32 _maxSubmissions,
    uint32 _restartDelay
  )
    external
    onlyOwner()
  {
    for (uint256 i = 0; i < _removed.length; i++) {
      removeOracle(_removed[i]);
    }
    require(_added.length == _addedAdmins.length, "need same oracle and admin count");
    require(uint256(oracleCount()).add(_added.length) <= MAX_ORACLE_COUNT, "max oracles allowed");
    for (uint256 i = 0; i < _added.length; i++) {
      addOracle(_added[i], _addedAdmins[i]);
    }
    updateFutureRounds(paymentAmount, _minSubmissions, _maxSubmissions, _restartDelay, timeout);
  }
  function updateFutureRounds(
    uint128 _paymentAmount,
    uint32 _minSubmissions,
    uint32 _maxSubmissions,
    uint32 _restartDelay,
    uint32 _timeout
  )
    public
    onlyOwner()
  {
    uint32 oracleNum = oracleCount(); 
    require(_maxSubmissions >= _minSubmissions, "max must equal/exceed min");
    require(oracleNum >= _maxSubmissions, "max cannot exceed total");
    require(oracleNum == 0 || oracleNum > _restartDelay, "delay cannot exceed total");
    require(recordedFunds.available >= requiredReserve(_paymentAmount), "insufficient funds for payment");
    if (oracleCount() > 0) {
      require(_minSubmissions > 0, "min must be greater than 0");
    }
    paymentAmount = _paymentAmount;
    minSubmissionCount = _minSubmissions;
    maxSubmissionCount = _maxSubmissions;
    restartDelay = _restartDelay;
    timeout = _timeout;
    emit RoundDetailsUpdated(
      paymentAmount,
      _minSubmissions,
      _maxSubmissions,
      _restartDelay,
      _timeout
    );
  }
  function allocatedFunds()
    external
    view
    returns (uint128)
  {
    return recordedFunds.allocated;
  }
  function availableFunds()
    external
    view
    returns (uint128)
  {
    return recordedFunds.available;
  }
  function updateAvailableFunds()
    public
  {
    Funds memory funds = recordedFunds;
    uint256 nowAvailable = linkToken.balanceOf(address(this)).sub(funds.allocated);
    if (funds.available != nowAvailable) {
      recordedFunds.available = uint128(nowAvailable);
      emit AvailableFundsUpdated(nowAvailable);
    }
  }
  function oracleCount() public view returns (uint8) {
    return uint8(oracleAddresses.length);
  }
  function getOracles() external view returns (address[] memory) {
    return oracleAddresses;
  }
  function latestAnswer()
    public
    view
    virtual
    override
    returns (int256)
  {
    return rounds[latestRoundId].answer;
  }
  function latestTimestamp()
    public
    view
    virtual
    override
    returns (uint256)
  {
    return rounds[latestRoundId].updatedAt;
  }
  function latestRound()
    public
    view
    virtual
    override
    returns (uint256)
  {
    return latestRoundId;
  }
  function getAnswer(uint256 _roundId)
    public
    view
    virtual
    override
    returns (int256)
  {
    if (validRoundId(_roundId)) {
      return rounds[uint32(_roundId)].answer;
    }
    return 0;
  }
  function getTimestamp(uint256 _roundId)
    public
    view
    virtual
    override
    returns (uint256)
  {
    if (validRoundId(_roundId)) {
      return rounds[uint32(_roundId)].updatedAt;
    }
    return 0;
  }
  function getRoundData(uint80 _roundId)
    public
    view
    virtual
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    Round memory r = rounds[uint32(_roundId)];
    require(r.answeredInRound > 0 && validRoundId(_roundId), V3_NO_DATA_ERROR);
    return (
      _roundId,
      r.answer,
      r.startedAt,
      r.updatedAt,
      r.answeredInRound
    );
  }
   function latestRoundData()
    public
    view
    virtual
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return getRoundData(latestRoundId);
  }
  function withdrawablePayment(address _oracle)
    external
    view
    returns (uint256)
  {
    return oracles[_oracle].withdrawable;
  }
  function withdrawPayment(address _oracle, address _recipient, uint256 _amount)
    external
  {
    require(oracles[_oracle].admin == msg.sender, "only callable by admin");
    uint128 amount = uint128(_amount);
    uint128 available = oracles[_oracle].withdrawable;
    require(available >= amount, "insufficient withdrawable funds");
    oracles[_oracle].withdrawable = available.sub(amount);
    recordedFunds.allocated = recordedFunds.allocated.sub(amount);
    assert(linkToken.transfer(_recipient, uint256(amount)));
  }
  function withdrawFunds(address _recipient, uint256 _amount)
    external
    onlyOwner()
  {
    uint256 available = uint256(recordedFunds.available);
    require(available.sub(requiredReserve(paymentAmount)) >= _amount, "insufficient reserve funds");
    require(linkToken.transfer(_recipient, _amount), "token transfer failed");
    updateAvailableFunds();
  }
  function getAdmin(address _oracle)
    external
    view
    returns (address)
  {
    return oracles[_oracle].admin;
  }
  function transferAdmin(address _oracle, address _newAdmin)
    external
  {
    require(oracles[_oracle].admin == msg.sender, "only callable by admin");
    oracles[_oracle].pendingAdmin = _newAdmin;
    emit OracleAdminUpdateRequested(_oracle, msg.sender, _newAdmin);
  }
  function acceptAdmin(address _oracle)
    external
  {
    require(oracles[_oracle].pendingAdmin == msg.sender, "only callable by pending admin");
    oracles[_oracle].pendingAdmin = address(0);
    oracles[_oracle].admin = msg.sender;
    emit OracleAdminUpdated(_oracle, msg.sender);
  }
  function requestNewRound()
    external
    returns (uint80)
  {
    require(requesters[msg.sender].authorized, "not authorized requester");
    uint32 current = reportingRoundId;
    require(rounds[current].updatedAt > 0 || timedOut(current), "prev round must be supersedable");
    uint32 newRoundId = current.add(1);
    requesterInitializeNewRound(newRoundId);
    return newRoundId;
  }
  function setRequesterPermissions(address _requester, bool _authorized, uint32 _delay)
    external
    onlyOwner()
  {
    if (requesters[_requester].authorized == _authorized) return;
    if (_authorized) {
      requesters[_requester].authorized = _authorized;
      requesters[_requester].delay = _delay;
    } else {
      delete requesters[_requester];
    }
    emit RequesterPermissionsSet(_requester, _authorized, _delay);
  }
  function onTokenTransfer(address, uint256, bytes calldata _data)
    external
  {
    require(_data.length == 0, "transfer doesn't accept calldata");
    updateAvailableFunds();
  }
  function oracleRoundState(address _oracle, uint32 _queriedRoundId)
    external
    view
    returns (
      bool _eligibleToSubmit,
      uint32 _roundId,
      int256 _latestSubmission,
      uint64 _startedAt,
      uint64 _timeout,
      uint128 _availableFunds,
      uint8 _oracleCount,
      uint128 _paymentAmount
    )
  {
    require(msg.sender == tx.origin, "off-chain reading only");
    if (_queriedRoundId > 0) {
      Round storage round = rounds[_queriedRoundId];
      RoundDetails storage details = details[_queriedRoundId];
      return (
        eligibleForSpecificRound(_oracle, _queriedRoundId),
        _queriedRoundId,
        oracles[_oracle].latestSubmission,
        round.startedAt,
        details.timeout,
        recordedFunds.available,
        oracleCount(),
        (round.startedAt > 0 ? details.paymentAmount : paymentAmount)
      );
    } else {
      return oracleRoundStateSuggestRound(_oracle);
    }
  }
  function setValidator(address _newValidator)
    public
    onlyOwner()
  {
    address previous = address(validator);
    if (previous != _newValidator) {
      validator = AggregatorValidatorInterface(_newValidator);
      emit ValidatorUpdated(previous, _newValidator);
    }
  }
  function initializeNewRound(uint32 _roundId)
    private
  {
    updateTimedOutRoundInfo(_roundId.sub(1));
    reportingRoundId = _roundId;
    RoundDetails memory nextDetails = RoundDetails(
      new int256[](0),
      maxSubmissionCount,
      minSubmissionCount,
      timeout,
      paymentAmount
    );
    details[_roundId] = nextDetails;
    rounds[_roundId].startedAt = uint64(block.timestamp);
    emit NewRound(_roundId, msg.sender, rounds[_roundId].startedAt);
  }
  function oracleInitializeNewRound(uint32 _roundId)
    private
  {
    if (!newRound(_roundId)) return;
    uint256 lastStarted = oracles[msg.sender].lastStartedRound; 
    if (_roundId <= lastStarted + restartDelay && lastStarted != 0) return;
    initializeNewRound(_roundId);
    oracles[msg.sender].lastStartedRound = _roundId;
  }
  function requesterInitializeNewRound(uint32 _roundId)
    private
  {
    if (!newRound(_roundId)) return;
    uint256 lastStarted = requesters[msg.sender].lastStartedRound; 
    require(_roundId > lastStarted + requesters[msg.sender].delay || lastStarted == 0, "must delay requests");
    initializeNewRound(_roundId);
    requesters[msg.sender].lastStartedRound = _roundId;
  }
  function updateTimedOutRoundInfo(uint32 _roundId)
    private
  {
    if (!timedOut(_roundId)) return;
    uint32 prevId = _roundId.sub(1);
    rounds[_roundId].answer = rounds[prevId].answer;
    rounds[_roundId].answeredInRound = rounds[prevId].answeredInRound;
    rounds[_roundId].updatedAt = uint64(block.timestamp);
    delete details[_roundId];
  }
  function eligibleForSpecificRound(address _oracle, uint32 _queriedRoundId)
    private
    view
    returns (bool _eligible)
  {
    if (rounds[_queriedRoundId].startedAt > 0) {
      return acceptingSubmissions(_queriedRoundId) && validateOracleRound(_oracle, _queriedRoundId).length == 0;
    } else {
      return delayed(_oracle, _queriedRoundId) && validateOracleRound(_oracle, _queriedRoundId).length == 0;
    }
  }
  function oracleRoundStateSuggestRound(address _oracle)
    private
    view
    returns (
      bool _eligibleToSubmit,
      uint32 _roundId,
      int256 _latestSubmission,
      uint64 _startedAt,
      uint64 _timeout,
      uint128 _availableFunds,
      uint8 _oracleCount,
      uint128 _paymentAmount
    )
  {
    Round storage round = rounds[0];
    OracleStatus storage oracle = oracles[_oracle];
    bool shouldSupersede = oracle.lastReportedRound == reportingRoundId || !acceptingSubmissions(reportingRoundId);
    if (supersedable(reportingRoundId) && shouldSupersede) {
      _roundId = reportingRoundId.add(1);
      round = rounds[_roundId];
      _paymentAmount = paymentAmount;
      _eligibleToSubmit = delayed(_oracle, _roundId);
    } else {
      _roundId = reportingRoundId;
      round = rounds[_roundId];
      _paymentAmount = details[_roundId].paymentAmount;
      _eligibleToSubmit = acceptingSubmissions(_roundId);
    }
    if (validateOracleRound(_oracle, _roundId).length != 0) {
      _eligibleToSubmit = false;
    }
    return (
      _eligibleToSubmit,
      _roundId,
      oracle.latestSubmission,
      round.startedAt,
      details[_roundId].timeout,
      recordedFunds.available,
      oracleCount(),
      _paymentAmount
    );
  }
  function updateRoundAnswer(uint32 _roundId)
    internal
    returns (bool, int256)
  {
    if (details[_roundId].submissions.length < details[_roundId].minSubmissions) {
      return (false, 0);
    }
    int256 newAnswer = Median.calculateInplace(details[_roundId].submissions);
    rounds[_roundId].answer = newAnswer;
    rounds[_roundId].updatedAt = uint64(block.timestamp);
    rounds[_roundId].answeredInRound = _roundId;
    latestRoundId = _roundId;
    emit AnswerUpdated(newAnswer, _roundId, now);
    return (true, newAnswer);
  }
  function validateAnswer(
    uint32 _roundId,
    int256 _newAnswer
  )
    private
  {
    AggregatorValidatorInterface av = validator; 
    if (address(av) == address(0)) return;
    uint32 prevRound = _roundId.sub(1);
    uint32 prevAnswerRoundId = rounds[prevRound].answeredInRound;
    int256 prevRoundAnswer = rounds[prevRound].answer;
    try av.validate{gas: VALIDATOR_GAS_LIMIT}(
      prevAnswerRoundId,
      prevRoundAnswer,
      _roundId,
      _newAnswer
    ) {} catch {}
  }
  function payOracle(uint32 _roundId)
    private
  {
    uint128 payment = details[_roundId].paymentAmount;
    Funds memory funds = recordedFunds;
    funds.available = funds.available.sub(payment);
    funds.allocated = funds.allocated.add(payment);
    recordedFunds = funds;
    oracles[msg.sender].withdrawable = oracles[msg.sender].withdrawable.add(payment);
    emit AvailableFundsUpdated(funds.available);
  }
  function recordSubmission(int256 _submission, uint32 _roundId)
    private
  {
    require(acceptingSubmissions(_roundId), "round not accepting submissions");
    details[_roundId].submissions.push(_submission);
    oracles[msg.sender].lastReportedRound = _roundId;
    oracles[msg.sender].latestSubmission = _submission;
    emit SubmissionReceived(_submission, _roundId, msg.sender);
  }
  function deleteRoundDetails(uint32 _roundId)
    private
  {
    if (details[_roundId].submissions.length < details[_roundId].maxSubmissions) return;
    delete details[_roundId];
  }
  function timedOut(uint32 _roundId)
    private
    view
    returns (bool)
  {
    uint64 startedAt = rounds[_roundId].startedAt;
    uint32 roundTimeout = details[_roundId].timeout;
    return startedAt > 0 && roundTimeout > 0 && startedAt.add(roundTimeout) < block.timestamp;
  }
  function getStartingRound(address _oracle)
    private
    view
    returns (uint32)
  {
    uint32 currentRound = reportingRoundId;
    if (currentRound != 0 && currentRound == oracles[_oracle].endingRound) {
      return currentRound;
    }
    return currentRound.add(1);
  }
  function previousAndCurrentUnanswered(uint32 _roundId, uint32 _rrId)
    private
    view
    returns (bool)
  {
    return _roundId.add(1) == _rrId && rounds[_rrId].updatedAt == 0;
  }
  function requiredReserve(uint256 payment)
    private
    view
    returns (uint256)
  {
    return payment.mul(oracleCount()).mul(RESERVE_ROUNDS);
  }
  function addOracle(
    address _oracle,
    address _admin
  )
    private
  {
    require(!oracleEnabled(_oracle), "oracle already enabled");
    require(_admin != address(0), "cannot set admin to 0");
    require(oracles[_oracle].admin == address(0) || oracles[_oracle].admin == _admin, "owner cannot overwrite admin");
    oracles[_oracle].startingRound = getStartingRound(_oracle);
    oracles[_oracle].endingRound = ROUND_MAX;
    oracles[_oracle].index = uint16(oracleAddresses.length);
    oracleAddresses.push(_oracle);
    oracles[_oracle].admin = _admin;
    emit OraclePermissionsUpdated(_oracle, true);
    emit OracleAdminUpdated(_oracle, _admin);
  }
  function removeOracle(
    address _oracle
  )
    private
  {
    require(oracleEnabled(_oracle), "oracle not enabled");
    oracles[_oracle].endingRound = reportingRoundId.add(1);
    address tail = oracleAddresses[uint256(oracleCount()).sub(1)];
    uint16 index = oracles[_oracle].index;
    oracles[tail].index = index;
    delete oracles[_oracle].index;
    oracleAddresses[index] = tail;
    oracleAddresses.pop();
    emit OraclePermissionsUpdated(_oracle, false);
  }
  function validateOracleRound(address _oracle, uint32 _roundId)
    private
    view
    returns (bytes memory)
  {
    uint32 startingRound = oracles[_oracle].startingRound;
    uint32 rrId = reportingRoundId;
    if (startingRound == 0) return "not enabled oracle";
    if (startingRound > _roundId) return "not yet enabled oracle";
    if (oracles[_oracle].endingRound < _roundId) return "no longer allowed oracle";
    if (oracles[_oracle].lastReportedRound >= _roundId) return "cannot report on previous rounds";
    if (_roundId != rrId && _roundId != rrId.add(1) && !previousAndCurrentUnanswered(_roundId, rrId)) return "invalid round to report";
    if (_roundId != 1 && !supersedable(_roundId.sub(1))) return "previous round not supersedable";
  }
  function supersedable(uint32 _roundId)
    private
    view
    returns (bool)
  {
    return rounds[_roundId].updatedAt > 0 || timedOut(_roundId);
  }
  function oracleEnabled(address _oracle)
    private
    view
    returns (bool)
  {
    return oracles[_oracle].endingRound == ROUND_MAX;
  }
  function acceptingSubmissions(uint32 _roundId)
    private
    view
    returns (bool)
  {
    return details[_roundId].maxSubmissions != 0;
  }
  function delayed(address _oracle, uint32 _roundId)
    private
    view
    returns (bool)
  {
    uint256 lastStarted = oracles[_oracle].lastStartedRound;
    return _roundId > lastStarted + restartDelay || lastStarted == 0;
  }
  function newRound(uint32 _roundId)
    private
    view
    returns (bool)
  {
    return _roundId == reportingRoundId.add(1);
  }
  function validRoundId(uint256 _roundId)
    private
    view
    returns (bool)
  {
    return _roundId <= ROUND_MAX;
  }
}
interface AccessControllerInterface {
  function hasAccess(address user, bytes calldata data) external view returns (bool);
}
contract SimpleWriteAccessController is AccessControllerInterface, Owned {
  bool public checkEnabled;
  mapping(address => bool) internal accessList;
  event AddedAccess(address user);
  event RemovedAccess(address user);
  event CheckAccessEnabled();
  event CheckAccessDisabled();
  constructor()
    public
  {
    checkEnabled = true;
  }
  function hasAccess(
    address _user,
    bytes memory
  )
    public
    view
    virtual
    override
    returns (bool)
  {
    return accessList[_user] || !checkEnabled;
  }
  function addAccess(address _user)
    external
    onlyOwner()
  {
    if (!accessList[_user]) {
      accessList[_user] = true;
      emit AddedAccess(_user);
    }
  }
  function removeAccess(address _user)
    external
    onlyOwner()
  {
    if (accessList[_user]) {
      accessList[_user] = false;
      emit RemovedAccess(_user);
    }
  }
  function enableAccessCheck()
    external
    onlyOwner()
  {
    if (!checkEnabled) {
      checkEnabled = true;
      emit CheckAccessEnabled();
    }
  }
  function disableAccessCheck()
    external
    onlyOwner()
  {
    if (checkEnabled) {
      checkEnabled = false;
      emit CheckAccessDisabled();
    }
  }
  modifier checkAccess() {
    require(hasAccess(msg.sender, msg.data), "No access");
    _;
  }
}
contract SimpleReadAccessController is SimpleWriteAccessController {
  function hasAccess(
    address _user,
    bytes memory _calldata
  )
    public
    view
    virtual
    override
    returns (bool)
  {
    return super.hasAccess(_user, _calldata) || _user == tx.origin;
  }
}
contract AccessControlledAggregator is FluxAggregator, SimpleReadAccessController {
  constructor(
    address _link,
    uint128 _paymentAmount,
    uint32 _timeout,
    address _validator,
    int256 _minSubmissionValue,
    int256 _maxSubmissionValue,
    uint8 _decimals,
    string memory _description
  ) public FluxAggregator(
    _link,
    _paymentAmount,
    _timeout,
    _validator,
    _minSubmissionValue,
    _maxSubmissionValue,
    _decimals,
    _description
  ){}
  function getRoundData(uint80 _roundId)
    public
    view
    override
    checkAccess()
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return super.getRoundData(_roundId);
  }
  function latestRoundData()
    public
    view
    override
    checkAccess()
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return super.latestRoundData();
  }
  function latestAnswer()
    public
    view
    override
    checkAccess()
    returns (int256)
  {
    return super.latestAnswer();
  }
  function latestRound()
    public
    view
    override
    checkAccess()
    returns (uint256)
  {
    return super.latestRound();
  }
  function latestTimestamp()
    public
    view
    override
    checkAccess()
    returns (uint256)
  {
    return super.latestTimestamp();
  }
  function getAnswer(uint256 _roundId)
    public
    view
    override
    checkAccess()
    returns (int256)
  {
    return super.getAnswer(_roundId);
  }
  function getTimestamp(uint256 _roundId)
    public
    view
    override
    checkAccess()
    returns (uint256)
  {
    return super.getTimestamp(_roundId);
  }
}