/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;
contract PoktraderSwap {
    //Public Deposite
    function Deposite(uint amount) public {
         totalSupply += amount;
    }
    // The Keyword "public" makes accessible from other contracts
    address public Myaddress;
    // This function querys the balance from other accounts
    mapping (address => uint) public Wallet;
    // The Event is evidence to track transaction
    event Sent(address from, address to, uint amount);
    /**
    *The Constructor is Special Function. 
    * It permanently stores the address of the person creating the contract
    * The msg variable (together with tx and block) is a special global variable
    * The msg.sender is always the address where the current (external) function call came from
    */
    constructor() {
        Myaddress = msg.sender;
    }
    /**
    * The Mint function sends an amount of newly created coins to another address.
    * The require function ensures that only the creator of the contract can call Mint.
    * The arithmetic formula is statement in funtion send.
    */
    // Errors are used together with the revert statement.
        error Insufficienttotalsupply(uint requested, uint available);
    function Mint(address receiver, uint tokens) public {
        if (tokens > totalSupply)
            revert Insufficienttotalsupply({
                requested: tokens,
                available: totalSupply
            });

            totalSupply -= tokens;
            Wallet[receiver] += tokens;
    }
    // Errors are used together with the revert statement.
        error InsufficientWallet(uint requested, uint available);
    // The revert statement will explain why error.
    function Send(address receiver, uint amount) public {
        if (amount > Wallet[msg.sender])
            revert InsufficientWallet({
                requested: amount,
                available: Wallet[msg.sender]
            });

            Wallet[msg.sender] -= amount;
            Wallet[receiver] += amount;
            emit Sent(msg.sender, receiver, amount);
    }
    /// @notice EIP-20 token name for this token
    string public constant name = "PoktraderSwap";
    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "PKS";
    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;
    /// @notice Total number of tokens in circulation
    uint public totalSupply = 100_000_000e18; // 1m PKS
}