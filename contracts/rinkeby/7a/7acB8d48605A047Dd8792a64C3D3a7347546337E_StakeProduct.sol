pragma solidity ^0.8.0;

import "./ShroomWrapper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./../interfaces/IShroomController.sol";
import "../interfaces/IShroomAllocator.sol";
import "./LinkedList.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract StakeProduct is ShroomWrapper,LinkedList,Ownable,Pausable  {
    uint256 constant ONE_MILLION = 1000000;

    string stakeProductName;

    uint256 public lockTime;
    uint256 public apr;
    uint256 public maxQuota;
    uint256 public walletCap;

    struct ProductDetails{
        uint256 id;
        uint256 endTime;
        uint256 lastUpdateTime;
        uint256 rewardClaimed;
        uint256 tokenAmount;
    }

//    IERC20 public shroom;
    IShroomController public controller;


    mapping(address =>ProductDetails[]) public  userProducts;

    mapping(address => uint256) public rewardsClaimed;

    uint256 public  availableSlot;


    constructor(IERC20 _shroom,IShroomController _controller,uint256 _lockTime,uint256 _apr,uint256 _max,uint256 _walletCap, string memory _rewardEntityName)
    ShroomWrapper(_shroom) Ownable() Pausable(){
        controller = _controller;
        lockTime = _lockTime;
        apr = _apr;
        maxQuota = _max;
        walletCap = _walletCap;
        availableSlot=_max;
        stakeProductName = _rewardEntityName;
    }
    function getUserProductDetails(address _user) public view returns(ProductDetails[] memory){
         return userProducts[_user];


    }

    function pause() external onlyOwner whenNotPaused {
       _pause();
    }

    function unpause() external onlyOwner whenNotPaused {
        _unpause();
    }

    function makeAvailable() public whenNotPaused{
        uint256 time = block.timestamp;
        uint256 available;
        Node memory  headNode = LinkedList.getNodeDetails(head);
        uint256 headEndDate = headNode.timestamp;
        if (time < headEndDate && time > 0){
            available= 0;
        }
        else {
            available = headNode.balance;
            LinkedList.remove();
            for (uint i;i<10;i++){
                headNode = LinkedList.getNodeDetails(head);
                headEndDate = headNode.timestamp;
                if (time < headEndDate){
                    available += headNode.balance;
                    LinkedList.remove();
                }
                else{
                    break;
                }
            }
        }
        availableSlot+=available;
    }



    function stake(uint256 _amount) public  override whenNotPaused{
        makeAvailable();
        address user = msg.sender;
        require(balanceOf(user)+_amount<=walletCap,"Max cap for wallet reached");
        require(availableSlot > _amount,"Not enough available slot");
        availableSlot = availableSlot - _amount;
        uint256 time = block.timestamp;
        ProductDetails  memory stakeDetails;
        stakeDetails.id = userProducts[user].length + 1;
        stakeDetails.endTime = time + lockTime;
        stakeDetails.lastUpdateTime = time;
        stakeDetails.tokenAmount = _amount;
        userProducts[user].push(stakeDetails);
        LinkedList.append(_amount,time + lockTime);
        super.stake(_amount);
    }

    function earned(address _user)public view returns(uint256){
        ProductDetails [] memory userProduct = userProducts[_user];
        uint256 total = userProduct.length;
        uint256 rewards;
        for (uint i ;i<total;i++){
            rewards = rewards + _earned(userProduct[i]);
        }
        return rewards;
    }

    function earnedbyid(uint256 id,address _user) public view returns(uint256){
        
         ProductDetails [] memory userProduct = userProducts[_user];
         uint256 rewards;

        uint256 total = userProduct.length;
        for (uint i;i<total;i++){
            if(id == userProduct[i].id){
               rewards= _earned(userProduct[i]);
               break;
            }

        }
        return rewards;
        }



    function _earned(ProductDetails memory _details) internal view returns(uint256){
        uint256 balance = _details.tokenAmount;
        uint256 userTime = _details.lastUpdateTime;
        uint256 currentTime = block.timestamp;
        uint256 endTime = _details.endTime;
        uint256 applicableTime = endTime < currentTime ? endTime : currentTime;
        if (userTime > applicableTime){
            return 0;
        }
        uint256 reward = (balance * (applicableTime-userTime) *apr) / (100* 86400 *365);
        return reward;
    }

    function claimReward() public whenNotPaused {
        makeAvailable();
        address user = msg.sender;
        uint256 reward;
        ProductDetails [] storage userProduct = userProducts[user];
        uint256 total = userProduct.length;
        uint256 currentTime = block.timestamp;
        for (uint i ;i<total;i++){
            uint256 pReward = _earned(userProduct[i]);
            userProduct[i].lastUpdateTime = currentTime;
            reward +=pReward;
            userProduct[i].rewardClaimed = pReward;
        }
        rewardsClaimed[user] = rewardsClaimed[user] + reward;
        controller.getShroom(reward,stakeProductName,user);
    }

    function claimUnstakedShroom() public whenNotPaused{
        makeAvailable();
        address user = msg.sender;
        ProductDetails[] storage userProduct = userProducts[user];
        uint256 pendingReward;
        uint256 availableShroom;
        uint256 total = userProduct.length;
        for (uint i=0;i<total;i++){
            if (userProduct[i].endTime < block.timestamp){
                pendingReward=pendingReward + _earned(userProduct[i]);
                availableShroom = availableShroom + userProduct[i].tokenAmount;
                userProduct[i] = userProduct[total-1];
                userProduct.pop();
            }
        }
        rewardsClaimed[user]= rewardsClaimed[user]+pendingReward;
        super.unstake(availableShroom);
        controller.getShroom(pendingReward,stakeProductName,user);
    }


    function getInactiveStakes(address _user) public view returns(uint256[] memory,uint256[] memory){
        ProductDetails[] memory userProduct = userProducts[_user];
        uint256 total = userProduct.length;
        uint256[] memory claimableIds = new uint256[](total) ;
        uint256[] memory claimableShrooms = new uint256[](total);
        for (uint i=0;i<total;i++){
            if (userProduct[i].endTime < block.timestamp){
                claimableIds[i]=userProduct[i].id;
                claimableShrooms[i]= userProduct[i].tokenAmount;
            }
        }
        return (claimableIds,claimableShrooms);

    }

   function claimProductShroomReward(uint256 _id) external whenNotPaused{
       makeAvailable();
       address user = msg.sender;
       uint256 reward;
       ProductDetails[] storage userProduct = userProducts[user];
       uint256 total = userProduct.length;
       for(uint i;i<total;i++){
           if(userProduct[i].id==_id){
               reward = _earned(userProduct[i]);
               userProduct[i].rewardClaimed = reward;
               userProduct[i].lastUpdateTime = block.timestamp;
               rewardsClaimed[user] = rewardsClaimed[user] + reward;
               break;
           }
       }
       controller.getShroom(reward,stakeProductName,user);

   }

}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract ShroomWrapper {
    IERC20 public immutable shroom;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(IERC20 shroom_)  {
        shroom = shroom_;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        address user = msg.sender;
        _totalSupply = _totalSupply+ amount;
        _balances[user] = _balances[user]+ amount;
        shroom.transferFrom(user, address(this), amount);
    }

    function unstake(uint256 amount) public virtual {
        address user = msg.sender;
        uint256 userBalance = _balances[user];
        require(userBalance>=amount,"Cannot unstake more than the users staked amount");
        _totalSupply = _totalSupply-amount;
        _balances[user] = userBalance-amount;
        shroom.transfer(user, amount);
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;



interface IShroomController {
    function getShroom(uint256 _number,string memory _name,address _to)external;
    function getRemaining(string memory _name,address _to)external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IShroomAllocator  {
    function getShroom(uint256 _number,string memory _name)external;

}

pragma solidity ^0.8.0;

contract LinkedList {

    uint256 id;

    struct Node{
        uint256 next;
        uint balance;
        uint timestamp;
    }

    uint256 public head;
    mapping (uint256 => Node)  nodes;

// each node is appended to tail
    function append(uint _balance,uint _timestamp) internal {
        Node memory node = Node(id+1,_balance,_timestamp);
        nodes[id]  = node;
        id = id +1;
    }

    function getNodeDetails(uint _id) public view returns(Node memory){
        return nodes[_id];
    }

    function remove() internal{
        uint256 newHead = nodes[head].next;
        delete nodes[head];
        head = newHead;
    }

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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