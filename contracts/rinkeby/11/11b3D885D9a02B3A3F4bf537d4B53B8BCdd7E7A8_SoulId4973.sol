// SPDX-License-Identifier: MIT

/**
       █                                                                        
▐█████▄█ ▀████ █████  ▐████    ████████    ███████████  ████▌  ▄████ ███████████
▐██████ █▄ ▀██ █████  ▐████   ██████████   ████   ████▌ ████▌ ████▀       ████▀ 
  ▀████ ███▄ ▀ █████▄▄▐████  ████ ▐██████  ████▄▄▄████  █████████        ████▀  
▐▄  ▀██ █████▄ █████▀▀▐████ ▄████   ██████ █████████    █████████      ▄████    
▐██▄  █ ██████ █████  ▐█████████▀    ▐█████████ ▀████▄  █████ ▀███▄   █████     
▐████  █▀█████ █████  ▐████████▀        ███████   █████ █████   ████ ███████████
       █                                                                        
                                                                       
 *******************************************************************************
 * Sharkz Soul ID
 *******************************************************************************
 * Creator: Sharkz
 * Author: Jason Hoi
 * Date: 2022-07-17
 *
 */

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../lib/Adminable.sol";
import "../lib/ERC4973SoulContainer.sol";
import "../lib/712/EIP712Whitelist.sol";

