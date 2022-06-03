/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// Part: OpenZeppelin/[email protected]/Context

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// Part: OpenZeppelin/[email protected]/SafeMath

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// Part: smartcontractkit/[email protected]/AggregatorV3Interface

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// Part: HashToken

contract HashToken is ERC20 {
    constructor(uint256 initialSupply) public ERC20("Hash", "HASH") {
        _mint(msg.sender, initialSupply);
    }
}

// File: HashGameStore.sol

contract HashGameStore {
    struct Game {
        uint256 id; // ID of the game
        address developerAddress; // Developer the game belongs to
        uint256 quantityAvailable; // How many keys can still be minted
        bool limited; // If the game has a limited amount of keys that can be minted
        uint256 price; // TEMPORARY - Base price of each game key
        string downloadLink; // Filecoin Location
    }

    // Global Variables

    // List of all games on the platform
    Game[] private games;

    // Maps wallet address to a map of gameIDs to quantity of keys owned
    mapping(address => mapping(uint256 => uint256))
        public addressToGameIDToKeysInLibrary;

    mapping(address => mapping(uint256 => uint256))
        public addressToGameIDToKeysForSale; // NOTE: How many keys of the library are for sale

    // Maps wallet address to a map of gameIDs to price of keys in said wallet
    mapping(address => mapping(uint256 => uint256))
        public addressToGameIDToPrice;

    // Keeps track of if an address has been registered
    mapping(address => bool) public addressIsRegistered;
    address[] public registeredAddresses;

    // The address of our company's wallet
    address payable minter;

    // Constants
    uint256 REVENUE_SHARE = 1; // (1/100) - Percentage that Hash Game Store takes from developers

    HashToken public token;
    AggregatorV3Interface internal priceFeed;

    // Run when contract is deployed
    constructor() public {
        minter = msg.sender; // Sets the minter as us so we can retrieve the Tokens
        token = new HashToken(5000000000000000000000); // Creates the token contract (5000 HASH)
        priceFeed = AggregatorV3Interface( // Price feed to get ETH -> USD conversion
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
    }

    // Functions ==================================================================================================================

    // Returns the ETH -> USD price conversion

    /*
    function getLatestETHPrice() private view returns (int256) {
        (uint80 a, int256 ethPrice, uint256 b, uint256 c, uint80 d) = priceFeed
            .latestRoundData();

        return ethPrice;
    }
    */

    // Checks if an address has been registered. If it hasn't, start keep tracking of it
    // PRIVATE
    function registerAddress(address a) private {
        if (!addressIsRegistered[a]) {
            addressIsRegistered[a] = true;
            registeredAddresses.push(a);
        }
    }

    // Registers a game with the developer as the msg.sender's developer (0 for infinite)
    // PUBLIC
    function gameRegister(
        uint256 price,
        uint256 quantityAvailable,
        string memory downloadLink
    ) public returns (uint256) {
        Game memory newGame;
        newGame.developerAddress = msg.sender;
        newGame.id = games.length;
        newGame.price = price;
        newGame.downloadLink = downloadLink;

        if (quantityAvailable == 0) {
            newGame.limited = false;
        } else {
            newGame.limited = true;
            newGame.quantityAvailable = quantityAvailable;
        }

        games.push(newGame);
        return games.length - 1;
    }

    // Buys and generates a new key from a developer
    // PUBLIC
    function buyOriginalKey(uint256 gameID) public {
        Game storage game = games[gameID];

        // If the game has limited quantity, said quantity must not be 0
        require(
            (!game.limited) || (game.quantityAvailable > 0),
            "All of this game's copies have sold out"
        );

        // Get the cheapest deal for the game
        uint256 price = game.price;

        // Player must have the necessary balance
        require(
            token.balanceOf(msg.sender) >= price,
            "The caller didn't have enough Hash tokens"
        );

        // Give the contract permission to transfer $HASH
        require(
            token.allowance(msg.sender, address(this)) >= price,
            "The caller didn't allow the platform to spend enough Hash tokens on their behalf"
        );

        // Subtract from the key's available stock if needed
        if (game.limited) {
            game.quantityAvailable--;
        }

        // Transfer part to Developer
        uint256 devRevenue = (price * (100 - REVENUE_SHARE)) / 100;
        token.transferFrom(msg.sender, game.developerAddress, devRevenue);

        // Transfer part to Hash
        uint256 hashRevenue = (price * (REVENUE_SHARE)) / 100;
        token.transferFrom(msg.sender, minter, hashRevenue);

        // Add key to player's wallet
        addressToGameIDToKeysInLibrary[msg.sender][gameID]++;

        // If the address isn't registered, then start keeping track of it
        registerAddress(msg.sender);
    }

    // Lists X keys of a game for sale
    // PUBLIC
    function setKeysForSale(
        uint256 gameID,
        uint256 quantity,
        uint256 price
    ) public {
        require( // The wallet must at least as many keys as it is trying to sell
            quantity <= addressToGameIDToKeysInLibrary[msg.sender][gameID],
            "The wallet does quantitynot own as many keys as it is trying to list"
        );

        // Set 'quantity' amount of keys for sale
        addressToGameIDToKeysForSale[msg.sender][gameID] = quantity;

        // Set the price of said amount of keys
        addressToGameIDToPrice[msg.sender][gameID] = price;
    }

    // Buy keys from an account
    // PRIVATE
    function buyOldKey(
        uint256 gameID,
        address walletAddress,
        uint256 quantity
    ) private {
        uint256 price = addressToGameIDToPrice[walletAddress][gameID] *
            quantity;
        uint256 availableQuantity = addressToGameIDToKeysForSale[walletAddress][
            gameID
        ];

        Game memory game = games[gameID];
        address developerAddress = game.developerAddress;

        require( // The wallet must at least as many keys as are being bought
            availableQuantity >= quantity,
            "The wallet does not own as many keys as are being bought"
        );

        require( // The wallet must own enough tokens
            token.balanceOf(msg.sender) >= price,
            "The wallet doesn't own enough funds to buy this much"
        );

        // Give the contract permission to transfer $HASH
        require(
            token.allowance(msg.sender, address(this)) >= price,
            "The caller didn't allow the platform to spend enough Hash tokens on their behalf"
        );

        // Transfer part to Reseller
        uint256 userRevenue = ((price * 89) / 100);
        token.transferFrom(msg.sender, walletAddress, userRevenue);

        // Transfer part to Developer
        uint256 devRevenue = ((price * 10) / 100);
        token.transferFrom(msg.sender, developerAddress, devRevenue);

        // Transfer part to Hash
        uint256 hashRevenue = ((price * 1) / 100);
        token.transferFrom(msg.sender, minter, hashRevenue);

        // Transfer key quantities
        addressToGameIDToKeysForSale[walletAddress][gameID] -= quantity;
        addressToGameIDToKeysInLibrary[walletAddress][gameID] -= quantity;
        addressToGameIDToKeysInLibrary[msg.sender][gameID] += quantity;

        // If the address isn't registered, then start keeping track of it
        registerAddress(msg.sender);
    }

    // Buy the lowest priced key of a specific game
    // PUBLIC
    function buyLowestPriceKey(uint256 gameID, uint256 quantity) public {
        // Find the address that is selling a key with the lowest price
        address lowestPriceAddress = getLowestPriceReseller(gameID, msg.sender);

        buyOldKey(gameID, lowestPriceAddress, quantity);
    }

    // Public Getter Functions ---------------------------------------------------------

    // Returns the contract address of the token
    function getTokenAddress() public view returns (HashToken) {
        return token;
    }

    // Get the lowest price key for a specific game
    function getLowestKeyPrice(uint256 gameID, address exceptionAddress)
        public
        view
        returns (uint256)
    {
        address lowestPriceAddress = getLowestPriceReseller(
            gameID,
            exceptionAddress
        );

        return addressToGameIDToPrice[lowestPriceAddress][gameID];
    }

    // Get the lowest price key quantity for a specific game
    function getLowestPriceKeyQuantity(uint256 gameID, address exceptionAddress)
        public
        view
        returns (uint256)
    {
        address lowestPriceAddress = getLowestPriceReseller(
            gameID,
            exceptionAddress
        );

        return addressToGameIDToKeysForSale[lowestPriceAddress][gameID];
    }

    // Returns the lowest key price reseller for a specific game
    function getLowestPriceReseller(uint256 gameID, address exceptionAddress)
        public
        view
        returns (address)
    {
        uint256 lowestPrice;
        address lowestPriceAddress;

        for (uint256 i = 0; i < registeredAddresses.length; i++) {
            address a = registeredAddresses[i];

            // The message sender cannot buy from himself
            if (a != exceptionAddress) {
                // There are any keys on sale
                if (addressToGameIDToKeysForSale[a][gameID] > 0) {
                    uint256 price = addressToGameIDToPrice[a][gameID];

                    // If the price is lower
                    if (lowestPrice < price) {
                        lowestPrice = price;
                        lowestPriceAddress = a;
                    }
                }
            }
        }

        return lowestPriceAddress;
    }

    // Returns the price of a key from a player's library
    function getOldGameKeyPrice(address walletAddress, uint256 keyID)
        public
        view
        returns (uint256)
    {
        return addressToGameIDToPrice[walletAddress][keyID];
    }

    // Returns the amount of keys an account owns
    function getKeysForAddress(address a, uint256 gameID)
        public
        view
        returns (uint256)
    {
        return addressToGameIDToKeysInLibrary[a][gameID];
    }

    // Returns the amount of keys an account has listed for sale
    function getKeysForAddressForSale(address a, uint256 gameID)
        public
        view
        returns (uint256)
    {
        return addressToGameIDToKeysForSale[a][gameID];
    }

    // Returns a list with the IDs of the games a wallet owns
    function getLibrary(address walletAddress)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory walletLibrary = new uint256[](games.length);
        uint256 j;

        // Go through games list and check if the address has any copies of the game
        for (uint256 i = 0; i < games.length; i++) {
            if (addressToGameIDToKeysInLibrary[walletAddress][i] > 0) {
                walletLibrary[j++] = i;
            }
        }

        // Create an array that will be more compact than 'walletLibrary'
        uint256[] memory returnedLibrary = new uint256[](j);

        // Append all the elements from the big array to the smaller one
        for (uint256 i = 0; i < j; i++) {
            returnedLibrary[i] = walletLibrary[i];
        }

        return returnedLibrary;
    }

    // Returns the HASH Token Balance of a specific wallet
    function getAddressBalance(address a) public view returns (uint256) {
        return token.balanceOf(a);
    }

    // Returns the price of an original key for a game
    function getOriginalGamePrice(uint256 gameID)
        public
        view
        returns (uint256)
    {
        return games[gameID].price;
    }

    // Returns the link to the download of a game [OPTIONAL -> msg.sender must own the game]
    function getGameDownloadLink(uint256 gameID)
        public
        view
        returns (string memory)
    {
        // The msg.sender must own the game to request the link to its download
        /*
        require(
            addressToGameIDToKeysInLibrary[msg.sender][gameID] > 0,
            "The account request the link to this game's download does not own it"
        );*/

        return games[gameID].downloadLink;
    }

    // Test Functions -------------------------------------------------------------------

    // Sends Hash Tokens for free (FOR TESTING PURPOSES)
    function acquireHashTokens(uint256 hashTokens) public {
        token.transfer(msg.sender, hashTokens);
    }
}