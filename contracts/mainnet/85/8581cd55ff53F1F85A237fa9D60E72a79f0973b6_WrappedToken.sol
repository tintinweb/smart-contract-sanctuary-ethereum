// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IOnchainVaults.sol";
import "./interfaces/IOrderRegistry.sol";
import "./interfaces/IShareToken.sol";
import "./interfaces/IStrategyPool.sol";

/**
 * @title common broker
 */
contract Broker is Ownable {
    using Address for address;
    using SafeERC20 for IERC20;

    event PriceChanged(uint256 rideId, uint256 oldVal, uint256 newVal);
    event SlippageChanged(uint256 rideId, uint256 oldVal, uint256 newVal);
    event RideInfoRegistered(uint256 rideId, RideInfo rideInfo);
    event MintAndSell(uint256 rideId, uint256 mintShareAmt, uint256 price, uint256 slippage);
    event CancelSell(uint256 rideId, uint256 cancelShareAmt);
    event RideDeparted(uint256 rideId, uint256 usedInputTokenAmt);
    event SharesBurned(uint256 rideId, uint256 burnedShareAmt);
    event SharesRedeemed(uint256 rideId, uint256 redeemedShareAmt);
    event OnchainVaultsChanged(address oldAddr, address newAddr);

    address public onchainVaults;

    mapping (uint256=>uint256) public prices; // rideid=>price, price in decimal 1e18
    uint256 public constant PRICE_DECIMALS = 1e18;
    mapping (uint256=>uint256) public slippages; // rideid=>slippage, slippage in denominator 10000
    uint256 public constant SLIPPAGE_DENOMINATOR = 10000;

    bytes4 internal constant ERC20_SELECTOR = bytes4(keccak256("ERC20Token(address)"));
    bytes4 internal constant ETH_SELECTOR = bytes4(keccak256("ETH()"));
    uint256 internal constant SELECTOR_OFFSET = 0x20;

    // Starkex token id of this mint token

    struct RideInfo {
        address share;
        uint256 tokenIdShare;
        uint256 quantumShare; 
        address inputToken;
        uint256 tokenIdInput;
        uint256 quantumInput;
        address outputToken;
        uint256 tokenIdOutput;
        uint256 quantumOutput;

        address strategyPool; // 3rd defi pool
    }
    // rideid => RideInfo
    // rideId will also be used as vaultIdShare, vaultIdInput and vaultIdOutput,
    // this is easy to maintain and will assure funds from different rides won’t mix together and create weird edge cases
    mapping (uint256 => RideInfo) public rideInfos; 

    mapping (uint256=>uint256) public ridesShares; // rideid=>amount
    mapping (uint256=>bool) public rideDeparted; // rideid=>bool
    
    uint256 public nonce;
    uint256 public constant EXP_TIME = 2e6; // expiration time stamp of the limit order 

    mapping (uint256=>uint256) public actualPrices; //rideid=>actual price

    struct OrderAssetInfo {
        uint256 tokenId;
        uint256 quantizedAmt;
        uint256 vaultId;
    }

    /**
     * @dev Constructor
     */
    constructor(
        address _onchainVaults
    ) {
        onchainVaults = _onchainVaults;
    }

    /**
     * @notice can be set multiple times, will use latest when mintShareAndSell.
     */
    function setPrice(uint256 _rideId, uint256 _price) external onlyOwner {
        require(ridesShares[_rideId] == 0, "change forbidden once share starting to sell");

        uint256 oldVal = prices[_rideId];
        prices[_rideId] = _price;
        emit PriceChanged(_rideId, oldVal, _price);
    }

    /**
     * @notice price slippage allowance when executing strategy
     */
    function setSlippage(uint256 _rideId, uint256 _slippage) external onlyOwner {
        require(_slippage <= 10000, "invalid slippage");
        require(ridesShares[_rideId] == 0, "change forbidden once share starting to sell");

        uint256 oldVal = slippages[_rideId];
        slippages[_rideId] = _slippage;
        emit SlippageChanged(_rideId, oldVal, _slippage);
    }

    /**
     * @notice registers ride info
     */
    function addRideInfo(uint256 _rideId, uint256[3] memory _tokenIds, address[3] memory _tokens, address _strategyPool) external onlyOwner {
        RideInfo memory rideInfo = rideInfos[_rideId];
        require(rideInfo.tokenIdInput == 0, "ride assets info registered already");

        require(_strategyPool.isContract(), "invalid strategy pool addr");
        _checkValidTokenIdAndAddr(_tokenIds[0], _tokens[0]);
        _checkValidTokenIdAndAddr(_tokenIds[1], _tokens[1]);
        _checkValidTokenIdAndAddr(_tokenIds[2], _tokens[2]);

        IOnchainVaults ocv = IOnchainVaults(onchainVaults);
        uint256 quantumShare = ocv.getQuantum(_tokenIds[0]);
        uint256 quantumInput = ocv.getQuantum(_tokenIds[1]);
        uint256 quantumOutput = ocv.getQuantum(_tokenIds[2]);
        rideInfo = RideInfo(_tokens[0], _tokenIds[0], quantumShare, _tokens[1], _tokenIds[1], 
            quantumInput,  _tokens[2], _tokenIds[2], quantumOutput, _strategyPool);
        rideInfos[_rideId] = rideInfo;
        emit RideInfoRegistered(_rideId, rideInfo);
    }

    /**
     * @notice mint share and sell for input token
     */
    function mintShareAndSell(uint256 _rideId, uint256 _amount, uint256 _tokenIdFee, uint256 _quantizedAmtFee, uint256 _vaultIdFee) external onlyOwner {
        RideInfo memory rideInfo = rideInfos[_rideId];
        require(rideInfo.tokenIdInput != 0, "ride assets info not registered");
        require(prices[_rideId] != 0, "price not set");
        require(slippages[_rideId] != 0, "slippage not set");
        require(ridesShares[_rideId] == 0, "already mint for this ride"); 
        if (_tokenIdFee != 0) {
            _checkValidTokenId(_tokenIdFee);
        }

        IShareToken(rideInfo.share).mint(address(this), _amount);

        IERC20(rideInfo.share).safeIncreaseAllowance(onchainVaults, _amount);
        IOnchainVaults(onchainVaults).depositERC20ToVault(rideInfo.tokenIdShare, _rideId, _amount / rideInfo.quantumShare);
        
        _submitOrder(OrderAssetInfo(rideInfo.tokenIdShare, _amount / rideInfo.quantumShare, _rideId), 
            OrderAssetInfo(rideInfo.tokenIdInput, _amount / rideInfo.quantumInput, _rideId), OrderAssetInfo(_tokenIdFee, _quantizedAmtFee, _vaultIdFee));
        
        ridesShares[_rideId] = _amount;

        emit MintAndSell(_rideId, _amount, prices[_rideId], slippages[_rideId]);
    }

    /**
     * @notice cancel selling for input token
     */
    function cancelSell(uint256 _rideId, uint256 _amount, uint256 _tokenIdFee, uint256 _quantizedAmtFee, uint256 _vaultIdFee) external onlyOwner {
        uint256 amount = ridesShares[_rideId];
        require(amount >= _amount, "no enough shares to cancel sell"); 
        require(!rideDeparted[_rideId], "ride departed already");
        if (_tokenIdFee != 0) {
            _checkValidTokenId(_tokenIdFee);
        }

        RideInfo memory rideInfo = rideInfos[_rideId]; //amount > 0 implies that the rideAssetsInfo already registered
        _submitOrder(OrderAssetInfo(rideInfo.tokenIdInput, _amount / rideInfo.quantumInput, _rideId), 
            OrderAssetInfo(rideInfo.tokenIdShare, _amount / rideInfo.quantumShare, _rideId), OrderAssetInfo(_tokenIdFee, _quantizedAmtFee, _vaultIdFee));

        emit CancelSell(_rideId, _amount);
    }

    /**
     * @notice ride departure to execute strategy (swap input token for output token)
     * share : inputtoken = 1 : 1, outputtoken : share = price
     */
    function departRide(uint256 _rideId, uint256 _tokenIdFee, uint256 _quantizedAmtFee, uint256 _vaultIdFee) external onlyOwner {
        require(!rideDeparted[_rideId], "ride departed already");
        if (_tokenIdFee != 0) {
            _checkValidTokenId(_tokenIdFee);
        }

        rideDeparted[_rideId] = true;

        burnRideShares(_rideId); //burn unsold shares
        uint256 amount = ridesShares[_rideId]; //get the left share amount
        require(amount > 0, "no shares to depart"); 
        
        RideInfo memory rideInfo = rideInfos[_rideId]; //amount > 0 implies that the rideAssetsInfo already registered
        IOnchainVaults ocv = IOnchainVaults(onchainVaults);

        uint256 inputTokenAmt;
        {
            uint256 inputTokenQuantizedAmt = ocv.getQuantizedVaultBalance(address(this), rideInfo.tokenIdInput, _rideId);
            assert(inputTokenQuantizedAmt > 0); 
            ocv.withdrawFromVault(rideInfo.tokenIdInput, _rideId, inputTokenQuantizedAmt);
            inputTokenAmt = inputTokenQuantizedAmt * rideInfo.quantumInput;
        }

        uint256 outputAmt;
        if (rideInfo.inputToken == address(0) /*ETH*/) {
            outputAmt = IStrategyPool(rideInfo.strategyPool).sellEth{value: inputTokenAmt}(rideInfo.outputToken);
        } else {
            IERC20(rideInfo.inputToken).safeIncreaseAllowance(rideInfo.strategyPool, inputTokenAmt);
            outputAmt = IStrategyPool(rideInfo.strategyPool).sellErc(rideInfo.inputToken, rideInfo.outputToken, inputTokenAmt);
        }

        {
            uint256 expectMinResult = amount * prices[_rideId] * (SLIPPAGE_DENOMINATOR - slippages[_rideId]) / PRICE_DECIMALS / SLIPPAGE_DENOMINATOR;
            require(outputAmt >= expectMinResult, "price and slippage not fulfilled");
            
            actualPrices[_rideId] = outputAmt * PRICE_DECIMALS / amount;

            if (rideInfo.outputToken != address(0) /*ERC20*/) {
                IERC20(rideInfo.outputToken).safeIncreaseAllowance(onchainVaults, outputAmt);
                ocv.depositERC20ToVault(rideInfo.tokenIdOutput, _rideId, outputAmt / rideInfo.quantumOutput);
            } else {
                ocv.depositEthToVault{value: outputAmt / rideInfo.quantumOutput * rideInfo.quantumOutput}(rideInfo.tokenIdOutput, _rideId);
            }
        }

        _submitOrder(OrderAssetInfo(rideInfo.tokenIdOutput, outputAmt / rideInfo.quantumOutput, _rideId), 
            OrderAssetInfo(rideInfo.tokenIdShare, amount / rideInfo.quantumShare, _rideId), OrderAssetInfo(_tokenIdFee, _quantizedAmtFee, _vaultIdFee));

        emit RideDeparted(_rideId, inputTokenAmt);
    }

    /**
     * @notice burn ride shares after ride is done
     */
    function burnRideShares(uint256 _rideId) public onlyOwner {
        uint256 amount = ridesShares[_rideId];
        require(amount > 0, "no shares to burn"); 
        
        RideInfo memory rideInfo = rideInfos[_rideId]; //amount > 0 implies that the rideAssetsInfo already registered
        IOnchainVaults ocv = IOnchainVaults(onchainVaults);
        uint256 quantizedAmountToBurn = ocv.getQuantizedVaultBalance(address(this), rideInfo.tokenIdShare, _rideId);
        require(quantizedAmountToBurn > 0, "no shares to burn");

        ocv.withdrawFromVault(rideInfo.tokenIdShare, _rideId, quantizedAmountToBurn);

        uint256 burnAmt = quantizedAmountToBurn * rideInfo.quantumShare;
        ridesShares[_rideId] = amount - burnAmt; // update to left amount
        IShareToken(rideInfo.share).burn(address(this), burnAmt);

        emit SharesBurned(_rideId, burnAmt);
    }

    /**
     * @notice user to redeem share for input or output token 
     * input token when ride has not been departed, otherwise, output token
     */
    function redeemShare(uint256 _rideId, uint256 _redeemAmount) external {
        uint256 amount = ridesShares[_rideId];
        require(amount > 0, "no shares to redeem");

        RideInfo memory rideInfo = rideInfos[_rideId]; //amount > 0 implies that the rideAssetsInfo already registered

        IERC20(rideInfo.share).safeTransferFrom(msg.sender, address(this), _redeemAmount);

        IOnchainVaults ocv = IOnchainVaults(onchainVaults);
        bool departed = rideDeparted[_rideId];
        if (departed) {
            //swap to output token
            uint256 boughtAmt = _redeemAmount * actualPrices[_rideId] / PRICE_DECIMALS;            
            ocv.withdrawFromVault(rideInfo.tokenIdOutput, _rideId, boughtAmt / rideInfo.quantumOutput);
            if (rideInfo.outputToken == address(0) /*ETH*/) {
                (bool success, ) = msg.sender.call{value: boughtAmt}(""); 
                require(success, "ETH_TRANSFER_FAILED");                
            } else {
                IERC20(rideInfo.outputToken).safeTransfer(msg.sender, boughtAmt);
            }
        } else {
            //swap to input token
            ocv.withdrawFromVault(rideInfo.tokenIdInput, _rideId, _redeemAmount / rideInfo.quantumInput);
            if (rideInfo.inputToken == address(0) /*ETH*/) {
                (bool success, ) = msg.sender.call{value: _redeemAmount}(""); 
                require(success, "ETH_TRANSFER_FAILED");
            } else {
                IERC20(rideInfo.inputToken).safeTransfer(msg.sender, _redeemAmount);
            }
        }

        ridesShares[_rideId] -= _redeemAmount;
        IShareToken(rideInfo.share).burn(address(this), _redeemAmount);

        emit SharesRedeemed(_rideId, _redeemAmount);
    }

    function _checkValidTokenIdAndAddr(uint256 tokenId, address token) view internal {
        bytes4 selector = _checkValidTokenId(tokenId);
        if (selector == ETH_SELECTOR) {
            require(token == address(0), "ETH addr should be 0");
        } else if (selector == ERC20_SELECTOR) {
            require(token.isContract(), "invalid token addr");
        }
    }

    function _checkValidTokenId(uint256 tokenId) view internal returns (bytes4 selector) {
        selector = extractTokenSelector(IOnchainVaults(onchainVaults).getAssetInfo(tokenId));
        require(selector == ETH_SELECTOR || selector == ERC20_SELECTOR, "unsupported token"); 
    }

    function extractTokenSelector(bytes memory assetInfo)
        internal
        pure
        returns (bytes4 selector)
    {
        assembly {
            selector := and(
                0xffffffff00000000000000000000000000000000000000000000000000000000,
                mload(add(assetInfo, SELECTOR_OFFSET))
            )
        }
    }

    function _submitOrder(OrderAssetInfo memory sellInfo, OrderAssetInfo memory buyInfo, OrderAssetInfo memory feeInfo) private {
        nonce += 1;
        address orderRegistryAddr = IOnchainVaults(onchainVaults).orderRegistryAddress();
        IOrderRegistry(orderRegistryAddr).registerLimitOrder(onchainVaults, sellInfo.tokenId, buyInfo.tokenId, feeInfo.tokenId, 
            sellInfo.quantizedAmt, buyInfo.quantizedAmt, feeInfo.quantizedAmt, sellInfo.vaultId, buyInfo.vaultId, feeInfo.vaultId, nonce, EXP_TIME);
    }

    function setOnchainVaults(address _newAddr) external onlyOwner {
        emit OnchainVaultsChanged(onchainVaults, _newAddr);
        onchainVaults = _newAddr;
    }

    // To receive ETH when invoking IOnchainVaults.withdrawFromVault
    receive() external payable {}
    fallback() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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

pragma solidity 0.8.9;

interface IOnchainVaults {
    function depositERC20ToVault(
        uint256 assetId,
        uint256 vaultId,
        uint256 quantizedAmount
    ) external;

    function depositEthToVault(
        uint256 assetId, 
        uint256 vaultId) 
    external payable;

    function withdrawFromVault(
        uint256 assetId,
        uint256 vaultId,
        uint256 quantizedAmount
    ) external;

    function getQuantizedVaultBalance(
        address ethKey,
        uint256 assetId,
        uint256 vaultId
    ) external view returns (uint256);

    function getVaultBalance(
        address ethKey,
        uint256 assetId,
        uint256 vaultId
    ) external view returns (uint256);

    function getQuantum(uint256 presumedAssetType) external view returns (uint256);

    function orderRegistryAddress() external view returns (address);

    function isAssetRegistered(uint256 assetType) external view returns (bool);

    function getAssetInfo(uint256 assetType) external view returns (bytes memory assetInfo);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IOrderRegistry {

    function registerLimitOrder(
        address exchangeAddress,
        uint256 tokenIdSell,
        uint256 tokenIdBuy,
        uint256 tokenIdFee,
        uint256 amountSell,
        uint256 amountBuy,
        uint256 amountFee,
        uint256 vaultIdSell,
        uint256 vaultIdBuy,
        uint256 vaultIdFee,
        uint256 nonce,
        uint256 expirationTimestamp
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

interface IShareToken {
    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

interface IStrategyPool {
    // sell the amount of the input token, and the amount of output token will be sent to msg.sender
    function sellErc(address inputToken, address outputToken, uint256 inputAmt) external returns (uint256 outputAmt);

    function sellEth(address outputToken) external payable returns (uint256 outputAmt);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../interfaces/IStrategyPool.sol";

import "./interfaces/IDummyToken.sol";

/**
 * @title Dummy pool
 */
contract StrategyDummy is IStrategyPool, Ownable {
    using SafeERC20 for IERC20;

    address public broker;
    modifier onlyBroker() {
        require(msg.sender == broker, "caller is not broker");
        _;
    }

    event BrokerUpdated(address broker);
    event OutputTokensUpdated(address wrapToken, bool enabled);

    mapping(address => bool) public supportedOutputTokens;

    constructor(
        address _broker
    ) {
        broker = _broker;
    }

    function sellErc(address inputToken, address outputToken, uint256 inputAmt) external onlyBroker returns (uint256 outputAmt) {
        bool toBuy = supportedOutputTokens[outputToken];
        bool toSell = supportedOutputTokens[inputToken];

        require(toBuy || toSell, "not supported tokens!");

        IERC20(inputToken).safeTransferFrom(msg.sender, address(this), inputAmt);
        if (toBuy) {
            IERC20(inputToken).safeIncreaseAllowance(outputToken, inputAmt);
            IDummyToken(outputToken).buy(inputAmt);
            outputAmt = IERC20(outputToken).balanceOf(address(this));
            IERC20(outputToken).safeTransfer(msg.sender, outputAmt);
        } else {
            IDummyToken(inputToken).sell(inputAmt);
            outputAmt = IERC20(outputToken).balanceOf(address(this));
            IERC20(outputToken).safeTransfer(msg.sender, outputAmt);
        }
    }

    function sellEth(address outputToken) external onlyBroker payable returns (uint256 outputAmt) {
        // do nothing
    }

    function updateBroker(address _broker) external onlyOwner {
        broker = _broker;
        emit BrokerUpdated(broker);
    }

    function setSupportedOutputToken(address _outputToken, bool _enabled) external onlyOwner {
        supportedOutputTokens[_outputToken] = _enabled;
        emit OutputTokensUpdated(_outputToken, _enabled);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IDummyToken {

    function name() external view  returns (string memory);

    function symbol() external view returns (string memory);
    
    function decimals() external view returns (uint8);

    function mint(address _to, uint _amount) external; 

    function buy(uint _amount) external; 

    function sell(uint _amount) external; 
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IDummyToken.sol";

/**
 * @title Dummy output token
 */
contract OutputTokenDummy is ERC20, Ownable {
    using SafeERC20 for IERC20;

    uint8 private immutable _decimals;

    address private supplyToken;

    uint256 private lastHarvestBlockNum;

    uint256 public harvestPerBlock;  

    address public controller; // st comp
    modifier onlyController() {
        require(msg.sender == controller, "caller is not controller");
        _;
    }

    event ControllerUpdated(address controller);

    constructor(
        address _supplyToken,
        address _controller,
        uint256 _harvestPerBlock
    ) ERC20(string(abi.encodePacked("Celer ", IDummyToken(_supplyToken).name())), string(abi.encodePacked("celr", IDummyToken(_supplyToken).symbol()))) {
        _decimals = IDummyToken(_supplyToken).decimals();
        supplyToken = _supplyToken;
        controller = _controller;
        lastHarvestBlockNum = block.number;
        harvestPerBlock = _harvestPerBlock;
    }
    
    function buy(uint _amount) external onlyController {
        require(_amount > 0, "invalid amount");
        IERC20(supplyToken).safeTransferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount);
    }
    
    function sell(uint _amount) external {
        require(_amount > 0, "invalid amount");
        require(totalSupply() >= _amount, "not enough supply");

        IDummyToken(supplyToken).mint(address(this), harvestPerBlock * (block.number - lastHarvestBlockNum));
        lastHarvestBlockNum = block.number;

        IERC20(supplyToken).safeTransfer(msg.sender, _amount * IERC20(supplyToken).balanceOf(address(this)) / totalSupply());
        _burn(msg.sender, _amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function underlyingToken() public view returns (address) {
        return supplyToken;
    }

    function updateController(address _controller) external onlyOwner {
        controller = _controller;
        emit ControllerUpdated(_controller);
    }

    function updateHarvestPerBlock(uint256 newVal) external onlyOwner {
        harvestPerBlock = newVal;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/ICErc20.sol";
import "./interfaces/IComptroller.sol";

/**
 * @title Wrapped Token of compound c tokens
 */
contract WrappedToken is ERC20, Ownable {
    using Address for address;
    using SafeERC20 for IERC20;

    uint8 private immutable _decimals;

    address private immutable ctoken;
    address public immutable comp; // compound comp token
    address public immutable comptroller; //compound controller

    // min comp reward to distribute, taking into the account of the comp swap gas cost in the strategy. default as 0
    uint256 public minCompRewardToDistribute; 

    address public controller; // st comp
    modifier onlyController() {
        require(msg.sender == controller, "caller is not controller");
        _;
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin && !address(msg.sender).isContract(), "Not EOA");
        _;
    }

    event ControllerUpdated(address controller);
    event MinCompRewardToDistributeUpdated(uint256 newValue);

    constructor(
        address _ctoken,
        address _controller,
        address _comptroller,
        address _comp
    ) ERC20(string(abi.encodePacked("Wrapped ", ICErc20(_ctoken).name())), string(abi.encodePacked("W", ICErc20(_ctoken).symbol()))) {
        _decimals = ICErc20(_ctoken).decimals();
        ctoken = _ctoken;
        controller = _controller;
        comptroller = _comptroller;
        comp = _comp;
    }
    
    function mint(uint _amount) external onlyController {
        require(_amount > 0, "invalid amount");
        IERC20(ctoken).safeTransferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount);
    }
    
    function burn(uint _amount) external {
        require(_amount > 0, "invalid amount");
        require(totalSupply() >= _amount, "not enough supply");
        
        // distribute harvested comp proportional
        uint256 compBalance = IERC20(comp).balanceOf(address(this));
        if (compBalance > 0) {
            uint256 distAmt = compBalance * _amount / totalSupply();
            if (distAmt >= minCompRewardToDistribute) {
                IERC20(comp).safeTransfer(msg.sender, distAmt);
            }
        }

        _burn(msg.sender, _amount);
        IERC20(ctoken).safeTransfer(msg.sender, _amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function underlyingCToken() public view returns (address) {
        return ctoken;
    }

    function harvest() external onlyEOA {
        // Claim COMP token.
        address[] memory holders = new address[](1);
        holders[0] = address(this);
        ICErc20[] memory cTokens = new ICErc20[](1);
        cTokens[0] = ICErc20(ctoken);
        IComptroller(comptroller).claimComp(holders, cTokens, false, true);
    }

    function updateController(address _controller) external onlyOwner {
        controller = _controller;
        emit ControllerUpdated(_controller);
    }

    function updateMinCompRewardToDistribute(uint256 _minComp) external onlyOwner {
        minCompRewardToDistribute = _minComp;
        emit MinCompRewardToDistributeUpdated(_minComp);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ICErc20 {
    /**
     * @notice Accrue interest for `owner` and return the underlying balance.
     *
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external returns (uint256);

    /**
     * @notice Get the token balance of the `owner`
     * @param owner The address of the account to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @notice Supply ERC20 token to the market, receive cTokens in exchange.
     *
     * @param mintAmount The amount of the underlying asset to supply
     * @return 0 = success, otherwise a failure
     */
    function mint(uint256 mintAmount) external returns (uint256);

    /**
     * @notice Redeem cTokens in exchange for a specified amount of underlying asset.
     *
     * @param redeemAmount The amount of underlying to redeem
     * @return 0 = success, otherwise a failure
     */
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    /**
     * @notice Sender redeems cTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of cTokens to redeem into underlying
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeem(uint256 redeemTokens) external returns (uint256);

    /**
     * @notice Returns the current per-block supply interest rate for this cToken
     * @return The supply interest rate per block, scaled by 1e18
     */
    function supplyRatePerBlock() external view returns (uint256);

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() external returns (uint256);

    /**
     * @notice Calculates the exchange rate from the underlying to the CToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() external view returns (uint256);

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address dst, uint256 amount) external returns (bool);

    function name() external view  returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ICErc20.sol";

interface IComptroller {
    /**
     * @notice Claim all the comp accrued by the holder in all markets.
     *
     * @param holder The address to claim COMP for
     */
    function claimComp(address holder) external;

    /**
     * @notice Claim all comp accrued by the holders
     * @param holders The addresses to claim COMP for
     * @param cTokens The list of markets to claim COMP in
     * @param borrowers Whether or not to claim COMP earned by borrowing
     * @param suppliers Whether or not to claim COMP earned by supplying
     */
    function claimComp(
        address[] memory holders,
        ICErc20[] memory cTokens,
        bool borrowers,
        bool suppliers
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/ICErc20.sol";
import "./interfaces/ICEth.sol";
import "./interfaces/IWrappedToken.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "../../interfaces/IStrategyPool.sol";

/**
 * @title Compound pool
 */
contract StrategyCompound is IStrategyPool, Ownable {
    using SafeERC20 for IERC20;

    address public broker;
    modifier onlyBroker() {
        require(msg.sender == broker, "caller is not broker");
        _;
    }

    address public immutable comp; // compound comp token
    address public immutable uniswap; // The address of the Uniswap V2 router
    address public immutable weth; // The address of WETH token

    event BrokerUpdated(address broker);
    event WrapTokenUpdated(address wrapToken, bool enabled);

    mapping(address => bool) public supportedWrapTokens; //wrappedtoken => true

    constructor(
        address _broker,
        address _comp,
        address _uniswap,
        address _weth
    ) {
        broker = _broker;
        comp = _comp;
        uniswap = _uniswap;
        weth = _weth;
    }

    function sellErc(address inputToken, address outputToken, uint256 inputAmt) external onlyBroker returns (uint256 outputAmt) {
        bool toBuy = supportedWrapTokens[outputToken];
        bool toSell = supportedWrapTokens[inputToken];

        require(toBuy || toSell, "not supported tokens!");

        IERC20(inputToken).safeTransferFrom(msg.sender, address(this), inputAmt);
        if (toBuy) { // to buy a wrapped token
            address cToken = IWrappedToken(outputToken).underlyingCToken();
            IERC20(inputToken).safeIncreaseAllowance(cToken, inputAmt);
            uint256 mintResult = ICErc20(cToken).mint(inputAmt);
            require(mintResult == 0, "Couldn't mint cToken");
            outputAmt = ICErc20(cToken).balanceOf(address(this));
            
            // transfer cToken into wrapped token contract and mint equal wrapped tokens 
            IERC20(cToken).safeIncreaseAllowance(outputToken, outputAmt);
            IWrappedToken(outputToken).mint(outputAmt);

            IERC20(outputToken).safeTransfer(msg.sender, outputAmt);
        } else { // to sell a wrapped token
            address cToken = IWrappedToken(inputToken).underlyingCToken();
            
            // transfer cToken/comp from wrapped token contract and burn the wrapped tokens 
            IWrappedToken(inputToken).burn(inputAmt);
            uint256 redeemResult = ICErc20(cToken).redeem(inputAmt);
            require(redeemResult == 0, "Couldn't redeem cToken");

            if (outputToken != address(0) /*ERC20*/) {
                sellCompForErc(outputToken);
                outputAmt = IERC20(outputToken).balanceOf(address(this));
                IERC20(outputToken).safeTransfer(msg.sender, outputAmt);
            } else /*ETH*/ {
                sellCompForEth();
                outputAmt = address(this).balance;
                (bool success, ) = msg.sender.call{value: outputAmt}(""); // NOLINT: low-level-calls.
                require(success, "eth transfer failed");
            }
        }
    }

    function sellCompForErc(address target) private {
        uint256 compBalance = IERC20(comp).balanceOf(address(this));
        if (compBalance > 0) {
            // Sell COMP token for obtain more supplying token(e.g. DAI, USDT)
            IERC20(comp).safeIncreaseAllowance(uniswap, compBalance);

            address[] memory paths = new address[](3);
            paths[0] = comp;
            paths[1] = weth;
            paths[2] = target;

            IUniswapV2Router02(uniswap).swapExactTokensForTokens(
                compBalance,
                uint256(0),
                paths,
                address(this),
                block.timestamp + 1800
            );
        }
    }

    function sellCompForEth() private {
        uint256 compBalance = IERC20(comp).balanceOf(address(this));
        if (compBalance > 0) {
            // Sell COMP token for obtain more ETH
            IERC20(comp).safeIncreaseAllowance(uniswap, compBalance);

            address[] memory paths = new address[](2);
            paths[0] = comp;
            paths[1] = weth;

            IUniswapV2Router02(uniswap).swapExactTokensForETH(
                compBalance,
                uint256(0),
                paths,
                address(this),
                block.timestamp + 1800
            );
        }
    }

    function sellEth(address outputToken) external onlyBroker payable returns (uint256 outputAmt) {
        require(supportedWrapTokens[outputToken], "not supported tokens!");
        
        address cToken = IWrappedToken(outputToken).underlyingCToken();
        ICEth(cToken).mint{value: msg.value}();
        outputAmt = ICEth(cToken).balanceOf(address(this));

        // transfer cToken into wrapped token contract and mint equal wrapped tokens 
        IERC20(cToken).safeIncreaseAllowance(outputToken, outputAmt);
        IWrappedToken(outputToken).mint(outputAmt);

        IERC20(outputToken).safeTransfer(msg.sender, outputAmt);
    }

    function updateBroker(address _broker) external onlyOwner {
        broker = _broker;
        emit BrokerUpdated(broker);
    }

    function setSupportedWrapToken(address _wrapToken, bool _enabled) external onlyOwner {
        supportedWrapTokens[_wrapToken] = _enabled;
        emit WrapTokenUpdated(_wrapToken, _enabled);
    }

    receive() external payable {}
    fallback() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ICEth {
    /**
     * @notice Get the token balance of the `owner`
     * @param owner The address of the account to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @notice Accrue interest for `owner` and return the underlying balance.
     *
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external returns (uint256);

    /**
     * @notice Supply ETH to the market, receive cTokens in exchange.
     */
    function mint() external payable;

    /**
     * @notice Redeem cTokens in exchange for a specified amount of underlying asset.
     *
     * @param redeemAmount The amount of underlying to redeem
     * @return 0 = success, otherwise a failure
     */
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() external returns (uint256);

    /**
     * @notice Calculates the exchange rate from the underlying to the CToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IWrappedToken {
    
    function mint(uint _amount) external; 
    
    function burn(uint _amount) external;

    function underlyingCToken() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.9;

interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external;

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata paths,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title A mintable {ERC20} token.
 */
contract InputTokenDummy is ERC20Burnable, Ownable {
    uint8 private _decimals;

    /**
     * @dev Constructor that gives msg.sender an initial supply of tokens.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply_
    ) ERC20(name_, symbol_) {
        _decimals = decimals_;
        _mint(msg.sender, initialSupply_);
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     */
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IShareToken.sol";

/**
 * @title A {ERC20} token used for ride share.
 */
contract ShareToken is IShareToken, ERC20, Ownable {
    uint8 private immutable _decimals;

    address public broker;
    modifier onlyBroker() {
        require(msg.sender == broker, "caller is not broker");
        _;
    }

    event BrokerUpdated(address broker);

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address _broker
    ) ERC20(name_, symbol_) {
        _decimals = decimals_;
        broker = _broker;
    }

    function mint(address _to, uint256 _amount) external onlyBroker {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external onlyBroker {
        _burn(_from, _amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function updateBroker(address _broker) external onlyOwner {
        broker = _broker;
        emit BrokerUpdated(broker);
    }
}