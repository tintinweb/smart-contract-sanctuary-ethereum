//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

//import "hardhat/console.sol";

// For usage of Strings.toString
import "@openzeppelin/contracts/utils/Strings.sol";

interface IERC721Receiver {
  function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC721 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  /*event MintedNftId(uint nftId);

  function safeMint(string memory _name, string memory _description, string memory _imageURI) public payable returns (uint256);

  function tokenURI(uint256 _nftId) public view returns (string memory);

  function totalSupply() public view returns (uint256);

  function balanceOf(address _owner) public view returns (uint256);

  */

  function ownerOf(uint256 _nftId) external view returns (address);

  function getPrice() external view returns (uint256);

  function safeTransfer(address _to, uint256 _tokenId) external;
 
  /*
  function setPrice(uint256 _price) external;


  function getMetadata(uint256 _token_id) external view returns (string memory _name, string memory _description, string memory _imageURI, uint256 _mintDate);
  */
}

contract NFTContract is IERC721 {
  struct NFTMetadata {
    string name;
    string description;
    string imageURI;
    uint256 timestamp;
  }
 
  string public _name;
  string public _symbol;
  uint256 private nftId;
  uint256 public price;
  address private ownerAddress;

  // maps owner address to balance amount
  mapping(address => uint256) balances;

  // maps nftIDs to owner address
  mapping(uint256 => address) owners;
 
  // maps nftIDs to its metadata
  mapping(uint256 => NFTMetadata) metadata;

  uint256[] public _allTokens;

  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
    nftId = 0;

    // TODO: Check default price, or maybe require it in the constructor?
    price = 1000000 gwei;

    ownerAddress = msg.sender;
  }

  function name() override public view returns (string memory) {
    return _name;
  }

  function symbol() override public view returns (string memory) {
    return _symbol;
  }

  event MintedNftId(uint nftId);

  function safeMint(string memory _name, string memory _description, string memory _imageURI) public payable returns (uint256) {
    address owner = msg.sender;
    require(validOwner(owner), "Minting user must not be address 0");
    require(msg.value == price, string.concat("You should send", Strings.toString(price), "gweis"));

    nftId += 1;
    owners[nftId] = owner;
    balances[owner] += 1;
    metadata[nftId] = NFTMetadata(_name, _description, _imageURI, block.timestamp);

    _allTokens.push(nftId);

    emit MintedNftId(nftId);

    return nftId;
  }

  function tokenURI(uint256 _nftId) public view returns (string memory) {
    require(validOwner(owners[_nftId]), "NFT must be minted");

    return string(abi.encodePacked("baseURI", Strings.toString(_nftId)));
  }

  /// @notice Count NFTs tracked by this contract
  /// @return A count of valid NFTs tracked by this contract, where each one of
  ///  them has an assigned and queryable owner not equal to the zero address
  function totalSupply() public view returns (uint256) {
    return _allTokens.length;
  }

  /// @notice Count all NFTs assigned to an owner
  /// @dev NFTs assigned to the zero address are considered invalid, and this
  ///  function throws for queries about the zero address.
  /// @param _owner An address for whom to query the balance
  /// @return The number of NFTs owned by `_owner`, possibly zero
  function balanceOf(address _owner) public view returns (uint256) {
    require(validOwner(_owner), "Address 0 is reserved");

    return balances[_owner];
  }

  /// @notice Find the owner of an NFT
  /// @dev NFTs assigned to zero address are considered invalid, and queries
  ///  about them do throw.
  /// @param _nftId The identifier for an NFT
  /// @return The address of the owner of the NFT
  function ownerOf(uint256 _nftId) override public view returns (address) {
    require(validOwner(owners[_nftId]), "Query about invalid NFT");

    return owners[_nftId];
  }

  /// @notice Transfers the ownership of an NFT from one address to another address
  /// @dev Throws unless `msg.sender` is the current owner, an authorized
  ///  operator, or the approved address for this NFT. Throws if `_from` is
  ///  not the current owner. Throws if `_to` is the zero address. Throws if
  ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
  ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
  ///  `onERC721Received` on `_to` and throws if the return value is not
  ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
  /// @ param _from The current owner of the NFT
  /// @param _to The new owner
  /// @param _tokenId The NFT to transfer
  /// @ param data Additional data with no specified format, sent in call to `_to`
  function safeTransfer(address _to, uint256 _tokenId) override public {
    require(validOwner(_to), "Address 0 is reserved");
    address from = msg.sender;
    require(_to != from, "Can't transfer to itself");
    address owner = ownerOf(_tokenId);
    require(from == owner, "Can't transfer if you are not the owner");
  
    balances[from] -= 1;
    balances[_to] += 1;

    owners[_tokenId] = _to;

    if (_to.code.length > 0) { // checks if _to is a contract
      try IERC721Receiver(_to).onERC721Received(msg.sender, from, _tokenId, bytes("")) returns (bytes4 retval) {
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721: transfer to non ERC721Receiver implementer");
        }
      }
    }
  }

  function setPrice(uint256 _price) external onlyOwner() {
    require(_price > 0, "Price should be greater than 0");
    price = _price;
  }

  function getPrice() override public view returns (uint256) {
    return price;
  }

  function getMetadata(uint256 _token_id) external view onlyNFTOwner(_token_id) returns (string memory) {
    return (metadata[_token_id].name);
  }
 
  function validOwner(address _owner) private pure returns (bool) {
    return _owner != address(0);
  }
  
  // TODO: Use ownable interface
  modifier onlyOwner() {
    require(msg.sender == ownerAddress, "You are not the owner");
    _;
  }

  modifier onlyNFTOwner(uint256 _token_id) {
    require(msg.sender == owners[_token_id], "You are not the NFT owner");
    _;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}