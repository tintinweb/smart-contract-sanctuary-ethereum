/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract XECoin {
    // Public properties
    string public name = "XE Coin";
    string public symbol = "XEE";
    uint8 public decimals = 4;
    uint256 public totalSupply = 777195450;

    // Creates array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // Generates public event on blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Generate public event on blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    // Notify clients about amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constructor
     *
     * Initializes contract with initial supply tokens to creator of the contract
     */
    constructor() {
        totalSupply = 777195450 * 10 ** uint256(4);  // Update total supply with decimal amount
        balanceOf[msg.sender] = totalSupply;         // Give creator all initial tokens
        name = "XE Coin";                            // Set name for display purposes
        symbol =  "XEE";                             // Set symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0x0));

        // Check if sender has enough
        require(balanceOf[_from] >= _value);

        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);

        // Save this for an assertion in future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];

        // Subtract from sender
        balanceOf[_from] -= _value;

        // Add same to recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);

        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to address of recipient
     * @param _value amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);

        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from address of sender
     * @param _to address of recipient
     * @param _value amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);

        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender address authorized to spend
     * @param _value max amount they can spend
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping contract about it
     *
     * @param _spender address authorized to spend
     * @param _value max amount they can spend
     * @param _extraData some extra information to send to approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);

        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from system irreversibly
     *
     * @param _value amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from system irreversibly on behalf of `_from`.
     *
     * @param _from address of sender
     * @param _value amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance

        balanceOf[_from] -= _value;                         // Subtract from targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);

        return true;
    }
}

interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external;
}