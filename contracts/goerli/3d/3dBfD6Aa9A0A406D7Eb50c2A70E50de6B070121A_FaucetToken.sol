// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "./StandardToken.sol";

/**
 * @title Minterest Faucet Test Token
 * @author Minterest
 * @notice A simple test token that lets anyone get more of it.
 */
contract FaucetToken is StandardToken {
    constructor(
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) StandardToken(_initialAmount, _tokenName, _decimalUnits, _tokenSymbol) {}

    function allocateTo(address _owner, uint256 value) public {
        balanceOf[_owner] += value;
        totalSupply += value;
        emit Transfer(address(this), _owner, value);
    }

    function approveTo(
        address _owner,
        address _spender,
        uint256 amount
    ) external {
        allowance[_owner][_spender] = amount;
        emit Approval(_owner, _spender, amount);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "./ERC20.sol";

/**
 * @title Standard ERC20 token
 * @dev Implementation of the basic standard token.
 *  See https://github.com/ethereum/EIPs/issues/20
 */
contract StandardToken is ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public override totalSupply;
    mapping(address => mapping(address => uint256)) public override allowance;
    mapping(address => uint256) public override balanceOf;

    constructor(
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) {
        totalSupply = _initialAmount;
        balanceOf[msg.sender] = _initialAmount;
        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _decimalUnits;
    }

    function transfer(address dst, uint256 amount) external virtual override returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");

        balanceOf[msg.sender] = balanceOf[msg.sender] - amount;
        balanceOf[dst] = balanceOf[dst] + amount;
        emit Transfer(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external virtual override returns (bool) {
        require(allowance[src][msg.sender] >= amount, "Insufficient allowance");
        require(balanceOf[src] >= amount, "Insufficient balance");

        allowance[src][msg.sender] = allowance[src][msg.sender] - amount;
        balanceOf[src] = balanceOf[src] - amount;
        balanceOf[dst] = balanceOf[dst] + amount;
        emit Transfer(src, dst, amount);
        return true;
    }

    function approve(address _spender, uint256 amount) external virtual override returns (bool) {
        allowance[msg.sender][_spender] = amount;
        emit Approval(msg.sender, _spender, amount);
        return true;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "./ERC20Base.sol";

interface ERC20 is ERC20Base {
    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

interface ERC20Base {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function totalSupply() external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function balanceOf(address who) external view returns (uint256);
}