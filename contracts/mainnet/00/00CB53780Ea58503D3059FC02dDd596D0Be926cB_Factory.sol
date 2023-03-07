// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
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

/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: BUSL-1.1
 */
pragma solidity ^0.8.13;

import { Proxy } from "./Proxy.sol";
import { IVault } from "./interfaces/IVault.sol";
import { IMainRegistry } from "./interfaces/IMainRegistry.sol";
import { IFactory } from "./interfaces/IFactory.sol";
import { ERC721 } from "../lib/solmate/src/tokens/ERC721.sol";
import { Strings } from "./utils/Strings.sol";
import { MerkleProofLib } from "./utils/MerkleProofLib.sol";
import { FactoryGuardian } from "./security/FactoryGuardian.sol";

/**
 * @title Factory.
 * @author Pragma Labs
 * @notice The Lending pool has the logic to deploy and upgrade Arcadia Vaults.
 * @dev The Factory is an ERC721 contract that maps each id to an Arcadia Vault.
 */
contract Factory is IFactory, ERC721, FactoryGuardian {
    using Strings for uint256;

    /* //////////////////////////////////////////////////////////////
                                STORAGE
    ////////////////////////////////////////////////////////////// */

    // The latest Vault version, new deployed vault use the latest version by default.
    uint16 public latestVaultVersion;
    // The baseURI of the ERC721 tokens.
    string public baseURI;
    // Array of all Arcadia Vault contract addresses.
    address[] public allVaults;

    // Map vaultVersion => flag.
    mapping(uint256 => bool) public vaultVersionBlocked;
    // Map vaultAddress => vaultIndex.
    mapping(address => uint256) public vaultIndex;
    // Map vaultVersion => versionInfo.
    mapping(uint256 => VaultVersionInfo) public vaultDetails;

    // Struct with additional information for a specific Vault version.
    struct VaultVersionInfo {
        address registry; // The contract address of the MainRegistry.
        address logic; // The contract address of the Vault logic.
        bytes32 versionRoot; // The Merkle root of the merkle tree of all the compatible vault versions.
        bytes data; // Arbitrary data, can contain instructions to execute when updating Vault to new logic.
    }

    /* //////////////////////////////////////////////////////////////
                                EVENTS
    ////////////////////////////////////////////////////////////// */

    event VaultUpgraded(address indexed vaultAddress, uint16 oldVersion, uint16 indexed newVersion);
    event VaultVersionAdded(
        uint16 indexed version, address indexed registry, address indexed logic, bytes32 versionRoot
    );
    event VaultVersionBlocked(uint16 version);

    /* //////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    ////////////////////////////////////////////////////////////// */

    constructor() ERC721("Arcadia Vault", "ARCADIA") { }

    /*///////////////////////////////////////////////////////////////
                          VAULT MANAGEMENT
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to create a new Vault.
     * @param salt A salt to be used to generate the hash.
     * @param vaultVersion The Vault version.
     * @param baseCurrency The Base-currency in which the vault is denominated.
     * @return vault The contract address of the proxy contract of the newly deployed vault.
     * @dev Safe to cast a uint256 to a bytes32 since the space of both is 2^256.
     */
    function createVault(uint256 salt, uint16 vaultVersion, address baseCurrency)
        external
        whenCreateNotPaused
        returns (address vault)
    {
        vaultVersion = vaultVersion == 0 ? latestVaultVersion : vaultVersion;

        require(vaultVersion <= latestVaultVersion, "FTRY_CV: Unknown vault version");
        require(!vaultVersionBlocked[vaultVersion], "FTRY_CV: Vault version blocked");

        // Hash tx.origin with the user provided salt to avoid front-running vault deployment with an identical salt.
        // We use tx.origin instead of msg.sender so that deployments through a third party contract is not vulnerable to front-running.
        vault = address(new Proxy{salt: keccak256(abi.encodePacked(salt, tx.origin))}(vaultDetails[vaultVersion].logic));

        IVault(vault).initialize(msg.sender, vaultDetails[vaultVersion].registry, uint16(vaultVersion), baseCurrency);

        allVaults.push(vault);
        vaultIndex[vault] = allVaults.length;

        _mint(msg.sender, allVaults.length);

        emit VaultUpgraded(vault, 0, vaultVersion);
    }

    /**
     * @notice View function returning if an address is a vault.
     * @param vault The address to be checked.
     * @return bool Whether the address is a vault or not.
     */
    function isVault(address vault) public view returns (bool) {
        return vaultIndex[vault] > 0;
    }

    /**
     * @notice Returns the owner of a vault.
     * @param vault The Vault address.
     * @return owner_ The Vault owner.
     * @dev Function does not revert when a non-existing vault is passed, but returns zero-address as owner.
     */
    function ownerOfVault(address vault) external view returns (address owner_) {
        owner_ = _ownerOf[vaultIndex[vault]];
    }

    /**
     * @notice This function allows vault owners to upgrade the logic of the vault.
     * @param vault Vault that needs to be upgraded.
     * @param version The vaultVersion to upgrade to.
     * @param proofs The merkle proofs that prove the compatibility of the upgrade from current to new vaultVersion.
     * @dev As each vault is a proxy, the implementation of the proxy can be changed by the owner of the vault.
     * Checks are done such that only compatible versions can be upgraded to.
     * Merkle proofs and their leaves can be found on https://www.github.com/arcadia-finance.
     */
    function upgradeVaultVersion(address vault, uint16 version, bytes32[] calldata proofs) external {
        require(_ownerOf[vaultIndex[vault]] == msg.sender, "FTRY_UVV: Only Owner");
        require(!vaultVersionBlocked[version], "FTRY_UVV: Vault version blocked");
        uint256 currentVersion = IVault(vault).vaultVersion();

        bool canUpgrade = MerkleProofLib.verify(
            proofs, getVaultVersionRoot(), keccak256(abi.encodePacked(currentVersion, uint256(version)))
        );

        require(canUpgrade, "FTR_UVV: Version not allowed");

        IVault(vault).upgradeVault(
            vaultDetails[version].logic, vaultDetails[version].registry, version, vaultDetails[version].data
        );

        emit VaultUpgraded(vault, uint16(currentVersion), version);
    }

    /**
     * @notice Function to get the latest versioning root.
     * @return The latest versioning root.
     * @dev The versioning root is the root of the merkle tree of all the compatible vault versions.
     * The root is updated every time a new vault version added. The root is used to verify the
     * proofs when a vault is being upgraded.
     */
    function getVaultVersionRoot() public view returns (bytes32) {
        return vaultDetails[latestVaultVersion].versionRoot;
    }

    /**
     * @notice Function used to transfer a vault between users.
     * @param from The sender.
     * @param to The target.
     * @param vault The address of the vault that is transferred.
     * @dev This method transfers a vault not on id but on address and also transfers the vault proxy contract to the new owner.
     */
    function safeTransferFrom(address from, address to, address vault) public {
        uint256 id = vaultIndex[vault];
        IVault(allVaults[id - 1]).transferOwnership(to);
        super.safeTransferFrom(from, to, id);
    }

    /**
     * @notice Function used to transfer a vault between users.
     * @param from The sender.
     * @param to The target.
     * @param id The id of the vault that is about to be transferred.
     * @dev This method overwrites the safeTransferFrom function in ERC721.sol to also transfer the vault proxy contract to the new owner.
     */
    function safeTransferFrom(address from, address to, uint256 id) public override {
        IVault(allVaults[id - 1]).transferOwnership(to);
        super.safeTransferFrom(from, to, id);
    }

    /**
     * @notice Function used to transfer a vault between users.
     * @param from The sender.
     * @param to The target.
     * @param id The id of the vault that is about to be transferred.
     * @param data additional data, only used for onERC721Received.
     * @dev This method overwrites the safeTransferFrom function in ERC721.sol to also transfer the vault proxy contract to the new owner.
     */
    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) public override {
        IVault(allVaults[id - 1]).transferOwnership(to);
        super.safeTransferFrom(from, to, id, data);
    }

    /**
     * @notice Function used to transfer a vault between users.
     * @param from The sender.
     * @param to The target.
     * @param id The id of the vault that is about to be transferred.
     * @dev This method overwrites the safeTransferFrom function in ERC721.sol to also transfer the vault proxy contract to the new owner.
     */
    function transferFrom(address from, address to, uint256 id) public override {
        IVault(allVaults[id - 1]).transferOwnership(to);
        super.transferFrom(from, to, id);
    }

    /*///////////////////////////////////////////////////////////////
                    VAULT VERSION MANAGEMENT
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to set a new vault version with the contracts to be used for new deployed vaults.
     * @param registry The contract address of the Main Registry.
     * @param logic The contract address of the Vault logic.
     * @param versionRoot The Merkle root of the merkle tree of all the compatible vault versions.
     * @param data Arbitrary data, can contain instructions to execute when updating Vault to new logic.
     * @dev Changing any of the contracts does NOT change the contracts for existing deployed vaults,
     * unless the vault owner explicitly chooses to upgrade their vault to a newer version
     * If a new Main Registry contract is set, all the BaseCurrencies currently stored in the Factory
     * are checked against the new Main Registry contract. If they do not match, the function reverts.
     */
    function setNewVaultInfo(address registry, address logic, bytes32 versionRoot, bytes calldata data)
        external
        onlyOwner
    {
        require(versionRoot != bytes32(0), "FTRY_SNVI: version root is zero");
        require(logic != address(0), "FTRY_SNVI: logic address is zero");

        //If there is a new Main Registry Contract, Check that baseCurrencies in factory and main registry match.
        if (vaultDetails[latestVaultVersion].registry != registry && latestVaultVersion != 0) {
            address oldRegistry = vaultDetails[latestVaultVersion].registry;
            uint256 oldCounter = IMainRegistry(oldRegistry).baseCurrencyCounter();
            uint256 newCounter = IMainRegistry(registry).baseCurrencyCounter();
            require(oldCounter <= newCounter, "FTRY_SNVI: counter mismatch");
            for (uint256 i; i < oldCounter;) {
                require(
                    IMainRegistry(oldRegistry).baseCurrencies(i) == IMainRegistry(registry).baseCurrencies(i),
                    "FTRY_SNVI: no baseCurrency match"
                );
                unchecked {
                    ++i;
                }
            }
        }

        unchecked {
            ++latestVaultVersion;
        }

        vaultDetails[latestVaultVersion].registry = registry;
        vaultDetails[latestVaultVersion].logic = logic;
        vaultDetails[latestVaultVersion].versionRoot = versionRoot;
        vaultDetails[latestVaultVersion].data = data;

        emit VaultVersionAdded(latestVaultVersion, registry, logic, versionRoot);
    }

    /**
     * @notice Function to block a certain vault logic version from being created as a new vault.
     * @param version The vault version to be phased out.
     * @dev Should any vault logic version be phased out,
     * this function can be used to block it from being created for new vaults.
     */
    function blockVaultVersion(uint256 version) external onlyOwner {
        require(version > 0 && version <= latestVaultVersion, "FTRY_BVV: Invalid version");
        vaultVersionBlocked[version] = true;

        emit VaultVersionBlocked(uint16(version));
    }

    /*///////////////////////////////////////////////////////////////
                    VAULT LIQUIDATION LOGIC
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Function called by a Vault at the start of a liquidation to transfer ownership to the Liquidator contract.
     * @param liquidator The contract address of the liquidator.
     * @dev This transfer bypasses the standard transferFrom and safeTransferFrom from the ERC-721 standard.
     */
    function liquidate(address liquidator) external whenLiquidateNotPaused {
        require(isVault(msg.sender), "FTRY: Not a vault");

        uint256 id = vaultIndex[msg.sender];
        address from = _ownerOf[id];
        unchecked {
            _balanceOf[from]--;
            _balanceOf[liquidator]++;
        }

        _ownerOf[id] = liquidator;

        delete getApproved[id];
        emit Transfer(from, liquidator, id);
    }

    /*///////////////////////////////////////////////////////////////
                        HELPER FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Function returns the total number of vaults.
     * @return numberOfVaults The total number of vaults.
     */
    function allVaultsLength() external view returns (uint256 numberOfVaults) {
        numberOfVaults = allVaults.length;
    }

    /*///////////////////////////////////////////////////////////////
                        ERC-721 LOGIC
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Function that stores a new base URI.
     * @dev tokenURI's of Arcadia Vaults are not meant to be immutable
     * and might be updated later to allow users to
     * choose/create their own vault art,
     * as such no URI freeze is added.
     * @param newBaseURI The new base URI to store.
     */
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    /**
     * @notice Function that returns the token URI as defined in the erc721 standard.
     * @param tokenId The id if the vault.
     * @return uri The token uri.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory uri) {
        require(_ownerOf[tokenId] != address(0), "ERC721Metadata: URI query for nonexistent token");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title Proxy
 * @author Pragma Labs
 * @dev Implementation based on ERC-1967: Proxy Storage Slots
 * See https://eips.ethereum.org/EIPS/eip-1967
 */
