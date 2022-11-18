/**
 *Submitted for verification at Etherscan.io on 2022-11-18
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
//import './ERC721.sol';

contract IERC721 {

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => address) internal _owners;
    mapping(uint256 => address) private _tokenApprovals;


    function balanceOf(address _owner) public view returns (uint256){
        require(_owner != address(0), "Not valid addresss");
        return _balances[_owner];
    }
    function ownerOf(uint256 _tokenId) internal view returns (address){
        address admin = _owners[_tokenId];
        require(admin != address(0), "Token id is not Valid");
        return admin;
    }
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public {
        transferFrom(_from, _to, _tokenId);
        require(_checkOnERC721Received(), "Reciever not implement");
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable {
        safeTransferFrom(_from, _to, _tokenId, "");
    }
    function transferFrom(address _from, address _to, uint256 _tokenId) public payable{
        address owner = ownerOf(_tokenId);
        require(owner == _from, "You are not the owner of this token");

        require(_to != address(0), "Not valid address");
        approve(address (0), _tokenId);
        _balances[_from] -= 1;
        _balances[_to] += 1;
        _owners[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }
    function approve(address _approved, uint256 _tokenId) public payable{
        address owner = ownerOf(_tokenId);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "Not approved");
        _tokenApprovals[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }
    function setApprovalForAll(address _operator, bool _approved) external{
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    function getApproved(uint256 _tokenId) external view returns (address){
        require(_owners[_tokenId] != address(0), "Token id is not vaid");
        return _tokenApprovals[_tokenId];
    }
    function isApprovedForAll(address _owner, address _operator) internal view returns (bool){
        return _operatorApprovals[_owner][_operator];
    }

    function _checkOnERC721Received() private pure returns(bool) {
        return true;
    }
//  EIP165: Query if contract implemented another interface
    function _supportInterface(bytes4 interfaceId) public pure virtual returns(bool) {
        return interfaceId == 0x80ac58cd;
    }
}



contract NFT is IERC721 {
    string public _name;
    string public _symbol;
    uint256 public tokenCount;
    address public owner;
    
    mapping(uint256 => string) private _tokenUris;

    constructor(string memory name, string memory symbol)  {
        _name = name;
        _symbol = symbol;
    }

    function tokenURI(uint256 tokenId) public view returns(string memory) {
        require(_owners[tokenId] != address(0), "Token id is not valid or doesn't exist!");
        return _tokenUris[tokenId];
    }

    function _supportInterface(bytes4 interfaceID) public pure override returns(bool) {
        return  interfaceID == 0x01ffc9a7 || interfaceID == 0x80ac58cd  ;
    }

    function mint(string memory tokenUri) public {
        tokenCount += 1;
        _balances[msg.sender] += 1;
        _owners[tokenCount] = msg.sender;
        _tokenUris[tokenCount] = tokenUri;

        emit Transfer(address(0), msg.sender, tokenCount);
    }

    function checkBalance(address _owner) public view returns(uint256) {
        return balanceOf(_owner);
    }

    function get_owner() public view returns(address) {
        return owner;
    }
}