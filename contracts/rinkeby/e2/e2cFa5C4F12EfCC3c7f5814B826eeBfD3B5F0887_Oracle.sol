// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Escrow.sol";

contract Oracle is Ownable{
    function validate(address _escrow,uint _uid, bool _validationStatus,uint _fee) public onlyOwner{
        Escrow escrow = Escrow(_escrow);
        escrow.validateContract(_uid, _validationStatus, _fee);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
@title Escrow
@author Core Devs Ltd
@notice An escrow smart contract
*/
contract Escrow is Ownable{
    
    address public oracle; //Oracle address
    uint public disputFee; //Fixed addtional fee for disput
    address[] public admins; //Admin list

    /**
    @dev Oracle smart contract must be deployed first before deploying this
    @param _oracle Oracle smart contract address
    @param _disputFee Fixed addtional fee for disput
    */
    constructor(address _oracle,uint _disputFee){
        oracle = _oracle;
        disputFee = _disputFee;
    }
    

    /**   
    @notice Escrow status/stages.
    */
    enum Stage {initiated,accepted,productSent,productReceived,completed,denied,onDispute}


    /**   
    @notice Contract/agreement detail.
    */
    struct Agreement{
        bool validated; //validation status
        uint amount; // Product price
        uint fee; //Marketplace fee
        uint lastTime;  // Last delivery time
        address payable seller; // Person selling
        address payable buyer;   // Person buying
        address currency; //buying currency
        Stage stage; //current stage of agreement
    }

    mapping(uint => Agreement) public agreements;
    

    /**   
    @notice Events.
    */

    /**   
    @notice Emitted on initiating a new contract.
    @dev Passes UID and the Agreement/contract body
    */
    event Initiate (uint, Agreement);

    /**   
    @notice Emitted when status changes on contract.
    @dev Passes UID and the Agreement/contract body
    */
    event StatusChange (uint, Agreement);

    /**   
    @notice Emitted when contract gets completed.
    @dev Passes UID and the Agreement/contract body
    */
    event Complete (uint, Agreement);

    /**   
    @notice Emitted if someone raise a dispute.
    @dev Passes UID and the Agreement/contract body
    */
    event Dispute (uint, Agreement);

    /**   
    @notice Emitted when contract get deleted.
    @dev Passes UID
    */
    event Delete (uint);


    /// Modifiers.

    /**   
    @notice limits execution to buyers only.
    @param _uid Predefined unique identifier
    */
    modifier onlyBuyer(uint _uid) {
        require(msg.sender == agreements[_uid].buyer , "You must be the buyer to execute this function");
        _;
    }

    /**   
    @notice limits execution to seller only.
    @param _uid Predefined unique identifier
    */
    modifier onlySeller(uint _uid) {
        require(msg.sender == agreements[_uid].seller , "You must be the seller to execute this function");
        _;
    }

    /**   
    @notice limits execution to admins only.
    @param _user wallet address 
    */
    modifier onlyAdmin(address _user) {
        if(!(checkifAdmin(_user))){
            revert("You must be the admin to execute this function");
        }
        _;
    }

    /**   
    @notice limits execution to oracly smart contract only.
    */
    modifier onlyOracle() {
        require(msg.sender == oracle, "Only Oracle can execute this function");
        _;
    }

    /**   
    @notice limits execution to validated contracts/agreements only.
    @param _uid Predefined unique identifier 
    */
    modifier onlyValidated(uint _uid) {
        require(agreements[_uid].validated==true, "Agreement has to be validated to execute this function");
        _;
    }


    /**   
    @notice Funtions/Methods
    */

    /**  
    @notice Function to create a contract/agreement.
    @param _uid Predefined unique identifier for contract/agreement.
    @param _amount Transaction amount/product price
    @param _buyer Wallet addtess of buyer
    @param _seller Wallet addtess of seller
    @param _currency token address of selected currency. 
        use 0x00000000000000000000000000000000000000 for native.
    @custom:events this emits "Initiate" event
    */
    function createContract(uint _uid,uint _amount, address payable _buyer, address payable _seller, address _currency) public payable{
        require (_seller != _buyer, "seller and buyer can not be the same");
        require(_amount>0);
        require(agreements[_uid].amount==0);
        if (_currency==address(0x0000000000000000000000000000000000000000)){
            require (_amount>0, "Tx amount will have to be more than 0");
            require (msg.value == _amount, "Invalid Amount");
        }else{
            IERC20 currency = IERC20(_currency);
            currency.transferFrom(msg.sender, address(this), _amount);
        }

        agreements[_uid].validated = false;
        agreements[_uid].amount = _amount;
        agreements[_uid].seller = _seller;
        agreements[_uid].buyer = _buyer;
        agreements[_uid].currency = _currency;
        emit Initiate(_uid, agreements[_uid]);
    }

    /**  
    @notice Contract/agreement validator. Can only be used by the oracle.
    @param _uid Predefined unique identifier for contract/agreement.
    @param _validationStatus True or False. Sent by oracle after validation.
    @param _fee precalculated fee amount of the trade. Sent by oracle after validation.
    @custom:events this emits "StatusChange" event on success.
    @custom:events this emits "Delete" event if validation fails.
    */
    function validateContract(uint _uid, bool _validationStatus, uint _fee)public onlyOracle{
        if(!_validationStatus){
            delete agreements[_uid];
            emit Delete(_uid);
        }else{
            agreements[_uid].validated = _validationStatus;
            agreements[_uid].fee = _fee;
            agreements[_uid].lastTime = block.timestamp+ 1 days;
            agreements[_uid].stage = Stage.initiated;
            emit StatusChange(_uid, agreements[_uid]);
        }
    }

    /**  
    @notice Funtion for the seller to accept the contract/agreemnt from buyer.
    @param _uid Predefined unique identifier for contract/agreement.
    @custom:events this emits "StatusChange" event.
    */
    function acceptContract(uint _uid) public onlySeller(_uid) onlyValidated(_uid){
        require(agreements[_uid].stage==Stage.initiated );
        agreements[_uid].stage = Stage.accepted;
        agreements[_uid].lastTime = block.timestamp+ 1 days;
        emit StatusChange(_uid, agreements[_uid]);
    }

    /**  
    @notice Funtion for the seller to deny the contract/agreemnt from buyer.
    @param _uid Predefined unique identifier for contract/agreement.
    @custom:events this emits "StatusChange" event.
    */
    function denyContract(uint _uid) public onlySeller(_uid) onlyValidated(_uid){
        require(agreements[_uid].stage==Stage.initiated );
        agreements[_uid].stage = Stage.denied;
        emit StatusChange(_uid, agreements[_uid]);
    }
   
    /**  
    @notice Function to claim money back if agreement is denied or expirs before seller accepts it.
    @param _uid Predefined unique identifier for contract/agreement.
    @custom:events this emits "Delete" event.
    */
    function claim(uint _uid) public onlyBuyer(_uid) onlyValidated(_uid){
        //Checks if the contract/agreement is denied or expired in initiated stage.
        require(agreements[_uid].stage==Stage.denied || (agreements[_uid].stage==Stage.initiated && block.timestamp>agreements[_uid].lastTime));
        agreements[_uid].validated=false;
        if (agreements[_uid].currency==address(0x0000000000000000000000000000000000000000)){
            agreements[_uid].buyer.transfer(agreements[_uid].amount);
        }else{
            IERC20 currency = IERC20(agreements[_uid].currency);
            currency.transfer(msg.sender, agreements[_uid].amount);
        }
        delete agreements[_uid];
        emit Delete(_uid);
    }
    
    /**  
    @notice Function to change the contract/agreement status to "productSent"  after sending the product.
    @param _uid Predefined unique identifier for contract/agreement.
    @custom:events this emits "StatusChange" event.
    */
    function markProductSent(uint _uid) public {
        require((msg.sender == agreements[_uid].seller || checkifAdmin(msg.sender)==true), "You must be the seller or admin to execute this function");
        require(agreements[_uid].stage==Stage.accepted);
        agreements[_uid].stage = Stage.productSent;
        agreements[_uid].lastTime = block.timestamp+ 1 days;
        emit StatusChange(_uid, agreements[_uid]);
    }

    /**  
    @notice Function to confirm that the buyer received the product in acceptable condition.
    @param _uid Predefined unique identifier for contract/agreement.
    @custom:events this emits "StatusChange" event.
    */
    function markProductreceived(uint _uid) public {
        require((msg.sender == agreements[_uid].buyer || checkifAdmin(msg.sender)==true), "You must be the buyer or admin to execute this function");
        require(agreements[_uid].stage==Stage.productSent);
        agreements[_uid].stage = Stage.productReceived;
        agreements[_uid].lastTime = block.timestamp+ 1 days;
        emit StatusChange(_uid, agreements[_uid]);
    }

    /**  
    @notice Function to finish a successfull contract/agreement. It will also release the money to seller.
    @param _uid Predefined unique identifier for contract/agreement.
    @custom:route This will coduct calling resolveContract function.
    @custom:events this emits "Complete" event.
    */
    function markContractCompleted(uint _uid) public onlySeller(_uid) {
        require(agreements[_uid].stage==Stage.productReceived);
        resolveContract(_uid, agreements[_uid].seller);
        emit Complete(_uid, agreements[_uid]);
    }

    /**  
    @notice Function to raise disput on certain situations (id conditions are met).
        the conditions are: 1 - The minimum time (last time) has to be more than time now.
                            2 - Stage has to be accepted or productSent
    @param _uid Predefined unique identifier for contract/agreement.
    @custom:events this emits "Dispute" event.
    */
    function reaiseDispute(uint _uid) public {
        //time now has to be more than the minimum time.
        require(block.timestamp>agreements[_uid].lastTime);
        //Status has to be either accepted or productSent.
        require(agreements[_uid].stage==Stage.accepted || agreements[_uid].stage==Stage.productSent);
        agreements[_uid].stage = Stage.onDispute;
        agreements[_uid].fee = agreements[_uid].fee+disputFee;
        emit Dispute(_uid, agreements[_uid]);
    }

    /**  
    @notice function for the admin to award the disput to either buyer or seller.
    @param _uid Predefined unique identifier for contract/agreement.
    @param _winner Wallet address of winner.
    @custom:route This will coduct calling resolveContract function.
    */
    function awardDispute(uint _uid, address payable _winner) public onlyAdmin(msg.sender) {
        require(agreements[_uid].stage==Stage.onDispute);
        require(agreements[_uid].buyer==_winner || agreements[_uid].seller==_winner);
        resolveContract(_uid, _winner);
    }

    /**  
    @notice Function used internally to change the contract/agreement stage to complete and distributing the money.
    @param _uid Predefined unique identifier for contract/agreement.
    @param _wallet wallet address to set destination for money
    @custom:events this emits "Complete" event.
    */
    function resolveContract(uint _uid, address payable _wallet) private{
        agreements[_uid].stage = Stage.completed;
        address payable owner = payable(owner());
        uint fee = agreements[_uid].fee;
        if (agreements[_uid].currency==address(0x0000000000000000000000000000000000000000)){
            _wallet.transfer(agreements[_uid].amount-fee);
            owner.transfer(fee);
        }else{
            IERC20 currency = IERC20(agreements[_uid].currency);
            currency.transfer(_wallet, (agreements[_uid].amount-fee));
            currency.transfer(owner, (fee));
        }
        emit Complete(_uid, agreements[_uid]);
    }

    /**  
    @notice Function to add a new admin.
    @param _admin wallet address of admin
    */
    function addAdmin(address _admin) public onlyOwner{
        admins.push(_admin);
    }

    /**  
    @notice Function to rmeove an admin.
    @param _admin wallet address of admin
    */
    function removeAdmin(address _admin) public onlyOwner{
        for (uint256 index = 0; index < admins.length; index++) {
            if(admins[index]==_admin){
                delete admins[index];
                break;
            }
            
        }
    }

    /**  
    @notice Function to check if the user admin.
    @param _user wallet address of the user
    @return Boolean
    */
    function checkifAdmin(address _user) public view returns(bool){
        for (uint256 index = 0; index < admins.length; index++) {
            if(admins[index]==_user){
                return true;
            }
        }
        return false;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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