contract Proxy {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    struct AddressSlot {
        address value;
    }

    event Upgraded(address indexed implementation);

    constructor(address logic) payable {
        _getAddressSlot(_IMPLEMENTATION_SLOT).value = logic;
        emit Upgraded(logic);
    }

    /**
     * @dev Fallback function that delegates calls to the implementation address.
     * Will run if call data is empty.
     */
    receive() external payable virtual {
        _delegate(_getAddressSlot(_IMPLEMENTATION_SLOT).value);
    }

    /**
     * @dev Fallback function that delegates calls to the implementation address.
     * Will run if no other function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _delegate(_getAddressSlot(_IMPLEMENTATION_SLOT).value);
    }

    /*///////////////////////////////////////////////////////////////
                        IMPLEMENTATION LOGIC
    ///////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function _getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /*///////////////////////////////////////////////////////////////
                        DELEGATION LOGIC
    ///////////////////////////////////////////////////////////////*/

    /**
     * @dev Delegates the current call to `implementation`.
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}

/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.13;

interface IFactory {
    /**
     * @notice View function returning if an address is a vault.
     * @param vault The address to be checked.
     * @return bool Whether the address is a vault or not.
     */
    function isVault(address vault) external view returns (bool);

    /**
     * @notice Function used to transfer a vault between users.
     * @dev This method transfers a vault not on id but on address and also transfers the vault proxy contract to the new owner.
     * @param from sender.
     * @param to target.
     * @param vault The address of the vault that is about to be transferred.
     */
    function safeTransferFrom(address from, address to, address vault) external;

    /**
     * @notice Function called by a Vault at the start of a liquidation to transfer ownership.
     * @param liquidator The contract address of the liquidator.
     */
    function liquidate(address liquidator) external;
}

