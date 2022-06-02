// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

//import "IERC20.sol";
//import "SafeERC20.sol";
//import "ISwapRouter.sol";
import "IERC20.sol";
import "SafeERC20.sol";
import "ISwapRouter.sol";

interface IERC20Detailed is IERC20 {
    function decimals() external view returns (uint256);
}

interface IUniswapRouter is ISwapRouter {
    function refundETH() external payable;
}

interface ISpaceTimeOracle {
    function getTargetAssets() external view returns (string[] memory, uint256);

    function getSymbolAddress(string memory _symbol)
        external
        view
        returns (address);

    function getSymbolPrice(string memory _symbol)
        external
        view
        returns (uint256);

    function getSymbolTargetPercentage(
        string memory _symbol,
        string memory _targetRiskWeighting
    ) external view returns (uint256);
}

interface WBNB {
    function deposit() external payable;

    function withdraw(uint256 wad) external payable;

    function totalSupply() external returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);
}

contract Wallet {
    address public oracleAddress;
    string public riskWeighting;
    address public wbnbAddress;
    string[] public ownedSymbols; // = ["UNI", "WBTC", "MKR", "SUSHI"];
    //string[] public targetAssetsList; // should be memory, not stored
    uint256 wbnbBalance = 0; // should be memory, not stored
    uint256 bnbBalance = 0; // should be memory, not stored
    uint256 totalBalance; // should be memory, not stored
    uint256 public totalDeposited = 0; // track deposits
    address payable depositFeeAddress;
    address payable performanceFeeAddress;
    uint256 depositFee;
    uint256 performanceFee;
    address public uinswapV3RouterAddress;

    //mapping(string => address) internal ownedSymbolToAssetAddress;
    //mapping(string => uint256) internal ownedSymbolToPrice;
    //mapping(string => uint256) internal ownedSymbolToTargetPercentage;

    using SafeERC20 for IERC20;
    using SafeERC20 for WBNB;

    WBNB wbnbToken = WBNB(wbnbAddress);

    IUniswapRouter uniswapRouter = IUniswapRouter(uinswapV3RouterAddress);

    constructor(address _SpaceTimeOracleAddress) {
        oracleAddress = address(_SpaceTimeOracleAddress);
        riskWeighting = "rwMaxAssetCap"; //* TO BE SET BY DEPLOYMENT FUNCTION *//
        depositFee = 5; // 0.05% calculated as 5/1000
        performanceFee = 50; // 5.0% calculated as 50/1000
        depositFeeAddress = payable(0x5131da5D06C50262342802DeCFfC775A3A4DD66B);
        performanceFeeAddress = payable(
            0xc34185b9BF47e236c89b09DAb8091081cA8039EC
        );
        wbnbAddress = address(0xd0A1E359811322d97991E03f863a0C30C2cF029C); //Kovan testnet
        uinswapV3RouterAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    }

    function processDepositFee(uint256 _bnbBalance) internal {
        uint256 depositFeeAmount = (_bnbBalance * depositFee) / 1000;
        IERC20(wbnbAddress).safeTransfer(depositFeeAddress, depositFeeAmount);
    }

    function processPerformanceFee(uint256 _profit) internal {
        uint256 performanceFeeAmount = (_profit * performanceFee) / 1000;
        IERC20(wbnbAddress).safeTransfer(
            performanceFeeAddress,
            performanceFeeAmount
        );
    }

    function getBnbBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getWbnbBalance() public view returns (uint256) {
        return IERC20Detailed(wbnbAddress).balanceOf(address(this));
    }

    function getTokenBalance(string memory _token)
        public
        view
        returns (uint256, uint256)
    {
        address tokenAddress = address(
            ISpaceTimeOracle(oracleAddress).getSymbolAddress(_token)
        );
        IERC20Detailed assetToken = IERC20Detailed(tokenAddress);
        uint256 tokenBalance = assetToken.balanceOf(address(this));
        uint256 tokenDecimals = assetToken.decimals();
        uint256 tokenPrice = ISpaceTimeOracle(oracleAddress).getSymbolPrice(
            _token
        );
        uint256 tokenBalanceInWbnb = (tokenBalance * tokenPrice) /
            10**tokenDecimals;
        return (tokenBalance, tokenBalanceInWbnb);
    }

    function getTotalBalanceInWbnb(string[] memory _ownedAssets)
        public
        view
        returns (uint256)
    {
        uint256 _tokenBalances = 0;
        if (_ownedAssets.length > 0) {
            for (uint256 x = 0; x < _ownedAssets.length; x++) {
                (, uint256 tokenBalanceInWbnb) = getTokenBalance(
                    _ownedAssets[x]
                );
                _tokenBalances = _tokenBalances + tokenBalanceInWbnb;
            }
        }
        uint256 _totalBalance = _tokenBalances +
            getBnbBalance() +
            getWbnbBalance();
        return _totalBalance;
    }

    // Update targetAssets with the latest targets from the SpaceTimeOracle
    function getTargetAssets() public view returns (string[] memory) {
        (string[] memory targetAssets, ) = ISpaceTimeOracle(oracleAddress)
            .getTargetAssets();
        return targetAssets;
    }

    /* 
    //
    Create sell, adjust and buy lists based on currently owned assets and the target asset lists pulled from the SpaceTimeOracle
    //
    */
    string[] public sellSymbolsList;

    function getSellSymbolsList() public view returns (string[] memory) {
        return sellSymbolsList;
    }

    event createListEvent(string, string[]);

    // Output 1: items in owned that do not exist in target (SELL)
    function createSellList(string[] memory _targetAssetsList)
        public
        returns (string[] memory)
    {
        if (ownedSymbols.length > 0) {
            string[] memory _ownedSymbols = ownedSymbols;
            string[] memory sellSymbols = new string[](5);
            uint256 index = 0;

            for (uint256 x = 0; x < _ownedSymbols.length; x++) {
                for (uint256 i = 0; i < _targetAssetsList.length; i++) {
                    if (
                        keccak256(abi.encodePacked(_ownedSymbols[x])) ==
                        keccak256(abi.encodePacked(_targetAssetsList[i]))
                    ) {
                        if (x < _ownedSymbols.length) {
                            _ownedSymbols[x] = "!Removed!";
                        } else {
                            delete _ownedSymbols;
                        }
                    }
                }
                if (
                    keccak256(abi.encodePacked(_ownedSymbols[x])) !=
                    keccak256(abi.encodePacked("!Removed!"))
                ) {
                    sellSymbols[index] = _ownedSymbols[x];
                    index = index + 1;
                }
            }
            emit createListEvent("sellSymbols", sellSymbols);
            return sellSymbols;
        } else {
            string[] memory sellSymbols;
            emit createListEvent("sellSymbols", sellSymbols);
            return sellSymbols;
        }
    }

    // Output 2: items in target that exist in owned (ADJUST)
    function createAdjustList(string[] memory _targetAssetsList)
        public
        returns (string[] memory)
    {
        if (ownedSymbols.length > 0) {
            string[] memory _ownedSymbols = ownedSymbols;
            string[] memory adjustSymbols = new string[](5);
            uint256 index = 0;

            for (uint256 i = 0; i < _targetAssetsList.length; i++) {
                for (uint256 x = 0; x < _ownedSymbols.length; x++) {
                    if (
                        keccak256(abi.encodePacked(_targetAssetsList[i])) ==
                        keccak256(abi.encodePacked(_ownedSymbols[x]))
                    ) {
                        adjustSymbols[index] = _ownedSymbols[x];
                        index = index + 1;
                    }
                }
            }
            emit createListEvent("adjustSymbols", adjustSymbols);
            return adjustSymbols;
        } else {
            string[] memory adjustSymbols;
            emit createListEvent("adjustSymbols", adjustSymbols);
            return adjustSymbols;
        }
    }

    // Output 3: items in target that do not exist in owned (BUY)
    function createBuyList(string[] memory _targetAssetsList)
        public
        returns (string[] memory)
    {
        string[] memory _ownedSymbols = ownedSymbols;
        string[] memory buySymbols = new string[](5);
        uint256 index = 0;

        for (uint256 x = 0; x < _targetAssetsList.length; x++) {
            for (uint256 i = 0; i < _ownedSymbols.length; i++) {
                if (
                    keccak256(abi.encodePacked(_targetAssetsList[x])) ==
                    keccak256(abi.encodePacked(_ownedSymbols[i]))
                ) {
                    if (x < _targetAssetsList.length) {
                        _targetAssetsList[x] = "!Removed!";
                    } else {
                        delete _targetAssetsList;
                    }
                }
            }
            if (
                keccak256(abi.encodePacked(_targetAssetsList[x])) !=
                keccak256(abi.encodePacked("!Removed!"))
            ) {
                buySymbols[index] = _targetAssetsList[x];
                index = index + 1;
            }
        }
        emit createListEvent("buySymbols", buySymbols);
        return buySymbols;
    }

    /* 
    //
    Swap tokens based on the sell, adjust or buy lists
    //
    */
    event transactionDetail(string, string, uint256, uint256);
    event sellAsset(string);

    // Sell assets that are owned and are no longer on the target list
    function sellAssets(string[] memory _sellList) internal {
        require(_sellList.length > 0, "No assets in list");
        for (uint256 x = 0; x < _sellList.length; x++) {
            if (
                keccak256(abi.encodePacked(_sellList[x])) !=
                keccak256(abi.encodePacked(""))
            ) {
                //SELL
                emit sellAsset(_sellList[x]);
                address tokenAddress = ISpaceTimeOracle(oracleAddress)
                    .getSymbolAddress(_sellList[x]);
                (
                    uint256 tokenBalance,
                    uint256 tokenBalanceInWbnb
                ) = getTokenBalance(_sellList[x]);
                buyWbnb(tokenAddress, tokenBalance);
                emit transactionDetail(
                    "Sold",
                    _sellList[x],
                    tokenBalance,
                    tokenBalanceInWbnb
                );
            }
        }
    }

    event adjustAsset(string);

    function adjustAssets(string[] memory _adjustList) internal {
        require(_adjustList.length > 0, "No assets in list");
        for (uint256 x = 0; x < _adjustList.length; x++) {
            if (
                keccak256(abi.encodePacked(_adjustList[x])) !=
                keccak256(abi.encodePacked(""))
            ) {
                //ADJUST
                emit adjustAsset(_adjustList[x]);
            }
        }
    }

    event buyAsset(string);
    event buyAssetAmount(uint256); //remove after testing

    function buyAssets(string[] memory _buyList, uint256 _totalBalance)
        internal
    {
        require(_buyList.length > 0, "No assets in list");
        for (uint256 x = 0; x < _buyList.length; x++) {
            if (
                keccak256(abi.encodePacked(_buyList[x])) !=
                keccak256(abi.encodePacked(""))
            ) {
                //BUY
                emit buyAsset(_buyList[x]);
                uint256 targetPercentage = ISpaceTimeOracle(oracleAddress)
                    .getSymbolTargetPercentage(_buyList[x], riskWeighting);
                uint256 wbnbAmountIn = (_totalBalance / 100) * targetPercentage;
                emit buyAssetAmount(wbnbAmountIn);
                address tokenAddress = address(
                    ISpaceTimeOracle(oracleAddress).getSymbolAddress(
                        _buyList[x]
                    )
                );
                sellWbnb(tokenAddress, wbnbAmountIn);
                (
                    uint256 tokenBalance,
                    uint256 tokenBalanceInWbnb
                ) = getTokenBalance(_buyList[x]);

                emit transactionDetail(
                    "Bought",
                    _buyList[x],
                    tokenBalance,
                    tokenBalanceInWbnb
                );
                //ownedSymbols.push(buySymbols[i]);
            }
        }
    }

    event returnBalance(string msg, uint256 ref);

    function rebalance() public {
        string[] memory targetAssetsList = getTargetAssets();
        string[] memory sellList = createSellList(targetAssetsList);
        string[] memory adjustList = createAdjustList(targetAssetsList);
        string[] memory buyList = createBuyList(targetAssetsList);

        bnbBalance = getBnbBalance();
        emit returnBalance("BNB", bnbBalance);
        if (bnbBalance > 0) {
            totalDeposited = bnbBalance + totalDeposited;
            wrapBNB();
            //processDepositFee(bnbBalance);
        }

        //sellAssets(sellList);
        //adjustAssets(adjustList);
        buyAssets(buyList, getTotalBalanceInWbnb(ownedSymbols));
        //function updateOwnedSymbols() {
        //    ownedSymbols = new string[];
        //    for i in adjust: add to owned
        //    for i in buy: add to owned
        //}

        //update total balance
        // at this point items in adjust assets are the only "owned" assets except for WBNB, so new ownedSymbols = adjustassets
        // OR update total balance on adjust assets
        //if (adjustSymbolsList.length > 0) {
        //    ISpaceTimeRebalancer.adjustAssets(_sellSymbolsList);
        //}
        //update total balance
        //if (buySymbolsList.length > 0) {
        //    ISpaceTimeRebalancer.buyAssets(_sellSymbolsList);
        //}
    }

    receive() external payable {}

    fallback() external payable {}

    function wrapBNB() public {
        bnbBalance = getBnbBalance();
        require(bnbBalance > 0, "No BNB available to wrap");
        wbnbToken.deposit{value: bnbBalance}();
    }

    function unWrapBNB() public {
        wbnbBalance = getWbnbBalance();
        require(wbnbBalance > 0, "No WBNB available to unwrap");
        wbnbToken.approve(address(this), wbnbBalance);
        wbnbToken.withdraw(wbnbBalance);
    }

    function buyWbnb(address _tokenAddress, uint256 _amountIn) internal {
        uint256 deadline = block.timestamp + 15;
        uint24 fee = 10000;
        address recipient = address(this);
        uint256 amountOutMinimum = 0;
        //amountOutMinimum: ((100 - slippage) * token1Amount) / 100,
        uint160 sqrtPriceLimitX96 = 0;
        IERC20Detailed assetToken = IERC20Detailed(_tokenAddress);
        require(
            assetToken.approve(address(uinswapV3RouterAddress), _amountIn),
            "Token approve failed"
        );
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams(
                _tokenAddress,
                wbnbAddress,
                fee,
                recipient,
                deadline,
                _amountIn,
                amountOutMinimum,
                sqrtPriceLimitX96
            );
        uniswapRouter.exactInputSingle(params);
        uniswapRouter.refundETH(); // check for Pancakeswap
    }

    function sellWbnb(address _tokenAddress, uint256 _amountIn) internal {
        uint256 deadline = block.timestamp + 15;
        uint24 fee = 10000;
        address recipient = address(this);
        uint256 amountOutMinimum = 0;
        //amountOutMinimum: ((100 - slippage) * token1Amount) / 100,
        uint160 sqrtPriceLimitX96 = 0;
        require(
            wbnbToken.approve(address(uinswapV3RouterAddress), _amountIn),
            "WBNB approve failed"
        );
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams(
                wbnbAddress,
                _tokenAddress,
                fee,
                recipient,
                deadline,
                _amountIn,
                amountOutMinimum,
                sqrtPriceLimitX96
            );
        uniswapRouter.exactInputSingle(params);
        uniswapRouter.refundETH();
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

import "IERC20.sol";
import "Address.sol";

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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import "IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params)
        external
        payable
        returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}