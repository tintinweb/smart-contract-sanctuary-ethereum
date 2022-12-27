pragma solidity 0.5.9;

import "../data/QueryTCR.sol";

contract TCRFactory {
  event TCRCreated(QueryTCR tcr, address creator);

  function createTCR(
    bytes8 prefix,
    Parameters params,
    BandRegistry registry
  ) external returns(QueryTCR) {
    QueryTCR tcr = new QueryTCR(prefix, params, registry);
    emit TCRCreated(tcr, msg.sender);
    return tcr;
  }
}

pragma solidity 0.5.9;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";


/// "Fractional" library facilitate fixed point decimal computation. In Band Protocol, fixed point decimal can be
/// represented using `uint256` data type. The decimal is fixed at 18 digits and `mulFrac` can be used to multiply
/// the fixed point decimal with an ordinary `uint256` value.
library Fractional {
  using SafeMath for uint256;
  uint256 internal constant DENOMINATOR = 1e18;

  function getDenominator() internal pure returns (uint256) {
    return DENOMINATOR;
  }

  function mulFrac(uint256 numerator, uint256 value) internal pure returns(uint256) {
    return numerator.mul(value).div(DENOMINATOR);
  }
}

pragma solidity 0.5.9;

import "./Equation.sol";


interface Expression {
  /// Return the result of evaluating the expression given a variable value
  function evaluate(uint256 x) external view returns (uint256);
}


contract EquationExpression is Expression {
  using Equation for Equation.Node[];
  Equation.Node[] public equation;

  constructor(uint256[] memory expressionTree) public {
    equation.init(expressionTree);
  }

  function evaluate(uint256 x) public view returns (uint256) {
    return equation.calculate(x);
  }
}


contract BondingCurveExpression is EquationExpression {
  constructor(uint256[] memory expressionTree) public EquationExpression(expressionTree) {}
}


contract TCRMinDepositExpression is EquationExpression {
  constructor(uint256[] memory expressionTree) public EquationExpression(expressionTree) {}
}

pragma solidity 0.5.9;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../../bancor/BancorPower.sol";


library Equation {
  using SafeMath for uint256;

  /// An expression tree is encoded as a set of nodes, with root node having index zero. Each node has 3 values:
  ///  1. opcode: the expression that the node represents. See table below.
  /// +--------+----------------------------------------+------+------------+
  /// | Opcode |              Description               | i.e. | # children |
  /// +--------+----------------------------------------+------+------------+
  /// |   00   | Integer Constant                       |   c  |      0     |
  /// |   01   | Variable                               |   X  |      0     |
  /// |   02   | Arithmetic Square Root                 |   √  |      1     |
  /// |   03   | Boolean Not Condition                  |   !  |      1     |
  /// |   04   | Arithmetic Addition                    |   +  |      2     |
  /// |   05   | Arithmetic Subtraction                 |   -  |      2     |
  /// |   06   | Arithmetic Multiplication              |   *  |      2     |
  /// |   07   | Arithmetic Division                    |   /  |      2     |
  /// |   08   | Arithmetic Exponentiation              |  **  |      2     |
  /// |   09   | Arithmetic Percentage* (see below)     |   %  |      2     |
  /// |   10   | Arithmetic Equal Comparison            |  ==  |      2     |
  /// |   11   | Arithmetic Non-Equal Comparison        |  !=  |      2     |
  /// |   12   | Arithmetic Less-Than Comparison        |  <   |      2     |
  /// |   13   | Arithmetic Greater-Than Comparison     |  >   |      2     |
  /// |   14   | Arithmetic Non-Greater-Than Comparison |  <=  |      2     |
  /// |   15   | Arithmetic Non-Less-Than Comparison    |  >=  |      2     |
  /// |   16   | Boolean And Condition                  |  &&  |      2     |
  /// |   17   | Boolean Or Condition                   |  ||  |      2     |
  /// |   18   | Ternary Operation                      |  ?:  |      3     |
  /// |   19   | Bancor's log** (see below)             |      |      3     |
  /// |   20   | Bancor's power*** (see below)          |      |      4     |
  /// +--------+----------------------------------------+------+------------+
  ///  2. children: the list of node indices of this node's sub-expressions. Different opcode nodes will have different
  ///     number of children.
  ///  3. value: the value inside the node. Currently this is only relevant for Integer Constant (Opcode 00).
  /// (*) Arithmetic percentage is computed by multiplying the left-hand side value with the right-hand side,
  ///     and divide the result by 10^18, rounded down to uint256 integer.
  /// (**) Using BancorFormula, the opcode computes log of fractional numbers. However, this fraction's value must
  ///     be more than 1. (baseN / baseD >= 1). The opcode takes 3 childrens(c, baseN, baseD), and computes
  ///     (c * log(baseN / baseD)) limitation is in range of 1 <= baseN / baseD <= 58774717541114375398436826861112283890
  ///     (= 1e76/FIXED_1), where FIXED_1 defined in BancorPower.sol
  /// (***) Using BancorFomula, the opcode computes exponential of fractional numbers. The opcode takes 4 children
  ///     (c,baseN,baseD,expV), and computes (c * ((baseN / baseD) ^ (expV / 1e6))). See implementation for the
  ///     limitation of the each value's domain. The end result must be in uint256 range.
  struct Node {
    uint8 opcode;
    uint8 child0;
    uint8 child1;
    uint8 child2;
    uint8 child3;
    uint256 value;
  }

  enum ExprType { Invalid, Math, Boolean }

  uint8 constant OPCODE_CONST = 0;
  uint8 constant OPCODE_VAR = 1;
  uint8 constant OPCODE_SQRT = 2;
  uint8 constant OPCODE_NOT = 3;
  uint8 constant OPCODE_ADD = 4;
  uint8 constant OPCODE_SUB = 5;
  uint8 constant OPCODE_MUL = 6;
  uint8 constant OPCODE_DIV = 7;
  uint8 constant OPCODE_EXP = 8;
  uint8 constant OPCODE_PCT = 9;
  uint8 constant OPCODE_EQ = 10;
  uint8 constant OPCODE_NE = 11;
  uint8 constant OPCODE_LT = 12;
  uint8 constant OPCODE_GT = 13;
  uint8 constant OPCODE_LE = 14;
  uint8 constant OPCODE_GE = 15;
  uint8 constant OPCODE_AND = 16;
  uint8 constant OPCODE_OR = 17;
  uint8 constant OPCODE_IF = 18;
  uint8 constant OPCODE_BANCOR_LOG = 19;
  uint8 constant OPCODE_BANCOR_POWER = 20;
  uint8 constant OPCODE_INVALID = 21;

  /// @dev Initialize equation by array of opcodes/values in prefix order. Array
  /// is read as if it is the *pre-order* traversal of the expression tree.
  function init(Node[] storage self, uint256[] calldata _expressions) external {
    /// Init should only be called when the equation is not yet initialized.
    require(self.length == 0);
    /// Limit expression length to < 256 to make sure gas cost is managable.
    require(_expressions.length < 256);
    for (uint8 idx = 0; idx < _expressions.length; ++idx) {
      uint256 opcode = _expressions[idx];
      require(opcode < OPCODE_INVALID);
      Node memory node;
      node.opcode = uint8(opcode);
      /// Get the node's value. Only applicable on Integer Constant case.
      if (opcode == OPCODE_CONST) {
        node.value = _expressions[++idx];
      }
      self.push(node);
    }
    (uint8 lastNodeIndex,) = populateTree(self, 0);
    require(lastNodeIndex == self.length - 1);
  }

  /// Calculate the Y position from the X position for this equation.
  function calculate(Node[] storage self, uint256 xValue) external view returns (uint256) {
    return solveMath(self, 0, xValue);
  }

  /// Return the number of children the given opcode node has.
  function getChildrenCount(uint8 opcode) private pure returns (uint8) {
    if (opcode <= OPCODE_VAR) {
      return 0;
    } else if (opcode <= OPCODE_NOT) {
      return 1;
    } else if (opcode <= OPCODE_OR) {
      return 2;
    } else if (opcode <= OPCODE_BANCOR_LOG) {
      return 3;
    } else if (opcode <= OPCODE_BANCOR_POWER) {
      return 4;
    }
    revert();
  }

  /// Check whether the given opcode and list of expression types match. Revert on failure.
  function checkExprType(uint8 opcode, ExprType[] memory types)
    private pure returns (ExprType)
  {
    if (opcode <= OPCODE_VAR) {
      return ExprType.Math;
    } else if (opcode == OPCODE_SQRT) {
      require(types[0] == ExprType.Math);
      return ExprType.Math;
    } else if (opcode == OPCODE_NOT) {
      require(types[0] == ExprType.Boolean);
      return ExprType.Boolean;
    } else if (opcode >= OPCODE_ADD && opcode <= OPCODE_PCT) {
      require(types[0] == ExprType.Math);
      require(types[1] == ExprType.Math);
      return ExprType.Math;
    } else if (opcode >= OPCODE_EQ && opcode <= OPCODE_GE) {
      require(types[0] == ExprType.Math);
      require(types[1] == ExprType.Math);
      return ExprType.Boolean;
    } else if (opcode >= OPCODE_AND && opcode <= OPCODE_OR) {
      require(types[0] == ExprType.Boolean);
      require(types[1] == ExprType.Boolean);
      return ExprType.Boolean;
    } else if (opcode == OPCODE_IF) {
      require(types[0] == ExprType.Boolean);
      require(types[1] != ExprType.Invalid);
      require(types[1] == types[2]);
      return types[1];
    } else if (opcode == OPCODE_BANCOR_LOG) {
      require(types[0] == ExprType.Math);
      require(types[1] == ExprType.Math);
      require(types[2] == ExprType.Math);
      return ExprType.Math;
    } else if (opcode == OPCODE_BANCOR_POWER) {
      require(types[0] == ExprType.Math);
      require(types[1] == ExprType.Math);
      require(types[2] == ExprType.Math);
      require(types[3] == ExprType.Math);
      return ExprType.Math;
    }
    revert();
  }

  /// Helper function to recursively populate node infoMaprmation following the given pre-order
  /// node list. It inspects the opcode and recursively call populateTree(s) accordingly.
  /// @param self storage pointer to equation data to build tree.
  /// @param currentNodeIndex the index of the current node to populate infoMap.
  /// @return An (uint8, bool). The first value represents the last  (highest/rightmost) node
  /// index of the current subtree. The second value indicates the type of this subtree.
  function populateTree(Node[] storage self, uint8 currentNodeIndex)
    private returns (uint8, ExprType)
  {
    require(currentNodeIndex < self.length);
    Node storage node = self[currentNodeIndex];
    uint8 opcode = node.opcode;
    uint8 childrenCount = getChildrenCount(opcode);
    ExprType[] memory childrenTypes = new ExprType[](childrenCount);
    uint8 lastNodeIdx = currentNodeIndex;
    for (uint8 idx = 0; idx < childrenCount; ++idx) {
      if (idx == 0) node.child0 = lastNodeIdx + 1;
      else if (idx == 1) node.child1 = lastNodeIdx + 1;
      else if (idx == 2) node.child2 = lastNodeIdx + 1;
      else if (idx == 3) node.child3 = lastNodeIdx + 1;
      else revert();
      (lastNodeIdx, childrenTypes[idx]) = populateTree(self, lastNodeIdx + 1);
    }
    ExprType exprType = checkExprType(opcode, childrenTypes);
    return (lastNodeIdx, exprType);
  }


  function solveMath(Node[] storage self, uint8 nodeIdx, uint256 xValue)
    private view returns (uint256)
  {
    Node storage node = self[nodeIdx];
    uint8 opcode = node.opcode;
    if (opcode == OPCODE_CONST) {
      return node.value;
    } else if (opcode == OPCODE_VAR) {
      return xValue;
    } else if (opcode == OPCODE_SQRT) {
      uint256 childValue = solveMath(self, node.child0, xValue);
      uint256 temp = childValue.add(1).div(2);
      uint256 result = childValue;
      while (temp < result) {
        result = temp;
        temp = childValue.div(temp).add(temp).div(2);
      }
      return result;
    } else if (opcode >= OPCODE_ADD && opcode <= OPCODE_PCT) {
      uint256 leftValue = solveMath(self, node.child0, xValue);
      uint256 rightValue = solveMath(self, node.child1, xValue);
      if (opcode == OPCODE_ADD) {
        return leftValue.add(rightValue);
      } else if (opcode == OPCODE_SUB) {
        return leftValue.sub(rightValue);
      } else if (opcode == OPCODE_MUL) {
        return leftValue.mul(rightValue);
      } else if (opcode == OPCODE_DIV) {
        return leftValue.div(rightValue);
      } else if (opcode == OPCODE_EXP) {
        uint256 power = rightValue;
        uint256 expResult = 1;
        for (uint256 idx = 0; idx < power; ++idx) {
          expResult = expResult.mul(leftValue);
        }
        return expResult;
      } else if (opcode == OPCODE_PCT) {
        return leftValue.mul(rightValue).div(1e18);
      }
    } else if (opcode == OPCODE_IF) {
      bool condValue = solveBool(self, node.child0, xValue);
      if (condValue) return solveMath(self, node.child1, xValue);
      else return solveMath(self, node.child2, xValue);
    } else if (opcode == OPCODE_BANCOR_LOG) {
      uint256 multiplier = solveMath(self, node.child0, xValue);
      uint256 baseN = solveMath(self, node.child1, xValue);
      uint256 baseD = solveMath(self, node.child2, xValue);
      return BancorPower.log(multiplier, baseN, baseD);
    } else if (opcode == OPCODE_BANCOR_POWER) {
      uint256 multiplier = solveMath(self, node.child0, xValue);
      uint256 baseN = solveMath(self, node.child1, xValue);
      uint256 baseD = solveMath(self, node.child2, xValue);
      uint256 expV = solveMath(self, node.child3, xValue);
      require(expV < 1 << 32);
      (uint256 expResult, uint8 precision) = BancorPower.power(baseN, baseD, uint32(expV), 1e6);
      return expResult.mul(multiplier) >> precision;
    }
    revert();
  }

  function solveBool(Node[] storage self, uint8 nodeIdx, uint256 xValue)
    private view returns (bool)
  {
    Node storage node = self[nodeIdx];
    uint8 opcode = node.opcode;
    if (opcode == OPCODE_NOT) {
      return !solveBool(self, node.child0, xValue);
    } else if (opcode >= OPCODE_EQ && opcode <= OPCODE_GE) {
      uint256 leftValue = solveMath(self, node.child0, xValue);
      uint256 rightValue = solveMath(self, node.child1, xValue);
      if (opcode == OPCODE_EQ) {
        return leftValue == rightValue;
      } else if (opcode == OPCODE_NE) {
        return leftValue != rightValue;
      } else if (opcode == OPCODE_LT) {
        return leftValue < rightValue;
      } else if (opcode == OPCODE_GT) {
        return leftValue > rightValue;
      } else if (opcode == OPCODE_LE) {
        return leftValue <= rightValue;
      } else if (opcode == OPCODE_GE) {
        return leftValue >= rightValue;
      }
    } else if (opcode >= OPCODE_AND && opcode <= OPCODE_OR) {
      bool leftBoolValue = solveBool(self, node.child0, xValue);
      if (opcode == OPCODE_AND) {
        if (leftBoolValue) return solveBool(self, node.child1, xValue);
        else return false;
      } else if (opcode == OPCODE_OR) {
        if (leftBoolValue) return true;
        else return solveBool(self, node.child1, xValue);
      }
    } else if (opcode == OPCODE_IF) {
      bool condValue = solveBool(self, node.child0, xValue);
      if (condValue) return solveBool(self, node.child1, xValue);
      else return solveBool(self, node.child2, xValue);
    }
    revert();
  }
}

