/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: MIT                                                                               
                                                    
pragma solidity 0.8.13;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library EnumerableSet {

    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];
                set._values[toDeleteIndex] = lastValue;
                set._indexes[lastValue] = valueIndex;
            }

            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }


    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

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

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

contract ERC20 is Context, IERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _createInitialSupply(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

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
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountToken, uint amountETH);

}

interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IDexPair {

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface DividendPayingTokenOptionalInterface {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}

interface DividendPayingTokenInterface {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) external view returns(uint256);

  /// @notice Distributes ether to token holders as dividends.
  /// @dev SHOULD distribute the paid ether to token holders as dividends.
  ///  SHOULD NOT directly transfer ether to token holders in this function.
  ///  MUST emit a `DividendsDistributed` event when the amount of distributed ether is greater than 0.
  function distributeDividends() external payable;

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev SHOULD transfer `dividendOf(msg.sender)` wei to `msg.sender`, and `dividendOf(msg.sender)` SHOULD be 0 after the transfer.
  ///  MUST emit a `DividendWithdrawn` event if the amount of ether transferred is greater than 0.
  function withdrawDividend() external;

  /// @dev This event MUST emit when ether is distributed to token holders.
  /// @param from The address which sends ether to this contract.
  /// @param weiAmount The amount of distributed ether in wei.
  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount
  );

  /// @dev This event MUST emit when an address withdraws their dividend.
  /// @param to The address which withdraws ether from this contract.
  /// @param weiAmount The amount of withdrawn ether in wei.
  event DividendWithdrawn(
    address indexed to,
    uint256 weiAmount
  );
}

contract DividendPayingToken is DividendPayingTokenInterface, DividendPayingTokenOptionalInterface, Ownable {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
  // For more discussion about choosing the value of `magnitude`,
  //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;
  
  // About dividendCorrection:
  // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
  // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
  //   `dividendOf(_user)` should not be changed,
  //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
  // To keep the `dividendOf(_user)` unchanged, we add a correction term:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
  //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
  //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
  // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  mapping(address => uint256) public holderPendingRewards;
  mapping(address => uint256) public holderRewardsUnlockTime;
  uint256 public vestingTime = 3 days;
  mapping(address => uint256) public holderRevokedRewards;
  mapping(address => uint256) public holderRevokedRewardsOffset;
  
  mapping (address => uint256) public holderBalance;
  uint256 public totalBalance;

  uint256 public totalDividendsDistributed;

  /// @dev Distributes dividends whenever ether is paid to this contract.
  receive() external payable {
    distributeDividends();
  }

  /// @notice Distributes ether to token holders as dividends.
  /// @dev It reverts if the total supply of tokens is 0.
  /// It emits the `DividendsDistributed` event if the amount of received ether is greater than 0.
  /// About undistributed ether:
  ///   In each distribution, there is a small amount of ether not distributed,
  ///     the magnified amount of which is
  ///     `(msg.value * magnitude) % totalSupply()`.
  ///   With a well-chosen `magnitude`, the amount of undistributed ether
  ///     (de-magnified) in a distribution can be less than 1 wei.
  ///   We can actually keep track of the undistributed ether in a distribution
  ///     and try to distribute it in the next distribution,
  ///     but keeping track of such data on-chain costs much more than
  ///     the saved ether, so we don't do that.
    
  function distributeDividends() public override payable { 
      if(totalBalance > 0){
        if (msg.value > 0) {
          magnifiedDividendPerShare = magnifiedDividendPerShare.add(
            (msg.value).mul(magnitude) / totalBalance
          );
          emit DividendsDistributed(msg.sender, msg.value);
    
          totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
        }
      }
  }

  function updateVestingTime(uint256 timeInHours) external onlyOwner {
      require(timeInHours * 1 hours <= 5 days, "Cannot set vesting period longer than 5 days");
      vestingTime = timeInHours * 1 hours;
  }
  
  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function withdrawDividend() external virtual override {
    _withdrawDividendOfUser(payable(msg.sender));
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      emit DividendWithdrawn(user, _withdrawableDividend);
      (bool success,) = user.call{value: _withdrawableDividend+holderPendingRewards[user], gas: 3000}("");

      if(!success) {
        withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
        return 0;
      }

      return _withdrawableDividend;
    }

    return 0;
  }

  function _shiftDividendOfUser(address payable user) internal {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      holderPendingRewards[user] += _withdrawableDividend;
    }
  }


  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) external view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) external view override returns(uint256) {
    return withdrawnDividends[_owner];
  }


  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    return magnifiedDividendPerShare.mul(holderBalance[_owner]).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }

  /// @dev Internal function that increases tokens to an account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account that will receive the created tokens.
  /// @param value The amount that will be created.
  function _increase(address account, uint256 value) internal {
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  /// @dev Internal function that reduces an amount of the token of a given account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account whose tokens will be burnt.
  /// @param value The amount that will be burnt.
  function _reduce(address account, uint256 value) internal {
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = holderBalance[account];
    holderBalance[account] = newBalance;
    if(newBalance > currentBalance) {
      uint256 increaseAmount = newBalance.sub(currentBalance);
      _increase(account, increaseAmount);
      totalBalance += increaseAmount;
    } else if(newBalance < currentBalance) {
      uint256 reduceAmount = currentBalance.sub(newBalance);
      _reduce(account, reduceAmount);
      totalBalance -= reduceAmount;
    }
  }

  function setHolderRewardsUnlockTime(address account, uint256 newTime) external onlyOwner {
      holderRewardsUnlockTime[account] = newTime;
  }

  
}

