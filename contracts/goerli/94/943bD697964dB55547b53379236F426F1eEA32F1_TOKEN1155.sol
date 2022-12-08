/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

pragma solidity 0.8.7;

contract TOKEN1155 {
    
    string public name;             //  variable to assign token name
    string public symbol;           //  variable to assign token symbol
    bytes32 public keyauth;        //  variable to assign keyauth
    
    mapping(uint256 => uint256) private _totalSupply;
    event RecordedData(address acct, string description, string data);
    
    address private contractOwner;
    
    
    /**
        @dev    modifier that requires that the sender must be the contract owner
    */
    
    modifier onlyContractOwner {
        require(
            msg.sender == contractOwner,
            "Only contractOwner can call this function."
        );
        _;
    }

    /**
        initializer to initialize in place of the constructor; the token name, token symbol, the contract owner and the token uri 

        @param _tokenName is the name assigned to the token on deployment
        @param _tokenSymbol is the symbol assigned to the token on deployment
        @param _uri is the token URI assigned on deployment

        @dev    the initialize function is used in place of the constructor to ensure that the contract is upgradable
    */

    function initialize(string memory _tokenName, string memory _tokenSymbol, string memory _uri, string memory _keyauth) public virtual  {
        
        contractOwner = msg.sender;         //  set contract owner
        name = _tokenName;                  //  set token name
        symbol = _tokenSymbol;              //  set token symbol
        // __ERC1155_init(_uri);               //  set token uri  ( upgradable safe )
       keyauth = sha256(abi.encode(_keyauth));

    }

    /**
        @dev    function to get the address of the contract owner
        @return contractOwner which is the address of the contract owner
    */

    function getContractOwner() public view returns (address) {
        return contractOwner;
    }


    /**
        @dev    function to mint tokens
        @notice new tokens can only be minted by the recipient or the contract owner
        
        @param account  is the recipient for the token
        @param tokenID  is the id of token to be minted
        @param tokencount is the amount of tokens to be minted
        @param key_auth is a signature message as another parameter to restrict only authorized user can execute this method
    */

   
    
    function createToken (address account, uint256 tokenID, uint256 tokencount, string memory uri ,bytes memory data, string memory key_auth) public {         
        require(keyauth == sha256(abi.encode(key_auth)),"Key does not match, Only authorized user can transfer");
        require(msg.sender == account || msg.sender == contractOwner,"Only authorized user can mint");
        // _mint(account, tokenID, tokencount,data);                 
        _totalSupply[tokenID] += tokencount;
    
    }
        
    
    // Reacord Data on blockchain  
    /*add signature message as another parameter to restrict only authorized user can execute this method*/

    function recordOnBlockchain(address acct, string memory email_id, string memory data, string memory key_auth) public  {
        require(keyauth == sha256(abi.encode(key_auth)), "Key does not match, Only authorized user can write");
        require(msg.sender == acct || msg.sender == contractOwner,"Only authorized user can record");
        emit RecordedData(acct,email_id,data);
    } 


    
    /**
        function to burn the token can only be called by contractOwner or _walletApproved
    */
    function burnToken(address account,uint256 tokenID, uint256 amount,string memory key_auth) public {
        
        require(keyauth == sha256(abi.encode(key_auth)), "Key does not match, Only authorized user can burn");
        // require(balanceOf(account, tokenID) > 0, "No tokens to burn in this wallet");
        // _burn(account,tokenID,amount);
        _totalSupply[tokenID] -= amount;
    
    }
    
    
        /**
     * @dev Total amount of tokens in with a given companyID.
     */
    function totalSupply(uint256 tokenID) public view  returns (uint256) {
        return _totalSupply[tokenID];
    }

    /**
     * @dev Indicates weither any token exist with a given id, or not.
     */
    function exists(uint256 tokenID) public view  returns (bool) {
        return totalSupply(tokenID) > 0;
    }
    
    
        /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from,address to,uint256[] memory ids,uint256[] memory amounts,bytes memory data,string memory key_auth) public {
        require(keyauth == sha256(abi.encode(key_auth)), "Key does not match, Only authorized user can transfer");
        // require(from == _msgSender() || isApprovedForAll(from, _msgSender()),"ERC1155: transfer caller is not owner nor approved" );
        
            // _safeBatchTransferFrom(from, to, ids, amounts, data);
        
        
    }
    
          /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
     /*add signature message as another parameter to restrict only authorized user can execute this method*/
    function safeTransferFrom(address from,address to,uint256 id,uint256 amount,bytes memory data,string memory key_auth) public virtual /*override*/  {
        require(keyauth == sha256(abi.encode(key_auth)), "Key does not match, Only authorized user can transfer");
        // require(msg.sender == contractOwner || msg.sender == from || from == _msgSender() || isApprovedForAll(from, _msgSender()),"ERC1155: caller is not owner nor approved");
        
            // _safeTransferFrom(from, to, id, amount, data);
    }
    
     
    // contract recieving ether
    //The function cannot have arguments, cannot return anything and must have external visibility and payable state mutability.
    receive() external payable {
        // React to receiving ether
    }


    function setKeyAuth(string memory _keyauth) public onlyContractOwner {
        //keyauth = _keyauth;
        keyauth = sha256(abi.encode(_keyauth));
    }

    
    function transferContractownership(address _address) public onlyContractOwner
    {
        contractOwner = _address;
    }
    
    
    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }

    assembly {
        result := mload(add(source, 32))
    }
}   
}