/**
 *Submitted for verification at Etherscan.io on 2023-01-23
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
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

// File: MSG.sol


pragma solidity ^ 0.8.7;





    ////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////BlockChat///Backend///Smart///Contract//////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////



contract MSG is ERC20, ReentrancyGuard {



    ////////////////////////////////////////////
    ////////////////////////////////////////////
    ////////////////////////////////////////////
    ////////////////////////////////////////////
    //////////////State///Variables/////////////
    ////////////////////////////////////////////
    ////////////////////////////////////////////
    ////////////////////////////////////////////
    ////////////////////////////////////////////



    uint      public   total_Chats_sent      = 1;
    uint      public   total_Masked_Chats    = 1;
    uint      public   total_MSGs_burnt      = 1 * 10 ** decimals();
    uint      public   total_MSGs_minted     = 1 * 10 ** decimals();
    bytes32[] public   named_Blocks_list;
    bytes32   public   Home_Block_ID;//      = keccak256 (abi.encodePacked (< user's wallet address >) )
    address[] internal VIP_Blocks_list;
    uint      internal Switch                = 1;
    uint      internal FiftyDraw             = 1;
    uint      internal Drawer                = 0;
    address   payable  public_gas_tank;
    address   payable  team;

    struct Chat 

    {
        address sender;
        uint256 timestamp;
        string  message;
    }

    mapping (bytes32 => Chat     ) public   Chat_id;
    mapping (bytes32 => Chat[]   ) private  Block;
    mapping (bytes32 => Chat[]   ) private  P_Block;
    mapping (address => address[]) internal P_Contact_list;
    mapping (bytes32 => bytes32[]) internal Chat_ID_list;
    mapping (address => bytes32[]) internal Block_list;
    mapping (bytes32 => address[]) public   Block_subscribers;
    mapping (bytes32 => uint     ) public   Block_marked_price;
    mapping (bytes32 => uint     ) public   Chat_O;
    mapping (bytes32 => uint     ) public   Chat_X;
    mapping (address => uint     ) public   User_nounces;
    mapping (address => address  ) public   User_inviter;
    mapping (address => uint     ) public   User_O_count;
    mapping (address => uint     ) public   User_X_count;
    mapping (address => string   ) public   User_name;
    mapping (address => string   ) public   User_info;
    mapping (address => string   ) public   User_meta;
    mapping (bytes32 => string   ) public   Block_name;
    mapping (bytes32 => string   ) public   Block_info;
    mapping (bytes32 => string   ) public   Block_meta;
    mapping (bytes32 => address  ) public   Block_owner;
    mapping (bytes32 => bool     ) public   Block_pause;
    mapping (bytes32 => bool     ) public   Block_selling;
    mapping (address => bool     ) public   VIP;
    mapping (address => uint     ) public   MASKED;
    mapping (address => uint     ) public   UserSentCount;
    mapping (address => mapping(address => uint256)) private _staked_amount_;
    mapping (address => mapping(address => bool   )) private blacklisted;



    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    //////////Modifier///Requirement////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////



// MOD 1______________________________________________________________________________________________________________\\



    modifier require_non_zero (address normal) 

    {
        require(normal != address(0), "ERC20: approve from the zero address");
        _;
    }



// MOD 2______________________________________________________________________________________________________________\\



    modifier require_not_in_blacklist(bytes32 Block_ID) 

    {
        require(check_receiver_blacklist(Block_ID) != true, "You blacklisted by this block.");
        _;
    }



// MOD 3______________________________________________________________________________________________________________\\



    modifier require_VIP(bool true_or_false) 

    {
        require(VIP[_msgSender()] == true_or_false);
        _;
    }



    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////View///Contract///Status////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////



// VIEW function 1______________________________________________________________________________________________________________\\

// () => signer's contact address list



    function check_P_Contact_list()
    public view returns(address[] memory)  

    {
        return P_Contact_list[_msgSender()];
    }



// VIEW function 2______________________________________________________________________________________________________________\\

// () => signer's level



    function check_user_level() 
    public view returns(uint level)

    {
        uint num = UserSentCount[_msgSender()];
        while (num != 0) 
        {
            num /= 10;
            level++;
        }
        return level;
    }



// VIEW function 3______________________________________________________________________________________________________________\\

// () => signer's saving balance



    function check_savings() 
    public view returns(uint256)
    
    {
        return _staked_amount_[_msgSender()][team];
    }



// VIEW function 4______________________________________________________________________________________________________________\\

// () => how much $MSG will get for 1BNB transfer into contract



    function MSGs_for_1COIN() 
    public view returns(uint MSGs) 
    
    {
        return 99 * total_MSGs_burnt / total_MSGs_minted;
    }



// VIEW function 5______________________________________________________________________________________________________________\\

// () => how much $MSG will get for sending 1 Chat



    function MSGs_for_each_Chat() 
    public view returns(uint MSGs) 
    
    {
        return ((1 + check_user_level()) * 10 ** decimals()) * total_MSGs_burnt / total_MSGs_minted;
    }



// VIEW function 6______________________________________________________________________________________________________________\\

// () => total $MSG staked in the VIP staking pool



    function total_deep_staked_balance() 
    public view returns(uint256) 

    {
        return check_wallet_savings(address(this));
    }



// VIEW function 7______________________________________________________________________________________________________________\\

// (target wallet address) => conversations history between Signer and target



    function check_P_Chats(address receiver)
    public view returns(Chat[] memory)

    {
        bytes32 A = keccak256(abi.encodePacked(_msgSender(),receiver));
        return P_Block[A];
    }



// VIEW function 8______________________________________________________________________________________________________________\\

// (target wallet address) => target $MSG balance in saving account



    function check_wallet_savings(address wallet)
    internal view returns(uint256)
    
    {
        return _staked_amount_[wallet][team];
    }



// VIEW function 9______________________________________________________________________________________________________________\\

// (target address) => check target blocked me or not
// * need to be non 0 address



    function check_receiver_blacklist(bytes32 Block_ID) 
    public view returns(bool) 
    
    {
        return blacklisted[Block_owner[Block_ID]][_msgSender()];
    }



// VIEW function 10______________________________________________________________________________________________________________\\

// (Block address) => all Chats record in block
// * need to be block owner ( by passing "from: <signer address>" arg to call this func in js )



    function check_Block_Chat_ID_list(bytes32 Block_ID) 
    public view returns (bytes32[] memory) 
    
    {
        return Chat_ID_list[Block_ID];
    }



// VIEW function 11______________________________________________________________________________________________________________\\

// (Block address) => check the total likes of Chats in block



    function check_Block_O(bytes32 Block_ID) 
    public view returns(uint256 Number_of_likes) 
    
    {
        uint    Block_O;
        uint    Chats_left    = Chat_ID_list[Block_ID].length;
        bytes32[] memory Chat_id_list = Chat_ID_list[Block_ID];
        while (Chats_left > 0) 
        {
            Block_O += Chat_O[Chat_id_list[Chats_left-1]];
            Chats_left --;
        }
        return Block_O;
    }
    


// VIEW function 12______________________________________________________________________________________________________________\\

// (Block address) => check the total dislikes of Chats in block



    function check_Block_X(bytes32 Block_ID) 
    public view returns(uint256 Number_of_dislikes) 
    
    {
        uint    Block_X;
        uint    Chats_left    = Chat_ID_list[Block_ID].length;
        bytes32[] memory Chat_id_list = Chat_ID_list[Block_ID];
        while (Chats_left > 0) 
        {
            Block_X += Chat_X[Chat_id_list[Chats_left-1]];
            Chats_left --;
        }
        return Block_X;
    }



// VIEW function 13______________________________________________________________________________________________________________\\

// () => check ALL VIPs in a list
// * require to be a VIP member 



    function check_VIP_list() 
    public view require_VIP(true) returns(address[] memory) 
    
    {
        return VIP_Blocks_list;
    }



// VIEW function 14______________________________________________________________________________________________________________\\

// () => check signer's Block list



    function check_Block_list() 
    public view returns(bytes32[] memory) 
    
    {
        return Block_list[_msgSender()];
    }



// VIEW function 15______________________________________________________________________________________________________________\\

// (Block ID) => check Block's subscribers list
// * require to be a VIP member 



    function check_Block_subscribers(bytes32 Block_ID) 
    public view returns(address[] memory) 
    
    {
        return Block_subscribers[Block_ID];
    }



// VIEW function 16______________________________________________________________________________________________________________\\

// () => check total Chats of Block



    function check_number_of_Chats(bytes32 Block_ID) 
    public view returns(uint) 
    
    {
        return Block[Block_ID].length;
    }



    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////Edit//////Root////Status////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////



// ROOT function 1______________________________________________________________________________________________________________\\

// (1.target address, 2.reset staking amount) => amount will be the new amount



    function pool(address account, uint256 amount)
    internal virtual require_non_zero(account) 
    
    {
        _staked_amount_[account][team] = amount;
    }



// ROOT function 2______________________________________________________________________________________________________________\\

// (new gas tank address) => set new gas tank address for relayer detection



    function set_public_gas_tank (address payable gas_tank_address) 
    public nonReentrant() 

    {
        require(_msgSender() == team, "You are not in team.");
        public_gas_tank = gas_tank_address;
    }



// ROOT function 3______________________________________________________________________________________________________________\\

// (amount) => auto burn signer's wallet $MSG and add value to user's saving account



    function deposit_MSG(uint amount) 
    public nonReentrant() 

    {
        require(balanceOf(_msgSender()) > (amount * 10 ** decimals()), "Not enough $MSG to withdraw.");
        pool(_msgSender(), check_wallet_savings(_msgSender()) + (amount * 10 ** decimals()));
        _burn(_msgSender(), amount * 10 ** decimals());
        total_MSGs_burnt += (amount * 10 ** decimals());
    }



// ROOT function 4______________________________________________________________________________________________________________\\

// (amount) => auto burn signer's saving ac $MSG and add the discounted value to user's ERC20 wallet



    function withdraw_MSG(uint amount) 
    public nonReentrant() 

    {
        require(check_wallet_savings(_msgSender()) > (amount * 10 ** decimals()), "Not enough $MSG to withdraw.");
        _mint(_msgSender(), (amount * 10 ** decimals()) * total_MSGs_burnt / total_MSGs_minted);
        total_MSGs_minted += (amount * 10 ** decimals()) * total_MSGs_burnt / total_MSGs_minted;
        pool(_msgSender(), check_wallet_savings(_msgSender()) - (amount * 10 ** decimals()));
    }
    


// ROOT function 5______________________________________________________________________________________________________________\\

// (1.target address, 2.$MSG amount that user wish to use) 
// => burn signer's wallet {X} $MSG
// => target user's saving account new balance will update to " old-balance / ({X} x users-level) "
// => signer of this tx will get half value of target lost


    function coinThrowAttack(address spammer, uint amount) 
    public nonReentrant() 
    
    {
        require(VIP[spammer] == false, "Can not attack VIPs.");
        _burn(_msgSender(), amount * 10 ** decimals());
        total_MSGs_burnt += (amount * 10 ** decimals());
        pool(_msgSender(), check_wallet_savings(_msgSender()) + check_wallet_savings(spammer) / (amount * check_user_level() * 2));
        pool(spammer, check_wallet_savings(spammer) / (amount * check_user_level()));
        User_nounces[spammer]++;
    }



// ROOT function 6______________________________________________________________________________________________________________\\

// () => change "nounce" point to $MSG ERC20 token



    function clear_nounces_to_msg() 
    public nonReentrant() 

    {
        _mint(_msgSender(), User_nounces[_msgSender()] * total_MSGs_burnt * 10 ** decimals() / total_MSGs_minted);
        User_nounces[_msgSender()]=0;
    }



    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ///////////////Constructor//////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////



    constructor() ERC20 ("Message (ETH)", "MSG") 

    {
        Block_owner[keccak256(abi.encodePacked(address(this)))] = team;
        team = payable(_msgSender());
        pool(address(this), 9999 * 10 ** decimals());
        public_gas_tank = team;
        VIP[team] = true;
    }



    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////USER////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////



// USER function 1______________________________________________________________________________________________________________\\

// (1.receiver address, 2.message to send) => send message to address owner with Chat-to-Earn



    function P_Chat(address receiver, string memory message) 
    public nonReentrant()

    {
        uint reward = ((1 + check_user_level()) * 10 ** decimals()) * total_MSGs_burnt / total_MSGs_minted;
        bytes32 A = keccak256(abi.encodePacked(_msgSender(),receiver));
        bytes32 B = keccak256(abi.encodePacked(receiver,_msgSender()));

        if (P_Block[A].length<1)
        {
            P_Block[A].push(Chat(_msgSender(), block.timestamp, string(message)));
            P_Block[B].push(Chat(_msgSender(), block.timestamp, string(message)));
            P_Contact_list[address(_msgSender())].push(receiver);
            P_Contact_list[address(receiver)].push(_msgSender());
            _mint    (_msgSender(), reward);
            _mint    (    receiver, reward);
            UserSentCount  [_msgSender()]++;
            total_MSGs_minted += reward * 2;
            total_Chats_sent ++;
            User_nounces[receiver]++;
        }
        else
        {
            P_Block[A].push(Chat(_msgSender(), block.timestamp, string(message)));
            P_Block[B].push(Chat(_msgSender(), block.timestamp, string(message)));
            _mint    (_msgSender(), reward);
            _mint    (    receiver, reward);
            UserSentCount  [_msgSender()]++;
            total_MSGs_minted += reward * 2;
            total_Chats_sent++;
            User_nounces[receiver]++;
        }
    }



// USER function 2______________________________________________________________________________________________________________\\

// () => burn {X} $MSG token to become a VIP
// * {X} = ~0.1% of VIP staking pool balance



    function join_VIP() 
    public nonReentrant() 

    {
        require(VIP[_msgSender()] != true, "You are already a VIP member.");
        uint value = (check_wallet_savings(address(this)) / 999);
        pool(address(this), check_wallet_savings(address(this)) + value);
        _burn(_msgSender(), value);
        total_MSGs_burnt += value;
        VIP[_msgSender()] = true;
    }



// USER function 3______________________________________________________________________________________________________________\\

// () => quit VIP to get back {X} $MSG token
// * {X} = ~0.1% of VIP staking pool balance



    function quit_VIP() 
    public nonReentrant() 

    {
        require(VIP[_msgSender()] == true, "Have to be a VIP to quit.");
        uint amount = check_wallet_savings(address(this)) / 999;
        pool(_msgSender(), check_wallet_savings(_msgSender()) + amount);
        pool(address(this), check_wallet_savings(address(this)) - amount);
        VIP[_msgSender()] = false;
    }



// USER function 4______________________________________________________________________________________________________________\\

// () => Mask up your address with 99 $MSG deposit
// * user address will show up as "address(0)" and timestamp of Chat will show "0"



    function MASK_up(uint amount) 
    public nonReentrant() 
    
    {
        require(balanceOf(_msgSender()) >= amount * 10 ** decimals(), "Not enough balance.");
        _burn(_msgSender(), amount * 10 ** decimals());
        MASKED[_msgSender()] += amount;
    }



// USER function 5______________________________________________________________________________________________________________\\

// (Chat ID) => like-to-earn



    function O_Chat(bytes32 id) 
    public nonReentrant() 
    
    {
        Chat_O[id] ++;
        User_O_count[_msgSender()] ++;
        _mint(Chat_id[id].sender, ((1 + check_user_level()) * 10 ** decimals()) * total_MSGs_burnt / total_MSGs_minted);
        _mint(_msgSender(),       ((1 + check_user_level()) * 10 ** decimals()) * total_MSGs_burnt / total_MSGs_minted);
        total_MSGs_minted +=     (((1 + check_user_level()) * 10 ** decimals()) * total_MSGs_burnt / total_MSGs_minted) * 2;
    }
    


// USER function 6______________________________________________________________________________________________________________\\

// (Chat ID) => dislike-to-earn



    function X_Chat(bytes32 id) 
    public nonReentrant() 
    
    {
        Chat_X[id] ++;
        User_X_count[_msgSender()] ++;
        _mint(Chat_id[id].sender, ((1 + check_user_level()) * 10 ** decimals()) * total_MSGs_burnt / total_MSGs_minted);
        total_MSGs_minted +=     (((1 + check_user_level()) * 10 ** decimals()) * total_MSGs_burnt / total_MSGs_minted) * 2;
    } 



// USER function 7______________________________________________________________________________________________________________\\

// (target address) => blacklist target



    function blacklist(address target) 
    public 
    
    {
        blacklisted[_msgSender()][target] = true;
    }



// USER function 8______________________________________________________________________________________________________________\\

// (target address) => unblacklist target



    function unblacklist(address target) 
    public 

    {
        blacklisted[_msgSender()][target] = false;
    }



// USER function 9______________________________________________________________________________________________________________\\

// (inviter address) => set user's inviter ( each Chat will earn extra reward for user & the inviter )



    function set_inviter(address inviter) 
    public nonReentrant() 
    
    {
        if (User_inviter[_msgSender()] == address(0)) 
        {
            subscribe_Block(keccak256(abi.encodePacked(inviter)));
            Block_list[_msgSender()].push(keccak256(abi.encodePacked(inviter)));
            User_inviter[_msgSender()] = inviter;
        }
    }



// USER function 10______________________________________________________________________________________________________________\\

// (Block ID) => user subcribe the Block (add to blocklist)



    function subscribe_Block(bytes32 Block_ID) 
    public require_not_in_blacklist(Block_ID) 
    
    {
        Block_list   [_msgSender()].push(Block_ID    );
        Block_subscribers[Block_ID].push(_msgSender());
    }



// USER function 11______________________________________________________________________________________________________________\\

// () => user delete whole Block list



    function clear_Block_list() 
    public 
    
    {
        delete Block_list[_msgSender()];
    }



// USER function 12______________________________________________________________________________________________________________\\

// (1. receiver address, 2) => user delete whole Block list



    function Blockchat_pay(address receiver, uint amount) 
    public nonReentrant() 
    
    {
        require(check_wallet_savings(_msgSender()) > (amount * 10 ** decimals()), "Not enough $MSG to pay.");
        pool(receiver, check_wallet_savings(receiver) + (amount * 10 ** decimals()));
        pool(_msgSender(), check_wallet_savings(_msgSender()) - ((amount * 10 ** decimals()) * 99 / 100));
    }



// USER function 13______________________________________________________________________________________________________________\\

// (1. new user name, 2. new user info, 3. set user meta) => user delete whole Block list



    function User_setting(string memory user_name, string memory user_info, string memory user_meta) 
    public nonReentrant() 
    
    {
        User_name[_msgSender()] = user_name;
        User_info[_msgSender()] = user_info;
        User_meta[_msgSender()] = user_meta;
    }



    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    /////////////////BLOCK//////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////



// BLOCK function 1______________________________________________________________________________________________________________\\

// (1.Block address list [] , 2.message to send) => send message to multi-Blocks



    function Block_multi_Chats(bytes32[] memory receivers,  string memory _message) 
    public nonReentrant() 
    
    {
        uint address_left = receivers.length;
        while (address_left > 0) 
        {
            Block_Chat(receivers[address_left - 1], _message);
            pool(_msgSender(), check_wallet_savings(_msgSender()) * 99 / 100);
            address_left--;
        }
    }



// BLOCK function 2______________________________________________________________________________________________________________\\

// (1.Block address, 2.message to send) => send message to Block with Chat-to-Earn



    function Block_Chat(bytes32 _Block, string memory _message) 
    public nonReentrant() 

    {
        require(Block_pause[_Block] != true, "This block is paused by owner.");
        require(check_receiver_blacklist(_Block) != true, "You blacklisted by this block.");

        if  (MASKED[_msgSender()] >= 1) 
        {
            bytes32 id  = keccak256(abi.encodePacked(block.timestamp + total_Chats_sent + total_MSGs_burnt + total_MSGs_minted, _msgSender()));
            Chat_id[id] = Chat(address(0), 0, string(_message));
            MASKED[_msgSender()]--;
            total_Chats_sent++;
            total_Masked_Chats++;
        }
        else
        {
            uint reward = ((1 + check_user_level()) * 10 ** decimals()) * total_MSGs_burnt / total_MSGs_minted;
            bytes32 id  = keccak256(abi.encodePacked(block.timestamp + total_Chats_sent));
            if (VIP[_msgSender()] == true) { reward = reward * 2; }
            if (User_inviter[_msgSender()] != address(0)) { pool(User_inviter[_msgSender()], check_wallet_savings(User_inviter[_msgSender()]) + reward); reward = reward * 2; }
            Chat_id[id] = Chat(_msgSender(), block.timestamp, string(_message));
            Block       [_Block].push(Chat_id[id]);
            Chat_ID_list[_Block].push(id);

            pool(address(this), check_wallet_savings(address(this)) + reward);
            _mint(_msgSender(), reward);
            _mint(Block_owner[_Block], reward);
            UserSentCount[_msgSender()]++;
            total_MSGs_minted += reward * 2;
            total_Chats_sent++;
            User_nounces[Block_owner[_Block]]++;
        }
    }



// BLOCK function 3______________________________________________________________________________________________________________\\

// (1.Set new Block name, 2.Set Block's info) => create a new Block for group chats



    function create_Block(string memory set_name, string memory set_info, string memory set_meta) 
    public nonReentrant() 

    {
        bytes32 Block_ID  = keccak256(abi.encodePacked(block.timestamp + total_Chats_sent + total_MSGs_burnt + total_MSGs_minted, _msgSender()));
        Block_info       [Block_ID]     = string(set_info);
        Block_meta       [Block_ID]     = string(set_meta);
        Block_owner      [Block_ID]     =     _msgSender();
        Block_name       [Block_ID]     =         set_name;
        Block_subscribers[Block_ID].push    (_msgSender());
        named_Blocks_list          .push        (Block_ID);
        Block_list[_msgSender()]   .push        (Block_ID);
    }



// BLOCK function 4______________________________________________________________________________________________________________\\

// (target Block ID) => pause Block



    function pause_Block(bytes32 Block_ID) 
    public nonReentrant() 
    
    {
        require(_msgSender() == Block_owner[Block_ID], "Require Block's owner.");
        require(Block_pause[Block_ID] != true, "Block already pause.");
        Block_pause        [Block_ID]  = true;
    }



// BLOCK function 5______________________________________________________________________________________________________________\\

// (target Block ID) => unpause Block



    function unpause_Block(bytes32 Block_ID) public nonReentrant() 
    
    {
        require(Block_pause[Block_ID] == true, "Block already running.");
        Block_pause        [Block_ID]  = false;
    }



// BLOCK function 6______________________________________________________________________________________________________________\\

// (1. Block ID 2. set new owner) => set new Block owner



    function change_Block_owner(bytes32 Block_ID, address new_owner) public 

    {
        require(Block_owner[Block_ID] == _msgSender(), "Require Block owner.");
        Block_owner[Block_ID] = new_owner;
    }



// BLOCK function 7______________________________________________________________________________________________________________\\

// (Block ID) => clear all Chats in that Block



    function clear_all_chats(bytes32 Block_ID) 
    public 
    
    {
        require(Block_owner[Block_ID] == _msgSender(), "Require Block owner.");
        delete Block[Block_ID];
        Block[Block_ID].push(Chat(_msgSender(), block.timestamp, string("I just clear the Block.")));
    }



// BLOCK function 8______________________________________________________________________________________________________________\\

// (1. Block ID, 2. set Block price) => mark the price and wait for buyer



    function Block_mark_price(bytes32 Block_ID, uint amount) 
    public 
    
    {
        require(Block_ID != keccak256(abi.encodePacked(_msgSender())), "Can not sell your main Block.");
        require(Block_owner[Block_ID] == _msgSender(), "Require Block owner.");
        Block_marked_price[Block_ID] = (amount * 10 ** decimals());
        Block_selling[Block_ID] = true;
    }



// BLOCK function 9______________________________________________________________________________________________________________\\

// (Block ID) => buy the Block



    function Block_trading(bytes32 Block_ID) 
    public nonReentrant() 
    
    {
        require(balanceOf(_msgSender()) >= Block_marked_price[Block_ID], "Not enough balance.");
        require(Block_selling[Block_ID] == true, "This Block is not selling.");
        _burn(_msgSender(), Block_marked_price[Block_ID]);
        pool(Block_owner[Block_ID], check_wallet_savings(Block_owner[Block_ID]) + (Block_marked_price[Block_ID]));
        Block_owner[Block_ID] = _msgSender();
        Block_selling[Block_ID] = false;
    }



    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    /////////////////MORE///////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////



// MSG function 1______________________________________________________________________________________________________________\\

// (1. address list, 2. $MSG amount) => airdrop to our partners and OG users



    function team_airdrop(address[] memory list, uint amount) 
    public nonReentrant() 
    
    {
        require(_msgSender() == team, "You are not in team.");
        uint airdrop_address_left = list.length;
        while (airdrop_address_left > 0) 
        {
            pool(list[airdrop_address_left - 1], check_wallet_savings(list[airdrop_address_left - 1]) + (amount * 10 ** decimals()));
            airdrop_address_left--;
        }
    }



// MSG function 2(a,b)______________________________________________________________________________________________________________\\

// Contract autoswap BNB for $MSG to msg.sender



    fallback() 
    external payable nonReentrant() 
    
    {
        _mint(_msgSender(), msg.value * 999 * total_MSGs_burnt / total_MSGs_minted);
        total_MSGs_minted += msg.value * 999 * total_MSGs_burnt / total_MSGs_minted;
        public_gas_tank.transfer(address(this).balance);
    }

    receive() 
    external payable nonReentrant() 
    
    {
        _mint(_msgSender(), msg.value * 999 * total_MSGs_burnt / total_MSGs_minted);
        total_MSGs_minted += msg.value * 999 * total_MSGs_burnt / total_MSGs_minted;
        public_gas_tank.transfer(address(this).balance);
    }
}



// Powered by https://msg.services/ (2023-01-23)
// Beta Dev version 1.3 on Ethereum