// SPDX-License-Identifier: MIT
/*                 
                                                           @@@@@@@@@@@                                        
                                                        @@@@@@@@@@@@@@@(                        
                                                     @@@          &@@, #@@@@                    
                                                    @@              @@     @@@                 
                                        @@@@@@@@@@@@@                      @@/   @@@@@@        
                                 &@@@@@@%           @@                .     @@@   @@@ @@@       
                             [email protected]@@&                  @@@              @@/    @@#    @@  @@       
                           ,@@&                      &@@             #     (@@     @@  @@      
                          @@@                          @@@,       @@@      @@     @@@  @@      
                         [email protected]@                              @@@@@@@@@        @@@@@@@@    @@      
                         &@@                                                          @@@       
                         @@(                                    #&@@                &@@(        
                          @@@                                   @@ &@@@&        /@@@@           
                          %@@                                  @#%     (@@@@@@@@&               
                           @@                 *&@@@@@@@.       @@                               
                           @@/      /@@@@@@@@%(       @@      @@@                               
                           @@&      @@,               @@      @@                                
                           &@@      @@                @@      @@                                
                            @@      @@(               @@      @@                                
                            @@#     (@@               @@@     @@                                
                             (@@@@@@@#                  &@@@@@#                                 
                                      



 /$$$$$$$$ /$$                     /$$                                 /$$                              
| $$_____/| $$                    | $$                                | $$                              
| $$      | $$  /$$$$$$   /$$$$$$ | $$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$  /$$$$$$   /$$$$$$  /$$   /$$
| $$$$$   | $$ /$$__  $$ /$$__  $$| $$__  $$ |____  $$| $$__  $$ /$$__  $$ |____  $$ /$$__  $$| $$  | $$
| $$__/   | $$| $$$$$$$$| $$  \ $$| $$  \ $$  /$$$$$$$| $$  \ $$| $$  | $$  /$$$$$$$| $$  \__/| $$  | $$
| $$      | $$| $$_____/| $$  | $$| $$  | $$ /$$__  $$| $$  | $$| $$  | $$ /$$__  $$| $$      | $$  | $$
| $$$$$$$$| $$|  $$$$$$$| $$$$$$$/| $$  | $$|  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$$| $$      |  $$$$$$$
|________/|__/ \_______/| $$____/ |__/  |__/ \_______/|__/  |__/ \_______/ \_______/|__/       \____  $$
                        | $$                                                                   /$$  | $$
                        | $$                                                                  |  $$$$$$/
                        |__/                                                                   \______/


@author:   Baris Arya CANTEPE  (@bcantepe)


*/
pragma solidity ^0.8.4;

import "@beskay/erc721b/contracts/ERC721B.sol"      ;
import "@openzeppelin/contracts/access/Ownable.sol" ;
import "@openzeppelin/contracts/utils/Strings.sol"  ;

