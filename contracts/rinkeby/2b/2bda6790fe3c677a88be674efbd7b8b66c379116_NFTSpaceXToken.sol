// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20/ERC20Permit.sol";
import "./INFTSpaceXToken.sol";
import "../utils/EIP712.sol";
import "../utils/math/SafeCast.sol";
import "../access/NFTSpaceXAccessControls.sol";

contract NFTSpaceXToken is INFTSpaceXToken, ERC20Permit {
  struct Checkpoint {
    uint32 fromBlock;
    uint256 votes;
  }

  string public constant version = "1.0.0";
  uint256 public constant MAX_TOTAL_SUPPLY = 1e26;

  NFTSpaceXAccessControls public nftspacexAccessControls;

  mapping(address => address) internal _delegates;
  mapping(address => Checkpoint[]) private _checkpoints;
  Checkpoint[] private _totalSupplyCheckpoints;

  bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

  modifier onlyAdminOrTokenMinter() {
    require(nftspacexAccessControls.hasAdminRole(_msgSender()) ||
      nftspacexAccessControls.hasTokenMinterRole(_msgSender()),
      "NST: only admin or TMR"
    );
    _;
  }

  constructor(address _nftspacexAccessControls) ERC20Permit("NFTSpaceX Token", "NST", version) {
    nftspacexAccessControls = NFTSpaceXAccessControls(_nftspacexAccessControls);
  }

  function maxTotalSupply() public pure override returns (uint256) {
    return MAX_TOTAL_SUPPLY;
  }

  /**
    * @dev Comp version of the {getVotes} accessor, with `uint96` return type.
    */
  function getCurrentVotes(address account) external view virtual returns (uint96) {
    return SafeCast.toUint96(getVotes(account));
  }

  /**
    * @dev Comp version of the {getPastVotes} accessor, with `uint96` return type.
    */
  function getPriorVotes(address account, uint256 blockNumber) external view virtual returns (uint96) {
    return SafeCast.toUint96(getPastVotes(account, blockNumber));
  }

  /**
    * @dev Get number of checkpoints for `account`.
    */
  function numCheckpoints(address account) public view virtual returns (uint32) {
    return SafeCast.toUint32(_checkpoints[account].length);
  }

  /**
    * @dev Get the address `account` is currently delegating to.
    */
  function delegates(address account) public view virtual override returns (address) {
    return _delegates[account];
  }

  function getVotes(address account) public view virtual override returns (uint256) {
    uint256 pos = _checkpoints[account].length;
    return pos == 0 ? 0 : _checkpoints[account][pos - 1].votes;
  }

  /**
    * @dev Retrieve the number of votes for `account` at the end of `blockNumber`.
    *
    * Requirements:
    *
    * - `blockNumber` must have been already mined
    */
  function getPastVotes(address account, uint256 blockNumber) public view virtual override returns (uint256) {
    require(blockNumber < block.number, "ERC20Votes: block not yet mined");
    return _checkpointsLookup(_checkpoints[account], blockNumber);
  }

  /**
    * @dev Retrieve the `totalSupply` at the end of `blockNumber`. Note, this value is the sum of all balances.
    * It is but NOT the sum of all the delegated votes!
    *
    * Requirements:
    *
    * - `blockNumber` must have been already mined
    */
  function getPastTotalSupply(uint256 blockNumber) public view virtual override returns (uint256) {
    require(blockNumber < block.number, "ERC20Votes: block not yet mined");
    return _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
  }

  /**
    * @dev Lookup a value in a list of (sorted) checkpoints.
    */
  function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 blockNumber) private view returns (uint256) {
    // We run a binary search to look for the earliest checkpoint taken after `blockNumber`.
    //
    // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
    // With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
    // - If the middle checkpoint is after `blockNumber`, we look in [low, mid)
    // - If the middle checkpoint is before or equal to `blockNumber`, we look in [mid+1, high)
    // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
    // out of bounds (in which case we're looking too far in the past and the result is 0).
    // Note that if the latest checkpoint available is exactly for `blockNumber`, we end up with an index that is
    // past the end of the array, so we technically don't find a checkpoint after `blockNumber`, but it works out
    // the same.
    uint256 high = ckpts.length;
    uint256 low = 0;
    while (low < high) {
      uint256 mid = SafeMath.average(low, high);
      if (ckpts[mid].fromBlock > blockNumber) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }

    return high == 0 ? 0 : ckpts[high - 1].votes;
  }

  /**
    * @dev Delegate votes from the sender to `delegatee`.
    */
  function delegate(address delegatee) public virtual override {
    _delegate(_msgSender(), delegatee);
  }

  /**
    * @notice Delegates votes from signatory to `delegatee`
    * @param delegatee The address to delegate votes to
    * @param nonce The contract state required to match the signature
    * @param expiry The time at which to expire the signature
    * @param v The recovery byte of the signature
    * @param r Half of the ECDSA signature pair
    * @param s Half of the ECDSA signature pair
    */
  function delegateBySig(
    address delegatee,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public virtual override {
    require(expiry >= block.timestamp, "NST: signature expiry");
    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(abi.encodePacked(DELEGATION_TYPEHASH, delegatee, nonce, expiry))
      )
    );
    address recoveredAddress = ecrecover(digest, v, r, s);
    require(recoveredAddress != address(0), "NST: invalid signature");
    require(nonce == nonces[recoveredAddress]++, "NST: invalid nonce");
    _delegate(recoveredAddress, delegatee);
  }

  function mint(address account, uint256 amount) public override onlyAdminOrTokenMinter {
    _mint(account, amount);
  }

  /**
    * @dev Destroys `amount` tokens from the caller.
    *
    * See {ERC20-_burn}.
    */
  function burn(uint256 amount) public virtual override {
    _burn(_msgSender(), amount);
  }

  /**
    * @dev Destroys `amount` tokens from `account`, deducting from the caller's
    * allowance.
    *
    * See {ERC20-_burn} and {ERC20-allowance}.
    *
    * Requirements:
    *
    * - the caller must have allowance for ``accounts``'s tokens of at least
    * `amount`.
    */
  function burnFrom(address account, uint256 amount) public virtual override {
    _spendAllowance(account, _msgSender(), amount);
    _burn(account, amount);
  }

  /**
    * @dev Snapshots the totalSupply after it has been increased.
    */
  function _mint(address _account, uint256 _amount) internal virtual override {
    super._mint(_account, _amount);
    require(totalSupply() <= maxTotalSupply(), "NST: total supply risks overflowing votes");

    _writeCheckpoint(_totalSupplyCheckpoints, _add, _amount);
  }

  /**
    * @dev Snapshots the totalSupply after it has been decreased.
    */
  function _burn(address _account, uint256 _amount) internal virtual override {
    super._burn(_account, _amount);

    _writeCheckpoint(_totalSupplyCheckpoints, _subtract, _amount);
  }

  /**
    * @dev Move voting power when tokens are transferred.
    *
    * Emits a {DelegateVotesChanged} event.
    */
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    super._afterTokenTransfer(from, to, amount);

    _moveVotingPower(delegates(from), delegates(to), amount);
  }

  /**
    * @dev Change delegation for `delegator` to `delegatee`.
    *
    * Emits events {DelegateChanged} and {DelegateVotesChanged}.
    */
  function _delegate(address delegator, address delegatee) internal virtual {
    address currentDelegate = delegates(delegator);
    uint256 delegatorBalance = balanceOf(delegator);
    _delegates[delegator] = delegatee;

    emit DelegateChanged(delegator, currentDelegate, delegatee);

    _moveVotingPower(currentDelegate, delegatee, delegatorBalance);
  }

  function _moveVotingPower(
    address src,
    address dst,
    uint256 amount
  ) private {
    if (src != dst && amount > 0) {
      if (src != address(0)) {
        (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[src], _subtract, amount);
        emit DelegateVotesChanged(src, oldWeight, newWeight);
      }

      if (dst != address(0)) {
        (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[dst], _add, amount);
        emit DelegateVotesChanged(dst, oldWeight, newWeight);
      }
    }
  }

  function _writeCheckpoint(
    Checkpoint[] storage ckpts,
    function(uint256, uint256) view returns (uint256) op,
    uint256 delta
  ) private returns (uint256 oldWeight, uint256 newWeight) {
    uint256 pos = ckpts.length;
    oldWeight = pos == 0 ? 0 : ckpts[pos - 1].votes;
    newWeight = op(oldWeight, delta);

    if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
      ckpts[pos - 1].votes = SafeCast.toUint224(newWeight);
    } else {
      ckpts.push(Checkpoint({fromBlock: SafeCast.toUint32(block.number), votes: SafeCast.toUint224(newWeight)}));
    }
  }

  function _add(uint256 a, uint256 b) private pure returns (uint256) {
    return a + b;
  }

  function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
    return a - b;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "../../utils/math/SafeMath.sol";
