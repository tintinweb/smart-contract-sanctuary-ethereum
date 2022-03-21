// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./AccessControl.sol";
import "./Context.sol";
import "./ERC20Burnable.sol";

/**
 * @dev Token ERC20 (based on OpenZeppelin v.3.1.0-20200702), including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - ability for holders to pledge (lock over another account) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a banker role that allows for others' tokens management (transfer, burning, allowance)
 *  - NOT MORE a contributor role that allows to deposit tokens on escrow wallets
 *  - a notary role that allows to finalize the transfer of pledged token and to unlock token transfers from escrow wallets
 *  - an admin role that allows to manage other roles
 *  - an owner address that can manage the admin role
 */
contract TokenNGN is Context, AccessControl, ERC20Burnable {
// PLEDGE .. sender ... total amount
    mapping (address => uint256) private _totalcredits;
// PLEDGE .. sender ............ receiver . amount
    mapping (address => mapping (address => uint256)) private _credits;

// ESCROW .. project .. total amount
    mapping (bytes32 => uint256) private _escrowtotal;
// ESCROW .. project .. cap amount
    mapping (bytes32 => uint256) private _escrowcap;
// ESCROW .. project .. cap active
    mapping (bytes32 => bool) private _escrowcapactive;
// ESCROW .. project ........... sender ............ receiver . amount
    mapping (bytes32 => mapping (address => mapping (address => uint256))) private _escrow;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BANKER_ROLE = keccak256("BANKER_ROLE");
    bytes32 public constant NOTARY_ROLE = keccak256("NOTARY_ROLE");

    constructor (
        string memory name,
        string memory symbol,
        address initialAccount,
        uint256 initialBalance,
        uint8 decimals
    ) public payable ERC20(name, symbol) {
        _setupDecimals(decimals);
        _mint(initialAccount, initialBalance);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(BANKER_ROLE, _msgSender());
        _setupRole(NOTARY_ROLE, _msgSender());
    }

/********************************************************************************
***
*** PLEDGING FUNCTIONS
***
*********************************************************************************/

    /**
     * @dev Returns the amount of tokens pledged by `account`.
     */
    function totalCredits(address account) external view returns (uint256) {
        return _totalcredits[account];
    }

    /**
     * @dev Returns the amount of not-pledged tokens owned by `account`.
     */
    function netBalanceOf(address account) external view returns (uint256) {
        return balanceOf(account).sub(_totalcredits[account]);
    }

    /**
     * @dev Returns the amount of tokens pledged by `sender` over `recipient`.
     */
    function creditsOver(address sender, address recipient) external view returns (uint256) {
        return _credits[sender][recipient];
    }

    /**
     * @dev Atomically increases the credit granted to `spender` by the caller.
     *
     * Emits a {Pledge} event indicating the updated credit.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseCredit(address spender, uint256 addedValue) public virtual returns (bool) {
        _totalcredit(_msgSender(), _totalcredits[_msgSender()].add(addedValue));
        _pledge(_msgSender(), spender, _credits[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the credit granted to `spender` by the caller.
     *
     * Emits a {Pledge} event indicating the updated credit.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least `subtractedValue`.
     */
    function decreaseCredit(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _totalcredit(_msgSender(), _totalcredits[_msgSender()].sub(subtractedValue, "ERC20: decreased credit below zero"));
        _pledge(_msgSender(), spender, _credits[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased credit below zero"));
        return true;
    }

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * credits mechanism. `amount` is then deducted from the caller's
     * credit.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} and a {Pledge} event.
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have credit for ``sender``'s tokens of at least `amount`.
     *
     * - reserved to `NOTARY_ROLE`.
     */
    function accreditFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        require(hasRole(NOTARY_ROLE, _msgSender()), "ERC20 approve: must have notary role to approve spending of others' tokens");
        _transfer(sender, recipient, amount);
        _totalcredit(sender, _totalcredits[sender].sub(amount, "ERC20: transfer amount exceeds credits"));
        _pledge(sender, recipient, _credits[sender][recipient].sub(amount, "ERC20: transfer amount exceeds credits"));
        return true;
    }

    /**
     * @dev Withdraw of the `amount` from the credit granted to `spender` by the `owner`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Pledge} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have credit for the caller of at least `amount`.
     *
     * - reserved to `NOTARY_ROLE`.
    */
    function withdrawCredit(address owner, address spender, uint256 amount) public virtual returns (bool) {
        require(hasRole(NOTARY_ROLE, _msgSender()), "ERC20 approve: must have notary role to approve spending of others' tokens");
        _totalcredit(owner, _totalcredits[owner].sub(amount, "ERC20: decreased credit below zero"));
        _pledge(owner, spender, _credits[owner][spender].sub(amount, "ERC20: decreased credit below zero"));
        return true;
    }

    /**
     * @dev Sets `amount` as the total credit of `spender` over other accounts' tokens.
     *
     * This is internal function.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `amount` cannot be more than balance.
     */
    function _totalcredit(address owner, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: pledge from the zero address");
        require(amount <= balanceOf(owner), "ERC20: amount exceeds balance");

        _totalcredits[owner] = amount;
    }

    /**
     * @dev Sets `amount` as the credit of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `pledge`, and can be used to
     * e.g. set automatic credits for certain subsystems, etc.
     *
     * Emits a {Pledge} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _pledge(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: pledge from the zero address");
        require(spender != address(0), "ERC20: pledge to the zero address");

        _credits[owner][spender] = amount;
        emit Pledge(owner, spender, amount);
    }

    /**
     * @dev Emitted when the credit of a `spender` for an `owner` is set by
     * a call to {pledge}. `value` is the new credit.
     */
    event Pledge(address indexed owner, address indexed spender, uint256 value);

/********************************************************************************
***
*** MINTING FUNCTIONS
***
*********************************************************************************/

    /**
     * @dev Creates `amount` new tokens for `account`.
     *
     * - reserved to `MINTER_ROLE`.
     */
    function mint(address account, uint256 amount) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20 mint: must have minter role to mint");
        _mint(account, amount);
    }

