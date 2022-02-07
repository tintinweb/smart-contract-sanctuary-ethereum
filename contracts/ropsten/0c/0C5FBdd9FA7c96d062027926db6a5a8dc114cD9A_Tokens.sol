/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.8.0 <0.9.0; //No safemath needed


contract Ownable { //ERC173

    address public _owner;

    constructor() {
        _owner = msg.sender; //set the owner to the deployer of the contract
    }

    // Make sure a function can only be called by the owner of the contract
    modifier onlyOwner() {
        require(msg.sender == _owner, "You are not the owner of this contract");
        _;
    }

    /// @dev This emits when ownership of a contract changes. 
    event OwnershipTransferred(
        address indexed previousOwner, 
        address indexed newOwner
    );

    /// @notice Get the address of the owner    
    /// @return The address of the owner.
    function owner() view public returns(address) {
        return(_owner);
    }

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract 
    function transferOwnership(address _newOwner) public onlyOwner {
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
    }
}


contract Tokens is Ownable { //ERC20

    string private _name = "DAO MIP Token";
    string private _symbol = "DMT";
    uint8 private _decimals = 2;
    uint256 private _totalSupply = 100 * (10 ** _decimals);
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _frozen;
    mapping(address => uint256) private _locked;

    constructor() {
        _balances[_owner] += _totalSupply;
    }

    // make sure the caller of a function is not frozen
    modifier notFrozen(address _from) {
        require(!_frozen[_from], "This account is frozen");
        _;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function transfer(address _to, uint256 _value) public notFrozen(msg.sender) returns (bool) {
        require(_balances[msg.sender] >= _value, "Insufficient funds");
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value); 

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public notFrozen(_from) returns (bool) {
        require(_balances[_from] >= _value, "Insufficient funds");
        require(_allowances[_from][msg.sender] >= _value, "Insufficient allowance");
        _balances[_from] -= _value;
        _allowances[_from][msg.sender] -= _value;
        _balances[_to] += _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public notFrozen(msg.sender) returns (bool) {
        require(_balances[msg.sender] >= _value, "Insufficient funds");
        _allowances[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function increaseApproval(address _spender, uint256 _addedValue) public notFrozen(msg.sender) returns (bool) {
        require(_balances[msg.sender] >= _allowances[msg.sender][_spender] + _addedValue, "Insufficient funds");
        _allowances[msg.sender][_spender] += _addedValue;

        emit Approval(msg.sender, _spender, _allowances[msg.sender][_spender]);

        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue) public notFrozen(msg.sender) returns (bool) {
        require(_allowances[msg.sender][_spender] >= _subtractedValue, "Insufficient allowance");
        _allowances[msg.sender][_spender] -= _subtractedValue;

        emit Approval(msg.sender, _spender, _allowances[msg.sender][_spender]);

        return true;
    }

    function mint(uint256 _value) public onlyOwner returns (bool) {
        _balances[_owner] += _value;

        return true;
    }

    function burn(uint256 _value) public onlyOwner returns (bool) {
        _balances[_owner] -= _value;

        return true;
    }

    function revoke(address _from, uint256 _value) public onlyOwner returns (bool) {
        _balances[_from] -= _value;
        _balances[_owner] += _value;

        return true;
    }

    function freeze(address _from) public onlyOwner returns (bool) {
        _frozen[_from] = true;

        return true;
    }

    function unfreeze(address _from) public onlyOwner returns (bool) {
        _frozen[_from] = false;

        return true;
    }

    function lock(address _from, uint256 _end) public onlyOwner returns (bool) {
        _locked[_from] = _end;

        return true;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return _allowances[_owner][_spender];
    }

    function frozen(address _from) public view returns (bool) {
        return _frozen[_from];
    }

    function locked(address _from) public view returns (uint256) {
        return _locked[_from];
    }
}