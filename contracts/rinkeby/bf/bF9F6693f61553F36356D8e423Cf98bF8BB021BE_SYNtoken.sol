/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.13;



// Part: OpenZeppelin/[email protected]/Context

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

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: OpenZeppelin/[email protected]/IERC20Metadata

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

// Part: OpenZeppelin/[email protected]/ERC20

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

// File: SYNtoken.sol

//import "@openzeppelin/contracts/token/ERC777/ERC777.sol";

contract SYNtoken is ERC20 {
    address[] public owner;
    address[] public operators;
    mapping(address => bool) whitelistedAddresses;
    address[] whitelistedAddressArray;
    address public masterContract;
    mapping(address => uint256) companyLedger;

    constructor(uint256 initialSupply) ERC20("PulseOPS10", "Ops10") {
        _mint(msg.sender, initialSupply);
        // setting the master contract to which all coins will be vested to.
        masterContract = 0xF58e051086B71314950e1a6f4100081B9c3DFC8d;
        owner.push(msg.sender);
        owner.push(masterContract);
        // debating whether it makes sense to set the master contract as an operator or does that make the mastercontract the central point of failure.
        operators.push(owner[0]);
        //intializing the companyLedger with the contract.
        companyLedger[msg.sender] = initialSupply;
    }

    // These two functions exist but will both be depracated as the "isInArray" does their job
    // These could be usefull to increase readablity of the code.
    function isOperator(address pretentious_address) private returns (bool) {
        for (uint256 i = 0; i < operators.length; i++) {
            if (operators[i] == pretentious_address) {
                return true;
            }
        }
        return false;
    }

    function isOwner(address pretentious_address) private returns (bool) {
        for (uint256 i = 0; i < owner.length; i++) {
            if (owner[i] == pretentious_address) {
                return true;
            }
        }
        return false;
    }

    function isInArray(
        address address_to_check,
        address[] memory array_WeWant_ToCheck
    ) private view returns (bool) {
        for (uint256 x = 0; x < array_WeWant_ToCheck.length; x++) {
            if (array_WeWant_ToCheck[x] == address_to_check) {
                return true;
            }
        }
        return false;
    }

    // this function has to look through an array of addresses and find the index of a desired element.
    // how can we handle the times it cant find the element ?
    function returnIndex(address toFind, address[] memory arrayToLookInto)
        private
        returns (uint256)
    {
        for (uint256 i = 0; i < arrayToLookInto.length; i++) {
            if (arrayToLookInto[i] == toFind) {
                return i;
            }
        }
    }

    modifier onlyOperator() {
        require(
            isInArray(msg.sender, operators),
            "Only operators or owners can perform this action !"
        );
        _;
    }

    modifier onlyOwner() {
        require(
            isInArray(msg.sender, owner),
            "Only the owner can perform this action !"
        );
        _;
    }

    modifier onlyMaster() {
        require(
            msg.sender == masterContract,
            "Only the master contract can perform this action ! "
        );
        _;
    }

    // make sure it checks if the operator already exists.
    function setOperators(address operator_to_add)
        public
        onlyOwner
        returns (bool)
    {
        for (uint256 i = 0; i < operators.length; i++) {
            if (operators[i] == operator_to_add) {
                //Have to find a way to print in solidity, maybe using events.
                //print("The operator already exists");
                return true;
            }
        }
        operators.push(operator_to_add);
        return true;
    }

    // a way to delete operators that should no longer have those priviledges, the number of operators should not be expected to be more that the number of employees hired.
    function removeOperators(address[] memory operator_to_remove)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < operator_to_remove.length; i++) {
            // the returnIndex wont return a number if it does not find an index, the require is supposed to thrown an error
            require(
                returnIndex(operator_to_remove[i], operators) <= 10000,
                "Sorry, could not find the index of the address you are tyring to remove"
            );
            delete operators[i];
        }
    }

    function getOperators() public view returns (address[] memory) {
        return operators;
    }

    /* overriding the base function and now users can only send funds to the owner of the contract.
       The idea is to also track using the companyLedger the transactions that the whitelisted users can perform. 
    */
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        if (!isOwner(msg.sender)) {
            require(
                isOwner(to),
                "The overlords own these coins. You can not send funds elsewhere !"
            );
        }
        // make sure the first member of the owner array is always the address of the contract.
        _transfer(owner[0], to, amount);
        companyLedger[to] += amount;
        companyLedger[msg.sender] -= amount;
        return true;
    }

    /* limiting this function to sending to only the owner when it is a user that wants to use the function. 
   It is forseeable that further restrictions would be necessary; even the master and owner should only be 
   able to send funds to the master contract
*/
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        if (!isOwner(msg.sender) || !(msg.sender == masterContract)) {
            require(
                isOwner(to),
                "The overlords own these coins. You can not send funds elsewhere !"
            );
        }
        address spender = _msgSender();
        // _spendAllowance(from, spender, amount); if this comment is still here then I still have to look into this function.
        _transfer(from, to, amount);
        /* if the person calling the function is neither the contract owner nor the master vault 
        then the companyLedger has to be updated by increasing the receivers balance and 
         decreasing the spenders balance. 
        If it is the 
        */
        if (!isOwner(msg.sender) || !(msg.sender == masterContract)) {
            companyLedger[to] += amount;
            companyLedger[from] -= amount;
        } else {
            companyLedger[to] += amount;
            companyLedger[from] -= amount;
        }

        return true;
    }

    // airdrop aka batch transfers should only be available to the contract owners. Amount to send has to be the same and has to be an integer.
    // airdropping should also only be possible to whitelisted addresses.
    function sendTokensToMultipleAdresses(
        address[] memory listOfAddresses_ToSend_To,
        uint256 amountToSend
    ) public onlyOperator {
        for (uint256 z = 0; z < listOfAddresses_ToSend_To.length; z++) {
            transfer(listOfAddresses_ToSend_To[z], amountToSend);
        }
    }

    // adds users to whitelist and keeps track in an array and dictionary which users are whitelisted
    // the array is necessary as staff want a getter function to find out which users are allready whitelisted without spending gas every time to do so

    function whitelistUsers(address[] memory arr) public onlyOperator {
        for (uint256 i = 0; i < arr.length; i++) {
            whitelistedAddresses[arr[i]] = true; //only owner can whitelist address
            whitelistedAddressArray.push(arr[i]);
        }
    }

    // here 1000 is used because we do not expect there to be more than 1000 entries, as there are less than 1000 employees currently.
    function removeFromWhitelist(address[] memory usersToRemove)
        public
        onlyOperator
    {
        for (uint256 i = 0; i < usersToRemove.length; i++) {
            require(
                returnIndex(usersToRemove[i], whitelistedAddressArray) <= 10000,
                "Sorry, could not find the index of the address you are tyring to remove"
            );
            delete whitelistedAddressArray[
                returnIndex(usersToRemove[i], whitelistedAddressArray)
            ];
            delete whitelistedAddresses[usersToRemove[i]];
        }
    }

    function getListOf_WhitelistedAddresses()
        public
        view
        returns (address[] memory)
    {
        return whitelistedAddressArray;
    }

    function verifyUser(address _whitelistedAddress)
        public
        view
        returns (bool)
    {
        return whitelistedAddresses[_whitelistedAddress];
    }

    // in order to check a batch of users to and return an array of non verified addresses
    // check whitelisted users might be more appropriate
    // find a way to make this public view
    function Check_Verified_Users(address[] memory listOfAddresses)
        public
        view
        returns (string memory)
    {
        for (uint256 y = 0; y < listOfAddresses.length; y++) {
            require(
                verifyUser(listOfAddresses[y]),
                string(
                    abi.encodePacked(
                        "The following position of address is not whitelisted, ",
                        "This function is not fully functional yet. "
                    )
                )
            );
        }
        return ("All addresses are verified ! ");
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /* because only whitelisted addresses can have the token by design. We will take all the tokens from the whitelisted addresses 
    and send them to the master contract. 
    But since it is impossible for the contract to know how many tokens an user has. We will have to keep track of how many tokens
    are sent out to each address in the transfer functions. 
    And then we transfer then rest from the owner contract to masterContract
    */
    function vestAllTokens() public onlyMaster {
        for (uint256 i = 0; i < whitelistedAddressArray.length; i++) {
            transferFrom(
                whitelistedAddressArray[i],
                masterContract,
                companyLedger[whitelistedAddressArray[i]]
            );
        transfer(masterContract, companyLedger[owner[0]]);
        }
    }
}