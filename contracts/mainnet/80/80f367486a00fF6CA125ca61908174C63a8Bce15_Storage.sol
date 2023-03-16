// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title IStorage
 * @notice Interface for Storage
 */
interface IStorage {

    /**
     * @notice Lets an authorised module add a guardian to a vault.
     * @param _vault - The target vault.
     * @param _guardian - The guardian to add.
     */
    function setGuardian(address _vault, address _guardian) external;

    /**
     * @notice Lets an authorised module revoke a guardian from a vault.
     * @param _vault - The target vault.
     */
    function revokeGuardian(address _vault) external;

    /**
     * @notice Function to be used to add heir address to bequeath vault ownership.
     * @param _vault - The target vault.
     */
    function setHeir(address _vault, address _newHeir) external;

    /**
     * @notice Function to be called when voting has to be toggled.
     * @param _vault - The target vault.
     */
    function toggleVoting(address _vault) external;

    /**
     * @notice Set or unsets lock for a vault contract.
     * @param _vault - The target vault.
     * @param _lock - Lock needed to be set.
     */
    function setLock(address _vault, bool _lock) external;

    /**
     * @notice Sets a new time delay for a vault contract.
     * @param _vault - The target vault.
     * @param _newTimeDelay - The new time delay.
     */
    function setTimeDelay(address _vault, uint256 _newTimeDelay) external;

    /**
     * @notice Checks if an account is a guardian for a vault.
     * @param _vault - The target vault.
     * @param _guardian - The account address to be checked.
     * @return true if the account is a guardian for a vault.
     */
    function isGuardian(address _vault, address _guardian) external view returns (bool);

    /**
     * @notice Returns guardian address.
     * @param _vault - The target vault.
     * @return the address of the guardian account if guardian is added else returns zero address.
     */
    function getGuardian(address _vault) external view returns (address);

    /**
     * @notice Returns boolean indicating state of the vault.
     * @param _vault - The target vault.
     * @return true if the vault is locked, else returns false.
     */
    function isLocked(address _vault) external view returns (bool);

    /**
     * @notice Returns boolean indicating if voting is enabled.
     * @param _vault - The target vault.
     * @return true if voting is enabled, else returns false.
     */
    function votingEnabled(address _vault) external view returns (bool);

    /**
     * @notice Returns uint256 time delay in seconds for a vault
     * @param _vault - The target vault.
     * @return uint256 time delay in seconds for a vault.
     */
    function getTimeDelay(address _vault) external view returns (uint256);

    /**
     * @notice Returns an heir address for a vault.
     * @param _vault - The target vault.
     */
    function getHeir(address _vault) external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IVault} from "../vault/IVault.sol";
import {IStorage} from "./IStorage.sol";

/**
 * @title Storage
 * @notice Base contract for the storage of a vault.
 */
