/**
 *Submitted for verification at Etherscan.io on 2022-02-02
*/

pragma solidity 0.4.19;

contract Token {

    /// total amount of tokens
    uint public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public constant returns (uint balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public constant returns (uint remaining);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event Issue(uint amount);
    event Redeem(uint amount);
}

contract RegularToken is Token {
    address public owner;
    uint constant private MAX_UINT = 2**256 - 1;

    mapping (address => uint) public balances;
    mapping (address => mapping (address => uint)) public allowed;
    

    function RegularToken() public {
        owner = msg.sender;
    }

    /// @notice Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /// @notice Allows the current `owner` to transfer control of the contract to a `_newOwner`.
    /// @param _newOwner The address to transfer ownership to.
    function transferOwnership(address _newOwner) public onlyOwner {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }

    /// @notice Issue a new `_amount` of tokens, these tokens are deposited into the `owner` address
    /// @param _amount Number of tokens to be issued
    function issue(uint _amount) public onlyOwner {
        require(totalSupply + _amount > totalSupply);
        require(balances[owner] + _amount > balances[owner]);

        balances[owner] += _amount;
        totalSupply += _amount;
        Issue(_amount);
    }

    /// @notice Redeem tokens. These tokens are withdrawn from the owner address. if the balance must be enough to cover the redeem or the call will fail.
    /// @param _amount Number of tokens to be issued
    function redeem(uint _amount) public onlyOwner {
        require(totalSupply >= _amount);
        require(balances[owner] >= _amount);

        totalSupply -= _amount;
        balances[owner] -= _amount;
        Redeem(_amount);
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        //Default assumes totalSupply can't be over max (2^256 - 1).
        if (balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success)
    {
        uint allowance = allowed[_from][msg.sender];
        if (balances[_from] >= _value
            && allowance >= _value
            && balances[_to] + _value >= balances[_to]
        ) {
            balances[_to] += _value;
            balances[_from] -= _value;
            if (allowance < MAX_UINT) {
                allowed[_from][msg.sender] -= _value;
            }
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}

contract IOSToken is RegularToken {

    uint8 constant public decimals = 18;
    string constant public name = "Wrapped IOSToken";
    string constant public symbol = "WIOST";

    function IOSToken() public {
        totalSupply = 21*10**27;
        balances[msg.sender] = totalSupply;
        Transfer(address(0), msg.sender, totalSupply);
    }
}