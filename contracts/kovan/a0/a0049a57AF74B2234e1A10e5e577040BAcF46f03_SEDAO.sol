// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// TODO: implement openzeppelin Ownable
contract SEShareToken is ERC20 {
    address public owner;
    
    constructor() ERC20("7Energy Share Token", "7ES") {
        owner = msg.sender;
    }

    function mint(address account, uint256 amount) public {
        require(msg.sender == owner, "only owner can mint");
        _mint(account, amount);
    }
    
    function burn(address account, uint256 amount) public {
        require(msg.sender == owner, "only owner can burn");
        _burn(account, amount);
    }

    // skip allowance check for owned initiated transfers
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        if(msg.sender == owner) {
            _transfer(sender, recipient, amount);
            return true;    
        } else {
            return ERC20.transferFrom(sender, recipient, amount);
        }
    }

    // make it a non-transferable  token
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        require(msg.sender == owner, "non-transferable");
        ERC20._transfer(sender, recipient, amount);
    }
}

contract SEDAO {
    IERC20 public paymentToken;
    SEShareToken public shareToken;
    uint256 public admissionAmount;
    address public admin;
    mapping(address => bool) public isOracle;
    // timeframe after which a leaving member can redeem all shares
    uint256 public cooldownPeriod = 3600*24; // 1 day
    mapping(address => bool) public isMember;
    mapping(address => bool) public prefersShares;
    // timestamp at which a member left - reset after cooldown
    mapping(address => uint256) public leftTs;
    uint256 constant SHARE_PRICE_DENOM = 1E18;

    constructor(
        IERC20 paymentToken_, 
        uint256 initialAdmissionAmount_
    ) {
        admin = msg.sender;
        paymentToken = paymentToken_;
        admissionAmount = initialAdmissionAmount_;
        shareToken = new SEShareToken();
    }

    modifier onlyMember {
        require(isMember[msg.sender], "not a member");
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "only admin");
        _;
    }

    modifier onlyOracle {
        require(isOracle[msg.sender], "not an oracle");
        _;
    }

    // amount of shares a member gets when joining
    function getAdmissionShareAmount() public view returns(uint256) {
        return admissionAmount * 1;
    }

    // min amount of shares required for retaining membership
    function getMinShareAmount() public view returns(uint256) {
        return getAdmissionShareAmount() / 2;
    }

    // returns true if the given account is a member holding the min amount of shares required
    function isSolventMember(address account) public view returns (bool) {
        return isMember[account] && shareToken.balanceOf(account) >= getMinShareAmount();
    }

    // in v1, the share price is just the relation between treasury and outstanding shares
    function getSharePrice() public view returns(uint256) {
        //require(shareToken.totalSupply() > 0, "no shares outstanding");
        if(shareToken.totalSupply() > 0) {
            return paymentToken.balanceOf(address(this)) * SHARE_PRICE_DENOM / shareToken.totalSupply();
        } else { // fallback to the price set for admission
            return admissionAmount * SHARE_PRICE_DENOM / getAdmissionShareAmount();
        }
    }

    event Joined(address indexed account, uint256 admissionPaymentAmount, uint256 admissionSharesAmount);
    // Allows anybody to pre-join the DAO by paying the admission fee and getting shares in return
    // Sender needs to ERC20.approve() beforehand
    // TODO: allow ERC777.send()
    function join() external {
        require(! isMember[msg.sender], "already a member");
        paymentToken.transferFrom(msg.sender, address(this), admissionAmount);
        shareToken.mint(msg.sender, getAdmissionShareAmount());
        isMember[msg.sender] = true;
        emit Joined(msg.sender, admissionAmount, getAdmissionShareAmount());
    }

    event BoughtShares(address indexed account, uint256 sharesAmount, uint256 paymentAmount);
    // Allows members to buy more shares
    function buyShares(uint256 sharesAmount) external onlyMember {
        paymentToken.transferFrom(msg.sender, address(this), sharesAmount * getSharePrice() / SHARE_PRICE_DENOM);
        shareToken.mint(msg.sender, sharesAmount);
        emit BoughtShares(msg.sender, sharesAmount, sharesAmount * getSharePrice() / SHARE_PRICE_DENOM);
    }

    event RedeemedShares(address indexed account, uint256 amount, uint256 paymentAmount);
    // Allows anybody to redeem shares for payment tokens
    // at least shares equivalent to the admission amount need to be left
    function redeemShares(uint256 sharesAmount) external {
        require(sharesAmount <= shareToken.balanceOf(msg.sender), "amount exceeds balance");
        if(shareToken.balanceOf(msg.sender) - sharesAmount < getMinShareAmount()) {
            if(isMember[msg.sender]) {
                revert("not enough shares left");
            } else if(leftTs[msg.sender] != 0) { // leaving member
                require(block.timestamp >= leftTs[msg.sender] + cooldownPeriod, "cooldown not over");
                leftTs[msg.sender] = 0; // cooldown over, reset
            }
        }
        
        uint256 paymentAmount = sharesAmount * getSharePrice() / SHARE_PRICE_DENOM;
        paymentToken.transfer(msg.sender, paymentAmount);
        shareToken.burn(msg.sender, sharesAmount);
        emit RedeemedShares(msg.sender, sharesAmount, paymentAmount);
    }

    event Left(address indexed account, uint256 sharesHeld);
    // allows members to leave. Shares can be redeemed after the cooldown period
    function leave() external onlyMember {
        leftTs[msg.sender] = block.timestamp;
        isMember[msg.sender] = false;
        emit Left(msg.sender, shareToken.balanceOf(msg.sender));
    }
    
    // not yet tested - don't use!
    event PrefersPayment(address indexed account);
    // allows producers to set their preference to getting rewarded with payment tokens
    function preferPayment() external onlyMember {
        prefersShares[msg.sender] = false;
        emit PrefersPayment(msg.sender);
    }

    // not yet tested - don't use!
    event PrefersShares(address indexed account);
    // allows producers to set their preference to getting rewarded with shares
    function preferShares() external onlyMember {
        prefersShares[msg.sender] = true;
        emit PrefersShares(msg.sender);
    }

    event Consumed(address indexed account, uint256 period, uint256 wh, uint256 price);
    event Produced(address indexed account, uint256 period, uint256 wh, uint256 price);
    // oracle provides a list of accounts to be updated for the given accounting period
    // account[], whDelta[], price
    // relies on the oracle not bankrupting the DAO - sum of delta shall always be zero
    // the oracle may split the operations into multiple batches
    // a positive whDelta means production, a negative one consumption
    function prosumed(uint256 period, address[] memory accounts, int256[] calldata whDeltas, uint256 whPrice) 
        external onlyOracle 
    {
        require(accounts.length == whDeltas.length, "bad params");
        for(uint256 i=0; i<accounts.length; i++) {
            int256 amountDelta = whDeltas[i]*int256(whPrice);
            if(amountDelta < 0) { // net consumer pays into treasury account
                uint256 paymentAmount = uint256(amountDelta * -1);
                try paymentToken.transferFrom(accounts[i], address(this), paymentAmount) {
                } catch (bytes memory /*reason*/) {
                    // on failed payment, an equivalent amount in shares is burned
                    // in order to compensate the treasury
                    // TODO: handle case of not enough shares left
                    shareToken.burn(accounts[i], paymentAmount * SHARE_PRICE_DENOM / getSharePrice());
                }
                emit Consumed(accounts[i], period, uint256(whDeltas[i] * -1), whPrice);
            } else if(amountDelta > 0) { // net producer gets paid by treasury account or in shares
                uint256 rewardAmount = uint256(amountDelta);
                if(prefersShares[msg.sender]) {
                    shareToken.mint(msg.sender, rewardAmount * SHARE_PRICE_DENOM / getSharePrice());
                } else {
                    paymentToken.transfer(accounts[i], rewardAmount);
                }
                emit Produced(accounts[i], period, uint256(whDeltas[i]), whPrice);
            } // else: ignore items with 0 delta
        }
    }

    event RemovedMember(address indexed account, uint256 sharesHeld);
    // allows the admin to remove a member. Cooldown period not applied in this case.
    function removeMember(address account) external onlyAdmin {
        if(isMember[account]) {
            isMember[account] = false;
            emit RemovedMember(account, shareToken.balanceOf(account));
        }
    }

    event AddedOracle(address indexed account);
    function addOracle(address account) external onlyAdmin {
        require(! isOracle[account], "already set");
        isOracle[account] = true;
        emit AddedOracle(account);
    }

    event RemovedOracle(address indexed account);
    function removeOracle(address account) external onlyAdmin {
        require(isOracle[account], "not set");
        isOracle[account] = false;
        emit RemovedOracle(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
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
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
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