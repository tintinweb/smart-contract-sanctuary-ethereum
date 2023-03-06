// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "Ownable.sol";
import "IERC20.sol";
import "IRapidTokenUpgradeable.sol";

    error TransferFailed();

contract InitialOffering is Ownable {
//    using EnumerableMap for EnumerableMap.UintToAddressMap;

    event Launch(
        address indexed beneficiary,
        address indexed admin,
        uint256 feePerThousand,
        uint256 minimalAmount,
        uint256 maximalAmount,
        uint256 startAt,
        uint256 endAt
    );

    enum FUNDING_STATE {
        NOT_STARTED,
        IN_PROGRESS,
        SETTLED,
        REFUNDED,
        PAUSED
    }

    struct IssuingData {
        // Creator of campaign
        address beneficiary;
        // rapid bonz admin address - use for proxy transactions
        address admin;
        // fee collected by rapid bondz (per mille counter)
        uint256 feePerThousand;
        // Amount of tokens to raise
        uint256 minimalAmount;
        uint256 maximalAmount;
        // Total amount pledged
        uint256 pledgedTotalAmount;
        // Timestamp of start of campaign
        uint256 startAt;
        // Timestamp of end of campaign
        uint256 endAt;
        // True if initial offering has been launched
        bool launched;
        bool settled;
        bool refunded;
    }

    FUNDING_STATE public fundingState;
    bool stableCoinConfigured;
    bool rapidBondzContractConfigured;

    mapping(address => uint256) public pledgedAmountsDict;
    address[] public pledgers;

    struct FeesData {
        uint256 amountFees;
        uint256 pledgedAfterFees;
    }

    FeesData public feesData;
    IssuingData public initialOfferingData;

    IERC20 public stableCoin;
    IRapidTokenUpgradeable public rapidBondzContract;

    event Pledge(address indexed caller, uint256 amount);
    event Claim(address indexed beneficiary);
    event Refund(address indexed caller, uint256 amount);
    event Status(address indexed caller, uint256 amount);
    event ObtainingRapidBondzToken(address indexed caller, uint256 amount);
    event Settlement(IssuingData initialOfferingData);
    event AddStableCoinContract(IERC20 stableCoin);
    event AddRapidBondzContract(IRapidTokenUpgradeable rapidBondzContract);
    event InitialOfferingCancel(IssuingData initialOffering);

    constructor() {
        fundingState = FUNDING_STATE.NOT_STARTED;
    }

    function addStableCoinContract(address __stableCoin)
        public
        onlyOwner
    {
        require(
            fundingState == FUNDING_STATE.NOT_STARTED,
//            !initialOfferingData.launched,
            "stable coin can not be changed after launch"
        );
        stableCoin = IERC20(__stableCoin);
        stableCoinConfigured = true;
        emit AddStableCoinContract(stableCoin);
    }

    function addRapidBondzTokenContract(address __rapidBondzToken)
        public
        onlyOwner
    {
        require(
            fundingState == FUNDING_STATE.NOT_STARTED,
//            !initialOfferingData.launched,
            "rapid bondz contract can not be changed after launch"
        );
        rapidBondzContract = IRapidTokenUpgradeable(__rapidBondzToken);
        rapidBondzContractConfigured = true;
        emit AddRapidBondzContract(rapidBondzContract);
    }

    modifier rbTokenConfigured() {
        require(
            rapidBondzContractConfigured,
            "rapid bondz contract have to be pointed before launch"
        );
        _;
    }

    modifier scTokenConfigured() {
        require(
            stableCoinConfigured,
            "stable coin contract have to be pointed before launch"
        );
        _;
    }
    
    modifier rbTokenInitialized() {
        bool initialized = rapidBondzContract.getIsInitialized();
        require(initialized, "Rapid Bondz token have to be initialized initialized!");
        _;
    }


    function launch(
        address payable _beneficiary,
        address payable _admin,
        uint256 _feePerThousand,
        uint256 _minimalAmount,
        uint256 _maximalAmount,
        uint256 _startAt,
        uint256 _endAt
    )
        external
        onlyOwner
        rbTokenConfigured
        scTokenConfigured
        rbTokenInitialized
    {
        require(
            _minimalAmount < _maximalAmount,
            "minimalAmount has to be lower than maximalAmount"
        );

        // check if initial offering ends after time of launch
        require(_startAt < _endAt, "startDate has to be lower than endDate");

        require(
            _startAt + 3600 > block.timestamp,
            "startDate has to be greater than current timestamp"
        );
        fundingState = FUNDING_STATE.IN_PROGRESS;

        initialOfferingData = IssuingData({
            beneficiary: _beneficiary,
            admin: _admin,
            feePerThousand: _feePerThousand,
            minimalAmount: _minimalAmount,
            maximalAmount: _maximalAmount,
            pledgedTotalAmount: 0,
//            startAt: _startAt,
            startAt: _startAt,
            endAt: _endAt,
            launched: true,
            settled: false,
            refunded: false
        });

        emit Launch(
            _beneficiary,
            _admin,
            _feePerThousand,
            _minimalAmount,
            _maximalAmount,
            _startAt,
            _endAt
        );
    }

    function cancel() external {
        require(block.timestamp < initialOfferingData.startAt, "started");
        emit InitialOfferingCancel(initialOfferingData);
    }

    function pledge(uint256 _amount)
    external
    {
        // to avoid errors generated by time difference in between offchain timestamp and chain timestamp especially in
        // testing _startAt is automatically updated if difference is irrelevant (less than 1 hour = 60s * 60 min)
        require(
            initialOfferingData.startAt + 3600 > block.timestamp,
            "startDate has to be greater than current timestamp"
        );

        if (initialOfferingData.pledgedTotalAmount + _amount > initialOfferingData.maximalAmount) {
            // pledged amount is adjusted in order not to exceed maximalAmount
            _amount = initialOfferingData.maximalAmount - initialOfferingData.pledgedTotalAmount;
        }

        initialOfferingData.pledgedTotalAmount += _amount;
        if (pledgedAmountsDict[msg.sender] == 0) {
            pledgers.push(msg.sender);
        }

        pledgedAmountsDict[msg.sender] += _amount;
        stableCoin.transferFrom(msg.sender, address(this), _amount);
        emit Pledge(msg.sender, _amount);
    }

    event PledgedTotal(uint256 pledged);
    function getPledgedAmount() public {
        emit PledgedTotal(initialOfferingData.pledgedTotalAmount);
    }

    function retrievePledgedAmount() public view returns (uint256) {
        return (initialOfferingData.pledgedTotalAmount);
    }

    function retrievePledgers() public view returns (address[] memory) {
        return pledgers;
    }

    function settlement()
        public
        onlyOwner
    {
        feesData.amountFees =
            (initialOfferingData.pledgedTotalAmount * initialOfferingData.feePerThousand) /
            1000;
        feesData.pledgedAfterFees =
            initialOfferingData.pledgedTotalAmount -
            feesData.amountFees;

        //3lines bellow to are for production purpose (it can cause errors in testing)
        require(
            block.timestamp > initialOfferingData.endAt,
            "Initial offering is not ended"
        );
        require(
            initialOfferingData.pledgedTotalAmount >= initialOfferingData.minimalAmount,
            "pledged < minimalAmount"
        );

        stableCoin.transfer(msg.sender, feesData.amountFees);
        stableCoin.transfer(
            initialOfferingData.beneficiary,
            feesData.pledgedAfterFees
        );

        for (
            uint256 pledgerIndex = 0;
            pledgerIndex < pledgers.length;
//            pledgerIndex++
        ) {

            if (pledgers[pledgerIndex]== address(0)) {
                pledgers.push(msg.sender);
            }

            address user__ = pledgers[pledgerIndex];
            uint256 amount__ = pledgedAmountsDict[user__];
            bool success = rapidBondzContract.transfer(user__, amount__);
            if (!success) revert TransferFailed();
            emit ObtainingRapidBondzToken(user__, amount__);

            unchecked {
                ++pledgerIndex;
            }
        }

        fundingState = FUNDING_STATE.SETTLED;
//        initialOfferingData.settled = true;
        emit Claim(initialOfferingData.beneficiary);
        emit Settlement(initialOfferingData);
    }

    function refundAll() external {
        //2 lines bellow to are for production purpose (it can cause errors in testing)
        require(block.timestamp > initialOfferingData.endAt, "not ended");
        require(
            initialOfferingData.pledgedTotalAmount < initialOfferingData.maximalAmount,
            "pledged >= maximalAmount"
        );

        for (
            uint256 pledgerIndex = 0;
            pledgerIndex < pledgers.length;
//            pledgerIndex++
        ) {
            address user__ = pledgers[pledgerIndex];
            uint256 amount__ = pledgedAmountsDict[user__];
            stableCoin.transfer(user__, amount__);
            emit Refund(user__, amount__);

            pledgers[pledgerIndex] = pledgers[pledgers.length - 1];
            pledgers.pop();
            pledgedAmountsDict[user__] = 0;
            unchecked {
                ++pledgerIndex;
            }
        }
        fundingState = FUNDING_STATE.REFUNDED;
//        initialOfferingData.refunded = true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
pragma solidity ^0.8.17;

import "IERC20Upgradeable.sol";

interface IRapidTokenUpgradeable is IERC20Upgradeable {
    function getIsInitialized() external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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