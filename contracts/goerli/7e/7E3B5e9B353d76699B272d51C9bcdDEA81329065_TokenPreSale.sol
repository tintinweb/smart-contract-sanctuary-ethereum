/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

// File: @openzeppelin/contracts/utils/Address.sol

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
}

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

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

// File: contracts/TokenPreSale.sol

pragma solidity >=0.8.0 <0.9.0;




interface IContracts {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function lock(
        address owner,
        address token,
        bool isLpToken,
        uint256 amount,
        uint256 unlockDate,
        string memory description
    ) external returns (uint256 lockId);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

contract TokenPreSale is ReentrancyGuard, Ownable {
    uint256 public BASE_MULTIPLIER;
    address public ROUTER;
    address public FACTORY;
    address public WETH;
    address public LOCKER;

    uint256 public startTimeSeedSale;
    uint256 public endTimeSeedSale;
    uint256 public startTimePrivateSale;
    uint256 public endTimePrivateSale;
    uint256 public startTimePublicSale;
    uint256 public endTimePublicSale;

    address public saleToken;
    uint256 public baseDecimals;
    uint256 public amountTokensForLiquidity;
    uint256 public timeUnlockLiquidity;
    uint256 public treasuryPercentage;
    address payable public treasuryAddress;

    uint256 public priceSeedSale;
    uint256 public pricePrivateSale;
    uint256 public pricePublicSale;

    uint256 public tokensToSellSeedSale;
    uint256 public tokensToSellPrivateSale;
    uint256 public tokensToSellPublicSale;
    uint256 public maxAmountTokensForSalePerUserForSeed;
    uint256 public maxAmountTokensForSalePerUserForPrivate;
    uint256 public maxAmountTokensForSalePerUserForPublic;
    uint256 public tokensToSellTotal;

    uint256 private ethInvestedSeedSale;
    uint256 private ethInvestedPrivateSale;
    uint256 private ethInvestedPublicSale;

    uint256 public vestingStartTime;
    uint256 public vestingCliff;
    uint256 public vestingPeriod;

    bool private presaleTimeInitiated = false;
    bool private seedSaleTreasuryClaimed = false;
    bool private privateSaleTreasuryClaimed = false;
    bool private publicSaleTreasuryClaimed = false;

    bool public liquidityFinalized = false;
    bool public tokensaleCanceled = false;

    struct Vesting {
        uint256 totalAmount;
        uint256 claimedAmount;
        uint256 claimStart;
        uint256 claimEnd;
    }

    mapping(address => Vesting) public userVesting;
    mapping(address => bool) public whitelistSeedSale;
    mapping(address => bool) public whitelistPrivateSale;
    mapping(address => uint256) public userDepositETH;
    mapping(address => uint256) private userAmountBoughtSeed;
    mapping(address => uint256) private userAmountBoughtPrivate;
    mapping(address => uint256) private userAmountBoughtPublic;

    event Received(address, uint);

    constructor(
        address _router,
        address _factory,
        address _weth,
        address _locker
    ) public {
        BASE_MULTIPLIER = (10 ** 18);
        ROUTER = _router;
        FACTORY = _factory;
        WETH = _weth;
        LOCKER = _locker;
    }

    /**
     * @dev To add the sale times, can only be called once
     * @param _startTimeSeedSale Unix timestamp seed sale start
     * @param _endTimeSeedSale Unix timestamp seed sale end
     * @param _startTimePrivateSale; Unix timestamp private sale start
     * @param _endTimePrivateSale Unix timestamp private sale end
     * @param _startTimePublicSale Unix timestamp public sale start
     * @param _endTimePublicSale Unix timestamp public sale end
     * @param _vestingStartTime Unix timestamp vesting start
     */
    function addSaleTimes(
        uint256 _startTimeSeedSale,
        uint256 _endTimeSeedSale,
        uint256 _startTimePrivateSale,
        uint256 _endTimePrivateSale,
        uint256 _startTimePublicSale,
        uint256 _endTimePublicSale,
        uint256 _vestingStartTime
    ) external onlyOwner {
        require(presaleTimeInitiated == false, "already initiated");
        require(
            _startTimeSeedSale > 0 ||
                _endTimeSeedSale > 0 ||
                _startTimePrivateSale > 0 ||
                _endTimePrivateSale > 0 ||
                _startTimePublicSale > 0 ||
                _endTimePublicSale > 0 ||
                _vestingStartTime > 0,
            "Invalid parameters"
        );

        if (_startTimeSeedSale > 0) {
            require(block.timestamp < _startTimeSeedSale, "in past");
            startTimeSeedSale = _startTimeSeedSale;
        }

        if (_endTimeSeedSale > 0) {
            require(block.timestamp < _endTimeSeedSale, "in past");
            require(_endTimeSeedSale > _startTimeSeedSale, "ends before start");
            endTimeSeedSale = _endTimeSeedSale;
        }

        if (_startTimePrivateSale > 0) {
            require(block.timestamp < _startTimePrivateSale, "in past");
            startTimePrivateSale = _startTimePrivateSale;
        }

        if (_endTimePrivateSale > 0) {
            require(block.timestamp < _endTimePrivateSale, "in past");
            require(
                _endTimePrivateSale > _startTimePrivateSale,
                "ends before start"
            );
            endTimePrivateSale = _endTimePrivateSale;
        }

        if (_startTimePublicSale > 0) {
            require(block.timestamp < _startTimePublicSale, "in past");
            startTimePublicSale = _startTimePublicSale;
        }

        if (_endTimePublicSale > 0) {
            require(block.timestamp < _endTimePublicSale, "in past");
            require(
                _endTimePublicSale > _startTimePublicSale,
                "ends before start"
            );
            endTimePublicSale = _endTimePublicSale;
        }

        if (_vestingStartTime > 0) {
            require(
                _vestingStartTime >= endTimePublicSale,
                "Vesting starts before Presale ends"
            );
            vestingStartTime = _vestingStartTime;
        }
        presaleTimeInitiated = true;
    }

    /**
     * @dev Creates a new presale
     * @param _saleToken address of token to be sold
     * @param _baseDecimals No of decimals for the token. (10**18), for 18 decimal token
     * @param _amountTokensForLiquidity Amount of tokens for liq. if 1 million tokens to be sold then - 1_000_000 has to be passed
     * @param _vestingCliff Cliff period for vesting in seconds
     * @param _vestingPeriod Total vesting period(after vesting cliff) in seconds
     * @param _treasuryPercentage Percentage of raised funds that will go to the team
     * @param _treasuryAddress address to receive treasury percentage
     * @param _whitelistSeedSale array of addresses that are allowed to buy in Seed
     * @param _whitelistPrivateSale array of addresses that are allowed to buy in Private
     */
    function createPresale(
        address _saleToken,
        uint256 _baseDecimals,
        uint256 _amountTokensForLiquidity,
        uint256 _timeUnlockLiquidity,
        uint256 _vestingCliff,
        uint256 _vestingPeriod,
        uint256 _treasuryPercentage,
        address payable _treasuryAddress,
        address[] memory _whitelistSeedSale,
        address[] memory _whitelistPrivateSale
    ) external onlyOwner checkSaleNotStartedYet {
        require(presaleTimeInitiated == true, "Time not set");
        require(_treasuryPercentage <= 30, ">30");

        saleToken = _saleToken;
        baseDecimals = _baseDecimals;
        amountTokensForLiquidity = _amountTokensForLiquidity;
        timeUnlockLiquidity = _timeUnlockLiquidity;
        vestingCliff = _vestingCliff;
        vestingPeriod = _vestingPeriod;
        treasuryPercentage = _treasuryPercentage;
        treasuryAddress = _treasuryAddress;
        for (uint i = 0; i < _whitelistSeedSale.length; i++) {
            whitelistSeedSale[_whitelistSeedSale[i]] = true;
        }
        for (uint i = 0; i < _whitelistPrivateSale.length; i++) {
            whitelistPrivateSale[_whitelistPrivateSale[i]] = true;
        }
    }

    /**
     * @dev To update the sale times
     * @param _startTimeSeedSale New start time
     * @param _endTimeSeedSale New end time
     * @param _startTimePrivateSale New start time
     * @param _endTimePrivateSale New end time
     * @param _startTimePublicSale New start time
     * @param _endTimePublicSale New end time
     * @param _vestingStartTime New start time
     */
    function changeSaleTimes(
        uint256 _startTimeSeedSale,
        uint256 _endTimeSeedSale,
        uint256 _startTimePrivateSale,
        uint256 _endTimePrivateSale,
        uint256 _startTimePublicSale,
        uint256 _endTimePublicSale,
        uint256 _vestingStartTime
    ) external onlyOwner {
        require(
            _startTimeSeedSale > 0 ||
                _endTimeSeedSale > 0 ||
                _startTimePrivateSale > 0 ||
                _endTimePrivateSale > 0 ||
                _startTimePublicSale > 0 ||
                _endTimePublicSale > 0,
            "Invalid"
        );

        if (_startTimeSeedSale > 0) {
            require(block.timestamp < startTimeSeedSale, "already started");
            require(block.timestamp < _startTimeSeedSale, "time in past");
            startTimeSeedSale = _startTimeSeedSale;
        }

        if (_endTimeSeedSale > 0) {
            require(block.timestamp < endTimeSeedSale, "already ended");
            require(_endTimeSeedSale > startTimeSeedSale, "Invalid");
            endTimeSeedSale = _endTimeSeedSale;
        }

        if (_startTimePrivateSale > 0) {
            require(block.timestamp < startTimePrivateSale, "already started");
            require(block.timestamp < _startTimePrivateSale, "time in past");
            startTimePrivateSale = _startTimePrivateSale;
        }

        if (_endTimePrivateSale > 0) {
            require(block.timestamp < endTimePrivateSale, "already ended");
            require(_endTimeSeedSale > endTimePrivateSale, "Invalid");
            endTimePrivateSale = _endTimePrivateSale;
        }

        if (_startTimePublicSale > 0) {
            require(block.timestamp < startTimePublicSale, "already started");
            require(block.timestamp < _startTimePublicSale, "time in past");
            startTimePublicSale = _startTimePublicSale;
        }

        if (_endTimePublicSale > 0) {
            require(block.timestamp < endTimePublicSale, "already ended");
            require(_endTimePublicSale > startTimePublicSale, "Invalid");
            endTimePublicSale = _endTimePublicSale;
        }

        if (_vestingStartTime > 0) {
            require(
                _vestingStartTime >= endTimePublicSale,
                "Vesting starts before Presale ends"
            );
            vestingStartTime = _vestingStartTime;
        }
    }

    /**
     * @dev To add presale sale data
     * @param _tokensToSellSeedSale No of tokens to sell without denomination. If 1 million tokens to be sold then - 1_000_000 has to be passed
     * @param _tokensToSellPrivateSale No of tokens to sell without denomination. If 1 million tokens to be sold then - 1_000_000 has to be passed
     * @param _tokensToSellPublicSale No of tokens to sell without denomination. If 1 million tokens to be sold then - 1_000_000 has to be passed
     * @param _maxAmountTokensForSalePerUserForSeed max tokens each user in seed can buy. 1 million tokens - 1_000_000 has to be passed
     * @param _maxAmountTokensForSalePerUserForPrivate max tokens each user in private can buy. 1 million tokens - 1_000_000 has to be passed
     * @param _maxAmountTokensForSalePerUserForPublic max tokens each user in public can buy. 1 million tokens - 1_000_000 has to be passed
     * @param _priceSeedSale Per token price for seed multiplied by (10**18). how much ETH does 1 token cost
     * @param _pricePrivateSale Per token price for private multiplied by (10**18). how much ETH does 1 token cost
     * @param _pricePublicSale Per token price for public multiplied by (10**18). how much ETH does 1 token cost
     */
    function addPresaleSaleData(
        uint256 _tokensToSellSeedSale,
        uint256 _tokensToSellPrivateSale,
        uint256 _tokensToSellPublicSale,
        uint256 _maxAmountTokensForSalePerUserForSeed,
        uint256 _maxAmountTokensForSalePerUserForPrivate,
        uint256 _maxAmountTokensForSalePerUserForPublic,
        uint256 _priceSeedSale,
        uint256 _pricePrivateSale,
        uint256 _pricePublicSale
    ) external onlyOwner checkSaleNotStartedYet {
        require(presaleTimeInitiated == true, "Time not set");

        if (_tokensToSellSeedSale > 0) {
            tokensToSellSeedSale = _tokensToSellSeedSale;
        }
        if (_tokensToSellPrivateSale > 0) {
            tokensToSellPrivateSale = _tokensToSellPrivateSale;
        }
        if (_tokensToSellPublicSale > 0) {
            tokensToSellPublicSale = _tokensToSellPublicSale;
        }

        uint256 totalTokens = tokensToSellSeedSale +
            tokensToSellPrivateSale +
            tokensToSellPublicSale;
        tokensToSellTotal = totalTokens;

        if (_maxAmountTokensForSalePerUserForSeed > 0) {
            maxAmountTokensForSalePerUserForSeed = _maxAmountTokensForSalePerUserForSeed;
        }
        if (_maxAmountTokensForSalePerUserForPrivate > 0) {
            maxAmountTokensForSalePerUserForPrivate = _maxAmountTokensForSalePerUserForPrivate;
        }
        if (_maxAmountTokensForSalePerUserForPublic > 0) {
            maxAmountTokensForSalePerUserForPublic = _maxAmountTokensForSalePerUserForPublic;
        }

        if (_priceSeedSale > 0) {
            priceSeedSale = _priceSeedSale;
        }
        if (_pricePrivateSale > 0) {
            pricePrivateSale = _pricePrivateSale;
        }
        if (_pricePublicSale > 0) {
            pricePublicSale = _pricePublicSale;
        }
    }

    /**
     * @dev To whitelist addresses for Seed, can also be called durinig sale
     * @param _wallets Array of wallet addresses
     */
    function addToWhitelistSeedSale(
        address[] memory _wallets
    ) external onlyOwner {
        for (uint256 i = 0; i < _wallets.length; i++) {
            whitelistSeedSale[_wallets[i]] = true;
        }
    }

    /**
     * @dev To whitelist addresses for Private, can also be called durinig sale
     * @param _wallets Array of wallet addresses
     */
    function addToWhitelistPrivateSale(
        address[] memory _wallets
    ) external onlyOwner {
        for (uint256 i = 0; i < _wallets.length; i++) {
            whitelistPrivateSale[_wallets[i]] = true;
        }
    }

    /**
     * @dev To remove addresses from the Seed whitelist, can also be called durinig sale
     * @param _wallets Array of wallet addresses
     */
    function removeFromWhitelistSeedSale(
        address[] memory _wallets
    ) external onlyOwner {
        for (uint256 i = 0; i < _wallets.length; i++) {
            delete whitelistSeedSale[_wallets[i]];
        }
    }

    /**
     * @dev To remove addresses from the Private whitelist, can also be called durinig sale
     * @param _wallets Array of wallet addresses
     */
    function removeFromWhitelistPrivateSale(
        address[] memory _wallets
    ) external onlyOwner {
        for (uint256 i = 0; i < _wallets.length; i++) {
            delete whitelistPrivateSale[_wallets[i]];
        }
    }

    /**
     * @dev To cancel the presale and let user withdraw their funds
     */
    function cancelPresale() external onlyOwner {
        require(!liquidityFinalized, "Liq already added");
        require(!tokensaleCanceled, "Already canceled");
        tokensaleCanceled = true;
    }

    /**
     * @dev sending the treasury percentage to the team. can only be called once. should be called before the next sale phase starts
     */
    function claimTreasuryPercentageFromSeed() external onlyOwner {
        require(tokensaleCanceled == false, "Sale canceled");
        require(seedSaleTreasuryClaimed == false, "Already finalized");
        require(block.timestamp > endTimeSeedSale, "Sale not finished yet");
        uint256 treasuryAmountETH = (ethInvestedSeedSale * treasuryPercentage) /
            100;

        if (treasuryAmountETH > 0) {
            treasuryAddress.transfer(treasuryAmountETH);
        }
        seedSaleTreasuryClaimed = true;
    }

    /**
     * @dev sending the treasury percentage to the team. can only be called once. should be called before the next sale phase starts
     */
    function claimTreasuryPercentageFromPrivate() external onlyOwner {
        require(tokensaleCanceled == false, "Sale canceled");
        require(privateSaleTreasuryClaimed == false, "Already finalized");
        require(block.timestamp > endTimePrivateSale, "Sale not finished yet");
        uint256 treasuryAmountETH = (ethInvestedPrivateSale *
            treasuryPercentage) / 100;

        if (treasuryAmountETH > 0) {
            treasuryAddress.transfer(treasuryAmountETH);
        }
        privateSaleTreasuryClaimed = true;
    }

    /**
     * @dev sending the treasury percentage to the team. can only be called once. should be called before the next sale phase starts
     */
    function claimTreasuryPercentageFromPublic() external onlyOwner {
        require(tokensaleCanceled == false, "Sale canceled");
        require(publicSaleTreasuryClaimed == false, "Already finalized");
        require(block.timestamp > endTimePublicSale, "Sale not finished yet");
        uint256 treasuryAmountETH = (ethInvestedPublicSale *
            treasuryPercentage) / 100;

        if (treasuryAmountETH > 0) {
            treasuryAddress.transfer(treasuryAmountETH);
        }
        publicSaleTreasuryClaimed = true;
    }

    /**
     * @dev To finalize the sale by adding the tokens to liquidity and move the unsold tokens. can only be called once.
     */
    function finalizeLiquidity() external onlyOwner checkSaleEnded {
        require(
            seedSaleTreasuryClaimed == true &&
                privateSaleTreasuryClaimed == true &&
                publicSaleTreasuryClaimed == true,
            "Treasury not claimed"
        );
        require(tokensaleCanceled == false, "Tokensale canceled");
        require(liquidityFinalized == false, "Already finalized");
        require(block.timestamp > endTimePublicSale, "Sale not over yet");
        uint256 LiquidityAmountETH = address(this).balance;
        uint256 tokensForLiquidity = amountTokensForLiquidity * baseDecimals;

        IContracts(saleToken).approve(ROUTER, tokensForLiquidity);

        (bool successAddLiq, ) = address(ROUTER).call{
            value: LiquidityAmountETH
        }(
            abi.encodeWithSignature(
                "addLiquidityETH(address,uint256,uint256,uint256,address,uint256)",
                saleToken,
                tokensForLiquidity,
                0,
                0,
                address(this),
                block.timestamp + 600
            )
        );
        require(successAddLiq, "Add liq failed");

        if (tokensToSellPublicSale > 0) {
            IContracts(saleToken).transfer(
                treasuryAddress,
                tokensToSellPublicSale * baseDecimals
            );
        }

        liquidityFinalized = true;
    }

    /**
     * @dev To send the LP tokens to a locker
     */
    function lockLiquidity() external onlyOwner {
        require(liquidityFinalized == true, "Liquidity not finalized");

        address pair = IContracts(FACTORY).getPair(saleToken, WETH);
        uint256 pairBalance = IContracts(pair).balanceOf(address(this));

        IContracts(pair).approve(LOCKER, pairBalance);

        IContracts(LOCKER).lock(
            treasuryAddress,
            pair,
            true,
            pairBalance,
            timeUnlockLiquidity,
            "LP Lock"
        );
    }

    function _checkSaleNotStartedYet() private view {
        require(block.timestamp <= startTimeSeedSale, "Sale already started");
    }

    modifier checkSaleNotStartedYet() {
        _checkSaleNotStartedYet();
        _;
    }

    function _checkSaleActive(uint256 amount) private view {
        require(
            (block.timestamp >= startTimeSeedSale &&
                block.timestamp <= endTimeSeedSale) ||
                (block.timestamp >= startTimePrivateSale &&
                    block.timestamp <= endTimePrivateSale) ||
                (block.timestamp >= startTimePublicSale &&
                    block.timestamp <= endTimePublicSale),
            "Sale not active"
        );
        require(amount > 0 && amount <= tokensToSellTotal, "Invalid amount");
    }

    modifier checkSaleActive(uint256 amount) {
        _checkSaleActive(amount);
        _;
    }

    function _checkSaleEnded() private view {
        require(block.timestamp >= endTimePublicSale, "Sale not over yet");
    }

    modifier checkSaleEnded() {
        _checkSaleEnded();
        _;
    }

    function isSaleActive(
        uint256 startTime,
        uint256 endTime
    ) internal view returns (bool) {
        return block.timestamp >= startTime && block.timestamp <= endTime;
    }

    function isSeedSaleActive() internal view returns (bool) {
        return isSaleActive(startTimeSeedSale, endTimeSeedSale);
    }

    function isPrivateSaleActive() internal view returns (bool) {
        return isSaleActive(startTimePrivateSale, endTimePrivateSale);
    }

    function isPublicSaleActive() internal view returns (bool) {
        return isSaleActive(startTimePublicSale, endTimePublicSale);
    }

    /**
     * @dev To buy into a presale using ETH. can only be called if any sale is currently active
     * @param amount No of tokens to buy. not in wei
     */
    function buyWithEth(
        uint256 amount
    ) external payable checkSaleActive(amount) nonReentrant returns (bool) {
        require(tokensaleCanceled == false, "Sale canceled");
        require(msg.value > 0, "no ETH sent");

        uint256 ethAmount;
        if (isSeedSaleActive()) {
            require(whitelistSeedSale[_msgSender()], "Not whitelisted");
            require(
                amount <= maxAmountTokensForSalePerUserForSeed,
                "Buying too many"
            );
            require(
                userAmountBoughtSeed[_msgSender()] <=
                    maxAmountTokensForSalePerUserForSeed,
                "Buying too many"
            );
            require(tokensToSellSeedSale > 0, "All tokens have been sold");
            ethAmount = amount * priceSeedSale;
            require(msg.value == ethAmount, "Wrong ETH amount");
            tokensToSellSeedSale -= amount;
            userAmountBoughtSeed[_msgSender()] += amount;
            ethInvestedSeedSale += msg.value;
        }

        if (isPrivateSaleActive()) {
            require(whitelistPrivateSale[_msgSender()], "Not whitelisted");
            require(
                amount <= maxAmountTokensForSalePerUserForPrivate,
                "Buying too many"
            );
            require(
                userAmountBoughtPrivate[_msgSender()] <=
                    maxAmountTokensForSalePerUserForPrivate,
                "Buying too many"
            );
            require(tokensToSellPrivateSale > 0, "All tokens have been sold");
            ethAmount = amount * pricePrivateSale;
            require(msg.value == ethAmount, "Wrong ETH amount");
            tokensToSellPrivateSale -= amount;
            userAmountBoughtPrivate[_msgSender()] += amount;
            ethInvestedPrivateSale += msg.value;
            if (tokensToSellSeedSale > 0) {
                tokensToSellPrivateSale += tokensToSellSeedSale;
                tokensToSellSeedSale = 0;
            }
        }

        if (isPublicSaleActive()) {
            require(
                amount <= maxAmountTokensForSalePerUserForPublic,
                "Buying too many"
            );
            require(
                userAmountBoughtPublic[_msgSender()] <=
                    maxAmountTokensForSalePerUserForPublic,
                "Buying too many"
            );
            require(tokensToSellPublicSale > 0, "All tokens have been sold");
            ethAmount = amount * pricePublicSale;
            require(msg.value == ethAmount, "Wrong ETH amount");
            tokensToSellPublicSale -= amount;
            userAmountBoughtPublic[_msgSender()] += amount;
            ethInvestedPublicSale += msg.value;
            if (tokensToSellPrivateSale > 0) {
                tokensToSellPublicSale += tokensToSellPrivateSale;
                tokensToSellPrivateSale = 0;
            }
        }

        tokensToSellTotal -= amount;
        userDepositETH[_msgSender()] += ethAmount;

        if (userVesting[_msgSender()].totalAmount > 0) {
            userVesting[_msgSender()].totalAmount += (amount * baseDecimals);
        } else {
            userVesting[_msgSender()] = Vesting(
                (amount * baseDecimals),
                0,
                vestingStartTime + vestingCliff,
                vestingStartTime + vestingCliff + vestingPeriod
            );
        }
        return true;
    }

    /**
     * @dev Helper funtion to get claimable tokens for a given presale.
     * @param user User address
     */
    function claimableAmount(address user) public view returns (uint256) {
        Vesting memory _user = userVesting[user];
        require(_user.totalAmount > 0, "Nothing to claim");
        uint256 amount = _user.totalAmount - _user.claimedAmount;
        require(amount > 0, "Already claimed");
        if (block.timestamp < _user.claimStart) return 0;
        if (block.timestamp >= _user.claimEnd) return amount;

        uint256 vestingDuration = _user.claimEnd - _user.claimStart;
        uint256 timeSinceStart = block.timestamp - _user.claimStart;
        uint256 ClaimablePerSecond = _user.totalAmount / vestingDuration;
        uint256 amountToClaim = (ClaimablePerSecond * timeSinceStart) -
            _user.claimedAmount;

        return amountToClaim;
    }

    /**
     * @dev To claim tokens after vesting cliff from a presale
     * @param user User address
     */
    function claim(address user) public returns (bool) {
        uint256 amount = claimableAmount(user);
        require(tokensaleCanceled == false, "Tokensale canceled");
        require(liquidityFinalized == true, "Liquidity not added yet");

        require(amount > 0, "Zero claim amount");
        require(saleToken != address(0), "Token address not set");
        require(
            amount <= IContracts(saleToken).balanceOf(address(this)),
            "Not enough tokens in the contract"
        );
        userVesting[user].claimedAmount += amount;
        IContracts(saleToken).transfer(user, amount);
        return true;
    }

    function userWithdrawETHPresaleCanceled() external nonReentrant {
        require(tokensaleCanceled == true, "Sale not canceled");
        require(userDepositETH[_msgSender()] > 0, "No ETH to withdraw");

        uint256 userETH = userDepositETH[_msgSender()];
        userDepositETH[_msgSender()] = 0;
        (bool success, ) = _msgSender().call{value: userETH}("");
        require(success, "Withdrawal failed");
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}