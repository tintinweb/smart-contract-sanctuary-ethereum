// SPDX-License-Identifier: MIT

import "@beskay/erc721b/contracts/ERC721B.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

pragma solidity ^0.8.4;

library LibPart {
    bytes32 public constant TYPE_HASH = keccak256("Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}

// Developer: uglyrobot.eth
contract HouseOfFinns is ERC721B, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    /*
     * bytes4(keccak256('getRoyalties(LibAsset.AssetType)')) == 0x44c74bcc
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES = 0x44c74bcc;

    string public hofProvenance; // Hash of all images
    
    string private _licenseText;
    bool public licenseLocked; // Init false. Team can't edit the license after this is flipped.
    
    string private _baseTokenURI; // Will be updated with IPFS url once minted out
    bool public baseURILocked; // Init false. Team can't change the baseURI after flipping this, making the metadata truly locked forever.
    string public contractURI; //used by OpenSea, not an official standard
    
    uint256 public hofPrice = 80000000000000000; // 0.08 ETH
    uint96 private _royaltyBPS = 500; // 5% royalty for Rarible/Mintable
    address private _royaltyReceiver; //address of wallet to receive royalties. Defaults to owner().

    uint256 public constant HOF_MAX = 10000; //cannot be changed
    uint256 public maxHofPurchase = 50; //max per mint, to make sale fairer.

    bool public saleIsActive;// Init false.

    uint256 public marketingReserve = 850; // Reserve for marketing - Giveaways/Prizes etc

    address public withdrawAddress; //address of profits wallet
    

    event licenseIsLocked(string _licenseText);
    event metadataLocked(string _baseTokenURI);

    constructor(
        address _teamWallet, 
        string memory _initLicenseText, 
        string memory _initBaseTokenURI,
        string memory _ContractURI
    ) ERC721B("House of Finns", "HOF") payable {
        withdrawAddress = _teamWallet; //set marketing team address
        _royaltyReceiver = _teamWallet; //default to owner
        _licenseText = _initLicenseText;
        _baseTokenURI = _initBaseTokenURI;
        contractURI = _ContractURI;
    }
    
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier contractOwner() {
        _isOwner();
        _;
    }

    /**
    * This actually saves a chunk of contract deployment gas when modifier is used multiple times.
    */
    function _isOwner() internal view {
        require(owner() == _msgSender(), "Ownable: not the owner");
    }
    
    function withdraw() public {
        require(withdrawAddress == msg.sender, "Withdrawl wallet only");

        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    //Rarible royalty interface new
    function getRaribleV2Royalties(uint256 /*id*/) external view returns (LibPart.Part[] memory) {
         LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _royaltyBPS;
        _royalties[0].account = payable(_royaltyReceiver);
        return _royalties;
    }

    //Mintable royalty handler
    function royaltyInfo(uint256 /*_tokenId*/, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
       return (_royaltyReceiver, (_salePrice * _royaltyBPS)/10000);
    }

    // Register support for our two royalty standards, falling back to inherited contracts
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721B) returns (bool) {
        if(interfaceId == _INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if(interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    /**
     * Slightly more gas efficient than balanceOf for merely returning ownership status.
     */
    function isFinnsOwner(address owner) public view virtual returns (bool) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();

        uint256 qty = _owners.length;
        // Cannot realistically overflow, since we are using uint256
        unchecked {
            for (uint256 i = 0; i < qty; i++) {
                if (owner == ownerOf(i)) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * Returns array of tokens only from the last mint in descending order. Transfers
     * will affect this, it's only useful right after minting.
     * It is not recommended to call this function from another smart contract
     * as it can become quite expensive -- call this function off chain instead.
     */
    function latestMinted(address owner) public view virtual returns (uint256[] memory) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        
        if (totalSupply() == 0) {
            return new uint256[](0);
        }

        uint256 count;
        uint256 start;
        bool started;
        for (uint256 tokenId = _owners.length-1; tokenId >= 0; tokenId--) {
            if (!started && _owners[tokenId] == owner) {
                start = tokenId;
                started = true;
                count++;
            } else if (_owners[tokenId] == address(0)) {
                count++;
            } else if (count >= 1) {
                break;
            }

            if (tokenId == 0) {
                break;
            }
        }

        uint256 i;
        uint256 end = 0;
        if (count <= start) { //prevent underflow
            end = start - count;
        }
        uint256[] memory tokenIds = new uint256[](count);
        for (uint256 tokenId = start; tokenId > end; tokenId--) {
            tokenIds[i] = tokenId;
            i++;
        }

        return tokenIds;
    }

    // see https://medium.com/coinmonks/the-elegance-of-the-nft-provenance-hash-solution-823b39f99473
    function setProvenanceHash(string memory provenanceHash) public contractOwner {
        hofProvenance = provenanceHash;
    }

    //change the metadata baseURI
    function setBaseURI(string memory baseURI) public contractOwner {
        require(baseURILocked == false, "Already locked");
        _baseTokenURI = baseURI;
    }

    // Locks the baseURI to prevent further metadata changes. Only lock if it's all in onchain storage, and you will never need to update it again, or you're screwed!
    function lockBaseURI() public contractOwner {
        baseURILocked = true;
        emit metadataLocked(_baseTokenURI);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(_baseTokenURI).length > 0 ? string(abi.encodePacked(_baseTokenURI, tokenId.toString())) : "";
    }

    //used by OpenSea
    function setContractURI(string memory _uri) public contractOwner {
        contractURI = _uri;
    }

    //This enables minting
    function flipSaleState() public contractOwner {
        saleIsActive = !saleIsActive;
    }

    // Returns the license for tokens
    function tokenLicense(uint256 _id) public view returns(string memory) {
        require(_id < totalSupply(), "Invalid token");
        return _licenseText;
    }
    
    // Locks the license to prevent further changes 
    function lockLicense() public contractOwner {
        licenseLocked = true;
        emit licenseIsLocked(_licenseText);
    }
    
    // Change the license
    function changeLicense(string memory _license) public contractOwner {
        require(licenseLocked == false, "Already locked");
        _licenseText = _license;
    }
    
    // Change the mintPrice
    function setMintPrice(uint256 _newPrice) public contractOwner {
        require(_newPrice != hofPrice, "Not new value");
        hofPrice = _newPrice;
    }
    
    // Change the royaltyBPS
    function setRoyaltyBPS(uint96 _newRoyaltyBPS) public contractOwner {
        require(_newRoyaltyBPS != _royaltyBPS, "Not new value");
        _royaltyBPS = _newRoyaltyBPS;
    }
    
    // Change the royalty receiver address
    function setRoyaltyReceiver(address _account) public contractOwner {
        require(_account != _royaltyReceiver, "Not new value");
        _royaltyReceiver = _account;
    }

    //calculate the mint limit factoring in balances of all reserves
    function _mintLimit() internal virtual returns (uint256 limit) {
        if (marketingReserve > HOF_MAX) {
            return HOF_MAX;
        } else {
            return HOF_MAX - marketingReserve;
        }
    }
    
    // Change per-mint limit
    function setMaxHofPurchase(uint256 _limit) public contractOwner {
        require(maxHofPurchase != _limit, "Not new value");
        maxHofPurchase = _limit;
    }

    /*---------------- Mint Functions -----------*/
    
    // Mint function for marketing reserve
    function reserveMintMarketing(address _to, uint256 _reserveAmount) public contractOwner {        
        require(_reserveAmount > 0 && _reserveAmount <= marketingReserve, "Exceeds reserve remaining");
        require(totalSupply() + _reserveAmount < HOF_MAX, "Exceeds  supply");

        marketingReserve -= _reserveAmount;
        _safeMint(_to, _reserveAmount);
    }
    
    // Mint function for marketing reserve to multiple addresses
    function reserveMintMarketingMass(address[] memory _to, uint256[] memory _reserveAmount) public contractOwner { 
        require(_to.length == _reserveAmount.length, "To and amount length mismatch");
        require(_to.length > 0, "No tos");

        uint256 totalReserve = 0;
        for (uint256 i = 0; i < _to.length; i++) {
            totalReserve += _reserveAmount[i];
        }       
        require(totalReserve > 0 && totalReserve <= marketingReserve, "Exceeds reserve remaining");
        require(totalSupply() + totalReserve < HOF_MAX, "Exceeds  supply");

        marketingReserve -= totalReserve;
        for (uint256 i = 0; i < _to.length; i++) {
            _safeMint(_to[i], _reserveAmount[i]);
        }
    }

    //Mint for the hof minting drop
    function mintFinns(uint256 numberOfTokens) public payable nonReentrant {
        require(saleIsActive, "Sale Inactive");
        require(numberOfTokens > 0 && numberOfTokens <= maxHofPurchase, "Exceeds transaction max");
        require(totalSupply() + numberOfTokens < _mintLimit(), "Exceeds max supply");
        require(msg.value == hofPrice * numberOfTokens, "Check price");
        
        _safeMint(msg.sender, numberOfTokens);
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

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
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