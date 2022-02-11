/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Burnable {
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
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external;

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


/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/**
 * @dev Collection of functions related to the address type
 */
library Address {

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
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


contract Wallet is Ownable {

    event Deposit(uint256 indexed depositId, address indexed sender, uint256 amount);
    event Request(uint256 indexed withdrawalId, address indexed recipient, uint256 amount);
    event Processed(uint256 indexed withdrawalId, address indexed recipient, uint256 amount);
    event Withdrawal(uint256 indexed withdrawalId, address indexed recipient, uint256 amount);
    event ProcessorAdded(address indexed newProcessor);
    event ProcessorRemoved(address indexed oldProcessor);
    event ManagerAdded(address indexed newManager);
    event ManagerRemoved(address indexed oldManager);

    IERC20Burnable public token;
    uint256 public depositCount;
    uint256 public withdrawalCount;
    mapping(address => bool) public processors;
    mapping(address => bool) public managers;
    mapping(uint256 => uint256) private deposits;
    mapping(uint256 => address) private depositSenders;
    mapping(uint256 => uint256) private depositAmounts;
    mapping(uint256 => uint256) private withdrawals;
    mapping(uint256 => address) private withdrawalRecipients;
    mapping(uint256 => uint256) private withdrawalAmounts;
    mapping(uint256 => uint256) private withdrawalStatuses;

    constructor(address __token) {
        require(Address.isContract(__token), "Error: Address should be a contract");
        token = IERC20Burnable(__token);

        depositCount = 0;
        withdrawalCount = 0;
    }

    function addProcessor(address __newProcessor) external onlyOwner {
        require(__newProcessor != address(0), "Processor: new processor is the zero address");
        processors[__newProcessor] = true;
        emit ProcessorAdded(__newProcessor);
    }

    function removeProcessor(address __oldProcessor) external onlyOwner {
        require(__oldProcessor != address(0), "Processor: old processor is the zero address");
        processors[__oldProcessor] = false;
        emit ProcessorRemoved(__oldProcessor);
    }

    modifier onlyProcessor() {
        require(processors[_msgSender()], "Processor: caller is not the processor");
        _;
    }

    function addManager(address __newManager) external onlyOwner {
        require(__newManager != address(0), "Manager: new manager is the zero address");
        managers[__newManager] = true;
        emit ManagerAdded(__newManager);
    }

    function removeManager(address __oldManager) external onlyOwner {
        require(__oldManager != address(0), "Manager: old manager is the zero address");
        managers[__oldManager] = false;
        emit ManagerRemoved(__oldManager);
    }

    modifier onlyManager() {
        require(managers[_msgSender()], "Manager: caller is not the manager");
        _;
    }

    function deposit(uint256 __depositId, uint256 __amount) external {
        token.transferFrom(_msgSender(), address(this), __amount);

        deposits[depositCount] = __depositId;
        depositSenders[__depositId] = _msgSender();
        depositAmounts[__depositId] = __amount;

        depositCount++;
        emit Deposit(__depositId, _msgSender(), __amount);
    }

    function request(uint256 __withdrawalId, address __recipient, uint256 __amount) external {
        require(withdrawalStatuses[__withdrawalId] == 0, "Request: withdrawal request already processed");

        withdrawals[withdrawalCount] = __withdrawalId;
        withdrawalRecipients[__withdrawalId] = __recipient;
        withdrawalAmounts[__withdrawalId] = __amount;
        withdrawalStatuses[__withdrawalId] = 0;

        withdrawalCount++;
        emit Request(__withdrawalId, __recipient, __amount);
    }

    function process(uint256 __withdrawalId, address __recipient, uint256 __amount) external onlyProcessor {
        require(withdrawalStatuses[__withdrawalId] == 0, "Request: withdrawal request already processed");

        withdrawalRecipients[__withdrawalId] = __recipient;
        withdrawalAmounts[__withdrawalId] = __amount;
        withdrawalStatuses[__withdrawalId] = 1;

        emit Processed(__withdrawalId, __recipient, __amount);
    }

    function __withdraw(uint256 __withdrawalId, address __recipient, uint256 __amount) internal {
        token.transfer(__recipient, __amount);
        withdrawalStatuses[__withdrawalId] = 2;

        emit Withdrawal(__withdrawalId, __recipient, __amount);
    }

    function withdraw(uint256[] calldata __withdrawals) external onlyManager {
        uint __total = 0;
        for (uint256 __i = 0; __i < __withdrawals.length; __i++) {
            require(withdrawalStatuses[__withdrawals[__i]] == 1, "Withdraw: incorect withdrawal request status");
            __total = __total + withdrawalAmounts[__withdrawals[__i]];
        }
        require(token.balanceOf(address(this)) > __total, "Process: insuficient balance");

        for (uint256 __i = 0; __i < __withdrawals.length; __i++) {
            __withdraw(__withdrawals[__i], withdrawalRecipients[__withdrawals[__i]], withdrawalAmounts[__withdrawals[__i]]);
        }
    }

    function getDepositById(uint256 __depositId) public view virtual returns (address, uint256) {
        if (depositSenders[__depositId] != address(0)) {
            return (depositSenders[__depositId], depositAmounts[__depositId]);
        }
        return (address(0), 0);
    }

    function getDeposit(uint256 __deposit) public view virtual returns (address, uint256) {
        if (deposits[__deposit] > 0) {
            return getDepositById(deposits[__deposit]);
        }
        return (address(0), 0);
    }

    function getWithdrawalById(uint256 __withdrawalId) public view virtual returns (address, uint256, uint256) {
        if (withdrawalRecipients[__withdrawalId] != address(0)) {
            return (withdrawalRecipients[__withdrawalId], withdrawalAmounts[__withdrawalId], withdrawalStatuses[__withdrawalId]);
        }
        return (address(0), 0, 0);
    }

    function getWithdrawal(uint256 __withdrawal) public view virtual returns (address, uint256, uint256) {
        if (withdrawals[__withdrawal] > 0) {
            return getWithdrawalById(withdrawals[__withdrawal]);
        }
        return (address(0), 0, 0);
    }

    function withdrawAssets(uint256 __amount) external onlyOwner {
        if (__amount == 0) {
            __amount = address(this).balance;
        }
        payable(_msgSender()).transfer(__amount);
    }

    function withdrawCustomTokens(address __token, uint256 __amount) external onlyOwner {
        IERC20Burnable custom = IERC20Burnable(__token);
        if (__amount == 0) {
            __amount = custom.balanceOf(address(this));
        }
        custom.transfer(_msgSender(), __amount);
    }

}