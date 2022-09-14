pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@gelatonetwork/relay-context/contracts/GelatoRelayContext.sol";
import "./INiftyOrderbook.sol";
import "./lib/Ownable.sol";
import "./Validator.sol";
import "./MarketRegistry.sol";
import "./IWeth.sol";

contract NiftyOrderbook is INiftyOrderbook, ReentrancyGuard, Validator, Ownable, GelatoRelayContext {

    string public constant name = "Nifty Orderbook";
    string public constant version = "1.0";

    bool isOpen = true;
    bool onlyGelatoCanMatch = true;

    MarketRegistry public marketRegistry;
    IWeth public weth;

    mapping(bytes32 => uint256) public amountFulfilled;

    mapping(bytes32 => bool) public cancelled;

    event Match(bytes32 orderHash, uint256 amountFilled);

    event Cancel(bytes32 orderHash, uint256 amountFilled);

    constructor(uint chainId, address _marketRegistry, address payable _weth) {
        DOMAIN_SEPARATOR = hash(EIP712Domain({
            name              : name,
            version           : version,
            chainId           : chainId,
            verifyingContract : address(this)
        }));
        marketRegistry = MarketRegistry(_marketRegistry);
        weth = IWeth(_weth);
    }

    modifier contractIsOpen() {
        require(isOpen, "contract close");
        _;
    }

    modifier onlyGelatoRelayMatch() {
        if (onlyGelatoCanMatch) {
            require(
                _isGelatoRelay(msg.sender),
                "only gelato can match"
            );
        }
        _;
    }

    function setMarketRegistry(address _marketRegistry) external onlyOwner {
        marketRegistry = MarketRegistry(_marketRegistry);
    }

    function toggleIsOpen() external onlyOwner {
        isOpen = !isOpen;
    }

    function toggleOnlyGelatoCanMatch() external onlyOwner {
        onlyGelatoCanMatch = !onlyGelatoCanMatch;
    }

    /// @dev After calling, the order can not be filled anymore.
    /// @param order Order struct containing order specifications.
    function cancelOrder(Order calldata order) public
    {
        // Validate transaction signed by maker
        if (order.maker != msg.sender) {
            revert('invalid maker');
        }
        // get the order hash
        bytes32 orderHash = hashOrder(order);
        // validate not fully filled
        require(amountFulfilled[orderHash] < order.amount, "order has already been fully filled");
        // validate not cancelled
        require(!cancelled[orderHash], "order has already been cancelled");
        // update cancel state
        cancelled[orderHash] = true;
        // emit cancel event
        emit Cancel(orderHash, amountFulfilled[orderHash]);
    }

    /// @dev direct buy - cart
    /// @param tradeDetails items to purchase
    function buy(
        MarketRegistry.TradeDetails[] calldata tradeDetails
    ) external payable nonReentrant contractIsOpen {
        // execute trades
        _trade(tradeDetails);
        // return remaining ETH (if any)
        if (address(this).balance > 0) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    /// @dev fulfill limit order
    /// @param signature signed by the order maker
    /// @param order limit order to fill
    /// @param tradeDetails items to purchase
    function matchOrders(
        bytes calldata signature,
        Order calldata order,
        MarketRegistry.TradeDetails[] calldata tradeDetails
    ) external payable nonReentrant contractIsOpen onlyGelatoRelayMatch {
        // get the order hash
        bytes32 orderHash = hashOrder(order);
        // get the number of items to fulfill
        uint256 numOfItems = tradeDetails.length;
        // validate signature
        require(signatureValid(orderHash, order.maker, signature), "signature invalid");
        // validate expiration time
        require(order.expirationTime >= block.timestamp, "order expired");
        // validate items can be fulfilled
        require(amountFulfilled[orderHash] + numOfItems <= order.amount && numOfItems > 0, "too much to fulfill");
        // validate not cancelled
        require(!cancelled[orderHash], "order has been cancelled");
        // validate the order items
        uint256 totalValue = validateOrderItems(tradeDetails, order);
        // update amount filfilled
        amountFulfilled[orderHash] += numOfItems;
        // if relayer is executing calculate total value plus fee
        if (_isGelatoRelay(msg.sender)) {
            // check maxFee per nft
            totalValue += _getFee();
        }
        // take current value from order maker
        weth.transferFrom(order.maker, address(this), totalValue);
        // convert weth to eth
        weth.withdraw(totalValue);
        // if relayer is executing pay it's fee
        if (_isGelatoRelay(msg.sender)) {
            _transferRelayFeeCapped(order.maxFee * numOfItems);
        }
        // execute trades
        _trade(tradeDetails);
        // return remaining ETH (if any)
        if (address(this).balance > 0) {
            payable(order.maker).transfer(address(this).balance);
        }
        // emit match event
        emit Match(orderHash, amountFulfilled[orderHash]);
    }

    function validateOrderItems(
        MarketRegistry.TradeDetails[] calldata tradeDetails,
        Order calldata order
    ) internal view returns (uint256 totalValue) {
        for (uint256 i = 0; i < tradeDetails.length; i++) {
            // market details
            (,uint256 assetContractSlice, uint256 receiverAddressSlice,) = marketRegistry.markets(tradeDetails[i].marketId);
            // asset contract address should match trade details
            require(getAddress(tradeDetails[i].tradeData, assetContractSlice) == order.contractAddress, "wrong asset purchase");
            // receiver address should match order maker
            require(getAddress(tradeDetails[i].tradeData, receiverAddressSlice) == order.maker, "wrong receiver");
            // price should be lower than order
            require(order.price >= tradeDetails[i].value, "high asset price");
            // total order value
            totalValue += tradeDetails[i].value;
        }

        return totalValue;
    }

    function _trade(MarketRegistry.TradeDetails[] memory tradeDetails)
        internal
    {
        require(tradeDetails.length > 0, "tradeDetails not valid");

        for (uint256 i = 0; i < tradeDetails.length; i++) {
            // get market details
            (address _proxy,,,bool _isActive) = marketRegistry
                .markets(tradeDetails[i].marketId);
            // market should be active
            require(_isActive, "market not active");
            // execute trade
            (bool success, ) = _proxy.call{value: tradeDetails[i].value}(
                tradeDetails[i].tradeData
            );
            // check if the call passed successfully
            _checkCallResult(success);
        }
    }

    function _checkCallResult(bool _success) internal pure {
        if (!_success) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function getAddress(bytes calldata tradeData, uint256 addressSlice)
        internal
        pure
        returns (address slicedAddress)
    {
        // sliced the data at a given point
        return
            abi.decode(
                tradeData[addressSlice:],
                (address)
            );
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.4;

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
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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

pragma solidity ^0.8.4;

contract EIP712 {

    struct EIP712Domain {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    bytes32 DOMAIN_SEPARATOR;

    function hash(EIP712Domain memory eip712Domain)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(eip712Domain.name)),
            keccak256(bytes(eip712Domain.version)),
            eip712Domain.chainId,
            eip712Domain.verifyingContract
        ));
    }

}

pragma solidity ^0.8.4;

import "./lib/EIP712.sol";
import "./INiftyOrderbook.sol";

contract Validator is INiftyOrderbook, EIP712 {
    bytes32 constant ORDER_TYPEHASH = keccak256(
        "Order(address maker,address contractAddress,uint256 amount,uint256 price,uint256 maxFee,uint256 expirationTime,uint256 salt)"
    );

    function hashOrder(Order memory order)
        public
        pure
        returns (bytes32 hash)
    {
        /* Per EIP 712. */
        return keccak256(abi.encode(
            ORDER_TYPEHASH,
            order.maker,
            order.contractAddress,
            order.amount,
            order.price,
            order.maxFee,
            order.expirationTime,
            order.salt
        ));
    }

    function hashToSign(bytes32 orderHash)
        internal
        view
        returns (bytes32 hash)
    {
        /* Calculate the string a user must sign. */
        return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            orderHash
        ));
    }

    function signatureValid(bytes32 orderHash, address maker, bytes memory signature) public view returns (bool isValid) {
        /* Calculate hash which must be signed. */
        bytes32 calculatedHashToSign = hashToSign(orderHash);
        
        uint8 v = uint8(signature[0]);
        bytes32 r;
        bytes32 s;
        assembly {
            r := mload(add(signature, 33))
            s := mload(add(signature, 65))
        }

        if (signature.length > 65 && signature[signature.length-1] == 0x03) { // EthSign byte
            /* (d.1): Old way: order hash signed by maker using the prefixed personal_sign */
            return ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",calculatedHashToSign)), v, r, s) == maker;
        }
        /* (d.2): New way: order hash signed by maker using sign_typed_data */
        return ecrecover(calculatedHashToSign, v, r, s) == maker;
    }

}

