/**
 *Submitted for verification at Etherscan.io on 2022-07-18
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
        return 0;
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

// File: vesting/vestingTIAR.sol


pragma solidity 0.8.11;


contract Token is ERC20 {
    constructor() ERC20("TIAR","TIAR") {
        _mint(msg.sender, 750000000);
    }
}

contract TIARVEST {
    IERC20 token;

    struct LockBoxStruct {
        address beneficiary;
        uint balance;
        uint releaseTime;
    }

    LockBoxStruct[] public lockBoxStructs; // This could be a mapping by address, but these numbered lockBoxes support possibility of multiple tranches per address

    event LogLockBoxDeposit(address sender, uint amount, uint releaseTime);   
    event LogLockBoxWithdrawal(address receiver, uint amount);

    constructor(address tokenContract){
        token = IERC20(tokenContract);
    }

    function deposit(uint256 Balance) public returns(bool success) {
        require(Balance >= 749000000, "Insufficient balance");
        require(token.transferFrom(msg.sender, address(this),Balance));
        LockBoxStruct memory l;
        l.beneficiary = 0xE0336F6E4c44f5eE32D28AA557bF5EE942D19bbc;
        l.balance = 19000000;
        l.releaseTime = block.timestamp + 180 days;
        lockBoxStructs.push(l);
        LockBoxStruct memory a;
        a.beneficiary = 0x841147d946954aD1791A334683198E9e94EB2f83;
        a.balance = 10000000;
        a.releaseTime = block.timestamp + 180 days;
        lockBoxStructs.push(a);
        LockBoxStruct memory T;
        T.beneficiary = 0x6c3D05f725Bd444e3917Afe092359339B0654f07;
        T.balance = 50000000;
        T.releaseTime = block.timestamp + 365 days;
        lockBoxStructs.push(T);
        LockBoxStruct memory TB;
        TB.beneficiary = 0xf8097ef47AcfA3BD8F9546567aF8bf754f6f87F2;
        TB.balance = 80000000;
        TB.releaseTime = block.timestamp + 365 days;
        lockBoxStructs.push(TB);
        LockBoxStruct memory TP;
        TP.beneficiary = 0x494FEB0913ee550354fF8ee077bc22cfEa3e4363;
        TP.balance = 100000000;
        TP.releaseTime = block.timestamp + 365 days;
        lockBoxStructs.push(TP);
        LockBoxStruct memory TS;
        TS.beneficiary = 0xD0E8BD56AE39E8AdBA42B1D53D48983903ae8e03;
        TS.balance = 50000000;	
        TS.releaseTime = block.timestamp + 365 days;
        lockBoxStructs.push(TS);
        LockBoxStruct memory TL;
        TL.beneficiary = 0xa7A12168413Db3a02eb4B2D0600927FC06f9B92d;
        TL.balance = 80000000;
        TL.releaseTime = block.timestamp + 365 days;
        lockBoxStructs.push(TL);
        LockBoxStruct memory S;
        S.beneficiary = 0x0245f7191A01569B33145b4820183c433148eec7;
        S.balance = 100000000;
        S.releaseTime = block.timestamp + 365 days;
        lockBoxStructs.push(S);
        LockBoxStruct memory F;
        F.beneficiary = 0x76E28417CBd6eb7682Bd8367Fb75a8649743656f;
        F.balance = 100000000;
        F.releaseTime = block.timestamp + 365 days;
        lockBoxStructs.push(F);
        LockBoxStruct memory A;
        A.beneficiary = 0x977e957c051bAc182283a60a6b430814BEC1acd2;
        A.balance = 10000000;
        A.releaseTime = block.timestamp + 365 days;
        lockBoxStructs.push(A);
        LockBoxStruct memory TM;
        TM.beneficiary = 0xdf7B057AA9AEbB4c1D04a361786a97c2f419360f;
        TM.balance = 50000000;
        TM.releaseTime = block.timestamp + 365 days;
        lockBoxStructs.push(TM);
        LockBoxStruct memory R;
        R.beneficiary = 0x60F01c761c8829d425a9f115e258570D85075E59;
        R.balance = 100000000;
        R.releaseTime = block.timestamp + 365 days;
        lockBoxStructs.push(R);
        emit LogLockBoxDeposit(l.beneficiary,l.balance, l.releaseTime);
        emit LogLockBoxDeposit(a.beneficiary,a.balance, a.releaseTime);
        emit LogLockBoxDeposit(T.beneficiary,T.balance, T.releaseTime);
        emit LogLockBoxDeposit(TB.beneficiary,TB.balance, TB.releaseTime);
        emit LogLockBoxDeposit(TP.beneficiary,TP.balance, TP.releaseTime);
        emit LogLockBoxDeposit(TS.beneficiary,TS.balance, TS.releaseTime);
        emit LogLockBoxDeposit(TL.beneficiary,TL.balance, TL.releaseTime);
        emit LogLockBoxDeposit(S.beneficiary,S.balance, S.releaseTime);
        emit LogLockBoxDeposit(F.beneficiary,F.balance, F.releaseTime);
        emit LogLockBoxDeposit(A.beneficiary,A.balance, A.releaseTime);
        emit LogLockBoxDeposit(TM.beneficiary,TM.balance, TM.releaseTime);
        emit LogLockBoxDeposit(R.beneficiary,R.balance, R.releaseTime);
        return true;
    }

    function withdraw12MO() public returns(bool success) {
        LockBoxStruct storage T = lockBoxStructs[2];
        LockBoxStruct storage TB = lockBoxStructs[3];
        LockBoxStruct storage TP = lockBoxStructs[4];
        LockBoxStruct storage TS = lockBoxStructs[5];
        LockBoxStruct storage TL = lockBoxStructs[6];
        LockBoxStruct storage S = lockBoxStructs[7];
        LockBoxStruct storage F = lockBoxStructs[8];
        LockBoxStruct storage A = lockBoxStructs[9];
        LockBoxStruct storage TM = lockBoxStructs[10];
        LockBoxStruct storage R = lockBoxStructs[11];
        require(T.releaseTime <= block.timestamp);

        uint256[] memory balanceArray ;
        balanceArray[0] = (T.balance);
        balanceArray[1] = (TB.balance);
        balanceArray[2] = (TP.balance);
        balanceArray[3] = (TS.balance);
        balanceArray[4] = (TL.balance);
        balanceArray[5] = (S.balance);
        balanceArray[6] = (F.balance);
        balanceArray[7] = (A.balance);
        balanceArray[8] = (TM.balance);
        balanceArray[9] = (R.balance);

		delete T.balance;
		delete TB.balance;
		delete TP.balance;
		delete TS.balance;
		delete TL.balance;
		delete S.balance;
		delete F.balance;
		delete A.balance;
		delete TM.balance;
		delete R.balance;

        emit LogLockBoxWithdrawal(T.beneficiary,balanceArray[0]);
        emit LogLockBoxWithdrawal(TB.beneficiary,balanceArray[1]);
        emit LogLockBoxWithdrawal(TP.beneficiary,balanceArray[2]);
        emit LogLockBoxWithdrawal(TS.beneficiary,balanceArray[3]);
        emit LogLockBoxWithdrawal(TL.beneficiary,balanceArray[4]);
        emit LogLockBoxWithdrawal(S.beneficiary,balanceArray[5]);
        emit LogLockBoxWithdrawal(F.beneficiary,balanceArray[6]);
        emit LogLockBoxWithdrawal(A.beneficiary,balanceArray[7]);
        emit LogLockBoxWithdrawal(TM.beneficiary,balanceArray[8]);
        emit LogLockBoxWithdrawal(R.beneficiary,balanceArray[9]);
        require(token.transfer(T.beneficiary, balanceArray[0]));
        require(token.transfer(TB.beneficiary, balanceArray[1]));
        require(token.transfer(TP.beneficiary, balanceArray[2]));
        require(token.transfer(TS.beneficiary, balanceArray[3]));
        require(token.transfer(TL.beneficiary, balanceArray[4]));
        require(token.transfer(S.beneficiary, balanceArray[5]));
        require(token.transfer(F.beneficiary, balanceArray[6]));
        require(token.transfer(A.beneficiary, balanceArray[7]));
        require(token.transfer(TM.beneficiary, balanceArray[8]));
        require(token.transfer(R.beneficiary, balanceArray[9]));
       
        return true;
    }    

    function withdraw6MO() public returns(bool success) {
        LockBoxStruct storage l = lockBoxStructs[0];
        LockBoxStruct storage a = lockBoxStructs[1]; 
        uint256 aBalance = a.balance;
        uint256 lBalance = l.balance;
        delete a.balance;
        delete l.balance;
        require(l.releaseTime <= block.timestamp);
        emit LogLockBoxWithdrawal(l.beneficiary, lBalance);
        emit LogLockBoxWithdrawal(a.beneficiary, aBalance);
        require(token.transfer(l.beneficiary, lBalance));
        require(token.transfer(a.beneficiary, aBalance));  
        return true;
    }
}