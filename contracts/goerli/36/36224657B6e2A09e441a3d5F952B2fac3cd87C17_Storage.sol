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
    function addGuardian(address _vault, address _guardian) external;

    /**
     * @notice Lets an authorised module revoke a guardian from a vault.
     * @param _vault - The target vault.
     */
    function revokeGuardian(address _vault) external;

    /**
     * @notice Function to be used to add heir address to bequeath vault ownership.
     * @param _vault - The target vault.
     */
    function addHeir(address _vault, address _newHeir) external;

    /**
     * @notice Lets an authorised module revoke a guardian from a vault.
     * @param _vault - The target vault.
     */
    function revokeHeir(address _vault) external;

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

    uint256 public constant MIN_TIME_DELAY = 5;
    uint256 public constant MAX_TIME_DELAY = 5 minutes;

    struct StorageConfig {
        uint256 timeDelay; // time delay in seconds which has to be expired to executed queued requests.
        address heir; // address of the heir to bequeath.
        address guardian; // address of the guardian.
        bool votingEnabled; // true if voting of guardians is enabled else false.
        bool locked; // true is vault is locked else false.
    }
    
    // Vault specific lock storage
    mapping (address => StorageConfig) vaultStorage;

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
        bool _locked = vaultStorage[_vault].votingEnabled;
        if(!_locked) {
            require(vaultStorage[_vault].guardian != address(0), "S: Cannot enable voting");
        }
        vaultStorage[_vault].votingEnabled = !_locked;   
    }

    /**
     * @inheritdoc IStorage
     */
    function addGuardian(
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
        vaultStorage[_vault].guardian = address(0);
        vaultStorage[_vault].votingEnabled = false;
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
        require(
            _newTimeDelay > MIN_TIME_DELAY &&
            _newTimeDelay <= MAX_TIME_DELAY,
            "S: Invalid Time Delay"
        );
        vaultStorage[_vault].timeDelay = _newTimeDelay;
    }
    
    /**
     * @inheritdoc IStorage
     */
    function addHeir(
        address _vault,
        address _heir
    )
        external
        onlyModule(_vault)
    {
        require(
            vaultStorage[_vault].heir == address(0),
            "S: Invalid Heir"
        );
        vaultStorage[_vault].heir = _heir;
    }

    /**
     * @inheritdoc IStorage
     */
    function revokeHeir(
        address _vault
    )
        external
        onlyModule(_vault)
    {
        vaultStorage[_vault].heir = address(0);
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
     * @notice Returns the vault owner.
     * @return The vault owner address.
     */
    function owner() external view returns (address);

    /**
     * @notice Returns the number of authorised modules.
     * @return The number of authorised modules.
     */
    function modules() external view returns (uint);

    /**
     * @notice Sets a new owner for the vault.
     * @param _newOwner The new owner.
     */
    function setOwner(address _newOwner) external;

    /**
     * @notice Checks if a module is authorised on the vault.
     * @param _module The module address to check.
     * @return `true` if the module is authorised, otherwise `false`.
     */
    function authorised(address _module) external view returns (bool);

    /**
     * @notice Returns the module responsible for a static call redirection.
     * @param _sig The signature of the static call.
     * @return the module doing the redirection
     */
    function enabled(bytes4 _sig) external view returns (address);

    /**
     * @notice Enables/Disables a module.
     * @param _module The target module.
     * @param _value Set to `true` to authorise the module.
     */
    function authoriseModule(address _module, bool _value, bytes32 _initData) external;

    /**
    * @notice Enables a static method by specifying the target module to which the call must be delegated.
    * @param _module The target module.
    * @param _method The static method signature.
    */
    function enableStaticCall(address _module, bytes4 _method) external;
}