/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

//SPDX-License-Identifier: qcontract.org
pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256 balance);
    function transfer(address to, uint256 amount)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool success);

    function allowance(address tokenOwner, address spender)
        external
        view
        returns (uint256 remaining);

    function approve(address spender, uint256 amount)
        external
        returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
}

contract SafeMath {
    function add(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b >= a);
        c = a / b;
    }
}

contract PlanetZero is IERC20, SafeMath {
    address payable owner;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _totalSupply;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) allowed;

    //init token details
    constructor() {
        name = "Planet Zero";
        symbol = "PLZ";
        decimals = 18;
        _totalSupply = 500000000000000000000000000;
        owner = payable(msg.sender);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256 balance)
    {
        return balances[account];
    }

    function allowance(address tokenOwner, address spender)
        external
        view
        override
        returns (uint256 remaining)
    {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool success)
    {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool success)
    {
        balances[msg.sender] = sub(balances[msg.sender], amount);
        balances[to] = add(balances[to], amount);

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool success) {
        allowed[from][msg.sender] = sub(allowed[from][msg.sender], amount);

        balances[from] = sub(balances[from], amount);
        balances[to] = add(balances[to], amount);

        emit Transfer(msg.sender, to, amount);
        return true;
    }
}