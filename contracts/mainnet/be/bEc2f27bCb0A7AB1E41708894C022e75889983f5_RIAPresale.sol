//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./lib/IERC20.sol";
import "./lib/Address.sol";
import "./lib/Context.sol";
import "./lib/Pausable.sol";
import "./lib/Ownable.sol";
import "./lib/ReentrancyGuard.sol";

interface Aggregator {
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint startedAt,
        uint updatedAt,
        uint80 answeredInRound
    );
}

contract RIAPresale is ReentrancyGuard, Ownable, Pausable {
    uint public salePrice;
    uint public totalTokensForPresale;
    uint public minimumBuyAmount;
    uint public inSale;
    uint public priceStep;
    uint public periodSize;
    uint public startTime;
    uint public endTime;
    uint public claimStart;
    uint public baseDecimals;

    address public saleToken;
    address dataOracle;
    address USDTtoken;
    address USDCtoken;
    address BUSDtoken;
    address DAItoken;

    mapping(address => uint) public userDeposits;
    mapping(address => bool) public hasClaimed;

    event TokensBought(
        address indexed user,
        uint indexed tokensBought,
        address indexed purchaseToken,
        uint amountPaid,
        uint timestamp
    );

    event TokensClaimed(
        address indexed user,
        uint amount,
        uint timestamp
    );

    constructor(uint _startTime, uint _endTime, address _oracle, address _usdt, address _usdc, address _busd, address _dai) {
        require(_startTime > block.timestamp && _endTime > _startTime, "Invalid time");
        baseDecimals = (10 ** 18);
        salePrice = 0.01 * (10 ** 18); //USD
        priceStep = 0.0025 * (10 ** 18); //USD
        periodSize = 30_000_000;
        totalTokensForPresale = 300_000_000;
        minimumBuyAmount = 1000;
        inSale = totalTokensForPresale;
        startTime = _startTime;
        endTime = _endTime;
        dataOracle = _oracle;
        USDTtoken = _usdt;
        USDCtoken = _usdc;
        BUSDtoken = _busd;
        DAItoken = _dai;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function calculatePrice(uint256 _amount) internal view returns (uint256 totalValue) {
        uint256 totalSold = totalTokensForPresale - inSale;

        if(totalSold + _amount <= periodSize) return (_amount * salePrice);
        else {
            uint256 extra = (totalSold + _amount) - periodSize;
            uint256 _salePrice = salePrice;

            if(totalSold >= periodSize) {
                _salePrice = (_salePrice + priceStep) + (((totalSold - periodSize) / periodSize) * priceStep);

                uint256 period = _amount / periodSize;

                if(period == 0) return (_amount * _salePrice);
                else {
                    while(period > 0) {
                        totalValue = totalValue + (periodSize * _salePrice);
                        _amount -= periodSize;
                        _salePrice += priceStep;
                        period--;
                    }

                    if(_amount > 0) totalValue += (_amount * _salePrice);
                }
            } else {
                totalValue = (_amount - extra) * _salePrice;
                if(extra <= periodSize) return totalValue + (extra * ((_salePrice * 125) / 100));
                else {
                    while(extra >= periodSize) {
                        _salePrice += priceStep;
                        totalValue = totalValue + (periodSize * _salePrice);
                        extra -= periodSize;
                    }

                    if(extra > 0) {
                        _salePrice += priceStep;
                        totalValue += (extra * _salePrice);
                    }
                    return totalValue;
                }
            }
        }
    }

    function getETHLatestPrice() public view returns (uint) {
        (, int256 price, , , ) = Aggregator(dataOracle).latestRoundData();
        price = (price * (10 ** 10));
        return uint(price);
    }

    function sendValue(address payable recipient, uint amount) internal {
        require(address(this).balance >= amount, "Low balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH Payment failed");
    }

    modifier checkSaleState(uint amount) {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Invalid time for buying");
        require(amount >= minimumBuyAmount, "Too small amount");
        require(amount > 0 && amount <= inSale, "Invalid sale amount");
        _;
    }

    function buyWithEth(uint amount) external payable checkSaleState(amount) whenNotPaused nonReentrant {
        uint usdPrice = calculatePrice(amount);
        uint ethAmount = (usdPrice * baseDecimals) / getETHLatestPrice();
        require(msg.value >= ethAmount, "Less payment");
        uint excess = msg.value - ethAmount;
        inSale -= amount;
        userDeposits[_msgSender()] += (amount * baseDecimals);
        sendValue(payable(owner()), ethAmount);
        if(excess > 0) sendValue(payable(_msgSender()), excess);

        emit TokensBought(
            _msgSender(),
            amount,
            address(0),
            ethAmount,
            block.timestamp
        );
    }

    function buyWithUSD(uint amount, uint purchaseToken) external checkSaleState(amount) whenNotPaused {
        uint usdPrice = calculatePrice(amount);
        if(purchaseToken == 0 || purchaseToken == 1) usdPrice = usdPrice / (10 ** 12); //USDT and USDC have 6 decimals
        inSale -= amount;
        userDeposits[_msgSender()] += (amount * baseDecimals);

        IERC20 tokenInterface;
        if(purchaseToken == 0) tokenInterface = IERC20(USDTtoken);
        else if(purchaseToken == 1) tokenInterface = IERC20(USDCtoken);
        else if(purchaseToken == 2) tokenInterface = IERC20(BUSDtoken);
        else if(purchaseToken == 3) tokenInterface = IERC20(DAItoken);

        uint ourAllowance = tokenInterface.allowance(_msgSender(), address(this));
        require(usdPrice <= ourAllowance, "Make sure to add enough allowance");

        (bool success, ) = address(tokenInterface).call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                _msgSender(),
                owner(),
                usdPrice
            )
        );

        require(success, "Token payment failed");

        emit TokensBought(
            _msgSender(),
            amount,
            address(tokenInterface),
            usdPrice,
            block.timestamp
        );
    }

    function getEthAmount(uint amount) external view returns (uint ethAmount) {
        uint usdPrice = calculatePrice(amount);
        ethAmount = (usdPrice * baseDecimals) / getETHLatestPrice();
    }

    function getTokenAmount(uint amount, uint purchaseToken) external view returns (uint usdPrice) {
        usdPrice = calculatePrice(amount);
        if(purchaseToken == 0 || purchaseToken == 1) usdPrice = usdPrice / (10 ** 12); //USDT and USDC have 6 decimals
    }

    function startClaim(uint _claimStart, uint tokensAmount, address _saleToken) external onlyOwner {
        require(_claimStart > endTime && _claimStart > block.timestamp, "Invalid claim start time");
        require(tokensAmount >= ((totalTokensForPresale - inSale) * baseDecimals), "Tokens less than sold");
        require(_saleToken != address(0), "Zero token address");
        require(claimStart == 0, "Claim already set");
        claimStart = _claimStart;
        saleToken = _saleToken;
        IERC20(_saleToken).transferFrom(_msgSender(), address(this), tokensAmount);
    }

    function claim() external whenNotPaused {
        require(saleToken != address(0), "Sale token not added");
        require(block.timestamp >= claimStart, "Claim has not started yet");
        require(!hasClaimed[_msgSender()], "Already claimed");
        hasClaimed[_msgSender()] = true;
        uint amount = userDeposits[_msgSender()];
        require(amount > 0, "Nothing to claim");
        delete userDeposits[_msgSender()];
        IERC20(saleToken).transfer(_msgSender(), amount);
        emit TokensClaimed(_msgSender(), amount, block.timestamp);
    }

    function changeClaimStart(uint _claimStart) external onlyOwner {
        require(claimStart > 0, "Initial claim data not set");
        require(_claimStart > endTime, "Sale in progress");
        require(_claimStart > block.timestamp, "Claim start in past");
        claimStart = _claimStart;
    }

    function changeSaleTimes(uint _startTime, uint _endTime) external onlyOwner {
        require(_startTime > 0 || _endTime > 0, "Invalid parameters");

        if(_startTime > 0) {
            require(block.timestamp < _startTime, "Sale time in past");
            startTime = _startTime;
        }

        if(_endTime > 0) {
            require(_endTime > startTime, "Invalid endTime");
            endTime = _endTime;
        }
    }

    function changePriceStep(uint _priceStep) external onlyOwner {
        require(_priceStep > 0 && _priceStep != priceStep, "Invalid price step");
        priceStep = _priceStep;
    }

    function changePeriodSize(uint _periodSize) external onlyOwner {
        require(_periodSize > 0 && _periodSize != periodSize, "Invalid period size");
        periodSize = _periodSize;
    }

    function changeMinimumBuyAmount(uint _amount) external onlyOwner {
        require(_amount > 0 && _amount != minimumBuyAmount, "Invalid amount");
        minimumBuyAmount = _amount;
    }

    function withdrawTokens(address token, uint amount) external onlyOwner {
        IERC20(token).transfer(owner(), amount);
    }

    function withdrawEthers() external onlyOwner {
        (bool success,) = owner().call{value: address(this).balance}("");
        require(success, "Failed to withdraw");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.6;

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

pragma solidity ^0.8.6;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

pragma solidity ^0.8.6;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.8.6;

// SPDX-License-Identifier: MIT License

import "./Context.sol";

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.6;

import "./Context.sol";

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.6;

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