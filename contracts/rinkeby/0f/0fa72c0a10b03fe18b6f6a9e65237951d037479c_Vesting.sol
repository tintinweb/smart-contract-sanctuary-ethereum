/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

/**
 *Submitted for verification at BscScan.com on 2022-03-15
*/

/**
 *Submitted for verification at BscScan.com on 2022-03-15
*/

/**
 *Submitted for verification at BscScan.com on 2022-03-14
*/

/**
 *Submitted for verification at BscScan.com on 2022-03-14
*/

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IBEP20 {
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

contract Vesting {

    IBEP20 public token;

    address public owner;
    uint public startDate;
    bool public isStart;

    uint day = 1 minutes;
    uint day1 = 2 minutes;

    event TokenWithdraw(address indexed buyer, uint value);
      event RecoverToken(address indexed token, uint256 indexed amount);

    mapping(address => InvestorDetails) public Investors;

    modifier onlyOwner {
        require(msg.sender == owner, 'Owner only function');
        _;
    }
   modifier setDate{
        require(isStart == true,"wait for start date");
        _;
    }

    uint public seedStartDate;
    uint public privateStartDate;
    uint public StrategyStartDate;
    uint public publicStartDate;
    uint public launchStartDate;

    uint public nextPayDate;

    uint public seedLockEndDate;
    uint public privateLockEndDate;
    uint public StrategyLockEndDate;
    uint public publicLockDate;
    uint public launchLockDate;

    uint public seedVestingEndDate;
    uint public privateVestingEndDate;
    uint public StrategyVestingEndDate;
    uint public publicVestingEndDate;
    uint public launchVestingEndDate;


    uint public seedNextPay;
     
   
    receive() external payable {
    }
   
       
      constructor(address _tokenAddress) {
        require(_tokenAddress != address(0));
        token = IBEP20(_tokenAddress);
        owner = msg.sender; 
    }
    
    
    /* Withdraw the contract's BNB balance to owner wallet*/
    function extractBNB() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function getInvestorDetails(address _addr) public view returns(InvestorDetails memory){
        return Investors[_addr];
    }

    
    function getContractTokenBalance() public view returns(uint) {
        return token.balanceOf(address(this));
    }
    


    /* Utility function for testing. The token address used in this ICO contract can be changed. */
    function setTokenAddress(address _addr) public onlyOwner {
        token = IBEP20(_addr);
    }

   

    struct Investor {
        address account;
        uint amount;
        uint8 saleType;
    }

    struct InvestorDetails {
        uint totalBalance;
        uint timeDifference;
        uint lastVestedTime;
        uint reminingUnitsToVest;
        uint tokensPerUnit;
        uint vestingBalance;
        uint investorType;
        uint initialAmount;
        uint nextAmount;
        bool isInitialAmountClaimed;
    }


    function addInvestorDetails(Investor[] memory investorArray) public onlyOwner {
        require(investorArray.length <= 25, "Array length exceeding 25, You might probably run out of gas");
        for(uint16 i = 0; i < investorArray.length; i++) {
            InvestorDetails memory investor;
            uint8 saleType = investorArray[i].saleType;
            investor.totalBalance = (investorArray[i].amount)*(10 ** 18);
            investor.investorType = investorArray[i].saleType;
            investor.vestingBalance = investor.totalBalance;

            if(saleType == 1) {
                investor.reminingUnitsToVest = 365;
                investor.nextAmount = (investor.totalBalance)*(4)/100;
                investor.initialAmount = (investor.totalBalance)*(4)/100;
                investor.tokensPerUnit = ((investor.totalBalance) - (investor.initialAmount) -(investor.nextAmount))/365;
            }

            if(saleType == 2) {
                investor.reminingUnitsToVest = 300;
                investor.nextAmount = (investor.totalBalance) *(7)/100;
                investor.initialAmount = (investor.totalBalance)*(7)/100;
                investor.tokensPerUnit = ((investor.totalBalance) - (investor.initialAmount) -(investor.nextAmount))/300;
            }

            if(saleType == 3) {
                investor.reminingUnitsToVest = 240;
                investor.nextAmount = (investor.totalBalance)*(10)/100;
                investor.initialAmount = (investor.totalBalance) *(10)/100;
                investor.tokensPerUnit = ((investor.totalBalance) - (investor.initialAmount) -(investor.nextAmount))/240;
            }
             if(saleType == 4) {//public
               investor.reminingUnitsToVest = 4;
                investor.initialAmount = (investor.totalBalance)*(20)/100;
                investor.tokensPerUnit = ((investor.totalBalance) - (investor.initialAmount))/4;
                }
        
            if(saleType == 5){
                investor.reminingUnitsToVest = 4;
                investor.initialAmount = (investor.totalBalance)*(0)/100;
                investor.tokensPerUnit =  ((investor.totalBalance) - (investor.initialAmount))/4;
            }


            Investors[investorArray[i].account] = investor; 
        }
    }

    
   
    
    uint[6] public lockDates = [0,seedLockEndDate,privateLockEndDate,StrategyLockEndDate,publicLockDate,launchLockDate];
    uint[6] public dates = [0,day,day,day,day1,day1];
    uint public activeLockDate;

    function withdrawTokens() public  setDate {
        require(isStart= true,"wait for start date");

        if(Investors[msg.sender].isInitialAmountClaimed) {
            require(block.timestamp>=lockDates[Investors[msg.sender].investorType],"wait until lock period to complete");
            activeLockDate = lockDates[Investors[msg.sender].investorType] ;
        
            // console.log(activeLockDate);
            // console.log(lockDates[Investors[msg.sender].investorType]);
            /* Time difference to calculate the interval between now and last vested time. */
            uint timeDifference;
            if(Investors[msg.sender].lastVestedTime == 0) {
                require(activeLockDate > 0, "Active lockdate was zero");
                timeDifference = (block.timestamp) - (activeLockDate);
            } else {
                timeDifference = block.timestamp  - (Investors[msg.sender].lastVestedTime);
            }



            uint numberOfUnitsCanBeVested =dates[Investors[msg.sender].investorType];
            
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
           // Investors[msg.sender].tokensPerUnit =  Investors[msg.sender].vestingBalance.sub(Investors[msg.sender].initialAmount).div(10);
            uint tokenToTransfer = numberOfUnitsCanBeVested * Investors[msg.sender].tokensPerUnit;
            uint reminingUnits = Investors[msg.sender].reminingUnitsToVest;
            uint balance = Investors[msg.sender].vestingBalance;
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
           if(block.timestamp> seedNextPay){
               if( Investors[msg.sender].isInitialAmountClaimed){
                 Investors[msg.sender].vestingBalance -= Investors[msg.sender].nextAmount;
            Investors[msg.sender].isInitialAmountClaimed = true;
            uint amount = Investors[msg.sender].nextAmount;
            token.transfer(msg.sender, amount);
            emit TokenWithdraw(msg.sender, amount);
               }else{
            Investors[msg.sender].vestingBalance -= Investors[msg.sender].nextAmount + Investors[msg.sender].initialAmount ;
            Investors[msg.sender].isInitialAmountClaimed = true;
            uint amount = Investors[msg.sender].nextAmount +Investors[msg.sender].initialAmount ;
            token.transfer(msg.sender, amount);
            emit TokenWithdraw(msg.sender, amount); 
          }
           }
                else{
          require(!Investors[msg.sender].isInitialAmountClaimed, "Amount already withdrawn!");
          require(block.timestamp > seedStartDate," Wait Until the Start Date");
           if(Investors[msg.sender].investorType == 4 || Investors[msg.sender].investorType == 5 ){
              Investors[msg.sender].isInitialAmountClaimed = true;  
           }

           if(Investors[msg.sender].investorType == 5){
             Investors[msg.sender].isInitialAmountClaimed = true;  
           }else{
           require(Investors[msg.sender].initialAmount >0,"wait for next vest time ");}

            uint amount = Investors[msg.sender].initialAmount;
            Investors[msg.sender].vestingBalance -= Investors[msg.sender].initialAmount;
            Investors[msg.sender].initialAmount = 0 ; 
            token.transfer(msg.sender, amount);
            emit TokenWithdraw(msg.sender, amount);
          
                }
            }
            
        
    }
    function setStartDates( uint  _setStartDate ,bool _setDatee) public onlyOwner{
        isStart = _setDatee;
       seedStartDate = _setStartDate;
        privateStartDate = _setStartDate;
        StrategyStartDate = _setStartDate;
        publicStartDate = _setStartDate;
        launchStartDate = _setStartDate;

        seedNextPay =  seedStartDate  + 1 minutes;

        seedLockEndDate = seedNextPay  +  1 minutes;
        privateLockEndDate = seedNextPay + 5 minutes;
        StrategyLockEndDate = seedNextPay +  5 minutes;

        publicLockDate = publicStartDate ;
        launchLockDate = launchStartDate ;

        seedVestingEndDate = seedLockEndDate +  365 minutes;
        privateVestingEndDate = privateLockEndDate + 300 minutes;
        StrategyVestingEndDate = StrategyLockEndDate + 240 minutes;

        publicVestingEndDate = publicLockDate +  10 minutes;
        launchVestingEndDate = launchLockDate + 10 minutes;  

    }
    function setDay(uint _value) public onlyOwner {
        day = _value;
    }
  
    function transferOwnership(address _setOwner) public onlyOwner{
        owner= _setOwner;
    }

     function depositToken(uint amount) public onlyOwner {
        token.transferFrom(msg.sender, address(this), amount);
    }

     function recoverTokens(address _token, uint256 amount) public onlyOwner {
        IBEP20(_token).transfer(msg.sender, amount);
        emit RecoverToken(_token, amount);

    }
  
 
}