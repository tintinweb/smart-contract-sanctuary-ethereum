// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import './ERC721Connector.sol';

contract KryptoBirds is ERC721Connector {
    uint256 private counter;
  //  mapping(string => bool) _kryptoBirdzExists;

    constructor() ERC721Connector('KryptoBirds','KBIRDS'){
      
    }
     
     function mint() public {
         // require(!_kryptoBirdzExists[_kryptobirdz],"Error! Krypto Birdz already Exists");
           uint256 _id = counter;
           uint256 count;
           assembly {
			     let c := add(_id, 1)
            count := c
	        }
         counter = count;
         //_kryptoBirdzExists[_kryptobirdz] = true;
         _mint(msg.sender,_id);
     }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import './ERC721.sol';
//import './ERC721Enumerable.sol';

contract ERC721Connector is ERC721 {

constructor(string memory name, string memory symbol) ERC721(name,symbol){

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
     string private _name;

    // Token symbol
     string private _symbol;
     constructor(string memory name_, string memory symbol_){
        _name = name_;
        _symbol = symbol_;
      }

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
        uint256 ownerbalance = _OwnedTokensCount[to];
        uint256 count;
         assembly {
			     let c := add(ownerbalance, 1)
            count := c
	        }
        _tokenOwner[tokenId] = to;
         _OwnedTokensCount[to]  = count;

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