pragma solidity ^0.8.4;

import "./lib/Ownable.sol";

contract MarketRegistry is Ownable {
    struct TradeDetails {
        uint256 marketId;
        uint256 value;
        bytes tradeData;
    }

    struct Market {
        address proxy;
        uint256 assetContractSlice;
        uint256 receiverAddressSlice;
        bool isActive;
    }

    Market[] public markets;

    function addMarket(address proxy, uint256 assetContractSlice, uint256 receiverAddressSlice) external onlyOwner {
        markets.push(Market(proxy, assetContractSlice, receiverAddressSlice, true));
    }

    function setMarketStatus(uint256 marketId, bool newStatus)
        external
        onlyOwner
    {
        Market storage market = markets[marketId];
        market.isActive = newStatus;
    }

    function setMarketProxy(
        uint256 marketId,
        address newProxy,
        uint256 assetContractSlice,
        uint256 receiverAddressSlice
    ) external onlyOwner {
        Market storage market = markets[marketId];
        market.proxy = newProxy;
        market.assetContractSlice = assetContractSlice;
        market.receiverAddressSlice = receiverAddressSlice;
    }
}

pragma solidity ^0.8.4;

interface IWeth {
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function withdraw(uint wad) external;
}

pragma solidity ^0.8.4;

interface INiftyOrderbook {
    struct Order {
        /* maker address */
        address maker;
        /* contract address for the nft */
        address contractAddress;
        /* total nfts maker wants to buy */
        uint256 amount;
        /* price per nft */
        uint256 price;
        /* max tx fee per nft - gas + fee */
        uint256 maxFee;
        /* expiration timestamp - 0 no expiry */
        uint256 expirationTime;
        /* salt */
        uint256 salt;
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
pragma solidity ^0.8.1;

import {NATIVE_TOKEN} from "../constants/Tokens.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library TokenUtils {
    using SafeERC20 for IERC20;

