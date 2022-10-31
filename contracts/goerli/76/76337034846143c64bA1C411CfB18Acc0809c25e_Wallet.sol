// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./testUSDC.sol";
import "./Exchange.sol";

/// @notice Library SafeMath used to prevent overflows and underflows
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Wallet is Ownable {
    using SafeMath for uint256; //for prevention of integer overflow

    address public immutable Owner;

    //For prevention of reentrancy
    bool private locked;

    address public ethToken = address(0);

    Exchange tokens;

    IERC20 token;

    event Deposit(address token, address user, uint256 amount, uint256 balance);

    /// @notice Event when amount withdrawn exchange
    event Withdraw(
        address token,
        address user,
        uint256 amount,
        uint256 balance
    );

    constructor(address _ExchangeAdd) {
        tokens = Exchange(_ExchangeAdd);
        Owner = msg.sender;
    }

    function depositETH() external payable {
        tokens.updateBalance(ethToken, msg.sender, msg.value, true);

        emit Deposit(
            ethToken,
            msg.sender,
            msg.value,
            tokens.balanceOf(ethToken, msg.sender)
        );
    }

    function withdrawETH(uint256 _amount) external {
        require(
            tokens.balanceOf(ethToken, msg.sender) -
                tokens.getlockedFunds(msg.sender, ethToken) >=
                _amount,
            "Insufficient balance ETH to withdraw"
        );
        require(!locked, "Reentrant call detected!");
        locked = true;
        tokens.updateBalance(ethToken, msg.sender, _amount, false);
        locked = false;
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "failed to send amount");

        emit Withdraw(
            ethToken,
            msg.sender,
            _amount,
            tokens.balanceOf(ethToken, msg.sender)
        );
    }

    //from and transferFrom is from ERC20 contract
    //_token should be an ERC20 token
    function depositToken(address _token, uint256 _amount) external {
        require(_token != ethToken);
        require(
            tokens.isVerifiedToken(_token),
            "Token not verified on Exchange"
        );
        //need to add a check to prove that it is an ERC20 token
        token = IERC20(_token);

        //Requires approval first
        require(token.transferFrom(msg.sender, address(this), _amount));

        if (_token == tokens.usdc())
            tokens.updateBalance(_token, msg.sender, _amount.mul(10**12), true);
        else tokens.updateBalance(_token, msg.sender, _amount, true);

        emit Deposit(
            _token,
            msg.sender,
            _amount,
            tokens.balanceOf(_token, msg.sender)
        );
    }

    function withdrawToken(address _token, uint256 _amount) external {
        require(_token != ethToken);
        require(
            tokens.isVerifiedToken(_token),
            "Token not verified on Exchange"
        );

        require(
            tokens.balanceOf(_token, msg.sender) -
                tokens.getlockedFunds(msg.sender, _token) >=
                _amount,
            "Insufficient Tokens to withdraw"
        );
        require(!locked, "Reentrant call detected!");
        locked = true;

        tokens.updateBalance(_token, msg.sender, _amount, false);

        token = IERC20(_token);

        if (_token == tokens.usdc())
            require(token.transfer(msg.sender, _amount.div(10**12)));
        else require(token.transfer(msg.sender, _amount));

        locked = false;
        emit Withdraw(
            _token,
            msg.sender,
            _amount,
            tokens.balanceOf(_token, msg.sender)
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
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
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
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
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
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

/* ERC 20 constructor takes in 2 strings, feel free to change the first string to the name of your token name, and the second string to the corresponding symbol for your custom token name */
// SPDX-License-Identifier: MIT
import "./ERC20.sol";

pragma solidity ^0.8.0;

contract testUSDC is ERC20 {
    constructor(uint256 _initial_supply) ERC20("testUSDC", "tUSDC") {
        _mint(msg.sender, _initial_supply);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./testUSDC.sol";
import "./Wallet.sol";
//import "./MathMul.sol";

/// @notice Library SafeMath used to prevent overflows and underflows
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Exchange is Ownable {
    using SafeMath for uint256; //for prevention of integer overflow
    //using MathMul for uint256;

    address public immutable Owner;
    address public usdc;
    address public ethToken = address(0);
    uint256 decimals = 10**18;

    //Token Address List available in DEX
    address[] public tokenList;

    //s_orderBook mappping: tokenAddress -> Side -> Order Array
    mapping(address => mapping(uint256 => _Order[])) public s_orderBook;

    //Balance in DEX
    mapping(address => mapping(address => uint256)) public s_tokens; //tokenAdress -> msg.sender -> tokenAmt

    //Locked value in orders in DEX  user->Token->lockedAmount
    mapping(address => mapping(address => uint256)) public lockedFunds;

    mapping(address => _Order[]) public s_filledOrders;

    uint256 public s_orderId = 0;
    bool private s_isManual = true;

    //Structs representing an order has unique id, user and amounts to give and get between two s_tokens to exchange
    struct _Order {
        uint256 id;
        address user;
        address token;
        uint256 amount;
        uint256 price; //in usdc
        Side side;
    }

    enum Side {
        BUY,
        SELL
    }

    //add events
    /// @notice Event when an order is placed on an exchange
    event Order(
        uint256 id,
        address user,
        address token,
        uint256 amount,
        uint256 price,
        Side side
    );

    /// @notice Event when an order is cancelled
    event Cancel(
        uint256 id,
        address user,
        address token,
        uint256 amount,
        uint256 price
    );

    event Fill(
        uint256 id,
        address user,
        address token,
        uint256 amount,
        uint256 price
    );

    constructor(address _usdc) {
        usdc = _usdc;
        addToken(usdc);
        addToken(ethToken);

        Owner = msg.sender;
    }

    //For Buyer, when making buy order they deposit usdc and receive token of choice
    //For seller, when making sell order, they deposit token of choice and receive usdc
    function createLimitBuyOrder(
        address _token,
        uint256 _amount,
        uint256 _price //in usdc/token
    ) external {
        //Token must be approved in DEX
        require(isVerifiedToken(_token), "Token unavailable in DEX");

        //Our Exchange does not allow buying of USDC
        require(_token != usdc, "Unable to purchase USDC");

        uint256 totalValue = (_amount.mul(_price)).div(decimals);

        //Amount user has deposited in the DEX must be >= value he wants to buy
        require(
            balanceOf(usdc, msg.sender).sub(getlockedFunds(msg.sender, usdc)) >=
                totalValue,
            "Insufficient USDC"
        );

        //Lock the funds (USDC) in the wallet by removing balance in DEX
        updateLockedFunds(msg.sender, usdc, totalValue, true);

        s_orderBook[_token][uint256(Side.BUY)].push(
            _Order(s_orderId, msg.sender, _token, _amount, _price, Side.BUY)
        );

        emit Order(s_orderId, msg.sender, _token, _amount, _price, Side.BUY);

        s_orderId = s_orderId.add(1);
    }

    function createLimitSellOrder(
        address _token,
        uint256 _amount,
        uint256 _price //in usdc/token
    ) external {
        //Token must be approved in DEX
        require(isVerifiedToken(_token), "Token unavailable in DEX");

        //Our Exchange does not allow buying of USDC
        require(_token != usdc, "Unable to sell USDC");

        //Amount of tokens user deposit in DEX must be >= the amount of tokens they want to sell
        require(
            balanceOf(_token, msg.sender) -
                getlockedFunds(msg.sender, _token) >=
                _amount,
            "Insufficient tokens"
        );

        //Lock the funds (tokens) in the wallet
        updateLockedFunds(msg.sender, _token, _amount, true);

        s_orderBook[_token][uint256(Side.SELL)].push(
            _Order(s_orderId, msg.sender, _token, _amount, _price, Side.SELL)
        );

        emit Order(s_orderId, msg.sender, _token, _amount, _price, Side.SELL);

        s_orderId = s_orderId.add(1);
    }

    function cancelOrder(
        Side side,
        uint256 _id,
        address _token
    ) public {
        require(_id >= 0 && _id <= s_orderId, "Invalid Order ID");
        require(isVerifiedToken(_token), "Token unavailable in DEX");

        _Order[] storage _order = s_orderBook[_token][uint256(side)];
        uint256 size = _order.length;
        _Order memory order;

        uint256 index;
        for (uint256 i = 0; i < size; i++) {
            if (_order[i].id == _id) {
                index = i;
                order = _order[i];
                break;
            }
        }

        //Manual cancellation of orders
        if (s_isManual) {
            require(msg.sender == order.user, "Not Order Owner");

            //Unlock funds
            if (side == Side.BUY) {
                updateLockedFunds(
                    msg.sender,
                    usdc,
                    (order.price.mul(order.amount)).div(decimals),
                    false
                );
            } else if (side == Side.SELL) {
                updateLockedFunds(msg.sender, _token, order.amount, false);
            }
        }

        for (uint256 j = index; j < size - 1; j++) {
            _order[j] = _order[j + 1];
        }
        delete _order[size - 1];
        _order.pop();

        s_orderBook[_token][uint256(side)] = _order;

        emit Cancel(order.id, msg.sender, _token, order.amount, order.price);
    }

    function fillOrder(
        Side side,
        uint256 _id,
        address _token,
        uint256 _amount,
        uint256 _price
    ) public {
        require(_id >= 0 && _id <= s_orderId);
        _Order[] memory _order = s_orderBook[_token][uint256(side)];
        _Order memory order;

        order = getOrderFromArray(_order, _id);

        require(order.amount >= _amount);

        order.amount = order.amount.sub(_amount);

        if (side == Side.BUY) {
            updateLockedFunds(
                order.user,
                usdc,
                (order.price.mul(_amount)).div(decimals),
                false
            );
        } else if (side == Side.SELL) {
            updateLockedFunds(order.user, _token, _amount, false);
        }

        emit Fill(_id, order.user, _token, _amount, _price);

        if (order.amount == 0) {
            s_filledOrders[order.user].push(order);
            s_isManual = false;
            cancelOrder(side, order.id, order.token); //remove filled orders
            s_isManual = true;
        }
    }

    function matchOrders(
        address _token,
        uint256 _id,
        Side side
    ) external {
        //when order is filled,
        //BUY Side => deduct USDC from balance, sent token to balance, order updated.
        //SELL Side =>deduct token from balance, sent USDC from DEX, order updated.
        uint256 saleTokenAmt;
        //Token must be approved in DEX
        require(isVerifiedToken(_token), "Token unavailable in DEX");
        require(_id >= 0 && _id <= s_orderId);

        if (side == Side.BUY) {
            //Retrieve buy order to be filled
            _Order[] memory _order = s_orderBook[_token][0];
            _Order memory buyOrderToFill = getOrderFromArray(_order, _id);

            //Retrieve sell order to match
            _Order[] memory _sellOrder = s_orderBook[_token][1];
            for (uint256 i = 0; i < _sellOrder.length; i++) {
                //sell order hit buyer's limit price
                if (_sellOrder[i].price <= buyOrderToFill.price) {
                    _Order memory sellOrder = _sellOrder[i];
                    //if buyer's amount to buy > seller's amount to sell
                    if (buyOrderToFill.amount > sellOrder.amount) {
                        saleTokenAmt = sellOrder.amount;
                    }
                    //if seller's amount to sell >= buyer's amount to buy
                    else if (buyOrderToFill.amount <= sellOrder.amount) {
                        saleTokenAmt = buyOrderToFill.amount;
                    }

                    //Verify current balance
                    require(
                        balanceOf(usdc, buyOrderToFill.user) >=
                            (saleTokenAmt.mul(sellOrder.price)).div(decimals),
                        "Insufficient buyer USDC Balance"
                    );
                    require(
                        balanceOf(_token, sellOrder.user) >= saleTokenAmt,
                        "Insufficient seller Token Balance"
                    );

                    //update orders
                    fillOrder(
                        Side.BUY,
                        _id,
                        _token,
                        saleTokenAmt,
                        sellOrder.price
                    );
                    fillOrder(
                        Side.SELL,
                        sellOrder.id,
                        _token,
                        saleTokenAmt,
                        sellOrder.price
                    );

                    //buyer update
                    updateBalance(
                        _token,
                        buyOrderToFill.user,
                        saleTokenAmt,
                        true
                    );
                    updateBalance(
                        usdc,
                        buyOrderToFill.user,
                        (sellOrder.price.mul(saleTokenAmt)).div(decimals),
                        false
                    );

                    //seller update
                    updateBalance(_token, sellOrder.user, saleTokenAmt, false);
                    updateBalance(
                        usdc,
                        sellOrder.user,
                        (sellOrder.price.mul(saleTokenAmt)).div(decimals),
                        true
                    );
                }

                if (buyOrderToFill.amount == 0) break;
            }
        } else if (side == Side.SELL) {
            //Retrieve sell order to be filled
            _Order[] memory _order = s_orderBook[_token][1];
            _Order memory sellOrderToFill = getOrderFromArray(_order, _id);

            //Retrieve buy order to match
            _Order[] memory _buyOrder = s_orderBook[_token][0];
            for (uint256 i = 0; i < _buyOrder.length; i++) {
                //sell order hit buyer's limit price
                if (_buyOrder[i].price >= sellOrderToFill.price) {
                    _Order memory order = _buyOrder[i];

                    //if seller's amount to sell > buyer's amount to buy
                    if (sellOrderToFill.amount > order.amount) {
                        saleTokenAmt = order.amount;
                    }
                    //if buyer's amount to buy > seller's amount to sell
                    else if (sellOrderToFill.amount <= order.amount) {
                        saleTokenAmt = sellOrderToFill.amount;
                    }

                    //Verify current balance
                    require(
                        balanceOf(_token, sellOrderToFill.user) >= saleTokenAmt,
                        "Insufficient seller Token Balance"
                    );
                    require(
                        balanceOf(usdc, order.user) >=
                            (saleTokenAmt.mul(order.price)).div(decimals),
                        "Insufficient buyer USDC Balance"
                    );

                    //update orders
                    fillOrder(
                        Side.SELL,
                        _id,
                        _token,
                        saleTokenAmt,
                        order.price
                    );
                    fillOrder(
                        Side.BUY,
                        order.id,
                        _token,
                        saleTokenAmt,
                        order.price
                    );

                    //seller update
                    updateBalance(
                        _token,
                        sellOrderToFill.user,
                        saleTokenAmt,
                        false
                    );
                    updateBalance(
                        usdc,
                        sellOrderToFill.user,
                        (order.price.mul(saleTokenAmt)).div(decimals),
                        true
                    );

                    //buyer update
                    updateBalance(_token, order.user, saleTokenAmt, true);
                    updateBalance(
                        usdc,
                        order.user,
                        (order.price.mul(saleTokenAmt)).div(decimals),
                        false
                    );
                }

                if (sellOrderToFill.amount == 0) break;
            }
        }
    }

    function getOrderLength(Side side, address _token)
        public
        view
        returns (uint256)
    {
        return s_orderBook[_token][uint256(side)].length;
    }

    function getOrder(
        address _token,
        uint256 index,
        Side side
    )
        public
        view
        returns (
            uint256,
            uint256,
            address,
            uint256,
            uint256
        )
    {
        _Order memory order = s_orderBook[_token][uint256(side)][index];
        return (
            order.id,
            order.amount,
            order.user,
            order.price,
            uint256(order.side)
        );
    }

    function getFilledOrderLength(address _user) public view returns (uint256) {
        return s_filledOrders[_user].length;
    }

    function getFilledOrder(address _user, uint256 index)
        public
        view
        returns (
            uint256,
            uint256,
            address,
            uint256,
            uint256
        )
    {
        _Order memory filledOrder = s_filledOrders[_user][index];
        return (
            filledOrder.id,
            filledOrder.amount,
            filledOrder.user,
            filledOrder.price,
            uint256(filledOrder.side)
        );
    }

    function getOrderFromArray(_Order[] memory _order, uint256 _id)
        public
        pure
        returns (_Order memory)
    {
        _Order memory order;
        for (uint256 i = 0; i < _order.length; i++) {
            if (_order[i].id == _id) {
                order = _order[i];
                break;
            }
        }
        return order;
    }

    //Only for Unit Testing in Local Blockchain
    function orderExists(
        uint256 _id,
        Side side,
        address _token
    ) public view returns (bool) {
        _Order[] memory orders = s_orderBook[_token][uint256(side)];

        for (uint256 i = 0; i < orders.length; i++) {
            if (orders[i].id == _id) {
                return true;
            }
        }
        return false;
    }

    function getlockedFunds(address _user, address _token)
        public
        view
        returns (uint256)
    {
        return lockedFunds[_user][_token];
    }

    function updateLockedFunds(
        address _user,
        address _token,
        uint256 _amount,
        bool isAdd
    ) public {
        if (isAdd) {
            lockedFunds[_user][_token] = lockedFunds[_user][_token].add(
                _amount
            );
        } else if (!isAdd) {
            lockedFunds[_user][_token] = lockedFunds[_user][_token].sub(
                _amount
            );
        }
    }

    //balance of specific tokens in the dex owned by specific user
    function balanceOf(address _token, address _user)
        public
        view
        returns (uint256)
    {
        return s_tokens[_token][_user];
    }

    function updateBalance(
        address _token,
        address _user,
        uint256 _amount,
        bool isAdd
    ) public {
        if (isAdd) {
            s_tokens[_token][_user] = s_tokens[_token][_user].add(_amount);
        } else if (!isAdd) {
            s_tokens[_token][_user] = s_tokens[_token][_user].sub(_amount);
        }
    }

    function addToken(address _token) public onlyOwner {
        address[] memory tokens = tokenList;
        bool isAdded = false;
        //Cannot be repeated
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == _token) {
                isAdded = true;
                break;
            }
        }
        require(isAdded == false, "Token already verified on DEX!");

        tokenList.push(_token);
    }

    function isVerifiedToken(address _token) public view returns (bool) {
        uint256 size = tokenList.length;

        for (uint256 i = 0; i < size; i++) {
            if (tokenList[i] == _token) return true;
        }
        return false;
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
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