import "../../utils/EIP712.sol";

abstract contract ERC20Permit is ERC20, EIP712 {
  using SafeMath for uint256;

  mapping(address => uint256) public nonces;

  bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

  constructor(string memory _name, string memory _symbol, string memory _version) ERC20(_name, _symbol) {
    uint256 chainId;
    assembly {
      chainId := chainid()
    }

    DOMAIN_SEPARATOR = hash(EIP712Domain({
      name: _name,
      version: _version,
      chainId: chainId,
      verifyingContract: address(this)
    }));
  }

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    require(expiry >= block.timestamp, "NST: expiry");
    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, expiry))
      )
    );
    address recoveredAddress = ecrecover(digest, v, r, s);
    require(recoveredAddress != address(0) && recoveredAddress == owner, "NST: invalid signature");
    _approve(owner, spender, value);
  }
}

// SPDX-License-Identifier: MIT

import "./ERC20/IERC20.sol";

pragma solidity ^0.8.0;

interface INFTSpaceXToken is IERC20 {
  event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
  event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);
  
  function maxTotalSupply() external view returns (uint256);
  function mint(address account, uint256 amount) external;
  function burn(uint256 amount) external;
  function burnFrom(address account, uint256 amount) external;
  function getVotes(address account) external view returns (uint256);
  function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);
  function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);
  function delegates(address account) external view returns (address);
  function delegate(address delegatee) external;
  function delegateBySig(
    address delegatee,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EIP712 {
  struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
  }

  bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
  );
  bytes32 public DOMAIN_SEPARATOR;

  function hash(EIP712Domain memory eip712Domain) internal pure returns (bytes32) {
    return keccak256(abi.encode(
      EIP712DOMAIN_TYPEHASH,
      keccak256(bytes(eip712Domain.name)),
      keccak256(bytes(eip712Domain.version)),
      eip712Domain.chainId,
      eip712Domain.verifyingContract
    ));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
  /**
    * @dev Returns the downcasted uint248 from uint256, reverting on
    * overflow (when the input is greater than largest uint248).
    *
    * Counterpart to Solidity's `uint248` operator.
    *
    * Requirements:
    *
    * - input must fit into 248 bits
    *
    * _Available since v4.7._
    */
  function toUint248(uint256 value) internal pure returns (uint248) {
    require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
    return uint248(value);
  }

  /**
    * @dev Returns the downcasted uint240 from uint256, reverting on
    * overflow (when the input is greater than largest uint240).
    *
    * Counterpart to Solidity's `uint240` operator.
    *
    * Requirements:
    *
    * - input must fit into 240 bits
    *
    * _Available since v4.7._
    */
  function toUint240(uint256 value) internal pure returns (uint240) {
    require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
    return uint240(value);
  }

  /**
    * @dev Returns the downcasted uint232 from uint256, reverting on
    * overflow (when the input is greater than largest uint232).
    *
    * Counterpart to Solidity's `uint232` operator.
    *
    * Requirements:
    *
    * - input must fit into 232 bits
    *
    * _Available since v4.7._
    */
  function toUint232(uint256 value) internal pure returns (uint232) {
    require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
    return uint232(value);
  }

  /**
    * @dev Returns the downcasted uint224 from uint256, reverting on
    * overflow (when the input is greater than largest uint224).
    *
    * Counterpart to Solidity's `uint224` operator.
    *
    * Requirements:
    *
    * - input must fit into 224 bits
    *
    * _Available since v4.2._
    */
  function toUint224(uint256 value) internal pure returns (uint224) {
    require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
    return uint224(value);
  }

  /**
    * @dev Returns the downcasted uint216 from uint256, reverting on
    * overflow (when the input is greater than largest uint216).
    *
    * Counterpart to Solidity's `uint216` operator.
    *
    * Requirements:
    *
    * - input must fit into 216 bits
    *
    * _Available since v4.7._
    */
  function toUint216(uint256 value) internal pure returns (uint216) {
    require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
    return uint216(value);
  }

  /**
    * @dev Returns the downcasted uint208 from uint256, reverting on
    * overflow (when the input is greater than largest uint208).
    *
    * Counterpart to Solidity's `uint208` operator.
    *
    * Requirements:
    *
    * - input must fit into 208 bits
    *
    * _Available since v4.7._
    */
  function toUint208(uint256 value) internal pure returns (uint208) {
    require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
    return uint208(value);
  }

  /**
    * @dev Returns the downcasted uint200 from uint256, reverting on
    * overflow (when the input is greater than largest uint200).
    *
    * Counterpart to Solidity's `uint200` operator.
    *
    * Requirements:
    *
    * - input must fit into 200 bits
    *
    * _Available since v4.7._
    */
  function toUint200(uint256 value) internal pure returns (uint200) {
    require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
    return uint200(value);
  }

  /**
    * @dev Returns the downcasted uint192 from uint256, reverting on
    * overflow (when the input is greater than largest uint192).
    *
    * Counterpart to Solidity's `uint192` operator.
    *
    * Requirements:
    *
    * - input must fit into 192 bits
    *
    * _Available since v4.7._
    */
  function toUint192(uint256 value) internal pure returns (uint192) {
    require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
    return uint192(value);
  }

  /**
    * @dev Returns the downcasted uint184 from uint256, reverting on
    * overflow (when the input is greater than largest uint184).
    *
    * Counterpart to Solidity's `uint184` operator.
    *
    * Requirements:
    *
    * - input must fit into 184 bits
    *
    * _Available since v4.7._
    */
  function toUint184(uint256 value) internal pure returns (uint184) {
    require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
    return uint184(value);
  }

  /**
    * @dev Returns the downcasted uint176 from uint256, reverting on
    * overflow (when the input is greater than largest uint176).
    *
    * Counterpart to Solidity's `uint176` operator.
    *
    * Requirements:
    *
    * - input must fit into 176 bits
    *
    * _Available since v4.7._
    */
  function toUint176(uint256 value) internal pure returns (uint176) {
    require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
    return uint176(value);
  }

  /**
    * @dev Returns the downcasted uint168 from uint256, reverting on
    * overflow (when the input is greater than largest uint168).
    *
    * Counterpart to Solidity's `uint168` operator.
    *
    * Requirements:
    *
    * - input must fit into 168 bits
    *
    * _Available since v4.7._
    */
  function toUint168(uint256 value) internal pure returns (uint168) {
    require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
    return uint168(value);
  }

  /**
    * @dev Returns the downcasted uint160 from uint256, reverting on
    * overflow (when the input is greater than largest uint160).
    *
    * Counterpart to Solidity's `uint160` operator.
    *
    * Requirements:
    *
    * - input must fit into 160 bits
    *
    * _Available since v4.7._
    */
  function toUint160(uint256 value) internal pure returns (uint160) {
    require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
    return uint160(value);
  }

  /**
    * @dev Returns the downcasted uint152 from uint256, reverting on
    * overflow (when the input is greater than largest uint152).
    *
    * Counterpart to Solidity's `uint152` operator.
    *
    * Requirements:
    *
    * - input must fit into 152 bits
    *
    * _Available since v4.7._
    */
  function toUint152(uint256 value) internal pure returns (uint152) {
    require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
    return uint152(value);
  }

  /**
    * @dev Returns the downcasted uint144 from uint256, reverting on
    * overflow (when the input is greater than largest uint144).
    *
    * Counterpart to Solidity's `uint144` operator.
    *
    * Requirements:
    *
    * - input must fit into 144 bits
    *
    * _Available since v4.7._
    */
  function toUint144(uint256 value) internal pure returns (uint144) {
    require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
    return uint144(value);
  }

  /**
    * @dev Returns the downcasted uint136 from uint256, reverting on
    * overflow (when the input is greater than largest uint136).
    *
    * Counterpart to Solidity's `uint136` operator.
    *
    * Requirements:
    *
    * - input must fit into 136 bits
    *
    * _Available since v4.7._
    */
  function toUint136(uint256 value) internal pure returns (uint136) {
    require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
    return uint136(value);
  }

  /**
    * @dev Returns the downcasted uint128 from uint256, reverting on
    * overflow (when the input is greater than largest uint128).
    *
    * Counterpart to Solidity's `uint128` operator.
    *
    * Requirements:
    *
    * - input must fit into 128 bits
    *
    * _Available since v2.5._
    */
  function toUint128(uint256 value) internal pure returns (uint128) {
    require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
    return uint128(value);
  }

  /**
    * @dev Returns the downcasted uint120 from uint256, reverting on
    * overflow (when the input is greater than largest uint120).
    *
    * Counterpart to Solidity's `uint120` operator.
    *
    * Requirements:
    *
    * - input must fit into 120 bits
    *
    * _Available since v4.7._
    */
  function toUint120(uint256 value) internal pure returns (uint120) {
    require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
    return uint120(value);
  }

  /**
    * @dev Returns the downcasted uint112 from uint256, reverting on
    * overflow (when the input is greater than largest uint112).
    *
    * Counterpart to Solidity's `uint112` operator.
    *
    * Requirements:
    *
    * - input must fit into 112 bits
    *
    * _Available since v4.7._
    */
  function toUint112(uint256 value) internal pure returns (uint112) {
    require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
    return uint112(value);
  }

  /**
    * @dev Returns the downcasted uint104 from uint256, reverting on
    * overflow (when the input is greater than largest uint104).
    *
    * Counterpart to Solidity's `uint104` operator.
    *
    * Requirements:
    *
    * - input must fit into 104 bits
    *
    * _Available since v4.7._
    */
  function toUint104(uint256 value) internal pure returns (uint104) {
    require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
    return uint104(value);
  }

  /**
    * @dev Returns the downcasted uint96 from uint256, reverting on
    * overflow (when the input is greater than largest uint96).
    *
    * Counterpart to Solidity's `uint96` operator.
    *
    * Requirements:
    *
    * - input must fit into 96 bits
    *
    * _Available since v4.2._
    */
  function toUint96(uint256 value) internal pure returns (uint96) {
    require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
    return uint96(value);
  }

  /**
    * @dev Returns the downcasted uint88 from uint256, reverting on
    * overflow (when the input is greater than largest uint88).
    *
    * Counterpart to Solidity's `uint88` operator.
    *
    * Requirements:
    *
    * - input must fit into 88 bits
    *
    * _Available since v4.7._
    */
  function toUint88(uint256 value) internal pure returns (uint88) {
    require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
    return uint88(value);
  }

  /**
    * @dev Returns the downcasted uint80 from uint256, reverting on
    * overflow (when the input is greater than largest uint80).
    *
    * Counterpart to Solidity's `uint80` operator.
    *
    * Requirements:
    *
    * - input must fit into 80 bits
    *
    * _Available since v4.7._
    */
  function toUint80(uint256 value) internal pure returns (uint80) {
    require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
    return uint80(value);
  }

  /**
    * @dev Returns the downcasted uint72 from uint256, reverting on
    * overflow (when the input is greater than largest uint72).
    *
    * Counterpart to Solidity's `uint72` operator.
    *
    * Requirements:
    *
    * - input must fit into 72 bits
    *
    * _Available since v4.7._
    */
  function toUint72(uint256 value) internal pure returns (uint72) {
    require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
    return uint72(value);
  }

  /**
    * @dev Returns the downcasted uint64 from uint256, reverting on
    * overflow (when the input is greater than largest uint64).
    *
    * Counterpart to Solidity's `uint64` operator.
    *
    * Requirements:
    *
    * - input must fit into 64 bits
    *
    * _Available since v2.5._
    */
  function toUint64(uint256 value) internal pure returns (uint64) {
    require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
    return uint64(value);
  }

  /**
    * @dev Returns the downcasted uint56 from uint256, reverting on
    * overflow (when the input is greater than largest uint56).
    *
    * Counterpart to Solidity's `uint56` operator.
    *
    * Requirements:
    *
    * - input must fit into 56 bits
    *
    * _Available since v4.7._
    */
  function toUint56(uint256 value) internal pure returns (uint56) {
    require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
    return uint56(value);
  }

  /**
    * @dev Returns the downcasted uint48 from uint256, reverting on
    * overflow (when the input is greater than largest uint48).
    *
    * Counterpart to Solidity's `uint48` operator.
    *
    * Requirements:
    *
    * - input must fit into 48 bits
    *
    * _Available since v4.7._
    */
  function toUint48(uint256 value) internal pure returns (uint48) {
    require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
    return uint48(value);
  }

  /**
    * @dev Returns the downcasted uint40 from uint256, reverting on
    * overflow (when the input is greater than largest uint40).
    *
    * Counterpart to Solidity's `uint40` operator.
    *
    * Requirements:
    *
    * - input must fit into 40 bits
    *
    * _Available since v4.7._
    */
  function toUint40(uint256 value) internal pure returns (uint40) {
    require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
    return uint40(value);
  }

  /**
    * @dev Returns the downcasted uint32 from uint256, reverting on
    * overflow (when the input is greater than largest uint32).
    *
    * Counterpart to Solidity's `uint32` operator.
    *
    * Requirements:
    *
    * - input must fit into 32 bits
    *
    * _Available since v2.5._
    */
  function toUint32(uint256 value) internal pure returns (uint32) {
    require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
    return uint32(value);
  }

  /**
    * @dev Returns the downcasted uint24 from uint256, reverting on
    * overflow (when the input is greater than largest uint24).
    *
    * Counterpart to Solidity's `uint24` operator.
    *
    * Requirements:
    *
    * - input must fit into 24 bits
    *
    * _Available since v4.7._
    */
  function toUint24(uint256 value) internal pure returns (uint24) {
    require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
    return uint24(value);
  }

  /**
    * @dev Returns the downcasted uint16 from uint256, reverting on
    * overflow (when the input is greater than largest uint16).
    *
    * Counterpart to Solidity's `uint16` operator.
    *
    * Requirements:
    *
    * - input must fit into 16 bits
    *
    * _Available since v2.5._
    */
  function toUint16(uint256 value) internal pure returns (uint16) {
    require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
    return uint16(value);
  }

  /**
    * @dev Returns the downcasted uint8 from uint256, reverting on
    * overflow (when the input is greater than largest uint8).
    *
    * Counterpart to Solidity's `uint8` operator.
    *
    * Requirements:
    *
    * - input must fit into 8 bits
    *
    * _Available since v2.5._
    */
  function toUint8(uint256 value) internal pure returns (uint8) {
    require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
    return uint8(value);
  }

  /**
    * @dev Converts a signed int256 into an unsigned uint256.
    *
    * Requirements:
    *
    * - input must be greater than or equal to 0.
    *
    * _Available since v3.0._
    */
  function toUint256(int256 value) internal pure returns (uint256) {
    require(value >= 0, "SafeCast: value must be positive");
    return uint256(value);
  }

  /**
    * @dev Returns the downcasted int248 from int256, reverting on
    * overflow (when the input is less than smallest int248 or
    * greater than largest int248).
    *
    * Counterpart to Solidity's `int248` operator.
    *
    * Requirements:
    *
    * - input must fit into 248 bits
    *
    * _Available since v4.7._
    */
  function toInt248(int256 value) internal pure returns (int248) {
    require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
    return int248(value);
  }

  /**
    * @dev Returns the downcasted int240 from int256, reverting on
    * overflow (when the input is less than smallest int240 or
    * greater than largest int240).
    *
    * Counterpart to Solidity's `int240` operator.
    *
    * Requirements:
    *
    * - input must fit into 240 bits
    *
    * _Available since v4.7._
    */
  function toInt240(int256 value) internal pure returns (int240) {
    require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
    return int240(value);
  }

  /**
    * @dev Returns the downcasted int232 from int256, reverting on
    * overflow (when the input is less than smallest int232 or
    * greater than largest int232).
    *
    * Counterpart to Solidity's `int232` operator.
    *
    * Requirements:
    *
    * - input must fit into 232 bits
    *
    * _Available since v4.7._
    */
  function toInt232(int256 value) internal pure returns (int232) {
    require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
    return int232(value);
  }

  /**
    * @dev Returns the downcasted int224 from int256, reverting on
    * overflow (when the input is less than smallest int224 or
    * greater than largest int224).
    *
    * Counterpart to Solidity's `int224` operator.
    *
    * Requirements:
    *
    * - input must fit into 224 bits
    *
    * _Available since v4.7._
    */
  function toInt224(int256 value) internal pure returns (int224) {
    require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
    return int224(value);
  }

  /**
    * @dev Returns the downcasted int216 from int256, reverting on
    * overflow (when the input is less than smallest int216 or
    * greater than largest int216).
    *
    * Counterpart to Solidity's `int216` operator.
    *
    * Requirements:
    *
    * - input must fit into 216 bits
    *
    * _Available since v4.7._
    */
  function toInt216(int256 value) internal pure returns (int216) {
    require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
    return int216(value);
  }

  /**
    * @dev Returns the downcasted int208 from int256, reverting on
    * overflow (when the input is less than smallest int208 or
    * greater than largest int208).
    *
    * Counterpart to Solidity's `int208` operator.
    *
    * Requirements:
    *
    * - input must fit into 208 bits
    *
    * _Available since v4.7._
    */
  function toInt208(int256 value) internal pure returns (int208) {
    require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
    return int208(value);
  }

  /**
    * @dev Returns the downcasted int200 from int256, reverting on
    * overflow (when the input is less than smallest int200 or
    * greater than largest int200).
    *
    * Counterpart to Solidity's `int200` operator.
    *
    * Requirements:
    *
    * - input must fit into 200 bits
    *
    * _Available since v4.7._
    */
  function toInt200(int256 value) internal pure returns (int200) {
    require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
    return int200(value);
  }

  /**
    * @dev Returns the downcasted int192 from int256, reverting on
    * overflow (when the input is less than smallest int192 or
    * greater than largest int192).
    *
    * Counterpart to Solidity's `int192` operator.
    *
    * Requirements:
    *
    * - input must fit into 192 bits
    *
    * _Available since v4.7._
    */
  function toInt192(int256 value) internal pure returns (int192) {
    require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
    return int192(value);
  }

  /**
    * @dev Returns the downcasted int184 from int256, reverting on
    * overflow (when the input is less than smallest int184 or
    * greater than largest int184).
    *
    * Counterpart to Solidity's `int184` operator.
    *
    * Requirements:
    *
    * - input must fit into 184 bits
    *
    * _Available since v4.7._
    */
  function toInt184(int256 value) internal pure returns (int184) {
    require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
    return int184(value);
  }

  /**
    * @dev Returns the downcasted int176 from int256, reverting on
    * overflow (when the input is less than smallest int176 or
    * greater than largest int176).
    *
    * Counterpart to Solidity's `int176` operator.
    *
    * Requirements:
    *
    * - input must fit into 176 bits
    *
    * _Available since v4.7._
    */
  function toInt176(int256 value) internal pure returns (int176) {
    require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
    return int176(value);
  }

  /**
    * @dev Returns the downcasted int168 from int256, reverting on
    * overflow (when the input is less than smallest int168 or
    * greater than largest int168).
    *
    * Counterpart to Solidity's `int168` operator.
    *
    * Requirements:
    *
    * - input must fit into 168 bits
    *
    * _Available since v4.7._
    */
  function toInt168(int256 value) internal pure returns (int168) {
    require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
    return int168(value);
  }

  /**
    * @dev Returns the downcasted int160 from int256, reverting on
    * overflow (when the input is less than smallest int160 or
    * greater than largest int160).
    *
    * Counterpart to Solidity's `int160` operator.
    *
    * Requirements:
    *
    * - input must fit into 160 bits
    *
    * _Available since v4.7._
    */
  function toInt160(int256 value) internal pure returns (int160) {
    require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
    return int160(value);
  }

  /**
    * @dev Returns the downcasted int152 from int256, reverting on
    * overflow (when the input is less than smallest int152 or
    * greater than largest int152).
    *
    * Counterpart to Solidity's `int152` operator.
    *
    * Requirements:
    *
    * - input must fit into 152 bits
    *
    * _Available since v4.7._
    */
  function toInt152(int256 value) internal pure returns (int152) {
    require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
    return int152(value);
  }

  /**
    * @dev Returns the downcasted int144 from int256, reverting on
    * overflow (when the input is less than smallest int144 or
    * greater than largest int144).
    *
    * Counterpart to Solidity's `int144` operator.
    *
    * Requirements:
    *
    * - input must fit into 144 bits
    *
    * _Available since v4.7._
    */
  function toInt144(int256 value) internal pure returns (int144) {
    require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
    return int144(value);
  }

  /**
    * @dev Returns the downcasted int136 from int256, reverting on
    * overflow (when the input is less than smallest int136 or
    * greater than largest int136).
    *
    * Counterpart to Solidity's `int136` operator.
    *
    * Requirements:
    *
    * - input must fit into 136 bits
    *
    * _Available since v4.7._
    */
  function toInt136(int256 value) internal pure returns (int136) {
    require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
    return int136(value);
  }

  /**
    * @dev Returns the downcasted int128 from int256, reverting on
    * overflow (when the input is less than smallest int128 or
    * greater than largest int128).
    *
    * Counterpart to Solidity's `int128` operator.
    *
    * Requirements:
    *
    * - input must fit into 128 bits
    *
    * _Available since v3.1._
    */
  function toInt128(int256 value) internal pure returns (int128) {
    require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
    return int128(value);
  }

  /**
    * @dev Returns the downcasted int120 from int256, reverting on
    * overflow (when the input is less than smallest int120 or
    * greater than largest int120).
    *
    * Counterpart to Solidity's `int120` operator.
    *
    * Requirements:
    *
    * - input must fit into 120 bits
    *
    * _Available since v4.7._
    */
  function toInt120(int256 value) internal pure returns (int120) {
    require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
    return int120(value);
  }

  /**
    * @dev Returns the downcasted int112 from int256, reverting on
    * overflow (when the input is less than smallest int112 or
    * greater than largest int112).
    *
    * Counterpart to Solidity's `int112` operator.
    *
    * Requirements:
    *
    * - input must fit into 112 bits
    *
    * _Available since v4.7._
    */
  function toInt112(int256 value) internal pure returns (int112) {
    require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
    return int112(value);
  }

  /**
    * @dev Returns the downcasted int104 from int256, reverting on
    * overflow (when the input is less than smallest int104 or
    * greater than largest int104).
    *
    * Counterpart to Solidity's `int104` operator.
    *
    * Requirements:
    *
    * - input must fit into 104 bits
    *
    * _Available since v4.7._
    */
  function toInt104(int256 value) internal pure returns (int104) {
    require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
    return int104(value);
  }

  /**
    * @dev Returns the downcasted int96 from int256, reverting on
    * overflow (when the input is less than smallest int96 or
    * greater than largest int96).
    *
    * Counterpart to Solidity's `int96` operator.
    *
    * Requirements:
    *
    * - input must fit into 96 bits
    *
    * _Available since v4.7._
    */
  function toInt96(int256 value) internal pure returns (int96) {
    require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
    return int96(value);
  }

  /**
    * @dev Returns the downcasted int88 from int256, reverting on
    * overflow (when the input is less than smallest int88 or
    * greater than largest int88).
    *
    * Counterpart to Solidity's `int88` operator.
    *
    * Requirements:
    *
    * - input must fit into 88 bits
    *
    * _Available since v4.7._
    */
  function toInt88(int256 value) internal pure returns (int88) {
    require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
    return int88(value);
  }

  /**
    * @dev Returns the downcasted int80 from int256, reverting on
    * overflow (when the input is less than smallest int80 or
    * greater than largest int80).
    *
    * Counterpart to Solidity's `int80` operator.
    *
    * Requirements:
    *
    * - input must fit into 80 bits
    *
    * _Available since v4.7._
    */
  function toInt80(int256 value) internal pure returns (int80) {
    require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
    return int80(value);
  }

  /**
    * @dev Returns the downcasted int72 from int256, reverting on
    * overflow (when the input is less than smallest int72 or
    * greater than largest int72).
    *
    * Counterpart to Solidity's `int72` operator.
    *
    * Requirements:
    *
    * - input must fit into 72 bits
    *
    * _Available since v4.7._
    */
  function toInt72(int256 value) internal pure returns (int72) {
    require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
    return int72(value);
  }

  /**
    * @dev Returns the downcasted int64 from int256, reverting on
    * overflow (when the input is less than smallest int64 or
    * greater than largest int64).
    *
    * Counterpart to Solidity's `int64` operator.
    *
    * Requirements:
    *
    * - input must fit into 64 bits
    *
    * _Available since v3.1._
    */
  function toInt64(int256 value) internal pure returns (int64) {
    require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
    return int64(value);
  }

  /**
    * @dev Returns the downcasted int56 from int256, reverting on
    * overflow (when the input is less than smallest int56 or
    * greater than largest int56).
    *
    * Counterpart to Solidity's `int56` operator.
    *
    * Requirements:
    *
    * - input must fit into 56 bits
    *
    * _Available since v4.7._
    */
  function toInt56(int256 value) internal pure returns (int56) {
    require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
    return int56(value);
  }

  /**
    * @dev Returns the downcasted int48 from int256, reverting on
    * overflow (when the input is less than smallest int48 or
    * greater than largest int48).
    *
    * Counterpart to Solidity's `int48` operator.
    *
    * Requirements:
    *
    * - input must fit into 48 bits
    *
    * _Available since v4.7._
    */
  function toInt48(int256 value) internal pure returns (int48) {
    require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
    return int48(value);
  }

  /**
    * @dev Returns the downcasted int40 from int256, reverting on
    * overflow (when the input is less than smallest int40 or
    * greater than largest int40).
    *
    * Counterpart to Solidity's `int40` operator.
    *
    * Requirements:
    *
    * - input must fit into 40 bits
    *
    * _Available since v4.7._
    */
  function toInt40(int256 value) internal pure returns (int40) {
    require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
    return int40(value);
  }

  /**
    * @dev Returns the downcasted int32 from int256, reverting on
    * overflow (when the input is less than smallest int32 or
    * greater than largest int32).
    *
    * Counterpart to Solidity's `int32` operator.
    *
    * Requirements:
    *
    * - input must fit into 32 bits
    *
    * _Available since v3.1._
    */
  function toInt32(int256 value) internal pure returns (int32) {
    require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
    return int32(value);
  }

  /**
    * @dev Returns the downcasted int24 from int256, reverting on
    * overflow (when the input is less than smallest int24 or
    * greater than largest int24).
    *
    * Counterpart to Solidity's `int24` operator.
    *
    * Requirements:
    *
    * - input must fit into 24 bits
    *
    * _Available since v4.7._
    */
  function toInt24(int256 value) internal pure returns (int24) {
    require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
    return int24(value);
  }

  /**
    * @dev Returns the downcasted int16 from int256, reverting on
    * overflow (when the input is less than smallest int16 or
    * greater than largest int16).
    *
    * Counterpart to Solidity's `int16` operator.
    *
    * Requirements:
    *
    * - input must fit into 16 bits
    *
    * _Available since v3.1._
    */
  function toInt16(int256 value) internal pure returns (int16) {
    require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
    return int16(value);
  }

  /**
    * @dev Returns the downcasted int8 from int256, reverting on
    * overflow (when the input is less than smallest int8 or
    * greater than largest int8).
    *
    * Counterpart to Solidity's `int8` operator.
    *
    * Requirements:
    *
    * - input must fit into 8 bits
    *
    * _Available since v3.1._
    */
  function toInt8(int256 value) internal pure returns (int8) {
    require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
    return int8(value);
  }

  /**
    * @dev Converts an unsigned uint256 into a signed int256.
    *
    * Requirements:
    *
    * - input must be less than or equal to maxInt256.
    *
    * _Available since v3.0._
    */
  function toInt256(uint256 value) internal pure returns (int256) {
    // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
    require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
    return int256(value);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./NFTSpaceXAdminAccess.sol";

contract NFTSpaceXAccessControls is NFTSpaceXAdminAccess {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant TOKEN_MINTER_ROLE = keccak256("TOKEN_MINTER_ROLE");
  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  event MinterRoleGranted(address indexed beneficiary, address indexed caller);
  event MinterRoleRemoved(address indexed beneficiary, address indexed caller);
  event OperatorRoleGranted(address indexed beneficiary, address indexed caller);
  event OperatorRoleRemoved(address indexed beneficiary, address indexed caller);
  event SmartContractRoleGranted(address indexed beneficiary, address indexed caller);
  event SmartContractRoleRemoved(address indexed beneficiary, address indexed caller);

  function hasMinterRole(address _address) public view returns (bool) {
    return hasRole(MINTER_ROLE, _address);
  }

  function hasTokenMinterRole(address _address) public view returns (bool) {
    return hasRole(TOKEN_MINTER_ROLE, _address);
  }

  function hasOperatorRole(address _address) public view returns (bool) {
    return hasRole(OPERATOR_ROLE, _address);
  }

  function addMinterRole(address _beneficiary) external {
    grantRole(MINTER_ROLE, _beneficiary);
    emit MinterRoleGranted(_beneficiary, _msgSender());
  }

  function removeMinterRole(address _beneficiary) external {
    revokeRole(MINTER_ROLE, _beneficiary);
    emit MinterRoleRemoved(_beneficiary, _msgSender());
  }

  function addTokenMinterRole(address _beneficiary) external {
    grantRole(TOKEN_MINTER_ROLE, _beneficiary);
    emit SmartContractRoleGranted(_beneficiary, _msgSender());
  }

  function addOperatorRole(address _beneficiary) external {
    grantRole(OPERATOR_ROLE, _beneficiary);
    emit OperatorRoleGranted(_beneficiary, _msgSender());
  }

  function removeOperatorRole(address _beneficiary) external {
    revokeRole(OPERATOR_ROLE, _beneficiary);
    emit OperatorRoleRemoved(_beneficiary, _msgSender());
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "../../utils/Context.sol";

contract ERC20 is Context, IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }    

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */

    // solhint-disable no-empty-blocks
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControl.sol";

contract NFTSpaceXAdminAccess is AccessControl {
  bool private initAccess;

  event AdminRoleGranted(address indexed beneficiary, address indexed caller);
  event AdminRoleRemoved(address indexed beneficiary, address indexed caller);

  function initAccessControls(address _admin) public {
    require(!initAccess, "NSA: Already initialised");
    require(_admin != address(0), "NSA: zero address");
    _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    initAccess = true;
  }

  function hasAdminRole(address _address) public view returns (bool) {
    return hasRole(DEFAULT_ADMIN_ROLE, _address);
  }

  function addAdminRole(address _beneficiary) external {
    grantRole(DEFAULT_ADMIN_ROLE, _beneficiary);
    emit AdminRoleGranted(_beneficiary, _msgSender());
  }

  function removeAdminRole(address _beneficiary) external {
    revokeRole(DEFAULT_ADMIN_ROLE, _beneficiary);
    emit AdminRoleRemoved(_beneficiary, _msgSender());
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/libraries/EnumerableSet.sol";
import "../utils/introspection/ERC165.sol";
import "../interfaces/IAccessControl.sol";

abstract contract AccessControl is Context, IAccessControl, ERC165 {
  using EnumerableSet for EnumerableSet.AddressSet;

  struct RoleData {
    EnumerableSet.AddressSet members;
    bytes32 adminRole;
  }

  mapping(bytes32 => RoleData) private _roles;
  bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
  }

  function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
    return _roles[role].members.contains(account);
  }

  function getRoleMemberCount(bytes32 role) public view returns (uint256) {
    return _roles[role].members.length();
  }

  function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
    return _roles[role].members.at(index);
  }

  function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
    return _roles[role].adminRole;
  }

  function grantRole(bytes32 role, address account) public virtual override {
    require(hasRole(_roles[role].adminRole, _msgSender()), "AC: must be an admin");
    _grantRole(role, account);
  }

  function revokeRole(bytes32 role, address account) public virtual override {
    require(hasRole(_roles[role].adminRole, _msgSender()), "AC: must be an admin");
    _revokeRole(role, account);
  }

  function renounceRole(bytes32 role, address account) public virtual override {
    require(account == _msgSender(), "AC: must renounce yourself");
    _revokeRole(role, account);
  }

  function _setupRole(bytes32 role, address account) internal virtual {
    _grantRole(role, account);
  }

  function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
    emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
    _roles[role].adminRole = adminRole;
  }

  function _grantRole(bytes32 role, address account) private {
    if (_roles[role].members.add(account)) {
      emit RoleGranted(role, account, _msgSender());
    }
  }

  function _revokeRole(bytes32 role, address account) private {
    if (_roles[role].members.remove(account)) {
      emit RoleRevoked(role, account, _msgSender());
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library EnumerableSet {
  struct Set {
    bytes32[] _values;
    mapping (bytes32 => uint256) _indexes;
  }

  /**
    * @dev Add a value to a set. O(1).
    *
    * Returns true if the value was added to the set, that is if it was not
    * already present.
    */
  function _add(Set storage set, bytes32 value) private returns (bool) {
    if (!_contains(set, value)) {
      set._values.push(value);
      // The value is stored at length-1, but we add 1 to all indexes
      // and use 0 as a sentinel value
      set._indexes[value] = set._values.length;
      return true;
    } else {
      return false;
    }
  }

  /**
    * @dev Removes a value from a set. O(1).
    *
    * Returns true if the value was removed from the set, that is if it was
    * present.
    */
  function _remove(Set storage set, bytes32 value) private returns (bool) {
    // We read and store the value's index to prevent multiple reads from the same storage slot
    uint256 valueIndex = set._indexes[value];

    if (valueIndex != 0) { // Equivalent to contains(set, value)
      // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
      // the array, and then remove the last element (sometimes called as 'swap and pop').
      // This modifies the order of the array, as noted in {at}.

      uint256 toDeleteIndex = valueIndex - 1;
      uint256 lastIndex = set._values.length - 1;

      // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
      // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

      bytes32 lastvalue = set._values[lastIndex];

      // Move the last value to the index where the value to delete is
      set._values[toDeleteIndex] = lastvalue;
      // Update the index for the moved value
      set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

      // Delete the slot where the moved value was stored
      set._values.pop();

      // Delete the index for the deleted slot
      delete set._indexes[value];

      return true;
    } else {
      return false;
    }
  }

  /**
    * @dev Returns true if the value is in the set. O(1).
    */
  function _contains(Set storage set, bytes32 value) private view returns (bool) {
    return set._indexes[value] != 0;
  }

  /**
    * @dev Returns the number of values on the set. O(1).
    */
  function _length(Set storage set) private view returns (uint256) {
    return set._values.length;
  }

  /**
  * @dev Returns the value stored at position `index` in the set. O(1).
  *
  * Note that there are no guarantees on the ordering of values inside the
  * array, and it may change when more values are added or removed.
  *
  * Requirements:
  *
  * - `index` must be strictly less than {length}.
  */
  function _at(Set storage set, uint256 index) private view returns (bytes32) {
    require(set._values.length > index, "EnumerableSet: index out of bounds");
    return set._values[index];
  }

  // Bytes32Set

  struct Bytes32Set {
    Set _inner;
  }

  /**
    * @dev Add a value to a set. O(1).
    *
    * Returns true if the value was added to the set, that is if it was not
    * already present.
    */
  function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
    return _add(set._inner, value);
  }

  /**
    * @dev Removes a value from a set. O(1).
    *
    * Returns true if the value was removed from the set, that is if it was
    * present.
    */
  function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
    return _remove(set._inner, value);
  }

  /**
    * @dev Returns true if the value is in the set. O(1).
    */
  function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
    return _contains(set._inner, value);
  }

  /**
    * @dev Returns the number of values in the set. O(1).
    */
  function length(Bytes32Set storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  /**
  * @dev Returns the value stored at position `index` in the set. O(1).
  *
  * Note that there are no guarantees on the ordering of values inside the
  * array, and it may change when more values are added or removed.
  *
  * Requirements:
  *
  * - `index` must be strictly less than {length}.
  */
  function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
    return _at(set._inner, index);
  }

  // AddressSet

  struct AddressSet {
    Set _inner;
  }

  /**
    * @dev Add a value to a set. O(1).
    *
    * Returns true if the value was added to the set, that is if it was not
    * already present.
    */
  function add(AddressSet storage set, address value) internal returns (bool) {
    return _add(set._inner, bytes32(uint256(uint160(value))));
  }

  /**
    * @dev Removes a value from a set. O(1).
    *
    * Returns true if the value was removed from the set, that is if it was
    * present.
    */
  function remove(AddressSet storage set, address value) internal returns (bool) {
    return _remove(set._inner, bytes32(uint256(uint160(value))));
  }

  /**
    * @dev Returns true if the value is in the set. O(1).
    */
  function contains(AddressSet storage set, address value) internal view returns (bool) {
    return _contains(set._inner, bytes32(uint256(uint160(value))));
  }

  /**
    * @dev Returns the number of values in the set. O(1).
    */
  function length(AddressSet storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  /**
  * @dev Returns the value stored at position `index` in the set. O(1).
  *
  * Note that there are no guarantees on the ordering of values inside the
  * array, and it may change when more values are added or removed.
  *
  * Requirements:
  *
  * - `index` must be strictly less than {length}.
  */
  function at(AddressSet storage set, uint256 index) internal view returns (address) {
      return address(uint160(uint256(_at(set._inner, index))));
  }


  // UintSet

  struct UintSet {
    Set _inner;
  }

  /**
    * @dev Add a value to a set. O(1).
    *
    * Returns true if the value was added to the set, that is if it was not
    * already present.
    */
  function add(UintSet storage set, uint256 value) internal returns (bool) {
    return _add(set._inner, bytes32(value));
  }

  /**
    * @dev Removes a value from a set. O(1).
    *
    * Returns true if the value was removed from the set, that is if it was
    * present.
    */
  function remove(UintSet storage set, uint256 value) internal returns (bool) {
    return _remove(set._inner, bytes32(value));
  }

  /**
    * @dev Returns true if the value is in the set. O(1).
    */
  function contains(UintSet storage set, uint256 value) internal view returns (bool) {
    return _contains(set._inner, bytes32(value));
  }

  /**
    * @dev Returns the number of values on the set. O(1).
    */
  function length(UintSet storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  /**
  * @dev Returns the value stored at position `index` in the set. O(1).
  *
  * Note that there are no guarantees on the ordering of values inside the
  * array, and it may change when more values are added or removed.
  *
  * Requirements:
  *
  * - `index` must be strictly less than {length}.
  */
  function at(UintSet storage set, uint256 index) internal view returns (uint256) {
    return uint256(_at(set._inner, index));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAccessControl {
  /**
    * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
    *
    * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
    * {RoleAdminChanged} not being emitted signaling this.
    */
  event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

  /**
    * @dev Emitted when `account` is granted `role`.
    *
    * `sender` is the account that originated the contract call, an admin role
    * bearer except when using {AccessControl-_setupRole}.
    */
  event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

  /**
    * @dev Emitted when `account` is revoked `role`.
    *
    * `sender` is the account that originated the contract call:
    *   - if using `revokeRole`, it is the admin role bearer
    *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
    */
  event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

  /**
    * @dev Returns `true` if `account` has been granted `role`.
    */
  function hasRole(bytes32 role, address account) external view returns (bool);

  /**
    * @dev Returns the admin role that controls `role`. See {grantRole} and
    * {revokeRole}.
    *
    * To change a role's admin, use {AccessControl-_setRoleAdmin}.
    */
  function getRoleAdmin(bytes32 role) external view returns (bytes32);

  /**
    * @dev Grants `role` to `account`.
    *
    * If `account` had not been already granted `role`, emits a {RoleGranted}
    * event.
    *
    * Requirements:
    *
    * - the caller must have ``role``'s admin role.
    */
  function grantRole(bytes32 role, address account) external;

  /**
    * @dev Revokes `role` from `account`.
    *
    * If `account` had been granted `role`, emits a {RoleRevoked} event.
    *
    * Requirements:
    *
    * - the caller must have ``role``'s admin role.
    */
  function revokeRole(bytes32 role, address account) external;

  /**
    * @dev Revokes `role` from the calling account.
    *
    * Roles are often managed via {grantRole} and {revokeRole}: this function's
    * purpose is to provide a mechanism for accounts to lose their privileges
    * if they are compromised (such as when a trusted device is misplaced).
    *
    * If the calling account had been granted `role`, emits a {RoleRevoked}
    * event.
    *
    * Requirements:
    *
    * - the caller must be `account`.
    */
  function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

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