pragma solidity ^0.6.6;

/**
    @title An open source smart contract for a UBI token with demurrage that
        gives control of the currency to the community, with adjustable
        parameters.
    @author The Value Instrument Team
    @notice 
    @dev This contract was developed for solc 0.6.6
*/

import "./lib/contracts-ethereum-package/token/ERC20/ERC20Burnable.sol";
import "./lib/contracts-ethereum-package/math/SafeMath.sol";
import "./FusedController.sol";
import "./lib/contracts-ethereum-package/Initializable.sol";
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
contract VICoin is ERC20BurnableUpgradeSafe, FusedController, Calculations {
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
    ) public {
        FusedController.initialize(_controller);
        __ERC20_init(_name, _symbol);

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

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./ERC20.sol";
import "../../Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeSafe is
    Initializable,
    ContextUpgradeSafe,
    ERC20UpgradeSafe
{
    function __ERC20Burnable_init() internal initializer {
        __Context_init_unchained();
        __ERC20Burnable_init_unchained();
    }

    function __ERC20Burnable_init_unchained() internal initializer {}

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
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(
            amount,
            "ERC20: burn amount exceeds allowance"
        );

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - .
     */
    function burnAt(address account, uint256 amount) public virtual {
        _burn(account, amount);
    }

    uint256[50] private __gap;
}

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.6;

import "./lib/contracts-ethereum-package/Initializable.sol";

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

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

pragma solidity ^0.6.6;

import "./lib/contracts-ethereum-package/math/SafeMath.sol";

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

pragma solidity ^0.6.0;
import "../Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20UpgradeSafe is Initializable, ContextUpgradeSafe, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */

    function __ERC20_init(string memory name, string memory symbol) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
    }

    function __ERC20_init_unchained(string memory name, string memory symbol) internal initializer {


        _name = name;
        _symbol = symbol;
        _decimals = 18;

    }


    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    uint256[44] private __gap;
}

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

pragma solidity ^0.6.2;

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
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}