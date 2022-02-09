/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 
abstract contract ReentrancyGuard { 
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
   _status = _ENTERED;

        _;
        _status = _NOT_ENTERED;
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
 
    function toString(uint256 value) internal pure returns (string memory) { 
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
}
 
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
 
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
    constructor() {
        _transferOwnership(_msgSender());
    }
 
    function owner() public view virtual returns (address) {
        return _owner;
    } 
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
 
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
 
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
 
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
 
library Address { 
    function isContract(address account) internal view returns (bool) { 
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    } 
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
 
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    } 
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
 
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
 
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    } 
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
 
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
 
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
 
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
 
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else { 
            if (returndata.length > 0) { 

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
 
interface IERC721Receiver { 
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
 
interface IERC165 { 
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
 
abstract contract ERC165 is IERC165 { 
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
} 
interface IERC721 is IERC165 { 
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId); 
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId); 
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved); 
    function balanceOf(address owner) external view returns (uint256 balance); 
    function ownerOf(uint256 tokenId) external view returns (address owner); 
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external; 
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external; 
    function approve(address to, uint256 tokenId) external;
 
    function getApproved(uint256 tokenId) external view returns (address operator); 
    function setApprovalForAll(address operator, bool _approved) external; 
    function isApprovedForAll(address owner, address operator) external view returns (bool); 
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
} 
interface IERC721Enumerable is IERC721 { 
    function totalSupply() external view returns (uint256); 
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId); 
    function tokenByIndex(uint256 index) external view returns (uint256);
}  
interface IERC721Metadata is IERC721 { 
    function name() external view returns (string memory); 
    function symbol() external view returns (string memory); 
    function tokenURI(uint256 tokenId) external view returns (string memory);
} 
contract ERC721A is
  Context,
  ERC165,
  IERC721,
  IERC721Metadata,
  IERC721Enumerable
{
  using Address for address;
  using Strings for uint256;

  struct TokenOwnership {
    address addr;
    uint64 startTimestamp;
  }

  struct AddressData {
    uint128 balance;
    uint128 numberMinted;
  }

  uint256 private currentIndex = 0;

  uint256 internal immutable collectionSize;
  uint256 internal immutable maxBatchSize; 
  string private _name; 
  string private _symbol; 
  mapping(uint256 => TokenOwnership) private _ownerships; 
  mapping(address => AddressData) private _addressData; 
  mapping(uint256 => address) private _tokenApprovals; 
  mapping(address => mapping(address => bool)) private _operatorApprovals; 
  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxBatchSize_,
    uint256 collectionSize_
  ) {
    require(
      collectionSize_ > 0,
      "ERC721A: collection must have a nonzero supply"
    );
    require(maxBatchSize_ > 0, "ERC721A: max batch size must be nonzero");
    _name = name_;
    _symbol = symbol_;
    maxBatchSize = maxBatchSize_;
    collectionSize = collectionSize_;
  } 
  function totalSupply() public view override returns (uint256) {
    return currentIndex;
  } 
  function tokenByIndex(uint256 index) public view override returns (uint256) {
    require(index < totalSupply(), "ERC721A: global index out of bounds");
    return index;
  } 
  function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    override
    returns (uint256)
  {
    require(index < balanceOf(owner), "ERC721A: owner index out of bounds");
    uint256 numMintedSoFar = totalSupply();
    uint256 tokenIdsIdx = 0;
    address currOwnershipAddr = address(0);
    for (uint256 i = 0; i < numMintedSoFar; i++) {
      TokenOwnership memory ownership = _ownerships[i];
      if (ownership.addr != address(0)) {
        currOwnershipAddr = ownership.addr;
      }
      if (currOwnershipAddr == owner) {
        if (tokenIdsIdx == index) {
          return i;
        }
        tokenIdsIdx++;
      }
    }
    revert("ERC721A: unable to get token of owner by index");
  } 
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC721Enumerable).interfaceId ||
      super.supportsInterface(interfaceId);
  } 
  function balanceOf(address owner) public view override returns (uint256) {
    require(owner != address(0), "ERC721A: balance query for the zero address");
    return uint256(_addressData[owner].balance);
  }

  function _numberMinted(address owner) internal view returns (uint256) {
    require(
      owner != address(0),
      "ERC721A: number minted query for the zero address"
    );
    return uint256(_addressData[owner].numberMinted);
  }

  function ownershipOf(uint256 tokenId)
    internal
    view
    returns (TokenOwnership memory)
  {
    require(_exists(tokenId), "ERC721A: owner query for nonexistent token");

    uint256 lowestTokenToCheck;
    if (tokenId >= maxBatchSize) {
      lowestTokenToCheck = tokenId - maxBatchSize + 1;
    }

    for (uint256 curr = tokenId; curr >= lowestTokenToCheck; curr--) {
      TokenOwnership memory ownership = _ownerships[curr];
      if (ownership.addr != address(0)) {
        return ownership;
      }
    }

    revert("ERC721A: unable to determine the owner of token");
  } 
  function ownerOf(uint256 tokenId) public view override returns (address) {
    return ownershipOf(tokenId).addr;
  } 
  function name() public view virtual override returns (string memory) {
    return _name;
  } 
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  } 
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(),_getUriExtension()))
        : "";
  } 
  function _baseURI() internal view virtual returns (string memory) {
    return "";
  }

  function _getUriExtension() internal view virtual returns (string memory) {
    return "";
  }
 
  function approve(address to, uint256 tokenId) public override {
    address owner = ERC721A.ownerOf(tokenId);
    require(to != owner, "ERC721A: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721A: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId, owner);
  } 
  function getApproved(uint256 tokenId) public view override returns (address) {
    require(_exists(tokenId), "ERC721A: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  } 
  function setApprovalForAll(address operator, bool approved) public override {
    require(operator != _msgSender(), "ERC721A: approve to caller");

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }
 
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }
 
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    _transfer(from, to, tokenId);
  } 
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    safeTransferFrom(from, to, tokenId, "");
  } 
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public override {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      "ERC721A: transfer to non ERC721Receiver implementer"
    );
  } 
  function _exists(uint256 tokenId) internal view returns (bool) {
    return tokenId < currentIndex;
  }

  function _safeMint(address to, uint256 quantity) internal {
    _safeMint(to, quantity, "");
  } 
  function _safeMint(
    address to,
    uint256 quantity,
    bytes memory _data
  ) internal {
    uint256 startTokenId = currentIndex;
    require(to != address(0), "ERC721A: mint to the zero address"); 
    require(!_exists(startTokenId), "ERC721A: token already minted");
    require(quantity <= maxBatchSize, "ERC721A: quantity to mint too high");

    _beforeTokenTransfers(address(0), to, startTokenId, quantity);

    AddressData memory addressData = _addressData[to];
    _addressData[to] = AddressData(
      addressData.balance + uint128(quantity),
      addressData.numberMinted + uint128(quantity)
    );
    _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

    uint256 updatedIndex = startTokenId;

    for (uint256 i = 0; i < quantity; i++) {
      emit Transfer(address(0), to, updatedIndex);
      require(
        _checkOnERC721Received(address(0), to, updatedIndex, _data),
        "ERC721A: transfer to non ERC721Receiver implementer"
      );
      updatedIndex++;
    }

    currentIndex = updatedIndex;
    _afterTokenTransfers(address(0), to, startTokenId, quantity);
  } 
  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) private {
    TokenOwnership memory prevOwnership = ownershipOf(tokenId);

    bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
      getApproved(tokenId) == _msgSender() ||
      isApprovedForAll(prevOwnership.addr, _msgSender()));

    require(
      isApprovedOrOwner,
      "ERC721A: transfer caller is not owner nor approved"
    );

    require(
      prevOwnership.addr == from,
      "ERC721A: transfer from incorrect owner"
    );
    require(to != address(0), "ERC721A: transfer to the zero address");

    _beforeTokenTransfers(from, to, tokenId, 1); 
    _approve(address(0), tokenId, prevOwnership.addr);

    _addressData[from].balance -= 1;
    _addressData[to].balance += 1;
    _ownerships[tokenId] = TokenOwnership(to, uint64(block.timestamp)); 
    uint256 nextTokenId = tokenId + 1;
    if (_ownerships[nextTokenId].addr == address(0)) {
      if (_exists(nextTokenId)) {
        _ownerships[nextTokenId] = TokenOwnership(
          prevOwnership.addr,
          prevOwnership.startTimestamp
        );
      }
    }

    emit Transfer(from, to, tokenId);
    _afterTokenTransfers(from, to, tokenId, 1);
  } 
  function _approve(
    address to,
    uint256 tokenId,
    address owner
  ) private {
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  uint256 public nextOwnerToExplicitlySet = 0; 
  function _setOwnersExplicit(uint256 quantity) internal {
    uint256 oldNextOwnerToSet = nextOwnerToExplicitlySet;
    require(quantity > 0, "quantity must be nonzero");
    uint256 endIndex = oldNextOwnerToSet + quantity - 1;
    if (endIndex > collectionSize - 1) {
      endIndex = collectionSize - 1;
    } 
    require(_exists(endIndex), "not enough minted yet for this cleanup");
    for (uint256 i = oldNextOwnerToSet; i <= endIndex; i++) {
      if (_ownerships[i].addr == address(0)) {
        TokenOwnership memory ownership = ownershipOf(i);
        _ownerships[i] = TokenOwnership(
          ownership.addr,
          ownership.startTimestamp
        );
      }
    }
    nextOwnerToExplicitlySet = endIndex + 1;
  } 
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    if (to.isContract()) {
      try
        IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
      returns (bytes4 retval) {
        return retval == IERC721Receiver(to).onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721A: transfer to non ERC721Receiver implementer");
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  } 
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {} 
  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}
}

