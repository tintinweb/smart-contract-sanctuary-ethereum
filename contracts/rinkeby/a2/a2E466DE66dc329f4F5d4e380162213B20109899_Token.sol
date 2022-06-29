/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

pragma solidity ^0.4.24;

/**
 * @title Token Sample
 * @author Zero the first>
 */

contract Token {
    string public constant symbol = 'BLG';
    string public constant name = 'Blockchain Learning Group Community Token';
    uint public constant decimals = 18;
    /***********************************************
     * Specify the rate for your token token / wei *
     **********************************************/

    uint256 private totalSupply_;
    mapping (address => uint256) private balances_;
    mapping(address => mapping (address => uint256)) private allowed_;
    address private owner_; // EOA

    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event TokensMinted(address indexed _to, uint256 value, uint256 totalSupply);

    constructor() public {
        owner_ = msg.sender;
    }

    // @dev Approve a user to spend your tokens.
    function approve(address _spender, uint256 _amount)
        external
        returns (bool)
    {
        require(_amount > 0, 'Can not approve an amount <= 0, Token.approve()');
        require(_amount <= balances_[msg.sender], 'Amount is greater than senders balance, Token.approve()');  

        allowed_[msg.sender][_spender] += _amount;  // NOTE overflow

        return true;
    }
    
    // Buy tokens with ether, mint and allocate new tokens to the purchaser.
    function buy() external payable returns (bool)
    {
        // May not buy with a value of 0

        // Compute the amount of tokens to mint

        // Update the total supply and buyer's balance
    
        // Emit events
        return true;
    }
    
    // Transfer value to another address
    function transfer (
        address _to,
        uint256 _value
    )   external
        returns (bool)
    {
        // Ensure from address has a sufficient balance

        // Update the from and to balances

        // Emit events
        return true;
    }
    
    // Tranfer on behalf of a user, from one address to another
    function transferFrom(address _from, address _to, uint256 _amount)
        external
        returns (bool)
    {
        require(_amount > 0, 'Cannot transfer amount <= 0, Token.transferFrom()');
        require(_amount <= balances_[_from], 'From account has an insufficient balance, Token.transferFrom()');
        require(_amount <= allowed_[_from][msg.sender], 'msg.sender has insufficient allowance, Token.transferFrom()');

        balances_[_from] -= _amount; // NOTE underflow
        balances_[_to] += _amount;  // NOTE overflow

        allowed_[_from][msg.sender] -= _amount;  // NOTE underflow

        emit Transfer(_from, _to, _amount);

        return true;
    }

    // withdraw the ETH held by this contract
    function withdraw(address _wallet) external returns(bool) {
        // Confirm only the owner may withdraw 

        // Transfer the balance of the contract, this, to the wallet
        return true;
    }

    // @return the allowance the owner gave the spender
    function allowance(address _owner, address _spender)
        external
        constant
        returns(uint256)
    {
        return allowed_[_owner][_spender];
    }

    // return the address' balance
    function balanceOf(
        address _owner
    )   external
        constant
        returns (uint256)
    {
        return balances_[_owner];
    }

    // return total amount of tokens.
    function totalSupply()
        external
        constant
        returns (uint256)
    {
        return totalSupply_;
    }
}