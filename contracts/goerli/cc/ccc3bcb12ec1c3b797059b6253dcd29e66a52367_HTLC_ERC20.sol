/**
 *Submitted for verification at Etherscan.io on 2023-01-26
*/

/**
 *Submitted for verification at Etherscan.io on 2022-08-16
 */

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.10;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

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
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
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
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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

// File: contracts/Erc20Htlc.sol

/**
 * @title Hash Time Lock Contract (HTLC) ERC20
 *
 * @author Meheret Tesfaye Batu <[email protected]>
 *
 * HTLC -> A Hash Time Lock Contract is essentially a type of payment in which two people
 * agree to a financial arrangement where one party will pay the other party a certain amount
 * of cryptocurrencies, such as Bitcoin or Ethereum assets.
 * However, because these contracts are Time-Locked, the receiving party only has a certain
 * amount of time to accept the payment, otherwise the money can be returned to the sender.
 *
 * Hash-Locked -> A Hash locked functions like “two-factor authentication” (2FA). It requires
 * the intended recipient to provide the correct secret passphrase to withdraw the funds.
 *
 * Time-Locked -> A Time locked adds a “timeout” expiration date to a payment. It requires
 * the intended recipient to claim the funds prior to the expiry. Otherwise, the transaction
 * defaults to enabling the original sender of funds to withdraw a refund.
 */
contract HTLC_ERC20 {
    struct LockContract {
        address token;
        bytes32 secret_hash;
        address recipient;
        address sender;
        uint256 endtime;
        uint256 amount;
        bool withdrawn;
        bool refunded;
        string preimage;
    }

    mapping(bytes32 => LockContract) public locked_contracts;

    event log_fund(
        bytes32 indexed locked_contract_id,
        address token,
        bytes32 secret_hash,
        address indexed recipient,
        address indexed sender,
        uint256 endtime,
        uint256 amount
    );
    event log_withdraw(bytes32 indexed locked_contract_id);
    event log_refund(bytes32 indexed locked_contract_id);

    modifier is_token_transferable(
        address token,
        address,
        uint256 amount
    ) {
        require(amount > 0, "token amount must be > 0");
        require(
            ERC20(token).allowance(msg.sender, address(this)) >= amount,
            "token allowance must be >= amount"
        );
        _;
    }
    modifier future_endtime(uint256 endtime) {
        require(
            block.timestamp < endtime,
            "endtime time must be in the future"
        );
        _;
    }
    modifier is_locked_contract_exist(bytes32 locked_contract_id) {
        require(
            have_locked_contract(locked_contract_id),
            "locked_contract_id does not exist"
        );
        _;
    }
    modifier check_secret_hash_matches(
        bytes32 locked_contract_id,
        string memory preimage
    ) {
        require(
            locked_contracts[locked_contract_id].secret_hash ==
                sha256(abi.encodePacked(preimage)),
            "secret hash hash does not match"
        );
        _;
    }
    modifier withdrawable(bytes32 locked_contract_id) {
        require(
            locked_contracts[locked_contract_id].recipient == msg.sender,
            "withdrawable: not recipient"
        );
        require(
            locked_contracts[locked_contract_id].withdrawn == false,
            "withdrawable: already withdrawn"
        );
        require(
            locked_contracts[locked_contract_id].refunded == false,
            "withdrawable: already refunded"
        );
        _;
    }
    modifier refundable(bytes32 locked_contract_id) {
        require(
            locked_contracts[locked_contract_id].sender == msg.sender,
            "refundable: not sender"
        );
        require(
            locked_contracts[locked_contract_id].refunded == false,
            "refundable: already refunded"
        );
        require(
            locked_contracts[locked_contract_id].withdrawn == false,
            "refundable: already withdrawn"
        );
        _;
    }

    /**
     * @dev Sender sets up a new Hash Time Lock Contract (HTLC) and depositing the ERC20 token.
     *
     * @param token ERC20 Token contract address.
     * @param secret_hash A sha256 secret hash.
     * @param recipient Recipient account of the ERC20 token.
     * @param sender Sender account of the ERC20 token.
     * @param endtime The timestamp that the lock expires at.
     * @param amount Amount of the token to lock up.
     *
     * @return locked_contract_id of the new HTLC.
     */
    function fund(
        address token,
        bytes32 secret_hash,
        address recipient,
        address sender,
        uint256 endtime,
        uint256 amount
    )
        external
        is_token_transferable(token, msg.sender, amount)
        future_endtime(endtime)
        returns (bytes32 locked_contract_id)
    {
        locked_contract_id = sha256(
            abi.encodePacked(
                token,
                secret_hash,
                recipient,
                sender,
                endtime,
                amount
            )
        );

        if (have_locked_contract(locked_contract_id))
            revert("this locked contract already exists");

        if (!ERC20(token).transferFrom(msg.sender, address(this), amount))
            revert("transferFrom sender to this failed");

        locked_contracts[locked_contract_id] = LockContract(
            token,
            secret_hash,
            recipient,
            sender,
            endtime,
            amount,
            false,
            false,
            ""
        );

        emit log_fund(
            locked_contract_id,
            token,
            secret_hash,
            recipient,
            sender,
            endtime,
            amount
        );
        return locked_contract_id;
    }

    /**
     * @dev Called by the recipient once they know the preimage (secret key) of the secret hash.
     *
     * @param locked_contract_id of HTLC to withdraw.
     * @param preimage sha256(preimage) hash should equal the contract secret hash.
     *
     * @return bool true on success or false on failure.
     */
    function withdraw(bytes32 locked_contract_id, string memory preimage)
        external
        is_locked_contract_exist(locked_contract_id)
        check_secret_hash_matches(locked_contract_id, preimage)
        withdrawable(locked_contract_id)
        returns (bool)
    {
        LockContract storage locked_contract = locked_contracts[
            locked_contract_id
        ];

        locked_contract.preimage = preimage;
        locked_contract.withdrawn = true;
        require(
            ERC20(locked_contract.token).transfer(
                locked_contract.recipient,
                locked_contract.amount
            )
        );

        emit log_withdraw(locked_contract_id);
        return true;
    }

    /**
     * @dev Called by the sender if there was no withdraw and the time lock has expired.
     *
     * @param locked_contract_id of HTLC to refund.
     *
     * @return bool true on success or false on failure.
     */
    function refund(bytes32 locked_contract_id)
        external
        is_locked_contract_exist(locked_contract_id)
        refundable(locked_contract_id)
        returns (bool)
    {
        LockContract storage locked_contract = locked_contracts[
            locked_contract_id
        ];

        locked_contract.refunded = true;
        require(
            ERC20(locked_contract.token).transfer(
                locked_contract.sender,
                locked_contract.amount
            )
        );

        emit log_refund(locked_contract_id);
        return true;
    }

    /**
     * @dev Is there a locked contract with HTLC contract id.
     *
     * @param locked_contract_id of HTLC to find it exists.
     *
     * @return exists boolean true or false.
     */
    function have_locked_contract(bytes32 locked_contract_id)
        internal
        view
        returns (bool exists)
    {
        exists = (locked_contracts[locked_contract_id].amount != 0);
    }
}