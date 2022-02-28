/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

// File: contracts/LampsPaymentSplitter.sol



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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library SafeERC20Upgradeable {
    using Address for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract PaymentSplitter {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address payable constant TREASURY = payable(0x0bA6585009c2E275CdE3Ede4Ab086d2c8b71b155);
    address payable constant UWULABS = payable(0x354A70969F0b4a4C994403051A81C2ca45db3615);
    address payable constant CM = payable(0xD80b6996C73BA77FF96FF2ADA982eBA1cb73d387);
    address payable constant CA = payable(0xFeB95163E713ADa2594Fe50CA0462a89db32cCa8);
    address payable constant MOD = payable(0xfd45CD3ACa3c21e1600f07eA60CAA96B2d6d3D05);
    address payable constant WEBDEV = payable(0x06046310B5483d4c185D9d87933D944405Ceb981);
    address payable constant WRITER = payable(0x118B91e2F362D5B3ecb7a6bebce08Ea617c659E9);
    address payable constant ARTIST = payable(0x8C0dd928691113D5C91D678aE7c7818F6a036E04);
    address payable constant NIKHIMA = payable(0xb304b3205862dF57e1718FFE0A1E7165c89c1482);

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
    }

    function percentOfTotal(uint256 total, uint256 percentInGwei) internal pure returns (uint256) {
        return (total * percentInGwei) / 1 gwei;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function withdrawETH() external {
        withdrawToken(address(0));
    }

    function withdrawToken(address token) public {
        if (token == address(0)) {
            uint256 totalBalance = address(this).balance;
            sendValue(TREASURY, percentOfTotal(totalBalance, 0.30 gwei)); // 1.5%/5% - 30% of royalties
            sendValue(UWULABS, percentOfTotal(totalBalance, 0.10 gwei)); // 0.5%/5% - 10% of royalties
            sendValue(CM, percentOfTotal(totalBalance, 0.03 gwei)); // 0.15%/5% - 3% of royalties
            sendValue(CA, percentOfTotal(totalBalance, 0.03 gwei)); // 0.15%/5% - 3% of royalties
            sendValue(MOD, percentOfTotal(totalBalance, 0.03 gwei)); // 0.15%/5% - 3% of royalties
            sendValue(WEBDEV, percentOfTotal(totalBalance, 0.03 gwei)); // 0.15%/5% - 3% of royalties
            sendValue(WRITER, percentOfTotal(totalBalance, 0.03 gwei)); // 0.15%/5% - 3% of royalties
            sendValue(ARTIST, percentOfTotal(totalBalance, 0.15 gwei)); // 0.75%/5% - 15% of royalties
            sendValue(NIKHIMA, address(this).balance); // 1.5%/5% - 30% of royalties
        } else {
            uint256 totalBalance = IERC20Upgradeable(token).balanceOf(address(this));
            IERC20Upgradeable(token).safeTransfer(TREASURY, percentOfTotal(totalBalance, 0.30 gwei)); // 1.5%/5% - 30% of royalties
            IERC20Upgradeable(token).safeTransfer(UWULABS, percentOfTotal(totalBalance, 0.10 gwei)); // 0.5%/5% - 10% of royalties
            IERC20Upgradeable(token).safeTransfer(CM, percentOfTotal(totalBalance, 0.03 gwei)); // 0.15%/5% - 3% of royalties
            IERC20Upgradeable(token).safeTransfer(CA, percentOfTotal(totalBalance, 0.03 gwei)); // 0.15%/5% - 3% of royalties
            IERC20Upgradeable(token).safeTransfer(MOD, percentOfTotal(totalBalance, 0.03 gwei)); // 0.15%/5% - 3% of royalties
            IERC20Upgradeable(token).safeTransfer(WEBDEV, percentOfTotal(totalBalance, 0.03 gwei)); // 0.15%/5% - 3% of royalties
            IERC20Upgradeable(token).safeTransfer(WRITER, percentOfTotal(totalBalance, 0.03 gwei)); // 0.15%/5% - 3% of royalties
            IERC20Upgradeable(token).safeTransfer(ARTIST, percentOfTotal(totalBalance, 0.15 gwei)); // 0.75%/5% - 15% of royalties
            IERC20Upgradeable(token).safeTransfer(NIKHIMA, IERC20Upgradeable(token).balanceOf(address(this))); // 1.5%/5% - 30% of royalties
        }
    }
}