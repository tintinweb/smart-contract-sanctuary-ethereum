/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.7.0;

// This is the main building block for smart contracts.
contract Token {
    // Some string type variables to identify the token.
    // The `public` modifier makes a variable readable from outside the contract.
    string private _name ;
    string private _symbol ;
    uint8 private _decimals;

    // The fixed amount of tokens stored in an unsigned integer type variable.
    uint256 public _totalSupply = 999;

    // An address type variable is used to store ethereum accounts.
    address public _owner;

    // A mapping is a key/value map. Here we store each account balance.
    mapping(address => uint256) _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    /**
     * Contract initialization.
     *
     * The `constructor` is executed only once when the contract is created.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) {
        // The totalSupply is assigned to transaction sender, which is the account
        // that is deploying the contract.
        _balances[msg.sender] = _totalSupply;
        _owner = msg.sender;
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }


    

    /**
     * Read only function to retrieve the token balance of a given account.
     *
     * The `view` modifier indicates that it doesn't modify the contract's
     * state, which allows us to call it without executing a transaction.
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    // function test() external view returns (uint256) {
    //     return totalSupply;
    // }

    // function test2() external {
    //     totalSupply = totalSupply - 100;
    // }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function mint(address account, uint256 amount) public {
        require(account != address(0), "ERC20: mint to the zero address");
        require(msg.sender == _owner, "Should be owner!");

        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        // emit Transfer(address(0), account, amount);
    }

    function burn(address account, uint256 value) public {
        require(account != address(0), "ERC20: burn from the zero address");

    _totalSupply = _totalSupply - value;
        _balances[account] = _balances[account] - value;
        // emit Transfer(account, address(0), value);
    }

    function approve(address spender, uint256 value) public {
        // require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[msg.sender][spender] = value;
        // emit Approval(owner, spender, value);
    }

    //  function transfer(address sender, address recipient, uint256 amount) internal {
    //     require(sender != address(0), "ERC20: transfer from the zero address");
    //     require(recipient != address(0), "ERC20: transfer to the zero address");

    //     _balances[sender] = _balances[sender] - amount;
    //     _balances[recipient] = _balances[recipient] + amount;
    //     // emit Transfer(sender, recipient, amount);
    // }

    function transfer(address to, uint256 amount) external {
        // Check if the transaction sender has enough tokens.
        // If `require`'s first argument evaluates to `false` then the
        // transaction will revert.
        require(_balances[msg.sender] >= amount, "Not enough tokens");

        // Transfer the amount.
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
    }

    // function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
    //     transfer( recipient, amount);
    //     approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    //     return true;
    // }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_allowances[sender][msg.sender] >= amount, "Not allowed!");

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        
        // _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);

        _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;

        // emit Approval(sender, spender, value);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

}