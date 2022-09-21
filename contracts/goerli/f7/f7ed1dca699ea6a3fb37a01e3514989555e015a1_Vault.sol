// SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.9;

import "openzeppelin/access/Ownable.sol";
import "openzeppelin/security/Pausable.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import "./plugins/IPlugin.sol";

contract Vault is Ownable, IERC20, Pausable {
    string public constant name = "Mycelium LINK";
    string public constant symbol = "myLINK";
    uint8 public immutable decimals;
    address public immutable LINK;

    /**
     * myLINK balances are dynamic. They represent the holder's share in the total amount of
     * LINK controlled by the Vault. An account's balance is calculated as:
     *
     *      shares[account] * totalSupply() / totalShares()
     *
     * Mints, transfers, and burns operate on the equivalent number of shares, rather than the balance
     * directly. This allows the balance to change over time without requiring an infeasible number of
     * storage writes.
     *
     * Conversions between myLINK and shares will not always be exact due to rounding errors. For example,
     * if there are 100 shares and 200 myLINK in the Vault, the smallest possible transfer is 2 myLINK.
     * To mitigate this, the initial conversion rate (STARTING_SHARES_PER_LINK) is set to a high number
     * allowing more precision. As the Vault grows, the precision will decrease.
     *
     * Because of the dynamic nature of myLINK balances, integer overflow errors will arise when the Vault
     * reaches a certain capacity, according to the following formula:
     *
     *      totalSupply()^2 * STARTING_SHARES_PER_LINK < 2^256
     *
     * So the vault will not allow deposits that would cause the Vault to exceed the MAX_CAPACITY number.
     * This enforces a tradeoff between precision and capacity. Since the total LINK supply is 10e27, we
     * can safely set the MAX_CAPACITY to 10e28 and still have plenty of precision with a starting rate of
     */
    uint256 public MAX_CAPACITY = 10e27;
    uint256 public constant STARTING_SHARES_PER_LINK = 10e20;

    uint256 public totalShares;
    mapping(address => uint256) public shares;

    uint256 public pluginCount;
    mapping(uint256 => address) public plugins;

    // owner > spender > value
    mapping(address => mapping(address => uint256)) public allowance;

    event Deposit(address indexed from, uint256 value);
    event Withdraw(address indexed to, uint256 value);
    event PluginAdded(address indexed plugin, uint256 index);
    event PluginRemoved(address indexed plugin);

    constructor(address _LINK) {
        LINK = _LINK;
        decimals = IERC20Metadata(_LINK).decimals();
    }

    /** USER FUNCTIONS **/
    function deposit(uint256 _value) external whenNotPaused {
        require(_value > 0, "Amount must be greater than 0");
        require(_value <= availableForDeposit(), "Amount exceeds available capacity");

        uint256 newShares = convertToShares(_value);
        _mintShares(msg.sender, newShares);

        IERC20(LINK).transferFrom(msg.sender, address(this), _value);
        _distributeToPlugins();

        emit Deposit(msg.sender, _value);
    }

    function withdraw(uint256 _value) external whenNotPaused {
        require(_value > 0, "Amount must be greater than 0");
        require(_value <= balanceOf(msg.sender), "Amount exceeds balance");

        _retrieveLink(_value);

        _burnShares(msg.sender, convertToShares(_value));

        IERC20(LINK).transfer(msg.sender, _value);

        emit Withdraw(msg.sender, _value);
    }

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public whenNotPaused returns (bool) {
        require(_value <= allowance[_from][msg.sender], "Amount exceeds allowance");

        _transfer(_from, _to, _value);
        allowance[_from][msg.sender] -= _value;

        return true;
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        require(_spender != address(0), "Cannot approve zero address");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /** OWNER FUNCTIONS **/
    function addPlugin(address _plugin, uint256 _index) external onlyOwner {
        require(_plugin != address(0), "Cannot add zero address");
        require(_index <= pluginCount, "Index must be less than or equal to plugin count");

        uint256 pointer = pluginCount;
        while (pointer > _index) {
            plugins[pointer] = plugins[pointer - 1];
            pointer--;
        }
        plugins[pointer] = _plugin;
        pluginCount++;

        IERC20(LINK).approve(_plugin, type(uint256).max);

        emit PluginAdded(_plugin, _index);
    }

    function removePlugin(uint256 _index) external onlyOwner {
        require(_index < pluginCount, "Index out of bounds");
        address pluginAddr = plugins[_index];

        _withdrawFromPlugin(pluginAddr, IPlugin(pluginAddr).balance());

        uint256 pointer = _index;
        while (pointer < pluginCount - 1) {
            plugins[pointer] = plugins[pointer + 1];
            pointer++;
        }
        delete plugins[pluginCount - 1];
        pluginCount--;

        emit PluginRemoved(pluginAddr);
    }

    function rebalancePlugins(uint256[] memory _withdrawalValues) external onlyOwner {
        require(_withdrawalValues.length == pluginCount, "Invalid withdrawal values");
        for (uint256 i = 0; i < pluginCount; i++) {
            _withdrawFromPlugin(plugins[i], _withdrawalValues[i]);
        }
        _distributeToPlugins();
    }

    function setMaxCapacity(uint256 _maxCapacity) external onlyOwner {
        MAX_CAPACITY = _maxCapacity;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /** INTERNAL FUNCTIONS **/
    function _mintShares(address _to, uint256 _shares) internal {
        require(_to != address(0), "Cannot mint to address 0");

        totalShares += _shares;
        unchecked {
            // Overflow is impossible, because totalShares would overflow first
            shares[_to] += _shares;
        }
    }

    function _burnShares(address _from, uint256 _shares) internal {
        require(_from != address(0), "Cannot burn from address 0");

        require(shares[_from] >= _shares, "Cannot burn more shares than owned");
        unchecked {
            // Underflow is impossible, because of above require statement
            shares[_from] -= _shares;
            totalShares -= _shares;
        }
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(_from != address(0), "Cannot transfer from zero address");
        require(_to != address(0), "Cannot transfer to zero address");

        uint256 sharesToTransfer = convertToShares(_value);
        require(sharesToTransfer <= shares[_from], "Amount exceeds balance");

        // Overflow is impossible because sharesToTransfer will always be less than totalShares
        // which is checked when new shares are minted
        unchecked {
            shares[_from] -= sharesToTransfer;
            shares[_to] += sharesToTransfer;
        }

        emit Transfer(_from, _to, _value);
    }

    function _distributeToPlugins() internal {
        uint256 remaining = IERC20(LINK).balanceOf(address(this));

        // Plugins are ordered by priority. Fill the first one first, then the second, etc.
        for (uint256 i = 0; i < pluginCount; i++) {
            if (remaining == 0) {
                break;
            }

            address plugin = plugins[i];
            uint256 available = IPlugin(plugin).availableForDeposit();
            if (available > 0) {
                uint256 amount = available > remaining ? remaining : available;
                _depositToPlugin(plugin, amount);
                remaining -= amount;
            }
        }
    }

    function _depositToPlugin(address _plugin, uint256 _value) internal {
        IPlugin(_plugin).deposit(_value);
    }

    function _retrieveLink(uint256 _requested) internal {
        require(_requested <= availableForWithdrawal(), "Amount exceeds available balance");

        uint256 currentBalance = IERC20(LINK).balanceOf(address(this));
        if (currentBalance >= _requested) {
            return;
        }

        uint256 remaining = _requested - currentBalance;
        // Withdraw in reverse order of deposit
        for (uint256 i = 0; i < pluginCount; i++) {
            if (remaining == 0) {
                break;
            }

            address plugin = plugins[pluginCount - i - 1];
            uint256 available = IPlugin(plugin).availableForWithdrawal();
            if (available > 0) {
                uint256 amount = available > remaining ? remaining : available;
                _withdrawFromPlugin(plugin, amount);
                remaining -= amount;
            }
        }

        if (remaining > 0) {
            revert("Unable to withdraw enough LINK from plugins");
        }
    }

    function _withdrawFromPlugin(address _plugin, uint256 _value) internal {
        IPlugin(_plugin).withdraw(_value);
    }

    /** VIEWS **/
    function totalSupply() public view override returns (uint256) {
        uint256 supply = IERC20(LINK).balanceOf(address(this));
        for (uint256 i = 0; i < pluginCount; i++) {
            supply += IPlugin(plugins[i]).balance();
        }
        return supply;
    }

    function availableForDeposit() public view returns (uint256) {
        uint256 supply = totalSupply();
        if (supply >= MAX_CAPACITY) {
            return 0;
        }
        return MAX_CAPACITY - supply;
    }

    function availableForWithdrawal() public view returns (uint256) {
        uint256 available = IERC20(LINK).balanceOf(address(this));
        for (uint256 i = 0; i < pluginCount; i++) {
            available += IPlugin(plugins[i]).availableForWithdrawal();
        }
        return available;
    }

    function balanceOf(address _account) public view override returns (uint256) {
        return convertToLink(shares[_account]);
    }

    function convertToLink(uint256 _shares) public view returns (uint256) {
        uint256 shareSupply = totalShares; // saves one SLOAD
        if (shareSupply == 0) {
            return _shares / STARTING_SHARES_PER_LINK;
        }
        return (totalSupply() * _shares) / shareSupply;
    }

    function convertToShares(uint256 _link) public view returns (uint256) {
        uint256 linkSupply = totalSupply(); // saves one SLOAD
        if (linkSupply == 0) {
            return _link * STARTING_SHARES_PER_LINK;
        }
        return (totalShares * _link) / linkSupply;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.9;

interface IPlugin {
    function deposit(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function balance() external view returns (uint256);

    function availableForDeposit() external view returns (uint256);

    function availableForWithdrawal() external view returns (uint256);
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