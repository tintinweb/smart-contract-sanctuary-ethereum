/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
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
        return functionCallWithValue(target, data, 0, errorMessage);
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

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

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

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
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


contract SparkToken is Context, IERC20, Ownable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private minTotalSupply = 10000 * 10 ** decimals;
    uint256 public burnTotalSupply;

    string public name = "Spark Token";
    string public symbol = "SKT";
    uint256 public decimals = 18;

    address public usdt = 0x966deD5B32ec28C8f3E332225184c2a5a01585B0;
    IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public uniswapV2Pair;
    address lpDealAddress;

    mapping(address => address) private recommenderMap;

    address market = 0x04ea394AB45AF0b79710c68Ea87B87d0945b12BD;
    address daoFund = 0xdEaE3412a02FA5D67D8bF1be435f180DfeB23D50;
    address platform = 0x62450ecaD082d4f4C5d4a37848DAaD7a297E53F9;
    address liquidityManager;
    uint8 private marketRate = 10;
    uint8 private daoFundRate = 10;
    uint8 private lpRate = 10;
    uint8 private lpShareRate = 10;
    uint8 private burnRate = 10;
    uint8 private level = 8;
    mapping(address => bool) private excluded;
    uint256 minLp = 10 * 10 ** decimals;
    uint256 minRecommend = 10 ** decimals / 100;

    uint256 minLpDealTokenCount = 10 ** decimals;

    uint256 public startTime;
    uint256 limit = 50 * 10 ** decimals;
    mapping(address => bool) private notLimit;
    mapping(address => bool) private transNotLimit;

    mapping(address => bool) private blacklist;

    mapping(address => uint32) private lastTradeTime;
    uint16 private tradeInterval = 600;

    bool lock;
    modifier swapLock() {
        require(!lock, "ERC20: swap locked");
        lock = true;
        _;
        lock = false;
    }

    constructor(uint256 _startTime) {
        _mint(owner(), 100000 * 10 ** decimals);
        startTime = _startTime;

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
        .createPair(address(this), usdt);

        excluded[address(this)] = true;
        excluded[address(uniswapV2Router)] = true;
        excluded[market] = true;
        excluded[daoFund] = true;
        excluded[platform] = true;
        excluded[owner()] = true;

        notLimit[address(this)] = true;
        notLimit[uniswapV2Pair] = true;
        notLimit[address(uniswapV2Router)] = true;
        notLimit[market] = true;
        notLimit[daoFund] = true;
        notLimit[platform] = true;
        notLimit[owner()] = true;

        transNotLimit[market] = true;
        transNotLimit[daoFund] = true;
        transNotLimit[platform] = true;
        transNotLimit[owner()] = true;
    }

    receive() external payable {}

    function initLiquidityManager(address _liquidityManager) public onlyOwner {
        liquidityManager = _liquidityManager;
        excluded[liquidityManager] = true;
        notLimit[liquidityManager] = true;
        Address.functionCall(liquidityManager, abi.encodeWithSelector(0x86863ec6, address(this), uniswapV2Pair, minLpDealTokenCount));
    }

    function setLpDealAddress(address _lpDealAddress) public onlyOwner {
        lpDealAddress = _lpDealAddress;
    }

    function addBlackList(address _addr, bool _state) public onlyOwner {
        blacklist[_addr] = _state;
    }

    function setStartTime(uint256 _startTime) public onlyOwner {
        startTime = _startTime;
    }

    function setExcluded(address _addr, bool _state) public onlyOwner {
        excluded[_addr] = _state;
    }

    function setNotLimit(address _addr, bool _state) public onlyOwner {
        notLimit[_addr] = _state;
    }

    function setTransNotLimit(address _addr, bool _state) public onlyOwner {
        transNotLimit[_addr] = _state;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function burn(uint256 amount) public {
        address spender = _msgSender();
        require(excluded[spender], "ERC20: Cannot burn");
        _burn(spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!blacklist[from], "ERC20: Blacklist users");

        _tradeControl(from, to);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        _balances[from] = fromBalance - amount;

        if (amount >= minRecommend) {
            _saveRecommender(from, to);
        }

        uint256 finalAmount = _fee(from, to, amount);

        if (!Address.isContract(from) && !Address.isContract(to)) {
            _swapForLiquidity();
        }

        if (!transNotLimit[from] && !notLimit[to]) {
            require(_balances[to] + finalAmount <= limit, "ERC20: limit 50");
        }
        _balances[to] += finalAmount;

        emit Transfer(from, to, finalAmount);
    }

    function _mint(address account, uint256 amount) private {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) private {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        _balances[account] = accountBalance - amount;

        _baseBurn(account, amount);
//
//        _totalSupply -= amount;
//        burnTotalSupply += amount;
//
//        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) private {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");

            _approve(owner, spender, currentAllowance - amount);
        }
    }

    function _saveRecommender(address from, address to) private {
        if (_balances[to] != 0 || recommenderMap[to] != address(0)) {
            return;
        }

        if (Address.isContract(to)
            || to == address(0)) {
            return;
        }

        recommenderMap[to] = Address.isContract(from) ? platform : from;
    }

    function _tradeControl(address from, address to) private {
        if (from == address(uniswapV2Pair) || to == address(uniswapV2Pair)) {
            address addr = from == address(uniswapV2Pair) ? to : from;
            if (startTime > block.timestamp) {
                if (!notLimit[addr]) {
                    revert("Transaction not started");
                }
            } else if (startTime + 10 > block.timestamp) {
                if (!notLimit[addr]) {
                    blacklist[addr] = true;
                }
            } else if (startTime + 3600 > block.timestamp) {
                if (!notLimit[addr]) {
                    require(lastTradeTime[addr] + tradeInterval <= block.timestamp, "ERC20: Insufficient interval");
                    lastTradeTime[addr] = uint32(block.timestamp);
                }
            }
        }
    }

    function _fee(address from, address to, uint256 amount) private returns(uint256 finalAmount) {
        if (from == address(uniswapV2Pair) || to == address(uniswapV2Pair)) {
            address addr = from == address(uniswapV2Pair) ? to : from;
            if (excluded[addr]) {
                finalAmount = amount;
            } else {
                finalAmount = _countFee(from, addr, amount);
            }
        } else {
            finalAmount = amount;
        }
    }

    function _countFee(address from, address addr, uint256 amount) private returns(uint256 finalAmount) {
        uint256 marketFee = amount * marketRate / 1000;
        uint256 daoFundFee = amount * daoFundRate / 1000;
        uint256 lpFee = amount * lpRate / 1000;
        uint256 lpShareFee = amount * lpShareRate / 1000;
        uint256 burnFee = amount * burnRate / 1000;

        uint256 totalRate = _countBonusLevel();

        uint256 bonusFee = amount * totalRate / 1000;
        finalAmount = amount - marketFee - daoFundFee - lpFee - lpShareFee - burnFee - bonusFee;

        address recommender = recommenderMap[addr];
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
        for (uint256 i ; i < level && recommender != address(0) ; i++) {
            if (pair.balanceOf(recommender) < minLp && !excluded[recommender]) {
                continue;
            }

            uint256 bonus = amount * 5 / 1000;

            if (_balances[recommender] >= 50 && !excluded[recommender]) {
                _baseBurn(from, bonus);
            } else {
                _addBalance(from, recommender, bonus);
            }

            bonusFee -= bonus;

            recommender = recommenderMap[recommender];
        }

        _addBalance(from, platform, bonusFee);
        _addBalance(from, market, marketFee);
        _addBalance(from, daoFund, daoFundFee);
        _addBalance(from, liquidityManager, lpFee + lpShareFee);
        _baseBurn(from, burnFee);
    }

    function _baseBurn(address from, uint256 amount) private {
        uint256 finalBurn = 0;
        if (_totalSupply > minTotalSupply) {
            finalBurn = amount;
            if (_totalSupply - amount < minTotalSupply) {
                finalBurn = _totalSupply - minTotalSupply;
            }
            _totalSupply -= finalBurn;
            burnTotalSupply += finalBurn;
            emit Transfer(from, address(0), finalBurn);

            if (_totalSupply < 80000 * 10 ** decimals) {
                level = 6;
            } else if (_totalSupply < 50000 * 10 ** decimals) {
                level = 4;
            } else if (_totalSupply < 30000 * 10 ** decimals) {
                level = 2;
            } else if (_totalSupply <= 10000 * 10 ** decimals) {
                level = 0;
            }
        }

        if (finalBurn < amount) {
            _addBalance(from, platform, amount - finalBurn);
        }
    }

    function _countBonusLevel() private view returns(uint256 totalRate) {
        for (uint256 i ; i < level ; i++) {
            totalRate += 5;
        }
    }

    function _addBalance(address from, address to, uint256 amount) private {
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _swapForLiquidity() private swapLock {
        uint256 tokens = _balances[liquidityManager];
        if (tokens < minLpDealTokenCount) {
            return;
        }

        Address.functionCall(liquidityManager, abi.encodeWithSelector(0x24b1c2ba, lpRate, lpShareRate));
    }

    function _baseTransfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[from] = fromBalance - amount;

        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }
}