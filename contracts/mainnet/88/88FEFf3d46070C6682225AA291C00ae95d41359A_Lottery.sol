// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Lottery {
    ERC20Burnable public ERC20Token;

    uint256 public pool;
    uint256 public fees;
    uint256 public ticket_cost;
    uint256 public last_drawn;
    uint256 public fee_basis_points = 500;
    uint256 public total_basis_points = 10000;

    address s_owner;
    address g_owner;
    address[] public players;
    address[] public winners;
    address[] public bonusPoolTokens;

    bool public lotteryStarted;

    mapping(address => uint256) public bonusPool;
    mapping(address => mapping(address => uint256)) public claimableRewards;

    constructor(address tokenAddress, address giver) {
        s_owner = msg.sender;
        g_owner = giver;
        ERC20Token = ERC20Burnable(tokenAddress);
        pool = 0;
        fees = 0;
        ticket_cost = 10 ether;
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner, "Caller is not the owner");
        _;
    }

    modifier onlyGiver() {
        require(msg.sender == g_owner, "Caller is not the giver");
        _;
    }

    modifier hasLotteryStarted() {
        require(lotteryStarted, "Lottery has not yet started");
        _;
    }

    modifier notZeroPlayers() {
        require(players.length != 0, "No one in the lottery");
        _;
    }

    function updateTicketCost(uint256 newTicketCost) external onlyOwner {
        ticket_cost = newTicketCost;
    }

    function updateFeeBasisPoints(uint256 _fee_basis_points)
        external
        onlyOwner
    {
        fee_basis_points = _fee_basis_points;
    }

    function updateTotalBasisPoints(uint256 _total_basis_points)
        external
        onlyOwner
    {
        total_basis_points = _total_basis_points;
    }

    function giveTickets(address wallet, uint256 amount) external onlyGiver {
        for (uint256 i = 0; i < amount; i++) {
            players.push(wallet);
        }
    }

    function addBonusTokens(address tokenAddress, uint256 amount)
        external
        payable
        onlyOwner
    {
        bool alreadyIn = false;
        for (uint256 i = 0; i < bonusPoolTokens.length; i++) {
            if (tokenAddress == bonusPoolTokens[i]) {
                alreadyIn = true;
            }
        }
        if (!alreadyIn) {
            bonusPoolTokens.push(tokenAddress);
        }

        if (tokenAddress == address(0)) {
            require(
                amount == msg.value,
                "provided amount does not match native tokens sent"
            );
            bonusPool[tokenAddress] += amount;
        } else {
            bonusPool[tokenAddress] += amount;
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                address(this),
                amount
            );
        }
    }

    function removeBonusToken(address tokenAddress) external onlyOwner {
        uint256 bonusTokensLength = bonusPoolTokens.length;
        require(
            bonusTokensLength != 0,
            "no bonus token to remove from lottery"
        );
        // require(bonusTokensLength != 0, "No bonus tokens in lottery");
        uint256 currentBonusTokenAmount = bonusPool[tokenAddress];
        uint256 poolIndex = 0;
        // Find index of token in array of bonus tokens
        while (
            poolIndex < bonusTokensLength &&
            bonusPoolTokens[poolIndex] != tokenAddress
        ) {
            if (poolIndex == bonusTokensLength - 1) break;
            poolIndex++;
        }

        // Guard if token not found

        require(
            bonusPoolTokens[poolIndex] == tokenAddress,
            "Token is not in bonus pool"
        );

        // Remove the token from the array and reset amount

        while (poolIndex < bonusTokensLength - 1) {
            bonusPoolTokens[poolIndex] = bonusPoolTokens[poolIndex + 1];
            poolIndex++;
        }
        bonusPoolTokens.pop();
        bonusPool[tokenAddress] = 0;

        // send current funds of token to owner
        if (tokenAddress == address(0)) {
            payable(msg.sender).transfer(currentBonusTokenAmount);
        } else {
            IERC20(tokenAddress).transfer(msg.sender, currentBonusTokenAmount);
        }
    }

    function startNextLottery() external onlyOwner {
        lotteryStarted = true;
    }

    function stopLottery() external onlyOwner {
        lotteryStarted = false;
    }

    function getWinners() external view returns (address[] memory) {
        return winners;
    }

    function getPlayers() external view returns (address[] memory) {
        return players;
    }

    function getBonusPoolTokens() external view returns (address[] memory) {
        return bonusPoolTokens;
    }

    function enter(uint256 numTickets) public hasLotteryStarted {
        ERC20Token.transferFrom(
            msg.sender,
            address(this),
            ticket_cost * numTickets
        );
        uint256 poolRatio = (ticket_cost) / 2;
        ERC20Token.burn(poolRatio * numTickets);
        uint256 poolShare = ((total_basis_points - fee_basis_points) *
            poolRatio) / total_basis_points;
        pool = pool + (poolShare * numTickets);
        fees = fees + ((poolRatio - poolShare) * numTickets);
        for (uint256 index = 0; index < numTickets; index++) {
            players.push(msg.sender);
        }
    }

    function pickWinner(uint256[] calldata randomNumbers)
        external
        onlyOwner
        notZeroPlayers
    {
        winners = new address[](0);

        // pick winners
        uint256 numPlayers = players.length;
        // indexes expected to be at most length of 3
        for (uint256 i = 0; i < randomNumbers.length && i < numPlayers; i++) {
            uint256 pickedWinnerIndex = randomNumbers[i] % players.length;
            winners.push(players[pickedWinnerIndex]);
        }
        uint256 winningAmount = pool / winners.length;

        // Record base prize
        for (uint256 i = 0; i < winners.length; i++) {
            claimableRewards[winners[i]][address(ERC20Token)] =
                claimableRewards[winners[i]][address(ERC20Token)] +
                winningAmount;
        }
        // Record bonus prize
        for (uint256 i = 0; i < bonusPoolTokens.length; i++) {
            address bonusToken = bonusPoolTokens[i];
            uint256 bonusTokenAmount = bonusPool[bonusToken] / winners.length;
            bonusPool[bonusToken] = 0;
            // winners.length expected to at most be 3
            for (uint256 i = 0; i < winners.length; i++) {
                claimableRewards[winners[i]][bonusToken] =
                    claimableRewards[winners[i]][bonusToken] +
                    bonusTokenAmount;
            }
        }
        // Reset info
        pool = 0;
        players = new address[](0);
        last_drawn = block.timestamp;
        lotteryStarted = false;
    }

    function claimRewards(address[] calldata tokenAddresses) external {
        uint256 basePrize = claimableRewards[msg.sender][address(ERC20Token)];
        claimableRewards[msg.sender][address(ERC20Token)] = 0;
        ERC20Token.transfer(msg.sender, basePrize);
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            uint256 tokenAmount = claimableRewards[msg.sender][
                tokenAddresses[i]
            ];
            claimableRewards[msg.sender][tokenAddresses[i]] = 0;
            // native token
            if (tokenAddresses[i] == address(0)) {
                payable(msg.sender).transfer(tokenAmount);
            } else {
                // erc20s
                IERC20(tokenAddresses[i]).transfer(msg.sender, tokenAmount);
            }
        }
    }

    function withdrawFees() external onlyOwner {
        ERC20Token.transfer(msg.sender, fees);
        fees = 0;
    }

    function withdrawRemaining(address tokenAddress, uint256 amount)
        external
        onlyOwner
    {
        require(
            IERC20(tokenAddress).balanceOf(address(this)) >= amount,
            "Invalid amount requested to be withdrawn"
        );
        if (tokenAddress == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            IERC20(tokenAddress).transfer(msg.sender, amount);
        }
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