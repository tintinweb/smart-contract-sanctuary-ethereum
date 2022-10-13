// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../libraries/LibPCOLicenseClaimer.sol";
import {ERC721Base, ERC721BaseInternal} from "@solidstate/contracts/token/ERC721/base/ERC721Base.sol";
import {ERC721Metadata} from "@solidstate/contracts/token/ERC721/metadata/ERC721Metadata.sol";
import {ERC721MetadataStorage} from "@solidstate/contracts/token/ERC721/metadata/ERC721MetadataStorage.sol";
import {ERC165} from "@solidstate/contracts/introspection/ERC165.sol";
import {IERC165} from "@solidstate/contracts/interfaces/IERC165.sol";
import {IERC721} from "@solidstate/contracts/interfaces/IERC721.sol";
import {ERC165Storage} from "@solidstate/contracts/introspection/ERC165Storage.sol";
import {OwnableStorage} from "@solidstate/contracts/access/ownable/OwnableStorage.sol";

contract PCOERC721Facet is ERC721Base, ERC721Metadata, ERC165 {
    using ERC165Storage for ERC165Storage.Layout;
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        require(
            msg.sender == OwnableStorage.layout().owner,
            "Ownable: sender must be owner"
        );
        _;
    }

    function initializeERC721(
        string memory name,
        string memory symbol,
        string memory baseURI
    ) external onlyOwner {
        ERC721MetadataStorage.Layout storage ls = ERC721MetadataStorage
            .layout();
        ls.name = name;
        ls.symbol = symbol;
        ls.baseURI = baseURI;

        ERC165Storage.layout().setSupportedInterface(
            type(IERC165).interfaceId,
            true
        );
        ERC165Storage.layout().setSupportedInterface(
            type(IERC721).interfaceId,
            true
        );
    }

    /// @dev Override _isApprovedOrOwner to include corresponding beacon proxy
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        override
        returns (bool)
    {
        LibPCOLicenseClaimer.DiamondStorage storage cs = LibPCOLicenseClaimer
            .diamondStorage();

        return
            super._isApprovedOrOwner(spender, tokenId) ||
            spender == cs.beaconProxies[tokenId];
    }

    /**
     * @inheritdoc ERC721BaseInternal
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721BaseInternal, ERC721Metadata) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./LibGeoWebParcel.sol";

library LibPCOLicenseClaimer {
    bytes32 private constant STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage.LibPCOLicenseClaimer");

    struct DiamondStorage {
        /// @notice start time of the genesis land parcel auction.
        uint256 auctionStart;
        /// @notice when the required bid amount reaches its minimum value.
        uint256 auctionEnd;
        /// @notice start price of the genesis land auction. Decreases to endingBid between auctionStart and auctionEnd.
        uint256 startingBid;
        /// @notice the final/minimum required bid reached and maintained at the end of the auction.
        uint256 endingBid;
        /// @notice The beacon contract for PCO licenses
        address beacon;
        /// @notice Beacon proxies for each license
        mapping(uint256 => address) beaconProxies;
        /// @notice User salts for deterministic proxy addresses
        mapping(address => uint256) userSalts;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }

    /**
     * @notice the current dutch auction price of a parcel.
     */
    function _requiredBid() internal view returns (uint256) {
        DiamondStorage storage ds = diamondStorage();
        if (block.timestamp > ds.auctionEnd) {
            return ds.endingBid;
        }

        uint256 timeElapsed = block.timestamp - ds.auctionStart;
        uint256 auctionDuration = ds.auctionEnd - ds.auctionStart;
        uint256 priceDecrease = (ds.startingBid * timeElapsed) /
            auctionDuration;
        return ds.startingBid - priceDecrease;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721 } from '../../../interfaces/IERC721.sol';
import { IERC721Receiver } from '../../../interfaces/IERC721Receiver.sol';
import { AddressUtils } from '../../../utils/AddressUtils.sol';
import { EnumerableMap } from '../../../utils/EnumerableMap.sol';
import { EnumerableSet } from '../../../utils/EnumerableSet.sol';
import { IERC721Base } from './IERC721Base.sol';
import { ERC721BaseStorage } from './ERC721BaseStorage.sol';
import { ERC721BaseInternal } from './ERC721BaseInternal.sol';

