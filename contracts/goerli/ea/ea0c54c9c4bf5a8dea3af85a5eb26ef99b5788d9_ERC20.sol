/**
 *Submitted for verification at Etherscan.io on 2022-11-16
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

 /// @notice This contact follows the standard for ERC-20 fungible tokens
 /// @dev Comment follow the Ethereum ´Natural Specification´ language format (´natspec´)
 /// Referencia: https://docs.soliditylang.org/en/v0.8.16/natspec-format.html  
contract ERC20 {

    /// STATE VARIABLES
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public maxSupply;

    /// STATE MAPPINGS
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    /// EVENTS
    /// @notice Trigger when tokens are transferred
    /// @dev On new tokens creation, trigger with the `from` address set to zero address
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    /// @notice Trigger on any successful call to `approve` method
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /// @notice Trigger on any successful call to `burn` method
    event Burn(address indexed _from, address indexed _commandedBy, uint256 _value);

    /**
     * @notice Initialize the state of the contract
     * @dev Throw if `_name` is empty. Message: "constructor - Invalid parameter: _name"
     * @dev Throw if `_symbol` is empty. Message: "constructor - Invalid parameter: _symbol"
     * @param _name The name of the token
     * @param _symbol The symbol of the token
     * @param _maxSupply The maximum supply of the token. Zero for unlimited emition
     */
    constructor(string memory _name, string memory _symbol, uint256 _maxSupply) {
        require(bytes(_name).length != 0, "constructor - Invalid parameter: _name");
        require(bytes(_symbol).length != 0, "constructor - Invalid parameter: _symbol");

        name = _name;
        symbol = _symbol;
        maxSupply = _maxSupply;
        decimals = 18; // Same as ether
    }

    /// EXTERNAL FUNCTIONS

    /**
     * @notice Transfers `_value` amount of tokens to address `_to`. On success must fire the `Transfer` event.
     * @dev Throw if `_to` is zero address. Message: "transfer - Invalid parameter: _to"
     * @dev Throw if `_to` is sender account. Message: "transfer - Invalid recipient, same as remittent"
     * @dev Throw if `_value` is zero. Message: "transfer - Invalid parameter: _value"
     * @dev Throw if remittent account has insufficient balance. Message: "transfer - Insufficient balance"
     * @param _to It is the recipient account address
     * @param _value It is the amount of tokens to transfer.
     */
    function transfer(address _to, uint256 _value) external {
        require(_to != address(0), "transfer - Invalid parameter: _to");
        require(_to != msg.sender, "transfer - Invalid recipient, same as remittent");
        require(_value != 0, "transfer - Invalid parameter: _value");
        require(balanceOf[msg.sender] >= _value, "transfer - Insufficient balance");

        balanceOf[_to] += _value;
        balanceOf[msg.sender] -= _value;

        emit Transfer(msg.sender, _to, _value);
    }

    /**
     * @notice Transfers `_value` amount of tokens from address `_from` to address `_to`. 
     * On success must fire the `Transfer` event.
     * @dev Throw if `_from` is zero address. Message: "transferFrom - Invalid parameter: _from"
     * @dev Throw if `_to` is zero address. Message: "transferFrom - Invalid parameter: _to"
     * @dev Throw if `_to` is the same as `_from` account. Message: "transferFrom - Invalid recipient, same as remittent"
     * @dev Throw if `_value` is zero. Message: "transferFrom - Invalid parameter: _value"
     * @dev Throw if `_from` account has insufficient balance. Message: "transferFrom - Insufficient balance"
     * @dev Throws if `msg.sender` is not the current owner or an approved address with permission to spend the balance of the '_from' account
     * Message: "transferFrom - Insufficent allowance"
     * @param _from It is the remittent account address
     * @param _to It is the recipient account address
     * @param _value It is the amount of tokens to transfer.
     */
    function transferFrom(address _from, address _to, uint256 _value) external {
        require(_from != address(0), "transferFrom - Invalid parameter: _from");
        require(_to != address(0), "transferFrom - Invalid parameter: _to");
        require(_to != _from, "transferFrom - Invalid recipient, same as remittent");
        require(_value != 0, "transderFrom - Invalid parameter: _value");
        require(balanceOf[_from] >= _value, "transferFrom - Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "transferFrom - Insufficient allowance");

        allowance[_from][msg.sender] -= _value;
        balanceOf[_from] -= _value;
        balanceOf[_to] -= _value;

        emit Transfer(_from, _to, _value);
    }

    /**
     * @notice Allows `_spender` to withdraw from sender account multiple times, up to the `_value` amount
     * On success must fire the `Approval` event.
     * @dev If this function is called multiple times it overwrites the current allowance with `_value`
     * @dev Throw if allowance tries to be set to a new value, higher than zero, for the same spender, 
     * with a current allowance different that zero. Message: "approve - Invalid allowance amount. Set to zero first"
     * @dev Throw if `_spender` is zero address. Message: "approve - Invalid parameter: _spender"
     * @dev Throw if `_value` exceeds the sender's balance. Message: "approve - Insufficient balance"
     * @param _spender It is the spender account address
     * @param _value It is the allowance amount.
     */
    function approve(address _spender, uint256 _value) external {
        require(allowance[msg.sender][_spender] <= 0, "approve - Invalid allowance amount. Set to zero first");
        require(_spender != address(0), "approve - Invalid parameter: _spender");
        require(balanceOf[_spender] >= _value, "approve - Insufficient balance");

        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
    }

    /**
     * @notice Issues a new amount of tokens in exchange for ethers at a parity of 1 to 1
     * @dev Throw if msg.value is zero. Message: "mint - Invalid ether amount"
     * @dev Throw if `_recipient` is zero address. Message: "mint - Invalid parameter: _recipient"
     * @dev Throw if total supply overcame the maximum supply. Message: "mint - Total supply exceeds maximum supply"
     * @param _recipient It is the recipient account for the new tokens
     */
    function mint(address _recipient) external {
        require(msg.sender != address(0), "mint - Invalid ether amount");
        require(_recipient != address(0), "mint - Invalid parameter: _recipient");
        require(totalSupply <= maxSupply, "mint - Total supply exceeds maximun supply");

        balanceOf[_recipient] += 1;
        totalSupply += 1;

        emit Transfer(address(0), _recipient, 1);
    }

    /**
     * @notice Returns ethers in exchange for burning an amount of tokens from '_from' account, at a parity of 1 to 1
     * @dev Throw if `_from` is zero address. Message: "burn - Invalid parameter: _from"
     * @dev Throw if `_value` is zero. Message: "burn - Invalid parameter: _value"
     * @dev Throw if `_from` account has insufficient tokens to burn. Message: "burn - Insufficient balance"
     * @dev Throw if sender is not allowed to spend balance from `_from` account.
     * Message: "burn - Insufficent allowance"
     * @param _from It is the address of the account from which tokens will be burned
     * @param _value It is the number of new tokens to be burned
     */
    function burn(address _from, uint256 _value) external {
        require(_from != address(0), "burn - Invalid parameter: _from");
        require(_value != 0, "burn - Invalid parameter: _value");
        require(balanceOf[_from] < _value, "burn - Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "burn - Insufficient allowance");

        allowance[_from][msg.sender] -= _value;
        balanceOf[_from] -= _value;
        totalSupply -= _value;

        emit Transfer(_from, address(0), _value);
    }
}