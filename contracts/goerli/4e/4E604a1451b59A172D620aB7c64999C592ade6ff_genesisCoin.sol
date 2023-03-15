/**
 *Submitted for verification at polygonscan.com on 2022-06-22
*/

/**
 *Submitted for verification at polygonscan.com on 2022-04-20
*/

// File: GGDAO/contracts/Genesis Coin NFT/erc721-metadata.sol
// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface ERC721Metadata
{

  function name()
    external
    view
    returns (string memory _name);

  function symbol()
    external
    view
    returns (string memory _symbol);

  function tokenURI(uint256 _tokenId)
    external
    view
    returns (string memory _uri);

}
// File: GGDAO/contracts/Genesis Coin NFT/ownable.sol

pragma solidity 0.8.7;

contract Ownable 
{

  string public constant NOT_CURRENT_OWNER = "018001";
  string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "018002";

  address public owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor()
  {
    owner = msg.sender;
  }
  
  modifier onlyOwner()
  {
    require(msg.sender == owner, NOT_CURRENT_OWNER);
    _;
  }

  function transferOwnership(
    address _newOwner
  )
    public
    onlyOwner
  {
    require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}
// File: GGDAO/contracts/Genesis Coin NFT/address-utils.sol

pragma solidity 0.8.7;

library AddressUtils
{
  function isContract(
    address _addr
  )
    internal
    view
    returns (bool addressCheck)
  {
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    assembly { codehash := extcodehash(_addr) } // solhint-disable-line
    addressCheck = (codehash != 0x0 && codehash != accountHash);
  }

}
// File: GGDAO/contracts/Genesis Coin NFT/erc165.sol

pragma solidity 0.8.7;

interface ERC165
{
  function supportsInterface(
    bytes4 _interfaceID
  )
    external
    view
    returns (bool);
    
}
// File: GGDAO/contracts/Genesis Coin NFT/supports-interface.sol

pragma solidity 0.8.7;


contract SupportsInterface is
  ERC165
{
  mapping(bytes4 => bool) internal supportedInterfaces;

  constructor()
  {
    supportedInterfaces[0x01ffc9a7] = true; // ERC165
  }

  function supportsInterface(
    bytes4 _interfaceID
  )
    external
    override
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceID];
  }

}
// File: GGDAO/contracts/Genesis Coin NFT/erc721-token-receiver.sol

pragma solidity 0.8.7;

interface ERC721TokenReceiver
{
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes calldata _data
  )
    external
    returns(bytes4);

}
// File: GGDAO/contracts/Genesis Coin NFT/erc721.sol

pragma solidity 0.8.7;

interface ERC721
{
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

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  function approve(
    address _approved,
    uint256 _tokenId
  )
    external;

  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external;

  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256);

  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  function getApproved(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    view
    returns (bool);

}
// File: GGDAO/contracts/Genesis Coin NFT/token.sol

pragma solidity 0.8.7;





