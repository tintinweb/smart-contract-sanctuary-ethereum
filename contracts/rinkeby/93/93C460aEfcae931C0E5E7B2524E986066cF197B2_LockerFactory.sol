// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Locker.sol";


contract LockerFactory is Ownable {

    uint public lockerCount;    

    uint public lockerFee = 0.1 ether;
    uint public updateLockerFee = 0.05 ether;

    mapping(address => address[]) private lockersListByTokenAddress;
    mapping(address => address[]) private lockersListByOwnerAddress;
    mapping(uint256 => address)   private lockersList;

    event LockerCreated (uint id, address owner, address token, address lockerAddress);
    event FundsWithdrawn (uint funds, uint timestamp);
    event FundsReceived (address sender, uint funds, uint timestamp);

    function createLocker(IERC20 _token, uint _numOfTokens, uint _unlockTime) payable public {

        require(msg.value >= lockerFee, "Please pay the fee");
        require(_unlockTime > 0, "The unlock time should in future");
        lockerCount++;
        
        Locker locker = new Locker(lockerCount, _msgSender(), _token, _numOfTokens, _unlockTime, updateLockerFee);
        _token.transferFrom(_msgSender(), address(locker), _numOfTokens);

        lockersListByOwnerAddress[_msgSender()].push(address(locker));
        lockersListByTokenAddress[address(_token)].push(address(locker));
        lockersList[lockerCount] = address(locker);

        emit LockerCreated (lockerCount, _msgSender(), address(_token), address(locker) );

    }

    function getLockersListbyToken(address _tokenAddress) public view returns (address[] memory) {
        return lockersListByTokenAddress[_tokenAddress];
    }

    function getLockersListbyOwner(address _owner) public view returns (address[] memory) {
        return lockersListByOwnerAddress[_owner];
    }
    function getLockerById(uint256 _id) public view returns (address) {
        require(_id <= lockerCount && _id > 0, "Locker ID out of range");
        return lockersList[_id];
    }

    function updateFees(uint _lockerFee, uint _updatingFee) public onlyOwner {
        lockerFee = _lockerFee;
        updateLockerFee = _updatingFee;
    }

    function withdrawFunds() public onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw");
        bool transfer = payable(owner()).send(balance);
        require(transfer, "unable to transfer ETHs");
        emit FundsWithdrawn (balance, block.timestamp);
    }

    receive() external payable {
        emit FundsReceived(msg.sender, msg.value, block.timestamp);
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
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Locker {

    LockerInfo private lockerInfo;
    
    uint immutable public updateFee;
    address immutable public master;

    enum Status {LOCKED, REDEEMED}

    struct LockerInfo {
        uint id;
        address owner; 
        IERC20 token;
        uint numOfTokensLocked;
        uint unlockTime;
        uint lockTime;
        Status status;
    }

    event LockerUpdated (uint id, uint numOfTokens, uint unlockTime, uint status);
    event LockerUnlocked (uint id, uint numOfTokens, uint unlockTime, uint status);

    constructor (
        uint _lockerID, 
        address _owner, 
        IERC20 _token, 
        uint _numOfTokens, 
        uint _unlockTime,
        uint _updateFee
    ) 
    {
        updateFee = _updateFee;
        master = payable(msg.sender);
        lockerInfo = LockerInfo(_lockerID, _owner, _token, _numOfTokens, _unlockTime, block.timestamp, Status.LOCKED);    
    }

    /// @notice this is the function to increase locker time
    /// @param additionTimeInSeconds should be in seconds 
    function addMoreTimeToLocker(uint additionTimeInSeconds) public payable {
        require(msg.value >= updateFee, "Insufficient funds");

        LockerInfo memory _lockerInfo =  lockerInfo;

        require(msg.sender == _lockerInfo.owner, "Not owner of the locker");
        require(_lockerInfo.status == Status.LOCKED, "Locker is expired, can't be updated");

        lockerInfo.unlockTime += additionTimeInSeconds;

        emit LockerUpdated (
            _lockerInfo.id, 
            _lockerInfo.numOfTokensLocked, 
            _lockerInfo.unlockTime + additionTimeInSeconds, 
            0
        );

        sendFundsToMaster(msg.value);

    }

    /// @notice this is the function to increase number of tokens
    /// @param additionTokens should be already approved 
    function addMoreTokensToLocker(uint additionTokens) public payable {
        require(msg.value >= updateFee, "Insufficient funds");

        LockerInfo memory _lockerInfo =  lockerInfo;

        require(msg.sender == _lockerInfo.owner, "Not owner of the locker");
        require(_lockerInfo.status == Status.LOCKED, "Locker is expired, can't be updated");

        lockerInfo.numOfTokensLocked += additionTokens;

        _lockerInfo.token.transferFrom(msg.sender, address(this), additionTokens);

        emit LockerUpdated (
            _lockerInfo.id, 
            _lockerInfo.numOfTokensLocked + additionTokens, 
            _lockerInfo.unlockTime, 
            0
        );

        sendFundsToMaster(msg.value);
        
    }

    /// @notice this is the function to unlock the locked tokens 
    function unlockTokens() public {
        LockerInfo memory _lockerInfo =  lockerInfo;

        require(msg.sender == _lockerInfo.owner, "Not owner of the locker");
        require(block.timestamp >= lockerInfo.unlockTime, "Not unlocked yet");
        require(_lockerInfo.status == Status.LOCKED, "Already redeemed");

        lockerInfo.status = Status.REDEEMED;

        _lockerInfo.token.transfer(_lockerInfo.owner, _lockerInfo.numOfTokensLocked);
        
        emit LockerUnlocked (_lockerInfo.id, _lockerInfo.numOfTokensLocked, block.timestamp, 1);

    }

    /// @notice A getter functions to read the locker information 
    function getLockerInfo() public view returns (LockerInfo memory) {
        return lockerInfo;
    }

    /// @notice internal functions to trasfer collected fees to the master contract
    function sendFundsToMaster(uint _funds) internal {
        (bool res,) = payable(master).call{value: _funds}("");
        require(res, "cannot send funds to master"); 
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