contract Elephandary is ERC721B, Ownable {
using Strings for uint256;

// Contract Variables

uint256 public maxSupply = 4444;
uint256 public constant maxFreeMint = 1500 ;
uint256 public constant teamReservedSupply = 81;

uint256 public mintPrice = 0 ether ;
uint256 public maxFreeMintPerWallet = 1 ; 
uint256 public maxMintPerWallet = 31 ;
uint256 public maxMintPerTx = 30; 

uint256 public teamMinted; 
bool    public saleStatus = true;

string  public baseTokenUrl = "ipfs://QmS27ifo6mTBhHHJynKgxhoqamT6f2WAkXgPvHejoUZvsY/";
string  public tokenUrlSuffix = ".json";

mapping (address => uint256) public _numberMinted ; // bool da olabilir


address constant KITTEN1   = 0x69CC9A9E7f38117dc40d850dF43eC21b6B416A47 ; // Mojo Jojo
address constant KITTEN2   = 0xd8925d9BC9D55b7a25428D3593b1b425388c6287 ; // Blossom
address constant KITTEN3   = 0x8c1715Ac3466547193567e403752960114CB3147 ; // Bubbles
address constant KITTEN4   = 0xd2ECFb430B55E0726b77Eb84380FB531cfdE1EA9 ; // Buttercup
//adresler en son tekrar kontrol edilsin hata olması ihtimaline karşı

constructor () ERC721B( "Elephandary" , "ELEPHAN") { }

// Mint

function freeMint () external onlyAccount() {

uint256 _maxFreeMint = 1500;
uint256 _teamReservedSupply = 81;
//Created variables again on memory to save gas. 
require(_numberMinted[msg.sender] < 1, "You can't mint free anymore");
require(totalSupply() + 1 <= ( _maxFreeMint + _teamReservedSupply) , "Maximum free mint amount reached.");
require(saleStatus == true , "Mint is inactive.");

_numberMinted[msg.sender] += 1 ;
_mint(msg.sender, 1);
  
}

//mintRequirements(amount_)
function publicMint (uint256 amount_) public payable  onlyAccount() {
_numberMinted[msg.sender] += amount_ ;
_mint(msg.sender, amount_);

}


function teamMint(address to, uint256 _amount) external onlyOwner {

    require( teamMinted + _amount < teamReservedSupply + 1,   "No more Team mint" );
    require(totalSupply() + _amount < maxSupply + 1, "Max supply exceed");

    teamMinted += _amount;
    _safeMint(to, _amount);
  
  }


// Owner Functions

// This function can only reduce max supply. 
function reduceSupply (uint256 _maxSupply) external onlyOwner {

require(_maxSupply < maxSupply, "Supply can not be increased, only reduce.") ;

maxSupply = _maxSupply ;

}

function withdraw() external onlyOwner {

uint256 balance = address(this).balance ;
require (balance > 0 , "Zero balance, can not withdraw") ;

_withdraw(KITTEN1, (balance * 250) / 1000) ;
_withdraw(KITTEN2, (balance * 250) / 1000) ;
_withdraw(KITTEN3, (balance * 250) / 1000) ;
_withdraw(KITTEN4, (balance * 250) / 1000) ;

}

function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");   
        }

// Variable Changers
function setMintPrice (uint256 mintPrice_) external onlyOwner {
mintPrice = mintPrice_ ;
}

function setMaxMintPerWallet (uint256 maxMintPerWallet_) external onlyOwner {
maxMintPerWallet = maxMintPerWallet_ ;
}

function setMaxMintPerTx (uint256 maxMintPerTx_) external onlyOwner {
maxMintPerTx = maxMintPerTx_ ;
}

function setSaleStatus (bool saleStatus_) external onlyOwner {
    saleStatus = saleStatus_ ;
}

function setBaseTokenUrl(string memory _baseTokenUrl) public onlyOwner {
    baseTokenUrl = _baseTokenUrl;
  }

function setTokenUrlSuffix(string memory _tokenUrlSuffix) public onlyOwner {
    tokenUrlSuffix = _tokenUrlSuffix;
  }



// View Functions

  function _baseURI() internal view returns (string memory) {
    return baseTokenUrl;
  }

  function _suffix() internal view virtual returns (string memory) {
    return tokenUrlSuffix;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
  {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    string memory baseURI = _baseURI();
    string memory suffix = _suffix();
    return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), suffix)): "";
  
  }



// Modifiers

modifier mintRequirements (uint256 _amount) {
    require(_amount > 0 , "Mint amount can not be 0");
    require(totalSupply() + _amount <= ( maxSupply - teamReservedSupply)  , "Maximum mint amount reached"); 
    require(_numberMinted[msg.sender] + _amount <= maxMintPerWallet , "You've minted max amount" );
    require(_amount <= maxMintPerTx , "Max mint amount per tx exceed");
    require(saleStatus == true , "Public mint is inactive");
    require(msg.value >= _amount  * mintPrice , "Insufficient ETH");
    _;
    }

modifier onlyAccount() {
    // Contracts are not allowed
    require(msg.sender == tx.origin, "Only accounts ser.");
    _;
     }

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintedQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerIndexOutOfBounds();
error OwnerQueryForNonexistentToken();
error TokenIndexOutOfBounds();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error UnableDetermineTokenOwner();
error UnableGetTokenOwnerByIndex();
error URIQueryForNonexistentToken();

/**
 * Updated, minimalist and gas efficient version of OpenZeppelins ERC721 contract.
 * Includes the Metadata and  Enumerable extension.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 * Does not support burning tokens
 *
 * @author beskay0x
 * Credits: chiru-labs, solmate, transmissions11, nftchance, squeebo_nft and others
 */

