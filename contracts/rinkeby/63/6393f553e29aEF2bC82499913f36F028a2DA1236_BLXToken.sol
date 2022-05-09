/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

// TODO: Implement IERC20.sol interface and make the token mintable
contract BLXToken {
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    string private _name;
    uint8 private _decimals;
    string private _symbol;
    address private _ownerAddress;
    uint256 private _totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


    constructor( uint256 _initialAmount, string memory _tokenName, uint8 _decimalUnits, string memory _tokenSymbol) {
        balances[msg.sender] = _initialAmount;                // Give the creator all initial tokens
        _totalSupply = _initialAmount;                        // Update total supply
        _name = _tokenName;                                   // Set the name for display purposes
        _decimals = _decimalUnits;                            // Amount of decimals for display purposes
        _symbol = _tokenSymbol;                               // Set the symbol for display purposes
        _ownerAddress = msg.sender;                           // Set the address for owner the token
    }

    function name() external view returns (string memory){
        return _name;
    }

    function decimals() external view returns (uint8){
        return _decimals;
    }

    function symbol() external view returns (string memory){
        return _symbol;
    }

    function totalSupply() external view returns (uint256){
        return _totalSupply;
    }
    function mint(uint256 amount) external virtual {
        require(_ownerAddress != address(0), "ERC20: mint to the zero address");
        require(_ownerAddress == msg.sender, "The current address is not owner of the Token");
        _totalSupply += amount;
        balances[_ownerAddress] += amount;
        emit Transfer(address(0), _ownerAddress, amount);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "Not enough tokens");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowanceValue = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowanceValue >= _value, "not allow amount more than value send");
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowanceValue < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}