pragma solidity 0.5.9;

import  "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./ERC20Base.sol";


contract SnapshotToken is ERC20Base {
  using SafeMath for uint256;

  /// IMPORTANT: votingPowers are kept as a linked list of ALL historical changes.
  /// - This allows the contract to figure out voting power of the address at any nonce `n`, by
  /// searching for the node that has the biggest nonce that is not greater than `n`.
  /// - For efficiency, nonce and power are packed into one uint256 integer, with the top 64 bits
  /// representing nonce, and the bottom 192 bits representing voting power.
  mapping (address => mapping(uint256 => uint256)) _votingPower;
  mapping (address => uint256) public votingPowerChangeCount;
  uint256 public votingPowerChangeNonce = 0;

  /// Returns user voting power at the given index, that is, as of the user's index^th voting power change
  function historicalVotingPowerAtIndex(address owner, uint256 index) public view returns (uint256) {
    require(index <= votingPowerChangeCount[owner]);
    return _votingPower[owner][index] & ((1 << 192) - 1);  // Lower 192 bits
  }

  /// Returns user voting power at the given time. Under the hood, this performs binary search
  /// to look for the largest index at which the nonce is not greater than 'nonce'.
  /// The voting power at that index is the returning value.
  function historicalVotingPowerAtNonce(address owner, uint256 nonce) public view returns (uint256) {
    require(nonce <= votingPowerChangeNonce && nonce < (1 << 64));
    uint256 start = 0;
    uint256 end = votingPowerChangeCount[owner];
    while (start < end) {
      uint256 mid = start.add(end).add(1).div(2); /// Use (start+end+1)/2 to prevent infinite loop.
      if ((_votingPower[owner][mid] >> 192) > nonce) {  /// Upper 64-bit nonce
        /// If midTime > nonce, this mid can't possibly be the answer.
        end = mid.sub(1);
      } else {
        /// Otherwise, search on the greater side, but still keep mid as a possible option.
        start = mid;
      }
    }
    return historicalVotingPowerAtIndex(owner, start);
  }

  function _transfer(address from, address to, uint256 value) internal {
    super._transfer(from, to, value);
    votingPowerChangeNonce = votingPowerChangeNonce.add(1);
    _changeVotingPower(from);
    _changeVotingPower(to);
  }

  function _mint(address account, uint256 amount) internal {
    super._mint(account, amount);
    votingPowerChangeNonce = votingPowerChangeNonce.add(1);
    _changeVotingPower(account);
  }

  function _burn(address account, uint256 amount) internal {
    super._burn(account, amount);
    votingPowerChangeNonce = votingPowerChangeNonce.add(1);
    _changeVotingPower(account);
  }

  function _changeVotingPower(address account) internal {
    uint256 currentIndex = votingPowerChangeCount[account];
    uint256 newPower = balanceOf(account);
    require(newPower < (1 << 192));
    require(votingPowerChangeNonce < (1 << 64));
    currentIndex = currentIndex.add(1);
    votingPowerChangeCount[account] = currentIndex;
    _votingPower[account][currentIndex] = (votingPowerChangeNonce << 192) | newPower;
  }
}

pragma solidity 0.5.9;


