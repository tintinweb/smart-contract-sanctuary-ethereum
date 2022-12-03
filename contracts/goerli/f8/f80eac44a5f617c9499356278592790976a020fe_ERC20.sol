/**
 *Submitted for verification at Etherscan.io on 2022-12-03
*/

// SPDX-License-Identifier: MIT
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

// File: ERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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

struct Rational {
    uint8 numerator;
    uint8 denominator;
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => bool) internal _merchantList; 

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) internal _thirdPartyList;

    address[] private _pendingMerchants;
    address[] private _pendingThirdParties;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    address private _owner;
    uint256 private _maxAllowance;

    Rational private handlingRate;
    Rational private tipRate;

    modifier isMerchant(address _address) {
        require(_merchantList[_address], "You need to be a merchant");
        _;
    }

    modifier isThirdParty(address _address) {
        require(_thirdPartyList[_address], "You need to be an authorized third-party.");
        _;
    }

    modifier isOwner(address _address) {
        require(_address == _owner, "You need to be the owner.");
        _;
    }

    modifier notMerchant(address _address) {
        require(!_merchantList[_address], "You are already a merchant.");
        _;
    }

    modifier notThirdParty(address _address) {
        require(!_thirdPartyList[_address], "You are already a third party.");
        _;
    }

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_, uint8 handlingRateNum, uint8 tipRateNum) {
        _name = name_;
        _symbol = symbol_;
        _owner = _msgSender();
        _maxAllowance = 100 * 10 ** decimals();
        handlingRate.denominator = 100;
        handlingRate.numerator = handlingRateNum;
        tipRate.denominator = 100;
        tipRate.numerator = tipRateNum;
        
    }

    function getHandlingRate() public view returns(uint8){
        return handlingRate.numerator;
    }

    function getTipRate() public view returns(uint8){
        return tipRate.numerator;
    }

    function setHandlingRate(uint8 _rate) public isOwner(_msgSender()) {
        handlingRate.numerator = _rate;
    }

    function setTipRate(uint8 _rate) public isOwner(_msgSender()) {
        tipRate.numerator = _rate;
    }

    function addMerchant(address _addressToMerchant) public isOwner(_msgSender()){
        _merchantList[_addressToMerchant] = true;
    }

    function getPendingMerchants() public view isOwner(_msgSender()) returns(address[] memory) {
        return _pendingMerchants;
    }

    function getPendingThridParties() public view isOwner(_msgSender()) returns(address[] memory) {
        return _pendingThirdParties;
    }

    function addAllPendingMerchants() public isOwner(_msgSender()) {
        for(uint i=0; i <_pendingMerchants.length; ++i ) {
            if (!_merchantList[_pendingMerchants[i]]){
                _merchantList[_pendingMerchants[i]] = true;
            }
        }
        delete _pendingMerchants;
    }

    function addAllPendingThirdParties() public isOwner(_msgSender()) {
        for(uint i=0; i<_pendingThirdParties.length; ++i) {
            if(!_thirdPartyList[_pendingThirdParties[i]]) {
                _thirdPartyList[_pendingThirdParties[i]] = true;
            }
        }

        delete _pendingThirdParties;
    }

    function verifyMerchant(address _merchantAddress) public view returns(bool) {
        bool merchantIsWhitelisted = _merchantList[_merchantAddress];
        return merchantIsWhitelisted;
    }

    function addThirdParty(address _addressToThirdParty) public isOwner(_msgSender()){
        _thirdPartyList[_addressToThirdParty] = true;
    }

    function verifyThirdParty(address _thirdPartyAddress) public view returns(bool) {
        bool thirdPartyIsWhitelisted = _thirdPartyList[_thirdPartyAddress];
        return thirdPartyIsWhitelisted;
    }

    function removeMerchant(address _merchantAddress) public isOwner(_msgSender()) {
        _merchantList[_merchantAddress] = false;
    }

    function removeThirdParty(address _thirdPartyAddress) public isOwner(_msgSender()) {
        _thirdPartyList[_thirdPartyAddress] = false;
    }

    function requestMerchant() public notMerchant(_msgSender()) {
        _pendingMerchants.push(_msgSender());
    }

    function requestThirdParty() public notThirdParty(_msgSender()) {
        _pendingThirdParties.push(_msgSender());
    }

    function getMaxAllowance() public view isOwner(_msgSender()) returns(uint256) {
        return _maxAllowance;
    }

    function setMaxAllowance(uint256 maxAllowance) public isOwner(_msgSender()) {
        _maxAllowance = maxAllowance * 10 ** decimals();
    }

    function increaseMaxAllowance(uint256 addedAmount) public isOwner(_msgSender()) {
        _maxAllowance = _maxAllowance + addedAmount * 10 ** decimals();
    }

    function decreaseMaxAllowance(uint256 subtractedValue) public isOwner(_msgSender()) {
        require(_maxAllowance >= subtractedValue, "ERC20: Max allowance cannot below zero.");
        unchecked {
            _maxAllowance = _maxAllowance - subtractedValue * 10 ** decimals();
        }
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
     * NOTE: This information is only used for display purposes: it in
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
        
        if (verifyMerchant(to) || verifyThirdParty(to)) {
            _transferWithHandling(owner, to, amount);
        }   else {
            _transfer(owner, to, amount);
        }
        return true;
    }

    function transferFromOwner(address to, uint256 amount) public virtual isOwner(_msgSender()) returns(bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {


        return _allowances[owner][spender];


    } // TODO!!!!!!!!!!!!

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

    function approve(address thirdParty, uint256 amount) public override returns (bool) {
        if (verifyThirdParty(thirdParty)) {
            // Only allow for trusted third-party in the whitelist.
            require(amount * 10 ** decimals() <= getMaxAllowance(), "ERC20: Amount exceeds maximum allowance.");
            unchecked {
                _approve(_msgSender(), thirdParty, amount * 10 ** decimals());
            }
            return true;
        }
        return false;
    }

    function increaseAllowance(address thirdParty, uint256 addedAmount) public virtual returns (bool) {
        if (verifyThirdParty(thirdParty)) {
            // Only allow for trusted third-party in the whitelist.
            uint256 newAllowance = allowance(_msgSender(), thirdParty) + addedAmount * 10 ** decimals();
            require(newAllowance <= getMaxAllowance(), "ERC20: Amount exceeds maximum allowance.");
            unchecked {
                _approve(_msgSender(), thirdParty, newAllowance);
            }
            return true;
        }
        return false;
    }

    function decreaseAllowance(address thirdParty, uint256 subtractedValue) public virtual returns (bool) {
        if (verifyThirdParty(thirdParty)) {
            // Only allow for trusted third-party in the whitelist.
            uint256 currentAllowance = allowance(_msgSender(), thirdParty);
            require(currentAllowance >= subtractedValue * 10 ** decimals(), "ERC20: Decreased allowance below zero");
            unchecked {
                _approve(_msgSender(), thirdParty, currentAllowance - subtractedValue * 10 ** decimals());
            }
            return true;
        }
        return false;
    }


    function mint(address account, uint256 amount) public virtual isMerchant(_msgSender()) returns (bool){
        require(verifyMerchant(account), "ERC20: You can not mint to a machant account");
        unchecked {
            _mint(account, amount);
        }
        return true;
    }

    function purchaseToken() public payable returns (bool){
        require(msg.value > 0, "You need to buy more than 0 tokens");
        unchecked {
            _mint(_msgSender(), msg.value * 1000 * 10 ** 18);
        }
        return true;
    }

    function burn(address account, uint256 amount) public virtual isMerchant(_msgSender()) returns (bool){
        require(verifyMerchant(account), "ERC20: You can not burn from a machant account");
        unchecked {
            _burn(account, amount);
        }
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
    ) public virtual override isThirdParty(_msgSender()) isMerchant(to) returns (bool) {
        address spender = _msgSender();
        
        uint256 tips = (tipRate.numerator * amount) / tipRate.denominator;
        uint256 handlingFee = (handlingRate.numerator * amount) / handlingRate.denominator;

        _spendAllowance(from, spender, amount+tips+handlingFee);
        _transfer(from, spender, tips);
        _transferWithHandling(from, to, amount);
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

     function _transferWithHandling(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        uint256 handlingFee = handlingRate.numerator*amount / handlingRate.denominator;
        uint256 totalAmount = amount + handlingFee;

        require(fromBalance >= totalAmount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - totalAmount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[_owner] += handlingFee;
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