/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.13;

interface IMainRegistry {
    /**
     * @notice Returns number of baseCurrencies.
     * @return counter the number of baseCurrencies.
     */
    function baseCurrencyCounter() external view returns (uint256);

    /**
     * @notice Returns the Factory address.
     * @return factory The Factory address.
     */
    function factory() external view returns (address);

    /**
     * @notice Returns the contract of a baseCurrency.
     * @param index The index of the baseCurrency in the array baseCurrencies.
     * @return baseCurrency The baseCurrency address.
     */
    function baseCurrencies(uint256 index) external view returns (address);

    /**
     * @notice Checks if a contract is a baseCurrency.
     * @param baseCurrency The baseCurrency address.
     * @return boolean.
     */
    function isBaseCurrency(address baseCurrency) external view returns (bool);

    /**
     * @notice Checks if an action is allowed.
     * @param action The action address.
     * @return boolean.
     */
    function isActionAllowed(address action) external view returns (bool);

    /**
     * @notice Batch deposit multiple assets.
     * @param assetAddresses An array of addresses of the assets.
     * @param assetIds An array of asset ids.
     * @param amounts An array of amounts to be deposited.
     * @return assetTypes The identifiers of the types of the assets deposited.
     * 0 = ERC20
     * 1 = ERC721
     * 2 = ERC1155
     */
    function batchProcessDeposit(
        address[] calldata assetAddresses,
        uint256[] calldata assetIds,
        uint256[] calldata amounts
    ) external returns (uint256[] memory);

