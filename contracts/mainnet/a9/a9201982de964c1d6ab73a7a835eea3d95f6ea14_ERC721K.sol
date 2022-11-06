/**
 *Submitted for verification at Etherscan.io on 2022-11-06
*/

// SPDX-License-Identifier: CC BY-NC-ND 4.0

pragma solidity ^0.8.17;

/** INFO
 * Refinement of the work made at https://github.com/beskay/ERC721B
 * Public mint added, as well as price management
 * On chain metadata is now available
 * The contract is now compatible with baseURI and tokenURI mechanisms
 * Security has been handled with protected contract
 * Single tokens approve for granular ACL is now supported
 * Minting by sending price value or multiple of price value to contract is allowed
 * @author TheCookingSenpai
 *
 * ANCHOR Original ERC721B Header
 * Updated, minimalist and gas efficient version of OpenZeppelins ERC721 contract.
 * Includes the Metadata and  Enumerable extension.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 * Does not support burning tokens TODO
 *
 * Credits: beskay0x, chiru-labs, solmate, transmissions11, nftchance, squeebo_nft and others
 */

// SECTION Interfaces
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
// !SECTION Interfaces

// SECTION Safety
contract protected {
    mapping (address => bool) is_auth;
    function authorized(address addy) public view returns(bool) {
        return is_auth[addy];
    }
    function set_authorized(address addy, bool booly) public onlyAuth {
        is_auth[addy] = booly;
    }
    modifier onlyAuth() {
        require( is_auth[msg.sender] || msg.sender==owner, "not owner");
        _;
    }
    address owner;
    modifier onlyOwner() {
        require(msg.sender==owner, "not owner");
        _;
    }
    bool locked;
    modifier safe() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }

    function change_owner(address new_owner) public onlyAuth {
        owner = new_owner;
    }
    fallback() external {}
}
// !SECTION Safety