    modifier onlyERC20(address _token) {
        require(_token != NATIVE_TOKEN, "TokenUtils.onlyERC20");
        _;
    }

    function transfer(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount == 0) return;
        _token == NATIVE_TOKEN
            ? Address.sendValue(payable(_to), _amount)
            : IERC20(_token).safeTransfer(_to, _amount);
    }

    function transferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal onlyERC20(_token) {
        if (_amount == 0) return;
        IERC20(_token).safeTransferFrom(_from, _to, _amount);
    }

    function getBalance(address token, address user)
        internal
        view
        returns (uint256)
    {
        return
            token == NATIVE_TOKEN
                ? user.balance
                : IERC20(token).balanceOf(user);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

address constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

address constant GELATO_RELAY = 0xaBcC9b596420A9E9172FD5938620E265a0f9Df92;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import {TokenUtils} from "./lib/TokenUtils.sol";
import {GELATO_RELAY} from "./constants/GelatoRelay.sol";

/**
 * @dev Context variant with Gelato Relay Fee support.
 * Expects calldata encoding:
 *   abi.encodePacked(bytes fnArgs, address feeCollectorAddress, address feeToken, uint256 fee)
 * Therefore, we're expecting 3 * 32bytes to be appended to normal msgData
 * 32bytes start offsets from calldatasize:
 *     feeCollector: - 32 * 3
 *     feeToken: - 32 * 2
 *     fee: - 32
 */
abstract contract GelatoRelayContext {
    using TokenUtils for address;

    // GelatoRelayContext
    uint256 internal constant _FEE_COLLECTOR_START = 3 * 32;
    uint256 internal constant _FEE_TOKEN_START = 2 * 32;
    uint256 internal constant _FEE_START = 32;

    modifier onlyGelatoRelay() {
        require(
            _isGelatoRelay(msg.sender),
            "GelatoRelayContext.onlyGelatoRelay"
        );
        _;
    }

    // DANGER! Only use with onlyGelatoRelay `_isGelatoRelay` before transferring
    function _transferRelayFee() internal {
        _getFeeToken().transfer(_getFeeCollector(), _getFee());
    }

    // DANGER! Only use with onlyGelatoRelay `_isGelatoRelay` before transferring
    function _transferRelayFeeCapped(uint256 _maxFee) internal {
        uint256 fee = _getFee();
        require(
            fee <= _maxFee,
            "GelatoRelayContext._transferRelayFeeCapped: maxFee"
        );
        _getFeeToken().transfer(_getFeeCollector(), fee);
    }

    function _isGelatoRelay(address _forwarder)
        internal
        view
        virtual
        returns (bool)
    {
        return _forwarder == GELATO_RELAY;
    }

    function _msgData() internal view returns (bytes calldata) {
        return
            _isGelatoRelay(msg.sender)
                ? msg.data[:msg.data.length - _FEE_COLLECTOR_START]
                : msg.data;
    }

    // Only use with previous onlyGelatoRelay or `_isGelatoRelay` checks
    function _getFeeCollector() internal pure returns (address) {
        return
            abi.decode(
                msg.data[msg.data.length - _FEE_COLLECTOR_START:],
                (address)
            );
    }

    // Only use with previous onlyGelatoRelay or `_isGelatoRelay` checks
    function _getFeeToken() internal pure returns (address) {
        return
            abi.decode(
                msg.data[msg.data.length - _FEE_TOKEN_START:],
                (address)
            );
    }

    // Only use with previous onlyGelatoRelay or `_isGelatoRelay` checks
    function _getFee() internal pure returns (uint256) {
        return abi.decode(msg.data[msg.data.length - _FEE_START:], (uint256));
    }
}