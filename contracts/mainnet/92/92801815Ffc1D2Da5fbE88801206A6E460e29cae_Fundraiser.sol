//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Fundraiser is Ownable {
    struct FundraiserDetails {
        uint256 targetAmount;
        uint256 minContribution;
        uint256 currentAmount;
        address admin;
        uint40 targetTimestamp;
        uint8 noWhitelisted;
        bool killed;
        bool collected;
    }

    uint256 public platformFee = 499;
    uint256 public holdingFee = 499;
    uint256 public freeHoldingPeriod = 3600*24*30*6;
    uint256 public maxFundraiserDuration = 3600*24*30*12;
    
    uint256 public constant COMBINED_PERCENTAGE_PRECISION = 1000000;

    FundraiserDetails[] public fundraisers;
    mapping (address => mapping (uint256 => uint256)) public addressAndIndexToAmountFunded;
    mapping (address => mapping (uint256 => mapping(address => uint256))) public addressAndIndexToTokensFunded;
    mapping (address => mapping (uint256 => uint256)) public tokenAndIndexToValue;
    mapping (address => mapping (uint256 => uint256)) public tokenAndIndexToGoal;
    mapping (address => mapping (uint256 => bool)) public isTokenCollectedForFundraiser;

    bool public isCreateEnabled = false;

    event Create(address indexed admin, uint256 indexed index, uint256 targetTimestamp, uint256 targetAmount, uint256 minContribution, string name, string description);
    event WhitelistToken(uint256 indexed index, address indexed tokenAddress, uint256 goal, string tokenSymbol, uint256 decimals);
    event Donate(address indexed contributor, uint256 indexed index, uint256 value);
    event DonateToken(address indexed contributor, uint256 indexed index, uint256 value, address tokenAddress);
    event Refund(address indexed contributor, uint256 indexed index);
    event RefundToken(address indexed contributor, uint256 indexed index, address indexed tokenAddress);
    event Collect(uint256 indexed index);
    event CollectToken(uint256 indexed index, address indexed tokenAddress);
    event Killed(uint256 indexed index);


    // ======= Platform config =======

    /**
     * @dev Update free holding period
     */
    function updateFreeHoldingPeriod(uint256 newPeriodInSeconds) external onlyOwner {
        freeHoldingPeriod = newPeriodInSeconds;
    }

    /**
     * @dev Update max fundraiser duration
     */
    function updateMaxFundraiserDuration(uint256 newDurationInSeconds) external onlyOwner {
        maxFundraiserDuration = newDurationInSeconds;
    }

    /**
     * @dev Update holding fee
     */
    function updateHoldingFee(uint256 newHoldingFeeInPercentFractions) external onlyOwner {
        require(newHoldingFeeInPercentFractions <= 1000, "Fee too large");
        holdingFee = newHoldingFeeInPercentFractions;
    }

    /**
     * @dev Update platform fee
     */
    function updatePlatformFee(uint256 newPlatformFeeInPercentFractions) external onlyOwner {
        require(newPlatformFeeInPercentFractions <= 1000, "Fee too large");
        platformFee = newPlatformFeeInPercentFractions;
    }
    
    /**
     * @dev Toggle whether creating new fundraisers is enabled. Existing fundraisers will go on regardless.
     */
    function toggleEnabled() external onlyOwner {
        isCreateEnabled = !isCreateEnabled;
    }

    // ======= Fundraiser config =======

    /**
     * @dev Returns whether a token has been whitelisted for a fundraiser
     */
    function isTokenWhitelistedForFundraiser(address token, uint256 index) public view returns (bool) {
        return tokenAndIndexToGoal[token][index] > 0;
    }

    /**
     * @dev Create a fundraiser
     */
    function createFundraiser(uint40 targetTimestamp, uint256 targetAmount, uint256 minContribution, string calldata name, string calldata description, address[] calldata tokenAddresses, uint256[] calldata tokenGoals) external {
        require(isCreateEnabled, "Creating fundraisers is disabled");
        require(targetTimestamp > block.timestamp, "Expiration must be in the future");
        require(targetTimestamp < block.timestamp + maxFundraiserDuration, "Expiration too late");
        require(targetAmount > 0, "Amount must be non-zero");
        require(minContribution <= targetAmount, "Minimum contribution must be lower than target amount");
        require(tokenAddresses.length == tokenGoals.length && tokenAddresses.length < 256, "Wrong lengths");

        emit Create(msg.sender, fundraisers.length, targetTimestamp, targetAmount, minContribution, name, description);
        fundraisers.push(FundraiserDetails(targetAmount, minContribution, 0, msg.sender, targetTimestamp, uint8(tokenAddresses.length), false, false));

        uint256 index = fundraisers.length - 1;
        for (uint256 i=0; i<tokenAddresses.length; i++) {
            require(tokenGoals[i] > 0, "Goal can't be 0");
            emit WhitelistToken(index, tokenAddresses[i], tokenGoals[i], ERC20(tokenAddresses[i]).symbol(), ERC20(tokenAddresses[i]).decimals());
            tokenAndIndexToGoal[tokenAddresses[i]][index] = tokenGoals[i];
        }
    }

    /**
     * @dev Kill fundraiser
     */
    function killFundraiser(uint256 index) external {
        require(msg.sender == fundraisers[index].admin || msg.sender == owner(), "Not authorized");
        require(!fundraisers[index].killed, "Fundraiser killed");

        emit Killed(index);
        fundraisers[index].killed = true;
    }

    // ======= Funding =======

    /**
     * @dev Fund fundraiser
     */
    function fundFundraiser(uint256 index) external payable {
        require(block.timestamp < fundraisers[index].targetTimestamp && !fundraisers[index].killed, "Fundraiser is closed");
        require(msg.value >= fundraisers[index].minContribution && msg.value > 0, "Amount too low");

        fundraisers[index].currentAmount += msg.value;
        addressAndIndexToAmountFunded[msg.sender][index] += msg.value;
        emit Donate(msg.sender, index, msg.value);
    }

    /**
     * @dev Fund fundraiser with whitelisted token
     */
    function fundFundraiserWithToken(uint256 index, uint256 amount, address token) external {
        require(block.timestamp < fundraisers[index].targetTimestamp && !fundraisers[index].killed, "Fundraiser is closed");
        require(isTokenWhitelistedForFundraiser(token, index), "Token not whitelisted");

        addressAndIndexToTokensFunded[msg.sender][index][token] += amount;
        tokenAndIndexToValue[token][index] += amount;
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit DonateToken(msg.sender, index, amount, token);
    }

    // ======= Funds collection =======

    /**
     * @dev Returns fundraiser's percentage to goal, including ether goal and all tokens
     */
    function getCombinedPercentage(uint256 index, address[] calldata tokenAddresses) public view returns (uint256) {
        require(tokenAddresses.length == fundraisers[index].noWhitelisted, "Invalid tokens");

        uint256 percentage;
        percentage += fundraisers[index].currentAmount * COMBINED_PERCENTAGE_PRECISION / fundraisers[index].targetAmount;

        for (uint256 i=0; i<tokenAddresses.length; i++) {
            require(isTokenWhitelistedForFundraiser(tokenAddresses[i], index), "Token not whitelisted");
            percentage += tokenAndIndexToValue[tokenAddresses[i]][index] * COMBINED_PERCENTAGE_PRECISION / tokenAndIndexToGoal[tokenAddresses[i]][index];
        }

        return percentage * 100 / COMBINED_PERCENTAGE_PRECISION;
    }

    /**
     * @dev Returns fee for fundraiser - either platform fee, or platform fee + holding fee if funds have not been collected after freeHoldingPeriod
     */
    function getFeeForFundraiser(uint256 index) public view returns (uint256) {
        if (block.timestamp > fundraisers[index].targetTimestamp && block.timestamp - fundraisers[index].targetTimestamp >= freeHoldingPeriod) {
            return platformFee + holdingFee;
        } else {
            return platformFee;
        }
    }

    /**
     * @dev Collect funds from a successful fundraiser
     */
    function collectFunds(uint256 index, address[] calldata tokenAddresses) external {
        require(msg.sender == fundraisers[index].admin, "Not owner of fundraiser");
        require(block.timestamp >= fundraisers[index].targetTimestamp, "Fundraiser still in progress");
        require(getCombinedPercentage(index, tokenAddresses) >= 100, "Fundraiser could not raise enough");
        require(!fundraisers[index].collected, "Already collected");

        fundraisers[index].collected = true;
        emit Collect(index);

        uint256 fee = getFeeForFundraiser(index);
        uint256 ownerAmount = fundraisers[index].currentAmount * fee / 10000;
        payable(owner()).transfer(ownerAmount);
        payable(fundraisers[index].admin).transfer(fundraisers[index].currentAmount - ownerAmount);
    }

    /**
     * @dev Collect tokens from a successful fundraiser
     */
    function collectTokens(uint256 index, address token, address[] calldata tokenAddresses) external {
        require(msg.sender == fundraisers[index].admin, "Not owner of fundraiser");
        require(block.timestamp >= fundraisers[index].targetTimestamp, "Fundraiser still in progress");
        require(getCombinedPercentage(index, tokenAddresses) >= 100, "Fundraiser could not raise enough");
        require(isTokenWhitelistedForFundraiser(token, index), "Token not whitelisted");
        require(!isTokenCollectedForFundraiser[token][index], "Already collected");

        isTokenCollectedForFundraiser[token][index] = true;
        emit CollectToken(index, token);

        uint256 fee = getFeeForFundraiser(index);
        uint256 ownerAmount = tokenAndIndexToValue[token][index] * fee / 10000;
        IERC20(token).transfer(owner(), ownerAmount);
        IERC20(token).transfer(msg.sender, tokenAndIndexToValue[token][index] - ownerAmount);
    }

    /**
     * @dev Refund contributors for a failed fundraiser
     */
    function refundFunds(address[] calldata contributors, uint256 index, address[] calldata tokenAddresses) external {
        if (block.timestamp >= fundraisers[index].targetTimestamp) {
            require(getCombinedPercentage(index, tokenAddresses) < 100, "Fundraiser did not fail");
        } else {
            require(fundraisers[index].killed, "Fundraiser still in progress and not killed");
        }

        uint256 totalOwnerAmount = 0;
        uint256 fee = getFeeForFundraiser(index);

        for (uint256 i=0; i<contributors.length; i++) {
            uint256 amount = addressAndIndexToAmountFunded[contributors[i]][index];
            if(amount > 0) {
                addressAndIndexToAmountFunded[contributors[i]][index] = 0;

                uint256 ownerAmount = amount * fee / 10000;
                totalOwnerAmount += ownerAmount;
                payable(contributors[i]).transfer(amount - ownerAmount);
                emit Refund(contributors[i], index);
            }
        }

        payable(owner()).transfer(totalOwnerAmount);
    }

    /**
     * @dev Refund token to contributors for a failed fundraiser
     */
    function refundFundsToken(address[] calldata contributors, uint256 index, address tokenAddress, address[] calldata tokenAddresses) external {
        require(isTokenWhitelistedForFundraiser(tokenAddress, index), "Token not whitelisted");

        if (block.timestamp >= fundraisers[index].targetTimestamp) {
            require(getCombinedPercentage(index, tokenAddresses) < 100, "Fundraiser did not fail");
        } else {
            require(fundraisers[index].killed, "Fundraiser still in progress and not killed");
        }

        uint256 totalOwnerAmount = 0;
        uint256 fee = getFeeForFundraiser(index);

        for (uint256 i=0; i<contributors.length; i++) {
            uint256 amount = addressAndIndexToTokensFunded[contributors[i]][index][tokenAddress];
            if(amount > 0) {
                addressAndIndexToTokensFunded[contributors[i]][index][tokenAddress] = 0;

                uint256 ownerAmount = amount * fee / 10000;
                totalOwnerAmount += ownerAmount;
                IERC20(tokenAddress).transfer(contributors[i], amount - ownerAmount);
                emit RefundToken(contributors[i], index, tokenAddress);
            }
        }

        IERC20(tokenAddress).transfer(owner(), totalOwnerAmount);
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