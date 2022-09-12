// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./interfaces/IVerifier.sol";
import "./interfaces/IRewardSwap.sol";
import "./interfaces/ISacredTrees.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface Hasher {
  function poseidon(bytes32[1] calldata inputs) external pure returns (bytes32);
}

interface AaveInterestsProxy {
  function withdraw(uint256 amount, address receiver) external;
}

interface ETHSacred {
  function totalAaveInterests() external pure returns(uint256);
}

struct ReferenceContracts {
  address rewardSwap;
  address governance;
  address sacredTrees;
  address sacredProxy;
  address aaveInterestsProxy;
}

contract Miner is ReentrancyGuard{
  using SafeMath for uint256;

  IVerifier public rewardVerifier;
  IVerifier public withdrawVerifier;
  IVerifier public treeUpdateVerifier;
  IRewardSwap public immutable rewardSwap;
  address public immutable governance;
  address public immutable sacredProxy;
  ISacredTrees public sacredTrees;
  ShareTrack public shareTrack;

  mapping(bytes32 => bool) public accountNullifiers;
  mapping(bytes32 => bool) public rewardNullifiers;
  uint256 public minimumInterests;
  uint256 public aaveInterestFee = 50;// 0.5%, 50 / 10000, value: 0, 1 (0.01%),~ 1000 (10%)
  uint256 private instanceCount;
  Hasher private hasher;
  address public aaveInterestsProxy;
  mapping(address => uint256) public rates;
  mapping(uint256 => address) public instances;
  mapping(address => uint256) public activeDeposits;
  mapping(bytes32 => uint256[2]) public totalShareSnapshots;

  uint256 public accountCount;
  uint256 public constant ACCOUNT_ROOT_HISTORY_SIZE = 100;
  bytes32[ACCOUNT_ROOT_HISTORY_SIZE] public accountRoots;

  event NewAccount(bytes32 commitment, bytes32 nullifier, bytes encryptedAccount, uint256 index);
  event RateChanged(address instance, uint256 value);
  event VerifiersUpdated(address reward, address withdraw, address treeUpdate);
  event AaveInterestsAmount(uint256 amount);

  struct ShareTrack {
    uint256 lastUpdated;
    uint256 totalShares;
  }

  struct TreeUpdateArgs {
    bytes32 oldRoot;
    bytes32 newRoot;
    bytes32 leaf;
    uint256 pathIndices;
  }

  struct AccountUpdate {
    bytes32 inputRoot;
    bytes32 inputNullifierHash;
    bytes32 outputRoot;
    uint256 outputPathIndices;
    bytes32 outputCommitment;
  }

  struct RewardExtData {
    address relayer;
    bytes encryptedAccount;
  }

  struct RewardArgs {
    uint256 rate;
    uint256 fee;
    address instance;
    uint256 apAmount;
    uint256 aaveInterestAmount;
    bytes32 rewardNullifier;
    bytes32 extDataHash;
    bytes32 depositRoot;
    bytes32 withdrawalRoot;
    RewardExtData extData;
    AccountUpdate account;
  }

  struct WithdrawExtData {
    uint256 fee;
    address recipient;
    address relayer;
    bytes encryptedAccount;
  }

  struct WithdrawArgs {
    uint256 apAmount;
    uint256 aaveInterestAmount;
    bytes32 extDataHash;
    WithdrawExtData extData;
    AccountUpdate account;
  }

  struct Rate {
    address instance;
    uint256 value;
  }

  modifier onlySacredProxy {
    require(msg.sender == sacredProxy, "Not authorized");
    _;
  }

  modifier onlyGovernance() {
    require(msg.sender == governance, "Only governance can perform this action");
    _;
  }

  constructor (
    ReferenceContracts memory contracts,
    address[3] memory _verifiers,
    address _hasher,
    bytes32 _accountRoot,
    Rate[] memory _rates,
    uint256 _minimumInterests,
    uint256 _aaveInterestFee
  ) {
    rewardSwap = IRewardSwap(contracts.rewardSwap);
    governance = contracts.governance;
    sacredProxy = contracts.sacredProxy;
    sacredTrees = ISacredTrees(contracts.sacredTrees);
    minimumInterests = _minimumInterests;
    aaveInterestFee = _aaveInterestFee;
    hasher = Hasher(_hasher);
    aaveInterestsProxy = contracts.aaveInterestsProxy;
    // insert empty tree root without incrementing accountCount counter
    accountRoots[0] = _accountRoot;

    _setRates(_rates);
    // prettier-ignore

    _setVerifiers([
      IVerifier(_verifiers[0]),
      IVerifier(_verifiers[1]),
      IVerifier(_verifiers[2])
    ]);
    shareTrack.lastUpdated = block.number;
  }

  function updateShares(address instance, bool byDeposit, bytes32 nullifier) external onlySacredProxy {
    _updateShares();
    if(byDeposit) {
      activeDeposits[instance]++;
    } else {
      activeDeposits[instance]--;
      bytes32 key = hasher.poseidon([nullifier]);
      uint256 totalInterests = 0;
      for(uint256 i = 0; i < instanceCount; ++i) {
        totalInterests +=  ETHSacred(instances[i]).totalAaveInterests();
      }
      totalShareSnapshots[key] = [shareTrack.totalShares, totalInterests];
    }
  }

  function getAaveInterestsAmount(bytes32 rewardNullifier, uint256 apAmount) public returns (uint256) {
    uint256 interests = 0;
    if(totalShareSnapshots[rewardNullifier][0] > 0) {
      interests = totalShareSnapshots[rewardNullifier][1].mul(apAmount).div(totalShareSnapshots[rewardNullifier][0]);
    }
    emit AaveInterestsAmount(interests);
    return interests;
  }

  function reward(bytes memory _proof, RewardArgs memory _args) public {
    reward(_proof, _args, new bytes(0), TreeUpdateArgs(0, 0, 0, 0));
  }

  function batchReward(bytes[] calldata _rewardArgs) external {
    for (uint256 i = 0; i < _rewardArgs.length; ++i) {
      (bytes memory proof, RewardArgs memory args) = abi.decode(_rewardArgs[i], (bytes, RewardArgs));
      reward(proof, args);
    }
  }

  function reward (
    bytes memory _proof,
    RewardArgs memory _args,
    bytes memory _treeUpdateProof,
    TreeUpdateArgs memory _treeUpdateArgs
  ) public {
    validateAccountUpdate(_args.account, _treeUpdateProof, _treeUpdateArgs);
    sacredTrees.validateRoots(_args.depositRoot, _args.withdrawalRoot);
    require(_args.extDataHash == keccak248(abi.encode(_args.extData)), "Incorrect external data hash");
    require(_args.fee < 2**248, "Fee value out of range");
    require(_args.rate == rates[_args.instance] && _args.rate > 0, "Invalid reward rate");
    require(!rewardNullifiers[_args.rewardNullifier], "Reward has been already spent");
    require(_args.aaveInterestAmount == getAaveInterestsAmount(_args.rewardNullifier, _args.apAmount), "Incorrect value for aave interest amount");
    require(
      rewardVerifier.verifyProof(
        _proof,
        [
          uint256(_args.rate),
          uint256(_args.fee),
          uint256(uint160(_args.instance)),
          uint256(_args.apAmount),
          uint256(_args.aaveInterestAmount),
          uint256(_args.rewardNullifier),
          uint256(_args.extDataHash),
          uint256(_args.account.inputRoot),
          uint256(_args.account.inputNullifierHash),
          uint256(_args.account.outputRoot),
          uint256(_args.account.outputPathIndices),
          uint256(_args.account.outputCommitment),
          uint256(_args.depositRoot),
          uint256(_args.withdrawalRoot)
        ]
      ),
      "Invalid reward proof"
    );

    accountNullifiers[_args.account.inputNullifierHash] = true;
    rewardNullifiers[_args.rewardNullifier] = true;
    insertAccountRoot(_args.account.inputRoot == getLastAccountRoot() ? _args.account.outputRoot : _treeUpdateArgs.newRoot);
    if (_args.fee > 0) {
      rewardSwap.swap(_args.extData.relayer, _args.fee);
    }

    delete totalShareSnapshots[_args.rewardNullifier];

    emit NewAccount(
      _args.account.outputCommitment,
      _args.account.inputNullifierHash,
      _args.extData.encryptedAccount,
      accountCount - 1
    );
  }

  function withdraw(bytes memory _proof, WithdrawArgs memory _args) public {
    withdraw(_proof, _args, new bytes(0), TreeUpdateArgs(0, 0, 0, 0));
  }

  function withdraw(
    bytes memory _proof,
    WithdrawArgs memory _args,
    bytes memory _treeUpdateProof,
    TreeUpdateArgs memory _treeUpdateArgs
  ) public nonReentrant {
    validateAccountUpdate(_args.account, _treeUpdateProof, _treeUpdateArgs);
    require(_args.extDataHash == keccak248(abi.encode(_args.extData)), "Incorrect external data hash");
    require(_args.apAmount < 2**248, "Amount value out of range");
    require(_args.aaveInterestAmount < 2**248, "AaveInterestAmount value out of range");
    require(
      withdrawVerifier.verifyProof(
        _proof,
        [
          uint256(_args.apAmount),
          uint256(_args.aaveInterestAmount),
          uint256(_args.extDataHash),
          uint256(_args.account.inputRoot),
          uint256(_args.account.inputNullifierHash),
          uint256(_args.account.outputRoot),
          uint256(_args.account.outputPathIndices),
          uint256(_args.account.outputCommitment)
        ]
      ),
      "Invalid withdrawal proof"
    );

    insertAccountRoot(_args.account.inputRoot == getLastAccountRoot() ? _args.account.outputRoot : _treeUpdateArgs.newRoot);
    accountNullifiers[_args.account.inputNullifierHash] = true;
    // allow submitting noop withdrawals (amount == 0)
    uint256 amount = _args.apAmount.sub(_args.extData.fee, "Amount should be greater than fee");
    if (amount > 0) {
      rewardSwap.swap(_args.extData.recipient, amount);
    }
    // Note. The relayer swap rate always will be worse than estimated
    if (_args.extData.fee > 0) {
      rewardSwap.swap(_args.extData.relayer, _args.extData.fee);
    }
    
    uint256 fee  = _args.aaveInterestAmount * aaveInterestFee / 10000;
    if(_args.aaveInterestAmount - fee > minimumInterests) {
      AaveInterestsProxy(aaveInterestsProxy).withdraw(_args.aaveInterestAmount - fee, _args.extData.recipient);
      if(fee > minimumInterests) {
        AaveInterestsProxy(aaveInterestsProxy).withdraw(fee, governance);
      }
    }

    emit NewAccount(
      _args.account.outputCommitment,
      _args.account.inputNullifierHash,
      _args.extData.encryptedAccount,
      accountCount - 1
    );
  }

  function setMinimumInterests(uint256 _minimumInterests) external onlyGovernance {
    require(_minimumInterests > 0, "miniumInterests has to be larger than zero");
    minimumInterests = _minimumInterests;
  }

  function setAaveInterestFee(uint256 _aaveInterestFee) external onlyGovernance {
    require(_aaveInterestFee <= 1000, "Aave Interest fee has to be smaller than 10%");
    aaveInterestFee = _aaveInterestFee;
  }

  function setRates(Rate[] memory _rates) external onlyGovernance {
    _setRates(_rates);
  }

  function setVerifiers(IVerifier[3] calldata _verifiers) external onlyGovernance {
    _setVerifiers(_verifiers);
  }

  function setSacredTreesContract(ISacredTrees _sacredTrees) external onlyGovernance {
    require(address(_sacredTrees) != address(0), "_sacredTrees cannot be zero address");
    sacredTrees = _sacredTrees;
  }

  function setPoolWeight(uint256 _newWeight) external onlyGovernance {
    rewardSwap.setPoolWeight(_newWeight);
  }

  function setAaveInterestsProxyContract(address _interestsProxy) external onlyGovernance {
    aaveInterestsProxy = _interestsProxy;
  }


  // ------VIEW-------

  /**
    @dev Whether the root is present in the root history
    */
  function isKnownAccountRoot(bytes32 _root, uint256 _index) public view returns (bool) {
    return _root != 0 && accountRoots[_index % ACCOUNT_ROOT_HISTORY_SIZE] == _root;
  }

  /**
    @dev Returns the last root
    */
  function getLastAccountRoot() public view returns (bytes32) {
    return accountRoots[accountCount % ACCOUNT_ROOT_HISTORY_SIZE];
  }

  // -----INTERNAL-------

  function keccak248(bytes memory _data) internal pure returns (bytes32) {
    return keccak256(_data) & 0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  }

  function validateTreeUpdate(
    bytes memory _proof,
    TreeUpdateArgs memory _args,
    bytes32 _commitment
  ) internal view {
    require(_proof.length > 0, "Outdated account merkle root");
    require(_args.oldRoot == getLastAccountRoot(), "Outdated tree update merkle root");
    require(_args.leaf == _commitment, "Incorrect commitment inserted");
    require(_args.pathIndices == accountCount, "Incorrect account insert index");
    require(
      treeUpdateVerifier.verifyProof(
        _proof,
        [uint256(_args.oldRoot), uint256(_args.newRoot), uint256(_args.leaf), uint256(_args.pathIndices)]
      ),
      "Invalid tree update proof"
    );
  }

  function validateAccountUpdate(
    AccountUpdate memory _account,
    bytes memory _treeUpdateProof,
    TreeUpdateArgs memory _treeUpdateArgs
  ) internal view {
    require(!accountNullifiers[_account.inputNullifierHash], "Outdated account state");
    if (_account.inputRoot != getLastAccountRoot()) {
      // _account.outputPathIndices (= last tree leaf index) is always equal to root index in the history mapping
      // because we always generate a new root for each new leaf
      require(isKnownAccountRoot(_account.inputRoot, _account.outputPathIndices), "Invalid account root");
      validateTreeUpdate(_treeUpdateProof, _treeUpdateArgs, _account.outputCommitment);
    } else {
      require(_account.outputPathIndices == accountCount, "Incorrect account insert index");
    }
  }

  function insertAccountRoot(bytes32 _root) internal {
    accountRoots[++accountCount % ACCOUNT_ROOT_HISTORY_SIZE] = _root;
  }

  function _setRates(Rate[] memory _rates) internal {
    instanceCount = _rates.length;
    for (uint256 i = 0; i < _rates.length; ++i) {
      require(_rates[i].value < 2**128, "Incorrect rate");
      address instance = _rates[i].instance;
      rates[instance] = _rates[i].value;
      instances[i] = instance;
      emit RateChanged(instance, _rates[i].value);
    }
  }

  function _setVerifiers(IVerifier[3] memory _verifiers) internal {
    require(address(_verifiers[0]) != address(0), "rewardVerifier cannot be zero address");
    require(address(_verifiers[1]) != address(0), "withdrawVerifier cannot be zero address");
    require(address(_verifiers[2]) != address(0), "treeUpdateVerifier cannot be zero address");
    rewardVerifier = _verifiers[0];
    withdrawVerifier = _verifiers[1];
    treeUpdateVerifier = _verifiers[2];
    emit VerifiersUpdated(address(_verifiers[0]), address(_verifiers[1]), address(_verifiers[2]));
  }

  function _updateShares() private {
    uint256 delta = block.number - shareTrack.lastUpdated;
    for(uint256 i = 0; i < instanceCount; ++i) {
      address instance = instances[i];
      shareTrack.totalShares += delta * activeDeposits[instance] * rates[instance];
    }
    shareTrack.lastUpdated = block.number;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IVerifier {
  function verifyProof(bytes calldata proof, uint256[4] calldata input) external view returns (bool);

  function verifyProof(bytes calldata proof, uint256[8] calldata input) external view returns (bool);

  function verifyProof(bytes calldata proof, uint256[14] calldata input) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IRewardSwap {
  function swap(address recipient, uint256 amount) external returns (uint256);

  function setPoolWeight(uint256 newWeight) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ISacredTrees {
  function registerDeposit(address instance, bytes32 commitment) external;
  function registerWithdrawal(address instance, bytes32 nullifier) external;
  function validateRoots(bytes32 _depositRoot, bytes32 _withdrawalRoot) external view;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}