interface ERC20Interface {
  // Standard ERC-20 interface.
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  // Extension of ERC-20 interface to support supply adjustment.
  function mint(address to, uint256 value) external returns (bool);
  function burn(address from, uint256 value) external returns (bool);
}

pragma solidity 0.5.9;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/access/roles/MinterRole.sol";
import "./ERC20Interface.sol";


/// "ERC20Base" is the standard ERC-20 implementation that allows its minter to mint tokens. Both BandToken and
/// CommunityToken extend from ERC20Base. In addition to the standard functions, the class provides `transferAndCall`
/// function, which performs a transfer and invokes the given function using the provided data. If the destination
/// contract uses "ERC20Acceptor" interface, it can verify that the caller properly sends appropriate amount of tokens.
contract ERC20Base is ERC20Interface, ERC20, MinterRole {
  string public name;
  string public symbol;
  uint8 public decimals = 18;

  constructor(string memory _name, string memory _symbol) public {
    name = _name;
    symbol = _symbol;
  }

  function transferAndCall(address to, uint256 value, bytes4 sig, bytes memory data) public returns (bool) {
    require(to != address(this));
    _transfer(msg.sender, to, value);
    (bool success,) = to.call(abi.encodePacked(sig, uint256(msg.sender), value, data));
    require(success);
    return true;
  }

  function mint(address to, uint256 value) public onlyMinter returns (bool) {
    _mint(to, value);
    return true;
  }

  function burn(address from, uint256 value) public onlyMinter returns (bool) {
    _burn(from, value);
    return true;
  }
}

pragma solidity 0.5.9;

import "./ERC20Interface.sol";


/// "ERC20Acceptor" is a utility smart contract that provides `requireToken` modifier for any contract that intends
/// to have functions that accept ERC-20 token transfer to inherit.
contract ERC20Acceptor {
  /// A modifer to decorate function that requires ERC-20 transfer. If called by ERC-20
  /// contract, the modifier trusts that the transfer already occurs. Otherwise, the modifier
  /// invokes 'transferFrom' to ensure that appropriate amount of tokens is paid properly.
  modifier requireToken(ERC20Interface token, address sender, uint256 amount) {
    if (msg.sender != address(token)) {
      require(sender == msg.sender);
      require(token.transferFrom(sender, address(this), amount));
    }
    _;
  }
}

pragma solidity 0.5.9;


interface BandExchangeInterface {
  function convertFromEthToBand() external payable returns (uint256);
}

pragma solidity 0.5.9;

interface WhiteListInterface {
  function verify(address reader) external view returns (bool);
}

pragma solidity 0.5.9;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/math/Math.sol";
import "../token/ERC20Acceptor.sol";
import "../utils/Expression.sol";
import "../utils/Fractional.sol";
import "../Parameters.sol";


