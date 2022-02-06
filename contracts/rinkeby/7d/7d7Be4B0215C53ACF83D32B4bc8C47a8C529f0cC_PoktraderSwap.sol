/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;
contract PoktraderSwap {
    //Public Deposit
    mapping (address => uint) public Balances;
    function Deposit() public payable{
        require(msg.value > 0, "Deposit money is zero");

        Balances[msg.sender] += msg.value; 
    }
    function Withdraw(uint amount) public{
        require(amount > 0 && amount <= Balances[msg.sender],"insufficient money");

        payable(msg.sender).transfer(amount);
        Balances[msg.sender] -= amount;
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
    function Mint(uint amount) public{ 
        if (amount > totalSupply)      
            revert Insufficienttotalsupply({
                requested: amount,
                available: totalSupply
            });
            totalSupply -= amount;
            Wallet[msg.sender] += amount;
    }
    // Errors are used together with the revert statement.
        error InsufficientWallet(uint requested, uint available);
    // The revert statement will explain why error.
    function Send(address receiver, uint amount) public{
        if (amount > Wallet[msg.sender])
            revert InsufficientWallet({
                requested: amount,
                available: Wallet[msg.sender]
            });

            Wallet[msg.sender] -= amount;
            Wallet[receiver] += amount;
            emit Sent(msg.sender, receiver, amount);
    }
    /// @notice ERC-20 token name for this token
    string public constant name = "PoktraderSwap";
    /// @notice ERC-20 token symbol for this token
    string public constant symbol = "PKS";
    /// @notice ERC-20 token decimals for this token
    uint8 public constant decimals = 18;
    /// @notice Total number of tokens in circulation
    uint public totalSupply = 100_000_000e18; // 100m PKS
}