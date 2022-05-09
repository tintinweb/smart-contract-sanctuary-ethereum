// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IERC20Metadata.sol";

contract ERC20 is IERC20, IERC20Metadata{
    // Token received for 1 Eth payment
    uint256 public tokenPerEth;

    address payable public manager;
    // EIP-20 Standard
    string public symbol;
    // EIP-20 Standard
    uint8 public decimals;
    // EIP-20 Standard
    string public name;
    // EIP-20 Standard
    uint256 public totalSupply;
    // EIP-20 Standard
    mapping(address => uint256) public balanceOf;
    // EIP-20 Standard
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _tokenPerEth) public {
        manager = address(uint160(msg.sender));
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        tokenPerEth = _tokenPerEth;
    }

    modifier managerOnly() {
        require(msg.sender == manager, "ERC20: Contract manager restricted call");
        _;
    }

    function setTokenPerEth(uint256 _tokenPerEth) public managerOnly returns (bool){
        require(_tokenPerEth < tokenPerEth, "ERC20: Cannot set token per eth greater than or equal to the current token per eth");
        tokenPerEth = _tokenPerEth;
        return true;
    }

    // EIP-20 Standard
    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        require(balanceOf[msg.sender] >= _value, "ERC20: Cannot transfer as balance is low");
        require(_to != address(0), "ERC20: Cannot transfer to zero address");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // EIP-20 Standard
    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        require(_spender != address(0), "ERC20: Cannot approve a zero address");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // EIP-20 Standard
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_to != address(0), "ERC20: Cannot transfer to a zero address");
        require(allowance[_from][msg.sender] >= _value, "ERC20: Cannot transfer as allowance is low");
        require(balanceOf[_from] >= _value, "ERC20: Cannot transfer as balance is low");
        allowance[_from][msg.sender] -= _value;
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function mint(address _to)
        public
        payable
        returns (bool success)
    {
        require(_to != address(0), "ERC20: Cannot transfer to a zero address");
        uint256 _value = msg.value * tokenPerEth;
        totalSupply += _value;
        balanceOf[_to] += _value;
        manager.transfer(msg.value);
        emit Transfer(address(0), _to, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "ERC20: Cannot burn as balance is low");
        require(msg.sender != address(0), "ERC20: Cannot burn from zero address");
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "./IERC20.sol";

interface IERC20Metadata {
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns(uint256 balance);
    function transfer(address recipient, uint256 amount) external returns(bool success);
    function transferFrom(address owner, address recipient, uint256 amount) external returns(bool success);
    function allowance(address owner, address spender) external view returns(uint256 remaining);
    function approve(address spender, uint256 amount) external returns(bool success);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}