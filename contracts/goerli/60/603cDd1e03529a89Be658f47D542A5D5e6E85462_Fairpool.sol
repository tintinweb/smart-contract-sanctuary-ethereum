// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "solmate/src/utils/FixedPointMathLib.sol";
import "./ERC20Enumerable.sol";
import "./SharedOwnership.sol";

/**
 * Definitions:
 * - base - token amount
 * - quote - money amount (native blockchain currency)
 *
 * Notes:
 * - quote = (base * base) * speed / scale; // the bonding curve equation (quote on the left side)
 * - base = (quote * scale / speed).sqrt(); // the bonding curve equation (base on the left side)
 * - price = quote / base = base * speed / scale; // the price equation
 * - The `_decimals` variable must be equal to the decimals of the base asset of the current blockchain (so that msg.value is scaled to this amount of decimals)
 * - Variables must use uint instead of smaller types because uint actually costs less gas
 * - Custom errors must be used over string descriptions because it costs less gas
 * - Custom errors must not include the function arguments (i.e. don't add function arguments as error parameters)
 * - Custom errors should be translated in UI
 * - Custom errors can have names of any length (the resulting selector is always 4 bytes)
 * - Ownable is needed to allow changing the social media URLs (only owner could do this, and the owner can transfer ownership to a multisig for better security)
 * - Ownable is needed to change speed & tax (otherwise there could be a battle between the beneficiaries)
 * - Owner may call renounceOwnership(), thus setting the owner to zero address
 * - sell() may increase tallies[msg.sender] (if the seller address is included in the distribution of dividends). This is desirable because of 1) lower gas cost (no need to check if address != msg.sender) 2) correct behavior in the limit case where the seller is the only remaining holder (he should not pay dividends to anyone else ~= he should pay dividends to himself)
 * - payable(msg.sender).transfer() are potential contract calls (revert on failure)
 * - baseNew is always divisible by scale without remainder (due to upscale() / downscale())
 * - quoteNew is always divisible by scale without remainder (due to getQuote(baseNew) )
 * - baseDelta is always divisible by scale without remainder (due to baseNew - baseOld / baseOld - baseNew)
 * - quoteDelta is always divisible by scale without remainder (due to quoteNew - quoteOld / quoteOld - quoteNew)
 */