    /**
     * @notice Batch withdrawal multiple assets.
     * @param assetAddresses An array of addresses of the assets.
     * @param amounts An array of amounts to be withdrawn.
     * @return assetTypes The identifiers of the types of the assets withdrawn.
     * 0 = ERC20
     * 1 = ERC721
     * 2 = ERC1155
     */
    function batchProcessWithdrawal(
        address[] calldata assetAddresses,
        uint256[] calldata assetIds,
        uint256[] calldata amounts
    ) external returns (uint256[] memory);

    /**
     * @notice Calculate the total value of a list of assets denominated in a given BaseCurrency.
     * @param assetAddresses The List of token addresses of the assets.
     * @param assetIds The list of corresponding token Ids that needs to be checked.
     * @param assetAmounts The list of corresponding amounts of each Token-Id combination.
     * @param baseCurrency The contract address of the BaseCurrency.
     * @return valueInBaseCurrency The total value of the list of assets denominated in BaseCurrency.
     */
    function getTotalValue(
        address[] calldata assetAddresses,
        uint256[] calldata assetIds,
        uint256[] calldata assetAmounts,
        address baseCurrency
    ) external view returns (uint256);

    /**
     * @notice Calculate the collateralValue given the asset details in given baseCurrency.
     * @param assetAddresses The List of token addresses of the assets.
     * @param assetIds The list of corresponding token Ids that needs to be checked.
     * @param assetAmounts The list of corresponding amounts of each Token-Id combination.
     * @param baseCurrency An address of the BaseCurrency contract.
     * @return collateralValue Collateral value of the given assets denominated in BaseCurrency.
     */
    function getCollateralValue(
        address[] calldata assetAddresses,
        uint256[] calldata assetIds,
        uint256[] calldata assetAmounts,
        address baseCurrency
    ) external view returns (uint256);

