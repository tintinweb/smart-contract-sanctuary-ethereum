/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;



// File: MultiSigWallet.sol

/**
    D E S C R I P T I O N

    A basic solidity program that allows the creation of a wallet in the contract.

    Wallet owners can:
    
    1. Submit a transaction.
    2. Approve and revoke a pending transaction.
    3. Anyone can execute a transaction after enough owners has approved it.

*/

contract MultiSigWallet
{
    // initialize a map of acount to fund,
    mapping(address => uint) address_to_fund;
    uint wallet_amount;
    address[] public wallets;
    address payable owner;
    uint total_wallets;
    bool locked;

    constructor()
    {
        owner = payable(msg.sender);
    }

    struct All_Wallets
    {
        address payable user;
        uint cash;
    }

    All_Wallets[] public all;


    // a struct of all transactions
    // struct contains a hash, a from address, a to address, and the value being sent ovet through the blockchain

    struct Transaction
    {
        bytes32 t_hash;
        address from;
        address to;
        uint amount;
        bool approved;
        uint number_of_appprovals;
    }

    // a list that will hold all pending transactions
    Transaction[] public transactions;

    fallback() external payable {}
    receive()  external payable {}

    // control modifier
    // this modifier makes sure that the user has not created a recorded wallet before

    function isvalidperson(address r) internal returns(bool)
    {
        
        for(uint i = 0; i < wallets.length; i++)
        {
            if(wallets[i] == r)
            {
                return true;
            }
        }
        
        return false;
    }

    modifier Valid_Transaction(address receiver, uint val)
    {
        require(val > 0, "You cant submit a transaction that is empty.");
        require(isvalidperson(receiver), "The receiver has no wallet here.");
        _;
    }

    modifier Valid_Sender
    {
        require(isvalidperson(msg.sender), "You have no wallet here.");
        _;
    }

    modifier Is_Listed(uint index)
    {
        require(index >= 0, "Index not listed");
        _;
    }

    modifier Is_Valid(uint index)
    {
        require(index < transactions.length, "Index not listed");
        _;
    }

    modifier NoReentrance()
    {
        require(!locked, "You cannot redo this action.");
        locked = true;
        _;
        locked = false;
    }

    // this function creates a new 'wallet' and checks if the user has an already existing wallet.
    function Create_Wallet() public
    {
        for(uint i = 0; i < wallets.length; i++)
        {
            if(wallets[i] == msg.sender)
            {
                revert("You have created a wallet here.");
            }
        }

        // address_to_fund[msg.sender] += wallet_amount;
        address_to_fund[msg.sender] += 0;
        wallets.push(msg.sender);
        total_wallets += 1;
        all.push(All_Wallets(payable(msg.sender), 0));
    }


    function Make_Transaction(address receiver, uint val) public Valid_Sender Valid_Transaction(receiver, val)
    {
        bytes32 txn_hash = keccak256(abi.encodePacked(msg.sender, receiver, val));
        transactions.push(Transaction(txn_hash, msg.sender, receiver, val, false, 0));
        // return("This transaction has been listed");
    }

    // approval function
    function Approve_Transaction(uint index) public NoReentrance Is_Listed(index) Is_Valid(index) payable
    {
        transactions[index].approved = true;
        transactions[index].number_of_appprovals += 1;

        if(transactions[index].number_of_appprovals  > (total_wallets / 2))
        {
            payable(transactions[index].to).call{value: transactions[index].amount}("");
            // payable(transactions[index].to).transfer(transactions[index].amount);

            for(uint j = 0; j < all.length; j++)
            {
                if(all[j].user == transactions[index].to)
                {
                    all[j].cash += transactions[index].amount;
                }
            }

            delete transactions[index];
        }
    }


    function Revoke_Transaction(uint index) NoReentrance Is_Listed(index) public returns(string memory)
    {
        transactions[index].approved = true;
        transactions[index].number_of_appprovals -= 1;

        return("Transaction revoked");
    }


    function getwallets() public view returns(uint256)
    {
        return wallets.length;
    }
}