// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./helpers/Whitelist.sol";
import "./interfaces/IUniswapRouterV2.sol";

pragma solidity 0.8.17;

contract TokenSale is Ownable, Whitelist {
    using SafeERC20 for IERC20;
    using Address for address;

    IUniswapV2Router public swapRouter; // swap router

    struct TokenSaleRound {
        uint256 startTime; // tokenSale round start time timestamp
        uint256 endTime; // tokenSale round end time timestamp
        uint256 duration; // tokenSale round duration
        uint256 minAmount; // min purchase amount
        uint256 maxAmount; // max purchase amount
        uint256 purchasePrice; // purchase price
        uint256 tokensSold; // number of tokens sold
        uint256 totalPurchaseAmount; // number of tokens on sale
        uint256 tokenSaleType; // 0 - pre_sale; 1 - main_sale; 2 - private_sale
        bool isPublic; // if true then round is public, else is private
        bool isEnded; // active tokenSale if true, if false vesting is end
    }

    address public usdtToken; // usdt or busd token address
    address[] public path; // path for get price eth or bnb
    address public treasury; // treasury address
    uint256 public roundsCounter; // quantity of tokeSale rounds
    uint256 public immutable PRECISSION = 1000; // 10000; // precission for math operation

    mapping(uint256 => TokenSaleRound) public rounds; // 0 pre_sale; 1 main_sale; 2 private_sale;
    mapping(address => mapping(uint256 => uint256)) public userBalance; // return user balance of planetex token
    mapping(address => mapping(uint256 => uint256)) public userSpentFunds; // return user spent funds in token sale

    //// @errors

    //// @dev - unequal length of arrays
    error InvalidArrayLengths(string err);
    /// @dev - address to the zero;
    error ZeroAddress(string err);
    /// @dev - user not in the whitelist
    error NotInTheWhitelist(string err);
    /// @dev - round not started
    error RoundNotStarted(string err);
    /// @dev - round is started
    error RoundIsStarted(string err);
    /// @dev - amount more or less than min or max
    error MinMaxPurchase(string err);
    /// @dev - tokens not enough
    error TokensNotEnough(string err);
    /// @dev - msg.value cannot be zero
    error ZeroMsgValue(string err);
    /// @dev - round with rhis id not found
    error RoundNotFound(string err);
    /// @dev - round is ended
    error RoundNotEnd(string err);

    ////@notice emitted when the user purchase token
    event PurchasePlanetexToken(
        address user,
        uint256 spentAmount,
        uint256 receivedAmount
    );
    ////@notice emitted when the owner withdraw unsold tokens
    event WithdrawUnsoldTokens(
        uint256 roundId,
        address recipient,
        uint256 amount
    );
    ////@notice emitted when the owner update round start time
    event UpdateRoundStartTime(
        uint256 roundId,
        uint256 startTime,
        uint256 endTime
    );

    constructor(
        uint256[] memory _purchasePercents, // array of round purchase percents
        uint256[] memory _minAmounts, // array of round min purchase amounts
        uint256[] memory _maxAmounts, // array of round max purchase amounts
        uint256[] memory _durations, // array of round durations in seconds
        uint256[] memory _purchasePrices, // array of round purchase prices
        uint256[] memory _startTimes, // array of round start time timestamps
        bool[] memory _isPublic, // array of isPublic bool indicators
        uint256 _planetexTokenTotalSupply, // planetex token total supply
        address _usdtToken, // usdt token address
        address _treasury, // treasury address
        address _unirouter // swap router address
    ) {
        if (
            _purchasePercents.length != _minAmounts.length ||
            _purchasePercents.length != _maxAmounts.length ||
            _purchasePercents.length != _durations.length ||
            _purchasePercents.length != _purchasePrices.length ||
            _purchasePercents.length != _isPublic.length ||
            _purchasePercents.length != _startTimes.length
        ) {
            revert InvalidArrayLengths("TokenSale: Invalid array lengths");
        }
        if (
            _usdtToken == address(0) ||
            _treasury == address(0) ||
            _unirouter == address(0)
        ) {
            revert ZeroAddress("TokenSale: Zero Address");
        }

        for (uint256 i; i <= _purchasePercents.length - 1; i++) {
            TokenSaleRound storage tokenSaleRound = rounds[i];
            tokenSaleRound.duration = _durations[i];
            tokenSaleRound.startTime = _startTimes[i];
            tokenSaleRound.endTime = _startTimes[i] + _durations[i];
            tokenSaleRound.minAmount = _minAmounts[i];
            tokenSaleRound.maxAmount = _maxAmounts[i];
            tokenSaleRound.purchasePrice = _purchasePrices[i];
            tokenSaleRound.tokensSold = 0;
            tokenSaleRound.totalPurchaseAmount =
                (_planetexTokenTotalSupply * _purchasePercents[i]) /
                PRECISSION;
            tokenSaleRound.isPublic = _isPublic[i];
            tokenSaleRound.isEnded = false;
            tokenSaleRound.tokenSaleType = i;
        }
        roundsCounter = _purchasePercents.length - 1;
        usdtToken = _usdtToken;
        treasury = _treasury;
        swapRouter = IUniswapV2Router(_unirouter);
        address[] memory _path = new address[](2);
        _path[0] = IUniswapV2Router(_unirouter).WETH();
        _path[1] = _usdtToken;
        path = _path;
    }

    /**
    @dev The modifier checks whether the tokenSale round has not expired.
    @param roundId tokenSale round id.
    */
    modifier isEnded(uint256 roundId) {
        TokenSaleRound storage tokenSaleRound = rounds[roundId];
        if (roundId > roundsCounter) {
            revert RoundNotFound("TokenSale: Round not found");
        }
        require(
            tokenSaleRound.endTime > block.timestamp,
            "TokenSale: Round is ended"
        );
        _;
    }

    //// External functions

    receive() external payable {}

    /**
    @dev The function performs the purchase of tokens for usdt or busd tokens
    @param roundId tokeSale round id.
    @param amount usdt or busd amount.
    */
    function buyForErc20(uint256 roundId, uint256 amount)
        external
        isEnded(roundId)
    {
        TokenSaleRound storage tokenSaleRound = rounds[roundId];

        if (!tokenSaleRound.isPublic) {
            if (!whitelist[msg.sender]) {
                revert NotInTheWhitelist("TokenSale: Not in the whitelist");
            }
        }

        if (!isRoundStared(roundId)) {
            revert RoundNotStarted("TokenSale: Round is not started");
        }

        if (
            amount < tokenSaleRound.minAmount ||
            amount > tokenSaleRound.maxAmount
        ) {
            revert MinMaxPurchase("TokenSale: Amount not allowed");
        }

        uint256 tokenAmount = _calcPurchaseAmount(
            amount,
            tokenSaleRound.purchasePrice
        );

        if (
            tokenSaleRound.tokensSold + tokenAmount >
            tokenSaleRound.totalPurchaseAmount
        ) {
            revert TokensNotEnough("TokenSale: Tokens not enough");
        }
        if (
            userSpentFunds[msg.sender][roundId] + amount >
            tokenSaleRound.maxAmount
        ) {
            revert MinMaxPurchase("TokenSale: Amount not allowed");
        }

        tokenSaleRound.tokensSold += tokenAmount;
        userSpentFunds[msg.sender][roundId] += amount;

        IERC20(usdtToken).safeTransferFrom(msg.sender, treasury, amount);

        userBalance[msg.sender][roundId] += tokenAmount;

        _endSoldOutRound(roundId);
        emit PurchasePlanetexToken(msg.sender, amount, tokenAmount);
    }

    /**
    @dev The function performs the purchase of tokens for eth or bnb tokens
    @param roundId tokeSale round id.
    */
    function buyForEth(uint256 roundId) external payable isEnded(roundId) {
        if (msg.value == 0) {
            revert ZeroMsgValue("TokenSale: Zero msg.value");
        }

        TokenSaleRound storage tokenSaleRound = rounds[roundId];

        if (!tokenSaleRound.isPublic) {
            if (!whitelist[msg.sender]) {
                revert NotInTheWhitelist("TokenSale: Not in the whitelist");
            }
        }

        if (!isRoundStared(roundId)) {
            revert RoundNotStarted("TokenSale: Round is not started");
        }

        uint256[] memory amounts = swapRouter.getAmountsOut(msg.value, path);

        if (
            amounts[1] < tokenSaleRound.minAmount ||
            amounts[1] > tokenSaleRound.maxAmount
        ) {
            revert MinMaxPurchase("TokenSale: Amount not allowed");
        }

        uint256 tokenAmount = _calcPurchaseAmount(
            amounts[1],
            tokenSaleRound.purchasePrice
        );

        if (
            tokenSaleRound.tokensSold + tokenAmount >
            tokenSaleRound.totalPurchaseAmount
        ) {
            revert TokensNotEnough("TokenSale: Tokens not enough");
        }

        if (
            userSpentFunds[msg.sender][roundId] + amounts[1] >
            tokenSaleRound.maxAmount
        ) {
            revert MinMaxPurchase("TokenSale: Amount not allowed");
        }

        tokenSaleRound.tokensSold += tokenAmount;
        userSpentFunds[msg.sender][roundId] += amounts[1];

        userBalance[msg.sender][roundId] += tokenAmount;

        _endSoldOutRound(roundId);

        (bool sent, ) = treasury.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        emit PurchasePlanetexToken(msg.sender, amounts[1], tokenAmount);
    }

    /**
    @dev The function withdraws tokens that were not sold and writes 
    them to the balance of the specified wallet.Only owner can call it. 
    Only if round is end.
    @param roundId tokeSale round id.
    @param recipient recipient wallet address
    */
    function withdrawUnsoldTokens(uint256 roundId, address recipient)
        external
        onlyOwner
    {
        if (roundId > roundsCounter) {
            revert RoundNotFound("TokenSale: Round not found");
        }
        TokenSaleRound storage tokenSaleRound = rounds[roundId];
        if (tokenSaleRound.endTime > block.timestamp) {
            revert RoundNotEnd("TokenSale: Round not end");
        }
        if (tokenSaleRound.totalPurchaseAmount > tokenSaleRound.tokensSold) {
            uint256 unsoldTokens = tokenSaleRound.totalPurchaseAmount -
                tokenSaleRound.tokensSold;
            tokenSaleRound.tokensSold = tokenSaleRound.totalPurchaseAmount;
            userBalance[recipient][roundId] += unsoldTokens;
            emit WithdrawUnsoldTokens(roundId, recipient, unsoldTokens);
        } else {
            revert TokensNotEnough("TokenSale: Sold out");
        }

        tokenSaleRound.isEnded = true;
    }

    /**
    @dev The function update token sale round start time.Only owner can call it. 
    Only if round is not started.
    @param roundId tokeSale round id.
    @param newStartTime new start time timestamp
    */
    function updateStartTime(uint256 roundId, uint256 newStartTime)
        external
        onlyOwner
    {
        if (roundId > roundsCounter) {
            revert RoundNotFound("TokenSale: Round not found");
        }
        TokenSaleRound storage tokenSaleRound = rounds[roundId];
        if (tokenSaleRound.startTime < block.timestamp) {
            revert RoundIsStarted("TokenSale: Round is started");
        }

        tokenSaleRound.startTime = newStartTime;
        tokenSaleRound.endTime = newStartTime + tokenSaleRound.duration;
        emit UpdateRoundStartTime(
            roundId,
            tokenSaleRound.startTime,
            tokenSaleRound.endTime
        );
    }

    //// Public Functions

    function convertToStable(uint256 amount, uint256 roundId)
        public
        view
        returns (
            uint256 ethAmount,
            uint256 usdtAmount,
            uint256 planetexAmount
        )
    {
        TokenSaleRound storage tokenSaleRound = rounds[roundId];
        if (amount > 0) {
            uint256[] memory amounts = swapRouter.getAmountsOut(amount, path);
            ethAmount = amounts[0];
            usdtAmount = amounts[1];
            planetexAmount = _calcPurchaseAmount(
                usdtAmount,
                tokenSaleRound.purchasePrice
            );
        } else {
            ethAmount = 0;
            usdtAmount = 0;
            planetexAmount = 0;
        }
    }

    function getUserAvailableAmount(address user, uint256 roundId)
        public
        view
        returns (
            uint256 ethAmount,
            uint256 usdtAmount,
            uint256 planetexAmount
        )
    {
        TokenSaleRound storage tokenSaleRound = rounds[roundId];
        usdtAmount = tokenSaleRound.maxAmount - userSpentFunds[user][0];
        if (usdtAmount > 0) {
            planetexAmount = _calcPurchaseAmount(
                usdtAmount,
                tokenSaleRound.purchasePrice
            );
            address[] memory pathToEth = new address[](2);
            pathToEth[0] = usdtToken;
            pathToEth[1] = swapRouter.WETH();
            uint256[] memory amounts = swapRouter.getAmountsOut(
                usdtAmount,
                pathToEth
            );
            ethAmount = amounts[1];
        } else {
            ethAmount = 0;
            planetexAmount = 0;
            usdtAmount = 0;
        }
    }

    /**
    @dev The function shows whether the round has started. Returns true if yes, false if not
    @param roundId tokeSale round id.
    */
    function isRoundStared(uint256 roundId) public view returns (bool) {
        if (roundId > roundsCounter) {
            revert RoundNotFound("TokenSale: Round not found");
        }
        TokenSaleRound storage tokenSaleRound = rounds[roundId];
        return (block.timestamp >= tokenSaleRound.startTime &&
            block.timestamp <= tokenSaleRound.endTime);
    }

    /**
    @dev The function returns the timestamp of the end of the tokenSale round
    @param roundId tokeSale round id.
    */
    function getRoundEndTime(uint256 roundId) public view returns (uint256) {
        if (roundId > roundsCounter) {
            revert RoundNotFound("TokenSale: Round not found");
        }
        TokenSaleRound storage tokenSaleRound = rounds[roundId];
        return tokenSaleRound.endTime;
    }

    /**
    @dev The function returns the timestamp of the start of the tokenSale round
    @param roundId tokeSale round id.
    */
    function getRoundStartTime(uint256 roundId) public view returns (uint256) {
        if (roundId > roundsCounter) {
            revert RoundNotFound("TokenSale: Round not found");
        }
        TokenSaleRound storage tokenSaleRound = rounds[roundId];
        return tokenSaleRound.startTime;
    }

    //// Internal Functions

    /**
    @dev The function ends the round if all tokens are sold out
    @param roundId tokeSale round id.
    */
    function _endSoldOutRound(uint256 roundId) internal {
        TokenSaleRound storage tokenSaleRound = rounds[roundId];

        if (tokenSaleRound.tokensSold == tokenSaleRound.totalPurchaseAmount) {
            tokenSaleRound.isEnded = true;
        }
    }

    /**
    @dev The function calculates the number of tokens to be received by the user
    @param amount usdt or busd token amount.
    @param price purchase price
    */
    function _calcPurchaseAmount(uint256 amount, uint256 price)
        internal
        pure
        returns (uint256 tokenAmount)
    {
        tokenAmount = (amount / price) * 1e18;
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

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * @dev This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;

    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);

    /**
     * @dev add an address to the whitelist
     * @param addr address
     * @return success if the address was added to the whitelist, false if the address was already in the whitelist
     */
    function addAddressToWhitelist(address addr)
        public
        onlyOwner
        returns (bool success)
    {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            emit WhitelistedAddressAdded(addr);
            success = true;
        }
    }

    /**
     * @dev add addresses to the whitelist
     * @param addrs addresses
     * @return success if at least one address was added to the whitelist,
     * false if all addresses were already in the whitelist
     */
    function addAddressesToWhitelist(address[] memory addrs)
        public
        onlyOwner
        returns (bool success)
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addAddressToWhitelist(addrs[i])) {
                success = true;
            }
        }
    }

    /**
     * @dev remove an address from the whitelist
     * @param addr address
     * @return success if the address was removed from the whitelist,
     * false if the address wasn't in the whitelist in the first place
     */
    function removeAddressFromWhitelist(address addr)
        public
        onlyOwner
        returns (bool success)
    {
        if (whitelist[addr]) {
            whitelist[addr] = false;
            emit WhitelistedAddressRemoved(addr);
            success = true;
        }
    }

    /**
     * @dev remove addresses from the whitelist
     * @param addrs addresses
     * @return success if at least one address was removed from the whitelist,
     * false if all addresses weren't in the whitelist in the first place
     */
    function removeAddressesFromWhitelist(address[] memory addrs)
        public
        onlyOwner
        returns (bool success)
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (removeAddressFromWhitelist(addrs[i])) {
                success = true;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
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