/**
 * @title Base ERC721 implementation, excluding optional extensions
 */
abstract contract ERC721Base is IERC721Base, ERC721BaseInternal {
    using AddressUtils for address;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @inheritdoc IERC721
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balanceOf(account);
    }

    /**
     * @inheritdoc IERC721
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        return _ownerOf(tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        return _getApproved(tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        returns (bool)
    {
        return _isApprovedForAll(account, operator);
    }

    /**
     * @inheritdoc IERC721
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable {
        _handleTransferMessageValue(from, to, tokenId, msg.value);
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            'ERC721: transfer caller is not owner or approved'
        );
        _transfer(from, to, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable {
        _handleTransferMessageValue(from, to, tokenId, msg.value);
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            'ERC721: transfer caller is not owner or approved'
        );
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @inheritdoc IERC721
     */
    function approve(address operator, uint256 tokenId) public payable {
        _handleApproveMessageValue(operator, tokenId, msg.value);
        address owner = ownerOf(tokenId);
        require(operator != owner, 'ERC721: approval to current owner');
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            'ERC721: approve caller is not owner nor approved for all'
        );
        _approve(operator, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function setApprovalForAll(address operator, bool status) public {
        require(operator != msg.sender, 'ERC721: approve to caller');
        ERC721BaseStorage.layout().operatorApprovals[msg.sender][
            operator
        ] = status;
        emit ApprovalForAll(msg.sender, operator, status);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from '../../../utils/UintUtils.sol';
import { ERC721BaseInternal, ERC721BaseStorage } from '../base/ERC721Base.sol';
import { ERC721MetadataStorage } from './ERC721MetadataStorage.sol';
import { ERC721MetadataInternal } from './ERC721MetadataInternal.sol';
import { IERC721Metadata } from './IERC721Metadata.sol';

/**
 * @title ERC721 metadata extensions
 */
abstract contract ERC721Metadata is IERC721Metadata, ERC721MetadataInternal {
    using ERC721BaseStorage for ERC721BaseStorage.Layout;
    using UintUtils for uint256;

    /**
     * @notice inheritdoc IERC721Metadata
     */
    function name() public view virtual returns (string memory) {
        return ERC721MetadataStorage.layout().name;
    }

    /**
     * @notice inheritdoc IERC721Metadata
     */
    function symbol() public view virtual returns (string memory) {
        return ERC721MetadataStorage.layout().symbol;
    }

    /**
     * @notice inheritdoc IERC721Metadata
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        require(
            ERC721BaseStorage.layout().exists(tokenId),
            'ERC721Metadata: URI query for nonexistent token'
        );

        ERC721MetadataStorage.Layout storage l = ERC721MetadataStorage.layout();

        string memory tokenIdURI = l.tokenURIs[tokenId];
        string memory baseURI = l.baseURI;

        if (bytes(baseURI).length == 0) {
            return tokenIdURI;
        } else if (bytes(tokenIdURI).length > 0) {
            return string(abi.encodePacked(baseURI, tokenIdURI));
        } else {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        }
    }

    /**
     * @inheritdoc ERC721MetadataInternal
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC721MetadataStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC721Metadata');

    struct Layout {
        string name;
        string symbol;
        string baseURI;
        mapping(uint256 => string) tokenURIs;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from '../interfaces/IERC165.sol';
import { ERC165Storage } from './ERC165Storage.sol';

/**
 * @title ERC165 implementation
 */
abstract contract ERC165 is IERC165 {
    using ERC165Storage for ERC165Storage.Layout;

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return ERC165Storage.layout().isSupportedInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from './IERC165.sol';
import { IERC721Internal } from './IERC721Internal.sol';

/**
 * @title ERC721 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721 is IERC721Internal, IERC165 {
    /**
     * @notice query the balance of given address
     * @return balance quantity of tokens held
     */
    function balanceOf(address account) external view returns (uint256 balance);

    /**
     * @notice query the owner of given token
     * @param tokenId token to query
     * @return owner token owner
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @notice transfer token between given addresses, without checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice grant approval to given account to spend token
     * @param operator address to be approved
     * @param tokenId token to approve
     */
    function approve(address operator, uint256 tokenId) external payable;

    /**
     * @notice get approval status for given token
     * @param tokenId token to query
     * @return operator address approved to spend token
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @notice grant approval to or revoke approval from given account to spend all tokens held by sender
     * @param operator address to be approved
     * @param status approval status
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return status whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool status);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC165Storage {
    struct Layout {
        mapping(bytes4 => bool) supportedInterfaces;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC165');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function isSupportedInterface(Layout storage l, bytes4 interfaceId)
        internal
        view
        returns (bool)
    {
        return l.supportedInterfaces[interfaceId];
    }

    function setSupportedInterface(
        Layout storage l,
        bytes4 interfaceId,
        bool status
    ) internal {
        require(interfaceId != 0xffffffff, 'ERC165: invalid interface id');
        l.supportedInterfaces[interfaceId] = status;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setOwner(Layout storage l, address owner) internal {
        l.owner = owner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./LibGeoWebCoordinate.sol";

library LibGeoWebParcel {
    using LibGeoWebCoordinate for uint64;
    using LibGeoWebCoordinatePath for uint256;

    bytes32 private constant STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage.LibGeoWebParcel");

    /// @dev Structure of a land parcel
    struct LandParcel {
        uint64 baseCoordinate;
        uint256[] path;
    }

    /// @dev Enum for different actions
    enum Action {
        Build,
        Destroy,
        Check
    }

    /// @dev Maxmium uint256 stored as a constant to use for masking
    uint256 private constant MAX_INT = 2**256 - 1;

    /// @notice Emitted when a parcel is built
    event ParcelBuilt(uint256 indexed _id);

    /// @notice Emitted when a parcel is destroyed
    event ParcelDestroyed(uint256 indexed _id);

    /// @notice Emitted when a parcel is modified
    event ParcelModified(uint256 indexed _id);

    struct DiamondStorage {
        /// @notice Stores which coordinates are available
        mapping(uint256 => mapping(uint256 => uint256)) availabilityIndex;
        /// @notice Stores which coordinates belong to a parcel
        mapping(uint256 => LandParcel) landParcels;
        /// @dev The next ID to assign to a parcel
        uint256 nextId;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }

    /**
     * @notice Build a new parcel. All coordinates along the path must be available. All coordinates are marked unavailable after creation.
     * @param baseCoordinate Base coordinate of new parcel
     * @param path Path of new parcel
     */
    function build(uint64 baseCoordinate, uint256[] memory path) internal {
        require(
            path.length > 0,
            "LibGeoWebParcel: Path must have at least one component"
        );

        DiamondStorage storage ds = diamondStorage();

        // Mark everything as available
        _updateAvailabilityIndex(Action.Build, baseCoordinate, path);

        LandParcel storage p = ds.landParcels[ds.nextId];
        p.baseCoordinate = baseCoordinate;
        p.path = path;

        emit ParcelBuilt(ds.nextId);

        ds.nextId += 1;
    }

    /**
     * @notice Destroy an existing parcel. All coordinates along the path are marked as available.
     * @param id ID of land parcel
     */
    function destroy(uint256 id) internal {
        DiamondStorage storage ds = diamondStorage();

        LandParcel storage p = ds.landParcels[id];

        _updateAvailabilityIndex(Action.Destroy, p.baseCoordinate, p.path);

        delete ds.landParcels[id];

        emit ParcelDestroyed(id);
    }

    /**
     * @notice The next ID to assign to a parcel
     */
    function nextId() internal view returns (uint256) {
        DiamondStorage storage ds = diamondStorage();
        return ds.nextId;
    }

    /// @dev Update availability index by traversing a path and marking everything as available or unavailable
    function _updateAvailabilityIndex(
        Action action,
        uint64 baseCoordinate,
        uint256[] memory path
    ) private {
        DiamondStorage storage ds = diamondStorage();

        uint64 currentCoord = baseCoordinate;

        uint256 pI = 0;
        uint256 currentPath = path[pI];

        (uint256 iX, uint256 iY, uint256 i) = currentCoord._toWordIndex();
        uint256 word = ds.availabilityIndex[iX][iY];

        do {
            if (action == Action.Build) {
                // Check if coordinate is available
                require(
                    (word & (2**i) == 0),
                    "LibGeoWebParcel: Coordinate is not available"
                );

                // Mark coordinate as unavailable in memory
                word = word | (2**i);
            } else if (action == Action.Destroy) {
                // Mark coordinate as available in memory
                word = word & ((2**i) ^ MAX_INT);
            }

            // Get next direction
            bool hasNext;
            uint256 direction;
            (hasNext, direction, currentPath) = currentPath._nextDirection();

            if (!hasNext) {
                // Try next path
                pI += 1;
                if (pI >= path.length) {
                    break;
                }
                currentPath = path[pI];
                (hasNext, direction, currentPath) = currentPath
                    ._nextDirection();
            }

            // Traverse to next coordinate
            uint256 newIX;
            uint256 newIY;
            (currentCoord, newIX, newIY, i) = currentCoord._traverse(
                direction,
                iX,
                iY,
                i
            );

            // If new coordinate is in new word
            if (newIX != iX || newIY != iY) {
                // Update word in storage
                ds.availabilityIndex[iX][iY] = word;

                // Advance to next word
                word = ds.availabilityIndex[newIX][newIY];
            }

            iX = newIX;
            iY = newIY;
        } while (true);

        // Update last word in storage
        ds.availabilityIndex[iX][iY] = word;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// @title LibGeoWebCoordinate is an unsigned 64-bit integer that contains x and y coordinates in the upper and lower 32 bits, respectively
library LibGeoWebCoordinate {
    // Fixed grid size is 2^23 longitude by 2^22 latitude
    uint64 public constant MAX_X = ((2**23) - 1);
    uint64 public constant MAX_Y = ((2**22) - 1);

    /// @notice Traverse a single direction
    /// @param origin The origin coordinate to start from
    /// @param direction The direction to take
    /// @return destination The destination coordinate
    function traverse(
        uint64 origin,
        uint256 direction,
        uint256 iX,
        uint256 iY,
        uint256 i
    )
        external
        pure
        returns (
            uint64,
            uint256,
            uint256,
            uint256
        )
    {
        return _traverse(origin, direction, iX, iY, i);
    }

    function _traverse(
        uint64 origin,
        uint256 direction,
        uint256 iX,
        uint256 iY,
        uint256 i
    )
        internal
        pure
        returns (
            uint64,
            uint256,
            uint256,
            uint256
        )
    {
        uint64 originX = _getX(origin);
        uint64 originY = _getY(origin);

        if (direction == 0) {
            // North
            originY += 1;
            require(originY <= MAX_Y, "Direction went too far north!");

            if (originY % 16 == 0) {
                iY += 1;
                i -= 240;
            } else {
                i += 16;
            }
        } else if (direction == 1) {
            // South
            require(originY > 0, "Direction went too far south!");
            originY -= 1;

            if (originY % 16 == 15) {
                iY -= 1;
                i += 240;
            } else {
                i -= 16;
            }
        } else if (direction == 2) {
            // East
            if (originX >= MAX_X) {
                // Wrap to west
                originX = 0;
                iX = 0;
                i -= 15;
            } else {
                originX += 1;
                if (originX % 16 == 0) {
                    iX += 1;
                    i -= 15;
                } else {
                    i += 1;
                }
            }
        } else if (direction == 3) {
            // West
            if (originX == 0) {
                // Wrap to east
                originX = MAX_X;
                iX = MAX_X / 16;
                i += 15;
            } else {
                originX -= 1;
                if (originX % 16 == 15) {
                    iX -= 1;
                    i += 15;
                } else {
                    i -= 1;
                }
            }
        }

        uint64 destination = (originY | (originX << 32));

        return (destination, iX, iY, i);
    }

    /// @notice Get the X coordinate
    function _getX(uint64 coord) internal pure returns (uint64 coordX) {
        coordX = (coord >> 32); // Take first 32 bits
        require(coordX <= MAX_X, "X coordinate is out of bounds");
    }

    /// @notice Get the Y coordinate
    function _getY(uint64 coord) internal pure returns (uint64 coordY) {
        coordY = (coord & ((2**32) - 1)); // Take last 32 bits
        require(coordY <= MAX_Y, "Y coordinate is out of bounds");
    }

    /// @notice Convert coordinate to word index
    function toWordIndex(uint64 coord)
        external
        pure
        returns (
            uint256 iX,
            uint256 iY,
            uint256 i
        )
    {
        return _toWordIndex(coord);
    }

    function _toWordIndex(uint64 coord)
        internal
        pure
        returns (
            uint256 iX,
            uint256 iY,
            uint256 i
        )
    {
        uint256 coordX = uint256(_getX(coord));
        uint256 coordY = uint256(_getY(coord));

        iX = coordX / 16;
        iY = coordY / 16;

        uint256 lX = coordX % 16;
        uint256 lY = coordY % 16;

        i = lY * 16 + lX;
    }
}

/// @notice LibGeoWebCoordinatePath stores a path of directions in a uint256. The most significant 8 bits encodes the length of the path
library LibGeoWebCoordinatePath {
    uint256 private constant INNER_PATH_MASK = (2**(256 - 8)) - 1;
    uint256 private constant PATH_SEGMENT_MASK = (2**2) - 1;

    /// @notice Get next direction from path
    /// @param path The path to get the direction from
    /// @return hasNext If the path has a next direction
    /// @return direction The next direction taken from path
    /// @return nextPath The next path with the direction popped from it
    function nextDirection(uint256 path)
        external
        pure
        returns (
            bool hasNext,
            uint256 direction,
            uint256 nextPath
        )
    {
        return _nextDirection(path);
    }

    function _nextDirection(uint256 path)
        internal
        pure
        returns (
            bool hasNext,
            uint256 direction,
            uint256 nextPath
        )
    {
        uint256 length = (path >> (256 - 8)); // Take most significant 8 bits
        hasNext = (length > 0);
        if (!hasNext) {
            return (hasNext, 0, 0);
        }
        uint256 _path = (path & INNER_PATH_MASK);

        direction = (_path & PATH_SEGMENT_MASK); // Take least significant 2 bits of path
        nextPath = (_path >> 2) | ((length - 1) << (256 - 8)); // Trim direction from path
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        require(success, 'AddressUtils: failed to send value');
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            'AddressUtils: insufficient balance for call'
        );
        return _functionCallWithValue(target, data, value, error);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        require(
            isContract(target),
            'AddressUtils: function call to non-contract'
        );

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Map implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableMap {
    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        MapEntry[] _entries;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct AddressToAddressMap {
        Map _inner;
    }

    struct UintToAddressMap {
        Map _inner;
    }

    function at(AddressToAddressMap storage map, uint256 index)
        internal
        view
        returns (address, address)
    {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        address addressKey;
        assembly {
            addressKey := mload(add(key, 20))
        }
        return (addressKey, address(uint160(uint256(value))));
    }

    function at(UintToAddressMap storage map, uint256 index)
        internal
        view
        returns (uint256, address)
    {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    function contains(AddressToAddressMap storage map, address key)
        internal
        view
        returns (bool)
    {
        return _contains(map._inner, bytes32(uint256(uint160(key))));
    }

    function contains(UintToAddressMap storage map, uint256 key)
        internal
        view
        returns (bool)
    {
        return _contains(map._inner, bytes32(key));
    }

    function length(AddressToAddressMap storage map)
        internal
        view
        returns (uint256)
    {
        return _length(map._inner);
    }

    function length(UintToAddressMap storage map)
        internal
        view
        returns (uint256)
    {
        return _length(map._inner);
    }

    function get(AddressToAddressMap storage map, address key)
        internal
        view
        returns (address)
    {
        return
            address(
                uint160(
                    uint256(_get(map._inner, bytes32(uint256(uint160(key)))))
                )
            );
    }

    function get(UintToAddressMap storage map, uint256 key)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    function set(
        AddressToAddressMap storage map,
        address key,
        address value
    ) internal returns (bool) {
        return
            _set(
                map._inner,
                bytes32(uint256(uint160(key))),
                bytes32(uint256(uint160(value)))
            );
    }

    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    function remove(AddressToAddressMap storage map, address key)
        internal
        returns (bool)
    {
        return _remove(map._inner, bytes32(uint256(uint160(key))));
    }

    function remove(UintToAddressMap storage map, uint256 key)
        internal
        returns (bool)
    {
        return _remove(map._inner, bytes32(key));
    }

    function _at(Map storage map, uint256 index)
        private
        view
        returns (bytes32, bytes32)
    {
        require(
            map._entries.length > index,
            'EnumerableMap: index out of bounds'
        );

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    function _contains(Map storage map, bytes32 key)
        private
        view
        returns (bool)
    {
        return map._indexes[key] != 0;
    }

    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, 'EnumerableMap: nonexistent key');
        unchecked {
            return map._entries[keyIndex - 1]._value;
        }
    }

    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {
            map._entries.push(MapEntry({ _key: key, _value: value }));
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            unchecked {
                map._entries[keyIndex - 1]._value = value;
            }
            return false;
        }
    }

    function _remove(Map storage map, bytes32 key) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {
            unchecked {
                MapEntry storage last = map._entries[map._entries.length - 1];

                // move last entry to now-vacant index
                map._entries[keyIndex - 1] = last;
                map._indexes[last._key] = keyIndex;
            }

            // clear last index
            map._entries.pop();
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, value);
    }

    function indexOf(AddressSet storage set, address value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(UintSet storage set, uint256 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            'EnumerableSet: index out of bounds'
        );
        return set._values[index];
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _indexOf(Set storage set, bytes32 value)
        private
        view
        returns (uint256)
    {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721 } from '../../../interfaces/IERC721.sol';

/**
 * @title ERC721 base interface
 */
interface IERC721Base is IERC721 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { EnumerableMap } from '../../../utils/EnumerableMap.sol';
import { EnumerableSet } from '../../../utils/EnumerableSet.sol';

library ERC721BaseStorage {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC721Base');

    struct Layout {
        EnumerableMap.UintToAddressMap tokenOwners;
        mapping(address => EnumerableSet.UintSet) holderTokens;
        mapping(uint256 => address) tokenApprovals;
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function exists(Layout storage l, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        return l.tokenOwners.contains(tokenId);
    }

    function totalSupply(Layout storage l) internal view returns (uint256) {
        return l.tokenOwners.length();
    }

    function tokenOfOwnerByIndex(
        Layout storage l,
        address owner,
        uint256 index
    ) internal view returns (uint256) {
        return l.holderTokens[owner].at(index);
    }

    function tokenByIndex(Layout storage l, uint256 index)
        internal
        view
        returns (uint256)
    {
        (uint256 tokenId, ) = l.tokenOwners.at(index);
        return tokenId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721Internal } from '../../../interfaces/IERC721Internal.sol';
import { IERC721Receiver } from '../../../interfaces/IERC721Receiver.sol';
import { AddressUtils } from '../../../utils/AddressUtils.sol';
import { EnumerableMap } from '../../../utils/EnumerableMap.sol';
import { EnumerableSet } from '../../../utils/EnumerableSet.sol';
import { ERC721BaseStorage } from './ERC721BaseStorage.sol';

/**
 * @title Base ERC721 internal functions
 */
abstract contract ERC721BaseInternal is IERC721Internal {
    using ERC721BaseStorage for ERC721BaseStorage.Layout;
    using AddressUtils for address;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using EnumerableSet for EnumerableSet.UintSet;

    function _balanceOf(address account)
        internal
        view
        virtual
        returns (uint256)
    {
        require(
            account != address(0),
            'ERC721: balance query for the zero address'
        );
        return ERC721BaseStorage.layout().holderTokens[account].length();
    }

    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        address owner = ERC721BaseStorage.layout().tokenOwners.get(tokenId);
        require(owner != address(0), 'ERC721: invalid owner');
        return owner;
    }

    function _getApproved(uint256 tokenId)
        internal
        view
        virtual
        returns (address)
    {
        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();

        require(
            l.exists(tokenId),
            'ERC721: approved query for nonexistent token'
        );

        return l.tokenApprovals[tokenId];
    }

    function _isApprovedForAll(address account, address operator)
        internal
        view
        virtual
        returns (bool)
    {
        return ERC721BaseStorage.layout().operatorApprovals[account][operator];
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            ERC721BaseStorage.layout().exists(tokenId),
            'ERC721: query for nonexistent token'
        );

        address owner = _ownerOf(tokenId);

        return (spender == owner ||
            _getApproved(tokenId) == spender ||
            _isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), 'ERC721: mint to the zero address');

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();

        require(!l.exists(tokenId), 'ERC721: token already minted');

        _beforeTokenTransfer(address(0), to, tokenId);

        l.holderTokens[to].add(tokenId);
        l.tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, '');
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            'ERC721: transfer to non ERC721Receiver implementer'
        );
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = _ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        _approve(address(0), tokenId);

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();
        l.holderTokens[owner].remove(tokenId);
        l.tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            _ownerOf(tokenId) == from,
            'ERC721: transfer of token that is not own'
        );
        require(to != address(0), 'ERC721: transfer to the zero address');

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();
        l.holderTokens[from].remove(tokenId);
        l.holderTokens[to].add(tokenId);
        l.tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            'ERC721: transfer to non ERC721Receiver implementer'
        );
    }

    function _approve(address operator, uint256 tokenId) internal virtual {
        ERC721BaseStorage.layout().tokenApprovals[tokenId] = operator;
        emit Approval(_ownerOf(tokenId), operator, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual returns (bool) {
        if (!to.isContract()) {
            return true;
        }

        bytes memory returnData = to.functionCall(
            abi.encodeWithSelector(
                IERC721Receiver(to).onERC721Received.selector,
                msg.sender,
                from,
                tokenId,
                data
            ),
            'ERC721: transfer to non ERC721Receiver implementer'
        );

        bytes4 returnValue = abi.decode(returnData, (bytes4));
        return returnValue == type(IERC721Receiver).interfaceId;
    }

    /**
     * @notice ERC721 hook, called before externally called approvals for processing of included message value
     * @param operator beneficiary of approval
     * @param tokenId id of transferred token
     * @param value message value
     */
    function _handleApproveMessageValue(
        address operator,
        uint256 tokenId,
        uint256 value
    ) internal virtual {}

    /**
     * @notice ERC721 hook, called before externally called transfers for processing of included message value
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId id of transferred token
     * @param value message value
     */
    function _handleTransferMessageValue(
        address from,
        address to,
        uint256 tokenId,
        uint256 value
    ) internal virtual {}

    /**
     * @notice ERC721 hook, called before all transfers including mint and burn
     * @dev function should be overridden and new implementation must call super
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId id of transferred token
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC721 interface needed by internal functions
 */
interface IERC721Internal {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed operator,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        require(value == 0, 'UintUtils: hex length insufficient');

        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ERC721BaseInternal } from '../base/ERC721Base.sol';
import { ERC721MetadataStorage } from './ERC721MetadataStorage.sol';

/**
 * @title ERC721Metadata internal functions
 */
abstract contract ERC721MetadataInternal is ERC721BaseInternal {
    /**
     * @notice ERC721 hook: clear per-token URI data on burn
     * @inheritdoc ERC721BaseInternal
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (to == address(0)) {
            delete ERC721MetadataStorage.layout().tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721Internal } from '../../../interfaces/IERC721Internal.sol';

/**
 * @title ERC721Metadata interface
 */
interface IERC721Metadata is IERC721Internal {
    /**
     * @notice get token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice get token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}