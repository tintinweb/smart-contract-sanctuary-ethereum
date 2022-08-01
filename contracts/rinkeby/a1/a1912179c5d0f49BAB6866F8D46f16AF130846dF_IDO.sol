// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IPool.sol";
import "./Whitelist.sol";
import "./Pool.sol";
import "./Validations.sol";

interface IStake {
    struct UserData {
        uint256 stakeToken;
        uint256 rewards;
        uint256 lastUpdateTime;
        uint256 stakingTime;
    }

    function users(address user) external view returns (UserData memory);
}

contract IDO is Pausable, Ownable, Whitelist {
    IPool private pool;
    address public stakingContract;

    event LogPoolCreated(address indexed poolOwner);
    event LogPoolStatusChanged(address indexed poolOwner, uint256 newStatus);
    event LogWithdraw(address indexed participant, uint256 amount);

    constructor(address _stakingContract) {
        require(
            address(0) != address(_stakingContract),
            "zero address not accepted!"
        );
        stakingContract = _stakingContract;
    }

    function createPool(
        uint256 _hardCap,
        uint256 _startDateTime,
        uint256 _endDateTime,
        uint256 _status
    ) external onlyOwner _createPoolOnlyOnce returns (bool success) {
        IPool.PoolModel memory model = IPool.PoolModel({
            hardCap: _hardCap,
            startDateTime: _startDateTime,
            endDateTime: _endDateTime,
            status: IPool.PoolStatus(_status)
        });

        pool = new Pool(model);
        emit LogPoolCreated(_msgSender());
        success = true;
    }

    function addIDOInfo(
        address _investmentTokenAddress,
        uint256 _minAllocationPerUser,
        uint256 _maxAllocationPerUser
    ) external onlyOwner {
        pool.addIDOInfo(
            IPool.IDOInfo({
                investmentTokenAddress: _investmentTokenAddress,
                minAllocationPerUser: _minAllocationPerUser,
                maxAllocationPerUser: _maxAllocationPerUser
            })
        );
    }

    function updatePoolStatus(uint256 newStatus)
        external
        onlyOwner
        returns (bool success)
    {
        pool.updatePoolStatus(newStatus);
        emit LogPoolStatusChanged(_msgSender(), newStatus);
        success = true;
    }

    function addAddressesToWhitelist(address[] calldata whitelistedAddresses)
        external
        onlyOwner
    {
        addToWhitelist(whitelistedAddresses);
    }

    function getCompletePoolDetails()
        external
        view
        _poolIsCreated
        returns (IPool.CompletePoolDetails memory poolDetails)
    {
        poolDetails = pool.getCompletePoolDetails();
    }

    // Whitelisted accounts can invest in the Pool
    function participate(uint256 amount) external _onlyWhitelisted(msg.sender) {
        require(
            IStake(stakingContract).users(msg.sender).stakeToken >= 500 ether,
            "User not staked required amount"
        );
        pool.deposit(msg.sender, amount);
    }

    function poolAddress() external view returns (address _pool) {
        _pool = address(pool);
    }

    function withdrawFunds(address fundsWallet) public onlyOwner {
        address investmentTokenAddress = pool.getInvestmentTokenAddress();
        uint256 totalRaisedAmount = IERC20(investmentTokenAddress).balanceOf(
            address(this)
        );
        require(totalRaisedAmount > 0, "Raised funds should be greater than 0");
        IERC20(investmentTokenAddress).transfer(fundsWallet, totalRaisedAmount);
    }

    modifier _onlyWhitelisted(address _address) {
        require(isWhitelisted(_address), "Not Whitelisted!");
        _;
    }

    modifier _createPoolOnlyOnce() {
        require(address(pool) == address(0), "Pool already created!");
        _;
    }

    modifier _poolIsCreated() {
        require(address(pool) != address(0), "Pool not created yet!");
        _;
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

interface IPool {
    struct PoolModel {
        uint256 hardCap; // how much project wants to raise
        uint256 startDateTime;
        uint256 endDateTime;
        PoolStatus status; //: by default “Upcoming”,
    }

    struct IDOInfo {
        address investmentTokenAddress; //the address of the token in which project will raise funds
        uint256 minAllocationPerUser;
        uint256 maxAllocationPerUser;
    }

    // Pool data that needs to be retrieved:
    struct CompletePoolDetails {
        Participations participationDetails;
        PoolModel pool;
        IDOInfo poolDetails;
        uint256 totalRaised;
    }

    struct Participations {
        ParticipantDetails[] investorsDetails;
        uint256 count;
    }

    struct ParticipantDetails {
        address addressOfParticipant;
        uint256 totalRaisedAmount;
    }

    enum PoolStatus {
        Upcoming,
        Ongoing,
        Finished,
        Paused,
        Cancelled
    }

    function addIDOInfo(IDOInfo memory _detailedPoolInfo) external;

    function getCompletePoolDetails()
        external
        view
        returns (CompletePoolDetails memory poolDetails);

    function getInvestmentTokenAddress()
        external
        view
        returns (address investmentTokenAddress);

    function updatePoolStatus(uint256 _newStatus) external;

    function deposit(address _sender, uint256 _amount) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Validations.sol";

contract Whitelist {
    mapping(address => bool) private whitelistedAddressesMap;
    address[] private whitelistedAddressesArray;

    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed accout);

    constructor() {}

    function addToWhitelist(address[] calldata _addresses)
        internal
        returns (bool success)
    {
        require(_addresses.length > 0, "an array of address is expected");

        for (uint256 i = 0; i < _addresses.length; i++) {
            address userAddress = _addresses[i];

            Validations.revertOnZeroAddress(userAddress);

            if (!isAddressWhitelisted(userAddress))
                addAddressToWhitelist(userAddress);
        }
        success = true;
    }

    function isWhitelisted(address _address)
        internal
        view
        _nonZeroAddress(_address)
        returns (bool isIt)
    {
        isIt = whitelistedAddressesMap[_address];
    }

    function getWhitelistedUsers() internal view returns (address[] memory) {
        uint256 count = whitelistedAddressesArray.length;

        address[] memory _whitelistedAddresses = new address[](count);

        for (uint256 i = 0; i < count; i++) {
            _whitelistedAddresses[i] = whitelistedAddressesArray[i];
        }
        return _whitelistedAddresses;
    }

    modifier _nonZeroAddress(address _address) {
        Validations.revertOnZeroAddress(_address);
        _;
    }

    function isAddressWhitelisted(address _address)
        private
        view
        returns (bool isIt)
    {
        isIt = whitelistedAddressesMap[_address];
    }

    function addAddressToWhitelist(address _address) private {
        whitelistedAddressesMap[_address] = true;
        whitelistedAddressesArray.push(_address);
        emit AddedToWhitelist(_address);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IPool.sol";
import "./Validations.sol";

contract Pool is IPool, Ownable {
    PoolModel private poolInformation;
    IDOInfo private idoInfo;

    address[] private participantsAddress;
    mapping(address => uint256) private collaborations;
    uint256 private _amountRaised = 0;

    event LogPoolContractAddress(address);
    event LogPoolStatusChanged(uint256 currentStatus, uint256 newStatus);
    event LogDeposit(address indexed participant, uint256 amount);

    constructor(PoolModel memory _pool) {
        _preValidatePoolCreation(_pool);
        poolInformation = IPool.PoolModel({
            hardCap: _pool.hardCap, // 100k
            startDateTime: _pool.startDateTime,
            endDateTime: _pool.endDateTime,
            status: _pool.status
        });

        emit LogPoolContractAddress(address(this));
    }

    modifier _addIDOInfoOnlyOnce() {
        require(
            address(idoInfo.investmentTokenAddress) == address(0),
            "already added IDO info"
        );
        _;
    }

    function addIDOInfo(IDOInfo memory _pdi)
        external
        override
        onlyOwner
        _addIDOInfoOnlyOnce
    {
        _preIDOInfoUpdate(_pdi);

        idoInfo.investmentTokenAddress = _pdi.investmentTokenAddress;
        idoInfo.minAllocationPerUser = _pdi.minAllocationPerUser;
        idoInfo.maxAllocationPerUser = _pdi.maxAllocationPerUser;
    }

    receive() external payable {
        revert("Call deposit()");
    }

    function deposit(address _sender, uint256 _amount)
        external
        override
        onlyOwner
        _pooIsOngoing(poolInformation)
        _hardCapNotPassed(poolInformation.hardCap, _amount)
        _isAmountStaisfyAllocationRange(_amount)
    {
        IERC20(idoInfo.investmentTokenAddress).transferFrom(
            _sender,
            msg.sender,
            _amount
        );
        _increaseRaisedAmount(_amount);
        _addToParticipants(_sender, _amount);
        emit LogDeposit(_sender, _amount);
    }

    function updatePoolStatus(uint256 _newStatus) external override onlyOwner {
        require(_newStatus < 5 && _newStatus >= 0, "wrong Status;");
        uint256 currentStatus = uint256(poolInformation.status);
        poolInformation.status = PoolStatus(_newStatus);
        emit LogPoolStatusChanged(currentStatus, _newStatus);
    }

    function getCompletePoolDetails()
        external
        view
        override
        returns (CompletePoolDetails memory poolDetails)
    {
        poolDetails = CompletePoolDetails({
            participationDetails: _getParticipantsInfo(),
            totalRaised: _getTotalRaised(),
            pool: poolInformation,
            poolDetails: idoInfo
        });
    }

    function getInvestmentTokenAddress()
        external
        view
        override
        returns (address investmentTokenAddress)
    {
        return idoInfo.investmentTokenAddress;
    }

    // remove

    function _getParticipantsInfo()
        private
        view
        returns (Participations memory participants)
    {
        uint256 count = participantsAddress.length;

        ParticipantDetails[] memory parts = new ParticipantDetails[](count);

        for (uint256 i = 0; i < count; i++) {
            address userAddress = participantsAddress[i];
            parts[i] = ParticipantDetails(
                userAddress,
                collaborations[userAddress]
            );
        }
        participants.count = count;
        participants.investorsDetails = parts;
    }

    function _getTotalRaised() private view returns (uint256 amount) {
        amount = _amountRaised;
    }

    function _increaseRaisedAmount(uint256 _amount) private {
        require(_amount > 0, "No amount found!");
        _amountRaised += _amount;
    }

    function _addToParticipants(address _address, uint256 amount) private {
        require(!_didAlreadyParticipated(_address), "Already participated");
        _addToListOfParticipants(_address);
        _keepRecordOfAmountRaised(_address, amount);
    }

    function _didAlreadyParticipated(address _address)
        private
        view
        returns (bool isIt)
    {
        isIt = collaborations[_address] > 0;
    }

    function _addToListOfParticipants(address _address) private {
        participantsAddress.push(_address);
    }

    function _keepRecordOfAmountRaised(address _address, uint256 amount)
        private
    {
        collaborations[_address] += amount;
    }

    function _preValidatePoolCreation(IPool.PoolModel memory _pool)
        private
        view
    {
        require(_pool.hardCap > 0, "hardCap must be > 0");
        require(
            _pool.startDateTime > block.timestamp,
            "startDateTime must be > now"
        );
    }

    function _preIDOInfoUpdate(IDOInfo memory _idoInfo) private pure {
        require(
            address(_idoInfo.investmentTokenAddress) != address(0),
            "investmentTokenAddress is a zero address!"
        );
        require(
            _idoInfo.minAllocationPerUser > 0,
            "minAllocation must be > 0!"
        );
        require(
            _idoInfo.minAllocationPerUser < _idoInfo.maxAllocationPerUser,
            "minAllocation must be < max!"
        );
    }

    modifier _pooIsOngoing(IPool.PoolModel storage _pool) {
        require(_pool.status == IPool.PoolStatus.Ongoing, "Pool not open!");
        require(
            _pool.startDateTime <= block.timestamp,
            "Pool not started yet!"
        );
        require(_pool.endDateTime >= block.timestamp, "pool endDate passed!");

        _;
    }

    modifier _isPoolFinished(IPool.PoolModel storage _pool) {
        require(
            _pool.status == IPool.PoolStatus.Finished,
            "Pool status not Finished!"
        );
        _;
    }

    modifier _isAmountStaisfyAllocationRange(uint256 amount) {
        require(
            amount >= idoInfo.minAllocationPerUser &&
                amount <= idoInfo.maxAllocationPerUser,
            "Amount out of allocation range"
        ); // deposit between 500 USDT and 1000 USDT */
        _;
    }

    modifier _hardCapNotPassed(uint256 _hardCap, uint256 amount) {
        uint256 _beforeBalance = _getTotalRaised();

        uint256 sum = _getTotalRaised() + amount;
        require(sum <= _hardCap, "hardCap reached!");
        assert(sum > _beforeBalance);
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

library Validations {
    function revertOnZeroAddress(address _address) internal pure {
        require(address(0) != address(_address), "zero address not accepted!");
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