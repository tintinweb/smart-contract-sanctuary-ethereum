// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity 0.8.15;

import "./token/ERC721OptimizedFactory.sol";

contract GOTMFactory is ERC721OptimizedFactory {
    constructor(string memory baseURI_, OptionConfig memory optionConfig_, address payable erc721OptimizedAddress_, address proxyRegistryAddress_) ERC721OptimizedFactory(
        "GOATs of the Metaverse Factory",
        "GOTMF",
        baseURI_,
        optionConfig_,
        erc721OptimizedAddress_,
        proxyRegistryAddress_
    ) {}
}

// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity 0.8.15;

import "../access/SharedOwnable.sol";
import "../interfaces/IERC721Optimized.sol";
import "../opensea/IERC721Factory.sol";
import "../opensea/ProxyRegistry.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ERC721OptimizedFactory is Context, SharedOwnable, IERC721, IERC721Factory {
    using Strings for address;
    using Strings for uint256;

    struct OptionConfig {
        uint64[] mintAmount;
    }

    string private _name;
    string private _symbol;
    string private _baseURI;
    OptionConfig private _optionConfig;
    IERC721Optimized private _erc721Optimized;
    address private _proxyRegistryAddress;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_, string memory baseURI_, OptionConfig memory optionConfig_, address payable erc721OptimizedAddress_, address proxyRegistryAddress_) {
        require(bytes(name_).length > 0, "ERC721OptimizedFactory: name can't be empty");
        require(bytes(symbol_).length > 0, "ERC721OptimizedFactory: symbol can't be empty");
        require(bytes(baseURI_).length > 0, "ERC721OptimizedFactory: baseURI can't be empty");
        require(optionConfig_.mintAmount.length > 0, "ERC721OptimizedFactory: optionConfig's mintAmount can't be empty");
        require(erc721OptimizedAddress_ != address(0), "ERC721OptimizedFactory: erc721OptimizedAddress can't be null address");
        if (proxyRegistryAddress_ != address(0))
            ProxyRegistry(proxyRegistryAddress_).proxies(_msgSender());

        IERC721Optimized erc721Optimized = IERC721Optimized(erc721OptimizedAddress_);
        erc721Optimized.publicMintConfig();

        _name = name_;
        _symbol = symbol_;
        _baseURI = baseURI_;
        _optionConfig = optionConfig_;
        _erc721Optimized = erc721Optimized;
        _proxyRegistryAddress = proxyRegistryAddress_;

        _fireTransferEvents(address(0), owner());
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Factory).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function baseURI() external view returns (string memory) {
        return _baseURI;
    }

    function optionConfig() external view returns (OptionConfig memory) {
        return _optionConfig;
    }

    function erc721OptimizedAddress() external view returns (address) {
        return address(_erc721Optimized);
    }

    function proxyRegistryAddress() external view returns (address) {
        return _proxyRegistryAddress;
    }

    function numOptions() external view returns (uint256) {
        return _optionConfig.mintAmount.length;
    }

    function setBaseURI(string calldata baseURI_) external onlySharedOwners {
        require(bytes(baseURI_).length > 0, "ERC721OptimizedFactory: baseURI can't be empty");
        _baseURI = baseURI_;
    }

    function setOptionConfig(OptionConfig memory optionConfig_) external onlySharedOwners {
        require(optionConfig_.mintAmount.length > 0, "ERC721OptimizedFactory: optionConfig's mintAmount can't be empty");
        _fireTransferEvents(owner(), address(0));
        _optionConfig = optionConfig_;
        _fireTransferEvents(address(0), owner());
    }

    function setProxyRegistryAddress(address proxyRegistryAddress_) external onlySharedOwners {
        if (proxyRegistryAddress_ != address(0))
            ProxyRegistry(proxyRegistryAddress_).proxies(_msgSender());
        _proxyRegistryAddress = proxyRegistryAddress_;
    }

    function contractURI() external view returns (string memory) {
        return string(abi.encodePacked(_baseURI, "contract"));
    }
    
    function canMint(uint256 _optionId) external view returns (bool) {
        return _canMint(_optionId);
    }

    function tokenURI(uint256 _optionId) external view returns (string memory) {
        return string(abi.encodePacked(_baseURI, _optionId.toString()));
    }

    function supportsFactoryInterface() external pure returns (bool) {
        return true;
    }

    function mint(uint256 _optionId, address _toAddress) external {
        _mint(_optionId, _toAddress);
    }

    function kill(address payable recipient) external onlyOwner {
        _fireTransferEvents(owner(), address(0));
        selfdestruct(recipient);
    }

    function transferOwnership(address newOwner) override public onlyOwner {
        address _prevOwner = owner();
        super.transferOwnership(newOwner);
        _fireTransferEvents(_prevOwner, newOwner);
    }

    function _canMint(uint256 _optionId) private view returns (bool) {
        if (_optionId >= _optionConfig.mintAmount.length)
            return false;

        IERC721Optimized.MintConfig memory publicMintConfig = _erc721Optimized.publicMintConfig();
        if (block.timestamp < publicMintConfig.mintStartTimestamp)
            return false;

        if (block.timestamp >= publicMintConfig.mintEndTimestamp)
            return false;

        uint64 amount = _optionConfig.mintAmount[_optionId];
        if (_erc721Optimized.totalMinted() + amount > publicMintConfig.maxTotalMintAmount)
            return false;

        return true;
    }

    function _mint(uint256 _optionId, address _toAddress) private {
        require((owner() == _msgSender()) || (_proxyRegistryAddress != address(0) && address(ProxyRegistry(_proxyRegistryAddress).proxies(owner())) == _msgSender()) || (_operatorApprovals[owner()][_msgSender()]), string(abi.encodePacked("ERC721OptimizedFactory: caller ", _msgSender().toHexString(), " is not permitted to mint")));
        require(_canMint(_optionId), "ERC721OptimizedFactory: can't mint");

        _erc721Optimized.publicMint(_toAddress, _optionConfig.mintAmount[_optionId]);
    }

    function _fireTransferEvents(address _from, address _to) private {
        for (uint256 i = 0; i < _optionConfig.mintAmount.length; i++)
            emit Transfer(_from, _to, i);
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use IERC721 so the frontend doesn't have to worry about different method names.
     */

    function approve(address, uint256) external {}
    function setApprovalForAll(address _operator, bool _approved) external {
        if (owner() == _msgSender())
            _operatorApprovals[_msgSender()][_operator] = _approved;
    }

    function transferFrom(address, address _to, uint256 _tokenId) external {
        _mint(_tokenId, _to);
    }

    function safeTransferFrom(address, address _to, uint256 _tokenId) external {
        _mint(_tokenId, _to);
    }

    function safeTransferFrom(address, address _to, uint256 _tokenId, bytes calldata) external {
        _mint(_tokenId, _to);
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        if (owner() == _owner) {
            if (_owner == _operator)
                return true;

            if (_proxyRegistryAddress != address(0) && address(ProxyRegistry(_proxyRegistryAddress).proxies(_owner)) == _operator)
                return true;

            if (_operatorApprovals[_owner][_operator])
                return true;
        }

        return false;
    }

    function balanceOf(address _owner) external view returns (uint256 _balance) {
        if (owner() == _owner)
            _balance = _optionConfig.mintAmount.length;
    }

    function getApproved(uint256) external view returns (address) {
        return owner();
    }

    function ownerOf(uint256) external view returns (address) {
        return owner();
    }
}

// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity >=0.4.13;

import "./OwnableDelegateProxy.sol";

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity >=0.4.13;

contract OwnableDelegateProxy {}

// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity ^0.8.0;

interface IERC721Factory {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function numOptions() external view returns (uint256);

    function canMint(uint256 _optionId) external view returns (bool);

    function tokenURI(uint256 _optionId) external view returns (string memory);

    function supportsFactoryInterface() external view returns (bool);

    function mint(uint256 _optionId, address _toAddress) external;
}

// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity 0.8.15;

interface IERC721Optimized {
    struct MintConfig {
        uint64 maxTotalMintAmount;
        uint64 maxMintAmountPerAddress;
        uint128 pricePerMint;
        uint256 mintStartTimestamp;
        uint256 mintEndTimestamp;
        uint64[] discountPerMintAmountKeys;
        uint128[] discountPerMintAmountValues;
    }

    function publicMintConfig() external view returns (MintConfig memory);

    function totalMinted() external view returns (uint256);

    function publicMint(address to, uint64 amount) external;
}

// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract SharedOwnable is Ownable {
    address private _creator;
    mapping(address => bool) private _sharedOwners;

    event SharedOwnershipAdded(address indexed sharedOwner);
    event SharedOwnershipRemoved(address indexed sharedOwner);

    constructor() Ownable() {
        _creator = msg.sender;
        _setSharedOwner(msg.sender, true);
    }

    modifier onlyCreator() {
        require(_creator == msg.sender, "SharedOwnable: caller is not the creator");
        _;
    }

    modifier onlySharedOwners() {
        require(owner() == msg.sender || _sharedOwners[msg.sender], "SharedOwnable: caller is not a shared owner");
        _;
    }

    function getCreator() external view returns (address) {
        return _creator;
    }

    function isSharedOwner(address account) external view returns (bool) {
        return _sharedOwners[account];
    }

    function setSharedOwner(address account, bool sharedOwner) external onlyCreator {
        _setSharedOwner(account, sharedOwner);
    }

    function _setSharedOwner(address account, bool sharedOwner) private {
        _sharedOwners[account] = sharedOwner;
        if (sharedOwner)
            emit SharedOwnershipAdded(account);
        else
            emit SharedOwnershipRemoved(account);
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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