contract SoulId4973 is Adminable, ERC4973SoulContainer, EIP712Whitelist, ReentrancyGuard {
    uint256 public tokenMinted;
    uint256 public tokenBurned;
    address public nftContract;
    address private _claimContract;

    string private _metaName = "Sharkz Soul ID #";
    string private _metaDesc = "Sharkz Soul ID is 100% on-chain generated token based on ERC4973-Soul Container designed by Sharkz Entertainment. Soul ID is the way to join our decentralized governance and allow owner to permanently stores Soul Badges from the ecosystem.";
    string private _cachedBaseUri = "https://test.sharkzent.io/assets/idcards/static/";
    bool public useCachedMeta;

    struct ContractData {
        address rawContract;
        uint16 size;
    }

    struct ContractDataPages {
        uint256 maxPageNumber;
        bool exists;
        mapping (uint256 => ContractData) pages;
    }

    mapping (string => ContractDataPages) internal _contractDataPages;

    constructor() 
        ERC4973SoulContainer("SOULID", "SOULID") 
        EIP712Whitelist() 
    {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller should not be a contract");
        _;
    }

    // update token meta data desc
    function setMetaDesc(string calldata _desc) external onlyAdmin {
        _metaDesc = _desc;
    }

    // setup external cached meta data
    function setCachedBaseUri(string calldata _uri) external onlyAdmin {
        _cachedBaseUri = _uri;
    }

    // enable/disable external cached meta data
    function setCachedMeta(bool _enable) external onlyAdmin {
        useCachedMeta = _enable;
    }

    // update linking ERC721 contract address
    function setNFTContract(address _addr) external onlyAdmin {
        nftContract = _addr;
    }

    // update linking claim contract
    function setClaimContract(address _addr) external onlyAdmin {
        _claimContract = _addr;
    }

    function totalSupply() public view returns (uint256) {
        return tokenMinted - tokenBurned;
    }
    
    function _runMint(address _to) private {
        // token id starts from index 0
        _mint(_to, tokenMinted);
        unchecked {
          tokenMinted += 1;
        }
    }

    function ownerMint(address _to) external onlyAdmin {
        _runMint(_to);
    }

    function claimMint(address _to) external nonReentrant {
        require(_claimContract != address(0), "Linked claim contract is not set");
        require(_claimContract == msg.sender, "Caller is not claim contract");
        _runMint(_to);
    }

    function publicMint() external nonReentrant callerIsUser() {
        address addr = msg.sender;
        if (nftContract != address(0)) {
            require(IERC721(nftContract).balanceOf(addr) > 0, "Caller is not a NFT owner");
        }
        _runMint(addr);
    }

    function whitelistMint(bytes calldata _signature) external callerIsUser checkWhitelist(_signature) {
        _runMint(msg.sender);
    }

    function burn(uint256 _tokenId) public override {
      super.burn(_tokenId);
      unchecked {
          tokenBurned += 1;
      }
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (!useCachedMeta) {
            return string(
                abi.encodePacked(
                    'data:application/json;utf8,',
                    '{"name":"', _metaName, _toString(_tokenId),
                    '","description":"', _metaDesc,
                    '","image":"data:image/svg+xml;utf8,', tokenImage(_tokenId),
                    '","attributes":[',
                    '{"trait_type":"Card ID","value":"', _toString(_tokenId), '"},',
                    '{"trait_type":"Creation Time","value":"', _toString(_tokenCreationTime(_tokenId)), '"}]}'
                )
            );
        } else {
            return string(abi.encodePacked(_cachedBaseUri, _toString(_tokenId), ".json"));
        }
    }

    // render dynamic svg image
    function tokenImage(uint256 _tokenId) public view returns (string memory) {
        string memory svgHead = string(getImageData('svgHead'));
        uint256 time = _tokenCreationTime(_tokenId);
        return string(
            abi.encodePacked(
                svgHead,
                _svgText(time, _tokenId),
                "</svg>"
            )
        );
    }

    // render dynamic svg <text> element with token creation timestamp and tokenId
    function _svgText(uint256 _time, uint256 _tokenId) internal pure returns (string memory) {
        // <text text-anchor='middle' x='191.34' y='270' fill='#8ecad8' font-family='custom' font-size='12'>{time}#{tokenId}</text>
        return string(
            abi.encodePacked(
                "<text text-anchor='middle' x='191.34' y='270' fill='#8ecad8' font-family='custom' font-size='12'>",
                _toString(_time),
                "#",
                _toString(_tokenId),
                "</text>"
            )
        );
    }

    // store & revocation of image data by creating new contracts from current contract
    function saveImageData(
        string memory _key, 
        uint256 _pageNumber, 
        bytes memory _b
    )
        external 
        onlyAdmin 
    {
        require(_b.length <= 24576, "Exceeded 24,576 bytes max contract space");
        /**
         * 
         * `init` variable is the header of contract data
         * 61_00_00 -- PUSH2 (contract code size)
         * 60_00 -- PUSH1 (code position)
         * 60_00 -- PUSH1 (mem position)
         * 39 CODECOPY
         * 61_00_00 PUSH2 (contract code size)
         * 60_00 PUSH1 (mem position)
         * f3 RETURN
         *
        **/
        bytes memory init = hex"610000_600e_6000_39_610000_6000_f3";
        bytes1 size1 = bytes1(uint8(_b.length));
        bytes1 size2 = bytes1(uint8(_b.length >> 8));
        // 2 bytes = 2 x uint8 = 65,536 max contract code size
        init[1] = size2;
        init[2] = size1;
        init[9] = size2;
        init[10] = size1;
        
        // contract code content
        bytes memory code = abi.encodePacked(init, _b);

        // create the contract
        address dataContract;
        assembly {
            dataContract := create(0, add(code, 32), mload(code))
            if eq(dataContract, 0) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        // record the deployed contract data
        saveImageDataRecord(
            _key,
            _pageNumber,
            dataContract,
            _b.length
        );
    }

    function saveImageDataRecord(
        string memory _key,
        uint256 _pageNumber,
        address _dataContract,
        uint256 _size
    )
        public
        onlyAdmin
    {
        // Pull the current data for the contractData
        ContractDataPages storage _cdPages = _contractDataPages[_key];

        // Store the maximum page
        if (_cdPages.maxPageNumber < _pageNumber) {
            _cdPages.maxPageNumber = _pageNumber;
        }

        // Keep track of the existance of this key
        _cdPages.exists = true;

        // Add the page to the location needed
        _cdPages.pages[_pageNumber] = ContractData(
            _dataContract,
            uint16(_size)
        );
    }

    function getImageData(
        string memory _key
    )
        public
        view
        returns (bytes memory)
    {
        ContractDataPages storage _cdPages = _contractDataPages[_key];

        // Determine the total size
        uint256 totalSize;
        for (uint256 idx; idx <= _cdPages.maxPageNumber; idx++) {
            totalSize += _cdPages.pages[idx].size;
        }

        // Create a region large enough for all of the data
        bytes memory _totalData = new bytes(totalSize);

        // For each page, pull and compile
        uint256 currentPointer = 32;
        for (uint256 idx; idx <= _cdPages.maxPageNumber; idx++) {
            ContractData storage dataPage = _cdPages.pages[idx];
            address dataContract = dataPage.rawContract;
            uint256 size = uint256(dataPage.size);
            uint256 offset = 0;

            // Copy directly to total data
            assembly {
                extcodecopy(dataContract, add(_totalData, currentPointer), offset, size)
            }

            // Update the current pointer
            currentPointer += size;
        }

        return _totalData;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * Adminable access control
 *******************************************************************************
 * Creator: Sharkz
 * Author: Jason Hoi
 * Date: 2022-07-19
 *
 */
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides basic access control mechanism, multiple 
 * admins can be added or removed from the contract, admins are granted 
 * exclusive access to specific functions with the provided modifier.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {setAdmin}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyAdmin`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Adminable is Context {
    event AdminCreated(address indexed addr);
    event AdminRemoved(address indexed addr);

    // Array of admin addresses
    address[] private _admins;

    // add the first admin with contract creator
    constructor() {
        _createAdmin(_msgSender());
    }

    function isAdmin(address addr) public view virtual returns (bool) {
        if (addr == address(0)) {
          return false;
        }
        for (uint256 i = 0; i < _admins.length; i++) {
          if (addr == _admins[i])
          {
            return true;
          }
        }
        return false;
    }

    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "Adminable: caller is not admin");
        _;
    }

    function setAdmin(address to, bool approved) public virtual onlyAdmin {
        if (approved) {
            // add new admin when `to` address is not existing admin
            require(!isAdmin(to), "Adminable: add admin for existing admin");
            _createAdmin(to);

        } else {
            // for safety, specifically prevent removing initial admin
            require(to != _admins[0], "Adminable: can not remove initial admin with setAdmin");

            // remove existing admin
            require(isAdmin(to), "Adminable: remove non-existent admin");
            uint256 total = _admins.length;

            // replace current array element with last element, and pop() remove last element
            if (to != _admins[total - 1]) {
                _admins[_adminIndex(to)] = _admins[total - 1];
                _admins.pop();
            } else {
                _admins.pop();
            }

            emit AdminRemoved(to);
        }
    }

    function _adminIndex(address addr) internal view virtual returns (uint256) {
        for (uint256 i = 0; i < _admins.length; i++) {
            if (addr == _admins[i]) {
                return i;
            }
        }
        revert("Adminable: admin index not found");
    }

    function _createAdmin(address addr) internal virtual {
        _admins.push(addr);
        emit AdminCreated(addr);
    }

    /**
     * @dev Leaves the contract without admin.
     *
     * NOTE: Renouncing the last admin will leave the contract without any admins,
     * thereby removing any functionality that is only available to admins.
     */
    function renounceLastAdmin() public virtual onlyAdmin {
        require(_admins.length == 1, "Adminable: can not renounce admin when there are more than one admins");
        delete _admins;
        emit AdminRemoved(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * ERC4973 Soul Container
 *******************************************************************************
 * Creator: Sharkz
 * Author: Jason Hoi
 * Date: 2022-07-19
 *
 */

pragma solidity ^0.8.7;

import "./IERC4973.sol";
import "./IERC4973SoulContainer.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata {
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

/**
 * @dev See https://eips.ethereum.org/EIPS/eip-4973
 * @dev Implementation of IERC4973 and the additional IERC4973 Soul Container interface
 * 
 * Please noted that EIP-4973 is a draft proposal by the time of contract design, EIP 
 * final definition can be changed.
 * 
 * This implementation included many features for real-life usage, by including ERC721
 * Metadata extension, we allow NFT platforms to recognize the token name, symbol and token
 * metadata, ex. token image, attributes. By design, ERC721 transfer, operator, and approval 
 * mechanisms are all removed.
 *
 * Access controls applied user roles: token owner, token guardians, admins, public users.
 * 
 * Assumes that the max value for token id, and guardians numbers are 2**256 (uint256).
 *
 */
contract ERC4973SoulContainer is IERC4973, IERC4973SoulId, IERC721Metadata {
    /// @dev This emits when admin is added or removed.
    event SetAdmin(address indexed to, bool approved);

    /// @dev Emitted when `tokenId` token is transferred from `from` to `to`.
    /// It is required for NFT platforms to detect token creation.
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /// @dev Token id and address is 1:1 binding, however, existing token can be renewed or burnt, 
    /// releasing old address to be bind to new token id.
    /// Compiler will pack this into a single 256bit word.
    struct AddressData {
        // We use smallest uint8 to record 0/1 balance value for the address
        uint8 balance;
        // Token create time for the single token per address
        uint40 createTimestamp;
        // Keep track of minted token amount, address can mint more token only after 
        // previous token is burnt by token owner
        uint64 numberMinted;
        // Keep track of burnt token amount
        uint64 numberBurned;
        // Keep track of renewal counter for address
        uint80 numberRenewal;
    }

    // Mapping owner address to token count
    mapping(address => AddressData) internal _addressData;

    // Renewal request struct
    struct RenewalRequest {
        // Requester address can be token owner or guardians
        address requester;
        // Request created time
        uint40 createTimestamp;
        // Request expiry time
        uint40 expireTimestamp;
        // uint16 leaveover in uint256 struct
    }

    // Mapping token ID to renewal request, only store last request to allow easy override
    mapping(uint256 => RenewalRequest) private _renewalRequest;

    // Mapping request hash key to approver addresses
    mapping(uint256 => mapping(address => bool)) private _renewalApprovers;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping token ID to multiple guardians.
    mapping(uint256 => address[]) private _guardians;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
            interfaceId == type(IERC4973).interfaceId ||
            interfaceId == type(IERC4973SoulId).interfaceId;
    }

    /**
     * Returns the address unique token creation timestamp
     */
    function _tokenCreationTime(uint256 _tokenId) internal view returns (uint256) {
        return uint256(_addressData[ownerOf(_tokenId)].createTimestamp);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * @dev See {IERC4973-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC4973SoulContainer: balance query for the zero address");
        return uint256(_addressData[owner].balance);
    }

    /**
     * @dev See {IERC4973-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC4973SoulContainer: owner query for non-existent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for non-existent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation with `baseURI` and the `tokenId`.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * Returns whether `tokenId` exists.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * Returns whether the address is either the owner or guardian
     */
    function _isOwnerOrGuardian(address addr, uint256 tokenId) internal view virtual returns (bool) {
        return (addr != address(0) && (addr == ownerOf(tokenId) || isGuardian(addr, tokenId)));
    }

    /**
     * Returns guardian index by address for the token
     */
    function _getGuardianIndex(address addr, uint256 tokenId) internal view virtual returns (uint256) {
        for (uint256 i = 0; i < _guardians[tokenId].length; i++) {
            if (addr == _guardians[tokenId][i]) {
                return i;
            }
        }
        revert("ERC4973SoulContainer: guardian index error");
    }

    /**
     * Returns guardian index by address for the token
     */
    function getGuardianIndex(address addr, uint256 tokenId) public view virtual returns (uint256) {
        require(_isOwnerOrGuardian(_msgSenderERC4973(), tokenId), "ERC4973SoulContainer: query from non-owner or guardian");
        return _getGuardianIndex(addr, tokenId);
    }

    /**
     * Returns guardian address by index
     */
    function getGuardianByIndex(uint256 index, uint256 tokenId) public view virtual returns (address) {
        require(_isOwnerOrGuardian(_msgSenderERC4973(), tokenId), "ERC4973SoulContainer: query from non-owner or guardian");
        return _guardians[tokenId][index];
    }

    /**
     * Returns guardian count
     */
    function getGuardianCount(uint256 tokenId) public view virtual returns (uint256) {
        require(_isOwnerOrGuardian(_msgSenderERC4973(), tokenId), "ERC4973SoulContainer: query from non-owner or guardian");
        return _guardians[tokenId].length;
    }

    /**
     * @dev See {IERC4973SoulId-isGuardian}.
     */
    function isGuardian(address addr, uint256 tokenId) public view virtual override returns (bool) {
        require(addr != address(0), "ERC4973SoulContainer: guardian is zero address");
        
        for (uint256 i = 0; i < _guardians[tokenId].length; i++) {
            if (addr == _guardians[tokenId][i]) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev See {IERC4973SoulId-setGuardian}.
     */
    function setGuardian(address to, bool approved, uint256 tokenId) public virtual override {
        // access controls
        require(ownerOf(tokenId) == _msgSenderERC4973(), "ERC4973SoulContainer: guardian setup query from non-owner");

        require(_exists(tokenId), "ERC4973SoulContainer: guardian setup query for non-existent token");
        if (approved) {
            // adding guardian
            require(!isGuardian(to, tokenId), "ERC4973SoulContainer: guardian already existed");
            _guardians[tokenId].push(to);

        } else {
            // remove guardian
            require(isGuardian(to, tokenId), "ERC4973SoulContainer: removing non-existent guardian");

            uint256 total = _guardians[tokenId].length;
            if (_guardians[tokenId][total-1] != to) {
                uint256 index = _getGuardianIndex(to, tokenId);
                // replace current value from last array element
                _guardians[tokenId][index] = _guardians[tokenId][total-1];
                // remove last element and shorten the array length
                _guardians[tokenId].pop();
            } else {
                // remove last element and shorten the array length
                _guardians[tokenId].pop();
            }
        }

        emit SetGuardian(to, tokenId, approved);
    }

    /**
     * Returns approver index key for the current token renewal request
     */
    function _approverIndexKey(uint256 tokenId) internal view virtual returns (uint256) {
        uint256 createTime = _renewalRequest[tokenId].createTimestamp;
        return uint256(keccak256(abi.encodePacked(createTime, ":", tokenId)));
    }

    /**
     * Returns approval count for the renewal request
     * Approvers can be token owner or guardians
     */
    function getApprovalCount(uint256 tokenId) public view virtual returns (uint256) {
        uint256 indexKey = _approverIndexKey(tokenId);
        uint256 count = 0;

        // count if token owner approved
        if (_renewalApprovers[indexKey][ownerOf(tokenId)]) {
            count += 1;
        }

        for (uint256 i = 0; i < _guardians[tokenId].length; i++) {
            address guardian = _guardians[tokenId][i];
            if (_renewalApprovers[indexKey][guardian]) {
                count += 1;
            }
        }

        return count;
    }

    /**
     * Returns request approval quorum size (min number of approval needed)
     */
    function getApprovalQuorum(uint256 tokenId) public view virtual returns (uint256) {
        uint256 guardianCount = _guardians[tokenId].length;
        // mininum approvers are 2 (can be 1 token owner plus at least 1 guardian)
        require(guardianCount > 0, "ERC4973SoulContainer: approval quorum require at least 2 approvers");

        uint256 total = 1 + guardianCount;
        uint256 quorum = (total) / 2 + 1;
        return quorum;
    }

    /**
     * Returns whether renew request approved
     *
     * Valid approvers = N = 1 + guardians (1 from token owner)
     * Mininum one guardian is need to build the quorum system.
     *
     * Approval quorum = N / 2 + 1
     * For example: 3 approvers = 2 quorum needed
     *              4 approvers = 3 quorum needed
     *              5 approvers = 3 quorum needed
     *
     * Requirements:
     * - renewal request is not expired
     */
    function isRequestApproved(uint256 tokenId) public view virtual returns (bool) {
        if (getApprovalCount(tokenId) >= getApprovalQuorum(tokenId)) {
          return true;
        } else {
          return false;
        }
    }

    /**
     * Returns whether renew request is expired
     */
    function isRequestExpired(uint256 tokenId) public view virtual returns (bool) {
        uint256 expiry = uint256(_renewalRequest[tokenId].expireTimestamp);
        if (expiry > 0 && expiry <= block.timestamp) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev See {IERC4973SoulId-requestRenew}.
     */
    function requestRenew(uint256 expireTimestamp, uint256 tokenId) public virtual override {
        // access controls
        require(_isOwnerOrGuardian(_msgSenderERC4973(), tokenId), "ERC4973SoulContainer: query from non-owner or guardian");

        _renewalRequest[tokenId].requester = _msgSenderERC4973();
        _renewalRequest[tokenId].expireTimestamp = uint40(expireTimestamp);
        _renewalRequest[tokenId].createTimestamp = uint40(block.timestamp);

        emit RequestRenew(_msgSenderERC4973(), tokenId, expireTimestamp);
    }

    /**
     * @dev See {IERC4973SoulId-approveRenew}.
     */
    function approveRenew(bool approved, uint256 tokenId) public virtual override {
        // access controls
        require(_isOwnerOrGuardian(_msgSenderERC4973(), tokenId), "ERC4973SoulContainer: query from non-owner or guardian");

        // requirements
        require(_exists(tokenId), "ERC4973SoulContainer: approve for non-existent token");
        require(!isRequestExpired(tokenId), "ERC4973SoulContainer: request expired");

        // minimum 2 approvers: approver #1 is owner, approver #2, #3... are guardians
        require(_guardians[tokenId].length > 0, "ERC4973SoulContainer: approval quorum require at least 2 approvers");

        uint256 indexKey = _approverIndexKey(tokenId);
        _renewalApprovers[indexKey][_msgSenderERC4973()] = approved;
        
        emit ApproveRenew(tokenId, approved);
    }

    /**
     * @dev See {IERC4973SoulId-renew}.
     * Emits {Renew} event.
     * Emits {Transfer} event. (to support NFT platforms)
     */
    function renew(address to, uint256 tokenId) public virtual override {
        // access controls
        require(_isOwnerOrGuardian(_msgSenderERC4973(), tokenId), "ERC4973SoulContainer: renew with unauthorized access");
        require(_renewalRequest[tokenId].requester == _msgSenderERC4973(), "ERC4973SoulContainer: renew with invalid requester");

        // requirements
        require(_exists(tokenId), "ERC4973SoulContainer: renew with non-existent token");
        require(!isRequestExpired(tokenId), "ERC4973SoulContainer: renew with expired request");
        require(isRequestApproved(tokenId), "ERC4973SoulContainer: renew with unapproved request");
        require(balanceOf(to) == 0, "ERC4973SoulContainer: renew to existing token address");
        require(to != address(0), "ERC4973SoulContainer: renew to zero address");

        address oldAddr = ownerOf(tokenId);

        unchecked {
            // reset renewal request
            delete _renewalRequest[tokenId];

            // update old address data
            _addressData[oldAddr].balance = 0;
            _addressData[oldAddr].numberBurned += 1;

            // update new address data
            _addressData[to].balance = 1;
            _addressData[to].numberRenewal += 1;
            _addressData[to].createTimestamp = uint40(block.timestamp);
            _owners[tokenId] = to;
        }

        emit Renew(to, tokenId);
        emit Transfer(oldAddr, to, tokenId);
    }

    /**
     * @dev Mints `tokenId` to `to` address.
     *
     * Requirements:
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     * - 1:1 mapping of token and address
     *
     * Emits {Attest} event.
     * Emits {Transfer} event. (to support NFT platforms)
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC4973SoulContainer: mint to the zero address");
        require(!_exists(tokenId), "ERC4973SoulContainer: token already minted");
        require(balanceOf(to) == 0, "ERC4973SoulContainer: one token per address");

        // Overflows are incredibly unrealistic.
        // max balance should be only 1
        unchecked {
            _addressData[to].balance = 1;
            _addressData[to].numberMinted += 1;
            _addressData[to].createTimestamp = uint40(block.timestamp);
            _owners[tokenId] = to;
        }

        emit Attest(to, tokenId);
        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     *
     * Requirements:
     * - `tokenId` must exist.
     * 
     * Access:
     * - `tokenId` owner
     *
     * Emits {Revoke} event.
     * Emits {Transfer} event. (to support NFT platforms)
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);
        _addressData[owner].balance = 0;
        _addressData[owner].numberBurned += 1;

        // delete will reset all struct variables to 0
        delete _owners[tokenId];
        delete _renewalRequest[tokenId];

        emit Revoke(owner, tokenId);
        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Burns `tokenId`. See {IERC4973-burn}.
     *
     * Access:
     * - `tokenId` owner
     */
    function burn(uint256 tokenId) public virtual override {
        require(ownerOf(tokenId) == _msgSenderERC4973(), "ERC4973SoulContainer: burn from non-owner");

        _burn(tokenId);
    }

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * For GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC4973() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * Converts `uint256` to ASCII `string`
     */
    function _toString(uint256 value) internal pure returns (string memory ptr) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for {
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } {
                // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
    }
}

// SPDX-License-Identifier: MIT

/**                                                                 
 *******************************************************************************
 * EIP 721 whitelist with only msg.sender
 *******************************************************************************
 * Author: Jason Hoi
 * Date: 2022-05-09
 *
 */

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../Adminable.sol";

contract EIP712Whitelist is Adminable {
    using ECDSA for bytes32;

    // Verify signature with this signer address
    address public eip712Signer = address(0);

    // Domain separator is EIP-712 defined struct to make sure 
    // signature is coming from the this contract in same ETH newtork.
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#definition-of-domainseparator
    // @MATCHING cliend-side code
    bytes32 public DOMAIN_SEPARATOR;

    // HASH_STRUCT should not contain unnecessary whitespace between each parameters
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#definition-of-encodetype
    // @MATCHING cliend-side code
    bytes32 public constant HASH_STRUCT = keccak256("Minter(address wallet)");

    constructor() {
        // @MATCHING cliend-side code
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                // @MATCHING cliend-side code
                keccak256(bytes("WhitelistToken")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    function setSigner(address _addr) public onlyAdmin {
        eip712Signer = _addr;
    }

    modifier checkWhitelist(bytes calldata _signature) {
        require(eip712Signer == _recoverSigner(_signature), "EIP712: Invalid Signature");
        _;
    }

    // Verify signature (relating to msg.sender) comes by correct signer
    function verifySignature(bytes calldata _signature) public view returns (bool) {
        return eip712Signer == _recoverSigner(_signature);
    }

    // Recover the signer address
    function _recoverSigner(bytes calldata _signature) internal view returns (address) {
        require(eip712Signer != address(0), "EIP712: Whitelist not enabled");

        // Verify EIP-712 signature by recreating the data structure
        // that we signed on the client side, and then using that to recover
        // the address that signed the signature for this data.
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(HASH_STRUCT, msg.sender))
            )
        );
        return digest.recover(_signature);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

/// @title Account-bound tokens
/// @dev See https://eips.ethereum.org/EIPS/eip-4973
///  Note: the ERC-165 identifier for this interface is 0x5164cf47.
interface IERC4973 /* is ERC165, ERC721Metadata */ {
  /// @dev This emits when a new token is created and bound to an account by
  /// any mechanism.
  /// Note: For a reliable `from` parameter, retrieve the transaction's
  /// authenticated `from` field.
  event Attest(address indexed to, uint256 indexed tokenId);
  /// @dev This emits when an existing ABT is revoked from an account and
  /// destroyed by any mechanism.
  /// Note: For a reliable `from` parameter, retrieve the transaction's
  /// authenticated `from` field.
  event Revoke(address indexed to, uint256 indexed tokenId);
  /// @notice Count all ABTs assigned to an owner
  /// @dev ABTs assigned to the zero address are considered invalid, and this
  ///  function throws for queries about the zero address.
  /// @param owner An address for whom to query the balance
  /// @return The number of ABTs owned by `owner`, possibly zero
  function balanceOf(address owner) external view returns (uint256);
  /// @notice Find the address bound to an ERC4973 account-bound token
  /// @dev ABTs assigned to zero address are considered invalid, and queries
  ///  about them do throw.
  /// @param tokenId The identifier for an ABT
  /// @return The address of the owner bound to the ABT
  function ownerOf(uint256 tokenId) external view returns (address);
  /// @notice Destroys `tokenId`. At any time, an ABT receiver must be able to
  ///  disassociate themselves from an ABT publicly through calling this
  ///  function.
  /// @dev Must emit a `event Revoke` with the `address to` field pointing to
  ///  the zero address.
  /// @param tokenId The identifier for an ABT
  function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * IERC4973 Soul Container interface
 *******************************************************************************
 * Creator: Sharkz
 * Author: Jason Hoi
 * Date: 2022-07-19
 *
 */

pragma solidity ^0.8.7;

/**
 * @dev See https://eips.ethereum.org/EIPS/eip-4973
 * This is additional interface on top of EIP-4973
 */
interface IERC4973SoulId {
  /**
   * @dev This emits when any guardian added or removed for a token.
   */
  event SetGuardian(address indexed to, uint256 indexed tokenId, bool approved);

  /**
   * @dev This emits when token owner or guardian request for token renewal.
   */
  event RequestRenew(address indexed from, uint256 indexed tokenId, uint256 expireTimestamp);

  /**
   * @dev This emits when renewal request approved by one address
   */
  event ApproveRenew(uint256 indexed tokenId, bool indexed approved);

  /**
   * @dev This emits when a token is renewed and bind to new address
   */
  event Renew(address indexed to, uint256 indexed tokenId);

  /**
   * @dev Returns whether an address is guardian of `tokenId`.
   */
  function isGuardian(address addr, uint256 tokenId) external view returns (bool);

  /**
   * @dev Set/remove guardian for `tokenId`.
   *
   * Requirements:
   * - `tokenId` exists
   * - (addition) guardian is not set before
   * - (removal) guardian should be existed
   *
   * Access:
   * - `tokenId` owner
   * 
   * Emits {SetGuardian} event.
   */
  function setGuardian(address to, bool approved, uint256 tokenId) external;

  /**
   * @dev Request for token renewal, to reassign token to new address.
   * It is recommanded to setup non-zero expiry timestamp, zero expiry means the 
   * request can last forever to receive approval.
   *
   * Requirements:
   * - `tokenId` exists
   *
   * Access:
   * - `tokenId` owner
   * - `tokenId` guardian
   *
   * Emits {RequestRenew} event.
   */
  function requestRenew(uint256 expireTimestamp, uint256 tokenId) external;

  /**
   * @dev Approve or cancel approval for a renewal request.
   * Owner or guardian can reset the renewal request by calling requestRenew() again to 
   * reset request approver index key to new value.
   *
   * Valid approvers = N = 1 + guardians (1 from token owner)
   * Mininum one guardian is need to build the quorum system.
   *
   * Approval quorum (> 50%) = N / 2 + 1
   * For example: 3 approvers = 2 quorum needed
   *              4 approvers = 3 quorum needed
   *              5 approvers = 3 quorum needed
   *
   * Requirements:
   * - `tokenId` exists
   * - request not expired
   *
   * Access:
   * - `tokenId` owner
   * - `tokenId` guardian
   *
   * Emits {ApproveRenew} event.
   */
  function approveRenew(bool approved, uint256 tokenId) external;

  /**
   * @dev Renew a token to new address.
   *
   * Renewal process (token can be renewed and bound to new address):
   * 1) Token owner or guardians (in case of the owner lost wallet) create/reset a renewal request
   * 2) Token owner and eacg guardian can approve the request until approval quorum (> 50%) reached
   * 3) Renewal action can be called by request originator to set the new binding address
   *
   * Requirements:
   * - `tokenId` exists
   * - request not expired
   * - request approved
   * - `to` address is not an owner of another token
   * - `to` cannot be the zero address.
   *
   * Access:
   * - `tokenId` owner
   * - `tokenId` guardian
   * - requester of the request
   *
   * Emits {Renew} event.
   */
  function renew(address to, uint256 tokenId) external;

  /**
   * @dev Returns true if this contract implements the interface defined by `interfaceId`.
   * See https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
   */
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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