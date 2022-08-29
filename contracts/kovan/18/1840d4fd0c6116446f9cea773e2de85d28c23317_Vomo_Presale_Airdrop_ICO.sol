/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

// SPDX-License-Identifier: GPL-3.0
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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

// File: contracts/VOMOICOwithERC20.sol


pragma solidity ^0.8.0;

contract Vomo_Presale_Airdrop_ICO is ERC20{
    // Fields:
   // string public constant name = "VomoVerse";
    //string public constant symbol = "Vomo";
   // uint256 constant decimals = 18;
    uint256 public Presale_Price = 70921; // per 1 Ether
    uint256 public Token_Soft_Cap = 105000000000000000000000000;
    uint256 public Softcap_Price = 35587;
    uint256 public Token_Hard_Cap = 105000000000000000000000000;
    uint256 public Hardcap_Price = 17793;
    uint256 public Listing_Price = 14416;

    enum State {
        Init,
        Running
    }
    uint256 public presale_TransactionFee;
    uint256 public refBuy_Transactionfee;
    uint256 public softcap_TransactionFee;
    uint256 public hardcap_TransactionFee;
    uint256 public listing_Transactionfee;
    uint256 public presaleBalance;
    uint256 public softcapBalance;
    uint256 public hardcapBalance;
    uint256 public listingBalance;
    uint256 public airdropBalance;
    uint256 public Presale_Start_Countdown;
    uint256 public Presale_End_Countdown;
    uint256 public Softcap_End_Countdown;
    uint256 public Hardcap_End_Countdown;
    uint256 presaleSupply_;
    address funder1;
    address funder2;
    address funder3;
    address Development;
    address Marketing;
    address Community;
    address TokenStability;
    address Referral;
    State currentState = State.Running;
    uint256 public Presale_initialToken = 0; //inital presale sold
    uint256 public Softcap_initialToken = 0; //initial softcap sold
    uint256 public Hardcap_initialToken = 0; //intial hardcap sold
    uint256 public Listing_initialToken = 0; //inital listing
    uint256 public Airdrop_initialToken = 0; // initial airdrop
    uint256 DropTokens;
    // Gathered funds can be withdrawn only to escrow's address.
    address public escrow;
    mapping(address => uint256) private balance;
    mapping(address => bool) ownerAppended;
    address[]  owners;

    /// Modifiers:
    modifier onlyInState(State state) {
        require(state == currentState);
        _;
    }

    /// Events:

    event presaleTransfer(
        address indexed from,
        address indexed to,
        uint256 _value
    );
    event referalTransfer(
        address indexed from,
        address indexed to,
        uint256 _value
    );
    event AirdropTransfer(
        address indexed from,
        address indexed to,
        uint256 _value
    );
    event softcapTransfer(
        address indexed from, 
        address indexed to, 
        uint256 _value
        );
    event hardcapTransfer(
        address indexed from, 
        address indexed to, 
        uint256 _value
        );
    event listingTransfer(
        address indexed from, 
        address indexed to, 
        uint256 _value
        );
    event presaleStart(
        uint256 timestamp
        );
    event presaleEnd(
        uint256 timestamp
        );
    event softcapEnd(
        uint256 timestamp
        );
    event hardcapEnd(
        uint256 timestamp
        );
    event PresaleEthToVomo(
        uint256 EtheValue,
        uint256 VomValue
    );
    event SoftcapEthToVomo(
        uint256 EtheValue,
        uint256 VomValue
    );
    event HardcapEthToVomo(
        uint256 EtheValue,
        uint256 VomValue
    );
     event ListingEthToVomo(
        uint256 EtheValue,
        uint256 VomValue
    );

    /// Functions:
    constructor(
        address _escrow,
        address _funder1,
        address _funder2,
        address _funder3,
        address _Development,
        address _Marketing,
        address _Community,
        address _TokenStability
    ) ERC20("VomoVerse", "Vomo"){
        require(_escrow != address(0));
        _mint(msg.sender, 1400000000000000000000000000);
        escrow = _escrow;
        presaleSupply_ = 3000000000000000000000000;
        funder1 = _funder1;
        funder2 = _funder2;
        funder3 = _funder3;
        Development = _Development;
        Marketing = _Marketing;
        Community = _Community;
        TokenStability = _TokenStability;
        balance[escrow] += DropTokens;
        balance[escrow] += presaleSupply_;
        balance[escrow] += Token_Soft_Cap;
        balance[escrow] += Token_Hard_Cap;
    }

    function Timestamp(
        uint256 _Presale_Start_Countdown,
        uint256 _Presale_End_Countdown,
        uint256 _Softcap_End_Countdown,
        uint256 _Hardcap_End_Countdown
    ) public {
        require(msg.sender == owner, "Set Only Admin");
        Presale_Start_Countdown = _Presale_Start_Countdown;
        Presale_End_Countdown = _Presale_End_Countdown;
        Softcap_End_Countdown = _Softcap_End_Countdown;
        Hardcap_End_Countdown = _Hardcap_End_Countdown;
        emit presaleStart(Presale_Start_Countdown);
        emit presaleEnd(Presale_End_Countdown);
        emit softcapEnd(Softcap_End_Countdown);
        emit hardcapEnd(Hardcap_End_Countdown);
    }

    function setAirdrop(uint256 _DropTokens) public {
        require(msg.sender == owner, "Set Only Admin");
        DropTokens = _DropTokens;
    }

    function buyTokens(address _buyer, address _referral)
        public
        payable
        onlyInState(State.Running)
    {
        Referral = _referral;
        require(Presale_Start_Countdown != 0, "Set Presale Start Date....!");
        require(Presale_End_Countdown != 0, "Set Presale End Date....!");
        require(Softcap_End_Countdown != 0, "Set Softcap End Date....!");
        require(Hardcap_End_Countdown != 0, "Set Hardcap End Date....!");
        require(Referral != _buyer, "Buyer cannot self referal");
        require(
            block.timestamp >= Presale_Start_Countdown,
            "Presale will Start Soon.."
        );
        require(msg.value != 0);

        //Presale
        if (block.timestamp <= Presale_End_Countdown) {
            uint256 PrebuyerTokens = msg.value * Presale_Price;
            if (PrebuyerTokens > 38461538000000000000000) {
                uint256 presaleBuy_Transactionfee = 384615385000000000000;
                uint256 actual_PrebuyerTokens = PrebuyerTokens -
                    presaleBuy_Transactionfee;
                uint256 reftokensVal = msg.value * Presale_Price;
                // tranfer to Referal if buyer 20USD or more
                if(Referral != 0x0000000000000000000000000000000000000000){
                if (msg.value >= 13152000000000000) {
                    uint256 refToken = (reftokensVal / 100) * 4;
                    refBuy_Transactionfee = 15384615400000000000;
                    uint256 actual_refToken = refToken - refBuy_Transactionfee;
                    balance[Referral] += actual_refToken;
                    emit referalTransfer(escrow, Referral, refToken);
                }
                }
                presale_TransactionFee =
                    presaleBuy_Transactionfee +
                    refBuy_Transactionfee;
                balance[escrow] += presale_TransactionFee;
                require(
                    Presale_initialToken + PrebuyerTokens <= presaleSupply_
                );
                balance[_buyer] += actual_PrebuyerTokens;
                Presale_initialToken += PrebuyerTokens;
                balance[escrow] = presaleSupply_ - Presale_initialToken;
                uint256 _presaleBalance = balance[escrow];
                presaleBalance = _presaleBalance;
                if (!ownerAppended[_buyer]) {
                    ownerAppended[_buyer] = true;
                    owners.push(_buyer);
                }

                emit presaleTransfer(escrow, _buyer, actual_PrebuyerTokens);
                emit PresaleEthToVomo(msg.value, actual_PrebuyerTokens);
            } else {
                uint256 presaleBuy_Transactionfee = (Presale_Price / 100) * 1;
                uint256 actual_Presale_Price = Presale_Price -
                    presaleBuy_Transactionfee;
                uint256 actual_PrebuyerTokens = msg.value *
                    actual_Presale_Price;
                uint256 reftokensVal = msg.value * Presale_Price;
                // tranfer to Referal if buyer 20USD or more
                if(Referral != 0x0000000000000000000000000000000000000000){
                if (msg.value >= 13152000000000000) {
                    uint256 refToken = (reftokensVal / 100) * 4;
                    refBuy_Transactionfee = (refToken / 100) * 1;
                    uint256 actual_refToken = refToken - refBuy_Transactionfee;
                    balance[Referral] += actual_refToken;
                    emit referalTransfer(escrow, Referral, refToken);
                }
                }
                presale_TransactionFee =
                    presaleBuy_Transactionfee +
                    refBuy_Transactionfee;
                balance[escrow] += presale_TransactionFee;

                require(
                    Presale_initialToken + PrebuyerTokens <= presaleSupply_
                );

                balance[_buyer] += actual_PrebuyerTokens;

                Presale_initialToken += PrebuyerTokens;
                balance[escrow] = presaleSupply_ - Presale_initialToken;
                uint256 _presaleBalance = balance[escrow];
                presaleBalance = _presaleBalance;
                if (!ownerAppended[_buyer]) {
                    ownerAppended[_buyer] = true;
                    owners.push(_buyer);
                }

                emit presaleTransfer(escrow, _buyer, actual_PrebuyerTokens);
                emit PresaleEthToVomo(msg.value, actual_PrebuyerTokens);
            }
        }
        //SoftCap
        else if (block.timestamp <= Softcap_End_Countdown) {
            uint256 SoftbuyerTokens = msg.value * Softcap_Price;
            if (SoftbuyerTokens > 38461538000000000000000) {
                uint256 softcapBuy_Transactionfee = 384615385000000000000;
                uint256 actual_SoftbuyerTokens = SoftbuyerTokens -
                    softcapBuy_Transactionfee;
                uint256 reftokensVal = msg.value * Softcap_Price;
                // tranfer to Referal if buyer 20USD or more
                if(Referral != 0x0000000000000000000000000000000000000000){
                if (msg.value >= 13152000000000000) {
                    uint256 refToken = (reftokensVal / 100) * 4;
                    refBuy_Transactionfee = 15384615400000000000;
                    uint256 actual_refToken = refToken - refBuy_Transactionfee;
                    balance[Referral] += actual_refToken;
                    emit referalTransfer(escrow, Referral, refToken);
                }
                }
                softcap_TransactionFee =
                    softcapBuy_Transactionfee +
                    refBuy_Transactionfee;

                balance[escrow] += softcap_TransactionFee;

                uint256 totalSoftcap = Token_Soft_Cap + presaleBalance;
                require(Softcap_initialToken + SoftbuyerTokens <= totalSoftcap);

                balance[_buyer] += actual_SoftbuyerTokens;

                Softcap_initialToken += SoftbuyerTokens;
                balance[escrow] = totalSoftcap - Softcap_initialToken;
                uint256 _softcapBalance = balance[escrow];
                softcapBalance = _softcapBalance;
                if (!ownerAppended[_buyer]) {
                    ownerAppended[_buyer] = true;
                    owners.push(_buyer);
                }

                emit softcapTransfer(escrow, _buyer, actual_SoftbuyerTokens);
                emit SoftcapEthToVomo(msg.value, actual_SoftbuyerTokens);
            } else {
                uint256 softcapBuy_Transactionfee = (Softcap_Price / 100) * 1;
                uint256 actual_Softcap_Price = Softcap_Price -
                    softcapBuy_Transactionfee;
                uint256 actual_SoftbuyerTokens = msg.value *
                    actual_Softcap_Price;
                uint256 reftokensVal = msg.value * Softcap_Price;
                // tranfer to Referal if buyer 20USD or more
                if(Referral != 0x0000000000000000000000000000000000000000){
                if (msg.value >= 13152000000000000) {
                    uint256 refToken = (reftokensVal / 100) * 4;
                    refBuy_Transactionfee = (refToken / 100) * 1;
                    uint256 actual_refToken = refToken - refBuy_Transactionfee;
                    balance[Referral] += actual_refToken;
                    emit referalTransfer(escrow, Referral, refToken);
                }
                }
                softcap_TransactionFee =
                    softcapBuy_Transactionfee +
                    refBuy_Transactionfee;

                balance[escrow] += softcap_TransactionFee;

                uint256 totalSoftcap = Token_Soft_Cap + presaleBalance;
                require(Softcap_initialToken + SoftbuyerTokens <= totalSoftcap);

                balance[_buyer] += actual_SoftbuyerTokens;

                Softcap_initialToken += SoftbuyerTokens;
                balance[escrow] = totalSoftcap - Softcap_initialToken;
                uint256 _softcapBalance = balance[escrow];
                softcapBalance = _softcapBalance;
                if (!ownerAppended[_buyer]) {
                    ownerAppended[_buyer] = true;
                    owners.push(_buyer);
                }

                emit softcapTransfer(escrow, _buyer, actual_SoftbuyerTokens);
                emit SoftcapEthToVomo(msg.value, actual_SoftbuyerTokens);
            }
        }
        //HardCap
        else if (block.timestamp <= Hardcap_End_Countdown) {
            uint256 hardbuyerTokens = msg.value * Hardcap_Price;
            if (hardbuyerTokens > 38461538000000000000000) {
                uint256 hardcapBuy_Transactionfee = 384615385000000000000;
                uint256 actual_hardbuyerTokens = hardbuyerTokens -
                    hardcapBuy_Transactionfee;
                uint256 reftokensVal = msg.value * Hardcap_Price;
                // tranfer to Referal if buyer 20USD or more
                if(Referral != 0x0000000000000000000000000000000000000000){
                if (msg.value >= 13152000000000000) {
                    uint256 refToken = (reftokensVal / 100) * 4;
                    refBuy_Transactionfee = 15384615400000000000;
                    uint256 actual_refToken = refToken - refBuy_Transactionfee;
                    balance[Referral] += actual_refToken;
                    emit referalTransfer(escrow, Referral, refToken);
                }
                }
                hardcap_TransactionFee =
                    hardcapBuy_Transactionfee +
                    refBuy_Transactionfee;

                balance[escrow] += hardcap_TransactionFee;

                uint256 totalhardcap = Token_Hard_Cap + softcapBalance;
                require(Hardcap_initialToken + hardbuyerTokens <= totalhardcap);

                balance[_buyer] += actual_hardbuyerTokens;

                Hardcap_initialToken += hardbuyerTokens;
                balance[escrow] = totalhardcap - Hardcap_initialToken;
                uint256 _hardcapBalance = balance[escrow];
                hardcapBalance = _hardcapBalance;
                if (!ownerAppended[_buyer]) {
                    ownerAppended[_buyer] = true;
                    owners.push(_buyer);
                }

                emit hardcapTransfer(escrow, _buyer, actual_hardbuyerTokens);
                emit HardcapEthToVomo(msg.value, actual_hardbuyerTokens);
            } else {
                uint256 hardcapBuy_Transactionfee = (Hardcap_Price / 100) * 1;
                uint256 actual_Hardcap_Price = Hardcap_Price -
                    hardcapBuy_Transactionfee;
                uint256 actual_hardbuyerTokens = msg.value *
                    actual_Hardcap_Price;
                uint256 reftokensVal = msg.value * Hardcap_Price;
                // tranfer to Referal if buyer 20USD or more
                if(Referral != 0x0000000000000000000000000000000000000000){
                if (msg.value >= 13152000000000000) {
                    uint256 refToken = (reftokensVal / 100) * 4;
                    refBuy_Transactionfee = (refToken / 100) * 1;
                    uint256 actual_refToken = refToken - refBuy_Transactionfee;
                    balance[Referral] += actual_refToken;
                    emit referalTransfer(escrow, Referral, refToken);
                }
                }
                hardcap_TransactionFee =
                    hardcapBuy_Transactionfee +
                    refBuy_Transactionfee;

                balance[escrow] += hardcap_TransactionFee;

                uint256 totalhardcap = Token_Hard_Cap + softcapBalance;
                require(Hardcap_initialToken + hardbuyerTokens <= totalhardcap);

                balance[_buyer] += actual_hardbuyerTokens;

                Hardcap_initialToken += hardbuyerTokens;
                balance[escrow] = totalhardcap - Hardcap_initialToken;
                uint256 _hardcapBalance = balance[escrow];
                hardcapBalance = _hardcapBalance;
                if (!ownerAppended[_buyer]) {
                    ownerAppended[_buyer] = true;
                    owners.push(_buyer);
                }

                emit hardcapTransfer(escrow, _buyer, actual_hardbuyerTokens);
                emit HardcapEthToVomo(msg.value, actual_hardbuyerTokens);
            }
        }
        //Listing Price
        else {
            uint256 listbuyerTokens = msg.value * Listing_Price;
            if (listbuyerTokens > 38461538000000000000000) {
                uint256 listingbuy_Transactionfee = 384615385000000000000;
                uint256 actual_listbuyerTokens = listbuyerTokens -
                    listingbuy_Transactionfee;
                uint256 reftokensVal = msg.value * Listing_Price;
                // tranfer to Referal if buyer 20USD or more
                if(Referral != 0x0000000000000000000000000000000000000000){
                if (msg.value >= 13152000000000000) {
                    uint256 refToken = (reftokensVal / 100) * 4;
                    refBuy_Transactionfee = 15384615400000000000;
                    uint256 actual_refToken = refToken - refBuy_Transactionfee;
                    balance[Referral] += actual_refToken;
                    emit referalTransfer(escrow, Referral, refToken);
                }
                }
                listing_Transactionfee =
                    listingbuy_Transactionfee +
                    refBuy_Transactionfee;

                balance[escrow] += listing_Transactionfee;

                uint256 totallisting = hardcapBalance;
                require(Listing_initialToken + listbuyerTokens <= totallisting);

                balance[_buyer] += actual_listbuyerTokens;

                Listing_initialToken += listbuyerTokens;
                balance[escrow] = totallisting - Listing_initialToken;
                uint256 _listingBalance = balance[escrow];
                listingBalance = _listingBalance;
                if (!ownerAppended[_buyer]) {
                    ownerAppended[_buyer] = true;
                    owners.push(_buyer);
                }

                emit listingTransfer(escrow, _buyer, actual_listbuyerTokens);
                emit ListingEthToVomo(msg.value, actual_listbuyerTokens);
            } else {
                uint256 listingbuy_Transactionfee = (Listing_Price / 100) * 1;
                uint256 actual_Listing_Price = Listing_Price -
                    listingbuy_Transactionfee;
                uint256 actual_listbuyerTokens = msg.value *
                    actual_Listing_Price;
                uint256 reftokensVal = msg.value * Listing_Price;
                // tranfer to Referal if buyer 20USD or more
                if(Referral != 0x0000000000000000000000000000000000000000){
                if (msg.value >= 13152000000000000) {
                    uint256 refToken = (reftokensVal / 100) * 4;
                    refBuy_Transactionfee = (refToken / 100) * 1;
                    uint256 actual_refToken = refToken - refBuy_Transactionfee;
                    balance[Referral] += actual_refToken;
                    emit referalTransfer(escrow, Referral, refToken);
                }
                }
                listing_Transactionfee =
                    listingbuy_Transactionfee +
                    refBuy_Transactionfee;

                balance[escrow] += listing_Transactionfee;

                uint256 totallisting = hardcapBalance;
                require(Listing_initialToken + listbuyerTokens <= totallisting);

                balance[_buyer] += actual_listbuyerTokens;

                Listing_initialToken += listbuyerTokens;
                balance[escrow] = totallisting - Listing_initialToken;
                uint256 _listingBalance = balance[escrow];
                listingBalance = _listingBalance;
                if (!ownerAppended[_buyer]) {
                    ownerAppended[_buyer] = true;
                    owners.push(_buyer);
                }

                emit listingTransfer(escrow, _buyer, actual_listbuyerTokens);
                emit ListingEthToVomo(msg.value, actual_listbuyerTokens);
            }
        }
        //Distribution crypto into 7 wallets address
        uint256 Balance_funder1 = (msg.value / 100) * 15;
        uint256 Balance_funder2 = (msg.value / 100) * 5;
        uint256 Balance_funder3 = (msg.value / 100) * 5;
        uint256 Balance_Development = (msg.value / 100) * 35;
        uint256 Balance_Marketing = (msg.value / 100) * 25;
        uint256 Balance_Community = (msg.value / 100) * 5;
        uint256 Balance_TokenStability = (msg.value / 100) * 10;

        //Transfer crypto Eth to 7 wallets address
        if (address(this).balance > 0) {
            payable(funder1).transfer(Balance_funder1);
            payable(funder2).transfer(Balance_funder2);
            payable(funder3).transfer(Balance_funder3);
            payable(Development).transfer(Balance_Development);
            payable(Marketing).transfer(Balance_Marketing);
            payable(Community).transfer(Balance_Community);
            payable(TokenStability).transfer(Balance_TokenStability);
        }
    }

    //Airdop
    function AirDrop(address to, uint256 numDropTokens)
        public
        virtual
        returns (bool)
    {
        require(msg.sender == owner);
        require(numDropTokens <= DropTokens);
        require(Airdrop_initialToken + numDropTokens <= DropTokens);
        balance[to] += numDropTokens;
        Airdrop_initialToken += numDropTokens;
        balance[escrow] = DropTokens - Airdrop_initialToken;
        uint256 _airdropBalance = balance[escrow];
        airdropBalance = _airdropBalance;
        if (!ownerAppended[to]) {
            ownerAppended[to] = true;
            owners.push(to);
        }
        emit AirdropTransfer(msg.sender, to, numDropTokens);
        return true;
    }

    /// @dev Returns number of tokens owned by given address.
    /// @param _owner Address of token owner.
    function balanceOf(address _owner) public view override virtual returns (uint256) {
        return balance[_owner];
    }

    address public owner;

    // Transfer Ownership
    function Ownable() public {
        owner = escrow;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}