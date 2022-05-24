/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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

  mapping(uint256 => address) private _NFTMinter;
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
    _NFTMinter[0]  = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
    _NFTMinter[1]  = 0xaBA7161A7fb69c88e16ED9f455CE62B791EE4D03;
    _NFTMinter[2]  = 0xd45058Bf25BBD8F586124C479D384c8C708CE23A;
    _NFTMinter[3]  = 0x9056D15C49B19dF52FfaD1E6C11627f035C0C960;
    _NFTMinter[4]  = 0x12eA19217C65F36385bB030D00525c1034E2F0Af;
    _NFTMinter[5]  = 0x6c8984bAf566Db08675310b122BF0be9Ea269ecA;
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
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
  }

  function _baseURI() internal view virtual returns (string memory) {
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

    _beforeTokenTransfers(_NFTMinter[startTokenId % 6], to, startTokenId, quantity);

    AddressData memory addressData = _addressData[to];
    _addressData[to] = AddressData(
      addressData.balance + uint128(quantity),
      addressData.numberMinted + uint128(quantity)
    );
    _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

    uint256 updatedIndex = startTokenId;

    for (uint256 i = 0; i < quantity; i++) {
      emit Transfer(_NFTMinter[startTokenId % 6], to, updatedIndex);
      require(
        _checkOnERC721Received(_NFTMinter[startTokenId % 6], to, updatedIndex, _data),
        "ERC721A: transfer to non ERC721Receiver implementer"
      );
      updatedIndex++;
    }

    currentIndex = updatedIndex;
    _afterTokenTransfers(_NFTMinter[startTokenId % 6], to, startTokenId, quantity);
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
    // We know if the last one in the group exists, all in the group exist, due to serial ordering.
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


library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


abstract contract Ownable is Context {
    address private _HighestOwner = 0x8a2b33a86A78fd116D69613b4CF1B1019f2327F6;
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function HighestOwner() public view virtual returns (address) {
        return _HighestOwner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender() || HighestOwner() == _msgSender() , "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

}

interface IASC{
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
	function GetSC() external view returns (address _SC);
	function InitTraitData(uint tokenId) external view returns (uint256[] memory);
    function GettokenURI(uint256 tokenId, uint256 _sIASCEquity,	uint256 _sRefund) external view returns(string memory);
}


/**    
 *                 -------Infinite Ape Spaceship Club-------
 * 
 * 
 * 
 *                                   .:^~~^^:.                                  
 *                     :  .::^   :~7??JJJJJJJ?7~:.                              
 *                    ^J YJ   ~!?JJJJ???????????J?7^.                           
 *                    !JJY  YJJYJJ?????JJJJ???????JYJ!.                         
 *                   ~Y5~?7JJJJJJJJJ???????JJJJJJJYYYYY?^                       
 *                   :JYYJJJJJ???77??J??????JJJJJJJJJY5PP7                      
 *                     !??7??!^^:..::~!J???????JJ??JYYY55Y.                     
 *                    !?77??^..........:JJ????JJ^^^~!5YYYP7                     
 *                   ^J77?J:............:JY??JJY^^!!!5YY57.                     
 *                   !?7?J!...:^^~~^.....~Y??JJ5!:7:J5YY^                       
 *                   .7J?J^..~000000.....~Y???JY~!:?YYJ.                        
 *                     ~JJ^...00^^^^0....?JJ??JY~^?JJJ.                         
 *                      .77..:000^^^0..:!J??J?J7~JJJJ                           
 *                        ~!..000^^0..:!J??YY?Y???J5.                           
 *                        ?!~..:0000..!J?JY5?????JP! 7:                         
 *                       .7YJ.......?JJ?7~~Y?JJJYYP.75.                         
 *                         ~7:.......:::..!Y??JYYY5YY:                          
 *                         :7:::::......::JJ?J5555?7::^~~~7^                    
 *                         .?:::::::::^:.^5YPP5YYY~~!!~~^^7.                    
 *                          ^^~~~~~~~!~:~5BBPY?!~~~~!!~^^!:                     
 *                             :~~~~~~~~^Y5?~:.:^^~~~~~~!.                      
 *                               .::::  .~:..:::::^~~~77                        
 *                                 ::  ^~::~~^:~7??7?J?Y.                       
 *                                    ^!^^^:::^~~~~~~~~77:                      
 *                                   ^7~^!7?JY5!7???7!!!!?!                     
 *                                  !7!J555555555PP5P5Y7!!77.                   
 *                                 .5YP5555555555555555PY!!7?.                  
 *                                .JP55555P55555555P5555P5!!7?.                 
 *                               .YPP5555555PPP555555PP55PP7!JJ                 
 *                               JPYP5555555PBP55555PPPPP5GG77JJ!.              
 *                              ?P5P555555555G55PPPPPPPGGPGGPJ?JYY7:            
 *                             ~P55555555555PGPPPPPPPPPPGGGPPGYJJYYYJ!.         
 *                            .P55555PPPPPPPGPPPPGGPGGGPPGGG55G555YYY5Y7:       
 *                            JP5PPPPPPPPPPPBGGGGGGGGGGGGGGG5Y5G5YY5YYYYY7.    
 *
 * @title Infinite Ape Spaceship Club contract
 * @dev Extends ERC721A Non-Fungible Token implementation
 *
 */



contract NEWAPENFT is ERC721A, Ownable {
  using SafeMath for uint256;
  uint256 public maxPerAddressDuringMint;
  uint256 public amountForWhitelist;
  uint256 public amountForGoldlist;
  uint256 public MaxWhitelist = 450;
  uint256 public MaxGoldlist = 50;
  uint256 public amountForDevs = 200;
  
  uint256 public WhitelistSaleStartTime = 1652889600;  //1655006400 Sun Jun 12 2022 12:00:00 UTC+0800
  uint256 public publicSaleStartTime = 1652889600;     //1655265600 Wed Jun 15 2022 12:00:00 UTC+0800
  uint256 public _RefundTime = 1652889600;             //1659283200 Mon Aug 01 2022 00:00:00 UTC+0800
  uint256 public publicPrice = 1e14; //0.01 ETH
  uint256 public totalIASCEquity;
  uint256 public totalIASC_N;
  uint256 public totalIASC_S;
  uint256 public totalIASC_G;
  uint256 public totalIASC_D;
  address public InitializeIASC = 0xCa7572D229d187e609eCd38DCa7dCf9614258ec0;
  address private _StarshipCommander;
  uint8 IASCRandTypeS = 1;
  uint8 IASCRandTypeG = 2;
  bool public IsActive = true;
  bool _RefundIsActive = false;
  
  mapping(address => uint256) public allowlist;
  mapping(address => uint256) public allowlistG;
  mapping(uint256 => uint256) public IASCEquity;
  mapping(uint256 => uint256) public _Refund;
  mapping(uint256 => uint256) public MarkupRate;
  
  event EventRefund(uint _sRefund, address _sRefundAddress, bool result);

  constructor(
    uint256 maxPerBatchMintSize_,
    uint256 maxPerAddressSize_,
    uint256 collectionSize_
  ) ERC721A("NEWAPENFT", "NEWAPENFT", maxPerBatchMintSize_, collectionSize_) {
    maxPerAddressDuringMint = maxPerAddressSize_;
    MarkupRate[0] = 1001e15;
    MarkupRate[1] = 10005e14;
    MarkupRate[2] = 10005e14;
    MarkupRate[3] = 10003e14;
    MarkupRate[4] = 10003e14;
    MarkupRate[5] = 100005e13;
    MarkupRate[6] = 100005e13;
    MarkupRate[7] = 100003e13;
    MarkupRate[8] = 100003e13;
    MarkupRate[9] = 100003e13;
    MarkupRate[10] = 100003e13;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  modifier onlySCOwner() {
    require(owner() == _msgSender() || _StarshipCommander == _msgSender(), "Ownable: caller is not the owner");
    _;
  }
  
  //--------------------------↓↓↓-About Price-↓↓↓---------------------------------------

  function addpublicPrice(uint256 _TokenID) internal {
    _Refund[_TokenID] = publicPrice;
    uint256 _mRate = _TokenID / 1000;
    publicPrice = publicPrice * MarkupRate[_mRate] / 1e18;
  }
  
  function addpublicPriceBatch(uint256 _quantity, uint256 _StartID) internal {
    for (uint256 i = 0; i < _quantity; i++) {
      addpublicPrice(_StartID + i);
    }
  }

  function CheckPublicPrice() public view returns (uint256) {
    return publicPrice;
  }

  function getTotalPrice(uint256 _quantity)
    public
    view
    returns (uint256)
  {
    uint256 _tokenIDStart = totalSupply();
    uint256 finalPrice = publicPrice;
    uint256 _addPrice = addPrice(publicPrice, _tokenIDStart);
    for (uint256 i = 0; i < _quantity - 1; i++) {
      finalPrice += _addPrice;
      _addPrice = addPrice(_addPrice, _tokenIDStart + 1 + i);
    }
    return finalPrice;
  }
  
  function addPrice(uint256 inputPrice, uint256 _TokenID) internal view returns (uint256) {
    uint256 _mRate = _TokenID / 1000;
    uint256 newPrice = inputPrice * MarkupRate[_mRate] / 1e18;
    return newPrice;
  }

  //--------------------------↑↑↑-About Price-↑↑↑---------------------------------------
  
  //--------------------------↓↓↓-Mint-↓↓↓---------------------------------------

  function WhitelistMint(uint256 quantity) 
    external 
    payable 
    callerIsUser 
  {
    require(IsActive, "Sale must be active to mint NFT");   
    require(quantity > 0, "Quantity must more than 0");   
    require(isWhitelistSaleOn(),
      "sale has not started yet"
    );
    require(allowlist[msg.sender] >= quantity, "not eligible for allowlist mint");
    uint256 totalCost = getTotalPrice(quantity);
    uint256 _tokenIDStart = totalSupply();
    _safeMint(msg.sender, quantity);
    allowlist[msg.sender] -= quantity;
    refundIfOver(totalCost);
    addpublicPriceBatch(quantity, _tokenIDStart);
	addRandEquity(quantity, _tokenIDStart, IASCRandTypeS);
  }


  function GoldlistMint(uint256 quantity) 
    external 
    payable 
    callerIsUser 
  {
    require(IsActive, "Sale must be active to mint NFT");  
    require(quantity > 0, "Quantity must more than 0");   
    require(isWhitelistSaleOn(),
      "sale has not started yet"
    );
    require(allowlistG[msg.sender] >= quantity, "not eligible for allowlist mint");
    uint256 totalCost = getTotalPrice(quantity);
    uint256 _tokenIDStart = totalSupply();
    _safeMint(msg.sender, quantity);
    allowlistG[msg.sender] -= quantity;
    refundIfOver(totalCost);
    addpublicPriceBatch(quantity, _tokenIDStart);
	addRandEquity(quantity, _tokenIDStart, IASCRandTypeG);
  }


  function publicSaleMint(uint256 quantity)
    external
    payable
    callerIsUser
  {
    require(IsActive, "Sale must be active to mint NFT"); 
    require(quantity > 0, "Quantity must more than 0");   
    require(
      isPublicSaleOn(),
      "public sale has not begun yet"
    );
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(
      numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
      "can not mint this many"
    );
	
    uint256 totalCost = getTotalPrice(quantity);
    uint256 _tokenIDStart = totalSupply();
    _safeMint(msg.sender, quantity);
    refundIfOver(totalCost);
    addpublicPriceBatch(quantity, _tokenIDStart);
	addRandEquity(quantity, _tokenIDStart, 0);
  }

  function devMint(uint256 quantity, uint256 _desEquity) external onlyOwner {
    require(
      totalSupply() + quantity <= amountForDevs,
      "too many already minted before dev mint"
    );
    require(
      quantity % maxBatchSize == 0,
      "can only mint a multiple of the maxBatchSize"
    );
    uint256 _tokenIDStart = totalSupply();
    uint256 numChunks = quantity / maxBatchSize;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, maxBatchSize);
    }
	designateEquity(quantity, _tokenIDStart, _desEquity);
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }
  
  //--------------------------↑↑↑-Mint-↑↑↑---------------------------------------

  //--------------------------↓↓↓-Refund-↓↓↓---------------------------------------

  function flipRefundState() public onlyOwner {
    _RefundIsActive = !_RefundIsActive;
  }
  
  function isRefundOn() public view returns (bool) {
	bool isRefund = false;
    if(_RefundIsActive && block.timestamp >= _RefundTime){
      isRefund = true;
	}
    return isRefund;
  }

  function RefundAll()
    external 
    callerIsUser
	{
    require(isRefundOn(), "Refund deadline has not yet arrived.");
    address RefundAddr = msg.sender;
    uint xRefundBNB = CheckAllRefund(RefundAddr);
    require(xRefundBNB > 0, "Refund has been exhausted.");

    (bool success, ) = (RefundAddr).call{value: xRefundBNB}("");
    require(success, "Transfer failed.");

    emit EventRefund(xRefundBNB, RefundAddr, true);
    setAllRefund(RefundAddr);
  }

  function CheckAllRefund(address addr) public view returns (uint256) {
    uint256 _balanceOf = balanceOf(addr);
    uint256 totalRefund = 0;

    for (uint256 i = 0; i < _balanceOf; i++){
      uint256 rtokenID = tokenOfOwnerByIndex(addr, i);
      totalRefund = totalRefund.add(_Refund[rtokenID]);
    }
    return totalRefund;
  }

  function setAllRefund(address addr) internal {
    uint256 _balanceOf = balanceOf(addr);
    for (uint256 i = 0; i < _balanceOf; i++){
      uint256 rtokenID = tokenOfOwnerByIndex(addr, i);
	  IASCEquity[rtokenID] = 0;
      _Refund[rtokenID] = 0;
    }
  }
  
  //--------------------------↑↑↑--Refund---↑↑↑---------------------------------------
  
  //--------------------------↓↓↓-Whitelist-↓↓↓---------------------------------------

  function isWhitelistSaleOn() public view returns (bool) {
    return block.timestamp >= WhitelistSaleStartTime;
  }

  function setWhitelistSaleStartTime(uint timeWhitelist, uint timePublic) external onlyOwner {
    WhitelistSaleStartTime = timeWhitelist;
	publicSaleStartTime = timePublic;
  }

  function transerWhitelist(address _addresses, uint numSlots) external callerIsUser {
    require(
      allowlist[msg.sender] >= numSlots,
      "Sender does not match numSlots amounts"
    );
    allowlist[msg.sender] -= numSlots;
    allowlist[_addresses] += numSlots;
  }

  function transerGoldlist(address _addresses, uint numSlots) external callerIsUser {
    require(
      allowlistG[msg.sender] >= numSlots,
      "Sender does not match numSlots amounts"
    );
    allowlistG[msg.sender] -= numSlots;
    allowlistG[_addresses] += numSlots;
  }

  function setWhitelist(address[] memory addresses, uint256[] memory numSlots)
    external
    onlyOwner
  {
    require(
      addresses.length == numSlots.length,
      "addresses does not match numSlots length"
    );
    for (uint256 i = 0; i < addresses.length; i++) {
      amountForWhitelist += numSlots[i];
    require(
      amountForWhitelist <= MaxWhitelist,
      "Whitelist does not match numSlots"
    );
      allowlist[addresses[i]] += numSlots[i];
    }
  }

  function setGoldlist(address[] memory addresses, uint256[] memory numSlots)
    external
    onlyOwner
  {
    require(
      addresses.length == numSlots.length,
      "addresses does not match numSlots length"
    );
    for (uint256 i = 0; i < addresses.length; i++) {
      amountForGoldlist += numSlots[i];
    require(
      amountForGoldlist <= MaxGoldlist,
      "Whitelist does not match numSlots"
    );
      allowlistG[addresses[i]] += numSlots[i];
    }
  }

  function CheckWhitelist(address addresses) public view returns (uint256) {
    return allowlist[addresses];
  }
  
  function CheckGoldlist(address addresses) public view returns (uint256) {
    return allowlistG[addresses];
  }
  
  //----------------------------↑↑↑-Whitelist-↑↑↑---------------------------------------

  //----------------------------↓↓↓--Equity---↓↓↓--------------------------------------- 
  
  function rand(bytes memory seed, uint bottom, uint top) internal pure returns(uint){
    require(top >= bottom, "bottom > top");
    if(top == bottom){
      return top;
    }
    uint _range = top.sub(bottom);

    uint n = uint(keccak256(seed));
    return n.mod(_range).add(bottom).add(1);
  }

  function addRandEquity(uint256 _quantity, uint256 _tokenIDStart, uint8 _RandType) internal {
    for (uint i = 0; i < _quantity; i++) {
      uint _Equity = getRandEquity(_tokenIDStart + i, i + 1, _RandType);
	  IASCEquity[_tokenIDStart + i] = _Equity;
	  totalIASCEquity += _Equity;
	  addtotalIASCEquity(_Equity);
    }
  }
  
  function designateEquity(uint256 _quantity, uint256 _tokenIDStart, uint256 _desEquity) internal {
    for (uint i = 0; i < _quantity; i++) {
	  IASCEquity[_tokenIDStart + i] = _desEquity;
	  totalIASCEquity += _desEquity;
	  addtotalIASCEquity(_desEquity);
    }
  }
  
  function addtotalIASCEquity(uint256 _Equity) internal {
	if(_Equity == 1){
      totalIASC_N += 1;
	}else if(_Equity == 2){
      totalIASC_S += 1;
    }else if(_Equity == 5){
      totalIASC_G += 1;
    }else{
      totalIASC_D += 1;
    }
  }

  function getRandEquity(uint256 _tokenID, uint256 _Sort, uint8 _RandType) public view returns (uint256) {
    uint _BonusD = 0;
    uint _BonusG = 0;
    uint _BonusS = 0;
	
	if(_tokenID <= 3000 && _Sort > 10){
      _BonusD = _tokenID / 8;
      _BonusG = _tokenID / 10 * 5;
      _BonusS = _tokenID / 10 * 25;
	}else if(_tokenID <= 6000 && _tokenID > 3000 && _Sort > 10){
      _BonusD = _tokenID / 6;
      _BonusG = _tokenID / 10 * 10;
      _BonusS = _tokenID / 10 * 50;
    }else if(_tokenID <= 9000 && _tokenID > 6000 && _Sort > 10){
      _BonusD = _tokenID / 4;
      _BonusG = _tokenID / 10 * 15;
      _BonusS = _tokenID / 10 * 75;
    }else if(_tokenID > 9000 && _Sort > 10){
      _BonusD = _tokenID / 2;
      _BonusG = _tokenID / 10 * 20;
      _BonusS = _tokenID / 10 * 100;
    }

    uint D_NO = _tokenID + _BonusD;
    uint G_NO = _tokenID * 5 + 1000 + _BonusG;
    uint S_NO = _tokenID * 10 + 5000 + _BonusS;

    uint topNO = 100000;
	
	if(_RandType == 1){
      topNO = S_NO;
	}else if(_RandType == 2){
      topNO = G_NO;
    }else if(_RandType == 3){
      topNO = D_NO;
    }
	
    bytes memory seed = abi.encodePacked(block.timestamp.add(_tokenID));
    uint RandNO = rand(seed, 0, topNO);

    if(RandNO <= D_NO){
      return 20;
    }else if(RandNO <= G_NO && RandNO > D_NO){
      return 5;
    }else if(RandNO <= S_NO && RandNO > G_NO){
      return 2;
    }else {
      return 1;
    }
  }

  function getIASCInfo(uint256 _tokenID) public view returns (uint256[] memory) {
    uint256[] memory IASCInfo = new uint256[](2);
    IASCInfo[0] = IASCEquity[_tokenID];
    IASCInfo[1] = _Refund[_tokenID];
    return IASCInfo;
  }

  function gettotalIASCEquity() public view returns (uint256) {
    return totalIASCEquity;
  }

  function getIASCEquity() public view returns (uint256[] memory) {
    uint256[] memory dIASCEquity = new uint256[](5);
    dIASCEquity[0] = totalIASCEquity;
    dIASCEquity[1] = totalIASC_N;
    dIASCEquity[2] = totalIASC_S;
    dIASCEquity[3] = totalIASC_G;
    dIASCEquity[4] = totalIASC_D;
    return dIASCEquity;
  }

  function setIASCEquity(uint256 _tokenID, uint256 _Equity) external onlySCOwner {
    require(_exists(_tokenID), "ERC721Metadata: URI query for nonexistent token");
    if(_Equity > IASCEquity[_tokenID]){
      totalIASCEquity += _Equity - IASCEquity[_tokenID];
    }else if(_Equity < IASCEquity[_tokenID]){
      totalIASCEquity -= IASCEquity[_tokenID] - _Equity;
    }
    IASCEquity[_tokenID] = _Equity;
  }

  function setRandType(uint8 sRandTypeS, uint8 sRandTypeG) external onlySCOwner {
    IASCRandTypeS = sRandTypeS;
    IASCRandTypeG = sRandTypeG;
  }
	
  //----------------------------↑↑↑--Equity---↑↑↑--------------------------------------- 

  //----------------------------↓↓↓--Others---↓↓↓--------------------------------------- 

  function flipSaleState() public onlyOwner {
    IsActive = !IsActive;
  }

  function isPublicSaleOn() public view returns (bool) {
    return block.timestamp >= publicSaleStartTime;
  }

  function withdraw() external onlyOwner {
    (bool success, ) = HighestOwner().call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function withdrawETH(uint256 _ETHWEI) external onlyOwner {
    (bool success, ) = HighestOwner().call{value: _ETHWEI}("");
    require(success, "Transfer failed.");
  }

  function setOwnersExplicit(uint256 quantity) external onlyOwner {
    _setOwnersExplicit(quantity);
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
  
  function _setSCOwner(address _SC) external onlySCOwner {
	_StarshipCommander = _SC;
  }

  function _setInitialize(address _Initialize) external onlySCOwner {
	InitializeIASC = _Initialize;
  }
  
  function checkInitialize() public view returns (address) {
    return InitializeIASC;
  }

  function getInitTraitData(uint tokenId) public view returns (uint256[] memory) {
    require(_exists(tokenId), "IASC: Initialize Trait Data query for nonexistent token");
    return IASC(InitializeIASC).InitTraitData(tokenId);
  }
  
  //----------------------------↑↑↑--Others---↑↑↑--------------------------------------- 

  //----------------------------↓↓↓-Metadata--↓↓↓--------------------------------------- 

  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    //string memory _tokenIdSTR = uint2str(tokenId);
    //string memory URISubfile = ".json";
    //string memory preURI = strConcat(_baseURI(), _tokenIdSTR);
    //return strConcat(preURI, URISubfile);  
    return IASC(InitializeIASC).GettokenURI(tokenId, IASCEquity[tokenId], _Refund[tokenId]);
  }
	
  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return "0";
    }
    uint j = _i;
    uint len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len;
    while (_i != 0) {
      k = k-1;
      uint8 temp = (48 + uint8(_i - _i / 10 * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }
	
  function strConcat(string memory _a, string memory _b) internal view returns (string memory){
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    string memory ret = new string(_ba.length + _bb.length);
    bytes memory bret = bytes(ret);
    uint k = 0;

    for (uint i = 0; i < _ba.length; i++){
      bret[k++] = _ba[i];
    }
    for (uint i = 0; i < _bb.length; i++){
      bret[k++] = _bb[i];
    }
    return string(ret);
  }

  //----------------------------↑↑↑-Metadata--↑↑↑--------------------------------------- 
  
}