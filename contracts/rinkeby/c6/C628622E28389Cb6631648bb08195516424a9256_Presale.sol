// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Presale {
    using SafeERC20 for IERC20;

    struct lockingTokenInfo {
        uint256 amount;
        uint256 endLockTimestamp;
    }

    uint256 public totalSoldAmount;

    mapping(address => lockingTokenInfo) public lockedTokens;

    AggregatorV3Interface internal priceFeed;

    IERC20 public tokenAddr;
    IERC20 public usdtAddr;

    uint256 public seedPriceForRound1 = 6500000;            // $0.065
    uint256 public seedPriceForRound2 = 5000000;            // $0.05
    uint256 public privatePriceForRound1 = 8500000;         // $0.085
    uint256 public privatePriceForRound2 = 7000000;         // $0.07

    uint256 public ROUND1_MIN_AMOUNT = 10000;
    uint256 public ROUND2_MIN_AMOUNT = 10**7;
    uint256 public ROUND2_MAX_AMOUNT = 2 * 10**7;
    uint256 public LOCKING_PERIOD = 6;                      // 6 months

    uint256 public seedStartDate = 1652572800;              // May 15, 2022 12:00:00 AM GMT
    uint256 public seedEndDate = 1660608000;                // Aug 16, 2022 12:00:00 AM GMT
    uint256 public privateEndDate = 1665878400;             // Oct 16, 2022 12:00:00 AM GMT

    address payable public lpWallet = payable(0x31DB7dC50C4077AA065F5C296A766b1A6Db56df2);
    address payable public devWallet = payable(0x9b786d161ACA544dd8119F172fd511557ecB529c);
    address payable public marketWallet = payable(0x1B4942F4366794e77240A1ED935818B305c8477c);
    address payable public cfWallet1 = payable(0xf98E4c178EeD9313Ce0856cf775ce950C08d6F39);
    address payable public cfWallet2 = payable(0xD6F6c0c0270F1001fbd0583cA40Cc4b7a40529B0);
    address payable public cfWallet3 = payable(0x9b786d161ACA544dd8119F172fd511557ecB529c);

    address public deployer;

    event Buy(address indexed caller, uint8 paymentType, uint256 paidAmount, uint256 tokenAmount, uint256 buyDate);
    event Claim(address indexed caller, uint256 tokenAmount, uint256 claimDate);

    modifier onlyAdminGroup {
        require((msg.sender == cfWallet1) || (msg.sender == cfWallet2) || (msg.sender == cfWallet3), "caller is not admin");
        _;
    }

    modifier onlyCFWallet1 {
        require(msg.sender == cfWallet1, "caller is not cfWallet1");
        _;
    }

    modifier onlyCFWallet2 {
        require(msg.sender == cfWallet2, "caller is not cfWallet2");
        _;
    }

    modifier onlyCFWallet3 {
        require(msg.sender == cfWallet3, "caller is not cfWallet3");
        _;
    }

    modifier onlyDevWallet {
        require(msg.sender == devWallet, "caller is not devWallet");
        _;
    }

    modifier onlyLPWallet {
        require(msg.sender == lpWallet, "caller is not lpWallet");
        _;
    }

    modifier onlyMarketWallet {
        require(msg.sender == marketWallet, "caller is not marketWallet");
        _;
    }

    modifier onlyDeployer {
        require(msg.sender == deployer, "caller is not deployer");
        _;
    }

    /**
     * Network: Mumbai
     * Aggregator: MATIC/USD
     * Address: 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
     *
     * Network: Polygon Mainnet
     * Aggregator: MATIC/USD
     * Address: 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
     */
    constructor(address _tokenAddr, address _usdtAddr, address _priceFeedAddr) {
        tokenAddr = IERC20(_tokenAddr);
        usdtAddr = IERC20(_usdtAddr);                       // 0xc2132D05D31c914a87C6611C10748AEb04B58e8F
        priceFeed = AggregatorV3Interface(_priceFeedAddr);  // 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
        deployer = msg.sender;
    }

    function setTokenAddress(address _newToken) external onlyDeployer {
        tokenAddr = IERC20(_newToken);
    }

    function setUSDTAddress(address _newToken) external onlyDeployer {
        usdtAddr = IERC20(_newToken);
    }

    function setSeedPriceForRound1(uint256 _newPrice) external onlyDeployer {
        seedPriceForRound1 = _newPrice;
    }

    function setSeedPriceForRound2(uint256 _newPrice) external onlyDeployer {
        seedPriceForRound2 = _newPrice;
    }

    function setPrivatePriceForRound1(uint256 _newPrice) external onlyDeployer {
        privatePriceForRound1 = _newPrice;
    }

    function setPrivatePriceForRound2(uint256 _newPrice) external onlyDeployer {
        privatePriceForRound2 = _newPrice;
    }

    function setSeedStartDate(uint256 _newDate) external onlyDeployer {
        seedStartDate = _newDate;
    }

    function setSeedEndDate(uint256 _newDate) external onlyDeployer {
        seedEndDate = _newDate;
    }

    function setPrivateEndDate(uint256 _newDate) external onlyDeployer {
        privateEndDate = _newDate;
    }

    function setLPWallet(address payable _newAddress) external onlyLPWallet {
        lpWallet = _newAddress;
    }

    function setDevWallet(address payable _newAddress) external onlyDevWallet {
        devWallet = _newAddress;
    }

    function setMarketWallet(address payable _newAddress) external onlyMarketWallet {
        marketWallet = _newAddress;
    }

    function setCFWallet1(address payable _newAddress) external onlyCFWallet1 {
        cfWallet1 = _newAddress;
    }

    function setCFWallet2(address payable _newAddress) external onlyCFWallet2 {
        cfWallet2 = _newAddress;
    }

    function setCFWallet3(address payable _newAddress) external onlyCFWallet3 {
        cfWallet3 = _newAddress;
    }

    function setDeployer(address _newAddress) external onlyDeployer {
        deployer = _newAddress;
    }

    function _lockToken(uint256 _amount, address _sender) internal {
        require(lockedTokens[_sender].amount == 0, "You've already bought!");
        require(_amount > 0, "The estimated token amount is zero");
        require(_amount < _getTokenBalance() - totalSoldAmount, "Insufficient remain token balance");

        lockedTokens[_sender].amount = _amount;
        lockedTokens[_sender].endLockTimestamp = block.timestamp + (2628029 * LOCKING_PERIOD);
        totalSoldAmount += _amount;
    }
    
    function _getTokenBalance() internal view returns (uint256) {
        return tokenAddr.balanceOf(address(this));
    }

    function getSalePeriod() public view returns (uint8) {
        if (block.timestamp >= seedStartDate && block.timestamp < seedEndDate) {
            return 1;
        } else if (block.timestamp >= seedEndDate && block.timestamp < privateEndDate) {
            return 2;
        }

        return 0;
    }

    function getTokenPrice(uint256 _tokenAmount) public view returns (uint256) {
        uint8 tokenSalePeriod = getSalePeriod();

        if (_tokenAmount >= ROUND1_MIN_AMOUNT * 10**18 && _tokenAmount <= ROUND2_MIN_AMOUNT * 10**18) {
            if (tokenSalePeriod == 1) {
                return seedPriceForRound1;
            } else if (tokenSalePeriod == 2) {
                return privatePriceForRound1;
            }
        } else if (_tokenAmount > ROUND2_MIN_AMOUNT * 10**18 && _tokenAmount <= ROUND2_MAX_AMOUNT * 10**18) {
            if (tokenSalePeriod == 1) {
                return seedPriceForRound2;
            } else if (tokenSalePeriod == 2) {
                return privatePriceForRound2;
            }
        }

        return 0;
    }

    function getLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();

        return price;
    }

    function estimatedMaticAmount(uint256 _amount) public view returns (uint256) {
        uint256 maticPrice = uint256(getLatestPrice());
        uint256 tokenPrice = getTokenPrice(_amount);

        uint256 estimatedAmount = tokenPrice * _amount / maticPrice;

        return estimatedAmount;
    }

    function estimatedUSDTAmount(uint256 _amount) public view returns (uint256) {
        uint256 tokenPrice = getTokenPrice(_amount);

        uint256 estimatedAmount = tokenPrice * _amount / 10**20;

        return estimatedAmount;
    }

    function buyTokenWithMatic(uint256 _amount) external payable {
        require(getSalePeriod() > 0, "Not valid sale period");
        require(msg.value > 0, "Value cannot be zero");

        uint256 maticPrice = uint256(getLatestPrice());
        uint256 tokenPrice = getTokenPrice(_amount);

        require(tokenPrice > 0, "Invalid token price");
        require(msg.value >= tokenPrice * _amount / maticPrice, "Insufficient value");
        _lockToken(_amount, msg.sender);

        emit Buy(msg.sender, 1, msg.value, _amount, block.timestamp);
    }

    function buyTokenWithUSDT(uint256 _amount, uint256 _amountInUSDT) external {
        require(getSalePeriod() > 0, "Not valid sale period");
        require(_amountInUSDT > 0, "amount cannot be zero");
        require(usdtAddr.allowance(msg.sender, address(this)) >= _amountInUSDT, "This contract isn't approved for transferFrom of USDT");
        require(usdtAddr.balanceOf(msg.sender) >= _amountInUSDT, "Your USDT balance is insufficient");

        uint256 tokenPrice = getTokenPrice(_amount);

        require(tokenPrice > 0, "Invalid token price");
        require(_amountInUSDT >= tokenPrice * _amount / 10**20, "Insufficient value");

        usdtAddr.transferFrom(msg.sender, address(this), _amountInUSDT);

        _lockToken(_amount, msg.sender);

        emit Buy(msg.sender, 2, _amountInUSDT, _amount, block.timestamp);
    }

    function claimToken() external {
        require(lockedTokens[msg.sender].endLockTimestamp <= block.timestamp, "Lock period(6 Month) isn't ended yet");

        uint256 amount = lockedTokens[msg.sender].amount;

        require(_getTokenBalance() >= amount, "Insufficient balance");

        tokenAddr.transfer(msg.sender, amount);

        lockedTokens[msg.sender].amount = 0;
        lockedTokens[msg.sender].endLockTimestamp = 0;

        emit Claim(msg.sender, amount, block.timestamp);
    }

    function burn() external onlyAdminGroup {
        require(block.timestamp > privateEndDate, "private sale period");

        uint256 restBalance = _getTokenBalance();

        tokenAddr.transfer(0x000000000000000000000000000000000000dEaD, restBalance);
    }

    function withdraw() external onlyAdminGroup {
        uint256 lpBalance = address(this).balance * 50 / 100;
        uint256 devBalance = address(this).balance * 32 / 100;
        uint256 cfWallet1Balance = address(this).balance * 55 / 1000;
        uint256 cfWallet2Balance = address(this).balance * 55 / 1000;
        uint256 cfWallet3Balance = address(this).balance / 100;
        uint256 marketBalance = address(this).balance * 6 / 100;

        if (lpBalance > 0) {
            lpWallet.transfer(lpBalance);
        }
        
        if (devBalance > 0) {
            devWallet.transfer(devBalance);
        }
        
        if (cfWallet1Balance > 0) {
            cfWallet1.transfer(cfWallet1Balance);
        }
        
        if (cfWallet2Balance > 0) {
            cfWallet2.transfer(cfWallet2Balance);
        }
        
        if (cfWallet3Balance > 0) {
            cfWallet3.transfer(cfWallet3Balance);
        }
        
        if (marketBalance > 0) {
            marketWallet.transfer(marketBalance);
        }

        uint256 lpUSDTBalance = usdtAddr.balanceOf(address(this)) * 50 / 100;
        uint256 devUSDTBalance = usdtAddr.balanceOf(address(this)) * 32 / 100;
        uint256 cfWallet1USDTBalance = usdtAddr.balanceOf(address(this)) * 55 / 1000;
        uint256 cfWallet2USDTBalance = usdtAddr.balanceOf(address(this)) * 55 / 1000;
        uint256 cfWallet3USDTBalance = usdtAddr.balanceOf(address(this)) / 100;
        uint256 marketUSDTBalance = usdtAddr.balanceOf(address(this)) * 6 / 100;

        if (lpUSDTBalance > 0) {
            usdtAddr.transfer(lpWallet, lpUSDTBalance);
        }

        if (devUSDTBalance > 0) {
            usdtAddr.transfer(devWallet, devUSDTBalance);
        }

        if (cfWallet1USDTBalance > 0) {
            usdtAddr.transfer(cfWallet1, cfWallet1USDTBalance);
        }

        if (cfWallet2USDTBalance > 0) {
            usdtAddr.transfer(cfWallet2, cfWallet2USDTBalance);
        }

        if (cfWallet3USDTBalance > 0) {
            usdtAddr.transfer(cfWallet3, cfWallet3USDTBalance);
        }

        if (marketUSDTBalance > 0) {
            usdtAddr.transfer(marketWallet, marketUSDTBalance);
        }
    }

    receive() external payable {}
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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