contract Storage is IStorage{

    struct StorageConfig {
        uint256 timeDelay; // time delay in seconds which has to be expired to executed queued requests.
        address heir; // address of the heir to bequeath.
        address guardian; // address of the guardian.
        bool votingEnabled; // true if voting of guardians is enabled else false.
        bool locked; // true is vault is locked else false.
    }
    
    // Vault specific lock storage
    mapping (address => StorageConfig) private vaultStorage;

    /**
     * @notice Throws if the caller is not an authorised module.
     */
    modifier onlyModule(address _vault) {
        require(IVault(_vault).authorised(msg.sender), "S: must be an authorized module to call this method");
        _;
    }

     /**
     * @inheritdoc IStorage
     */
    function setLock(
        address _vault,
        bool _lock
    ) external onlyModule(_vault) {
        vaultStorage[_vault].locked = _lock;
    }

    /**
     * @inheritdoc IStorage
     */
    function toggleVoting(
        address _vault
    )
        external
        onlyModule(_vault)
    {
        vaultStorage[_vault].votingEnabled = !vaultStorage[_vault].votingEnabled;
    }

    /**
     * @inheritdoc IStorage
     */
    function setGuardian(
        address _vault,
        address _guardian
    )
        external
        onlyModule(_vault)
    {
        require(
            vaultStorage[_vault].guardian == address(0),
            "S: Invalid guardian"
        );
        vaultStorage[_vault].guardian = _guardian;
    }

    /**
     * @inheritdoc IStorage
     */
    function revokeGuardian(
        address _vault
    )
        external
        onlyModule(_vault)
    {
        require(
            vaultStorage[_vault].guardian != address(0),
            "S: cannot remove guardian"
        );
        vaultStorage[_vault].guardian = address(0);
    }

    /**
     * @inheritdoc IStorage
     */
    function setTimeDelay(
        address _vault,
        uint256 _newTimeDelay
    )
        external
        onlyModule(_vault)
    {
        vaultStorage[_vault].timeDelay = _newTimeDelay;
    }
    
    /**
     * @inheritdoc IStorage
     */
    function setHeir(
        address _vault,
        address _heir
    )
        external
        onlyModule(_vault)
    {
        vaultStorage[_vault].heir = _heir;
    }

    /**
     * @inheritdoc IStorage
     */
    function isLocked(
        address _vault
    ) 
        external
        view
        returns (bool)
    {
        return vaultStorage[_vault].locked;
    }

    /**
     * @inheritdoc IStorage
     */
    function votingEnabled(
        address _vault
    ) 
        external
        view
        returns (bool)
    {
        return vaultStorage[_vault].votingEnabled;       
    }

    /**
     * @inheritdoc IStorage
     */
    function getGuardian(
        address _vault
    )
        external
        view
        returns (address)
    {
        return vaultStorage[_vault].guardian;
    }

    /**
     * @inheritdoc IStorage
     */
    function isGuardian(
        address _vault,
        address _guardian
    )
        external
        view
        returns (bool)
    {
        return (vaultStorage[_vault].guardian == _guardian);
    }

    /**
     * @inheritdoc IStorage
     */
    function getTimeDelay(
        address _vault
    )
        external
        view
        returns(uint256)
    {
        return vaultStorage[_vault].timeDelay;
    }

    /**
     * @inheritdoc IStorage
     */
    function getHeir(
        address _vault
    )
        external
        view
        returns(address)
    {
        return vaultStorage[_vault].heir;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title IVault
 * @notice Interface for the BaseVault
 */
interface IVault {

    /**
     * @notice Enables/Disables a module.
     * @param _module The target module.
     * @param _value Set to `true` to authorise the module.
     */
    function authoriseModule(address _module, bool _value, bytes memory _initData) external;

    /**
     * @notice Enables a static method by specifying the target module to which the call must be delegated.
     * @param _module The target module.
     */
    function enableStaticCall(address _module) external;


    /**
     * @notice Inits the vault by setting the owner and authorising a list of modules.
     * @param _owner The owner.
     * @param _initData bytes32 initilization data specific to the module.
     * @param _modules The modules to authorise.
     */
    function init(address _owner, address[] calldata _modules, bytes[] calldata _initData) external;

    /**
     * @notice Sets a new owner for the vault.
     * @param _newOwner The new owner.
     */
    function setOwner(address _newOwner) external;

    /**
     * @notice Returns the vault owner.
     * @return The vault owner address.
     */
    function owner() external view returns (address);

    /**
     * @notice Returns the number of authorised modules.
     * @return The number of authorised modules.
     */
    function modules() external view returns (uint256);

    /**
     * @notice Checks if a module is authorised on the vault.
     * @param _module The module address to check.
     * @return `true` if the module is authorised, otherwise `false`.
     */
    function authorised(address _module) external view returns (bool);

    /**
     * @notice Returns the module responsible, if static call is enabled for `_sig`, otherwise return zero address.
     * @param _sig The signature of the static call.
     * @return the module doing the redirection or zero address
     */
    function enabled(bytes4 _sig) external view returns (address);
}