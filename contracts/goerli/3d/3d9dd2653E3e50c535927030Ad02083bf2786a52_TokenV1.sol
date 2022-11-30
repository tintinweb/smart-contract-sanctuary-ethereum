//SPDX-License-Identifier: Unlicensed
 
pragma solidity ^0.8.9;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { AbstractTokenV1 } from "./AbstractTokenV1.sol";
import { Ownable } from "./Ownable.sol";
import { Pausable } from "./Pausable.sol";
import { Blacklistable } from "./Blacklistable.sol";

/**
 * @title Token
 * @dev ERC20 Token backed by fiat reserves
 */

contract TokenV1 is AbstractTokenV1, Ownable, Pausable, Blacklistable {
    
    string public name;
    string public symbol;
    uint8 public decimals;
    string public currency;
    address public masterMinter;
    //bool internal initializedToken;

    uint256 internal _totalSupply;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => address[]) internal approvedAddresses;
    mapping(address => bool) public isMinter;
    mapping(address => uint256) internal maxAmountPerMint; //max minter can mint in one txn
    mapping(address => uint256) internal minterCumulative;// Total cumulative amt minter can mint before reconfigure
    mapping(address => uint256) public minterAllowance; //Allowance set by approval
    mapping(address => uint256) internal totalMinted;


    event Mint(address indexed minter, address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 amount);
    event MinterConfigured(address indexed minter, uint256 minterAllowedAmount);
    event MinterRemoved(address indexed oldMinter);
    event MasterMinterChanged(address indexed newMasterMinter);

    modifier onlyMinter(){
        require(isMinter[msg.sender], "not a minter");
        _;
    }

     /**
     * @dev Throws if called by any account other than the masterMinter
     */
    modifier onlyMasterMinter() {
        require(
            msg.sender == masterMinter,
            "caller not masterMinter"
        );
        _;
    }


    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory tokenCurrency,
        uint8 tokenDecimals,
        address newMasterMinter,
        address newPauser, 
        address newBlacklister
    ) external onlyOwner {
        require(
            newMasterMinter != address(0),
            "No zero addr"
        );
        require(
            newPauser != address(0),
            "No zero addr"
        );
        require(
            newBlacklister != address(0),
            "No zero addr"
        );
    
        name = tokenName;
        symbol = tokenSymbol;
        currency = tokenCurrency;
        decimals = tokenDecimals;
        masterMinter = newMasterMinter;
        _pauser = newPauser;
        _blacklister = newBlacklister;
        //initializedToken = true;
        //initialized = true;
    }

    function getApprovedAddresses() external view returns (address[] memory){
        return(approvedAddresses[msg.sender]);
    }

    function getMinterAllowance(address minter) external view returns (uint256) {
        return minterAllowance[minter];
    }

    /**
     * @notice Amount of remaining tokens spender is allowed to transfer on
     * behalf of the token owner
     * @param owner     Token owner's address
     * @param spender   Spender's address
     * @return Allowance amount
     */
    function allowance(address owner, address spender)
        external
        override
        view
        returns (uint256)
    {
        return allowed[owner][spender];
    }

    /**
     * @dev Get totalSupply of token
     */
    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Get token balance of an account
     * @param account address The account
     */
    function balanceOf(address account)
        external
        override
        view
        returns (uint256)
    {
        return balances[account];
    }

    /**
     * @notice Set spender's allowance over the caller's tokens to be a given
     * value.
     * @param spender   Spender's address
     * @param value     Allowance amount
     * @return True if successful
     */
    function approve(address spender, uint256 value)
        external
        override
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(spender)
        returns (bool)
    {        
        require(msg.sender!=spender, "msg.sender not spender");
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Internal function to set allowance
     * @param owner     Token owner's address
     * @param spender   Spender's address
     * @param value     Allowance amount
     */
    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal override {

        require(owner != address(0), "No zero addr");
        require(spender != address(0), "No zero addr");
        approvedAddresses[owner].push(spender);
        allowed[owner][spender] = value;

        emit Approval(owner, spender, value);
    }

    /**
     * @notice Transfer tokens by spending allowance
     * @param from  Payer's address
     * @param to    Payee's address
     * @param value Transfer amount
     * @return True if successful
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        external
        override
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(from)
        notBlacklisted(to)
        returns (bool)
    {
        require(
            value <= allowed[from][msg.sender],
            "amount > allowance"
        );
        _transfer(from, to, value);
        allowed[from][msg.sender] -= value;
        return true;
    }

    /**
     * @notice Transfer tokens from the caller
     * @param to    Payee's address
     * @param value Transfer amount
     * @return True if successful
     */
    function transfer(address to, uint256 value)
        external
        override
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(to)
        returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @notice Internal function to process transfers
     * @param from  Payer's address
     * @param to    Payee's address
     * @param value Transfer amount
     */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal override {
        require(from != address(0), "No zero addr");
        require(to != address(0), "No zero addr");
        require(
            value <= balances[from],
            "amount > balance"
        );

        balances[from] -= value;
        balances[to] += value;
        emit Transfer(from, to, value);
    }

    /*
     * @dev Function to add/update a new minter
     * @param minter The address of the minter
     * @param minterAllowedAmount The minting amount allowed for the minter
     * @return True if the operation was successful.
     */
     
    function configureMinter(address minter, uint256 _minterAllowedAmount, uint256 _minterCap, uint256 _maxPerTxn)
        external
        whenNotPaused
        onlyMasterMinter
        returns (bool)
    {
        isMinter[minter] = true;
        totalMinted[minter] = 0;
        minterCumulative[minter] = _minterCap;
        minterAllowance[minter] = _minterAllowedAmount;
        maxAmountPerMint[minter] = _maxPerTxn;


        emit MinterConfigured(minter, _minterAllowedAmount);
        return true;
    }

    /**
     * @dev Function to remove a minter
     * @param minter The address of the minter to remove
     * @return True if the operation was successful.
     */
    function removeMinter(address minter)
        external
        onlyMasterMinter
        returns (bool)
    {
        isMinter[minter] = false;
        maxAmountPerMint[minter] = 0;
        minterCumulative[minter] = 0;
        emit MinterRemoved(minter);
        return true;
    }

    /**
     * @dev allows a minter to burn some of its own tokens
     * Validates that caller is a minter and that sender is not blacklisted
     * amount is less than or equal to the minter's account balance
     * @param _amount uint256 the amount of tokens to be burned
     */
    function burn(uint256 _amount)
        external
        whenNotPaused
        onlyMinter
        notBlacklisted(msg.sender)
    {
        uint256 balance = balances[msg.sender];
        require(_amount > 0, "burn amount not greater than 0");
        require(balance >= _amount, "burn amount exceeds balance");

        _totalSupply -= (_amount);
        balances[msg.sender] -= (_amount);
        emit Burn(msg.sender, _amount);
        emit Transfer(msg.sender, address(0), _amount);
    }

    function mint(address _to, uint256 _amount)
    public
    whenNotPaused
    notBlacklisted(msg.sender)
    notBlacklisted(_to)
    returns (bool)
    {
     
        require(_to != address(0), "No zero addr");
        require(_amount > 0, "must mint > 0");
        require(isMinter[_to], "unconfigured minter");
        require(minterAllowance[_to] >= _amount, "allowance exceeded");
        require(
            _amount <= maxAmountPerMint[_to],
            "txn max exceeded"
        );
        require((totalMinted[_to] + _amount) <= minterCumulative[_to], "above minter cap");

        totalMinted[_to] += _amount;
        _totalSupply += _amount;
        balances[_to] += _amount;
        minterCumulative[_to] -= _amount;
        minterAllowance[_to] -= _amount;
        emit Mint(msg.sender, _to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    function updateMasterMinter(address _newMasterMinter) external onlyOwner {
        require(
            _newMasterMinter != address(0),
            "No zero addr"
        );
        masterMinter = _newMasterMinter;
        emit MasterMinterChanged(masterMinter);
    }

        /**
     * @notice Increase the allowance by a given increment
     * @param spender   Spender's address
     * @param increment Amount of increase in allowance
     * @return True if successful
     */
    function increaseAllowance(address spender, uint256 increment)
        external
        payable
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(spender)
        returns (bool)
    {
        require(balances[msg.sender] > allowed[msg.sender][spender] + increment, "lacking funds");
       
        _increaseAllowance(msg.sender, spender, increment);
        return true;
    }

    /**
     * @notice Decrease the allowance by a given decrement
     * @param spender   Spender's address
     * @param decrement Amount of decrease in allowance
     * @return True if successful
     */
    function decreaseAllowance(address spender, uint256 decrement)
        external
        payable
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(spender)
        returns (bool)
    {

        _decreaseAllowance(msg.sender, spender, decrement);
        return true;
    }

     function _increaseAllowance(
        address owner,
        address spender,
        uint256 increment
    ) internal override { 
        allowed[owner][spender] += increment;
        _approve(owner, spender, allowed[owner][spender]);
    }

    /**
     * @notice Internal function to decrease the allowance by a given decrement
     * @param owner     Token owner's address
     * @param spender   Spender's address
     * @param decrement Amount of decrease
     */
    function _decreaseAllowance(
        address owner,
        address spender,
        uint256 decrement
    ) internal override {
        require(
            
            allowed[owner][spender] >= decrement,
            "allowance < zero"
        );

        _approve(
            owner,
            spender,
            allowed[owner][spender] - decrement
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract AbstractTokenV1 is IERC20 {
    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal virtual;

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual;

    function _increaseAllowance(
        address owner,
        address spender,
        uint256 increment
    ) internal virtual;

    function _decreaseAllowance(
        address owner,
        address spender,
        uint256 decrement
    ) internal virtual;
}

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

/**
 * @notice The Ownable contract has an owner address, and provides basic
 * authorization control functions
 */
contract Ownable {
    // Owner of the contract
    address private _owner;
    //bool public initialized;

    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event OwnershipTransferred(address previousOwner, address newOwner);

     /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "caller not owner");
        _;
    }

    /**
     * @dev The constructor sets the original owner of the contract to the sender account.
     */
    constructor() {
        setOwner(msg.sender);
    }

    /**
     * @dev Tells the address of the owner
     * @return the address of the owner
     */
    function getOwner() external view returns (address) {
        return _owner;
    }

    /**
     * @dev Sets a new owner address
     */
    function setOwner(address newOwner) internal {
        _owner = newOwner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(
            newOwner != address(0),
            "No zero addr"
        );
        emit OwnershipTransferred(_owner, newOwner);
        setOwner(newOwner);
    }
}

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

import { PermissionAdmin } from "./PermissionAdmin.sol";

/**
 * @notice Base contract which allows children to implement an emergency stop
 * mechanism
 */

contract Pausable is PermissionAdmin {

    address internal _pauser;
    bool public paused = false;

    event Pause();
    event Unpause();
    event pauserChanged(address indexed newPauser);

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused, "paused");
        _;
    }

    /**
     * @dev throws if called by any account other than the pauser
     */
    modifier onlyPauser() {
        require(msg.sender == _pauser, "caller not pauser");
        _;
    }

    /**
     * @notice Returns current rescuer
     * @return Pauser's address
     */
    function getPauser() external view returns (address) {
        return _pauser;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() external onlyPauser {        
        require(paused == false, "already paused");
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() external onlyPauser {
        require(paused == true, "already unpaused");
        paused = false;
        emit Unpause();
    }

    /**
     * @dev update the pauser role
     */
    function updatePauser(address _newPauser) external onlyPermissionAdmin {
        //require(initialized, "Pausable: TokenV1 not initialized");
        require(
            _newPauser != address(0),
            "No zero addr"
        );
        _pauser = _newPauser;
        emit pauserChanged(_pauser);
    }
}

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

import {PermissionAdmin} from "./PermissionAdmin.sol";

/**
 * @title Blacklistable Token
 * @dev Allows accounts to be blacklisted by a "blacklister" role
 */
contract Blacklistable is PermissionAdmin {

    address internal _blacklister;
    mapping(address => bool) public blacklisted;

    event Blacklisted(address indexed _account);
    event UnBlacklisted(address indexed _account);
    event BlacklisterChanged(address indexed newBlacklister);

    /**
     * @dev Throws if called by any account other than the blacklister
     */
    modifier onlyBlacklister() {
        require(msg.sender == _blacklister, "caller not blacklister");
        _;
    }

    /**
     * @dev Throws if argument account is blacklisted
     * @param _account The address to check
     */
    modifier notBlacklisted(address _account) {
        require(_blacklister != address(0), "No zero addr");
        require(!blacklisted[_account], "account blacklisted");
        _;
    }

    /**
     * @notice Returns current rescuer
     * @return Blacklister's address
     */
    function getBlacklister() external view returns (address) {
        return _blacklister;
    }

    /**
     * @dev Checks if account is blacklisted
     * @param _account The address to check
     */
    function isBlacklisted(address _account) external view returns (bool) {
        return blacklisted[_account];
    }

    /**
     * @dev Adds account to blacklist
     * @param _account The address to blacklist
     */
    function blacklist(address _account) external onlyBlacklister {
        require(!blacklisted[_account], "already blacklisted");
        require(_account != _blacklister, "blacklister cannot blacklist itself");
        require(_account != address(0), "No zero addr");
        blacklisted[_account] = true;
        emit Blacklisted(_account);
    }

    /**
     * @dev Removes account from blacklist
     * @param _account The address to remove from the blacklist
     */
    function unBlacklist(address _account) external onlyBlacklister {
        blacklisted[_account] = false;
        emit UnBlacklisted(_account);
    }

    function updateBlacklister(address _newBlacklister)
        external
        onlyPermissionAdmin
    {
        //require(initialized, "TokenV1 not initialized");
        require(_newBlacklister != address(0), "No zero addr");
        _blacklister = _newBlacklister;
        emit BlacklisterChanged(_blacklister);
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

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

import { Ownable } from "./Ownable.sol";

/** 
* @notice Base contract which allows owner to set an admin to select the pauser, 
* blacklister, and rescuer. Only the contract owner can modify the admin.
*/

contract PermissionAdmin is Ownable{

    address private _permissionAdmin;

    event permissionAdminChanged(address indexed admin);

    modifier onlyPermissionAdmin() {
        require(
            msg.sender == _permissionAdmin, 
            "caller not permission admin"
        );
        _;
    }

     /**
     * @notice Returns current rescuer
     * @return permissionAdmin's address
     */
    function getPermissionAdmin() external view returns (address) {
        return _permissionAdmin;
    }

    function setPermissionAdmin(address _newAdmin) external onlyOwner {
        require(
            _newAdmin != address(0), 
            "No zero addr"
        );
        _permissionAdmin = _newAdmin;
        emit permissionAdminChanged(_permissionAdmin);
    }

}