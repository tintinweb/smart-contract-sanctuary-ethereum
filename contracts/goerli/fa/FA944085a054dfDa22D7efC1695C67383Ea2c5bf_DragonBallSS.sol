// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";


contract DragonBallSS is ERC721{
    string public name;
    string public symbol;
    uint256 public tokenCount;


    mapping(uint256 => string) private _tokenURIs;


    constructor(string memory _name,string memory _symbol){
        name =_name;
        symbol = _symbol;
    }


    // https: url : consist all the information regarding metadata

    function tokenURI(uint256 _tokenId) public view returns(string memory){
        require(_owners[_tokenId] != address(0), "Token ID doesnot exist");
        return _tokenURIs[_tokenId];
    }

    // create a new NFT inside out collection
    function mint(string memory _tokenURI) public{
        tokenCount+=1;
        _balances[msg.sender] += 1;
        _owners[tokenCount] = msg.sender;
        _tokenURIs[tokenCount] = _tokenURI;
        emit Transfer(address(0), msg.sender,tokenCount);
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns(bool){
        return interfaceId == 0x5b5e139f || interfaceId == 0x80ac58cd;
    }


}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract ERC721{

    mapping(address =>uint256) internal _balances;
    mapping(uint256 => address) internal _owners;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(uint256 => address) private _tokenApprovals;

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    // returns the number of NFT's assigned to an owner 
    function balanceOf(address _owner) public view returns (uint256){
       require(_owner != address(0),"Address is invalid");
        return _balances[_owner];
    }

    //  Finds the owner of an NFT
    function ownerOf(uint256 _tokenId) public view returns (address){
        address owner = _owners[_tokenId];
        require(owner != address(0),"Token Id is invalid");
        return owner;
    }

    // Enables or disables an operator to manage all of the msg.senders assets

    function setApprovalForAll(address _operator, bool _approved) external {
       _operatorApprovals[msg.sender][_operator] = _approved;
       emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    //  checks if an address is an operator for another address
    function isApprovedForAll(address _owner, address _operator) public view returns (bool){
        return _operatorApprovals[_owner][_operator];
    }

    // updates an approved address for an NFTs

    function approve(address _approved, uint256 _tokenId) public payable{
        address owner = ownerOf(_tokenId);
        require(msg.sender == owner || isApprovedForAll(owner,msg.sender),"Msg.sender is not the owner or operator");
        _tokenApprovals[_tokenId] = _approved;
        emit Approval(owner,_approved,_tokenId);        
    }
    // gets the approved address for a single NFTs
    function getApproved(uint256 _tokenId) public view returns (address){
        require(_owners[_tokenId] != address(0),"Token ID is invalid");
        return _tokenApprovals[_tokenId];
    }

    // Transfers ownership of an NFT

    function transferFrom(address _from, address _to, uint256 _tokenId) public payable{
        address owner = ownerOf(_tokenId);
        require(
            msg.sender == owner || 
            getApproved(_tokenId) == msg.sender ||
            isApprovedForAll(owner,msg.sender),
            "msg.sender is not owner or approved address for transfer"
        );

        require(owner == _from, "From address is not the owner");
        require(_to != address(0), "Addressis zero address");

        approve(address(0), _tokenId);

        _balances[_from] -= 1;
        _balances[_to] += 1;
        _owners[_tokenId] = _to;
        emit  Transfer( _from, _to, _tokenId);

    }

    // standard transferFrom
    // check id onERC721Received is implemented when sending to smart contracts

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public payable{
        transferFrom(_from,_to,_tokenId);
        require(_checkOnERC721Received(),"Reciever not immplemented");
    }

    

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable{
        safeTransferFrom(_from,_to,_tokenId,"");
    }

    // Oversimplefied

    function _checkOnERC721Received() private pure returns (bool){
        return true;
    }


    function supportsInterface(bytes4 _interfaceId) public pure virtual returns (bool){
        return _interfaceId == 0x80ac58cd;
        
    }
}