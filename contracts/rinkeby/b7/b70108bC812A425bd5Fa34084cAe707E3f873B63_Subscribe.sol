/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

pragma solidity >=0.7.0 <0.9.0;

contract Subscribe is Ownable {
    string public name;
    bool public isPaused = false;
    uint public refundPeriod = 1;
    uint public withdrawableBalance = 0;
    
    /*<UPDATED> GAME LOGIC*/
    uint public blockCount = 0;
    mapping(uint => uint) public plans;
    mapping(string => uint) public discounts;
    //mapping(uint => mapping(address => Better[])) public betters;
    mapping(address => SubscribedPlan[]) public subscribers;

    struct SubscribedPlan {
        address user;
        uint price;
        uint plan;
        uint256 date;
    }
   
    event PlanCreated(
        uint plan,
        uint price
    );

    event PlanRemoved(
        uint plan
    );

    event DiscountCreated(
        uint discount,
        string name
    );

    event DiscountRemoved(
        string name
    );
    /*</UPDATED>*/
    
    constructor() {
        name = "CryptoMarketDarts";
        planCreate(30, 13000000000000000);
        planCreate(180, 67000000000000000);
        planCreate(360, 117000000000000000);
    }

    function subscribeDeposit(uint _plan, string memory _discount_name) public payable {
        require(!isPaused, "Subscribtions are paused at the moment");
        require(_plan > 0, "Plan does not exist.");
        require(plans[_plan] > 0, "Plan does not exist.");
        if(bytes(_discount_name).length > 0) {
            require(discounts[_discount_name] > 0 && discounts[_discount_name] <= 100, "Discount percent must be more from 1 to 100");
            require(msg.value >= plans[_plan] * discounts[_discount_name] / 100 - 1, "Wrong Ether amount for current plan");
        } else {
            require(msg.value == plans[_plan], "Wrong Ether amount for current plan");
        }
        

        //generate map array like this map(address user => map(String[] hash)) with uniq hash keys
        SubscribedPlan memory subscribed_plan;
        subscribed_plan.user = msg.sender;
        subscribed_plan.price = plans[_plan];
        subscribed_plan.plan = _plan;
        subscribed_plan.date = block.timestamp;
        subscribers[msg.sender].push(subscribed_plan);
    }
    
    //////////////////only owner functions
    function setIsPaused(bool _state) public onlyOwner {
        isPaused = _state;
    }

    function setRefundPeriod(uint _refundPeriod) public onlyOwner {
        refundPeriod = _refundPeriod;
    }

    //////////////////////plan create
    function planCreate(uint _plan, uint _price) public onlyOwner {
        // Require valid _plan
        require(_plan > 0 && _plan <= 1080, "Plan date must be more then 0");
        
        require(_price > 0, "Plan date must be more then 0");
        // Create the miner
        plans[_plan] = _price;
        // Trigger event
        emit PlanCreated(_plan, _price);
    }
    
    //////////////////////plan remove
    function planRemove(uint _plan) public onlyOwner {
        // Require valid address
        require(_plan > 0, "plan must be more then 0");
        
        delete plans[_plan];
        emit PlanRemoved(_plan);
    }

    //////////////////////dicount create
    function discountCreate(uint _discount, string memory _name) public onlyOwner {
        // Require valid _plan
        require(_discount > 0 && _discount <= 100, "Discount percent must be more from 1 to 100");
        
        require(bytes(_name).length > 0, "Discount name must can't be empty");
        // Create the miner
        discounts[_name] = _discount;
        // Trigger event
        emit DiscountCreated(_discount, _name);
    }
    
    //////////////////////plan remove
    function discountRemove(string memory _name) public onlyOwner {
        // Require valid _plan
        require(bytes(_name).length > 0, "Discount name must can't be empty");
        
        delete discounts[_name];
        emit DiscountRemoved(_name);
    }

    // NOTE: This should not be used for generating random number in real world
    function generateRandomNumber() private view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.timestamp)));
    }

    function subscriberAdd() public onlyOwner {
        // Require valid _plan
        //require(_plan > 0 && _plan <= 1080, "Plan date must be more then 0");
        
        //require(_price > 0, "Plan date must be more then 0");
        // Create the miner
        //subscribers[msg.sender].push(generateRandomNumber());
        // Trigger event
        //emit PlanCreated(_plan, _price);
    }
    
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: withdrawableBalance
        }("");
        require(success);
    }
}