/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

/**
 *Submitted for verification at BscScan.com on 2022-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint256);
  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);
  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint256) external view returns (address pair);
  function allPairsLength() external view returns (uint256);
  function createPair(address tokenA, address tokenB) external returns (address pair);
  function setFeeTo(address) external;
  function setFeeToSetter(address) external;
} interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint256);
  function balanceOf(address owner) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 value) external returns (bool);
  function transfer(address to, uint256 value) external returns (bool);
  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);
  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint256);
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
  event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
  event Sync(uint112 reserve0, uint112 reserve1);
  function MINIMUM_LIQUIDITY() external pure returns (uint256);
  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );
  function price0CumulativeLast() external view returns (uint256);
  function price1CumulativeLast() external view returns (uint256);
  function kLast() external view returns (uint256);
  function mint(address to) external returns (uint256 liquidity);
  function burn(address to) external returns (uint256 amount0, uint256 amount1);
  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;
  function skim(address to) external;
  function sync() external;
  function initialize(address, address) external;
} interface IUniswapV2Router01 {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);
  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );
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
  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);
  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);
  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);
  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);
  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);
  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);
  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);
  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);
  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);
  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);
  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);
  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);
  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);
  function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
  function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
} interface IUniswapV2Router02 is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);
  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);
  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;
  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
} library Address {
  function isContract(address account) internal view returns (bool) {
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != accountHash && codehash != 0x0);
  }
  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");
    (bool success, ) = recipient.call{value: amount}("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }
  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, "Address: low-level call failed");
  }
  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, errorMessage);
  }
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    return _functionCallWithValue(target, data, value, errorMessage);
  }
  function _functionCallWithValue(
    address target,
    bytes memory data,
    uint256 weiValue,
    string memory errorMessage
  ) private returns (bytes memory) {
    require(isContract(target), "Address: call to non-contract");
    (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
    if (success) {
      return returndata;
    } else {
      if (returndata.length > 0) {
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
} library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    return c;
  }
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
} interface IERC20 {
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
} interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
} abstract contract Context {
    function __Context_init() internal {
    }
    function __Context_init_unchained() internal {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
} contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    function __ERC20_init(string memory name_, string memory symbol_) internal {
        __ERC20_init_unchained(name_, symbol_);
    }
    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal {
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

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(from, to, amount);
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        _afterTokenTransfer(from, to, amount);
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
    uint256[45] private __gap;
} library MerkleProof {

    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }
    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
} interface INodeManager {
  function feeManager() external view returns (address);
  function countOfUser(address account) external view returns (uint32);
} contract Alora is ERC20 {
  using SafeMath for uint256;
  constructor() {
    __ERC20_init("Alora", "ALORA");
    owner = msg.sender;
    operator = msg.sender;
    transferTaxRate = 1000;
    buyBackFee = 1600;
    sellBackFee = 1400;
    operatorFee = 0;
    liquidityFee = 4000;
    minAmountToLiquify = 10 ether;
    checkNodeBeforeSell = true;
    // whiteListerfund = 0xBd6fc012F89368eD1E0da4b0d047A09d08366727;
    _maxCapReserveAllocation = 75000e18;
    reserveAllocationAmount = 0;
    _maxCapRewardPool = 700000e18;
    rewardPoolAmount = 0;
    _maxCapTeamAllocation = 75000e18;
    teamAllocationAmount = 0;
    _maxCapLiquidityPool = 150000e18;
    liquidityPoolAmount = 0;
    // _totalDeposit = 0;

    removeExcludedFromFee(owner);
    setExcludedFromFee(owner);
    _mint(owner, 1000000 ether);

  }
  receive() external payable {}
  bool private _inSwapAndLiquify;
  uint32 public transferTaxRate; // 1000 => 10%
  uint32 private buyBackFee; // 3000 => 30%
  uint32 public operatorFee; // 60 => 6% (60*0.1)
  uint32 public liquidityFee; // 40 => 4% (40*0.1)
  uint256 private minAmountToLiquify;
  address public owner;
  address public operator;
  // address public whiteListerfund;
  mapping(address => bool) public isExcludedFromFee;
  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2Pair;
  uint256 private accumulatedOperatorTokensAmount;
  address public nodeManagerAddress;
  bool public checkNodeBeforeSell;
  uint32 private sellBackFee; // 3000 => 30%
  uint256 private _maxCapReserveAllocation;
  uint256 public reserveAllocationAmount;
  uint256 private _maxCapRewardPool;
  uint256 public rewardPoolAmount;
  uint256 private _maxCapTeamAllocation;
  uint256 public teamAllocationAmount;
  uint256 private _maxCapLiquidityPool;
  uint256 public liquidityPoolAmount;
  // bytes32 public merkleRoot;
  // address public stableToken;
  // mapping(uint8 => uint256) toDepositAmount;
  // uint256 public _totalDeposit;
  mapping(address => bool) public blacklist;
  // mapping(address => uint256) public depositAmount;
  event SwapAndLiquify(uint256, uint256, uint256);
  event UniswapV2RouterUpdated(address, address, address);
  event LiquidityAdded(uint256, uint256);
  modifier onlyOwner() {
    require(owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }
  modifier lockTheSwap() {
    _inSwapAndLiquify = true;
    _;
    _inSwapAndLiquify = false;
  }
  modifier transferTaxFree() {
    uint32 _transferTaxRate = transferTaxRate;
    transferTaxRate = 0;
    _;
    transferTaxRate = _transferTaxRate;
  }
  function setTransferTaxRate(uint32 _transferTaxRate) public onlyOwner {
    transferTaxRate = _transferTaxRate;
  }
  function buyFee() public view returns (uint32) {
    return buyBackFee;
  }
  function setBuyFee(uint32 value) public onlyOwner {
    buyBackFee = value;
  }
  function sellFee() public view returns (uint32) {
    return sellBackFee;
  }
  function setSellFee(uint32 value) public onlyOwner {
    sellBackFee = value;
  }
  function setOperator(address account) public onlyOwner {
    operator = account;
  }
  function setOperatorFee(uint32 value) public onlyOwner {
    operatorFee = value;
  }
  function setLiquidityFee(uint32 value) public onlyOwner {
    liquidityFee = value;
  }
  function setExcludedFromFee(address account) public onlyOwner {
    isExcludedFromFee[account] = true;
  }
  function removeExcludedFromFee(address account) public onlyOwner {
    isExcludedFromFee[account] = false;
  }
  function setMinAmountToLiquify(uint256 value) public onlyOwner {
    minAmountToLiquify = value;
  }
  function setNodeManagerAddress(address _nodeManagerAddress) public onlyOwner {
    nodeManagerAddress = _nodeManagerAddress;
  }
  function setCheckNodeBeforeSell(bool check) public onlyOwner {
    checkNodeBeforeSell = check;
  }
  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    require(!blacklist[from], "stop");
    bool _isSwappable = address(uniswapV2Router) != address(0) && uniswapV2Pair != address(0);
    bool _isBuying = _isSwappable && msg.sender == address(uniswapV2Pair) && from == address(uniswapV2Pair);
    bool _isSelling = _isSwappable && msg.sender == address(uniswapV2Router) && to == address(uniswapV2Pair);
    uint256 _amount = amount;
    if (!isExcludedFromFee[from] && !isExcludedFromFee[to]) {
      uint256 taxAmount = 0;
      if (_isSelling && checkNodeBeforeSell && nodeManagerAddress != address(0) && !_inSwapAndLiquify) {
        INodeManager mgr = INodeManager(nodeManagerAddress);
        require(address(mgr.feeManager()) == from || mgr.countOfUser(from) > 0, "Insufficient Node count!");
      }
      if (_isSelling && sellBackFee > 0) {
        taxAmount = amount.mul(sellBackFee).div(10000);
      } else if (_isBuying && buyBackFee > 0) {
        taxAmount = amount.mul(buyBackFee).div(10000);
      } else if (transferTaxRate > 0) {
        taxAmount = amount.mul(transferTaxRate).div(10000);
      }
      if (taxAmount > 0) {
        uint256 operatorFeeAmount = taxAmount.mul(operatorFee).div(100);
        super._transfer(from, address(this), operatorFeeAmount);
        accumulatedOperatorTokensAmount += operatorFeeAmount;
        if (_isSelling && !_inSwapAndLiquify) {
          swapAndSendToAddress(operator, accumulatedOperatorTokensAmount);
          accumulatedOperatorTokensAmount = 0;
        }
        uint256 liquidityAmount = taxAmount.mul(liquidityFee).div(100);
        super._transfer(from, address(this), liquidityAmount);
        _amount = amount.sub(operatorFeeAmount.add(liquidityAmount));
      }
    }
    if (_isSwappable && !_inSwapAndLiquify && !_isBuying && from != owner) {
      swapAndLiquify();
    }
    super._transfer(from, to, _amount);
  }
  function claimTransfer(
    address from,
    address to,
    uint256 amount
  ) public {
    super._transfer(from, to, amount);
  }
  function swapAndSendToAddress(address destination, uint256 tokens) private lockTheSwap transferTaxFree {
    uint256 initialETHBalance = address(this).balance;
    swapTokensForEth(tokens);
    uint256 newBalance = (address(this).balance).sub(initialETHBalance);
    payable(destination).transfer(newBalance);
  }
  function swapAndLiquify() private lockTheSwap transferTaxFree {
    uint256 contractTokenBalance = balanceOf(address(this));
    if (contractTokenBalance >= accumulatedOperatorTokensAmount) {
      contractTokenBalance = contractTokenBalance.sub(accumulatedOperatorTokensAmount);
      if (contractTokenBalance >= minAmountToLiquify) {
        uint256 liquifyAmount = contractTokenBalance;
        uint256 half = liquifyAmount.div(2);
        uint256 otherHalf = liquifyAmount.sub(half);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
      }
    }
  }
  function swapTokensForEth(uint256 tokenAmount) private {
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
  }
  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    uniswapV2Router.addLiquidityETH{value: ethAmount}(
      address(this),
      tokenAmount,
      0,
      0,
      owner,
      block.timestamp
    );
    emit LiquidityAdded(tokenAmount, ethAmount);
  }
  function updateRouter(address _router) public onlyOwner {
    uniswapV2Router = IUniswapV2Router02(_router);
    uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), uniswapV2Router.WETH());
    require(uniswapV2Pair != address(0), "Token:Invalid pair");
    emit UniswapV2RouterUpdated(msg.sender, address(uniswapV2Router), uniswapV2Pair);
  }
  function claimTokens(address teamWallet) public onlyOwner {
    payable(teamWallet).transfer(address(this).balance);
  }
  function claimOtherTokens(address anyToken, address recipient) external onlyOwner {
    IERC20(anyToken).transfer(recipient, IERC20(anyToken).balanceOf(address(this)));
  }
  function clearStuckBalance(address payable account) external onlyOwner {
    account.transfer(address(this).balance);
  }
  function addBlacklist(address _account) public onlyOwner {
    blacklist[_account] = true;
  }




  function mintReserveAllocation(address _reserveAllocation, uint256 _amount) public onlyOwner {
    require(_maxCapReserveAllocation >= _amount, "RA:Minting amount exceed");
    reserveAllocationAmount += _amount;
    require(_maxCapReserveAllocation >= reserveAllocationAmount, "RA:Minted exceed limite");
    _mint(_reserveAllocation, _amount);
  }

  function mintRewardPool(address _rewardPool, uint256 _amount) public onlyOwner {
    require(_maxCapRewardPool >= _amount, "RP:Minting amount exceed");
    rewardPoolAmount += _amount;
    require(_maxCapRewardPool >= rewardPoolAmount, "RP:Minted exceed limite");
    _mint(_rewardPool, _amount);
  }

  function mintTeamAllocation(address _teamAllocation, uint256 _amount) public onlyOwner {
    require(_maxCapTeamAllocation >= _amount, "TA:Minting amount exceed");
    teamAllocationAmount += _amount;
    require(_maxCapTeamAllocation >= teamAllocationAmount, "TA:Minted exceed limite");
    _mint(_teamAllocation, _amount);
  }

  function mintLiquidityPool(address _liquidityPool, uint256 _amount) public onlyOwner {
    require(_maxCapLiquidityPool >= _amount, "LP:Minting amount exceed");
    liquidityPoolAmount += _amount;
    require(_maxCapLiquidityPool >= liquidityPoolAmount, "TA:Minted exceed limite");
    _mint(_liquidityPool, _amount);
  }




  function burn( address account, uint256 _amount) public onlyOwner {
    _burn(account, _amount);
  }
}