//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @author DegenDeveloper.eth
 * April 28, 2022
 *
 * This contract allows users to start permanent discussion threads for any topic.
 * Users can leave comments in existing discussion threads.
 *
 * These discussion threads are called holes and the comments inside are called rabbits.
 *
 * To dig a hole, a user must pay the DIG_FEE. In exchange for digging a hole,
 * a user will be minted DIG_REWARD number of rabbits (RBIT).
 *
 * To leave a rabbit in a hole, a user will burn 1 RBIT.
 *
 * This contract also stores the holes dug & rabbits left by each user.
 */
contract TheRabbitHole is Ownable, ERC20 {
    using Counters for Counters.Counter;
    using Strings for uint256;
    /// lookup identifiers ///
    bytes32 internal constant HOLES = keccak256("HOLES");
    bytes32 internal constant RABBITS = keccak256("RABBITS");
    /// the price in matic to dig 1 hole ///
    uint256 public DIG_FEE = 1 ether;
    /// the number of RBIT minted to a hole digger ///
    uint256 public DIG_REWARD = 25;

    /**
     * A discussion thread for any topic
     * @param digger The address that dug the hole
     * @param title The human-readable title of the hole
     * @param hole_hash The hash of the hole's title
     * @param timestamp The time the hole was dug
     * @param rabbit_count The number of rabbits in the hole
     *
     */
    struct Hole {
        address digger;
        string title;
        bytes32 hole_hash;
        uint256 timestamp;
        Counters.Counter rabbit_count;
    }
    /**
     * A comment in a discussion thread
     * @param leaver The address that left the rabbit
     * @param comment The comment the leaver left
     * @param hole_hash The hash of the hole the rabbit was left in
     * @param timestamp The time the rabbit was left
     */
    struct Rabbit {
        address leaver;
        string comment;
        bytes32 hole_hash;
        uint256 timestamp;
    }

    /// mapping for the number of holes dug and rabbits left ///
    mapping(bytes32 => Counters.Counter) internal stats;
    /// mapping for each hole by index ///
    mapping(uint256 => Hole) public holes;
    /// mapping of each rabbit by index ///
    mapping(uint256 => Rabbit) public rabbits; // rabbits by index
    /// mapping for the index of a hole (by the hash of its title)
    mapping(bytes32 => uint256) internal hole_indexes;
    /// mapping for all of the rabbits in each hole by index ///
    mapping(bytes32 => mapping(uint256 => Rabbit)) internal rabbitsByHole;
    /// mapping for the number of holes/rabbits made by each address ///
    mapping(bytes32 => mapping(address => Counters.Counter)) internal userStats;
    /// mapping for the index of each hole/rabbit made by a user
    mapping(bytes32 => mapping(address => mapping(uint256 => uint256)))
        internal userObjectIndexes;

    /// ============ CONSTRUCTOR ============ ///

    /**
     * Mints 1000 RBIT to the contract owner
     */
    constructor() ERC20("TheRabbitHole", "RBIT") {
        _mint(msg.sender, 1000);
    }

    /// ============ OWNER FUNCTIONS ============ ///

    /**
     * Holes will be cheap to dig, to keep this possible
     * the owner will need to occasionally change the dig fee
     * @param _fee The fee to dig a hole in wei
     */
    function setDigFee(uint256 _fee) public onlyOwner {
        DIG_FEE = _fee;
    }

    /**
     * Incase the dig reward needs to be adjusted
     * @param _amount The number of RBIT minted to a digger
     */
    function setDigReward(uint256 _amount) public onlyOwner {
        DIG_REWARD = _amount;
    }

    /**
     * For withdrawing contract funds to a specific address
     * @param _addr The receiver of the funds
     */
    function withdrawFunds(address payable _addr) public onlyOwner {
        _addr.transfer(address(this).balance);
    }

    /// ============ PUBLIC FUNCTIONS ============ ///

    /**
     * Starts a discussion thread using _title and mints caller RBIT
     * @param _title The title of the discussion thread
     * @param _rabbit1 The first rabbit to leave in the newly dug hole
     * @notice `_title`s should follow the guidelines listed in the dapp
     * @notice Following the guidelines will reduce the chances of two holes being about the same topic
     */
    function digHole(string memory _title, string memory _rabbit1)
        public
        payable
    {
        require(msg.value >= DIG_FEE, "TheRabbitHole: Insufficient funds");
        require(
            hole_indexes[keccak256(abi.encodePacked(_title))] == 0,
            "TheRabbitHole: Hole already dug"
        );

        _digHole(_title);
        _leaveRabbit(stats[HOLES].current(), _rabbit1);
        _mint(msg.sender, DIG_REWARD);
    }

    /**
     * Leaves a comment in an already dug hole
     * @param _holeIndex The index of the hole caller is leaving the rabbit in
     * @param _comment The comment to leave in the hole
     * @notice Caller must have an RBIT balance > 0
     * @notice Leaving a rabbit in a hole will burn 1 of caller's RBIT
     */
    function leaveRabbit(uint256 _holeIndex, string memory _comment) public {
        require(
            holes[_holeIndex].rabbit_count.current() > 0,
            "TheRabbitHole: Hole not dug yet"
        );

        _leaveRabbit(_holeIndex, _comment);
        _burn(msg.sender, 1);
    }

    /// ============ INTERNAL FUNCTIONS ============ ///

    /**
     * Helper function for hole digging
     * @param _title The title for the hole being dug
     */
    function _digHole(string memory _title) internal {
        /// increment the number of holes in the contract ///
        /// increment the number of holes dug by caller ///
        stats[HOLES].increment();
        userStats[HOLES][msg.sender].increment();
        /// get the hole's hash and index ///
        bytes32 holeHash = keccak256(abi.encodePacked(_title));
        uint256 currentHole = stats[HOLES].current();
        /// construct hole ///
        holes[currentHole].digger = msg.sender;
        holes[currentHole].title = _title;
        holes[currentHole].hole_hash = holeHash;
        holes[currentHole].timestamp = block.timestamp;
        hole_indexes[holeHash] = stats[HOLES].current();
        /// set hole for user ///
        userObjectIndexes[HOLES][msg.sender][
            userStats[HOLES][msg.sender].current()
        ] = currentHole;
    }

    function _leaveRabbit(uint256 _holeIndex, string memory _comment) internal {
        /// increment the number of rabbits in contract ///
        /// incrememt the number of rabbits in hole ///
        /// increment the number of rabbits from caller ///
        stats[RABBITS].increment();
        holes[_holeIndex].rabbit_count.increment();
        userStats[RABBITS][msg.sender].increment();
        /// get the hole's hash and the rabbit's index ///
        bytes32 holeHash = holes[_holeIndex].hole_hash;
        uint256 currentRabbit = stats[RABBITS].current();
        /// construct rabbit ///
        rabbits[currentRabbit].leaver = msg.sender;
        rabbits[currentRabbit].comment = _comment;
        rabbits[currentRabbit].hole_hash = holeHash;
        rabbits[currentRabbit].timestamp = block.timestamp;
        /// place rabbit in hole ///
        rabbitsByHole[holeHash][
            holes[_holeIndex].rabbit_count.current()
        ] = rabbits[currentRabbit];
        /// set rabbit for user ///
        userObjectIndexes[RABBITS][msg.sender][
            userStats[RABBITS][msg.sender].current()
        ] = currentRabbit;
    }

    /// ============ READ-ONLY FUNCTIONS ============ ///

    /**
     * @return _holes The total number of holes dug
     */
    function totalHoles() public view returns (uint256 _holes) {
        _holes = stats[HOLES].current();
    }

    /**
     * @return _rabbits The total number of rabbits left
     */
    function totalRabbits() public view returns (uint256 _rabbits) {
        _rabbits = stats[RABBITS].current();
    }

    /**
     * RBIT should be represented as whole numbers
     */
    function decimals() public pure override returns (uint8) {
        return 0;
    }

    /**
     * Gets the index for a hole by hash
     * @param _holeHash The hash of the hole's title
     * @return _index The index for the hole
     */
    function getHoleIndexByHash(bytes32 _holeHash)
        public
        view
        returns (uint256 _index)
    {
        _index = hole_indexes[_holeHash];
    }

    /**
     * Gets the index for a hole by title
     * @param _title The title of the hole
     * @return _index The index for the hole
     */
    function getHoleIndexByTitle(string memory _title)
        public
        view
        returns (uint256 _index)
    {
        _index = hole_indexes[keccak256(abi.encodePacked(_title))];
    }

    /**
     * Makes the hash for a hole
     * @param _title The string to hash
     * @return _hash The hash of the string
     */
    function getHashForString(string memory _title)
        public
        pure
        returns (bytes32 _hash)
    {
        _hash = keccak256(abi.encodePacked(_title));
    }

    /**
     * Gets the number of rabbits left in a specific hole
     * @param _index The index of the hole to check
     * @return _rabbits The number of rabbits in the hole
     */
    function getTotalRabbitsInHole(uint256 _index)
        public
        view
        returns (uint256 _rabbits)
    {
        _rabbits = holes[_index].rabbit_count.current();
    }

    /**
     * Gets a specific rabbit from a hole
     * @param _holeIndex The index of the hole to check
     * @param _rabbitIndex The index of the rabbit in the hole
     * @return _rabbit The rabbit at _rabbitIndex in holes[_holeIndex]
     */
    function getRabbitInHole(uint256 _holeIndex, uint256 _rabbitIndex)
        public
        view
        returns (Rabbit memory _rabbit)
    {
        bytes32 holeHash = holes[_holeIndex].hole_hash;
        _rabbit = rabbitsByHole[holeHash][_rabbitIndex];
    }

    /**
     * Gets the number of holes dug by a user
     * @param _user The address to lookup
     * @return _holes The number of holes dug by _user
     */
    function getUserHoleCount(address _user)
        public
        view
        returns (uint256 _holes)
    {
        _holes = userStats[HOLES][_user].current();
    }

    /**
     * Gets the number of rabbits left by a user
     * @param _user The address to lookup
     * @return _rabbits The number of rabbits left by _user
     */
    function getUserRabbitCount(address _user)
        public
        view
        returns (uint256 _rabbits)
    {
        _rabbits = userStats[RABBITS][_user].current();
    }

    /**
     * Gets the indexes for each hole dug by a user
     * @param _user The address to lookup
     * @return _holes An array of indexes for each hole dug by _user
     */
    function getUserHoles(address _user)
        public
        view
        returns (uint256[] memory _holes)
    {
        _holes = new uint256[](getUserHoleCount(_user));
        for (uint256 i = 0; i < getUserHoleCount(_user); ++i) {
            _holes[i] = userObjectIndexes[HOLES][_user][i + 1];
        }
    }

    /**
     * Gets the indexes for each rabbit left by a user
     * @param _user The address to lookup
     * @return _rabbits An array of indexes for each rabbit left by _user
     */
    function getUserRabbits(address _user)
        public
        view
        returns (uint256[] memory _rabbits)
    {
        _rabbits = new uint256[](getUserRabbitCount(_user));
        for (uint256 i = 0; i < getUserRabbitCount(_user); ++i) {
            _rabbits[i] = userObjectIndexes[RABBITS][_user][i + 1];
        }
    }

    /**
     * @return _fee The fee to dig 1 hole
     */
    function getDigFee() public view returns (uint256 _fee) {
        _fee = DIG_FEE;
    }

    /**
     * @return _reward The number of RBIT to mint to a hole digger
     */
    function getDigReward() public view returns (uint256 _reward) {
        _reward = DIG_REWARD;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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

// SPDX-License-Identifier: MIT
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