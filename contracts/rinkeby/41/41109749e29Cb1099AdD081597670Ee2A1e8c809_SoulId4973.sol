// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * Identity Card NFT
 * *****************************************************************************
 * Creator: Sharkz
 * Author: Jason Hoi
 * Date: 2022-07-13
 *
 */

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../lib/ERC4973SoulId.sol";
import "../lib/EIP712Whitelist.sol";

contract SoulId4973 is Ownable, ERC4973SoulId, EIP712Whitelist, ReentrancyGuard {
    uint256 public tokenMinted;
    uint256 public tokenBurned;
    address public nftContract;
    address private _claimContract;

    string private _metaName = "Sharkz Soul ID #";
    string private _metaDesc = "Sharkz Soul ID is 100% on-chain generated token based on ERC4973-Soul Container designed by Sharkz Entertainment. Soul ID is the way to join our decentralized governance and allow owner to permanently stores Soul Badges from the ecosystem.";
    string public _cachedBaseUri = "https://test.sharkzent.io/assets/idcards/static/";
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
        ERC4973SoulId("SOULID", "SOULID") 
        EIP712Whitelist() 
    {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller should not be a contract");
        _;
    }

    // update token meta data desc
    function setMetaDesc(string calldata _desc) external onlyOwner {
        _metaDesc = _desc;
    }

    // setup external cached meta data
    function setCachedBaseUri(string calldata _uri) external onlyOwner {
        _cachedBaseUri = _uri;
    }

    // enable/disable external cached meta data
    function setCachedMeta(bool _enable) external onlyOwner {
        useCachedMeta = _enable;
    }

    // update linking ERC721 contract address
    function setNFTContract(address _addr) external onlyOwner {
        nftContract = _addr;
    }

    // update linking claim contract
    function setClaimContract(address _addr) external onlyOwner {
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

    function ownerMint(address _to) external onlyOwner {
        _runMint(_to);
    }

    function claim(address _to) external nonReentrant {
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
                    '{"trait_type":"ID Number","value":"', _toString(_tokenId), '"},',
                    '{"trait_type":"Background","value":"', "Blue", '"}]}'
                )
                // abi.encodePacked(
                //     'data:application/json;utf8,',
                //     '{"name":"', _metaName, '#', _toString(_tokenId),
                //     '","description":"', metaDesc,
                //     '","image":"data:image/svg+xml;base64,', Base64.encode(bytes(getSvg(_tokenId))),
                //     '","attributes":[',
                //     '{"trait_type":"ID Number","value":"', _toString(_tokenId), '"},',
                //     '{"trait_type":"Background","value":"', "Blue", '"}]}'
                // )
            );
        } else {
            return string(abi.encodePacked(_cachedBaseUri, _toString(_tokenId), ".json"));
        }
    }

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

    // generate dynamic svg <text> element with token creation timestamp and tokenId
    function _svgText(uint256 _time, uint256 _tokenId) internal pure returns (string memory) {
        // <text x='154' y='270' fill='#8ecad8' font-family='custom' font-size='12'>1600000000#1</text>
        uint256 x = 187 - 3 * _digitCount(_time) - 3 * _digitCount(_tokenId);
        return string(
            abi.encodePacked(
                "<text x='",
                _toString(x),
                "' y='270' fill='#8ecad8' font-family='custom' font-size='12'>",
                _toString(_time),
                "#",
                _toString(_tokenId),
                "</text>"
            )
        );
    }

    function _digitCount (uint _num) internal pure returns (uint256) {
        uint256 count = 1;
        uint256 z = _num / 10;
        while (z > 0) {
            count += 1;
            z = z / 10;
        }
        return count;
    }

    // store & revocation of image data by creating new contracts from current contract
    function saveImageData(
        string memory _key, 
        uint256 _pageNumber, 
        bytes memory _b
    )
        external 
        onlyOwner 
    {
        require(_b.length < 24576, "Exceeded 24,576 bytes max contract space");
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
        onlyOwner
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
 * ERC721 Identity
 *
 * Note: This contract disabled transfer feature, however, token approval and 
 * operator features are kept, enabling shadow burning or staking checking.
 * This contract may not be compatible with ERC721 contracting if transfer 
 * feature is required.
 * *****************************************************************************
 * Author: Jason Hoi
 * Date: 2022-07-11
 *
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IERC4973.sol";
import "./IERC4973SoulId.sol";
import "./721/IERC721Metadata.sol";

contract ERC4973SoulId is Ownable, ERC165, IERC4973, IERC4973SoulId, IERC721Metadata {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     *  It is required to allow Opensea or MetaMask or similar platforms to detect token.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    // One token id is bound to one address, and one address can hold one token only.
    // However, existing token cab be renewed or burnt, allowing owner address to release.
    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // We use smallest uint8 to record 0/1 balance value for the address
        uint8 balance;
        // Token create time for the single token per address
        uint40 createTimestamp;
        // 2**64-1 = 1.84e19 is more than enough
        // Keep track of minted amount of the address
        uint64 numberMinted;
        // Keep track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // Keep track of renewal
        uint64 numberRenewal;
        // extra data
        uint16 data;
    }

    struct RenewalRequest {
        // Requester address can be token owner or guardians
        address requester;
        // Request created time
        uint40 createTimestamp;
        // Request expiry time
        uint40 expireTimestamp;
        // Approval state, default as 0 or not approved
        uint8 approved;
    }

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => AddressData) internal _addressData;

    // Mapping token ID to possible multiple guardians
    mapping(uint256 => mapping(address => bool)) private _guardians;

    // Mapping token ID to renewal request
    mapping(uint256 => RenewalRequest) private _renewalRequest;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC4973SoulId).interfaceId ||
            interfaceId == type(IERC4973).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC4973-balanceOf}.
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ERC4973SoulId: balance query for the zero address");
        return uint256(_addressData[owner].balance);
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
     * @dev See {IERC4973-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC4973SoulId: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : "";
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
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether the address is either the owner or guardian
     *
     */
    function _isOwnerOrGuardian(address addr, uint256 tokenId) internal view returns (bool) {
        return (addr == ownerOf(tokenId) || isGuardian(addr, tokenId));
    }

    /**
     * @dev Returns whether address is guardian of `tokenId`. See {IERC4973SoulId-isGuardian}.
     */
    function isGuardian(address addr, uint256 tokenId) public view returns (bool) {
        return _guardians[tokenId][addr];
    }

    /**
     * @dev Set/remove guardian for `tokenId`. See {IERC4973SoulId-setGuardian}.
     *
     * Requirements:
     * - `tokenId` exists
     * - guardian address not set
     *
     * Access:
     * - `tokenId` owner
     */
    function setGuardian(address guardian, bool approved, uint256 tokenId) public {
        require(_exists(tokenId), "ERC4973SoulId: guardian setup query for nonexistent token");
        require(ownerOf(tokenId) == _msgSender(), "ERC4973SoulId: guardian setup query from non-owner");
        require(!isGuardian(guardian, tokenId), "ERC4973SoulId: guardian setup duplicated");

        _guardians[tokenId][guardian] = approved;
        emit SetGuardian(guardian, approved, tokenId);
    }

    /**
     * @dev Returns whether renew request approved
     *
     * Requirements:
     * - renewal request is not expired
     */
    function isRequestApproved(uint256 tokenId) public view returns (bool) {
        if (_renewalRequest[tokenId].approved > 0) {
          return true;
        } else {
          return false;
        }
    }

    /**
     * @dev Returns whether renew request is expired
     */
    function isRequestExpired(uint256 tokenId) public view returns (bool) {
        uint256 expiry = uint256(_renewalRequest[tokenId].expireTimestamp);
        if (expiry > 0 && expiry <= block.timestamp) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Request for renewing token, reassign token to new address. See {IERC4973SoulId-requestRenew}
     *
     * Requirements:
     * - `tokenId` exists
     *
     * Access:
     * - `tokenId` owner
     * - `tokenId` guardian
     *
     * Emits a {RequestRenew} event.
     */
    function requestRenew(uint256 expire, uint256 tokenId) public {
        require(_exists(tokenId), "ERC4973SoulId: request renew query for nonexistent token");
        require(_isOwnerOrGuardian(_msgSender(), tokenId), "ERC4973SoulId: request renew query from non-owner or guardian");

        _renewalRequest[tokenId].requester = _msgSender();
        _renewalRequest[tokenId].expireTimestamp = uint40(expire);
        _renewalRequest[tokenId].createTimestamp = uint40(block.timestamp);
        _renewalRequest[tokenId].approved = 0;

        emit RequestRenew(_msgSender(), tokenId, expire);
    }

    /**
     * @dev Approve renewal request. See {IERC4973SoulId-approveRenew}
     *
     * Requirements:
     * - `tokenId` exists
     * - request not expired
     * - request not approved before
     *
     * Access:
     * - contract issuer
     *
     * Emits a {ApproveRequestRenew} event.
     */
    function approveRenew(uint256 tokenId, bool approved) public {
        require(_exists(tokenId), "ERC4973SoulId: approve for nonexistent token");
        require(!isRequestExpired(tokenId), "ERC4973SoulId: request expired");
        require(!isRequestApproved(tokenId), "ERC4973SoulId: approval request already sent");
        require(owner() == _msgSender(), "ERC4973SoulId: approval request from non-contract owner");
        if (approved) {
            _renewalRequest[tokenId].approved = 1;
        } else {
            _renewalRequest[tokenId].approved = 0;
        }
        
        emit ApproveRequestRenew(tokenId, approved);
    }

    /**
     * @dev Renew `tokenId`. See {IERC4973SoulId-renew}.
     *
     * Requirements:
     * - `tokenId` exists
     * - request not expired
     * - request approved
     * - `to` address is not an owner of another token
     *
     * Access:
     * - `tokenId` owner
     * - `tokenId` guardian
     *
     * Emits a {Renew} event.
     */
    function renew(address to, uint256 tokenId) public {
        require(_exists(tokenId), "ERC4973SoulId: renew for nonexistent token");
        require(!isRequestExpired(tokenId), "ERC4973SoulId: request expired");
        require(isRequestApproved(tokenId), "ERC4973SoulId: unapproved renew request");
        require(balanceOf(to) == 0, "ERC4973SoulId: one token per address");
        require(_isOwnerOrGuardian(_msgSender(), tokenId), "ERC4973SoulId: unauthorized access");

        address owner = ownerOf(tokenId);

        unchecked {
            // reset renewal request
            _renewalRequest[tokenId].approved = 0;

            // reset address balance
            _addressData[owner].balance = 0;
            _addressData[to].balance = 1;
            _addressData[to].numberRenewal += 1;
            _addressData[to].createTimestamp = uint40(block.timestamp);

            // update token owner address
            _owners[tokenId] = to;
        }

        emit Renew(to, tokenId);
    }

    /**
     * @dev Mints `tokenId` to `to` address.
     *
     * Requirements:
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     * - 1:1 mapping of token and address
     *
     * Emits a {Attest} event.
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC4973SoulId: mint to the zero address");
        require(!_exists(tokenId), "ERC4973SoulId: token already minted");
        require(balanceOf(to) == 0, "ERC4973SoulId: one token per address");

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
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     * - `tokenId` must exist.
     * 
     * Access:
     * - `tokenId` owner
     *
     * Emits a {Revoke} event.
     */
    function _burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId);
        _addressData[owner].balance = 0;
        _addressData[owner].numberBurned += 1;

        delete _owners[tokenId];

        emit Revoke(owner, tokenId);
        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Burns `tokenId`. See {IERC4973-burn}.
     *
     * Access:
     * - `tokenId` owner
     */
    function burn(uint256 tokenId) public virtual {
        require(ownerOf(tokenId) == _msgSender(), "ERC4973SoulId: burn from non-owner");

        _burn(tokenId);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
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
 * *****************************************************************************
 * Author: Jason Hoi
 * Date: 2022-05-09
 *
 */

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EIP712Whitelist is Ownable {
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

    function setSigner(address _addr) public onlyOwner {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
       █                                                                        
▐█████▄█ ▀████ █████  ▐████    ████████    ███████████  ████▌  ▄████ ███████████
▐██████ █▄ ▀██ █████  ▐████   ██████████   ████   ████▌ ████▌ ████▀       ████▀ 
  ▀████ ███▄ ▀ █████▄▄▐████  ████ ▐██████  ████▄▄▄████  █████████        ████▀  
▐▄  ▀██ █████▄ █████▀▀▐████ ▄████   ██████ █████████    █████████      ▄████    
▐██▄  █ ██████ █████  ▐█████████▀    ▐█████████ ▀████▄  █████ ▀███▄   █████     
▐████  █▀█████ █████  ▐████████▀        ███████   █████ █████   ████ ███████████
       █                                                                        
                                                                       
 *******************************************************************************
 * EIP 4973 Soul Id (add-on interface)
 * *****************************************************************************
 * Creator: Sharkz
 * Author: Jason Hoi
 * Date: 2022-07-02
 *
 */

pragma solidity ^0.8.6;

/// @dev See https://eips.ethereum.org/EIPS/eip-4973
///  IERC4973SoulId added new features for renewal and guardians.
interface IERC4973SoulId {
  /// @dev This emits when any guardian addresses changed for an token.
  ///  The zero address indicates there is no guardian address.
  ///  When a Attest event emits, guardian addresses should be all reset.
  event SetGuardian(address indexed to, bool approved, uint256 indexed tokenId);

  /// @dev This emits when token owner or guardian request for token renewal.
  ///  It is recommanded to setup non-zero expiry timestamp, 0 means request last forever.
  event RequestRenew(address indexed from, uint256 indexed tokenId, uint256 expireTimestamp);

  /// @dev This emits when renewal request approved.
  event ApproveRequestRenew(uint256 indexed tokenId, bool indexed approved);

  /// @dev This emits when a token is renew and bound to an account.
  ///  A Soul ID token can only be renew and bound to new address after:
  ///  1) Renewal request is sent by owner or any guardian
  ///  2) Renewal request is approved by contract owner
  ///  3) Renewal action is performed by owner or any guardian only
  event Renew(address indexed to, uint256 indexed tokenId);

  function isGuardian(address addr, uint256 tokenId) external view returns (bool);

  function setGuardian(address to, bool approved, uint256 tokenId) external;

  function isRequestExpired(uint256 tokenId) external view returns (bool);

  function isRequestApproved(uint256 tokenId) external view returns (bool);

  function requestRenew(uint256 tokenId, uint256 expire) external;

  function approveRenew(uint256 tokenId, bool approved) external;

  function renew(address to, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

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