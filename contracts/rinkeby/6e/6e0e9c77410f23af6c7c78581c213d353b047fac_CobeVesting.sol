/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

/**
 *Submitted for verification at BscScan.com on 2022-06-08
*/

/**
 *Submitted for verification at BscScan.com on 2022-05-20
*/

/**
 *Submitted for verification at BscScan.com on 2022-05-19
*/

/**
 *Submitted for verification at BscScan.com on 2022-05-17
*/

pragma solidity ^0.8.13;
// import "hardhat/console.sol";

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
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



pragma solidity ^0.8.0;

contract CobeVesting is Ownable,ReentrancyGuard {

    IERC20 public token;

    uint256 public activeLockDate;
    bool isremoved;
    // mapping(address=>bool) public isStart;
    mapping(address=>mapping(uint=>bool)) public isSameInvestor;


    uint256 day = 60;
    // uint day1= 3 minutes ;

    // modifier setStart{
    //     require(isStart==true,"wait for start");
    //     _;
    // }
    uint[4] public startDates=[0,seedStartDate,privateStartDate,publicStartDate];
    uint[4] public lockEnd=[0,seedLockEndDate,privateLockEndDate,publicLockEndDate];
    // uint[4] public vestEnd=[];

    event TokenWithdraw(address indexed buyer, uint value);
    event InvestersAddress(address accoutt, uint _amout,uint saletype,uint starttime);

    mapping(address => InvestorDetails) public Investors;
    mapping(address=>timings) public InvestorTime;
    mapping(address=>bool) public isStarted;

  

    uint256  seedStartDate;
    uint256  privateStartDate;
    uint256 public publicStartDate;

    uint256  seedLockEndDate;
    uint256  privateLockEndDate;
    uint256 public publicLockEndDate;

    uint256 public seedVestingEndDate;
    uint256 public privateVestingEndDate;
    uint256 public publicVestingEndDate;
   
    receive() external payable {
    }
   
    constructor() {
    }

    
    /* Withdraw the contract's BNB balance to owner wallet*/
    function extractBNB() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function getInvestorDetails(address _addr) public view returns(InvestorDetails memory){
        return Investors[_addr];
    }

    
    function getContractTokenBalance() public view returns(uint256) {
        return token.balanceOf(address(this));
    }

    
    
    /* 
        Transfer the remining token to different wallet. 
        Once the ICO is completed and if there is any remining tokens it can be transfered other wallets.
    */
    function transferToken(address _addr, uint256 value) public onlyOwner {
        require(value <= token.balanceOf(address(this)), 'Insufficient balance to withdraw');
        token.transfer(_addr, value);
    }

    /* Utility function for testing. The token address used in this ICO contract can be changed. */
    function setTokenAddress(address _addr) public onlyOwner {
        token = IERC20(_addr);
    }


    struct Investor {
        address account;
        uint256 amount;
        uint8 saleType;
        uint256 starttime;
    }
    struct timings{
        uint256 startTime;
        uint256 LockEndTime;
        uint256 VestingEndTime;
    }

    struct InvestorDetails {
        uint256 totalBalance;
        uint256 timeDifference;
        uint256 lastVestedTime;
        uint256 starttime;
        uint256 reminingUnitsToVest;
        uint256 tokensPerUnit;
        uint256 vestingBalance;
        uint256 investorType;
        uint256 initialAmount;
        bool isInitialAmountClaimed;
    }


    function addInvestorDetails(Investor[] memory investorArray) public onlyOwner {
        for(uint16 i = 0; i < investorArray.length; i++) {
         if(isremoved){
                 isSameInvestor[investorArray[i].account][investorArray[i].saleType]=true;
                 isremoved=false;
            }else{  
                require(!isSameInvestor[investorArray[i].account][investorArray[i].saleType],"Investor Exist");
                isSameInvestor[investorArray[i].account][investorArray[i].saleType]=true;
            }

             uint8 saleType = investorArray[i].saleType;
            InvestorDetails memory investor;
            investor.totalBalance = (investorArray[i].amount) * (10 ** 18);
            investor.investorType = investorArray[i].saleType;
            investor.vestingBalance = investor.totalBalance;
            investor.starttime = investorArray[i].starttime;
            timings memory users;
         
          

            if(saleType == 1) {
                investor.reminingUnitsToVest = 300;
                investor.initialAmount = (investor.totalBalance * 5)/(100);
                investor.tokensPerUnit = ((investor.totalBalance) - (investor.initialAmount))/(300);
                users.startTime =investor.starttime;
                users.LockEndTime =  users.startTime +  2 minutes;
                users.VestingEndTime =  users.LockEndTime + 300 minutes;
               

            }
    

            if(saleType == 2) {
                investor.reminingUnitsToVest = 300;
                investor.initialAmount = (investor.totalBalance * 5)/(100);
                investor.tokensPerUnit = ((investor.totalBalance) - (investor.initialAmount))/(300);
                users.startTime =investor.starttime;
                users.LockEndTime = users.startTime + 2 minutes;
                users.VestingEndTime =   users.LockEndTime  + 300 minutes;  
            }

            if(saleType == 3) {
                investor.reminingUnitsToVest = 120;
                investor.initialAmount = (investor.totalBalance * 5)/(100);
                investor.tokensPerUnit = ((investor.totalBalance)-(investor.initialAmount))/(120); 
                  users.startTime=investor.starttime;
                  users.LockEndTime= users.startTime+ 2  minutes;
                  users.VestingEndTime = users.LockEndTime +120 minutes;
            }
            isStarted[investorArray[i].account]=true;

              InvestorTime[investorArray[i].account]=users;
                
            Investors[investorArray[i].account] = investor; 
            emit InvestersAddress(investorArray[i].account,investorArray[i].amount, investorArray[i].saleType, investorArray[i].starttime);
        }
    }

    function withdrawTokens() public   nonReentrant  {
        lockEnd=[0,seedLockEndDate,privateLockEndDate,publicLockEndDate];
        // InvestorTime[msg.sender].LockEndTime
        require(Investors[msg.sender].investorType >0,"Investor Not Found");
        if(Investors[msg.sender].isInitialAmountClaimed) {
        activeLockDate=lockEnd[Investors[msg.sender].investorType];
           require(block.timestamp>InvestorTime[msg.sender].LockEndTime,"wait until lockData complete");

            /* Time difference to calculate the interval between now and last vested time. */
            uint256 timeDifference;
            if(Investors[msg.sender].lastVestedTime == 0) {
                require(InvestorTime[msg.sender].LockEndTime > 0, "Active lockdate was zero");
                timeDifference = (block.timestamp) - (InvestorTime[msg.sender].LockEndTime);
            } else {
                timeDifference = (block.timestamp) -(Investors[msg.sender].lastVestedTime);
            }
            
            /* Number of units that can be vested between the time interval */
            uint256 numberOfUnitsCanBeVested = (timeDifference)/(day);
            
            /* Remining units to vest should be greater than 0 */
            require(Investors[msg.sender].reminingUnitsToVest > 0, "All units vested!");
            
            /* Number of units can be vested should be more than 0 */
            require(numberOfUnitsCanBeVested > 0, "Please wait till next vesting period!");

            if(numberOfUnitsCanBeVested >= Investors[msg.sender].reminingUnitsToVest) {
                numberOfUnitsCanBeVested = Investors[msg.sender].reminingUnitsToVest;
            }
            
            /*
                1. Calculate number of tokens to transfer
                2. Update the investor details
                3. Transfer the tokens to the wallet
            */
            uint256 tokenToTransfer = numberOfUnitsCanBeVested * Investors[msg.sender].tokensPerUnit;
            uint256 reminingUnits = Investors[msg.sender].reminingUnitsToVest;
            uint256 balance = Investors[msg.sender].vestingBalance;
            Investors[msg.sender].reminingUnitsToVest -= numberOfUnitsCanBeVested;
            Investors[msg.sender].vestingBalance -= numberOfUnitsCanBeVested * Investors[msg.sender].tokensPerUnit;
            Investors[msg.sender].lastVestedTime = block.timestamp;
            if(numberOfUnitsCanBeVested == reminingUnits) { 
                token.transfer(msg.sender, balance);
                emit TokenWithdraw(msg.sender, balance);
            } else {
                token.transfer(msg.sender, tokenToTransfer);
                emit TokenWithdraw(msg.sender, tokenToTransfer);
            }  
        }
        else {
            require(!Investors[msg.sender].isInitialAmountClaimed, "Amount already withdrawn!");
             startDates=[0,seedStartDate,privateStartDate,publicStartDate];
             require(block.timestamp>InvestorTime[msg.sender].startTime," wait for start date");
             uint amount=allAmounts(msg.sender);
             Investors[msg.sender].vestingBalance -= Investors[msg.sender].initialAmount;
              Investors[msg.sender].isInitialAmountClaimed = true;

             if(Investors[msg.sender].investorType == 1){
            token.transfer(msg.sender, amount);
             }else if(Investors[msg.sender].investorType == 2){
            token.transfer(msg.sender, amount);
             }else{
             token.transfer(msg.sender,amount);
             }
                emit TokenWithdraw(msg.sender, amount);
        }
    }

    function allAmounts(address _addr) public view returns(uint){
            Investors[_addr].vestingBalance == (Investors[_addr].vestingBalance)-Investors[_addr].initialAmount;
            uint256 amount = Investors[msg.sender].initialAmount;
            Investors[msg.sender].initialAmount ==0;
          return amount;
    }
    

    function setDay(uint256 _value) public onlyOwner {
        day = _value;
    }
    // function setvestingdays(uint256 _vestingdays) external onlyOwner{
    //     day = _vestingdays;
    // }
   function removeSingleInvestor(address  _addr) public onlyOwner{
        isremoved=true;
        require(block.timestamp<InvestorTime[_addr].startTime,"Vesting Started , Unable to Remove Investor");
        require(Investors[_addr].investorType >0,"Investor Not Found");
            delete Investors[_addr];
  }
  
    function removeMultipleInvestors(address[] memory _addr) external onlyOwner{
        for(uint i=0;i<_addr.length;i++){
            removeSingleInvestor(_addr[i]);
        }
    }


    function getAvailableBalance(address _addr) public view returns(uint256, uint256, uint256){
           if(Investors[_addr].isInitialAmountClaimed){
          
            uint hello= day;
            uint timeDifference;
            if(Investors[_addr].lastVestedTime == 0) {
                if(block.timestamp>=InvestorTime[_addr].VestingEndTime)return(Investors[_addr].tokensPerUnit* Investors[_addr].reminingUnitsToVest,0,0);
                if(block.timestamp<InvestorTime[_addr].LockEndTime) return(0,0,0);
            if(InvestorTime[_addr].LockEndTime + day> 0)return (((block.timestamp-InvestorTime[_addr].LockEndTime)/day) *Investors[_addr].tokensPerUnit,0,0);//, "Active lockdate was zero");
            timeDifference = (block.timestamp) -(InvestorTime[_addr].LockEndTime);
            }
           
            else { 
        timeDifference = (block.timestamp)-(Investors[_addr].lastVestedTime);}
            uint numberOfUnitsCanBeVested;
            uint tokenToTransfer ;
            numberOfUnitsCanBeVested = (timeDifference)/(hello);
            if(numberOfUnitsCanBeVested >= Investors[_addr].reminingUnitsToVest) {
                numberOfUnitsCanBeVested = Investors[_addr].reminingUnitsToVest;}
            tokenToTransfer = numberOfUnitsCanBeVested * Investors[_addr].tokensPerUnit;
            uint reminingUnits = Investors[_addr].reminingUnitsToVest;
            uint balance = Investors[_addr].vestingBalance;
                    if(numberOfUnitsCanBeVested == reminingUnits) return(balance,0,0) ;  
                    else return(tokenToTransfer,reminingUnits,balance); }
        else {
            if(!isStarted[_addr])return(0,0,0);
            if(block.timestamp<InvestorTime[_addr].startTime)return(0,0,0);
              if(Investors[_addr].investorType==1){
                    Investors[_addr].initialAmount == 0 ;
            return (Investors[_addr].initialAmount,0,0);}

            else if(Investors[_addr].investorType==2){
                    Investors[_addr].initialAmount == 0 ;
            return (Investors[_addr].initialAmount,0,0);
            }else{
                    Investors[_addr].initialAmount == 0 ;
                  return (Investors[_addr].initialAmount,0,0);
            }
        }
    }

   

    function depositTokens(uint256 _amount) external onlyOwner{
        require(_amount>0,"Amount should be greater than 0 ");
      token.transferFrom( msg.sender, address(this), _amount);
    }
}