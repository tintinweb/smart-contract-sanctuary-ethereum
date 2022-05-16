/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

// import "./interfaces/IERC20.sol";

/// @title A Token based on IERC20
/// @author Harmony-AT
/// @notice You can use this contract to create a IERC20 Token
/// @dev Custom implementation of IERC20 with custom minting logic
contract BLXToken {
    uint256 private constant MAX_UINT256 = 2**256 - 1;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

    string private _name;
    uint8 private _decimals;
    string private _symbol;
    address private _ownerAddress;
    uint256 private _totalSupply;

    constructor(
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) {
        balances[msg.sender] = _initialAmount; // Give the creator all initial tokens
        _totalSupply = _initialAmount; // Update total supply
        _name = _tokenName; // Set the name for display purposes
        _decimals = _decimalUnits; // Amount of decimals for display purposes
        _symbol = _tokenSymbol; // Set the symbol for display purposes
        _ownerAddress = msg.sender; // Set the address for owner the token
    }

     event Transfer(address indexed from, address indexed to, uint256 value);
     event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Name of the token
    /// @dev Return the name of the token
    function name() external view returns (string memory) {
        return _name;
    }

    /// @notice Decimals of the token
    /// @dev Return Decimals of the token
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /// @notice Symbol of the token
    /// @dev Return symbol of the token
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /// @notice Total supply of token
    /// @dev Return total supply of token
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function getAddress() external view returns (address){
        return address(this);
    }

    /// @notice Mint an amount of token to the contract owner's balance and total supply
    /// @dev Emit a Transfer Event from zero address to owner's address, only contract owner can run
    /// @param amount The amount of token to mint
    function mint(uint256 amount) external virtual {
        require(_ownerAddress != address(0), "ERC20: mint to the zero address");
        require(
            _ownerAddress == msg.sender,
            "The current address is not owner of the Token"
        );
        _totalSupply += amount;
        balances[_ownerAddress] += amount;
        emit Transfer(address(0), _ownerAddress, amount);
    }

    /// @notice Transfer token from this address to another address
    /// @dev Emit a Transfer Event from sender to _to address
    /// @param _to Target address
    /// @param _value Amount of token to transfer
    /// @return success bool result of the transfer
    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        require(balances[msg.sender] >= _value, "Not enough tokens");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /// @notice Transfer token from an address to another address
    /// @dev Emit a Transfer Event with _value token from _from to _to
    /// @param _from _from Address to get token from
    /// @param  _to Address to receive token
    /// @param _value Amount of token
    /// @return success bool result of the transfer
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        uint256 allowanceValue = allowed[_from][msg.sender];
        require(
            balances[_from] >= _value && allowanceValue >= _value,
            "not allow amount more than value send"
        );
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

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }

}