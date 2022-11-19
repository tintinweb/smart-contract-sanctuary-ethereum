// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC721 {
    //follow this website to get methods
    // https://eips.ethereum.org/EIPS/eip-721

    mapping(address => uint256) internal _balances;
    mapping(uint256 => address) internal _owners;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => address) private _tokenApprovals;

    //events
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    //check the balance
    function balanceOf(address _owner) public view returns (uint256) {
        // https://stackoverflow.com/questions/48219716/what-is-address0-in-solidity
        require(_owner != address(0), "Address is invalid");
        return _balances[_owner];
    }

    //its is like having a joint account
    // example
    // if their is a collection id {
    //     1,2,3,,4,5,6,
    // }
    // if 1,2,3 belong to 0x1
    // to this i am adding another account 0x2 i.e 0x1 => 0x2 now both account has the accesible to {1,2,3} id's
    function setApprovalForAll(address _operator, bool _approved) external {
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    // if we have a collection then their might be multiple nft each one will have diffrent id
    //so here we r fetching the token id and returing the address of the owner
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = _owners[_tokenId];
        require(owner != address(0), "token iD is not valid");
        return owner;
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        returns (bool)
    {
        return _operatorApprovals[_owner][_operator];
    }

    //like in setApprove all if u dont want to approve all the nft then just approve sign NFT so approve funtion is used
    function approve(address _approved, uint256 _tokenId) public payable {
        address owner = ownerOf(_tokenId);
        require(msg.sender == owner || isApprovedForAll(owner,msg.sender),"MSG.SENDER is not owner or operator");
        _tokenApprovals[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }

    function getApproved(uint256 _tokenId) public view returns (address) {
        require(_owners[_tokenId] != address(0), "Token id is invalid");
        return _tokenApprovals[_tokenId];
    }

    // transferiing the ownership
    // 0x1 => tokenid (NFT) = 1
    // 0x2 => tokenid =  1

    //now transferiing the token if=d from 0x2 to 0x3
    // 0x3 => tokenid =1

    function transferFrom(
        address _from,
        address _to,
        uint256 tokenId
    ) public payable {
        address owner = ownerOf(tokenId);
        require(
            msg.sender == owner ||
                getApproved(tokenId) == msg.sender ||
                isApprovedForAll(owner, msg.sender),
            "Msg.sender is not owner or approved for transfer"
        );

        require(owner == _from, "From address is not the owner");
        require(_to != address(0), "Address is zero address");

        //resetting the approve we still dont need the old owner so
        approve(address(0), tokenId);
        _balances[_from] -= 1;
        _balances[_to] += 1;
        _owners[tokenId] = _to;

        emit Transfer(_from, _to, tokenId);
    }

    // when u transfering the the NFT to an account address u can directly do it without any checks
    //but whne u transfer it to an contract we need to use reciver funtion if a contract is going to ecive sm Nft they have to implement this reciver function in ERC721

    //If you trying to send an nft to an contract if that contract doesnot have this revice funtion then The nfT will be lost and we cant see it
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) public payable {
        //checking the address for knwoing is it a contract address or uia address if conditon not met then they will roll back the funtion the transfer will not execute
        require(_checkOnErc721Received(), "Reciver not implemented");
    }

    function _checkOnErc721Received() private pure returns (bool) {
        return true;
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        returns (bool)
    {
        return interfaceId == 0x80ac58cd;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
//in wwe.json i have used pinata to store data in IPFS pinata gives free 1gb storage 
//use of pinata is . when u upload smthing direcctly in ipfs if that file is not accessed in while time they get deleted , so what pinata does is it try to pin this data in ipfs so that it stay for more time 

contract WWE is ERC721 {
    string public name;

    string public symbol;

    uint256 public tokenCount;
    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    //retuns token URI
    // that is basically https url :consist of all the info regarding metadata
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        //see erc721 coontract of _owner which is retuning the address
        require(_owners[_tokenId] != address(0), "Token doesnot exist");
        return  _tokenURIs[_tokenId];
    }

    //create a new NFT inside our collection
    function mint(string memory _tokenURI) public{
        tokenCount +=1;
        _balances[msg.sender] +=1;
        _owners[tokenCount] = msg.sender;
        _tokenURIs[tokenCount] = _tokenURI;

        emit Transfer(address(0), msg.sender, tokenCount);
    }

//we have added override because we r trying to overrise the funtion which is inherited
    function supportsInterface(bytes4 interfaceId) public pure override returns(bool){
        //saying that our contract is supported by this two interfaces
        // y two id becuase one is for meta data id and another is for ERC721 id
        return interfaceId == 0x5b5e139f  || interfaceId == 0x80ac58cd;
    }
}