// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/a035b235b4f2c9af4ba88edc4447f02e37f8d124

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {IERC20} from "solidity-utils/contracts/oz-common/interfaces/IERC20.sol";
import {VersionedInitializable} from "./dependencies/upgradeability/VersionedInitializable.sol";

/**
* @title LendToAaveMigrator
* @notice This contract implements the migration from LEND to AAVE token
* @author Aave 
*/
contract LendToAaveMigrator is VersionedInitializable {
    IERC20 public immutable AAVE;
    IERC20 public immutable LEND;
    uint256 public immutable LEND_AAVE_RATIO;
    uint256 public constant REVISION = 2;
    
    uint256 public _totalLendMigrated;

    /**
    * @dev emitted on migration
    * @param sender the caller of the migration
    * @param amount the amount being migrated
    */
    event LendMigrated(address indexed sender, uint256 indexed amount);

    /**
    * @dev emitted on token rescue when initializing
    * @param from the origin of the rescued funds
    * @param to the destination of the rescued funds
    * @param amount the amount being rescued
    */
    event AaveTokensRescued(address from, address indexed to, uint256 amount);

    /**
    * @param aave the address of the AAVE token
    * @param lend the address of the LEND token
    * @param lendAaveRatio the exchange rate between LEND and AAVE 
     */
    constructor(IERC20 aave, IERC20 lend, uint256 lendAaveRatio) public {
        AAVE = aave;
        LEND = lend;
        LEND_AAVE_RATIO = lendAaveRatio;
    }

    /**
    * @dev initializes the implementation and rescues the LEND sent to the contract
    * by migrating them to AAVE and sending them to the AaveMerkleDistributor
    * and then burning the LEND tokens
    * @param aaveMerkleDistributor address of the AAVE rescue distributor
    * @param lendToMigratorAmount amount of lend sent to migrator that need to be rescued
    * @param lendToLendAmount amount of lend sent to LEND that need to be rescued
    * @param lendToAaveAmount amount of lend sent to AAVE that need to be rescued
    */
    function initialize(address aaveMerkleDistributor, uint256 lendToMigratorAmount, uint256 lendToLendAmount, uint256 lendToAaveAmount) public initializer {
        uint256 lendAmount = lendToMigratorAmount + lendToLendAmount + lendToAaveAmount;
        uint256 migratorLendBalance = _totalLendMigrated + lendToMigratorAmount;

        // account for the LEND sent to the contract for the total migration
        _totalLendMigrated += lendAmount;

        // transfer AAVE + LEND sent to this contract
        uint256 amountToRescue = lendAmount / LEND_AAVE_RATIO;
        AAVE.transfer(aaveMerkleDistributor, amountToRescue);

        LEND.transfer(address(LEND), migratorLendBalance);

        emit LendMigrated(address(this), lendAmount);
        emit AaveTokensRescued(address(this), aaveMerkleDistributor, amountToRescue);

        // checks that the amount of AAVE not migrated is less or equal as the amount of AAVE disposable for migration
        // we have found that there was a previous small surplus on the AAVE token amount found on the LendToAaveMigrator
        // contract previous to the rescue, that is why we need to use <= instead of == . This amount is 582968318731898974 (0,58 AAVE)
        require((LEND.totalSupply() - LEND.balanceOf(address(LEND)) - lendToAaveAmount ) / LEND_AAVE_RATIO <= AAVE.balanceOf(address(this)),
            'INCORRECT_BALANCE_RESCUED'
        );
    }

    /**
    * @dev returns true if the migration started
    */
    function migrationStarted() external view returns(bool) {
        return lastInitializedRevision != 0;
    }

    /**
    * @dev executes the migration from LEND to AAVE. Users need to give allowance to this contract to transfer LEND before executing
    * this transaction.
    * burns the migrated LEND amount 
    * @param amount the amount of LEND to be migrated
    */
    function migrateFromLEND(uint256 amount) external {
        require(lastInitializedRevision != 0, "MIGRATION_NOT_STARTED");

        _totalLendMigrated = _totalLendMigrated + amount;
        LEND.transferFrom(msg.sender, address(this), amount);
        AAVE.transfer(msg.sender, amount / LEND_AAVE_RATIO);

        LEND.transfer(address(LEND), amount);
        
        emit LendMigrated(msg.sender, amount);
    }

    /**
    * @dev returns the implementation revision
    * @return the implementation revision
    */
    function getRevision() internal pure override returns (uint256) {
        return REVISION;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

/**
 * @title VersionedInitializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 *
 * @author Aave, inspired by the OpenZeppelin Initializable contract
 */
abstract contract VersionedInitializable {
    /**
   * @dev Indicates that the contract has been initialized.
   */
    uint256 internal lastInitializedRevision = 0;

   /**
   * @dev Modifier to use in the initializer function of a contract.
   */
    modifier initializer() {
        uint256 revision = getRevision();
        require(revision > lastInitializedRevision, "Contract instance has already been initialized");

        lastInitializedRevision = revision;

        _;

    }

    /// @dev returns the revision number of the contract.
    /// Needs to be defined in the inherited class as a constant.
    function getRevision() internal pure virtual returns(uint256);


    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}