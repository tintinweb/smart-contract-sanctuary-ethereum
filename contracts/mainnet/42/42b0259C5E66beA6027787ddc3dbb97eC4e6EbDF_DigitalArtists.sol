/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

/*
[email protected]@@@@#%*;,..............*@
[email protected]@@@@@@@@#*:[email protected]@
[email protected]@@@@@@@@@@@*,........;@@@
[email protected]@@@@@@@@@@@@%,......:#@@@
[email protected]@@@@@@@@@@@@@?.....,#@@@@
[email protected]@@@@@@@@@@@@@@,...,[email protected]@@@@
[email protected]@@@@@@@@@@@@@@:...%@@@@@@
[email protected]@@@@@@@@@@@@@@,[email protected]@@@@@@
[email protected]@@@@@@@@@@@@@?..*@@@@@@@@
[email protected]@@@@@@@@@@@@%,[email protected]@@@@@@@@
[email protected]@@@@@@@@@@@*..;@@@@@@@@@@
[email protected]@@@@@@@@#*:..:@@@@@@@@@@#
[email protected]@@@#S%*;,[email protected]@@@@@@@@@#  

..........................................................................................................................................
88888888ba,....88...............88.......................88............db..............................88.................................
88......`"8b...""...............""....,d.................88...........d88b......................,d.....""...............,d................
88........`8b.........................88.................88..........d8'`8b.....................88......................88................
88.........88..88...,adPPYb,d8..88..MM88MMM..,adPPYYba,..88.........d8'..`8b......8b,dPPYba,..MM88MMM..88..,adPPYba,..MM88MMM..,adPPYba,..
88.........88..88..a8"....`Y88..88....88....."".....`Y8..88........d8YaaaaY8b.....88P'..."Y8....88.....88..I8[....""....88.....I8[....""..
88.........8P..88..8b.......88..88....88.....,adPPPPP88..88.......d8""""""""8b....88............88.....88...`"Y8ba,.....88......`"Y8ba,...
88.......a8P...88.."8a,...,d88..88....88,....88,....,88..88......d8'........`8b...88............88,....88..aa....]8I....88,....aa....]8I..
88888888Y"'....88...`"YbbdP"Y8..88...."Y888..`"8bbdP"Y8..88.....d8'..........`8b..88............"Y888..88..`"YbbdP"'...."Y888..`"YbbdP"'..
....................aa,....,88............................................................................................................
....................."Y8bbdP".............................................................................................................

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/*********************************************
 *********************************************
 *  H e l p e r   l i b r a r i e s
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
}

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     * See openzeppelin's Address.sol for details
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.
        return account.code.length > 0;
    }
}

/*********************************************
 *********************************************
 *  H e l p e r   c o n t r a c t s
 */

contract ReentrancyGuard {
    uint8 private constant _NOT_ENTERED = 1;
    uint8 private constant _ENTERED = 2;
    uint8 private _status;

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

contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Caller not owner");
        _;
    }

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Invalid address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/*********************************************
 *********************************************
 *  I n t e r f a c e s
 */

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

interface IERC2981 {
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

interface IERC721Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Enumerable {
    function totalSupply() external view returns (uint256);