contract DividendTracker is DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    mapping (address => uint256) public holderRewardsRevoked;

    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(address key) private view returns (uint) {
        return tokenHoldersMap.values[key];
    }

    function getIndexOfKey(address key) private view returns (int) {
        if(!tokenHoldersMap.inserted[key]) {
            return -1;
        }
        return int(tokenHoldersMap.indexOf[key]);
    }

    function getKeyAtIndex(uint index) private view returns (address) {
        return tokenHoldersMap.keys[index];
    }



    function size() private view returns (uint) {
        return tokenHoldersMap.keys.length;
    }

    function set(address key, uint val) private {
        if (tokenHoldersMap.inserted[key]) {
            tokenHoldersMap.values[key] = val;
        } else {
            tokenHoldersMap.inserted[key] = true;
            tokenHoldersMap.values[key] = val;
            tokenHoldersMap.indexOf[key] = tokenHoldersMap.keys.length;
            tokenHoldersMap.keys.push(key);
        }
    }

    function remove(address key) private {
        if (!tokenHoldersMap.inserted[key]) {
            return;
        }

        delete tokenHoldersMap.inserted[key];
        delete tokenHoldersMap.values[key];

        uint index = tokenHoldersMap.indexOf[key];
        uint lastIndex = tokenHoldersMap.keys.length - 1;
        address lastKey = tokenHoldersMap.keys[lastIndex];

        tokenHoldersMap.indexOf[lastKey] = index;
        delete tokenHoldersMap.indexOf[key];

        tokenHoldersMap.keys[index] = lastKey;
        tokenHoldersMap.keys.pop();
    }

    Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public immutable minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event IncludeInDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() {
    	claimWait = 1200;
        minimumTokenBalanceForDividends = 1000 * (1e18);
    }

    function excludeFromDividends(address account) external onlyOwner {
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	remove(account);

    	emit ExcludeFromDividends(account);
    }
    
    function includeInDividends(address account) external onlyOwner {
    	require(excludedFromDividends[account]);
    	excludedFromDividends[account] = false;

    	emit IncludeInDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 1200 && newClaimWait <= 86400, "Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable,
            uint256 revokedRewards,
            uint256 holderRewardsUnlock) {
        account = _account;

        index = getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;


                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }


        withdrawableDividends = withdrawableDividendOf(account)+holderPendingRewards[account];
        totalDividends = accumulativeDividendOf(account) - holderRevokedRewardsOffset[_account];

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime.add(claimWait) :
                                    0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
        
        revokedRewards = holderRevokedRewards[account];
        holderRewardsUnlock = holderRewardsUnlockTime[account];
    }

    function getAccountAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	if(index >= size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0, 0, 0);
        }

        address account = getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}

    	return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    	if(excludedFromDividends[account]) {
    		return;
    	}

    	if(newBalance >= minimumTokenBalanceForDividends){
            _setBalance(account, newBalance);
    		set(account, newBalance);
    	}
    	else {
            _setBalance(account, 0);
    		remove(account);
    	}

    	processAccount(account, true);
    }
    
    function processAccount(address payable account, bool automatic) public onlyOwner {
        if(holderRewardsUnlockTime[account] > block.timestamp){
            _shiftDividendOfUser(account);
        } else {
            uint256 amount = _withdrawDividendOfUser(account);
            if(amount > 0) {
                lastClaimTimes[account] = block.timestamp;
                emit Claim(account, amount, automatic);
            }
        }
    }

    function revokeRewards(address account) external onlyOwner {
        uint256 rewardsToRevoke = withdrawableDividendOf(account)+holderPendingRewards[account];
        if(rewardsToRevoke > 0){
            holderPendingRewards[account] = 0;
            holderRevokedRewards[account] += rewardsToRevoke;
            holderRevokedRewardsOffset[account] += rewardsToRevoke;
            withdrawnDividends[account] = withdrawnDividends[account].add(withdrawableDividendOf(account));
            
            bool success;
            (success,) = address(this).call{value: rewardsToRevoke}("");
            
            totalDividendsDistributed -= rewardsToRevoke;
            holderRevokedRewards[account] -= withdrawableDividendOf(account);
        }
    }
}

