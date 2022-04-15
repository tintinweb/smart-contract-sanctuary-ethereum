//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract MaxToken is IERC20 {
    //uint constant MAX_UINT = type(uint).max;

    uint public override totalSupply;
    address public owner;

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowances;

    mapping (address => bool) public minters;
    string public name;
    string public symbol;
    uint8 public decimals;

    constructor (uint initialSupply_, string memory name_, string memory symbol_, uint8 decimals_) {
        owner = msg.sender;
        balances[msg.sender] = initialSupply_;
        totalSupply = initialSupply_;
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        minters[msg.sender] = true;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////

    function balanceOf(address who) external view override returns (uint256) {
        return balances[who];
    }

    function allowance(address owner_, address spender)
        external
        view
        override
        returns (uint256)
    {
        return allowances[owner_][spender];
    }

    function transfer(address to, uint256 value)
        external
        override
        returns (bool)
    {
        require(balances[msg.sender] >= value, 'Not enough tokens on balance');
        balances[msg.sender] -= value;
        balances[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        allowances[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        require(allowances[from][msg.sender] >= value, 'Not enough allowance to spend');
        require(balances[from] >= value, 'Not enough tokens on spender balance');

        allowances[from][msg.sender] -= value;
        balances[from] -= value;
        balances[to] += value;

        emit Transfer(from, to, value);
        return true;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////

    function setMinterRole(address user, bool isMinter) external {
        require(msg.sender == owner, 'Only owner can set minter role');

        minters[user] = isMinter;
    }

    function mint(address to, uint value) external {
        require(minters[msg.sender] == true, 'Only minter can mint tokens');

        totalSupply += value;
        balances[to] += value;

        emit Transfer(address(0), to, value);
    }

    function burnInternal(address from, uint value) internal {
        require(balances[from] >= value, 'Not enough tokens on balance to burn');

        totalSupply -= value;
        balances[from] -= value;

        emit Transfer(from, address(0), value);
    }

    function burn(uint value) external {
        burnInternal(msg.sender, value);
    }

    function burnFrom(address from, uint value) external {
        require(allowances[from][msg.sender] >= value, 'Not enough allowance to burn');

        allowances[from][msg.sender] -= value;
        burnInternal(from, value);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}