// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) protocol V1 for NFT. Wrapper - Checker
pragma solidity 0.8.11;

import "SafeERC20.sol";
import "IERC1155.sol";
import "IERC721.sol";
import "ERC165Checker.sol";


import "IWrapper.sol";
import "LibEnvelopTypes.sol";

contract WrapperChecker {
    using SafeERC20 for IERC20;
    using ERC165Checker for address;

    IWrapper public wrapper;
    uint256 constant public MAX_ROYALTY_PERCENT = 5000;
    uint256 constant public MAX_TIME_TO_UNWRAP = 365 days;
    uint256 constant public MAX_FEE_THRESHOLD_PERCENT = 1; //percent from project token totalSupply
    bytes4 public constant IID_IERC1155 = type(IERC1155).interfaceId;
    bytes4 public constant IID_IERC721 = type(IERC721).interfaceId; 
    //IERC165 internal checkingContract;

    constructor(address _wrapper) {
        require(_wrapper != address(0), "No zero");
        wrapper = IWrapper(_wrapper);
    }

    function getNativeCollateralBalance(
        address _wNFTAddress, 
        uint256 _wNFTTokenId 
    ) public view returns (uint256) 
    {
        (uint256 res, ) = wrapper.getCollateralBalanceAndIndex(
            _wNFTAddress, 
            _wNFTTokenId,
            ETypes.AssetType.NATIVE, 
            address(0), // tokenAddress 
            0           // tokenId
        );
        return res;
    }

    function getERC20CollateralBalance(
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        address _erc20
    ) public view returns (uint256, uint256) 
    {
        return wrapper.getCollateralBalanceAndIndex(
            _wNFTAddress, 
            _wNFTTokenId,
            ETypes.AssetType.ERC20, 
            _erc20,
            0
        );
    }

    function getERC1155CollateralBalance(
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        address _erc1155,
        uint256 _tokenId
    ) public view returns (uint256, uint256) 
    {
        return wrapper.getCollateralBalanceAndIndex(
            _wNFTAddress, 
            _wNFTTokenId,
            ETypes.AssetType.ERC1155, 
            _erc1155,
            _tokenId
        ); 
    }

    function checkWrap(
        ETypes.INData calldata _inData, 
        ETypes.AssetItem[] calldata _collateral, 
        address _wrappFor
    ) 
        public view returns (bool, string memory)
    {
        bool result = true;
        string memory messages = "";
        if (_inData.unWrapDestinition == address(0)) {
            result = false;
            messages="unWrapDestinition cant be zero, ";
            }

        if (_wrappFor == address(0)) {
            result = false; 
            messages= string(
                abi.encodePacked(
                    messages,
                    "WrapperFor cant be zero, "
                    )
                );
            }

        if (_inData.fees.length == 0&&_inData.royalties.length != 0){
            result = false; 
            messages= string(
                abi.encodePacked(
                    messages,
                    "Royalty source is transferFee, "
                    )
                ); 
            }

        if (_inData.outType == ETypes.AssetType.ERC1155&&_inData.outBalance == 0){
            result = false; 
            messages= string(
                abi.encodePacked(
                    messages,
                    "WNFT type is ERC1155 - wnft should have balance, "
                    )
                ); 
            }
        
        if (_inData.inAsset.asset.assetType == ETypes.AssetType.ERC1155&&_inData.inAsset.amount == 0){
            result = false; 
            messages= string(
                abi.encodePacked(
                    messages,
                    "Original NFT type is ERC1155 - original nft should have balance, "
                    )
                ); 
            }

        if (_inData.inAsset.asset.contractAddress == address(0)){
            result = false; 
            messages= string(
                abi.encodePacked(
                    messages,
                    "NFT contract address cant be zero, "
                    )
                ); 
            }

        if (_inData.locks.length != 0){
            uint256 j = 0;
            for (uint256 i = 0; i < _inData.locks.length; i ++) {
                if (_inData.locks[i].lockType == 0x00){
                    j++;
                }
            }
            if (j > 1) {
                result = false; 
                messages= string(
                    abi.encodePacked(
                        messages,
                        "Several time locks, "
                        )
                    );
                } 
            }

        if (_inData.locks.length != 0){
            for (uint256 i = 0; i < _inData.locks.length; i ++) {
                if (_inData.locks[i].lockType == 0x00&&_inData.locks[i].param>block.timestamp + MAX_TIME_TO_UNWRAP){
                    result = false; 
                    messages= string(
                        abi.encodePacked(
                            messages,
                            "Too long Wrap, "
                            )
                        );
                    }
                }
            }

        if (_inData.rules != 0x0002&& _inData.rules > 0x000F){
            result = false; 
                messages= string(
                    abi.encodePacked(
                        messages,
                        "Wrong rule code, "
                    )
                );
            }

        if (_inData.fees.length != 0){
            for (uint256 i = 0; i < _inData.fees.length; i ++) {
                if (_inData.fees[i].param!=0&&_inData.fees[i].token!=address(0)){
                    //there is transfer fee and settings are correct
                    for (uint256 j = 0; j < _inData.royalties.length; j ++) {
                        if (_inData.royalties[j].beneficiary == address(0)||_inData.royalties[j].percent==0){
                            //incorrect something in royalty settings
                            result = false; 
                            messages= string(
                                abi.encodePacked(
                                    messages,
                                    "Wrong royalty settings, "
                                )
                            );
                            break;
                        }
                        else {
                            if (_inData.royalties[j].percent > MAX_ROYALTY_PERCENT&&_inData.royalties[j].beneficiary!=address(wrapper)){
                                result = false; 
                                messages= string(
                                    abi.encodePacked(
                                        messages,
                                        "Royalty percent too big, "
                                    )
                                );
                                break;
                            }

                        }
                    }
                    if (_inData.fees[i].feeType == 0x00&&_inData.fees[i].token!=wrapper.protocolTechToken()){
                        for (uint256 j = 0; j < _inData.locks.length; j ++) {
                            if (_inData.locks[j].lockType == 0x01&&_inData.locks[j].param>IERC20(_inData.fees[i].token).totalSupply() * MAX_FEE_THRESHOLD_PERCENT / 100){
                                result = false; 
                                messages= string(
                                    abi.encodePacked(
                                        messages,
                                        "Too much threshold, "
                                        )
                                    );
                                break;
                                }
                            }
                        }

                }
                else {
                    result = false; 
                    messages= string(
                        abi.encodePacked(
                            messages,
                            "Wrong Fee settings, "
                            )
                        );
                    break;
                    }
                }
            }
        else {
            for (uint256 l = 0; l < _inData.locks.length; l ++) {
                if (_inData.locks[l].lockType == 0x01&&_inData.locks[l].param!=0){
                    result = false; 
                    messages= string(
                        abi.encodePacked(
                            messages,
                            "Cant set Threshold without transferFee, "
                            )
                        );
                    break;
                    }
                }
                
            }

         if (_inData.fees.length != 0){
            uint256 j=0;
            for (uint256 i = 0; i < _inData.fees.length; i ++) {
                if (_inData.fees[i].feeType==0x00){
                    j++;
                    }
                }
            if (j==0){
                for (uint256 l = 0; l < _inData.locks.length; l ++) {
                    if (_inData.locks[l].lockType == 0x01&&_inData.locks[l].param!=0){
                        result = false; 
                        messages= string(
                            abi.encodePacked(
                                messages,
                                "Cant set Threshold without transferFee, "
                                )
                            );
                        break;
                        }
                    }
                if (_inData.royalties.length != 0){
                    result = false; 
                    messages= string(
                        abi.encodePacked(
                            messages,
                            "Royalty source is transferFee, "
                            )
                        ); 
                    }

                }
            }   

        //analyze collateral array

        if (_collateral.length!=0){
            for (uint256 i = 0; i < _collateral.length; i ++) {
                if (_collateral[i].asset.assetType == ETypes.AssetType.ERC20&&(_collateral[i].asset.contractAddress==address(0)||_collateral[i].amount==0)){
                    result = false; 
                    messages= string(
                        abi.encodePacked(
                            messages,
                            "ERC20 collateral has incorrect settings, "
                            )
                        );
                    break;
                    }
                else if(_collateral[i].asset.assetType == ETypes.AssetType.ERC721&&_collateral[i].asset.contractAddress==address(0)){
                    result = false; 
                    messages= string(
                        abi.encodePacked(
                            messages,
                            "ERC721 collateral has incorrect settings, "
                            )
                        );
                    break;
                    }
                else if (_collateral[i].asset.assetType == ETypes.AssetType.ERC1155&&
                        (_collateral[i].asset.contractAddress==address(0)||_collateral[i].amount==0||_collateral[i].tokenId==0)){
                    result = false; 
                    messages= string(
                        abi.encodePacked(
                            messages,
                            "ERC1155 collateral has incorrect settings, "
                            )
                        );
                    break;
                    }
                if ((_collateral[i].asset.assetType == ETypes.AssetType.ERC721&&
                        _collateral[i].asset.contractAddress.supportsInterface(IID_IERC721)!=true)||
                    (_collateral[i].asset.assetType == ETypes.AssetType.ERC1155&&
                        _collateral[i].asset.contractAddress.supportsInterface(IID_IERC1155)!=true)){
                    result = false; 
                    messages= string(
                        abi.encodePacked(
                            messages,
                            "Collateral token is not ERC721 and not ERC1155, "
                            )
                        );
                    break;
                    }
                }
            }
        if ((_inData.inAsset.asset.assetType == ETypes.AssetType.ERC721&&
                _inData.inAsset.asset.contractAddress.supportsInterface(IID_IERC721)!=true)||
            (_inData.inAsset.asset.assetType == ETypes.AssetType.ERC1155&&
                _inData.inAsset.asset.contractAddress.supportsInterface(IID_IERC1155)!=true)){
            result = false; 
            messages= string(
                abi.encodePacked(
                    messages,
                    "Original token is not ERC721 and not ERC1155, "
                    )
                );
        }
        
        bytes memory messages_bytes =  bytes ( messages ); 
        if (messages_bytes.length == 0) {
            messages="Success";
        }

        return (result, messages);
    }

    function checkAddCollateral(
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        ETypes.AssetItem[] calldata _collateral
    ) public view returns (bool, string memory) 
    {
        bool result = true;
        string memory messages = "";
        //analize collateral array

        if (_collateral.length!=0){
            for (uint256 i = 0; i < _collateral.length; i ++) {
                if (_collateral[i].asset.assetType == ETypes.AssetType.ERC20&&(_collateral[i].asset.contractAddress==address(0)||_collateral[i].amount==0)){
                    result = false; 
                    messages= string(
                        abi.encodePacked(
                            messages,
                            "ERC20 collateral has incorrect settings, "
                            )
                        );
                    break;
                    }
                else if(_collateral[i].asset.assetType == ETypes.AssetType.ERC721&&_collateral[i].asset.contractAddress==address(0)){
                    result = false; 
                    messages= string(
                        abi.encodePacked(
                            messages,
                            "ERC721 collateral has incorrect settings, "
                            )
                        );
                    break;
                    }
                else if (_collateral[i].asset.assetType == ETypes.AssetType.ERC1155&&
                        (_collateral[i].asset.contractAddress==address(0)||_collateral[i].amount==0||_collateral[i].tokenId==0)){
                    result = false; 
                    messages= string(
                        abi.encodePacked(
                            messages,
                            "ERC1155 collateral has incorrect settings, "
                            )
                        );
                    break;
                    }
                if ((_collateral[i].asset.assetType == ETypes.AssetType.ERC721&&
                        _collateral[i].asset.contractAddress.supportsInterface(IID_IERC721)!=true)||
                    (_collateral[i].asset.assetType == ETypes.AssetType.ERC1155&&
                        _collateral[i].asset.contractAddress.supportsInterface(IID_IERC1155)!=true)){
                    result = false; 
                    messages= string(
                        abi.encodePacked(
                            messages,
                            "Collateral token is not ERC721 and not ERC1155, "
                            )
                        );
                    break;
                    }
                }
            }
        bytes memory messages_bytes =  bytes ( messages ); 
        if (messages_bytes.length == 0) {
            messages="Success";
            }

        return (result, messages);
    }

    function checkUnWrap(
        ETypes.AssetType _wNFTType, 
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        bool _isEmergency
    ) public view returns (bool) 
    {
        return true;
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

//import "IERC721Enumerable.sol";
import "LibEnvelopTypes.sol";

interface IWrapper  {

    event WrappedV1(
        address indexed inAssetAddress,
        address indexed outAssetAddress, 
        uint256 indexed inAssetTokenId, 
        uint256 outTokenId,
        address wnftFirstOwner,
        uint256 nativeCollateralAmount,
        bytes2  rules
    );

    event UnWrappedV1(
        address indexed wrappedAddress,
        address indexed originalAddress,
        uint256 indexed wrappedId, 
        uint256 originalTokenId, 
        address beneficiary, 
        uint256 nativeCollateralAmount,
        bytes2  rules 
    );

    event CollateralAdded(
        address indexed wrappedAddress,
        uint256 indexed wrappedId,
        uint8   assetType,
        address collateralAddress,
        uint256 collateralTokenId,
        uint256 collateralBalance
    );

    event PartialUnWrapp(
        address indexed wrappedAddress,
        uint256 indexed wrappedId,
        uint256 lastCollateralIndex
    );
    event SuspiciousFail(
        address indexed wrappedAddress,
        uint256 indexed wrappedId, 
        address indexed failedContractAddress
    );

    event EnvelopFee(
        address indexed receiver,
        address indexed wNFTConatract,
        uint256 indexed wNFTTokenId,
        uint256 amount
    );

    function wrap(
        ETypes.INData calldata _inData, 
        ETypes.AssetItem[] calldata _collateral, 
        address _wrappFor
    ) 
        external 
        payable 
    returns (ETypes.AssetItem memory);

    // function wrapUnsafe(
    //     ETypes.INData calldata _inData, 
    //     ETypes.AssetItem[] calldata _collateral, 
    //     address _wrappFor
    // ) 
    //     external 
    //     payable
    // returns (ETypes.AssetItem memory);

    function addCollateral(
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        ETypes.AssetItem[] calldata _collateral
    ) external payable;

    // function addCollateralUnsafe(
    //     address _wNFTAddress, 
    //     uint256 _wNFTTokenId, 
    //     ETypes.AssetItem[] calldata _collateral
    // ) 
    //     external 
    //     payable;

    function unWrap(
        ETypes.AssetType _wNFTType, 
        address _wNFTAddress, 
        uint256 _wNFTTokenId
    ) external; 

    function unWrap(
        ETypes.AssetType _wNFTType, 
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        bool _isEmergency
    ) external;

    function chargeFees(
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        address _from, 
        address _to,
        bytes1 _feeType
    ) 
        external  
        returns (bool);   

    ////////////////////////////////////////////////////////////////////// 
    
    function MAX_COLLATERAL_SLOTS() external view returns (uint256);
    function protocolTechToken() external view returns (address);
    function protocolWhiteList() external view returns (address);
    //function trustedOperators(address _operator) external view returns (bool); 
    //function lastWNFTId(ETypes.AssetType _assetType) external view returns (ETypes.NFTItem); 

    function getWrappedToken(address _wNFTAddress, uint256 _wNFTTokenId) 
        external 
        view 
        returns (ETypes.WNFT memory);

    function getOriginalURI(address _wNFTAddress, uint256 _wNFTTokenId) 
        external 
        view 
        returns(string memory); 
    
    function getCollateralBalanceAndIndex(
        address _wNFTAddress, 
        uint256 _wNFTTokenId,
        ETypes.AssetType _collateralType, 
        address _erc,
        uint256 _tokenId
    ) external view returns (uint256, uint256);
   
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) protocol V1 for NFT. 
pragma solidity 0.8.11;

library ETypes {

    enum AssetType {EMPTY, NATIVE, ERC20, ERC721, ERC1155, FUTURE1, FUTURE2, FUTURE3}
    
    struct Asset {
        AssetType assetType;
        address contractAddress;
    }

    struct AssetItem {
        Asset asset;
        uint256 tokenId;
        uint256 amount;
    }

    struct NFTItem {
        address contractAddress;
        uint256 tokenId;   
    }

    struct Fee {
        bytes1 feeType;
        uint256 param;
        address token; 
    }

    struct Lock {
        bytes1 lockType;
        uint256 param; 
    }

    struct Royalty {
        address beneficiary;
        uint16 percent;
    }

    struct WNFT {
        AssetItem inAsset;
        AssetItem[] collateral;
        address unWrapDestinition;
        Fee[] fees;
        Lock[] locks;
        Royalty[] royalties;
        bytes2 rules;

    }

    struct INData {
        AssetItem inAsset;
        address unWrapDestinition;
        Fee[] fees;
        Lock[] locks;
        Royalty[] royalties;
        AssetType outType;
        uint256 outBalance;      //0- for 721 and any amount for 1155
        bytes2 rules;

    }

    struct WhiteListItem {
        bool enabledForFee;
        bool enabledForCollateral;
        bool enabledRemoveFromCollateral;
        address transferFeeModel;
    }

    struct Rules {
        bytes2 onlythis;
        bytes2 disabled;
    }

}