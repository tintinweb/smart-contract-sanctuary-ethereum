pragma solidity 0.4.24;

// ================= Ownable Contract start =============================
/*
 * Ownable
 *
 * Assign contract to an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */
contract Ownable {
    address public owner;

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}
// ================= Ownable Contract end ===============================

// ================= SafeMath Contract start ============================
contract SafeMath {

    function safeAdd(uint256 x, uint256 y) internal returns (uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns (uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns (uint256) {
        uint256 z = x * y;
        assert((x == 0) || (z / x == y));
        return z;
    }

    function safeDiv(uint256 x, uint256 y) internal returns (uint256) {
        uint256 z = x / y;
        return z;
    }
}
// ================= SafeMath Contract end ==============================

// ================= ERC20 Token Contract start =========================
/*
 * ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    uint public totalSupply;

    function balanceOf(address who) constant returns (uint);

    function allowance(address owner, address spender) constant returns (uint);

    function transfer(address to, uint value) returns (bool ok);

    function transferFrom(address from, address to, uint value) returns (bool ok);

    function approve(address spender, uint value) returns (bool ok);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
// ================= ERC20 Token Contract end ===========================

// ================= Standard Token Contract start ======================
contract StandardToken is ERC20, SafeMath {

    /**
     * Fix for the ERC20 short address attack.
     */
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) returns (bool success){
        balances[msg.sender] = safeSubtract(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) returns (bool success) {
        var _allowance = allowed[_from][msg.sender];

        balances[_to] = safeAdd(balances[_to], _value);
        balances[_from] = safeSubtract(balances[_from], _value);
        allowed[_from][msg.sender] = safeSubtract(_allowance, _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }
}
// ================= Standard Token Contract end ========================

// ================= Pausable Token Contract start ======================
/**
 * @title Pausable
 * Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
    * modifier to allow actions only when the contract IS paused
    */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
    * modifier to allow actions only when the contract IS NOT paused
    */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
    * called by the owner to pause, triggers stopped state
    */
    function pause() onlyOwner whenNotPaused returns (bool) {
        paused = true;
        Pause();
        return true;
    }

    /**
    * called by the owner to unpause, returns to normal state
    */
    function unpause() onlyOwner whenPaused returns (bool) {
        paused = false;
        Unpause();
        return true;
    }
}
// ================= Pausable Token Contract end ========================

// ================= ABCToken contract start ============================
contract ABCToken is SafeMath, StandardToken, Pausable {
    string public name;
    string public symbol;
    uint256 public decimals;
    address public icoContract;
    bool public startTrading = false;

    function ABCToken(
        string _name,
        string _symbol,
        uint256 _decimals
    )
    {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /**
    * called by the owner to disable trading
    */
    function disableTrading() onlyOwner returns (bool) {
        startTrading = false;
        return true;
    }

    /**
    * called by the owner to enable trading
    */
    function enableTrading() onlyOwner returns (bool) {
        startTrading = true;
        return true;
    }

    function transfer(address _to, uint _value) whenNotPaused returns (bool success) {
        if (msg.sender != address(0)) {
            require(startTrading);
        }
        return super.transfer(_to,_value);
    }

    function approve(address _spender, uint _value) whenNotPaused returns (bool success) {
        return super.approve(_spender,_value);
    }

    function balanceOf(address _owner) constant returns (uint balance) {
        return super.balanceOf(_owner);
    }

    function setIcoContract(address _icoContract) onlyOwner {
        if (_icoContract != address(0)) {
            icoContract = _icoContract;
        }
    }

    function sell(address _recipient, uint256 _value) whenNotPaused returns (bool success) {
        assert(_value > 0);
        require(msg.sender == icoContract);

        balances[_recipient] += _value;
        totalSupply += _value;

        Transfer(0x0, owner, _value);
        Transfer(owner, _recipient, _value);
        return true;
    }
}
// ================= ABCToken contract end ==============================

// ================= ICO Contract Start =================================
contract ABCTokenContract is SafeMath, Pausable {
    ABCToken public ico;

    uint256 public tokenCreationCap;
    uint256 public totalSupply;

    address public ethFundDeposit;
    address public icoAddress;

    uint256 public tokenExchangeRate;

    event LogCreateICO(address from, address to, uint256 val);

    function CreateICO(address to, uint256 val) internal returns (bool success) {
        LogCreateICO(0x0, to, val);
        return ico.sell(to, val);
    }

    function ABCTokenContract(
        address _ethFundDeposit,
        address _icoAddress,
        uint256 _tokenCreationCap,
        uint256 _tokenExchangeRate
    )
    {
        ethFundDeposit = _ethFundDeposit;
        icoAddress = _icoAddress;
        tokenCreationCap = _tokenCreationCap;
        tokenExchangeRate = _tokenExchangeRate;
        ico = ABCToken(icoAddress);
    }

    function () payable {
        createTokens(msg.sender, msg.value);
    }

    function totalEtherHasBeenReceived() public view returns (uint256) {
        return address(ethFundDeposit).balance;
    }

    /// accepts ETH and creates new ICO tokens.
    function createTokens(address _beneficiary, uint256 _value) internal whenNotPaused {
        require (tokenCreationCap > totalSupply);

        uint256 tokens = safeMult(_value, tokenExchangeRate);
        uint256 checkedSupply = safeAdd(totalSupply, tokens);

        if (tokenCreationCap < checkedSupply) {
            uint256 tokensToAllocate = safeSubtract(tokenCreationCap, totalSupply);
            uint256 tokensToRefund   = safeSubtract(tokens, tokensToAllocate);
            totalSupply = tokenCreationCap;
            uint256 etherToRefund = tokensToRefund / tokenExchangeRate;

            require(CreateICO(_beneficiary, tokensToAllocate));
            msg.sender.transfer(etherToRefund);
            ethFundDeposit.transfer(this.balance);
            return;
        }

        totalSupply = checkedSupply;

        require(CreateICO(_beneficiary, tokens));
        ethFundDeposit.transfer(this.balance);
    }
}
// ================= ICO Contract End ===================================