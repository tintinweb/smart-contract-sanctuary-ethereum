/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// SPDX-License-Identifier: MIT


//  https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol
pragma solidity ^0.8.0;

interface IERC165 {
   
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol
pragma solidity ^0.8.0;

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



// File: @openzeppelin/contracts/utils/introspection/ERC165.sol
pragma solidity ^0.8.0;

abstract contract ERC165 is IERC165 {
 
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


pragma solidity ^0.8.0;
// conerts to ASCII
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";


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

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol

pragma solidity ^0.8.0;
//address functions
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

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/IERC721Metadata.sol

pragma solidity ^0.8.0;


//ERC-721 Token Standard
 
interface IERC721Metadata is IERC721 {
   
    function name() external view returns (string memory);

   
    function symbol() external view returns (string memory);

  
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721Receiver.sol

pragma solidity ^0.8.0;



interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol
pragma solidity ^0.8.0;

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    string private _name;

    string private _symbol;

    mapping(uint256 => address) private _owners;

    mapping(address => uint256) private _balances;

    mapping(uint256 => address) private _tokenApprovals;

    mapping(address => mapping(address => bool)) private _operatorApprovals;
//coolection constructor
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

   
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }


    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }


    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

   
    function name() public view virtual override returns (string memory) {
        return _name;
    }

 
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

  
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

 
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

   
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

   
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

  
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

 
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

  
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

   
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }


    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

  
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

   
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

  
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

 
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

   
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);


        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

   
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

    
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

  
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}




// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

pragma solidity ^0.8.0;
// owner only commands
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

 //owner constructor
    constructor() {
        _setOwner(_msgSender());
    }

  
    function owner() public view virtual returns (address) {
        return _owner;
    }

   
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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



/*  \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD//   
    \\UNDRTD// //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ \\UNDRTD// 
    \\UNDRTD// //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ \\UNDRTD// 
    \\UNDRTD// //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ \\UNDRTD//
    \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD//   
    \\UNDRTD// //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ \\UNDRTD//  
    \\UNDRTD// //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ \\UNDRTD// 
    \\UNDRTD// //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ \\UNDRTD// 
    \\UNDRTD// //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ \\UNDRTD// 
    \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD// 
    \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD//   
    \\UNDRTD// //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ \\UNDRTD// 
    \\UNDRTD// //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ \\UNDRTD// 
    \\UNDRTD// //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ \\UNDRTD// 
    \\UNDRTD// //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ \\UNDRTD// 
    \\UNDRTD// //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ \\UNDRTD// 
    \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD//   
    \\UNDRTD// //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ \\UNDRTD// 
    \\UNDRTD// //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ \\UNDRTD// 
    \\UNDRTD// //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ //UNDRTD\\ \\UNDRTD// 
    \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD// \\UNDRTD// 


                                          f i r e b u g 5 0 9                     
*/
pragma solidity >=0.7.0 <0.9.0;

contract UNDRTD is ERC721, Ownable {
  using Strings for uint256;
 
  string public _collectionName= "UNDRTD";
  string public _collectionSymbol="UNDRTD";
  string baseURI="ipfs://CID/";
  string public baseExtension = ".json";
  uint256 public cost = 0.1 ether;
  uint256 public maxSupply = 333;

  //track mints
  uint256 public amountMinted;
  uint256 public burnCount;

 //claim list toggle
  bool public claimListActive=false;
  //mint/public toggle
  bool public paused = true;
  bool public revealed = false;
  string public passUri;

    //claim list mapping
    mapping(address => uint256) private _claimList;
    uint256 public claimCount;


  constructor() ERC721(_collectionName, _collectionSymbol)
   {
    setPassURI("ipfs://QmbPbQPRHrCg1StkobXp4sxR4o92CAqgqgYm3nF5MZ5fa9/UNDRTD.json");
    amountMinted=0;
    burnCount=0;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public minting fuction + WL check
  function mint(uint256 _mintAmount) public payable {

    uint256 mintSupply = totalSupply();
//manage public mint
  
      mintSupply=totalSupply();
    require(!paused, "Contract is paused");
    require(_mintAmount > 0, "mint amount cant be 0");
    require(mintSupply + _mintAmount <= maxSupply, "Mint amount is too high there may not be enough left to mint that many");

    if (msg.sender != owner()) {
      require(msg.value >= cost * _mintAmount);
    }
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, mintSupply + i);
    }
    amountMinted+=_mintAmount;
  
  }
  //claimable list mint funtion

function mintClaimList(uint256 numberOfTokens) external payable {
    uint256 currentSupply = totalSupply();

    require(claimListActive, "Claim list is not active");
    require(numberOfTokens <= _claimList[msg.sender], "Exceeded max available to purchase");
    require(currentSupply + numberOfTokens <= maxSupply, "Purchase would exceed max supply");
    // cost taken down to 0 for claims
    //require(cost * numberOfTokens <= msg.value, "Eth value sent is not correct");

    _claimList[msg.sender] -= numberOfTokens;
    for (uint256 i = 1; i <= (numberOfTokens); i++) {
        _safeMint(msg.sender, currentSupply + i);
    }
    if(_claimList[msg.sender]==0){
          claimCount-=1;
      }
    amountMinted+=numberOfTokens;
 }

//return total supply minted
 function totalSupply() public view returns (uint256) {
    return amountMinted;
  }
//gas efficient function to find token ids owned by address

   function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
    
    if(revealed == false) {
        return passUri;
    }
    if(tokenId>amountMinted) {
        return passUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }
  //actions for the owner to interact with contract
  function setReveal(bool _newBool) public onlyOwner() {
      revealed = _newBool;
  }
// update mint cost
  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }

//revealed bool  
  function setPassURI(string memory _passURI) public onlyOwner {
    passUri = _passURI;
  }
//base URI extension
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }
//set extension (.json)
  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
//contract paused state
  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  //white list fuctions

//claim functions
//set single claim address
function setClaimList(address addressInput, uint256 numAllowedToMint) external onlyOwner {
       
            _claimList[addressInput] = numAllowedToMint;
            claimCount+=1;
    }
//set claim list to true or false for active
    function setClaimListActive(bool _claimListActive) external onlyOwner {
        claimListActive = _claimListActive;
    }
//reset claimCount (claim list count)
    function claimCountReset(uint256 _newCount) public onlyOwner {
        claimCount=_newCount;
    }
//set a full claim address list 
function setFullClaimList(address[] calldata addresses, uint256 numAllowedToMint) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
        _claimList[addresses[i]] = numAllowedToMint;
    }
    claimCount+=addresses.length;
}
//burn
  function burn(uint _tokenId) external {
    require(_isApprovedOrOwner(_msgSender(), _tokenId));
    _burn(_tokenId);
    burnCount++;
  }

//witdraw to retrieve all funds to deployment account 
  function PrimaryWithdraw() public payable onlyOwner {
 
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}