contract NFToken is
  ERC721,
  SupportsInterface
{
  using AddressUtils for address;
  string constant ZERO_ADDRESS = "003001";
  string constant NOT_VALID_NFT = "003002";
  string constant NOT_OWNER_OR_OPERATOR = "003003";
  string constant NOT_OWNER_APPROVED_OR_OPERATOR = "003004";
  string constant NOT_ABLE_TO_RECEIVE_NFT = "003005";
  string constant NFT_ALREADY_EXISTS = "003006";
  string constant NOT_OWNER = "003007";
  string constant IS_OWNER = "003008";
  uint256 public constant price = 1 ether;
  bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

  mapping (uint256 => address) internal idToOwner;

  mapping (uint256 => address) internal idToApproval;

  mapping (address => uint256) private ownerToNFTokenCount;

  mapping (address => mapping (address => bool)) internal ownerToOperators;

  modifier canOperate(
    uint256 _tokenId
  )
  {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender],
      NOT_OWNER_OR_OPERATOR
    );
    _;
  }

  modifier canTransfer(
    uint256 _tokenId
  )
  {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner == msg.sender
      || idToApproval[_tokenId] == msg.sender
      || ownerToOperators[tokenOwner][msg.sender],
      NOT_OWNER_APPROVED_OR_OPERATOR
    );
    _;
  }

  modifier validNFToken(
    uint256 _tokenId
  )
  {
    require(idToOwner[_tokenId] != address(0), NOT_VALID_NFT);
    _;
  }

  constructor ()
  {
    supportedInterfaces[0x80ac58cd] = true; // ERC721
  }

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external
    override
  {
    _safeTransferFrom(_from, _to, _tokenId, _data);
  }

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
    override
  {
    _safeTransferFrom(_from, _to, _tokenId, "");
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
    override
    canTransfer(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);

    _transfer(_to, _tokenId);
  }

  function approve(
    address _approved,
    uint256 _tokenId
  )
    external
    override
    canOperate(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(_approved != tokenOwner, IS_OWNER);

    idToApproval[_tokenId] = _approved;
    emit Approval(tokenOwner, _approved, _tokenId);
  }

  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external
    override
  {
    ownerToOperators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  function balanceOf(
    address _owner
  )
    external
    override
    view
    returns (uint256)
  {
    require(_owner != address(0), ZERO_ADDRESS);
    return _getOwnerNFTCount(_owner);
  }

  function ownerOf(
    uint256 _tokenId
  )
    external
    override
    view
    returns (address _owner)
  {
    _owner = idToOwner[_tokenId];
    require(_owner != address(0), NOT_VALID_NFT);
  }

  function getApproved(
    uint256 _tokenId
  )
    external
    override
    view
    validNFToken(_tokenId)
    returns (address)
  {
    return idToApproval[_tokenId];
  }

  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    override
    view
    returns (bool)
  {
    return ownerToOperators[_owner][_operator];
  }

  function _transfer(
    address _to,
    uint256 _tokenId
  )
    internal
  {
    address from = idToOwner[_tokenId];
    _clearApproval(_tokenId);

    _removeNFToken(from, _tokenId);
    _addNFToken(_to, _tokenId);

    emit Transfer(from, _to, _tokenId);
  }
  
  function _mint(
    address _to,
    uint256 _tokenId
  )
    internal
    virtual
  {
    require(_to != address(0), ZERO_ADDRESS);
    require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);
    _addNFToken(_to, _tokenId);

    emit Transfer(address(0), _to, _tokenId);
  }
    
  function getOwnerOf(
    uint256 _tokenId
  )
    internal
    virtual
    returns (address _owner)
  {
    _owner = idToOwner[_tokenId];
    require(_owner != address(0), NOT_VALID_NFT);
  }
  
  function _burn(
    uint256 _tokenId
  )
    internal
    virtual
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    _clearApproval(_tokenId);
    _removeNFToken(tokenOwner, _tokenId);
    emit Transfer(tokenOwner, address(0), _tokenId);
  }


  function _removeNFToken(
    address _from,
    uint256 _tokenId
  )
    internal
    virtual
  {
    require(idToOwner[_tokenId] == _from, NOT_OWNER);
    ownerToNFTokenCount[_from] -= 1;
    delete idToOwner[_tokenId];
  }

  function _addNFToken(
    address _to,
    uint256 _tokenId
  )
    internal
    virtual
  {
    require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);

    idToOwner[_tokenId] = _to;
    ownerToNFTokenCount[_to] += 1;
  }

  function _getOwnerNFTCount(
    address _owner
  )
    internal
    virtual
    view
    returns (uint256)
  {
    return ownerToNFTokenCount[_owner];
  }

  function _safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
    private
    canTransfer(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);

    _transfer(_to, _tokenId);

    if (_to.isContract())
    {
      bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
      require(retval == MAGIC_ON_ERC721_RECEIVED, NOT_ABLE_TO_RECEIVE_NFT);
    }
  }

  function _clearApproval(
    uint256 _tokenId
  )
    private
  {
    delete idToApproval[_tokenId];
  }

}
// File: GGDAO/contracts/Genesis Coin NFT/tokenMeta.sol

pragma solidity 0.8.7;



contract NFTokenMetadata is
  NFToken,
  ERC721Metadata
{

  string internal nftName;

  string internal nftSymbol;

  mapping (uint256 => string) internal idToUri;

  constructor()
  {
    supportedInterfaces[0x5b5e139f] = true; // ERC721Metadata
  }

  function name()
    external
    override
    view
    returns (string memory _name)
  {
    _name = nftName;
  }

  function symbol()
    external
    override
    view
    returns (string memory _symbol)
  {
    _symbol = nftSymbol;
  }
function tokenURI(uint256 _tokenId)
    public
    override
    view
    validNFToken(_tokenId)
    returns (string memory)
  {
    return idToUri[_tokenId];
  }
  function _burn(
    uint256 _tokenId
  )
    internal
    override
    virtual
  {
    super._burn(_tokenId);

    delete idToUri[_tokenId];
  }

  function _setTokenUri(
    uint256 _tokenId,
    string memory _uri
  )
    internal
    validNFToken(_tokenId)
  {
    idToUri[_tokenId] = _uri;
  }

}
// File: GGDAO/contracts/Genesis Coin NFT/main.sol

