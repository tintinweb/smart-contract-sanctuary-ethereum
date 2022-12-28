//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/INFTType.sol";
import "./utils/Proxyable.sol";
import "./NFTTypeStats.sol";

contract GamificationBLL is Ownable, Proxyable, NFTTypeStats {
    using Strings for uint256;

    INFTType public nftContract;

    error InconsistenArrayLengths();

    constructor(address _nftContract) {
        if (_nftContract == address(0)) revert addressIsZero();
        nftContract = INFTType(_nftContract);
    }

    function getMultipleGroupPointsForAddress(
        address user,
        uint32[] memory groupIds
    ) external view returns (uint256 points) {
        for (uint x; x < groupIds.length; x++) {
            points += getGroupPointsForAddress(user, groupIds[x]);
        }
    }

    function getPointsForTokenID(uint32 nftID) external view returns (uint256) {
        uint32 nftType = nftContract.tokenIDToNFTType(nftID);
        return nftTypeToPoints[nftType];
    }

    function getPointsForTokenIDs(uint32[] calldata nftIDs)
        public
        view
        returns (uint256 points)
    {
        uint32[] memory nftTypes = nftContract.getNFTTypesForTokenIDs(nftIDs);
        for (uint x; x < nftTypes.length; x++) {
            points += nftTypeToPoints[nftTypes[x]];
        }
        return points;
    }

    // could run out of gas if user has a lot of NFTs
    // suggest getting token IDs off-chain and sending in batches through getPointsForTokenIDs
    function getPointsForUser(address user)
        external
        view
        returns (uint256 points)
    {
        uint32[] memory nftTypes = nftContract.getNFTTypesForTokenIDs(
            nftContract.getNFTTypesForUser(user)
        );
        for (uint x; x < nftTypes.length; x++) {
            points += nftTypeToPoints[nftTypes[x]];
        }
        return points;
    }

    function getStakingPointsForUser(address user)
        external
        view
        returns (uint256 points)
    {
        uint32[] memory nftTypes = nftContract.getNFTTypesForTokenIDs(
            nftContract.getNFTTypesForUser(user)
        );
        for (uint x; x < nftTypes.length; x++) {
            points += nftTypeToPoints[nftTypes[x]];
        }
        return points;
    }

    function setNFTContract(address value) external onlyOwner {
        if (value == address(0)) revert addressIsZero();
        nftContract = INFTType(value);
    }

    function getGroupPointsForAddress(address user, uint32 groupId)
        public
        view
        returns (uint256 points)
    {
        Group memory group = nftTypeGroups[groupId];
        points = nftContract.getNFTTypeCounts(user, group.nftTypes) >=
            group.nftCountRequiredForPoints
            ? group.points
            : 0;
    }

    function checkSeriesForTokenIDs(uint32 seriesId, uint32[] calldata tokenIds)
        public
        view
        returns (bool)
    {
        Series memory series = nftTypeSeries[seriesId];
        if (series.nftTypes.length != tokenIds.length)
            revert InconsistenArrayLengths();
        uint32[] memory nftTypes = nftContract.getNFTTypesForTokenIDs(tokenIds);
        for (uint x; x < nftTypes.length; x++) {
            if (nftTypes[x] != series.nftTypes[x]) return false;
        }
        return true;
    }

    function getPointsForSeries(uint32 seriesId, uint32[] calldata tokenIds)
        external
        view
        returns (uint256)
    {
        return
            checkSeriesForTokenIDs(seriesId, tokenIds)
                ? nftTypeSeries[seriesId].points
                : 0;
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface INFTType {
    // retrieve count of owned NFTs for a user for a specific NFT type
    function getNFTTypeCount(address account, uint32 nftType)
        external
        view
        returns (uint256);

    // retrieve count of owner NFTs for a user for multiple NFT types
    function getNFTTypeCounts(address account, uint32[] calldata nftTypes)
        external
        view
        returns (uint256 result);

    // returns specific tokenURI is one is assigned to the token
    // if not, then returns URI for NFT type using tokenBaseURI
    function tokenURI(uint256 tokenID) external view returns (string memory);

    function tokenIDToNFTType(uint32 tokenId) external view returns (uint32);

    function getNFTTypeForTokenID(uint32 tokenID)
        external
        view
        returns (uint32);

    function getNFTTypesForTokenIDs(uint32[] calldata tokenIDs)
        external
        view
        returns (uint32[] memory);

    function balanceOf(address owner) external view returns (uint256);

    function tokenOfOwnerByIndex(address account, uint256 index)
        external
        view
        returns (uint256);

    function getNFTTypesForUser(address user)
        external
        view
        returns (uint32[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Proxyable is Ownable {

    mapping(address => bool) public proxyToApproved; // proxy allowance for interaction with future contract

    modifier onlyProxy() {
        require(proxyToApproved[_msgSender()], "Only proxy");
        _;
    }

    function setProxyState(address proxyAddress, bool value) public onlyOwner {
        proxyToApproved[proxyAddress] = value;
    } 
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/INFTType.sol";

abstract contract NFTTypeStats is Ownable {
    using Strings for uint256;

    struct Group {
        string name;
        uint32[] nftTypes;
        uint points;
        uint nftCountRequiredForPoints;
    }

    struct Series {
        string name;
        uint32[] nftTypes;
        uint points;
    }

    uint32 public groupCount;
    uint32 public seriesCount;
    uint32 public attributeCount;
    mapping(uint32 => Group) public nftTypeGroups;
    mapping(uint32 => uint32) public nftTypeToPoints;
    mapping(uint32 => Series) public nftTypeSeries;

    error addressIsZero();
    error tooManyIDs(uint sent, uint max);
    error idOutOfBounds(uint sent, uint max);

    constructor() {}

    function addGroup(
        string calldata _name,
        uint32[] calldata _nftTypes,
        uint _points,
        uint _nftCountRequiredForPoints
    ) external onlyOwner {
        nftTypeGroups[groupCount] = Group({
            name: _name,
            nftTypes: _nftTypes,
            points: _points,
            nftCountRequiredForPoints: _nftCountRequiredForPoints
        });
        ++groupCount;
    }

    function editGroup(
        uint32 groupId,
        string calldata _name,
        uint32[] calldata _nftTypes,
        uint32 _points
    ) external onlyOwner {
        if (groupId >= groupCount)
            revert idOutOfBounds({sent: groupId, max: groupCount - 1});
        nftTypeGroups[groupId].name = _name;
        nftTypeGroups[groupId].nftTypes = _nftTypes;
        nftTypeGroups[groupId].points = _points;
    }

    function addSeries(
        string calldata _name,
        uint32[] calldata _nftTypes,
        uint _points
    ) external onlyOwner {
        nftTypeSeries[seriesCount] = Series({
            name: _name,
            nftTypes: _nftTypes,
            points: _points
        });
        ++seriesCount;
    }

    function editSeries(
        uint32 seriesId,
        string calldata _name,
        uint32[] calldata _nftTypes,
        uint32 _points
    ) external onlyOwner {
        if (seriesId >= seriesCount)
            revert idOutOfBounds({sent: seriesId, max: seriesCount - 1});
        nftTypeSeries[seriesId].name = _name;
        nftTypeSeries[seriesId].nftTypes = _nftTypes;
        nftTypeSeries[seriesId].points = _points;
    }

    function setNFTTypePoints(uint32 nftType, uint32 value) external onlyOwner {
        nftTypeToPoints[nftType] = value;
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