    /**
     * @notice Calculate the getLiquidationValue given the asset details in given baseCurrency.
     * @param assetAddresses The List of token addresses of the assets.
     * @param assetIds The list of corresponding token Ids that needs to be checked.
     * @param assetAmounts The list of corresponding amounts of each Token-Id combination.
     * @param baseCurrency An address of the BaseCurrency contract.
     * @return liquidationValue Liquidation value of the given assets denominated in BaseCurrency.
     */
    function getLiquidationValue(
        address[] calldata assetAddresses,
        uint256[] calldata assetIds,
        uint256[] calldata assetAmounts,
        address baseCurrency
    ) external view returns (uint256);
}

/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.13;

interface IVault {
    /**
     * @notice Returns the Vault version.
     * @return version The Vault version.
     */
    function vaultVersion() external view returns (uint16);

    /**
     * @notice Initiates the variables of the vault.
     * @param owner The tx.origin: the sender of the 'createVault' on the factory.
     * @param registry The 'beacon' contract to which should be looked at for external logic.
     * @param vaultVersion The version of the vault logic.
     * @param baseCurrency The Base-currency in which the vault is denominated.
     */
    function initialize(address owner, address registry, uint16 vaultVersion, address baseCurrency) external;

    /**
     * @notice Stores a new address in the EIP1967 implementation slot & updates the vault version.
     * @param newImplementation The contract with the new vault logic.
     * @param newRegistry The MainRegistry for this specific implementation (might be identical as the old registry)
     * @param data Arbitrary data, can contain instructions to execute when updating Vault to new logic
     * @param newVersion The new version of the vault logic.
     */
    function upgradeVault(address newImplementation, address newRegistry, uint16 newVersion, bytes calldata data)
        external;

