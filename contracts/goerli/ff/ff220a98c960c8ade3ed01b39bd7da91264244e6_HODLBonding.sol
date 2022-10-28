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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interface/IStaking.sol";
import "./interface/IOracle.sol";

contract HODLBonding is Ownable, ReentrancyGuard {
    using Address for address;

    IERC20 public immutable hfd; //HFD Token
    uint256 public initialPrice = 0.1 * 10**6; //0.1$
    bool public isDynamicPriceUsed; //Whether fixed price or dynamic price is used

    uint32 public startTime; //Time at which sale actually starts
    uint32 public limitActiveTill; //Time until which max cap is active
    uint256 public earlyBuyLimit; //Maximum amount that can be bought at initial stages

    IStaking public staking; //Staking contract interface
    IOracle public oracle; //Oracle contract interface

    //Goerli
    IERC20 internal constant USDC = IERC20(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);
    IERC20 internal constant USDT = IERC20(0xC2C527C0CACF457746Bd31B2a698Fe89de2b6d49);
    address public paymentReceiver; //Address where which payment is sent

    mapping(uint8 => uint256) public discountPerLock; //In percentage. 2 decimals
    mapping(address => uint256) public totalBought; //Total bought by a user

    modifier notContract() {
        require(!msg.sender.isContract(), "HODLBonding: Contracts not allowed");
        _;
    }

    event TokensPurchased(address indexed user, uint256 amount, address purchaseToken, uint8 lockId);

    constructor(
        address _hfd,
        address _staking,
        address  _oracle,
        address _receiver,
        uint32 _startTime,
        uint32 _limitActive,
        uint256 _earlyLimit
    ) {
        hfd = IERC20(_hfd);
        staking = IStaking(_staking);
        oracle = IOracle(_oracle);
        paymentReceiver = _receiver;
        startTime = _startTime;
        limitActiveTill = _limitActive;
        earlyBuyLimit = _earlyLimit;

        hfd.approve(address(staking), type(uint256).max);
    }

    function setLimits(uint32 _startTime, uint32 _limitActive, uint256 _earlyLimit) external onlyOwner {
        require(_limitActive >= _startTime, "HODL: Invalid limit");
        limitActiveTill = _limitActive;
        earlyBuyLimit = _earlyLimit;
        startTime = _startTime;
    }

    function setDiscounts(uint8[] calldata _lockIds, uint256[] calldata _discounts) external onlyOwner {
        require(_lockIds.length == _discounts.length, "HODL: invalid input");
        for (uint256 i = 0; i < _lockIds.length; i++) {
            discountPerLock[_lockIds[i]] = _discounts[i];
        }
    }

    function setDynamicPriceUsed(bool _value) external onlyOwner {
        isDynamicPriceUsed = _value;
    }

    function setContracts(address _newStaking, address _newOracle) external onlyOwner {
        staking = IStaking(_newStaking);
        oracle = IOracle(_newOracle);
    }

    function setReceiver(address _newReceiver) external onlyOwner {
        paymentReceiver = _newReceiver;
    }

    function buyHFD(
        uint256 _amount,
        address _token,
        uint8 _lockId
    ) external payable notContract nonReentrant {
        require(block.timestamp >= startTime, "HODL: Bond buy not active");
        if (block.timestamp <= limitActiveTill) {
            require(totalBought[msg.sender] + _amount <= earlyBuyLimit, "HODL: Amount exceeds max limit");
        }

        if (_token == address(0)) {
            uint256 price = isDynamicPriceUsed ? oracle.getPriceInETH(_amount) : oracle.convertUSDToETH(initialPrice);
            uint256 discountedPrice = price - ((price * discountPerLock[_lockId]) / 10000);
            require(msg.value >= discountedPrice, "HODL: Insufficient funds sent for purchase");

            Address.sendValue(payable(paymentReceiver), msg.value);
        } else {
            uint256 price = isDynamicPriceUsed ? oracle.getPriceInUSD(_amount) : initialPrice;
            uint256 discountedPrice = price - ((price * discountPerLock[_lockId]) / 10000);
            if (_token == address(USDC)) {
                USDC.transferFrom(msg.sender, paymentReceiver, discountedPrice);
            } else if (_token == address(USDT)) {
                USDT.transferFrom(msg.sender, paymentReceiver, discountedPrice);
            } else {
                revert("HODL: Invalid payment token");
            }
        }

        totalBought[msg.sender] += _amount;
        uint256[] memory amt = new uint256[](1);
        amt[0] = _amount;
        staking.deposit(0, _lockId, msg.sender, amt);

        emit TokensPurchased(msg.sender, _amount, _token, _lockId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IOracle {
    function consult(
        address tokenIn,
        uint256 amountIn,
        address tokenOut
    ) external view returns (uint256 amountOut);

    function convertETHToUSD(uint256 ethAmount) external view returns (uint256 usdAmount);

    function convertUSDToETH(uint256 usdAmount) external view returns (uint256 ethAmount);

    function getPriceInETH(uint256 tokenAmount) external view returns (uint256 ethAmount);

    function getPriceInUSD(uint256 tokenAmount) external view returns (uint256 usdAmount);

    function granularity() external view returns (uint8);

    function observationIndexOf(uint256 timestamp) external view returns (uint8 index);

    function owner() external view returns (address);

    function pair() external view returns (address);

    function pairObservations(uint256)
        external
        view
        returns (
            uint256 timestamp,
            uint256 price0Cumulative,
            uint256 price1Cumulative
        );

    function periodSize() external view returns (uint256);

    function priceFeed() external view returns (address);

    function renounceOwnership() external;

    function setChainlink(address _feed, bool _isUsing) external;

    function token() external view returns (address);

    function transferOwnership(address newOwner) external;

    function update() external;

    function windowSize() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IStaking {
    function add(
        uint8 _isInputNFT,
        uint8 _isVested,
        uint256 _allocPoint,
        address _input,
        uint256 _startIdx,
        uint256 _endIdx
    ) external;

    function canWithdraw(uint8 _lid, address _user) external view returns (bool);

    function claimReward(uint256 _pid) external;

    function deposit(
        uint256 _pid,
        uint8 _lid,
        address _benificiary,
        uint256[] memory _amounts
    ) external;

    function feeWallet() external view returns (address);

    function getDepositedIdsOfUser(uint256 _pid, address _user) external view returns (uint256[] memory);

    function getRewardPerBlock() external view returns (uint256 rpb);

    function massUpdatePools() external;

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external returns (bytes4);

    function owner() external view returns (address);

    function pendingTkn(uint256 _pid, address _user) external view returns (uint256);

    function percPerDay() external view returns (uint16);

    function poolInfo(uint256)
        external
        view
        returns (
            uint8 isInputNFT,
            uint8 isVested,
            uint32 totalInvestors,
            address input,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accTknPerShare,
            uint256 startIdx,
            uint256 endIdx,
            uint256 totalDeposit
        );

    function poolLength() external view returns (uint256);

    function poolLockInfo(uint256)
        external
        view
        returns (
            uint32 multi,
            uint32 claimFee,
            uint32 lockPeriodInSeconds
        );

    function renounceOwnership() external;

    function reward() external view returns (address);

    function rewardWallet() external view returns (address);

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint8 _isVested,
        uint256 _startIdx,
        uint256 _endIdx
    ) external;

    function setPercentagePerDay(uint16 _perc) external;

    function setPoolLock(
        uint256 _lid,
        uint32 _multi,
        uint32 _claimFee,
        uint32 _lockPeriod
    ) external;

    function setVesting(address _vesting) external;

    function setWallets(address _reward, address _feeWallet) external;

    function startBlock() external view returns (uint256);

    function totalActualDeposit() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function updatePool(uint256 _pid) external;

    function userInfo(uint256, address)
        external
        view
        returns (
            uint256 totalDeposit,
            uint256 rewardDebt,
            uint256 totalClaimed,
            uint256 depositTime
        );

    function userLockInfo(uint8, address) external view returns (uint256 totalActualDeposit, uint256 depositTime);

    function vestingCont() external view returns (address);

    function withdraw(
        uint256 _pid,
        uint8 _lid,
        uint256[] memory _amounts
    ) external;
}