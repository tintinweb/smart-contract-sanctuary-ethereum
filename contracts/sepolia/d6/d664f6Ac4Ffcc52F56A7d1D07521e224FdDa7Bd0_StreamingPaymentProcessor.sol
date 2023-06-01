// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

// Internal Dependencies
import {
    IPaymentProcessor,
    IPaymentClient
} from "src/modules/IPaymentProcessor.sol";
import {Module} from "src/modules/base/Module.sol";
import {ERC20} from "@oz/token/ERC20/ERC20.sol";

// Interfaces
import {IERC20} from "@oz/token/ERC20/IERC20.sol";
import {IProposal} from "src/proposal/IProposal.sol";

/**
 * @title Payment processor module implementation #2: Linear vesting curve.
 *
 * @dev The payment module handles the money flow to the contributors
 * (e.g. how many tokens are sent to which contributor at what time).
 *
 * @author byterocket
 */

contract StreamingPaymentProcessor is Module, IPaymentProcessor {
    //--------------------------------------------------------------------------
    // Storage

    struct StreamingWallet {
        uint _salary;
        uint _released;
        uint _start;
        uint _duration;
    }

    // paymentClient => contributor => Payment
    mapping(address => mapping(address => StreamingWallet)) private vestings;
    // paymentClient => contributor => unclaimableAmount
    mapping(address => mapping(address => uint)) private unclaimableAmounts;

    /// @notice list of addresses with open payment Orders per paymentClient
    mapping(address => address[]) private activePayments;

    //--------------------------------------------------------------------------
    // Events

    /// @notice Emitted when a payment gets processed for execution.
    /// @param recipient The address that will receive the payment.
    /// @param amount The amount of tokens the payment consists of.
    /// @param start Timestamp at which the vesting starts.
    /// @param duration Timestamp at which the full amount should be claimable.
    event StreamingPaymentAdded(
        address indexed paymentClient,
        address indexed recipient,
        uint amount,
        uint start,
        uint duration
    );

    /// @notice Emitted when the vesting to an address is removed.
    /// @param recipient The address that will stop receiving payment.
    event StreamingPaymentRemoved(
        address indexed paymentClient, address indexed recipient
    );

    /// @notice Emitted when a running vesting schedule gets updated.
    /// @param recipient The address that will receive the payment.
    /// @param newSalary The new amount of tokens the payment consists of.
    /// @param newDuration Number of blocks over which the amount will vest.
    event PaymentUpdated(address recipient, uint newSalary, uint newDuration);

    /// @notice Emitted when a running vesting schedule gets updated.
    /// @param recipient The address that will receive the payment.
    /// @param amount The amount of tokens the payment consists of.
    /// @param start Timestamp at which the vesting starts.
    /// @param duration Number of blocks over which the amount will vest
    event InvalidStreamingOrderDiscarded(
        address indexed recipient, uint amount, uint start, uint duration
    );

    //--------------------------------------------------------------------------
    // Errors

    /// @notice insufficient tokens in the client to do payments
    error Module__PaymentManager__InsufficientTokenBalanceInClient();

    //--------------------------------------------------------------------------
    // Modifiers

    /// @notice checks that the caller is an active module
    modifier onlyModule() {
        if (!proposal().isModule(_msgSender())) {
            revert Module__PaymentManager__OnlyCallableByModule();
        }
        _;
    }

    /// @notice checks that the client is calling for itself
    modifier validClient(IPaymentClient client) {
        if (_msgSender() != address(client)) {
            revert Module__PaymentManager__CannotCallOnOtherClientsOrders();
        }
        _;
    }

    //--------------------------------------------------------------------------
    // External Functions

    /// @inheritdoc Module
    function init(
        IProposal proposal_,
        Metadata memory metadata,
        bytes memory /*configdata*/
    ) external override(Module) initializer {
        __Module_init(proposal_, metadata);
    }

    /// @notice Release the releasable tokens.
    ///         In OZ VestingWallet this method is named release().
    function claim(IPaymentClient client) external {
        _claim(address(client), _msgSender());
    }

    /// @inheritdoc IPaymentProcessor
    function processPayments(IPaymentClient client)
        external
        onlyModule
        validClient(client)
    {
        //We check if there are any new paymentOrders, without processing them
        if (client.paymentOrders().length > 0) {
            // If there are, we remove all payments that would be overwritten
            // Doing it at the start ensures that collectPaymentOrders will always start from a blank slate concerning balances/allowances.
            _cancelRunningOrders(client);

            // Collect outstanding orders and their total token amount.
            IPaymentClient.PaymentOrder[] memory orders;
            uint totalAmount;
            (orders, totalAmount) = client.collectPaymentOrders();

            if (token().balanceOf(address(client)) < totalAmount) {
                revert Module__PaymentManager__InsufficientTokenBalanceInClient(
                );
            }

            // Generate Streaming Payments for all orders
            address _recipient;
            uint _amount;
            uint _start;
            uint _duration;
            for (uint i; i < orders.length; i++) {
                _recipient = orders[i].recipient;
                _amount = orders[i].amount;
                _start = orders[i].createdAt;
                _duration = (orders[i].dueTo - _start);

                _addPayment(
                    address(client), _recipient, _amount, _start, _duration
                );

                emit PaymentOrderProcessed(
                    address(client), _recipient, _amount, _start, _duration
                );
            }
        }
    }

    /// @inheritdoc IPaymentProcessor
    function cancelRunningPayments(IPaymentClient client)
        external
        onlyModule
        validClient(client)
    {
        _cancelRunningOrders(client);
    }

    /// @notice Deletes a contributors payment and leaves non-released tokens
    ///         in the PaymentClient.
    /// @param contributor Contributor's address.
    function removePayment(IPaymentClient client, address contributor)
        external
        onlyAuthorized
    {
        _removePayment(address(client), contributor);
    }

    //--------------------------------------------------------------------------
    // Public Functions

    /// @notice Getter for the start timestamp.
    /// @param contributor Contributor's address.
    function start(address client, address contributor)
        public
        view
        returns (uint)
    {
        return vestings[client][contributor]._start;
    }

    /// @notice Getter for the vesting duration.
    /// @param contributor Contributor's address.
    function duration(address client, address contributor)
        public
        view
        returns (uint)
    {
        return vestings[client][contributor]._duration;
    }

    /// @notice Getter for the amount of eth already released
    /// @param contributor Contributor's address.
    function released(address client, address contributor)
        public
        view
        returns (uint)
    {
        return vestings[client][contributor]._released;
    }

    /// @notice Calculates the amount of tokens that has already vested.
    /// @param contributor Contributor's address.
    function vestedAmount(address client, address contributor, uint timestamp)
        public
        view
        returns (uint)
    {
        return _vestingSchedule(client, contributor, timestamp);
    }

    /// @notice Getter for the amount of releasable tokens.
    function releasable(address client, address contributor)
        public
        view
        returns (uint)
    {
        return vestedAmount(client, contributor, uint(block.timestamp))
            - released(client, contributor);
    }

    /// @notice Getter for the amount of tokens that could not be claimed.
    function unclaimable(address client, address contributor)
        public
        view
        returns (uint)
    {
        return unclaimableAmounts[client][contributor];
    }

    function token() public view returns (IERC20) {
        return this.proposal().token();
    }

    //--------------------------------------------------------------------------
    // Internal Functions

    function findAddressInActivePayments(address client, address contributor)
        internal
        view
        returns (uint)
    {
        address[] memory contribSearchArray = activePayments[client];

        uint length = activePayments[client].length;
        for (uint i; i < length; i++) {
            if (contribSearchArray[i] == contributor) {
                return i;
            }
        }
        return type(uint).max;
    }

    function _cancelRunningOrders(IPaymentClient client) internal {
        //IPaymentClient.PaymentOrder[] memory orders;
        //orders = client.paymentOrders();
        address[] memory _activePayments = activePayments[address(client)];

        address _recipient;
        for (uint i; i < _activePayments.length; ++i) {
            _recipient = _activePayments[i];

            _removePayment(address(client), _recipient);
        }
    }

    function _removePayment(address client, address contributor) internal {
        //we claim the earned funds for the contributor.
        _claim(client, contributor);

        //we remove the payment from the activePayments array
        uint contribIndex = findAddressInActivePayments(client, contributor);

        if (contribIndex != type(uint).max) {
            // Move the last element into the place to delete
            activePayments[client][contribIndex] =
                activePayments[client][activePayments[client].length - 1];
            // Remove the last element
            activePayments[client].pop();

            delete vestings[client][contributor];

            emit StreamingPaymentRemoved(client, contributor);
        }

        /// Note that all unvested funds remain in the PaymentClient, where they will be accounted for in future payment orders.
    }

    /// @notice Adds a new payment containing the details of the monetary flow
    ///         depending on the module.
    /// @param _contributor Contributor's address.
    /// @param _salary Salary contributor will receive per epoch.
    /// @param _start Start vesting timestamp.
    /// @param _duration Streaming duration timestamp.
    function _addPayment(
        address client,
        address _contributor,
        uint _salary,
        uint _start,
        uint _duration
    ) internal {
        if (
            !validAddress(_contributor) || !validSalary(_salary)
                || !validStart(_start) || !validDuration(_duration)
        ) {
            emit InvalidStreamingOrderDiscarded(
                _contributor, _salary, _start, _duration
            );
        } else {
            vestings[client][_contributor] =
                StreamingWallet(_salary, 0, _start, _duration);

            uint contribIndex =
                findAddressInActivePayments(client, _contributor);
            if (contribIndex == type(uint).max) {
                activePayments[client].push(_contributor);
            }

            emit StreamingPaymentAdded(
                client, _contributor, _salary, _start, _duration
            );
        }
    }

    function _claim(address client, address beneficiary) internal {
        uint amount = releasable(client, beneficiary);
        vestings[client][beneficiary]._released += amount;

        //if beneficiary has unclaimable tokens from before, add it to releasable amount
        if (unclaimableAmounts[client][beneficiary] > 0) {
            amount += unclaimable(client, beneficiary);
            delete unclaimableAmounts[client][beneficiary];
        }

        // we claim the earned funds for the contributor.
        address _token = address(token());
        (bool success, bytes memory data) = address(_token).call(
            abi.encodeWithSelector(
                IERC20(_token).transferFrom.selector,
                client,
                beneficiary,
                amount
            )
        );
        if (success && (data.length == 0 || abi.decode(data, (bool)))) {
            emit TokensReleased(beneficiary, _token, amount);
        } else {
            // if transfer fails, store amount to unclaimableAmounts.
            unclaimableAmounts[client][beneficiary] += amount;
        }
    }

    /// @notice Virtual implementation of the vesting formula.
    ///         Returns the amount vested, as a function of time,
    ///         for an asset given its total historical allocation.
    /// @param contributor The contributor to check on.
    /// @param timestamp Current block.timestamp
    function _vestingSchedule(
        address client,
        address contributor,
        uint timestamp
    ) internal view virtual returns (uint) {
        uint totalAllocation = vestings[client][contributor]._salary;
        uint startContributor = start(client, contributor);
        uint durationContributor = duration(client, contributor);

        if (timestamp < startContributor) {
            return 0;
        } else if (timestamp > startContributor + durationContributor) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - startContributor))
                / durationContributor;
        }
    }

    /// @notice validate address input.
    /// @param addr Address to validate.
    /// @return True if address is valid.
    function validAddress(address addr) internal view returns (bool) {
        if (
            addr == address(0) || addr == _msgSender() || addr == address(this)
                || addr == address(proposal())
        ) {
            return false;
        }
        return true;
    }

    function validSalary(uint _salary) internal pure returns (bool) {
        if (_salary == 0) {
            return false;
        }
        return true;
    }

    function validStart(uint _start) internal view returns (bool) {
        if (_start < block.timestamp || _start >= type(uint).max) {
            return false;
        }
        return true;
    }

    function validDuration(uint _duration) internal pure returns (bool) {
        if (_duration == 0) {
            return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

import {IERC20} from "@oz/token/ERC20/IERC20.sol";

import {IPaymentClient} from "src/modules/mixins/IPaymentClient.sol";

interface IPaymentProcessor {
    //--------------------------------------------------------------------------
    // Errors

    /// @notice invalid caller
    error Module__PaymentManager__OnlyCallableByModule();

    /// @notice a client can only execute on its own orders
    error Module__PaymentManager__CannotCallOnOtherClientsOrders();

    //--------------------------------------------------------------------------
    // Events

    /// @notice Emitted when a payment gets processed for execution.
    /// @param paymentClient The payment client that originated the order.
    /// @param recipient The address that will receive the payment.
    /// @param amount The amount of tokens the payment consists of.
    /// @param createdAt Timestamp at which the order was created.
    /// @param dueTo Timestamp at which the full amount should be payed out/claimable.
    event PaymentOrderProcessed(
        address indexed paymentClient,
        address indexed recipient,
        uint amount,
        uint createdAt,
        uint dueTo
    );

    /// @notice Emitted when an amount of ERC20 tokens gets sent out of the contract.
    /// @param recipient The address that will receive the payment.
    /// @param amount The amount of tokens the payment consists of.
    event TokensReleased(
        address indexed recipient, address indexed token, uint amount
    );

    //--------------------------------------------------------------------------
    // Functions

    /// @notice Processes all payments from an {IPaymentClient} instance.
    /// @dev It's up to the the implementation to keep up with what has been
    ///      paid out or not.
    /// @param client The {IPaymentClient} instance to process its to payments.
    function processPayments(IPaymentClient client) external;

    /// @notice Cancels all unfinished payments from an {IPaymentClient} instance.
    /// @dev It's up to the the implementation to keep up with what has been
    ///      paid out or not.
    /// @param client The {IPaymentClient} instance to process its to payments.
    function cancelRunningPayments(IPaymentClient client) external;

    /// @notice Returns the IERC20 token the payment processor can process.
    function token() external view returns (IERC20);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

// External Dependencies
import {
    PausableUpgradeable,
    ContextUpgradeable
} from "@oz-up/security/PausableUpgradeable.sol";

// Internal Libraries
import {LibMetadata} from "src/modules/lib/LibMetadata.sol";

// Internal Interfaces
import {IModule, IProposal} from "src/modules/base/IModule.sol";
import {IAuthorizer} from "src/modules/IAuthorizer.sol";

/**
 * @title Module
 *
 * @dev The base contract for modules.
 *
 *      This contract provides a framework for triggering and receiving proposal
 *      callbacks (via `call`) and a modifier to authenticate
 *      callers via the module's proposal.
 *
 *      Each module is identified via a unique identifier based on its major
 *      version, title, and url given in the metadata.
 *
 *      Using proxy contracts, e.g. beacons, enables globally updating module
 *      instances when its minor version changes, but supports differentiating
 *      otherwise equal modules with different major versions.
 *
 * @author byterocket
 */
abstract contract Module is IModule, PausableUpgradeable {
    //--------------------------------------------------------------------------
    // Storage
    //
    // Variables are prefixed with `__Module_`.

    /// @dev The module's proposal instance.
    ///
    /// @custom:invariant Not mutated after initialization.
    IProposal internal __Module_proposal;

    /// @dev The module's metadata.
    ///
    /// @custom:invariant Not mutated after initialization.
    Metadata internal __Module_metadata;

    //--------------------------------------------------------------------------
    // Modifiers
    //
    // Note that the modifiers declared here are available in dowstream
    // contracts too. To not make unnecessary modifiers available, this contract
    // inlines argument validations not needed in downstream contracts.

    /// @notice Modifier to guarantee function is only callable by addresses
    ///         authorized via Proposal.
    modifier onlyAuthorized() {
        IAuthorizer authorizer = __Module_proposal.authorizer();
        if (!authorizer.isAuthorized(_msgSender())) {
            revert Module__CallerNotAuthorized();
        }
        _;
    }

    /// @notice Modifier to guarantee function is only callable by either
    ///         addresses authorized via Proposal or the Proposal's manager.
    modifier onlyAuthorizedOrManager() {
        IAuthorizer authorizer = __Module_proposal.authorizer();
        if (
            !authorizer.isAuthorized(_msgSender())
                && __Module_proposal.manager() != _msgSender()
        ) {
            revert Module__CallerNotAuthorized();
        }
        _;
    }

    /// @notice Modifier to guarantee function is only callable by the proposal.
    /// @dev onlyProposal functions MUST only access the module's storage, i.e.
    ///      `__Module_` variables.
    /// @dev Note to use function prefix `__Module_`.
    modifier onlyProposal() {
        if (_msgSender() != address(__Module_proposal)) {
            revert Module__OnlyCallableByProposal();
        }
        _;
    }

    //--------------------------------------------------------------------------
    // Initialization

    constructor() {
        _disableInitializers();
    }

    /// @inheritdoc IModule
    function init(
        IProposal proposal_,
        Metadata memory metadata,
        bytes memory /*configdata*/
    ) external virtual initializer {
        __Module_init(proposal_, metadata);
    }

    /// @dev The initialization function MUST be called by the upstream
    ///      contract in their overriden `init()` function.
    /// @param proposal_ The module's proposal.
    function __Module_init(IProposal proposal_, Metadata memory metadata)
        internal
        onlyInitializing
    {
        __Pausable_init();

        // Write proposal to storage.
        if (address(proposal_) == address(0)) {
            revert Module__InvalidProposalAddress();
        }
        __Module_proposal = proposal_;

        // Write metadata to storage.
        if (!LibMetadata.isValid(metadata)) {
            revert Module__InvalidMetadata();
        }
        __Module_metadata = metadata;
    }

    //--------------------------------------------------------------------------
    // onlyAuthorized Functions
    //
    // API functions for authenticated users.

    /// @inheritdoc IModule
    function pause() external override(IModule) onlyAuthorizedOrManager {
        _pause();
    }

    /// @inheritdoc IModule
    function unpause() external override(IModule) onlyAuthorizedOrManager {
        _unpause();
    }

    //--------------------------------------------------------------------------
    // Public View Functions

    /// @inheritdoc IModule
    function identifier() public view returns (bytes32) {
        return LibMetadata.identifier(__Module_metadata);
    }

    /// @inheritdoc IModule
    function version() public view returns (uint, uint) {
        return (__Module_metadata.majorVersion, __Module_metadata.minorVersion);
    }

    /// @inheritdoc IModule
    function url() public view returns (string memory) {
        return __Module_metadata.url;
    }

    /// @inheritdoc IModule
    function title() public view returns (string memory) {
        return __Module_metadata.title;
    }

    /// @inheritdoc IModule
    function proposal() public view returns (IProposal) {
        return __Module_proposal;
    }

    //--------------------------------------------------------------------------
    // Internal Functions

    /// @dev Internal function to trigger a callback from the proposal.
    /// @param data The call data for the proposal to call.
    /// @return Whether the callback succeeded.
    /// @return The return data of the callback.
    function _triggerProposalCallback(bytes memory data)
        internal
        returns (bool, bytes memory)
    {
        bool ok;
        bytes memory returnData;
        (ok, returnData) =
            __Module_proposal.executeTxFromModule(address(this), data);

        // Note that there is no check whether the proposal callback succeeded.
        // This responsibility is delegated to the caller, i.e. downstream
        // module implementation.
        // However, the {IModule} interface defines a generic error type for
        // failed proposal callbacks that can be used to prevent different
        // custom error types in each implementation.
        return (ok, returnData);
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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

// External Interfaces
import {IERC20} from "@oz/token/ERC20/IERC20.sol";

// Internal Interfaces
import {IModuleManager} from "src/proposal/base/IModuleManager.sol";
import {IFundingManager} from "src/proposal/base/IFundingManager.sol";
import {IAuthorizer} from "src/modules/IAuthorizer.sol";
import {IPaymentProcessor} from "src/modules/IPaymentProcessor.sol";

interface IProposal is IModuleManager, IFundingManager {
    //--------------------------------------------------------------------------
    // Errors

    /// @notice Function is only callable by authorized caller.
    error Proposal__CallerNotAuthorized();

    /// @notice Execution of transaction failed.
    error Proposal__ExecuteTxFailed();

    //--------------------------------------------------------------------------
    // Functions

    /// @notice Initialization function.
    function init(
        uint proposalId,
        address owner,
        IERC20 token,
        address[] calldata modules,
        IAuthorizer authorizer,
        IPaymentProcessor paymentProcessor
    ) external;

    /// @notice Executes a call on target `target` with call data `data`.
    /// @dev Only callable by authorized caller.
    /// @param target The address to call.
    /// @param data The call data.
    /// @return The return data of the call.
    function executeTx(address target, bytes memory data)
        external
        returns (bytes memory);

    /// @notice Returns the proposal's id.
    /// @dev Unique id set by the {ProposalFactory} during initialization.
    function proposalId() external view returns (uint);

    /// @notice The {IAuthorizer} implementation used to authorize addresses.
    function authorizer() external view returns (IAuthorizer);

    /// @notice The {IPaymentProcessor} implementation used to process module
    ///         payments.
    function paymentProcessor() external view returns (IPaymentProcessor);

    /// @notice The proposal's {IERC20} token accepted for fundings and used
    ///         for payments.
    function token() external view returns (IERC20);

    /// @notice The proposal's non-rebasing receipt token.
    function receiptToken() external view returns (IERC20);

    /// @notice The version of the proposal instance.
    function version() external pure returns (string memory);

    function owner() external view returns (address);

    function manager() external view returns (address);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

// Internal Interfaces
import {IPaymentProcessor} from "src/modules/IPaymentProcessor.sol";

interface IPaymentClient {
    struct PaymentOrder {
        /// @dev The recipient of the payment.
        address recipient;
        /// @dev The amount of tokens to pay.
        uint amount;
        /// @dev Timestamp at which the order got created.
        uint createdAt;
        /// @dev Timestamp at which the payment SHOULD be fulfilled.
        uint dueTo;
    }

    //--------------------------------------------------------------------------
    // Errors

    /// @notice Function is only callable by authorized address.
    error Module__PaymentClient__CallerNotAuthorized();

    /// @notice ERC20 token transfer failed.
    error Module__PaymentClient__TokenTransferFailed();

    /// @notice Given recipient invalid.
    error Module__PaymentClient__InvalidRecipient();

    /// @notice Given amount invalid.
    error Module__PaymentClient__InvalidAmount();

    /// @notice Given dueTo invalid.
    error Module__PaymentClient__InvalidDueTo();

    /// @notice Given arrays' length mismatch.
    error Module__PaymentClient__ArrayLengthMismatch();

    //--------------------------------------------------------------------------
    // Events

    /// @notice Added a payment order.
    /// @param recipient The address that will receive the payment.
    /// @param amount The amount of tokens the payment consists of.
    event PaymentOrderAdded(address indexed recipient, uint amount);

    //--------------------------------------------------------------------------
    // Functions

    /// @notice Returns the list of outstanding payment orders.
    function paymentOrders() external view returns (PaymentOrder[] memory);

    /// @notice Returns the total outstanding token payment amount.
    function outstandingTokenAmount() external view returns (uint);

    /// @notice Collects outstanding payment orders.
    /// @dev Marks the orders as completed for the client.
    ///      The responsibility to fulfill the orders are now in the caller's
    ///      hand!
    /// @return list of payment orders
    /// @return total amount of token to pay
    function collectPaymentOrders()
        external
        returns (PaymentOrder[] memory, uint);
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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

import {IModule} from "src/modules/base/IModule.sol";

/**
 * @title Metadata Library
 *
 * @dev Provides common functions for {IModule}'s Metadata type.
 *
 * @author byterocket
 */
library LibMetadata {
    /// @dev Returns the identifier for given metadata.
    /// @param metadata The metadata.
    /// @return The metadata's identifier.
    function identifier(IModule.Metadata memory metadata)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                metadata.majorVersion, metadata.url, metadata.title
            )
        );
    }

    /// @dev Returns whether the given metadata is valid.
    /// @param metadata The metadata.
    /// @return True if metadata valid, false otherwise.
    function isValid(IModule.Metadata memory metadata)
        internal
        pure
        returns (bool)
    {
        // Invalid if url empty.
        if (bytes(metadata.url).length == 0) {
            return false;
        }

        // Invalid if title empty.
        if (bytes(metadata.title).length == 0) {
            return false;
        }

        // Invalid if version is v0.0.
        if (metadata.majorVersion == 0 && metadata.minorVersion == 0) {
            return false;
        }

        return true;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

// Internal Interfaces
import {IProposal} from "src/proposal/IProposal.sol";

interface IModule {
    struct Metadata {
        uint majorVersion;
        uint minorVersion;
        string url;
        string title;
    }

    //--------------------------------------------------------------------------
    // Errors

    /// @notice Function is only callable by authorized caller.
    error Module__CallerNotAuthorized();

    /// @notice Function is only callable by the proposal.
    error Module__OnlyCallableByProposal();

    /// @notice Given proposal address invalid.
    error Module__InvalidProposalAddress();

    /// @notice Given metadata invalid.
    error Module__InvalidMetadata();

    /// @notice Proposal callback triggered failed.
    /// @param funcSig The signature of the function called.
    error Module_ProposalCallbackFailed(string funcSig);

    //--------------------------------------------------------------------------
    // Functions

    /// @notice The module's initializer function.
    /// @dev CAN be overriden by downstream contract.
    /// @dev MUST call `__Module_init()`.
    /// @param proposal The module's proposal instance.
    /// @param metadata The module's metadata.
    /// @param configdata Variable config data for specific module
    ///                   implementations.
    function init(
        IProposal proposal,
        Metadata memory metadata,
        bytes memory configdata
    ) external;

    /// @notice Returns the module's identifier.
    /// @dev The identifier is defined as the keccak256 hash of the module's
    ///      abi packed encoded major version, url and title.
    /// @return The module's identifier.
    function identifier() external view returns (bytes32);

    /// @notice Returns the module's version.
    /// @return The module's major version.
    /// @return The module's minor version.
    function version() external view returns (uint, uint);

    /// @notice Returns the module's URL.
    /// @return The module's URL.
    function url() external view returns (string memory);

    /// @notice Returns the module's title.
    /// @return The module's title.
    function title() external view returns (string memory);

    /// @notice Returns the module's {IProposal} proposal instance.
    /// @return The module's proposal.
    function proposal() external view returns (IProposal);

    /// @notice Pauses the module.
    /// @dev Only callable by authorized addresses.
    function pause() external;

    /// @notice Unpauses the module.
    /// @dev Only callable by authorized addresses.
    function unpause() external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

interface IAuthorizer {
    function isAuthorized(address who) external view returns (bool);
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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

interface IModuleManager {
    //--------------------------------------------------------------------------
    // Errors

    /// @notice Function is only callable by authorized address.
    error Proposal__ModuleManager__CallerNotAuthorized();

    /// @notice Function is only callable by modules.
    error Proposal__ModuleManager__OnlyCallableByModule();

    /// @notice Given module address invalid.
    error Proposal__ModuleManager__InvalidModuleAddress();

    /// @notice Given address is a module.
    error Proposal__ModuleManager__IsModule();

    /// @notice Given address is not a module.
    error Proposal__ModuleManager__IsNotModule();

    /// @notice The supplied modules are not consecutive.
    error Proposal__ModuleManager__ModulesNotConsecutive();

    /// @notice The Manager has reached the maximum amount of modules.
    error Proposal__ModuleManager__ModuleAmountOverLimits();

    //--------------------------------------------------------------------------
    // Events

    /// @notice Event emitted when module added.
    /// @param module The module's address.
    event ModuleAdded(address indexed module);

    /// @notice Event emitted when module removed.
    /// @param module The module's address.
    event ModuleRemoved(address indexed module);

    /// @notice Event emitted when account `account` is granted role `role` for
    ///         module `module`.
    /// @param module The module's address.
    /// @param role The access control role.
    /// @param account The account the role was granted to.
    event ModuleRoleGranted(
        address indexed module, bytes32 indexed role, address indexed account
    );

    /// @notice Event emitted when account `account` is revoked role `role` for
    ///         module `module`.
    /// @param module The module's address.
    /// @param role The access control role.
    /// @param account The account the role was revoked for.
    event ModuleRoleRevoked(
        address indexed module, bytes32 indexed role, address indexed account
    );

    //--------------------------------------------------------------------------
    // Functions

    /// @notice Executes a call to `to` with call data `data` either via call
    /// @dev Only callable by enabled modules.
    /// @param to The address to call.
    /// @param data The call data.
    /// @return Whether the call succeeded.
    /// @return The return data of the call.
    function executeTxFromModule(address to, bytes memory data)
        external
        returns (bool, bytes memory);

    /// @notice Adds address `module` as module.
    /// @dev Only callable by authorized address.
    /// @dev Fails if address invalid or address already added as module.
    /// @param module The module address to add.
    function addModule(address module) external;

    /// @notice Removes address `module` as module.
    /// @dev Only callable by authorized address.
    /// @dev Fails if address not added as module.
    /// @param module The module address to remove.
    function removeModule(address module) external;

    /// @notice Returns whether the address `module` is added as module.
    /// @param module The module to check.
    /// @return True if module added, false otherwise.
    function isModule(address module) external returns (bool);

    /// @notice Returns the list of all modules.
    /// @return List of all modules.
    function listModules() external view returns (address[] memory);

    /// @notice Returns the number of modules.
    function modulesSize() external view returns (uint8);

    /// @notice Grants role `role` to account `account` in caller's access
    ///         control context.
    /// @dev Only callable by enabled module.
    /// @param role The access control role.
    /// @param account The account to grant given role.
    function grantRole(bytes32 role, address account) external;

    /// @notice Revokes role `role` from account `account` in caller's access
    ///         control context.
    /// @dev Only callable by enabled module.
    /// @param role The access control role.
    /// @param account The account to revoke role for.
    function revokeRole(bytes32 role, address account) external;

    /// @notice Renounces the caller's role `role` in module's `module` access
    ///         control context.
    /// @param module The module in which's access control context the role
    ///               should be renounced.
    /// @param role The access control role.
    function renounceRole(address module, bytes32 role) external;

    /// @notice Returns whether the account `account` holds the role `role` in
    ///         the module's `module` access control context.
    /// @param module The module in which's access control context the role
    ///               is checked.
    /// @param role The access control role.
    /// @param account The account to check role for.
    /// @return True if account has role in module's access control context,
    ///         false otherwise.
    function hasRole(address module, bytes32 role, address account)
        external
        returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

import {IRebasingERC20} from "src/proposal/token/IRebasingERC20.sol";

interface IFundingManager is IRebasingERC20 {
    //--------------------------------------------------------------------------
    // Errors

    /// @notice Function is only callable by authorized address.
    error Proposal__FundingManager__CannotSelfDeposit();

    /// @notice There is a cap on deposits.
    error Proposal__FundingManager__DepositCapReached();

    //--------------------------------------------------------------------------
    // Events

    /// @notice Event emitted when a deposit takes place.
    /// @param from The address depositing tokens.
    /// @param to The address that will receive the receipt tokens.
    /// @param amount The amount of tokens deposited.
    event Deposit(
        address indexed from, address indexed to, uint indexed amount
    );

    /// @notice Event emitted when a withdrawal takes place.
    /// @param from The address supplying the receipt tokens.
    /// @param to The address that will receive the underlying tokens.
    /// @param amount The amount of underlying tokens withdrawn.
    event Withdrawal(
        address indexed from, address indexed to, uint indexed amount
    );

    //--------------------------------------------------------------------------
    // Functions

    function deposit(uint amount) external;
    function depositFor(address to, uint amount) external;

    function withdraw(uint amount) external;
    function withdrawTo(address to, uint amount) external;
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "./IERC20Metadata.sol";

/**
 * @title Rebasing ERC20 Interface
 *
 * @dev Interface definition for Rebasing ERC20 tokens which have an "elastic"
 *      external balance and "fixed" internal balance.
 *      Each user's external balance is represented as a product of a "scalar"
 *      and the user's internal balance.
 *
 *      In regular time intervals the rebase operation updates the scalar,
 *      which increases or decreases all user balances proportionally.
 *
 *      The standard ERC20 methods are denomintaed in the elastic balance.
 *
 * @author Buttonwood Foundation
 */
interface IRebasingERC20 is IERC20Metadata {
    /// @notice Returns the fixed balance of the specified address.
    /// @param who The address to query.
    function scaledBalanceOf(address who) external view returns (uint);

    /// @notice Returns the total fixed supply.
    function scaledTotalSupply() external view returns (uint);

    /// @notice Transfer all of the sender's balance to a specified address.
    /// @param to The address to transfer to.
    /// @return True on success, false otherwise.
    function transferAll(address to) external returns (bool);

    /// @notice Transfer all balance tokens from one address to another.
    /// @param from The address to send tokens from.
    /// @param to The address to transfer to.
    function transferAllFrom(address from, address to)
        external
        returns (bool);

    /// @notice Triggers the next rebase, if applicable.
    function rebase() external;

    /// @notice Event emitted when the balance scalar is updated.
    /// @param epoch The number of rebases since inception.
    /// @param newScalar The new scalar.
    event Rebase(uint indexed epoch, uint newScalar);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)
pragma solidity ^0.8.13;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 *
 * @author OpenZeppelin
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 *
 * @author OpenZeppelin
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint);

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
    function approve(address spender, uint amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint amount)
        external
        returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint value);
}