// SECTION Errors
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
// !SECTION Errors


 contract ERC721K is protected {
    /*
                                 EVENTS
    */

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*
                          METADATA STORAGE/LOGIC
    */

    string public name;

    string public symbol;

    string private baseURI;

    uint public price;

    struct METADATA {
        string name;
        string description;
        string image;
        string external_url;
        mapping(string => string) attribute;
        string[] attribute_keys;
    }

    mapping(uint => METADATA) metadata;

    function setTokenMetadata(uint id, 
                              string memory _name,
                              string memory _description,
                              string memory _image,
                              string memory _external_url,
                              string[] memory _traits,
                              string[] memory _values) public onlyAuth {
        require(id < totalSupply(), "id out of bounds");
        require(_traits.length == _values.length, "traits/values mismatch");
        metadata[id].name = _name;
        metadata[id].description = _description;
        metadata[id].image = _image;
        metadata[id].external_url = _external_url;
        for (uint i=0; i<_traits.length; i++) {
            metadata[id].attribute[_traits[i]] = _values[i];
            metadata[id].attribute_keys.push(_traits[i]);
        }
    }

    function getTokenMetadata(uint id) public view returns (string memory _metadata_) {
        // Ensure exists
        require(id < totalSupply(), "id out of bounds");
        require(bytes(metadata[id].name).length > 0, "no metadata");
        // Start
        string memory _metadata = "{";
        _metadata = string.concat(_metadata, '"name": "');
        _metadata = string.concat(_metadata, metadata[id].name);
        _metadata = string.concat(_metadata, '", "description": "');
        _metadata = string.concat(_metadata, metadata[id].description);
        _metadata = string.concat(_metadata, '", "image": "');
        _metadata = string.concat(_metadata, metadata[id].image);
        _metadata = string.concat(_metadata, '", "external_url": "');
        _metadata = string.concat(_metadata, metadata[id].external_url);
        _metadata = string.concat(_metadata, '", "attributes": [');
        for (uint i = 0; i < metadata[id].attribute_keys.length; i++) {
            _metadata = string.concat(_metadata, '{"trait_type": "');
            _metadata = string.concat(_metadata, metadata[id].attribute_keys[i]);
            _metadata = string.concat(_metadata, '", "value": "');
            _metadata = string.concat(_metadata, metadata[id].attribute[metadata[id].attribute_keys[i]]);
            _metadata = string.concat(_metadata, '"}');
            if (i < metadata[id].attribute_keys.length - 1) {
                _metadata = string.concat(_metadata, ',');
            }
        }
        _metadata = string.concat(_metadata, ']}');
        return _metadata;
    }

    function tokenURI(uint id) public view returns (string memory URI) {
        require(id < totalSupply(), "id out of bounds");
        return string(abi.encodePacked(baseURI, id));
    }

    function setBaseURI(string memory uri) public {
        baseURI = uri;
    }

    /*
                          ERC721 STORAGE
    */

    // Array which maps token ID to address (index is tokenID)
    address[] internal _owners;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping to keep track of single tokens allowance given from addr to addr
    mapping(address => 
        mapping(uint => 
        mapping(address => bool))) 
        public allowed;

    /*
                              CONSTRUCTOR
    */

    constructor(string memory _name, string memory _symbol, uint _price) {
        name = _name;
        symbol = _symbol;
        price = _price;
        owner = msg.sender;
        is_auth[msg.sender] = true;
    }

    /*
                              ERC165 LOGIC
    */

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x780e9d63 || // ERC165 Interface ID for ERC721Enumerable
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*
                       ERC721ENUMERABLE LOGIC
    */

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
    function tokenOfOwnerByIndex(address _owner, uint256 index) public view virtual returns (uint256 tokenId) {
        if (index >= balanceOf(_owner)) revert OwnerIndexOutOfBounds();

        uint256 count;
        uint256 qty = _owners.length;
        // Cannot realistically overflow, since we are using uint256
        unchecked {
            for (tokenId; tokenId < qty; tokenId++) {
                if (_owner == ownerOf(tokenId)) {
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

    /*
                              ERC721 LOGIC
    */

    /**
     * @dev Iterates through _owners array, returns balance of address
     * It is not recommended to call this function from another smart contract
     * as it can become quite expensive -- call this function off chain instead.
     */
    function balanceOf(address _owner) public view virtual returns (uint256) {
        if (_owner == address(0)) revert BalanceQueryForZeroAddress();

        uint256 count;
        uint256 qty = _owners.length;
        // Cannot realistically overflow, since we are using uint256
        unchecked {
            for (uint256 i; i < qty; i++) {
                if (_owner == ownerOf(i)) {
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
            for (tokenId; ; tokenId++) {
                if (_owners[tokenId] != address(0)) {
                    return _owners[tokenId];
                }
            }
        }

        revert UnableDetermineTokenOwner();
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual {
        address _owner = ownerOf(tokenId);
        if (to == _owner) revert ApprovalToCurrentOwner();

        if (msg.sender != _owner && !isApprovedForAll(_owner, msg.sender)) revert ApprovalCallerNotOwnerNorApproved();

        _tokenApprovals[tokenId] = to;
        emit Approval(_owner, to, tokenId);
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
    function isApprovedForAll(address _owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[_owner][operator];
    }

    function approveOwned(address _approved, 
                     uint256 _tokenId) 
                     public payable {
        if (!(_owners[_tokenId]==msg.sender)) {
            revert("Not owned");
        }
        // Setting allowance
        allowed[msg.sender][_tokenId][_approved] = true;
        emit Approval(msg.sender, _approved, _tokenId);
    }
    
    function disapproveOwned(address _disapproved, 
                        uint256 _tokenId) 
                        public payable {
        if (!(_owners[_tokenId]==msg.sender)) {
            revert("Not owned");
        }
        // Setting allowance
        allowed[msg.sender][_tokenId][_disapproved] = false;
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
            isApprovedForAll(from, msg.sender) || 
            allowed[from][tokenId][msg.sender]);
        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();

        // delete token approvals from previous owner
        delete allowed[from][tokenId][msg.sender];
        delete _tokenApprovals[tokenId];
        _owners[tokenId] = to;

        // if token ID below transferred one isnt set, set it to previous owner
        // if tokenid is zero, skip this to prevent underflow
        if (tokenId > 0 && _owners[tokenId - 1] == address(0)) {
            _owners[tokenId - 1] = from;
        }

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safe}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        safeTransferFrom(from, to, id, '');
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
        if (to.code.length == 0) return true;

        try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) revert TransferToNonERC721ReceiverImplementer();

            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
    }

    /*
                        MINT LOGIC
    */

    function mint(uint quantity) 
                  public safe payable 
                  returns (bool success) {
        // In bounds
        if(!(quantity > 0)) revert("quantity must be > 0");
        if(!(msg.value == price)) revert("Wrong price");
        _mint(msg.sender, quantity);
        return true;
    }

    function setPrice(uint price_) public onlyAuth {
        price = price_;
    }

    /**
     * @dev check if contract confirms token transfer, if not - reverts
     * unlike the standard ERC721 implementation this is only called once per mint,
     * no matter how many tokens get minted, since it is useless to check this
     * requirement several times -- if the contract confirms one token,
     * it will confirm all additional ones too.
     * This saves us around 5k gas per additional mint
     */
    function _safeMint(address to, uint256 qty) internal virtual {
        _safeMint(to, qty, '');
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
            for (uint256 i; i < qty - 1; i++) {
                _owners.push();
                emit Transfer(address(0), to, _currentIndex + i);
            }
        }

        // set last index to receiver
        _owners.push(to);
        emit Transfer(address(0), to, _currentIndex + (qty - 1));
    }

    receive() external payable {
        if((msg.value%price)!=0) return;
        uint qty_ = msg.value/price;
        _mint(msg.sender, qty_);
    }
}