// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ownership/Ownable.sol";
import "./interfaces/IMerchant.sol";
import "./libraries/Address.sol";

contract Merchant is IMerchant, Ownable {

    mapping(address => MerchantInfo) public merchantMap;

    event AddMerchant(address merchantAddress);

    constructor(){
        owner = msg.sender;
    }

    receive() payable external {}

    function isMerchant(address _merchant) external view returns(bool) {
        return _isMerchant(_merchant);
    }

    function _isMerchant(address _merchant) public view returns(bool) {
        return merchantMap[_merchant].account != address(0);
    }

    function addMerchant(address payable _settleAccount, address _settleCurrency, bool _autoSettle, bool _isFixedRate, address[] memory _tokens) external {

        if(address(0) != _settleCurrency) {
            require(Address.isContract(_settleCurrency));
        }

        if(_tokens.length > 0) {
            for(uint i = 0; i < _tokens.length; i++) {
                require(Address.isContract(_tokens[i]));
            }
        }

        merchantMap[msg.sender] = MerchantInfo (msg.sender, _settleAccount, _settleCurrency, _autoSettle, _isFixedRate, _tokens);

        emit AddMerchant(msg.sender);

    }

    function setMerchantToken(address[] memory _tokens) external {
        require(_isMerchant(msg.sender));
        for (uint i = 0; i < _tokens.length; i++) {
            require(Address.isContract(_tokens[i]));
        }
        merchantMap[msg.sender].tokens = _tokens;
    }

    function getMerchantTokens(address _merchant) external view returns(address[] memory) {
        return merchantMap[_merchant].tokens;
    }

    function setSettleCurrency(address payable _currency) external {
        require(_isMerchant(msg.sender));
        merchantMap[msg.sender].settleCurrency = _currency;
    }

    function getSettleCurrency(address _merchant) external view returns (address) {
        return merchantMap[_merchant].settleCurrency;
    }

    function setSettleAccount(address payable _account) external {
        require(_isMerchant(msg.sender));
        merchantMap[msg.sender].settleAccount = _account;
    }

    function getSettleAccount(address _account) external view returns(address) {
        return merchantMap[_account].settleAccount;
    }

    function setAutoSettle(bool _autoSettle) external {
        require(_isMerchant(msg.sender));
        merchantMap[msg.sender].autoSettle = _autoSettle;
    }

    function getAutoSettle(address _merchant) external view returns (bool){
        return merchantMap[_merchant].autoSettle;
    }

    function setFixedRate(bool _fixedRate) external{
        require(_isMerchant(msg.sender));
        merchantMap[msg.sender].isFixedRate = _fixedRate;
    }

    function getFixedRate(address _merchant) external view returns(bool) {
        return merchantMap[_merchant].isFixedRate;
    }

    function validatorCurrency(address _merchant, address _currency) public view returns (bool){
        return _validatorCurrency(_merchant, _currency);
    }

    function _validatorCurrency(address _merchant, address _currency) public view returns (bool){
        for(uint idx = 0; idx < merchantMap[_merchant].tokens.length; idx ++) {
            if (_currency == merchantMap[_merchant].tokens[idx]) {
                return true;
            }
        }
        return false;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMerchant {

    struct MerchantInfo {
        address account;
        address payable settleAccount;
        address settleCurrency;
        bool autoSettle;
        bool isFixedRate;
        address [] tokens;
    }

    function isMerchant(address _merchant) external view returns(bool);

    function addMerchant(address payable _settleAccount, address _settleCurrency, bool _autoSettle, bool _isFixedRate, address[] memory _tokens) external;

    function setMerchantToken(address[] memory _tokens) external;

    function getMerchantTokens(address _merchant) external view returns(address[] memory);

    function setSettleCurrency(address payable _currency) external;

    function getSettleCurrency(address _merchant) external view returns (address);

    function setSettleAccount(address payable _account) external;

    function getSettleAccount(address _account) external view returns(address);

    function setAutoSettle(bool _autoSettle) external;

    function getAutoSettle(address _merchant) external view returns (bool);

    function setFixedRate(bool _fixedRate) external;

    function getFixedRate(address _merchant) external view returns(bool);

    function validatorCurrency(address _merchant, address _currency) external view returns (bool);

}

// SPDX-License-Identifier: MIT
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev The contract has an owner address, and provides basic authorization control whitch
 * simplifies the implementation of user permissions. This contract is based on the source code at:
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
 */
contract Ownable {

    /**
     * @dev Error constants.
     */
    string public constant NOT_CURRENT_OWNER = "018001";
    string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "018002";

    /**
     * @dev Current owner address.
     */
    address public owner;

    /**
     * @dev An event which is triggered when the owner is changed.
     * @param previousOwner The address of the previous owner.
     * @param newOwner The address of the new owner.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The constructor sets the original `owner` of the contract to the sender account.
     */
    constructor(){
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner(){
        require(msg.sender == owner, NOT_CURRENT_OWNER);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

}