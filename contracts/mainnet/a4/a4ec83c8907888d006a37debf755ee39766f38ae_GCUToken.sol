/**
 *Submitted for verification at Etherscan.io on 2022-10-31
*/

pragma solidity ^0.4.19;

/*
--------------------------------------------------------------------------------
The GCU Token Smart Contract

ERC20: https://github.com/ethereum/EIPs/issues/20
ERC223: https://github.com/ethereum/EIPs/issues/223

MIT Licence
--------------------------------------------------------------------------------
*/

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // assert(_b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
        return _a / _b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_b <= _a);
        return _a - _b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        assert(c >= _a);
        return c;
    }
}

contract ERC223Interface {
    uint public totalSupply_;
    function balanceOf(address who) view returns (uint);
    function transfer(address to, uint value) returns (bool);
    function transfer(address to, uint value, bytes data)  returns (bool);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

/**
 * @dev Standard ERC223 function that will handle incoming token transfers.
 *
 * param _from  Token sender address.
 * param _value Amount of tokens.
 * param _data  Transaction metadata.
 */
contract ContractReceiver {
    function tokenFallback(address _from, uint _value, bytes _data) {
        _from;
        _value;
        _data;
    }
}

contract GCUToken is ERC223Interface {
    using SafeMath for uint256;

    /* Contract Constants */
    string public constant _name = "Global Currency Unit";
    string public constant _symbol = "GCU";
    uint8 public constant _decimals = 18;

    /* Contract Variables */
    address public owner;
    uint256 public totalSupply_;

    mapping(address => uint256) public balances;
    mapping(address => mapping (address => uint256)) public allowed;

    /*88 888 888 000*/
    /* Constructor initializes the owner's balance and the supply  */
    constructor (uint256 _amount, address _initialWallet) {
        owner = _initialWallet;
        totalSupply_ = _amount * (uint256(10) ** _decimals);
        balances[_initialWallet] = totalSupply_;

        emit Transfer(0x0, _initialWallet, totalSupply_);
    }

    /* ERC20 Events */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed to, uint256 value);

    /* ERC223 Events */
    event Transfer(address indexed from, address indexed to, uint value, bytes data);

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
     * @dev Returns balance of the `_owner`.
     *
     * @param _address   The address whose balance will be returned.
     * @return balance Balance of the `_owner`.
     */
    function balanceOf(address _address) view returns (uint256 balance) {
        return balances[_address];
    }

    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      This function works the same with the previous one
     *      but doesn't contain `_data` param.
     *      Added due to backwards compatibility reasons.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     */
    function transfer(address _to, uint _value) returns (bool success) {
        if (balances[msg.sender] >= _value
        && _value > 0
        && balances[_to] + _value > balances[_to]) {
            bytes memory empty;
            if(isContract(_to)) {
                return transferToContract(_to, _value, empty);
            } else {
                return transferToAddress(_to, _value, empty);
            }
        } else {
            return false;
        }
    }

    /* Withdraws to address _to form the address _from up to the amount _value */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value
        && allowed[_from][msg.sender] >= _value
        && _value > 0
        && balances[_to] + _value > balances[_to]) {
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    /* Allows _spender to withdraw the _allowance amount form sender */
    function approve(address _spender, uint256 _allowance) returns (bool success) {
        allowed[msg.sender][_spender] = _allowance;
        Approval(msg.sender, _spender, _allowance);
        return true;
    }

    /* Checks how much _spender can withdraw from _owner */
    function allowance(address _owner, address _spender) view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /* ERC223 Functions */
    /* Get the contract constant _name */
    function name() view returns (string name) {
        return _name;
    }

    /* Get the contract constant _symbol */
    function symbol() view returns (string symbol) {
        return _symbol;
    }

    /* Get the contract constant _decimals */
    function decimals() view returns (uint8 decimals) {
        return _decimals;
    }

    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      Invokes the `tokenFallback` function if the recipient is a contract.
     *      The token transfer fails if the recipient is a contract
     *      but does not implement the `tokenFallback` function
     *      or the fallback function to receive funds.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     * @param _data  Transaction metadata.
     */
    function transfer(address _to, uint _value, bytes _data) returns (bool success) {
        if (balances[msg.sender] >= _value
        && _value > 0
        && balances[_to] + _value > balances[_to]) {
            if(isContract(_to)) {
                return transferToContract(_to, _value, _data);
            } else {
                return transferToAddress(_to, _value, _data);
            }
        } else {
            return false;
        }
    }

    /* Transfer function when _to represents a regular address */
    function transferToAddress(address _to, uint _value, bytes _data) internal returns (bool success) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }

    /* Transfer function when _to represents a contract address, with the caveat
    that the contract needs to implement the tokenFallback function in order to receive tokens */
    function transferToContract(address _to, uint _value, bytes _data) internal returns (bool success) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        Transfer(msg.sender, _to, _value);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }

    /* Infers if whether _address is a contract based on the presence of bytecode */
    function isContract(address _address) internal returns (bool is_contract) {
        uint length;
        if (_address == 0) return false;
        assembly {
        length := extcodesize(_address)
        }
        if(length > 0) {
            return true;
        } else {
            return false;
        }
    }

    /* Stops any attempt to send Ether to this contract */
    function () {
        revert();
        //throw;
    }
}