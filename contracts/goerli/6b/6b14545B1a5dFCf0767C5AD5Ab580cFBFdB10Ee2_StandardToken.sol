// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "./BasicToken.sol";
import "./ERC20.sol";

abstract contract tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) virtual public;
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    /* Public variables of the token */
    string public _standard = 'ERC20';

    string public _name;

    string public _symbol;

    uint8 public _decimals;

    uint256 public _totalSupply;

    address public _owner;

    mapping (address => mapping (address => uint256)) internal allowed;

    constructor (
        uint256 initialSupply,
        string memory tokenName,
        uint8 decimalUnits,
        string memory tokenSymbol
    ) {
        balances[msg.sender] = initialSupply;
        // Give the creator all initial tokens
        _totalSupply = initialSupply;
        // Update total supply
        _name = tokenName;
        // Set the name for display purposes
        _symbol = tokenSymbol;
        // Set the symbol for display purposes
        _decimals = decimalUnits;
        // Amount of decimals for display purposes

        _owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != _owner) revert();
        _;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = SafeMath.sub(balances[_from], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public override returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function multiApprove(address[] memory _spender, uint256[] memory _value) public returns (bool){
        require(_spender.length == _value.length);
        for(uint i=0;i<=_spender.length;i++){
            allowed[msg.sender][_spender[i]] = _value[i];
            emit Approval(msg.sender, _spender[i], _value[i]);
        }
        return true;
    }
    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return allowed[owner][spender];
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = SafeMath.add(allowed[msg.sender][_spender], _addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function multiIncreaseApproval(address[] memory _spender, uint[] memory _addedValue) public returns (bool) {
        require(_spender.length == _addedValue.length);
        for(uint i=0;i<=_spender.length;i++){
            allowed[msg.sender][_spender[i]] = SafeMath.add(allowed[msg.sender][_spender[i]], _addedValue[i]);
            emit Approval(msg.sender, _spender[i], allowed[msg.sender][_spender[i]]);
        }
        return true;
    }
    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = SafeMath.sub(oldValue, _subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function multiDecreaseApproval(address[] memory _spender, uint[] memory _subtractedValue) public returns (bool) {
        require(_spender.length == _subtractedValue.length);
        for(uint i=0;i<=_spender.length;i++){
            uint oldValue = allowed[msg.sender][_spender[i]];
            if (_subtractedValue[i] > oldValue) {
                allowed[msg.sender][_spender[i]] = 0;
            } else {
                allowed[msg.sender][_spender[i]] = SafeMath.sub(oldValue, _subtractedValue[i]);
            }
            emit Approval(msg.sender, _spender[i], allowed[msg.sender][_spender[i]]);
        }
        return true;
    }

    /* Approve and then comunicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public
    returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, _owner, _extraData);
            return true;
        }
    }

}