abstract contract ERC721B {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 tokenId) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                          ERC721 STORAGE
    //////////////////////////////////////////////////////////////*/

    // Array which maps token ID to address (index is tokenID)
    address[] internal _owners;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x780e9d63 || // ERC165 Interface ID for ERC721Enumerable
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       ERC721ENUMERABLE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _owners.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * Dont call this function on chain from another smart contract, since it can become quite expensive
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256 tokenId) {
        if (index >= balanceOf(owner)) revert OwnerIndexOutOfBounds();

        uint256 count;
        uint256 qty = _owners.length;
        // Cannot realistically overflow, since we are using uint256
        unchecked {
            for (tokenId; tokenId < qty; tokenId++) {
                if (owner == ownerOf(tokenId)) {
                    if (count == index) return tokenId;
                    else count++;
                }
            }
        }

        revert UnableGetTokenOwnerByIndex();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual returns (uint256) {
        if (index >= totalSupply()) revert TokenIndexOutOfBounds();
        return index;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Iterates through _owners array, returns balance of address
     * It is not recommended to call this function from another smart contract
     * as it can become quite expensive -- call this function off chain instead.
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();

        uint256 count;
        uint256 qty = _owners.length;
        // Cannot realistically overflow, since we are using uint256
        unchecked {
            for (uint256 i = 0; i < qty; i++) {
                if (owner == ownerOf(i)) {
                    count++;
                }
            }
        }
        return count;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        if (!_exists(tokenId)) revert OwnerQueryForNonexistentToken();

        // Cannot realistically overflow, since we are using uint256
        unchecked {
            for (uint256 i = tokenId; ; i++) {
                if (_owners[i] != address(0)) {
                    return _owners[i];
                }
            }
        }

        revert UnableDetermineTokenOwner();
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual {
        address owner = ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) revert ApprovalCallerNotOwnerNorApproved();

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        if (operator == msg.sender) revert ApproveToCaller();

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        if (!_exists(tokenId)) revert OwnerQueryForNonexistentToken();
        if (ownerOf(tokenId) != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        bool isApprovedOrOwner = (msg.sender == from ||
            msg.sender == getApproved(tokenId) ||
            isApprovedForAll(from, msg.sender));
        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();

        // delete token approvals from previous owner
        delete _tokenApprovals[tokenId];
        _owners[tokenId] = to;

        // if token ID below transferred one isnt set, set it to previous owner
        // if tokenid is zero, skip this to prevent underflow
        if (tokenId > 0) {
            if (_owners[tokenId - 1] == address(0)) {
                _owners[tokenId - 1] = from;
            }
        }

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        if (!_checkOnERC721Received(from, to, id, '')) revert TransferToNonERC721ReceiverImplementer();
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        if (!_checkOnERC721Received(from, to, id, data)) revert TransferToNonERC721ReceiverImplementer();
    }

    /**
     * @dev Returns whether `tokenId` exists.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId < _owners.length;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert TransferToNonERC721ReceiverImplementer();
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

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev check if contract confirms token transfer, if not - reverts
     * unlike the standard ERC721 implementation this is only called once per mint,
     * no matter how many tokens get minted, since it is useless to check this
     * requirement several times -- if the contract confirms one token,
     * it will confirm all additional ones too.
     * This saves us around 5k gas per additional mint
     */
    function _safeMint(address to, uint256 qty) internal virtual {
        _mint(to, qty);

        if (!_checkOnERC721Received(address(0), to, _owners.length - 1, ''))
            revert TransferToNonERC721ReceiverImplementer();
    }

    function _safeMint(
        address to,
        uint256 qty,
        bytes memory data
    ) internal virtual {
        _mint(to, qty);

        if (!_checkOnERC721Received(address(0), to, _owners.length - 1, data))
            revert TransferToNonERC721ReceiverImplementer();
    }

    function _mint(address to, uint256 qty) internal virtual {
        if (to == address(0)) revert MintToZeroAddress();
        if (qty == 0) revert MintZeroQuantity();

        uint256 _currentIndex = _owners.length;

        // Cannot realistically overflow, since we are using uint256
        unchecked {
            for (uint256 i = 0; i < qty - 1; i++) {
                _owners.push();
                emit Transfer(address(0), to, _currentIndex + i);
            }
        }

        // set last index to receiver
        _owners.push(to);
        emit Transfer(address(0), to, _currentIndex + (qty - 1));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

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
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}