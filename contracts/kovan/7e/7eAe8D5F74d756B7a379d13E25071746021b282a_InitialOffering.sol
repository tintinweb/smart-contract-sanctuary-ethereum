// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import "Ownable.sol";
import "IERC20.sol";

contract InitialOffering is Ownable {
    event Launch(
        address indexed beneficiary,
        uint32 minimalAmount,
        uint32 maximalAmount,
        uint32 startAt,
        uint32 endAt
    );

    enum IssuingSuccessChoices { MaximalAmountReached, MinimalAmountAndDurationReached}

    enum IssuingFailedChoices {FailedAmountAndDurationReached, Canceled }

    enum IssuingStatusChoices {MaximalAmountReached, MinimalAmountAndDurationReached, FailedAmountAndDurationReached,
        Canceled, NotCompleted, Settled}
//    IssuingStatusChoices constant defaultIssuingStatusChoices = IssuingStatusChoices.NotCompleted;

    //    IssuingStatusChoices public issuingStatus;
    //    IssuingStatusChoices constant public defaultIssuingStatusChoices = IssuingStatusChoices.NotCompleted;


    struct IssuingData {
        // Creator of campaign
        address beneficiary;
        // Amount of tokens to raise
        uint32 minimalAmount;
        uint32 maximalAmount;
        // Total amount pledged
        uint32 pledged;
        // Timestamp of start of campaign
        uint32 startAt;
        // Timestamp of end of campaign
        uint32 endAt;
        // True if initial offering has been either completed or canceled
//        IssuingStatusChoices status;
        bool issuingSucceed;
        bool issuingFailed;
        bool settled;
        //        bool closed;
    }

    IssuingData public initialOffering;

    //    event Cancel(IssuingData initialOffering);
    event Pledge(address indexed caller, uint32 amount);
    event Claim(address indexed beneficiary);
    event Refund(address indexed caller, uint32 amount);
    event Status(address indexed caller, uint32 amount);
    event ObtainingRapidBondzToken(address indexed caller, uint32 amount);
    event Settlement(IssuingData initialOffering);

//    event IssuingClosed(IssuingData initialOffering);
    event IssuingSucceed(IssuingData initialOffering);
    event IssuingFailed(IssuingData initialOffering);

    //    IERC20 public immutable stableCoin;
    IERC20 public stableCoin;
    IERC20 public rapidBondzToken;


    mapping(address => uint32) public pledgedAmountsDict;
    address[] public pledgers;


    constructor(
//        address payable __beneficiary,
//        uint32 __minimalAmount,
//        uint32 __maximalAmount,
//        uint32 __startAt,
//        uint32 __endAt
    ) {
//        launch(__beneficiary, __minimalAmount, __maximalAmount, __startAt, __endAt);
    }

    function launch(
        address payable _beneficiary,
        uint32 _minimalAmount,
        uint32 _maximalAmount,
        uint32 _startAt,
        uint32 _endAt
    ) external {
        // assure the launch of initial offering is future (is not already started)
        require(_startAt >= block.timestamp, "start at < now");
        // check if initial offering ends after time of launch
        require(_endAt >= _startAt, "end at < start at");
        // maximal duration of initial offering is set up to 90 days
        require(_endAt <= block.timestamp + 90 days, "end at > max duration");

        initialOffering = IssuingData({
        beneficiary : _beneficiary,
        minimalAmount : _minimalAmount,
        maximalAmount : _maximalAmount,
        pledged : 0,
        startAt : _startAt,
        endAt : _endAt,
//        status : defaultIssuingStatusChoices,
        issuingSucceed : false,
        issuingFailed : false,
        settled : false
        //                        canceled: false,
        //                        claimed: false
        });
        emit Launch(_beneficiary, _minimalAmount, _maximalAmount, _startAt, _endAt);
    }

    function cancel() external {
        require(block.timestamp < initialOffering.startAt, "started");
        initialOffering.issuingFailed = true;
        //        emit Cancel(initialOffering);
        emit IssuingFailed(initialOffering);
    }


    function pledge(uint32 _amount) external {
        //        Campaign storage campaign = campaigns[_id];
        require(block.timestamp >= initialOffering.startAt, "not started");
        require(block.timestamp <= initialOffering.endAt, "ended");
//        require(initialOffering.status == IssuingStatusChoices.NotCompleted, "initial offering closed");
        require(!initialOffering.issuingSucceed, "initial offering closed succeeded");
        require(!initialOffering.issuingFailed, "initial offering closed failed");
        require(initialOffering.pledged <= initialOffering.maximalAmount, "pledged amount exceeded maximalAmount");

        if (initialOffering.pledged + _amount >= initialOffering.maximalAmount) {

            // pledged amount is adjusted in order not to exceed maximalAmount
            _amount = initialOffering.maximalAmount - initialOffering.pledged;
            initialOffering.issuingSucceed = true;
//            initialOffering.status = IssuingStatusChoices.MaximalAmountReached;
            emit IssuingSucceed(initialOffering);
        }

        initialOffering.pledged += _amount;
        if (pledgedAmountsDict[msg.sender] == 0) {
            pledgers.push(msg.sender);
        }

        pledgedAmountsDict[msg.sender] += _amount;
        stableCoin.transferFrom(msg.sender, address(this), _amount);

        emit Pledge(msg.sender, _amount);
    }


    function settlement() external {
        require(block.timestamp > initialOffering.endAt, "not ended");
        require(initialOffering.pledged >= initialOffering.minimalAmount, "pledged < minimalAmount");
//        require(initialOffering.status == IssuingStatusChoices.MaximalAmountReached ||
//            initialOffering.status == IssuingStatusChoices.MinimalAmountAndDurationReached, "initial offering closed");
        require(initialOffering.issuingSucceed, "issuing not completed successfully");
        //        require(!initialOffering.claimed, "claimed");
        //        require(!issuingStatus.Canceled, "canceled");
        //        require(!initialOffering.canceled, "canceled");
//        require(initialOffering.issuingSucceed, "issuing not completed successfully");


        initialOffering.settled = true;
        stableCoin.transfer(initialOffering.beneficiary, initialOffering.pledged);

        for (
            uint256 pledgerIndex = 0;
            pledgerIndex < pledgers.length;
            pledgerIndex++
        ) {
            address user__ = pledgers[pledgerIndex];
            uint32 amount__ = pledgedAmountsDict[user__];
            rapidBondzToken.transfer(user__, amount__);
            emit ObtainingRapidBondzToken(user__, amount__);

            pledgers[pledgerIndex] = pledgers[pledgers.length - 1];
            pledgers.pop();
            pledgedAmountsDict[user__] = 0;
        }

        emit Claim(initialOffering.beneficiary);
        emit Settlement(initialOffering);
    }

    function refundMe() external {
        require(block.timestamp > initialOffering.endAt, "not ended");
        require(initialOffering.pledged < initialOffering.maximalAmount, "pledged >= maximalAmount");

        uint32 bal = pledgedAmountsDict[msg.sender];
        pledgedAmountsDict[msg.sender] = 0;
        stableCoin.transfer(msg.sender, bal);

        emit Refund(msg.sender, bal);
    }

    function refundAll() external {
        require(block.timestamp > initialOffering.endAt, "not ended");
        require(initialOffering.pledged < initialOffering.maximalAmount, "pledged >= maximalAmount");

        for (
            uint256 pledgerIndex = 0;
            pledgerIndex < pledgers.length;
            pledgerIndex++
        ) {
            address user__ = pledgers[pledgerIndex];
            uint32 amount__ = pledgedAmountsDict[user__];
            stableCoin.transfer(user__, amount__);
            emit Refund(user__, amount__);

            pledgers[pledgerIndex] = pledgers[pledgers.length - 1];
            pledgers.pop();
            pledgedAmountsDict[user__] = 0;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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