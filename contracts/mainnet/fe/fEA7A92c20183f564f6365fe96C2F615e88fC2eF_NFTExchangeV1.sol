// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFTExchange.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/INFTify1155.sol";
import "../interfaces/INFTify721.sol";

contract NFTExchangeV1 is NFTExchange {
    using SafeERC20 for IERC20;

    uint256 private constant ERC_721 = 1;
    uint256 private constant ERC_1155 = 0;

    /**
     * @dev Buy from primary sale
     * data: [0] tokenID, [1] quantity, [2] sellOrderSupply, [3] sellOrderPrice, [4] enableMakeOffer
     * ------[5] buyingAmount, [6] tokenType, [7] partnerType, [8] partnerFee, [9] transactionType,
     * ------[10] storeFeeRatio, [11-...] payoutRatios
     * addr: [0] creator == artist, [1] tokenAddress, [2] collectionAddress, [3] signer, [4] storeAddress,
     * ------[5] receiver, [6---] payoutAddress
     * strs: [0] internalTxId
     * signatures: [0] nftBuyRequestSignture, [1] sellOrderSignature, [2] payoutSignature
     */
    function buyNowNative(
        uint256[] memory, /*data*/
        address[] memory, /*addr*/
        string[] memory, /*strs*/
        bytes[] memory /*signatures*/
    ) public payable reentrancyGuard {
        _delegatecall(buyHandler);
    }

    /**
     * @dev Accept offer
     * data: [0] tokenID, [1] quantity, [2] sellOrderSupply, [3] enableMakeOffer, [4] sellOrderPrice
     * ------[5] offerAmount, [6] offerPrice, [7] listingTime, [8] expirationTime, [9] tokenType,
     * ------[10] partnerType, [11] partnerFee, [12] storeFeeRatio, [13-...] payoutRatio
     * addr: [0] creator == artist, [1] contractAddress, [2] tokenAddress, [3] receiver, [4] signer,
     * ------[5] storeAddress, [6-...] payoutAddress
     * strs: [0] internalTxId
     * signatures: [0] nftAcceptOfferSignature, [1] sellOrderSignature, [2] makeOfferSignature, [3] payoutSignature
     */
    function acceptOffer(
        uint256[] memory, /*data*/
        address[] memory, /*addr*/
        string[] memory, /*strs*/
        bytes[] memory /*signatures*/
    ) public reentrancyGuard {
        _delegatecall(offerHandler);
    }

    /**
     * @dev Buy from secondary sale
     * data: [0] tokenID, [1] royaltyRatio, [2] sellOrderSupply, [3] sellOrderPrice, [4] enableMakeOffer,
     * ------[5] amount, [6] tokenType, [7] partnerType, [8] partnerFee, [9] transactionType,
     * ------[10] storeFeeRatio, [11-...] payoutRatios
     * addr: [0] creator == artist, [1] contractAddress, [2] tokenAddress, [3] seller, [4] signer,
     * ------[5] storeAddress, [6] receiver, [7---] payoutAddress
     * strs: [0] internalTxId
     * signatures: [0] nftResellSignature, [1] sellOrderSignature, [2] payoutSignature
     */
    function sellNowNative(
        uint256[] memory, /*data*/
        address[] memory, /*addr*/
        string[] memory, /*strs*/
        bytes[] memory /*signatures*/
    ) public payable reentrancyGuard {
        _delegatecall(sellHandler);
    }

    /**
     * @dev Cancel sale order
     * data: [0] saleOrderID, [1] saleOrderSupply, [2] type
     * addr: [0] signer
     * strs: [...] internalTxId
     * signatures: [0-...] saleOrderSignatures, cancelBatchSignature
     */
    function cancelSaleOrder(
        uint256[] memory, /*data*/
        address[] memory, /*addr*/
        string[] memory, /*strs*/
        bytes[] memory /*signatures*/
    ) public reentrancyGuard {
        _delegatecall(cancelHandler);
    }

    /**
     * @dev Cancel offer
     * data: [0] makeOfferID, [1] type
     * addr: [0] signer
     * strs: [0] internalTxId
     * signatures: [0] makeOfferSignature
     */
    function cancelOffer(
        uint256[] memory, /*data*/
        address[] memory, /*addr*/
        string[] memory, /*strs*/
        bytes[] memory /*signatures*/
    ) public reentrancyGuard {
        _delegatecall(cancelHandler);
    }

    function withdraw(
        address _to,
        address tokenAddress,
        uint256 _amount
    ) public onlyAdmins {
        require(tokenAddress != address(0), "Token address is zero");
        IERC20(tokenAddress).safeTransfer(_to, _amount);
    }

    function transferNFT(
        address collection,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        uint256 tokenType,
        bytes memory data
    ) public reentrancyGuard {
        require(msg.sender == address(this), "NFTify: only proxy contract");

        if (tokenType == ERC_721) {
            INFTify721(collection).safeTransferFrom(from, to, id, data);
        } else if (tokenType == ERC_1155) {
            INFTify1155(collection).safeTransferFrom(
                from,
                to,
                id,
                amount,
                data
            );
        }
    }

    /**
     * @dev Open box
     * data [0] box id, [1-...] token ids
     * addr [0] owner, [1] signer, [2] box's collection, [3-...] token's collection
     * strs [0] internalTxId
     * signatures [0] openBoxSignature, [1-...] boxSignatures
     */
    function openBox(
        uint256[] memory,
        address[] memory,
        string[] memory,
        bytes[] memory
    ) public reentrancyGuard {
        _delegatecall(boxUtils);
    }

    /**
     * @dev Execute meta transaction
     */
    function executeMetaTransaction(
        uint256[] memory, /* data */
        address[] memory, /* addrs */
        bytes[] memory, /* signatures */
        bytes32, /* requestType */
        uint8, /* v */
        bytes32, /* r */
        bytes32 /* s */
    ) public reentrancyGuard {
        _delegatecall(metaHandler);
    }

    /**
     * @dev Claim airdrop
     */
    function claimAirdrop(
        uint256[] memory,
        address[] memory,
        string[] memory,
        bytes[] memory
    ) public reentrancyGuard {
        _delegatecall(airdropHandler);
    }

    /**
     * @dev Cancel airdrop event
     */
    function cancelAirdropEvent(
        uint256[] memory,
        address[] memory,
        string[] memory,
        bytes[] memory
    ) public reentrancyGuard {
        _delegatecall(cancelHandler);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../common/Upgradeable.sol";

contract NFTExchange is Upgradeable {
    event PaymentTokenEvent(address indexed _tokenAddress, string _currencyId);
    event ServiceFeeEvent(
        address indexed _tokenAddress,
        string _currencyId,
        uint256 _feeRate
    );

    modifier onlyAdmins() {
        require(adminList[msg.sender], "Need admin role");
        _;
    }

    modifier onlyAdminsAndSubAdmins(uint8 _role) {
        require(
            adminList[msg.sender] || subAdminList[msg.sender][_role],
            "Only admins or sub-admin with this role"
        );
        _;
    }

    function isAdmin(address _address) public view returns (bool) {
        return adminList[_address];
    }

    function isSubAdmin(address _address, uint8 _role)
        public
        view
        returns (bool)
    {
        return subAdminList[_address][_role] || adminList[_address];
    }

    function setOfferHandler(address newOfferHandler) public onlyAdmins {
        offerHandler = newOfferHandler;
    }

    function setSignatureUtils(address newSignatureUtils) public onlyAdmins {
        signatureUtils = newSignatureUtils;
    }

    function setBuyHandler(address newBuyHandler) public onlyAdmins {
        buyHandler = newBuyHandler;
    }

    function setRecipient(address newRecipient) public onlyAdmins {
        recipient = newRecipient;
    }

    function setFeatureHandler(address newFeatureHandler) public onlyAdmins {
        featureHandler = newFeatureHandler;
    }

    function setSellHandler(address newSellHandler) public onlyAdmins {
        sellHandler = newSellHandler;
    }

    function setCancelHandler(address newCancelHandler) public onlyAdmins {
        cancelHandler = newCancelHandler;
    }

    function setTrustedForwarder(address newForwarder) public onlyAdmins {
        trustedForwarder = newForwarder;
    }

    function setFeeUtils(address newFeeUtils) public onlyAdmins {
        feeUtils = newFeeUtils;
    }

    function setBoxUtils(address newBoxUtils) public onlyAdmins {
        boxUtils = newBoxUtils;
    }

    function setMetaHandler(address newMetaHandler) public onlyAdmins {
        metaHandler = newMetaHandler;
    }

    function setAdminList(address _address, bool value) public {
        adminList[_address] = value;
    }

    function setSubAdminList(
        address _address,
        uint8 _role,
        bool value
    ) public onlyAdmins {
        subAdminList[_address][_role] = value;
    }

    function setSigner(address _address, bool _value) external onlyAdmins {
        signers[_address] = _value;
    }

    function setTokenFee(
        string memory _currencyId,
        address _tokenAddress,
        uint256 _feeRate
    ) public onlyAdminsAndSubAdmins(2) {
        tokensFee[_tokenAddress] = _feeRate;
        emit ServiceFeeEvent(_tokenAddress, _currencyId, _feeRate);
    }

    function addAcceptedToken(string memory _currencyId, address _tokenAddress)
        public
        onlyAdminsAndSubAdmins(1)
    {
        acceptedTokens[_tokenAddress] = true;
        emit PaymentTokenEvent(_tokenAddress, _currencyId);
    }

    function removeAcceptedToken(address _tokenAddress)
        public
        onlyAdminsAndSubAdmins(1)
    {
        acceptedTokens[_tokenAddress] = false;
    }

    function setAirdropHandler(address newAirdropHandler) public onlyAdmins {
        airdropHandler = newAirdropHandler;
    }

    function getNonce(bytes32 handler, address account)
        public
        view
        returns (uint256)
    {
        return _nonces[handler][account];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

interface INFTify1155 {
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTify721 {
    function mint(
        address account,
        uint256 id,
        bytes memory data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReentrancyGuarded.sol";

abstract contract Upgradeable is ReentrancyGuarded {
    address public trustedForwarder;
    address public recipient;
    address public signatureUtils;

    address public feeUtils;
    address public offerHandler;
    address public boxUtils;
    mapping(bytes => bool) public openedBoxSignatures;

    mapping(address => bool) adminList;
    mapping(address => bool) public acceptedTokens;
    mapping(uint256 => uint256) public soldQuantity;
    mapping(bytes => bool) invalidSaleOrder;
    mapping(bytes => bool) invalidOffers;
    mapping(bytes => bool) acceptedOffers;
    mapping(bytes => uint256) public soldQuantityBySaleOrder;

    mapping(address => uint256) public nonces;
    mapping(address => uint256) public tokensFee;
    address public metaHandler;

    mapping(bytes => mapping(address => uint256)) public claimedAmountPerUser;
    mapping(bytes32 => mapping(address => uint256)) _nonces;
    mapping(bytes => bool) public invalidAirdropEvent;
    address public airdropHandler;
    mapping(bytes => mapping(uint256 => uint256)) public claimedAmountPerNFT;
    address offerHandlerNativeAddress;
    address public buyHandler;
    address sellHandlerAddress;
    address erc721SellHandlerAddress;
    address public featureHandler;
    address public sellHandler;
    address erc721SellHandlerNativeAddress;

    mapping(string => mapping(string => bool)) storeFeatures;
    mapping(string => mapping(address => uint256)) royaltyFeeAmount;
    address public cancelHandler;
    mapping(string => mapping(address => uint256)) featurePrice;
    mapping(string => mapping(string => mapping(address => uint256))) featureStakedAmount;
    mapping(address => bool) signers;

    mapping(address => mapping(uint8 => bool)) subAdminList;

    function _delegatecall(address _impl) internal {
        require(_impl != address(0), "Impl address is 0");

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(
                sub(gas(), 10000),
                _impl,
                ptr,
                calldatasize(),
                0,
                0
            )
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            switch result
            case 0 {
                revert(ptr, size)
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ReentrancyGuarded {
    bool reentrancyLock = false;

    /* Prevent a contract function from being reentrant-called. */
    modifier reentrancyGuard() {
        if (reentrancyLock) {
            revert();
        }
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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