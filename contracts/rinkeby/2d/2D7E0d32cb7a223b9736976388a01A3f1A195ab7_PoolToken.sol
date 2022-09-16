//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PoolToken is Ownable {
    address public ParthLabs = 0x661B3a9297E8bee53602cA3E8140ff0555f725ED;
    struct UserInfo {
        uint256 dailyReceived;
        uint256 startAt;
        uint256 lastClaimAt;
        uint256 totalReceived;
        uint256 maxTokenReceived;
    }
    mapping(address => UserInfo) private _userInfo;
    mapping(address => bool) private _admins;
    uint256 private PeriodTimeReceived;

    modifier onlyAdmins() {
        require(_admins[_msgSender()], "Caller must be the admin.");
        _;
    }
    
    event UserInformation(address indexed  user, uint256 maxTokenReceived);
    event ClaimedToken(address indexed  user, uint256 totalToken);
    event AdminsChanged(address indexed account, bool allowance);

    function setTime(uint256 periodTime) external onlyAdmins{
        PeriodTimeReceived = periodTime;
    }

    function setAdmin(address account, bool allowance) external onlyOwner {
        _admins[account] = allowance;
        emit AdminsChanged(account, allowance);
    }

    function isAdmin(address account) external view returns (bool) {
        return (_admins[account]);
    }
    
    function userInfo(address _user) public view returns(uint256, uint256, uint256, uint256){
        UserInfo storage user = _userInfo[_user];
        return (
            user.dailyReceived,
            user.lastClaimAt,
            user.totalReceived,
            user.maxTokenReceived
        );
    }
    
    function addUserInfo(address customer, uint256 dailyReceived, uint256 maxTokenReceived) external onlyAdmins {
        uint256 startAt = block.timestamp;
        _userInfo[customer].startAt = startAt;
        _userInfo[customer].dailyReceived = dailyReceived; 
        _userInfo[customer].maxTokenReceived = maxTokenReceived;

        emit UserInformation(customer, maxTokenReceived);
    }

    function daysHavePassed(uint timeStartClaim) private view returns(uint256) {
        uint256 timeNow = block.timestamp;
        require(timeStartClaim <= timeNow, "time invalid");
        //calculate to the number of days that have passed
        return (timeNow - timeStartClaim) / PeriodTimeReceived;
    }

    function unClaimedAmount(address _user) external view returns(uint256) {
        uint256 tokenRemained = _userInfo[_user].maxTokenReceived - _userInfo[_user].totalReceived;
        return tokenRemained;
    }

    function claimToken(address recepient) external  {
        uint256 maxTokenReceived = _userInfo[recepient].maxTokenReceived;
        require(_userInfo[recepient].totalReceived != maxTokenReceived, "you have received enough token");
        // calculate the days passed
        uint256 startAt = _userInfo[recepient].startAt;
        uint256 daysPassed = daysHavePassed(startAt);

        uint256 tokenAmount = _userInfo[recepient].dailyReceived;
        uint256 totalToken = tokenAmount * daysPassed;

        uint256 tokenRemained =maxTokenReceived - _userInfo[recepient].totalReceived;
        _userInfo[recepient].totalReceived += totalToken;
         
        uint256 claimAt = block.timestamp;
        _userInfo[recepient].startAt = claimAt;
        _userInfo[recepient].lastClaimAt = claimAt;

        if (_userInfo[recepient].totalReceived > maxTokenReceived) {
            _userInfo[recepient].totalReceived = maxTokenReceived;
            totalToken = tokenRemained;
        }

        IERC20(ParthLabs).transfer(recepient, totalToken);
        emit ClaimedToken(recepient, totalToken);
    }

    function transferAnyBEP20Token(address _tokenAddress, uint256 _amount) external onlyOwner {
        IERC20(_tokenAddress).transfer(owner(), _amount);
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