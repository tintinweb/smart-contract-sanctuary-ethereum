// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./protocols/ICanvas.sol";
import "./protocols/IDeployRegistry.sol";
import "./protocols/IPixelCanvasRegistry.sol";
import "./PixelCanvasApplicationType.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
    
    
contract BoxCanvas is ICanvas, Ownable {

    event EventSetPixel(
        IPixel indexed pixelContract,
        uint256 indexed tokenId,
        uint32 locationX,
        uint32 locationY,
        uint32 locationZ
    );

    event EventRemovePixel(
        IPixel indexed pixelContract,
        uint256 indexed tokenId
    );

    struct LocationData {
        uint32 locationX;
        uint32 locationY;
        uint32 locationZ;
    }
    
    struct PixelData {
        IPixel pixelContract;
        uint256 tokenId;
    }

    string public constant CONST_OPERATION_SET_PIXEL = "box-canvas-set-pixel";
    string public constant CONST_OPERATION_REMOVE_PIXEL = "box-canvas-remove-pixel";

    IDeployRegistry private _privateDeployRegistry;
    string private _privateName;
    uint32 private _privateWidth;
    uint32 private _privateHeight;
    uint32 private _privateDepth;

    mapping(bytes32 => LocationData) private _locationByPixel;
    mapping(bytes32 => PixelData) private _pixelByLocation;
    
    constructor(IDeployRegistry _deployRegistry, string memory _name, uint32 _width, uint32 _height, uint32 _depth) {
        _privateDeployRegistry = _deployRegistry;
        _privateName = _name;
        _privateWidth = _width;
        _privateHeight = _height;
        _privateDepth = _depth;
    }

    //ICanvas

    function name() public override view returns (string memory) {
        return _privateName;
    }

    function kind() virtual override public pure returns (string memory) {
        return "box";
    }

    function width() public override view returns (uint32) {
        return _privateWidth;
    }

    function height() public override view returns (uint32) {
        return _privateHeight;
    }

    function depth() public override view returns (uint32) {
        return _privateDepth;
    }

    function canModify(IPixel pixelContract, uint256 tokenId) public override view returns (bool) {
        _requireValidPixel(pixelContract, tokenId);

        return (pixelContract.ownerOf(tokenId) == _msgSender());
    }

    function getLocation(IPixel pixelContract, uint256 tokenId) public override view returns (bool, uint32, uint32, uint32) {
        _requireValidPixel(pixelContract, tokenId);

        if (address(pixelContract) == address(0)) {
            return (false, 0, 0, 0);
        }

        PixelData memory pixel = PixelData(pixelContract, tokenId);
        bytes32 _pixelHash = pixelHash(pixel);
        LocationData memory location = _locationByPixel[_pixelHash];
        uint32 locationX = location.locationX;
        uint32 locationY = location.locationY;
        uint32 locationZ = location.locationZ;
        bool success = (locationX > 0) && (locationY > 0) && (locationZ > 0);
        return (success, locationX, locationY, locationZ);
    }

    function getPixel(uint32 locationX, uint32 locationY, uint32 locationZ) public override view returns (IPixel, uint256) {
        LocationData memory location = LocationData(locationX, locationY, locationZ);
        bytes32 _locationHash = locationHash(location);
        PixelData memory pixel = _pixelByLocation[_locationHash];
        return (pixel.pixelContract, pixel.tokenId);
    }

    function setPixel(IPixel pixelContract, uint256 tokenId, uint32 locationX, uint32 locationY, uint32 locationZ) public override payable {
        _requireValueForOperation(msg.value, CONST_OPERATION_SET_PIXEL);
        _requireValidPixel(pixelContract, tokenId);

        PixelData memory pixel = PixelData(pixelContract, tokenId);
        LocationData memory location = LocationData(locationX, locationY, locationZ);
        _requireCanModify(pixel);
        _requireValidLocation(location);
        _requireThisCanvas(pixel);
        
        bytes32 _pixelHash = pixelHash(pixel);
        bytes32 _locationHash = locationHash(location);

        PixelData memory currentPixelAtLocation = _pixelByLocation[_locationHash];
        bool hasPixelAtSpecifiedLocation = ((currentPixelAtLocation.pixelContract != IPixel(address(0))) || (currentPixelAtLocation.tokenId > 0));
        require(!hasPixelAtSpecifiedLocation, "Location is already contains pixel");

        LocationData memory currentPixelLocation = _locationByPixel[_pixelHash];
        bool wasPlaced = ((currentPixelLocation.locationX > 0) && (currentPixelLocation.locationY > 0) && (currentPixelLocation.locationZ > 0));
        if (wasPlaced) {
            bytes32 _currentLocationlHash = locationHash(currentPixelLocation);
            _pixelByLocation[_currentLocationlHash] = PixelData(IPixel(address(0)), 0);
        }

        _pixelByLocation[_locationHash] = pixel;
        _locationByPixel[_pixelHash] = location;
        emit EventSetPixel(pixelContract, tokenId, locationX, locationY, locationZ);

        _getPixelCanvasRegistry().paymentsDeposit{value: msg.value}();
    }

    function removePixel(IPixel pixelContract, uint256 tokenId) public override payable {
        _requireValueForOperation(msg.value, CONST_OPERATION_REMOVE_PIXEL);
        _requireValidPixel(pixelContract, tokenId);
        
        PixelData memory pixel = PixelData(pixelContract, tokenId);
        _requireCanModify(pixel);
        _requireThisCanvas(pixel);
        bytes32 _pixelHash = pixelHash(pixel);

        LocationData memory location = _locationByPixel[_pixelHash];
        bytes32 _locationHash = locationHash(location);

        _locationByPixel[_pixelHash] = LocationData(0, 0, 0);
        _pixelByLocation[_locationHash] = PixelData(IPixel(address(0)), 0);
        emit EventRemovePixel(pixelContract, tokenId);

        _getPixelCanvasRegistry().paymentsDeposit{value: msg.value}();
    }

    function locationIndex(uint32 locationX, uint32 locationY, uint32 locationZ) override public view returns (uint256) {
        LocationData memory location = LocationData(locationX, locationY, locationZ);
        _requireValidLocation(location);

        uint256 maxX = width();
        uint256 maxY = height();
        uint256 index = (locationX - 1) + ((locationY - 1) * maxX) + ((locationZ - 1) * maxX * maxY);
        index += 1;
        return index;
    }

    function locationFromIndex(uint256 index) override public view returns (uint32, uint32, uint32) {
        _requireValidLocationIndex(index);

        uint256 actualIndex = index - 1;
        uint256 maxX = width();
        uint256 maxY = height();

        uint256 locationZ = actualIndex / (maxX * maxY);
        actualIndex -= (locationZ * maxX * maxY);
        uint256 locationY = actualIndex / maxX;
        uint256 locationX = actualIndex % maxX;
        return (uint32(locationX + 1), uint32(locationY + 1), uint32(locationZ + 1));
    }

    function metadata() public override view returns (ICanvasMetadata memory) {
        ICanvasMetadata memory _metadata = ICanvasMetadata(address(this), name(), kind(), width(), height(), depth());
        return _metadata;
    }

    function pixelMetadataList(uint256 offset, uint256 count) public override view returns (IPixel.IPixelMetadataPage memory) {
        _requireValidLocationIndex(offset);

        uint256 paginationLimit = _getPixelCanvasRegistry().paginationLimit();
        uint256 availableCount = count;
        if (count > paginationLimit) {
            availableCount = paginationLimit;
        }

        uint256 supply = width() * height() * depth();
        uint256 availableAmount = (supply + 1) - offset;
        if (availableAmount > availableCount) {
            availableAmount = availableCount;
        }

        IPixel.IPixelMetadata[] memory items = new IPixel.IPixelMetadata[](availableAmount);
        for (uint256 index = offset; index < offset + availableAmount; index += 1) {
            uint256 itemsIndex = index - offset;
            (uint32 locationX, uint32 locationY, uint32 locationZ) = locationFromIndex(index);
            (IPixel pixel, uint256 tokenId) = getPixel(locationX, locationY, locationZ);

            IPixel.IPixelMetadata memory _metadata;
            if (address(pixel) != address(0)) {
                _metadata = pixel.metadata(tokenId);
            } else {
                _metadata = IPixel.IPixelMetadata(address(0), 0, address(0), "", 0, metadata(), locationX, locationY, locationZ);
            }
            items[itemsIndex] = _metadata;
        }
        return IPixel.IPixelMetadataPage(offset, availableAmount, supply, items);
    }

    //Private

    function _requireCanModify(PixelData memory pixel) internal view {
        require(canModify(pixel.pixelContract, pixel.tokenId), "Only pixel token owner can perform modification");
    }

    function _requireValidLocation(LocationData memory location) internal view {
        bool valid = ((location.locationX > 0) && (location.locationX <= width()) && (location.locationY > 0) && (location.locationY <= height()) && (location.locationZ > 0) && (location.locationZ <= depth()));
        require(valid, "Locaction is outside the canvas");
    }

    function _requireThisCanvas(PixelData memory pixel) internal view {
        require(pixel.pixelContract.getCanvas(pixel.tokenId) != ICanvas(address(0)), "Pixel is not attached");
        require(pixel.pixelContract.getCanvas(pixel.tokenId) == ICanvas(this), "Pixel is in another canvas");
    }

    function _requireValidPixel(IPixel pixelContract, uint256 tokenId) internal view {
        bool hasPixel = _privateDeployRegistry.has(PixelCanvasApplicationType.PIXEL, address(pixelContract));
        require(hasPixel, "Not a pixel");
        require((tokenId > 0), "Invalid tokenId");
    }

    function _requireValueForOperation(uint256 value, string memory operation) private view {
        require(value >= _getPixelCanvasRegistry().getCost(address(this), operation), "Not enough value");
    }

    function _requireValidLocationIndex(uint256 index) internal view {
        bool valid = ((index > 0) && (index <= (width() * height() * depth())));
        require(valid, "Locaction index must me in [1 : (width * height * depth)]");
    }

    function pixelHash(PixelData memory pixel) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(address(pixel.pixelContract), Strings.toString(pixel.tokenId)));
    }

    function locationHash(LocationData memory location) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(Strings.toString(location.locationX), Strings.toString(location.locationY), Strings.toString(location.locationZ)));
    }

    function stringsEqual(string memory string1, string memory string2) private pure returns (bool) {
        return (keccak256(abi.encodePacked(string1)) == keccak256(abi.encodePacked(string2)));
    }

    function _getPixelCanvasRegistry() private view returns (IPixelCanvasRegistry) {
        address contractAddress = _privateDeployRegistry.get(PixelCanvasApplicationType.REGISTRY, 0);
        require(contractAddress != address(0), "PixelCanvasRegistry not configured");
        return IPixelCanvasRegistry(contractAddress);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IPixel.sol";

interface ICanvas {

    struct ICanvasMetadata {
        address contractAddress;

        string name;
        string kind;
        uint32 width;
        uint32 height;
        uint32 depth;
    }

    function name() external view returns (string memory);

    function kind() external view returns (string memory);

    function width() external view returns (uint32);

    function height() external view returns (uint32);

    function depth() external view returns (uint32);

    function canModify(IPixel pixelContract, uint256 tokenId) external view returns (bool);

    function getLocation(IPixel pixelContract, uint256 tokenId) external view returns (bool, uint32, uint32, uint32);

    function getPixel(uint32 locationX, uint32 locationY, uint32 locationZ) external view returns (IPixel, uint256);

    function setPixel(IPixel pixelContract, uint256 tokenId, uint32 locationX, uint32 locationY, uint32 locationZ) external payable;

    function removePixel(IPixel pixelContract, uint256 tokenId) external payable;

    function locationIndex(uint32 locationX, uint32 locationY, uint32 locationZ) external view returns (uint256);

    function locationFromIndex(uint256 index) external view returns (uint32, uint32, uint32);

    function metadata() external view returns (ICanvasMetadata memory);

    function pixelMetadataList(uint256 offset, uint256 count) external view returns (IPixel.IPixelMetadataPage memory);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDeployRegistry {
    
    function list(uint256 _type) external view returns (address[] memory);

    function get(uint256 _type, uint256 _index) external view returns (address);

    function length(uint256 _type) external view returns (uint256);

    function has(uint256 _type, address _address) external view returns (bool);

    function add(uint256 _type, address _address) external returns (bool);

    function remove(uint256 _type, address _address) external returns (bool);

    function clear(uint256 _type) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPixelCanvasRegistry {

    struct Option {
        address pixelContract;
        uint256 amount;
    }

    //Common

    function proxyRegistry() external view returns (address);

    //Paging

    function paginationLimit() external view returns (uint256);

    function updatePaginationLimit(uint256 limit) external;

    //Costs

    function getCost(address _address, string memory operation) external view returns (uint256);

    function updateCost(address _address, string memory operation, uint256 cost) external;

    // Pixel Supply
    
    function getPixelSupply(address _address) external view returns (uint256);

    function updatePixelSupply(address _address, uint256 supply) external;

    //Options

    function getNumberOfOptions() external view returns (uint256);

    function getOptionsIdentifiers() external view returns (uint256[] memory);

    function getOption(uint256 optionId) external view returns (Option memory);

    function hasOption(uint256 optionId) external view returns (bool);

    function updateOption(uint256 optionId, address pixelAddress, uint256 amount) external;

    //Payments

    function paymentsAmount() external view returns (uint256);

    function paymentsDeposit() external payable;

    function paymentsWithdraw(address payable recepient, uint256 amountLimit) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library PixelCanvasApplicationType {
    
    uint256 constant REGISTRY = 0;
    uint256 constant PIXEL = 1;
    uint256 constant CANVAS = 2;
    uint256 constant FACTORY = 3;

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

pragma solidity ^0.8.0;

import "./ICanvas.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IPixel is IERC721 {

    struct IPixelMetadata {
        address contractAddress;
        uint256 tokenId;
        address tokenOwner;
        
        string pixelType;
        uint32 color;

        ICanvas.ICanvasMetadata cavasMetadata;

        uint32 locationX;
        uint32 locationY;
        uint32 locationZ;
    }

    struct IPixelMetadataPage {
        uint256 offset;
        uint256 count;
        uint256 total;
        IPixelMetadata[] items;
    }

    function pixelType() external view returns (string memory);

    function canModify(uint256 tokenId) external view returns (bool);

    function getDefaultColor() external pure returns (uint32);

    function getCanvas(uint256 tokenId) external view returns (ICanvas);

    function setCanvas(uint256 tokenId, ICanvas canvasContract) external payable;

    function getColor(uint256 tokenId) external view returns (uint32);

    function setColor(uint256 tokenId, uint32 color) external payable;

    function metadata(uint256 tokenId) external view returns (IPixelMetadata memory);

    function metadataList(uint256 offset, uint256 count) external view returns (IPixelMetadataPage memory);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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