    /**
     * @notice Transfers ownership of the contract to a new account.
     * @param newOwner The new owner of the Vault.
     */
    function transferOwnership(address newOwner) external;

    /**
     * @notice Function called by Liquidator to start liquidation of the Vault.
     * @param openDebt The open debt taken by `originalOwner` at moment of liquidation at trustedCreditor.
     * @return originalOwner The original owner of this vault.
     * @return baseCurrency The baseCurrency in which the vault is denominated.
     * @return trustedCreditor The account or contract that is owed the debt.
     */
    function liquidateVault(uint256 openDebt) external returns (address, address, address);
}

/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: BUSL-1.1
 */

pragma solidity ^0.8.13;

import { Owned } from "lib/solmate/src/auth/Owned.sol";

/**
 * @title Guardian
 * @author Pragma Labs
 * @notice This module provides the base logic that allows authorized accounts to trigger an emergency stop.
 */
abstract contract BaseGuardian is Owned {
    /* //////////////////////////////////////////////////////////////
                                STORAGE
    ////////////////////////////////////////////////////////////// */

    // Address of the Guardian.
    address public guardian;
    // Last timestamp an emergency stop was triggered.
    uint256 public pauseTimestamp;

    /* //////////////////////////////////////////////////////////////
                                EVENTS
    ////////////////////////////////////////////////////////////// */

    event GuardianChanged(address indexed oldGuardian, address indexed newGuardian);

    /* //////////////////////////////////////////////////////////////
                                MODIFIERS
    ////////////////////////////////////////////////////////////// */

    /**
     * @dev Throws if called by any account other than the guardian.
     */
    modifier onlyGuardian() {
        require(msg.sender == guardian, "Guardian: Only guardian");
        _;
    }

    /* //////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    ////////////////////////////////////////////////////////////// */

    constructor() Owned(msg.sender) { }

    /* //////////////////////////////////////////////////////////////
                            GUARDIAN LOGIC
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice This function is used to set the guardian address
     * @param guardian_ The address of the new guardian.
     * @dev Allows onlyOwner to change the guardian address.
     */
    function changeGuardian(address guardian_) external onlyOwner {
        emit GuardianChanged(guardian, guardian_);
        guardian = guardian_;
    }

    /* //////////////////////////////////////////////////////////////
                            PAUSING LOGIC
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice This function is used to pause all the flags of the contract.
     * @dev This function can be called by the guardian to pause all functionality in the event of an emergency.
     * This function pauses repay, withdraw, borrow, deposit and liquidation.
     * This function can only be called by the guardian.
     * The guardian can only pause the protocol again after 32 days have past since the last pause.
     * This is to prevent that a malicious guardian can take user-funds hostage for an indefinite time.
     * @dev After the guardian has paused the protocol, the owner has 30 days to find potential problems,
     * find a solution and unpause the protocol. If the protocol is not unpaused after 30 days,
     * an emergency procedure can be started by any user to unpause the protocol.
     * All users have now at least a two-day window to withdraw assets and close positions before
     * the protocol can again be paused (after 32 days).
     */
    function pause() external virtual onlyGuardian { }

    /**
     * @notice This function is used to unPause all flags.
     * @dev If the protocol is not unpaused after 30 days, any user can unpause the protocol.
     * This ensures that no rogue owner or guardian can lock user funds for an indefinite amount of time.
     * All users have now at least a two-day window to withdraw assets and close positions before
     * the protocol can again be paused (after 32 days).
     */
    function unPause() external virtual { }
}

/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: BUSL-1.1
 */

pragma solidity ^0.8.13;

import { BaseGuardian } from "./BaseGuardian.sol";

/**
 * @title Factory Guardian
 * @author Pragma Labs
 * @notice This module provides the logic for the Factory that allows authorized accounts to trigger an emergency stop.
 */
