/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Coin20 {
    // Custom struct stuff
    struct Profile{
        string name;
        int favoriteNumber;
        bool isDating;
    }

    mapping (address => Profile) public profiles;

    function getName(address _addr) public view returns (string memory) {
        return profiles[_addr].name;
    }
    function getFavoriteNumber(address _addr) public view returns (int) {
        return profiles[_addr].favoriteNumber;
    }
    function getIsDating(address _addr) public view returns (bool) {
        return profiles[_addr].isDating;
    }

    function createProfile(string memory _name, int _favoriteNumber, bool _isDating) public {
        profiles[msg.sender] = Profile(_name, _favoriteNumber, _isDating);
        emit CreateProfile(msg.sender, _name, _favoriteNumber, _isDating);
    }

    function removeProfile() public {
        delete profiles[msg.sender];
        emit RemoveProfile(msg.sender);
    }

    event CreateProfile(address indexed _from, string name, int favoriteNumbeer, bool isDating);
    event RemoveProfile(address indexed _from);

    // ERC20 stuff + minting
    address public minter;
    mapping (address => uint256) public balances;
    uint256 private _totalSupply;

    mapping (address => mapping (address => uint256)) _allowance;

    constructor() {
        minter = msg.sender;
    }

    function mint(address receiver, uint amount) public {
        require(msg.sender == minter, "Only creator can mint coins");
        balances[receiver] += amount;
        _totalSupply += amount;
    }

    function name() public view returns (string memory) {
        return "MyToken";
    }

    function symbol() public view returns (string memory) {
        return "C20";
    }

    function decimals() public view returns (uint8) {
        return 0;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_value <= balances[msg.sender], "Not enough money for transfer");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balances[_from], "Not enough money for transfer");
        require(_value <= _allowance[_from][msg.sender], "Not enough allowance for transfer");

        balances[_from] -= _value;
        balances[_to] += _value;
        _allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        _allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return _allowance[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}