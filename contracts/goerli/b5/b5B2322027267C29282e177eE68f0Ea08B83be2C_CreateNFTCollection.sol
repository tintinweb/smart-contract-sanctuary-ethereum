// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./Erc721.sol";

contract CreateNFTCollection is Erc721{
  string private _name;
  string private _symbol;
  uint256 private _tokenId;
  // object to hold the uri for tokens
  mapping(uint256 => string) _tokenURIs;
  
  constructor(string memory name_, string memory symbol_){
    _name = name_;
    _symbol = symbol_;
  }

  function name() external view returns(string memory) {
    return _name;
  }

  function symbol() external view returns(string memory) {
    return _symbol;
  }

  function tokenURI(uint256 _tokenId) external view returns (string memory) {
    // check if token is valid
    require(_ownerOf[_tokenId] != address(0), "Invalid Token");

    return _tokenURIs[_tokenId];
  }

  /*
  Add a NFT in the collection
    - update balance of sender/caller
    - update owner of token
    - update tokenURI of token
  */ 
  function mint(string memory _tokenURI) external { 
    _balanceOf[msg.sender] += 1;
    _ownerOf[_tokenId] = msg.sender;
    _tokenURIs[_tokenId] = _tokenURI;
    emit Transfer(address(0), msg.sender, _tokenId);

    _tokenId += 1;
  }

  function supportsInterface(bytes4 _interfaceId) public pure override returns(bool) {
      return _interfaceId == 0x80ac58cd || _interfaceId == 0x5b5e139f;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Erc721{
    // object to hold no. of nft's held by address
    mapping(address => uint256) internal _balanceOf;
    // object to hold owner's address of nft
    mapping(uint256 => address) internal _ownerOf;
    // object to hold the approver of a nft
    mapping(uint256 => address) internal _approverOf;
    // object to hold the approver of all the nft of a user
    mapping(address => mapping(address => bool)) _approverOfAll;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    
    // get amount of nft held by a address
    function balanceOf(address _owner) external view returns(uint256){
      require(_owner != address(0), "Invalid address");

      return _balanceOf[_owner];
    } 

    // get the owner address of a nft
    function ownerOf(uint256 _tokenId) public view returns(address){
      address owner = _ownerOf[_tokenId];
      require(owner != address(0), "Invalid token");

      return owner;
    }

    // set the operator for all the nft's held by a address
    function setApprovalForAll(address _operator, bool _approved) external{
      require(_operator != address(0), "Invalid Address");

      _approverOfAll[msg.sender][_operator] = _approved;
      emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    // check if a address is a operator for the onwer address
    function isApprovedForAll(address _owner, address _operator) public view returns(bool){
      return _approverOfAll[_owner][_operator];
    }

    // set the approver access for a nft held by the owner address
    function approve(address _approved, uint256 _tokenId) public payable{
      address owner = ownerOf(_tokenId);
      require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "Unauthorised");

      _approverOf[_tokenId] = _approved;
      emit Approval(owner, _approved, _tokenId);
    }

    // get the approver address of a nft 
    function getApproved(uint256 _tokenId) public view returns(address){
      require(_ownerOf[_tokenId ] != address(0), "Inavlid token");

      return _approverOf[_tokenId];
    }

    /*
    Pre transfer checks
      - check if it's a valid nft
      - check if the from address is the owner 
      - check if the sender/caller is a authorised person
      - check if to is a valid address
    Transfer
      - update owner address for nft
      - delete the approver of nft set by the sender
      - update count of nft held by sender and receiver
    */
    function transferFrom(address _from, address _to, uint256 _tokenId) public payable {
      address owner = ownerOf(_tokenId);
      require(_from == owner, "From address is not the owner of token");
      require(msg.sender == _from || msg.sender == getApproved(_tokenId) || isApprovedForAll(_from, msg.sender), "Unauthorised");
      require(_to != address(0), "Invalid to address");

      _ownerOf[_tokenId] = _to;
      delete _approverOf[_tokenId];
      _balanceOf[_from] -= 1;
      _balanceOf[_to] += 1;
      emit Transfer(_from, _to, _tokenId);
    }
    
    /*
      ** to be complete **
      to check if the receiver address is contract
    */ 
    function onERC721Received () private pure returns(bool) {
      return true;
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public payable {
      transferFrom(_from, _to, _tokenId);
      require(onERC721Received(), "Receiver not implemented");
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable {
      safeTransferFrom(_from, _to, _tokenId, "");
    }

    function supportsInterface(bytes4 _interfaceId) public pure virtual returns(bool) {
      return _interfaceId == 0x80ac58cd;
    }
}