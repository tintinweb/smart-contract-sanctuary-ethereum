/**
 *Submitted for verification at Etherscan.io on 2023-03-17
*/

pragma solidity 0.4.17;

/*  
 *   Math operations with safety checks that throw on error
 */
library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/*
 *  The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    address public newOwner;
	
    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function changeOwner(address _owner) onlyOwner public {
        require(_owner != 0);
        newOwner = _owner;
    }
    
    function confirmOwner() public {
        require(newOwner == msg.sender);
        owner = newOwner;
        delete newOwner;
    }
}

/*
 * Simpler version of ERC20 interface
 *  see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
    uint256 public _totalSupply;
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256 balance);
    function transfer(address to, uint value) public returns (bool success);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

/*
 * ERC20 interface
 *  see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256 remaining);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/*
 *  Pausable
 *  Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /*
    *  Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused);
    _;
    }

    /*
    *  Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused);
    _;
    }

    /*
    * called by the owner to pause, triggers stopped state
    */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

    /*
    *  called by the owner to unpause, returns to normal state
    */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

/*
 *  Basic token
 *  Basic version of StandardToken, with no allowances.
 */
contract BasicToken is Ownable, Pausable, ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;

    /*
    *  Fix for the ERC20 short address attack.
    */
    modifier onlyPayloadSize(uint256 size) {
        require(!(msg.data.length < size + 4));
        _;
    }

    /*
    *  transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) whenNotPaused returns (bool success) {
        require (!(_to == 0x0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /*
    *  Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}


/*
 *  Implementation of the basic standard token.
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract StandardToken is BasicToken, ERC20 {

    mapping (address => mapping (address => uint256)) public allowed;
    uint256 public constant maxtet =100000000000;  // maximum token TET = 10 000 000, 0000 (digitals=4)

    /*
    *  Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _value) public  onlyPayloadSize(3 * 32) whenNotPaused returns (bool success) {
        require (!(_to == 0x0));
        var _allowance = allowed[_from][msg.sender];

        if (_allowance < maxtet) {
            allowed[_from][msg.sender] = _allowance.sub(_value);
        }
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    /*
    *  Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool success) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /*
    * Function to check the amount of tokens than an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint specifying the amount of tokens still available for the spender.
    */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}


contract BlackList is Ownable, BasicToken {

    //  Getters to allow the same blacklist to be used also by other contracts 
    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    mapping (address => bool) public isBlackListed;
    
    function addBlackList (address _User) public onlyOwner {
        isBlackListed[_User] = true;
        AddedBlackList(_User);
    }

    function removeBlackList (address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        RemovedBlackList(_clearedUser);
    }

    event AddedBlackList(address _user);

    event RemovedBlackList(address _user);

}


contract Tettoken is  StandardToken, BlackList {

    string public name;
    string public symbol;
    uint8 public decimals;

    function name() public view returns (string) {
        return name;
    }

    function symbol() public view returns (string) {
        return symbol;
    }

    function decimals() public view returns (uint8) {
        return decimals;
    }

    //  The contract can be initialized with a number of tokens
    //  All the tokens are deposited to the owner address
    //
    // @param _balance Initial supply of the contract
    // @param _name Token Name
    // @param _symbol Token symbol
    // @param _decimals Token decimals
    function Tettoken(uint256 _initialSupply, string _name, string _symbol, uint8 _decimals) public {
        require( _initialSupply <= maxtet); // maximum token TET = 10 000 000, 0000 (digitals=4)
        _totalSupply = _initialSupply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        balances[owner] = _initialSupply;
    }

    function totalSupply() public view returns (uint256) {
            return _totalSupply;
    }

    function tetwrite(uint256 _newts) public onlyOwner returns (uint256 tetts) {
        require( _newts <= maxtet);
        require( _newts != _totalSupply);

        if (_newts > _totalSupply) {
               balances[owner] = balances[owner].add(_newts - _totalSupply);
        } else {
                  require  (balances[owner] >= ( _totalSupply - _newts ));
                balances[owner] = balances[owner].sub(_totalSupply - _newts)  ;
        }
         _totalSupply = _newts ;
         Tetwrite(_totalSupply);
         return _totalSupply ;
    }


    // Issue a new amount of tokens
    // these tokens are deposited into the owner address
    //
    // @param _amount Number of tokens to be issued
    function issue(uint256 _amount) public onlyOwner returns (bool success) {
        require(_totalSupply + _amount <= maxtet); 
        require(_totalSupply + _amount > _totalSupply);
        require(balances[owner] + _amount > balances[owner]);

        balances[owner] += _amount;
        _totalSupply += _amount;
        Issue(_amount);
        return true;
    }

    // Redeem tokens.
    // These tokens are withdrawn from the owner address
    // if the balance must be enough to cover the redeem
    // or the call will fail.
    // @param _amount Number of tokens to be issued
    function redeem(uint256 _amount) public onlyOwner returns (bool success) {
        require(_totalSupply >= _amount);
        require(balances[owner] >= _amount);

        _totalSupply -= _amount;
        balances[owner] -= _amount;
        Redeem(_amount);
        return true;
    }

    event Issue(uint256 _amount);

    event Redeem(uint256 _amount);

    event Tetwrite(uint256 _tetts);
}