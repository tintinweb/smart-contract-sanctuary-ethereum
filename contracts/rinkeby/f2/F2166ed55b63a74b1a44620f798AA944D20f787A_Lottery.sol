// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Lottery is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum LOTTERY_STATE {
        NOT_STARTED,
        ACTIVE,
        CLOSED
    }

    enum Status {
        active,
        inactive,
        expired
    }

    struct Ticket {
        address player;
        uint32 ticket;
    }

    struct DropInfo {
        string photo;
        string title;
        string titleLink;
        string supplier;
        string supplierLink;
        uint256 itemAvax;
        uint256 itemUsd;
        uint256 dropAvax;
        uint256 dropUsd;
        uint256 startDate;
        uint256 endDate;
        uint256 duration;
        uint256 ticketQuota;
        string dropType;
    }

    struct LotteryInfo {
        address[] players;
        address creator;
        address[] winners;
        address winner;
        Ticket[] tickets;
        DropInfo dropInfo;
        Status status;
        bool nftSent;
    }

    address public payToken;
    uint256 public minAmount;
    address public treasury;
    address public rewardDistributor;

    /// @dev current active lottery id
    uint256 public currentLotteryId;

    /// @dev lottery id => Lottry info
    mapping(uint256 => LotteryInfo) public lotteries;
    LotteryInfo[] lotteryList;

    /// @dev lottery id => user index => status
    mapping(uint256 => mapping(uint256 => bool)) _winnerSelected;

    event LotterySaved(
        address indexed creator,
        uint256 indexed lotteryId,
        uint256 timestamp
    );
    event LotteryEntered(
        address indexed participant,
        uint256 indexed lotteryId,
        uint256 amount,
        uint32[] ticketNumbers,
        uint256 timestamp
    );
    event LotteryEnded(
        address indexed creator,
        uint256 indexed lotteryId,
        uint256 timestamp
    );

    /**
     * @dev Construct Lottery contract
     * @param _payToken address of pay token
     * @param _minAmount minimum amount of pay token
     * @param _treasury address of treasury
     * @param _rewardDistributor address of rewardDistributor
     */
    constructor(
        address _payToken,
        uint256 _minAmount,
        address _treasury,
        address _rewardDistributor
    ) {
        require(_payToken != address(0), "Error: payToken address is zero");
        require(_treasury != address(0), "Error: treasury address is zero");
        require(
            _rewardDistributor != address(0),
            "Error: rewardDistributor address is zero"
        );

        payToken = _payToken;
        minAmount = _minAmount;
        treasury = _treasury;
        rewardDistributor = _rewardDistributor;

        currentLotteryId = 0;
    }

    /**
     * @dev Get lottery from lotteryId
     */
    function getLotteryInfo(uint256 _lotteryId)
        public
        view
        returns (LotteryInfo memory)
    {
        return lotteries[_lotteryId];
    }

    /**
     * @dev Create or Update lottry only from owner
     */
    function handleLottery(DropInfo calldata _data, uint256 _lotteryId)
        public
        onlyOwner
    {
        if (_lotteryId == 0) {
            currentLotteryId += 1;
        } else {
            currentLotteryId = _lotteryId;
        }
        lotteries[currentLotteryId].creator = msg.sender;
        lotteries[currentLotteryId].dropInfo.photo = _data.photo;
        lotteries[currentLotteryId].dropInfo.title = _data.title;
        lotteries[currentLotteryId].dropInfo.titleLink = _data.titleLink;
        lotteries[currentLotteryId].dropInfo.supplier = _data.supplier;
        lotteries[currentLotteryId].dropInfo.supplierLink = _data.supplierLink;
        lotteries[currentLotteryId].dropInfo.itemAvax = _data.itemAvax;
        lotteries[currentLotteryId].dropInfo.itemUsd = _data.itemUsd;
        lotteries[currentLotteryId].dropInfo.dropAvax = _data.dropAvax;
        lotteries[currentLotteryId].dropInfo.dropUsd = _data.dropUsd;
        lotteries[currentLotteryId].dropInfo.startDate = _data.startDate;
        lotteries[currentLotteryId].dropInfo.endDate = _data.endDate;
        lotteries[currentLotteryId].dropInfo.duration = _data.duration;
        lotteries[currentLotteryId].dropInfo.ticketQuota = _data.ticketQuota;
        lotteries[currentLotteryId].dropInfo.dropType = _data.dropType;
        lotteries[currentLotteryId].status = Status.inactive;
        lotteryList.push(lotteries[currentLotteryId]);

        emit LotterySaved(msg.sender, currentLotteryId, block.timestamp);
    }

    function activateLottery(uint256[] calldata _lotteryIds)
        public
        onlyOwner
        returns (bool)
    {
        for (uint256 i = 0; i < _lotteryIds.length; i++) {
            require(
                lotteries[i].status == Status.inactive,
                "Please select only inactive drops."
            );
        }
        for (uint256 i = 0; i < _lotteryIds.length; i++) {
            lotteries[i].status = Status.active;
        }
        return true;
    }

    function deactivateLottery(uint256[] calldata _lotteryIds)
        public
        onlyOwner
        returns (bool)
    {
        for (uint256 i = 0; i < _lotteryIds.length; i++) {
            require(
                lotteries[i].status == Status.active,
                "Please select only active drops."
            );
        }
        for (uint256 i = 0; i < _lotteryIds.length; i++) {
            lotteries[i].status = Status.inactive;
        }
        return true;
    }

    /**
     * @dev Enter lottery
     * @param _lotteryId lottery id
     * @param _amount amount of pay token
     */
    function enterLottery(
        uint256 _lotteryId,
        uint256 _amount,
        uint32[] calldata _ticketNumbers
    ) public {
        require(
            lotteries[_lotteryId].status == Status.active,
            "Lottery is not active"
        );
        require(_amount > 0, "Not enough pay token!");
        require(
            msg.sender != lotteries[_lotteryId].creator,
            "Lottery creator can't participate"
        );
        require(_ticketNumbers.length > 0, "Not enough tickets!");

        // transfer payToken from user to lottery
        IERC20(payToken).safeTransferFrom(msg.sender, treasury, _amount);

        lotteries[_lotteryId].players.push(msg.sender);
        for (uint256 i = 0; i < _ticketNumbers.length; i++) {
            Ticket memory _ticket;
            _ticket.player = msg.sender;
            _ticket.ticket = _ticketNumbers[i];
            lotteries[_lotteryId].tickets.push(_ticket);
        }

        emit LotteryEntered(
            msg.sender,
            _lotteryId,
            _amount,
            _ticketNumbers,
            block.timestamp
        );
    }

    /**
     * @dev End lottery and choose winner by only owner
     * @param _lotteryId lottery id
     */
    function endLottery(uint256 _lotteryId) public onlyOwner nonReentrant {
        require(
            lotteries[_lotteryId].status == Status.active,
            "Lottery is not active"
        );
        require(
            lotteries[_lotteryId].players.length > 1,
            "Error: less than 2 participants"
        );

        // choose winners
        _drawWinner(_lotteryId);

        emit LotteryEnded(msg.sender, _lotteryId, block.timestamp);
    }

    /**
     * @notice Change minimum amount of payToken to enter lottery
     * @param _minAmount     amount of minAmount
     */
    function changeMinPayTokenAmount(uint256 _minAmount) external onlyOwner {
        minAmount = _minAmount;
    }

    /**
     * @notice Change treasury address
     * @param _treasury  address of treasury
     */
    function changeTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Error: treasury address is zero");
        treasury = _treasury;
    }

    /**
     * @notice Change rewardDistributor address
     * @param _rewardDistributor  address of rewardDistributor
     */
    function changeRewardDistributor(address _rewardDistributor)
        external
        onlyOwner
    {
        require(
            _rewardDistributor != address(0),
            "Error: rewardDistributor address is zero"
        );
        rewardDistributor = _rewardDistributor;
    }

    /**
     * @notice Draw 3 winners
     * @param _lotteryId lottery id
     */
    function _drawWinner(uint256 _lotteryId) internal {
        address[] memory lotteryPlayers = lotteries[_lotteryId].players;
        Ticket[] memory tickets = lotteries[_lotteryId].tickets;
        // it's increased when same random number is generated
        uint256 pIdx;

        uint256 indexOfWinner;
        // get random number
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty, // can actually be manipulated by the miners!
                    block.timestamp, // timestamp is predictable
                    lotteryPlayers, // lottery players
                    pIdx
                )
            )
        );

        indexOfWinner = randomNumber % tickets.length;
        lotteries[_lotteryId].winner = lotteries[_lotteryId]
            .tickets[indexOfWinner]
            .player;

        // change lottery status
        lotteries[currentLotteryId].status = Status.expired;
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}