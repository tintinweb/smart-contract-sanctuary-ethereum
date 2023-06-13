// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import {IAaveLendPoolAddressesProvider} from "./interfaces/IAaveLendPoolAddressesProvider.sol";
import {IAaveLendPool} from "./interfaces/IAaveLendPool.sol";
import {IAaveFlashLoanReceiver} from "./interfaces/IAaveFlashLoanReceiver.sol";
import {ILendPoolAddressesProvider} from "./interfaces/ILendPoolAddressesProvider.sol";
import {ILendPool} from "./interfaces/ILendPool.sol";
import {ILendPoolLoan} from "./interfaces/ILendPoolLoan.sol";

import {IStakedNft} from "../interfaces/IStakedNft.sol";
import {INftPool} from "../interfaces/INftPool.sol";

contract LendingMigrator is
    IAaveFlashLoanReceiver,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    event NftMigrated(address indexed borrower, address indexed nftAsset, uint256 nftTokenId, uint256 debtAmount);

    uint256 public constant PERCENTAGE_FACTOR = 1e4;
    uint256 public constant BORROW_SLIPPAGE = 10; // 0.1%

    IAaveLendPoolAddressesProvider public aaveAddressesProvider;
    IAaveLendPool public aaveLendPool;
    ILendPoolAddressesProvider public bendAddressesProvider;
    ILendPool public bendLendPool;
    ILendPoolLoan public bendLendLoan;

    INftPool public nftPool;
    IStakedNft public stBayc;
    IStakedNft public stMayc;
    IStakedNft public stBakc;

    IERC721Upgradeable public bayc;
    IERC721Upgradeable public mayc;
    IERC721Upgradeable public bakc;

    function initialize(
        address aaveAddressesProvider_,
        address bendAddressesProvider_,
        address nftPool_,
        address stBayc_,
        address stMayc_,
        address stBakc_
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        nftPool = INftPool(nftPool_);
        stBayc = IStakedNft(stBayc_);
        stMayc = IStakedNft(stMayc_);
        stBakc = IStakedNft(stBakc_);

        bayc = IERC721Upgradeable(stBayc.underlyingAsset());
        mayc = IERC721Upgradeable(stMayc.underlyingAsset());
        bakc = IERC721Upgradeable(stBakc.underlyingAsset());

        aaveAddressesProvider = IAaveLendPoolAddressesProvider(aaveAddressesProvider_);
        aaveLendPool = IAaveLendPool(aaveAddressesProvider.getLendingPool());

        bendAddressesProvider = ILendPoolAddressesProvider(bendAddressesProvider_);
        bendLendPool = ILendPool(bendAddressesProvider.getLendPool());
        bendLendLoan = ILendPoolLoan(bendAddressesProvider.getLendPoolLoan());

        IERC721Upgradeable(bayc).setApprovalForAll(address(nftPool), true);
        IERC721Upgradeable(mayc).setApprovalForAll(address(nftPool), true);
        IERC721Upgradeable(bakc).setApprovalForAll(address(nftPool), true);

        IERC721Upgradeable(address(stBayc)).setApprovalForAll(address(bendLendPool), true);
        IERC721Upgradeable(address(stMayc)).setApprovalForAll(address(bendLendPool), true);
        IERC721Upgradeable(address(stBakc)).setApprovalForAll(address(bendLendPool), true);
    }

    struct ExecuteOperationLocaVars {
        address[] nftAssets;
        uint256[] nftTokenIds;
        uint256[] newDebtAmounts;
        address borrower;
        uint256 aaveFlashLoanFeeRatio;
        uint256 totalNewDebtAmount;
        uint256 balanceBeforeMigrate;
        uint256 balanceDiffBeforeMigrate;
        uint256 balanceAfterMigrate;
        uint256 balanceDiffAfterMigrate;
        uint256 balanceDiffToUser;
        uint256 repayToAave;
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address /*initiator*/,
        bytes calldata params
    ) external whenNotPaused nonReentrant returns (bool) {
        ExecuteOperationLocaVars memory execVars;

        require(msg.sender == address(aaveLendPool), "Migrator: caller must be aave lending pool");
        require(
            assets.length == 1 && amounts.length == 1 && premiums.length == 1,
            "Migrator: multiple assets not supported"
        );

        (execVars.nftAssets, execVars.nftTokenIds, execVars.newDebtAmounts) = abi.decode(
            params,
            (address[], uint256[], uint256[])
        );
        require(execVars.nftTokenIds.length > 0, "Migrator: empty token ids");
        require(
            execVars.nftAssets.length == execVars.nftTokenIds.length,
            "Migrator: inconsistent assets and token ids"
        );
        require(
            execVars.nftAssets.length == execVars.newDebtAmounts.length,
            "Migrator: inconsistent assets and debt amounts"
        );

        execVars.aaveFlashLoanFeeRatio = aaveLendPool.FLASHLOAN_PREMIUM_TOTAL();

        IERC20Upgradeable(assets[0]).approve(address(bendLendPool), type(uint256).max);

        execVars.balanceBeforeMigrate = IERC20Upgradeable(assets[0]).balanceOf(address(this));
        execVars.balanceDiffBeforeMigrate = execVars.balanceBeforeMigrate - amounts[0];

        for (uint256 i = 0; i < execVars.nftTokenIds.length; i++) {
            RepayAndBorrowLocaVars memory vars;
            vars.nftAsset = execVars.nftAssets[i];
            vars.nftTokenId = execVars.nftTokenIds[i];
            vars.newDebtAmount = execVars.newDebtAmounts[i];
            vars.flashLoanAsset = assets[0];
            vars.flashLoanFeeRatio = execVars.aaveFlashLoanFeeRatio;

            execVars.totalNewDebtAmount += vars.newDebtAmount;

            _repayAndBorrowPerNft(execVars, vars);
        }

        require(execVars.totalNewDebtAmount == amounts[0], "Migrator: inconsistent total debt amount");

        IERC20Upgradeable(assets[0]).approve(address(bendLendPool), 0);

        execVars.repayToAave = amounts[0] + premiums[0];
        IERC20Upgradeable(assets[0]).approve(msg.sender, execVars.repayToAave);

        execVars.balanceAfterMigrate = IERC20Upgradeable(assets[0]).balanceOf(address(this));
        require(execVars.balanceAfterMigrate >= execVars.repayToAave, "Migrator: insufficent to repay aave");

        // we try to borrow a little more to make sure it has enough to repay flash loan
        // but remain part need to be returned to user
        execVars.balanceDiffAfterMigrate = execVars.balanceAfterMigrate - execVars.repayToAave;
        if (execVars.balanceDiffAfterMigrate > execVars.balanceDiffBeforeMigrate) {
            execVars.balanceDiffToUser = execVars.balanceDiffAfterMigrate - execVars.balanceDiffBeforeMigrate;
            IERC20Upgradeable(assets[0]).transfer(execVars.borrower, execVars.balanceDiffToUser);
        }

        return true;
    }

    struct RepayAndBorrowLocaVars {
        address nftAsset;
        uint256 nftTokenId;
        uint256 newDebtAmount;
        address flashLoanAsset;
        uint256 flashLoanFeeRatio;
        uint256 loanId;
        address borrower;
        address debtReserve;
        uint256 debtTotalAmount;
        uint256 debtRemainAmount;
        uint256 redeemAmount;
        uint256 bidFine;
        uint256 debtTotalAmountWithBidFine;
        uint256 balanceBeforeRepay;
        uint256[] nftTokenIds;
        uint256 flashLoanPremium;
        uint256 debtBorrowAmountWithFee;
        uint256 balanceBeforeBorrow;
        uint256 balanceAfterBorrow;
    }

    function _repayAndBorrowPerNft(
        ExecuteOperationLocaVars memory execVars,
        RepayAndBorrowLocaVars memory vars
    ) internal {
        (vars.loanId, , , , vars.bidFine) = bendLendPool.getNftAuctionData(vars.nftAsset, vars.nftTokenId);
        (, vars.debtReserve, , vars.debtTotalAmount, , ) = bendLendPool.getNftDebtData(vars.nftAsset, vars.nftTokenId);
        vars.debtTotalAmountWithBidFine = vars.debtTotalAmount + vars.bidFine;

        // check new debt can cover old debt and flash loan fee
        vars.flashLoanPremium = (vars.newDebtAmount * vars.flashLoanFeeRatio) / PERCENTAGE_FACTOR;
        vars.debtBorrowAmountWithFee = vars.debtTotalAmountWithBidFine + vars.flashLoanPremium;
        require(
            vars.debtBorrowAmountWithFee <= vars.newDebtAmount,
            "Migrator: new debt can not cover old debt with fee"
        );

        // check borrower is same
        vars.borrower = bendLendLoan.borrowerOf(vars.loanId);
        if (execVars.borrower == address(0)) {
            execVars.borrower = vars.borrower;
        } else {
            require(execVars.borrower == vars.borrower, "Migrator: borrower not same");
        }

        vars.balanceBeforeRepay = IERC20Upgradeable(vars.debtReserve).balanceOf(address(this));

        require(vars.debtReserve == vars.flashLoanAsset, "Migrator: invalid flash loan asset");
        require(vars.debtTotalAmountWithBidFine <= vars.balanceBeforeRepay, "Migrator: insufficent to repay old debt");

        // redeem first if nft is in auction
        if (vars.bidFine > 0) {
            vars.redeemAmount = (vars.debtTotalAmount * 2) / 3;
            bendLendPool.redeem(vars.nftAsset, vars.nftTokenId, vars.redeemAmount, vars.bidFine);

            (, , , vars.debtRemainAmount, , ) = bendLendPool.getNftDebtData(vars.nftAsset, vars.nftTokenId);
        } else {
            vars.debtRemainAmount = vars.debtTotalAmount;
        }

        // repay all the old debt
        bendLendPool.repay(vars.nftAsset, vars.nftTokenId, vars.debtRemainAmount);

        // stake original nft to the staking pool
        IERC721Upgradeable(vars.nftAsset).safeTransferFrom(vars.borrower, address(address(this)), vars.nftTokenId);
        vars.nftTokenIds = new uint256[](1);
        vars.nftTokenIds[0] = vars.nftTokenId;
        address[] memory nfts = new address[](1);
        nfts[0] = vars.nftAsset;
        uint256[][] memory tokenIds = new uint256[][](1);
        tokenIds[0] = vars.nftTokenIds;
        nftPool.deposit(nfts, tokenIds);

        // borrow new debt with the staked nft
        vars.balanceBeforeBorrow = IERC20Upgradeable(vars.debtReserve).balanceOf(address(this));

        IStakedNft stNftAsset = getStakedNFTAsset(vars.nftAsset);

        bendLendPool.borrow(
            vars.debtReserve,
            vars.newDebtAmount,
            address(stNftAsset),
            vars.nftTokenId,
            vars.borrower,
            0
        );

        vars.balanceAfterBorrow = IERC20Upgradeable(vars.debtReserve).balanceOf(address(this));
        require(vars.balanceAfterBorrow == (vars.balanceBeforeBorrow + vars.newDebtAmount));

        emit NftMigrated(vars.borrower, vars.nftAsset, vars.nftTokenId, vars.debtTotalAmount);
    }

    function getStakedNFTAsset(address nftAsset) internal view returns (IStakedNft) {
        if (nftAsset == address(bayc)) {
            return stBayc;
        } else if (nftAsset == address(mayc)) {
            return stMayc;
        } else if (nftAsset == address(bakc)) {
            return stBakc;
        } else {
            revert("Migrator: invalid nft asset");
        }
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Receiver.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721ReceiverUpgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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
interface IERC721ReceiverUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

interface IApeCoinStaking {
    struct SingleNft {
        uint32 tokenId;
        uint224 amount;
    }

    struct PairNft {
        uint128 mainTokenId;
        uint128 bakcTokenId;
    }

    struct PairNftDepositWithAmount {
        uint32 mainTokenId;
        uint32 bakcTokenId;
        uint184 amount;
    }
    struct PairNftWithdrawWithAmount {
        uint32 mainTokenId;
        uint32 bakcTokenId;
        uint184 amount;
        bool isUncommit;
    }
    struct Position {
        uint256 stakedAmount;
        int256 rewardsDebt;
    }

    struct Pool {
        uint48 lastRewardedTimestampHour;
        uint16 lastRewardsRangeIndex;
        uint96 stakedAmount;
        uint96 accumulatedRewardsPerShare;
        TimeRange[] timeRanges;
    }

    struct TimeRange {
        uint48 startTimestampHour;
        uint48 endTimestampHour;
        uint96 rewardsPerHour;
        uint96 capPerPosition;
    }

    struct PoolWithoutTimeRange {
        uint48 lastRewardedTimestampHour;
        uint16 lastRewardsRangeIndex;
        uint96 stakedAmount;
        uint96 accumulatedRewardsPerShare;
    }

    struct DashboardStake {
        uint256 poolId;
        uint256 tokenId;
        uint256 deposited;
        uint256 unclaimed;
        uint256 rewards24hr;
        DashboardPair pair;
    }

    struct DashboardPair {
        uint256 mainTokenId;
        uint256 mainTypePoolId;
    }

    struct PoolUI {
        uint256 poolId;
        uint256 stakedAmount;
        TimeRange currentTimeRange;
    }

    struct PairingStatus {
        uint248 tokenId;
        bool isPaired;
    }

    function mainToBakc(uint256 poolId_, uint256 mainTokenId_) external view returns (PairingStatus memory);

    function bakcToMain(uint256 poolId_, uint256 bakcTokenId_) external view returns (PairingStatus memory);

    function nftContracts(uint256 poolId_) external view returns (address);

    function rewardsBy(uint256 poolId_, uint256 from_, uint256 to_) external view returns (uint256, uint256);

    function apeCoin() external view returns (address);

    function getCurrentTimeRangeIndex(Pool memory pool_) external view returns (uint256);

    function getTimeRangeBy(uint256 poolId_, uint256 index_) external view returns (TimeRange memory);

    function getPoolsUI() external view returns (PoolUI memory, PoolUI memory, PoolUI memory, PoolUI memory);

    function getSplitStakes(address address_) external view returns (DashboardStake[] memory);

    function stakedTotal(address addr_) external view returns (uint256);

    function pools(uint256 poolId_) external view returns (PoolWithoutTimeRange memory);

    function nftPosition(uint256 poolId_, uint256 tokenId_) external view returns (Position memory);

    function addressPosition(address addr_) external view returns (Position memory);

    function pendingRewards(uint256 poolId_, address address_, uint256 tokenId_) external view returns (uint256);

    function depositBAYC(SingleNft[] calldata nfts_) external;

    function depositMAYC(SingleNft[] calldata nfts_) external;

    function depositBAKC(
        PairNftDepositWithAmount[] calldata baycPairs_,
        PairNftDepositWithAmount[] calldata maycPairs_
    ) external;

    function depositSelfApeCoin(uint256 amount_) external;

    function claimSelfApeCoin() external;

    function claimBAYC(uint256[] calldata nfts_, address recipient_) external;

    function claimMAYC(uint256[] calldata nfts_, address recipient_) external;

    function claimBAKC(PairNft[] calldata baycPairs_, PairNft[] calldata maycPairs_, address recipient_) external;

    function withdrawBAYC(SingleNft[] calldata nfts_, address recipient_) external;

    function withdrawMAYC(SingleNft[] calldata nfts_, address recipient_) external;

    function withdrawBAKC(
        PairNftWithdrawWithAmount[] calldata baycPairs_,
        PairNftWithdrawWithAmount[] calldata maycPairs_
    ) external;

    function withdrawSelfApeCoin(uint256 amount_) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;
import {IApeCoinStaking} from "./IApeCoinStaking.sol";
import {IStakeManager} from "./IStakeManager.sol";
import {IStakedNft} from "./IStakedNft.sol";

interface INftPool {
    event NftRewardDistributed(address indexed nft, uint256 rewardAmount);

    event NftRewardClaimed(
        address indexed nft,
        uint256[] tokenIds,
        address indexed receiver,
        uint256 amount,
        uint256 rewardsDebt
    );

    event NftDeposited(address indexed nft, uint256[] tokenIds, address indexed owner);

    event NftWithdrawn(address indexed nft, uint256[] tokenIds, address indexed owner);

    struct PoolState {
        IStakedNft stakedNft;
        uint256 accumulatedRewardsPerNft;
        mapping(uint256 => uint256) rewardsDebt;
        uint256 pendingApeCoin;
    }

    struct PoolUI {
        uint256 totalStakedNft;
        uint256 accumulatedRewardsPerNft;
        uint256 pendingApeCoin;
    }

    function claimable(address[] calldata nfts_, uint256[][] calldata tokenIds_) external view returns (uint256);

    function staker() external view returns (IStakeManager);

    function deposit(address[] calldata nfts_, uint256[][] calldata tokenIds_) external;

    function withdraw(address[] calldata nfts_, uint256[][] calldata tokenIds_) external;

    function claim(address[] calldata nfts_, uint256[][] calldata tokenIds_) external;

    function receiveApeCoin(address nft_, uint256 rewardsAmount_) external;

    function compoundApeCoin(address nft_) external;

    function pendingApeCoin(address nft_) external view returns (uint256);

    function getPoolStateUI(address nft_) external view returns (PoolUI memory);

    function getNftStateUI(address nft_, uint256 tokenId) external view returns (uint256 rewardsDebt);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

interface IRewardsStrategy {
    function getNftRewardsShare() external view returns (uint256 nftShare);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {IERC721MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC721MetadataUpgradeable.sol";
import {IERC721ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC721ReceiverUpgradeable.sol";
import {IERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC721EnumerableUpgradeable.sol";

interface IStakedNft is IERC721MetadataUpgradeable, IERC721ReceiverUpgradeable, IERC721EnumerableUpgradeable {
    event Minted(address indexed to, uint256[] tokenId);
    event Burned(address indexed from, uint256[] tokenId);

    function authorise(address addr_, bool authorized_) external;

    function mint(address to, uint256[] calldata tokenIds) external;

    function burn(uint256[] calldata tokenIds) external;

    /**
     * @dev Returns the staker of the `tokenId` token.
     */
    function stakerOf(uint256 tokenId) external view returns (address);

    /**
     * @dev Returns a token ID owned by `staker` at a given `index` of its token list.
     * Use along with {totalStaked} to enumerate all of ``staker``'s tokens.
     */

    function tokenOfStakerByIndex(address staker, uint256 index) external view returns (uint256);

    /**
     * @dev Returns the total staked amount of tokens for staker.
     */
    function totalStaked(address staker) external view returns (uint256);

    function underlyingAsset() external view returns (address);

    function setDelegateCash(address delegate, uint256[] calldata tokenIds, bool value) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;
import {IApeCoinStaking} from "./IApeCoinStaking.sol";
import {IRewardsStrategy} from "./IRewardsStrategy.sol";
import {IWithdrawStrategy} from "./IWithdrawStrategy.sol";
import {IStakedNft} from "./IStakedNft.sol";

interface IStakeManager {
    event FeeRatioChanged(uint256 newRatio);
    event FeeRecipientChanged(address newRecipient);
    event BotAdminChanged(address newAdmin);
    event RewardsStrategyChanged(address nft, address newStrategy);
    event WithdrawStrategyChanged(address newStrategy);
    event Compounded(bool isClaimCoinPool, uint256 claimedNfts);

    function stBayc() external view returns (IStakedNft);

    function stMayc() external view returns (IStakedNft);

    function stBakc() external view returns (IStakedNft);

    function totalStakedApeCoin() external view returns (uint256);

    function totalPendingRewards() external view returns (uint256);

    function totalRefund() external view returns (uint256 principal, uint256 reward);

    function refundOf(address nft_) external view returns (uint256 principal, uint256 reward);

    function stakedApeCoin(uint256 poolId_) external view returns (uint256);

    function pendingRewards(uint256 poolId_) external view returns (uint256);

    function pendingFeeAmount() external view returns (uint256);

    function fee() external view returns (uint256);

    function feeRecipient() external view returns (address);

    function updateFee(uint256 fee_) external;

    function updateFeeRecipient(address recipient_) external;

    // bot
    function updateBotAdmin(address bot_) external;

    // strategy
    function updateRewardsStrategy(address nft_, IRewardsStrategy rewardsStrategy_) external;

    function updateWithdrawStrategy(IWithdrawStrategy withdrawStrategy_) external;

    function withdrawApeCoin(uint256 required) external returns (uint256);

    function mintStNft(IStakedNft stNft_, address to_, uint256[] calldata tokenIds_) external;

    // staking
    function calculateFee(uint256 rewardsAmount_) external view returns (uint256 feeAmount);

    function stakeApeCoin(uint256 amount_) external;

    function unstakeApeCoin(uint256 amount_) external;

    function claimApeCoin() external;

    function stakeBayc(uint256[] calldata tokenIds_) external;

    function unstakeBayc(uint256[] calldata tokenIds_) external;

    function claimBayc(uint256[] calldata tokenIds_) external;

    function stakeMayc(uint256[] calldata tokenIds_) external;

    function unstakeMayc(uint256[] calldata tokenIds_) external;

    function claimMayc(uint256[] calldata tokenIds_) external;

    function stakeBakc(
        IApeCoinStaking.PairNft[] calldata baycPairs_,
        IApeCoinStaking.PairNft[] calldata maycPairs_
    ) external;

    function unstakeBakc(
        IApeCoinStaking.PairNft[] calldata baycPairs_,
        IApeCoinStaking.PairNft[] calldata maycPairs_
    ) external;

    function claimBakc(
        IApeCoinStaking.PairNft[] calldata baycPairs_,
        IApeCoinStaking.PairNft[] calldata maycPairs_
    ) external;

    function withdrawRefund(address nft_) external;

    function withdrawTotalRefund() external;

    struct NftArgs {
        uint256[] bayc;
        uint256[] mayc;
        IApeCoinStaking.PairNft[] baycPairs;
        IApeCoinStaking.PairNft[] maycPairs;
    }

    struct CompoundArgs {
        bool claimCoinPool;
        NftArgs claim;
        NftArgs unstake;
        NftArgs stake;
        uint256 coinStakeThreshold;
    }

    function compound(CompoundArgs calldata args_) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

interface IWithdrawStrategy {
    function withdrawApeCoin(uint256 required) external returns (uint256 withdrawn);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

/**
 * @title IAaveFlashLoanReceiver interface
 * @notice Interface for the Aave fee IFlashLoanReceiver.
 * @author Bend
 * @dev implement this interface to develop a flashloan-compatible flashLoanReceiver contract
 **/
interface IAaveFlashLoanReceiver {
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

interface IAaveLendPool {
    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint256);

    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

/**
 * @title IAaveLendPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the aave protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Bend
 **/
interface IAaveLendPoolAddressesProvider {
    function getLendingPool() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

interface ILendPool {
    function borrow(
        address reserveAsset,
        uint256 amount,
        address nftAsset,
        uint256 nftTokenId,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function repay(address nftAsset, uint256 nftTokenId, uint256 amount) external returns (uint256, bool);

    function redeem(address nftAsset, uint256 nftTokenId, uint256 amount, uint256 bidFine) external returns (uint256);

    function getNftDebtData(
        address nftAsset,
        uint256 nftTokenId
    )
        external
        view
        returns (
            uint256 loanId,
            address reserveAsset,
            uint256 totalCollateral,
            uint256 totalDebt,
            uint256 availableBorrows,
            uint256 healthFactor
        );

    function getNftAuctionData(
        address nftAsset,
        uint256 nftTokenId
    )
        external
        view
        returns (uint256 loanId, address bidderAddress, uint256 bidPrice, uint256 bidBorrowAmount, uint256 bidFine);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

/**
 * @title LendPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Bend Governance
 * @author Bend
 **/
interface ILendPoolAddressesProvider {
    function getLendPool() external view returns (address);

    function getLendPoolLoan() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

interface ILendPoolLoan {
    function getCollateralLoanId(address nftAsset, uint256 nftTokenId) external view returns (uint256);

    function borrowerOf(uint256 loanId) external view returns (address);
}