contract Mizbeah is ERC20, Ownable {

    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxWalletAmount;

    uint256 public buyMultiplier = 0;
    uint256 public sellMultiplier = 20;

    EnumerableSet.AddressSet private buyerList;
    uint256 public nextLotteryTime;
    uint256 public timeBetweenLotteries = 24 hours;
    uint256 public minBuyAmount = .1 ether;
    bool public minBuyEnforced = true;
    uint256 public percentForLottery = 50;
    bool public lotteryEnabled = false;

    uint256 public lastBurnTimestamp;

    DividendTracker public immutable dividendTracker;

    IDexRouter public dexRouter;
    address public lpPair;

    bool private swapping;
    uint256 public swapTokensAtAmount;

    address operationsAddress;

    uint256 public tradingActiveBlock = 0; // 0 means trading is not active
    uint256 public blockForPenaltyEnd;
    mapping (address => bool) public restrictedWallet;
    uint256 public botsCaught;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;
    
     // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;

    uint256 public buyTotalFees;
    uint256 public buyOperationsFee;
    uint256 public buyLiquidityFee;
    uint256 public buyRewardsFee;
    uint256 public buyLotteryFee;

    uint256 public sellTotalFees;
    uint256 public sellOperationsFee;
    uint256 public sellLiquidityFee;
    uint256 public sellRewardsFee;
    uint256 public sellLotteryFee;

    uint256 public tokensForOperations;
    uint256 public tokensForLiquidity;
    uint256 public tokensForRewards;
    uint256 public tokensForLottery;

    uint256 public FEE_DENOMINATOR = 10000;
    
    /******************/

    // exlcude from fees and max transaction amount
    mapping (address => bool) public _isExcludedFromFees;
    mapping (address => bool) public _isExcludedMaxTransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event EnabledTrading();

    event RemovedLimits();

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event UpdatedMaxBuyAmount(uint256 newAmount);

    event UpdatedMaxSellAmount(uint256 newAmount);

    event UpdatedMaxWalletAmount(uint256 newAmount);

    event UpdatedOperationsAddress(address indexed newWallet);

    event MaxTransactionExclusion(address _address, bool excluded);

    event BuyBackTriggered(uint256 amount);

    event OwnerForcedSwapBack(uint256 timestamp);

    event CaughtBot(address sniper);

    event TransferForeignToken(address token, uint256 amount);

    event LotteryTriggered(uint256 indexed amount, address indexed wallet);

    constructor() ERC20("Mizbeah", "Seh") {
        
        address newOwner = 0x5B4828b9984DB461607073Ec5935138AB619F87F;

        dividendTracker = new DividendTracker();

        IDexRouter _dexRouter = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        dexRouter = _dexRouter;

        operationsAddress = address(0x5B4828b9984DB461607073Ec5935138AB619F87F); // for prod

        // create pair
        lpPair = IDexFactory(_dexRouter.factory()).createPair(address(this), _dexRouter.WETH());
        _excludeFromMaxTransaction(address(lpPair), true);
        _setAutomatedMarketMakerPair(address(lpPair), true);

        uint256 totalSupply = 1 * 1e9 * 1e18;

        uint256 mockSupply = 888 * 1e6 * 1e18;
        
        maxBuyAmount = mockSupply * 2 / 1000;
        maxSellAmount = mockSupply * 2 / 1000;
        maxWalletAmount = mockSupply * 2 / 100;
        swapTokensAtAmount = mockSupply * 25 / 100000;

        buyOperationsFee = 200;
        buyLiquidityFee = 400;
        buyRewardsFee = 400;
        buyLotteryFee = 0;
        buyTotalFees = buyOperationsFee + buyLiquidityFee + buyRewardsFee + buyLotteryFee;

        sellOperationsFee = 200;
        sellLiquidityFee = 400;
        sellRewardsFee = 400;
        sellLotteryFee = 0;
        sellTotalFees = sellOperationsFee + sellLiquidityFee + sellRewardsFee + sellLotteryFee;

        _excludeFromMaxTransaction(newOwner, true);
        _excludeFromMaxTransaction(msg.sender, true);
        _excludeFromMaxTransaction(operationsAddress, true);
        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(address(0xdead), true);
        _excludeFromMaxTransaction(address(dexRouter), true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(msg.sender);
        dividendTracker.excludeFromDividends(address(dexRouter));
        dividendTracker.excludeFromDividends(address(0xdead));

        excludeFromFees(newOwner, true);
        excludeFromFees(msg.sender, true);
        excludeFromFees(operationsAddress, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(address(dexRouter), true);

        _createInitialSupply(newOwner, mockSupply*35/100);
        _createInitialSupply(msg.sender, mockSupply*20/100);
        _createInitialSupply(address(0xdead), mockSupply*45/100 + (totalSupply - mockSupply));
    }

    receive() external payable {}

    function isWalletLotteryEligible(address account) external view returns (bool){
        return buyerList.contains(account);
    }
    
    function enableTrading(uint256 blocksForPenalty) external onlyOwner {
        require(blockForPenaltyEnd == 0);
        tradingActive = true;
        swapEnabled = true;
        tradingActiveBlock = block.number;
        blockForPenaltyEnd = tradingActiveBlock + blocksForPenalty;
        nextLotteryTime = block.timestamp + timeBetweenLotteries;
        emit EnabledTrading();
    }
    
    // remove limits after token is stable
    function removeLimits() external onlyOwner {
        limitsInEffect = false;
        transferDelayEnabled = false;
        emit RemovedLimits();
    }

    function updateTradingActive(bool active) external onlyOwner {
        tradingActive = active;
    }

    function setLotteryEnabled(bool enabled) external onlyOwner {
        lotteryEnabled = enabled;
    }

    function setBuyMultiplier(uint256 multiplier) external onlyOwner {
        require(multiplier <=20);
        buyMultiplier = multiplier;
    }

    function setSellMultiplier(uint256 multiplier) external onlyOwner {
        require(multiplier <=20);
        sellMultiplier = multiplier;
    }

    function manageRestrictedWallets(address[] calldata wallets, bool restricted) external onlyOwner {
        for(uint256 i = 0; i < wallets.length; i++){
            restrictedWallet[wallets[i]] = restricted;
            if(restricted){
                dividendTracker.revokeRewards(wallets[i]);
                dividendTracker.excludeFromDividends(wallets[i]);
            } else {
                dividendTracker.includeInDividends(wallets[i]);
            }
        }
    }
    
    // disable Transfer delay
    function disableTransferDelay() external onlyOwner {
        transferDelayEnabled = false;
    }

    function enableTransferDelay() external onlyOwner {
        transferDelayEnabled = true;
    }

    function calculatePriceImpact(uint256 value) public view returns (uint256) {
        value = value * 998 / 1000;

        IDexPair pair = IDexPair((address(lpPair)));

        (uint256 r0, uint256 r1,) = pair.getReserves();

        IERC20 token0 = IERC20(pair.token0());
        IERC20 token1 = IERC20(pair.token1());

        if(address(token1) == address(this)) {
            IERC20 tokenTemp = token0;
            token0 = token1;
            token1 = tokenTemp;

            uint256 rTemp = r0;
            r0 = r1;
            r1 = rTemp;
        }

        uint256 product = r0 * r1;

        uint256 r0After = r0 + value;
        uint256 r1After = product / r0After;

        return (10000 - (r1After * 10000 / r1)) * 998 / 1000;
    }
    
    function updateMaxBuyAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 2 / 1000) / 1e18);
        maxBuyAmount = newNum * (1e18);
        emit UpdatedMaxBuyAmount(maxBuyAmount);
    }
    
    function updateMaxSellAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 2 / 1000) / 1e18);
        maxSellAmount = newNum * (1e18);
        emit UpdatedMaxSellAmount(maxSellAmount);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 3 / 1000) / 1e18);
        maxWalletAmount = newNum * (1e18);
        emit UpdatedMaxWalletAmount(maxWalletAmount);
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
  	    require(newAmount >= totalSupply() * 1 / 100000);
  	    require(newAmount <= totalSupply() * 1 / 1000);
  	    swapTokensAtAmount = newAmount;
  	}
    
    function _excludeFromMaxTransaction(address updAds, bool isExcluded) private {
        _isExcludedMaxTransactionAmount[updAds] = isExcluded;
        emit MaxTransactionExclusion(updAds, isExcluded);
    }

    function airdropToWallets(address[] memory wallets, uint256[] memory amountsInTokens) external onlyOwner {
        require(wallets.length == amountsInTokens.length, "arrays must be the same length");
        require(wallets.length < 200); // allows for airdrop + launch at the same exact time, reducing delays and reducing sniper input.
        for(uint256 i = 0; i < wallets.length; i++){
            super._transfer(msg.sender, wallets[i], amountsInTokens[i]);
            dividendTracker.setBalance(payable(wallets[i]), balanceOf(wallets[i]));
            dividendTracker.setHolderRewardsUnlockTime(payable(wallets[i]), dividendTracker.vestingTime() + block.timestamp);
        }
    }
    
    function excludeFromMaxTransaction(address updAds, bool isEx) external onlyOwner {
        if(!isEx){
            require(updAds != lpPair, "Cannot remove uniswap pair from max txn");
        }
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != lpPair, "The pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        
        _excludeFromMaxTransaction(pair, value);

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateBuyFees(uint256 _operationsFee, uint256 _liquidityFee, uint256 _rewardsFee, uint256 _lotteryFee) external onlyOwner {
        buyOperationsFee = _operationsFee;
        buyLiquidityFee = _liquidityFee;
        buyRewardsFee = _rewardsFee;
        buyLotteryFee = _lotteryFee;
        buyTotalFees = buyOperationsFee + buyLiquidityFee + buyRewardsFee + buyLotteryFee;
        require(buyTotalFees <= 1500, "Must keep fees at 15% or less");
    }

    function updateSellFees(uint256 _operationsFee, uint256 _liquidityFee, uint256 _rewardsFee, uint256 _lotteryFee) external onlyOwner {
        sellOperationsFee = _operationsFee;
        sellLiquidityFee = _liquidityFee;
        sellRewardsFee = _rewardsFee;
        sellLotteryFee = _lotteryFee;
        sellTotalFees = sellOperationsFee + sellLiquidityFee + sellRewardsFee + sellLotteryFee;
        require(sellTotalFees <= 2000, "Must keep fees at 20% or less");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function _transfer(address from, address to, uint256 amount) internal override {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer must be greater than 0");
        
        if(!tradingActive){
            require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
        }

        if(!earlyBuyPenaltyInEffect() && blockForPenaltyEnd > 0){
            require(!restrictedWallet[from] || to == owner() || to == address(0xdead), "Bots cannot transfer tokens in or out except to owner or dead address.");
        }
        
        if(limitsInEffect){
            if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]){
                
                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.  
                if (transferDelayEnabled){
                    if (to != address(dexRouter) && to != address(lpPair)){
                        require(_holderLastTransferTimestamp[tx.origin] < block.number - 2 && _holderLastTransferTimestamp[to] < block.number - 2);
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                        _holderLastTransferTimestamp[to] = block.number;
                    }
                }
                 
                //when buy
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                        require(amount <= maxBuyAmount);
                        require(amount + balanceOf(to) <= maxWalletAmount);
                } 
                //when sell
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                        require(amount <= maxSellAmount);
                } 
                else if (!_isExcludedMaxTransactionAmount[to]){
                    require(amount + balanceOf(to) <= maxWalletAmount);
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(canSwap && swapEnabled && !swapping && !automatedMarketMakerPairs[from] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        if(lotteryEnabled){
            if(block.timestamp >= nextLotteryTime && address(this).balance > 0.1 ether && buyerList.length() > 1){
                payoutRewards(to);
            }
            else {
                gasBurn();
            }
        }

        bool takeFee = true;
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        
        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if(takeFee){
            // bot/sniper penalty.
            if((earlyBuyPenaltyInEffect() || (amount >= maxBuyAmount - .9 ether && blockForPenaltyEnd + 5 >= block.number)) && automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to] && buyTotalFees > 0){
                
                if(!earlyBuyPenaltyInEffect()){
                    // reduce by 1 wei per max buy over what Uniswap will allow to revert bots as best as possible to limit erroneously blacklisted wallets. First bot will get in and be blacklisted, rest will be reverted (*cross fingers*)
                    maxBuyAmount -= 1;
                }

                if(!restrictedWallet[to]){
                    restrictedWallet[to] = true;
                    botsCaught += 1;
                    emit CaughtBot(to);
                }

                fees = amount * (buyTotalFees) / FEE_DENOMINATOR;
        	    tokensForLiquidity += fees * buyLiquidityFee / buyTotalFees;
                tokensForOperations += fees * buyOperationsFee / buyTotalFees;
                tokensForRewards += fees * buyRewardsFee / buyTotalFees;
                tokensForLottery += fees * buyLotteryFee / buyTotalFees;
                dividendTracker.excludeFromDividends(to);
            }

            // on sell
            else if (automatedMarketMakerPairs[to] && sellTotalFees > 0){
                uint256 increasedSellTax = calculatePriceImpact(amount)*sellMultiplier;
                if(sellTotalFees + increasedSellTax >= 3000){
                    increasedSellTax = 3000 - sellTotalFees;
                }
                fees = amount * (sellTotalFees + increasedSellTax) / FEE_DENOMINATOR;
                tokensForLiquidity += fees * sellLiquidityFee / sellTotalFees;
                tokensForOperations += fees * sellOperationsFee / sellTotalFees;
                tokensForRewards += fees * sellRewardsFee / sellTotalFees;
                tokensForLottery += fees * sellLotteryFee / sellTotalFees;
                dividendTracker.setHolderRewardsUnlockTime(from, dividendTracker.vestingTime() + block.timestamp);
            }

            // on buy
            else if(automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                uint256 reducedBuyTax = calculatePriceImpact(amount)*buyMultiplier;
                if(buyTotalFees < reducedBuyTax){
                    reducedBuyTax = buyTotalFees;
                }
        	    fees = amount * (buyTotalFees - reducedBuyTax) / FEE_DENOMINATOR;
        	    tokensForLiquidity += fees * buyLiquidityFee / buyTotalFees;
                tokensForOperations += fees * buyOperationsFee / buyTotalFees;
                tokensForRewards += fees * buyRewardsFee / buyTotalFees;
                tokensForLottery += fees * buyLotteryFee / buyTotalFees;
                if(!minBuyEnforced || amount > getPurchaseAmount()){
                    if(!buyerList.contains(to)){
                        buyerList.add(to);
                    }
                }
            }
            
            if(fees > 0){    
                super._transfer(from, address(this), fees);
            }
        	
        	amount -= fees;
        }

        if(dividendTracker.holderRewardsUnlockTime(to) == 0){
            dividendTracker.setHolderRewardsUnlockTime(to, dividendTracker.vestingTime() + block.timestamp);
        }

        super._transfer(from, to, amount);

        dividendTracker.setBalance(payable(from), balanceOf(from));
        dividendTracker.setBalance(payable(to), balanceOf(to));

        if(dividendTracker.holderRewardsUnlockTime(from) > block.timestamp && takeFee){
            dividendTracker.revokeRewards(from);
        }

        if(buyerList.contains(from) && takeFee){
            buyerList.remove(from);
        }

    }

    function earlyBuyPenaltyInEffect() public view returns (bool){
        return block.number < blockForPenaltyEnd;
    }

    // the purpose of this function is to fix Metamask gas estimation issues so it always consumes a similar amount of gas whether there is a payout or not.
    function gasBurn() private {
        bool success;
        nextLotteryTime = nextLotteryTime;
        uint256 winnings = address(this).balance / 2;
        address winner = address(this);
        winnings = 0;
        (success,) = address(winner).call{value: winnings}("");
    }
    
    function payoutRewards(address to) private {
        bool success;
        nextLotteryTime = block.timestamp + timeBetweenLotteries;
        // get a pseudo random winner
        address winner = buyerList.at(random(0, buyerList.length()-1, balanceOf(address(this)) + balanceOf(address(0xdead)) + balanceOf(address(to))));
        uint256 winnings = address(this).balance * percentForLottery / 100;
        (success,) = address(winner).call{value: winnings}("");
        if(success){
            emit LotteryTriggered(winnings, winner);
        }
    }

    function random(uint256 from, uint256 to, uint256 salty) private view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp + block.difficulty +
                    ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
                    block.gaslimit +
                    ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
                    block.number +
                    salty
                )
            )
        );
        return seed % (to - from) + from;
    }

    function getPurchaseAmount() public view returns (uint256){
        address[] memory path = new address[](2);
        path[0] = dexRouter.WETH();
        path[1] = address(this);
        
        uint256[] memory amounts = new uint256[](2);
        amounts = dexRouter.getAmountsOut(minBuyAmount, path);
        return amounts[1];
    }

    function updateLotteryTimeCooldown(uint256 timeInHours) external onlyOwner {
        require(timeInHours >= 1 && timeInHours <= 24);
        timeBetweenLotteries = timeInHours * 1 hours;
    }

    function updatePercentForLottery(uint256 percent) external onlyOwner {
        require(percent >= 1 && percent <= 100);
        percentForLottery = percent;
    }

    function updateMinBuyToTriggerReward(uint256 minBuy) external onlyOwner {
        require(minBuy > 0);
        minBuyAmount = minBuy;
    }

    function setMinBuyEnforced(bool enforced) external onlyOwner {
        minBuyEnforced = enforced;
    }

    function updateVestingTime(uint256 timeInHours) external onlyOwner {
        dividendTracker.updateVestingTime(timeInHours);
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        _approve(address(this), address(dexRouter), tokenAmount);

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(dexRouter), tokenAmount);

        // add the liquidity
        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    function splitAndBurnLiquidity(uint256 percent) external onlyOwner {
        require(percent <=20);
        require(lastBurnTimestamp <= block.timestamp - 1 hours);
        lastBurnTimestamp = block.timestamp;
        uint256 lpBalance = IERC20(lpPair).balanceOf(address(this));
        uint256 tokenBalance = balanceOf(address(this));
        uint256 lpAmount = lpBalance * percent / 100;
        uint256 initialEthBalance = address(this).balance;

        // approve token transfer to cover all possible scenarios
        IERC20(lpPair).approve(address(dexRouter), lpAmount);

        // remove the liquidity
        dexRouter.removeLiquidityETH(
            address(this),
            lpAmount,
            1, // slippage is unavoidable
            1, // slippage is unavoidable
            address(this),
            block.timestamp
        );

        uint256 deltaTokenBalance = balanceOf(address(this)) - tokenBalance;
        if(deltaTokenBalance > 0){
            super._transfer(address(this), address(0xdead), deltaTokenBalance);
        }

        uint256 deltaEthBalance = address(this).balance - initialEthBalance;

        if(deltaEthBalance > 0){
            buyBackTokens(deltaEthBalance);
        }
    }

    function buyBackTokens(uint256 amountInWei) internal {
        address[] memory path = new address[](2);
        path[0] = dexRouter.WETH();
        path[1] = address(this);

        dexRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountInWei}(
            0,
            path,
            address(0xdead),
            block.timestamp
        );
    }

    function swapBack() private {

        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForOperations + tokensForRewards + tokensForLottery;
        
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance > swapTokensAtAmount * 10){
            contractBalance = swapTokensAtAmount * 10;
        }

        bool success;
        
        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap / 2;
        
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(contractBalance - liquidityTokens);
        
        uint256 ethBalance = address(this).balance - initialBalance;
        uint256 ethForLiquidity = ethBalance;

        uint256 ethForOperations = ethBalance * tokensForOperations / (totalTokensToSwap - (tokensForLiquidity/2));
        uint256 ethForRewards = ethBalance * tokensForRewards / (totalTokensToSwap - (tokensForLiquidity/2));
        uint256 ethForLottery = ethBalance * tokensForLottery / (totalTokensToSwap - (tokensForLiquidity/2));

        ethForLiquidity -= ethForOperations + ethForRewards + ethForLottery;
            
        tokensForLiquidity = 0;
        tokensForOperations = 0;
        tokensForRewards = 0;
        tokensForLottery = 0;
        
        if(liquidityTokens > 0 && ethForLiquidity > 0){
            addLiquidity(liquidityTokens, ethForLiquidity);
        }

        if(ethForOperations > 0){
            (success,) = address(operationsAddress).call{value: ethForOperations}("");
        }
        if(ethForRewards > 0){
            (success,) = address(dividendTracker).call{value: ethForRewards}("");
        }
        // remaining tokens stay for Lottery
    }

    function transferForeignToken(address _token, address _to) external onlyOwner returns (bool _sent) {
        require(_token != address(0));
        require(_token != address(this));
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
        emit TransferForeignToken(_token, _contractBalance);
    }

    // withdraw ETH if stuck
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(owner()).call{value: address(this).balance}("");
    }

    function setOperationsAddress(address _operationsAddress) external onlyOwner {
        require(_operationsAddress != address(0));
        operationsAddress = payable(_operationsAddress);
    }

    // force Swap back if slippage issues.
    function forceSwapBack() external onlyOwner {
        require(balanceOf(address(this)) >= swapTokensAtAmount, "Can only swap when token amount is at or higher than restriction");
        swapping = true;
        swapBack();
        swapping = false;
        emit OwnerForcedSwapBack(block.timestamp);
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function withdrawableDividendOf(address account) external view returns(uint256) {
    	return dividendTracker.withdrawableDividendOf(account) + dividendTracker.holderPendingRewards(account);
  	}

    function holderRewardsUnlockTime(address account) external view returns(uint256) {
    	return dividendTracker.holderRewardsUnlockTime(account);
  	}

	function dividendTokenBalanceOf(address account) external view returns (uint256) {
		return dividendTracker.holderBalance(account);
	}

    function getAccountDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256, 
            uint256) {
        return dividendTracker.getAccount(account);
    }

	function getAccountDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return dividendTracker.getAccountAtIndex(index);
    }

    function claim() external {
		dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }
    
    function getNumberOfDividends() external view returns(uint256) {
        return dividendTracker.totalBalance();
    }

    // excludes wallets and contracts from dividends (such as CEX hotwallets, etc.)
    function excludeFromDividends(address account) external onlyOwner {
        dividendTracker.excludeFromDividends(account);
    }

    // removes exclusion on wallets and contracts from dividends (such as CEX hotwallets, etc.)
    function includeInDividends(address account) external onlyOwner {
        dividendTracker.includeInDividends(account);
    }
}