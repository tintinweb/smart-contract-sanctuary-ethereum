/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/*
      An ERC-20 token must be able to:

    - Transfer tokens from one account to another
    - Return the balance of an account
    - Return the total tokens available in the token
    - Transfer tokens to an account

      ERC20 Tokens usually have some functions as below:

    - name() returns the name of the token (e.g., Binance Coin)
    - symbol() returns the symbol of the token (e.g., BNB)
    - decimals() returns the number of decimals the token uses
    - totalSupply() returns the total number initially supplied to the token
    - balanceOf() returns the balance of an account
    - transfer() transfers a certain amount of tokens to an address
    - transferFrom() transfers a certain amount of tokens from a beneficiary address to a recipient address
    - approve() withdraws tokens from the owner’s address up to a certain amount of tokens
    - allowance() returns the number of tokens withdrawable from the owner’s account

*/

contract AUTHICoin {

    event Transfer(address indexed from, address indexed to, uint tokens); // Which must be triggered when tokens are transferred.
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens); // Which must be triggered when an account is approved to collect a certain amount of tokens

    string public constant name = "Authic Coin";
    string public constant symbol = "AUTHIC";
    uint8 public constant decimals = 18;

    mapping(address => uint256) balances; // Mapping is used for define key-value relationships between "address" and "balance".

    mapping(address => mapping (address => uint256)) allowed; // It allows you to store the number of tokens that can be transferred to a recipient.

    uint256 totalSupply_; // This stores the number of tokens that are available in our contract. When the contract is deployed, developer can specify the total supply with constructor().

    constructor(uint256 total) { // Used for initialize a deafult method when the contract is deployed. Executed one time, does not run again.
      totalSupply_ = total;
      balances[msg.sender] = totalSupply_; // Now the total supply is balance of contract owner. 
    }

    function totalSupply() public view returns (uint256) { // This method used for return the total supply.
      return totalSupply_;
    }

    function balanceOf(address tokenOwner) public view returns (uint) { // This method used for return the total balance of token owner.
        return balances[tokenOwner];
    }

    /* EXPLANING TRANSFER FUNCTION BELOW 

    This method has the following arguments:

    receiver: the address of the account that will receive tokens
    numTokens: the number of tokens that will be sent to the receiver account

    In the body of the method, we see that a check is made to verify that the number of tokens to be sent to the recipient is enough according to the deployer’s address balance.

    Next, the numTokens is subtracted from the deployer’s balance and credited to the receiver‘s balance. Then, a Transfer event is emitted. Finally, the Boolean true is returned.

    */

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]); // Check the balance and transfer amount that will be sent.
        balances[msg.sender] -= numTokens; // Balance of sender is decreased.
        balances[receiver] += numTokens; // Balance of receiver is increased.
        emit Transfer(msg.sender, receiver, numTokens); // It used for trigger the Transfer event for log the details.
        return true; // If the transfer is success, function returns a true value.
    }

    /*

    EXPLANING APPROVE FUNCTION BELOW

    You can change the approved amount or revoke it altogether (only the unspent amount). But you cannot take back an already sent transfer.
    Approve is a function used to give permission the spender can be anyone an exchange or EOA to withdraw as many times from your token contract up to the _value.

    */
    

    function approve(address delegate, uint numTokens) public returns (bool) { 
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    /*

    EXPLANING ALLOWANCE FUNCTION BELOW

    In simple terms, the Allowance is a permission (or a proxy) 
    you give to the smart contract in order to allow it to spend - on your behalf - the token you want to use through its dApp.

    */

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    /*

    EXPLANING TRANSFERFROM FUNCTION BELOW

    The transferFrom() function transfers the tokens from an owner's account to the receiver account, but only if the transaction initiator 
    has sufficient allowance that has been previously approved by the owner to the transaction initiator. 
    To transfer the tokens using the transferFrom() function, approver must have called the approve() function prior. 
    As per the standard, the transferFrom() function must fire the Transfer event upon the successful execution and transfer of tokens. 
    The transfer of 0 (zero) value must also be treated as a valid transfer and should fire the Transfer event.

    */

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] -= numTokens;
        allowed[owner][msg.sender] -= numTokens;
        balances[buyer] += numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}