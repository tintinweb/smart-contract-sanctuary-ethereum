/**
 *Submitted for verification at Etherscan.io on 2023-02-02
*/

//SPDX-License-Identifier: MIT
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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/Referral.sol



pragma solidity ^0.8.0;


// A refferel system for any dapp.

// Needs some modifications. like making it only accessable by inherited contract.
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract Referral is Ownable{

    // Referral levels
    
    struct RefferalLevel {

        uint256 lvl1;
        uint256 lvl2;
        uint256 lvl3;
        uint256 lvl4;
        uint256 lvl5;
        uint256 lvl6;

    }
    uint[6] levelPercentages = [30, 20, 20, 10, 5, 5];

    mapping(address => address) private referral;
    mapping(address => RefferalLevel) private myRefferals;
    mapping(address => uint) private referenceProfit;
    uint public membersReceived = 0;
    bool locked = false;
address payable private remainingOwner; // The remaining refferel goes to owner account. @ dev

    // Modifier
    /**
     * @dev Prevents reentrancy
     */
    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    constructor(address payable _remaningOwner){
        remainingOwner = _remaningOwner;
    }

    function GetMyRefferals(address _account) public view returns (RefferalLevel memory) {
        return myRefferals[_account];
    }

    function isReferred() public view returns(bool){
        if(referral[msg.sender] == address(0)){
            return false;
        }else{
            return true;
        }
    }


    function setPercentages(uint _level, uint _percentage) public onlyOwner{
        require(_level<=6 && _level !=0 , "Invalid Level"); // ISSUE: percentages calculation ?
        require(_percentage<=100 && _percentage>0, "invalid percentages");
        levelPercentages[_level-1] = _percentage;
    }


    
    function _SetReferral(address _friend) internal{
        require(!isReferred(), "you have already joined");
        
        referral[msg.sender] = _friend;
        
        
        for (uint i = 0; i < 6; i++) {
            if (_friend == 0x0000000000000000000000000000000000000000) break;
            if (i == 0) myRefferals[_friend].lvl1++;

            if (i == 1) myRefferals[_friend].lvl2++;

            if (i == 2) myRefferals[_friend].lvl3++;

            if (i == 3) myRefferals[_friend].lvl4++;

            if (i == 4) myRefferals[_friend].lvl5++;

            if (i == 5) myRefferals[_friend].lvl6++;

            _friend = referral[_friend];
           
        }
    }

    function _HandleReferal(uint _amount) internal noReentrant {
        
        address payable _friend;
        uint totalbonus = 0;
        //level 1
        _friend = payable(referral[msg.sender]);
        if (
            _friend !=
            0x0000000000000000000000000000000000000000 &&
            myRefferals[_friend].lvl1 >= 1
        ) {
            uint bonus = (30*_amount)/100;
            _friend.transfer(bonus); //set by percentage.
            
            referenceProfit[_friend] = referenceProfit[_friend]+ bonus;
            totalbonus = totalbonus + bonus;
        }
        //level 2
        _friend = payable(referral[_friend]);
        if (
            _friend != 0x0000000000000000000000000000000000000000 &&
            myRefferals[_friend].lvl1 + myRefferals[_friend].lvl2 >= 2
        ) {
            uint bonus = (20*_amount)/100;
            _friend.transfer(bonus);
            
            referenceProfit[_friend] = referenceProfit[_friend]+bonus;
            totalbonus = totalbonus + bonus;

        }
        //level 3
        _friend = payable(referral[_friend]);
        if (
            _friend != 0x0000000000000000000000000000000000000000 &&
            myRefferals[_friend].lvl1 + myRefferals[_friend].lvl2 + myRefferals[_friend].lvl3 >= 3
        ) {
            uint bonus = (10*_amount)/100;

            _friend.transfer(bonus);
            
            referenceProfit[_friend] = referenceProfit[_friend]+bonus;
            totalbonus = totalbonus + bonus;

        }
        //level 4
        _friend = payable(referral[_friend]);
        if (
            _friend != 0x0000000000000000000000000000000000000000 &&
            myRefferals[_friend].lvl1 + myRefferals[_friend].lvl2 + myRefferals[_friend].lvl3+ myRefferals[_friend].lvl4 >= 4
        ) {
            uint bonus = (5*_amount)/100;
           _friend.transfer(bonus);
            
            referenceProfit[_friend] = referenceProfit[_friend] + bonus;
            totalbonus = totalbonus + bonus;

        }
        //level 5
        _friend = payable(referral[_friend]);
        if (
            _friend != 0x0000000000000000000000000000000000000000 &&
            myRefferals[_friend].lvl1 + myRefferals[_friend].lvl2 + myRefferals[_friend].lvl3+ myRefferals[_friend].lvl4+myRefferals[_friend].lvl5 >= 5
        ) {
            uint bonus = (5*_amount)/100;
            _friend.transfer(bonus);
            
            referenceProfit[_friend] = referenceProfit[_friend]+bonus;
            totalbonus = totalbonus + bonus;

        }
        // level 6
        _friend = payable(referral[_friend]);
        if (
            _friend != 0x0000000000000000000000000000000000000000 &&
            myRefferals[_friend].lvl1 + myRefferals[_friend].lvl2 + myRefferals[_friend].lvl3+ myRefferals[_friend].lvl4+myRefferals[_friend].lvl5+myRefferals[_friend].lvl6 >= 6
        ) {
            uint bonus = (5*_amount)/100;
            _friend.transfer(bonus);
            
            referenceProfit[_friend] = referenceProfit[_friend]+bonus;
            totalbonus = totalbonus + bonus;

        }
        membersReceived = membersReceived + totalbonus;
        //remaining goes to owner.

        if (_amount-totalbonus!=0) remainingOwner.transfer(_amount-totalbonus);
    }

    function GetRefferalProfit(address addr) public view returns(uint profit){
        profit = referenceProfit[addr];
    }
    
}



