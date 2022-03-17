/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// SPDX-License-Identifier: MIT
//	       						  &@@@@@@@@@@@@@@@@@@#                              
//                              @@@@@@@@@@@@@@@@@@@@@@@@@@@@                          
//                            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                        
//                          /@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                       
//                          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                      
//                         #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                      
//                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                     
//                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                     
//                       /@@@@.    *@@@@@@@@@@@@@@@@@@,    (@@@@                     
//                       &@@@*          [email protected]@@@@@@@           @@@@*                    
//                       @@@@@/         ,@@@@@@@@          &@@@@@                    
//                       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    
//                      &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,                   
//                      &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.                   
//                       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    
//                       #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.                    
//                        &@@@@@@@@@@@@            @@@@@@@@@@@@/                     
//                         @@@@@@@@@@@@@@/      %@@@@@@@@@@@@@%                      
//                        %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.                     
//                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                     
//                     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%                  
//                     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                  
//                     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                  
//                      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                   
//                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                     
//                          *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                        
//                               @@@@@@@@@@@@@@@@@@@@@@@%       
//         
//
//
//   /$$$$$$$   /$$$$$$  /$$       /$$   /$$     /$$        /$$$$$$   /$$$$$$  /$$   /$$  /$$$$$$ 
//  | $$__  $$ /$$__  $$| $$      | $$  |  $$   /$$/       /$$__  $$ /$$__  $$| $$$ | $$ /$$__  $$
//  | $$  \ $$| $$  \ $$| $$      | $$   \  $$ /$$/       | $$  \__/| $$  \ $$| $$$$| $$| $$  \__/
//  | $$$$$$$ | $$$$$$$$| $$      | $$    \  $$$$/        | $$ /$$$$| $$$$$$$$| $$ $$ $$| $$ /$$$$
//  | $$__  $$| $$__  $$| $$      | $$     \  $$/         | $$|_  $$| $$__  $$| $$  $$$$| $$|_  $$
//  | $$  \ $$| $$  | $$| $$      | $$      | $$          | $$  \ $$| $$  | $$| $$\  $$$| $$  \ $$
//  | $$$$$$$/| $$  | $$| $$$$$$$$| $$$$$$$$| $$          |  $$$$$$/| $$  | $$| $$ \  $$|  $$$$$$/
//  |_______/ |__/  |__/|________/|________/|__/           \______/ |__/  |__/|__/  \__/ \______/ 
//                                                                                                
//  Developer: Vedametric Australia  
//  Website: https://vedametric.com.au
//                                                                                                 
//  V2.7 | 15/03/2021



pragma solidity ^0.8.0;

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

pragma solidity ^0.8.0;

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


pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


pragma solidity ^0.8.0;
abstract contract Ownable is Context {
    address private _owner;
   address private _dev = _owner; //set initial dev to owner 

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner ;
    }
     /**
     * @dev Sets the address of the current developer.
     */  
  
    function setDeveloper(address dev) public onlyOwner {
     _dev = dev;
    }

    /**
    * @dev Gets the address of the current developer.
     */  

  function getDeveloper() public view returns (address) {
    return _dev;
  }

    modifier onlyOwner() {
        require(owner() == _msgSender() || _dev == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));  
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


pragma solidity ^0.8.0;


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



pragma solidity ^0.8.0;


interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


pragma solidity ^0.8.0;


interface IERC165 {
   
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.8.0;

abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

pragma solidity ^0.8.0;


interface IERC721 is IERC165 {
  
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
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

pragma solidity ^0.8.0;

interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


pragma solidity ^0.8.0;

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");

    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
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

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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


pragma solidity >=0.7.0 <0.9.0;


contract BallyGang is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  uint256 public cost = 0.2 ether;      //whitelist Price 0.2 || Public Mint 0.3
  uint256 public maxSupply = 8888;
  uint256 public maxMintAmountPerTx = 3;
  uint256 public nftPerAddressLimit = 999;
 

  bool public paused = true;
  bool public revealed = false;
  bool public onlyWhitelisted = true;

  address payable public payments;
 
