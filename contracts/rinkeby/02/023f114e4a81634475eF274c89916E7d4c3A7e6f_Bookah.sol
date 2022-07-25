/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

// SPDX-License-Identifier: MIT
// File: IBookah.sol

/**

$$$$$$$\                                          $$$$$$$$\ $$\                           
$$  __$$\                                         $$  _____|$$ |                          
$$ |  $$ | $$$$$$\   $$$$$$\   $$$$$$\  $$\   $$\ $$ |      $$$$$$$\   $$$$$$\  $$$$$$$\  
$$$$$$$  |$$  __$$\ $$  __$$\ $$  __$$\ $$ |  $$ |$$$$$\    $$  __$$\ $$  __$$\ $$  __$$\ 
$$  ____/ $$$$$$$$ |$$ /  $$ |$$ /  $$ |$$ |  $$ |$$  __|   $$ |  $$ |$$$$$$$$ |$$ |  $$ |
$$ |      $$   ____|$$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |      $$ |  $$ |$$   ____|$$ |  $$ |
$$ |      \$$$$$$$\ $$$$$$$  |$$$$$$$  |\$$$$$$$ |$$$$$$$$\ $$$$$$$  |\$$$$$$$\ $$ |  $$ |
\__|       \_______|$$  ____/ $$  ____/  \____$$ |\________|\_______/  \_______|\__|  \__|
                    $$ |      $$ |      $$\   $$ |                                        
                    $$ |      $$ |      \$$$$$$  |                                        
                    \__|      \__|       \______/                                         
                                                                            
**/

pragma solidity >=0.4.22 <0.9.0;

interface IBookah {
  
  event SupportedTokenUpdated(
    uint dateUpdated,
    address indexed tokenAddress
  );
  
  event BookingFeeUpdated(
    uint dateUpdated,
    uint newFee
  );

  event CreatedTicket(
    uint price,
    uint ticketId,
    address sellerAddress
  );
  
  event BoughtTicket(
    uint dateBought,
    uint id,
    uint noOfTicketsBought,
    address indexed sellerAddress,
    address indexed buyerAddress
  );

  event Withdrawal(
    uint dateWithdrawn,
    uint amount,
    address user
  );

