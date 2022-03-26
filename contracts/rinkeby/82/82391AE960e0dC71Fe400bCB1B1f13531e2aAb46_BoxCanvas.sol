// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./protocols/ICanvas.sol";
import "./PixelCanvasRegistry.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
    
    
contract BoxCanvas is ICanvas {

    struct LocationData {
        uint32 locationX;
        uint32 locationY;
        uint32 locationZ;
    }
    
    struct PixelData {
        IPixel pixelContract;
        uint256 tokenId;
    }

    string private _privateName;
    uint32 private _privateWidth;
    uint32 private _privateHeight;
    uint32 private _privateDepth;
    PixelCanvasRegistry private _privatePixelCanvasRegistry;

    mapping(bytes32 => LocationData) private _locationByPixel;
    mapping(bytes32 => PixelData) private _pixelByLocation;
    
    constructor(string memory _name, uint32 _width, uint32 _height, uint32 _depth, PixelCanvasRegistry _pixelCanvasRegistry) {
        _privateName = _name;
        _privateWidth = _width;
        _privateHeight = _height;
        _privateDepth = _depth;
        _privatePixelCanvasRegistry = _pixelCanvasRegistry;
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
        _requireValidPixel(pixelContract);

        return (pixelContract.ownerOf(tokenId) == msg.sender) || _privatePixelCanvasRegistry.hasPixel(IPixel(msg.sender));
    }

    function getLocation(IPixel pixelContract, uint256 tokenId) public override view returns (bool, uint32, uint32, uint32) {
        _requireValidPixel(pixelContract);

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

    function setPixel(IPixel pixelContract, uint256 tokenId, uint32 locationX, uint32 locationY, uint32 locationZ) public override {
        _requireValidPixel(pixelContract);

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
    }

    function removePixel(IPixel pixelContract, uint256 tokenId) public override {
        _requireValidPixel(pixelContract);
        
        PixelData memory pixel = PixelData(pixelContract, tokenId);
        _requireCanModify(pixel);
        _requireThisCanvas(pixel);
        bytes32 _pixelHash = pixelHash(pixel);

        LocationData memory location = _locationByPixel[_pixelHash];
        bytes32 _locationHash = locationHash(location);

        _locationByPixel[_pixelHash] = LocationData(0, 0, 0);
        _pixelByLocation[_locationHash] = PixelData(IPixel(address(0)), 0);

        if (!_privatePixelCanvasRegistry.hasPixel(IPixel(msg.sender))) {
            pixelContract.setCanvas(tokenId, ICanvas(address(0)));
        }
    }

    function pixelsAllocation(string memory pixelType) public override view returns (uint256) {
        if (stringsEqual(pixelType, "normal")) {
            return width() * height() * depth();
        } else {
            return 0;
        }
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

    function _requireValidPixel(IPixel pixelContract) internal view {
        require(_privatePixelCanvasRegistry.hasPixel(pixelContract), "Not a pixel");
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

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IPixel.sol";

interface ICanvas {

    function name() external view returns (string memory);

    function kind() external view returns (string memory);

    function width() external view returns (uint32);

    function height() external view returns (uint32);

    function depth() external view returns (uint32);

    function canModify(IPixel pixelContract, uint256 tokenId) external view returns (bool);

    function getLocation(IPixel pixelContract, uint256 tokenId) external view returns (bool, uint32, uint32, uint32);

    function getPixel(uint32 locationX, uint32 locationY, uint32 locationZ) external view returns (IPixel, uint256);

    function setPixel(IPixel pixelContract, uint256 tokenId, uint32 locationX, uint32 locationY, uint32 locationZ) external;

    function removePixel(IPixel pixelContract, uint256 tokenId) external;

    function pixelsAllocation(string memory pixelType) external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/AddressArray.sol";
import "./protocols/IPixel.sol";
import "./protocols/ICanvas.sol";
import "./protocols/IPixelCanvasRegistry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PixelCanvasRegistry is IPixelCanvasRegistry, Ownable {

    address[] private _privatePixels;
    address[] private _privateCanvases;

    function addPixel(IPixel pixel) override public onlyOwner returns (bool) {
        if (!hasPixel(pixel)) {
            _privatePixels.push(address(pixel));
            return true;
        } else {
            return false;
        }
    }

    function removePixel(IPixel pixel) override public onlyOwner returns (bool) {
        return AddressArray.removeValueFromArray(_privatePixels, address(pixel));
    }

    function hasPixel(IPixel pixel) override public view returns (bool) {
        return AddressArray.valueExistsInArray(_privatePixels, address(pixel));
    }

    function getPixels() public view returns (address[] memory) {
        return _privatePixels;
    }

    function addCanvas(ICanvas canvas) override public onlyOwner returns (bool) {
        if (!hasCanvas(canvas)) {
            _privateCanvases.push(address(canvas));
            return true;
        } else {
            return false;
        }
    }

    function removeCanvas(ICanvas canvas) override public onlyOwner returns (bool) {
        return AddressArray.removeValueFromArray(_privateCanvases, address(canvas));
    }

    function hasCanvas(ICanvas canvas) override public view returns (bool) {
        return AddressArray.valueExistsInArray(_privateCanvases, address(canvas));
    }

    function getCanvases() public view returns (address[] memory) {
        return _privateCanvases;
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

    function pixelType() external view returns (string memory);

    function canModify(uint256 tokenId) external view returns (bool);

    function getDefaultColor() external pure returns (uint32);

    function getCanvas(uint256 tokenId) external view returns (ICanvas);

    function setCanvas(uint256 tokenId, ICanvas canvasContract) external;

    function getColor(uint256 tokenId) external view returns (uint32);

    function setColor(uint256 tokenId, uint32 color) external;

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
pragma solidity ^0.8.0;


library AddressArray {

    function valueExistsInArray(address[] storage _array, address _value) internal view returns (bool) {
        return (indexOfValueInArray(_array, _value) < _array.length);
    }

    function indexOfValueInArray(address[] storage _array, address _value) internal view returns (uint256) {
        for (uint256 index = 0; index < _array.length; index++) {
            if (_array[index] == _value) {
                return index;
            }
        }
        return _array.length;
    }

    //Don't preserve order
    function removeValueByIndexFromArray(address[] storage _array, uint256 _index) internal {
        require(_index < _array.length, 'Index is out of bounds');
        _array[_index] = _array[_array.length - 1];
        _array.pop();
    }

    function removeValueFromArray(address[] storage _array, address _value) internal returns (bool) {
        uint256 index = indexOfValueInArray(_array, _value);
        if (index < _array.length) {
            removeValueByIndexFromArray(_array, index);
            return true;
        } else {
            return false;
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ICanvas.sol";
import "./IPixel.sol";

interface IPixelCanvasRegistry {

    function addPixel(IPixel pixel) external returns (bool);

    function removePixel(IPixel pixel) external returns (bool);

    function hasPixel(IPixel pixel) external view returns (bool);

    function addCanvas(ICanvas canvas) external returns (bool);

    function removeCanvas(ICanvas canvas) external returns (bool);

    function hasCanvas(ICanvas canvas) external view returns (bool);

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