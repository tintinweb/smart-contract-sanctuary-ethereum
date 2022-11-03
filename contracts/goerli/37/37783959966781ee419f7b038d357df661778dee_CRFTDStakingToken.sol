// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {utils} from "./lib/utils.sol";
import {ERC20UDS} from "UDS/tokens/ERC20UDS.sol";
import {ERC721UDS} from "UDS/tokens/ERC721UDS.sol";
import {OwnableUDS} from "UDS/auth/OwnableUDS.sol";
import {UUPSUpgrade} from "UDS/proxy/UUPSUpgrade.sol";
import {FxERC721sRoot} from "fx-contracts/FxERC721sRoot.sol";
import {Multicallable} from "UDS/utils/Multicallable.sol";
import {ERC20RewardUDS} from "UDS/tokens/extensions/ERC20RewardUDS.sol";
import {MINT_ERC20_SELECTOR} from "fx-contracts/FxERC20UDSRoot.sol";

// ------------- storage

bytes32 constant DIAMOND_STORAGE_CRFTD_TOKEN = keccak256("diamond.storage.crftd.token");

function s() pure returns (CRFTDTokenDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_CRFTD_TOKEN;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

struct CRFTDTokenDS {
    uint256 rewardEndDate;
    mapping(address => uint256) rewardRate;
    mapping(address => mapping(uint256 => address)) ownerOf;
}

// ------------- errors

error ZeroReward();
error ExceedsLimit();
error IncorrectOwner();
error InvalidFxChild();
error MigrationRequired();
error MigrationIncomplete();
error MigrationNotStarted();
error CollectionNotRegistered();
error CollectionAlreadyRegistered();

//       ___           ___           ___                    _____
//      /  /\         /  /\         /  /\       ___        /  /::\
//     /  /:/        /  /::\       /  /:/_     /__/\      /  /:/\:\
//    /  /:/        /  /:/\:\     /  /:/ /\    \  \:\    /  /:/  \:\
//   /  /:/  ___   /  /::\ \:\   /  /:/ /:/     \__\:\  /__/:/ \__\:|
//  /__/:/  /  /\ /__/:/\:\_\:\ /__/:/ /:/      /  /::\ \  \:\ /  /:/
//  \  \:\ /  /:/ \__\/~|::\/:/ \  \:\/:/      /  /:/\:\ \  \:\  /:/
//   \  \:\  /:/     |  |:|::/   \  \::/      /  /:/__\/  \  \:\/:/
//    \  \:\/:/      |  |:|\/     \  \:\     /__/:/        \  \::/
//     \  \::/       |__|:|        \  \:\    \__\/          \__\/
//      \__\/         \__\|         \__\/

/// @title CRFTDStakingToken (Cross-Chain)
/// @author phaze (https://github.com/0xPhaze)
/// @notice Minimal cross-chain ERC721 staking contract supporting multiple collections
/// @notice Token ids are registered with child ERC20 token
contract CRFTDStakingToken is FxERC721sRoot, ERC20RewardUDS, OwnableUDS, UUPSUpgrade, Multicallable {
    event CollectionRegistered(address indexed collection, uint256 rewardRate);

    /// @dev Setting `rewardEndDate` to this date enables migration.
    uint256 constant MIGRATION_START_DATE = (1 << 42) - 1;

    constructor(address checkpointManager, address fxRoot) FxERC721sRoot(checkpointManager, fxRoot) {
        __ERC20_init("CRFTD", "CRFTD", 18);
    }

    /* ------------- init ------------- */

    function init(string calldata name, string calldata symbol) external initializer {
        __Ownable_init();
        __ERC20_init(name, symbol, 18);
    }

    /* ------------- view ------------- */

    function rewardEndDate() public view override returns (uint256) {
        return s().rewardEndDate;
    }

    function rewardDailyRate() public pure override returns (uint256) {
        return 1e16; // 0.01
    }

    function rewardRate(address collection) public view returns (uint256) {
        return s().rewardRate[collection];
    }

    function ownerOf(address collection, uint256 id) public view returns (address) {
        return s().ownerOf[collection][id];
    }

    function getDailyReward(address user) public view returns (uint256) {
        return _getRewardMultiplier(user) * rewardDailyRate();
    }

    function migrationStarted() public view returns (bool) {
        if (fxChildTunnel() == address(0)) return false;
        if (rewardEndDate() != MIGRATION_START_DATE) return false;

        return true;
    }

    /* ------------- external ------------- */

    /// @notice Stake ids from approved collections.
    ///         If child is linked and migration enabled,
    ///         this will register the ids with child contract.
    /// @param collection erc721 collection address.
    /// @param tokenIds erc721 id array per collection.
    function stake(address collection, uint256[] calldata tokenIds) external {
        if (tokenIds.length > 20) revert ExceedsLimit();

        for (uint256 i; i < tokenIds.length; ++i) {
            ERC721UDS(collection).transferFrom(msg.sender, address(this), tokenIds[i]);

            s().ownerOf[collection][tokenIds[i]] = msg.sender;
        }

        if (migrationStarted()) {
            // note: we allow any collection to be transferred once L2 is activated.
            // Unrecognized collections are ignored on L2. This removes the need
            // to force a synchronized state of both contracts.
            if (_getRewardMultiplier(msg.sender) != 0) revert MigrationRequired();

            _registerERC721IdsWithChild(collection, msg.sender, tokenIds);
        } else {
            uint256 rate = s().rewardRate[collection];

            if (rate == 0) revert CollectionNotRegistered();

            _increaseRewardMultiplier(msg.sender, uint216(tokenIds.length * rate));
        }
    }

    /// @notice Unstake ids. If child is linked and migration enabled,
    ///         this will de-register the ids with child contract.
    /// @param collection erc721 collection address.
    /// @param tokenIds erc721 id array per collection.
    function unstake(address collection, uint256[] calldata tokenIds) external {
        if (tokenIds.length > 20) revert ExceedsLimit();

        if (migrationStarted()) {
            if (_getRewardMultiplier(msg.sender) != 0) revert MigrationRequired();

            _registerERC721IdsWithChild(collection, address(0), tokenIds);
        } else {
            uint256 rate = s().rewardRate[collection];

            if (rate == 0) revert CollectionNotRegistered();

            _decreaseRewardMultiplier(msg.sender, uint216(tokenIds.length * rate));
        }

        for (uint256 i; i < tokenIds.length; ++i) {
            if (s().ownerOf[collection][tokenIds[i]] != msg.sender) revert IncorrectOwner();

            delete s().ownerOf[collection][tokenIds[i]];

            ERC721UDS(collection).transferFrom(address(this), msg.sender, tokenIds[i]);
        }
    }

    /// @notice Synchronizes any erc721 ids with child. Duplicates are caught by child.
    /// @param collections erc721 collection addresses.
    /// @param tokenIds erc721 id array per collection.
    /// @return rewardMultiplier calculated rewardMultiplier to be registered with child.
    ///         Used by `safeMigrate()`.
    function synchronizeIdsWithChild(address[] calldata collections, uint256[][] calldata tokenIds)
        public
        returns (uint256 rewardMultiplier)
    {
        if (!migrationStarted()) revert MigrationNotStarted();
        if (_getRewardMultiplier(msg.sender) != 0) revert MigrationRequired();

        for (uint256 i; i < collections.length; ++i) {
            uint256 rate = s().rewardRate[collections[i]];

            if (rate == 0) revert CollectionNotRegistered();

            uint256[] calldata ids = tokenIds[i];
            mapping(uint256 => address) storage owners = s().ownerOf[collections[i]];

            rewardMultiplier += ids.length * rate;

            for (uint256 j; j < ids.length; ++j) {
                if (owners[ids[j]] != msg.sender) revert IncorrectOwner();
            }

            // note: we're optimistic by fore-going unique tokenId/collection checks
            // duplicates are caught in child registry and could only hurt the user during migration
            if (ids.length != 0) _registerERC721IdsWithChild(collections[i], msg.sender, ids);
        }
    }

    /// @notice Migrates the current user balance and erc721 ids to layer 2.
    ///         user `rewardMultiplier` MUST be 0 before registering any ids with child,
    ///         as otherwise it would be possible to earn on both chains.
    /// @param collections erc721 collection addresses.
    /// @param tokenIds erc721 id array per collection.
    function safeMigrate(address[] calldata collections, uint256[][] calldata tokenIds) external {
        if (!migrationStarted()) revert MigrationNotStarted();

        _claimReward(msg.sender);

        uint256 currentRewardMultiplier = _getRewardMultiplier(msg.sender);

        // migrate erc20 token balance
        uint256 balance = balanceOf(msg.sender);

        _burn(msg.sender, balance);
        _sendMessageToChild(abi.encodeWithSelector(MINT_ERC20_SELECTOR, msg.sender, balance));
        _setRewardMultiplier(msg.sender, 0);

        // migrate erc721 ids
        uint256 migratedRewardMultiplier = synchronizeIdsWithChild(collections, tokenIds);

        // this check does not guarantee that the user has migrated all erc721s,
        // but is an additional safety measure for the user
        if (currentRewardMultiplier != migratedRewardMultiplier) revert MigrationIncomplete();
    }

    function claimReward() external {
        _claimReward(msg.sender);
    }

    /* ------------- erc20 ------------- */

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        _claimReward(msg.sender);

        return ERC20UDS.transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        _claimReward(from);

        return ERC20UDS.transferFrom(from, to, amount);
    }

    /* ------------- O(n) read-only ------------- */

    function stakedIdsOf(
        address collection,
        address user,
        uint256 collectionSize
    ) external view returns (uint256[] memory) {
        return utils.getOwnedIds(s().ownerOf[collection], user, collectionSize);
    }

    function stakedBalanceOf(
        address collection,
        address user,
        uint256 collectionSize
    ) external view returns (uint256) {
        return utils.balanceOf(s().ownerOf[collection], user, collectionSize);
    }

    function ownedBalanceOf(
        address collection,
        address user,
        uint256 collectionSize
    ) external view returns (uint256) {
        return ERC721UDS(collection).balanceOf(user) + utils.balanceOf(s().ownerOf[collection], user, collectionSize);
    }

    /* ------------- owner ------------- */

    function startMigration(address fxChild) public onlyOwner {
        if (fxChild == address(0)) revert InvalidFxChild();

        setFxChildTunnel(fxChild);

        s().rewardEndDate = MIGRATION_START_DATE;
    }

    function setRewardEndDate(uint256 endDate) external onlyOwner {
        s().rewardEndDate = endDate;
    }

    function registerCollection(address collection, uint200 rate) external onlyOwner {
        if (rate == 0) revert ZeroReward();
        if (s().rewardRate[collection] != 0) revert CollectionAlreadyRegistered();

        s().rewardRate[collection] = rate;

        emit CollectionRegistered(collection, rate);
    }

    function airdrop(address[] calldata tos, uint256 amount) external onlyOwner {
        for (uint256 i; i < tos.length; ++i) _mint(tos[i], amount);
    }

    function airdrop(address[] calldata tos, uint256[] calldata amounts) external onlyOwner {
        for (uint256 i; i < tos.length; ++i) _mint(tos[i], amounts[i]);
    }

    /* ------------- override ------------- */

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _authorizeTunnelController() internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library utils {
    function getOwnedIds(
        mapping(uint256 => address) storage ownerMapping,
        address user,
        uint256 collectionSize
    ) internal view returns (uint256[] memory ids) {
        uint256 memPtr;
        uint256 idsLength;

        assembly {
            ids := mload(0x40)
            memPtr := add(ids, 32)
        }

        unchecked {
            uint256 end = collectionSize + 1;
            for (uint256 id = 0; id < end; ++id) {
                if (ownerMapping[id] == user) {
                    assembly {
                        mstore(memPtr, id)
                        memPtr := add(memPtr, 32)
                        idsLength := add(idsLength, 1)
                    }
                }
            }
        }

        assembly {
            mstore(ids, idsLength)
            mstore(0x40, memPtr)
        }
    }

    function balanceOf(
        mapping(uint256 => address) storage ownerMapping,
        address user,
        uint256 collectionSize
    ) internal view returns (uint256 numOwned) {
        unchecked {
            uint256 end = collectionSize + 1;
            address owner;
            for (uint256 id = 0; id < end; ++id) {
                owner = ownerMapping[id];
                assembly {
                    numOwned := add(numOwned, eq(owner, user))
                }
            }
        }
    }

    function indexOf(address[] calldata arr, address addr) internal pure returns (bool found, uint256 index) {
        unchecked {
            for (uint256 i; i < arr.length; ++i) if (arr[i] == addr) return (true, i);
        }
        return (false, 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "../utils/Initializable.sol";
import {EIP712PermitUDS} from "../auth/EIP712PermitUDS.sol";

// ------------- storage

bytes32 constant DIAMOND_STORAGE_ERC20 = keccak256("diamond.storage.erc20");

function s() pure returns (ERC20DS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_ERC20;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

struct ERC20DS {
    string name;
    string symbol;
    uint8 decimals;
    uint256 totalSupply;
    mapping(address => uint256) balanceOf;
    mapping(address => mapping(address => uint256)) allowance;
}

/// @title ERC20 (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate)
abstract contract ERC20UDS is Initializable, EIP712PermitUDS {
    ERC20DS private __storageLayout; // storage layout for upgrade compatibility checks

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed operator, uint256 amount);

    /* ------------- init ------------- */

    function __ERC20_init(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) internal virtual initializer {
        s().name = _name;
        s().symbol = _symbol;
        s().decimals = _decimals;
    }

    /* ------------- view ------------- */

    function name() external view virtual returns (string memory) {
        return s().name;
    }

    function symbol() external view virtual returns (string memory) {
        return s().symbol;
    }

    function decimals() external view virtual returns (uint8) {
        return s().decimals;
    }

    function totalSupply() external view virtual returns (uint256) {
        return s().totalSupply;
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        return s().balanceOf[owner];
    }

    function allowance(address owner, address operator) public view virtual returns (uint256) {
        return s().allowance[owner][operator];
    }

    /* ------------- public ------------- */

    function approve(address operator, uint256 amount) public virtual returns (bool) {
        s().allowance[msg.sender][operator] = amount;

        emit Approval(msg.sender, operator, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        s().balanceOf[msg.sender] -= amount;

        unchecked {
            s().balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = s().allowance[from][msg.sender];

        if (allowed != type(uint256).max) s().allowance[from][msg.sender] = allowed - amount;

        s().balanceOf[from] -= amount;

        unchecked {
            s().balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    // EIP-2612 permit
    function permit(
        address owner,
        address operator,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s_
    ) public virtual {
        _usePermit(owner, operator, value, deadline, v, r, s_);

        s().allowance[owner][operator] = value;

        emit Approval(owner, operator, value);
    }

    /* ------------- internal ------------- */

    function _mint(address to, uint256 amount) internal virtual {
        s().totalSupply += amount;

        unchecked {
            s().balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        s().balanceOf[from] -= amount;

        unchecked {
            s().totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "../utils/Initializable.sol";
import {EIP712PermitUDS} from "../auth/EIP712PermitUDS.sol";

// ------------- storage

bytes32 constant DIAMOND_STORAGE_ERC721 = keccak256("diamond.storage.erc721");

function s() pure returns (ERC721DS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_ERC721;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

struct ERC721DS {
    string name;
    string symbol;
    mapping(uint256 => address) ownerOf;
    mapping(address => uint256) balanceOf;
    mapping(uint256 => address) getApproved;
    mapping(address => mapping(address => bool)) isApprovedForAll;
}

// ------------- errors

error NonexistentToken();
error NonERC721Receiver();
error MintExistingToken();
error MintToZeroAddress();
error BalanceOfZeroAddress();
error TransferToZeroAddress();
error CallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();

/// @title ERC721 (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate)
/// @notice Integrates EIP712Permit
abstract contract ERC721UDS is Initializable, EIP712PermitUDS {
    ERC721DS private __storageLayout; // storage layout for upgrade compatibility checks

    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed operator, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /* ------------- init ------------- */

    function __ERC721_init(string memory name_, string memory symbol_) internal virtual initializer {
        s().name = name_;
        s().symbol = symbol_;
    }

    /* ------------- virtual ------------- */

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /* ------------- view ------------- */

    function name() external view virtual returns (string memory) {
        return s().name;
    }

    function symbol() external view virtual returns (string memory) {
        return s().symbol;
    }

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        if ((owner = s().ownerOf[id]) == address(0)) revert NonexistentToken();
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) revert BalanceOfZeroAddress();

        return s().balanceOf[owner];
    }

    function getApproved(uint256 id) public view returns (address) {
        return s().getApproved[id];
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return s().isApprovedForAll[owner][operator];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /* ------------- public ------------- */

    function approve(address operator, uint256 id) public virtual {
        address owner = s().ownerOf[id];

        if (msg.sender != owner && !s().isApprovedForAll[owner][msg.sender]) revert CallerNotOwnerNorApproved();

        s().getApproved[id] = operator;

        emit Approval(owner, operator, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        s().isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        if (to == address(0)) revert TransferToZeroAddress();
        if (from != s().ownerOf[id]) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (msg.sender == from ||
            s().isApprovedForAll[from][msg.sender] ||
            s().getApproved[id] == msg.sender);

        if (!isApprovedOrOwner) revert CallerNotOwnerNorApproved();

        unchecked {
            s().balanceOf[from]--;
            s().balanceOf[to]++;
        }

        s().ownerOf[id] = to;

        delete s().getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
            ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") !=
            ERC721TokenReceiver.onERC721Received.selector
        ) revert NonERC721Receiver();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
            ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) !=
            ERC721TokenReceiver.onERC721Received.selector
        ) revert NonERC721Receiver();
    }

    // EIP-4494 permit; differs from the current EIP
    function permit(
        address owner,
        address operator,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s_
    ) public virtual {
        _usePermit(owner, operator, 1, deadline, v, r, s_);

        s().isApprovedForAll[owner][operator] = true;

        emit ApprovalForAll(owner, operator, true);
    }

    /* ------------- internal ------------- */

    function _mint(address to, uint256 id) internal virtual {
        if (to == address(0)) revert MintToZeroAddress();
        if (s().ownerOf[id] != address(0)) revert MintExistingToken();

        unchecked {
            s().balanceOf[to]++;
        }

        s().ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = s().ownerOf[id];

        if (owner == address(0)) revert NonexistentToken();

        unchecked {
            s().balanceOf[owner]--;
        }

        delete s().ownerOf[id];
        delete s().getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        if (
            to.code.length != 0 &&
            ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") !=
            ERC721TokenReceiver.onERC721Received.selector
        ) revert NonERC721Receiver();
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        if (
            to.code.length != 0 &&
            ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) !=
            ERC721TokenReceiver.onERC721Received.selector
        ) revert NonERC721Receiver();
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "../utils/Initializable.sol";

// ------------- storage

bytes32 constant DIAMOND_STORAGE_OWNABLE = keccak256("diamond.storage.ownable");

function s() pure returns (OwnableDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_OWNABLE;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

struct OwnableDS {
    address owner;
}

// ------------- errors

error CallerNotOwner();

/// @title Ownable (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @dev Requires `__Ownable_init` to be called in proxy
abstract contract OwnableUDS is Initializable {
    OwnableDS private __storageLayout; // storage layout for upgrade compatibility checks

    event OwnerChanged(address oldOwner, address newOwner);

    function __Ownable_init() internal initializer {
        s().owner = msg.sender;
    }

    /* ------------- external ------------- */

    function owner() public view returns (address) {
        return s().owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        s().owner = newOwner;

        emit OwnerChanged(msg.sender, newOwner);
    }

    /* ------------- modifier ------------- */

    modifier onlyOwner() {
        if (msg.sender != s().owner) revert CallerNotOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC1967, ERC1967_PROXY_STORAGE_SLOT} from "./ERC1967Proxy.sol";

// ------------- errors

error OnlyProxyCallAllowed();
error DelegateCallNotAllowed();

/// @title Minimal UUPSUpgrade
/// @author phaze (https://github.com/0xPhaze/UDS)
abstract contract UUPSUpgrade is ERC1967 {
    address private immutable __implementation = address(this);

    /* ------------- external ------------- */

    function upgradeToAndCall(address logic, bytes calldata data) external virtual {
        _authorizeUpgrade(logic);
        _upgradeToAndCall(logic, data);
    }

    /* ------------- view ------------- */

    function proxiableUUID() external view virtual returns (bytes32) {
        if (address(this) != __implementation) revert DelegateCallNotAllowed();

        return ERC1967_PROXY_STORAGE_SLOT;
    }

    /* ------------- virtual ------------- */

    function _authorizeUpgrade(address logic) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FxBaseRootTunnel} from "./base/FxBaseRootTunnel.sol";

bytes4 constant REGISTER_ERC721s_IDS_SELECTOR = bytes4(
    keccak256("registerERC721IdsWithChild(address,address,uint256[])")
);

/// @title ERC721 FxRootTunnel
/// @author phaze (https://github.com/0xPhaze/fx-contracts)
abstract contract FxERC721sRoot is FxBaseRootTunnel {
    constructor(address checkpointManager, address fxRoot) FxBaseRootTunnel(checkpointManager, fxRoot) {}

    /* ------------- virtual ------------- */

    function _authorizeTunnelController() internal virtual override;

    /* ------------- internal ------------- */

    function _registerERC721IdsWithChild(
        address collection,
        address to,
        uint256[] calldata ids
    ) internal virtual {
        _sendMessageToChild(abi.encodeWithSelector(REGISTER_ERC721s_IDS_SELECTOR, collection, to, ids));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Multicallable
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @dev Allows for batched calls (non-payable)
abstract contract Multicallable {
    function multicall(bytes[] calldata data) external {
        unchecked {
            for (uint256 i; i < data.length; ++i) {
                (bool success, ) = address(this).delegatecall(data[i]);

                if (!success) {
                    assembly {
                        returndatacopy(0, 0, returndatasize())
                        return(0, returndatasize())
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20UDS, s as erc20ds} from "../ERC20UDS.sol";

// ------------- storage

bytes32 constant DIAMOND_STORAGE_ERC20_REWARD = keccak256("diamond.storage.erc20.reward");

function s() pure returns (ERC20RewardDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_ERC20_REWARD;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

struct UserData {
    uint216 multiplier;
    uint40 lastClaimed;
}

struct ERC20RewardDS {
    mapping(address => UserData) userData;
}

/// @title ERC20Reward (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @notice Allows for ERC20 reward accrual
/// @notice at a rate of rewardDailyRate() * multiplier[user] per day
/// @notice Tokens are automatically claimed before any multiplier update
abstract contract ERC20RewardUDS is ERC20UDS {
    ERC20RewardDS private __storageLayout; // storage layout for upgrade compatibility checks

    /* ------------- virtual ------------- */

    function rewardEndDate() public view virtual returns (uint256);

    function rewardDailyRate() public view virtual returns (uint256);

    /* ------------- view ------------- */

    function totalBalanceOf(address owner) public view virtual returns (uint256) {
        return ERC20UDS.balanceOf(owner) + pendingReward(owner);
    }

    function pendingReward(address owner) public view virtual returns (uint256) {
        UserData storage userData = s().userData[owner];

        return _calculateReward(userData.multiplier, userData.lastClaimed);
    }

    /* ------------- internal ------------- */

    function _getRewardMultiplier(address owner) internal view virtual returns (uint256) {
        return s().userData[owner].multiplier;
    }

    function _calculateReward(uint256 multiplier, uint256 lastClaimed) internal view virtual returns (uint256) {
        uint256 end = rewardEndDate();

        uint256 timestamp = block.timestamp;

        if (lastClaimed > end) return 0;
        else if (timestamp > end) timestamp = end;

        // If multiplier > 0 then lastClaimed > 0
        // because _claimReward must have been called
        return ((timestamp - lastClaimed) * multiplier * rewardDailyRate()) / 1 days;
    }

    function _claimReward(address owner) internal virtual {
        UserData storage userData = s().userData[owner];

        uint256 multiplier = userData.multiplier;
        uint256 lastClaimed = userData.lastClaimed;

        if (multiplier != 0) {
            // Only forego minting if multiplier == 0
            // checking for amount == 0 can lead to failed transactions
            // due to too little gas being supplied through estimation.
            // This is under the assumption that _increaseRewardMultiplier
            // is unlikely to be called twice in a row.
            uint256 amount = _calculateReward(multiplier, lastClaimed);

            _mint(owner, amount);
        }

        s().userData[owner].lastClaimed = uint40(block.timestamp);
    }

    function _increaseRewardMultiplier(address owner, uint216 quantity) internal virtual {
        _claimReward(owner);

        s().userData[owner].multiplier += quantity;
    }

    function _decreaseRewardMultiplier(address owner, uint216 quantity) internal virtual {
        _claimReward(owner);

        s().userData[owner].multiplier -= quantity;
    }

    function _setRewardMultiplier(address owner, uint216 quantity) internal virtual {
        _claimReward(owner);

        s().userData[owner].multiplier = quantity;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20UDS} from "UDS/tokens/ERC20UDS.sol";
import {FxBaseRootTunnel} from "./base/FxBaseRootTunnel.sol";

bytes4 constant MINT_ERC20_SELECTOR = bytes4(keccak256("mintERC20Tokens(address,uint256)"));

error InvalidSelector();

/// @title ERC20 Root
/// @author phaze (https://github.com/0xPhaze/fx-contracts)
abstract contract FxERC20UDSRoot is FxBaseRootTunnel, ERC20UDS {
    constructor(address checkpointManager, address fxRoot) FxBaseRootTunnel(checkpointManager, fxRoot) {}

    /* ------------- virtual ------------- */

    function _authorizeTunnelController() internal virtual override;

    /* ------------- internal ------------- */

    function _mintERC20TokensWithChild(address to, uint256 amount) internal virtual {
        _sendMessageToChild(abi.encodeWithSelector(MINT_ERC20_SELECTOR, to, amount));
    }

    /* ------------- external ------------- */

    function lock(address to, uint256 amount) external virtual {
        _burn(msg.sender, amount);

        _mintERC20TokensWithChild(to, amount);
    }

    function unlock(bytes calldata proofData) external virtual {
        bytes memory message = _validateAndExtractMessage(proofData);

        (bytes4 selector, address to, uint256 amount) = abi.decode(message, (bytes4, address, uint256));

        if (selector != MINT_ERC20_SELECTOR) revert InvalidSelector();

        _mint(to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {s as erc1967ds} from "../proxy/ERC1967Proxy.sol";

// ------------- errors

error ProxyCallRequired();
error AlreadyInitialized();

/// @title Initializable
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @dev functions using the `initializer` modifier are only callable during proxy deployment
/// @dev functions using the `reinitializer` modifier are only callable through a proxy
/// @dev and only before a proxy upgrade migration has completed
/// @dev (only when `upgradeToAndCall`'s `initCalldata` is being executed)
/// @dev allows re-initialization during upgrades
abstract contract Initializable {
    address private immutable __implementation = address(this);

    /* ------------- modifier ------------- */

    modifier initializer() {
        if (address(this).code.length != 0) revert AlreadyInitialized();
        _;
    }

    modifier reinitializer() {
        if (address(this) == __implementation) revert ProxyCallRequired();
        if (erc1967ds().implementation == __implementation) revert AlreadyInitialized();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ------------- storage

bytes32 constant DIAMOND_STORAGE_EIP_712_PERMIT = keccak256("diamond.storage.eip.712.permit");

function s() pure returns (EIP2612DS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_EIP_712_PERMIT;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

struct EIP2612DS {
    mapping(address => uint256) nonces;
}

// ------------- errors

error InvalidSigner();
error DeadlineExpired();

/// @title EIP712Permit (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate)
/// @dev `DOMAIN_SEPARATOR` needs to be re-computed every time
/// @dev for use with a proxy due to `address(this)`
abstract contract EIP712PermitUDS {
    EIP2612DS private __storageLayout; // storage layout for upgrade compatibility checks

    /* ------------- public ------------- */

    function nonces(address owner) public view returns (uint256) {
        return s().nonces[owner];
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256("EIP712"),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /* ------------- internal ------------- */

    function _usePermit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) internal virtual {
        if (deadline < block.timestamp) revert DeadlineExpired();

        unchecked {
            uint256 nonce = s().nonces[owner]++;

            address recovered = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonce,
                                deadline
                            )
                        )
                    )
                ),
                v_,
                r_,
                s_
            );

            if (recovered == address(0) || recovered != owner) revert InvalidSigner();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ------------- storage

// keccak256("eip1967.proxy.implementation") - 1
bytes32 constant ERC1967_PROXY_STORAGE_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

function s() pure returns (ERC1967UpgradeDS storage diamondStorage) {
    assembly { diamondStorage.slot := ERC1967_PROXY_STORAGE_SLOT } // prettier-ignore
}

struct ERC1967UpgradeDS {
    address implementation;
}

// ------------- errors

error InvalidUUID();
error NotAContract();

/// @title ERC1967
/// @author phaze (https://github.com/0xPhaze/UDS)
abstract contract ERC1967 {
    event Upgraded(address indexed implementation);

    function _upgradeToAndCall(address logic, bytes memory data) internal {
        if (logic.code.length == 0) revert NotAContract();

        if (ERC1822(logic).proxiableUUID() != ERC1967_PROXY_STORAGE_SLOT) revert InvalidUUID();

        if (data.length != 0) {
            (bool success, ) = logic.delegatecall(data);

            if (!success) {
                assembly {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }

        s().implementation = logic;

        emit Upgraded(logic);
    }
}

/// @title Minimal ERC1967Proxy
/// @author phaze (https://github.com/0xPhaze/UDS)
contract ERC1967Proxy is ERC1967 {
    constructor(address logic, bytes memory data) payable {
        _upgradeToAndCall(logic, data);
    }

    fallback() external payable {
        assembly {
            calldatacopy(0, 0, calldatasize())

            let success := delegatecall(gas(), sload(ERC1967_PROXY_STORAGE_SLOT), 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            if success {
                return(0, returndatasize())
            }

            revert(0, returndatasize())
        }
    }
}

/// @title ERC1822
/// @author phaze (https://github.com/0xPhaze/UDS)
abstract contract ERC1822 {
    function proxiableUUID() external view virtual returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Merkle} from "../lib/Merkle.sol";
import {RLPReader} from "../lib/RLPReader.sol";
import {ExitPayloadReader} from "../lib/ExitPayloadReader.sol";
import {MerklePatriciaProof} from "../lib/MerklePatriciaProof.sol";

// ------------- interfaces

interface IFxStateSender {
    function sendMessageToChild(address _receiver, bytes calldata _data) external;
}

interface ICheckpointManager {
    function headerBlocks(uint256 headerNumber)
        external
        view
        returns (
            bytes32 root,
            uint256 start,
            uint256 end,
            uint256 createdAt,
            address proposer
        );
}

// ------------- storage

bytes32 constant DIAMOND_STORAGE_FX_BASE_ROOT_TUNNEL = keccak256("diamond.storage.fx.base.root.tunnel");

function s() pure returns (FxBaseRootTunnelDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_FX_BASE_ROOT_TUNNEL;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

struct FxBaseRootTunnelDS {
    address fxChildTunnel;
    mapping(bytes32 => bool) processedExits;
}

// ------------- errors

error FxChildUnset();
error InvalidHeader();
error InvalidSelector();
error InvalidReceiptProof();
error InvalidFxChildTunnel();
error ExitAlreadyProcessed();

abstract contract FxBaseRootTunnel {
    using RLPReader for RLPReader.RLPItem;
    using Merkle for bytes32;
    using ExitPayloadReader for bytes;
    using ExitPayloadReader for ExitPayloadReader.ExitPayload;
    using ExitPayloadReader for ExitPayloadReader.Log;
    using ExitPayloadReader for ExitPayloadReader.LogTopics;
    using ExitPayloadReader for ExitPayloadReader.Receipt;

    bytes32 private constant SEND_MESSAGE_EVENT_SELECTOR =
        0x8c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036;

    IFxStateSender public immutable fxRoot;
    ICheckpointManager public immutable checkpointManager;

    constructor(address checkpointManager_, address fxRoot_) {
        checkpointManager = ICheckpointManager(checkpointManager_);
        fxRoot = IFxStateSender(fxRoot_);
    }

    /* ------------- virtual ------------- */

    function _authorizeTunnelController() internal virtual;

    /* ------------- view ------------- */

    function fxChildTunnel() public view virtual returns (address) {
        return s().fxChildTunnel;
    }

    function processedExits(bytes32 exitHash) public view virtual returns (bool) {
        return s().processedExits[exitHash];
    }

    function setFxChildTunnel(address fxChildTunnel_) public virtual {
        _authorizeTunnelController();

        s().fxChildTunnel = fxChildTunnel_;
    }

    /* ------------- internal ------------- */

    function _sendMessageToChild(bytes memory message) internal virtual {
        if (s().fxChildTunnel == address(0)) revert FxChildUnset();

        fxRoot.sendMessageToChild(s().fxChildTunnel, message);
    }

    /**
     * @notice receive message from  L2 to L1, validated by proof
     * @dev This function verifies if the transaction actually happened on child chain
     *
     * @param proofData RLP encoded data of the reference tx containing following list of fields
     *  0 - headerNumber - Checkpoint header block number containing the reference tx
     *  1 - blockProof - Proof that the block header (in the child chain) is a leaf in the submitted merkle root
     *  2 - blockNumber - Block number containing the reference tx on child chain
     *  3 - blockTime - Reference tx block time
     *  4 - txRoot - Transactions root of block
     *  5 - receiptRoot - Receipts root of block
     *  6 - receipt - Receipt of the reference transaction
     *  7 - receiptProof - Merkle proof of the reference receipt
     *  8 - branchMask - 32 bits denoting the path of receipt in merkle tree
     *  9 - receiptLogIndex - Log Index to read from the receipt
     */
    function _validateAndExtractMessage(bytes memory proofData) internal returns (bytes memory) {
        address childTunnel = s().fxChildTunnel;

        if (childTunnel == address(0)) revert FxChildUnset();

        ExitPayloadReader.ExitPayload memory payload = proofData.toExitPayload();

        bytes memory branchMaskBytes = payload.getBranchMaskAsBytes();
        uint256 blockNumber = payload.getBlockNumber();
        // checking if exit has already been processed
        // unique exit is identified using hash of (blockNumber, branchMask, receiptLogIndex)
        bytes32 exitHash = keccak256(
            abi.encodePacked(
                blockNumber,
                // first 2 nibbles are dropped while generating nibble array
                // this allows branch masks that are valid but bypass exitHash check (changing first 2 nibbles only)
                // so converting to nibble array and then hashing it
                MerklePatriciaProof._getNibbleArray(branchMaskBytes),
                payload.getReceiptLogIndex()
            )
        );

        if (s().processedExits[exitHash]) revert ExitAlreadyProcessed();

        s().processedExits[exitHash] = true;

        ExitPayloadReader.Receipt memory receipt = payload.getReceipt();
        ExitPayloadReader.Log memory log = receipt.getLog();

        // check child tunnel
        if (childTunnel != log.getEmitter()) revert InvalidFxChildTunnel();

        bytes32 receiptRoot = payload.getReceiptRoot();
        // verify receipt inclusion
        if (!MerklePatriciaProof.verify(receipt.toBytes(), branchMaskBytes, payload.getReceiptProof(), receiptRoot))
            revert InvalidReceiptProof();

        (bytes32 headerRoot, uint256 startBlock, , , ) = checkpointManager.headerBlocks(payload.getHeaderNumber());

        bytes32 leaf = keccak256(
            abi.encodePacked(blockNumber, payload.getBlockTime(), payload.getTxRoot(), receiptRoot)
        );

        if (!leaf.checkMembership(blockNumber - startBlock, headerRoot, payload.getBlockProof()))
            revert InvalidHeader();

        ExitPayloadReader.LogTopics memory topics = log.getTopics();

        if (bytes32(topics.getField(0).toUint()) != SEND_MESSAGE_EVENT_SELECTOR) revert InvalidSelector();

        // received message data
        bytes memory message = abi.decode(log.getData(), (bytes)); // event decodes params again, so decoding bytes to get message

        return message;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Merkle {
    function checkMembership(
        bytes32 leaf,
        uint256 index,
        bytes32 rootHash,
        bytes memory proof
    ) internal pure returns (bool) {
        require(proof.length % 32 == 0, "Invalid proof length");
        uint256 proofHeight = proof.length / 32;
        // Proof of size n means, height of the tree is n+1.
        // In a tree of height n+1, max #leafs possible is 2 ^ n
        require(index < 2**proofHeight, "Leaf index is too big");

        bytes32 proofElement;
        bytes32 computedHash = leaf;
        for (uint256 i = 32; i <= proof.length; i += 32) {
            assembly {
                proofElement := mload(add(proof, i))
            }

            if (index % 2 == 0) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }

            index = index / 2;
        }
        return computedHash == rootHash;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 * @author Hamdi Allam [email protected]
 * Please reach out with any questions or concerns
 */
library RLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START = 0xb8;
    uint8 constant LIST_SHORT_START = 0xc0;
    uint8 constant LIST_LONG_START = 0xf8;
    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint256 len;
        uint256 memPtr;
    }

    struct Iterator {
        RLPItem item; // Item that's being iterated over.
        uint256 nextPtr; // Position of the next item in the list.
    }

    /*
     * @dev Returns the next element in the iteration. Reverts if it has not next element.
     * @param self The iterator.
     * @return The next element in the iteration.
     */
    function next(Iterator memory self) internal pure returns (RLPItem memory) {
        require(hasNext(self));

        uint256 ptr = self.nextPtr;
        uint256 itemLength = _itemLength(ptr);
        self.nextPtr = ptr + itemLength;

        return RLPItem(itemLength, ptr);
    }

    /*
     * @dev Returns true if the iteration has more elements.
     * @param self The iterator.
     * @return true if the iteration has more elements.
     */
    function hasNext(Iterator memory self) internal pure returns (bool) {
        RLPItem memory item = self.item;
        return self.nextPtr < item.memPtr + item.len;
    }

    /*
     * @param item RLP encoded bytes
     */
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        uint256 memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

    /*
     * @dev Create an iterator. Reverts if item is not a list.
     * @param self The RLP item.
     * @return An 'Iterator' over the item.
     */
    function iterator(RLPItem memory self) internal pure returns (Iterator memory) {
        require(isList(self));

        uint256 ptr = self.memPtr + _payloadOffset(self.memPtr);
        return Iterator(self, ptr);
    }

    /*
     * @param item RLP encoded bytes
     */
    function rlpLen(RLPItem memory item) internal pure returns (uint256) {
        return item.len;
    }

    /*
     * @param item RLP encoded bytes
     */
    function payloadLen(RLPItem memory item) internal pure returns (uint256) {
        return item.len - _payloadOffset(item.memPtr);
    }

    /*
     * @param item RLP encoded list in bytes
     */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory) {
        require(isList(item));

        uint256 items = numItems(item);
        RLPItem[] memory result = new RLPItem[](items);

        uint256 memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 dataLen;
        for (uint256 i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr);
            memPtr = memPtr + dataLen;
        }

        return result;
    }

    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        if (item.len == 0) return false;

        uint8 byte0;
        uint256 memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START) return false;
        return true;
    }

    /*
     * @dev A cheaper version of keccak256(toRlpBytes(item)) that avoids copying memory.
     * @return keccak256 hash of RLP encoded bytes.
     */
    function rlpBytesKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        uint256 ptr = item.memPtr;
        uint256 len = item.len;
        bytes32 result;
        assembly {
            result := keccak256(ptr, len)
        }
        return result;
    }

    function payloadLocation(RLPItem memory item) internal pure returns (uint256, uint256) {
        uint256 offset = _payloadOffset(item.memPtr);
        uint256 memPtr = item.memPtr + offset;
        uint256 len = item.len - offset; // data length
        return (memPtr, len);
    }

    /*
     * @dev A cheaper version of keccak256(toBytes(item)) that avoids copying memory.
     * @return keccak256 hash of the item payload.
     */
    function payloadKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        (uint256 memPtr, uint256 len) = payloadLocation(item);
        bytes32 result;
        assembly {
            result := keccak256(memPtr, len)
        }
        return result;
    }

    /** RLPItem conversions into data types **/

    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);
        if (result.length == 0) return result;

        uint256 ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    // any non-zero byte is considered true
    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1);
        uint256 result;
        uint256 memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        return result == 0 ? false : true;
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix
        require(item.len == 21);

        return address(uint160(toUint(item)));
    }

    function toUint(RLPItem memory item) internal pure returns (uint256) {
        require(item.len > 0 && item.len <= 33);

        uint256 offset = _payloadOffset(item.memPtr);
        uint256 len = item.len - offset;

        uint256 result;
        uint256 memPtr = item.memPtr + offset;
        assembly {
            result := mload(memPtr)

            // shfit to the correct location if neccesary
            if lt(len, 32) {
                result := div(result, exp(256, sub(32, len)))
            }
        }

        return result;
    }

    // enforces 32 byte length
    function toUintStrict(RLPItem memory item) internal pure returns (uint256) {
        // one byte prefix
        require(item.len == 33);

        uint256 result;
        uint256 memPtr = item.memPtr + 1;
        assembly {
            result := mload(memPtr)
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        require(item.len > 0);

        uint256 offset = _payloadOffset(item.memPtr);
        uint256 len = item.len - offset; // data length
        bytes memory result = new bytes(len);

        uint256 destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(item.memPtr + offset, destPtr, len);
        return result;
    }

    /*
     * Private Helpers
     */

    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) private pure returns (uint256) {
        if (item.len == 0) return 0;

        uint256 count = 0;
        uint256 currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
            currPtr = currPtr + _itemLength(currPtr); // skip over an item
            count++;
        }

        return count;
    }

    // @return entire rlp item byte length
    function _itemLength(uint256 memPtr) private pure returns (uint256) {
        uint256 itemLen;
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) itemLen = 1;
        else if (byte0 < STRING_LONG_START) itemLen = byte0 - STRING_SHORT_START + 1;
        else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte
                /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                itemLen := add(dataLen, add(byteLen, 1))
            }
        } else if (byte0 < LIST_LONG_START) {
            itemLen = byte0 - LIST_SHORT_START + 1;
        } else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        return itemLen;
    }

    // @return number of bytes until the data
    function _payloadOffset(uint256 memPtr) private pure returns (uint256) {
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) return 0;
        else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START)) return 1;
        else if (byte0 < LIST_SHORT_START)
            // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        else return byte0 - (LIST_LONG_START - 1) + 1;
    }

    /*
     * @param src Pointer to source
     * @param dest Pointer to destination
     * @param len Amount of memory to copy from the source
     */
    function copy(
        uint256 src,
        uint256 dest,
        uint256 len
    ) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        if (len == 0) return;

        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint256 mask = 256**(WORD_SIZE - len) - 1;

        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RLPReader} from "./RLPReader.sol";

library ExitPayloadReader {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    uint8 constant WORD_SIZE = 32;

    struct ExitPayload {
        RLPReader.RLPItem[] data;
    }

    struct Receipt {
        RLPReader.RLPItem[] data;
        bytes raw;
        uint256 logIndex;
    }

    struct Log {
        RLPReader.RLPItem data;
        RLPReader.RLPItem[] list;
    }

    struct LogTopics {
        RLPReader.RLPItem[] data;
    }

    // copy paste of private copy() from RLPReader to avoid changing of existing contracts
    function copy(
        uint256 src,
        uint256 dest,
        uint256 len
    ) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint256 mask = 256**(WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }

    function toExitPayload(bytes memory data) internal pure returns (ExitPayload memory) {
        RLPReader.RLPItem[] memory payloadData = data.toRlpItem().toList();

        return ExitPayload(payloadData);
    }

    function getHeaderNumber(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[0].toUint();
    }

    function getBlockProof(ExitPayload memory payload) internal pure returns (bytes memory) {
        return payload.data[1].toBytes();
    }

    function getBlockNumber(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[2].toUint();
    }

    function getBlockTime(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[3].toUint();
    }

    function getTxRoot(ExitPayload memory payload) internal pure returns (bytes32) {
        return bytes32(payload.data[4].toUint());
    }

    function getReceiptRoot(ExitPayload memory payload) internal pure returns (bytes32) {
        return bytes32(payload.data[5].toUint());
    }

    function getReceipt(ExitPayload memory payload) internal pure returns (Receipt memory receipt) {
        receipt.raw = payload.data[6].toBytes();
        RLPReader.RLPItem memory receiptItem = receipt.raw.toRlpItem();

        if (receiptItem.isList()) {
            // legacy tx
            receipt.data = receiptItem.toList();
        } else {
            // pop first byte before parsting receipt
            bytes memory typedBytes = receipt.raw;
            bytes memory result = new bytes(typedBytes.length - 1);
            uint256 srcPtr;
            uint256 destPtr;
            assembly {
                srcPtr := add(33, typedBytes)
                destPtr := add(0x20, result)
            }

            copy(srcPtr, destPtr, result.length);
            receipt.data = result.toRlpItem().toList();
        }

        receipt.logIndex = getReceiptLogIndex(payload);
        return receipt;
    }

    function getReceiptProof(ExitPayload memory payload) internal pure returns (bytes memory) {
        return payload.data[7].toBytes();
    }

    function getBranchMaskAsBytes(ExitPayload memory payload) internal pure returns (bytes memory) {
        return payload.data[8].toBytes();
    }

    function getBranchMaskAsUint(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[8].toUint();
    }

    function getReceiptLogIndex(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[9].toUint();
    }

    // Receipt methods
    function toBytes(Receipt memory receipt) internal pure returns (bytes memory) {
        return receipt.raw;
    }

    function getLog(Receipt memory receipt) internal pure returns (Log memory) {
        RLPReader.RLPItem memory logData = receipt.data[3].toList()[receipt.logIndex];
        return Log(logData, logData.toList());
    }

    // Log methods
    function getEmitter(Log memory log) internal pure returns (address) {
        return RLPReader.toAddress(log.list[0]);
    }

    function getTopics(Log memory log) internal pure returns (LogTopics memory) {
        return LogTopics(log.list[1].toList());
    }

    function getData(Log memory log) internal pure returns (bytes memory) {
        return log.list[2].toBytes();
    }

    function toRlpBytes(Log memory log) internal pure returns (bytes memory) {
        return log.data.toRlpBytes();
    }

    // LogTopics methods
    function getField(LogTopics memory topics, uint256 index) internal pure returns (RLPReader.RLPItem memory) {
        return topics.data[index];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RLPReader} from "./RLPReader.sol";

library MerklePatriciaProof {
    /*
     * @dev Verifies a merkle patricia proof.
     * @param value The terminating value in the trie.
     * @param encodedPath The path in the trie leading to value.
     * @param rlpParentNodes The rlp encoded stack of nodes.
     * @param root The root hash of the trie.
     * @return The boolean validity of the proof.
     */
    function verify(
        bytes memory value,
        bytes memory encodedPath,
        bytes memory rlpParentNodes,
        bytes32 root
    ) internal pure returns (bool) {
        RLPReader.RLPItem memory item = RLPReader.toRlpItem(rlpParentNodes);
        RLPReader.RLPItem[] memory parentNodes = RLPReader.toList(item);

        bytes memory currentNode;
        RLPReader.RLPItem[] memory currentNodeList;

        bytes32 nodeKey = root;
        uint256 pathPtr = 0;

        bytes memory path = _getNibbleArray(encodedPath);
        if (path.length == 0) {
            return false;
        }

        for (uint256 i = 0; i < parentNodes.length; i++) {
            if (pathPtr > path.length) {
                return false;
            }

            currentNode = RLPReader.toRlpBytes(parentNodes[i]);
            if (nodeKey != keccak256(currentNode)) {
                return false;
            }
            currentNodeList = RLPReader.toList(parentNodes[i]);

            if (currentNodeList.length == 17) {
                if (pathPtr == path.length) {
                    if (keccak256(RLPReader.toBytes(currentNodeList[16])) == keccak256(value)) {
                        return true;
                    } else {
                        return false;
                    }
                }

                uint8 nextPathNibble = uint8(path[pathPtr]);
                if (nextPathNibble > 16) {
                    return false;
                }
                nodeKey = bytes32(RLPReader.toUintStrict(currentNodeList[nextPathNibble]));
                pathPtr += 1;
            } else if (currentNodeList.length == 2) {
                uint256 traversed = _nibblesToTraverse(RLPReader.toBytes(currentNodeList[0]), path, pathPtr);
                if (pathPtr + traversed == path.length) {
                    //leaf node
                    if (keccak256(RLPReader.toBytes(currentNodeList[1])) == keccak256(value)) {
                        return true;
                    } else {
                        return false;
                    }
                }

                //extension node
                if (traversed == 0) {
                    return false;
                }

                pathPtr += traversed;
                nodeKey = bytes32(RLPReader.toUintStrict(currentNodeList[1]));
            } else {
                return false;
            }
        }

        return false;
    }

    function _nibblesToTraverse(
        bytes memory encodedPartialPath,
        bytes memory path,
        uint256 pathPtr
    ) private pure returns (uint256) {
        uint256 len = 0;
        // encodedPartialPath has elements that are each two hex characters (1 byte), but partialPath
        // and slicedPath have elements that are each one hex character (1 nibble)
        bytes memory partialPath = _getNibbleArray(encodedPartialPath);
        bytes memory slicedPath = new bytes(partialPath.length);

        // pathPtr counts nibbles in path
        // partialPath.length is a number of nibbles
        for (uint256 i = pathPtr; i < pathPtr + partialPath.length; i++) {
            bytes1 pathNibble = path[i];
            slicedPath[i - pathPtr] = pathNibble;
        }

        if (keccak256(partialPath) == keccak256(slicedPath)) {
            len = partialPath.length;
        } else {
            len = 0;
        }
        return len;
    }

    // bytes b must be hp encoded
    function _getNibbleArray(bytes memory b) internal pure returns (bytes memory) {
        bytes memory nibbles = "";
        if (b.length > 0) {
            uint8 offset;
            uint8 hpNibble = uint8(_getNthNibbleOfBytes(0, b));
            if (hpNibble == 1 || hpNibble == 3) {
                nibbles = new bytes(b.length * 2 - 1);
                bytes1 oddNibble = _getNthNibbleOfBytes(1, b);
                nibbles[0] = oddNibble;
                offset = 1;
            } else {
                nibbles = new bytes(b.length * 2 - 2);
                offset = 0;
            }

            for (uint256 i = offset; i < nibbles.length; i++) {
                nibbles[i] = _getNthNibbleOfBytes(i - offset + 2, b);
            }
        }
        return nibbles;
    }

    function _getNthNibbleOfBytes(uint256 n, bytes memory str) private pure returns (bytes1) {
        return bytes1(n % 2 == 0 ? uint8(str[n / 2]) / 0x10 : uint8(str[n / 2]) % 0x10);
    }
}