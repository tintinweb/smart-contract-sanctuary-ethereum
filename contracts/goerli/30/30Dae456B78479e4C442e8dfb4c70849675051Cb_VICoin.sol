// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./FusedController.sol";
import "./Calculations.sol";

struct Settings {
    // number of blocks until balance decays to zero
    uint256 lifetime;
    // blocks between each generation period
    uint256 generationPeriod;
    // tokens issued to each account at each generation period
    uint256 generationAmount;
    // starting balance for a new account
    uint256 initialBalance;
    // contribution % taken from the transaction fee on every transfer
    uint256 communityContribution;
    // transaction fee % taken from every transfer
    uint256 transactionFee;
    // account that receives the contribution payments
    address communityContributionAccount;
}

/// @notice One contract is deployed for each community
/// @dev Based on openzeppelin's burnable and mintable ERC20 tokens
contract VICoin is ERC20Burnable, FusedController, Calculations {
    using SafeMath for uint256;
    using SafeMath for int256;

    Settings settings;
    mapping(address => uint256) public lastTransactionBlock;
    mapping(address => uint256) public lastGenerationBlock;
    mapping(address => uint256) public zeroBlock;
    mapping(address => bool) public accountApproved;
    uint256 public numAccounts;

    event TransferSummary(
        address indexed from,
        address indexed to,
        uint256 value,
        uint256 feesBurned,
        uint256 contribution,
        uint256 payoutSender,
        uint256 payoutRecipient
    );
    event VerifyAccount(address indexed account);
    event UnapproveAccount(address account);
    event Log(string name, uint256 value);

    constructor (
        string memory _name,
        string memory _symbol,
        uint256 _lifetime,
        uint256 _generationAmount,
        uint256 _generationPeriod,
        uint256 _communityContribution,
        uint256 _transactionFee,
        uint256 _initialBalance,
        address _communityContributionAccount,
        address _controller
    ) ERC20(_name, _symbol) public {
        FusedController.initialize(_controller);
        address communityContributionAccount = _communityContributionAccount;
        if (_communityContributionAccount == address(0)) {
            communityContributionAccount = msg.sender;
        }

        settings.lifetime = _lifetime;
        settings.generationAmount = _generationAmount;
        settings.generationPeriod = _generationPeriod;
        settings.communityContribution = _communityContribution;
        settings.transactionFee = _transactionFee;
        settings.initialBalance = _initialBalance;
        settings.communityContributionAccount = communityContributionAccount;

        numAccounts = 0;
    }

    function initializeSettings(
        uint256 _lifetime,
        uint256 _generationAmount,
        uint256 _generationPeriod,
        uint256 _communityContribution,
        uint256 _transactionFee,
        uint256 _initialBalance,
        address _communityContributionAccount
    ) external onlyController {
        address communityContributionAccount = _communityContributionAccount;
        if (_communityContributionAccount == address(0)) {
            communityContributionAccount = msg.sender;
        }

        settings.lifetime = _lifetime;
        settings.generationAmount = _generationAmount;
        settings.generationPeriod = _generationPeriod;
        settings.communityContribution = _communityContribution;
        settings.transactionFee = _transactionFee;
        settings.initialBalance = _initialBalance;
        settings.communityContributionAccount = communityContributionAccount;

        numAccounts = 0;
    }

    receive() external payable {
        revert("Do not send money to the contract");
    }

    /** @notice Manually trigger an onchain update of the live balance
        @return Generation accrued since last balance update */
    function triggerOnchainBalanceUpdate(address _account)
        public
        returns (uint256)
    {
        // 1. Decay the balance
        uint256 decay = calcDecay(
            lastTransactionBlock[_account],
            balanceOf(_account),
            block.number,
            zeroBlock[_account]
        );
        if (decay > 0) {
            _burn(_account, decay);
        }
        uint256 decayedBalance = balanceOf(_account);

        // 2. Generate tokens
        uint256 generationAccrued;
        if (accountApproved[_account]) {
            // Calculate the accrued generation, taking into account decay
            generationAccrued = calcGeneration(
                block.number,
                lastGenerationBlock[_account],
                settings.lifetime,
                settings.generationAmount,
                settings.generationPeriod
            );

            if (generationAccrued > 0) {
                // Issue the generated tokens
                _mint(_account, generationAccrued);

                // Record the last generation block
                lastGenerationBlock[_account] += Calculations
                    .calcNumCompletedPeriods(
                    block
                        .number,
                    lastGenerationBlock[_account],
                    settings
                        .generationPeriod
                )
                    .mul(settings.generationPeriod);

                // Extend the zero block
                zeroBlock[_account] = calcZeroBlock(
                    generationAccrued,
                    decayedBalance,
                    block.number,
                    settings.lifetime,
                    zeroBlock[_account]
                );
            }
        }
        // Record the last transaction block
        if (decay > 0 || generationAccrued > 0) {
            lastTransactionBlock[_account] = block.number;
        }
        return generationAccrued;
    }

    /** @notice Return the real balance of the account, as of this block
        @return Latest balance */
    function liveBalanceOf(address _account) public view returns (uint256) {
        uint256 decay = calcDecay(
            lastTransactionBlock[_account],
            balanceOf(_account),
            block.number,
            zeroBlock[_account]
        );
        uint256 decayedBalance = balanceOf(_account).sub(decay);
        if (lastGenerationBlock[_account] == 0) {
            return (decayedBalance);
        }
        uint256 generationAccrued = 0;
        if (accountApproved[_account]) {
            generationAccrued = calcGeneration(
                block.number,
                lastGenerationBlock[_account],
                settings.lifetime,
                settings.generationAmount,
                settings.generationPeriod
            );
        }
        return decayedBalance.add(generationAccrued);
    }

    /** @notice Transfer the currency from one account to another,
                updating each account to reflect the time passed, and the
                effects of the transfer
        @return Success */
    function transfer(address _to, uint256 _value)
        public
        override
        returns (bool)
    {
        uint256 feesBurned;
        uint256 contribution;
        // Process generation and decay for sender
        emit Log("Sender balance before update", balanceOf(msg.sender));
        uint256 generationAccruedSender = triggerOnchainBalanceUpdate(
            msg.sender
        );
        emit Log("Sender balance after update", balanceOf(msg.sender));

        // Process generation and decay for recipient
        emit Log("Recipient balance before update", balanceOf(_to));
        uint256 generationAccruedRecipient = triggerOnchainBalanceUpdate(_to);
        emit Log("Recipient balance after update", balanceOf(_to));

        require(
            balanceOf(msg.sender) >= _value,
            "Not enough balance to make transfer"
        );

        // Process fees and contribution
        (feesBurned, contribution) = processFeesAndContribution(
            _value,
            settings.transactionFee,
            settings.communityContribution
        );
        uint256 valueAfterFees = _value.sub(feesBurned).sub(contribution);

        //Extend zero block based on transfer
        zeroBlock[_to] = calcZeroBlock(
            valueAfterFees,
            balanceOf(_to),
            block.number,
            settings.lifetime,
            zeroBlock[_to]
        );

        /* If they haven't already been updated (during decay or generation),
            then update the lastTransactionBlock for both sender and recipient */
        if (lastTransactionBlock[_to] != block.number) {
            lastTransactionBlock[_to] = block.number;
        }
        if (lastTransactionBlock[msg.sender] != block.number) {
            lastTransactionBlock[msg.sender] = block.number;
        }

        super.transfer(_to, valueAfterFees);
        emit TransferSummary(
            msg.sender,
            _to,
            valueAfterFees,
            feesBurned,
            contribution,
            generationAccruedSender,
            generationAccruedRecipient
        );
        return true;
    }

    /// @notice transferFrom disabled
    function transferFrom(
        address,
        address,
        uint256
    ) public override returns (bool) {
        revert("transferFrom disabled");
    }

    /** @notice Calculate the fees and contribution, send contribution to the communtiy account,
            and burn the fees
        @dev Percentage to x dp as defined by contributionFeeDecimals e.g.
            when contributionFeeDecimals is 2, 1200 is 12.00%
        @return The total amount used for fees and contribution */
    function processFeesAndContribution(
        uint256 _value,
        uint256 _transactionFee,
        uint256 _communityContribution
    ) internal returns (uint256, uint256) {
        uint256 feesIncContribution = calcFeesIncContribution(
            _value,
            _transactionFee
        );
        uint256 contribution = calcContribution(
            _value,
            _transactionFee,
            _communityContribution
        );
        uint256 feesToBurn = calcFeesToBurn(
            _value,
            _transactionFee,
            _communityContribution
        );
        require(
            feesIncContribution == contribution.add(feesToBurn),
            "feesIncContribution should equal contribution + feesToBurn"
        );

        if (feesToBurn > 0) {
            super.burn(feesToBurn);
        }

        if (contribution > 0) {
            super.transfer(settings.communityContributionAccount, contribution);
        }

        return (feesToBurn, contribution);
    }

    /** @notice Unapprove the specified account so that it no longer receives
        generation */
    function unapproveAccount(address _account)
        external
        onlyController
        fused(6)
    {
        accountApproved[_account] = false;
        emit UnapproveAccount(_account);
    }

    /** @notice Create a new account with the specified role
        @dev New accounts can always be created.
            This function can't be disabled. */
    function verifyAccount(address _account) external onlyController {
        accountApproved[_account] = true;
        if (
            settings.initialBalance > 0 && lastTransactionBlock[_account] == 0
        ) {
            // This is a new account !
            numAccounts++;
            _mint(_account, settings.initialBalance);
            zeroBlock[_account] = block.number.add(settings.lifetime);
            lastTransactionBlock[_account] = block.number;
        }
        lastGenerationBlock[_account] = block.number;
        emit VerifyAccount(_account);
        emit TransferSummary(
            address(this),
            _account,
            settings.initialBalance,
            0,
            0,
            0,
            0
        );
    }

    /** @notice Get the number of tokens issued to each account after each
            generation period
        @return Number of tokens issued at each generation period */
    function getGenerationAmount() public view returns (uint256) {
        return settings.generationAmount;
    }

    /// @notice Get essential details for the account
    function getDetails(address _account)
        public
        view
        returns (
            uint256 _lastBlock,
            uint256 _balance,
            uint256 _zeroBlock
        )
    {
        _lastBlock = lastTransactionBlock[_account];
        _balance = balanceOf(_account);
        _zeroBlock = zeroBlock[_account];
    }

    /** @notice Return the current block number
        @return Current block number */
    function getBlockNumber() public view returns (uint256) {
        return block.number;
    }

    /** @notice Return lifetime
        @return Number of blocks until balance decays to zero
     */
    function getLifetime() external view returns (uint256) {
        return settings.lifetime;
    }

    /** @notice Return generation period
        @return Number of blocks between each generation period
    */
    function getGenerationPeriod() external view returns (uint256) {
        return settings.generationPeriod;
    }

    /** @notice Return initial balance
        @return Number of tokens issued when an account is first verified */
    function getInitialBalance() external view returns (uint256) {
        return settings.initialBalance;
    }

    /** @notice Return community contribution, to 2 decimal places
        @return The percentage that will be taken from the transaction fee 
                as a community contribution (2 d.p) */
    function getCommunityContribution() external view returns (uint256) {
        return settings.communityContribution;
    }

    /** @notice Return transaction fee, to 2 decimal places
        @return The percentage that will be taken from each transaction as a fee (2 d.p) */
    function getTransactionFee() external view returns (uint256) {
        return settings.transactionFee;
    }

    /** @notice Return the community contribution account
        @return The address that the community contribution is sent to */
    function getCommunityContributionAccount() external view returns (address) {
        return settings.communityContributionAccount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
    @title A controllable contract that can incrementally transition to an
        immutable contract
    @author Marc Griffiths, Value Instrument, the enkel collective
    @notice Provides special permisions to a controller account or contract,
        while allowing those special permissions to be discarded at any time */

contract FusedController is Initializable {
    address public controller;
    // address with priviledges to adjust settings, add accounts etc

    bool allFusesBlown;
    // set this to true to blow all fuses

    bool[32] fuseBlown;
    /* allows a seperate fuse for distinct functions, so that those functions
    can be disabled */

    event BlowFuse(uint8 _fuseID);
    event BlowAllFuses();
    event ChangeController(address _newController);

    function initialize(address _controller) public initializer {
        if (_controller == address(0)) {
            controller = msg.sender;
        } else {
            controller = _controller;
        }
    }

    /// Modifiers

    modifier fused(uint8 _fuseID) {
        require(allFusesBlown == false, "Function fuse has been triggered");
        require(
            fuseBlown[_fuseID] == false,
            "Function fuse has been triggered"
        );
        _;
    }
    modifier onlyController() {
        require(msg.sender == controller, "Controller account/contract only");
        _;
    }

    function blowAllFuses(bool _confirm) external onlyController {
        require(
            _confirm,
            "This will permanently disable function all fused functions, please set _confirm=true to confirm"
        );
        allFusesBlown = true;
        emit BlowAllFuses();
    }

    function blowFuse(uint8 _fuseID, bool _confirm) external onlyController {
        require(
            _confirm == true,
            "This will permanently disable function, please set _confirm=true to confirm"
        );
        fuseBlown[_fuseID] = true;
        emit BlowFuse(_fuseID);
    }

    function changeController(address _newController) external onlyController {
        controller = _newController;
        emit ChangeController(_newController);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Calculations {
    using SafeMath for uint256;

    uint256 constant contributionFeeDecimals = 2;
    uint256 constant multiplier = 10**6;

    /////////////////
    // Contributiones and fees
    /////////////////

    /** @notice Calculate the contribution due. Contribution is a percentage taken from the fee
        @dev Percentage to x dp as defined by contributionFeeDecimals e.g.
            when contributionFeeDecimals is 2, 1200 is 12.00%
        @return Tokens to pay as contribution */
    function calcContribution(
        uint256 _value,
        uint256 _feeRate,
        uint256 _contributionRate
    ) public pure returns (uint256) {
        uint256 contributionFeeMultiplier = (100 *
            10**contributionFeeDecimals)**2;
        return
            _value.mul(_feeRate).mul(_contributionRate).div(
                contributionFeeMultiplier
            );
    }

    /** @notice Calculate fees to burn. This is the fee % minus the contribution due
        @dev Percentage to x dp as defined by contributionFeeDecimals e.g.
            when contributionFeeDecimals is 2, 1200 is 12.00%
        @return Tokens to burn as fees */
    function calcFeesToBurn(
        uint256 _value,
        uint256 _feeRate,
        uint256 _contributionRate
    ) public pure returns (uint256) {
        uint256 contributionFeeMultiplier = 100 * 10**contributionFeeDecimals;
        return
            _value.mul(_feeRate).div(contributionFeeMultiplier).sub(
                calcContribution(_value, _feeRate, _contributionRate)
            );
    }

    /** @notice Calculate the total amount allocated for both fees and contribution
            Contribution % is not relavent as contributiones are taken from the fee
        @dev Percentage to x dp as defined by contributionFeeDecimals e.g.
            when contributionFeeDecimals is 2, 1200 is 12.00%
        @return Tokens to cover fees, inclusive of contribution */
    function calcFeesIncContribution(uint256 _value, uint256 _feeRate)
        public
        pure
        returns (uint256)
    {
        uint256 contributionFeeMultiplier = 100 * 10**contributionFeeDecimals;
        return _value.mul(_feeRate).div(contributionFeeMultiplier);
    }

    /** @notice Calculate the number of generation periods since the last
            generation block
        @return The number of completed periods since last generation block*/
    function calcNumCompletedPeriods(
        uint256 _blockNumber,
        uint256 _lastGenerationBlock,
        uint256 _generationPeriod
    ) public pure returns (uint256) {
        uint256 blocksSinceLastGeneration = _blockNumber.sub(
            _lastGenerationBlock
        );
        return blocksSinceLastGeneration.div(_generationPeriod);
    }

    /** @notice Calculate the number of tokens decayed since the last transaction
        @return Number of tokens decayed since last transaction */
    function calcDecay(
        uint256 _lastTransactionBlock,
        uint256 _balance,
        uint256 _thisBlock,
        uint256 _zeroBlock
    ) public pure returns (uint256) {
        require(
            _thisBlock >= _lastTransactionBlock,
            "Current block must be >= last transaction block"
        );

        // If zero block has not been set, decay = 0
        if (_zeroBlock == 0) {
            return 0;
        }

        // If zero block passed, decay all
        if (_thisBlock >= _zeroBlock) {
            return _balance;
        }

        // If no blocks passed since last transfer, nothing to decay
        uint256 blocksSinceLast = _thisBlock.sub(_lastTransactionBlock);
        if (blocksSinceLast == 0) {
            return 0;
        }
        /* Otherwise linear burn based on 'distance' moved to zeroblock since
            last transaction */
        uint256 fullDistance = _zeroBlock.sub(_lastTransactionBlock);
        uint256 relativeMovementToZero = blocksSinceLast.mul(multiplier).div(
            fullDistance
        );
        return _balance.mul(relativeMovementToZero).div(multiplier);
    }

    /** @notice Calculate the block at which the balance for this account will
            be zero
        @return Block at which balance is 0 */
    function calcZeroBlock(
        uint256 _value,
        uint256 _balance,
        uint256 _blockNumber,
        uint256 _lifetime,
        uint256 _originalZeroBlock
    ) public pure returns (uint256) {
        if (_balance == 0 || _originalZeroBlock == 0) {
            // No other transaction to consider, so use the full settings.lifetime
            return _blockNumber.add(_lifetime);
        }

        /* transactionWeight is the ratio of the transfer value to the total
            balance after the transfer */
        uint256 transactionWeight = _value.mul(multiplier).div(
            _balance.add(_value)
        );

        /* multiply the full settings.lifetime by this ratio, and add
            the result to the original zero block */
        uint256 newZeroBlock = _originalZeroBlock.add(
            _lifetime.mul(transactionWeight).div(multiplier)
        );

        if (newZeroBlock > _blockNumber.add(_lifetime)) {
            newZeroBlock = _blockNumber.add(_lifetime);
        }
        return newZeroBlock;
    }

    /** @notice Calculate the generation accrued since the last generation
            period
        @dev This function contains a for loop, so in theory may fail for
            accounts that have been inactive for an extremely long time. These
            accounts will have zero balance anyway. */
    function calcGeneration(
        uint256 _blockNumber,
        uint256 _lastGenerationBlock,
        uint256 _lifetime,
        uint256 _generationAmount,
        uint256 _generationPeriod
    ) public pure returns (uint256) {
        uint256 numCompletePeriods = calcNumCompletedPeriods(
            _blockNumber,
            _lastGenerationBlock,
            _generationPeriod
        );

        uint256 decayPerBlock = multiplier.div(_lifetime);
        uint256 decayPerGenerationPeriod = decayPerBlock.mul(_generationPeriod);
        uint256 remainingPerGenerationPeriod = multiplier.sub(
            decayPerGenerationPeriod
        );

        uint256 generation;
        for (uint256 i; i < numCompletePeriods; i++) {
            generation = generation
                .mul(remainingPerGenerationPeriod)
                .div(multiplier)
                .add(_generationAmount);
        }
        return generation;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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