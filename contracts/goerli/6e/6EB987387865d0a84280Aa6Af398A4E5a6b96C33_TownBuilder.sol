// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "OwnableOrApproved.sol";
import "ITownBuilder.sol";
import "ILand.sol";
import "ITown.sol";
import "IBuilding.sol";
import "ITownsLandCoin.sol";

contract TownBuilder is OwnableOrApproved, ITownBuilder {
    event BuildingAdded(
        uint256 indexed eventId,
        address indexed newOwner,
        uint256 indexed townTokenId,
        uint256 townType,
        uint256 townSize,
        uint256[] townBuildings,
        uint256 buildingTokenId,
        uint256 amountOfNew
    );

    modifier onlyLand() {
        require(_msgSender() == address(_land));
        _;
    }

    modifier onlyBuildingOrTown() {
        require(
            _msgSender() == address(_building) ||
                _msgSender() == address(_uniqueBuilding) ||
                _msgSender() == address(_town)
        );
        _;
    }

    ILand private _land;
    ITown private _town;
    IBuilding private _building;
    IBuilding private _uniqueBuilding;
    ITownsLandCoin private _townsLandCoin;

    uint256 private _buildingAddedEventId;

    // readonly variables that only change during minting
    mapping(uint256 => uint256) private _townIdToTownSize;

    // variables that participate in town construction and can be updated
    mapping(uint256 => uint256[]) private _townIdToConstructedBuildings;
    mapping(address => mapping(uint256 => uint256)) // owner -> type -> town Id
        private _townsUnderConstruction;
    mapping(address => mapping(uint256 => uint256[]))
        private _ownersToTypesToTownIds;
    mapping(uint256 => bool) private _isTownFinished;

    mapping(address => uint256[]) private _buildingOwnersWaitingPool;

    function initialize(
        address landAddress,
        address townAddress,
        address buildingAddress,
        address uniqueBuildingAddress,
        address townsLandCoin
    ) external onlyOwner {
        _land = ILand(landAddress);
        _town = ITown(townAddress);
        _building = IBuilding(buildingAddress);
        _uniqueBuilding = IBuilding(uniqueBuildingAddress);
        _townsLandCoin = ITownsLandCoin(townsLandCoin);
    }

    function approveAccount(address newApprovedAccount) external onlyOwner {
        _approveAccount(newApprovedAccount);
        _land.approveAccount(newApprovedAccount);
        _building.approveAccount(newApprovedAccount);
        _uniqueBuilding.approveAccount(newApprovedAccount);
        _town.approveAccount(newApprovedAccount);
        _townsLandCoin.approveAccount(newApprovedAccount);
    }

    function revokeAccount(address approvedAccount) external onlyOwner {
        _revokeAccount(approvedAccount);
        _land.revokeAccount(approvedAccount);
        _building.revokeAccount(approvedAccount);
        _uniqueBuilding.revokeAccount(approvedAccount);
        _town.revokeAccount(approvedAccount);
        _townsLandCoin.revokeAccount(approvedAccount);
    }

    function mintBonus(address account, uint256 amountWei)
        external
        onlyBuildingOrTown
    {
        _townsLandCoin.mintBonus(account, amountWei);
    }

    function burnBonus(address account, uint256 amountWei)
        external
        onlyBuildingOrTown
    {
        _townsLandCoin.burnBonus(account, amountWei);
    }

    function mintTown(
        address newOwner,
        uint256 townType,
        uint256 townSize,
        string calldata relativeTokenUri
    ) external onlyLand {
        uint256 townId = _town.mint(newOwner, townType, relativeTokenUri);

        _ownersToTypesToTownIds[newOwner][townType].push(townId);
        _townIdToTownSize[townId] = townSize;
        _refreshWaitingPool(newOwner);
    }

    function moveTownToNewOwner(
        address from,
        address to,
        uint256 townId,
        uint256 townType
    ) external onlyBuildingOrTown {
        if (_townsUnderConstruction[from][townType] == townId) {
            _townsUnderConstruction[from][townType] = 0;
        }
        if (_townsUnderConstruction[to][townType] == 0) {
            _townsUnderConstruction[to][townType] = townId;
        }

        _updateOwnersToTypesToTownsAfterTransfer(from, to, townId, townType);
        _refreshWaitingPool(to);
    }

    function addBuildingIfPossible(
        address prevOwner,
        address newOwner,
        uint256 buildingTokenId,
        uint256 amount,
        uint256 supportedTownType
    ) external onlyBuildingOrTown {
        _clearWaitingPool(prevOwner, buildingTokenId, amount);
        _addBuildingIfPossible(
            newOwner,
            buildingTokenId,
            amount,
            supportedTownType
        );
    }

    function _clearWaitingPool(
        address prevOwner,
        uint256 buildingTokenId,
        uint256 amount
    ) private onlyBuildingOrTown {
        uint256 buildingsToClear = amount;

        uint256[] memory currentPoolBuildings = _buildingOwnersWaitingPool[
            prevOwner
        ];
        if (currentPoolBuildings.length == 0) {
            return;
        }

        delete _buildingOwnersWaitingPool[prevOwner];

        for (uint256 i = 0; i < currentPoolBuildings.length; i++) {
            uint256 poolBuildingId = currentPoolBuildings[i];

            if (poolBuildingId == buildingTokenId && buildingsToClear > 0) {
                buildingsToClear--;
            } else {
                _buildingOwnersWaitingPool[prevOwner].push(poolBuildingId);
            }
        }
    }

    function _addBuildingIfPossible(
        address newOwner,
        uint256 buildingTokenId,
        uint256 amount,
        uint256 supportedTownType
    ) private onlyBuildingOrTown {
        uint256 amountLeftToBuild = amount;

        uint256 townId = _townsUnderConstruction[newOwner][supportedTownType];
        if (townId != 0) {
            amountLeftToBuild = _tryAddBuildings(
                newOwner,
                townId,
                supportedTownType,
                buildingTokenId,
                amountLeftToBuild
            );

            if (amountLeftToBuild == 0) {
                return;
            }
        }

        uint256[] memory ownedTowns = _ownersToTypesToTownIds[newOwner][
            supportedTownType
        ];
        for (
            uint256 townIndex = 0;
            townIndex < ownedTowns.length;
            townIndex++
        ) {
            townId = ownedTowns[townIndex];
            if (townId == 0 || _isTownFinished[townId]) {
                continue;
            }

            amountLeftToBuild = _tryAddBuildings(
                newOwner,
                townId,
                supportedTownType,
                buildingTokenId,
                amountLeftToBuild
            );

            if (amountLeftToBuild == 0) {
                return;
            }
        }

        _addBuildingsToWaitingPool(
            newOwner,
            buildingTokenId,
            amountLeftToBuild
        );
    }

    function _tryAddBuildings(
        address newOwner,
        uint256 townTokenId,
        uint256 townType,
        uint256 buildingTokenId,
        uint256 amountLeftToBuild
    ) private returns (uint256 leftToBuild) {
        uint256 amountToBuildNowInTown = 0;
        (amountToBuildNowInTown, amountLeftToBuild) = _tryBookEmptyCells(
            amountLeftToBuild,
            newOwner,
            townType,
            townTokenId
        );
        if (amountToBuildNowInTown == 0) {
            return amountLeftToBuild;
        }

        for (uint256 i = 0; i < amountToBuildNowInTown; i++) {
            _townIdToConstructedBuildings[townTokenId].push(buildingTokenId);
        }
        emit BuildingAdded(
            ++_buildingAddedEventId,
            newOwner,
            townTokenId,
            townType,
            _townIdToTownSize[townTokenId],
            _townIdToConstructedBuildings[townTokenId],
            buildingTokenId,
            amountToBuildNowInTown
        );

        _town.freeze(newOwner, townTokenId, amountToBuildNowInTown);
        _burnBuilding(newOwner, buildingTokenId, amountToBuildNowInTown);

        return amountLeftToBuild;
    }

    function _burnBuilding(
        address buildingOwner,
        uint256 buildingTokenId,
        uint256 amount
    ) private {
        if (_building.supportedTownType(buildingTokenId) != 0) {
            _building.burn(buildingOwner, buildingTokenId, amount);
        } else {
            _uniqueBuilding.burn(buildingOwner, buildingTokenId, amount);
        }
    }

    function _tryBookEmptyCells(
        uint256 amountLeftToBuild,
        address newOwner,
        uint256 townType,
        uint256 townId
    ) private returns (uint256 amountToBuildNowInTown, uint256 leftToBuild) {
        uint256 townMaxSize = _townIdToTownSize[townId];
        uint256[] memory constructedBuildings = _townIdToConstructedBuildings[
            townId
        ];
        uint256 emptyCells = townMaxSize - constructedBuildings.length;
        if (emptyCells > amountLeftToBuild) {
            _townsUnderConstruction[newOwner][townType] = townId;
            return (amountLeftToBuild, 0);
        } else {
            _townsUnderConstruction[newOwner][townType] = 0; // town fully constructed
            _isTownFinished[townId] = true;
            return (emptyCells, amountLeftToBuild - emptyCells);
        }
    }

    function _addBuildingsToWaitingPool(
        address newOwner,
        uint256 buildingTokenId,
        uint256 amount
    ) private {
        for (uint256 i = 0; i < amount; i++) {
            _buildingOwnersWaitingPool[newOwner].push(buildingTokenId);
        }
    }

    function _refreshWaitingPool(address townOwner) private {
        if (_isOwnerOrApproved(townOwner)) {
            // owner and approved accounts cannot participate in town building
            return;
        }

        uint256[] memory buildingTokens = _buildingOwnersWaitingPool[townOwner];
        delete _buildingOwnersWaitingPool[townOwner];

        for (uint256 i = 0; i < buildingTokens.length; i++) {
            uint256 buildingTokenId = buildingTokens[i];

            _addBuildingIfPossible(
                townOwner,
                buildingTokens[i],
                1,
                _resolveSupportedTownType(buildingTokenId)
            );
        }
    }

    function _resolveSupportedTownType(uint256 buildingTokenId)
        private
        view
        returns (uint256)
    {
        uint256 commonBuildingTownType = _building.supportedTownType(
            buildingTokenId
        );
        return
            commonBuildingTownType == 0
                ? _uniqueBuilding.supportedTownType(buildingTokenId)
                : commonBuildingTownType;
    }

    function _updateOwnersToTypesToTownsAfterTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 townType
    ) private {
        // find and remove tokenId from array of prev owner
        uint256[] memory prevOwnerTowns = _ownersToTypesToTownIds[from][
            townType
        ];
        uint256 prevOwnerTownsLength = prevOwnerTowns.length;
        for (uint256 i = 0; i < prevOwnerTownsLength; i++) {
            if (prevOwnerTowns[i] == tokenId) {
                prevOwnerTowns[i] = prevOwnerTowns[prevOwnerTownsLength - 1];
                break;
            }
        }
        _ownersToTypesToTownIds[from][townType] = prevOwnerTowns;
        _ownersToTypesToTownIds[from][townType].pop();

        // add tokenId to array of new owner
        _ownersToTypesToTownIds[to][townType].push(tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "Ownable.sol";

abstract contract OwnableOrApproved is Ownable {
    modifier onlyOwnerOrApproved() {
        require(_msgSender() == owner() || _approvedAccounts[_msgSender()]);
        _;
    }

    mapping(address => bool) private _approvedAccounts;

    function _isOwnerOrApproved(address account) internal view returns (bool) {
        return account == owner() || _approvedAccounts[account] == true;
    }

    function _approveAccount(address account) internal {
        _approvedAccounts[account] = true;
    }

    function _revokeAccount(address account) internal {
        _approvedAccounts[account] = false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ITownBuilder {
    function approveAccount(address newApprovedAccount) external;

    function revokeAccount(address approvedAccount) external;

    function mintTown(
        address newOwner,
        uint256 townType,
        uint256 townSize,
        string calldata relativeTokenUri
    ) external;

    function moveTownToNewOwner(
        address from,
        address to,
        uint256 townId,
        uint256 townType
    ) external;

    function addBuildingIfPossible(
        address prevOwner,
        address newOwner,
        uint256 buildingTokenId,
        uint256 amount,
        uint256 supportedTownType
    ) external;

    function mintBonus(address account, uint256 amountWei) external;

    function burnBonus(address account, uint256 amountWei) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ILand {
    function approveAccount(address newApprovedAccount) external;

    function revokeAccount(address approvedAccount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ITown {
    function approveAccount(address newApprovedAccount) external;

    function revokeAccount(address approvedAccount) external;

    function mint(
        address to,
        uint256 townType,
        string calldata relativeTokenUri
    ) external returns (uint256);

    function freeze(
        address owner,
        uint256 id,
        uint256 amountOfBuildings
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IBuilding {
    function approveAccount(address newApprovedAccount) external;

    function revokeAccount(address approvedAccount) external;

    function supportedTownType(uint256 tokenId) external view returns (uint256);

    function burn(
        address exOwner,
        uint256 id,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface ITownsLandCoin {
    function approveAccount(address newApprovedAccount) external;

    function revokeAccount(address approvedAccount) external;

    function mintBonus(address account, uint256 amountWei) external;

    function burnBonus(address account, uint256 amountWei) external;
}