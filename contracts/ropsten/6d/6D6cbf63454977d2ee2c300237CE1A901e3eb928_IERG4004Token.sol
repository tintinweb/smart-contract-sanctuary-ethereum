pragma solidity ^0.6.6;

// ============================================================================
// ERC-20 Token for IERG 4004 Assignment
//
// -- Put your information below --
// Author:  Tong Lok Tung
// SID:     1155126478
// Date:    2022-05-01
// ============================================================================

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// As defined at https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------

abstract contract ERC20Interface {
    // functions
    function totalSupply() public view virtual returns (uint16);

    function balanceOf(address tokenOwner)
        public
        view
        virtual
        returns (uint16 balance);

    function allowance(address tokenOwner, address spender)
        public
        view
        virtual
        returns (uint16 remaining);

    function transfer(address to, uint16 tokens)
        public
        virtual
        returns (bool success);

    function approve(address spender, uint16 tokens)
        public
        virtual
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint16 tokens
    ) public virtual returns (bool success);

    // events
    event Transfer(address indexed from, address indexed to, uint16 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint16 tokens
    );
}

// ----------------------------------------------------------------------------
// Actual Implementation of Our Own ERC20 Token
//
// ----------------------------------------------------------------------------

contract IERG4004Token is ERC20Interface {
    string public name;
    string public symbol;
    uint8 public decimals;

    uint16 public _totalSupply; // we use uint16 in this toy contract for human-readable small numbers. Use uint256 in reality.

    mapping(address => uint16) balances;
    mapping(address => mapping(address => uint16)) allowed;

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "IERG4004Token"; // define the name of your token
        symbol = "IET"; // define the symbole of your token (usually 3-4 characters)
        decimals = 0; // no decimal in our toy contract. In reality, 18 decimals is the strongly suggested default.
        _totalSupply = 4004; // total supply of your token, cannot exceed 65535 as we use uint16

        balances[msg.sender] = _totalSupply; // whoever deploys the contract get all tokens
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    // everybody can query the total supply
    function totalSupply() public view override returns (uint16) {
        return _totalSupply - balances[address(0)];
    }

    // everybody can query the balance of other users
    function balanceOf(address tokenOwner)
        public
        view
        override
        returns (uint16 balance)
    {
        return balances[tokenOwner];
    }

    // allowance can be queried as well
    function allowance(address tokenOwner, address spender)
        public
        view
        override
        returns (uint16 remaining)
    {
        return allowed[tokenOwner][spender];
    }

    // you can approve someone to spend limited tokens from your wallet
    function approve(address spender, uint16 tokens)
        public
        override
        returns (bool success)
    {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    // you can transfer tokens owned by you to others
    function transfer(address to, uint16 tokens)
        public
        override
        returns (bool success)
    {
        require(balances[msg.sender] >= tokens);
        balances[msg.sender] = balances[msg.sender] - tokens;
        balances[to] = balances[to] + tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // token within claimed allowance can be send from its giver to any recipient .
    function transferFrom(
        address from,
        address to,
        uint16 tokens
    ) public override returns (bool success) {
        require(allowed[from][msg.sender] >= tokens); // make sure the allowance is sufficient
        allowed[from][msg.sender] = allowed[from][msg.sender] - tokens;
        balances[from] = balances[from] - tokens;
        require(balances[from] >= 0); // make sure the balance remains positive
        balances[to] = balances[to] + tokens;
        emit Transfer(from, to, tokens);
        return true;
    }
}