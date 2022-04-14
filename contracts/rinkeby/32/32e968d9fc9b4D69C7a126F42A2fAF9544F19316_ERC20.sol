// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./irc20.sol";

contract ERC20 is IERC20 {
    uint public override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;
    
    address public owner;
    string public name;
    string public symbol;
    uint8 public decimals;

    constructor (string memory _name, string memory _symbol, uint8 _decimals) {
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You are not allowed.");
        _;
    }

    function transfer(address _to, uint _amount) external override returns (bool) {
        require(_amount <= balanceOf[msg.sender], "The amount to withdraw is exceeded your balance.");
        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint _amount) external override returns (bool) {
        require(_amount <= balanceOf[_from], "The amount to withdraw is exceeded holder balance.");
        require(_amount <= allowance[_from][msg.sender], "You have no allowance for this amount");
        allowance[_from][msg.sender] -= _amount;
        balanceOf[_from] -= _amount;
        balanceOf[_to] += _amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }

    function approve(address _from, uint _amount) external override returns (bool) {
        allowance[msg.sender][_from] = _amount;
        emit Approval(msg.sender, _from, _amount);
        return true;
    }

    function mint(address _to, uint _amount) external override onlyOwner{
        balanceOf[_to] += _amount;
        totalSupply += _amount;
        emit Transfer(address(0), _to, _amount);
    }

    function burn(uint _amount) external override{
        require(_amount <= balanceOf[msg.sender], "The amount to burn is exceeded your balance.");
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        emit Transfer(msg.sender, address(0), _amount);
    }

    function burnFrom(address _from, uint _amount) external override onlyOwner{
        require(_amount <= balanceOf[_from], "The amount to burn is exceeded balance.");
        balanceOf[_from] -= _amount;
        totalSupply -= _amount;
        emit Transfer(_from, address(0), _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {

    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // Views funcs
    function totalSupply() external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);

    // Funcs
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function mint(address _to, uint256 _amount) external;
    function burn(uint256 _amount) external;
    function burnFrom(address _from, uint256 _amount) external;

}