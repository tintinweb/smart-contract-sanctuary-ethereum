// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * This is a generated dummy diamond implementation for compatibility with
 * etherscan. For full contract implementation, check out the diamond on louper:
 * https://louper.dev/diamond/0xc173ae57b7479b95EA9EF0B1A3C70a61e84d0F30?network=rinkeby
 */
enum FacetCutAction {
    Add,
    Replace,
    Remove
}
struct FacetCut {
    address facetAddress;
    FacetCutAction action;
    bytes4[] functionSelectors;
}
struct Facet {
    address facetAddress;
    bytes4[] functionSelectors;
}

contract ERC1967Upgrade {
    address Address = 0x962956885a86825Ee65F01dF7ceFc413436750ac;
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT =
        0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(
            newAdmin != address(0),
            "ERC1967: new admin is the zero address"
        );
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT =
        0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
}

library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot)
        internal
        pure
        returns (AddressSlot storage r)
    {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot)
        internal
        pure
        returns (BooleanSlot storage r)
    {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot)
        internal
        pure
        returns (Bytes32Slot storage r)
    {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot)
        internal
        pure
        returns (Uint256Slot storage r)
    {
        assembly {
            r.slot := slot
        }
    }
}

contract DummyDiamondImplementation is ERC1967Upgrade {
    function diamondCut(
        FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) external {}

    function facetAddress(bytes4 _functionSelector)
        external
        view
        returns (address facetAddress_)
    {}

    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_)
    {}

    function facetFunctionSelectors(address _facet)
        external
        view
        returns (bytes4[] memory _facetFunctionSelectors)
    {}

    function facets() external view returns (Facet[] memory facets_) {}

    function supportsInterface(bytes4 _interfaceId)
        external
        view
        returns (bool)
    {}

    function owner() external view returns (address owner_) {}

    function transferOwnership(address _newOwner) external {}

    function allowListEnabled() external view returns (bool) {}

    function disableAllowList() external {}

    function enableAllowList() external {}

    function updateAllowList(bytes32 allowListRoot) external {}

    function airdrop() external view returns (bool) {}

    function approve(address to, uint256 tokenId) external {}

    function balanceOf(address owner) external view returns (uint256) {}

    function burn(uint256 tokenId) external {}

    function getApproved(uint256 tokenId) external view returns (address) {}

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool)
    {}

    function maxMintPerAddress() external view returns (uint256) {}

    function maxMintPerTx() external view returns (uint256) {}

    function maxSupply() external view returns (uint256) {}

    function mint(address to, uint256 quantity) external payable {}

    function mint(
        address to,
        uint256 quantity,
        bytes32[] memory merkleProof
    ) external payable {}

    function name() external view returns (string memory) {}

    function ownerOf(uint256 tokenId) external view returns (address) {}

    function price() external view returns (uint256) {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external {}

    function setAirdrop(bool _airdrop) external {}

    function setApprovalForAll(address operator, bool approved) external {}

    function setMaxMintPerTx(uint256 _maxMintPerTx) external {}

    function setMaxSupply(uint256 _maxSupply) external {}

    function setName(string memory _name) external {}

    function setPrice(uint256 _price) external {}

    function setSymbol(string memory _symbol) external {}

    function setTokenURI(string memory tokenURI) external {}

    function symbol() external view returns (string memory) {}

    function tokenURI(uint256 tokenId) external view returns (string memory) {}

    function totalSupply() external view returns (uint256) {}

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {}

    function dummyImplementation() external view returns (address) {}

    function setDummyImplementation(address implementation) external {}

    function pause() external {}

    function paused() external view returns (bool) {}

    function unpause() external {}

    function addPayee(address account, uint256 shares_) external {}

    function payee(uint256 index) external view returns (address) {}

    function releasable(address account) external view returns (uint256) {}

    function releasable(address token, address account)
        external
        view
        returns (uint256)
    {}

    function release(address account) external {}

    function release(address token, address account) external {}

    function released(address token, address account)
        external
        view
        returns (uint256)
    {}

    function released(address account) external view returns (uint256) {}

    function shares(address account) external view returns (uint256) {}

    function totalReleased(address token) external view returns (uint256) {}

    function totalReleased() external view returns (uint256) {}

    function totalShares() external view returns (uint256) {}

    function contractURI() external view returns (string memory) {}

    function royaltyBurn(uint256 tokenId) external {}

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256)
    {}
}