//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";
import "./NNN.sol";


contract Vesting is Ownable {
    struct PartInfo{
        uint start;
        uint end;
        uint countPeriods;
        uint amountPerPeriod;
        uint amount;
        uint claimedAmount;
        uint[] duration;
    }

    NNN public token;

    uint public TotalVestingToRelease;
    
    mapping (bytes32=> PartInfo) public vestingParts;

    event Claimed(uint timeClaimed,uint amountOfClaimed);
    event StartedVesting(uint timeStarted,uint timeEnd,uint amount,bytes32 hashObject);
    
    receive() external payable {}

    fallback() external payable {}

    
    constructor(NNN _token) {
        token = _token;
    }
    function createVestingPart(uint[] calldata _durations,uint _amount) public onlyOwner returns(bytes32){
        uint numberOfPeriods = _durations.length;
        uint lastTime = _durations[_durations.length-1];
        token.transferFrom(msg.sender, address(this), _amount);
        bytes32 _hash = keccak256(abi.encode(block.timestamp,numberOfPeriods,_amount));
        PartInfo storage part = vestingParts[_hash];
        part.start = block.timestamp;
        part.duration = _durations;
        part.end = lastTime + block.timestamp;
        part.countPeriods = numberOfPeriods;
        part.amountPerPeriod = _amount / numberOfPeriods;
        part.amount = _amount;
        part.claimedAmount = 0;
        emit StartedVesting(block.timestamp,part.end,_amount,_hash);
        return _hash;
    }
    function claimableAmount(bytes32 _hash) public view returns (uint256) {
        PartInfo storage part = vestingParts[_hash];
        uint timeCertain = elapsedTime(part.start);
        uint index = Arrays.findUpperBound(part.duration, timeCertain);
        return (index-1)*part.amountPerPeriod;
    }
    function claimVesting(bytes32 vestingPart,bool stayHere) public onlyOwner{
        uint amountToExit = claimableAmount(vestingPart);
        PartInfo storage part = vestingParts[vestingPart];
        part.amount - amountToExit;
        if(stayHere == true){
            TotalVestingToRelease+=amountToExit;
        }
        else {
            token.transferFrom(address(this), address(msg.sender), amountToExit);
        }
        
        part.claimedAmount += amountToExit; 
        emit Claimed(block.timestamp, amountToExit);
    }
    function elapsedTime(uint _time)internal view returns(uint){
        return block.timestamp - _time;
    }
    function getAllTime(bytes32 _hash)public view returns(uint[] memory){
        PartInfo storage part = vestingParts[_hash];
        return part.duration;
    }
    function multiSending(address[] calldata users,uint [] calldata amount) public onlyOwner {
        //(hasRole(ADMIN_ROLE, msg.sender));
        require(users.length == amount.length,"Not same value");
        
        uint total_value = sum(amount); 
        require(total_value<TotalVestingToRelease);
        //require(totalAllocPoint >= total_value);
        for (uint i = 0; i < users.length; i++){
            total_value -= amount[i];
            token.transfer(users[i], amount[i]);
        //emit sendedToUser(block.timestamp,amount[i],users[i]);
        }
        TotalVestingToRelease-=total_value;
    }
    function sum(uint[] memory amounts)internal pure returns (uint) {
        uint totalAmount = 0;
        for (uint i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        return totalAmount;
    }
 
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/utils/Context.sol"; 
contract Whitelisted is Context {
    struct WhitelistRound {
        uint256 duration;
        uint256 amountMax;
        mapping(address => bool) addresses;
        mapping(address => uint256) purchased;
    }

    WhitelistRound[] public _WhitelistRounds;

    uint256 public _Timestamp;
    address public _PairAddress;

    address public _whitelister;

    event WhitelisterTransferred(address indexed previousWhitelister, address indexed newWhitelister);

    constructor() {
        _whitelister = _msgSender();
    }

    modifier onlyWhitelister() {
        require(_whitelister == _msgSender(), "Caller is not the whitelister");
        _;
    }

    function renounceWhitelister() external onlyWhitelister {
        emit WhitelisterTransferred(_whitelister, address(0));
        _whitelister = address(0);
    }

    function transferWhitelister(address newWhitelister) external onlyWhitelister {
        _transferWhitelister(newWhitelister);
    }

    function _transferWhitelister(address newWhitelister) internal {
        require(newWhitelister != address(0), "New whitelister is the zero address");
        emit WhitelisterTransferred(_whitelister, newWhitelister);
        _whitelister = newWhitelister;
    }
    function createWhitelist(
        address pairAddress,
        uint256[] calldata durations,
        uint256[] calldata amountsMax
    ) external onlyWhitelister() {
        require(durations.length == amountsMax.length, "Invalid whitelist(s)");

        _PairAddress = pairAddress;

        if (durations.length > 0) {
            delete _WhitelistRounds;

            for (uint256 i = 0; i < durations.length; i++) {
                WhitelistRound storage whitelistRound = _WhitelistRounds.push();
                whitelistRound.duration = durations[i];
                whitelistRound.amountMax = amountsMax[i];
            }
        }
    }

    function modifyWhitelist(
        uint256 index,
        uint256 duration,
        uint256 amountMax,
        address[] calldata addresses,
        bool enabled
    ) external onlyWhitelister() {
        require(index < _WhitelistRounds.length, "Invalid index");
        require(amountMax > 0, "Invalid amountMax");

        if (duration != _WhitelistRounds[index].duration) _WhitelistRounds[index].duration = duration;

        if (amountMax != _WhitelistRounds[index].amountMax) _WhitelistRounds[index].amountMax = amountMax;

        for (uint256 i = 0; i < addresses.length; i++) {
            _WhitelistRounds[index].addresses[addresses[i]] = enabled;
        }
    }
    function getWhitelistRound()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        )
    {
        if (_Timestamp > 0) {
            uint256 wlCloseTimestampLast = _Timestamp;

            for (uint256 i = 0; i < _WhitelistRounds.length; i++) {
                WhitelistRound storage wlRound = _WhitelistRounds[i];

                wlCloseTimestampLast = wlCloseTimestampLast + wlRound.duration;
                if (block.timestamp <= wlCloseTimestampLast)
                    return (
                        i + 1,
                        wlRound.duration,
                        wlCloseTimestampLast,
                        wlRound.amountMax,
                        wlRound.addresses[_msgSender()],
                        wlRound.purchased[_msgSender()]
                    );
            }
        }

        return (0, 0, 0, 0, false, 0);
    }

   

    function _applyWhitelist(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        if (_PairAddress == address(0) || _WhitelistRounds.length == 0) return;

        if (_Timestamp == 0 && sender != _PairAddress && recipient == _PairAddress && amount > 0)
            _Timestamp = block.timestamp;

        if (sender == _PairAddress && recipient != _PairAddress) {
            //buying

            (uint256 wlRoundNumber, , , , , ) = getWhitelistRound();

            if (wlRoundNumber > 0) {
                WhitelistRound storage wlRound = _WhitelistRounds[wlRoundNumber - 1];

                require(wlRound.addresses[recipient], " Buyer is not whitelisted");

                uint256 amountRemaining = 0;

                if (wlRound.purchased[recipient] < wlRound.amountMax)
                    amountRemaining = wlRound.amountMax - wlRound.purchased[recipient];

                require(amount <= amountRemaining, "  Amount exceeds whitelist maximum");
                wlRound.purchased[recipient] = wlRound.purchased[recipient] + amount;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./Whitelisted.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./BlackListed.sol";


contract NNN is Context, IERC20, IERC20Metadata,Whitelisted,Pausable,Ownable,BlackListed {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _mint(msg.sender, 121000000000000000000000000000);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function mint (address _to, uint256 _amount)external onlyOwner{
        _mint(_to,_amount);
    }
    function burn(uint256 _amount) public whenNotPaused{
        _burn(msg.sender, _amount);
    }
    function pause()public onlyOwner{
        _pause();
    }
    function unpause() public onlyOwner{
        _unpause();
    }
    function withdrawToken(address _tokenContract, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_tokenContract);
        token.transfer(msg.sender, _amount);
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual whenNotPaused override returns (bool) {
        require(!inBlacklisted[to], "Recipient is backlisted");
        require(!inBlacklisted[msg.sender], "Sender is backlisted");
        _applyWhitelist(_msgSender(), to, amount);
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual whenNotPaused override returns (bool) {
        require(!inBlacklisted[spender], "Recipient is backlisted");
        require(!inBlacklisted[msg.sender], "Sender is backlisted");
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual whenNotPaused override returns (bool) {
        require(!inBlacklisted[to], "Recipient is backlisted");
        require(!inBlacklisted[msg.sender], "Sender is backlisted");
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual whenNotPaused returns (bool) {
        require(!inBlacklisted[spender], "Recipient is backlisted");
        require(!inBlacklisted[msg.sender], "Sender is backlisted");
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

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

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }


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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BlackListed is Ownable {
    
   
    mapping(address => bool) inBlacklisted;

    event Blacklisted(address indexed _account);
    event UnBlacklisted(address indexed _account);

    function blackList(address _user) public onlyOwner {
        require(!inBlacklisted[_user], "user already blacklisted");
        inBlacklisted[_user] = true;
        emit Blacklisted( _user);
    }
    
    function removeFromBlacklist(address _user) public onlyOwner {
        require(inBlacklisted[_user], "user already whitelisted");
        inBlacklisted[_user] = false;
        emit UnBlacklisted(_user);
    }
    function isBlacklisted(address _account) external view returns (bool) {
        return inBlacklisted[_account];
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Arrays.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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