contract Fairpool is ERC20Enumerable, SharedOwnership, ReentrancyGuard, Ownable {
    using FixedPointMathLib for uint;

    // Multiplier in the formula for base amount (as speed / scale)
    uint public speed;

    // Percentage of sale distributed to the beneficiaries (as royalties / scale)
    uint public royalties;

    // Percentage of sale distributed to the holders (as dividends / scale)
    // NOTE: can be set to zero to avoid the dividends
    uint public dividends;

    // Percentage of sale distributed to the operator (as fees / scale)
    uint public fees = scale * 25 / 1000; // 2.5%

    // Operator receives the fees
    address payable public operator = payable(0x7554140235ad2D1Cc75452D2008336700C598Dc1);

    // Quote asset balances available for withdrawal
    // IMPORTANT: Due to preallocation, sum(tallies) may increase without distribute() if someone simply transfers the underlying token to another person (by design, to preallocate the storage slot)
    // IMPORTANT: There's no deallocation: every address that has been a holder or a beneficiary in the past will always have tallies[address] >= defaultTally
    // `if (balanceOf(address) == 0) then (tallies[address] == 0)` => false, because beneficiaries may receive tallies while their balances are zero
    // `if (balanceOf(address) != 0) then (tallies[address] == defaultTally || tallies[address] > defaultTally)` => true, because of preallocation
    mapping(address => uint) internal tallies;

    // Real balance of contract (less than or equal to `address(this).balance - sum(tallies) - defaultTally * holders.length`)
    uint public quoteBalanceOfContract;

    // Allow up to 2 ** 32 unscaled
    uint internal constant maxSpeed = scale * (2 ** 32);

    // Allow up to 1 - (1 / scale) unscaled
    uint internal constant maxRoyalties = scale - 1;

    // Incremental holder cost is ~11000 gas (with preallocation optimization)
    // Full distribution cost is ~11000 gas * 256 holders = ~2816000 gas
    uint internal constant maxHoldersPerDistribution = 256;

    // used for preallocation: it is set on tallies for every holder
    uint internal constant defaultTally = 1;

    error BlockTimestampMustBeLessThanOrEqualToDeadline();
    error PaymentRequired();
    error BaseDeltaMustBeGreaterThanOrEqualToBaseDeltaMin(uint baseDelta);
    error QuoteReceivedMustBeGreaterThanOrEqualToQuoteReceivedMin(uint quoteDelta);
    error BaseDeltaMustBeGreaterThanZero();
    error BaseDeltaProposedMustBeLessThanOrEqualToBalance();
    error NothingToWithdraw();
    error AddressNotPayable(address addr);
    error SpeedMustBeLessThanOrEqualToMaxSpeed();
    error SpeedMustBeGreaterThanZero();
    error SpeedCanBeSetOnlyIfTotalSupplyIsZero();
    error RoyaltiesPlusDividendsPlusFeesMustBeLessThanScale();
    error NewTaxesMustBeLessThanOrEqualToOldTaxesOrTotalSupplyMustBeZero();
    error OnlyOperator();
    error OperatorMustNotBeZeroAddress();
    error OperatorMustNotBeContractAddress();

    event Buy(address indexed addr, uint baseDelta, uint quoteDelta);
    event Sell(address indexed addr, uint baseDelta, uint quoteDelta, uint quoteReceived);
    event Withdraw(address indexed addr, uint quoteReceived);
    event SetSpeed(uint speed);
    event SetRoyalties(uint royalties);
    event SetDividends(uint dividends);
    event SetFees(uint fees);
    event SetOperator(address operator);

    constructor(string memory name_, string memory symbol_, uint speed_, uint royalties_, uint dividends_, address payable[] memory beneficiaries_, uint[] memory shares_) ERC20(name_, symbol_) SharedOwnership(beneficiaries_, shares_) Ownable() {
        setSpeedInternal(speed_);
        setTaxesInternal(royalties_, dividends_, fees);
        // operator is already set
        // preallocate tallies
        for (uint i = 0; i < beneficiaries.length; i++) {
            tallies[beneficiaries[i]] = defaultTally;
        }
    }

    function buy(uint baseDeltaMin, uint deadline) public virtual payable nonReentrant {
        // slither-disable-next-line timestamp
        if (block.timestamp > deadline) revert BlockTimestampMustBeLessThanOrEqualToDeadline();
        if (msg.value == 0) revert PaymentRequired();
        (uint baseDelta, uint quoteDelta) = getBuyDeltas();
        if (baseDelta == 0) revert BaseDeltaMustBeGreaterThanZero();
        // baseDelta != 0 ==> quoteDelta != 0
        if (baseDelta < baseDeltaMin) revert BaseDeltaMustBeGreaterThanOrEqualToBaseDeltaMin(baseDelta);
        uint quoteRefund = msg.value - quoteDelta;
        emit Buy(msg.sender, baseDelta, quoteDelta);
        _mint(msg.sender, baseDelta);
        quoteBalanceOfContract += quoteDelta;
        if (quoteRefund != 0) payable(msg.sender).transfer(quoteRefund);
    }

    function sell(uint baseDeltaProposed, uint quoteReceivedMin, uint deadline) public virtual nonReentrant returns (uint quoteDistributed) {
        // slither-disable-next-line timestamp
        if (block.timestamp > deadline) revert BlockTimestampMustBeLessThanOrEqualToDeadline();
        if (baseDeltaProposed > balanceOf(msg.sender)) revert BaseDeltaProposedMustBeLessThanOrEqualToBalance();
        (uint baseDelta, uint quoteDelta) = getSellDeltas(baseDeltaProposed);
        if (baseDelta == 0) revert BaseDeltaMustBeGreaterThanZero();
        // baseDelta != 0 ==> quoteDelta != 0
        _burn(msg.sender, baseDelta);
        quoteBalanceOfContract -= quoteDelta;
        quoteDistributed = distribute(quoteDelta);
        uint quoteReceived = quoteDelta - quoteDistributed;
        if (quoteReceived < quoteReceivedMin) revert QuoteReceivedMustBeGreaterThanOrEqualToQuoteReceivedMin(quoteReceived);
        emit Sell(msg.sender, baseDelta, quoteDelta, quoteReceived);
        uint quoteWithdrawn = doWithdrawAndEmit();
        payable(msg.sender).transfer(quoteReceived + quoteWithdrawn);
    }

    function withdraw() public virtual nonReentrant {
        uint quoteWithdrawn = doWithdrawAndEmit();
        if (quoteWithdrawn == 0) revert NothingToWithdraw();
        payable(msg.sender).transfer(quoteWithdrawn);
    }

    function doWithdrawAndEmit() internal returns (uint quoteWithdrawn) {
        if (tallies[msg.sender] > defaultTally) {
            quoteWithdrawn = tallies[msg.sender] - defaultTally;
            emit Withdraw(msg.sender, quoteWithdrawn);
            tallies[msg.sender] = defaultTally;
        } else {
            quoteWithdrawn = 0;
        }
    }

    function setSpeed(uint $speed) external onlyOwner nonReentrant {
        if (totalSupply() != 0) revert SpeedCanBeSetOnlyIfTotalSupplyIsZero();
        setSpeedInternal($speed);
        emit SetSpeed($speed);
    }

    function setRoyalties(uint $royalties) external onlyOwner nonReentrant {
        setTaxesInternal($royalties, dividends, fees);
        emit SetRoyalties($royalties);
    }

    function setDividends(uint $dividends) external onlyOwner nonReentrant {
        setTaxesInternal(royalties, $dividends, fees);
        emit SetDividends($dividends);
    }

    function setFees(uint $fees) external onlyOperator nonReentrant {
        setTaxesInternal(royalties, dividends, $fees);
        emit SetFees($fees);
    }

    function setOperator(address payable $operator) external onlyOperator nonReentrant {
        setOperatorInternal($operator);
        emit SetOperator($operator);
    }

    function setSpeedInternal(uint $speed) internal {
        if ($speed == 0) revert SpeedMustBeGreaterThanZero();
        if ($speed > maxSpeed) revert SpeedMustBeLessThanOrEqualToMaxSpeed();
        speed = $speed;
    }

    function setOperatorInternal(address payable $operator) internal {
        if ($operator == address(0)) revert OperatorMustNotBeZeroAddress();
        if ($operator == address(this)) revert OperatorMustNotBeContractAddress();
        operator = $operator;
    }

    // using a single function for all three taxes to ensure their sum < scale (revert otherwise)
    function setTaxesInternal(uint $royalties, uint $dividends, uint $fees) internal {
        // checking each value separately first to ensure the sum doesn't overflow (otherwise Echidna reports an overflow)
        if ($royalties >= scale || $dividends >= scale || $fees >= scale || $royalties + $dividends + $fees >= scale) revert RoyaltiesPlusDividendsPlusFeesMustBeLessThanScale();
        if (totalSupply() != 0 && ($royalties > royalties || $dividends > dividends || $fees > fees)) revert NewTaxesMustBeLessThanOrEqualToOldTaxesOrTotalSupplyMustBeZero();
        royalties = $royalties;
        dividends = $dividends;
        fees = $fees;
    }

    /**
     * Distributes profit between beneficiaries and holders
     * Beneficiaries receive shares of profit
     * Holders receive shares of profit remaining after beneficiaries
     */
    function distribute(uint quoteDelta) internal returns (uint quoteDistributed) {
        // common loop variables
        uint i;
        uint length;
        uint total;
        address recipient;

        // distribute to beneficiaries
        uint quoteDistributedToBeneficiaries = (quoteDelta * royalties) / scale;
        if (quoteDistributedToBeneficiaries != 0) {
            length = beneficiaries.length;
            for (i = 0; i < length; i++) {
                recipient = beneficiaries[i];
                total = getShareAmount(quoteDistributedToBeneficiaries, recipient);
                tallies[recipient] += total;
                quoteDistributed += total;
            }
        }

        // distribute to holders
        uint quoteDistributedToHolders = (quoteDelta * dividends) / scale;
        if (quoteDistributedToHolders != 0) {
            length = holders.length;
            uint maxHolders = length < maxHoldersPerDistribution ? length : maxHoldersPerDistribution;
            uint baseOffset = getRandom(quoteDistributedToHolders) % holders.length; // 0 <= offset < holders.length
            uint offset;
            uint localTotalSupply;
            // NOTE: It's OK to use a separate loop to calculate localTotalSupply because the gas cost is much lower if you access the same storage slot multiple times within transaction
            for (i = 0; i < maxHolders; i++) {
                offset = addmod(baseOffset, i, length); // calculating offset with wrap-around
                localTotalSupply += balanceOf(holders[offset]);
            }
            for (i = 0; i < maxHolders; i++) {
                offset = addmod(baseOffset, i, length); // calculating offset with wrap-around
                recipient = holders[offset];
                total = (quoteDistributedToHolders * balanceOf(recipient)) / localTotalSupply;
                tallies[recipient] += total; // always 5000 gas, since we preallocate the storage slot in _afterTokenTransfer
                quoteDistributed += total;
            }
        }

        uint quoteDistributedToOperator = (quoteDelta * fees) / scale;
        if (quoteDistributedToOperator != 0) {
            operator.transfer(quoteDistributedToOperator);
            quoteDistributed += quoteDistributedToOperator;
        }
    }

    // IMPORTANT: "When a payable function is called: address(this).balance is increased by msg.value before any of your code is executed", so quoteNew should already include the msg.value
    // IMPORTANT: Buy deltas must be added, not subtracted from current amounts
    function getBuyDeltas() internal view returns (uint baseDelta, uint quoteDelta) {
        uint baseOld = totalSupply();
        uint quoteOld = quoteBalanceOfContract;
        uint quoteNewProposed = quoteOld + msg.value;
        uint baseNewProposed = getBase(quoteNewProposed);
        uint baseNew = downscale(baseNewProposed);
        uint quoteNew = getQuote(baseNew);
        if (baseNew < baseOld) { // may happen because of downscale()
            return (0, 0);
        } else {
            return (baseNew - baseOld, quoteNew - quoteOld);
        }
    }

    // IMPORTANT: Sell deltas must be subtracted, not added to current amounts
    function getSellDeltas(uint baseDeltaProposed) internal view returns (uint baseDelta, uint quoteDelta) {
        uint baseOld = totalSupply();
        uint quoteOld = quoteBalanceOfContract;
        uint baseNew = upscale(baseOld - baseDeltaProposed); // using upscale instead of downscale to ensure that `(baseOld - baseNew) < baseDeltaProposed` (because we're returning deltas to be subtracted, not added)
        uint quoteNew = getQuote(baseNew);
        if (baseOld < baseNew) { // may happen because of upscale() if baseDeltaProposed is very small
            return (0, 0);
        } else {
            return (baseOld - baseNew, quoteOld - quoteNew);
        }
    }

    function getQuote(uint base) internal view returns (uint quote) {
        return base * base * speed / scale;
    }

    function getBase(uint quote) internal view returns (uint base) {
        return (quote * scale / speed).sqrt();
    }

    // turn value into smaller $value that is divisible by scale without remainder (value > $value)
    function downscale(uint value) internal pure returns (uint $value) {
        return value / scale * scale;
    }

    // turn value into larger $value that is divisible by scale without remainder (value < $value)
    function upscale(uint value) internal pure returns (uint $value) {
        return (value / scale + 1) * scale;
    }

    modifier onlyOperator() {
        if (msg.sender != operator) revert OnlyOperator();
        _;
    }

    /* View functions */

    function withdrawable(address account) public view returns (uint) {
        return (tallies[account] <= defaultTally) ? 0 : tallies[account] - defaultTally;
    }

    /**
     * This PRNG is potentially insecure. However, it is only used to determine the base offset for the profit distribution. The only people who can benefit from gaming this function are current token holders (note that the seller is not included in the distribution because the _burn() is called before distribute()). Gaming this function requires collaboration between a miner and a seller, and only benefits multiple existing token holders. Therefore, we think that the risk of manipulation is low.
     */
    function getRandom(uint input) internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, blockhash(block.number - 1), msg.sender, input)));
    }

    /* Pure functions */

    /* Override functions */

    function _beforeTokenTransfer(
        address,
        address to,
        uint256
    ) internal virtual override {
        // [not needed] super._beforeTokenTransfer(from, to, amount);
        // check that address is payable before transferring the tokens, otherwise distribute() will revert for everyone
        // source: https://ethereum.stackexchange.com/a/123679
        // slither-disable-next-line arbitrary-send-eth
        if (!payable(to).send(0)) revert AddressNotPayable(to);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);
        // preallocate the storage slot to save on gas in the distribute() loop
        // minTotal is subtracted in withdraw()
        if (from == to || amount == 0) {
            return;
        }
        if (to != address(0) && balanceOf(to) != 0) {
            preallocate(to);
        }
    }

    function addBeneficiary(address target) internal virtual override {
        super.addBeneficiary(target);
        preallocate(target);
    }

    function preallocate(address target) internal {
        // `if` is necessary to prevent overwriting an existing positive tally
        if (tallies[target] == 0) tallies[target] = defaultTally;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract ERC20Enumerable is ERC20 {
    address[] public holders;

    // NOTE: solidity will return 0 for any address that is not present in indexesOfHolders. However, 0 is a valid index. We test against it via totalSupplyArray_eq_totalSupply()
    mapping (address => uint) internal indexesOfHolders;

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (from == to || amount == 0) {
            return;
        }
        if (from != address(0) && balanceOf(from) == 0) {
            removeHolder(from);
        }
        // if balanceOf(to) == amount, then balanceOfBeforeTransfer(to) == 0, so it should be added to holders
        if (to != address(0) && balanceOf(to) == amount) {
            addHolder(to);
        }
    }

    /**
     * Assumes that `holder` does not exist in `holders`
     */
    function addHolder(address target) internal {
        indexesOfHolders[target] = holders.length;
        holders.push(target);
    }

    /**
     * Assumes that `target` exists in `holders`
     * Uses a gas-optimal algorithm for removing the value from array
     * Does not preserve array order
     */
    function removeHolder(address target) internal {
        uint index = indexesOfHolders[target];
        address last = holders[holders.length - 1];
        indexesOfHolders[last] = index;
        holders[index] = last;
        holders.pop();
        delete indexesOfHolders[target];
    }

    function holdersLength() public view returns (uint) {
        return holders.length;
    }
}

