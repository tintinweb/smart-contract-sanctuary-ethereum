pragma solidity ^0.8.0;


contract Token {
    string public name = "Crypton ERC-20 task";
    string public symbol = "CET";
    uint8 public decimals = 4;

    // The fixed amount of tokens stored in an unsigned integer type variable.
    uint256 public totalSupply = 10000000;

    // An address type variable is used to store ethereum accounts.
    address public owner;

    // A mapping is a key/value map. Here we store each account balance.
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) private _allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    /**
     * Contract initialization.
     *
     * The `constructor` is executed only once when the contract is created.
     */
    constructor() {
        // The totalSupply is assigned to transaction sender, which is the account
        // that is deploying the contract.
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }


    /**
     * Read only function to retrieve the token balance of a given account.
     *
     * The `view` modifier indicates that it doesn't modify the contract's
     * state, which allows us to call it without executing a transaction.
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }


    /**
     * A function to transfer tokens.
     *
     * The `external` modifier makes a function *only* callable from outside
     * the contract.
     */
    function transfer(address to, uint256 amount) public returns (bool){
        // Check if the transaction sender has enough tokens.
        // If `require`'s first argument evaluates to `false` then the
        // transaction will revert.
        require(balances[msg.sender] >= amount, "Not enough tokens");

        // Transfer the amount.
        balances[msg.sender] -= amount;
        balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }


    /**
    * Transfers _value amount of tokens from address _from to address _to, and MUST fire the Transfer event.
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(balances[_from] >= _value, "Not enough tokens");
        require(_allowance[_from][msg.sender] >= _value, "Not allowed");

        balances[_from] -= _value;
        balances[_to] += _value;
        _allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }


    /**
    * Allows _spender to withdraw from your account multiple times, up to the _value amount.
    * If this function is called again it overwrites the current allowance with _value.
    */
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(balances[msg.sender] >= _value, "Not enough tokens");

        _allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    /**
    * Returns the amount which _spender is still allowed to withdraw from _owner.
    */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return _allowance[_owner][_spender];
    }

    function _burn(uint256 _value) public returns (bool) {
        require(owner == msg.sender, "Not owner");

        totalSupply -= _value;
        return true;
    }

    function _mint(uint256 _value) public returns (bool) {
        require(owner == msg.sender, "Not owner");

        totalSupply += _value;
        return true;
    }

}