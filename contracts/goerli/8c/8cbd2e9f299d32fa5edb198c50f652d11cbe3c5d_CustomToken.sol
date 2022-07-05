/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

pragma solidity 0.5.4;

/*
This Token Contract implements the standard token functionality (https://github.com/ethereum/EIPs/issues/20), the ERC223 functionality (https://github.com/ethereum/EIPs/issues/223) as well as the following OPTIONAL extras intended for use by humans.
In other words. This is intended for deployment in something like a Token Factory or Mist wallet, and then used by humans.
Imagine coins, currencies, shares, voting weight, etc.
Machine-based, rapid creation of many tokens would not necessarily need these extra features or will be minted in other manners.
1) Initial Finite Supply (upon creation one specifies how much is minted).
2) In the absence of a token registry: Optional Decimal, Symbol & Name.
.*/


interface Token {

    /// @return total amount of tokens
    function totalSupply() external view returns (uint256 supply);

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) external returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) external returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // Optionally implemented function to show the number of decimals for the token
    function decimals() external view returns (uint8 decimals);
}

/*
This implements ONLY the standard functions and NOTHING else.
For a token like you would want to deploy in something like Mist, see HumanStandardToken.sol.
If you deploy this, you won't have anything useful.
Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
.*/

contract StandardToken is Token {
    uint256 internal _total_supply;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) allowed;

    function transfer(address _to, uint256 _value) public returns (bool success) {
        //Default assumes totalSupply can't be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value)
        public
        returns (bool success)
    {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        require(_value > 0);
        if ((balances[_from] >= _value) && (allowed[_from][msg.sender] >= _value) && (_value > 0)) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
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

    function totalSupply() public view returns (uint256 supply) {
        return _total_supply;
    }
}


/// @title CustomToken
contract CustomToken is StandardToken {

    /*
     *  Token metadata
     */
    string public version = 'H0.1';       //human 0.1 standard. Just an arbitrary versioning scheme.
    string public name;
    string public symbol;
    uint8 public _decimals;
    uint256 public multiplier;

    address payable public owner_address;

    /*
     * Events
     */
    event Minted(address indexed _to, uint256 indexed _num);

    /*
     *  Public functions
     */
    /// @dev Contract constructor function.
    /// @param initial_supply Initial supply of tokens
    /// @param decimal_units Number of token decimals
    /// @param token_name Token name for display
    /// @param token_symbol Token symbol
    constructor(
        uint256 initial_supply,
        uint8 decimal_units,
        string memory token_name,
        string memory token_symbol
    )
        public
    {
        // Set the name for display purposes
        name = token_name;

        // Amount of decimals for display purposes
        _decimals = decimal_units;
        multiplier = 10**(uint256(decimal_units));

        // Set the symbol for display purposes
        symbol = token_symbol;

        // Initial supply is assigned to the owner
        owner_address = msg.sender;
        balances[owner_address] = initial_supply;
        _total_supply = initial_supply;
    }

    /// @notice Allows `num` tokens to be minted and assigned to `msg.sender`
    function mint(uint256 num) public {
        mintFor(num, msg.sender);
    }

    /// @notice Allows `num` tokens to be minted and assigned to `target`
    function mintFor(uint256 num, address target) public {
        balances[target] += num;
        _total_supply += num;

        emit Minted(target, num);

        require(balances[target] >= num);
        assert(_total_supply >= num);
    }

    /// @notice Transfers the collected ETH to the contract owner.
    function transferFunds() public {
        require(msg.sender == owner_address);
        require(address(this).balance > 0);

        owner_address.transfer(address(this).balance);
        assert(address(this).balance == 0);
    }

    function decimals() public view returns (uint8 decimals) {
        return _decimals;
    }
}