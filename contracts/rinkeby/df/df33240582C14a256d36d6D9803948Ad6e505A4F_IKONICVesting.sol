/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.4;

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

pragma solidity ^0.8.4;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.4;

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




contract IKONICVesting is Ownable,ReentrancyGuard{


    IERC20 public token;
    uint public globalStartTime;
    // uint public totalContractBalance=token.address(this).

    struct Investor {
        address account;
        uint256 amount;
        uint256 investorType;
    }


    struct vestingDetails {
        uint investorType;
        uint totalBalance;
        uint lastClaimTime;
        uint initialToBeClaimed;
        uint intermediateToBeClaimed;
        uint linearToBeClaimed;
        uint initialClaimed;
        uint intermediateClaimed;
        uint linearClaimed;
        bool hasInitialClaimed;
        bool hasIntermediateClaim;
        bool hasLinearClaimed;
    }

    constructor () {
    }
      

    event InvestorAddress(address account, uint _amout,uint investorType);
    event VestingAmountTaken(address account, uint _amout);


    mapping (address => vestingDetails) public InvestorDetails;
    mapping (address => bool) public isUserAdded;
    mapping (address => bool) public isBlackListed;
    mapping(address => uint256) public availableBalance; 
    mapping(address=>bool) public isIntermediateClaimed;
    mapping(address=>bool ) public isLinearClaimed;
    mapping(address=>uint) public uintPerDay;


    uint[] public initialVestingAmountWithdrawThresholdTime;
    uint[] public intermediateVestingAmountWithdrawThresholdTime;
    uint[] public linearVestingAmountWithdrawThresholdTime;
    uint[] public initialAmountReleased=[0,0,50,100,200,0,0,0,0,30,200];
    uint[] public intermediateAmountReleased=[0,0,0,0,0,0,0,0,60,0,0];
    uint[] public linearVestingAmountReleased=[0,1000,950,900,800,1000,1000,1000,940,970,800]; // stores percentage
    uint[] public intermediateVestingTimePeriod=[0,0,0,0,0,0,0,0,30 days,0,0];
    uint[] public linearVestingTimePeriod=[0,660 days,540 days,365 days,180 days,900 days ,1080 days ,1050 days,720 days,1350 days,480 days];

    function addInvestors(Investor[] memory vest) external onlyOwner {
        for (uint i = 0;i < vest.length;i++) {
            require (!isUserAdded[vest[i].account],'User already whitelisted');
            require (!isBlackListed[vest[i].account],'User BlackListed');
            isUserAdded[vest[i].account] = true;
            vestingDetails memory vesting;
            vesting.investorType = vest[i].investorType;
            vesting.totalBalance = vest[i].amount * 1 ether;
            uint256 _amount=vest[i].amount* 1 ether;
           
            availableBalance[vest[i].account]+=_amount;
            vesting.initialToBeClaimed = (initialAmountReleased[vest[i].investorType] *_amount) / 1000;
            vesting.intermediateToBeClaimed = (intermediateAmountReleased[vest[i].investorType] * _amount)/ 1000;
            vesting.linearToBeClaimed = (linearVestingAmountReleased[vest[i].investorType] * _amount ) / 1000;
             uintPerDay[vest[i].account]= vesting.linearToBeClaimed/(linearVestingTimePeriod[vest[i].investorType]/1 days);
            InvestorDetails[vest[i].account] = vesting;
            emit InvestorAddress(vest[i].account,_amount,vest[i].investorType);
        }
    }

      function getInvestorDetails(address _addr) public view returns(vestingDetails memory){
        return InvestorDetails[_addr];
    }
    function getContractTokenBalance() external view returns(uint){
        return token.balanceOf(address(this));
    }


    function withdraw() external nonReentrant{
        isIntermediateClaimed[msg.sender]=true;
        require (isUserAdded[msg.sender],'User Not Added');
        require (!isBlackListed[msg.sender],'User BlackListed');
        require (!InvestorDetails[msg.sender].hasLinearClaimed,'Vesting: All Amount Claimed');


        if (initialAmountReleased[InvestorDetails[msg.sender].investorType] == 0 && intermediateAmountReleased[InvestorDetails[msg.sender].investorType] > 0 && InvestorDetails[msg.sender].intermediateClaimed == 0)
                 {
                     InvestorDetails[msg.sender].lastClaimTime = intermediateVestingAmountWithdrawThresholdTime[InvestorDetails[msg.sender].investorType];
                 }
        else if (initialAmountReleased[InvestorDetails[msg.sender].investorType] == 0 && intermediateAmountReleased[InvestorDetails[msg.sender].investorType] == 0 && InvestorDetails[msg.sender].linearClaimed == 0 )
                {
                    InvestorDetails[msg.sender].lastClaimTime = linearVestingAmountWithdrawThresholdTime[InvestorDetails[msg.sender].investorType];
                }

        (uint amount, uint returnType) = getVestingBalance(msg.sender);
        require(returnType != 4,'Time Period is Not Over');
        if (returnType == 1) {
            require (amount >0,'Initial Vesting: 0 amount');
            InvestorDetails[msg.sender].hasInitialClaimed = true;
            InvestorDetails[msg.sender].initialClaimed += amount;
            token.transfer(msg.sender, amount);
            if (intermediateAmountReleased[InvestorDetails[msg.sender].investorType] > 0)
                InvestorDetails[msg.sender].lastClaimTime = intermediateVestingAmountWithdrawThresholdTime[InvestorDetails[msg.sender].investorType];
            else if (intermediateAmountReleased[InvestorDetails[msg.sender].investorType] == 0 )
                InvestorDetails[msg.sender].lastClaimTime = linearVestingAmountWithdrawThresholdTime[InvestorDetails[msg.sender].investorType];
                 availableBalance[msg.sender]-=amount;
            emit VestingAmountTaken(msg.sender, amount);
        } else if (returnType == 2) {
            require (amount >0,'Intermediate Vesting: 0 amount');
            InvestorDetails[msg.sender].lastClaimTime = block.timestamp;
            InvestorDetails[msg.sender].intermediateClaimed+=amount;
            
            require (InvestorDetails[msg.sender].intermediateToBeClaimed >= InvestorDetails[msg.sender].intermediateClaimed,'Intermediate Vesting: Cannot Claim More');
            if (InvestorDetails[msg.sender].intermediateToBeClaimed ==  InvestorDetails[msg.sender].intermediateClaimed)
            {
                InvestorDetails[msg.sender].hasIntermediateClaim = true;
                InvestorDetails[msg.sender].lastClaimTime = linearVestingAmountWithdrawThresholdTime[InvestorDetails[msg.sender].investorType];
            }
            token.transfer(msg.sender, amount);
            availableBalance[msg.sender]-=amount;
            emit VestingAmountTaken(msg.sender, amount);
        }
        else {
            require (amount >0,'Linear Vesting: 0 amount');
            InvestorDetails[msg.sender].lastClaimTime = block.timestamp;
            InvestorDetails[msg.sender].linearClaimed += amount;
            require (InvestorDetails[msg.sender].linearToBeClaimed >= InvestorDetails[msg.sender].linearClaimed,'Linear Besting: Cannot Claim More');
            if (InvestorDetails[msg.sender].linearToBeClaimed == InvestorDetails[msg.sender].linearClaimed)
            {
                InvestorDetails[msg.sender].hasLinearClaimed = true;
            }
            isLinearClaimed[msg.sender]=true;
            token.transfer(msg.sender, amount);
          availableBalance[msg.sender]-=amount;
            emit VestingAmountTaken(msg.sender, amount);
        }
    }

    //@dev Contract Setters

    function setRewardTokenAddress (address _tokenAddress) public onlyOwner {
        token = IERC20(_tokenAddress);
    }
    
    function setDates (uint startTime) external onlyOwner {

        globalStartTime = startTime;
        initialVestingAmountWithdrawThresholdTime = [0,startTime,startTime,startTime,startTime,startTime,startTime,startTime,startTime,startTime,startTime];
        intermediateVestingAmountWithdrawThresholdTime = [0,0,0,0,0,0,0,0,startTime + 14 days,0,0];
        linearVestingAmountWithdrawThresholdTime= [0,startTime+ 60 days ,startTime + 1 days ,startTime + 1 days,startTime +  1 days ,startTime + 180 days,startTime + 365 days,startTime + 30 days,startTime + 180 days, startTime + 90 days,startTime + 1 days];
    }
   

    //@dev Get Details About Vesting Time Period
    function getVestingBalance(address _userAddress) public view returns (uint, uint) {
        if (!InvestorDetails[_userAddress].hasInitialClaimed &&
            block.timestamp >= initialVestingAmountWithdrawThresholdTime[InvestorDetails[_userAddress].investorType] &&
            InvestorDetails[_userAddress].initialToBeClaimed > 0) {return (InvestorDetails[_userAddress].initialToBeClaimed, 1);}
        else if (
            !InvestorDetails[_userAddress].hasIntermediateClaim &&
            InvestorDetails[_userAddress].intermediateToBeClaimed > 0 &&
            block.timestamp >= intermediateVestingAmountWithdrawThresholdTime[InvestorDetails[_userAddress].investorType]) {
            (uint balance,uint _bal) = intermediateVestStatus(_userAddress);
           // console.log('Balance',balance);
            return (balance,_bal);
        }
        else if (!InvestorDetails[_userAddress].hasLinearClaimed && InvestorDetails[_userAddress].linearToBeClaimed > 0 && block.timestamp >= linearVestingAmountWithdrawThresholdTime[InvestorDetails[_userAddress].investorType]) return (linearVestingDetails(_userAddress),3);
        else return (0,4);
    }

    function intermediateVestStatus(address _userAddress) public view returns (uint,uint) {
        uint lastClaimTime = InvestorDetails[_userAddress].lastClaimTime;
        uint timeDifference;
        uint[11] memory intermediateArray = [0,0,0,0,0,0,0,0,globalStartTime + 14 days,0,0];// give Intermediate time
        if (block.timestamp <= intermediateVestingTimePeriod[InvestorDetails[_userAddress].investorType]+intermediateArray[InvestorDetails[_userAddress].investorType])
        {
            if(!isIntermediateClaimed[_userAddress]){
             timeDifference=block.timestamp-intermediateArray[InvestorDetails[_userAddress].investorType];
            }else{
             timeDifference = block.timestamp - lastClaimTime;
            }
            
        }
        else
        {
            //@dev to return people the exact amount if the intermediate vesting period is over
           return(InvestorDetails[_userAddress].intermediateToBeClaimed - InvestorDetails[_userAddress].intermediateClaimed,2);
        }

        timeDifference = timeDifference / 1 days;
        uint intermediateReleaseTimeSpan = intermediateVestingTimePeriod[InvestorDetails[_userAddress].investorType];
        uint totalIntermediateFund = InvestorDetails[_userAddress].intermediateToBeClaimed;
        uint perDayFund = totalIntermediateFund / (intermediateReleaseTimeSpan / 1 days);
        uint price = perDayFund * timeDifference;
        return (price,2);
    }


    function linearVestingDetails(address _userAddress) public view returns (uint) {
        uint lastClaimTime = InvestorDetails[_userAddress].lastClaimTime;
        uint timeDifference;
        uint[11] memory linearTime =[0,globalStartTime+ 60 days ,globalStartTime + 1 days ,globalStartTime + 1 days,globalStartTime +  1 days ,globalStartTime + 180 days,globalStartTime + 365 days,globalStartTime + 30 days,globalStartTime + 180 days, globalStartTime + 90 days,globalStartTime + 1 days];
        if (block.timestamp <= linearVestingTimePeriod[InvestorDetails[_userAddress].investorType]+linearTime[InvestorDetails[_userAddress].investorType]) {
             if(!isLinearClaimed[_userAddress]){

                    timeDifference=block.timestamp-linearTime[InvestorDetails[_userAddress].investorType];
             }else{
                 timeDifference = block.timestamp - lastClaimTime;
             }
        }
        else
        {
            //@dev to return people the exact amount if the intermediate vesting period is over
            return(InvestorDetails[_userAddress].linearToBeClaimed - InvestorDetails[_userAddress].linearClaimed);
        }

        timeDifference = timeDifference / 1 days;
        uint linearReleaseTimeSpan = linearVestingTimePeriod[InvestorDetails[_userAddress].investorType];
        uint totalIntermediateFund = InvestorDetails[_userAddress].linearToBeClaimed;
        uint perDayFund = totalIntermediateFund / (linearReleaseTimeSpan / 1 days);

        return perDayFund * timeDifference;
    }


    function getLinearVestEndTime(uint256 saletype) public view returns(uint){
        uint256 endDays=linearVestingAmountWithdrawThresholdTime[saletype]+linearVestingTimePeriod[saletype];
        return endDays;  
    }

    function blockUser(address[] memory blackListedAddresses) external onlyOwner {
        for (uint i=0; i< blackListedAddresses.length; i++) {
            isBlackListed[blackListedAddresses[i]] = true;
        }
    }

    function unBlockUser(address[] memory whitelistListedAddresses) external onlyOwner {
        for (uint i=0; i< whitelistListedAddresses.length; i++) {
            isBlackListed[whitelistListedAddresses[i]] = false;
        }
    }

    function extractETH() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

     function transferToken(address ERC20Address, uint256 value) public onlyOwner {
        require(value <= IERC20(ERC20Address).balanceOf(address(this)), 'Insufficient balance to withdraw');
        IERC20(ERC20Address).transfer(msg.sender, value);
    }


    function removeUser (address[] memory usersToRemove) external onlyOwner {
           require(globalStartTime==0,"Vesting Time Started");
        for (uint i=0; i< usersToRemove.length; i++) {
            removeSingleUser(usersToRemove[i]);
        }
    }

    function removeSingleUser(address _userAddress)public onlyOwner{
        require(InvestorDetails[_userAddress].investorType>0);
        require(globalStartTime==0,"Vesting Time Started");
        availableBalance[_userAddress]=0;
        delete InvestorDetails[_userAddress];
        isUserAdded[_userAddress]=false;
    }

}