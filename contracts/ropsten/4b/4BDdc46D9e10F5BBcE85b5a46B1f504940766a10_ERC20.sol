// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC20 token contract with EIP20 compatibility
/// @author Anton Konstantinov
contract ERC20 {
    address private owner;
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint8 public decimals;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    /// @notice Deploys the contract with the initial parameters(name, symbol, initial supply, decimals)
    /// @param _name Name of the token
    /// @param _symbol Symbol of the token
    /// @param _initialSupply Initial supply of the token,
    /// @param _decimals The number of decimals used by the token
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        uint8 _decimals
    ) {
        owner = msg.sender;

        name = _name;
        symbol = _symbol;
        totalSupply = _initialSupply;
        decimals = _decimals;

        _balances[owner] += _initialSupply;
    }

    modifier ownerOnly {
        require(msg.sender == owner, "Permission denied");
        _;
    }

    /// @notice transfer event
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /// @notice approval event
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    /// @param _of address of the token holder
    /// @return balance of the address
    function balanceOf(address _of) external view returns (uint256) {
        return _balances[_of];
    }

    /// @notice allowance of the transfer tokens from one address to another
    /// @param _spender who can spend the tokens
    /// @return Returns a boolean value indicating whether the operation succeeded.
    function approve(address _spender, uint256 _value) external returns (bool) {
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }


    /// @notice Returns the remaining number of tokens that spender will be allowed to spend on behalf of owner through transferFrom.
    function allowance(address _owner, address _spender) external view returns (uint256) {
        return _allowances[_owner][_spender];
    }

    /// @notice Moves amount tokens from the caller’s account to recipient
    /// @return Returns a boolean value indicating whether the operation succeeded.
    function transfer(address _to, uint256 _value) external returns (bool) {
        address from = msg.sender;
        uint256 fromBalance = _balances[from];

        require(fromBalance >= _value, "ERC20: transfer amount exceeds balance");

        _balances[from] = fromBalance - _value;
        _balances[_to] += _value;

        emit Transfer(from, _to, _value);

        return true;
    }

    /// @notice Moves amount tokens from sender to recipient using the allowance mechanism.
    /// @return Returns a boolean value indicating whether the operation succeeded.
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool) {
        require(_allowances[_from][msg.sender] >= _value, "ERC20: insufficient allowance");
        require(_balances[_from] >= _value, "ERC20: insufficient balance");

        _balances[_from] -= _value;
        _balances[_to] += _value;
        _allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);

        return true;
    }

    /// @notice Creates amount tokens and assigns them to account, increasing the total supply.
    /// @return Returns a boolean value indicating whether the operation succeeded.
    function mint(address _to, uint256 _value) external ownerOnly returns (bool) {
        _balances[_to] += _value;
        totalSupply += _value;
        emit Transfer(address(0), _to, _value);

        return true;
    }

    /// @notice Destroys amount tokens from account, reducing the total supply.
    /// @return Returns a boolean value indicating whether the operation succeeded.
    function burn(address _of, uint256 _value) external ownerOnly returns (bool) {
        require(_balances[_of] >= _value, "ERC20: burn amount exceeds balance");

        _balances[_of] -= _value;
        totalSupply -= _value;
        emit Transfer(_of, address(0), _value);

        return true;
    }


}