contract CashCrabs is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;


  uint256 public MAX_PER_Transtion = 5; // maximam amount that user can mint
  uint256 public MAX_PER_Address = 5; // maximam amount that user can mint

  uint256 public  PRICE = 25*10**15; //0.025 ether 

  uint256 private constant TotalCollectionSize_ = 10000; // total number of nfts
  uint256 private constant MaxMintPerBatch_ = 10; //max mint per traction

  bool public _revelNFT = false;
  string private _baseTokenURI;
  string private _uriBeforeRevel;

  uint public status = 1; //0-pause 2-whitelist 3-public

  mapping(address => bool) private whitelistedAddresses;

  constructor() ERC721A("Cash Crabs","CashCrabs", MaxMintPerBatch_, TotalCollectionSize_) {
    _uriBeforeRevel = "https://cashcrabs.mypinata.cloud/ipfs/QmPXLXoPTKGg9SdacJiZUo2H8ECSQtN2YsdPvm8F5LWyRv";
    whitelistedAddresses[0xFD845e60eAea6c960d2a2b6F490b53D26925D5cB] = true;
    whitelistedAddresses[0xFD845e60eAea6c960d2a2b6F490b53D26925D5cB] = true;
    whitelistedAddresses[0x09C624d5271A1f7e6A2588e778a4d48bb90A6952] = true;
    whitelistedAddresses[0x720Ff27ee0Cae603D54c915c2c2aAe9E467a3Ae8] = true;
    whitelistedAddresses[0x4067B5677eef1550C22AfF13477B7a919fA35020] = true;
    whitelistedAddresses[0xD6d57d174BE03101c29C1EB3a335559014896BC7] = true;
    whitelistedAddresses[0xfeD7219F6fd43b4D04e4f3F0fA515cFFb5C5de62] = true;
    whitelistedAddresses[0xeDcDd23C6A0a3B16C0C2d3e92C65D5D3b153290F] = true;
    whitelistedAddresses[0x0dcD05914C75A62471F35c6f3F361F84c39DfaB5] = true;
    whitelistedAddresses[0xbb767d5627A75C0943b917d980738E2c601770B6] = true;
    whitelistedAddresses[0xe2Bb817747136d290E5238Ed2ee2db91C96264cD] = true;
    whitelistedAddresses[0xb30D955Afc668EaB195f271D746484928A52cd49] = true;
    whitelistedAddresses[0xCd7aB7280b0DBb253EB109381daA07a0163c58B6] = true;
    whitelistedAddresses[0xCBF699Fc4FA85BC2Ca45BB63ADBFe78264Cc5813] = true;
    whitelistedAddresses[0x4De76a2D2A4deCFd68566889E63D571173F930e4] = true;
    whitelistedAddresses[0x53808009dC1A8e4A36039838B4d56CAea186F9F3] = true;
    whitelistedAddresses[0x9E5435685733787D1Bb5B6e434353C65cAB7c21d] = true;
    whitelistedAddresses[0x731464dd177Cac2d5E7aae58ccc58239B5f3aC43] = true;
    whitelistedAddresses[0x6490cf86E43b1d855fbD7f397E9c63F43dB40eA2] = true;
    whitelistedAddresses[0xAC065C832679b458008c916B1916cA93CA02568a] = true;
    whitelistedAddresses[0x40E4D03F8fF764B7857D0Da4181F0f31a7130C34] = true;
    whitelistedAddresses[0x47673689Fc0a7a22C024079292FfEbBD21A086fE] = true;
    whitelistedAddresses[0x9D2a6aA0b01118b021Ff3e940956e9659Ad3CCE6] = true;
    whitelistedAddresses[0x13e9272AE78459bD5c03e7CC33CF3cC83F765e90] = true;
    whitelistedAddresses[0xcbDAE7c71801BEDcb1bD156ecD665581c43b8112] = true;
    whitelistedAddresses[0x64d79EBEE793b7e546D7D02A8A2ab942775EaA31] = true;
    whitelistedAddresses[0x3c132DDfd6A307126226Ab9f82c951E3989e14dc] = true;
    whitelistedAddresses[0x7595D27eC13Be0A19EDBCFC7d55FE59534d6CC88] = true;
    whitelistedAddresses[0xF279d2934e937880bC486D19AB9A65A8eF4b49c0] = true;
    whitelistedAddresses[0xAf1d737345c84fF50b51E51FeF975Ae9ab31A45f] = true;
    whitelistedAddresses[0x7681712a55587A1E9b6eAb1ea828e4e14059106e] = true;
    whitelistedAddresses[0xA5D4A2c359C958C0530E37d801e851f7b7F7D69c] = true;
    whitelistedAddresses[0xE519E23fbF1a88bf9387FeDD662778b0b348e56A] = true;
    whitelistedAddresses[0x58C0e1CcCfc458f026E67f260BB25D8c71c1de2f] = true;
    whitelistedAddresses[0x7AeC2A61D9bc8e899Eb6e41CeDAF24983D4B1A7e] = true;
    whitelistedAddresses[0xa6f17FC0fcc0467fdBeb01f9bEf47d264B0ee772] = true;
    whitelistedAddresses[0xB868B2ca33365f784df87E31CefAA1E00a8386b5] = true;
    whitelistedAddresses[0x9A46731349080730299880307193a07D0153293d] = true;
    whitelistedAddresses[0x7c400954350b1338A7ead552c41521327D121146] = true;
    whitelistedAddresses[0xfcc1F854c979f61bCA87E651e72E45a72807915b] = true;
    whitelistedAddresses[0x64aA6b8F0e11473E5ef63a224E6E4E3ac63Ef954] = true;
    whitelistedAddresses[0x65f7E3EA4c1507F50467B7334E6d8f7547bb41D3] = true;
    whitelistedAddresses[0xF3Fb8Ba5b9B9DAbec152112A9DDc69D80b1cA07e] = true;
    whitelistedAddresses[0xb57F96B20ECCDD099845B67f8f590c907f4455CC] = true;
    whitelistedAddresses[0x19C99c068B4b3292c819429DA4550a2E36f9f943] = true;
    whitelistedAddresses[0x3Aa26AfDC92b2B09D6AfD3da1a8C11D2EED3772f] = true;
    whitelistedAddresses[0x70B3f80ed5d612005E784312EB335672DD86b16d] = true;
    whitelistedAddresses[0x4bFde9c1Ab8887452A2a9fB80b6F60e013108eA2] = true;
    whitelistedAddresses[0x3F69a1B4fed4408EF9724ad8879d92840d5AaEb2] = true;
    whitelistedAddresses[0xE4Aae6489A1215D1eEbd0cEE8409A77EE7BE467F] = true;
    whitelistedAddresses[0x62f841f3d4E299648CF66f23B71c578D755B2bF7] = true;
    whitelistedAddresses[0x9Cdb12deFD0838E54b4d1EE3261EDe601649E634] = true;
    whitelistedAddresses[0x7d992C2E88D8d35bFf5d6712eEee2c9445329238] = true;
    whitelistedAddresses[0x89Dc9bBEe3075a6d745E3Db6ae113A2aD3F1E545] = true;
    whitelistedAddresses[0x51015f7bfE495Eb5C1daeddaff63d0bA39eDc285] = true;
    whitelistedAddresses[0x039c8590c9a04Cb2451cDA75734861bc4DA31609] = true;
    whitelistedAddresses[0x11ab9463418E47Fc5D9Fe2a17f662AdB19B295C1] = true;
    whitelistedAddresses[0xc03BBC9038b16158d80Dd740F47DE733727E8b23] = true;
    whitelistedAddresses[0x1E93e03cb1798B853262A2b7cA19D7ae642bC8B7] = true;
    whitelistedAddresses[0x373FC2d830B2fcF7731F42Ab9D0D89E552da6ccB] = true;
    whitelistedAddresses[0xb63B9D76324c5BEe81fBF50DfeBB54eB7f3E33a6] = true;
    whitelistedAddresses[0xc5745B750c91ee9752c0C74FB6f91BCC26e6FC9a] = true;
    whitelistedAddresses[0x49825062451be8119A78Ac21Ddb7Dc79BDc1f7F6] = true;
    whitelistedAddresses[0x17171C667608A1d1Aa116Cd9B94e0A7e3620D861] = true;
    whitelistedAddresses[0xbC4fF24fEb140810ACe88E10883eb23D3880E9b3] = true;
    whitelistedAddresses[0x216885e1A68daD7d3936E7E012fa79223c6075A4] = true;
    whitelistedAddresses[0x9D94B5B752555e793F6B1E46eD9654470C459944] = true;
    whitelistedAddresses[0x28C01C0c0C7C25c763CBCa88446038Dc6B1fbA54] = true;
    whitelistedAddresses[0x99f18373BA0b123D59f1BE56C7F689ef6DdfDEa2] = true;
    whitelistedAddresses[0xBe628f65E995242D138A1461c75677B39fAf93C4] = true;
    whitelistedAddresses[0x34ff8a1B5286753161Baa0bCC446D7D6Dc3857dF] = true;
    whitelistedAddresses[0x659815937Af07f40B39B93bF16962ac1754ABBfd] = true;
    whitelistedAddresses[0x4B300A87272db2ca1b30d21d64CDd345C4b80AfC] = true;
    whitelistedAddresses[0x3c0Dd608611D552cf8cc7A0A4B51Bb8D808Ad886] = true;
    whitelistedAddresses[0x9DF087ADa77aF80F553DC0d2FB43C18dC5a6B444] = true;
    whitelistedAddresses[0x746849550373B814dfD93D8fc2a9D37CbC226bB8] = true;
    whitelistedAddresses[0x962772AE26a8098A49cfE01Fe3f6ce68C92F9B5f] = true;
    whitelistedAddresses[0x7A420e46405b573C0Aa96b12E80405A3819D3E6b] = true;
    whitelistedAddresses[0x7b6AEe8165B8e0f3d8c4a8c4651bBd2E89e37631] = true;
    whitelistedAddresses[0xa36EB29607D5deB20d0d6Dc49810cA7a23EB0B27] = true;
    whitelistedAddresses[0x96Cb84ac416602cec04B6778fa3F8e588e84cc95] = true;
    whitelistedAddresses[0x1101AAe94F9d196AC65Bbd440dB1ef0F639E80AE] = true;
    whitelistedAddresses[0xCef9709b428692C92F99BD193dcbBDf8f76A6C01] = true;
    whitelistedAddresses[0x647B7881b8A63FD8C6AAb5b0244b9067223d0e12] = true;
    whitelistedAddresses[0x960104582B294466F3DC3d6d5Ff7a618376772e5] = true;
    whitelistedAddresses[0x2B143cC08cdd999d92FDf44afeA5eBDC7296d90A] = true;
    whitelistedAddresses[0x2F22A600c056848bBEBcdea3645f736B62A8B85B] = true;
    whitelistedAddresses[0xcc2e464CbcE1B11108460cee52e3Cd82E887CbF8] = true;
    whitelistedAddresses[0x191c445ab08764f12C821857961CFEa5B837f276] = true;
    whitelistedAddresses[0x98139f943753Bb98ED5b346621d38DaDd51b416f] = true;
    whitelistedAddresses[0x8D3521b68D831d853A8A383CaA0735E69e3274E0] = true;
    whitelistedAddresses[0xCC0960243d099BCaE96c0D1AEACDdA01434d2ebc] = true;
    whitelistedAddresses[0x07cE5Db5F75E58d657926B636b9aD3e3869C91B4] = true;
    whitelistedAddresses[0x770aeEeFC75134558464d365d6C135f49162A5dB] = true;
    whitelistedAddresses[0x3Ad82E1312895eEe9720ccaBAd3a7f5F226d44BE] = true;
    whitelistedAddresses[0x756dA266dbb35f65645A8111516d0F0C09B372b5] = true;
    whitelistedAddresses[0x76eE43FdcF297AAf373e1981B9F9d4470EdeB71B] = true;
    whitelistedAddresses[0xEa594C9E54eCA6b36DbED9E1E2b22e592B5a3C1E] = true;
    whitelistedAddresses[0x76A80D9E29Aa41Fc8A84a827037F977C06B585fA] = true;
    whitelistedAddresses[0x482F8c1c569A597b6Ad258D979cF919037eb6424] = true;
    whitelistedAddresses[0x588f288Eb412E00b712C6AC18cD95BA1eB62fec3] = true;
    whitelistedAddresses[0x31c9b0554DA42f8c09E3458E4603E377FBa1b3Bf] = true;
    whitelistedAddresses[0x1239F236aA9cadA354B46df3d72b67Bf8eE41469] = true;
    whitelistedAddresses[0x9ae0816138b67b3CD2bA9680AAF983588243D0fd] = true;
    whitelistedAddresses[0xa3dE87BFB56690bb0737d4a4db1A61B554d3F81e] = true;
    whitelistedAddresses[0x8D2DCbBc57092d7DD114EDB923adB31053552DB4] = true;
    whitelistedAddresses[0xfB7587d77DA8c9c60E5Ab3D92962d045e7aBfa1B] = true;
    whitelistedAddresses[0x64A0d2ce34c2897D05fcFD6BE9742Fe2Fad182d2] = true;
    whitelistedAddresses[0x9c9272ee0e9A29E31bDac7d21A9d9a2A3d52e3e8] = true;
    whitelistedAddresses[0x5f9BE6B4F8025dA41239c608503a0cc998557e46] = true;
    whitelistedAddresses[0xaCBea6Bae19e4Da3F54f43459B9d7b6F6187B8Ca] = true;
    whitelistedAddresses[0xfcC99f087f32E560e99eC4feE1188a76F40FEE83] = true;
    whitelistedAddresses[0x6F941D19Cb5BC61Be7127dFa2e040A2ec17fBA63] = true;
    whitelistedAddresses[0x337e95D89875D43A57484048B9283b835f74E7Ae] = true;
    whitelistedAddresses[0x791FcE94B7D9cA5fe0a94636901F3d77E6aEE1E3] = true;
    whitelistedAddresses[0x43570CFaC4eE5fC682ABE2a2902Fbe1CE22a2841] = true;
    whitelistedAddresses[0x34DB797738c12DB1547E5C5fbC1BF6e00CBE65C5] = true;
    whitelistedAddresses[0x50ECfC76876E109bFD367F9C8A1a4ad2A493b063] = true;
    whitelistedAddresses[0x76D0AD6863b627F5786E7C6d17BC67426A9a2787] = true;
    whitelistedAddresses[0xb0E1dF6A0E18Fb6312Bdb1B7B0C41902E3420206] = true;
    whitelistedAddresses[0x2B5b0128B3821cDe5A9e90b921846B53B470e335] = true;
    whitelistedAddresses[0x07f97E3ad47C61dd67E9b59A9Bb9E83F6f709171] = true;
    whitelistedAddresses[0x4925de66FA9f53AA69421eD92b4d2EBc13A688D0] = true;
    whitelistedAddresses[0x2e664181c7E34cC5419c6094AcEb5C30B4972436] = true;
    whitelistedAddresses[0xc3C07157ed646e42c7Ac977b1603f45276b30F99] = true;
    whitelistedAddresses[0x1Cc839b23A915944276B7f594F8621E9ea537ECc] = true;
    whitelistedAddresses[0x705EFF609194673Fd01F0eBB199E65ea84a238cd] = true;
    whitelistedAddresses[0x7C2acf7ceD1f246f65f4D29fBEe4eB3D285D9738] = true;
    whitelistedAddresses[0x184b2665B176FEABBeadf63D49B47109121122eb] = true;
    whitelistedAddresses[0xfFD47BB6245868DC7c263387Ff2745CD998D23CF] = true;
    whitelistedAddresses[0xa15c2e11bCeDe084dB837c188D06c6EA039A8F74] = true;
    whitelistedAddresses[0xFE72cC7CfDC090299E1FF451cf1B542E6d4155a4] = true;
    whitelistedAddresses[0xab24F8ecEf60Ea9ec577e1f556BAdF1483961E9B] = true;
    whitelistedAddresses[0xB2da8A18710337658D37Ec027FaC3ef97e683D06] = true;
    whitelistedAddresses[0x2C78A83F0949EDbf8B0d5c4b1cD116194b56ac05] = true;
    whitelistedAddresses[0x6D624565F1F2070FDc7088474125c5ba80f041cA] = true;
    whitelistedAddresses[0xbeBcf96eEEd98D495F45407CE7017179738E3552] = true;
    whitelistedAddresses[0x4bfc251cBf1eeae80D94EB01d6271C0e51f63648] = true;
    whitelistedAddresses[0x5CE948C7d30e6EF56f75Ce7520e46bae12B454fd] = true;
    whitelistedAddresses[0x0232670c2F60fddDB3c642cC40C7C491Aa52Ad57] = true;
    whitelistedAddresses[0xabE8F776B5B33D842188BA42BFC5fC72d23de80E] = true;
    whitelistedAddresses[0xeE0f9973B2159229AaA0b5E90a704F9da72A8Da1] = true;
    whitelistedAddresses[0x8908e0318fa424370AC9511E0AC04A846B484D67] = true;
    whitelistedAddresses[0x1A63AfFE77eF0CD9c7f411633664200b04878E6c] = true;
    whitelistedAddresses[0xAE9BBAc063Fe60A77e7adBBB04Ce9aBcC39517e5] = true;
    whitelistedAddresses[0x3Bbf6E6c15C93375e00601a034D13Dc9AFc8a763] = true;
    whitelistedAddresses[0xD7C5D20e834009aA70B97E2F4760eDc173FDAbaB] = true;
    whitelistedAddresses[0x18171255F7d009bc21f80D0266F5d175f170C75D] = true;
    whitelistedAddresses[0x1b48012465eD4b770Ce11AB18aE1e701E6DfaF58] = true;
    whitelistedAddresses[0xD4D27FbD73fBa326282f3bf178Ed569CcbC4F9b5] = true;
    whitelistedAddresses[0x3513E4a60Fb4C3a272C8290F76aC924d606EA15d] = true;
    whitelistedAddresses[0x31F7f4Fe1bce32a99b99a616D81AFeFeC53F1FcB] = true;
    whitelistedAddresses[0x04D725941898d965A4DdE8cB40590A9BEB193da3] = true;
    whitelistedAddresses[0xF56535df84290396B92fcda58815812477C4a184] = true;
    whitelistedAddresses[0x5D54Bd4971ad61f298927dA1a3F85e6d88BCE1B1] = true;
    whitelistedAddresses[0x79cBd1D0c08217ed8b448A82ed714c3F3205eEe1] = true;
    whitelistedAddresses[0xE6e566aBc75317c04C39dDb5cD67De735a71f567] = true;
    whitelistedAddresses[0xaD97112509cbb091BD2FC1Fb2ce6531f1BBCE1c0] = true;
    whitelistedAddresses[0x73285945fC85CC1F7cE8AE254E3F6d83E3668270] = true;
    whitelistedAddresses[0x4cbC27Eb49022dC70694Fc3f6297beFb9d96aE18] = true;
    whitelistedAddresses[0xdb4551F4704Dea5Cd761Ee5d00f371b18Dca1085] = true;
    whitelistedAddresses[0x8cd5C2d368c1275D5ee8079A48A4fF80298eC314] = true;
    whitelistedAddresses[0xD0f9DAe23568f78c545A07A9C16228357F6401e8] = true;
    whitelistedAddresses[0x72169E50e2E3Ce7A767Cf5CD9336e8910D4b13D0] = true;
    whitelistedAddresses[0x7838950FC3A25234c03a0e63B2AACA978aB1A602] = true;
    whitelistedAddresses[0x648B5F5A5749749dE6edE1eBc88cD99d28B3ffD9] = true;
    whitelistedAddresses[0xBb7d11B97f07011f754fb5552248989ACFDECde3] = true;
    whitelistedAddresses[0x633c17B318b92b708949E4D82d32BCc6859083b0] = true;
    whitelistedAddresses[0xAddc39cE24076366276f702864E0a4c0aB9798f8] = true;
    whitelistedAddresses[0x9b5358Abf4C8328FB024ebAB6B5B095B08b5564B] = true;
    whitelistedAddresses[0x3811c005C183FA8104a72499a6F85Cb6bd644eAc] = true;
    whitelistedAddresses[0x06Fa86E319D35AAC2006E1f8273a3cA10a4FB2Fa] = true;
    whitelistedAddresses[0x688d4B0eb01FB0dfEF34818b5D1827fBDeF3184D] = true;
    whitelistedAddresses[0x3B2263A4a9D02E33E44CcD7bdf248CEF5eC633bc] = true;
    whitelistedAddresses[0x9bc4c78867a4816688d3F1bE696cdAaFd469bd0D] = true;
    whitelistedAddresses[0x420a7b48D7e34010a803257A10Ad9d95f8b2f88E] = true;
    whitelistedAddresses[0x2968B496A7A821B9a67011CF60f672571633CaD6] = true;
    whitelistedAddresses[0x0F7EEcc8cDfEcF83A3B6E93F34701C85d23a1E62] = true;
    whitelistedAddresses[0x8f432c6aa4da9298baa589Ae7539eA5746e8C474] = true;
    whitelistedAddresses[0x9FF4e59895012c634277E99171D1124B0F2c01eD] = true;
    whitelistedAddresses[0xcAB1EE41b663B712fd58fbaAE2a1f04591107Faa] = true;
    whitelistedAddresses[0x1D88F10627EcB8e596A5Ab451C2DF958f69BeFDC] = true;
    whitelistedAddresses[0x5bc53477dA64B971b09BEd40119f5F7bf0dA9667] = true;
    whitelistedAddresses[0x1688CA553e48049f192DC727fF14414BF1524243] = true;
    whitelistedAddresses[0x3d218b77bE29900ca97a7bdabaC7d665B05Be84A] = true;
    whitelistedAddresses[0x6617De1aEFCddA76c458018Bb9608e1E6A25Ad5B] = true;
    whitelistedAddresses[0x41CFcC63981CD09201A37dF7f515307FBaDf51F8] = true;
    whitelistedAddresses[0x54BF374c1a0eb4C52017Cc52Cf1633327EE3E985] = true;
    whitelistedAddresses[0x4efb7B6E34616Ae0f79f2D2644Caeea299ed941a] = true;
    whitelistedAddresses[0x5C21120970aa4D6a8ED6A8635aC84f21Bb55F1fA] = true;
    whitelistedAddresses[0xBF89828935484b3A4801Ed5e09718d6Bb60B46b4] = true;
    whitelistedAddresses[0xFfa4A51dFae1E8d43fA800dC639ca68B68D576b7] = true;
    whitelistedAddresses[0x7169301ebdBE4f2c86859991423A24EbbF91461E] = true;
    whitelistedAddresses[0x1c6F0082BE9Cb71DF7609917864FAdBB8A8599E7] = true;
    whitelistedAddresses[0x14e00A153296881C5A07c778D3Af97E21Ac4f978] = true;
    whitelistedAddresses[0x5Fe3055DB0D8cF215514E2787f9b414c2a52e6D8] = true;
    whitelistedAddresses[0x068481A3019C5fd50862C8FfFF53B3b70fa382bF] = true;
    whitelistedAddresses[0xAF4cF2A6Dc9F530B44b7fd9406B83258C79b2c71] = true;
    whitelistedAddresses[0xB13E94dd61ab15AE70F6294Ac2F41C578EEd39Dc] = true;
    whitelistedAddresses[0x9c0b69e3013fe53f276d79698E44E3149c62fa13] = true;
    whitelistedAddresses[0xB0c5e7CEB566CdD8EFB4B8dA79966FB6aB708F26] = true;
    whitelistedAddresses[0xc263776D9eA1BB86B4C5cd857a6454d1F47FCa59] = true;
    whitelistedAddresses[0x504f0BAf0810a9A3265BEBe18ee25474800ffc45] = true;
    whitelistedAddresses[0x0497E94c77029Af09517A74191ac86e15f3078C3] = true;
    whitelistedAddresses[0x47fD3F28ABe2CEa99C9c9Be02C7302e2D3bAC0E9] = true;
    whitelistedAddresses[0x471d62DB54a53dB851155b3Cb7Cb5F78A676B7c6] = true;
    whitelistedAddresses[0xAE58AA169CF8cE4Ff8FA6C24a1F434ff75c9b012] = true;
    whitelistedAddresses[0x7032d9D143C5e6750187e4184137104968b4363C] = true;
    whitelistedAddresses[0x7A504c602e4Db6A5e6f089d2d8539c77a79B5Bb9] = true;
    whitelistedAddresses[0x7d67ca153360582AE4721bC60589373b3d5Cec63] = true;
    whitelistedAddresses[0x0fa24CDA3012Fa9186496384c75C09a17Fee5A06] = true;
    whitelistedAddresses[0x83cAa0744780E228DB4E416F29589c074aB18512] = true;
    whitelistedAddresses[0x3c72910bc8364F9619F8b43b5A250bE6113995a0] = true;
    whitelistedAddresses[0x63EcC314a1cfeDA4c78ed516D20a8bE67dA280c2] = true;
    whitelistedAddresses[0xd6b1370243a68dAA835A14c451d3f0d22116BEc4] = true;
    whitelistedAddresses[0x97Bb12e8427E6FDC7881927dB0B0dA14445327BB] = true;
    whitelistedAddresses[0x8fd4f55A3a3f8F3cF461bD4A6a3FfeE937FBF75c] = true;
    whitelistedAddresses[0x818A9b822aD7840c096E6726321f194b47Ae31c2] = true;
    whitelistedAddresses[0xA4020bE699215A3B7712ffBa8fcA763820BdbDb6] = true;
    whitelistedAddresses[0xad3bfc3C00d7509bC01b54A1E07eB4746ffa361b] = true;
    whitelistedAddresses[0x835bBe0f99c15C2CB8FdF858868c1D3C52a50fa6] = true;
    whitelistedAddresses[0x976605C094a350c717E2Ed3D033197094AB05334] = true;
    whitelistedAddresses[0x3B8d244198d6e31aF5dCfaa1E51a920081fA7eAd] = true;
    whitelistedAddresses[0x853B811892B8107860E8b71e670a83C462B4A507] = true;
    whitelistedAddresses[0x0Be02eAb1fDF8C899A5086bFDEf0a336A1f12ba4] = true;
    whitelistedAddresses[0x2C72bc035Ba6242B7f7B7C1bdf0ed171A7c2b945] = true;
    whitelistedAddresses[0x194b3496E9d2FfAe6AF332350d33Af8B21cA9b5d] = true;
    whitelistedAddresses[0xa662ad1A0C36a51F6BfC72D5aD2D4a99791740bC] = true;
    whitelistedAddresses[0x6395303dc74AAdc38CBa51e8689dFa3519a13F0B] = true;
    whitelistedAddresses[0x3A086A1DEFdD5E9a62297abbFa9E91ab3e1CC16d] = true;
    whitelistedAddresses[0x8B6A413FB3512b1e56a175C89C32587bC23d91bF] = true;
    whitelistedAddresses[0x9991A1d42A63e41CD21C80e94c580d62A6E01471] = true;
    whitelistedAddresses[0xA221F8c497faB925073C182eDb4d305145b20F5F] = true;
    whitelistedAddresses[0x1B5413F8b60c67f3b4BE84d07ce57DC0D68986DC] = true;
    whitelistedAddresses[0x29CAa7a393cFE67576F81A8b77A22c7880aF5501] = true;
    whitelistedAddresses[0x227d93B231e70e7a6618D8bcb7eB68dC3D414F14] = true;
    whitelistedAddresses[0x46A2Ef74225423Ce13B4Ad479f71cb204b8Cc4B5] = true;
    whitelistedAddresses[0x3C469cbb8A35d753abcFb364b121647a4E6FEbc2] = true;
    whitelistedAddresses[0x02951D69f0A8eDed113100883e70AD133aDD3f56] = true;
    whitelistedAddresses[0xfE3F0624Dbc2036c47DeE835CDE6A19Fc0821538] = true;
    whitelistedAddresses[0x61109C7033C8003b0dECF6880c58fea718Ddd40e] = true;
    whitelistedAddresses[0x9BB4DBDb5D763cc5B1F678d5D5ce3f9cf765074F] = true;
    whitelistedAddresses[0x1124fF6bd2C98fbE62dc4C491a9d415c0FeC1BAF] = true;
    whitelistedAddresses[0x99da072869087Ce13bE20fCC7F13aE4D2aED4e4F] = true;
    whitelistedAddresses[0xDAFCe2279325b7314083320e9C82Be13f374E7c9] = true;
    whitelistedAddresses[0x6d80D27E181715b20Fec6A5492FC0B5f2a93931B] = true;
    whitelistedAddresses[0xb09511b387e0bbBd987FAc4433AFF5839dee5Ef4] = true;
    whitelistedAddresses[0x7ED0Fd948688aBf3785C5d8b7EeFCfbf82500fA0] = true;
    whitelistedAddresses[0x6483AFa117fD0c334f2A6D8D64149cf84FDd1dB2] = true;
    whitelistedAddresses[0xD281E80C2d2C8f09c22D0039124e94737019620e] = true;
    whitelistedAddresses[0xc424C67AB3A5A2D33AE5d234A7fd2c9eD55f807D] = true;
    whitelistedAddresses[0x70C8294446B02C70252992D1bC8Ed2E18E05be46] = true;
    whitelistedAddresses[0x8621AAA593eE6C2251d02647c67767b4C4EFbe12] = true;
    whitelistedAddresses[0x96242abC548D13d181857cb6Ffe32995e641fdAf] = true;
    whitelistedAddresses[0x01f2ea8D6594F6EB69027F7ddcc1D700bBdbBE48] = true;
    whitelistedAddresses[0x4f4354345088C9c320C9C048D0b36B1a73727Ce6] = true;
    whitelistedAddresses[0x3c3B59411792cdB893F167B3a7394eA9d125cD9A] = true;
    whitelistedAddresses[0x6b0e4EA76F522Cc337e4683e01d5B5779ab67f7b] = true;
    whitelistedAddresses[0xae29968890bFc0ea250abaFd30B0502B46214b81] = true;
    whitelistedAddresses[0xf82947b13c2a2A91B9c20b7B3b546b5Cb82e94A5] = true;
    whitelistedAddresses[0x8fB2F9DEFaA5a088E8ccfc01DaD56a938ae499E1] = true;
    whitelistedAddresses[0x3a61c3F67Df48E3f73509F6E58621a746797a645] = true;
    whitelistedAddresses[0x7F8235CC263A8Cbe81C642b6cdb53E488227Ca28] = true;
    whitelistedAddresses[0x6dd46d406BD1b9546c5b35da82E44fE7E141cbE8] = true;
    whitelistedAddresses[0x60f2f6718801CeFe0D2276a668a73d9EfD69a0A7] = true;
    whitelistedAddresses[0xF74A8D872597958e2889cc91d45BF2cAd6a3A364] = true;
    whitelistedAddresses[0x7FBeC09F7CE64b733260fB40acA15BF18528b3BB] = true;
    whitelistedAddresses[0x706108b116585805AfCC752e45d56C5Fa2f080FA] = true;
    whitelistedAddresses[0x4019868226fabBfB836d388beE5E870204371F9d] = true;
    whitelistedAddresses[0x69B3d3BE1D6CcFaEE8b48C9f5E37d634BEc99680] = true;
    whitelistedAddresses[0x8B56e84623d7Cb650F9863C9aa5CD1ffae3D62BC] = true;
    whitelistedAddresses[0xFBe871D0Aad0FDab932B60351aFD1006b03fda43] = true;
    whitelistedAddresses[0x22433e157a87d81D9F6460aaE4b89FfeEC2c382d] = true;
    whitelistedAddresses[0x04A65E8b543D4e1F7e1cC5d5118cb9B1b7aa20b1] = true;
    whitelistedAddresses[0x5bE67129914f502BAAd2791be0934F7dBa691500] = true;
    whitelistedAddresses[0xe8D531dC7122CBdEbD2Dd5E6D43DC09C9D1caAaB] = true;
    whitelistedAddresses[0xD49322ADD203C8e04ACDD53B7fF14B5E0AC861D7] = true;
    whitelistedAddresses[0x75eAD7715418F50F2285EAC120Ac003CE2e46227] = true;
    whitelistedAddresses[0xA6Fe464c7aAFF0827F264289a1E9b2b82cdb961a] = true;
    whitelistedAddresses[0xAdd9a6a1B6781eb889bB01326b5278032BD8E30e] = true;
    whitelistedAddresses[0x083eaD940335d6908CDb078df005Fb4C5f83A9b0] = true;
    whitelistedAddresses[0x9A4763bE8fFaD2F2EC958b8b3742b4D59Ec490e2] = true;
    whitelistedAddresses[0xd5a9C4a92dDE274e126f82b215Fccb511147Cd8e] = true;
    whitelistedAddresses[0x188408EF0c26225705f6Cdea6148f3f8Ed802348] = true;
    whitelistedAddresses[0xd5bB6ac79482467103263B818f2d8462224F6133] = true;
    whitelistedAddresses[0x6EF9Dca82362509cD878051D1FDC6dB12ddA2989] = true;
    whitelistedAddresses[0xD72D8eE3Ee73DeaB3137B2622F8e97BaDEa70900] = true;
    whitelistedAddresses[0xd4A645268CFE2806De8a3beF82c1FA79c99b1e1c] = true;
    whitelistedAddresses[0x43afdF4acd587b41b40693e820de52Da010A1c19] = true;
    whitelistedAddresses[0x6C8917547A0Dd8d3A9658DE9176837cFa9dd8933] = true;
    whitelistedAddresses[0xf873BeBDD61AB385D6b24C135BAF36C729CE8824] = true;
    whitelistedAddresses[0xEd034B287ea77A14970f1C0c8682a80a9468dBB3] = true;
    whitelistedAddresses[0x914FF77D2AA22E2604005ADa17a4eb54C2964131] = true;
    whitelistedAddresses[0x49B59DF9dF381B1634B81e3Ea12fcC0BB6Ae4498] = true;
    whitelistedAddresses[0xBbf63f18B363C1317aF8e48c6ecF2528955877be] = true;
    whitelistedAddresses[0x5EEb21cD9535c3130E683e5fFA51d25AE0926150] = true;
    whitelistedAddresses[0xaCf890389fF734d23aEAE8EA8bCBC1CB7b9fEE08] = true;
    whitelistedAddresses[0x48Fe093848d1a11B236C7d4450E6b6360B6bA7Ad] = true;
    whitelistedAddresses[0xB6C5B1a489606028Da263EDa28063186f96fa921] = true;
    whitelistedAddresses[0x392D688249ddA8C3f75402cc257307E04fcd793c] = true;
    whitelistedAddresses[0x7896ca4e8Dea26Af540bC466229435bea5457344] = true;
    whitelistedAddresses[0xfcD51CE91D05FFEF2a678B6b15579cEf0c28680A] = true;
    whitelistedAddresses[0x9F69b05c6Bb5871905412B998389912D3A4cbE4b] = true;
    whitelistedAddresses[0x5ef36FB9480b4dD1F217Cef4B054c97ad5857eF0] = true;
    whitelistedAddresses[0xc039B305CF30f5e7d42Ffa4fd92aF80D4b8d264C] = true;
    whitelistedAddresses[0xE3162DB6d1f2c4bDc6B97Ee98986FCFB1900238D] = true;
    whitelistedAddresses[0x6b718E50E4f8549AC3Ee828759477Ca1D8c2EEc5] = true;
    whitelistedAddresses[0xA1a0e1c77EcCdD42C3424a852d1d950D4f70A195] = true;
    whitelistedAddresses[0x095E54514a95d7579a9a12E77E33AAE6b5c9EfCc] = true;
    whitelistedAddresses[0xce33A5485345de213Ba726858Fd5aCbE21D255Bc] = true;
    whitelistedAddresses[0x1555CE5C0A71490dFCcc65ec1cABD3C5467deA15] = true;
    whitelistedAddresses[0x6a3bF16Bba8D8e9b9738c0e97940f3F5e55D2417] = true;
    whitelistedAddresses[0xC300c97E8BDd1De87a89B95f30fFc48beaCbF775] = true;
    whitelistedAddresses[0x33725931cef75B1b15c85dF10af4aAbfe4f8cb33] = true;
    whitelistedAddresses[0x8Fa2dd1f61C4784F6A9a5CAff6DeE48320a8574e] = true;
    whitelistedAddresses[0xAD0043104124fDa20cCbbA6137CA440FF9d2f096] = true;
    whitelistedAddresses[0xF180f0fF2cDc8F9Ed1CFa98b7D0Ed4aeC28ddbAf] = true;
    whitelistedAddresses[0x4D5cCe7FFe0b02c1B73678B295f0F3F24e88f854] = true;
    whitelistedAddresses[0x194F6b93BEf0B66494a83dd8a933f4942219d880] = true;
    whitelistedAddresses[0xDCc18fEFEBAa22A8b637c8cB1283815aeC35FAe7] = true;
    whitelistedAddresses[0x0F255AAF6b5131ea0FE46970fD93BeD3314080F2] = true;
    whitelistedAddresses[0xa99d8E77ce54a2C643E723469C4ec4B70F7212c9] = true;
    whitelistedAddresses[0xdCbeF5ca2245F2661FD69bA40c6643d7bC8B5BD0] = true;
    whitelistedAddresses[0x486F636B98C3B955159b46228104028F291c345e] = true;
    whitelistedAddresses[0xeAA14E5F2AC58692350c64070077355445d3d127] = true;
    whitelistedAddresses[0xE63c78ADCB7a766DDC48e493De46094b59376Ef5] = true;
    whitelistedAddresses[0xaE1e8745b14fdC57BD0be7662FFe82C664c25270] = true;
    whitelistedAddresses[0xFDc695E4DfbEc316eCEb205410A4bdBf171795df] = true;
    whitelistedAddresses[0x60F008bdEc59Bc57B25a3476E0b05eF4882f093a] = true;
    whitelistedAddresses[0xfd5dDf939b1453e369810896195c8103A52B9251] = true;
    whitelistedAddresses[0x1877FA3AF4A6Cec0C05f0932f87a0c386Cbf906B] = true;
    whitelistedAddresses[0x2FAcE9cC8C4246c38730AB2248eaa30E0e7Dc2d8] = true;
    whitelistedAddresses[0x731EC28e9314be2da65cDc0B7E55341eFE33A3d8] = true;
    whitelistedAddresses[0x8aD7a7ae30B3Cef4494C507133211d60a831Aa89] = true;
    whitelistedAddresses[0x92Cd135c7C2539E4D61CE4e5951f19D4beF7d871] = true;
    whitelistedAddresses[0xb3441Ac812872226092A401c8Ab0d8F3E919743e] = true;
    whitelistedAddresses[0xae320F2b5E965C6859834a4c4df41F324d06d1e0] = true;
    whitelistedAddresses[0xBd74Ba03A439D9B9621dFacc0fa4edE5C86A205C] = true;
    whitelistedAddresses[0xFa2a9C75Bd768deF7F144FD33d72DFCC6d0F1ff7] = true;
    whitelistedAddresses[0x1c10cA916EdE22b6ED14efdA442BEba14819CE4B] = true;
    whitelistedAddresses[0xf99983c1b128b87beD9aE10eC19df12feFDEb822] = true;
    whitelistedAddresses[0x7A455Da0FB1A70F421aba5b091b1862189942521] = true;
    whitelistedAddresses[0x5F9E228a454ae4C7de82604f4b4028A95e1705a0] = true;
    whitelistedAddresses[0xb470f97DAB8be7bb31640007560436cf0A024956] = true;
    whitelistedAddresses[0x56960880170EAf298826e6D0eE61f853Ee2deef5] = true;
    whitelistedAddresses[0x67A9F393f8e068B4187da09558a1f5036a3d9b34] = true;
    whitelistedAddresses[0x49612Fd70fEc2406c77a10a2926F39923D234C5B] = true;
    whitelistedAddresses[0xeCB03C8ABDCBD0Ef3f333efd11959d052Fb60b7c] = true;
    whitelistedAddresses[0x7Cd31150494AC32E8E42A6D9a31e67B48372a43B] = true;
    whitelistedAddresses[0x08e3012f872A5d1163C4069E4325D4D3e0D890f7] = true;
    whitelistedAddresses[0x39436E22EC425e93EB5C5136389B04854c142310] = true;
    whitelistedAddresses[0x5C57abD3548b87Ef9bAbEa37ed3abD51fad523a3] = true;
    whitelistedAddresses[0x5B94DE14d4789C0264a2E20132Ee2cb30F6B7f34] = true;
    whitelistedAddresses[0x7E5573836391c3240C95b1698ee3F815Bf01C904] = true;
    whitelistedAddresses[0x5cf9b65d03000c3Fb68AE833C5E21C91829BC7d1] = true;
    whitelistedAddresses[0x5c29F54cD1aF8636BeeAfBcdD4bE0114f4307ED4] = true;
    whitelistedAddresses[0xDcb30978A21C5a083A2C91bF06Dce37c261bFB43] = true;
    whitelistedAddresses[0x47F08742e58E2015c9E3d89957579d3e7869A0d8] = true;
    whitelistedAddresses[0x361533e1A7f04ea0cb9cAA76277d1BA04F48b1c9] = true;
    whitelistedAddresses[0x61FCF5155788A8C71E8E607F094aC4aB72c58CEb] = true;
    whitelistedAddresses[0x1B3585C01bA9e8dD6aEFd73f3Ca9D58BBEB666e7] = true;
    whitelistedAddresses[0xa9D60735AB0901F84F5D04b465FA2F1a6d0Aa7Ee] = true;
    whitelistedAddresses[0x2067baD494367B860D4f5f1C2a3862110ae4D75e] = true;
    whitelistedAddresses[0xE2371b3cF4Fc1E290D613FE3bF4a61d285199B17] = true;
    whitelistedAddresses[0xd5A771Da32A392036a98f7DA6b11D46D6D1c61f9] = true;
    whitelistedAddresses[0x4d7Bd6b18FfE526c901AeC3C7a2B564bD2c376D5] = true;
    whitelistedAddresses[0x40C7Fea74E92803f6e9d3Cd9fc0ABaCcc28d46bC] = true;
    whitelistedAddresses[0x73E4FDD812a1c28706cFbD03249731ef50F6F520] = true;
    whitelistedAddresses[0x2Eaa29D91CA91dB1Af608f9A7dF4F4feb5f01BFE] = true;
    whitelistedAddresses[0x73c48Ad7F4eC3E52b8FAB220337DBA7549e8170E] = true;
    whitelistedAddresses[0xdd12bF90cF2c48320F988534B3A8Bf246cC3aD0b] = true;
    whitelistedAddresses[0x83b127894d6E2bc1dbA6D88F0e022347969a02a3] = true;
    whitelistedAddresses[0xf295EFa8c90897D2770F795B3811452Fa3530F81] = true;
    whitelistedAddresses[0x9f0e16F48Ce7c7cF0902b1B965bE9D86172c4447] = true;
    whitelistedAddresses[0xD1F4Be365dB59548D474cF7C2bedc417209f9eF7] = true;
    whitelistedAddresses[0xa5D4c28304a8042A4557579A6229B37cD6736Ce6] = true;
    whitelistedAddresses[0x4A9513dAFCBD44C8A4409Ca262C4Da1f70A7064e] = true;
    whitelistedAddresses[0x6DE8e62dCe4c4C167626e297Cd3E5498B0096663] = true;
    whitelistedAddresses[0x9B809FB7C18fca0985d8b94E3EA6ccc3d6727a00] = true;
    whitelistedAddresses[0x1b33A158F6BcDCEcb53ad5D3a1b4f847DFC0a7C6] = true;
    whitelistedAddresses[0xE9bD37E8A30e7a15AEa960578DD283513C9BfA2c] = true;
    whitelistedAddresses[0x33b22f2578c87bc59F4fa4035A85475bD9C541ab] = true;
    whitelistedAddresses[0x8880018BA0517a71c29Da6B043Ee461589a9b529] = true;
    whitelistedAddresses[0x0D0bc2AdAf925D4F0F2aF8461b70aa3bC99f08e0] = true;
    whitelistedAddresses[0x0cF249aF439a1444910Cb0d7647a83DadF9B912b] = true;
    whitelistedAddresses[0x5920d33c06914Df0CdBaA780894FDEc4a23D3022] = true;
    whitelistedAddresses[0x707d9277F1966651b2bFA6C17BaED1C2Ee85f586] = true;
    whitelistedAddresses[0xbFC4460eF3d8fD49902FB831E73e304B0947ce59] = true;
    whitelistedAddresses[0x326262f035bb1925C78443276a3b3F796bd3Cd8C] = true;
    whitelistedAddresses[0xd6714f181934eD979344F4A8168581b8048A5e03] = true;
    whitelistedAddresses[0x26883856ED417087c828687464427ffe70BbACD7] = true;
    whitelistedAddresses[0xB67D0995647303350D9c0b4118759807A0A29B5c] = true;
    whitelistedAddresses[0x86F632C48eC142D602012375C793a41D4b97cC05] = true;
    whitelistedAddresses[0xB1146ECd00783165eBc41C363bcb2e6FB231dD09] = true;
    whitelistedAddresses[0xD3349916bB1aA25c7A459a8aEBB3310Ea5f423B5] = true;
    whitelistedAddresses[0x755a1dD37b7f7011F8D11E5043a427532d11C63F] = true;
    whitelistedAddresses[0x69B9c615cC9900073B8F200F9D13f882706B6374] = true;
    whitelistedAddresses[0xc3793662ceb87129431245E0e22B2A697C7F66E8] = true;
    whitelistedAddresses[0xcAb63F60878642BCb8236acDfE8a2ec6cDc14ed4] = true;
    whitelistedAddresses[0x0660459b2b658B232f3dB6ADfF5580e7558F60E6] = true;
    whitelistedAddresses[0x929dC783b613E6ccd80BA4a4FFD3289cfF82866A] = true;
    whitelistedAddresses[0xDffC43C8709De2EdA41AeDd5e4EaF51963c93A44] = true;
    whitelistedAddresses[0xCC89EC35fCECC62273603B6031f93ca692a54414] = true;
    whitelistedAddresses[0x6F0ca764Ff228C5942dcC4f2B48809236Ba03990] = true;
    whitelistedAddresses[0x3F140845EDeC1DbdD8dB54232fBAFDB637773C2F] = true;
    whitelistedAddresses[0x93f263bDa652E5061386284A7d3b6Ea0cDD27852] = true;
    whitelistedAddresses[0x9F46f9499C20dD3bb111215002ECb3c5fD52fC21] = true;
    whitelistedAddresses[0x813D9AFe8da7768c468d5330bb18175916f29c7f] = true;
    whitelistedAddresses[0xc76039347c20A331aF1938E3BE73273A965baa08] = true;
    whitelistedAddresses[0x7a756813C419D23b0E9A1B8A1D1dAfe662805BB1] = true;
    whitelistedAddresses[0xEcCD1694D625a37169189d248f8e7D55bE038a6f] = true;
    whitelistedAddresses[0xDa9551D92636D33f5F9712672D67fD08Fd4288e3] = true;
    whitelistedAddresses[0xeF745b83FEEa5c811aF76132245374C6a8Be8D08] = true;
    whitelistedAddresses[0x3Fb3365b48045208737EcE98aA31b2F7Ac6bbDC7] = true;
    whitelistedAddresses[0x3D92898c09614702B5031b42a3AA41F2E7FfFe07] = true;
    whitelistedAddresses[0x77d04628A093B243D9750F32893766c3d0B0449d] = true;
    whitelistedAddresses[0xD509F14123021f60df832518D08176ca4dfD0Bfa] = true;
    whitelistedAddresses[0x70C8825CD741be7750BbC462C776b6A3b6f39551] = true;
    whitelistedAddresses[0x95F445cC9e6a90b9445F2Ea805908aC6768A9E18] = true;
    whitelistedAddresses[0x84a13DF125ACafe9AC2F11D92A1d662e66f98c3c] = true;
    whitelistedAddresses[0x74D5EDf85139c6289f2Ee1ff49DD8E1864B0104C] = true;
    whitelistedAddresses[0x7D03e3E2C833018eE3a8cFcf3876296a2186696C] = true;
    whitelistedAddresses[0xFD69dfd91Aeb80d36e5B2200f581eB2350b078db] = true;
    whitelistedAddresses[0xe0123335BdE05195E0D78F79C9B2776493fa916c] = true;
    whitelistedAddresses[0x199fD4BFc1F012bbffa5f53F931B32037266fccC] = true;
    whitelistedAddresses[0xF416D9bB6576e15e9587A900134255dEdE849Cf2] = true;
    whitelistedAddresses[0x335525B494F659CeCdCe90d329A41Bed94e9d5f7] = true;
    whitelistedAddresses[0x7a57312C96d212eC4E77853c301d45C1D26487B0] = true;
    whitelistedAddresses[0xBD4c4049bF7B42889D343384743a808F9D6a1f45] = true;
    whitelistedAddresses[0x4B8caed2850513795635c123635CD8046A846520] = true;
    whitelistedAddresses[0xdaf55518E4EABFe34B39B953291C1A8383eF6020] = true;
    whitelistedAddresses[0xA166f681BE8dB248237444F0C48962F8F8940c98] = true;
    whitelistedAddresses[0xb366fdB2b665644524df762bd09c87FA3f6D7be4] = true;
    whitelistedAddresses[0x3147B17e5eb3B9A36A7CA16144E16Aae6295f499] = true;
    whitelistedAddresses[0x1f83404171F76CE8686B62bB89670AE7ab8e2D0D] = true;
    whitelistedAddresses[0x8DE02b898091a2401f2D89f6cf3C50307c329492] = true;
    whitelistedAddresses[0xd96bE45080e824686694E7f74169330FFc55d1DF] = true;
    whitelistedAddresses[0xbe7AC41E85fDb0171207d03BB6a2d8695E4e9033] = true;
    whitelistedAddresses[0xf3e4bb46f9C8e06e57996fD6b0337f60E824Be88] = true;
    whitelistedAddresses[0xA8b472599193D1BC01acfd6A31A9B6f5dc2a93E6] = true;
    whitelistedAddresses[0xd68936188779efb41BEF5659B9183B34Fb7963Fe] = true;
    whitelistedAddresses[0x8027e4EaeF12dae0b5A68B81BE3eC46a88e6Ff1a] = true;
    whitelistedAddresses[0x3A48B3b3fdf7eFDE99044d1F63ED1d00f61702bC] = true;
    whitelistedAddresses[0x15FaA3F30D2691f7Ff8b067938C07468f5Ee6C1F] = true;
    whitelistedAddresses[0xe64F4c1793057d8E6Ef4d72dc7547B51b2aaA750] = true;
    whitelistedAddresses[0x88Be47aeF010e57B01AC9E9F2272281C6B1e6514] = true;
    whitelistedAddresses[0xd6fC56bd9D65a4f00A3969791DB598Bd74f389b4] = true;
    whitelistedAddresses[0xf27e69c6Ef6dfC96f62f0B56DBD27FFeDcAF72Ba] = true;
    whitelistedAddresses[0xa72726267c804e7508dF6b3AC14014F1EAc2D5Ad] = true;
    whitelistedAddresses[0x2Ec79180e470E303AA0a6A3033bc7D19708aD365] = true;
    whitelistedAddresses[0x423907a13DcE86f5415a4e4221caCBDfb9cDdF47] = true;
    whitelistedAddresses[0x74a8fBB9651dAc3BB9f2f0d7B1af9CA3dE9181CE] = true;
    whitelistedAddresses[0x13cBB2dCBe4d39D8743bf1650C4E8C09103a324B] = true;
    whitelistedAddresses[0xddBaAEd29761659CB20554c343D656A0cd8095B5] = true;
    whitelistedAddresses[0x787551ae0AB07dE8EB91d1535DBD37f379B0111D] = true;
    whitelistedAddresses[0x5BaC6fd07ED7c3572ce36cb2b841D6eC84af27f0] = true;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }
 
  function mint(uint256 quantity) external payable callerIsUser {
    require(status == 1 && whitelistedAddresses[msg.sender] || status == 2 , "Sale is not Active");
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require( ( status == 1 && numberMinted(msg.sender) + quantity <= MAX_PER_Address ) || status == 2 , "Quantity exceeds allowed Mints" );
    require(  quantity <= MAX_PER_Transtion,"can not mint this many");
    require(msg.value >= PRICE * quantity, "Need to send more ETH.");
    _safeMint(msg.sender, quantity);    
  }

   function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
    if(_revelNFT){
    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
    } else{
      return _uriBeforeRevel;
    }
  }

  function isWhitelisted(address _user) public view returns (bool) {
    return whitelistedAddresses[_user];
  }

  
  function addNewWhitelistUsers(address[] calldata _users) public onlyOwner {
    // ["","",""]
    for(uint i=0;i<_users.length;i++)
        whitelistedAddresses[_users[i]] = true;
  }

  function setURIbeforeRevel(string memory URI) external onlyOwner {
    _uriBeforeRevel = URI;
  }

  function setBaseURI(string memory baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }
  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }
  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }
  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
  function changeRevelStatus() external onlyOwner {
    _revelNFT = !_revelNFT;
  }
  function changeMintPrice(uint256 _newPrice) external onlyOwner
  {
      PRICE = _newPrice;
  }
  function changeMAX_PER_Transtion(uint256 q) external onlyOwner
  {
      MAX_PER_Transtion = q;
  }
  function changeMAX_PER_Address(uint256 q) external onlyOwner
  {
      MAX_PER_Address = q;
  }

  function setStatus(uint256 s)external onlyOwner{
      status = s;
  }
  function getStatus()public view returns(uint){
      return status;
  }
  function giveaway(address a, uint q)public onlyOwner{
    _safeMint(a, q);
  }
}