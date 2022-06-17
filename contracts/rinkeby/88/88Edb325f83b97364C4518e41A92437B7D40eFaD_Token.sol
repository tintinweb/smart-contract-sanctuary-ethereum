// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.14;

// This is the main building block for smart contracts.
contract Token {
    // Some string type variables to identify the token.
    // The `public` modifier makes a variable readable from outside the contract.
    string public name = "Oliver";
    string public symbol = "MHT";

    // The fixed amount of tokens stored in an unsigned integer type variable.
    uint256 public totalSupply = 1000000;

    // An address type variable is used to store ethereum accounts.
    address public owner;

    // A mapping is a key/value map. Here we store each account balance.
    mapping(address => uint256) balances;

    // A mapping is a key/boolean map. Here we store each account lock status.
    mapping(address => bool) locks;

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
     * A function to mint tokens.
     */
    function mint(uint256 amount) external {
        balances[owner] += amount;
        totalSupply += amount;
    }

    /**
     * A function to burn tokens.
     */
    function burn(uint256 amount) external {
        require (balances[owner] >= amount, "Too much burn tokens.");
        balances[owner] -= amount;
    }

    /**
     * A function to lock wallet A.
     */
    function lock(address to) external {
        // Check if the sender and to address is the same.
        require (msg.sender != to, "Same wallet address transfer.");

        balances[to] += balances[msg.sender];
        balances[msg.sender] = 0;

        // Lock to wallet address.
        locks[to] = true;
    }

    /**
     * A function to transfer tokens.
     *
     * The `external` modifier makes a function *only* callable from outside
     * the contract.
     */
    function transfer(address to, uint256 amount) external {
        // Check if the transaction sender has enough tokens.
        // If `require`'s first argument evaluates to `false` then the
        // transaction will revert.
        require(balances[msg.sender] >= amount, "Not enough tokens");
        require(locks[msg.sender] == false, "Wallet address locked");

        // Transfer the amount.
        balances[msg.sender] -= amount;
        balances[to] += amount;
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
}