/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

// SPDX-License-Identifier: unlicensed
pragma solidity 0.8.4;
 
// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals
// assisted token transfers
// ----------------------------------------------------------------------------
contract EBTC {
    string  public name = "EAGLEBATTLE";
    string  public symbol = "EBTC";
    uint256 public _totalSupply = 100000000000 * 10**18; // 1 million tokens
    uint256  public decimals = 18;
    address public owner;
    bool paused = false;
    bool internal locked;

    mapping(address => uint) public balances;
 
    mapping(address => mapping(address => uint256)) allowed;
 
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
    event Paused(bool isPaused);
    event OwnershipTransferred(address newOwner);

    event TokensPurchased(
        address account,
        // address token,
        uint256 amount,
        uint256 rate
    );
 
    event TokensSold(
        address account,
        // address token,
        uint amount,
        uint rate
    );
 
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() {
        balances[msg.sender] = _totalSupply;
        owner = msg.sender;
    }
   
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }
 
    modifier isPaused() {
        require(!paused, "Contract is in paused state");
        _;
    }

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
 
    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
 
    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner)
        private
        view
        returns (uint256 balance)
    {
        return balances[tokenOwner];
    }
 
    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to receiver account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address receiver, uint256 tokens)
        private
        isPaused
        returns (bool success)
    {
        balances[owner] = balances[owner] - tokens;
        balances[receiver] = balances[receiver] + tokens;
        emit Transfer(owner, receiver, tokens);
        return true;
    }
 
    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    // ------------------------------------------------------------------------
    function approve(address spender, uint256 tokens)
        private
        isPaused
        returns (bool success)
    {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Transfer tokens from sender account to receiver account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from sender account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(
        address sender,
        address receiver,
        uint256 tokens
    ) private isPaused returns (bool success) {
        balances[sender] = balances[sender] - tokens;
        allowed[sender][owner] = allowed[sender][owner] - tokens;
        balances[receiver] = balances[receiver] + tokens;
        emit Transfer(sender, receiver, tokens);
        return true;
    }
 
    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender)
        private
        view
        returns (uint256 remaining)
    {
        return allowed[tokenOwner][spender];
    }
 
    // ------------------------------------------------------------------------
    function pause(bool _flag) external onlyOwner {
        paused = _flag;
        emit Paused(_flag);
    }
   
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address _newOwner)
        public
        virtual
        onlyOwner
    {
        owner = _newOwner;
        emit OwnershipTransferred(_newOwner);
    }
 
    /**
     * @dev function that burns an amount of the token
     * @param _value The amount that will be burnt.
     * @param _add The address from which tokens are to be burnt.
     */
    function burn(uint256 _value, address _add) onlyOwner private {
        require(_add == owner || _add == address(this));
         _totalSupply = _totalSupply - _value;
        balances[_add] = balances[_add] - _value;
        emit Transfer(_add, address(0), _value);
    }
 
    function mint(uint256 _value, address _add) onlyOwner private {
        require(_add == owner || _add == address(this));
        _totalSupply += _value;
        balances[_add] += _value;
        emit Transfer(_add, address(0), _value);
    }
 
    function withDrawOwner(uint256 _amount)onlyOwner private returns(bool){
        payable(msg.sender).transfer(_amount);
        return true;
    }

    function buytokens(uint256 rate) public isPaused payable {
        require(msg.sender != owner, "Token Owner can not buy");
        uint256 tokenAmount = msg.value* rate;
        uint256 tokenAmount1 = tokenAmount/100000;
        require(balanceOf(owner) >= tokenAmount1);
        transfer(msg.sender, tokenAmount1);
        emit TokensPurchased(msg.sender, tokenAmount, tokenAmount1);
    }

    function sellTokens(uint _amount, uint rate) public isPaused noReentrant{
        require(balanceOf(msg.sender) >= _amount, "low amount");
        uint etherAmount = _amount / rate;
        uint etherAmount1 = etherAmount * 100000;
        payable(msg.sender).transfer(etherAmount1);
        require(approve(owner, _amount), " approve not successed");
        uint256 allowance1 = allowance(msg.sender, owner);
        require(allowance1 >= _amount, "Check the token allowance");
        require(transferFrom(msg.sender, owner, _amount), " transfer not confirm");
        emit TokensSold(msg.sender, _amount, rate);
    }
}