  event TicketMetadataEdited(
    uint dateEdited,
    address seller
  );
  
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: Bookah.sol


pragma solidity >=0.4.22 <0.9.0;





contract Bookah is Ownable, IBookah, ReentrancyGuard {

  address public supportedToken;
  uint private _factor_;
  uint public bookingFee;
  
  constructor() {
    _factor_ = 100000;
    setBookingFee(2);
  }

  struct Ticket {
    uint id;
    uint price;
    uint noAvailable;
    uint dateCreated;
    bytes metadata;
    address seller;
  }

  struct User {
    string username;
    uint balance;
    uint noOfTicketsCreated;
    bytes userDetails;
    address userAddress;
  }

  struct Buyer {
    uint noOfTicketsBought;
    address buyer;
  }
  
  mapping (string => address) public usernames;
  mapping (address => string) public userAddresses;
  mapping (address => User) users;
  mapping (address => Ticket[]) tickets;
  mapping (address => mapping (uint => mapping( uint => Buyer ))) public buyerAddress;

  modifier onlyMember() { 
    require(
      users[msg.sender].userAddress != address(0),
      "No User Found"
    ); 
    _; 
  }
  
  modifier notMember(
    string memory _username
  ) { 
    require(
      users[msg.sender].userAddress == address(0),
      "Account Already Created"
    );
    require(
      usernames[_username] == address(0),
      "username Unavailable"
    );
    _; 
  }
  
  function setSupportedToken (address _tokenAddress) public onlyOwner {
    supportedToken = _tokenAddress;
    emit SupportedTokenUpdated(block.timestamp, _tokenAddress);
  }
  
  function setBookingFee (uint _newBookingFee) public onlyOwner {
    bookingFee = _newBookingFee;
    emit BookingFeeUpdated(block.timestamp, _newBookingFee);
  }

  function createUser (
    string memory _username,
    bytes memory _userDetails
  ) public notMember(_username) {

    require (
      getStringLength(_username) <= 15,
      "Length must be less/equal to 15"
    );

    // Check that there is no space in the username

    User memory _newUser = User({
      username: _username,
      balance: 0,
      noOfTicketsCreated: 0,
      userDetails: _userDetails,
      userAddress: msg.sender
    });

    users[msg.sender] = _newUser;
    usernames[_username] = msg.sender;
    userAddresses[msg.sender] = _username;
  }

  function editUserDetails (bytes memory _newUserDetails) public onlyMember {
    User memory _oldUser = users[msg.sender];

    User memory _newUser = User({
      username: _oldUser.username,
      balance: _oldUser.balance,
      noOfTicketsCreated: _oldUser.noOfTicketsCreated,
      userDetails: _newUserDetails,
      userAddress: _oldUser.userAddress
    });

    users[msg.sender] = _newUser;
  }
  
  function createTicket (
    uint _price,
    uint _noAvailable,
    bytes memory _metadata
  ) public onlyMember {
    require(
      (_price * _factor_) > 0,
      "Price Can't Be 0"
    );

    require(
      _noAvailable > 0,
      "Available Can't Be 0"
    );
    
    uint _noOfTickets = (tickets[msg.sender]).length;

    Ticket memory _newTicket = Ticket({
      id: _noOfTickets,
      price: (_price * _factor_),
      noAvailable: _noAvailable,
      dateCreated: block.timestamp,
      metadata: _metadata,
      seller: msg.sender
    });

    tickets[msg.sender].push(_newTicket);
    users[msg.sender].noOfTicketsCreated += 1;

    emit CreatedTicket(
      (_price * _factor_),
      _noOfTickets,
      msg.sender
    );
  }

  function editTicketMetadata (
    uint _ticketId,
    bytes memory _newTicketMetadata
  ) external onlyMember {
    require(
      tickets[msg.sender].length > _ticketId,
      "Invalid Ticket (doesn't exist)"
    );

    Ticket memory _oldTicket = tickets[msg.sender][_ticketId];

    Ticket memory _updatedTicket = Ticket({
      id: _oldTicket.id,
      price: _oldTicket.price,
      noAvailable: _oldTicket.noAvailable,
      dateCreated: _oldTicket.dateCreated,
      metadata: _newTicketMetadata,
      seller: _oldTicket.seller
    });

    tickets[msg.sender][_ticketId] = _updatedTicket;

    emit TicketMetadataEdited (
      block.timestamp, msg.sender
    );
  }

  function buyTicket (
    uint _ticketId,
    uint _noOfTicketsToBuy,
    address _ticketSeller
  ) external nonReentrant {
    require(
      tickets[_ticketSeller].length > _ticketId,
      "Invalid Ticket (doesn't exist)"
    );

    require(
      tickets[_ticketSeller][_ticketId].seller != msg.sender,
      "You can't buy your ticket"
    );

    uint _noOfSellerticketsAvailable = tickets[_ticketSeller][_ticketId].noAvailable;

    require(
      _noOfTicketsToBuy > 0,
      "Ticket must be more than 0"
    );
    
    require(
      _noOfSellerticketsAvailable >= _noOfTicketsToBuy,
      "Not Available Tickets"
    );

    uint _ticketPrice = (tickets[_ticketSeller][_ticketId].price * _noOfTicketsToBuy);

    require(
      ERC20(supportedToken).transferFrom(
        msg.sender,
        address(this),
        (
          getERCAmount(getTotalFee(_ticketPrice)) / _factor_
        )
      ) == true,
      "Failed to transfer Token"
    );

    users[_ticketSeller].balance += _ticketPrice;
    users[owner()].balance += _getTXFee(_ticketPrice);
    
    tickets[_ticketSeller][_ticketId].noAvailable -= _noOfTicketsToBuy;

    Buyer memory _newBuyer = Buyer({
      noOfTicketsBought: _noOfTicketsToBuy,
      buyer: msg.sender
    });

    require (
      buyerAddress[_ticketSeller][_ticketId][block.timestamp].buyer == address(0),
      "Retry Please"
    );

    buyerAddress[_ticketSeller][_ticketId][block.timestamp] = _newBuyer;

    emit BoughtTicket(
      block.timestamp,
      _ticketId,
      _noOfTicketsToBuy,
      _ticketSeller,
      msg.sender
    );
  }

  function withdraw () external nonReentrant onlyMember {
    uint _userBalance = users[msg.sender].balance;

    require(
      _userBalance > 0,
      "Nothing To Withdraw"
    );

    require(
      ERC20(supportedToken).transfer(
        msg.sender,
        (getERCAmount(_userBalance) / _factor_)
      ) == true, "Withdrawal failed"
    );

    users[msg.sender].balance = 0;

    require(
      users[msg.sender].balance == 0,
      "Error Occured On Blockchain"
    );

    emit Withdrawal(
      block.timestamp,
      _userBalance,
      msg.sender
    );
  }
  
  function getERCAmount(uint _price) internal view returns(uint) {
    return _price * (10 ** ERC20(supportedToken).decimals());
  }

  function getTickets (address _user) external view returns (Ticket[] memory) {
    return tickets[_user];
  }

  function getTicket (address _user, uint _ticketId) external view returns (Ticket memory) {
    return tickets[_user][_ticketId];
  }

  function getUser () external view returns(User memory) {
    return users[msg.sender];
  }

  function getTotalFee (uint _amount) public view returns (uint) {
    return (
      _getTXFee(_amount) + _amount
    );
  }
  
  function _getTXFee (uint _amount) private view returns (uint) {
    return (
      ((bookingFee * _amount) / 100)
    );
  }
  
  function getStringLength (string memory _s) private pure returns (uint) {
    bytes memory _b = bytes(_s);
    return _b.length;
  }
  
}