pragma solidity 0.8.7;





contract genesisCoin is NFTokenMetadata, Ownable {
    address public charContract;
    address public gameCoverContract;
    uint256 public characterCount = 0;
    uint256 public gameCoverCount = 0;

    mapping(uint256 => string) public characterToCoinURI;
    mapping(uint256 => uint256) public characterToCoinGenesisSupply;
    mapping(uint256 => uint256) public characterToStartingID;
    mapping(uint256 => uint256) public characterToCurrentID;

    mapping(uint256 => string) public gameCoverToCoinURI;
    mapping(uint256 => uint256) public gameCoverToCoinGenesisSupply;
    mapping(uint256 => uint256) public gameCoverToStartingID;
    mapping(uint256 => uint256) public gameCoverToCurrentID;

    address[] public holders;

    constructor(address[] memory holders) payable {
      nftName = "Genesis Coin";
      nftSymbol = "GC";
      createNewCharacterIn(100, "hash");
      for(uint256 i=0;i<holders.length;i++) { mintIn(holders[i], 100);}
    }

    function setCharContract(address _charContract) public onlyOwner {
        charContract = _charContract;
    }

    function setGameCoverContract(address _gameCoverContract) public onlyOwner {
        gameCoverContract = _gameCoverContract;
    }

    modifier onlyCharacterContract {
        require(msg.sender == charContract, "Invalid Caller");
        _;
    }

    fallback() external payable { }
    receive() external payable { }

    address[] public teamAddresses;

    function createNewCharacter(uint256 _id, string memory folderHash) public {
      require(msg.sender == charContract, "Invalid Caller");
      characterToCoinURI[_id] = string(abi.encodePacked(folderHash,"/coin.json"));
      characterToCoinGenesisSupply[_id] = 2500;
      characterToStartingID[_id] = (characterCount*2500)+1;
      characterToCurrentID[_id] = 0;
      characterCount+=1;
    }

    function createNewGameCover(uint256 _id, string memory folderHash) public {
      require(msg.sender == gameCoverContract, "Invalid Caller");
      gameCoverToCoinURI[_id] = string(abi.encodePacked(folderHash,"/coin.json"));
      gameCoverToCoinGenesisSupply[_id] = 2500;
      gameCoverToStartingID[_id] = (gameCoverCount*2500)+1;
      gameCoverToCurrentID[_id] = 0;
      gameCoverCount+=1;
    }

    function createNewCharacterIn(uint256 _id, string memory folderHash) internal {
      characterToCoinURI[_id] = string(abi.encodePacked(folderHash,"/coin.json"));
      characterToCoinGenesisSupply[_id] = 2500;
      characterToStartingID[_id] = (characterCount*2500)+1;
      characterToCurrentID[_id] = 0;
      characterCount+=1;
    }

    function mintIn(address _to, uint256 _id) internal {
      require(characterToCurrentID[_id] < 2500);
      uint256 _tokenId = characterToStartingID[_id] + characterToCurrentID[_id];
      super._mint(_to, _tokenId);
      super._setTokenUri(_tokenId, characterToCoinURI[_id]);
      characterToCurrentID[_id] += 1;
    } 

    function mintGenesis(address _to, uint256 _id) public {
      require(msg.sender == charContract, "Invalid Caller");
      require(characterToCurrentID[_id] < 2500);
      uint256 _tokenId = characterToStartingID[_id] + characterToCurrentID[_id];
      super._mint(_to, _tokenId);
      super._setTokenUri(_tokenId, characterToCoinURI[_id]);
      characterToCurrentID[_id] += 1;
    } 
    
    function setCharacterHash(uint256 _id, string memory _hash) public {
      require(isTeam(msg.sender));
      characterToCoinURI[_id] = _hash;
    }

    function extractEther() external onlyOwner {
      payable(msg.sender).transfer(address(this).balance);
    }

    function isTeam(address[] calldata _users) public onlyOwner {
      delete teamAddresses;
      teamAddresses = _users;
    }

    function isTeam(address _user) public view returns (bool) {
      for (uint i = 0; i < teamAddresses.length; i++) {
        if (teamAddresses[i] == _user) {
            return true;
        }
      }
      return false;
    }
 }