// SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.8.7;

import "./20Token.sol";
 
contract SHA_Token_ERC721 is Token {
    address owner;
    string public nameERC721;
    string public symbolERC721;
    uint public totalTokensERC721;
    uint public totalSupplyERC721;
 
    mapping(uint => uint) private tokenIndex;
    mapping(uint => bool) private tokenSellable;
    mapping(uint => uint) private tokenSellablePrise;
    mapping(uint => string) private tokenName;
    mapping(address => uint) private balancesERC721;
    mapping(uint => address) private tokenOwners;
    mapping(uint => bool) private tokenExists;
    mapping(address => mapping(uint => uint)) private ownerTokens;
    
    mapping(address => mapping (address => uint)) private allowedERC721;
    mapping(address => mapping(address => bool)) private allowedAll;
    
    modifier isExists(uint _tokenId){
        require(tokenExists[_tokenId] == true, "This token does not exist");
        _;
    }
    modifier isTokenOwner(address _from, uint _tokenId){
        require(_from == tokenOwners[_tokenId], "The specified address is not the owner of the token");
        _;
    }
    
    event TransferERC721(address indexed _from, address indexed _to, uint _tokenId);
    event ApprovalERC721(address indexed _owner, address indexed _approved, uint _tokenId);
    event ApprovalAllERC721(address indexed _owner, address indexed _operator, bool _approved);
    
    constructor(string memory _name, string memory _symbol, uint _totalTokens){
        owner = msg.sender;
        totalTokensERC721 = _totalTokens;
        totalSupplyERC721 = 0;
        symbolERC721 = _symbol;
        nameERC721 = _name;
    }
 
// ЭМИССИЯ ТОКЕНОВ
 
    function mintERC721(string memory _tokenName, address _to)public{
        require(msg.sender == owner, "You are not the owner of the contract");
        require(totalSupplyERC721 + 1 <= totalTokensERC721, "Issued maximum number of tokens");
        uint tokenId = uint(blockhash(block.number - 1)) / 10 + uint(keccak256(bytes(_tokenName))) / 10;
        require(tokenExists[tokenId] == false, "A token with this id already exists");
        
        tokenExists[tokenId] = true;
        tokenName[tokenId] = _tokenName;
        
        tokenOwners[tokenId] = _to;
        
        ownerTokens[_to][balancesERC721[_to]] = tokenId;
        balancesERC721[_to] += 1;
        
        tokenIndex[totalSupplyERC721] = tokenId;
        totalSupplyERC721 += 1;
    }
    
    function balanceOfERC721(address _owner) public view returns (uint){
        return balancesERC721[_owner];
    }
    
    function ownerOfERC721(uint _tokenId) public view isExists(_tokenId) returns (address){
        return tokenOwners[_tokenId];
    }
    
// РАЗРЕШЕНИЯ
    
    function approveERC721(address _to, uint _tokenId) public isTokenOwner(msg.sender, _tokenId) {
        require(msg.sender != _to, "The owner of the token cannot grant permission to himself");
        allowedERC721[msg.sender][_to] = _tokenId;
        emit ApprovalERC721(msg.sender, _to, _tokenId);
    }
 
    function cancelApproveERC721(address _to, uint _tokenId) public isExists(_tokenId) isTokenOwner(msg.sender, _tokenId) {
        require(msg.sender != _to, "The owner of the token cannot grant permission to himself");
        allowedERC721[msg.sender][_to] = 0;
        emit ApprovalERC721(msg.sender, _to, 0);
    }
    
    function setApprovalForAllERC721(address _operator, bool _approved) external{
        allowedAll[msg.sender][_operator] = _approved;
        emit ApprovalAllERC721(msg.sender, _operator, _approved);
    }
 
    function isApprovedForAllERC721(address _owner, address _operator) external view returns (bool){
        return allowedAll[_owner][_operator];
    }
    
// ТРАНСФЕР ТОКЕНОВ
 
    function transferERC721(address _from, address _to, uint256 _tokenId)internal{
        tokenOwners[_tokenId] = _to;
        
        uint index = 0;
        while(ownerTokens[_from][index] != _tokenId){
            index += 1;
        }
        for(uint i = index; i < balancesERC721[_from] - 1; i++){
            ownerTokens[_from][i] = ownerTokens[_from][i + 1];
        }
        
        ownerTokens[_to][balancesERC721[_to]] = _tokenId;
        
        balancesERC721[_from] -= 1;
        balancesERC721[_to] += 1;
        
        emit TransferERC721(_from, _to, _tokenId);
    }
    
    function transferFromERC721(address _from, address _to, uint256 _tokenId) external isExists(_tokenId) isTokenOwner(msg.sender, _tokenId) {
        require(msg.sender == _from, "The specified address is not the owner of the token");
        require(_to != address(0), "Can't send token to zero address");
        transferERC721(_from, _to, _tokenId);
    }
 
    function safeTransferFromERC721(address _from, address _to, uint256 _tokenId) external isExists(_tokenId) isTokenOwner(_from, _tokenId) {
        require(_tokenId == allowedERC721[_from][msg.sender] || allowedAll[_from][msg.sender] == true, "You do not have permission to dispose of this token");
        require(_to != address(0), "Can't send token to zero address");
        
        transferERC721(_from, _to, _tokenId);
        
        allowedERC721[_from][msg.sender] = 0;
    }

    function sellTokenERC721(address _from, uint256 _tokenId, uint cost) external{
        tokenSellable[_tokenId] = true;
        tokenSellablePrise[_tokenId] = cost;
    }

    function buyTokenERC721(address _to, uint256 _tokenId) external{
        require(IsSallableERC721(_tokenId));
        require(tokenSellablePrise[_tokenId] <= balances[_to]);
        transferERC721(tokenOwners[_tokenId], _to, _tokenId);
        transferERC20(tokenOwners[_tokenId], tokenSellablePrise[_tokenId]);
    }
 
// ИНФОРМАЦИЯ О ТОКЕНАХ
 
    function IsSallableERC721(uint256 _tokenId) public view returns(bool){
        return(tokenSellable[_tokenId]);
    }
    
    function tokenByIndexERC721(uint _index) external view returns (uint){
        require(_index < totalSupplyERC721, "A token with such an index does not exist");
        return tokenIndex[_index];
    }
    
    function tokenOfOwnerByIndexERC721(address _owner, uint _index) public view returns (uint tokenId){
        require(_index < balancesERC721[_owner], "The specified address does not have a token with this index");
        return ownerTokens[_owner][_index];
    }
    
    function getTokenNameByIdERC721(uint _tokenId)public view isExists(_tokenId) returns(string memory){
        return tokenName[_tokenId];
    }
}