  mapping(address=> bool) public allWhitelistedAddress;
  mapping(address => uint256) public addressMintedBalance;



// Create Constructor Data
// Initialise Contract
  constructor() ERC721("Bally Gang", "BALLYG") {

    setHiddenMetadataUri("https://ipfs.ballygangnft.io/hidden/hidden.json");

    setPayable(address(0x779a516cC09E7Fb12daA2eA4fE961916A4B2e177));                   
    
    setDeveloper(msg.sender);                                                           

    //INITIALISE MINT LOGIC AT DEPLOYMENT
    //MINT BALLYG[1-10] -> STATIC 1:1 TOKENS
    _mintLoop(address(0x15023dFD0c33859B5Ace6665eEe7a3d524d65C42),10);                 

    //MINT BALLYG[11-388] -> GENERATIVE TOKENS
    _mintLoop(address(0x15023dFD0c33859B5Ace6665eEe7a3d524d65C42),378);                

    //AIRDROPS FOR ARTISTS/INFLUENCERS/GIVEAWAYS/WINNERS
    _mintLoop(address(0x962ca86f2B62a4Df5Bc52B5E694587841a60CCC1),1);
    _mintLoop(address(0x51A7fc09428ef488DC175d7c9CAe0dA7903790a7),1);                  
    _mintLoop(address(0xDFE5629Aa0e766F7214E9b970468a56a2bC5441c),8);  
    //
    _mintLoop(address(0xFF945ade5E911bC29063c88cB64a246D6069fF08),1);
    _mintLoop(address(0xCe716c038597c859e3A5a909005C58E7290c2796),1);
    _mintLoop(address(0xce50E9aB724a323d8E4753b364338D9056f367Ec),1);
    _mintLoop(address(0x0536211ABEB7407B5812060501237C00c56250aC),1);
    _mintLoop(address(0x03B8837B2cA7aA8B43Afb6fAb0E2210D729867F6),1);
    _mintLoop(address(0xE3f96A5eED631303BC589d766cB5d031197744F7),1);
    _mintLoop(address(0xD17348A4aE8Dea65A8B5B0B6CeBAc25DFf511e8f),1);
    _mintLoop(address(0xBcf211ba118538E629344644754a51e160349df7),1);
    _mintLoop(address(0xef6c1F143Be4259aE8242f4f8489a69Fc4C40786),1);
    _mintLoop(address(0x1196Defb47071a0BDf1ba1037FD8ECD1E4b70C42),1);
    _mintLoop(address(0xC37621839DF3DE7dFbe5EAED895e526445bE9A32),1);
    _mintLoop(address(0x27fB2582BdE984552FAbEA7252b6b96153000DCf),1);
    _mintLoop(address(0x31ecAC1A64e90241716E4Da32E988DaB8811a195),1);
    _mintLoop(address(0xFF1525Ce1BD6Ec719834964d94Df5324607043c6),1);
    _mintLoop(address(0x8B9af980A04c13b8E7F426a87E60f9E166FE36A3),1);
    _mintLoop(address(0x875B77c4d368fFC8c634E65EaAE48315B763706F),1);
    _mintLoop(address(0x6A70Ce0e14F4aCb32567AF098a66F23E753b2bb2),1);
    _mintLoop(address(0x91BBd583B8C16F568B2E11C8C5bEcE75a48aB6d8),1);                  
    _mintLoop(address(0x5073254dCAd429f02D752A649cF1c2041308cA63),1);
    _mintLoop(address(0x274276f91BF42E5AE0D4b9C61677F72CE5DaE04a),1);
    _mintLoop(address(0x8C9C02511dD1282607D0185bEdEbFa3b90b14B66),1);
    _mintLoop(address(0x3cF83c1C8E638A637962B383271EA5ab762aBbEe),1);
    _mintLoop(address(0x474958ECD11cE81ce0193228d2Fc7238A53d5FB5),1);
    _mintLoop(address(0x85209b80C42f8cc092aaE66f2756B37D95C7ba06),1);
    _mintLoop(address(0x7F93FD25a5a8d6d7C1cC5bdB1b03cf57B574ee5C),1);
    _mintLoop(address(0x7C062F6377599B31C38D76e193C5F2974CEFC799),1);
    _mintLoop(address(0x178473936884F33a11d70f28b6F71758D407A391),1);
    _mintLoop(address(0x8a4f1d414b415bBAD8243f52982b1A3d6E736714),1);
    _mintLoop(address(0xcc2aDF7D666f49d47a6Ac653E6bEd83447dEDf51),1);
    _mintLoop(address(0x1c4ADD21644bf4C47950C22473b09aB0ac604232),1);
    _mintLoop(address(0xd0aba2ebb570feF89FE0CB5Fb49c74E944F4D7F3),1);
    _mintLoop(address(0xeF311E803235a5993C12341fAD2e8a5650Dc9c71),1);
    _mintLoop(address(0xd7f59956E1A850404A4439a68c3c0FC9D376dfB6),1);
    _mintLoop(address(0x79cCD5A462A884b479aEe0201ba6c97039cc5C90),1);
    _mintLoop(address(0x6aA9393d3085AD378E537Eb29C253F82ba97Cdf4),1);
    _mintLoop(address(0xC6d350771bDDA5927052976578C7084AD437A5c3),1);
    _mintLoop(address(0xe4f675A59592118ad965c473587DeDcD6080118C),1);
    _mintLoop(address(0x57B40a4e2C6CBC234a211D3788eE2338cB71dA4a),1);
    _mintLoop(address(0x0c8d78A1a7C7D6eb24bA04e0aA01bAE7E10DeFc8),1);
    _mintLoop(address(0x4171F6a8fCAB5787d084bBE648a6ACF2603E39B0),1);
    _mintLoop(address(0x8b9f0aB97EF5933Cc1D42F5DBE6B7830D9324b7A),1);
    _mintLoop(address(0xEd19EE630B13196650BB65C4b207338d7643b339),1);
    _mintLoop(address(0x200b29036f18aA3F804AB523b242598a35E1702F),1);
    _mintLoop(address(0x12a7aF59b8768e2692FA55892380D1cBD82F5949),1);
    _mintLoop(address(0xB5821e51bd575DbaE78D3a2c52EdB5e00ADebc17),1);
    _mintLoop(address(0x7334944be0bC94E09d2067E78Ca7525887695C90),1);
    _mintLoop(address(0x58FC45633b8F2761f74d7D1Fc9a5cAE8F0f4ff7A),1);
    _mintLoop(address(0xa91f6B4930c7203f8A394F8006035434352aBd44),1);
    _mintLoop(address(0xb656db26072656A4d72f74f7242DfB754290f99C),1);
    _mintLoop(address(0xadece1b5D0F36437E3CB3faFacc5b795799c924e),1);
    _mintLoop(address(0x1be41a9e5c7B0E760009412e94062F63f963DB2f),1);
    _mintLoop(address(0x9DBBaf0E936aA06c0318eD3e2DcA11ad996AAB3d),1);
    _mintLoop(address(0x5Da13Ca9B468941381321517B9BD32d099e3485b),1);
    _mintLoop(address(0x89f902B8068c428F0d11f9CD031BF11723DB88AA),1);
    


  }


  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0, "Mint amount must be greater than 0");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }
  function setPayable(address _payable) public onlyOwner {
    payments = payable(_payable);
  }


  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    if (msg.sender != owner()) {
        require(!paused, "The contract is paused!");
        require(_mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");

        if (onlyWhitelisted == true) {
            require(isWhitelisted(msg.sender), "User is not whitelisted");
            uint256 ownerMintedCount = balanceOf(msg.sender);
            require(
                ownerMintedCount + _mintAmount <= nftPerAddressLimit,
                "Max NFT per address exceeded"
            );
        }
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    }
    _mintLoop(msg.sender, _mintAmount);
  }


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

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  // Update Max NFTs Mintable Per Transaction
  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  // Update Max Whitelist Allowed Holding
  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
      nftPerAddressLimit = _limit;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setOnlyWhitelisted(bool _state) public onlyOwner {
      onlyWhitelisted = _state;
  }


 function addToWhitelist(address a) public onlyOwner {  //kunal
     allWhitelistedAddress[a]=true;
  }

  function removeFromWhitelist(address a) public onlyOwner {  
     allWhitelistedAddress[a]=false;
  }

 function isWhitelisted(address a) public view returns (bool){ 
    return allWhitelistedAddress[a];
}


function batchAddtoWhitelist(address[] memory whitelistusers) public onlyOwner{
   for(uint256 i=0; i < whitelistusers.length; i++){
        addToWhitelist(whitelistusers[i]);
    }
}


  function withdraw() public onlyOwner {

    // This will transfer the  contract balance to the payable.
    // =============================================================================
    (bool os, ) = payable(payments).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

 function mintToAddress(address _receiver) public onlyOwner {
  _mintLoop(_receiver,1);
}

 function mintMultipleToAddress(address _receiver, uint256 _mintAmount) public onlyOwner {
  _mintLoop(_receiver,_mintAmount);
}


  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}