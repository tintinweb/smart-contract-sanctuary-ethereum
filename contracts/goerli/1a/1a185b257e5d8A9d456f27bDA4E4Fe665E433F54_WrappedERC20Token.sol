/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**===============================
 * ERC-20  T O K E N  E V E N T S
 * ===============================
 * @dev contains contract's events
 * `Transfer`
 * `Approval`
 * `OwnershipTransferred`
 * `Paused`
 * `UnPaused`
 */
abstract contract TokenEvents {
    /// @dev Emitted when `from` account sends tokens `to` another account
    /// @param from the current token owner
    /// @param to the token receiver
    /// @param value the transferred amount
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Emitted when the token `owner`
    /// appoints a `spender` of an `amount`
    /// @param owner the current token owner
    /// @param spender account allowed to spend
    /// @param value the allowed amount
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /// @dev Emitted wneh the contract's `previousOwner`
    /// calls the transferOwnership function
    /// @param previousOwner the current Owner
    /// @param newOwner the new owner
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @dev called by the contract owner
    /// to stop non owner interaction
    event Paused();

    /// @dev called by the contract owner
    /// to resume non owner interaction
    event UnPaused();
}

/**==================================
 * E R C-20 T O K E N  S T O R A G E
 * ==================================
 * @dev accumulates the contract storage
 * and storage related functionality
 * string public `name`
 * string public `symbol`
 * bool public `paused`
 * address public `owner`
 * uint256 private `_totalSupply`
 * mapping private `_balances`
 * mapping private `_allowances`
 */
contract TokenStorage is TokenEvents {
    /// Token's Full name
    string public name;
    /// Token's short name
    string public symbol;
    /// Flag, whether the contract is paused
    bool public paused;
    /// Contract's current owner
    address public owner;
    /// Total issued tokens
    uint256 private _totalSupply;

    /// HashMap {`tokenOwner` : `amount`}
    mapping(address => uint256) private _balances;
    /// Hashmap {`currentOwner` : {`spender` : `amount`}}
    mapping(address => mapping(address => uint256)) private _allowances;

    /// @param _name the Token Full Name
    /// @param _symbol the Token Short Name
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        paused = false;
        owner = msg.sender;
    }

    /// @dev `GETTER` of the alowed to spend amount
    /// @return `_allowances`[`_owner`][`spender`]
    function allowance(address _owner, address spender)
        public
        view
        virtual
        returns (uint256)
    {
        return _allowances[_owner][spender];
    }

    /// @dev `GETTER` of an account's balance
    /// @return `_balances`[`account`]
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /// @dev `GETTER` of the Token's decimal digits
    /// @return `18`
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /// @dev Public `GETTER` of the private value
    /// @return `_totalSupply`
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /// @dev `MOVES` `amount` `from` => `to`
    /// @param from the original token owner
    /// @param to the new token owner
    /// @param amount the transferred number of tokens
    /// `EMITS`: {`Transfer`} event
    /// REQUIREMENTS:
    /// `from` & `to` cannot be address zero
    /// `from` must have the amount to transfer
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
            // Overflow not possible: the sum of all balances
            // is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /// @dev `ADDS` `amount` of tokens to the `account`
    /// Increases the `_totalSupply`
    /// @param account the beneficiary of the new tokens
    /// @param amount the number of newly added tokens
    /// REQUIREMENTS:
    /// The `account` cannot be address zero.
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible:
            // balance + amount is at most totalSupply
            // + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /// @dev `REMOVES` the `amount` of tokens
    /// from the `account`, reducing the `_totalSupply`
    /// @param account the current tokens owner
    /// @param amount the number of removed tokens
    /// EMITS: a {`Transfer`} event
    /// REQUIREMENTS:
    /// `account` cannot be address zero
    /// `account` must have the `amount` of tokens for burning
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

    /// @dev `ALLOWS` the `spender` to manipulate with the `amount` of tokens
    /// belonging to the `owner`
    /// @param _owner the current tokens' owner
    /// @param spender the account allowed to manipulate tokens
    /// @param amount the number of tokens allowed for manipualtion
    /// EMITS: an {`Approval`} event
    /// REQUIREMENTS:
    /// The `owner` & `spender` cannot be address zero
    function _approve(
        address _owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    /// @dev UPDATES the `owner`'s allowance for the `spender`
    /// If the allowance is infinite, no update occurs
    /// If currentAllowance < amount, reverts
    /// EMITS: an {`Approval`} event in case of update
    function _spendAllowance(
        address _owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(_owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(_owner, spender, currentAllowance - amount);
            }
        }
    }

    /// @dev `GETTER` of the msg.sender
    /// @return `msg.sender`
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    /// @dev `GETTER` of the msg.data
    /// @return `msg.data`
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /// @dev HOOK called before tokens transfer
    /// @param from the current token owner
    /// @param to the new token owner
    /// @param amount the number of newly added tokens
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /// @dev HOOK called after tokens transfer
    /// @param from the current token owner
    /// @param to the new token owner
    /// @param amount the number of newly added tokens
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

