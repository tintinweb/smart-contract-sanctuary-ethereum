/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

pragma solidity ^0.8.15;

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

pragma solidity ^0.8.15;

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

pragma solidity ^0.8.15;


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

pragma solidity ^0.8.15;

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




contract IKONICVesting is Ownable {


    IERC20 token;
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
//        setPauseStatus(true);
    }
      uint256 public linearStart8;

    event InvestorAddress(address account, uint _amout,uint investorType);
    event VestingAmountTaken(address account, uint _amout);
    mapping (address => vestingDetails) public Investors;
    mapping (address => bool) public isUserAdded;
    mapping (address => bool) public isBlackListed;
    mapping(address => uint256) public availableBalance; 
    mapping(address=>bool) public Inter;
    mapping(address=>bool ) public  Linear;
    mapping(address=>uint) public uintPerDay;


    uint[] public initialVestingAmountWithdrawThresholdTime;
    uint[] public intermediateVestingAmountWithdrawThresholdTime;
    uint[] public linearVestingAmountWithdrawThresholdTime;
    uint[] public initialAmountReleased=[0,0,50,100,200,0,0,0,0,30,200];
    uint[] public intermediateAmountReleased=[0,0,0,0,0,0,0,0,60,0,0];
    uint[] public linearVestingAmountReleased=[0,1000,950,900,800,1000,1000,1000,940,970,800]; // stores percentage
    uint[] public intermediateVestingTimePeriod=[0,0,0,0,0,0,0,0,1800,0,0];
    uint[] public linearVestingTimePeriod=[0,39600,32400,21900,10800,54000,65700,63000,43800,81000,28800];

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
             uintPerDay[vest[i].account]= vesting.linearToBeClaimed/(linearVestingTimePeriod[vest[i].investorType]/60);
            Investors[vest[i].account] = vesting;
            emit InvestorAddress(vest[i].account,_amount,vest[i].investorType);
        }
    }

      function getInvestorDetails(address _addr) public view returns(vestingDetails memory){
        return Investors[_addr];
    }
    function getContractTokenBalance() external view returns(uint){
        return token.balanceOf(address(this));
    }


    function withdraw() external{

          Inter[msg.sender]=true;
          
        require (isUserAdded[msg.sender],'User Not Added');
        require (!isBlackListed[msg.sender],'User BlackListed');
        require (!Investors[msg.sender].hasLinearClaimed,'Vesting: All Amount Claimed');


        if (initialAmountReleased[Investors[msg.sender].investorType] == 0 && intermediateAmountReleased[Investors[msg.sender].investorType] > 0 && Investors[msg.sender].intermediateClaimed == 0)
                 {
                     Investors[msg.sender].lastClaimTime = intermediateVestingAmountWithdrawThresholdTime[Investors[msg.sender].investorType];
                    // console.log('Inside if',Investors[msg.sender].lastClaimTime);
                 }
        else if (initialAmountReleased[Investors[msg.sender].investorType] == 0 && intermediateAmountReleased[Investors[msg.sender].investorType] == 0 && Investors[msg.sender].linearClaimed == 0 )
                {
                    Investors[msg.sender].lastClaimTime = linearVestingAmountWithdrawThresholdTime[Investors[msg.sender].investorType];
                  //  console.log('inside else if',Investors[msg.sender].lastClaimTime);
                }

        (uint amount, uint returnType) = getVestingBalance(msg.sender);
        require(returnType != 4,'Time Period is Not Over');
        if (returnType == 1) {
            require (amount >0,'Initial Vesting: 0 amount');
            Investors[msg.sender].hasInitialClaimed = true;
            Investors[msg.sender].initialClaimed += amount;
            token.transfer(msg.sender, amount);
            if (intermediateAmountReleased[Investors[msg.sender].investorType] > 0)
                Investors[msg.sender].lastClaimTime = intermediateVestingAmountWithdrawThresholdTime[Investors[msg.sender].investorType];
            else if (intermediateAmountReleased[Investors[msg.sender].investorType] == 0 )
                Investors[msg.sender].lastClaimTime = linearVestingAmountWithdrawThresholdTime[Investors[msg.sender].investorType];
                 availableBalance[msg.sender]-=amount;
            emit VestingAmountTaken(msg.sender, amount);
        } else if (returnType == 2) {
            require (amount >0,'Intermediate Vesting: 0 amount');
            Investors[msg.sender].lastClaimTime = block.timestamp;
            Investors[msg.sender].intermediateClaimed+=amount;
            
            require (Investors[msg.sender].intermediateToBeClaimed >= Investors[msg.sender].intermediateClaimed,'Intermediate Vesting: Cannot Claim More');
            if (Investors[msg.sender].intermediateToBeClaimed ==  Investors[msg.sender].intermediateClaimed)
            {
                Investors[msg.sender].hasIntermediateClaim = true;
                Investors[msg.sender].lastClaimTime = linearVestingAmountWithdrawThresholdTime[Investors[msg.sender].investorType];
            }
            token.transfer(msg.sender, amount);
            availableBalance[msg.sender]-=amount;
            emit VestingAmountTaken(msg.sender, amount);
        }
        else {
            require (amount >0,'Linear Vesting: 0 amount');
            Investors[msg.sender].lastClaimTime = block.timestamp;
            Investors[msg.sender].linearClaimed += amount;
            require (Investors[msg.sender].linearToBeClaimed >= Investors[msg.sender].linearClaimed,'Linear Besting: Cannot Claim More');
            if (Investors[msg.sender].linearToBeClaimed == Investors[msg.sender].linearClaimed)
            {
                Investors[msg.sender].hasLinearClaimed = true;
            }
            Linear[msg.sender]=true;
            token.transfer(msg.sender, amount);
          availableBalance[msg.sender]-=amount;
            emit VestingAmountTaken(msg.sender, amount);
        }
    }

    //@dev Contract Setters

    function setRewardTokenAddress (address _tokenAddress) external onlyOwner {
        token = IERC20(_tokenAddress);
    }
    
    function setDates (uint startTime) external onlyOwner {

        globalStartTime = startTime;
        linearStart8=startTime + 30 minutes;
        initialVestingAmountWithdrawThresholdTime = [0,startTime,startTime,startTime,startTime,startTime,startTime,startTime,startTime,startTime,startTime];
        intermediateVestingAmountWithdrawThresholdTime = [0,0,0,0,0,0,0,0,startTime + 1 minutes,0,0];
        linearVestingAmountWithdrawThresholdTime= [0,startTime+2 minutes,startTime + 1 minutes,startTime + 1 minutes,startTime + 1 minutes,startTime + 5 minutes,startTime + 10 minutes,startTime + 10 minutes,linearStart8 + 10 minutes, startTime + 15 minutes,startTime + 1 minutes];
//        setPauseStatus(false);
    }
   

    //@dev Get Details About Vesting Time Period
    function getVestingBalance(address _userAddress) public view returns (uint, uint) {
        if (!Investors[_userAddress].hasInitialClaimed &&
            block.timestamp >= initialVestingAmountWithdrawThresholdTime[Investors[_userAddress].investorType] &&
            Investors[_userAddress].initialToBeClaimed > 0) {return (Investors[_userAddress].initialToBeClaimed, 1);}
        else if (
            !Investors[_userAddress].hasIntermediateClaim &&
            Investors[_userAddress].intermediateToBeClaimed > 0 &&
            block.timestamp >= intermediateVestingAmountWithdrawThresholdTime[Investors[_userAddress].investorType]) {
            (uint balance,uint _bal) = intermediateVestStatus(_userAddress);
           // console.log('Balance',balance);
            return (balance,_bal);
        }
        else if (!Investors[_userAddress].hasLinearClaimed && Investors[_userAddress].linearToBeClaimed > 0 && block.timestamp >= linearVestingAmountWithdrawThresholdTime[Investors[_userAddress].investorType]) return (linearVestingDetails(_userAddress),3);
        else return (0,4);
    }

    function intermediateVestStatus(address _userAddress) public view returns (uint,uint) {
        uint lastClaimTime = Investors[_userAddress].lastClaimTime;
        uint timeDifference;
        uint[11] memory intermediateArray = [0,0,0,0,0,0,0,0,globalStartTime + 1 minutes,0,0];// give Intermediate time
        if (block.timestamp <= intermediateVestingTimePeriod[Investors[_userAddress].investorType]+intermediateArray[Investors[_userAddress].investorType])
        {
            if(!Inter[_userAddress]){
             timeDifference=block.timestamp-intermediateArray[Investors[_userAddress].investorType];
            }else{
             timeDifference = block.timestamp - lastClaimTime;
            }
            
        }
        else
        {
            //@dev to return people the exact amount if the intermediate vesting period is over
           return(Investors[_userAddress].intermediateToBeClaimed - Investors[_userAddress].intermediateClaimed,2);
        }

        timeDifference = timeDifference / 1 minutes;
        // console.log(timeDifference);

        uint intermediateReleaseTimeSpan = intermediateVestingTimePeriod[Investors[_userAddress].investorType];
        uint totalIntermediateFund = Investors[_userAddress].intermediateToBeClaimed;
        uint perDayFund = totalIntermediateFund / (intermediateReleaseTimeSpan / 1 minutes);
        uint price = perDayFund * timeDifference;
        return (price,2);
    }


    function linearVestingDetails(address _userAddress) public view returns (uint) {
        uint lastClaimTime = Investors[_userAddress].lastClaimTime;
        uint timeDifference;
        uint[11] memory linearTime = [0,globalStartTime+ 2 minutes,globalStartTime + 1 minutes,globalStartTime + 1 minutes,globalStartTime + 1 minutes,globalStartTime + 5 minutes/*5*/,globalStartTime + 10 minutes,globalStartTime + 10 minutes,linearStart8 + 10 minutes, globalStartTime + 15 minutes,globalStartTime + 1 minutes];
        if (block.timestamp <= linearVestingTimePeriod[Investors[_userAddress].investorType]+linearTime[Investors[_userAddress].investorType]) {
             if(!Linear[_userAddress]){

                    timeDifference=block.timestamp-linearTime[Investors[_userAddress].investorType];
             }else{
                 timeDifference = block.timestamp - lastClaimTime;
             }
        }
        else
        {
            //@dev to return people the exact amount if the intermediate vesting period is over
            return(Investors[_userAddress].linearToBeClaimed - Investors[_userAddress].linearClaimed);
        }

        timeDifference = timeDifference / 1 minutes;
        uint linearReleaseTimeSpan = linearVestingTimePeriod[Investors[_userAddress].investorType];
        uint totalIntermediateFund = Investors[_userAddress].linearToBeClaimed;
        uint perDayFund = totalIntermediateFund / (linearReleaseTimeSpan / 1 minutes);

        return perDayFund * timeDifference;
    }


    function getLinearVestEndTime(uint256 saletype) public view returns(uint){
        uint256 endDays=linearVestingAmountWithdrawThresholdTime[saletype]+linearVestingTimePeriod[saletype];
        return endDays;  
    }

    function blackListUser (address[] memory blackListedAddresses) external onlyOwner {
        for (uint i=0; i< blackListedAddresses.length; i++) {
            isBlackListed[blackListedAddresses[i]] = true;
        }
    }

    function whitelistListUser (address[] memory whitelistListedAddresses) external onlyOwner {
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
        for (uint i=0; i< usersToRemove.length; i++) {
             if (initialVestingAmountWithdrawThresholdTime[Investors[msg.sender].investorType] > 0)
                require (initialVestingAmountWithdrawThresholdTime[Investors[msg.sender].investorType] > block.timestamp,'Initial Vesting Has Started');
            if (intermediateVestingAmountWithdrawThresholdTime[Investors[msg.sender].investorType] > 0)
                require (intermediateVestingAmountWithdrawThresholdTime[Investors[msg.sender].investorType] > block.timestamp, 'Intermediate Vesting Has Started');
            if (linearVestingAmountWithdrawThresholdTime[Investors[msg.sender].investorType] > 0)
                require (linearVestingAmountWithdrawThresholdTime[Investors[msg.sender].investorType] > block.timestamp, 'Linear Vesting Has Started');
            isUserAdded[usersToRemove[i]] = false;
            delete Investors[usersToRemove[i]];
        }
    }

    function removeSingleUser(address _userAddress)public onlyOwner{
        require(Investors[_userAddress].investorType>0);
        delete Investors[_userAddress];
        isUserAdded[_userAddress]=false;
    }

}