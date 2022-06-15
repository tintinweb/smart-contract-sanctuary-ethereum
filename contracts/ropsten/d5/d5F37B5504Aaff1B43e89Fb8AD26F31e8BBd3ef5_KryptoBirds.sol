// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import './ERC721Connector.sol';

contract KryptoBirds is ERC721Connector {
    string [] public kryptoBirdz;
  //  mapping(string => bool) _kryptoBirdzExists;

    constructor() ERC721Connector('KryptoBirds','KBIRDS'){
      
    }
     
     function mint(string memory _kryptobirdz) public {
         // require(!_kryptoBirdzExists[_kryptobirdz],"Error! Krypto Birdz already Exists");

         kryptoBirdz.push(_kryptobirdz);
         uint _id = kryptoBirdz.length - 1;
         //_kryptoBirdzExists[_kryptobirdz] = true;
         _mint(msg.sender,_id);
     }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import './ERC721Metadata.sol';
import './ERC721Enumerable.sol';

contract ERC721Connector is ERC721Metadata,ERC721Enumerable {

constructor(string memory name, string memory symbol) ERC721Metadata(name,symbol){

}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract ERC721Metadata {
    string private _name;
    string private _symbol;
    constructor(string memory named, string memory symbolified){
     _name = named;
     _symbol=symbolified;
    }
    function name() external view returns (string memory){
        return _name;
    }
    function symbol() external view returns(string memory){
        return _symbol;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import './ERC721.sol';
contract ERC721Enumerable is ERC721 {

    uint256[] private _allTokens;

    // mapping from tokenId to position in _allTokens array
     mapping(uint256 => uint256) private _allTokensIndex; 
    // mapping of owner to list of all owner token ids
     mapping(address => uint256[]) private _ownedTokens;
    // mapping from token ID to index of the owner token list
      mapping(uint256 => uint256) private _ownedTokensIndex;

   
   // function tokenByIndex(uint256 _index) external view returns (uint256);

   
    //function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);

    function _mint(address to,uint256 tokenId) internal override(ERC721){
        super._mint(to,tokenId);
        // A. Add token to the owner
        // B. all tokens to our totalSupply - to allTokens
       _addTokensToAllTokenEnumeration(tokenId);
       _addTokensToOwnerEnumeration(to,tokenId);
    }
    function _addTokensToAllTokenEnumeration(uint256 tokenId) private{
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }
    function _addTokensToOwnerEnumeration(address to, uint256 tokenId) private{
        // 1. Add address and token id to the _ownedToken
        // 2. ownedTokensIndex tokenId set to address of ownedTokens position
        // 3. we want to execute this funciton with miniting
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);

    }
    function tokenByIndex(uint256 index) public view returns(uint256){
        require(index < totalSupply(), "global index is out of bound");
        return _allTokens[index];
    }
    function tokenOfOwnerByIndex(address owner,uint256 index) public view returns(uint256){
        require(index < balanceOf(owner), "Owner index is out of bound");
        return _ownedTokens[owner][index];
    }
    function totalSupply()public view returns(uint256){
     return _allTokens.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract ERC721{
    /*
    building out nft function 
    a. nft to point to an address
    b. keep track of token ids
    c. keep track of token owner address to token ids
    d. keep track of how many token an owner address has
    e. create an event that emits an transfer log - contract address
       where it is being minted to, the id
    */

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    mapping(uint => address) private _tokenOwner;
    mapping(address => uint256) private _OwnedTokensCount;
    mapping(uint => address) private _tokenApprovals;

    function balanceOf(address _owner) public view returns(uint256){
        require(_owner != address(0), 'Query for non-existing token');
        return _OwnedTokensCount[_owner];
    }
    function ownerOf(uint256 _tokenId) public view returns(address){
        address owner = _tokenOwner[_tokenId];
        require(owner != address(0), 'Query for non-existing token');
        return owner;
    }

    function _exists(uint256 tokenId) internal view returns(bool){
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    function _mint(address to,uint tokenId) internal virtual{
        require(to != address(0), "ERC721: minting to the Zero address");
        require(!_exists(tokenId), "ERC721: Token already minted");
        _tokenOwner[tokenId] = to;
        _OwnedTokensCount[to]  += 1;

        emit Transfer(address(0), to, tokenId);

    }
    function _transferFrom(address _from, address _to, uint256 _tokenId) internal {
        require(_to != address(0), "Error - ERC721 Transfer to the zero address");
        require(ownerOf(_tokenId) == _from, "ERC721: transfer of token that is not own");
        _OwnedTokensCount[_from] -= 1;
        _OwnedTokensCount[_to] += 1;
        emit Transfer(_from, _to, _tokenId);
    }
    function transferFrom(address _from, address _to, uint256 _tokenId) public{
        _transferFrom(_from, _to, _tokenId);
    }
    function approve(address _to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(_to != owner, "Error! Approved to current owner");
        require(msg.sender == owner ,"ERC721! Current culler is not the owner of token");
        _tokenApprovals[tokenId] = _to;
        emit Approval(owner, _to, tokenId);

    }

    
}