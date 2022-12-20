// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./lib/env/SaleExceptions.sol";
import "./lib/dataHandlers/SaleDataHandler.sol";

/**
 * @dev Contract handling sales/mints of Metawin ERC1155 collectibles and
 * gifting rewards upon purchse.
 * Admin can create any number of bundles, each representing a set of tokens,
 * their price and availability, discount rules (if any) and rewards granted.
 * Rewards can include Metawin Competition tickets and/or credits for other
 * Metawin games.
 */
contract MetawinCollectibleRewardsSale is
    Context,
    Roles,
    Pausable,
    ReentrancyGuard,
    SaleExceptions,
    SaleDataHandler
{
    /**
     * @notice Purchase (mint).
     * @param bundleId Id of the bundle to be purchased
     */
    function buy(uint256 bundleId)
        external
        payable
        nonReentrant
        whenNotPaused
        onlyIfOnSale(bundleId)
        onlyIfInStock(bundleId)
        enforcePerAccountLimit(_msgSender(), bundleId)
    {
        // Checks
        require(
            msg.value >= _getBundlePrice(bundleId),
            "Price paid incorrect"
        );
        // Gather/process required bundle data
        uint256 tokenId;
        Reward memory rewardData;
        (tokenId, rewardData) = _getBundleMintAndReward(bundleId);
        // Check exceptions
        bool canFulfill;
        Case purchaseCase;
        (canFulfill, purchaseCase, rewardData) = _checkCase(
            _msgSender(),
            rewardData
        );
        // If an exception was detected, revert (or ensure rewarding actions will be skipped).
        _processCaseException(canFulfill, purchaseCase);
        // Perform actual sale operations
        _sendReward(_msgSender(), rewardData);
        _handleMint(_msgSender(), tokenId);
        emit Purchased(_msgSender(), bundleId, tokenId, rewardData);
    }

    /**
     * @notice Check if `account` would be able to buy the bundle `bundleId` and/or
     * an exception would be returned, and which rewards would be granted (if any).
     * @param account Account address
     * @param bundleId Id of the bundle
     * @return wouldSucceed True if the purchase transaction would be fulfilled, false if would revert
     * @return Case Reason or case scenario in which the purchase would succeed/revert
     * @return Reward Actual rewards that would be received (applicable only if "wouldSucceed" is true)
     */
    function testBuyExceptions(address account, uint256 bundleId)
        external
        view
        returns (
            bool wouldSucceed,
            Case,
            Reward memory
        )
    {
        Reward memory bundleReward = bundleInfo(bundleId).reward;
        return _checkCase(account, bundleReward);
    }

    /**
     * @notice [Admin] Transfer contract balance to the payout address.
     */
    function withdrawProceeds() external onlyRole(METAWIN_ROLE) whenNotPaused {
        _sendProceeds(address(this).balance);
    }

    /**
     * @dev Calls the mint functions of the linked ERC1155 contract.
     */
    function _handleMint(
        address to,
        uint256 id
    ) private {
        _nft().mint(to, id, 1);
    }

    /**
     * @dev Send reward to account.
     */
    function _sendReward(address account, Reward memory rewardData) private {
        if (rewardData.competitionEntries > 0) {
            ICompetition(rewardData.competitionContractAddress)
                .createFreeEntriesFromExternalContract({
                    _competitionId: rewardData.competitionId,
                    _amountOfEntries: rewardData.competitionEntries,
                    _player: account
                });
        }
        if (rewardData.credits > 0) {
            _meth().credit(account, rewardData.credits);
        }
    }

    /**
     * @dev Transfer funds to the payout address, reverts on payment error.
     */
    function _sendProceeds(uint256 amount) private {
        (bool paid, ) = payoutAddress.call{value: amount}("");
        if (!paid) revert PaymentError();
    }

    // PAUSE //

    /**
     * @dev [Admin] Pause the contract
     */
    function pauseContract() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev [Admin] Unpause the contract
     */
    function unpauseContract() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.17;

contract SimpleEnumerator {
    // List of existing Item IDs
    uint256[] private _allItems;
    // Mapping from Item ID to position in the _allItems array
    mapping(uint256 => uint256) private _allItemsIndex;

    /**
     * @dev Returns full list of existing itemIds.
     */
    function _getAllItems() internal view returns (uint256[] memory) {
        return _allItems;
    }

    /**
     * @dev Checks if an item is already present in the enumeration data structure.
     */
    function _existsInEnumeration(uint256 itemId) internal view returns(bool){
        uint256 index = _allItemsIndex[itemId];
        if(index < _allItems.length) return _allItems[index] == itemId;
        else return false;
    }

    /**
     * @dev Add an item to the enumeration data structure.
     * @param itemId uint256 ID of the item to be added to the items list
     */
    function _addToEnumeration(uint256 itemId) internal {
        _allItemsIndex[itemId] = _allItems.length;
        _allItems.push(itemId);
    }

    /**
     * @dev Remove an item from the enumeration data structure.
     * @param itemId uint256 ID of the item to be removed from the items list
     */
    function _removeFromEnumeration(uint256 itemId) internal {
        uint256 lastItemIndex = _allItems.length - 1;
        uint256 itemIndex = _allItemsIndex[itemId];
        uint256 lastItemId = _allItems[lastItemIndex];
        _allItems[itemIndex] = lastItemId; // Move the last item to the slot of the to-delete item
        _allItemsIndex[lastItemId] = itemIndex; // Update the moved item's index
        // Delete the contents at the last position of the array
        delete _allItemsIndex[itemId];
        _allItems.pop();
    }
}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.17;

/**
 * @dev Interface for {MethBalance} contract.
 */
interface IMeth {
    /**
     * @dev Increase `account` balance by `amount`.
     */
    function credit(address account, uint256 amount) external;

    /**
     * @dev Reduce `account` balance by `amount`.
     */
    function charge(address account, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.17;

/**
 * @dev Interface allowing to interact with the MetawinCollectibleRewards token contract.
 */
interface IMetawinCollectibleRewards {
    /**
     * @dev Mints one or more tokens with the same typeId.
     */
    function mint(
        address to,
        uint256 typeId,
        uint256 amount
    ) external;

    /**
     * @dev Mints one or more tokens with multiple typeIds.
     */
    function mintBatch(
        address to,
        uint256[] memory typeIds,
        uint256[] memory amount
    ) external;

    /**
     * @dev Returns only the balance of the unredeemed tokens.
     * Use {balanceOfRedeemed} for the redeemed tokens balance.
     */
    function balanceOf(address account, uint256 typeId)
        external
        returns (uint256);

    /**
     * @dev @dev Batch-operations[Batched] variant of {balanceOf}.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata typeIds)
        external
        returns (uint256[] memory);
}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.17;

/**
 * @dev Interface allowing to interact with the competition contract.
 */
interface ICompetition {
    /**
     * @dev Gets entries for a promo competition. Only callable by the minter contract.
     * Minter contract must have the "MINTERCONTRACT" role assigned in the competition contract.
     * @param _competitionId Id of the competition.
     * @param _amountOfEntries Amount of entries.
     * @param _player Address of the user.
     */
    function createFreeEntriesFromExternalContract(
        uint256 _competitionId,
        uint256 _amountOfEntries,
        address _player
    ) external;

    /**
     * @dev Check whether `_player` is blacklisted.
     * @param _player The address of the player
     */
    function playerIsBlacklisted(address _player) external view returns (bool);

    /**
     * @dev Check whether the competition `_raffleId` is NOT in "accepted" state.
     * @param _raffleId Id of the competition
     */
    function raffleNotInAcceptedState(uint256 _raffleId)
        external
        view
        returns (bool);

    /**
     * @dev Check whether `_player` is account which provided the competition prize.
     * @param _player Player address
     * @param _raffleId Id of the competition
     */
    function playerIsSeller(address _player, uint256 _raffleId)
        external
        view
        returns (bool);

    /**
     * @dev Check whether `_player` would reach the maximum amount of allowed competition entries.
     * @param _player Player address
     * @param _raffleId Id of the competition
     * @param _amountOfEntries Amount of entries being requested
     */
    function playerReachedMaxEntries(
        address _player,
        uint256 _raffleId,
        uint256 _amountOfEntries
    ) external view returns (bool);

    /**
     * @dev Only needed for competitions restricted to players owning specific NFT collections.
     * Check if `_player` owns the token `_tokenIdUsed` of the collection `_collection`, required
     * to enter the competition `_raffleId`, and makes sure that such a token has not been
     * already used to enter the same competiotion.
     * @param _player The address of the player
     * @param _raffleId id of the raffle
     * @param _collection Address of the required collection, if any
     * @param _tokenIdUsed Id of the token of the required collection the player says he has and want to use in the raffle
     * @return canBuy True if the player can buy
     * @return cause Cause of the rejection if "canBuy" is False
     */
    function playerHasRequiredNFTs(
        address _player,
        uint256 _raffleId,
        address _collection,
        uint256 _tokenIdUsed
    ) external view returns (bool canBuy, string memory cause);
}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.17;

contract Structs {

    /**
     * @dev Type difining a reward.
     */
    struct Reward {
        address competitionContractAddress; // Address of the competition contract
        uint256 competitionId; // Competition ID
        uint256 competitionEntries; // Amount of competition tickets
        uint256 credits; // Amount of Metawin credits
    }

    /**
     * @dev Defines a set of rules to restrict the access to a specific action.
     */
    struct RestrictionRules {
        uint256 expiry; // Expiry time (Unix timestamp) - never expires if set to zero
        bool active; // Active state
        bool limitedStock; // True if the amount of available items must be limited
        uint16 stock; // Amount of items in stock
        uint16 maxPerAccount; // Maximum purchases per user
    }

    /**
     * @dev Information about a sale; if either [not set], [restrictions.onSale == false] or
     * [restrictions.expiry < current time], the item is considered as NOT on sale.
     */
    struct SaleInfo {
        uint256 price; // Sale price
        RestrictionRules restrictions;
    }

    /**
     * @dev Information about a bundle of multiple items sold as a whole.
     * The two arrays `ids` and `amounts` MUST have the same length.
     */
    struct Bundle {
        uint256 tokenId; // Id of the token on sale
        SaleInfo saleInfo; // Check {SaleInfo} type
        Reward reward; // Check {Reward} type
        bytes32 hash; // Hash to identify a Bundle (can be either random or generated by hashing the bundle data)
    }

}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.17;

import "./Roles.sol";
import "./Structs.sol";
import "./SaleEnv.sol";

abstract contract SaleExceptions is Roles, Structs, SaleEnv {
    /**
     * @dev Type enumerating the possible purchase scenarios.
     */
    enum Case {
        allowed_withRewards,
        allowed_noRewards,
        allowed_noCompetition,
        allowed_noMeth,
        denied_competitionInNotAcceptedState,
        denied_notEligibleForReawrds
    }

    /**
     * @dev Type enumerating the possible behaviours when a buyer is not allowed to join a competition.
     */
    enum RewardlessPurchaseOption {
        denied, // Fully denied
        allowed_noCompetition, // Allowed, no competition but receiving METH
        allowed_noRewards, // Allowed, no rewards at all
        enum_max // Helper for enum max
    }

    // Global state to allow purchases even if the buyer won't receive competition entries.
    // 0: denied; 1: allowed, NO competition entries but receiving METH; 2 allowed, NO competition entries and NO METH
    RewardlessPurchaseOption private _currentRewardlessPurchaseOption;


    // EVENTS AND ERRORS

    // Event to be sent out when a purchase was carried out with an exception
    event PurchasedWithException(Case exception);
    // Error to be sent out when a purchase was denied (returns the reason)
    error PurchaseDenied(Case reason);


    // VISIBILE FUNCTIONS

    /**
     * @notice Check the contract behaviour when purchases are made by accounts not eligible
     * for competitions; check {RewardlessPurchaseOption} type.
     */
    function rewardlessPurchasesRule() external view returns (RewardlessPurchaseOption) {
        return _currentRewardlessPurchaseOption;
    }

    /**
     * @notice [Admin] Set the contract behaviour when purchases are made by accounts not
     * eligible for competitions; check {RewardlessPurchaseOption} type.
     */
    function setRewardlessPurchaseRule(uint256 option) external onlyRole(METAWIN_ROLE) {
        require(option < uint256(RewardlessPurchaseOption.enum_max), "Input out of range");
        _currentRewardlessPurchaseOption = RewardlessPurchaseOption(option);
    }


    // INTERNAL LOGICS

    /**
     * @dev Internal function to perform the appropriate action (either succeed,
     * succeed with an event detailing the exception, or revert) depeding on
     * the outcome of {_checkCase}.
     * @param purchaseAllowed Whether the purchase should take place or revert
     * @param caseDetected Case detected by _checkCase (check {Case} type for info).
     */
    function _processCaseException(bool purchaseAllowed, Case caseDetected) internal {
        if(purchaseAllowed){
            if(caseDetected==Case.allowed_withRewards) return;
            else{
                emit PurchasedWithException(caseDetected);
                return; // Not actually needed but better being explicit
            }
        }
        else revert PurchaseDenied(caseDetected);
    }

    /**
     * @dev Internal function to return whether `account` is allowed to purchase
     * a specific bundle, the reason/conditions (check {Case} type for info), and
     * the rewardData (updated depending on the detected case).
     * @param account Address of the user
     * @param rewardData Reward data from the purchased bundle
     */
    function _checkCase(address account, Reward memory rewardData)
        view
        internal
        returns(bool purchaseAllowed, Case, Reward memory)
    {
        ICompetition _comp = ICompetition(rewardData.competitionContractAddress);
        // If the bundle doesn't reward with competition entries, skip all following checks
        if(rewardData.competitionEntries == 0){
            return (true, Case.allowed_withRewards, rewardData);
        }
        // Everything below is executed only if the bundle should reward with competition entries
        // Purchases never allowed if the competition is not in accepted state
        if (_comp.raffleNotInAcceptedState(rewardData.competitionId)){
            return (false, Case.denied_competitionInNotAcceptedState, rewardData);
        }
        // If the player is blacklisted...
        if (_comp.playerIsBlacklisted(account)){
            rewardData.competitionEntries = 0;
            // ... and rewardless purchases are not allowed:
            if (_currentRewardlessPurchaseOption == RewardlessPurchaseOption.denied){
                return (false, Case.denied_notEligibleForReawrds, rewardData);
            }
            // ... but the purchase should still take place with no competition entries (and still reward METH):
            else if (_currentRewardlessPurchaseOption == RewardlessPurchaseOption.allowed_noCompetition){
                return (true, Case.allowed_noCompetition, rewardData);
            }
            // ... and the purchase should still take place with no rewards at all:
            else {
                rewardData.credits = 0;
                return (true, Case.allowed_noRewards, rewardData);
            }
        }
        // If the player is not blacklisted:
        else {
            return (true, Case.allowed_withRewards, rewardData);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.17;

import "./Roles.sol";
import "../interfaces/IMetawinCollectibleRewards.sol";
import "../interfaces/ICompetition.sol";
import "../interfaces/IMeth.sol";

contract SaleEnv is Roles{
    
    // Address of the NFT contract
    address public nftContract;
    // Address receiving payments
    address public payoutAddress;
    // Address of the Competition contract
    address public competitionContract;
    // Address of the Game Credits contract
    address public methContract;

    /**
     * @dev Failsafe: set Admin address as default payout.
     */
    constructor() {
        payoutAddress = msg.sender;
    }

    /**
     * @dev [Admin] Change the payout address.
     */
    function setPayoutAddress(address _newAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        payoutAddress = _newAddress;
    }

    /**
     * @dev [Admin] Store the NFT contract address.
     * @param _nftContract Address of the NFT contract
     */
    function setNftAddress(address _nftContract)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        nftContract = _nftContract;
    }

    /**
     * @dev [Admin] Store the Meth contract address.
     * @param _methContract Address of the Meth contract
     */
    function setMethAddress(address _methContract)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        methContract = _methContract;
    }

    /**
     * @dev [Admin] Store the competition contract address.
     * IMPORTANT: It only affects the new Bundles, changing it doesn't
     * automatically affect the existing Bundles.
     * @param _competitionContract Address of the competition contract
     */
    function setCompetitionAddress(address _competitionContract)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        competitionContract = _competitionContract;
    }

    /**
     * @dev Return NFT contract instance.
     */
    function _nft() internal view returns (IMetawinCollectibleRewards) {
        return IMetawinCollectibleRewards(nftContract);
    }

    /**
     * @dev Return Meth contract instance.
     */
    function _meth() internal view returns (IMeth) {
        return IMeth(methContract);
    }

}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

abstract contract Roles is AccessControlEnumerable {

    // Role for sale contracts
    bytes32 public constant MINTER_SALE_ROLE = keccak256("MINTER_SALE_ROLE");
    // Role for Metawin backend
    bytes32 public constant METAWIN_ROLE = keccak256("METAWIN_ROLE");

    /**
     * @dev Grants all roles to deployer by default.
     */
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_SALE_ROLE, _msgSender());
        _setupRole(METAWIN_ROLE, _msgSender());
    }

}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.17;

import "../env/Roles.sol";
import "../env/Structs.sol";
import "../env/SaleEnv.sol";
import "../utils/SimpleEnumerator.sol";
import "./SaleDataEvents.sol";

contract SaleDataHandler is
    Roles,
    Structs,
    SaleEnv,
    SaleDataEvents,
    SimpleEnumerator
{
    // Bundle ID => BundleData
    mapping(uint256 => Bundle) private _bundleInfo;
    // Bundle hash => (account => amount purchased)
    mapping(bytes32 => mapping(address => uint16)) private _purchased;


    // MODIFIERS //

    /**
     * @dev Enforces functions to run only if the input bundle is on sale.
     */
    modifier onlyIfOnSale(uint256 bundleId) {
        require(isOnSale(bundleId), "Bundle not on sale");
        _;
    }

    /**
     * @dev If the bundle has a limited stock, ensures the item's availability
     * and reduces the stock by one.
     */
    modifier onlyIfInStock(uint256 bundleId) {
        // Skip if the bundle has unlimited stock
        if (_bundleInfo[bundleId].saleInfo.restrictions.limitedStock) {
            require(
                _bundleInfo[bundleId].saleInfo.restrictions.stock != 0,
                "Out of stock"
            );
            _bundleInfo[bundleId].saleInfo.restrictions.stock -= 1;
        }
        _;
    }

    /**
     * @dev Ensures `account` doesnt buy more entries of bundle `bundleId` than
     * the maxPerAccount (defined in the bundle info). If maxPerAccount is zero,
     * the check is skipped and this modifier only updates the "purchased" count.
     */
    modifier enforcePerAccountLimit(address account, uint256 bundleId) {
        uint256 limit = _bundleInfo[bundleId]
            .saleInfo
            .restrictions
            .maxPerAccount;
        bytes32 hash = _bundleInfo[bundleId].hash;
        if (limit != 0) {
            uint256 purchased = _purchased[hash][account];
            if (!(purchased < limit)) {
                revert PurchaseLimitExceeded(1, purchased, limit);
            }
        }
        _purchased[hash][account]++;
        _;
    }


    // FUNCTIONS //

    /**
     * @dev Returns full list of existing bundleIds.
     */
    function bundlesList() external view returns (uint256[] memory) {
        return _getAllItems();
    }

    /**
     * @dev Returns full info about a bundle by specifying its id.
     */
    function bundleInfo(uint256 bundleId) public view returns (Bundle memory) {
        return _bundleInfo[bundleId];
    }

    /**
     * @dev Returns true if the bundle is currently on sale. Check {Structs-RestrictionRules} for more details.
     */
    function isOnSale(uint256 bundleId) public view returns (bool) {
        return
            _bundleInfo[bundleId].saleInfo.restrictions.active &&
            (_bundleInfo[bundleId].saleInfo.restrictions.expiry == 0 ||
                _bundleInfo[bundleId].saleInfo.restrictions.expiry >
                block.timestamp);
    }

    /**
     * @notice Returns the price of a specific bundle.
     */
    function getPrice(uint256 bundleId) external view returns (uint256) {
        return _bundleInfo[bundleId].saleInfo.price;
    }

    /**
     * @notice Return the amount of items of a bundle purchsed by `account`
     * @param bundleHash hash of the bundle; use {bundleInfo} to retreive it
     * from the bundle ID
     */
    function amountPurchased(bytes32 bundleHash, address account)
        external
        view
        returns (uint16)
    {
        return _purchased[bundleHash][account];
    }

    /**
     * @notice [Admin] Create/override a bundle.
     * When a bundle is created through this method, the current competition contract address (global variable
     * {SaleEnv-competitionContract}) is stored within the Bundle itself: this allows upgrading the
     * competition contract address without affecting the existing bundles; when the contract address is amended,
     * only new bundles will be affected by the change.
     * @param bundleId Id of the bundle; if a bundle with the same id exists, the method overrides its values
     * @param tokenId Id of the NFT included in the bundle
     * @param price Price to be paid in order to purchase the bundle
     * @param rewardCompetitionId CompetitionId joined when purchasing
     * @param rewardEntries Amount of entries received for the competitionId
     * @param rewardCredits Amount of METH received when purchasing
     * @param expiryTime Unix timestamp representing the bundle sale end; if set to zero, it never expires
     * @param maxPerAccount Purchase limit per address; if set to zero, it's unlimited
     * @param stockSize Specifies how many units of the bundle are available for sale (unlimited if set to zero)
     */
    function setupBundle(
        uint256 bundleId,
        uint256 tokenId,
        uint256 price,
        uint256 rewardCompetitionId,
        uint256 rewardEntries,
        uint256 rewardCredits,
        uint256 expiryTime,
        uint16 maxPerAccount,
        uint16 stockSize
    ) external onlyRole(METAWIN_ROLE) {
        _setupBundle(
            bundleId,
            tokenId,
            price,
            rewardCompetitionId,
            rewardEntries,
            rewardCredits,
            expiryTime,
            maxPerAccount,
            stockSize
        );
    }
    
    /**
     * @notice [Admin] Create/override multiple bundles at once; the input must be an array of arrays.
     * When a bundle is created through this method, the current competition contract address (global variable
     * {SaleEnv-competitionContract}) is stored within the Bundle itself: this allows upgrading the
     * competition contract address without affecting the existing bundles; when the contract address is amended,
     * only new bundles will be affected by the change.
     * @param data Array of arrayfied bundle data; each bundle consists of 9 array elements; the input order
     * is consistent to {setupBundle}.
     */
    function setupBundleMulti(
        uint256[9][] calldata data
    ) external onlyRole(METAWIN_ROLE) {
        for(uint i=0; i<data.length; ++i){
            _setupBundle(
                data[i][0],         // Bundle Id
                data[i][1],         // Token Id
                data[i][2],         // Price
                data[i][3],         // Competition Id
                data[i][4],         // Competition entries
                data[i][5],         // Reward credits
                data[i][6],         // Expiry time
                uint16(data[i][7]), // Max per account
                uint16(data[i][8])  // Stock size
            );
        }
    }

    /**
     * @notice [Admin] Enables/disables one or more bundles. Disabled bundles cannot be purchased.
     */
    function toggleBundles(uint256[] calldata bundleIds)
        external
        onlyRole(METAWIN_ROLE)
    {
        for (uint256 i = 0; i < bundleIds.length; ++i) {
            require(
                _existsInEnumeration(bundleIds[i]),
                "Toggling not-existent bundle"
            );
            bool newStatus = _bundleInfo[bundleIds[i]]
                .saleInfo
                .restrictions
                .active
                ? false
                : true;
            _bundleInfo[bundleIds[i]].saleInfo.restrictions.active = newStatus;
            emit BundleToggled(bundleIds[i], newStatus);
        }
    }

    /**
     * @notice [Admin] Deletes the specified bundle(s).
     */
    function deleteBundles(uint256[] calldata bundleIds)
        external
        onlyRole(METAWIN_ROLE)
    {
        for (uint256 i = 0; i < bundleIds.length; ++i) {
            require(
                _existsInEnumeration(bundleIds[i]),
                "Deleting non-existent bundle"
            );
            _removeFromEnumeration(bundleIds[i]);
            delete _bundleInfo[bundleIds[i]];
            emit BundleDeleted(bundleIds[i]);
        }
    }

    /**
     * @dev Private function providing the internal logics to create/override a bundle.
     * Check {setupBundle} for more info.
     */
    function _setupBundle(
        uint256 bundleId,
        uint256 tokenId,
        uint256 price,
        uint256 rewardCompetitionId,
        uint256 rewardEntries,
        uint256 rewardCredits,
        uint256 expiryTime,
        uint16 maxPerAccount,
        uint16 stockSize
    ) private {
        // A cheaper random hash (rather than the hash of the full bundle data) is enough with this implementation
        bytes32 hash = keccak256(abi.encode(block.timestamp, bundleId, price));
        // Assemble Bundle data
        Bundle memory bundleData = Bundle(
                                            tokenId,
            SaleInfo(
                                            price,
                RestrictionRules({
                    expiry:                 expiryTime,
                    active:                 false,
                    limitedStock:           stockSize > 0,
                    stock:                  stockSize,
                    maxPerAccount:          maxPerAccount
                })
            ),
            Reward({
                competitionContractAddress: competitionContract,
                competitionId:              rewardCompetitionId,
                competitionEntries:         rewardEntries,
                credits:                    rewardCredits
            }),
                                            hash
        );
        // Save on storage
        _bundleInfo[bundleId] = bundleData;
        // Enumeration
        if (!_existsInEnumeration(bundleId)) _addToEnumeration(bundleId);
        // Event
        emit BundleSet(bundleId, bundleData);
    }

    /**
     * @dev Internal function to get the mint and reward data from a bundle.
     */
    function _getBundleMintAndReward(uint256 bundleId)
        internal
        view
        returns (uint256, Reward storage)
    {
        return (_bundleInfo[bundleId].tokenId, _bundleInfo[bundleId].reward);
    }

    /**
     * @dev Internal function to get the price of a bundle.
     */
    function _getBundlePrice(uint256 bundleId) internal view returns (uint256) {
        return _bundleInfo[bundleId].saleInfo.price;
    }
}

// SPDX-License-Identifier: UNLICENSED
/// @author: Valerio Di Napoli

pragma solidity ^0.8.17;

import "../env/Structs.sol";

contract SaleDataEvents is Structs{

    // SALE SETUP
    
    /**
     * @dev Emitted when a Bundle is created/amended.
     */
    event BundleSet(uint256 indexed bundleId, Bundle indexed bundle);
    /**
     * @dev Emitted when a Bundle is enabled/disabled.
     */
    event BundleToggled(uint256 indexed bundleId, bool indexed status);
    /**
     * @dev Emitted when a Bundle is deleted.
     */
    event BundleDeleted(uint256 indexed bundleId);
    /**
     * @dev Emitted when a Discount Rule is created/amended.
     */

    // SALES

    /**
     * @dev Event emitted after each purchase.
     */
    event Purchased(
        address indexed account,
        uint256 indexed bundleId,
        uint256 nftMinted,
        Reward rewardsIssued
    );
    /**
     * @dev Raised at payment failure.
     */
    error PaymentError();
    /**
     * @dev Raised if an account attempts to purchase more items than its limit
     */
    error PurchaseLimitExceeded(uint256 requested, uint256 pastPurchases, uint256 limit);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}