/**===========================================
 *       T O K E N   S E C U R I T Y
 * ===========================================
 * @dev concentrates security related logic
 * modifier `onlyOwner`
 * modifier `onlyUnpaused`
 * function `pause`
 * function `unPause`
 * function `transferOwnership`
 */
abstract contract TokenSecurity is TokenStorage {
    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorised function call");
        _;
    }

    modifier onlyUnpaused() {
        require(!paused, "The contract is under maintainance...");
        _;
    }

    constructor() {}

    function pause() public onlyOwner {
        paused = true;
        emit Paused();
    }

    function unPause() public onlyOwner {
        paused = false;
        emit UnPaused();
    }

    /// @dev `MOVES` contract ownership to the `newOwner`
    /// Called only by the current `owner`
    /// @param newOwner ownership recipient
    /// EMITS: an {`OwnershipTransferred`} event
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /// @dev `MOVES` contract ownership to the `newOwner`
    /// @param newOwner ownership recipient
    /// EMITS: an {`OwnershipTransferred`} event
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/** ==================================================
 * The ledger of the wrapped ERC20 tokens
 * ==================================================
 * function mint
 * function burnFrom
 * function transfer
 * function approve
 * function transferFrom
 * function increaseAllowance
 * function decreaseAllowance
 */
contract WrappedERC20Token is TokenSecurity {
    /// @custom:oz-upgrades-unsafe-allow constructor
    /// @param _name the token name
    /// @param _symbol the token ticker
    constructor(string memory _name, string memory _symbol)
        TokenStorage(_name, _symbol)
    {}

    /// Mints wrapped tokens locally
    /// @dev Implemented in OpenZeppelin ERC20Mintable
    /// @param to the address of the new token owner
    /// @param amount the number of tokens to be minted
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /// @dev `MOVES` `amount` from the current owner => `to`
    /// @param to the new token owner
    /// @param amount the transferred number of tokens
    /// `EMITS`: {`Transfer`} event
    /// REQUIREMENTS:
    /// `from` & `to` cannot be address zero
    /// `from` must have the amount to transfer
    function transfer(address to, uint256 amount)
        public
        virtual
        onlyUnpaused
        returns (bool)
    {
        address from = _msgSender();
        _transfer(from, to, amount);
        return true;
    }

    /// @dev `ALLOWS` the `spender` to manipulate with the `amount` of tokens
    /// belonging to the `owner`
    /// @param spender the account allowed to manipulate tokens
    /// @param amount the number of tokens allowed for manipualtion
    /// EMITS: an {`Approval`} event
    /// REQUIREMENTS:
    /// The `owner` & `spender` cannot be address zero
    /// Must be called by the current tokens owner
    function approve(address spender, uint256 amount)
        public
        virtual
        onlyUnpaused
        returns (bool)
    {
        address from = _msgSender();
        _approve(from, spender, amount);
        return true;
    }

    /// @dev See {IERC20-transferFrom}.
    /// @param from the current tokens owner
    /// @param to the new token owner
    /// @param amount the transferred number of tokens
    /// Emits an {Approval} event indicating the updated allowance.
    /// NOTE: Does not update the allowance if the current allowance
    /// is the maximum `uint256`.
    /// REQUIREMENTS:
    /// `from` and `to` cannot be the zero address.
    /// `from` must have a balance of at least `amount`.
    /// the caller must have allowance for tokens of at least`amount`.
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual onlyUnpaused returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /// @dev Atomically increases the allowance granted to `spender` by the caller.
    /// Emits an {`Approval`} event indicating the updated allowance.
    /// REQUIREMENTS:
    ///`spender` cannot be the zero address.
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        onlyUnpaused
        returns (bool)
    {
        address from = _msgSender();
        _approve(from, spender, allowance(from, spender) + addedValue);
        return true;
    }

    /// @dev Atomically decreases the allowance granted to `spender` by the caller.
    /// @param spender the account allowed to manipulate tokens of the caller
    /// @param subtractedValue the amount of reduced allowance
    /// Emits an {Approval} event indicating the updated allowance.
    /// REQUIREMENTS:
    /// `spender` cannot be the zero address.
    /// `spender` must have allowance for the caller of at least `subtractedValue`
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        onlyUnpaused
        returns (bool)
    {
        address from = _msgSender();
        uint256 currentAllowance = allowance(from, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(from, spender, currentAllowance - subtractedValue);
        }

        return true;
    }
}