// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title EthDepositLogic
 * @notice The main contract logic for deposit ether.
 */
contract EthDepositLogic {
    using SafeERC20 for IERC20;
    using Address for address payable;
    /**
     * @notice Cold Address to which any eth sent to this contract will be forwarded
     * @dev This is only set in EthDepositLogic (this) contract's storage.
     * It should be a cold wallet.
     */
    address payable public coldAddress;

    /**
     * @notice Minimum eth price for deposit
     * @dev This attribute is required for all future versions, as it is
     * accessed directly from EthDepositLogic contract
     */
    uint256 public minimumEthInput;

    /**
     * @notice Whether the contract is allowed to receive funds and
     * auto-forwarding to the cold wallet or not.
     * @dev This parameter is used to avoid users miss-sending the
     * fund on the blockchain that not allowed deposit.
     * Should be initialized in constructor.
     * false: allow Deposit
     * true: not allow Deposit,
     * it means transferring ETH to the contract will be forbidden;
     * Also, the transaction will be reverted and return the ETH back to the sender.
     */
    bool public isDisableDeposit;

    /**
     * @notice The address of the addition logic contract
     * @dev This is only set in EthDepositLogic (this) contract's storage.
     * Also, forwarding logic to this address via DELEGATECALL is disabled when
     * this contract is killed (coldAddress == address(0)).
     */
    address payable public implementation;

    /**
     * @dev This is only set in EthDepositLogic (this) contract's storage.
     * It has the ability to change the isDisableDeposit status, minInput amount,
     * and return back funds function
     * It's supposed to be a hot wallet.
     */
    address public operatorAddress;

    /**
     * @dev This is only set in EthDepositLogic (this) contract's storage.
     * It has the ability to kill the contract and disable addition logic forwarding,
     * and change the coldAddress, operatorAddress and implementation address storages.
     * It should be a cold wallet.
     */
    address public immutable adminAddress;

    /**
     * @dev The address of EthDepositLogic (use to check whether the context is delegate call or not)
     */
    address payable private immutable thisAddress;

    /**
     * @notice Create the contract, and sets the inital value of coldAddress,
     * adminAddress, operatorAddress, minimumEthInput, and thisAddress
     * @param coldAddr See coldAddress
     * @param adminAddr See adminAddress
     * @param operatorAddr See operatorAddress
     * @param miniEthInput See minimumEthInput
     * @param isDisableDepo See isDisableDeposit
     */
    constructor(
        address payable coldAddr,
        address adminAddr,
        address operatorAddr,
        uint256 miniEthInput,
        bool isDisableDepo
    ) {
        require(coldAddr != address(0), "0x0 is an invalid address");
        require(adminAddr != address(0), "0x0 is an invalid address");
        require(operatorAddr != address(0), "0x0 is an invalid address");
        coldAddress = coldAddr;
        adminAddress = adminAddr;
        operatorAddress = operatorAddr;
        minimumEthInput = miniEthInput;
        // set the EthDepositLogic contract address to immutable
        thisAddress = payable(address(this));
        isDisableDeposit = isDisableDepo;
    }

    /**
     * @notice Event used to log the proxy address and amount every time eth was forwarded
     * @param proxyReceiver The proxy address from which eth was forwarded
     * @param amount The amount of eth which was forwarded
     */
    event Deposit(address indexed proxyReceiver, uint256 amount);

    /**
     * @notice Event used to log the receiver address, operator address, and amount when the returnBackEth was called
     * @param toAddr The receiver address to return eth
     * @param operatorAddr The operator address which calls the function
     * @param fromAddr The address which returnback Eth
     * @param amount The amount of the eth which was returned
     */
    event ReturnBackEth(
        address indexed toAddr,
        address indexed operatorAddr,
        address indexed fromAddr,
        uint256 amount
    );

    /**
     * @notice Event used to log the receiver address, token address, operator address, and amount when the returnBackErc20 was called
     * @param toAddr The receiver address of the returned erc20 token
     * @param tokenAddr The token address of the erc20 token
     * @param operatorAddr The operator address which calls the function
     * @param fromAddr The address which returnback Erc21
     * @param amount The amount of the erc20 token which was returned
     */
    event ReturnBackErc20(
        address indexed toAddr,
        address indexed tokenAddr,
        address operatorAddr,
        address indexed fromAddr,
        uint256 amount
    );

    /**
     * @notice Event used to log the receiver address, token address, operator address, and tokenId when the returnBackErc721 was called
     * @param toAddr The receiver address of the returned erc721 token
     * @param tokenAddr The token address of the erc721 token
     * @param operatorAddr The operator address which calls the function
     * @param fromAddr The address which returnback Erc721
     * @param tokenId The tokenId of the erc721 token which was returned
     */
    event ReturnBackErc721(
        address indexed toAddr,
        address indexed tokenAddr,
        address operatorAddr,
        address indexed fromAddr,
        uint256 tokenId
    );

    /**
     * @notice Event used to log the receiver address, token address, operator address, and tokenId when the returnBackErc1155 was called
     * @param toAddr The receiver address of the returned erc1155 token
     * @param tokenAddr The token address of the erc1155 token
     * @param operatorAddr The operator address which calls the function
     * @param fromAddr The address which returnback erc1155
     * @param tokenId The tokenId of the erc1155 token which was returned
     * @param amount The amount of the erc1155 tokenId token which was returned
     */
    event ReturnBackErc1155(
        address indexed toAddr,
        address indexed tokenAddr,
        address operatorAddr,
        address indexed fromAddr,
        uint256 tokenId,
        uint256 amount
    );

    /**
     * @param newColdAddr The cold address after changed
     * @param oldColdAddr The cold address before changed
     */
    event ChangeColdAddress(
        address indexed newColdAddr,
        address indexed oldColdAddr
    );

    /**
     * @param newOperatorAddr The operator address after changed
     * @param oldOperatorAddr The operator address before changed
     */
    event ChangeOperatorAddress(
        address indexed newOperatorAddr,
        address indexed oldOperatorAddr
    );

    /**
     * @param operatorAddr The operator address
     * @param newMinimumEthInput The minimumEthInput after changed
     * @param oldMinimumEthInput The minimumEthInput before changed
     */
    event ChangeMinEthInput(
        address indexed operatorAddr,
        uint256 newMinimumEthInput,
        uint256 oldMinimumEthInput
    );

    /**
     * @param newImplAddr The implementation after changed
     * @param oldImplAddr The implementation before changed
     */
    event ChangeImplAddress(
        address indexed newImplAddr,
        address indexed oldImplAddr
    );

    /**
     * @dev This internal function checks if the current context is the main
     * EthDepositLogic contract or one of the proxies (delegatecall).
     * @return bool Whether this is EthDepositLogic or not
     */
    function isEthDepositLogic() internal view returns (bool) {
        return thisAddress == address(this);
    }

    /**
     * @dev Get an instance of EthDepositLogic for the main contract
     * @return EthDepositLogic instance (main contract of the system)
     */
    function getEthDepositLogic() internal view returns (EthDepositLogic) {
        // If this context is EthDepositLogic, use `this`, else use exDepositorAddr
        return isEthDepositLogic() ? this : EthDepositLogic(thisAddress);
    }

    /**
     * @dev Internal function for getting the implementation address.
     * This is needed because we don't know whether the current context is
     * the EthDepositLogic contract or a proxy contract.
     * @return implementation address of the EthDepositLogic
     */
    function getImplAddress() internal view returns (address payable) {
        return
            isEthDepositLogic()
                ? implementation
                : EthDepositLogic(thisAddress).implementation();
    }

    /**
     * @dev Internal function for getting the operation address.
     * This is needed because we don't know whether the current context is
     * the EthDepositLogic contract or a proxy contract.
     * @return operatorAddress of the EthDepositLogic
     */
    function getOperatorAddress() internal view returns (address) {
        // Use ethDepositLogic to perform logic for finding operation address
        EthDepositLogic ethDepositLogic = getEthDepositLogic();
        address operatorAddr = ethDepositLogic.operatorAddress();
        return operatorAddr;
    }

    /**
     * @dev Modifier that will execute internal code block only if the sender is the admin account
     */
    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Unauthorized admin");
        _;
    }

    /**
     * @dev Modifier that will execute internal code block only if the sender is the operator account
     */
    modifier onlyOperator() {
        address operatorAddr = getOperatorAddress();
        require(msg.sender == operatorAddr, "Unauthorized Operator");
        _;
    }

    /**
     * @dev Modifier that will execute internal code block only if not killed
     */
    modifier onlyAlive() {
        require(getEthDepositLogic().coldAddress() != address(0), "is killed");
        _;
    }

    /**
     * @notice check whether the contract be called directly or not
     * @dev Modifier that will execute internal code block only if called directly
     * (Not via delegatecall)
     */
    modifier onlyEthDepositLogic() {
        require(isEthDepositLogic(), "delegatecall is not allowed");
        _;
    }

    /**
     * @notice External function for returning Erc20 token to specific address
     * @dev Should be called by operator account
     * @param erc20Addr The address of the erc20 token contract
     * @param to The target address which received the erc20 token
     * @param amount The amount of the erc20 token to return
     */
    function returnBackErc20(
        IERC20 erc20Addr,
        address to,
        uint256 amount
    ) external onlyOperator {
        require(amount != 0, "0 is an invalid amount");
        require(to != address(0), "0x0 is an invalid address");
        uint256 erc20Balance = erc20Addr.balanceOf(address(this));
        require(erc20Balance >= amount, "amount is invalid");
        erc20Addr.safeTransfer(to, amount);
        emit ReturnBackErc20(
            to,
            address(erc20Addr),
            msg.sender,
            address(this),
            amount
        );
    }

    /**
     * @notice External function for returning ETH to specific address when the Eth is able to deposit
     * @dev It is also possible our addresses receive funds from another contract's selfdestruct.
     * @param to The target address to return Eth
     * @param amount The amount of Eth to return
     */
    function returnBackEth(address payable to, uint256 amount)
        external
        onlyOperator
    {
        require(amount != 0, "0 is an invalid amount");
        require(to != address(0), "0x0 is an invalid address");
        uint256 balance = address(this).balance;
        require(balance >= amount, "amount is invalid");
        (bool result, ) = to.call{value: amount}(""); // trasfer eth to specific address
        require(result, "Could not return back ETH");
        emit ReturnBackEth(to, msg.sender, address(this), amount);
    }

    /**
     * @notice External function for returning erc721 token to specific address
     * @dev Should be called by operator account,
     * use transferFrom to make sure it can be returned to all specific contract addresses
     * @param erc721Addr The address of the erc721 token contract
     * @param to The target address which received the erc721 token
     * @param tokenId The tokenId of the erc721 token to return
     */
    function returnBackErc721(
        IERC721 erc721Addr,
        address to,
        uint256 tokenId
    ) external onlyOperator {
        require(to != address(0), "0x0 is an invalid address");
        address owner = erc721Addr.ownerOf(tokenId);
        require(owner == address(this), "sender is not tokenId owner");
        erc721Addr.transferFrom(address(this), to, tokenId); // transfer Erc721 to specific address
        emit ReturnBackErc721(
            to,
            address(erc721Addr),
            msg.sender,
            address(this),
            tokenId
        );
    }

    /**
     * @notice External function for returning erc1155 token to specific address
     * @dev Should be called by operator account
     * @param erc1155Addr The address of the erc1155 token contract
     * @param to The target address which received the erc1155 token
     * @param tokenId The tokenId of the erc1155 token to return
     * @param amount The amount of the erc1155 tokenId token to return
     * @param data Additional data with no specified format that can use for own purpose
     */
    function returnBackErc1155(
        IERC1155 erc1155Addr,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external onlyOperator {
        require(to != address(0), "0x0 is an invalid address");
        uint256 erc1155Balance = erc1155Addr.balanceOf(address(this), tokenId);
        require(erc1155Balance >= amount, "amount is invalid");
        erc1155Addr.safeTransferFrom(address(this), to, tokenId, amount, data); // transfer Erc1155 to specific address
        emit ReturnBackErc1155(
            to,
            address(erc1155Addr),
            msg.sender,
            address(this),
            tokenId,
            amount
        );
    }

    /**
     * @notice External function for changing ColdAddress to newColdAddress
     * @param newColdAddress The new address for coldAddress
     */
    function changeColdAddress(address payable newColdAddress)
        external
        onlyEthDepositLogic
        onlyAlive
        onlyAdmin
    {
        require(newColdAddress != address(0), "0x0 is an invalid address");
        address payable oldColdAddress = coldAddress;
        coldAddress = newColdAddress;
        emit ChangeColdAddress(coldAddress, oldColdAddress);
    }

    /**
     * @notice External function for changing the operatorAddress
     * @param newOperatorAddress The new address for operatorAddress
     */
    function changeOperatorAddress(address newOperatorAddress)
        external
        onlyEthDepositLogic
        onlyAlive
        onlyAdmin
    {
        require(newOperatorAddress != address(0), "0x0 is an invalid address");
        address oldOperatorAddress = operatorAddress;
        operatorAddress = newOperatorAddress;
        emit ChangeOperatorAddress(operatorAddress, oldOperatorAddress);
    }

    /**
     * @notice External function for changing implementation to newAddress
     * @dev newImplAddress can be address(0) (to disable extra implementations)
     * @param newImplAddress The new address for implementation
     */
    function changeImplAddress(address payable newImplAddress)
        external
        onlyEthDepositLogic
        onlyAlive
        onlyAdmin
    {
        require(
            newImplAddress == address(0) || newImplAddress.isContract(),
            "implementation must be contract"
        );
        address payable oldImplAddress = implementation;
        implementation = newImplAddress;
        emit ChangeImplAddress(implementation, oldImplAddress);
    }

    /**
     * @notice External function for changing minimumEthInput to newMinInput.
     * @param newMinInput The new minimumEthInput
     */
    function changeMinEthInput(uint256 newMinInput)
        external
        onlyEthDepositLogic
        onlyAlive
        onlyOperator
    {
        uint256 oldMinEthInput = minimumEthInput;
        minimumEthInput = newMinInput;
        emit ChangeMinEthInput(msg.sender, minimumEthInput, oldMinEthInput);
    }

    /**
     * @notice External function for changing the status of isDisableDeposit switch
     * @param disableDeposit boolen
     */
    function isDisableDepositSwitch(bool disableDeposit)
        external
        onlyEthDepositLogic
        onlyAlive
        onlyAdmin
    {
        require(
            isDisableDeposit != disableDeposit,
            "nothing to change with isDisableDeposit"
        );
        isDisableDeposit = disableDeposit;
    }

    /**
     * @notice External function for killing the contract
     * @dev Setting cold address to 0, terminate the forwardingSwitch and changeXXX function.
     */
    function kill() external onlyEthDepositLogic onlyAlive onlyAdmin {
        coldAddress = payable(address(0));
    }

    /**
     * @notice forwarding Eth to cold address when there is no calldata
     * Forward any ETH value to the coldAddress
     * @dev This receive() type fallback means msg.data will be empty.
     * Disable deposits when killed.
     * Security note: Please check the Deposit event every time
     */
    receive() external payable {
        // Using a simplified version of onlyAlive
        // since we know that any call here has no calldata
        // this saves a large amount of gas due to the fact we know
        // that this can only be called from the EthDepositLogic context
        require(coldAddress != address(0), "Contract is killed");
        require(msg.value >= minimumEthInput, "Amount too small");
        require(isDisableDeposit == false, "Not able to Deposit");
        (bool success, ) = coldAddress.call{value: msg.value}("");
        require(success, "Forwarding funds failed");
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Forward calldata to supplemental implementation address.
     * @dev This fallback() type fallback will be called when there is some
     * call data, and this contract is alive.
     * It forwards to the implementation contract via DELEGATECALL.
     */
    fallback() external payable onlyAlive {
        address payable toAddr = getImplAddress();
        require(toAddr != address(0), "No fallback contract");
        (bool success, ) = toAddr.delegatecall(msg.data); // Forword the calldata the the implementation contract
        require(success, "Fallback contract execution failed");
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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