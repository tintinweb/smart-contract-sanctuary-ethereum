// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
pragma solidity 0.8.13;

library BasisPoints {
    function check(uint16 basisPoint) internal pure returns (bool) {
        return (basisPoint > 0 && basisPoint <= 10000);
    }

    function calculeAmount(uint16 basisPoint, uint256 amount)
        internal
        pure
        returns (uint256)
    {
        return ((amount * basisPoint) / 10000);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

library Sender {
    event SentMoney(address target, uint256 amount);
    event TransferFailed(address target, uint256 amount);

    function sendBalancePercentage(
        address targetAddress,
        uint16 basisPoint,
        uint256 amount
    ) internal returns (bool){
        uint256 amountToTransfer = (amount * basisPoint) / 10000;
        (bool success,) = payable(targetAddress).call{value: amountToTransfer}("");
        if(!success){
            emit TransferFailed(targetAddress, amountToTransfer);
        } else {
            emit SentMoney(targetAddress, amountToTransfer);
        }
        return success;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./libraries/BasisPoints.sol";
import {Sender} from "./libraries/Sender.sol";
import {BasisPoints} from "./libraries/BasisPoints.sol";

/// @author Polemix team
/// @title A royalties contract
contract RoyaltySender is Ownable, Pausable {
    /**
     * @dev I'm storing basisPoint because fixedPoint is not supported yet.
     * 100 basisPoint = 1%
     *  */
    struct RoyaltyUser {
        address userAddress;
        uint16 basisPoint;
    }

    uint8 private immutable pmixSellPosition;
    uint8 private immutable pmixReSellPosition;
    uint8 private immutable ownerReSellPosition;

    bool private distribute = false;

    RoyaltyUser[] private firstSell;
    RoyaltyUser[] private reSell;

    /**
     * @dev Represents the accumulated amount before the best responses addresses are set in the contract
     *      This variable is used to accumulate amount to distribute when executeRoyalties method is executed
     */
    uint256 private sellAmount;

    /**
     * @notice Represents the quantity of addresses that are going to receive royalties in the primary sale.
     */
    uint8 private firstSellQuantity;

    /**
     * @notice Emited when a royalty is sent
     * @param userAddress destination address
     * @param amount sent amount
     */
    event SentRoyalty(address userAddress, uint256 amount);

    /**
     * @notice Emited when funds are incoming
     * @param amount deposited amount
     */
    event Deposit(uint256 amount);

    /**
     * @notice Emited when contract owner withdraw funds
     * @param withdrawAddress address to send the funds
     * @param amount amount to withdraw
     */
    event WithdrawEvent(
        address indexed withdrawAddress,
        uint256 amount
    );

    /**
    * @notice AddressIsContract event is fired when an address of best responses array is a contract
    */
    event AddressIsContract(address userAddress);

    /**
     * @param firstSellQuantity_ quantity of addresses to give royalties
     * @param pmixAddress polemix address
     * @param pmixSellBasisPoints polemix basis points in the first sale
     * @param pmixReSellBasisPoints polemix basis points in the resale
     * @param ownerAddress owner address
     * @param ownerReSellBasisPoints owner basis points in the resale
     */
    constructor(
        uint8 firstSellQuantity_,
        address pmixAddress,
        uint16 pmixSellBasisPoints,
        uint16 pmixReSellBasisPoints,
        address ownerAddress,
        uint16 ownerReSellBasisPoints
    )
        checkBasisPoint(pmixSellBasisPoints)
        checkBasisPoint(pmixReSellBasisPoints)
        checkBasisPoint(ownerReSellBasisPoints)
        Pausable()
    {
        require(firstSellQuantity_ > 0, "First sell quantity must be > 0");

        firstSellQuantity = firstSellQuantity_;

        firstSell.push(RoyaltyUser(pmixAddress, pmixSellBasisPoints));
        pmixSellPosition = uint8(firstSell.length - 1);

        reSell.push(RoyaltyUser(pmixAddress, pmixReSellBasisPoints));
        pmixReSellPosition = uint8(reSell.length - 1);

        reSell.push(RoyaltyUser(ownerAddress, ownerReSellBasisPoints));
        ownerReSellPosition = uint8(reSell.length - 1);
    }

    /**
     * @notice receive: function that is called when nft is bought in an external marketplace
     * If the contract is paused then this function is disabled
     */
    receive() external payable whenNotPaused {
        emit Deposit(msg.value);
        sendRoyalties(reSell, msg.value);
    }

    /**
     * @notice checkBasisPoint: Modifier used to check basis point boundaries. Basis points should be between 1 and 10000
     */
    modifier checkBasisPoint(uint16 basisPoint) {
        require(
            BasisPoints.check(basisPoint),
            "Basis point beetween 1 and 10000"
        );
        _;
    }

    /**
     * @notice Adds the given addresses to the firstSell array and executes the royalties for all the addresses that must receive royalties.
     * @dev This function is executed only one time by the contract owner and sets royalties in distribute mode.
     *      If it has accumulated funds then it sends royalties to the right addresses
     *      FirstSell addresses which are from an smart contract will not receive royalties
     * @param firstSell_ contains the information used in the first sale
     */
    function executeRoyalties(RoyaltyUser[] memory firstSell_)
        external
        onlyOwner
    {
        require(!distribute, "Method already executed");
        require(
            (firstSell_.length + firstSell.length) <= firstSellQuantity,
            "First sell quantity are invalid"
        );

        for (uint256 i = 0; i < firstSell_.length; i++) {
            if(!Address.isContract(firstSell_[i].userAddress)) { 
                firstSell.push(firstSell_[i]);
            } else {
                emit AddressIsContract(firstSell_[i].userAddress);
            }
        }

        distribute = true;

        if (sellAmount > 0) {
            sendRoyalties(firstSell, sellAmount);
        }
    }

    /**
     * @notice receiveRoyalties
     * It is used to receive eth from mint transactions
     * Variable sellAmount accumulated amount that will be used when contract owner executes royalties
     * Contract owner is able to disable this function pausing the contract
     */
    function receiveRoyalties() external payable whenNotPaused {
        emit Deposit(msg.value);
        if (distribute) {
            sendRoyalties(firstSell, msg.value);
        } else {
            sellAmount = sellAmount + msg.value;
        }
    }

    /**
     * editPmixRoyalties
     * @param pmixAddress contains the wallet address used by polemix to get royalties
     * @param firstSellBasisPoint basis point for calculating the first sale
     * @param reSellBasisPoint basis point for calculating the resales
     */
    function editPmixRoyalties(
        address pmixAddress,
        uint16 firstSellBasisPoint,
        uint16 reSellBasisPoint
    )
        external
        checkBasisPoint(firstSellBasisPoint)
        checkBasisPoint(reSellBasisPoint)
        onlyOwner
    {
        firstSell[pmixSellPosition] = RoyaltyUser(
            pmixAddress,
            firstSellBasisPoint
        );
        reSell[pmixReSellPosition] = RoyaltyUser(pmixAddress, reSellBasisPoint);
    }

    /**
     * @notice editOwnerRoyalties
     * @param ownerAddress contains the wallet address used by owner to get royalties
     * @param reSellBasisPoint basis point for calculating the resales
     */
    function editOwnerRoyalties(address ownerAddress, uint16 reSellBasisPoint)
        external
        checkBasisPoint(reSellBasisPoint)
        onlyOwner
    {
        reSell[ownerReSellPosition] = RoyaltyUser(
            ownerAddress,
            reSellBasisPoint
        );
    }

    /**
     * @notice Returns the contract balance
     * @return Returns the contract balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Returns data about polemix royalties
     * @return address polemix address
     * @return saleBasisPoint basis point used in the first sale
     * @return reSaleBasisPoint basis point used in in the secondary sales
     */
    function getPmixRoyalties()
        external
        view
        returns (
            address,
            uint16,
            uint16
        )
    {
        return (
            firstSell[pmixSellPosition].userAddress,
            firstSell[pmixSellPosition].basisPoint,
            reSell[pmixReSellPosition].basisPoint
        );
    }

    /**
     * @notice Returns data about owner royalties
     * @return tuple(address pmixAddress, uint16 reSaleBasisPoint)
     */
    function getOwnerRoyalties() external view returns (address, uint16) {
        return (
            reSell[ownerReSellPosition].userAddress,
            reSell[ownerReSellPosition].basisPoint
        );
    }

    /**
     * @notice getRoyalties returns data related to the royalties
     * @return firstSell_ royalty data associated with the first sale
     * @return reSell_ roayalty data associated with secondary sales in external marketplaces
     */
    function getRoyalties()
        external
        view
        onlyOwner
        returns (RoyaltyUser[] memory firstSell_, RoyaltyUser[] memory reSell_)
    {
        return (firstSell, reSell);
    }

    /**
     * @notice Pause or resume contract state
     * The contract owner is the unique address able to pause/unpause the contract. This is an emergency stop mechanism.
     * @param pauseState. If it is true, contract is paused, otherwise is unpause
     */
    function pauseContract(bool pauseState) external onlyOwner {
        if (pauseState) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @notice send all the royalties. This function iterates all the addresses that must receive royalties and send the amount according to their basis points.
     */
    function sendRoyalties(RoyaltyUser[] memory sell, uint256 amount) private {
        for (uint256 i = 0; i < sell.length; i++) {
            Sender.sendBalancePercentage(
                sell[i].userAddress,
                sell[i].basisPoint,
                amount
            );
        }
    }

    /**
     * @notice Withdraw function. This function is used to extract remaining value from the contract.
     * @param withdrawAddress destination address to send the funds
     */
     function withdrawBalance(address payable withdrawAddress) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(withdrawAddress).transfer(balance);
        emit WithdrawEvent(withdrawAddress, balance);
     }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./RoyaltySender.sol";

contract RoyaltySenderProxy is Ownable, Pausable {

    address payable private implementationAddress;

    //Contract events

    /**
     * @notice ReceiveEvent event fired when "receive" function is executed
     * @param senderAddress contains the address of sender
     * @param amount contains the amount received by the contract
    */
    event ReceiveEvent(
        address indexed senderAddress,
        uint256 amount
    );

    /**
     * @notice ReceiveRoyaltiesEvent event fired when "receiveRoyalties" function is executed
     * @param senderAddress contains the address of sender
     * @param amount contains the amount received by the contract
    */
    event ReceiveRoyaltiesEvent(
        address indexed senderAddress,
        uint256 amount
    );

    /**
     * @notice ImplementationUpdatedEvent event fired when implementation is changed
     * @param newImplAddress contains the address of new implementation
    */
    event ImplementationUpdatedEvent(
        address indexed newImplAddress
    );

    /**
     * @notice WithdrawEvent event fired when withdraw is executed
     * @param withdrawAddress contains the address to do withdraw
     * @param amount contains the amount withdrawed
    */
    event WithdrawEvent(
        address indexed withdrawAddress,
        uint256 amount
    );

    /**
     * @notice RoyaltySenderProxy constructor
     * @param newImplAddress contains implementation address
    */
    constructor(address payable newImplAddress)  {
        implementationAddress = newImplAddress;
    }

    /**
     * @notice updateImplementation function to update proxy implementation address
     * @param newImplAddress contais the new implementation address
     */
    function updateImplementation(address payable newImplAddress) external onlyOwner {
        implementationAddress = newImplAddress;
        emit ImplementationUpdatedEvent(newImplAddress);
    }

    /**
     * @notice getImplementation function to get implementation contract address
     * @return payable address implementation
     */
    function getImplementation() external view onlyOwner returns(address payable){
        return implementationAddress;
    }

    /**
     * @notice receiveRoyalties function to receive royalties from erc721 polemix contracts
     */
    function receiveRoyalties() external payable whenNotPaused {
        RoyaltySender(implementationAddress).receiveRoyalties{
            value: msg.value
        }();
        emit ReceiveRoyaltiesEvent(msg.sender, msg.value);
    }

    /**
     * @notice receive function to receive royalties from secondary sales
     */
    receive() external payable whenNotPaused {
        (bool success,) =  implementationAddress.call{value:msg.value}(""); 
        require(success, "receive call fails");
        emit ReceiveEvent(msg.sender, msg.value);
    }

    /**
     * @notice pauseContract function to pause or unpause contract's functions. Only contract owner can use this function to pause/unpause this contract. This is an emergency stop mechanism.
     * @param pauseState contains a bool with the state of pause. True for pause, false for unpause
    */
    function pauseContract(bool pauseState) external onlyOwner {
        if (pauseState) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @notice Withdraw function
     * @param withdrawAddress to do balance withdraw
     */
     function withdrawBalance(address payable withdrawAddress) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success,) = payable(withdrawAddress).call{value: balance}("");
        require(success, "Transfer failed.");
        emit WithdrawEvent(withdrawAddress, balance);
     }

     /**
     * @notice getBalance function to return contract balance
     * @return uint256 contract balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}