contract SubscriptionContract is Referral {
    // Subscription for a persons.
    struct Subscription{
        bool isSubscribed;
        uint date;
        bool type1; 
    }
    uint private type1Value = 10 ether;


    uint private subscriptionDuration = 1 days * 365;

    // Mapping a persons subscription with his address.
    mapping(address=>Subscription) internal subscription;

    uint public subscribers = 0;
    uint8 public referralPercentage = 70;

    event SubscriptionEvent(address indexed _from, uint _value, uint _date);

    // Should be used before every function to remove expired subscription.
    modifier SubscriptionStoper(){
        Subscription storage mySubscription = subscription[msg.sender];
        if(mySubscription.isSubscribed == true && block.timestamp-mySubscription.date > subscriptionDuration)// 365 must be stored in a vriable to change it.
        {
            mySubscription.isSubscribed = false;
            mySubscription.type1 = false;
            
        }
        _;
    }
    // should be used for checking subscriptions.
    modifier isSubscribed(){
        Subscription storage mySubscription = subscription[msg.sender];
        require(mySubscription.isSubscribed == true && block.timestamp-mySubscription.date <=subscriptionDuration, 'Not Subscribed');
        _;
    }

    constructor(address payable _remaningOwner) Referral(_remaningOwner){

    }

    function setReferralPercentage(uint8 _percentage) public onlyOwner{
        referralPercentage = _percentage;
    }

    // setting type 1 and type 2 value

    // should be assessed by only owner. ---P
    function _SetSubscriptionPrice(uint _price1) internal {
        type1Value = _price1* 1 ether;
    }
    // should be assessed by only owner. ---P 
    function _SetSubscriptionDuration(uint _duration) internal {
        subscriptionDuration = _duration * 1 days;
    }
    
    function MySubscription() public view returns(bool _isSubscribed, uint _remaningTime){
        Subscription memory mySubscription = subscription[msg.sender];
        _isSubscribed =  mySubscription.isSubscribed;
        _remaningTime = subscriptionDuration - (block.timestamp - mySubscription.date);

    }
    // To subbscribe and enable refferels.
    function Subscribe(address _friend) payable public SubscriptionStoper{

        require(msg.value == type1Value, 'Insuffecient balance.');
        require(msg.sender != _friend, 'You cannot refer yourself');

        Subscription storage mySubscription = subscription[msg.sender];
        require(mySubscription.isSubscribed != true, 'You are already subscribed');

        Subscription storage friendSubscription = subscription[_friend];
        require(friendSubscription.isSubscribed == true || _friend == 0x0000000000000000000000000000000000000000, 'Your friend has no subscription');



        mySubscription.type1 = true;
        mySubscription.date = block.timestamp;
        mySubscription.isSubscribed = true; 
        subscribers++;
        // Setting the referrals.
        _SetReferral(_friend);
        // Sending the referral profits.
        _HandleReferal((msg.value*70)/100);

        emit SubscriptionEvent(msg.sender, msg.value, block.timestamp);

    }

    function IsSubscribed() public view returns(bool){
        Subscription storage mySubscription = subscription[msg.sender];
        if(mySubscription.isSubscribed == true && block.timestamp-mySubscription.date <=subscriptionDuration){
            return true;
        }else{
            return false;
        }
        
    }

    function extractToken(address tokenAddress, address recipient)
        public
        onlyOwner
    {
        IERC20 t = IERC20(tokenAddress);
        t.transfer(recipient, t.balanceOf(address(this)));
    }



    function withdraw(address _recipient) public onlyOwner {
        require(payable(_recipient).send(address(this).balance));
    }

}