/**
 *Submitted for verification at Etherscan.io on 2023-06-11
*/

/*
Non-Fungible Token (ERC721). The program should enable users to create,
transfer, and approve tokens. If you are unable to implement all the
functions within the given timeframe, you can deploy whatever portion you
have completed, and I will review the code accordingly. Once you have
finished implementing the program, test it using Remix. After successful
testing, deploy the program to the Sepolia test network. Verify and publish
the contract, and then share the contract address with me. The evaluation
will consider factors such as program completion, functionality, proper
utilization of visibility modifiers, and code reuse and understanding of
ERC721 token standard. 

*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC721 {

    /**
     * Q.1
     * Declare a variable `name` of type string to store a name of the token.
     * Use appropriate visibility (public/private/internal)
     */

    // write here
    string private name;

    /**
     * Q.2
     * Declare a variable `symbol` of type string to store a symbol of the token.
     * Use appropriate visibility (public/private/internal)
     */

    // write here

    string private symbol;

    /**
     * Q.3
     * Declare a mapping `owners` which will map tokenId (uint) to owners address (address);
     * Use appropriate visibility (public/private/internal)
     */

    // write here
    mapping(uint => address) private owners;

    /**
     * Q.4
     * Declare a mapping `balances` which will map owner (address) to their token balance (uint);
     * Use appropriate visibility (public/private/internal)
     */

    // write here
    mapping(address => uint) private balances;



    /**
     * Q.5
     * Declare a mapping `tokenApprovals` which will map tokenId (uint) to approved user address (address);
     * Use appropriate visibility (public/private/internal)
     */

    // write here
    mapping(uint => address) public tokenApprovals;


    /**
     * Q.6
     * Declare a nested mapping `opratorApprovals` from owner address (address) to operator approvals 
     * which will map approvedAddress (address) to approved status (bool)
     * Hint: mapping(address => mapping(address => bool))
     * This will tell whether a specifc owner address has given an approval to a specific user address to spend his/her token
     * Use appropriate visibility (public/private/internal)
     */

    // write here
    mapping(address => mapping(address => bool)) private operatorApprovals;

    /**
     * Q.7
     * Declare an event `Approval` which will emit the owner address, approved user address and tokenId
    */

    // write here
    event Approval(address,address,uint);



    /**
     * Q.8
     * Declare an event `ApprovalForAll` which will emit the owner address, approved user address and approved status (bool) true or false when the user grants or revokes the approval for a specific token
    */

    // write here
    event ApprovalForAll(address,bool);


    /**
     * Q.9
     * Declare an event `Transfer` which will emit the from address, to address and tokenId (uint) when the user trnasfers a token
    */

    // write here
    event Transfer(address,address,uint);


    /**
     * Q.10
     * Declare an constructor which will take tokenName, tokenSymbol as a parameter and will init the name and symbol values.
    */

    // write here
    constructor(
        string memory tokenName,
        string memory tokenSymbol

    ){
        name = tokenName;
        symbol = tokenSymbol;
    }


    /**
     * Q.10
     * Write a function named `balanceOf` which takes address as a parameter and returns the balance of that address
     * Check owner address is not zero address.
     * apply appropriate function visibility
    */

    // write here
    function balanceOf(address _ofOwner)public view returns(uint){
        require(_ofOwner != address(0),"Enter non-zero address");
        return balances[_ofOwner];
    }


    /**
     * Q.10
     * Write a function named `ownerOf` which takes the tokenId as parameter and returns the owner of that token
     * apply appropriate function visibility
    */

    // write here
    function ownerOf(uint _tokenId)public view returns(address){
        return owners[_tokenId];
    }

    /**
     * Q.11
     * Write a function `getTokenName` which returns the name of the current token 
     * apply appropriate function visibility
    */

    // write here
    function getTokenName() public view returns(string memory){
        return name;
    }


    /**
     * Q.12
     * Write a function `getTokenSymbol` which returns the symbol of the current token 
     * apply appropriate function visibility
    */

    // write here
    function getTokenSymbol()public view returns(string memory) {
        return symbol;
    }



    /**
     * Q.13
     * Write a function `approve` which will take spender address and token Id and gives approval for spender address to send the tokenId on behalf of owner.
     * Add the spender to the tokendApprovals mapping for tokenId passed as parameter.
     * Emit the approval event using required parameters
     * apply appropriate function visibility
     * Check:
     *  1. spender address and owner address are not same.
     *  2. caller is owner or approved as spender for that token(isApprovedForAll)
     *  
    */

    // write here
    function approve(address _spender, uint _tokenId) public {
        require(_spender != address(0), "Enter a non-zero address");
        require(_spender != ownerOf(_tokenId),"Need to be owner to approve");
        tokenApprovals[_tokenId] = _spender;
        emit Approval(ownerOf(_tokenId),_spender,_tokenId);
    }



    /**
     * Q.14
     * Write a function `isApprovedForAll` which takes owner address and approved user address and returns true or false depending on whether the approved user has approval or not.
     * apply appropriate function visibility
    */

    // write here
    function isApprovedForAll(address _owner, address _approvedUser)public view returns(bool){
        return operatorApprovals[_owner][_approvedUser];
    }


    /**
     * Q.15
     * Write a function `getApproved` which takes tokenId as parameter and returns the approved user address using tokenApprovals mapping
     * apply appropriate function visibility
    */

    // write here
    function getApproved(uint _tokenId)public view returns(address){
        return tokenApprovals[_tokenId];
    }


    /**
     * Q.16
     * Write a function `setApprovalForAll` which takes 
     *  owner address, operator address and boolean to
     *  indicate the spender is approved or not and sets approval using opertorApprovals mapping
     * 
     * apply appropriate function visibility
     * Checks:
     * Owner address and spender address are not equal
     * emit the ApprovalForAll event using required parameters
    */

    // write here
    function setApprovalForAll(address _owner, address _operator, bool _status) public {
        require(_operator != _owner, "Sender cannot be approver");
        operatorApprovals[_owner][_operator] = _status;
        emit ApprovalForAll(_operator,_status);
    }



    /**
     * Q.17
     * Write a function `isApprovedOrOwner` which takes the spender address and tokenId and returns the boolean if the spender is owner or approved as spender
     * 
     * apply appropriate function visibility
    */

    // write here
    function isApprovedOrOwner(address _spender, uint _tokenId) public view returns(bool){
        return (_spender == ownerOf(_tokenId) || getApproved(_tokenId) == _spender || isApprovedForAll(ownerOf(_tokenId), _spender));
    }


    
    /**
     * Q.18
     * Write a function `transfer` which takes to address * and tokenId and transfers tokenId to the given    *  address 
     * apply appropriate function visibility
     * Checks:
     *  1. Is the spender is owner or approved as spender using isApprovedOrOwner function
     *  2. Check the from address and token owner address are equal using ownerOf function
     *  3. Check to address is not zero address.
     * 
     * Clear the approvals from previous owners using delete keyword and token approvals mapping
     * Reduce the balance of the previous owner and increase the balance of new owner
     * Change the ownership in owners mapping to new owner
     * Emit the Transfer event with required parameters.
    */

    // write here
    function transfer(address _any, uint _tokenId) public {
        require(_any != address(0),"Cannot transfer to non-zero address");
        require(_any != ownerOf(_tokenId),"Owner cannot be tranffered");
        require(ownerOf(_tokenId) != address(0), "Cannot tranfer from non-zero address" );

        delete tokenApprovals[_tokenId];
        balances[ownerOf(_tokenId)] -= 1;
        balances[_any] += 1;
        owners[_tokenId] = _any;
        emit Transfer(ownerOf(_tokenId), _any, _tokenId);

    }


    
    /**
     * Q.19
     * Write a function `mint` to create a new token.
     * it takes tokenId as a parameter
     * Checks
     * 1. to address is not zero address
     * 2. Check tokenId already exists or not
     * Increment the balance of the to address
     * Bind tokenId with new owner in owners mapping
     * emit Transfer event with required parameters.
     */

    // write here
    function mint(uint _tokenId) public {
        require(_tokenId != 0, "_tokenId cannot be zero");
        require(owners[_tokenId] == address(0), "Token already exists");
        address minter = msg.sender;
        balances[minter] += 1;
        owners[_tokenId] = minter;
        emit Transfer(address(0), minter, _tokenId);
    }



    /**
     * Q.19
     * Write a function `burn` to delete the existing token.
     * it takes tokenId as a parameter
     * Checks
     * 1. only owner should burn the token
     * 2. Check if tokenId already exists or not.
     * Clear all the approvals for that token using delete keyword with tokenApprovals mapping
     * Reduce the balance of the owner
     * Clear token with owner mapping entry for that token using delete keyword.
     * Emit the Transfer event with required parameters.
     */

    // write here
    function burn(uint _tokenId) public {
        require(msg.sender != ownerOf(_tokenId),"Only owners can burn");
        require(ownerOf(_tokenId) != address(0), "Enter non zero address");

    delete tokenApprovals[_tokenId];
    balances[ownerOf(_tokenId)] -= 1;
    delete owners[_tokenId];
    emit Transfer(ownerOf(_tokenId), address(0), _tokenId);

    }

    
}