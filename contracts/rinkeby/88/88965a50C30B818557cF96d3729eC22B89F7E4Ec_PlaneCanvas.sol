// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BoxCanvas.sol";
    
    
contract PlaneCanvas is BoxCanvas {
    
    constructor(string memory _name, uint32 _width, uint32 _height, PixelCanvasRegistry _pixelCanvasRegistry) BoxCanvas(_name, _width, _height, 1, _pixelCanvasRegistry) {
        //Nothing
    }

    //ICanvas

    function kind() override public pure returns (string memory) {
        return "plane";
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./protocols/ICanvas.sol";
import "./PixelCanvasRegistry.sol";

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

        return (pixelContract.ownerOf(tokenId) == _msgSender()) || _privatePixelCanvasRegistry.hasPixel(IPixel(_msgSender()));
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

    function setPixel(IPixel pixelContract, uint256 tokenId, uint32 locationX, uint32 locationY, uint32 locationZ) public override payable {
        _requireValueForOperation(msg.value, CONST_OPERATION_SET_PIXEL);
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
        emit EventSetPixel(pixelContract, tokenId, locationX, locationY, locationZ);

        _privatePixelCanvasRegistry.paymentsDeposit{value: msg.value}();
    }

    function removePixel(IPixel pixelContract, uint256 tokenId) public override payable {
        _requireValueForOperation(msg.value, CONST_OPERATION_REMOVE_PIXEL);
        _requireValidPixel(pixelContract);
        
        PixelData memory pixel = PixelData(pixelContract, tokenId);
        _requireCanModify(pixel);
        _requireThisCanvas(pixel);
        bytes32 _pixelHash = pixelHash(pixel);

        LocationData memory location = _locationByPixel[_pixelHash];
        bytes32 _locationHash = locationHash(location);

        _locationByPixel[_pixelHash] = LocationData(0, 0, 0);
        _pixelByLocation[_locationHash] = PixelData(IPixel(address(0)), 0);
        emit EventRemovePixel(pixelContract, tokenId);

        if (!_privatePixelCanvasRegistry.hasPixel(IPixel(_msgSender()))) {
            pixelContract.setCanvas(tokenId, ICanvas(address(0)));
        }

        _privatePixelCanvasRegistry.paymentsDeposit{value: msg.value}();
    }

    function pixelsAllocation(string memory pixelType) public override view returns (uint256) {
        if (stringsEqual(pixelType, "normal")) {
            return width() * height() * depth();
        } else {
            return 0;
        }
    }

    function metadata() public override view returns (ICanvasMetadata memory) {
        ICanvasMetadata memory _metadata = ICanvasMetadata(address(this), name(), kind(), width(), height(), depth());
        return _metadata;
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

    function _requireValueForOperation(uint256 value, string memory operation) private view {
        require(value >= _privatePixelCanvasRegistry.getCost(address(this), operation), "Not enough value");
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

    function pixelsAllocation(string memory pixelType) external view returns (uint256);

    function metadata() external view returns (ICanvasMetadata memory);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/AddressArray.sol";
import "./protocols/IPixel.sol";
import "./protocols/ICanvas.sol";
import "./protocols/IPixelCanvasRegistry.sol";
import "./PixelCanvasVault.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PixelCanvasRegistry is IPixelCanvasRegistry, Ownable {

    event EventAddPixel(
        IPixel indexed pixel
    );

    event EventRemovePixel(
        IPixel indexed pixel
    );

    event EventAddCanvas(
        ICanvas indexed cavas
    );

    event EventRemoveCanvas(
        ICanvas indexed cavas
    );

    event EventUpdateCost(
        string indexed operarrion,
        uint256 cost
    );

    PixelCanvasVault private immutable _privateVault;
    address[] private _privatePixels;
    address[] private _privateCanvases;
    mapping(address => mapping(string => uint256)) private _privateCosts;

    constructor() {
        _privateVault = new PixelCanvasVault();
    }

    //Pixeles and canvase

    function addPixel(IPixel pixel) override public onlyOwner returns (bool) {
        if (!hasPixel(pixel)) {
            _privatePixels.push(address(pixel));
            emit EventAddPixel(pixel);
            return true;
        } else {
            return false;
        }
    }

    function removePixel(IPixel pixel) override public onlyOwner returns (bool) {
        bool success = AddressArray.removeValueFromArray(_privatePixels, address(pixel));
        if (success) {
            emit EventRemovePixel(pixel);
        }
        return success;
    }

    function hasPixel(IPixel pixel) override public view returns (bool) {
        return AddressArray.valueExistsInArray(_privatePixels, address(pixel));
    }

    function getPixels() override public view returns (address[] memory) {
        return _privatePixels;
    }

    function addCanvas(ICanvas canvas) override public onlyOwner returns (bool) {
        if (!hasCanvas(canvas)) {
            _privateCanvases.push(address(canvas));
            emit EventAddCanvas(canvas);
            return true;
        } else {
            return false;
        }
    }

    function removeCanvas(ICanvas canvas) override public onlyOwner returns (bool) {
        bool success = AddressArray.removeValueFromArray(_privateCanvases, address(canvas));
        if (success) {
            emit EventRemoveCanvas(canvas);
        }
        return success;
    }

    function hasCanvas(ICanvas canvas) override public view returns (bool) {
        return AddressArray.valueExistsInArray(_privateCanvases, address(canvas));
    }

    function getCanvases() override public view returns (address[] memory) {
        return _privateCanvases;
    }

    //Costs

    function getCost(address _address, string memory operation) override public view returns (uint256) {
        return _privateCosts[_address][operation];
    }

    function updateCost(address _address, string memory operation, uint256 cost) override public onlyOwner {
        _privateCosts[_address][operation] = cost;
        emit EventUpdateCost(operation, cost);
    }

    //Payments

    function paymentsAmount() override public view onlyOwner returns (uint256) {
        return _privateVault.amount();
    }

    function paymentsDeposit() override public payable {
        return _privateVault.deposit{value: msg.value}();
    }

    function paymentsWithdraw(address payable recepient) override public onlyOwner {
        _privateVault.withdraw(recepient);
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

pragma solidity ^0.8.0;

import "./ICanvas.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IPixel is IERC721 {

    struct IPixelMetadata {
        address contractAddress;
        uint256 tokenId;
        
        string pixelType;
        uint32 color;

        ICanvas.ICanvasMetadata cavasMetadata;

        uint32 locationX;
        uint32 locationY;
        uint32 locationZ;
    }

    function pixelType() external view returns (string memory);

    function canModify(uint256 tokenId) external view returns (bool);

    function getDefaultColor() external pure returns (uint32);

    function getCanvas(uint256 tokenId) external view returns (ICanvas);

    function setCanvas(uint256 tokenId, ICanvas canvasContract) external payable;

    function getColor(uint256 tokenId) external view returns (uint32);

    function setColor(uint256 tokenId, uint32 color) external payable;

    function metadata(uint256 tokenId) external view returns (IPixelMetadata memory);

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

    function getPixels() external view returns (address[] memory);

    function addCanvas(ICanvas canvas) external returns (bool);

    function removeCanvas(ICanvas canvas) external returns (bool);

    function hasCanvas(ICanvas canvas) external view returns (bool);

    function getCanvases() external view returns (address[] memory);

    //Costs

    function getCost(address _address, string memory operation) external view returns (uint256);

    function updateCost(address _address, string memory operation, uint256 cost) external;

    //Payments

    function paymentsAmount() external view returns (uint256);

    function paymentsDeposit() external payable;

    function paymentsWithdraw(address payable recepient) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
openzeppelin-contracts/contracts/utils/escrow/Escrow.sol
*/
 
contract PixelCanvasVault is Ownable {
    using Address for address payable;

    event Deposited(uint256 weiAmount);
    event Withdrawn(uint256 weiAmount);

    uint256 private _amount;

    function amount() public view onlyOwner returns (uint256) {
        return _amount;
    }

    function deposit() public payable onlyOwner {
        uint256 payment = msg.value;
        _amount += payment;
        emit Deposited(payment);
    }

    function withdraw(address payable recepient) public onlyOwner {
        uint256 payment = _amount;
        _amount = 0;
        recepient.sendValue(payment);
        emit Withdrawn(payment);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
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