abstract contract FactoryGuardian is BaseGuardian {
    /* //////////////////////////////////////////////////////////////
                                STORAGE
    ////////////////////////////////////////////////////////////// */

    // Flag indicating if the create() function is paused.
    bool public createPaused;
    // Flag indicating if the liquidate() function is paused.
    bool public liquidatePaused;

    /* //////////////////////////////////////////////////////////////
                                EVENTS
    ////////////////////////////////////////////////////////////// */

    event PauseUpdate(bool createPauseUpdate, bool liquidatePauseUpdate);

    /*
    //////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////
    */

    error FunctionIsPaused();

    /*
    //////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////
    */

    /**
     * @dev This modifier is used to restrict access to certain functions when the contract is paused for create vault.
     * It throws if create vault is paused.
     */
    modifier whenCreateNotPaused() {
        if (createPaused) revert FunctionIsPaused();
        _;
    }

    /**
     * @dev This modifier is used to restrict access to certain functions when the contract is paused for liquidate vaultq.
     * It throws if liquidate vault is paused.
     */
    modifier whenLiquidateNotPaused() {
        if (liquidatePaused) revert FunctionIsPaused();
        _;
    }

    /* //////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    ////////////////////////////////////////////////////////////// */

    constructor() { }

    /* //////////////////////////////////////////////////////////////
                            PAUSING LOGIC
    ////////////////////////////////////////////////////////////// */

    /**
     * @inheritdoc BaseGuardian
     */
    function pause() external override onlyGuardian {
        require(block.timestamp > pauseTimestamp + 32 days, "G_P: Cannot pause");
        createPaused = true;
        liquidatePaused = true;
        pauseTimestamp = block.timestamp;
        emit PauseUpdate(true, true);
    }

    /**
     * @notice This function is used to unpause one or more flags.
     * @param createPaused_ false when create functionality should be unPaused.
     * @param liquidatePaused_ false when liquidate functionality should be unPaused.
     * @dev This function can unPause repay, withdraw, borrow, and deposit individually.
     * @dev Can only update flags from paused (true) to unPaused (false), cannot be used the other way around
     * (to set unPaused flags to paused).
     */
    function unPause(bool createPaused_, bool liquidatePaused_) external onlyOwner {
        createPaused = createPaused && createPaused_;
        liquidatePaused = liquidatePaused && liquidatePaused_;
        emit PauseUpdate(createPaused, liquidatePaused);
    }

    /**
     * @inheritdoc BaseGuardian
     */
    function unPause() external override {
        require(block.timestamp > pauseTimestamp + 30 days, "G_UP: Cannot unPause");
        if (createPaused || liquidatePaused) {
            createPaused = false;
            liquidatePaused = false;
            emit PauseUpdate(false, false);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Gas optimized verification of proof of inclusion for a leaf in a Merkle tree.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/MerkleProof.sol)
library MerkleProofLib {
    function verify(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool isValid) {
        assembly {
            if proof.length {
                // Left shift by 5 is equivalent to multiplying by 0x20.
                let end := add(proof.offset, shl(5, proof.length))
                // Initialize `offset` to the offset of `proof` in the calldata.
                let offset := proof.offset
                // Iterate over proof elements to compute root hash.
                // prettier-ignore
                for { } 1 { } {
                    // Slot of `leaf` in scratch space.
                    // If the condition is true: 0x20, otherwise: 0x00.
                    let scratch := shl(5, gt(leaf, calldataload(offset)))
                    // Store elements to hash contiguously in scratch space.
                    // Scratch space is 64 bytes (0x00 - 0x3f) and both elements are 32 bytes.
                    mstore(scratch, leaf)
                    mstore(xor(scratch, 0x20), calldataload(offset))
                    // Reuse `leaf` to store the hash to reduce stack operations.
                    leaf := keccak256(0x00, 0x40)
                    offset := add(offset, 0x20)
                    // prettier-ignore
                    if iszero(lt(offset, end)) { break }
                }
            }
            isValid := eq(leaf, root)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

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
}