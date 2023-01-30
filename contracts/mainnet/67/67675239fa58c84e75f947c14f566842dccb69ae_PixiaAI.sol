/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

// SPDX-License-Identifier: MIT


/*
 * █▀█ █ ▀▄▀ █ ▄▀█   ▄▀█ █
 * █▀▀ █ █░█ █ █▀█   █▀█ █
 *
 * https://Pixia.Ai
 * https://t.me/PixiaAi
 * https://twitter.com/PixiaAi
*/


pragma solidity 0.8.17;

interface IUniswapV2Router01 {

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
    returns (uint[] memory amounts);
    
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
    returns (uint[] memory amounts);
    
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
    returns (uint[] memory amounts);
    
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


interface IUniswapV2Router02 is IUniswapV2Router01 {

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) internal view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) internal view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) internal view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) internal view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) internal {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) internal {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}


/// @title Dividend-Paying Token Optional Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev OPTIONAL functions for a dividend-paying token contract.
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


/// @title Dividend-Paying Token Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev An interface for a dividend-paying token contract.
interface DividendPayingTokenInterface {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) external view returns(uint256);


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


library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        
        require(b != -1 || a != MIN_INT256);

        
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


library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}


library SafeMath {
  
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
          
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

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


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}


contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    // The name function returns the name of the token.
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    // The symbol function returns the symbol of the token.
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    // The decimals function returns the number of decimal places used by the token.
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    // The totalSupply function returns the total supply of tokens in the contract.
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    // The balanceOf function returns the balance of tokens for an address.
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    // The transfer function transfers tokens to a recipient.
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    // The allowance function returns the allowance of a spender to spend tokens on behalf of an owner.
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    // The approve function approves an address to spend a certain amount of tokens.
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    // The transferFrom function transfers a certain amount of tokens from one address to another, then updates the allowance.
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

    // The increaseAllowance function increases the allowance of a spender.
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    // The decreaseAllowance function decrease the allowance of a spender.
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    // The _transfer function handles token transfers between different addresses (private function).
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

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

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

    // The _approve function updates the allowance of a spender for an owner and emits an Approval event (private function).
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


/// @title Dividend-Paying Token
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev A mintable ERC20 token that allows anyone to pay and distribute ether
///  to token holders as dividends and allows token holders to withdraw their dividends.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
contract DividendPayingToken is ERC20, Ownable, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  address public immutable  partnerToken; 


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

  uint256 public totalDividendsDistributed;

  constructor (string memory _name, string memory _symbol, address _rewardToken) ERC20(_name, _symbol) {
         partnerToken = _rewardToken;
  }


  function distributepartnerDividends(uint256 amount) public onlyOwner{
    require(totalSupply() > 0);

    if (amount > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (amount).mul(magnitude) / totalSupply()
      );
      emit DividendsDistributed(msg.sender, amount);

      totalDividendsDistributed = totalDividendsDistributed.add(amount);
    }
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function withdrawDividend() public virtual override {
    _withdrawDividendOfUser(payable(msg.sender));
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      emit DividendWithdrawn(user, _withdrawableDividend);
      bool success = IERC20(partnerToken).transfer(user, _withdrawableDividend);

      if(!success) {
        withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
        return 0;
      }

      return _withdrawableDividend;
    }

    return 0;
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) public view override returns(uint256) {
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
  function withdrawnDividendOf(address _owner) public view override returns(uint256) {
    return withdrawnDividends[_owner];
  }

  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }

  /// @dev Internal function that transfer tokens from one address to another.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param from The address to transfer from.
  /// @param to The address to transfer to.
  /// @param value The amount to be transferred.
  function _transfer(address from, address to, uint256 value) internal virtual override {
    require(false);

    int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
    magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
    magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
  }

  /// @dev Internal function that mints tokens to an account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account that will receive the created tokens.
  /// @param value The amount that will be created.
  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  /// @dev Internal function that burns an amount of the token of a given account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account whose tokens will be burnt.
  /// @param value The amount that will be burnt.
  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);

    if(newBalance > currentBalance) {
      uint256 mintAmount = newBalance.sub(currentBalance);
      _mint(account, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burn(account, burnAmount);
    }
  }
}


// File: contracts/PixiaAI.sol

