// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "../../lib/child/proxy/UUPSUpgrade.sol";
import "../../lib/child/ERC721UDS.sol";

contract MockERC721UDS is UUPSUpgrade, ERC721UDS {
    function init(string memory _name, string memory _symbol) external initializer {
        __ERC721UDS_init(_name, _symbol);
    }

    function proxiableVersion() public pure override returns (uint256) {
        return 1;
    }

    function _authorizeUpgrade() internal virtual override {}

    function tokenURI(uint256) public pure virtual override returns (string memory) {}

    function mint(address to, uint256 tokenId) public virtual {
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) public virtual {
        _burn(tokenId);
    }

    function safeMint(address to, uint256 tokenId) public virtual {
        _safeMint(to, tokenId);
    }

    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual {
        _safeMint(to, tokenId, data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC1822Versioned} from "./ERC1822Versioned.sol";
import {ERC1967, DIAMOND_STORAGE_ERC1967_UPGRADE} from "./ERC1967UDS.sol";

/* ------------- UUPSUpgrade ------------- */

error NotProxyCall();
error CallerNotOwner();
error DelegateCallNotAllowed();

abstract contract UUPSUpgrade is ERC1967, ERC1822Versioned {
    address private immutable __implementation = address(this);

    /* ------------- External ------------- */

    function upgradeTo(address logic) external payable onlyProxy {
        _authorizeUpgrade();
        _upgradeToAndCall(logic, "");
    }

    function upgradeToAndCall(address logic, bytes memory data) external payable onlyProxy {
        _authorizeUpgrade();
        _upgradeToAndCall(logic, data);
    }

    /* ------------- View ------------- */

    function proxiableUUID() external view notDelegated returns (bytes32) {
        return DIAMOND_STORAGE_ERC1967_UPGRADE;
    }

    /* ------------- Virtual ------------- */

    function _authorizeUpgrade() internal virtual;

    /* ------------- Modifier ------------- */

    modifier onlyProxy() {
        if (address(this) == __implementation) revert NotProxyCall();
        _;
    }

    modifier notDelegated() {
        if (address(this) != __implementation) revert DelegateCallNotAllowed();
        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {InitializableUDS} from "./InitializableUDS.sol";

/* ------------- Diamond Storage ------------- */

// keccak256("diamond.storage.erc721") == 0xf2dec0acaef95de6625646379d631adff4db9f6c79b84a31adcb9a23bf6cea78;
bytes32 constant DIAMOND_STORAGE_ERC721 = 0xf2dec0acaef95de6625646379d631adff4db9f6c79b84a31adcb9a23bf6cea78;

struct ERC721DS {
    string name;
    string symbol;
    mapping(uint256 => address) owners;
    mapping(address => uint256) balances;
    mapping(uint256 => address) getApproved;
    mapping(address => mapping(address => bool)) isApprovedForAll;
}

function ds() pure returns (ERC721DS storage diamondStorage) {
    assembly {
        diamondStorage.slot := DIAMOND_STORAGE_ERC721
    }
}

/* ------------- Errors ------------- */

error CallerNotOwnerNorApproved();
error NonexistentToken();
error NonERC721Receiver();

error BalanceOfZeroAddress();

error MintExistingToken();
error MintToZeroAddress();
error MintZeroQuantity();
error MintExceedsMaxSupply();
error MintExceedsMaxPerWallet();

error TransferFromIncorrectOwner();
error TransferToZeroAddress();

/* ------------- Contract ------------- */

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author phaze (https://github.com/0xPhaze)
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721UDS is InitializableUDS {
    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /* ------------- Init ------------- */

    function __ERC721UDS_init(string memory name_, string memory symbol_) internal onlyInitializing {
        ds().name = name_;
        ds().symbol = symbol_;
    }

    /* ------------- Public ------------- */

    function approve(address spender, uint256 id) public virtual {
        address owner = ds().owners[id];

        if (msg.sender != owner && !ds().isApprovedForAll[owner][msg.sender]) revert CallerNotOwnerNorApproved();

        ds().getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        ds().isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        if (to == address(0)) revert TransferToZeroAddress();
        if (from != ds().owners[id]) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (msg.sender == from ||
            ds().isApprovedForAll[from][msg.sender] ||
            ds().getApproved[id] == msg.sender);

        if (!isApprovedOrOwner) revert CallerNotOwnerNorApproved();

        unchecked {
            ds().balances[from]--;
            ds().balances[to]++;
        }

        ds().owners[id] = to;

        delete ds().getApproved[id];

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

    /* ------------- View ------------- */

    function tokenURI(uint256 id) public view virtual returns (string memory);

    function name() external view returns (string memory) {
        return ds().name;
    }

    function symbol() external view returns (string memory) {
        return ds().symbol;
    }

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        if ((owner = ds().owners[id]) == address(0)) revert NonexistentToken();
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) revert BalanceOfZeroAddress();

        return ds().balances[owner];
    }

    function getApproved(uint256 id) public view returns (address) {
        return ds().getApproved[id];
    }

    function isApprovedForAll(address operator, address owner) public view returns (bool) {
        return ds().isApprovedForAll[operator][owner];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /* ------------- Internal ------------- */

    function _mint(address to, uint256 id) internal virtual {
        if (to == address(0)) revert MintToZeroAddress();
        if (ds().owners[id] != address(0)) revert MintExistingToken();

        unchecked {
            ds().balances[to]++;
        }

        ds().owners[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ds().owners[id];

        if (owner == address(0)) revert NonexistentToken();

        unchecked {
            ds().balances[owner]--;
        }

        delete ds().owners[id];
        delete ds().getApproved[id];

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
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
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

interface IERC1822Versioned {
    function proxiableVersion() external view returns (uint256);

    function proxiableUUID() external view returns (bytes32);
}

abstract contract ERC1822Versioned is IERC1822Versioned {
    function proxiableVersion() public view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC1822Versioned} from "./ERC1822Versioned.sol";

/* ------------- Diamond Storage ------------- */

// keccak256("eip1967.proxy.implementation") - 1 = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
bytes32 constant DIAMOND_STORAGE_ERC1967_UPGRADE = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

struct ERC1967UpgradeDS {
    address implementation;
    uint256 version;
}

function ds() pure returns (ERC1967UpgradeDS storage diamondStorage) {
    assembly {
        diamondStorage.slot := DIAMOND_STORAGE_ERC1967_UPGRADE
    }
}

/* ------------- Errors ------------- */

error InvalidUUID();
error InvalidOwner();
error NotAContract();
error InvalidVersion();

/* ------------- ERC1967 ------------- */

abstract contract ERC1967 {
    event Upgraded(address indexed implementation);

    function _upgradeToAndCall(address logic, bytes memory data) internal {
        if (logic.code.length == 0) revert NotAContract();

        bytes32 uuid = IERC1822Versioned(logic).proxiableUUID();
        uint256 newVersion = IERC1822Versioned(logic).proxiableVersion();

        if (newVersion <= ds().version) revert InvalidVersion();
        if (uuid != DIAMOND_STORAGE_ERC1967_UPGRADE) revert InvalidUUID();

        ds().implementation = logic;

        emit Upgraded(logic);

        if (data.length != 0) _delegateCall(logic, data);

        ds().version = newVersion;
    }

    function _delegateCall(address logic, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = logic.delegatecall(data);

        if (success) return returndata;

        assembly {
            let returndata_size := mload(returndata)
            revert(add(32, returndata), returndata_size)
        }
    }
}

/* ------------- ERC1967Proxy ------------- */

contract ERC1967Proxy is ERC1967 {
    constructor(address logic, bytes memory data) payable {
        // ownableDS().owner = msg.sender; // @note: should move to __init() and make user responsible?
        _upgradeToAndCall(logic, data);
    }

    fallback() external payable {
        // address implementation = ds().implementation;

        assembly {
            let implementation := sload(DIAMOND_STORAGE_ERC1967_UPGRADE)

            calldatacopy(0, 0, calldatasize())

            let success := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch success
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC1822Versioned} from "./proxy/ERC1822Versioned.sol";
import {ds as erc1967UpgradeDS} from "./proxy/ERC1967UDS.sol";

/* ------------- Diamond Storage ------------- */

// keccak256("diamond.storage.initializable") == 0xa1fa48a92a6877bac95365e8033cc774fa4afedc9e943ab965e4c2a7a59613ee;
bytes32 constant DIAMOND_STORAGE_INITIALIZABLE = 0xa1fa48a92a6877bac95365e8033cc774fa4afedc9e943ab965e4c2a7a59613ee;

struct InitializableDS {
    bool initializing;
}

function ds() pure returns (InitializableDS storage diamondStorage) {
    assembly {
        diamondStorage.slot := DIAMOND_STORAGE_INITIALIZABLE
    }
}

/* ------------- Errors ------------- */

error NotProxyCall();
error NotInitializing();
error InvalidProxiableVersion();

/* ------------- Contract ------------- */

abstract contract InitializableUDS is ERC1822Versioned {
    address private immutable __implementation = address(this);

    /* ------------- Modifier ------------- */

    modifier initializer() {
        if (address(this) == __implementation) revert NotProxyCall();
        if (proxiableVersion() <= erc1967UpgradeDS().version) revert InvalidProxiableVersion();

        ds().initializing = true;

        _;

        ds().initializing = false;
    }

    modifier onlyInitializing() {
        if (address(this) == __implementation) revert NotProxyCall();
        if (!ds().initializing) revert NotInitializing();
        _;
    }
}