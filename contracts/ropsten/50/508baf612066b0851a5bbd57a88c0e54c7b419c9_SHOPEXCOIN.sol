/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// SPDX-License-Identifier: unlicensed
pragma solidity 0.8.4;

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals
// assisted token transfers
// ----------------------------------------------------------------------------
contract SHOPEXCOIN {
    string  public name = "SHOPEX COIN";
    string  public symbol = "SPC";
    uint256 public _totalSupply = 211000000 * 10**18; // 1 million tokens
    uint256  public decimals = 18;
    address public owner;
    bool paused = false;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
    event Paused(bool isPaused);
    event OwnershipTransferred(address newOwner);

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() {
        balances[msg.sender] = _totalSupply;
        owner = msg.sender;
    }

    // amountstaked    address > [100, 200, 300, 100]
    // timetoreedem    addres > [15month, 12month, 20month, 15monmth]
    // reedemabletoken address >

   
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }

    modifier isPaused() {
        require(!paused, "Contract is in paused state");
        _;
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint256) {
        return _totalSupply - balances[address(0)];
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner)
        public
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
        public
        isPaused
        returns (bool success)
    {
        balances[msg.sender] = balances[msg.sender] - tokens;
        balances[receiver] = balances[receiver] + tokens;
        emit Transfer(msg.sender, receiver, tokens);
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
        public
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
    ) public isPaused returns (bool success) {
        balances[sender] = balances[sender] - tokens;
        allowed[sender][msg.sender] = allowed[sender][msg.sender] - tokens;
        balances[receiver] = balances[receiver] + tokens;
        emit Transfer(sender, receiver, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender)
        public
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
    function burn(uint256 _value, address _add) onlyOwner public {
        require(_add == owner || _add == address(this));
         _totalSupply = _totalSupply - _value;
        balances[_add] = balances[_add] - _value;
        emit Transfer(_add, address(0), _value);
    }

    function mint(uint256 _value, address _add) onlyOwner public {
        require(_add == owner || _add == address(this));
        _totalSupply += _value;
        balances[_add] += _value;
        emit Transfer(_add, address(0), _value);
    }
}