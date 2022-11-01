// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

/**
 * @title ClearCryptos Transparent Upgradeable Proxy
 * @author ClearCryptos Blockchain Team - G3NOM3
 * @dev This contract inherits OpenZeppelin extra secure and audited contracts
 * for implementing the ERC20 standard with fees.
 */
contract CCXA is ERC20Upgradeable, OwnableUpgradeable {
    bool private s_initializedLiquidityProvider;
    bool private s_trading;

    uint8 private s_buyFee;
    uint8 private s_sellFee;
    uint8 private s_transferFee;
    address private s_feeAddress;

    mapping(address => bool) private s_isOperational;
    mapping(address => bool) private s_isLiquidityProvider;
    mapping(address => bool) private s_isBlacklisted;

    bool private s_inSwap;
    bool private s_internalSwapEnabled;
    uint256 private s_swapThreshold;

    IUniswapV2Router02 private s_uniswapV2Router;

    mapping(address => uint32) private s_cooldowns;
    mapping(address => bool) private s_cooldownWhitelist;
    uint256 private s_cooldownTime;
    mapping(address => bool) private s_testingAddress;

    modifier lockTheSwap() {
        s_inSwap = true;
        _;
        s_inSwap = false;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _supply
    ) public initializer {
        __ERC20_init(_name, _symbol);
        _mint(msg.sender, _supply);
        __Ownable_init();
    }

    /**
     * @dev Returns the current storage values of the fee infrastructure.
     *
     * @return s_buyFee the fee applied in {buy} transactions.
     * @return s_sellFee the fee applied in {sell} transactions.
     * @return s_transferFee the fee applied in {wallet-to-wallet} transactions.
     * @return s_feeAddress the address that collects the fee.
     */
    function getFeeState()
        external
        view
        virtual
        returns (
            uint8,
            uint8,
            uint8,
            address
        )
    {
        return (s_buyFee, s_sellFee, s_transferFee, s_feeAddress);
    }

    /**
     * @dev Returns the current storage value of the trading state.
     *
     * @return s_trading is the trading state.
     */
    function isTrading() external view virtual returns (bool) {
        return s_trading;
    }

    /**
     * @dev If a new liquidity provider is set, the transfers need to be paused to
     * avoid vulnerability exploits and fee issues.
     *
     * @return s_initializedLiquidityProvider is the current liquidity provider initializing state.
     */
    function isInitializedLiquidityProvider()
        external
        view
        virtual
        returns (bool)
    {
        return s_initializedLiquidityProvider;
    }

    /**
     * @dev Checks if the input address is an operations provider.
     *
     * @param _operationalAddress is a possible operations provider's address.
     */
    function isOperational(address _operationalAddress)
        external
        view
        virtual
        returns (bool)
    {
        return s_isOperational[_operationalAddress];
    }

    /**
     * @dev Checks if an address is a liquidity provider
     *
     * @param _liquidityprovider is a possible liquidity provider's address
     */
    function isLiquidityProvider(address _liquidityprovider)
        external
        view
        virtual
        returns (bool)
    {
        return s_isLiquidityProvider[_liquidityprovider];
    }

    /**
     * @dev Checks if an address is blacklisted
     *
     * @param _blacklistedAddress is a possible blacklisted address
     */
    function isBlacklisted(address _blacklistedAddress)
        external
        view
        virtual
        returns (bool)
    {
        return s_isBlacklisted[_blacklistedAddress];
    }

    /**
     * @dev Add Operational Address. This address represents an operations provider like a
     * smart contracts infrastructure (e.g. staking, flash loan etc.)
     *
     * Requirements:
     *
     * - `_operationalAddress` cannot be the zero address.
     *
     * @param _operationalAddress is a new operations provider's address.
     */
    function setOperational(address _operationalAddress)
        external
        virtual
        onlyOwner
    {
        require(
            _operationalAddress != address(0),
            "Zero address cannot be operational"
        );
        s_isOperational[_operationalAddress] = true;
    }

    /**
     * @dev Remove Operational Address
     *
     * @param _operationalAddress is an existing operations provider's address.
     */
    function removeOperational(address _operationalAddress)
        external
        virtual
        onlyOwner
    {
        delete s_isOperational[_operationalAddress];
    }

    /**
     * @dev Add new Liquidity Provider / Decentralized Exchange.
     *
     * Requirements:
     *
     * - `_liquidityProvider` cannot be the zero address.
     *
     * @param _liquidityProvider is a new liquidity provider's address.
     */
    function setLiquidityProvider(address _liquidityProvider)
        external
        virtual
        onlyOwner
    {
        require(
            _liquidityProvider != address(0),
            "Zero address cannot be a liquidity provider"
        );
        s_isLiquidityProvider[_liquidityProvider] = true;
    }

    /**
     * @dev Remove Liquidity Provider / Decentralized Exchange Address.
     *
     * @param _liquidityProvider is an existing liquidity provider's address
     */
    function removeLiquidityProvider(address _liquidityProvider)
        external
        virtual
        onlyOwner
    {
        delete s_isLiquidityProvider[_liquidityProvider];
    }

    /**
     * @dev Add new Blacklisted Address
     *
     * Requirements:
     *
     * - `_blacklistedAddress` cannot be the zero address.
     *
     * @param _blacklistedAddress is a new blacklisted address.
     */
    function setBlacklisted(address _blacklistedAddress)
        external
        virtual
        onlyOwner
    {
        require(
            _blacklistedAddress != address(0),
            "Zero address cannot be blacklisted"
        );
        s_isBlacklisted[_blacklistedAddress] = true;
    }

    /**
     * @dev Remove Blacklisted Address
     *
     * @param _blacklistedAddress is an existing blacklisted address
     */
    function removeBlacklisted(address _blacklistedAddress)
        external
        virtual
        onlyOwner
    {
        delete s_isBlacklisted[_blacklistedAddress];
    }

    /**
     * @dev Set wallet for collecting fees.
     *
     * Requirements:
     *
     * - `_feeAddress` cannot be the zero address.
     *
     * @param _feeAddress is the new address that collects the fees.
     */
    function setFeeAddress(address _feeAddress) external virtual onlyOwner {
        require(_feeAddress != address(0), "Zero address cannot collect fees");
        s_feeAddress = _feeAddress;
    }

    /**
     * @dev Pause / Resume Trading.
     * This feature helps in mitigating unknown vulnerability exploits.
     *
     * Requirements:
     *
     * - `_trading` needs to have a different value from `s_trading`.
     *
     * @param _trading is the new trading state.
     */
    function setTrading(bool _trading) external virtual onlyOwner {
        require(s_trading != _trading, "Value already set");
        s_trading = _trading;
    }

    /**
     * @dev Pause / Resume transfers to initialize new liquidity provider.
     *
     * Requirements:
     *
     * - `_initializedLiquidityProvider` needs to have a different value from `s_initializedLiquidityProvider`.
     *
     * @param _initializedLiquidityProvider is the new liquidity provider initializing state.
     */
    function setInitializedLiquidityProvider(bool _initializedLiquidityProvider)
        external
        virtual
        onlyOwner
    {
        require(
            s_initializedLiquidityProvider != _initializedLiquidityProvider,
            "Value already set"
        );
        s_initializedLiquidityProvider = _initializedLiquidityProvider;
    }

    /**
     * @dev Returns the internal swapping state
     *
     * @return s_internalSwapEnabled is the internal swapping state
     */
    function internalSwapEnabled() external view virtual returns (bool) {
        return s_internalSwapEnabled;
    }

    /**
     * @dev Pause / Resume internal swaps of the fee
     *
     * @param _internalSwapEnabled is the new internal swapping state
     */
    function setInternalSwapEnabled(bool _internalSwapEnabled)
        external
        virtual
        onlyOwner
    {
        require(
            s_internalSwapEnabled != _internalSwapEnabled,
            "Value already set"
        );
        s_internalSwapEnabled = _internalSwapEnabled;
    }

    /**
     * @dev Returns the UniswapV2 router
     *
     * @return s_uniswapV2Router is the UniswapV2 router
     */
    function uniswapV2Router()
        external
        view
        virtual
        returns (IUniswapV2Router02)
    {
        return s_uniswapV2Router;
    }

    /**
     * @dev Set UniswapV2 router for internal swaps
     *
     * @param _uniswapV2Router is the new UniswapV2 router address
     */
    function setUniswapV2Router(address _uniswapV2Router)
        external
        virtual
        onlyOwner
    {
        require(
            _uniswapV2Router != address(0),
            "Zero address cannot be uniswap v2 router"
        );
        s_uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
    }

    /**
     * @dev Returns the threshold amount
     *
     * @return s_swapThreshold is the threshold amount
     */
    function swapThreshold() external view virtual returns (uint256) {
        return s_swapThreshold;
    }

    /**
     * @dev Set threshold for internal swaps
     *
     * @param _swapThreshold is the new threshold amount
     */
    function setSwapThreshold(uint256 _swapThreshold)
        external
        virtual
        onlyOwner
    {
        require(_swapThreshold < 400_000e18, "Wrong amount");
        s_swapThreshold = _swapThreshold;
    }

    /**
     * @dev Checks if the input address is an whitelisted regarding cooldown.
     *
     * @param _cooldownWhitelist is a possible cooldown whitelisted address.
     */
    function isCooldownWhitelist(address _cooldownWhitelist)
        external
        view
        virtual
        returns (bool)
    {
        return s_cooldownWhitelist[_cooldownWhitelist];
    }

    /**
     * @dev Whitelist address from the cooldown system
     *
     * @param _cooldownWhitelist is a new whitelisted address
     */
    function setCooldownWhitelist(address _cooldownWhitelist)
        external
        virtual
        onlyOwner
    {
        require(
            _cooldownWhitelist != address(0),
            "Zero address cannot be cooldown whitelist"
        );
        s_cooldownWhitelist[_cooldownWhitelist] = true;
    }

    /**
     * @dev Remove address from the whitelist cooldown system
     *
     * @param _cooldownWhitelist is a possible whitelisted address
     */
    function removeCooldownWhitelist(address _cooldownWhitelist)
        external
        virtual
        onlyOwner
    {
        delete s_cooldownWhitelist[_cooldownWhitelist];
    }

    /**
     * @dev Returns the cooldown time
     *
     * @return s_cooldownTime is the cooldown time
     */
    function cooldownTime() external view virtual returns (uint256) {
        return s_cooldownTime;
    }

    /**
     * @dev MEV / bots attack solution: Set cooldown time for sells and transfers
     *
     * @param _cooldownTime is the new cooldown time
     */
    function setCooldownTime(uint256 _cooldownTime) external virtual onlyOwner {
        require(
            _cooldownTime < 5 minutes,
            "The cooldown time needs to be lower than 5 minutes"
        );
        s_cooldownTime = _cooldownTime;
    }

    /**
     * @dev Set new testing address
     *
     * @param _testingAddress is a new testing address
     */
    function setTestingAddress(address _testingAddress)
        external
        virtual
        onlyOwner
    {
        require(
            _testingAddress != address(0),
            "Zero address cannot be cooldown whitelist"
        );
        s_testingAddress[_testingAddress] = true;
    }

    /**
     * @dev Remove testing address
     *
     * @param _testingAddress is a possible testing address
     */
    function removeTestingAddress(address _testingAddress)
        external
        virtual
        onlyOwner
    {
        delete s_testingAddress[_testingAddress];
    }

    /**
     * @dev Set new fees.
     *
     * Requirements:
     *
     * - `_buyFee` needs to be lower than 20%.
     * - `_sellFee` needs to be lower than 20%
     * - `_transferFee` needs to be lower than 20%
     *
     * @param _buyFee the fee applied in {buy} transactions.
     * @param _sellFee the fee applied in {sell} transactions.
     * @param _transferFee the fee applied in {wallet-to-wallet} transactions.
     */
    function setFee(
        uint8 _buyFee,
        uint8 _sellFee,
        uint8 _transferFee
    ) external virtual onlyOwner {
        require(_buyFee < 20, "Buy fee needs to be lower than 20%");
        require(_sellFee < 20, "Sell fee needs to be lower than 20%");
        require(_transferFee < 20, "Transfer fee needs to be lower than 20%");
        s_buyFee = _buyFee;
        s_sellFee = _sellFee;
        s_transferFee = _transferFee;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to` deducting a fee when necessary.
     * In case of operational transfers, no fee is deducted.
     *
     * In the case of fee deduction, 2 {Transfers} are triggered:
     * 1. from `from` to `contract address`: `amount` * fee / 100
     * 2. from `from` to `to`: `amount` - (`amount` * fee / 100)
     *
     * @param from is the sender address
     * @param to is the recipient address
     * @param amount is the transfered quantity of tokens
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        uint256 tempAmount = amount;
        if (!s_isOperational[from] && !s_isOperational[to]) {
            require(
                !s_isBlacklisted[from] && !s_isBlacklisted[to],
                "The sender or recipient is blacklisted"
            );
            require(
                s_initializedLiquidityProvider,
                "Liquidity Provider is initializing"
            );

            if (s_isLiquidityProvider[to] || s_isLiquidityProvider[from]) {
                require(s_trading, "Trading is Paused");
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overThreshold = contractTokenBalance > s_swapThreshold;

            if (
                s_swapThreshold > 0 &&
                overThreshold &&
                !s_inSwap &&
                !s_isLiquidityProvider[from] &&
                (s_internalSwapEnabled || s_testingAddress[from])
            ) {
                swapTokensForEth(s_swapThreshold);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(contractETHBalance);
                }
            }

            uint256 currentFee = 0;
            if (s_isLiquidityProvider[from]) {
                currentFee = s_buyFee;
            } else if (s_isLiquidityProvider[to]) {
                currentFee = s_sellFee;
            } else {
                currentFee = s_transferFee;
            }

            if (currentFee != 0) {
                uint256 feeAmount = (tempAmount * currentFee) / 100;
                super._transfer(from, address(this), feeAmount);
                tempAmount = tempAmount - feeAmount;
            }
        }

        super._transfer(from, to, tempAmount);
    }

    /**
     * @dev Check to see whether the `from` address is not included in the cooldown whitelist.
     * If not, make sure the cooldown period is not in effect; if it is, stop the transfer.
     */
    function _beforeTokenTransfer(
        address from,
        address,
        uint256
    ) internal virtual override {
        if (!s_cooldownWhitelist[from]) {
            require(
                s_cooldowns[from] <= uint32(block.timestamp),
                "Please wait a bit before transferring or selling your tokens."
            );
        }
    }

    /**
     * @dev If the `to` address is not in the cooldown whitelist, add cooldown to it.
     */
    function _afterTokenTransfer(
        address,
        address to,
        uint256
    ) internal virtual override {
        if (!s_cooldownWhitelist[to]) {
            s_cooldowns[to] = uint32(block.timestamp + s_cooldownTime);
        }
    }

    /**
     * @dev function used for internally swap tokens (collected as fee) from within
     * the contract to ETH.
     *
     * @param amountTokens total of tokens used for swap
     */
    function swapTokensForEth(uint256 amountTokens) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = s_uniswapV2Router.WETH();
        _approve(address(this), address(s_uniswapV2Router), amountTokens);
        s_uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountTokens,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    /**
     * @dev send the ETH from within the contract to the fee wallet
     *
     * @param amountETH total of ETH to be sent to the fee address
     */
    function sendETHToFee(uint256 amountETH) private {
        payable(s_feeAddress).transfer(amountETH);
    }

    /**
     * @dev withdraw tokens from the contract and send to the owner
     *
     * @param amountTokens total of tokens to be withdrawn
     */
    function withdrawTokens(uint256 amountTokens) external virtual onlyOwner {
        require(
            amountTokens <= balanceOf(address(this)) && amountTokens > 0,
            "Wrong amount"
        );
        _transfer(address(this), owner(), amountTokens);
    }

    /**
     * @dev withdraw ETH from the contract and send to the owner
     */
    function withdrawETH() external virtual onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        if (contractETHBalance > 0) {
            sendETHToFee(contractETHBalance);
        }
    }

    /**
     * @dev manual swap of tokens from within the contract
     *
     * @param amountTokens total of tokens used for swap
     */
    function manualSwap(uint256 amountTokens) external virtual onlyOwner {
        require(
            amountTokens <= balanceOf(address(this)) &&
                amountTokens > 0 &&
                amountTokens < 45_000e18,
            "Wrong amount"
        );
        swapTokensForEth(amountTokens);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}