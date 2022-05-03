/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ERC721TokenReceiver {

  /**
   * @dev Handle the receipt of a NFT. The ERC721 smart contract calls this function on the
   * recipient after a `transfer`. This function MAY throw to revert and reject the transfer. Return
   * of other than the magic value MUST result in the transaction being reverted.
   * Returns `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))` unless throwing.
   * @notice The contract address is always the message sender. A wallet/broker/auction application
   * MUST implement the wallet interface if it will accept safe transfers.
   * @param _operator The address which called `safeTransferFrom` function.
   * @param _from The address which previously owned the token.
   * @param _tokenId The NFT identifier which is being transferred.
   * @param _data Additional data with no specified format.
   */
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns(bytes4);
}

contract BitTower {
    address constant internal NULL_ADDRESS = 0x0000000000000000000000000000000000000000;
    
    // ERC721 requires ERC165
    mapping(bytes4 => bool) internal supportedInterfaces;
    
    // ERC721
    mapping (uint256 => address) internal idToOwner;
    mapping (uint256 => address) internal idToApprovals;
    mapping (address => uint256) internal ownerToNFTokenCount;
    mapping (address => mapping (address => bool)) internal ownerToOperators;
    bytes4 constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    // IERC721Enumerable
    
    
    // ERC721Metadata
    string constant public name = "BitTower";
    string constant public symbol = "BITT";
    
    // Custom
    string internal baseUri = "https://bit-tower-bit-tower-business.vercel.app/api/floor/";
    uint256[] internal tokenIDs;
    mapping (uint256 => address) public originalTokenOwner;

    mapping (address => bool) public preLaunchWhitelisted;
    uint256 public mintCost = 0.09 ether;
    uint256 public startTime = 0; // unixTime
    uint256 public maxTotalSupply = 100;

    address internal owner;
    address internal newOwner;
    
    
    
    // ERC721 Events
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );
    
    // Used for approvals
    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender], "ERR_ERC721_NOT_OWNED_OR_APPROVED");
        _;
    }
    // Self-explanitory
    modifier canTransfer(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tokenOwner == msg.sender
            || getApproved(_tokenId) == msg.sender
            || ownerToOperators[tokenOwner][msg.sender],
            "ERR_ERC721_NOT_OWNED_OR_APPROVED"
        );
        _;
    }
    // Unminted tokens are invalid. These can't be burned anyway
    modifier validNFToken(uint256 _tokenId) {
        require(idToOwner[_tokenId] != NULL_ADDRESS, "ERR_ERC721_NONEXISTANT");
        _;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "ERR_BITT_ONLY_OWNER");
        _;
    }

    modifier onlyPostLaunch {
        require(block.timestamp > startTime || preLaunchWhitelisted[msg.sender], "ERR_BITT_TOO_EARLY");
        _;
    }
    
    constructor(uint256 _startTime) {
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        supportedInterfaces[0x5b5e139f] = true; // ERC721Metadata
        supportedInterfaces[0x780e9d63] = true; // ERC721Enumerable
        startTime = _startTime;
        owner = msg.sender;
    }
    
    // Custom functions
    function setNewOwner(address o) public onlyOwner {
        newOwner = o;
    }
    
    function acceptNewOwner() public {
        require(msg.sender == newOwner);
        owner = msg.sender;
    }

    function setBaseUri(string memory _uri) public onlyOwner {
        baseUri = _uri;
    }

    function setMintCost(uint256 _cost) public onlyOwner {
        mintCost = _cost;
    }

    function setMaxTotalSupply(uint256 _maxSupply) public onlyOwner {
        maxTotalSupply = _maxSupply;
    }

    function addToPreLaunch(address[] memory _addresses) public onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i += 1){
            preLaunchWhitelisted[_addresses[i]] = true;
        }
    }

    function withdrawFunds() public onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }

    function payToMint(address recipient, uint256 _tokenId) public payable onlyPostLaunch {
        require(msg.value >= mintCost, "ERR_BITT_UNDERPAY");
        _mint(recipient, _tokenId);
    }

    function allNFTsMintedSoFar() public view returns (uint256[] memory, address[] memory) {
        // return idToOwner.length;
        uint256[] memory resultTokenIDs = new uint256[](tokenIDs.length);
        address[] memory resultOwners = new address[](tokenIDs.length);
        for(uint256 i = 0; i < tokenIDs.length; i += 1){
            resultTokenIDs[i] = tokenIDs[i];
            resultOwners[i] = idToOwner[tokenIDs[i]];
        }
        return (resultTokenIDs, resultOwners);
    }
    
    // ERC721Enumerable functions
    
    function totalSupply() external view returns(uint256) {
        return tokenIDs.length;
    }
    
    function tokenOfOwnerByIndex(uint256 _index) external view returns(address _owner) {
        require(_index < tokenIDs.length, "ERR_BITT_INDEX_OUT_OF_BOUNDS");
        _owner = idToOwner[tokenIDs[_index]];
    }
    
    function tokenByIndex(uint256 _index) public view returns (uint256) {
        require(_index < tokenIDs.length, "ERR_BITT_INDEX_OUT_OF_BOUNDS");
        return tokenIDs[_index];
    }
    
    // ERC721Metadata functions
    
    function tokenURI(uint256 _tokenId) validNFToken(_tokenId) public view returns (string memory) {
        return concatStrings(baseUri, uint256ToString(_tokenId));
    }

    function tokenProperty(uint256 _tokenId) validNFToken(_tokenId) public view returns (uint256) {
        // no token data is stored on chain
        return 0;
    }
    
    // ERC721 functions
    
    function balanceOf(address _owner) external view returns(uint256) {
        require(_owner != NULL_ADDRESS, "ERR_ERC721_NULL_ADDRESS");
        return ownerToNFTokenCount[_owner];
    }
    
    function ownerOf(uint256 _tokenId) external view returns(address _owner){
        _owner = idToOwner[_tokenId];
        require(_owner != NULL_ADDRESS, "ERR_ERC721_NONEXISTANT");
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }
    
    function supportsInterface(bytes4 _interfaceID) external view returns(bool) {
        return supportedInterfaces[_interfaceID];
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenId) external canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, "ERR_ERC721_OWNER_MISMATCH");
        require(_to != NULL_ADDRESS, "ERR_ERC721_NULL_ADDRESS");
        _transfer(_to, _tokenId);
    }
    
    function approve(address _approved, uint256 _tokenId) external canOperate(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(_approved != tokenOwner, "ERR_ERC721_SELF_APPROVE");
        
        idToApprovals[_tokenId] = _approved;
        emit Approval(tokenOwner, _approved, _tokenId);
    }
    
    function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != NULL_ADDRESS);
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    
    function getApproved(uint256 _tokenId) public view validNFToken(_tokenId) returns (address){
        return idToApprovals[_tokenId];
    }
    
    function isApprovedForAll(address _owner, address _operator) external view returns(bool) {
        require(_owner != NULL_ADDRESS);
        require(_operator != NULL_ADDRESS);
        return ownerToOperators[_owner][_operator];
    }
    
    // Internal/private functions

    function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) internal canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, "ERR_ERC721_OWNER_MISMATCH");
        require(_to != NULL_ADDRESS, "ERR_ERC721_NULL_ADDRESS");
        
        _transfer(_to, _tokenId);
        
        if (isContract(_to)) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == MAGIC_ON_ERC721_RECEIVED);
        }
    }
    
    function _mint(address _to, uint256 _tokenId) private {
        require(_to != NULL_ADDRESS, "ERR_ERC721_NULL_ADDRESS");
        require(idToOwner[_tokenId] == NULL_ADDRESS, "ERR_BITT_ALREADY_MINTED");
        require(tokenIDs.length < maxTotalSupply, "ERR_BITT_MAX_SUPPLY");
        require(_tokenId >= 1  && _tokenId <= maxTotalSupply, "ERR_BITT_TOKEN_ID_OUT_OF_RANGE");
        tokenIDs.push(_tokenId);
        idToOwner[_tokenId] = _to;
        unchecked {
            // No individual user's balance will ever exceed 2 ** 256 - 1
            ownerToNFTokenCount[_to] += 1;
        }
        
        originalTokenOwner[_tokenId] = _to;
        emit Transfer(NULL_ADDRESS, _to, _tokenId);
    }

    function _transfer(address _to, uint256 _tokenId) private {
        address from = idToOwner[_tokenId];
        clearApproval(_tokenId);
        unchecked {
            // These will never underflow or overlow
            ownerToNFTokenCount[from] -= 1;
            ownerToNFTokenCount[_to] += 1;
        }
        idToOwner[_tokenId] = _to;
        emit Transfer(from, _to, _tokenId);
    }
    
    function clearApproval(uint256 _tokenId) private {
        if(idToApprovals[_tokenId] != NULL_ADDRESS){
            delete idToApprovals[_tokenId];
        }
    }
    
    // If bytecode exists at _addr then the _addr is a contract.
    function isContract(address _addr) internal view returns(bool) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length > 0);
    }
    
    // Functions used for generating the URI
    function amountOfZeros(uint256 num, uint256 base) internal pure returns(uint256) {
        uint256 result = 0;
        num /= base;
        while(num > 0) {
            num /= base;
            result += 1;
        }
        return result;
    }
    
    function uint256ToString(uint256 num) internal pure returns(string memory) {
        if (num == 0){
            return "0";
        }
        uint256 numLen = amountOfZeros(num, 10) + 1;
        bytes memory result = new bytes(numLen);
        while(num != 0) {
            numLen -= 1;
            result[numLen] = bytes1(uint8((num - (num / 10 * 10)) + 48));
            num /= 10;
        }
        return string(result);
    }
    
    function concatStrings(string memory str1, string memory str2) internal pure returns (string memory) {
        uint256 str1Len = bytes(str1).length;
        uint256 str2Len = bytes(str2).length;
        uint256 resultLen = str1Len + str1Len;
        bytes memory result = new bytes(resultLen);
        uint256 i;
        
        for(i = 0; i < str1Len; i += 1) {
            result[i] = bytes(str1)[i];
        }
        for(i = 0; i < str2Len; i += 1) {
            result[i + str1Len] = bytes(str2)[i];
        }
        return string(result);
    }
}