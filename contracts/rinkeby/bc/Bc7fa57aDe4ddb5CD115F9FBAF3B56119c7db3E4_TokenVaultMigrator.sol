// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IAddressRegistry.sol";
import "../interfaces/IFNFTHandler.sol";

contract TokenVaultMigrator is Ownable, IAddressRegistry, IFNFTHandler {

    /// The active address registry
    address private provider;

    constructor(address _provider) Ownable() {
        provider = _provider;
    }

    function initialize(
        address lock_manager_,
        address liquidity_,
        address revest_token_,
        address token_vault_,
        address revest_,
        address fnft_,
        address metadata_,
        address admin_,
        address rewards_
    ) external override {}

    ///
    /// SETTERS
    ///

    function setAdmin(address admin) external override onlyOwner {}

    function setLockManager(address manager) external override onlyOwner {}

    function setTokenVault(address vault) external override onlyOwner {}
   
    function setRevest(address revest) external override onlyOwner {}

    function setRevestFNFT(address fnft) external override onlyOwner {}

    function setMetadataHandler(address metadata) external override onlyOwner {}

    function setDex(address dex) external override onlyOwner {}

    function setRevestToken(address token) external override onlyOwner {}

    function setRewardsHandler(address esc) external override onlyOwner {}

    function setLPs(address liquidToken) external override onlyOwner {}

    function setProvider(address _provider) external onlyOwner {
        provider = _provider;
    }

    ///
    /// GETTERS
    ///

    function getAdmin() external view override returns (address) {
        return IAddressRegistry(provider).getAdmin();
    }

    function getLockManager() external view override returns (address) {
        return IAddressRegistry(provider).getLockManager();
    }

    function getTokenVault() external view override returns (address) {
        return IAddressRegistry(provider).getTokenVault();
    }

    // Fools the old TokenVault into believing the new token vault can control it
    function getRevest() external view override returns (address) {
        return IAddressRegistry(provider).getTokenVault();
    }

    /// Fools the old TokenVault into believeing this contract is the FNFTHandler
    function getRevestFNFT() external view override returns (address) {
        return address(this);
    }

    function getMetadataHandler() external view override returns (address) {
        return IAddressRegistry(provider).getMetadataHandler();
    }

    function getRevestToken() external view override returns (address) {
        return IAddressRegistry(provider).getRevestToken();
    }

    function getDEX(uint index) external view override returns (address) {
        return IAddressRegistry(provider).getDEX(index);
    }

    function getRewardsHandler() external view override returns(address) {
        return IAddressRegistry(provider).getRewardsHandler();
    }

    function getLPs() external view override returns (address) {
        return IAddressRegistry(provider).getLPs();
    }

    function getAddress(bytes32 id) public view override returns (address) {
        return IAddressRegistry(provider).getAddress(id);
    }


    ///
    /// FNFTHandler mock methods
    ///

    function mint(address account, uint id, uint amount, bytes memory data) external override {}

    function mintBatchRec(address[] memory recipients, uint[] memory quantities, uint id, uint newSupply, bytes memory data) external override {}

    function mintBatch(address to, uint[] memory ids, uint[] memory amounts, bytes memory data) external override {}

    function setURI(string memory newuri) external override {}

    function burn(address account, uint id, uint amount) external override {}

    function burnBatch(address account, uint[] memory ids, uint[] memory amounts) external override {}

    function getBalance(address tokenHolder, uint id) external view override returns (uint) {
        return IFNFTHandler(IAddressRegistry(provider).getRevestFNFT()).getBalance(tokenHolder, id);
    }

    function getSupply(uint fnftId) external view override returns (uint supply) {
        supply = IFNFTHandler(IAddressRegistry(provider).getRevestFNFT()).getSupply(fnftId);
        supply = supply == 0 ? 1 : supply;
    }

    function getNextId() external view override returns (uint nextId) {
        nextId = IFNFTHandler(IAddressRegistry(provider).getRevestFNFT()).getNextId();
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

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

/**
 * @title Provider interface for Revest FNFTs
 * @dev
 *
 */
interface IAddressRegistry {

    function initialize(
        address lock_manager_,
        address liquidity_,
        address revest_token_,
        address token_vault_,
        address revest_,
        address fnft_,
        address metadata_,
        address admin_,
        address rewards_
    ) external;

    function getAdmin() external view returns (address);

    function setAdmin(address admin) external;

    function getLockManager() external view returns (address);

    function setLockManager(address manager) external;

    function getTokenVault() external view returns (address);

    function setTokenVault(address vault) external;

    function getRevestFNFT() external view returns (address);

    function setRevestFNFT(address fnft) external;

    function getMetadataHandler() external view returns (address);

    function setMetadataHandler(address metadata) external;

    function getRevest() external view returns (address);

    function setRevest(address revest) external;

    function getDEX(uint index) external view returns (address);

    function setDex(address dex) external;

    function getRevestToken() external view returns (address);

    function setRevestToken(address token) external;

    function getRewardsHandler() external view returns(address);

    function setRewardsHandler(address esc) external;

    function getAddress(bytes32 id) external view returns (address);

    function getLPs() external view returns (address);

    function setLPs(address liquidToken) external;

}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;


interface IFNFTHandler  {
    function mint(address account, uint id, uint amount, bytes memory data) external;

    function mintBatchRec(address[] memory recipients, uint[] memory quantities, uint id, uint newSupply, bytes memory data) external;

    function mintBatch(address to, uint[] memory ids, uint[] memory amounts, bytes memory data) external;

    function setURI(string memory newuri) external;

    function burn(address account, uint id, uint amount) external;

    function burnBatch(address account, uint[] memory ids, uint[] memory amounts) external;

    function getBalance(address tokenHolder, uint id) external view returns (uint);

    function getSupply(uint fnftId) external view returns (uint);

    function getNextId() external view returns (uint);
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