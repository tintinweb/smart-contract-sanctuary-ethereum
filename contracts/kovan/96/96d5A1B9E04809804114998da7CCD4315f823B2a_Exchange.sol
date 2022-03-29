// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "ERC20.sol";
import "Ownable.sol";
import "AggregatorV3Interface.sol";

contract Exchange is Ownable {
    //Zero address account for Ether
    address constant ETHER = address(0);
    address feeAccount;
    uint256 feePercentage;
    address token;
    uint256 public orderCounter = 0;
    address[] public stakers;
    address[] public allowedToken;

    // Model for Order
    struct _Order {
        uint256 id;
        address user;
        address tokenGet;
        uint256 amountGet;
        address tokenGive;
        uint256 amountGive;
        uint256 timestamp;
    }

    // Stakers model
    struct _stakeOrder {
        uint256 amount;
        uint256 timestamp;
    }

    //Mapping for how much token a individual has deposited
    mapping(address => mapping(address => uint256))
        public token_depositer_amount;
    mapping(uint256 => _Order) public id_to_order;
    mapping(uint256 => bool) public id_to_cancelOrder;
    mapping(uint256 => bool) public id_to_fillOrder;
    mapping(address => address) public tokenPriceFeedMapping;
    mapping(address => bool) public allowedToken_to_bool;
    mapping(address => uint256) public staker_uniqueTokenStaked;
    mapping(address => mapping(address => uint256)) public token_staker_amount;
    mapping(address => _stakeOrder) public stakerToStakingOrder;

    //Events
    event Deposited(address token, uint256 _amount, address depositer);
    event Withdraw(address withdrawer, address token, uint256 amount);
    event Order(_Order Order);
    event OrderCanceled(_Order Order);
    event OrderFilled(_Order Order);

    constructor(
        address _feeAccount,
        uint256 _feePercentage,
        address _token
    ) public {
        feeAccount = _feeAccount;
        feePercentage = _feePercentage;
        token = _token;
        allowedToken_to_bool[_token] = true;
        allowedToken_to_bool[ETHER] = true;
        allowedToken = [_token, ETHER];
    }

    // Deposit Token
    function depositToken(address _token, uint256 _amount) public {
        require(ERC20(_token).transferFrom(msg.sender, address(this), _amount));
        token_depositer_amount[_token][msg.sender] =
            token_depositer_amount[_token][msg.sender] +
            _amount;
        emit Deposited(_token, _amount, msg.sender);
    }

    // Deposite Ether
    function depositEther() public payable {
        token_depositer_amount[ETHER][msg.sender] =
            token_depositer_amount[ETHER][msg.sender] +
            msg.value;
        emit Deposited(ETHER, msg.value, msg.sender);
    }

    // Withdrawing ether
    function withdrawEther(uint256 _amount) public {
        require(token_depositer_amount[ETHER][msg.sender] >= _amount);
        address payable withdrawer = payable(msg.sender);
        withdrawer.transfer(_amount);
        token_depositer_amount[ETHER][msg.sender] =
            token_depositer_amount[ETHER][msg.sender] -
            _amount;
        emit Withdraw(withdrawer, ETHER, _amount);
    }

    function withdrawToken(address _token, uint256 _amount) public {
        require(_token != ETHER);
        require(token_depositer_amount[_token][msg.sender] >= _amount);
        require(ERC20(_token).transfer(msg.sender, _amount));
        token_depositer_amount[_token][msg.sender] =
            token_depositer_amount[_token][msg.sender] -
            _amount;
        emit Withdraw(msg.sender, _token, _amount);
    }

    function balanceOf(address _token, address _user)
        public
        view
        returns (uint256)
    {
        return token_depositer_amount[_token][_user];
    }

    // Make function for making orders
    function makeOrder(
        address _tokenGet,
        address _tokenGive,
        uint256 _amountGive
    ) public returns (uint256) {
        require(
            token_depositer_amount[_tokenGive][msg.sender] >= _amountGive,
            "You need to have balance in the exchange to make order."
        );
        (uint256 price, uint256 decimal) = getTokenValue(_tokenGive);
        //     // Here _amountGive should be in wei form --> 10 **18
        uint256 amountGet = _amountGive * (price / 10**decimal);
        orderCounter = orderCounter + 1;
        _Order memory order = _Order(
            orderCounter,
            msg.sender,
            _tokenGet,
            amountGet,
            _tokenGive,
            _amountGive,
            block.timestamp
        );
        id_to_order[orderCounter] = order;
        emit Order(order);
        return amountGet;
    }

    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), decimals);
    }

    // Setting the price feed address to the corresponding token
    function setTokenPriceFeedMapping(address _token, address _priceFeedAddress)
        public
        onlyOwner
    {
        tokenPriceFeedMapping[_token] = _priceFeedAddress;
    }

    function cancelOrder(uint256 _id) public {
        require(id_to_fillOrder[_id] != true);
        _Order storage order = id_to_order[_id];
        require(
            order.user == msg.sender,
            "You can not cancel someone else's order."
        );
        id_to_cancelOrder[_id] = true;
        emit OrderCanceled(order);
    }

    function fillOrder(uint256 _id) public {
        require(id_to_fillOrder[_id] != true, "The Order has already filled");
        require(
            id_to_cancelOrder[_id] != true,
            "The Order has been canceled by the order owner."
        );

        _Order storage order = id_to_order[_id];

        uint256 feeAmount = (order.amountGive * feePercentage) / 100;
        // Token Given
        // Here all the assest is in this contract so we don't need to transfer the assest any where
        // we can just update their mapping
        token_depositer_amount[order.tokenGive][order.user] =
            token_depositer_amount[order.tokenGive][order.user] -
            (order.amountGive + feeAmount);
        token_depositer_amount[order.tokenGive][msg.sender] =
            token_depositer_amount[order.tokenGive][msg.sender] +
            order.amountGive;

        // // Token Get
        token_depositer_amount[order.tokenGet][msg.sender] =
            token_depositer_amount[order.tokenGet][msg.sender] -
            order.amountGet;
        token_depositer_amount[order.tokenGet][order.user] =
            token_depositer_amount[order.tokenGet][order.user] +
            order.amountGet;

        // // FeeAmount to FeeAccount
        token_depositer_amount[order.tokenGive][feeAccount] = feeAmount;
        id_to_fillOrder[_id] = true;
        emit OrderFilled(order);
    }

    function stake(address _token, uint256 _amount) public {
        // Which token to stake
        // How much to stake
        uint256 depositBalance = balanceOf(_token, msg.sender);
        require(allowedToken_to_bool[_token], "This Token not allowed.");
        require(depositBalance >= _amount, "Need more.");

        if (staker_uniqueTokenStaked[msg.sender] != 0) {
            issueTokenAdvanced();
        }

        updateUniqueTokenStaked(msg.sender);
        uint256 feeAmount = (_amount * feePercentage) / 100;
        token_depositer_amount[_token][msg.sender] =
            token_depositer_amount[_token][msg.sender] -
            (_amount + feeAmount);
        token_staker_amount[_token][msg.sender] =
            token_staker_amount[_token][msg.sender] +
            _amount;
        token_depositer_amount[_token][feeAccount] = feeAmount;

        if (staker_uniqueTokenStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }

        stakerToStakingOrder[msg.sender] = _stakeOrder(
            token_staker_amount[_token][msg.sender],
            block.timestamp
        );
    }

    function updateUniqueTokenStaked(address user) internal {
        staker_uniqueTokenStaked[user] = staker_uniqueTokenStaked[user] + 1;
    }

    function addAllowedToken(address _token) public onlyOwner {
        allowedToken_to_bool[_token] = true;
        allowedToken.push(_token);
    }

    function unstakeTokens(address _token) public {
        uint256 balance = token_staker_amount[_token][msg.sender];

        require(balance > 0, "You don't have Tokens to unstake.");

        issueTokenAdvanced();
        staker_uniqueTokenStaked[msg.sender] =
            staker_uniqueTokenStaked[msg.sender] -
            1;
        token_staker_amount[_token][msg.sender] = 0;
        token_depositer_amount[_token][msg.sender] =
            token_depositer_amount[_token][msg.sender] +
            balance;
        if (staker_uniqueTokenStaked[msg.sender] == 0) {
            for (
                uint256 stakersIndex = 0;
                stakersIndex < stakers.length;
                stakersIndex++
            ) {
                if (stakers[stakersIndex] == msg.sender) {
                    stakers[stakersIndex] = stakers[stakers.length - 1];
                    stakers.pop();
                }
            }
        }
        stakerToStakingOrder[msg.sender] = _stakeOrder(0, 0);
    }

    // Update this as such --> That user can claim there reward according to the timeStamp
    function issueToken() public onlyOwner {
        // issue a reward to all the staker according to the amount they have staked

        for (
            uint256 stakersIndex = 0;
            stakersIndex < stakers.length;
            stakersIndex++
        ) {
            address staker = stakers[stakersIndex];
            uint256 reward = (getStakerTotalValue(staker) * feePercentage) /
                100;

            token_depositer_amount[token][feeAccount] =
                token_depositer_amount[token][feeAccount] -
                reward;

            token_depositer_amount[token][staker] =
                token_depositer_amount[token][staker] +
                reward;
        }
    }

    function getStakerTotalValue(address _staker)
        public
        view
        returns (uint256)
    {
        uint256 totalValue = 0;
        require(
            staker_uniqueTokenStaked[_staker] > 0,
            "User don't have any value staked."
        );
        for (
            uint256 allowedTokenIndex = 0;
            allowedTokenIndex < allowedToken.length;
            allowedTokenIndex++
        ) {
            if (
                token_staker_amount[allowedToken[allowedTokenIndex]][_staker] >
                0
            ) {
                totalValue =
                    totalValue +
                    getStakersSingleTokenValue(
                        _staker,
                        allowedToken[allowedTokenIndex]
                    );
            }
        }
        return totalValue;
    }

    function getStakersSingleTokenValue(address _staker, address _token)
        public
        view
        returns (uint256)
    {
        require(
            staker_uniqueTokenStaked[_staker] > 0,
            "User don't have any value staked."
        );

        (uint256 price, uint256 decimals) = getTokenValue(_token);
        return ((token_staker_amount[_token][_staker] * price) /
            (10**decimals));
    }

    function issueTokenAdvanced() public returns (uint256) {
        require(
            staker_uniqueTokenStaked[msg.sender] > 0,
            "You don't have any token staked yet!"
        );
        _stakeOrder storage stakeOrder = stakerToStakingOrder[msg.sender];
        require(stakeOrder.amount > 0, "Not enough resources.");

        uint256 reward = (stakeOrder.amount / 100000000000000) *
            (block.timestamp - stakeOrder.timestamp);

        token_depositer_amount[token][feeAccount] =
            token_depositer_amount[token][feeAccount] -
            reward;

        token_depositer_amount[token][msg.sender] =
            token_depositer_amount[token][msg.sender] +
            reward;

        stakerToStakingOrder[msg.sender] = _stakeOrder(
            stakeOrder.amount,
            block.timestamp
        );
        return reward;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}