/// UNUSED:
/// #invariant "balanceOf"
///    forall(uint i in holders)
///       balanceOf(holders[i]) > 0;
/// #invariant "totalSupplyArray() == totalSupply()" totalSupplyArray() == totalSupply();

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./Scaled.sol";

abstract contract SharedOwnership is Scaled {
    // maxBeneficiaries is required to limit the gas costs of the beneficiaries loop in distribute()
    uint8 public constant maxBeneficiaries = 16;

    address[] public beneficiaries;
    mapping (address => uint) public shares;
    mapping (address => uint) internal indexesOfBeneficiaries;

    error BeneficiariesLengthMustBeEqualToSharesLength();
    error BeneficiariesLengthMustBeLessThanOrEqualToMax();
    error ShareMustBeGreaterThanZero();
    error SumOfSharesMustBeEqualToScale();
    error ToAddressMustBeNonZero();
    error AmountMustBeNonZero();
    error SharesMustBeGreaterThanOrEqualToAmount();

    event TransferShares(address indexed from, address indexed to, uint amount);

    constructor(address payable[] memory beneficiaries_, uint[] memory shares_) {
        if (beneficiaries_.length == 0) {
            beneficiaries = [msg.sender];
            shares[msg.sender] = scale;
        } else {
            if (beneficiaries_.length != shares_.length) revert BeneficiariesLengthMustBeEqualToSharesLength();
            if (beneficiaries_.length > maxBeneficiaries) revert BeneficiariesLengthMustBeLessThanOrEqualToMax();
            beneficiaries = beneficiaries_;
            uint sumOfShares;
            for (uint i = 0; i < shares_.length; i++) {
                uint share = shares_[i];
                if (share == 0) revert ShareMustBeGreaterThanZero();
                // no need to check (share <= scale) because we already check (sumOfShares != scale)
                shares[beneficiaries_[i]] = shares_[i];
                sumOfShares += share;
            }
            if (sumOfShares != scale) revert SumOfSharesMustBeEqualToScale();
        }
    }

    /**
     * This function doesn't support burns, because it would break the add/remove logic
     */
    function transferShares(address to, uint amount) external returns (bool) {
        address from = msg.sender;
        if (to == address(0)) revert ToAddressMustBeNonZero();
        if (amount == 0) revert AmountMustBeNonZero();
        uint256 fromBalance = shares[from];
        if (fromBalance < amount) revert SharesMustBeGreaterThanOrEqualToAmount();
        unchecked { shares[from] = fromBalance - amount; }
        shares[to] += amount;
        emit TransferShares(from, to, amount);
        _afterSharesTransfer(from, to, amount);
        return true;
    }

    /**
     * This logic has to be duplicated from ERC20Enumerable because it relies on indexesOfBeneficiaries mapping which can't be passed by reference
     */
    function _afterSharesTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if (from == to || amount == 0) {
            return;
        }
        if (from != address(0) && shares[from] == 0) {
            removeBeneficiary(from);
        }
        if (to != address(0) && shares[to] == amount) {
            addBeneficiary(to);
        }
        if (beneficiaries.length > maxBeneficiaries) revert BeneficiariesLengthMustBeLessThanOrEqualToMax();
    }

    /**
     * Assumes that `holder` does not exist in `holders`
     */
    function addBeneficiary(address target) internal virtual {
        indexesOfBeneficiaries[target] = beneficiaries.length;
        beneficiaries.push(target);
    }

    /**
     * Assumes that `target` exists in `beneficiaries`
     * Uses a gas-optimal algorithm for removing the value from array
     * Does not preserve array order
     */
    function removeBeneficiary(address target) internal virtual {
        uint index = indexesOfBeneficiaries[target];
        address last = beneficiaries[beneficiaries.length - 1];
        indexesOfBeneficiaries[last] = index;
        beneficiaries[index] = last;
        beneficiaries.pop();
        delete indexesOfBeneficiaries[target];
    }

    function getShareAmount(uint amount, address target) internal view returns (uint) {
        return (amount * shares[target]) / scale;
    }

    function beneficiariesLength() external view returns (uint) {
        return beneficiaries.length;
    }
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

contract Scaled {
    uint8 internal constant _decimals = 6;
    uint internal constant scale = 10 ** 6;
}