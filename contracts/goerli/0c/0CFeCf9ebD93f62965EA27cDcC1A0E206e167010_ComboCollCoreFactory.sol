// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./ComboCollCore.sol";
import "./interfaces/IComboCollCoreFactory.sol";

contract ComboCollCoreFactory is IComboCollCoreFactory {
    address public immutable proxyRegistryAddress;
    address public immutable comboCollFactory;
    address public immutable agent;
    address public immutable accounting;
    address public immutable comboCollProxy;

    constructor(
        address proxyRegistryAddress_,
        address comboCollFactory_,
        address agent_,
        address accounting_,
        address comboCollProxy_
    ) {
        if (
            proxyRegistryAddress_ == address(0) ||
            comboCollFactory_ == address(0) ||
            agent_ == address(0) ||
            accounting_ == address(0) ||
            comboCollProxy_ == address(0)
        ) {
            revert ZeroAddress();
        }
        proxyRegistryAddress = proxyRegistryAddress_;
        comboCollFactory = comboCollFactory_;
        agent = agent_;
        accounting = accounting_;
        comboCollProxy = comboCollProxy_;
    }

    function deploy(IComboCoreStructs.ConstructorParams calldata params)
        external
        override
        returns (address)
    {
        if (msg.sender != comboCollFactory) {
            revert CallerNotAllowed();
        }

        if (
            bytes(params.name).length == 0 ||
            bytes(params.symbol).length == 0 ||
            bytes(params.contractURIPath).length == 0
        ) {
            revert EmptyStringParam();
        }

        ComboCollCore combo = new ComboCollCore(
            params,
            agent,
            accounting,
            comboCollProxy,
            proxyRegistryAddress
        );
        combo.transferOwnership(IAccounting(accounting).getCollectionOwner());
        emit ComboCollCoreDeployed(address(combo));
        return address(combo);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../interfaces/base/IComboCoreStructs.sol";
import "../interfaces/base/ICollectionType.sol";
import "../interfaces/base/IComboReceipt.sol";

library ComboParamsValidator {
    error UnknownSet(uint256 id);       // 0xe21ee9e0
    error UnknownCollection(address coll);   // 0xd053b7de
    error UnexpectedCollectionOrder();  // 0x777dc214
    error UnexpectedTokenOrder();       // 0xe3bc761b
    error DuplicateERC721Tokens();      // 0x553b2df9
    error NoEnoughERC1155Balance();     // 0x6a5449b4
    error ZeroAmount();                 // 0x1f2a2005
    error TooFewItems();                // 0xf24f8e86
    error ExceedSetLimit();             // 0x84b31c68
    error ExceedCollLimit();            // 0xb79f1bd3

    struct Rules {
        address[]  _collections;
        // collection => collection Factor
        mapping(address => IComboCoreStructs.Factor) _collectionFactors;

        uint64[] _sets;
        // set id => set Factor
        mapping(uint64 => IComboCoreStructs.Factor) _setFactors;

        IComboCoreStructs.Limit[] _limits;
        // collection address => max usage times for each token
        mapping(address => uint256) _maxTokenUsages;
    }

    struct BoundaryCounter {
        uint256 _collTail;
        address[] _colls; // must be added in non-descending order
        uint256[] _collCounts;
        uint64[] _setIds; // must be in non-descending order
        uint256[] _setCounts;

        address[][] _collsForSet;
        uint256[] _collsForSetLengths;
    }

    struct UsageCounter {
        uint256 _totalCount;
        address[] _colls;
        uint256[] _counts;
        uint256 _totalAmount;
        uint256 _tailTokenId;
        uint256 _tailTokenAmount;

        uint256 _lockCollCount;
        address _lastLockColl;
        uint256[] _lockTokenCounts; // size = Ingredients.collections.length

        uint256 _unlockCollCount;
        address _lastUnlockColl;
        uint256[] _unlockTokenCounts; // size = Ingredients.collections.length
    }

    struct ValidateResult {
        IComboReceipt.ComboReceipt receipt;
        UsageCounter usageCounter; // TODO: for testing purpose
    }

    function initRules(
        Rules storage rules,
        IComboCoreStructs.ComboRules calldata comboRules
    ) external {
        uint256 i;
        for (i = 0; i < comboRules.factors.length; ++i) {
            if (comboRules.factors[i].collection != address(0)) {
                rules._collections.push(comboRules.factors[i].collection);
                rules._collectionFactors[comboRules.factors[i].collection] = comboRules.factors[i];
            } else {
                rules._sets.push(comboRules.factors[i].setId);
                rules._setFactors[comboRules.factors[i].setId] = comboRules.factors[i];
            }
        }

        for (i = 0; i < comboRules.limits.length; ++i) {
            rules._maxTokenUsages[comboRules.limits[i].collection] = comboRules.limits[i].maxTokenUsage;
            rules._limits.push(comboRules.limits[i]);
        }
    }

    function toComboRules(Rules storage rules) external view returns (IComboCoreStructs.ComboRules memory comboRules) {
        comboRules.limits = rules._limits;
        comboRules.factors = new IComboCoreStructs.Factor[](rules._collections.length + rules._sets.length);
        uint256 index;
        for (uint256 i = 0; i < rules._collections.length; ++i) {
            comboRules.factors[index] = rules._collectionFactors[
                rules._collections[i]
            ];
            ++index;
        }
        for (uint256 i = 0; i < rules._sets.length; ++i) {
            comboRules.factors[index] = rules._setFactors[rules._sets[i]];
            ++index;
        }
    }

    function validate(
        IComboCoreStructs.ComboParams calldata comboParams,
        bool[][] calldata isLockForItems,
        Rules storage rules
    )
        external
        view
        returns (ValidateResult memory result)
    {
        result.usageCounter = _countUsage(comboParams, isLockForItems);
        BoundaryCounter memory boundaryCounter = _countBoundary(rules, comboParams.ingredients);

        result.receipt = _makeReceipt(result.usageCounter, isLockForItems, comboParams);

        result.receipt.sets = rules._sets;
        result.receipt.collsForSet = new address[][](rules._sets.length);
        for (uint256 i = 0; i < rules._sets.length;) {
            result.receipt.collsForSet[i] = new address[](boundaryCounter._collsForSetLengths[i]);
            for (uint256 j = 0; j < boundaryCounter._collsForSetLengths[i];) {
                result.receipt.collsForSet[i][j] = boundaryCounter._collsForSet[i][j];
                unchecked { ++j; }
            }
            unchecked { ++i; }
        }
    }

    function _countUsage(
        IComboCoreStructs.ComboParams calldata comboParams,
        bool[][] calldata isLockForItems
    ) 
        internal
        pure
        returns (UsageCounter memory counter) {
        
        IComboCoreStructs.Ingredients calldata ingredients = comboParams.ingredients;
        uint256 size = ingredients.collections.length;

        counter._colls = new address[](size);
        counter._counts = new uint256[](size);
        counter._lockTokenCounts = new uint256[](size);
        counter._unlockTokenCounts = new uint256[](size);
        
        for (uint256 i = 0; i < size;) {
            address tokenAddress = ingredients.collections[i];
            // 1/5 check all collections are unique and sorted in ascending order
            if (i > 0 && cmp(tokenAddress, ingredients.collections[i - 1]) <= 0) {
                revert UnexpectedCollectionOrder();
            }
            counter._colls[i] = tokenAddress;
            bool isNotERC1155 = comboParams.collectionTypes[i] != ICollectionType.CollectionType.ERC1155;
            
            uint256 endJ = ingredients.itemsForCollections[i].length;
            for (uint256 j = 0; j < endJ;) {
                uint256 tokenId = ingredients.itemsForCollections[i][j];
                uint256 tokenAmount = ingredients.amountsForItems[i][j];
                if (tokenAmount == 0) {
                    revert ZeroAmount();
                }
                // 2/5 check all tokens are sorted in non-descending order
                if (j > 0 && tokenId < ingredients.itemsForCollections[i][j - 1]) {
                    revert UnexpectedTokenOrder();
                }

                // count cumulative amount
                counter._totalAmount += tokenAmount;

                if (j == 0 || counter._tailTokenId < tokenId) {
                    counter._tailTokenId = tokenId;
                    counter._tailTokenAmount = 0;

                    ++counter._totalCount; // plus only one, whether ERC721 or ERC1155
                    ++counter._counts[i];
                }
                counter._tailTokenAmount += tokenAmount;

                if (isNotERC1155) {
                    // 3/5 check no ERC-721 token are used twice
                    if (counter._tailTokenAmount > 1) {
                        revert DuplicateERC721Tokens();
                    }
                } else {
                    if (j == endJ - 1 || tokenId != ingredients.itemsForCollections[i][j + 1]) {
                        // 4/5 check balance for ERC-1155 tokens
                        if (comboParams.userBalancesFor1155Items[i][j] < counter._tailTokenAmount) {
                            revert NoEnoughERC1155Balance();
                        }
                    }
                }

                // 5/5 count lock or not
                if (isLockForItems[i][j]) {
                    if (tokenAddress != counter._lastLockColl) {
                        ++counter._lockCollCount;
                        counter._lastLockColl = tokenAddress;
                    }
                    ++counter._lockTokenCounts[counter._lockCollCount - 1];
                } else if (isNotERC1155) {
                    if (tokenAddress != counter._lastUnlockColl) {
                        ++counter._unlockCollCount;
                        counter._lastUnlockColl = tokenAddress;
                    }
                    ++counter._unlockTokenCounts[counter._unlockCollCount - 1];
                }
            
                unchecked { ++j; }
            }

            unchecked { ++i; }
        }
        if (counter._totalAmount < 2) {
            revert TooFewItems();
        }
    }

    function _countBoundary(
        Rules storage rules,
        IComboCoreStructs.Ingredients calldata ingredients
    ) 
        internal
        view
        returns (BoundaryCounter memory counter) {

        counter._colls = rules._collections;
        counter._collCounts = new uint256[](rules._collections.length);
        counter._setIds = rules._sets;
        uint256 size = rules._sets.length;
        counter._setCounts = new uint256[](size);
        counter._collsForSet = new address[][](size);
        counter._collsForSetLengths = new uint256[](size);

        uint256 i;
        for (i = 0; i < ingredients.collections.length;) {
            address tokenAddress = ingredients.collections[i];

            uint256 endJ = ingredients.itemsForCollections[i].length;
            for (uint256 j = 0; j < endJ;) {
                uint256 tokenAmount = ingredients.amountsForItems[i][j];
                uint256 setId = ingredients.setsForItems[i][j];
                if (setId == 0) {
                    if (counter._colls.length == 0) {
                        revert UnknownCollection(tokenAddress);
                    }
                    while (true) {
                        if (counter._colls[counter._collTail] == tokenAddress) {
                            counter._collCounts[counter._collTail] += tokenAmount;
                            break;
                        }
                        if (cmp(counter._colls[counter._collTail], tokenAddress) < 0 && counter._collTail < counter._colls.length - 1) {
                            ++counter._collTail;
                        } else {
                            revert UnknownCollection(tokenAddress);
                        }
                    }
                } else {
                    if (counter._setIds.length == 0) {
                        revert UnknownSet(setId);
                    }
                    uint256 low = 0;
                    uint256 high = counter._setIds.length;

                    while (low < high) {
                        uint256 mid = Math.average(low, high);

                        // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
                        // because Math.average rounds down (it does integer division with truncation).
                        if (counter._setIds[mid] > setId) {
                            high = mid;
                        } else {
                            low = mid + 1;
                        }
                    }

                    // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
                    if (low > 0) {
                        --low;
                    }
                    if (counter._setIds[low] == setId) {
                        counter._setCounts[low] += tokenAmount;

                        if (counter._collsForSet[low].length == 0) {
                            counter._collsForSet[low] = new address[](ingredients.collections.length);
                        }
                        if (
                            counter._collsForSetLengths[low] == 0 ||
                            counter._collsForSet[low][counter._collsForSetLengths[low] - 1] != tokenAddress
                        ) {
                            ++counter._collsForSetLengths[low];
                            counter._collsForSet[low][counter._collsForSetLengths[low] - 1] = tokenAddress;
                        }
                    } else {
                        revert UnknownSet(setId);
                    }
                }   

                unchecked { ++j; }   
            }
            unchecked { ++i; }
        }
        // check boundary
        for (i = 0; i < counter._setIds.length;) {
            IComboCoreStructs.Factor storage factor = rules._setFactors[counter._setIds[i]];
            if (factor.setId == 0 || counter._setCounts[i] < factor.min || counter._setCounts[i] > factor.max) {
                revert ExceedSetLimit();
            }
            unchecked {++i;}
        }
        for (i = 0; i < counter._colls.length;) {
            IComboCoreStructs.Factor storage factor = rules._collectionFactors[counter._colls[i]];
            if (factor.collection == address(0) || counter._collCounts[i] < factor.min || counter._collCounts[i] > factor.max) {
                revert ExceedCollLimit();
            }
            unchecked {++i;}
        }
    }

    function _makeReceipt(
        UsageCounter memory counter,
        bool[][] calldata isLockForItems,
        IComboCoreStructs.ComboParams calldata comboParams
    ) internal pure returns (IComboReceipt.ComboReceipt memory receipt) 
    {
        receipt.usedTotalCount = counter._totalCount;
        receipt.usedColls = counter._colls;
        receipt.usedCollCounts = counter._counts;

        uint256 i;
        uint256 size = counter._lockCollCount;
        if (size > 0) {
            receipt.lockColls = new address[](size);
            receipt.lockCollTypes = new ICollectionType.CollectionType[](size);
            receipt.lockTokenIds = new uint256[][](size);
            receipt.lockTokenAmounts = new uint256[][](size);
            receipt.lockUUIDs = new uint256[][](size);
            for (i = 0; i < size;) {
                receipt.lockTokenIds[i] = new uint256[](counter._lockTokenCounts[i]);
                receipt.lockTokenAmounts[i] = new uint256[](counter._lockTokenCounts[i]);
                receipt.lockUUIDs[i] = new uint256[](counter._lockTokenCounts[i]);
                unchecked {++i;}
            }
        }

        size = counter._unlockCollCount;
        if (size > 0) {
            receipt.unlockColls = new address[](size);
            receipt.unlockTokenIds = new uint256[][](size);
            receipt.unlockUUIDs = new uint256[][](size);
            for (i = 0; i < size;) {
                receipt.unlockTokenIds[i] = new uint256[](counter._unlockTokenCounts[i]);
                receipt.unlockUUIDs[i] = new uint256[](counter._unlockTokenCounts[i]);
                unchecked {++i;}
            }
        }

        uint256 indexLockColl;
        uint256 indexLockToken;
        uint256 indexUnlockColl;
        uint256 indexUnlockToken;

        IComboCoreStructs.Ingredients calldata ingredients = comboParams.ingredients;
        size = ingredients.collections.length;
        for (i = 0; i < size;) {
            address tokenAddress = ingredients.collections[i];
            bool isNotERC1155 = comboParams.collectionTypes[i] != ICollectionType.CollectionType.ERC1155;
            uint256 endJ = ingredients.itemsForCollections[i].length;
            for (uint256 j = 0; j < endJ;) {
                if (isLockForItems[i][j]) {
                    if (receipt.lockColls[indexLockColl] != tokenAddress) {
                        if (receipt.lockColls[indexLockColl] != address(0)) {
                            ++indexLockColl;
                        }
                        indexLockToken = 0;
                        receipt.lockColls[indexLockColl] = tokenAddress;
                        receipt.lockCollTypes[indexLockColl] = comboParams.collectionTypes[i];
                    }
                    receipt.lockTokenIds[indexLockColl][indexLockToken] = ingredients.itemsForCollections[i][j];
                    receipt.lockTokenAmounts[indexLockColl][indexLockToken] = ingredients.amountsForItems[i][j];
                    receipt.lockUUIDs[indexLockColl][indexLockToken] = comboParams.uuidForItems[i][j];
                    ++indexLockToken;
                } else if (isNotERC1155) {
                    if (receipt.unlockColls[indexUnlockColl] != tokenAddress) {
                        if (receipt.unlockColls[indexUnlockColl] != address(0)) {
                            ++indexUnlockColl;
                        }
                        indexUnlockToken = 0;
                        receipt.unlockColls[indexUnlockColl] = tokenAddress;
                    }
                    receipt.unlockTokenIds[indexUnlockColl][indexUnlockToken] = ingredients.itemsForCollections[i][j];
                    receipt.unlockUUIDs[indexUnlockColl][indexUnlockToken] = comboParams.uuidForItems[i][j];
                    ++indexUnlockToken;
                }
                unchecked {++j;}
            }
            unchecked {++i;}
        }
    }

    function cmp(address a, address b) internal pure returns (int8) {
        if (a == b) {
            return 0;
        }
        return uint160(a) > uint160(b) ? int8(1) : int8(-1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./ICollectionType.sol";

interface IComboReceipt is ICollectionType {

    struct ComboReceipt {
        uint256 comboId;
        bytes32 comboHash;

        uint256 usedTotalCount;
        address[] usedColls;
        uint256[] usedCollCounts;
        uint256[] addOnFees;

        address[] lockColls;    // ERC721 and ERC1155
        CollectionType[] lockCollTypes;
        uint256[][] lockTokenIds;
        uint256[][] lockTokenAmounts;
        uint256[][] lockUUIDs;

        address[] unlockColls; // only ERC721 (including Combo)
        uint256[][] unlockTokenIds;
        uint256[][] unlockUUIDs;

        uint64[] sets;
        address[][] collsForSet;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./ICollectionType.sol";


interface IComboCoreStructs is ICollectionType {

    struct Factor {
        uint128 max;
        uint128 min;
        // collection = address(0) indicates this is a factor for set and
        // Factor.setId must not be 0.
        address collection;
        // setId = 0 indicates this is a factor for non-set colection and 
        // Factor.collection must not be address(0).
        uint64 setId;
        bool lock;
    }

    struct Limit {
        address collection; // Only ERC721
        uint128 maxTokenUsage; // Max usage times for each token
    }

    struct ComboRules {
        Factor[] factors;
        Limit[] limits;
    }

    struct ConstructorParams {
        string name;
        string symbol;
        string contractURIPath;
        ComboRules comboRules;
    }

    // ============================ ComboMeta ============================
    struct Item {
        uint256 uuid;
        uint128 amount;
        uint64 setId;
        uint8 typ;
        bool lock;
        bool limit;
    }

    struct ComboMeta {
        // the one who created or edited this combo
        address creator;
        Item[] items;
    }

    // ============================ ComboParams ============================
    struct ComboParams {
        Ingredients ingredients;

        // For ingredients.collections
        CollectionType[] collectionTypes;

        // For ERC1155 collection, dup does not matter.
        uint256[][] userBalancesFor1155Items;

        uint256[][] uuidForItems;
        string hash;
    }

    struct Ingredients {
        address[] collections;    // sorted in ascending order. no dup.
        uint256[][] itemsForCollections; // sorted in ascending order. dup is only allowed for ERC-1155.
        uint128[][] amountsForItems;
        uint64[][] setsForItems;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface ICollectionType {
    enum CollectionType {
        UNDEFINED, // unused
        ERC721,
        ERC1155,
        COMBO
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./base/IComboCoreStructs.sol";

interface IComboCollCoreFactory {
    error ZeroAddress();        // 0xd92e233d
    error CallerNotAllowed();   // 0x2af07d20
    error EmptyStringParam();   // 0xcd308c86

    event ComboCollCoreDeployed(address combo);

    function deploy(IComboCoreStructs.ConstructorParams calldata params)
        external
        returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./base/IComboCoreStructs.sol";
import "./base/IComboReceipt.sol";

interface IComboCollCore is IComboCoreStructs, IComboReceipt {
    event Mint(address indexed who, uint256 indexed comboId, string metaHash, bytes32 comboHash);
    event Remint(address indexed who, uint256 indexed comboId, string metaHash, bytes32 comboHash);

    error CallerNotAllowed();       // 0x2af07d20
    error UnknownCollection(address collection);                        // 0xd053b7de
    error UnknownSet(uint256 setId);                                    // 0xe21ee9e0
    error ExceedTokenUsageLimit(address collection, uint256 tokenId);   // 0x4a9e44c8
    error NotComboOwner();                                              // 0x37021de8
    error ComboNotExists();                                             // 0x178832c0

    function mint(
        address caller,
        address to,
        ComboParams calldata params
    ) external returns (ComboReceipt memory);

    function remint(
        address caller,
        uint256 comboId,
        ComboParams calldata params
    ) external returns (ComboReceipt memory);

    function dismantle(address caller, uint256 comboId) external;

    function getComboRules() external view returns (ComboRules memory);

    /**
     * @dev Returns 0 if token is not limited
     */
    function getLimitedTokenUsages(uint256[] calldata uuids)
        external
        view
        returns (uint256[] memory);

    function comboMetasOf(uint256[] calldata comboIds)
        external
        view
        returns (ComboMeta[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface IAgent {
    enum AgentItemType {
        UNDEFINED, // unused
        ERC20,
        ERC721,
        ERC1155
    }

    error ZeroAddress(); // 0xd92e233d
    error EntranceClosed(); // 0x3118dcd6
    error InvalidAgentItemType(); // 0xcc05c803
    error OnlyOneAmountAllowed(); // 0x032cb2ed
    error CallerNotAllowed(); // 0x2af07d20
    error Reenter(); // 0xa1592b02

    struct AgentTransfer {
        AgentItemType itemType;
        address token;
        address from;
        address to;
        uint256 id;
        uint256 amount;
    }

    struct AgentTransferBatch {
        AgentItemType itemType;
        address token;
        address from;
        address to;
        uint256[] ids;
        uint256[] amounts;
    }

    struct AgentERC1155BatchTransfer {
        address token;
        address from;
        address to;
        uint256[] ids;
        uint256[] amounts;
    }

    function addEntrance(address entrance) external;

    function isApproved(address user, address operator)
        external
        view
        returns (bool);

    function executeTransfer(address user, AgentTransfer[] calldata transfers)
        external
        returns (bytes4);

    function executeTransferBatch(
        address user,
        AgentTransferBatch[] calldata transfers
    ) external returns (bytes4);

    function executeERC1155BatchTransfer(
        address user,
        AgentERC1155BatchTransfer[] calldata transfers
    ) external returns (bytes4);

    function executeWithERC1155BatchTransfer(
        address user,
        AgentTransfer[] calldata transfers,
        AgentTransferBatch[] calldata transferBatches,
        AgentERC1155BatchTransfer[] calldata erc1155BatchTransfers
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface IAccounting {
    error NotRecorder(); // 0x787a22eb
    error LimitExceeded(); // 0x3261c792
    error InvalidShares(); // 0x6edcc523
    error ZeroAddress(); // 0xd92e233d
    error NotFound(); // 0xc5723b51

    event ReceiverChangedBatch(
        address[] collections,
        address[] receivers
    );

    event ReceiverInitialized(address collection, address receiver);

    struct FeeShare {
        uint256 platform;
        uint256 collection;
        uint256 combo;
        uint256 base;
    }

    struct Royalty {
        address receiver;
        uint16 point; // [0, 10000] - %
    }

    struct BaseURIs {
        string baseTokenURI;
        string baseContractURI;
    }

    struct GlobalConfig {
        uint256 addOnsTaxPoints;
        address reserved;
        address collectionOwner;
        FeeShare mintShares;
        Royalty royalty;
        BaseURIs baseURIs;
    }

    function addOnsTaxPoints() external view returns (uint256);

    function setAddOnsTaxPoints(uint256 newPoint) external;

    function setMintRewardShare(
        uint256 platform,
        uint256 combo,
        uint256 collection
    ) external;

    function globalConfig() external view returns (GlobalConfig memory);

    function getAdminAddress() external view returns (address);

    function setReceivers(
        address[] calldata collections,
        address[] calldata receivers
    ) external;

    function initReceivers(address[] calldata collections) external;

    function receiversOf(address[] calldata collections)
        external
        view
        returns (address[] memory);

    function collectionsOf(address receiver)
        external
        view
        returns (address[] memory collections);

    function setCollectionOwner(address owner) external;

    function getCollectionOwner() external view returns (address);

    function setRoyalty(address receiver, uint16 point) external;

    function royaltyInfo(
        address collection,
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);

    function setBaseURIs(
        string memory baseTokenURI,
        string memory baseContractURI
    ) external;

    function getBaseTokenURI() external view returns (string memory);

    function getBaseContractURI() external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to 
 * save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../interfaces/IAgent.sol";
import {ProxyRegistry} from "./ProxyRegistry.sol";

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721Tradable is ERC721, Ownable {
    using Counters for Counters.Counter;

    error ApprovalToAgent();    // 0xb32b04ed

    /*
     * We rely on the OZ Counter util to keep track of the next available ID.
     * We track the nextTokenId instead of the currentTokenId to save users on gas costs. 
     * Read more about it here: https://shiny.mirror.xyz/OUampBbIz9ebEicfGnQf5At_ReMHlZy0tB4glb9xQ0E
     */ 
    Counters.Counter private _nextTokenId;
    address public immutable proxyRegistryAddress;
    address public immutable agent;

    constructor(
        string memory name_,
        string memory symbol_,
        address agent_,
        address proxyRegistryAddress_
    ) ERC721(name_, symbol_) {
        agent = agent_;
        proxyRegistryAddress = proxyRegistryAddress_;
        // nextTokenId is initialized to 1, since starting at 0 leads to higher gas cost for the first minter
        _nextTokenId.increment();
    }

    function nextTokenId() internal returns (uint256) {
        uint256 currentTokenId = _nextTokenId.current();
        _nextTokenId.increment();
        return currentTokenId;
    }

    /**
        @dev Returns the total tokens minted so far.
        1 is always subtracted from the Counter since it tracks the next available tokenId.
     */
    function totalSupply() external view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    function approve(address to_, uint256 tokenId_) public override {
        if (to_ == agent) {
            revert ApprovalToAgent();
        }
        super.approve(to_, tokenId_);
    }

    function setApprovalForAll(address operator_, bool approved_) public override {
        if (operator_ == agent) {
            revert ApprovalToAgent();
        }
        super.setApprovalForAll(operator_, approved_);
    }
    
    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner_, address operator_)
        override
        public
        view
        returns (bool)
    {
        if (IAgent(agent).isApproved(owner_, operator_)) {
            return true;
        }

        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner_)) == operator_) {
            return true;
        }

        return super.isApprovedForAll(owner_, operator_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";

import "./common/ERC721Tradable.sol";
import "./interfaces/IComboCollCore.sol";
import "./libs/ComboParamsValidator.sol";
import "./interfaces/IAccounting.sol";

contract ComboCollCore is ERC721Tradable, IComboCollCore, IERC2981 {
    using ComboParamsValidator for ComboParams;
    using ComboParamsValidator for ComboParamsValidator.Rules;

    // bytes4(keccak256('supportsComboInterface()'))
    bytes4 private constant _INTERFACEID_COMBO = 0x22d5a648;

    ComboParamsValidator.Rules private _rules;
    // uuid => usage times
    mapping(uint256 => uint256) private _tokenUsages;

    // combo id => ComboMeta
    mapping(uint256 => ComboMeta) private _combos;

    mapping(bytes32 => uint256) public tokenOfHash;
    mapping(uint256 => bytes32) public hashOfToken;

    address public immutable accounting;
    address public immutable comboCollProxy;

    string public contractURIPath;

    constructor(
        ConstructorParams memory params,
        address agent_,
        address accounting_,
        address comboCollProxy_,
        address proxyRegistryAddress_
    )
        ERC721Tradable(
            params.name,
            params.symbol,
            agent_,
            proxyRegistryAddress_
        )
    {
        contractURIPath = params.contractURIPath;
        accounting = accounting_;
        comboCollProxy = comboCollProxy_;

        _rules.initRules(params.comboRules);
    }

    function supportsInterface(bytes4 interfaceId_)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId_ == _INTERFACEID_COMBO ||
            interfaceId_ == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId_);
    }

    function supportsComboInterface() public pure returns (bool) {
        return true;
    }

    function tokenURI(uint256 tokenId_) override public view returns (string memory) {
        if (!_exists(tokenId_)) {
            revert ComboNotExists();
        }
        return string(abi.encodePacked(
            IAccounting(accounting).getBaseTokenURI(),
            Strings.toHexString(address(this)),
            "/",
            Strings.toHexString(uint256(hashOfToken[tokenId_]))
        ));
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(IAccounting(accounting).getBaseContractURI(), contractURIPath));
    }

    function royaltyInfo(uint256 tokenId_, uint256 salePrice_)
        external
        view
        returns (address receiver, uint256 royaltyAmount) {
        if (!_exists(tokenId_)) {
            revert ComboNotExists();
        }
        return IAccounting(accounting).royaltyInfo(address(this), tokenId_, salePrice_);
    }

    function mint(
        address caller_,
        address to_,
        ComboParams calldata comboParams
    ) external override returns (ComboReceipt memory receipt) {
        if (msg.sender != comboCollProxy) {
            revert CallerNotAllowed();
        }
        uint256 comboId = nextTokenId();
        _safeMint(to_, comboId);

        receipt = _updateCombo(caller_, comboId, comboParams);
        emit Mint(caller_, comboId, comboParams.hash, receipt.comboHash);
    }

    function remint(
        address caller_,
        uint256 comboId_,
        ComboParams calldata comboParams
    ) external override returns (ComboReceipt memory receipt) {
        if (msg.sender != comboCollProxy) {
            revert CallerNotAllowed();
        }
        if (ownerOf(comboId_) != caller_) {
            revert NotComboOwner();
        }
        _decreaseTokenUsage(comboId_);

        bytes32 hash = hashOfToken[comboId_];
        // delete hashOfToken[comboId_];    // unneccessary
        delete tokenOfHash[hash];

        receipt = _updateCombo(caller_, comboId_, comboParams);
        emit Remint(caller_, comboId_, comboParams.hash, receipt.comboHash);
    }

    function _updateCombo(
        address creator,
        uint256 comboId,
        ComboParams calldata comboParams
    ) internal returns (ComboReceipt memory) {
        ComboMeta storage meta = _combos[comboId];
        if (meta.creator != address(0)) {
            delete meta.items;
        }
        meta.creator = creator;
        Ingredients calldata ingredients = comboParams.ingredients;
        uint256 size = ingredients.collections.length;
        bool[][] memory isLockForItems = new bool[][](size);
        Item memory item;
        Factor storage factor;
        bytes memory data;
        for (uint256 i = 0; i < size;) {
            address tokenAddress = ingredients.collections[i];
            uint256 maxTokenUsage = _rules._maxTokenUsages[tokenAddress];

            uint256 len = ingredients.itemsForCollections[i].length;
            isLockForItems[i] = new bool[](len);
            for (uint256 j = 0; j < len;) {
                item.uuid = comboParams.uuidForItems[i][j];
                item.amount = ingredients.amountsForItems[i][j];
                item.setId = ingredients.setsForItems[i][j];
                item.typ = uint8(comboParams.collectionTypes[i]);
                item.limit = maxTokenUsage > 0;

                if (item.limit) {
                    if (_tokenUsages[item.uuid] == maxTokenUsage) {
                        revert ExceedTokenUsageLimit(tokenAddress, ingredients.itemsForCollections[i][j]);
                    }
                    ++_tokenUsages[item.uuid];
                }

                if (item.setId == 0) {
                    factor = _rules._collectionFactors[tokenAddress];
                    if (factor.collection == address(0)) {
                        revert UnknownCollection(tokenAddress);
                    }
                } else {
                    factor = _rules._setFactors[item.setId];
                    if (factor.setId == 0) {
                        revert UnknownSet(item.setId);
                    }
                }

                item.lock = factor.lock;
                isLockForItems[i][j] = item.lock;

                meta.items.push(item);
                data = abi.encode(data, item);
                unchecked{ ++j; }
            }
            unchecked{ ++i; }
        }

        ComboParamsValidator.ValidateResult memory result = comboParams.validate(isLockForItems, _rules);

        result.receipt.comboId = comboId;
        result.receipt.comboHash = keccak256(abi.encodePacked(data, comboParams.hash));
        hashOfToken[comboId] = result.receipt.comboHash;
        tokenOfHash[result.receipt.comboHash] = comboId;
        return result.receipt;
    }

    function dismantle(address caller_, uint256 comboId_) external override {
        if (msg.sender != comboCollProxy) {
            revert CallerNotAllowed();
        }
        if (ownerOf(comboId_) != caller_) {
            revert NotComboOwner();
        }

        _burn(comboId_);
        _decreaseTokenUsage(comboId_);

        bytes32 hash = hashOfToken[comboId_];
        delete hashOfToken[comboId_];
        delete tokenOfHash[hash];

        delete _combos[comboId_];
    }

    function _decreaseTokenUsage(uint256 comboId) internal {
        Item[] storage items = _combos[comboId].items;
        uint256 len = items.length;
        for (uint256 i = 0; i < len; ) {
            if (items[i].limit) {
                --_tokenUsages[items[i].uuid];
            }
            unchecked {
                ++i;
            }
        }
    }

    function getComboRules()
        public
        override
        view
        returns (ComboRules memory)
    {
        return _rules.toComboRules();
    }

    function getLimitedTokenUsages(uint256[] calldata uuids_)
        external
        view
        returns (uint256[] memory usages) {
        usages = new uint256[](uuids_.length);
        for (uint256 i = 0; i < uuids_.length; ++i) {
            usages[i] = _tokenUsages[uuids_[i]];
        }
    }

    function comboMetasOf(uint256[] calldata comboIds_) external override view returns (ComboMeta[] memory metas) {
        metas = new ComboMeta[](comboIds_.length);
        for (uint256 i = 0; i < comboIds_.length; ++i) {
            if (!_exists(comboIds_[i])) {
                revert ComboNotExists();
            }
            metas[i] = _combos[comboIds_[i]];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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