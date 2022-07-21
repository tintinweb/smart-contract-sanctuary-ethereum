// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./IERC20.sol";

contract SampleToken is IERC20 {
    constructor() {
        _totalSupply = 1000000;
        _balances[msg.sender] = 1000000;
    }

    uint256 private _totalSupply;
    //mapping{address} -> balance
    mapping(address => uint256) private _balances;
    //_allowances[sender][spender] = allowances
    mapping(address => mapping(address => uint256)) private _allowances;

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        require(_balances[msg.sender] >= amount);
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(_balances[sender] >= amount);
        require(_allowances[sender][msg.sender] >= amount);
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/* 
    https://eips.ethereum.org/EIPS/eip-20
*/
interface IERC20 {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value)
        external
        returns (bool success);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);
}