contract TCRBase is ERC20Acceptor {
  using Fractional for uint256;
  using SafeMath for uint256;

  event ApplicationSubmitted(bytes32 data, address indexed proposer, uint256 listAt, uint256 deposit);
  event EntryDeposited(bytes32 indexed data, uint256 value);
  event EntryWithdrawn(bytes32 indexed data,uint256 value);
  event EntryExited(bytes32 indexed data);
  event ChallengeInitiated(bytes32 indexed data, uint256 indexed challengeId, address indexed challenger, uint256 stake, bytes32 reasonData, uint256 proposerVote, uint256 challengerVote);
  event ChallengeVoteCommitted(uint256 indexed challengeId,address indexed voter, bytes32 commitValue, uint256 weight);
  event ChallengeVoteRevealed(uint256 indexed challengeId,address indexed voter, bool voteKeep);
  event ChallengeSuccess(bytes32 indexed data, uint256 indexed challengeId, uint256 voterRewardPool, uint256 challengerReward);
  event ChallengeFailed(bytes32 indexed data, uint256 indexed challengeId, uint256 voterRewardPool, uint256 proposerReward);
  event ChallengeInconclusive(bytes32 indexed data, uint256 indexed challengeId);
  event ChallengeRewardClaimed(uint256 indexed challengeId, address indexed voter, uint256 reward);

  Parameters public params;
  SnapshotToken public token;
  bytes8 public prefix;

  /// A TCR entry is considered to exist in 'entries' map iff its 'listedAt' is nonzero.
  struct Entry {
    address proposer;        /// The entry proposer
    uint256 deposit;         /// Amount token that is not on challenge stake
    uint256 listedAt;        /// Expiration time of entry's 'pending' status
    uint256 challengeId;     /// Id of challenge, applicable if not zero
  }
  enum ChallengeState { Invalid, Open, Kept, Removed, Inconclusive }
  enum VoteStatus { Nothing, Committed, VoteKeep, VoteRemove, Claimed }

  /// A challenge represent a challenge for a TCR entry.
  struct Challenge {
    bytes32 entryData;            /// The hash of data that is in question
    bytes32 reasonData;           /// The hash of reason for this challenge
    address challenger;           /// The challenger
    uint256 rewardPool;           /// Remaining reward pool. Relevant after resolved.
    uint256 remainingRewardVotes; /// Remaining voting power to claim rewards.
    uint256 commitEndTime;
    uint256 revealEndTime;
    uint256 snapshotNonce;
    uint256 voteRemoveRequiredPct;
    uint256 voteMinParticipation;
    uint256 keepCount;
    uint256 removeCount;
    uint256 totalCommitCount;
    mapping (address => bytes32) voteCommits;
    mapping (address => VoteStatus) voteStatuses;
    ChallengeState state;
  }

  mapping (bytes32 => Entry) public entries;
  mapping (uint256 => Challenge) public challenges;
  uint256 nextChallengeNonce = 1;

  constructor(bytes8 _prefix, Parameters _params) public {
    params = _params;
    prefix = _prefix;
    token = _params.token();
  }

  modifier entryMustExist(bytes32 data) {
    require(entries[data].listedAt > 0);
    _;
  }

  modifier entryMustNotExist(bytes32 data) {
    require(entries[data].listedAt == 0);
    _;
  }

  function isEntryActive(bytes32 data) public view returns (bool) {
    uint256 listedAt = entries[data].listedAt;
    return listedAt != 0 && now >= listedAt;
  }

  function getVoteStatus(uint256 challengeId, address voter) public view returns (VoteStatus) {
    return challenges[challengeId].voteStatuses[voter];
  }

  function currentMinDeposit(bytes32 entryData) public view entryMustExist(entryData) returns (uint256) {
    Entry storage entry = entries[entryData];
    uint256 minDeposit = params.get(prefix, "min_deposit");
    if (now < entry.listedAt) {
      return minDeposit;
    } else {
      address depositDecayFunction = address(params.get(prefix, "deposit_decay_function"));
      if (depositDecayFunction == address(0)) return minDeposit;
      else return Expression(depositDecayFunction).evaluate(now.sub(entry.listedAt)).mulFrac(minDeposit);
    }
  }

  /// Apply a new entry to the TCR. The applicant must stake token at least `min_deposit`.
  /// Application will get auto-approved if no challenge happens in `apply_stage_length` seconds.
  function applyEntry(address proposer, uint256 stake, bytes32 data)
    public
    requireToken(token, proposer, stake)
    entryMustNotExist(data)
  {
    require(stake >= params.get(prefix, "min_deposit"));
    Entry storage entry = entries[data];
    entry.proposer = proposer;
    entry.deposit = stake;
    entry.listedAt = now.add(params.get(prefix, "apply_stage_length"));
    emit ApplicationSubmitted(data, proposer, entry.listedAt, stake);
  }

  function deposit(address depositor, uint256 amount, bytes32 data)
    public
    requireToken(token, depositor, amount)
    entryMustExist(data)
  {
    Entry storage entry = entries[data];
    require(entry.proposer == depositor);
    entry.deposit = entry.deposit.add(amount);
    emit EntryDeposited(data, amount);
  }

  function withdraw(bytes32 data, uint256 amount)
    public
    entryMustExist(data)
  {
    Entry storage entry = entries[data];
    require(entry.proposer == msg.sender);
    if (entry.challengeId == 0) {
      require(entry.deposit >= amount.add(currentMinDeposit(data)));
    } else {
      require(entry.deposit >= amount);
    }
    entry.deposit = entry.deposit.sub(amount);
    require(token.transfer(msg.sender, amount));
    emit EntryWithdrawn(data, amount);
  }

  function exit(bytes32 data) public entryMustExist(data) {
    Entry storage entry = entries[data];
    require(entry.proposer == msg.sender);
    require(entry.challengeId == 0);
    _deleteEntry(data);
    emit EntryExited(data);
  }

  function initiateChallenge(address challenger, uint256 challengeDeposit, bytes32 data, bytes32 reasonData)
    public
    requireToken(token, challenger, challengeDeposit)
    entryMustExist(data)
  {
    Entry storage entry = entries[data];
    require(entry.challengeId == 0 && entry.proposer != challenger);
    uint256 stake = Math.min(entry.deposit, currentMinDeposit(data));
    require(challengeDeposit >= stake);
    if (challengeDeposit != stake) {
      require(token.transfer(challenger, challengeDeposit.sub(stake)));
    }
    entry.deposit = entry.deposit.sub(stake);
    uint256 challengeId = nextChallengeNonce;
    uint256 proposerVote = token.historicalVotingPowerAtNonce(entry.proposer, token.votingPowerChangeNonce());
    uint256 challengerVote = token.historicalVotingPowerAtNonce(challenger, token.votingPowerChangeNonce());
    nextChallengeNonce = challengeId.add(1);
    challenges[challengeId] = Challenge({
      entryData: data,
      reasonData: reasonData,
      challenger: challenger,
      rewardPool: stake,
      remainingRewardVotes: 0,
      commitEndTime: now.add(params.get(prefix, "commit_time")),
      revealEndTime: now.add(params.get(prefix, "commit_time")).add(params.get(prefix, "reveal_time")),
      snapshotNonce: token.votingPowerChangeNonce(),
      voteRemoveRequiredPct: params.get(prefix, "support_required_pct"),
      voteMinParticipation: params.get(prefix, "min_participation_pct").mulFrac(token.totalSupply()),
      keepCount: proposerVote,
      removeCount: challengerVote,
      totalCommitCount: proposerVote.add(challengerVote),
      state: ChallengeState.Open
    });
    entry.challengeId = challengeId;
    challenges[challengeId].voteStatuses[entry.proposer] = VoteStatus.VoteKeep;
    challenges[challengeId].voteStatuses[challenger] = VoteStatus.VoteRemove;
    emit ChallengeInitiated(data, challengeId, challenger, stake, reasonData, proposerVote, challengerVote);
  }

  function commitVote(uint256 challengeId, bytes32 commitValue) public {
    Challenge storage challenge = challenges[challengeId];
    require(challenge.state == ChallengeState.Open && now < challenge.commitEndTime);
    require(challenge.voteStatuses[msg.sender] == VoteStatus.Nothing);
    challenge.voteCommits[msg.sender] = commitValue;
    challenge.voteStatuses[msg.sender] = VoteStatus.Committed;
    uint256 weight = token.historicalVotingPowerAtNonce(msg.sender, challenge.snapshotNonce);
    challenge.totalCommitCount = challenge.totalCommitCount.add(weight);
    emit ChallengeVoteCommitted(challengeId, msg.sender, commitValue, weight);
  }

  function revealVote(address voter, uint256 challengeId, bool voteKeep, uint256 salt) public {
    Challenge storage challenge = challenges[challengeId];
    require(challenge.state == ChallengeState.Open);
    require(now >= challenge.commitEndTime && now < challenge.revealEndTime);
    require(challenge.voteStatuses[voter] == VoteStatus.Committed);
    require(challenge.voteCommits[voter] == keccak256(abi.encodePacked(voteKeep, salt)));
    uint256 weight = token.historicalVotingPowerAtNonce(voter, challenge.snapshotNonce);
    if (voteKeep) {
      challenge.keepCount = challenge.keepCount.add(weight);
      challenge.voteStatuses[voter] = VoteStatus.VoteKeep;
    } else {
      challenge.removeCount = challenge.removeCount.add(weight);
      challenge.voteStatuses[voter] = VoteStatus.VoteRemove;
    }
    emit ChallengeVoteRevealed(challengeId, voter, voteKeep);
  }

  /// Resolve TCR challenge. If the challenge succeeds, the entry will be removed and the challenger
  /// gets the reward. Otherwise, the entry's `deposit` gets bumped by the reward.
  function resolveChallenge(uint256 challengeId) public {
    Challenge storage challenge = challenges[challengeId];
    require(challenge.state == ChallengeState.Open);
    ChallengeState result = _getChallengeResult(challenge);
    challenge.state = result;
    bytes32 data = challenge.entryData;
    Entry storage entry = entries[data];
    assert(entry.challengeId == challengeId);
    entry.challengeId = 0;
    uint256 challengerStake = challenge.rewardPool;
    uint256 winnerExtraReward = params.get(prefix, "dispensation_percentage").mulFrac(challengerStake);
    uint256 winnerTotalReward = challengerStake.add(winnerExtraReward);
    uint256 rewardPool = challengerStake.sub(winnerExtraReward);
    if (result == ChallengeState.Kept) {
      uint256 proposerVote = token.historicalVotingPowerAtNonce(entry.proposer, challenge.snapshotNonce);
      uint256 proposerVoteReward = rewardPool.mul(proposerVote).div(challenge.keepCount);
      winnerTotalReward = winnerTotalReward.add(proposerVoteReward);
      entry.deposit = entry.deposit.add(winnerTotalReward);
      challenge.rewardPool = rewardPool.sub(proposerVoteReward);
      challenge.remainingRewardVotes = challenge.keepCount.sub(proposerVote);
      challenge.voteStatuses[entry.proposer] = VoteStatus.Claimed;
      emit ChallengeFailed(data, challengeId, challenge.rewardPool, winnerTotalReward);
    } else if (result == ChallengeState.Removed) {
      uint256 challengerVote = token.historicalVotingPowerAtNonce(challenge.challenger, challenge.snapshotNonce);
      uint256 challengerVoteReward = rewardPool.mul(challengerVote).div(challenge.removeCount);
      winnerTotalReward = winnerTotalReward.add(challengerVoteReward);
      require(token.transfer(challenge.challenger, winnerTotalReward));
      challenge.rewardPool = rewardPool.sub(challengerVoteReward);
      challenge.remainingRewardVotes = challenge.removeCount.sub(challengerVote);
      _deleteEntry(data);
      challenge.voteStatuses[challenge.challenger] = VoteStatus.Claimed;
      emit ChallengeSuccess(data, challengeId, challenge.rewardPool, winnerTotalReward);
    } else if (result == ChallengeState.Inconclusive) {
      entry.deposit = entry.deposit.add(challengerStake);
      require(token.transfer(challenge.challenger, challengerStake));
      challenge.rewardPool = 0;
      emit ChallengeInconclusive(data, challengeId);
    } else {
      assert(false);
    }
  }

  function claimReward(address voter, uint256 challengeId) public {
    Challenge storage challenge = challenges[challengeId];
    require(challenge.remainingRewardVotes > 0);
    if (challenge.state == ChallengeState.Kept) {
      require(challenge.voteStatuses[voter] == VoteStatus.VoteKeep);
    } else if (challenge.state == ChallengeState.Removed) {
      require(challenge.voteStatuses[voter] == VoteStatus.VoteRemove);
    } else {
      revert();
    }
    challenge.voteStatuses[voter] = VoteStatus.Claimed;
    uint256 weight = token.historicalVotingPowerAtNonce(voter, challenge.snapshotNonce);
    if (weight > 0) {
      uint256 remainingRewardPool = challenge.rewardPool;
      uint256 remainingRewardVotes = challenge.remainingRewardVotes;
      uint256 reward = remainingRewardPool.mul(weight).div(remainingRewardVotes);
      challenge.remainingRewardVotes = remainingRewardVotes.sub(weight);
      challenge.rewardPool = remainingRewardPool.sub(reward);
      require(token.transfer(voter, reward));
      emit ChallengeRewardClaimed(challengeId, voter, reward);
    }
  }

  function _getChallengeResult(Challenge storage challenge) internal view returns (ChallengeState) {
    assert(challenge.state == ChallengeState.Open);
    require(now >= challenge.commitEndTime);
    if (challenge.totalCommitCount < challenge.voteMinParticipation) {
      return ChallengeState.Inconclusive;
    }
    uint256 keepCount = challenge.keepCount;
    uint256 removeCount = challenge.removeCount;
    if (keepCount == 0 && removeCount == 0) {
      return ChallengeState.Inconclusive;
    }
    if (removeCount.mul(Fractional.getDenominator()) >= challenge.voteRemoveRequiredPct.mul(keepCount.add(removeCount))) {
      return ChallengeState.Removed;
    } else {
      return ChallengeState.Kept;
    }
  }

  function _deleteEntry(bytes32 data) internal {
    uint256 entryDeposit = entries[data].deposit;
    address proposer = entries[data].proposer;
    if (entryDeposit > 0) {
      require(token.transfer(proposer, entryDeposit));
    }
    delete entries[data];
  }
}

pragma solidity 0.5.9;

import "./TCRBase.sol";
import "./QueryInterface.sol";


/// "QueryTCR" extends `TCRBase` by making it compliant with `QueryInterface`. Users can ask if an entry exists
/// in the TCR. Note that due to TCR's unique economics, the costing of querying data here is zero.
contract QueryTCR is TCRBase, QueryInterface {

  constructor(bytes8 _prefix, Parameters _params, BandRegistry _registry)
    public TCRBase(_prefix, _params) QueryInterface(_registry) {}

  function queryPrice() public view returns (uint256) {
    return 0;
  }

  function queryImpl(bytes memory input) internal returns (bytes32 output, uint256 updatedAt, QueryStatus status) {
    if (input.length != 32) return ("", 0, QueryStatus.INVALID);
    bytes32 key = abi.decode(input, (bytes32));
    return (isEntryActive(bytes32(key)) ? bytes32(uint256(1)) : bytes32(uint256(0)), now, QueryStatus.OK);
  }
}

pragma solidity 0.5.9;

import "../BandRegistry.sol";


/// "QueryInterface" provides the standard `query` method for querying Band Protocol's curated data. The function
/// makes sure that query callers are not blacklisted and pay appropriate fee, as specified by `queryPrice` prior
/// to calling the meat `queryImpl` function.
contract QueryInterface {
  enum QueryStatus { INVALID, OK, NOT_AVAILABLE, DISAGREEMENT }
  event Query(address indexed caller, bytes input, QueryStatus status);
  BandRegistry public registry;

  constructor(BandRegistry _registry) public {
    registry = _registry;
  }

  function query(bytes calldata input)
    external payable returns (bytes32 output, uint256 updatedAt, QueryStatus status)
  {
    require(registry.verify(msg.sender));
    uint256 price = queryPrice();
    require(msg.value >= price);
    if (msg.value > price) msg.sender.transfer(msg.value - price);
    (output, updatedAt, status) = queryImpl(input);
    emit Query(msg.sender, input, status);
  }

  function queryPrice() public view returns (uint256);
  function queryImpl(bytes memory input)
    internal returns (bytes32 output, uint256 updatedAt, QueryStatus status);
}

