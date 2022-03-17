/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract TokenPoken {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public owner;
    uint256 private _maxSupply;
    uint256 private _availableSupply;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(uint256 tokenSupply) {
        owner = msg.sender;
        _maxSupply = tokenSupply;
        _availableSupply = tokenSupply;
    }

    function name() public pure returns (string memory) {
        return "TokenPoken";
    }

    function symbol() public pure returns (string memory) {
        return "TPK";
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _maxSupply - _availableSupply;
    }

    /**
        Return amount of tokent available to mint
     */
    function availableSupply() public view returns (uint256) {
        return _availableSupply;
    }

    function balanceOf(address _address) public view returns (uint256 balance) {
        return _balances[_address];
    }

    function mint(address _to, uint256 _value) external {
        require(msg.sender == owner, "Only owner can mint");
        require(_value <= _availableSupply, "Not enought tokens available to mint");
        _availableSupply -= _value;
        _balances[_to] += _value;
        
        emit Transfer(address(0), _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function _transfer(address _from, address _to, uint256 _value) private returns (bool success) {
        require(_balances[_from] >= _value, "Transfer amount exceeds balance");
        _balances[_from] -= _value;
        _balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_allowances[_from][msg.sender] >= _value, "Insufficient allowance");
        _allowances[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return _allowances[_owner][_spender];
    }

    function burn(address _from, uint256 _value) external {
        require(msg.sender == owner, "Only owner can burn");
        require(_balances[_from] >= _value, "Target address dont ahve enought tokens");
        
        _availableSupply += _value;
        _balances[_from] -= _value;
        
        emit Transfer(_from, address(0), _value);
    }

}