    function tokenByIndex(uint256 _index) external view returns (uint256);

    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        returns (uint256);
}

interface IERC721 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

contract DigitalArtists is
    IERC165,
    IERC721,
    IERC721Metadata,
    IERC721Enumerable,
    IERC2981,
    ReentrancyGuard,
    Ownable
{
    event Mint(
        uint256 indexed collectionId_,
        address indexed to_,
        uint256 tokenId_
    );

    event Withdraw(
        address indexed initiator_,
        address indexed to_,
        uint256 amount_
    );

    event CollectionArtistAddressUpdated(
        uint256 indexed collectionId_,
        address newAddr_,
        address oldAddr_
    );

    event CollectionStateUpdated(
        uint256 indexed collectionId_,
        uint8 newState_,
        uint8 oldSate_
    );

    event CollectionAuthorizationUpdated(
        uint256 indexed collectionId_,
        address indexed addr_,
        bool state_
    );

    modifier onlyAuthorized(uint256 collectionId_) {
        require(
            _isCollectionAuthorized(collectionId_, _msgSender()),
            "Unauthorized"
        );
        _;
    }

    struct Artist {
        string name;
        string info;
        uint32 collectionsCount;
    }

    struct Collection {
        // Collection name
        bytes32 name;
        // Collection base URI
        string baseUri;
        // Artists address
        address artistAddr;
        // Royalties address - artistAddr is used if this one is not set
        address royaltyAddr;
        // Current token id
        uint256 tokenId;
        // Starting token number
        uint256 tokenIdFrom;
        // Public mint(state 2) price
        uint256 mintPrice;
        // Premint (state 1) price
        uint256 premintPrice;
        // Balance from the minting process
        uint256 balance;
        // Withdrawn value [0] is artist and [1] is platform
        uint256[2] withdrawn;
        // Collection max supply
        uint32 maxSupply;
        // Maximum number of NFTs that could be minted on the premint
        uint32 premintMaxSupply;
        // Royalty basis
        uint16 royaltyBasis;
        // Maximum number of NFTs that address could mint on the public sale
        uint16 mintCap;
        // Maximum number of NFTs that address could mint on the premint
        uint16 premintCap;
        // Maximum number of addresses that premint list could hold
        uint16 premintListCap;
        // Current number of addresses on the premint list
        uint16 premintListCount;
        // Withdraw percentages [0] is artist and [1] is platform
        uint16[2] percentage;
        // Flag indicating whether collection base URI is locked
        uint8 baseUriLocked;
        // campaign state - 0 (not active), 1 (premint), 2 (public mint)
        uint8 state;
        // Mapping for authorizing addresses to manage this collection
        mapping(address => bool) authorized;
        // Mapping from address to boolean flag indicating if this address is on the premint list
        mapping(address => bool) premintList;
        // Mapping from address to number representing minted NFTs on the public sale
        mapping(address => uint32) minted;
        // Mapping from address to number representing minted NFTs on the premint
        mapping(address => uint32) preminted;
    }

    /*********************************************
     *********************************************
     *  P r i v a t e
     *      m e m b e r s
     *
     */

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Contract name
    string private _name;

    // Contract token symbol
    string private _symbol;

    // Default base uri. It will be used if collection base uri is not set
    string private _baseUri;

    // Default artist percentage when organizing mints
    uint16 private _percentArtist;

    // Default platform percentage when organizing mints
    uint16 private _percentPlatform;

    // Flag indicating whether anyone could use createCollection or only whitelisted addresses and owner
    uint8 private _isCreateCollectionPublic;

    // Reference to the last collection ID
    uint256 private _lastCollectionId;

    // Mapping from collection ID to Collection
    mapping(uint256 => Collection) private _collections;

    // Mapping from artist address to Artist
    mapping(address => Artist) private _artists;

    // Mapping from token id to collection ID
    mapping(uint256 => uint256) private _tokenIdToCollectionId;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    // Mapping from token id to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Mapping for explicit token URIs
    mapping(uint256 => string) private _tokenUri;

    // Mapping from token id to owner address
    mapping(uint256 => address) private _owners;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to number of owned token
    mapping(address => uint256) private _balances;

    // Mapping from artist address to boolean flag indicating whether this address is trusted
    mapping(address => bool) private _knownArtists;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    constructor() ReentrancyGuard() Ownable() {
        _symbol = "DA";
        _name = "Digital Artists";
    }

    /*********************************************
     *********************************************
     *  P u b l i c
     *      m e t h o d s
     *
     */

    /**
     * @notice Returns last collection ID
     */
    function lastCollectionId() public view returns (uint256) {
        return _lastCollectionId;
    }

    /**
     * @notice Returns collection ID from given token ID
     */
    function tokenIdToCollectionId(uint256 tokenId_)
        public
        view
        returns (uint256)
    {
        return _tokenIdToCollectionId[tokenId_];
    }

    /**
     * @notice Returns a token ID owned by `owner` at a given `index` of its token list.
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * @param owner_ owner address
     * @param idx_ index of token
     */
    function tokenOfOwnerByIndex(address owner_, uint256 idx_)
        public
        view
        returns (uint256)
    {
        require(idx_ < balanceOf(owner_), "Index out of bounds");
        return _ownedTokens[owner_][idx_];
    }

    /**
     * @notice Returns the total amount of tokens stored by the contract.
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @notice Returns the total amount of tokens in collection.
     * @param collectionId_ checked collection ID.
     */
    function totalSupplyByCollectionId(uint256 collectionId_)
        public
        view
        returns (uint256)
    {
        unchecked {
            return
                _collections[collectionId_].tokenId -
                _collections[collectionId_].tokenIdFrom;
        }
    }

    /**
     * @notice Returns a token ID at a given `index` of all the tokens stored by the contract.
     * @dev See {IERC721Enumerable-tokenByIndex}.
     * @param idx_ desired index
     */
    function tokenByIndex(uint256 idx_) public view returns (uint256) {
        require(idx_ < totalSupply(), "Index out of bounds");
        return _allTokens[idx_];
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Returns address and royatly amount from given token id and price.
     * Different collections could have different royatlies.
     * @param tokenId_ token id
     * @param price_ price against royatly is calculated
     */
    function royaltyInfo(uint256 tokenId_, uint256 price_)
        public
        view
        returns (address, uint256)
    {
        require(_exists(tokenId_), "Nonexistent token");
        uint256 collectionId = _tokenIdToCollectionId[tokenId_];

        unchecked {
            return (
                _collections[collectionId].royaltyAddr == address(0)
                    ? _collections[collectionId].artistAddr
                    : _collections[collectionId].royaltyAddr,
                (price_ * _collections[collectionId].royaltyBasis) / 10000
            );
        }
    }

    /**
     * @notice Returns token uri from given token id.
     * @param tokenId_ token id
     */
    function tokenURI(uint256 tokenId_) public view returns (string memory) {
        require(_exists(tokenId_), "Nonexistent token");

        if (bytes(_tokenUri[tokenId_]).length > 0) {
            // Explicit token uri
            return _tokenUri[tokenId_];
        }

        string memory baseUri = bytes(
            _collections[_tokenIdToCollectionId[tokenId_]].baseUri
        ).length > 0
            ? _collections[_tokenIdToCollectionId[tokenId_]].baseUri
            : _baseUri;

        return string(abi.encodePacked(baseUri, Strings.toString(tokenId_)));
    }

    /**
     * @notice Allows collection's artist or contract owner to explicitly set URI for token.
     * @param tokenId_ updated token id
     * @param uri_ explicit token uri
     */
    function updateTokenUri(uint256 tokenId_, string memory uri_) public {
        require(
            _isCollectionAuthorized(
                _tokenIdToCollectionId[tokenId_],
                _msgSender()
            ),
            "Unauthorized"
        );
        _tokenUri[tokenId_] = uri_;
    }

    /**
     * @notice Returns the count of the owned tokens by address.
     * @param owner_ checked addess
     */
    function balanceOf(address owner_) public view returns (uint256) {
        return _balances[owner_];
    }

    /**
     * @notice Returns the address of token id owner or zero address if non-existing token id is specified.
     * @param tokenId_ checked token id
     */
    function ownerOf(uint256 tokenId_) public view returns (address) {
        return _owners[tokenId_];
    }

    /**
     * @notice Returns boolean value indicating if the checked interface is supported.
     * @param interfaceId_ checked interface id
     */
    function supportsInterface(bytes4 interfaceId_) public pure returns (bool) {
        return
            interfaceId_ == type(IERC165).interfaceId ||
            interfaceId_ == type(IERC2981).interfaceId ||
            interfaceId_ == type(IERC721).interfaceId ||
            interfaceId_ == type(IERC721Metadata).interfaceId ||
            interfaceId_ == type(IERC721Enumerable).interfaceId;
    }

    /**
     * @notice Allows contract owner to update default percentages in case of public mint is organized.
     * @param percentArtist_ artist percentage
     * @param percentPlatform_ platform percentage
     */
    function updateDefaultPercentages(
        uint16 percentArtist_,
        uint16 percentPlatform_
    ) public onlyOwner {
        unchecked {
            require(
                percentArtist_ + percentPlatform_ == 10000,
                "Invalid percentage"
            );
        }

        _percentArtist = percentArtist_;
        _percentPlatform = percentPlatform_;
    }

    /**
     * @notice Allows contract owner to specify explicit split percentage for collection if public mint is organized.
     * @param collectionId_ collection ID
     * @param percentArtist_ artist percentage
     * @param percentPlatform_ platform percentage
     */
    function updateCollectionPercentages(
        uint256 collectionId_,
        uint16 percentArtist_,
        uint16 percentPlatform_
    ) public onlyOwner {
        if (percentArtist_ == 1) {
            // Artist percetage is explicitly set to 0, 1 means 0 percentage, see withdraw function
            _collections[collectionId_].percentage[0] = 1;
            _collections[collectionId_].percentage[1] = 10000;
        } else if (percentPlatform_ == 1) {
            // Platform percetage is explicitly set to 0, 1 means 0 percentage, see withdraw function
            _collections[collectionId_].percentage[0] = 10000;
            _collections[collectionId_].percentage[1] = 1;
        } else {
            unchecked {
                require(
                    percentArtist_ + percentPlatform_ == 10000,
                    "Invalid percentage"
                );
            }
            _collections[collectionId_].percentage[0] = percentArtist_;
            _collections[collectionId_].percentage[1] = percentPlatform_;
        }
    }

    /**
     * @notice Returns default split percentages - artists and platform respectively.
     */
    function defaultPercentages() public view returns (uint16, uint16) {
        return (_percentArtist, _percentPlatform);
    }

    /**
     * @notice Allows contract owner to specify default base URI.
     * @param uri_ new base URI
     */
    function setBaseUri(string memory uri_) public onlyOwner {
        _baseUri = uri_;
    }

    /**
     * @notice Returns the default base URI
     */
    function defaultBaseUri() public view returns (string memory) {
        return _baseUri;
    }

    /**
     * @notice Allows contract owner to change createCollection access level.
     * @param level_ access level - public or known artists only
     */
    function updateCreateCollectionAccess(uint8 level_) public onlyOwner {
        // Everything greater than 0 will allow public access to createCollection
        // otherwise onlyOwner and _knownArtists have access
        _isCreateCollectionPublic = level_;
    }

    /**
     * @notice Returns a boolean flag indicating if createColletion function is publicly accessible.
     */
    function isCreateCollectionPublic() public view returns (bool) {
        return _isCreateCollectionPublic > 0;
    }

    /**
     * @notice Allows contract owner to add addresses to the known artists white list.
     * @param addresses_ array of addresses
     */
    function addKnownArtists(address[] memory addresses_) public onlyOwner {
        for (uint256 i = 0; i < addresses_.length; i++) {
            _knownArtists[addresses_[i]] = true;
        }
    }

    /**
     * @notice Allows contract owner to remove addresses from the known artists white list.
     * @param addresses_ array of addresses
     */
    function removeKnownArtists(address[] memory addresses_) public onlyOwner {
        for (uint256 i = 0; i < addresses_.length; i++) {
            _knownArtists[addresses_[i]] = false;
        }
    }

    /**
     * @notice Returns boolean flag indicating whether address is a known artist.
     * @param addr_ checked address
     */
    function isKnownArtist(address addr_) public view returns (bool) {
        return _knownArtists[addr_];
    }

    /**
     * @notice Allows contract owner to set base URI for specific collection.
     * @param collectionId_ collection ID
     * @param baseUri_ base URI
     */
    function setCollectionBaseUri(uint256 collectionId_, string memory baseUri_)
        public
        onlyOwner
    {
        require(
            _collections[collectionId_].baseUriLocked == 0,
            "baseURI locked"
        );
        _collections[collectionId_].baseUri = baseUri_;
    }

    /**
     * @notice Allows contract owner to lock base URI from being changed. Once locked it cannot be unlocked.
     * @param collectionId_ collection ID
     */
    function lockCollectionBaseUri(uint256 collectionId_) public onlyOwner {
        _collections[collectionId_].baseUriLocked = 1;
    }

    /**
     * @notice Returns collection's base URI, if there is any.
     * @param collectionId_ collection ID
     */
    function collectionBaseUri(uint256 collectionId_)
        public
        view
        virtual
        returns (string memory)
    {
        return _collections[collectionId_].baseUri;
    }

    /**
     * @notice Returns boolean flag indicating whether collection's base URI is locked
     * @param collectionId_ collection ID
     */
    function isCollectionBaseUriLocked(uint256 collectionId_)
        public
        view
        virtual
        returns (bool)
    {
        return _collections[collectionId_].baseUriLocked > 0;
    }

    /**
     * @notice Allows collection authorized or contract owner to update max supply and premint max supply
     * @param collectionId_ collection ID
     * @param shouldUpdateMaxSupply_ flag indicating whether max supply value should be updated
     * @param maxSupply_ new max supply
     * @param shouldUpdatePremintMaxSupply_ flag indicating whether premint max supply value should be updated
     * @param premintMaxSupply_ new premint max supply
     */
    function updateCollectionSupplies(
        uint256 collectionId_,
        uint8 shouldUpdateMaxSupply_,
        uint32 maxSupply_,
        uint8 shouldUpdatePremintMaxSupply_,
        uint32 premintMaxSupply_
    ) public onlyAuthorized(collectionId_) {
        if (shouldUpdateMaxSupply_ != 0) {
            unchecked {
                require(
                    totalSupplyByCollectionId(collectionId_) <= maxSupply_ &&
                    _collections[collectionId_].maxSupply + 10000 > maxSupply_,
                    "Invalid max supply"
                );
            }

            _collections[collectionId_].maxSupply = maxSupply_;
        }

        if (shouldUpdatePremintMaxSupply_ != 0) {
            unchecked {
                require(
                    totalSupplyByCollectionId(collectionId_) <= premintMaxSupply_ &&
                    _collections[collectionId_].maxSupply + 10000 > premintMaxSupply_,
                    "Invalid premint max supply"
                );
            }
            _collections[collectionId_].premintMaxSupply = premintMaxSupply_;
        }
    }

    /**
     * @notice Returns collection supplies - max supply, premint max supply and current total supply
     * @param collectionId_ collection ID
     */
    function collectionSupplies(uint256 collectionId_)
        public
        view
        returns (
            uint32,
            uint32,
            uint256
        )
    {
        return (
            _collections[collectionId_].maxSupply,
            _collections[collectionId_].premintMaxSupply,
            totalSupplyByCollectionId(collectionId_)
        );
    }

    /**
     * @notice Allows collection authorized or contract owner to change state
     * @param collectionId_ collection ID
     * @param state_ state - 1(premint), 2(public mint), everything else is considered not active
     */
    function updateCollectionState(uint256 collectionId_, uint8 state_)
        public
        onlyAuthorized(collectionId_)
    {
        uint8 oldState = _collections[collectionId_].state;
        _collections[collectionId_].state = state_;
        emit CollectionStateUpdated(collectionId_, state_, oldState);
    }

    /**
     * @notice Returns collection state - 1(premint), 2(public mint), everything else is considered not active
     * @param collectionId_ collection ID
     */
    function collectionState(uint256 collectionId_)
        public
        view
        returns (uint8)
    {
        return _collections[collectionId_].state;
    }

    /**
     * @notice Returns how many NFTs give address minted on premint and public mint for specific collection
     * @param collectionId_ collection ID
     * @param addr_ checked address
     */
    function collectionAddressMintedStats(uint256 collectionId_, address addr_)
        public
        view
        returns (uint32, uint32)
    {
        return (
            _collections[collectionId_].minted[addr_],
            _collections[collectionId_].preminted[addr_]
        );
    }

    /**
     * @notice Returns generated balance from mint campaign of collection
     * @param collectionId_ collection ID
     */
    function collectionBalance(uint256 collectionId_)
        public
        view
        returns (uint256)
    {
        return _collections[collectionId_].balance;
    }

    /**
     * @notice Returns boolean flag indicating if address is collection authorized
     * @param collectionId_ collection ID
     * @param addr_ checked address
     */
    function isCollectionAuthorized(uint256 collectionId_, address addr_)
        public
        view
        returns (bool)
    {
        return _collections[collectionId_].authorized[addr_];
    }

    /**
     * @notice Returns collection bounds - starting token id, last token id, current token id
     * @param collectionId_ collection ID
     */
    function collectionBounds(uint256 collectionId_)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        unchecked {
            return (
                _collections[collectionId_].tokenIdFrom + 1,
                _collections[collectionId_].tokenIdFrom + _collections[collectionId_].maxSupply,
                _collections[collectionId_].tokenId
            );
        }
    }

    /**
     * @notice Returns info about collection - collection name, artist name, base URI, artist address, max supply
     * @param collectionId_ collection ID
     */
    function collectionInfo(uint256 collectionId_)
        public
        view
        returns (
            string memory,
            string memory,
            string memory,
            address,
            uint32
        )
    {
        return (
            string(abi.encodePacked(_collections[collectionId_].name)),
            string(abi.encodePacked(_artists[_collections[collectionId_].artistAddr].name)),
            string(abi.encodePacked(_collections[collectionId_].baseUri)),
            _collections[collectionId_].artistAddr,
            _collections[collectionId_].maxSupply
        );
    }

    /**
     * @notice Allows collection authorized or contract owner to retrive split payments information
     * @param collectionId_ collection ID
     */
    function collectionPaymentsInfo(uint256 collectionId_)
        public
        view
        onlyAuthorized(collectionId_)
        returns (
            uint256,
            uint256,
            uint16,
            uint16
        )
    {
        return (
            _collections[collectionId_].withdrawn[0],
            _collections[collectionId_].withdrawn[1],
            _collections[collectionId_].percentage[0],
            _collections[collectionId_].percentage[1]
        );
    }

    /**
     * @notice Allows contract owner or known artists to create new collectins on this contract
     * @param artistAddr_ collection artists address (required)
     * @param maxSupply_ collection max supply (required)
     * @param premintMaxSupply_ collection premint max supply (optional)
     */
    function createCollection(
        address artistAddr_,
        uint32 maxSupply_,
        uint32 premintMaxSupply_
    ) public {
        _nonZeroAddress(artistAddr_);
        require(maxSupply_ > 0 && maxSupply_ <= 5000000, "Invalid supply");

        if (_isCreateCollectionPublic == 0) {
            // Leave an option to publicly allow this operation
            require(
                _msgSender() == owner() || _knownArtists[_msgSender()],
                "Unauthorized"
            );
        }

        Collection storage c = _collections[++_lastCollectionId];
        c.artistAddr = artistAddr_;
        c.maxSupply = maxSupply_;

        if (premintMaxSupply_ > 0) {
            _collections[_lastCollectionId].premintMaxSupply = premintMaxSupply_;
        }

        uint256 prevIdx;
        unchecked {
            prevIdx = _lastCollectionId - 1;
            _artists[artistAddr_].collectionsCount++;
        }

        // Every new collection's tokenId will start from the previous end + 10000(gap)
        c.tokenId = _collections[prevIdx].tokenIdFrom + _collections[prevIdx].maxSupply + 10000;
        c.tokenIdFrom = c.tokenId;
    }

    /**
     * @notice Returns boolean flag indicating whether collection exists
     * @param collectionId_ collection ID
     */
    function collectionExists(uint256 collectionId_)
        public
        view
        returns (bool)
    {
        return _collections[collectionId_].artistAddr != address(0);
    }

    /**
     * @notice Allows collection authorized or contract owner to toggle address collection authorization state
     * @param collectionId_ collection ID
     * @param addr_ address to toggle authorization state for
     * @param state_ authorization state - true or false
     */
    function toggleCollectionAuthorization(
        uint256 collectionId_,
        address addr_,
        bool state_
    ) public onlyAuthorized(collectionId_) {
        _nonZeroAddress(addr_);
        _collections[collectionId_].authorized[addr_] = state_;
        emit CollectionAuthorizationUpdated(collectionId_, addr_, state_);
    }

    /**
     * @notice Allows contract owner to set royalty for specific collection
     * @param collectionId_ collection ID
     * @param royaltyAddr_ new royalty address
     * @param royaltyBasis_ new royalty basis
     */
    function updateCollectionRoyalty(
        uint256 collectionId_,
        address royaltyAddr_,
        uint16 royaltyBasis_
    ) public onlyOwner {
        require(royaltyBasis_ <= 5000, "Maximum 50% royalty");
        _collections[collectionId_].royaltyAddr = royaltyAddr_;
        _collections[collectionId_].royaltyBasis = royaltyBasis_;
    }

    /**
     * @notice Returns royalty information about collection
     * @param collectionId_ collection ID
     */
    function collectionRoyaltyInfo(uint256 collectionId_)
        public
        view
        returns (address, uint16)
    {
        return (
            _collections[collectionId_].royaltyAddr == address(0)
                ? _collections[collectionId_].artistAddr
                : _collections[collectionId_].royaltyAddr,
            _collections[collectionId_].royaltyBasis
        );
    }

    /**
     * @notice Allows artist or contract owner to update on-chain info about artist by address
     * @param addr_ artist address
     * @param name_ new artist name
     * @param info_ new artist info - free text
     */
    function updateArtist(
        address addr_,
        string memory name_,
        string memory info_
    ) public {
        require(
            _msgSender() == owner() || _msgSender() == addr_,
            "Unauthorized"
        );

        if (bytes(name_).length > 0) {
            _artists[addr_].name = name_;
        }

        if (bytes(info_).length > 0) {
            _artists[addr_].info = info_;
        }
    }

    /**
     * @notice Allows contract owner to update on-chain collection name
     * @param collectionId_ collection ID
     * @param collectionName_ collection name
     */
    function updateCollectionName(
        uint256 collectionId_,
        string memory collectionName_
    ) public onlyOwner {
        _collections[collectionId_].name = bytes32(bytes(collectionName_));
    }

    /**
     * @notice Allows contract owner to update collection's artist address
     * @param collectionId_ collection ID
     * @param artistAddr_ new artist address
     */
    function updateCollectionArtistAddr(
        uint256 collectionId_,
        address artistAddr_
    ) public onlyOwner {
        _nonZeroAddress(artistAddr_);
        address oldAddress = _collections[collectionId_].artistAddr;
        _collections[collectionId_].artistAddr = artistAddr_;
        emit CollectionArtistAddressUpdated(
            collectionId_,
            artistAddr_,
            oldAddress
        );
    }

    /**
     * @notice Returns artist address for collection
     * @param collectionId_ collection ID
     */
    function collectionArtistAddr(uint256 collectionId_)
        public
        view
        returns (address)
    {
        return _collections[collectionId_].artistAddr;
    }

    /**
     * @notice Allows collection authorized or contract owner to add addresses to premint list
     * @param collectionId_ collection ID
     * @param addresses_ array of addresses
     */
    function addToCollectionPremintList(
        uint256 collectionId_,
        address[] memory addresses_
    ) public onlyAuthorized(collectionId_) {
        Collection storage c = _collections[collectionId_];

        require(
            c.premintListCount + addresses_.length <= c.premintListCap,
            "Presale list overflow"
        );

        for (uint256 i = 0; i < addresses_.length; i++) {
            if (!c.premintList[addresses_[i]]) {
                c.premintList[addresses_[i]] = true;
                unchecked {
                    c.premintListCount++;
                }
            }
        }
    }

    /**
     * @notice Allows collection authorized or contract owner to remove addresses from premint list
     * @param collectionId_ collection ID
     * @param addresses_ array of addresses
     */
    function removeFromCollectionPremintList(
        uint256 collectionId_,
        address[] memory addresses_
    ) public onlyAuthorized(collectionId_) {
        Collection storage c = _collections[collectionId_];

        for (uint256 i = 0; i < addresses_.length; i++) {
            if (c.premintList[addresses_[i]]) {
                c.premintList[addresses_[i]] = false;
                unchecked {
                    c.premintListCount--;
                }
            }
        }
    }

    /**
     * @notice Returns boolean flag indicating if address is on the collection's premint list
     * @param collectionId_ collection ID
     * @param addr_ checked address
     */
    function isOnCollectionPremintList(uint256 collectionId_, address addr_)
        public
        view
        returns (bool)
    {
        return _collections[collectionId_].premintList[addr_];
    }

    /**
     * @notice Returns collection's premint list capacity and current count
     * @param collectionId_ collection ID
     */
    function collectionPremintListDetails(uint256 collectionId_)
        public
        view
        returns (uint16, uint16)
    {
        return (
            _collections[collectionId_].premintListCap,
            _collections[collectionId_].premintListCount
        );
    }

    /**
     * @notice Allows collection authorized or contract owner to update premint and mint prices for collection
     * @param collectionId_ collection ID
     * @param shouldUpdateMintPrice_ flag indicating whether mint price should be updated
     * @param mintPrice_ mint price to be set if shouldUpdateMintPrice_ > 0
     * @param shouldUpdatepremintPrice_ flag indicating whether premint price should be updated
     * @param premintPrice_ premint price to be set if shouldUpdatepremintPrice_ > 0
     */
    function updateCollectionMintPrices(
        uint256 collectionId_,
        uint8 shouldUpdateMintPrice_,
        uint256 mintPrice_,
        uint8 shouldUpdatepremintPrice_,
        uint256 premintPrice_
    ) public onlyAuthorized(collectionId_) {
        // using parameter which determines if value should be updated
        // proceed with update if shouldUpdate..._ paramters != 0

        if (shouldUpdateMintPrice_ != 0) {
            _collections[collectionId_].mintPrice = mintPrice_;
        }

        if (shouldUpdatepremintPrice_ != 0) {
            _collections[collectionId_].premintPrice = premintPrice_;
        }
    }

    /**
     * @notice Returns collection's mint and premint prices
     * @param collectionId_ collection ID
     */
    function collectionMintPrices(uint256 collectionId_)
        public
        view
        returns (uint256, uint256)
    {
        return (
            _collections[collectionId_].mintPrice,
            _collections[collectionId_].premintPrice
        );
    }

    /**
     * @notice Allows collection authorized or contract owner to update collection capacities - mint, premint, premint list
     * @param collectionId_ collection ID
     * @param shouldUpdateMintCap_ flag if mint capacity is updated
     * @param mintCap_ mint capacity to set
     * @param shouldUpdatePremintCap_ flag if premint capacity is updated
     * @param premintCap_ premint capacity to set
     * @param shouldUpdatePremintListCap_ flag if premint list capacity is updated
     * @param premintListCap_ premint list capacity to set
     */
    function updateCollectionCaps(
        uint256 collectionId_,
        uint8 shouldUpdateMintCap_,
        uint16 mintCap_,
        uint8 shouldUpdatePremintCap_,
        uint16 premintCap_,
        uint8 shouldUpdatePremintListCap_,
        uint16 premintListCap_
    ) public onlyAuthorized(collectionId_) {
        // using parameter which determines if value should be updated
        // proceed with update if shouldUpdate..._ paramters != 0

        if (shouldUpdateMintCap_ != 0) {
            _collections[collectionId_].mintCap = mintCap_;
        }

        if (shouldUpdatePremintCap_ != 0) {
            _collections[collectionId_].premintCap = premintCap_;
        }

        if (shouldUpdatePremintListCap_ != 0) {
            _collections[collectionId_].premintListCap = premintListCap_;
        }
    }

    /**
     * @notice Returns collection's mint and premint capacities
     * @param collectionId_ collection ID
     */
    function collectionMintCaps(uint256 collectionId_)
        public
        view
        returns (uint16, uint16)
    {
        return (
            _collections[collectionId_].mintCap,
            _collections[collectionId_].premintCap
        );
    }

    /**
     * @notice Mint function - will mint to message sender
     * @param collectionId_ collection ID
     * @param amount_ minted NFTs count
     */
    function mint(uint256 collectionId_, uint16 amount_) public payable {
        mintTo(collectionId_, amount_, _msgSender());
    }

    /**
     * @notice Mint function - will mint to receiver_
     * @param collectionId_ collection ID
     * @param amount_ minted NFTs count
     * @param receiver_ receiver of the minted NFTs
     */
    function mintTo(
        uint256 collectionId_,
        uint16 amount_,
        address receiver_
    ) public payable nonReentrant {
        _nonZeroAddress(receiver_);
        require(collectionExists(collectionId_), "Nonexistent collection");

        Collection storage c = _collections[collectionId_];

        require(
            totalSupplyByCollectionId(collectionId_) < c.maxSupply,
            "Mint completed"
        );
        require(amount_ > 0, "Invalid mint amount");

        if (c.state == 1) {
            require(c.premintList[receiver_], "Not on whitelist");

            uint32 minted = c.preminted[receiver_];
            unchecked {
                c.preminted[receiver_] += amount_;
            }

            _mint(
                collectionId_,
                c.premintPrice,
                receiver_,
                amount_,
                c.premintCap,
                c.premintMaxSupply,
                minted
            );
        } else if (c.state == 2) {
            uint32 minted = c.minted[receiver_];
            unchecked {
                c.minted[receiver_] += amount_;
            }
            _mint(
                collectionId_,
                c.mintPrice,
                receiver_,
                amount_,
                c.mintCap,
                c.maxSupply,
                minted
            );
        } else {
            revert("Mint not active");
        }
    }

    /**
     * @notice Mint function - allows collection authorized or contract owner to mint
     * @param collectionId_ collection ID
     * @param amount_ minted NFTs count
     * @param receiver_ receiver of the minted NFTs
     */
    function mintInternal(
        uint256 collectionId_,
        uint16 amount_,
        address receiver_
    ) public onlyAuthorized(collectionId_) nonReentrant {
        _nonZeroAddress(receiver_);

        Collection storage c = _collections[collectionId_];

        require(
            amount_ + totalSupplyByCollectionId(collectionId_) <= c.maxSupply,
            "Supply overflow"
        );

        for (uint16 i = 0; i < amount_; i++) {
            unchecked {
                c.tokenId += 1;
            }

            require(!_exists(c.tokenId), "Token already minted");

            _beforeTokenTransfer(address(0), receiver_, c.tokenId);

            _tokenIdToCollectionId[c.tokenId] = collectionId_;
            unchecked {
                _balances[receiver_] += 1;
            }
            _owners[c.tokenId] = receiver_;

            emit Mint(collectionId_, receiver_, c.tokenId);
        }
    }

    /**
     * @notice Transfer token from address to another
     * @param from_ current owner
     * @param to_ new owner address
     * @param tokenId_ desired token ID
     */
    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId_),
            "Not owner nor approved"
        );

        _transfer(from_, to_, tokenId_);
    }

    /**
     * @notice Safe transfer token from address to another. It is going to verify transfer using _checkOnERC721Received
     * @param from_ current owner
     * @param to_ new owner address
     * @param tokenId_ desired token ID
     */
    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    /**
     * @notice Safe transfer token from address to another. It is going to verify transfer using _checkOnERC721Received
     * @param from_ current owner
     * @param to_ new owner address
     * @param tokenId_ desired token ID
     * @param data_ passed data in case receiver is contract
     */
    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId_),
            "Not owner nor approved"
        );
        _transfer(from_, to_, tokenId_);
        require(
            _checkOnERC721Received(from_, to_, tokenId_, data_),
            "Non ERC721Receiver implementer"
        );
    }

    /**
     * @notice Allows collection authorized or contract owner to withdraw funds generated from mint campaign
     * @param collectionId_ collection ID
     * @param addr_ withdraw address
     */
    function withdraw(uint256 collectionId_, address addr_)
        public
        onlyAuthorized(collectionId_)
        nonReentrant
    {
        _nonZeroAddress(addr_);
        require(
            _collections[collectionId_].balance != 0,
            "Insufficient balance"
        );

        Collection storage c = _collections[collectionId_];

        // index 0 is artist and index 1 is platform
        uint8 idx = _msgSender() == owner() ? 1 : 0;
        uint256 allTimeBalance = c.balance + c.withdrawn[0] + c.withdrawn[1];
        uint16 percentage;

        if (_collections[collectionId_].percentage[idx] == 1) {
            // In this case the given side doesn't have a cut - it might be the platform or artist as well
            percentage = 0;
        } else if (
            _collections[collectionId_].percentage[idx] > 1 &&
            _collections[collectionId_].percentage[idx] <= 10000
        ) {
            // This is a valid percentage from the collection struct
            percentage = _collections[collectionId_].percentage[idx];
        } else {
            // Default percentage
            percentage = idx == 0 ? _percentArtist : _percentPlatform;
        }

        uint256 payment = (allTimeBalance * percentage) /
            10000 -
            c.withdrawn[idx];

        require(payment != 0, "Nothing to withdraw");

        c.withdrawn[idx] += payment;
        c.balance -= payment;

        (bool success, ) = payable(addr_).call{value: payment}("");
        require(success, "Withdraw failed");

        emit Withdraw(_msgSender(), addr_, payment);
    }

    /**
     * @notice Allows token owner or approved operator to approve address to token
     * @param to_ approved address
     * @param tokenId_ token ID
     */
    function approve(address to_, uint256 tokenId_) public {
        address tokenOwner = ownerOf(tokenId_);
        require(to_ != tokenOwner, "Approval to current owner");
        require(
            _msgSender() == tokenOwner ||
                isApprovedForAll(tokenOwner, _msgSender()),
            "Not owner nor approved"
        );
        _approve(to_, tokenId_);
    }

    /**
     * @notice Returns boolean flag indicating whether address is approved operator for owner tokens
     * @param checkedOwner_ address of owner
     * @param operator_ checked address
     */
    function isApprovedForAll(address checkedOwner_, address operator_)
        public
        view
        returns (bool)
    {
        return _operatorApprovals[checkedOwner_][operator_];
    }

    /**
     * @notice Allows token owner to set/reset operator for his tokens
     * @param operator_ address of owner
     * @param approved_ checked address
     */
    function setApprovalForAll(address operator_, bool approved_) public {
        require(operator_ != _msgSender(), "Approve to caller");
        _operatorApprovals[_msgSender()][operator_] = approved_;
        emit ApprovalForAll(_msgSender(), operator_, approved_);
    }

    /**
     * @notice Returns approved address of token
     * @param tokenId_ token ID
     */
    function getApproved(uint256 tokenId_) public view returns (address) {
        return _tokenApprovals[tokenId_];
    }

    /**
     * @notice Allows token owner or approved to burn token
     * @param tokenId_ token ID
     */
    function burn(uint256 tokenId_) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId_),
            "Not owner nor approved"
        );

        address owner = ownerOf(tokenId_);

        _beforeTokenTransfer(owner, address(0), tokenId_);
        _approve(address(0), tokenId_);

        _balances[owner] -= 1;
        delete _owners[tokenId_];

        emit Transfer(owner, address(0), tokenId_);
    }

    /*********************************************
     *********************************************
     *  P r i v a t e
     *      m e t h o d s
     *
     */

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) private {
        if (from_ == address(0)) {
            _allTokensIndex[tokenId_] = _allTokens.length;
            _allTokens.push(tokenId_);
        } else if (from_ != to_) {
            _removeTokenFromOwnerEnumeration(from_, tokenId_);
        }

        if (to_ == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId_);
        } else if (to_ != from_) {
            uint256 length = balanceOf(to_);
            _ownedTokens[to_][length] = tokenId_;
            _ownedTokensIndex[tokenId_] = length;
        }
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from_ address representing the previous owner of the given token ID
     * @param tokenId_ uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from_, uint256 tokenId_)
        private
    {
        uint256 lastTokenIndex = balanceOf(from_) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId_];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from_][lastTokenIndex];
            _ownedTokens[from_][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId_];
        delete _ownedTokens[from_][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId_ uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId_) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId_];
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;

        delete _allTokensIndex[tokenId_];
        _allTokens.pop();
    }

    function _exists(uint256 tokenId_) private view returns (bool) {
        return _owners[tokenId_] != address(0);
    }

    function _isApprovedOrOwner(address spender_, uint256 tokenId_)
        private
        view
        returns (bool)
    {
        require(_exists(tokenId_), "Operator query for nonexistent token");
        address tokenOwner = ownerOf(tokenId_);
        return (tokenOwner == spender_ ||
            getApproved(tokenId_) == spender_ ||
            isApprovedForAll(tokenOwner, spender_));
    }

    function _transfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) private {
        _nonZeroAddress(to_);
        require(ownerOf(tokenId_) == from_, "Not owner");

        _beforeTokenTransfer(from_, to_, tokenId_);
        _approve(address(0), tokenId_);

        _balances[from_] -= 1;
        _balances[to_] += 1;
        _owners[tokenId_] = to_;

        emit Transfer(from_, to_, tokenId_);
    }

    function _approve(address to_, uint256 tokenId_) private {
        _tokenApprovals[tokenId_] = to_;
        emit Approval(ownerOf(tokenId_), to_, tokenId_);
    }

    function _mint(
        uint256 collectionId_,
        uint256 price_,
        address receiver_,
        uint16 amount_,
        uint16 cap_,
        uint32 maxSupply_,
        uint32 minted_
    ) private {
        if (cap_ > 0) {
            require(amount_ + minted_ <= cap_, "Invalid mint amount");
        }

        require(
            amount_ + totalSupplyByCollectionId(collectionId_) <= maxSupply_,
            "Supply overflow"
        );

        unchecked {
            require(msg.value == amount_ * price_, "Invalid ETH amount");
            _collections[collectionId_].balance += amount_ * price_;
        }

        for (uint256 i = 0; i < amount_; i++) {
            unchecked {
                _collections[collectionId_].tokenId += 1;
            }

            require(
                !_exists(_collections[collectionId_].tokenId),
                "Token already minted"
            );

            _beforeTokenTransfer(
                address(0),
                receiver_,
                _collections[collectionId_].tokenId
            );

            _tokenIdToCollectionId[_collections[collectionId_].tokenId] = collectionId_;
            unchecked {
                _balances[receiver_] += 1;
            }
            _owners[_collections[collectionId_].tokenId] = receiver_;

            emit Mint(
                collectionId_,
                receiver_,
                _collections[collectionId_].tokenId
            );
        }
    }

    function _checkOnERC721Received(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) private returns (bool) {
        if (Address.isContract(to_)) {
            try
                IERC721Receiver(to_).onERC721Received(
                    _msgSender(),
                    from_,
                    tokenId_,
                    data_
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("Non ERC721Receiver implementer");
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

    function _nonZeroAddress(address addr_) private pure {
        require(addr_ != address(0), "Invalid address");
    }

    function _isCollectionAuthorized(uint256 collectionId_, address addr_)
        private
        view
        returns (bool)
    {
        return
            owner() == addr_ ||
            _collections[collectionId_].artistAddr == addr_ ||
            _collections[collectionId_].authorized[addr_];
    }
}