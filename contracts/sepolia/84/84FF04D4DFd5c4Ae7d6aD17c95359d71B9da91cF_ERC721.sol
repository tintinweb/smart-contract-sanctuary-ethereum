/**
 *Submitted for verification at Etherscan.io on 2023-06-11
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
     string private _name;

    /**
     * Q.2
     * Declare a variable `symbol` of type string to store a symbol of the token.
     * Use appropriate visibility (public/private/internal)
     */
    
    // write here

    string private _symbol;

    /**
     * Q.3
     * Declare a mapping `owners` which will map tokenId (uint) to owners address (address);
     * Use appropriate visibility (public/private/internal)
     */

    // write here
    mapping (uint => address) private _owners;

    /**
     * Q.4
     * Declare a mapping `balances` which will map owner (address) to their token balance (uint);
     * Use appropriate visibility (public/private/internal)
     */

    // write here

    mapping (address => uint) _balances;


    /**
     * Q.5
     * Declare a mapping `tokenApprovals` which will map tokenId (uint) to approved user address (address);
     * Use appropriate visibility (public/private/internal)
     */

    // write here

    mapping (uint => address) private _tokenApprovals;


    /**
     * Q.6
     * Declare a nested mapping `opratorApprovals` from owner address (address) to operator approvals 
     * which will map approvedAddress (address) to approved status (bool)
     * Hint: mapping(address => mapping(address => bool))
     * This will tell whether a specifc owner address has given an approval to a specific user address to spend his/her token
     * Use appropriate visibility (public/private/internal)
     */

    // write here

    mapping (address => mapping (address => bool)) private _operatorApprovals;


    /**
     * Q.7
     * Declare an event `Approval` which will emit the owner address, approved user address and tokenId
    */

    // write here

    event Approval (address indexed owner, address indexed userApproved, uint tokenId);


    /**
     * Q.8
     * Declare an event `ApprovalForAll` which will emit the owner address, approved user address and approved status (bool) true or false when the user grants or revokes the approval for a specific token
    */

    // write here

    event ApprovalForAll (address indexed owner, address indexed operatorApproved, bool approveStatus);


    /**
     * Q.9
     * Declare an event `Transfer` which will emit the from address, to address and tokenId (uint) when the user trnasfers a token
    */

    // write here

    event Transfer (address indexed from, address indexed to, uint tokenId);


    /**
     * Q.10
     * Declare an constructor which will take tokenName, tokenSymbol as a parameter and will init the name and symbol values.
    */

    // write here

    constructor (string memory tokenName, string memory tokenSymbol){
        _name = tokenName;
        _symbol = tokenSymbol;
    }


    /**
     * Q.10
     * Write a function named `balanceOf` which takes address as a parameter and returns the balance of that address
     * Check owner address is not zero address.
     * apply appropriate function visibility
    */

    // write here

    function balanceOf (address account) public view returns (uint){
        require (account != address (0),"Account address cannot be zero!");
        return _balances[account];
    }


    /**
     * Q.10
     * Write a function named `ownerOf` which takes the tokenId as parameter and returns the owner of that token
     * apply appropriate function visibility
    */

    // write here

    function ownerOf(uint tokenId) public view returns (address){
        return _owners[tokenId];
    }

    /**
     * Q.11
     * Write a function `getTokenName` which returns the name of the current token 
     * apply appropriate function visibility
    */

    // write here
    function getTokenName() public view returns(string memory){
        return _name;
    }


    /**
     * Q.12
     * Write a function `getTokenSymbol` which returns the symbol of the current token 
     * apply appropriate function visibility
    */

    // write here

    function getTokenSymbol() public view returns (string memory) {
        return _symbol;
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
    function approve(address spender, uint tokenId) public {
       address owner = ownerOf(tokenId);
        require (spender != owner,"You are already Approved!");
        require ( msg.sender == owner || isApprovedForAll(owner, msg.sender),"Caller is neither owner or approved for all!");
        _tokenApprovals[tokenId] = spender;
        emit Approval (owner, spender, tokenId);
    }



    /**
     * Q.14
     * Write a function `isApprovedForAll` which takes owner address and approved user address and returns true or false depending on whether the approved user has approval or not.
     * apply appropriate function visibility
    */
    function isApprovedForAll(address owner, address userApproved) public view returns (bool) {
        return _operatorApprovals[owner][userApproved];
    }


    /**
     * Q.15
     * Write a function `getApproved` which takes tokenId as parameter and returns the approved user address using tokenApprovals mapping
     * apply appropriate function visibility
    */

    // write here
    function getApproved (uint tokenId) public view returns (address){
        return _tokenApprovals[tokenId];
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
    function setApprovalForAll(address owner, address operatorApproved, bool approveStatus) public {
        require (owner != operatorApproved, "Caller is approved already!");
        _operatorApprovals[owner][operatorApproved] = approveStatus;
        emit ApprovalForAll(owner, operatorApproved, approveStatus);
    }


    /**
     * Q.17
     * Write a function `isApprovedOrOwner` which takes the spender address and tokenId and returns the boolean if the spender is owner or approved as spender
     * 
     * apply appropriate function visibility
    */

    // write here
    function isApprovedOrOwner (address spender, uint tokenId) internal view returns (bool){
        address owner = ownerOf(tokenId);
        return (owner == spender || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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

    function transfer (address from, address to, uint tokenId) public {
        
        if ( isApprovedOrOwner(from, tokenId)){
            require (ownerOf(tokenId)== from,"Cannot transfer from wrong address. Not an Owner");
            require (to != address(0),"Cannot transfer to a zero address!");
            delete _tokenApprovals[tokenId];

            _balances[from] -= 1;
            _balances[to] += 1;

            _owners[tokenId] = to;

            emit Transfer(from, to, tokenId);
        }
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

    function mint (address to, uint tokenId) public {

        require (to != address(0),"to address canot be zero!");
        require (ownerOf(tokenId) == address(0),"Token is already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
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

    function burn (uint tokenId) public {
        address owner = ownerOf(tokenId);
        require (msg.sender == owner, "Only owner can burn the token!");
        require (ownerOf(tokenId) != address(0), "Token Id does not exist!");
        delete _tokenApprovals[tokenId];
        _balances [owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner,address(0), tokenId);
    }


    
}