// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "./ERC20Detailed.sol";

contract TestWbtToken is ERC20Detailed {
    constructor() ERC20Detailed("TestWbtToken WBT", "WBT", 8, 300_000_000_00000000) {
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "./ERC20.sol";

contract ERC20Detailed is ERC20 {

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply
    )  {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _mint(msg.sender, totalSupply);
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./BlackList.sol";

/**
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract ERC20 is IERC20, BlackList, Pausable {
    mapping (address => uint256) _balances;

    mapping (address => mapping (address => uint256)) _allowed;

    uint256 internal _totalSupply;

    function totalSupply() external view override virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param user The address to query the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address user) external view override returns (uint256) {
        return _balances[user];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param user address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address user, address spender) external view returns (uint256) {
        return _allowed[user][spender];
    }


    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) external {
        require(spender != address(0));
        require(msg.sender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    )
    external
    {
        require(spender != address(0));
        require(msg.sender != address(0));

        _allowed[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    )
    external
    {
        require(spender != address(0));
        require(msg.sender != address(0));

        _allowed[msg.sender][spender] -= subtractedValue;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    }

    function transferFrom(address from, address to, uint256 value) external {
        require(value <= _allowed[from][msg.sender], 'Not allowed to spend');
        _transfer(from, to, value);
        _allowed[from][msg.sender] -= value;
    }

    function transfer(address to, uint256 value) external {
        _transfer(msg.sender, to, value);
    }

    function _transfer(address from, address to, uint256 value) internal whenNotPaused {
        require(!isBlacklisted(from));
        require(!isBlacklisted(to));
        require(to != address(0));

        _balances[from] -= value;
        _balances[to] += value;
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply += value;
        _balances[account] += value;
        emit Transfer(address(0), account, value);
    }

    /**
 * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external onlyOwner() virtual {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply -= value;
        _balances[account] -= value;
        emit Transfer(account, address(0), value);
    }

    function destroyBlackFunds (address _blackListedUser) external onlyOwner {
        require(isBlacklisted(_blackListedUser));
        uint dirtyFunds = _balances[_blackListedUser];
        _balances[_blackListedUser] = 0;
        _totalSupply -= dirtyFunds;
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "./Ownable.sol";

contract BlackList is Ownable {

    mapping(address => bool) _blacklist;

    /////// Getter to allow the same blacklist to be used also by other contracts (including upgraded Tether) ///////
    function isBlacklisted(address _maker) public view returns (bool) {
        return _blacklist[_maker];
    }

    function blacklistAccount(address account, bool sign) external onlyOwner {
        _blacklist[account] = sign;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "./Ownable.sol";

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
   */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
   */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
   */
    function pause() onlyOwner whenNotPaused external {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
   */
    function unpause() onlyOwner whenPaused external {
        paused = false;
        emit Unpause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() external view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender));
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner(address userAddress) public view returns (bool) {
        return userAddress == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external view returns (uint256);

    function transfer(address to, uint256 value) external;
    function transferFrom(address from, address to, uint256 value) external;

    function approve(address spender, uint256 value) external;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event DestroyedBlackFunds(
        address indexed blackListedUser,
        uint balance
    );
}