pragma solidity 0.5.9;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./token/SnapshotToken.sol";
import "./utils/Fractional.sol";


/// "Parameters" contract controls how other smart contracts behave through a key-value mapping, which other contracts
/// will query using `get` or `getRaw` functions. Every dataset community has one governance parameters contract.
/// Additionally, there is one parameter contract that is controlled by BandToken for protocol-wide parameters.
/// Conducting parameter changes can be done through the following process.
///   1. Anyone can propose for a change by sending a `propose` transaction, which will assign an ID to the proposal.
///   2. While the proposal is open, token holders can vote for approval or rejection through `vote` function.
///   3. After the voting period ends, if the proposal receives enough participation and support, it will get accepted.
///      `resolve` function must to be called to trigger the decision process.
///   4. Additionally, to facilitate unanimous parameter changes, a proposal is automatically resolved prior to its
///      expiration if more than the required percentage of ALL tokens approve the proposal.
/// Parameters contract uses the following parameters for its internal logic. These parameters can be change via the
/// same proposal process.
///   `params:expiration_time`: Number of seconds that a proposal stays open after getting proposed.
///   `params:min_participation_pct`: % of tokens required to participate in order for a proposal to be considered.
///   `params:support_required_pct`: % of participating tokens required to approve a proposal.
/// Parameters contract is "Ownable" initially to allow its owner to overrule the parameters during the initial
/// deployment as a measure against possible smart contract vulnerabilities. Owner can be set to 0x0 address afterwards.
contract Parameters is Ownable {
  using SafeMath for uint256;
  using Fractional for uint256;

  event ProposalProposed(uint256 indexed proposalId, address indexed proposer, bytes32 reasonHash);
  event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool vote, uint256 votingPower);
  event ProposalAccepted(uint256 indexed proposalId);
  event ProposalRejected(uint256 indexed proposalId);
  event ParameterChanged(bytes32 indexed key, uint256 value);
  event ParameterProposed(uint256 indexed proposalId, bytes32 indexed key, uint256 value);

  struct ParameterValue { bool existed; uint256 value; }
  struct KeyValue { bytes32 key; uint256 value; }
  enum ProposalState { INVALID, OPEN, ACCEPTED, REJECTED }

  struct Proposal {
    uint256 changesCount;                   /// The number of parameter changes
    mapping (uint256 => KeyValue) changes;  /// The list of parameter changes in proposal
    uint256 snapshotNonce;                  /// The votingPowerNonce to count voting power
    uint256 expirationTime;                 /// The time at which this proposal resolves
    uint256 voteSupportRequiredPct;         /// Threshold % for determining proposal acceptance
    uint256 voteMinParticipation;           /// The minimum # of votes required
    uint256 totalVotingPower;               /// The total voting power at this snapshotNonce
    uint256 yesCount;                       /// The current total number of YES votes
    uint256 noCount;                        /// The current total number of NO votes
    mapping (address => bool) isVoted;      /// Mapping for check who already voted
    ProposalState proposalState;            /// Current state of this proposal.
  }

  SnapshotToken public token;
  Proposal[] public proposals;
  mapping (bytes32 => ParameterValue) public params;

  constructor(SnapshotToken _token) public {
    token = _token;
  }

  function get(bytes8 namespace, bytes24 key) public view returns (uint256) {
    uint8 namespaceSize = 0;
    while (namespaceSize < 8 && namespace[namespaceSize] != byte(0)) ++namespaceSize;
    return getRaw(bytes32(namespace) | (bytes32(key) >> (8 * namespaceSize)));
  }

  function getRaw(bytes32 rawKey) public view returns (uint256) {
    ParameterValue storage param = params[rawKey];
    require(param.existed);
    return param.value;
  }

  function set(bytes8 namespace, bytes24[] memory keys, uint256[] memory values) public onlyOwner {
    require(keys.length == values.length);
    bytes32[] memory rawKeys = new bytes32[](keys.length);
    uint8 namespaceSize = 0;
    while (namespaceSize < 8 && namespace[namespaceSize] != byte(0)) ++namespaceSize;
    for (uint256 i = 0; i < keys.length; i++) {
      rawKeys[i] = bytes32(namespace) | bytes32(keys[i]) >> (8 * namespaceSize);
    }
    setRaw(rawKeys, values);
  }

  function setRaw(bytes32[] memory rawKeys, uint256[] memory values) public onlyOwner {
    require(rawKeys.length == values.length);
    for (uint256 i = 0; i < rawKeys.length; i++) {
      params[rawKeys[i]].existed = true;
      params[rawKeys[i]].value = values[i];
      emit ParameterChanged(rawKeys[i], values[i]);
    }
  }

  function getProposalChange(uint256 proposalId, uint256 changeIndex) public view returns (bytes32, uint256) {
    KeyValue memory keyValue = proposals[proposalId].changes[changeIndex];
    return (keyValue.key, keyValue.value);
  }

  function propose(bytes32 reasonHash, bytes32[] calldata keys, uint256[] calldata values) external {
    require(keys.length == values.length);
    uint256 proposalId = proposals.length;
    proposals.push(Proposal({
      changesCount: keys.length,
      snapshotNonce: token.votingPowerChangeNonce(),
      expirationTime: now.add(getRaw("params:expiration_time")),
      voteSupportRequiredPct: getRaw("params:support_required_pct"),
      voteMinParticipation: getRaw("params:min_participation_pct").mulFrac(token.totalSupply()),
      totalVotingPower: token.totalSupply(),
      yesCount: 0,
      noCount: 0,
      proposalState: ProposalState.OPEN
    }));
    emit ProposalProposed(proposalId, msg.sender, reasonHash);
    for (uint256 index = 0; index < keys.length; ++index) {
      bytes32 key = keys[index];
      uint256 value = values[index];
      emit ParameterProposed(proposalId, key, value);
      proposals[proposalId].changes[index] = KeyValue({key: key, value: value});
    }
  }

  function vote(uint256 proposalId, bool accepted) public {
    Proposal storage proposal = proposals[proposalId];
    require(proposal.proposalState == ProposalState.OPEN);
    require(now < proposal.expirationTime);
    require(!proposal.isVoted[msg.sender]);
    uint256 votingPower = token.historicalVotingPowerAtNonce(msg.sender, proposal.snapshotNonce);
    require(votingPower > 0);
    if (accepted) {
      proposal.yesCount = proposal.yesCount.add(votingPower);
    } else {
      proposal.noCount = proposal.noCount.add(votingPower);
    }
    proposal.isVoted[msg.sender] = true;
    emit ProposalVoted(proposalId, msg.sender, accepted, votingPower);
    uint256 minVoteToAccept = proposal.voteSupportRequiredPct.mulFrac(proposal.totalVotingPower);
    uint256 minVoteToReject = proposal.totalVotingPower.sub(minVoteToAccept);
    if (proposal.yesCount >= minVoteToAccept) {
      _acceptProposal(proposalId);
    } else if (proposal.noCount > minVoteToReject) {
      _rejectProposal(proposalId);
    }
  }

  function resolve(uint256 proposalId) public {
    Proposal storage proposal = proposals[proposalId];
    require(proposal.proposalState == ProposalState.OPEN);
    require(now >= proposal.expirationTime);
    uint256 yesCount = proposal.yesCount;
    uint256 noCount = proposal.noCount;
    uint256 totalCount = yesCount.add(noCount);
    if (totalCount >= proposal.voteMinParticipation &&
        yesCount.mul(Fractional.getDenominator()) >= proposal.voteSupportRequiredPct.mul(totalCount)) {
      _acceptProposal(proposalId);
    } else {
      _rejectProposal(proposalId);
    }
  }

  function _acceptProposal(uint256 proposalId) internal {
    Proposal storage proposal = proposals[proposalId];
    proposal.proposalState = ProposalState.ACCEPTED;
    for (uint256 index = 0; index < proposal.changesCount; ++index) {
      bytes32 key = proposal.changes[index].key;
      uint256 value = proposal.changes[index].value;
      params[key].existed = true;
      params[key].value = value;
      emit ParameterChanged(key, value);
    }
    emit ProposalAccepted(proposalId);
  }

  function _rejectProposal(uint256 proposalId) internal {
    Proposal storage proposal = proposals[proposalId];
    proposal.proposalState = ProposalState.REJECTED;
    emit ProposalRejected(proposalId);
  }
}

pragma solidity 0.5.9;

import "./token/ERC20Base.sol";
import "./token/SnapshotToken.sol";


/// "BandToken" is the native ERC-20 token of Band Protocol.
contract BandToken is ERC20Base("BandToken", "BAND"), SnapshotToken {}

pragma solidity 0.5.9;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./BandToken.sol";
import "./data/WhiteListInterface.sol";
import "./exchange/BandExchangeInterface.sol";


/// "BandRegistry" keeps the addresses of three main smart contracts inside of Band Protocol ecosystem:
///   1. "band" - Band Protocol's native ERC-20 token.
///   2. "exchange" - Decentralized exchange for converting ETH to Band and vice versa.
///   3. "whiteList" - Smart contract for validating non-malicious data consumers.
contract BandRegistry is Ownable {
  BandToken public band;
  BandExchangeInterface public exchange;
  WhiteListInterface public whiteList;

  constructor(BandToken _band, BandExchangeInterface _exchange) public {
    band = _band;
    exchange = _exchange;
  }

  function verify(address reader) public view returns (bool) {
    if (address(whiteList) == address(0)) return true;
    return whiteList.verify(reader);
  }

  function setWhiteList(WhiteListInterface _whiteList) public onlyOwner {
    whiteList = _whiteList;
  }

  function setExchange(BandExchangeInterface _exchange) public onlyOwner {
    exchange = _exchange;
  }
}

