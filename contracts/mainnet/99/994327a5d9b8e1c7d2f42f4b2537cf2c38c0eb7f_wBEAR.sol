/**
 *Submitted for verification at Etherscan.io on 2022-03-07
*/

/**
 * WRAPPED BEAR       -           https://BEARBUCKS.FINANCE         -         https://t.me/BEARBUCKS
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

/**
 * SAFEMATH LIBRARY
 */
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
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

interface IDEXRouter {
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

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract wBEAR is IERC20, Auth, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public constant MASK = type(uint128).max;
    address BASE = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address DEAD_NON_CHECKSUM = 0x000000000000000000000000000000000000dEaD;
    address BURN = 0x000000000000000000000000000000000000dEaD;
    address BEAR = 0xFd1Ce765af87Ac647059323f29a560E386A65492;
    IERC20 bear = IERC20(BEAR);

    string constant _name = "Wrapped Bear Bucks";
    string constant _symbol = "wBEAR";
    uint8 constant _decimals = 9;

    uint256 constant public maxSupply = 1000000000 * (10 ** _decimals);
    uint256 _totalSupply = 0;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    IDEXRouter public router;
    address public pair;

    bool public tradingEnabled = true;

    bool public canEmergencySweep = true;
    bool public hasEmergencySweeped = false;
    bool public paused = false;

    constructor () Auth(msg.sender) {
        approve(BEAR, maxSupply);
        _balances[msg.sender] = 0;
        emit Transfer(address(0), msg.sender, 0);
    }

    function mint(
        uint256 _amount
    ) external nonReentrant {
        require(!hasEmergencySweeped, "This contract is no longer in use");
        require(!paused, "This contract is paused");
        require(maxSupply >= _amount, "The amount exceeds the supply");
        bool _transfer = bear.transferFrom(msg.sender, address(this), _amount);
        require(_transfer, "Failed to receive tokens");
        _totalSupply += _amount;
        _balances[msg.sender] += _amount;
    }

    function redeem(
        uint256 _amount
    ) public nonReentrant {
        require(!hasEmergencySweeped, "This contract is no longer in use");
        require(!paused, "This contract is paused");
        require(_balances[msg.sender] >= _amount, "Your wBEAR balance is too low");
        require(_totalSupply >= _amount, "The contract BEAR balance is too low");
        bool _transfer = bear.transferFrom(address(this), msg.sender, _amount);
        require(_transfer, "Failed to send tokens");
        _balances[msg.sender] -= _amount;
        _totalSupply -= _amount;
    }

    function burn(
        uint256 _amount
    ) external nonReentrant {
        require(!hasEmergencySweeped, "This contract is no longer in use");
        require(!paused, "This contract is paused");
        require(_balances[msg.sender] >= _amount, "Your wBEAR balance is too low");
        require(_totalSupply >= _amount, "The contract BEAR balance is too low");
        bool _transfer = bear.transferFrom(address(this), BURN, _amount);
        require(_transfer, "Failed to send tokens");
        _balances[msg.sender] -= _amount;
        _totalSupply -= _amount;
    }

    function disableEmergencySweeping() external onlyOwner {
        require(!hasEmergencySweeped, "This contract is no longer in use");
        canEmergencySweep = false;
    }

    function emergencySweepCustom(
        address _to,
        uint256 _amount,
        bool _disable
    ) external onlyOwner {
        require(!hasEmergencySweeped, "This contract is no longer in use");
        require(canEmergencySweep, "Emergency sweeping has been disabled");
        bear.transfer(_to, _amount);
        if (_disable) {
            hasEmergencySweeped = true;
        }
    }

    function emergencySweepFull(
        address _to
    ) external onlyOwner {
        require(!hasEmergencySweeped, "This contract is no longer in use");
        require(canEmergencySweep, "Emergency sweeping has been disabled");
        bear.transfer(_to, bear.balanceOf(address(this)));
        hasEmergencySweeped = true;
    }

    function togglePaused(
        bool _paused
    ) external onlyOwner {
        paused = _paused;
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(
        address spender
    ) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(tradingEnabled, "Trading is currently disabled");
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function Sweep() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function changeBASE(
        address _BASE
    ) external onlyOwner {
        BASE = _BASE;
    }

    function changeWETH(
        address _WETH
    ) external onlyOwner {
        WETH = _WETH;
    }

    function changeBURN(
        address _BURN
    ) external onlyOwner {
        BURN = _BURN;
    }

    function changeBEAR(
        address _BEAR,
        bool _approve
    ) external onlyOwner {
        BEAR = _BEAR;
        bear = IERC20(_BEAR);
        if (_approve) {
            approve(BEAR, maxSupply);
        }
    }

    function transferForeignToken(
        address _token,
        address _to
    ) external onlyOwner returns (bool _sent) {
        if (_token == BEAR) {
            require(canEmergencySweep, "Emergency sweeping has been disabled");
        }
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    }

    function enableTrading() external authorized {
        if (!tradingEnabled) {
            tradingEnabled = true;
        }
    }

    function toggleTrading(
        bool _enabled
    ) external authorized {
        tradingEnabled = _enabled;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }
}