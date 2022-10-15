// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "./SelfStakingPool.sol";

contract SelfStakingPoolFactory is Ownable {
address public usdc = 0xD87Ba7A50B2E7E660f678A895E4B72E7CB4CCd9C; // Goeril
uint256 private maxOwnerPercent;

    event SelfPoolCreated(
        address pool,
        uint256 ticketValue, 
        uint256 endTime, 
        uint256 capacity,
        address owner,
        uint256 ownerPercent
    );
constructor (
    uint256  _maxOwnerPercent
)
{
maxOwnerPercent = _maxOwnerPercent;
}
function createPool( uint256 ticketValue, uint256 endTime, uint256 capacity, uint256 ownerPercent) external  {
   require(ownerPercent <= maxOwnerPercent, "ownerPercent is more than maxOwnerPercent"); 
   address  newPool = address(new SelfStakingPool(ticketValue, endTime, capacity, owner(), ownerPercent));
   emit SelfPoolCreated(newPool,ticketValue, endTime, capacity,owner(), ownerPercent);
}

function getMaxOwnerPercent() external view returns (uint256) {    
    return maxOwnerPercent;
}
 

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Usdc.sol";

contract SelfStakingPool {
    address private usdcAddress = 0xD87Ba7A50B2E7E660f678A895E4B72E7CB4CCd9C; // Goeril
    address public defaultAddress = 0x0000000000000000000000000000000000000000;
    UsdcToken private usdcToken;
    address private owner;
    uint256 public ticketValue;
    uint256 public lockTime;
    uint256 public capacity;
    uint256 private winnerPercent;
    uint256 private ownerPercent;
    bool public poolIsMature = false;
    mapping(address => address) private getStaker;
    uint private sumOfStakers = 0;
    uint private sumOfStakes = 0;
    address [] private stakers;
    address private winner;
    bool private hasWinner = false;
    bool private hasOwnerFee = false;
    bool private ownerPayIsSuccess = false;
    bool private rewardPayIsSuccess = false;
    constructor(
        uint256 _ticketValue,
        uint256 _endTime,
        uint256 _capacity,
        address _owner,
        uint256 _ownerPercent
    )
    {
    ticketValue = _ticketValue;
    lockTime = _endTime;
    capacity = _capacity; 
    usdcToken = UsdcToken(usdcAddress);
    owner = _owner;
    ownerPercent =  _ownerPercent;
    winnerPercent = 100 - ownerPercent;
    }

    function random(uint256 length) internal  view returns(uint){
        // return  0 to length -1
        uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, msg.sender.balance))) % length;
         randomnumber = randomnumber;
         return randomnumber;
    }    

    event SelfPoolStake(
        address staker,
        address pool   
    );
    event SelfPoolSetWinner(
        address winner,
        address pool,
        address owner
    );


    function stake(uint256 _ticketValue) external returns(bool)  {
        require(poolIsMature == false, "Pool is mature");
        require(lockTime > block.timestamp, "Pool finished");
        require(_ticketValue == ticketValue, "Amount is incorrect");
        // check sender value is usdc
        require(getStaker[msg.sender] != msg.sender, "You have already predicted!");
        require(sumOfStakers < capacity, "Pool is full");
        bool result = usdcToken.transferFrom(msg.sender, address(this), _ticketValue);
        if(result == false) {
           return false;
        }
        getStaker[msg.sender] = msg.sender;
        stakers.push(msg.sender);
        sumOfStakes= sumOfStakes + _ticketValue;
        sumOfStakers++;
        emit SelfPoolStake(msg.sender,address(this));
        return true;
    }
    
    function setWinner() external  returns(bool) {
       uint256 ownerReward;
       uint256 winnerReward;
       require(poolIsMature == false, "Pool payed rewards and matured!");
        if((sumOfStakers == capacity) || (lockTime <= block.timestamp)) {
            if(sumOfStakers == 0) {
                emit SelfPoolSetWinner(defaultAddress, address(this), owner);
                poolIsMature = true;
                return true;
            }
            if(sumOfStakers == 1) {
                bool isSuccessPay = usdcToken.transfer(stakers[0], sumOfStakes);
                if(isSuccessPay == false) {
                    return false;
                }
                emit SelfPoolSetWinner(defaultAddress, address(this), owner);
                poolIsMature = true;
                return true;
            }
            if(hasWinner == false) {
              uint index = random(stakers.length);
              winner = stakers[index];
              hasWinner = true;
            }
            if(hasOwnerFee == false) {
                ownerReward = (sumOfStakes/100)*ownerPercent;
                winnerReward = sumOfStakes - ownerReward;
                hasOwnerFee = true;
            }

            if(ownerPayIsSuccess == false) {
                ownerPayIsSuccess = usdcToken.transfer(owner, ownerReward);
            }

            if(rewardPayIsSuccess == false) {
                rewardPayIsSuccess = usdcToken.transfer(winner, winnerReward);
            }
            emit SelfPoolSetWinner(winner, address(this), owner);
            poolIsMature = true;
            return true;

       }
       return false;       
    }

    function getStakers() external view returns (address[] memory) {
        return stakers;
    }
    function getNumberOfStakers() external view returns (uint) {
        return stakers.length;
    }

    function getwinner() external view returns (address) {    
        return winner;
    }
    function getOwner() external view returns (address) {    
        return owner;
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

pragma solidity ^0.8.0;
// SPDX-License-Identifier: UNLICENSED

interface UsdcToken {
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
}