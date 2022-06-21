/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

//SPDX-License-Identifier: MIT
pragma solidity  0.8.14;

contract YounityNFT {

    string name_;
    string symbol_;
    uint256 tokenCounter;

    constructor (string memory _name, string memory _symbol) {
        name_ = _name;
        symbol_ = _symbol;
    }

    mapping (address => uint256) balances;  // mapping of an address to number of NFT held in contract
    mapping (uint256 => address) owners;    // Mapping of tokenId to its owner address
    // Mapping for owner to operator to status of approval for all NFT's in contract.
    mapping (address => mapping (address => bool)) operatorApproval;    
    mapping (uint256 => address) tokenApprovals; // Mapping of tokenId to spender address.
    mapping (uint256 => string) _tokenURI;
    mapping (address => uint256[]) myTokens;

    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    
    // Mint a NFT
    function mint(string memory _url) public {
        tokenCounter++; // tokenId
        balances[msg.sender] += 1;
        owners[tokenCounter] = msg.sender;
        _tokenURI[tokenCounter] = _url;
        myTokens[msg.sender].push(tokenCounter); // creator

        emit Transfer(address(0), msg.sender, tokenCounter);
    }
    function bulkMint(string[] memory _urls) public {
        for (uint i=0; i<_urls.length; i++){
            tokenCounter++;
            balances[msg.sender] += 1;
            owners[tokenCounter] = msg.sender;
            _tokenURI[tokenCounter] = _urls[i];
            myTokens[msg.sender].push(tokenCounter);
            emit Transfer(address(0), msg.sender, tokenCounter);
        }
    }
    function bulkMint2(string[] memory _urls) public {
        for(uint i=0; i<_urls.length; i++){
            mint(_urls[i]);
        }
    }

    function viewMyNFTs() public view returns (uint256[] memory) {
        return myTokens[msg.sender];
    }

    //Count all NFTs assigned to an owner
    function balanceOf(address _owner) public view returns (uint256){
        require(_owner != address(0), "Address zero not allowed");
        return balances[_owner];
    }

    //Find the owner of an NFT
    function ownerOf(uint256 _tokenId) external view returns (address) {
        address owner = owners[_tokenId];
        require(owner != address(0), "NFTs assigned to zero address" );
        return owner;
    }

    //Enable or disable approval for a third party ("operator") to manage all of `msg.sender`'s assets
    function setApprovalForAll(address _operator, bool _approved) external {
        require( msg.sender != _operator, "Cannot set approval to self");
        operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender,_operator,_approved);
    }
    function isApprovedForAll(address _owner, address _operator) public view returns (bool){
        return operatorApproval[_owner][_operator];
    }

    function approve(address _approved, uint256 _tokenId) public payable{
        address owner = owners[_tokenId];
        require(_approved != owner, "Can't approve to current owner");
        require(msg.sender == owner || isApprovedForAll(owner,msg.sender), "Caller is neither owner nor approved operator" );
        tokenApprovals[_tokenId] = _approved;
        emit Approval(owner,_approved,_tokenId);
    }

    //Get the approved address for a single NFT
    function getApproved(uint256 _tokenId) public view returns (address) {
        require(_exists(_tokenId), "Token Id does not exist");
        return tokenApprovals[_tokenId];
    }

    function _exists(uint256 _tokenId) internal view returns(bool) {
        return owners[_tokenId] != address(0);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public payable{
        require(_isApprovedOrOwner(msg.sender,_tokenId), "Caller is not owner or operator or approved");
        require(_from == owners[_tokenId], "Transfer not from owner");
        require(_to != address(0), "Sender address is a zero address");
        // Clear approvals from existing owner
        approve(address(0),_tokenId);
        balances[_from] -= 1;
        balances[_to] += 1;
        owners[_tokenId] = _to;
        myTokens[_to].push(_tokenId);
        require( _onERC721Received(), "Oversimplified");
        emit Transfer(_from,_to,_tokenId);

    }
    //Oversimplified
    function _onERC721Received () private pure returns(bool) {
        return true;
    }

    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns(bool){
        require(_exists(_tokenId), "Token Id does not exists");
        address owner = owners[_tokenId];
        return (_spender == owner || isApprovedForAll(owner,_spender) || getApproved(_tokenId)== _spender);
    }
    
    function name() external view returns (string memory _name){
        return name_;
    }
    
    function symbol() external view returns (string memory _symbol){
        return symbol_;
    }
    
    function tokenURI(uint256 _tokenId) external view returns (string memory){
        require( owners[_tokenId] != address(0), "Token Id does not exist");
        return _tokenURI[_tokenId];
    }

     // Array with all token ids, used for enumeration
    uint256[] private allTokens;

    function totalSupply() public view returns (uint256){
        return allTokens.length;
    }
    // Enumerate valid NFTs
    function tokenByIndex(uint256 _index) external view returns (uint256){
        require(_index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return allTokens[_index];
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private ownedTokens;

    // Enumerate NFTs assigned to an owner
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256){
        require(_index < balanceOf(_owner), "ERC721Enumerable: owner index out of bounds");
        return ownedTokens[_owner][_index];
    }
    // EIP165 : Query if a contract implements another interface
    function supportsInterface(bytes4 interfaceID) public pure returns (bool){
        return interfaceID == 0x80ac58cd || interfaceID == 0x5b5e139f;
    }

}

//bulkMint of 2 NFT - 367445
// bulkMint2 of 2 NFT - 316269
// mint of 1 NFT - 175204 ( 350408)