/********************************************************************************
***
*** FORCE TRANSFER FUNCTIONS
***
*********************************************************************************/

    /**
     * @dev Force moves `value` tokens from the ``from``'s account to ``to``'s account.
     *
     * - reserved to `BANKER_ROLE`.
     */
    function transferInternal(address from, address to, uint256 value) public {
        require(hasRole(BANKER_ROLE, _msgSender()), "ERC20 transfer: must have banker role to transfer others' tokens");
        _transfer(from, to, value);
    }

    /**
     * @dev Destroys `amount` tokens from the ``account``'s account.
     *
     * - reserved to `BANKER_ROLE`.
     */
    function burnInternal(address account, uint256 amount) public {
        require(hasRole(BANKER_ROLE, _msgSender()), "ERC20 burn: must have banker role to burn others' tokens");
        _burn(account, amount);
    }

    /**
     * @dev Force sets `value` as the allowance of `spender` over the ``owner``'s tokens.
     *
     * - reserved to `BANKER_ROLE`.
     */
    function approveInternal(address owner, address spender, uint256 value) public {
        require(hasRole(BANKER_ROLE, _msgSender()), "ERC20 approve: must have banker role to approve spending of others' tokens");
        _approve(owner, spender, value);
    }

    /**
     * @dev Atomically force increases the credit granted to `spender` by the `owner`.
     *
     * Emits a {Pledge} event indicating the updated credit.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     *
     * - reserved to `BANKER_ROLE`.
     */
    function increaseCreditInternal(address owner, address spender, uint256 addedValue) public virtual returns (bool) {
        require(hasRole(BANKER_ROLE, _msgSender()), "ERC20 approve: must have banker role to approve spending of others' tokens");
        _totalcredit(owner, _totalcredits[owner].add(addedValue));
        _pledge(owner, spender, _credits[owner][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically force decreases the credit granted to `spender` by the `owner`.
     *
     * Emits a {Pledge} event indicating the updated credit.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have credit for the caller of at least `subtractedValue`.
     *
     * - reserved to `BANKER_ROLE`.
     */
    function decreaseCreditInternal(address owner, address spender, uint256 subtractedValue) public virtual returns (bool) {
        require(hasRole(BANKER_ROLE, _msgSender()), "ERC20 approve: must have banker role to approve spending of others' tokens");
        _totalcredit(owner, _totalcredits[owner].sub(subtractedValue, "ERC20: decreased credit below zero"));
        _pledge(owner, spender, _credits[owner][spender].sub(subtractedValue, "ERC20: decreased credit below zero"));
        return true;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20) {
        super._beforeTokenTransfer(from, to, amount);

        // check if the sender of the transction (otherwise the case of mining new tokens) has enough unpledged tokens
        require(from == address(0) || balanceOf(from).sub(_totalcredits[from]) >= amount, "ERC20 credit: transfer amount exceeds net balance");
    }

/********************************************************************************
***
*** ESCROW WALLETS FUNCTIONS
***
*********************************************************************************/

    /**
     * @dev Returns the total amount of tokens locked in all escrow wallets (stored into the smart contract).
     */
    function totalLockedAmount() public view virtual returns (uint256) {
        return balanceOf(address(this));
    }

    /**
     * @dev Returns the remaining number of tokens that `sender` gave to
     * the `receiver` for `project` and that are locked in escrow. This is
     * zero by default.
     */
    function amountInEscrow(string memory project, address sender, address receiver) public view virtual returns (uint256) {
        return _escrow[_getProjectID(project)][sender][receiver];
    }

    /**
     * @dev Returns the upper limit for number of tokens of the escrow for `project`.
     * This is zero by default.
     */
    function capOfEscrow(string memory project) public view virtual returns (uint256) {
        return _escrowcap[_getProjectID(project)];
    }

    /**
     * @dev Set the upper limit for number of tokens of the escrow for `project`.
     */
    function setCapOfEscrow(string memory project, uint256 limit) public virtual returns (bool) {
        require(hasRole(NOTARY_ROLE, _msgSender()), "ERC20 cap: must have notary role to set limit cap of escrow");
        _escrowcap[_getProjectID(project)] = limit;
        return true;
    }

    /**
     * @dev Returns the state active/unactive of the upper limit for number of tokens of the escrow
     * for `project`. This is false by default.
     */
    function capStateOfEscrow(string memory project) public view virtual returns (bool) {
        return _escrowcapactive[_getProjectID(project)];
    }

    /**
     * @dev Set as active the state of the upper limit for number of tokens of the escrow for `project`.
     */
    function activateCapOfEscrow(string memory project) public virtual returns (bool) {
        require(hasRole(NOTARY_ROLE, _msgSender()), "ERC20 cap: must have notary role to activate cap of escrow");
        _escrowcapactive[_getProjectID(project)] = true;
        return true;
    }

    /**
     * @dev Set as unactive the state of the upper limit for number of tokens of the escrow for `project`.
     */
    function deactivateCapOfEscrow(string memory project) public virtual returns (bool) {
        require(hasRole(NOTARY_ROLE, _msgSender()), "ERC20 cap: must have notary role to deactivate cap of escrow");
        _escrowcapactive[_getProjectID(project)] = false;
        return true;
    }

    /**
     * @dev Returns the total number of tokens that are locked in escrow for `project`.
     */
    function totalAmountInEscrow(string memory project) public view virtual returns (uint256) {
        return _escrowtotal[_getProjectID(project)];
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to escrow wallet of the `project` for the `receiver`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {LockedInEscrow} event.
     *
     * Requirements:
     *
     * - the caller cannot be the zero address.
     * - `receiver` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transferToEscrow(string memory project, address receiver, uint256 amount) public virtual returns (bool) {
        _transfer(_msgSender(), address(this), amount);
        _escrowtotal[_getProjectID(project)] = _escrowtotal[_getProjectID(project)].add(amount);
        _lock(project, _msgSender(), receiver, _escrow[_getProjectID(project)][_msgSender()][receiver].add(amount));
        return true;
    }

    /**
     * @dev Moves back `amount` tokens to the caller's account from escrow wallet of the `project` for the `receiver`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {LockedInEscrow} event.
     *
     * Requirements:
     *
     * - the caller cannot be the zero address.
     * - `receiver` cannot be the zero address.
     * - the caller must have a quantity of locked token at least `amount`.
     */
    function withdrawFromEscrow(string memory project, address receiver, uint256 amount) public virtual returns (bool) {
        _transfer(address(this), _msgSender(), amount);
        _escrowtotal[_getProjectID(project)] = _escrowtotal[_getProjectID(project)].sub(amount);
        _lock(project, _msgSender(), receiver, _escrow[_getProjectID(project)][_msgSender()][receiver].sub(amount, "ERC20: transfer amount exceeds locked fund"));
        return true;
    }

    /**
     * @dev Moves ``sender``'s `amount` tokens from the escrow wallet of the `project` to the ``receiver``'s account.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {LockedInEscrow} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `receiver` cannot be the zero address.
     * - `sender` must have a quantity of locked token at least `amount`.
     */
    function transferFromEscrow(string memory project, address sender, address receiver, uint256 amount) public virtual returns (bool) {
        require(hasRole(NOTARY_ROLE, _msgSender()), "ERC20 transfer: must have notary role to unlock others' tokens from escrow");
        _transfer(address(this), receiver, amount);
        _escrowtotal[_getProjectID(project)] = _escrowtotal[_getProjectID(project)].sub(amount);
        _lock(project, sender, receiver, _escrow[_getProjectID(project)][sender][receiver].sub(amount, "ERC20: transfer amount exceeds locked fund"));
        return true;
    }

    /**
     * @dev Force moves ``sender``'s `amount` tokens to escrow wallet of the `project` for the `receiver`.
     *
     * Emits a {LockedInEscrow} event.
     *
     * - reserved to account with `BANKER_ROLE` AND `NOTARY_ROLE`.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `receiver` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function transferToEscrowInternal(string memory project, address sender, address receiver, uint256 amount) public {
        require(hasRole(BANKER_ROLE, _msgSender()), "ERC20 transfer: must have banker role to lock others' tokens into escrow");
        require(hasRole(NOTARY_ROLE, _msgSender()), "ERC20 transfer: must have notary role to lock others' tokens into escrow");
        _transfer(sender, address(this), amount);
        _escrowtotal[_getProjectID(project)] = _escrowtotal[_getProjectID(project)].add(amount);
        _lock(project, sender, receiver, _escrow[_getProjectID(project)][sender][receiver].add(amount));
    }

    /**
     * @dev Force moves back `amount` tokens to the ``sender``'s account from escrow wallet of the `project` for the `receiver`.
     *
     * Emits a {LockedInEscrow} event.
     *
     * - reserved to account with `BANKER_ROLE` AND `NOTARY_ROLE`.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `receiver` cannot be the zero address.
     * - `sender` must have a quantity of locked token at least `amount`.
     */
    function withdrawFromEscrowInternal(string memory project, address sender, address receiver, uint256 amount) public {
        require(hasRole(BANKER_ROLE, _msgSender()), "ERC20 transfer: must have banker role to unlock others' tokens from escrow");
        require(hasRole(NOTARY_ROLE, _msgSender()), "ERC20 transfer: must have notary role to unlock others' tokens from escrow");
        _transfer(address(this), sender, amount);
        _escrowtotal[_getProjectID(project)] = _escrowtotal[_getProjectID(project)].sub(amount);
        _lock(project, sender, receiver, _escrow[_getProjectID(project)][sender][receiver].sub(amount, "ERC20: transfer amount exceeds locked fund"));
    }

    /**
     * @dev Sets `amount` as the quantity of tokens that `sender` is giving to the `receiver` for the `project`.
     *
     * Emits an {LockedInEscrow} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `receiver` cannot be the zero address.
     */
    function _lock(string memory project, address sender, address receiver, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: lock from the zero address");
        require(receiver != address(0), "ERC20: lock to the zero address");
        require(!_escrowcapactive[_getProjectID(project)] || amount <= _escrowcap[_getProjectID(project)], "ERC20: lock amount exceeds the Escrow cap limit");

        _escrow[_getProjectID(project)][sender][receiver] = amount;
        emit LockedInEscrow(project, sender, receiver, amount);
    }

    /**
     * @dev Returns byte32 value (used as ID) of a `projectName`.
     */
    function _getProjectID(string memory projectName) internal pure virtual returns (bytes32) {
        return keccak256(abi.encodePacked(projectName));
    }

    /**
     * @dev Emitted when a `value` for `project` is locked/unlocked by `sender` in favour of `receiver`.
     */
    event LockedInEscrow(string indexed project, address indexed sender, address indexed receiver, uint256 value);
}