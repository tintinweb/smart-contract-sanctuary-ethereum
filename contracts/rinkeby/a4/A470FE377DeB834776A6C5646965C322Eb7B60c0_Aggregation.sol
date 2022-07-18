// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MarketRegistry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Aggregation is Ownable, ReentrancyGuard {

    MarketRegistry private marketRegistry;

    address private manager;

    // The token address corresponding to the fee charged
    address private feeTokenAddr;
    // Amount of handling fee
    uint256 private feeAmount;
    // Verify that the withdrawal is complete according to the ID number of the withdrawal fee
    mapping(uint256 => bool) private serialNums;

    mapping(string => bool) private batchOrderIds;

    event Manager(address manager);

    event MarketRegistration(address marketRegistry);

    // Set handling fee limit event
    event AggregationFee(address feeToken, uint256 feeTokenAmount);
    // Withdrawal fee event
    event Withdraw(uint256 serialNum, address tokenAddr, address payee, uint256 amount);

    event BatchBuy(string batchOrderId, uint256[] orderIds);

    event CatchEvent(string message);

    modifier onlyManager(){
        require(msg.sender == manager, "Not the manager");
        _;
    }

    modifier onlyAggregationEnable(){
        require(address(marketRegistry) != address(0), "Aggregation not enabled");
        _;
    }

    constructor(){
        manager = msg.sender;
    }

    function setManager(
        address _manager
    ) public onlyOwner {
        manager = _manager;
        emit Manager(_manager);
    }

    function getManager(
    ) public view returns (address) {
        return manager;
    }

    // Set up fees
    function setAggregationFee(address tokenAddr, uint256 fee) public onlyManager {
        feeTokenAddr = tokenAddr;
        feeAmount = fee;
        emit AggregationFee(tokenAddr, fee);
    }
    // Get fee information
    function getAggregationFee() public view returns (address tokenAddr, uint256 Amount){
        return (feeTokenAddr, feeAmount);
    }

    function setMarketRegistry(
        address _marketRegistry
    ) public onlyManager {
        marketRegistry = MarketRegistry(_marketRegistry);
        emit MarketRegistration(_marketRegistry);
    }

    function getMarketRegistry(
    ) public view returns (address) {
        return address(marketRegistry);
    }

    /**
    * @dev manager Withdraw the handling fee from the contract
    * @param serialNum The id number of the withdrawal fee
    * @param tokenaddr The currency of the withdrawal fee
    * @param payee The recipient of the withdrawal fee
    * @param amount Amount of withdrawal fee
    */
    function withdraw(
        uint256 serialNum,
        address tokenaddr,
        address payable payee,
        uint256 amount
    ) public onlyManager
    {
        require(amount > 0, "Withdrawal amount cannot be zero");
        if (serialNums[serialNum] == true) revert("Withdraw invalid");
        if (tokenaddr == address(0)) {//withdraw ETH
            require(address(this).balance >= amount, "Insufficient ETH");
            serialNums[serialNum] = true;
            payee.transfer(amount);
            emit Withdraw(serialNum, tokenaddr, payee, amount);
        } else {//withdraw ERC20
            IERC20 token = IERC20(tokenaddr);
            require(token.balanceOf(address(this)) >= amount, "Insufficient ERC20");
            serialNums[serialNum] = true;
            require(token.transfer(payee, amount) == true, "transfer ERC20 fail");
            emit Withdraw(serialNum, tokenaddr, payee, amount);
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

    function _trade(
        uint256 marketId,
        uint256 value,
        bytes calldata tradeData
    ) internal returns (bool){
        // get market details
        (address _proxy, bool _isActive) = marketRegistry.getMarket(marketId);
        // market should be active
        require(_isActive, "_trade: InActive Market");
        // execute trade
        //(bool success, bytes memory data) = _proxy.delegatecall(tradeData);
        (bool success,) = _proxy.call{value:value}(tradeData);
       
        // try _proxy.call{value:value}(tradeData) returns(bool success,bytes memory data){
        //     return success;
        // } catch Error(string memory reason){
        //     emit CatchEvent(reason);
        //     return false;
        // } 
        return success;
    }

    function batchBuy(
        string calldata batchOrderId,
        uint256[] calldata marketIds,
        uint256[] calldata values,
        bytes[] calldata tradeDatas,
        bool revertIfTrxFail
    ) payable external nonReentrant onlyAggregationEnable {
        if (batchOrderIds[batchOrderId] == true) revert("batchOrderId invalid");
        uint256 len = marketIds.length;
        require(len == tradeDatas.length && len == values.length, "LENGTH_MISMATCH");
        uint256[] memory successIds = new uint256[](len);
        uint256 index = 0;
        for (uint256 i = 0; i < len; ++i) {

            uint256 marketId = marketIds[i];
            bytes calldata tradeData = tradeDatas[i];
            uint256 value = values[i];

            bool _success = _trade(marketId, value, tradeData);

            if (_success) {
                successIds[index++] = i + 1;
            } else if (revertIfTrxFail == true){
                _checkCallResult(_success);
            }
        }
        batchOrderIds[batchOrderId] == true;
        emit BatchBuy(batchOrderId, successIds);

        // return remaining ETH (if any)
        assembly {
            if gt(selfbalance(), 0) {
                let callStatus := call(
                gas(),
                caller(),
                selfbalance(),
                0,
                0,
                0,
                0
                )
            }
        }
    }

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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MarketRegistry is Ownable {

    address private manager;

    event Market(uint256 marketId, address proxy, bool isActive);

    event Manager(address manager);

    struct _Market {
        address proxy;
        bool isActive;
    }

    mapping(uint256 => _Market) private markets;

    // only manager can use it
    modifier onlyManager (){
        require(msg.sender == manager, "Not the manager");
        _;
    }

    function setManager(
        address _manager
    )   public onlyOwner {
        manager = _manager;
        emit Manager(_manager);
    }

    function getManager(
    )   public view returns (address) {
        return manager;
    }

    constructor() {
        manager = msg.sender;
    }

    function setMarket(uint256 marketId, address proxy, bool isActive) public onlyManager {
        markets[marketId].proxy = proxy;
        markets[marketId].isActive = isActive;
        emit Market(marketId, proxy, isActive);
    }

    function getMarket(uint256 marketId) public view returns (address proxy, bool isActive){
        _Market memory market = markets[marketId];
        return (market.proxy, market.isActive);
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