pragma solidity 0.5.9;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";


/**
 * @title BancorPower, modified from the original "BancorFomula.sol"
 *        written by Bancor https://github.com/bancorprotocol/contracts
 *
 * @dev Changes include:
 *  1. Remove Bancor's specific functions and replace SafeMath with OpenZeppelin's.
 *  2. Change code from Contract to Library and change maxExpArray from being array
 *     with binary search inside `findPositionInMaxExpArray` to a simple linear search.
 *  3. Add requirement check that baseN >= baseD (this is always true for Bancor).
 * Licensed under Apache Lisense, Version 2.0.
 */
library BancorPower {
    using SafeMath for uint256;

    string internal constant version = '0.3';
    uint256 private constant ONE = 1;
    uint32 private constant MAX_WEIGHT = 1000000;
    uint8 private constant MIN_PRECISION = 32;
    uint8 private constant MAX_PRECISION = 127;

    /**
        Auto-generated via 'PrintIntScalingFactors.py'
    */
    uint256 private constant FIXED_1 = 0x080000000000000000000000000000000;
    uint256 private constant FIXED_2 = 0x100000000000000000000000000000000;
    uint256 private constant MAX_NUM = 0x200000000000000000000000000000000;

    /**
        Auto-generated via 'PrintLn2ScalingFactors.py'
    */
    uint256 private constant LN2_NUMERATOR   = 0x3f80fe03f80fe03f80fe03f80fe03f8;
    uint256 private constant LN2_DENOMINATOR = 0x5b9de1d10bf4103d647b0955897ba80;

    /**
        Auto-generated via 'PrintFunctionOptimalLog.py' and 'PrintFunctionOptimalExp.py'
    */
    uint256 private constant OPT_LOG_MAX_VAL = 0x15bf0a8b1457695355fb8ac404e7a79e3;
    uint256 private constant OPT_EXP_MAX_VAL = 0x800000000000000000000000000000000;

    /**
        General Description:
            Determine a value of precision.
            Calculate an integer approximation of (_baseN / _baseD) ^ (_expN / _expD) * 2 ^ precision.
            Return the result along with the precision used.

        Detailed Description:
            Instead of calculating "base ^ exp", we calculate "e ^ (log(base) * exp)".
            The value of "log(base)" is represented with an integer slightly smaller than "log(base) * 2 ^ precision".
            The larger "precision" is, the more accurately this value represents the real value.
            However, the larger "precision" is, the more bits are required in order to store this value.
            And the exponentiation function, which takes "x" and calculates "e ^ x", is limited to a maximum exponent (maximum value of "x").
            This maximum exponent depends on the "precision" used, and it is given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
            Hence we need to determine the highest precision which can be used for the given input, before calling the exponentiation function.
            This allows us to compute "base ^ exp" with maximum accuracy and without exceeding 256 bits in any of the intermediate computations.
            This functions assumes that "_expN < 2 ^ 256 / log(MAX_NUM - 1)", otherwise the multiplication should be replaced with a "safeMul".
    */
    function power(uint256 _baseN, uint256 _baseD, uint32 _expN, uint32 _expD) internal pure returns (uint256, uint8) {
        require(_baseN < MAX_NUM);
        require(_baseN >= _baseD);

        uint256 baseLog;
        uint256 base = _baseN * FIXED_1 / _baseD;
        if (base < OPT_LOG_MAX_VAL) {
            baseLog = optimalLog(base);
        }
        else {
            baseLog = generalLog(base);
        }

        uint256 baseLogTimesExp = baseLog * _expN / _expD;
        if (baseLogTimesExp < OPT_EXP_MAX_VAL) {
            return (optimalExp(baseLogTimesExp), MAX_PRECISION);
        }
        else {
            uint8 precision = findPositionInMaxExpArray(baseLogTimesExp);
            return (generalExp(baseLogTimesExp >> (MAX_PRECISION - precision), precision), precision);
        }
    }

    /**
    *   c >= 10^18
    *
     */
    function log(uint256 _c, uint256 _baseN, uint256 _baseD) internal pure returns (uint256) {
        // require(_baseN < MAX_NUM)
        require(_baseN >= _baseD);

        uint256 baseLog;
        uint256 base = _baseN * FIXED_1 / _baseD;
        if (base < OPT_LOG_MAX_VAL) {
            baseLog = optimalLog(base);
        } else {
            baseLog = generalLog(base);
        }

        return (baseLog * _c) / FIXED_1;
    }

    /**
        Compute log(x / FIXED_1) * FIXED_1.
        This functions assumes that "x >= FIXED_1", because the output would be negative otherwise.
    */
    function generalLog(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        // If x >= 2, then we compute the integer part of log2(x), which is larger than 0.
        if (x >= FIXED_2) {
            uint8 count = floorLog2(x / FIXED_1);
            x >>= count; // now x < 2
            res = count * FIXED_1;
        }

        // If x > 1, then we compute the fraction part of log2(x), which is larger than 0.
        if (x > FIXED_1) {
            for (uint8 i = MAX_PRECISION; i > 0; --i) {
                x = (x * x) / FIXED_1; // now 1 < x < 4
                if (x >= FIXED_2) {
                    x >>= 1; // now 1 < x < 2
                    res += ONE << (i - 1);
                }
            }
        }

        return res * LN2_NUMERATOR / LN2_DENOMINATOR;
    }

    /**
        Compute the largest integer smaller than or equal to the binary logarithm of the input.
    */
    function floorLog2(uint256 _n) internal pure returns (uint8) {
        uint8 res = 0;

        if (_n < 256) {
            // At most 8 iterations
            while (_n > 1) {
                _n >>= 1;
                res += 1;
            }
        }
        else {
            // Exactly 8 iterations
            for (uint8 s = 128; s > 0; s >>= 1) {
                if (_n >= (ONE << s)) {
                    _n >>= s;
                    res |= s;
                }
            }
        }

        return res;
    }

    /**
        The global "maxExpArray" is sorted in descending order, and therefore the following statements are equivalent:
        - This function finds the position of [the smallest value in "maxExpArray" larger than or equal to "x"]
        - This function finds the highest position of [a value in "maxExpArray" larger than or equal to "x"]
    */
    function findPositionInMaxExpArray(uint256 _x) internal pure returns (uint8) {
        if (0x1c35fedd14ffffffffffffffffffffffff >= _x) return  32;
        if (0x1b0ce43b323fffffffffffffffffffffff >= _x) return  33;
        if (0x19f0028ec1ffffffffffffffffffffffff >= _x) return  34;
        if (0x18ded91f0e7fffffffffffffffffffffff >= _x) return  35;
        if (0x17d8ec7f0417ffffffffffffffffffffff >= _x) return  36;
        if (0x16ddc6556cdbffffffffffffffffffffff >= _x) return  37;
        if (0x15ecf52776a1ffffffffffffffffffffff >= _x) return  38;
        if (0x15060c256cb2ffffffffffffffffffffff >= _x) return  39;
        if (0x1428a2f98d72ffffffffffffffffffffff >= _x) return  40;
        if (0x13545598e5c23fffffffffffffffffffff >= _x) return  41;
        if (0x1288c4161ce1dfffffffffffffffffffff >= _x) return  42;
        if (0x11c592761c666fffffffffffffffffffff >= _x) return  43;
        if (0x110a688680a757ffffffffffffffffffff >= _x) return  44;
        if (0x1056f1b5bedf77ffffffffffffffffffff >= _x) return  45;
        if (0x0faadceceeff8bffffffffffffffffffff >= _x) return  46;
        if (0x0f05dc6b27edadffffffffffffffffffff >= _x) return  47;
        if (0x0e67a5a25da4107fffffffffffffffffff >= _x) return  48;
        if (0x0dcff115b14eedffffffffffffffffffff >= _x) return  49;
        if (0x0d3e7a392431239fffffffffffffffffff >= _x) return  50;
        if (0x0cb2ff529eb71e4fffffffffffffffffff >= _x) return  51;
        if (0x0c2d415c3db974afffffffffffffffffff >= _x) return  52;
        if (0x0bad03e7d883f69bffffffffffffffffff >= _x) return  53;
        if (0x0b320d03b2c343d5ffffffffffffffffff >= _x) return  54;
        if (0x0abc25204e02828dffffffffffffffffff >= _x) return  55;
        if (0x0a4b16f74ee4bb207fffffffffffffffff >= _x) return  56;
        if (0x09deaf736ac1f569ffffffffffffffffff >= _x) return  57;
        if (0x0976bd9952c7aa957fffffffffffffffff >= _x) return  58;
        if (0x09131271922eaa606fffffffffffffffff >= _x) return  59;
        if (0x08b380f3558668c46fffffffffffffffff >= _x) return  60;
        if (0x0857ddf0117efa215bffffffffffffffff >= _x) return  61;
        if (0x07ffffffffffffffffffffffffffffffff >= _x) return  62;
        if (0x07abbf6f6abb9d087fffffffffffffffff >= _x) return  63;
        if (0x075af62cbac95f7dfa7fffffffffffffff >= _x) return  64;
        if (0x070d7fb7452e187ac13fffffffffffffff >= _x) return  65;
        if (0x06c3390ecc8af379295fffffffffffffff >= _x) return  66;
        if (0x067c00a3b07ffc01fd6fffffffffffffff >= _x) return  67;
        if (0x0637b647c39cbb9d3d27ffffffffffffff >= _x) return  68;
        if (0x05f63b1fc104dbd39587ffffffffffffff >= _x) return  69;
        if (0x05b771955b36e12f7235ffffffffffffff >= _x) return  70;
        if (0x057b3d49dda84556d6f6ffffffffffffff >= _x) return  71;
        if (0x054183095b2c8ececf30ffffffffffffff >= _x) return  72;
        if (0x050a28be635ca2b888f77fffffffffffff >= _x) return  73;
        if (0x04d5156639708c9db33c3fffffffffffff >= _x) return  74;
        if (0x04a23105873875bd52dfdfffffffffffff >= _x) return  75;
        if (0x0471649d87199aa990756fffffffffffff >= _x) return  76;
        if (0x04429a21a029d4c1457cfbffffffffffff >= _x) return  77;
        if (0x0415bc6d6fb7dd71af2cb3ffffffffffff >= _x) return  78;
        if (0x03eab73b3bbfe282243ce1ffffffffffff >= _x) return  79;
        if (0x03c1771ac9fb6b4c18e229ffffffffffff >= _x) return  80;
        if (0x0399e96897690418f785257fffffffffff >= _x) return  81;
        if (0x0373fc456c53bb779bf0ea9fffffffffff >= _x) return  82;
        if (0x034f9e8e490c48e67e6ab8bfffffffffff >= _x) return  83;
        if (0x032cbfd4a7adc790560b3337ffffffffff >= _x) return  84;
        if (0x030b50570f6e5d2acca94613ffffffffff >= _x) return  85;
        if (0x02eb40f9f620fda6b56c2861ffffffffff >= _x) return  86;
        if (0x02cc8340ecb0d0f520a6af58ffffffffff >= _x) return  87;
        if (0x02af09481380a0a35cf1ba02ffffffffff >= _x) return  88;
        if (0x0292c5bdd3b92ec810287b1b3fffffffff >= _x) return  89;
        if (0x0277abdcdab07d5a77ac6d6b9fffffffff >= _x) return  90;
        if (0x025daf6654b1eaa55fd64df5efffffffff >= _x) return  91;
        if (0x0244c49c648baa98192dce88b7ffffffff >= _x) return  92;
        if (0x022ce03cd5619a311b2471268bffffffff >= _x) return  93;
        if (0x0215f77c045fbe885654a44a0fffffffff >= _x) return  94;
        if (0x01ffffffffffffffffffffffffffffffff >= _x) return  95;
        if (0x01eaefdbdaaee7421fc4d3ede5ffffffff >= _x) return  96;
        if (0x01d6bd8b2eb257df7e8ca57b09bfffffff >= _x) return  97;
        if (0x01c35fedd14b861eb0443f7f133fffffff >= _x) return  98;
        if (0x01b0ce43b322bcde4a56e8ada5afffffff >= _x) return  99;
        if (0x019f0028ec1fff007f5a195a39dfffffff >= _x) return 100;
        if (0x018ded91f0e72ee74f49b15ba527ffffff >= _x) return 101;
        if (0x017d8ec7f04136f4e5615fd41a63ffffff >= _x) return 102;
        if (0x016ddc6556cdb84bdc8d12d22e6fffffff >= _x) return 103;
        if (0x015ecf52776a1155b5bd8395814f7fffff >= _x) return 104;
        if (0x015060c256cb23b3b3cc3754cf40ffffff >= _x) return 105;
        if (0x01428a2f98d728ae223ddab715be3fffff >= _x) return 106;
        if (0x013545598e5c23276ccf0ede68034fffff >= _x) return 107;
        if (0x01288c4161ce1d6f54b7f61081194fffff >= _x) return 108;
        if (0x011c592761c666aa641d5a01a40f17ffff >= _x) return 109;
        if (0x0110a688680a7530515f3e6e6cfdcdffff >= _x) return 110;
        if (0x01056f1b5bedf75c6bcb2ce8aed428ffff >= _x) return 111;
        if (0x00faadceceeff8a0890f3875f008277fff >= _x) return 112;
        if (0x00f05dc6b27edad306388a600f6ba0bfff >= _x) return 113;
        if (0x00e67a5a25da41063de1495d5b18cdbfff >= _x) return 114;
        if (0x00dcff115b14eedde6fc3aa5353f2e4fff >= _x) return 115;
        if (0x00d3e7a3924312399f9aae2e0f868f8fff >= _x) return 116;
        if (0x00cb2ff529eb71e41582cccd5a1ee26fff >= _x) return 117;
        if (0x00c2d415c3db974ab32a51840c0b67edff >= _x) return 118;
        if (0x00bad03e7d883f69ad5b0a186184e06bff >= _x) return 119;
        if (0x00b320d03b2c343d4829abd6075f0cc5ff >= _x) return 120;
        if (0x00abc25204e02828d73c6e80bcdb1a95bf >= _x) return 121;
        if (0x00a4b16f74ee4bb2040a1ec6c15fbbf2df >= _x) return 122;
        if (0x009deaf736ac1f569deb1b5ae3f36c130f >= _x) return 123;
        if (0x00976bd9952c7aa957f5937d790ef65037 >= _x) return 124;
        if (0x009131271922eaa6064b73a22d0bd4f2bf >= _x) return 125;
        if (0x008b380f3558668c46c91c49a2f8e967b9 >= _x) return 126;
        if (0x00857ddf0117efa215952912839f6473e6 >= _x) return 127;
        require(false);
        return 0;
    }

    /**
        This function can be auto-generated by the script 'PrintFunctionGeneralExp.py'.
        It approximates "e ^ x" via maclaurin summation: "(x^0)/0! + (x^1)/1! + ... + (x^n)/n!".
        It returns "e ^ (x / 2 ^ precision) * 2 ^ precision", that is, the result is upshifted for accuracy.
        The global "maxExpArray" maps each "precision" to "((maximumExponent + 1) << (MAX_PRECISION - precision)) - 1".
        The maximum permitted value for "x" is therefore given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
    */
    function generalExp(uint256 _x, uint8 _precision) internal pure returns (uint256) {
        uint256 xi = _x;
        uint256 res = 0;

        xi = (xi * _x) >> _precision; res += xi * 0x3442c4e6074a82f1797f72ac0000000; // add x^02 * (33! / 02!)
        xi = (xi * _x) >> _precision; res += xi * 0x116b96f757c380fb287fd0e40000000; // add x^03 * (33! / 03!)
        xi = (xi * _x) >> _precision; res += xi * 0x045ae5bdd5f0e03eca1ff4390000000; // add x^04 * (33! / 04!)
        xi = (xi * _x) >> _precision; res += xi * 0x00defabf91302cd95b9ffda50000000; // add x^05 * (33! / 05!)
        xi = (xi * _x) >> _precision; res += xi * 0x002529ca9832b22439efff9b8000000; // add x^06 * (33! / 06!)
        xi = (xi * _x) >> _precision; res += xi * 0x00054f1cf12bd04e516b6da88000000; // add x^07 * (33! / 07!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000a9e39e257a09ca2d6db51000000; // add x^08 * (33! / 08!)
        xi = (xi * _x) >> _precision; res += xi * 0x000012e066e7b839fa050c309000000; // add x^09 * (33! / 09!)
        xi = (xi * _x) >> _precision; res += xi * 0x000001e33d7d926c329a1ad1a800000; // add x^10 * (33! / 10!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000002bee513bdb4a6b19b5f800000; // add x^11 * (33! / 11!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000003a9316fa79b88eccf2a00000; // add x^12 * (33! / 12!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000048177ebe1fa812375200000; // add x^13 * (33! / 13!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000005263fe90242dcbacf00000; // add x^14 * (33! / 14!)
        xi = (xi * _x) >> _precision; res += xi * 0x000000000057e22099c030d94100000; // add x^15 * (33! / 15!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000057e22099c030d9410000; // add x^16 * (33! / 16!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000052b6b54569976310000; // add x^17 * (33! / 17!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000004985f67696bf748000; // add x^18 * (33! / 18!)
        xi = (xi * _x) >> _precision; res += xi * 0x000000000000003dea12ea99e498000; // add x^19 * (33! / 19!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000031880f2214b6e000; // add x^20 * (33! / 20!)
        xi = (xi * _x) >> _precision; res += xi * 0x000000000000000025bcff56eb36000; // add x^21 * (33! / 21!)
        xi = (xi * _x) >> _precision; res += xi * 0x000000000000000001b722e10ab1000; // add x^22 * (33! / 22!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000001317c70077000; // add x^23 * (33! / 23!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000cba84aafa00; // add x^24 * (33! / 24!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000082573a0a00; // add x^25 * (33! / 25!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000005035ad900; // add x^26 * (33! / 26!)
        xi = (xi * _x) >> _precision; res += xi * 0x000000000000000000000002f881b00; // add x^27 * (33! / 27!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000001b29340; // add x^28 * (33! / 28!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000000000efc40; // add x^29 * (33! / 29!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000007fe0; // add x^30 * (33! / 30!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000000420; // add x^31 * (33! / 31!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000000021; // add x^32 * (33! / 32!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000000001; // add x^33 * (33! / 33!)

        return res / 0x688589cc0e9505e2f2fee5580000000 + _x + (ONE << _precision); // divide by 33! and then add x^1 / 1! + x^0 / 0!
    }

    /**
        Return log(x / FIXED_1) * FIXED_1
        Input range: FIXED_1 <= x <= LOG_EXP_MAX_VAL - 1
        Auto-generated via 'PrintFunctionOptimalLog.py'
        Detailed description:
        - Rewrite the input as a product of natural exponents and a single residual r, such that 1 < r < 2
        - The natural logarithm of each (pre-calculated) exponent is the degree of the exponent
        - The natural logarithm of r is calculated via Taylor series for log(1 + x), where x = r - 1
        - The natural logarithm of the input is calculated by summing up the intermediate results above
        - For example: log(250) = log(e^4 * e^1 * e^0.5 * 1.021692859) = 4 + 1 + 0.5 + log(1 + 0.021692859)
    */
    function optimalLog(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;
        uint256 w;

        if (x >= 0xd3094c70f034de4b96ff7d5b6f99fcd8) {res += 0x40000000000000000000000000000000; x = x * FIXED_1 / 0xd3094c70f034de4b96ff7d5b6f99fcd8;} // add 1 / 2^1
        if (x >= 0xa45af1e1f40c333b3de1db4dd55f29a7) {res += 0x20000000000000000000000000000000; x = x * FIXED_1 / 0xa45af1e1f40c333b3de1db4dd55f29a7;} // add 1 / 2^2
        if (x >= 0x910b022db7ae67ce76b441c27035c6a1) {res += 0x10000000000000000000000000000000; x = x * FIXED_1 / 0x910b022db7ae67ce76b441c27035c6a1;} // add 1 / 2^3
        if (x >= 0x88415abbe9a76bead8d00cf112e4d4a8) {res += 0x08000000000000000000000000000000; x = x * FIXED_1 / 0x88415abbe9a76bead8d00cf112e4d4a8;} // add 1 / 2^4
        if (x >= 0x84102b00893f64c705e841d5d4064bd3) {res += 0x04000000000000000000000000000000; x = x * FIXED_1 / 0x84102b00893f64c705e841d5d4064bd3;} // add 1 / 2^5
        if (x >= 0x8204055aaef1c8bd5c3259f4822735a2) {res += 0x02000000000000000000000000000000; x = x * FIXED_1 / 0x8204055aaef1c8bd5c3259f4822735a2;} // add 1 / 2^6
        if (x >= 0x810100ab00222d861931c15e39b44e99) {res += 0x01000000000000000000000000000000; x = x * FIXED_1 / 0x810100ab00222d861931c15e39b44e99;} // add 1 / 2^7
        if (x >= 0x808040155aabbbe9451521693554f733) {res += 0x00800000000000000000000000000000; x = x * FIXED_1 / 0x808040155aabbbe9451521693554f733;} // add 1 / 2^8

        z = y = x - FIXED_1;
        w = y * y / FIXED_1;
        res += z * (0x100000000000000000000000000000000 - y) / 0x100000000000000000000000000000000; z = z * w / FIXED_1; // add y^01 / 01 - y^02 / 02
        res += z * (0x0aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa - y) / 0x200000000000000000000000000000000; z = z * w / FIXED_1; // add y^03 / 03 - y^04 / 04
        res += z * (0x099999999999999999999999999999999 - y) / 0x300000000000000000000000000000000; z = z * w / FIXED_1; // add y^05 / 05 - y^06 / 06
        res += z * (0x092492492492492492492492492492492 - y) / 0x400000000000000000000000000000000; z = z * w / FIXED_1; // add y^07 / 07 - y^08 / 08
        res += z * (0x08e38e38e38e38e38e38e38e38e38e38e - y) / 0x500000000000000000000000000000000; z = z * w / FIXED_1; // add y^09 / 09 - y^10 / 10
        res += z * (0x08ba2e8ba2e8ba2e8ba2e8ba2e8ba2e8b - y) / 0x600000000000000000000000000000000; z = z * w / FIXED_1; // add y^11 / 11 - y^12 / 12
        res += z * (0x089d89d89d89d89d89d89d89d89d89d89 - y) / 0x700000000000000000000000000000000; z = z * w / FIXED_1; // add y^13 / 13 - y^14 / 14
        res += z * (0x088888888888888888888888888888888 - y) / 0x800000000000000000000000000000000;                      // add y^15 / 15 - y^16 / 16

        return res;
    }

    /**
        Return e ^ (x / FIXED_1) * FIXED_1
        Input range: 0 <= x <= OPT_EXP_MAX_VAL - 1
        Auto-generated via 'PrintFunctionOptimalExp.py'
        Detailed description:
        - Rewrite the input as a sum of binary exponents and a single residual r, as small as possible
        - The exponentiation of each binary exponent is given (pre-calculated)
        - The exponentiation of r is calculated via Taylor series for e^x, where x = r
        - The exponentiation of the input is calculated by multiplying the intermediate results above
        - For example: e^5.021692859 = e^(4 + 1 + 0.5 + 0.021692859) = e^4 * e^1 * e^0.5 * e^0.021692859
    */
    function optimalExp(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;

        z = y = x % 0x10000000000000000000000000000000; // get the input modulo 2^(-3)
        z = z * y / FIXED_1; res += z * 0x10e1b3be415a0000; // add y^02 * (20! / 02!)
        z = z * y / FIXED_1; res += z * 0x05a0913f6b1e0000; // add y^03 * (20! / 03!)
        z = z * y / FIXED_1; res += z * 0x0168244fdac78000; // add y^04 * (20! / 04!)
        z = z * y / FIXED_1; res += z * 0x004807432bc18000; // add y^05 * (20! / 05!)
        z = z * y / FIXED_1; res += z * 0x000c0135dca04000; // add y^06 * (20! / 06!)
        z = z * y / FIXED_1; res += z * 0x0001b707b1cdc000; // add y^07 * (20! / 07!)
        z = z * y / FIXED_1; res += z * 0x000036e0f639b800; // add y^08 * (20! / 08!)
        z = z * y / FIXED_1; res += z * 0x00000618fee9f800; // add y^09 * (20! / 09!)
        z = z * y / FIXED_1; res += z * 0x0000009c197dcc00; // add y^10 * (20! / 10!)
        z = z * y / FIXED_1; res += z * 0x0000000e30dce400; // add y^11 * (20! / 11!)
        z = z * y / FIXED_1; res += z * 0x000000012ebd1300; // add y^12 * (20! / 12!)
        z = z * y / FIXED_1; res += z * 0x0000000017499f00; // add y^13 * (20! / 13!)
        z = z * y / FIXED_1; res += z * 0x0000000001a9d480; // add y^14 * (20! / 14!)
        z = z * y / FIXED_1; res += z * 0x00000000001c6380; // add y^15 * (20! / 15!)
        z = z * y / FIXED_1; res += z * 0x000000000001c638; // add y^16 * (20! / 16!)
        z = z * y / FIXED_1; res += z * 0x0000000000001ab8; // add y^17 * (20! / 17!)
        z = z * y / FIXED_1; res += z * 0x000000000000017c; // add y^18 * (20! / 18!)
        z = z * y / FIXED_1; res += z * 0x0000000000000014; // add y^19 * (20! / 19!)
        z = z * y / FIXED_1; res += z * 0x0000000000000001; // add y^20 * (20! / 20!)
        res = res / 0x21c3677c82b40000 + y + FIXED_1; // divide by 20! and then add y^1 / 1! + y^0 / 0!

        if ((x & 0x010000000000000000000000000000000) != 0) res = res * 0x1c3d6a24ed82218787d624d3e5eba95f9 / 0x18ebef9eac820ae8682b9793ac6d1e776; // multiply by e^2^(-3)
        if ((x & 0x020000000000000000000000000000000) != 0) res = res * 0x18ebef9eac820ae8682b9793ac6d1e778 / 0x1368b2fc6f9609fe7aceb46aa619baed4; // multiply by e^2^(-2)
        if ((x & 0x040000000000000000000000000000000) != 0) res = res * 0x1368b2fc6f9609fe7aceb46aa619baed5 / 0x0bc5ab1b16779be3575bd8f0520a9f21f; // multiply by e^2^(-1)
        if ((x & 0x080000000000000000000000000000000) != 0) res = res * 0x0bc5ab1b16779be3575bd8f0520a9f21e / 0x0454aaa8efe072e7f6ddbab84b40a55c9; // multiply by e^2^(+0)
        if ((x & 0x100000000000000000000000000000000) != 0) res = res * 0x0454aaa8efe072e7f6ddbab84b40a55c5 / 0x00960aadc109e7a3bf4578099615711ea; // multiply by e^2^(+1)
        if ((x & 0x200000000000000000000000000000000) != 0) res = res * 0x00960aadc109e7a3bf4578099615711d7 / 0x0002bf84208204f5977f9a8cf01fdce3d; // multiply by e^2^(+2)
        if ((x & 0x400000000000000000000000000000000) != 0) res = res * 0x0002bf84208204f5977f9a8cf01fdc307 / 0x0000003c6ab775dd0b95b4cbee7e65d11; // multiply by e^2^(+3)

        return res;
    }
}

pragma solidity ^0.5.0;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
    * @dev Transfer token for a specified addresses
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}

pragma solidity ^0.5.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

pragma solidity ^0.5.0;

/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
    /**
    * @dev Returns the largest of two numbers.
    */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
    * @dev Returns the smallest of two numbers.
    */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
    * @dev Calculates the average of two numbers. Since these are integers,
    * averages of an even and odd number cannot be represented, and will be
    * rounded down.
    */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

pragma solidity ^0.5.0;

import "../Roles.sol";

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}