contract PixiaAI is ERC20, Ownable {
    using SafeMath for uint256;

     struct BuyFee {
        uint16 staking;
        uint16 burn;
        uint16 autoLP;
        uint16 dev;
        uint16 treasury;
        uint16 partner;
        uint16 integration;
    }

    struct SellFee {
        uint16 staking;
        uint16 burn;
        uint16 autoLP;
        uint16 dev;
        uint16 treasury;
        uint16 partner;
        uint16 integration;
    }


    BuyFee public buyFee;
    SellFee public sellFee;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private swapping;
    bool public isLaunched;

    uint16 private totalBuyFee;
    uint16 private totalSellFee;
    uint256 public launchTime;

    TOKENDividendTracker public dividendTracker;

    address public intergrationToken = address (0x000000000000000000000000000000000000dEaD); // Integration token smart contract
    address public partnerToken = address(0x000000000000000000000000000000000000dEaD); // Partner token smart contract (autoDistributed to holders)
    
    address public devWallet =address(0xdDf3e4D035a75d3a5bB11F9CaD79fa555D3aa957); // Dev wallet 
    address public integrationWallet = address(0x000000000000000000000000000000000000dEaD); // Intergation wallet
    address public stakingWallet = address(0x000000000000000000000000000000000000dEaD); // Staking wallet
    address public treasuryWallet = address (0x306968Ccc755Eb0984F57A5729d28346aadb8db7); // TreasuryWallet
    address public constant burnWallet = address(0x000000000000000000000000000000000000dEaD); // Burn wallet

    uint256 public swapTokensAtAmount = 1 * 1e4 * 1e18; // 10000 tokens min for swap
    uint256 public maxTxAmount;
    uint256 public maxWallet;


    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedFromMaxTx;
    mapping(address => bool) public _isExcludedFromMaxWallet;
   

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);
    
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event GasForProcessingUpdated(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );

    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    event SendDividends( uint256 amount);


    constructor() ERC20("PixiaAI", "PIXIA") {
        dividendTracker = new TOKENDividendTracker(partnerToken);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D //Uniswap V2 router
        );
        // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;


        //buyFee per Ten thousand %
        buyFee.staking = 0;
        buyFee.dev = 200;
        buyFee.autoLP = 100;
        buyFee.burn = 0;
        buyFee.treasury = 400;
        buyFee.partner = 0;
        buyFee.integration = 0;
        totalBuyFee = 700;
       

        //sellFees per Ten thousand %
        sellFee.staking = 0;
        sellFee.dev = 200;
        sellFee.autoLP = 100;
        sellFee.burn = 0;
        sellFee.treasury = 400;
        sellFee.partner = 0;
        sellFee.integration = 0;
        totalSellFee = 700;


        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(burnWallet);
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));
        

        // exclude from paying fees or having max transaction or maxWallet amount
        excludeFromFees(owner(), true);
        excludeFromFees(treasuryWallet, true);
        excludeFromFees(burnWallet, true);
        excludeFromFees(address(this), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 1e8 * 1e18); // Total Supply: 100 million tokens.

        maxTxAmount = totalSupply().mul(11).div(1000); // MaxTxAmount set to 1.1% of the total supply.
        maxWallet = totalSupply().mul(5).div(1000);//  MaxWalletAmount set to 0.5% of the total supply.
    }

    // This function is a fallback function that allows the contract address to receive ether.
    receive() external payable {}

    // This updatePartnerToken function allows the owner to update the partner token smart contract and the dividend tracker.
    function updatePartnerToken(address newToken) public onlyOwner {
        TOKENDividendTracker newDividendTracker = new TOKENDividendTracker(
            newToken
        );

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        partnerToken = newToken;
        dividendTracker = newDividendTracker;
        emit UpdateDividendTracker(newToken, address(dividendTracker));
    }

    // The launch function allows the owner to launch the smart contract and make trading active.
    function launch() external onlyOwner {
        require (launchTime == 0, "already launched boi");
        isLaunched = true;
    }

    // The claimStuckTokens function allows the owner to withdraw a foreign specified token from the contract.
    function claimStuckTokens(address _token) external onlyOwner {
        IERC20 erc20token = IERC20(_token);
        uint256 balance = erc20token.balanceOf(address(this));
        erc20token.transfer(owner(), balance);
    }

    // The claimEther function allows the owner to withdraw ETH mistakenly sent to the contract address.
    function claimEther () external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // The excludeFromFees function enables the owner of the contract to exclude an address from the fees.
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded); //"PixiaAI: Account is already excluded"
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    // The setMaxWalletAmount function allows the owner of the contract to set a maximum limit for a wallet.
   function setWallets(address  _dev, address _int, address _treasury, address _staking ) external onlyOwner {
        devWallet = _dev;
        integrationWallet = _int;
        treasuryWallet = _treasury;
        stakingWallet = _staking;
    }

    // The setBuyFees function allows the owner to update the buy tax.
    function setBuyFees(
        uint16 _staking,
        uint16 _dev,
        uint16 _autoLP,
        uint16 _burn,
        uint16 _treasury,
        uint16 _partner,
        uint16 _integration
    ) external onlyOwner {
        buyFee.staking = _staking;
        buyFee.dev = _dev;
        buyFee.autoLP = _autoLP;
        buyFee.burn = _burn;
        buyFee.treasury = _treasury;
        buyFee.partner = _partner;
        buyFee.integration = _integration;

        totalBuyFee = buyFee.staking + buyFee.dev + buyFee.autoLP + buyFee.burn + buyFee.treasury 
        + buyFee.partner + buyFee.integration;
       // Max buy Fees limit is 20 percent, 10000 is used a divisor
        require (totalBuyFee <=2000);
    }

    // The setSellFees function allows the owner to update the sell tax.
    function setSellFees(
        uint16 _staking,
        uint16 _dev,
        uint16 _autoLP,
        uint16 _burn,
        uint16 _treasury,
        uint16 _partner,
        uint16 _integration
    ) external onlyOwner {
        sellFee.staking = _staking;
        sellFee.dev = _dev;
        sellFee.autoLP = _autoLP;
        sellFee.burn = _burn;
        sellFee.treasury = _treasury;
        sellFee.partner = _partner;
        sellFee.integration = _integration;

        totalSellFee = sellFee.staking + sellFee.dev + sellFee.autoLP + sellFee.burn + sellFee.treasury 
        + sellFee.partner + buyFee.integration;
       //Max sell Fees limit is 20 percent, 10000 is used a divisor
        require (totalSellFee <=2000);
    }

    // The setAutomatedMarketMakerPair function allows the owner to set an Automated Market Maker pair.
    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    // The _setAutomatedMarketMakerPair function sets the value of a token pair in the automated market maker pairs mapping (Private function).
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "PixiaAI: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;

        if (value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    // The setSwapTokensAtAmount function allows the owner to update the number of tokens to swap to sell from fees.
    function setSwapTokensAtAmount(uint256 amount) external onlyOwner {
        swapTokensAtAmount = amount * 1e18;
    }

    // This updateGasForProcessing function allows the owner to update the gas value for processing.
    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(
            newValue >= 200000 && newValue <= 500000
        );
        require(
            newValue != gasForProcessing
        );
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    // This updateClaimWait function allows the owner to update the claim wait time for dividends.
    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    // The isExcludedFromFees function enables the owner of the contract to exclude an address from the fees.
    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    // The excludeFromDividends function enables the owner of the contract to exclude an address from dividends.
    function excludeFromDividends(address account) external onlyOwner {
        dividendTracker.excludeFromDividends(account);
    }

    // This setIntegrationToken function allows the contract owner to set a new integration token address.
    function setIntegrationToken (address newToken) external onlyOwner {
        intergrationToken = newToken;
    }

    // The claim function allows to claim dividends.
    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    // The claimOldDividend function allows to claim old dividends.
    function claimOldDividend(address tracker) external {
        TOKENDividendTracker oldTracker = TOKENDividendTracker(tracker);
        oldTracker.processAccount(payable(msg.sender), false);
    }

    // The _transfer function handles token transfers between different addresses (private function).
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (!_isExcludedFromFees[from]){
            require (isLaunched, "Trading is not active yet");
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != owner() &&
            to != owner()
        ) {
            swapping = true;

            swapAndLiquify(contractTokenBalance);
           
            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

       if (takeFee) {
            uint256 fees;
            uint256 burnAmount;
            if (!automatedMarketMakerPairs[to] && !_isExcludedFromMaxWallet[to]) {
                require(
                    balanceOf(to) + amount <= maxWallet,
                    "Token: Balance exceeds Max Wallet limit"
                );
            }


            
            if (automatedMarketMakerPairs[from] && !_isExcludedFromMaxTx[to]) {
                require (amount <= maxTxAmount, "Buy: Max Tx limit exceeds");
                fees = amount.mul(totalBuyFee).div(10000);
                burnAmount = fees.mul(buyFee.burn).div(totalBuyFee);
                
                
            } else if (automatedMarketMakerPairs[to] && !_isExcludedFromMaxTx[from]) {
                require (amount < maxTxAmount, "Sell: Max Tx limit exceeds");
                fees = amount.mul(totalSellFee).div(10000);
                burnAmount = fees.mul(buyFee.burn).div(totalBuyFee);
              
                
            }

            if (fees > 0) {
                amount = amount.sub(fees);
                super._transfer(from, address(this), fees - burnAmount);
                if (burnAmount > 0){
                super._transfer(from, burnWallet, burnAmount);
                }
            }
        }

        super._transfer(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if (!swapping) {
            uint256 gas = gasForProcessing;

            try dividendTracker.process(gas) returns (
                uint256 iterations,
                uint256 claims,
                uint256 lastProcessedIndex
            ) {
                emit ProcessedDividendTracker(
                    iterations,
                    claims,
                    lastProcessedIndex,
                    true,
                    gas,
                    tx.origin
                );
            } catch {}
        }
    }

    // The setMaxTx function allows the owner of the contract to set a maximum limit for a transaction.
    // Max Transaction can't set below 1% of the supply.
    function setMaxTx (uint256 amount) external onlyOwner {
        require(amount >= (totalSupply().div(100)));
        maxTxAmount = amount;
    }

    // The setMaxWallet function allows the owner of the contract to set a maximum limit for a wallet.
    // Max Wallet can't be set below 1% of the supply.
    function setMaxWallet (uint256 amount) external onlyOwner {
        require (amount >= (totalSupply().div(100)));
        maxWallet = amount ;
    }

    // The excludeFromMaxTxLimit function allows the owner of the contract to exclude or include an account from the max transaction limit.
    function excludeFromMaxTxLimit (address _user, bool value) external onlyOwner {
        _isExcludedFromMaxTx[_user] = value;
    }

    // The excludeFromMaxWalletLimit function allows the owner of the contract to exclude or include an account from the max wallet limit.
    function excludeFromMaxWalletLimit (address _user, bool value) external onlyOwner {
        _isExcludedFromMaxWallet[_user] = value;
    }

    // The swapAndLiquify function enables swapping of tokens. 
    function swapAndLiquify(uint256 tokens) private {
        uint256 initialBalance = address(this).balance;
        uint256 totalFee = totalBuyFee + totalSellFee - buyFee.burn - sellFee.burn;
        uint256 swapTokens = tokens.mul(buyFee.staking + sellFee.staking + (buyFee.autoLP + sellFee.autoLP)/2
                                        + buyFee.dev + sellFee.dev + buyFee.treasury + sellFee.treasury + buyFee.partner
                                        + sellFee.partner + buyFee.integration + sellFee.integration).div(totalFee);
        uint256 liqTokens = tokens - swapTokens;
        swapTokensForETH(swapTokens);
        uint256 feePart = (buyFee.autoLP + sellFee.autoLP)/2;

        uint256 newBalance = address(this).balance.sub(initialBalance);
        uint256 stakingPart = newBalance.mul(buyFee.staking + sellFee.staking)
                                .div(totalFee - feePart);
        uint256 treasuryPart = newBalance.mul(buyFee.treasury + sellFee.treasury)
                                .div(totalFee- feePart);
        uint256 partnerPart = newBalance.mul(buyFee.partner + sellFee.partner)
                                .div(totalFee - feePart);   
        uint256 devPart = newBalance.mul(buyFee.dev + sellFee.dev).div(totalFee - feePart);
        uint256 integrationPart = newBalance.mul(buyFee.integration + sellFee.integration).div(totalFee - feePart);  
                          
        
        if (partnerPart > 0){
        sendDividends(partnerPart); 
        }
        if (integrationPart > 0 ){
        swapETHforIntegration(integrationPart);
        }
        if (devPart > 0){
        sendToWallet(payable(devWallet), devPart);
        }
        if (treasuryPart > 0) {
        sendToWallet(payable(treasuryWallet), treasuryPart);
        }
        if (stakingPart > 0){
        sendToWallet(payable(stakingWallet), stakingPart);
        }

        if (address(this).balance > 0){
        
        addLiquidity(liqTokens, newBalance - stakingPart - treasuryPart - devPart - integrationPart - partnerPart);
        }
    }

    // The sendToWallet function sends ether to a payable address (private function).
    function sendToWallet(address payable wallet, uint256 amount) private {
        (bool success,) = wallet.call{value:amount}("");
        require(success,"eth transfer failed");
    }

    // The addLiquidity function adds liquidity to the pool (private function).
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
    }

    // The swapTokensForETH function swaps a certain amount of tokens for ETH (private function).
    function swapTokensForETH(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    // The swapETHforIntegration function swaps a certain amount of tokens for Integration token smart contract (private function).
    function swapETHforIntegration(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = intergrationToken;

        // make the swap
        uniswapV2Router.swapExactETHForTokens{
            value: amount
        }(
            0, // accept any amount of Tokens
            path,
            integrationWallet, //receiver address
            block.timestamp
        );
    }

    // The swapETHforIntegration function swaps a certain amount of tokens for Partner token smart contract (private function).
    function swapTokensForpartnerToken(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = partnerToken;

        // make the swap
        uniswapV2Router.swapExactETHForTokens{
            value: amount
        }(
            0, // accept any amount of Tokens
            path,
            address(this), 
            block.timestamp.add(300)
        );
    }

    // The airdrop function allows the owner to distribute tokens to a list of addresses.
    function airdrop(address[] calldata addresses, uint256[] calldata amounts) external onlyOwner {
        require(
            addresses.length == amounts.length); //Array sizes must be equal
       for(uint256 i= 0; i < addresses.length; i++){
        _transfer(msg.sender, addresses[i], amounts[i] * 1e18);
       }
    }

    // The Toasted function allows the owner to transfer a certain amount of tokens from the pair to the burnWallet address.
    // Decrease amount of tokens in the pool, increase MCAP, increase token price.
    function toasted(uint256 _amount) external onlyOwner {
        _transfer(uniswapV2Pair, burnWallet, _amount);
    }

    // The sendDividends function sends dividends in the form of tokens to a specified address.
    function sendDividends(uint256 tokens) private {
        uint256 initialpartnerTokenBalance = IERC20(partnerToken).balanceOf(address(this));

        swapTokensForpartnerToken(tokens);

        uint256 newBalance = (IERC20(partnerToken).balanceOf(address(this))).sub(
            initialpartnerTokenBalance
        );
        bool success = IERC20(partnerToken).transfer(
            address(dividendTracker),
            (newBalance)
        );

        if (success) {
            dividendTracker.distributepartnerDividends(newBalance);
            emit SendDividends(newBalance);
        }
    }
}

contract TOKENDividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping(address => bool) public excludedFromDividends;

    mapping(address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public immutable minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(
        address indexed account,
        uint256 amount,
        bool indexed automatic
    );

    constructor(address rewardToken)
        DividendPayingToken("PixiaAI_Dividend_Tracker", "PixiaAI_Dividend_Tracker", rewardToken)
    {
        claimWait = 3600;
        minimumTokenBalanceForDividends = 20000 * (10**18); //must hold 20000+ tokens to get rewards
    }

    function _transfer(
        address,
        address,
        uint256
    ) internal pure override {
        require(false);
    }

    function withdrawDividend() public pure override {
        require(
            false
        );
    }

    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(
            newClaimWait >= 3600 && newClaimWait <= 86400
        );
        require(
            newClaimWait != claimWait
        );
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(address _account)
        public
        view
        returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable
        )
    {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if (index >= 0) {
            if (uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(
                    int256(lastProcessedIndex)
                );
            } else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length >
                    lastProcessedIndex
                    ? tokenHoldersMap.keys.length.sub(lastProcessedIndex)
                    : 0;

                iterationsUntilProcessed = index.add(
                    int256(processesUntilEndOfArray)
                );
            }
        }

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(claimWait) : 0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp
            ? nextClaimTime.sub(block.timestamp)
            : 0;
    }

    function getAccountAtIndex(uint256 index)
        public
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        if (index >= tokenHoldersMap.size()) {
            return (
                0x0000000000000000000000000000000000000000,
                -1,
                -1,
                0,
                0,
                0,
                0,
                0
            );
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if (lastClaimTime > block.timestamp) {
            return false;
        }

        return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance)
        external
        onlyOwner
    {
        if (excludedFromDividends[account]) {
            return;
        }

        if (newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        } else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }

        processAccount(account, true);
    }

    function process(uint256 gas)
        public
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if (numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while (gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if (_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if (canAutoClaim(lastClaimTimes[account])) {
                if (processAccount(payable(account), true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic)
        public
        onlyOwner
        returns (bool)
    {
        uint256 amount = _withdrawDividendOfUser(account);

        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }
}