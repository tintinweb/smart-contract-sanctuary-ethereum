/**
 *Submitted for verification at Etherscan.io on 2022-04-10
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.2; 

//LIBS
/////////////////////////////////////////
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
/////////////////////////////////////////

/*
*   Token Contract ERC20 Standard
*/
contract NFM {

    //USING LIBS
    /////////////////////////////////////////
    using SafeMath for uint256;
    /////////////////////////////////////////

    //Important Mappings of this Token
    /////////////////////////////////////////
    //Account Mappings
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowances;
    //Emission Mappings
    mapping(address => mapping(address => uint)) public emitings;
    //PAD Mappings
    mapping(address => uint) public PADprotection;
    mapping(address => uint) public PADtimePointer;
    mapping(address => bool) public PADWhitelisting;
    //Burning Mappings
    mapping(address => mapping(address => uint)) public burneds;
    /////////////////////////////////////////

    //Important Events for this Token
    /////////////////////////////////////////
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Paused(address account);
    event Unpaused(address account);
    event Emission(uint256 indexed time, address indexed from, address indexed to, uint value);
    event Burnings(address indexed from, address indexed to, uint value);
    event BonusPayments(address indexed from, address indexed to, uint value, string paymentType);
    /////////////////////////////////////////

    //TOKEN RELATED VARIABLES
    /////////////////////////////////////////
    string private Tokenname = "NFTISMUS";
    string private Tokensymbol = "NFM";
    uint private Tokendecimals = 18;
    uint256 private TotalSupply=0;
    //SC Address
    address private executer;
    //Contract OwnerAddress
    address private contractowner;
    uint256 private issuingStamp;
    bool private _paused;
    uint256 private dailyStamp;    

    //EMISSION RELATED VARIABLES
    uint256[] private emissionsDaily= [2037037.037027770*10**18, 2659259.259250000*10**18, 2731481.481472220*10**18, 2803703.703694440*10**18, 2875925.925916660*10**18, 2948148.148138880*10**18, 2094444.444444440*10**18, 2961111.111166660*10**18];
    uint256[] private emissionsYearly= [733333333.33*10**18, 957333333.33*10**18, 983333333.33*10**18, 1009333333.33*10**18, 1035333333.33*10**18, 1061333333.33*10**18, 754000000*10**18, 1066000000.02*10**18 ];
    uint256[] private yearstamps;
    uint256 private TotalEmissionAmount=0;
    uint256 private YearlyEmissionAmount=0;    
    uint256 private emissionTotalCounter=0;
    uint256 private DailyEmissionCount=0;
    uint256 private MonthlyEmissionCount=1;
    
    //BURNING RELATED VARIABLES
    uint256 private startBurningTimer;
    uint256 private burningFee;
    uint256 public burnCounter=0;
    uint256 private DailyTransactionCounter=0;
    uint256 private TotalAutomaticBurnAmount=0;
    uint256 private immutable FinalTotalSupply=1000000000*10**18;

    //BONUS PAYMENTS
    uint256 private mintingBonusTransfer=10*10**18;
    uint256 private mintingBonusNft=10*10**18;
    uint256 private dailyBNFTAmount=0;
    uint256 private totalBonusTransferPaid=0;
    uint256 private totalBonusNftPaid=0;

    //PUMP AND DUMP 
    uint256 public immutable maxDailyTradeVolume = 1000000*10**18;
    uint256 public immutable maxDailyTradeVolumeWL = 1500000*10**18;
    uint256 public immutable WLFee = 10000*10**18;
    /////////////////////////////////////////

    //Hardcoded Distribution SC Addresses
    /////////////////////////////////////////
    address[] private distributions; 
    /////////////////////////////////////////


    //Constructor Methode
    //Will initialise the necessary Variables
    /////////////////////////////////////////
    constructor() {
        //Store Contract Address
        executer=address(this);
        //Store contract owner
        contractowner=msg.sender;
        //Store timestamp for next Daily Emission 
        dailyStamp=block.timestamp+(3600*24); 
        issuingStamp=block.timestamp;
        
        //Create Balances initial Amount
        balances[contractowner] = 400000000*10**Tokendecimals;
        TotalSupply+=400000000*10**Tokendecimals;
        //Create Transfer Event of first Emission
        emit Transfer(address(0), contractowner, 400000000*10**Tokendecimals);
        //Initialise Paused Variable
        _paused = false;      
    }
    /////////////////////////////////////////


    //View Functions of the Details like Name, Symbol, Decimal, 
    //BalanceOf, TotalSupply, Allowances
    /////////////////////////////////////////
    function name() public view returns (string memory) {
        return Tokenname;
    }
    function symbol() public view returns (string memory) {
        return Tokensymbol;
    }
    function decimals() public view returns (uint256) {
        return Tokendecimals;
    }
    function totalSupply() public view returns (uint256) {
        return TotalSupply;
    }
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
    function emissionTimes() public view returns (uint256) {
        return emissionTotalCounter;
    }
    function burningTimes() public view returns (uint256) {
        return burnCounter;
    }
    function totalemissionAmount() public view returns (uint256) {
        return TotalEmissionAmount;
    }
    function _startBurningTimer() public view returns (uint256) {
        return startBurningTimer;
    }
    function issuingTime() public view returns (uint256) {
        return issuingStamp;
    }
    function dayTransactionCounter() public view returns (uint256) {
        return DailyTransactionCounter;
    }
    function automaticBurnAmount() public view returns (uint256) {
        return TotalAutomaticBurnAmount;
    }    
    function paused() public view virtual returns (bool) {
        return _paused;
    } 
    function _DailyEmissionCount() public view virtual returns (uint) {
        return DailyEmissionCount;
    }
    function _MonthlyEmissionCount() public view virtual returns (uint) {
        return MonthlyEmissionCount;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowances[owner][spender];
    }
    function _PDAOpenValue() public view returns (uint256){ 
            uint256 remainingValue;       
           if(PADWhitelisting[msg.sender] == true && PADtimePointer[msg.sender] > block.timestamp){
                remainingValue = SafeMath.sub(maxDailyTradeVolumeWL, PADprotection[msg.sender]);
                return remainingValue;
            }else if(PADWhitelisting[msg.sender] == false && PADtimePointer[msg.sender] > 0){
                remainingValue = SafeMath.sub(maxDailyTradeVolume, PADprotection[msg.sender]);
                return remainingValue;
            }else{
                remainingValue = maxDailyTradeVolume;
                return remainingValue;
            }       
    }
    /////////////////////////////////////////

    //Modifiers
    /////////////////////////////////////////
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }
    /////////////////////////////////////////


    //Action Functions 
    /////////////////////////////////////////
    
    //1-)
    //Transfer Function
    ///////////////////////////////////////
    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    //2-)
    //TransferFrom Function
    ///////////////////////////////////////
    function transferFrom(address from, address to, uint amount) public returns(bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    ///////////////////////////////////////

    //3-)
    //_transfer Function
    ///////////////////////////////////////
    function _transfer(address from,address to,uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_paused == false, "Contract is paused");

        //PUMP AND DUMP PROTECTION
        uint256 PADvalue=PADprotection[from]+amount;
        
        if(from == executer || from == contractowner){
            
        }else{  
            //PAD PROTECTION
            if(PADWhitelisting[from] == true && PADtimePointer[from] > block.timestamp){
                //Require Pump and Dump Protection
                require(_PDAWCheck(from,PADvalue) == true, "You reached the Daily Limit of 1.5 Million NFM");
                require(PADvalue <= maxDailyTradeVolumeWL, "Pump and Dump Security: your Amount exceeds daily Limit of 1.5 Million NFM");
                PADprotection[from] += amount;
            }else{
                //Require Pump and Dump Protection
                require(_PDACheck(from,PADvalue) == true, "You reached the Daily Limit of 1 Million NFM");
                require(PADvalue <= maxDailyTradeVolume, "Pump and Dump Security: your Amount exceeds daily Limit of 1 Million NFM");
                PADprotection[from] += amount;
            }
            
        }   
           
        uint256 fromBalance = balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            balances[from] = SafeMath.sub(fromBalance,amount);
        }
        //If Emission needs to be produced
        if(_emissionCheck()==true){
            _issueNewCoins();
            balances[from] += mintingBonusTransfer;
            emit Transfer(executer, from, mintingBonusTransfer);
            totalBonusTransferPaid += mintingBonusTransfer;
            //Calculate Fee on last day Transaction volume
            //burningFee = SafeMath.div((SafeMath.div((amount),100)),2);
            //dailyStamp=block.timestamp+(3600*24);
            dailyStamp=block.timestamp+(600);
            DailyTransactionCounter=0;
            //burningFee = SafeMath.div((SafeMath.div((amount),100)),2);
        }        
        balances[to] += amount;
        emit Transfer(from, to, amount);
        DailyTransactionCounter++;
    }
    ///////////////////////////////////////

    //4-)
    //_spendAllowance Function
    ///////////////////////////////////////
    function _spendAllowance(address owner,address spender,uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, SafeMath.sub(currentAllowance, amount));
            }
        }
    }
    ///////////////////////////////////////

    //-5)
    //_approve Function
    ///////////////////////////////////////
    function _approve(address owner,address spender,uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(_paused == false, "Contract is paused");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    ///////////////////////////////////////

    //-6)
    //approve Function
    ///////////////////////////////////////
    function approve(address spender, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }
    ///////////////////////////////////////

    //-7)
    //Increase Allowance
    ///////////////////////////////////////
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, SafeMath.add(allowance(owner, spender), addedValue));
        return true;
    }
    ///////////////////////////////////////

    //-8)
    //Decrease Allowance
    ///////////////////////////////////////
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, SafeMath.sub(currentAllowance, subtractedValue));
        }

        return true;
    }
    ///////////////////////////////////////

    //-9)
    //Mining Function
    ///////////////////////////////////////
    function _mint(uint256 amount) internal virtual {
        require(msg.sender != address(0), "ERC20: burn from the zero address");
        require(dailyStamp <= block.timestamp, "Its not Time yet");
        require(_paused == false, "Contract is paused");
        TotalSupply += amount;
        TotalEmissionAmount += amount;
        balances[executer] += amount;        
        emitings[address(0)][executer] += amount;
        emit Transfer(address(0), executer, amount);
        emit Emission(emissionTotalCounter, address(0), executer, amount);
        emissionTotalCounter++;
        
    }
    ///////////////////////////////////////

    //-10)
    //Burning Function
    ///////////////////////////////////////
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        require(account == executer || account == contractowner, "Only Owner can call");
        require(_paused == false, "Contract is paused");
        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            balances[account] = SafeMath.sub(accountBalance, amount);
        }
        TotalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
    ///////////////////////////////////////

    //-11)
    //Pausing Function
    ///////////////////////////////////////
    function _pause() public whenNotPaused {
        address callerfunc = msg.sender;
        require(callerfunc == contractowner, "Only Owner can call");
        _paused = true;
        emit Paused(callerfunc);
    }
    ///////////////////////////////////////

    //-12)
    //Unlock Pausing Function
    ///////////////////////////////////////
    function _unpause() public whenPaused {
        address callerfunc = msg.sender;
        require(callerfunc == contractowner, "Only Owner can call");
        _paused = false;
        emit Unpaused(callerfunc);
    }
    ///////////////////////////////////////

    //-13)
    //Initialise SC Contract Logic Function
    ///////////////////////////////////////
    function initialiseLogic() public virtual returns (bool){
        address callerfunc = msg.sender;
        require(callerfunc == contractowner, "Only Owner can call");
        //Store timestamp for next Daily Emission
        //dailyStamp=block.timestamp+(3600*24); 
        dailyStamp=block.timestamp+(600); 
        issuingStamp=block.timestamp;
        startBurningTimer=issuingStamp+(3600*24*30*12*4);
        yearstamps= [block.timestamp+(1*3600*24*30*12)+600, block.timestamp+(2*3600*24*30*12)+600, block.timestamp+(3*3600*24*30*12)+600, block.timestamp+(4*3600*24*30*12)+600, block.timestamp+(5*3600*24*30*12)+600, block.timestamp+(6*3600*24*30*12)+600, block.timestamp+(7*3600*24*30*12)+600, block.timestamp+(8*3600*24*30*12)+600,block.timestamp+(9*3600*24*30*12)+600,block.timestamp+(10*3600*24*30*12)+600,block.timestamp+(11*3600*24*30*12)+600, block.timestamp+(12*3600*24*30*12)+600];
        return true;
    }
    ///////////////////////////////////////

    //14-)
    //_emissionCheck Function
    ///////////////////////////////////////
    function _emissionCheck() internal virtual returns (bool) {
        require(_paused == false, "Contract is paused");

        //If Emission needs to be produced
        if(dailyStamp <= block.timestamp){
            return true;
        }

        return false;
    }
    ///////////////////////////////////////

    //-15)
    //TransferBonusEmission Function
    ///////////////////////////////////////
    function _issueNewCoins() internal virtual returns (bool){
        //Require that dailyStamp smaller or equal Block Timestamp
        require(dailyStamp <= block.timestamp, "Its not Time yet");
        
        bool Cpointing=(_emissionPointer() > 7) ? false : true;
        //Check if Emission time is over
        if(Cpointing==true){
        //Substract NFTBonuses from Daily emited NFT
        uint256 amount=SafeMath.sub(emissionsDaily[_emissionPointer()], dailyBNFTAmount);
        
        
        if(block.timestamp > yearstamps[7]){
        
        }else{
           if(MonthlyEmissionCount == 11 && DailyEmissionCount == 29){
                //Create Mathematics 
                uint256 namount= SafeMath.add(amount, YearlyEmissionAmount);
                
                namount = SafeMath.sub(emissionsYearly[_emissionPointer()], namount);               
                amount = SafeMath.add(amount, namount);
                  
                DailyEmissionCount++;
                YearlyEmissionAmount += amount;
                _mint(amount);             
            }else{ 
                if(DailyEmissionCount == 30){
                    DailyEmissionCount = 1;
                    if(MonthlyEmissionCount==11){
                        MonthlyEmissionCount = 1;
                        YearlyEmissionAmount =0;
                    }else{
                        MonthlyEmissionCount++;
                        
                    }
                    YearlyEmissionAmount += amount;
                }else{
                    DailyEmissionCount++;
                }
                
                _mint(amount);
            }
        }                  
        } 
       return true;
    }
    ///////////////////////////////////////

    //-16)
    //GET EMISSION POINTER Function
    ///////////////////////////////////////
    function _emissionPointer() internal virtual returns (uint256){
        //Require that dailyStamp smaller or equal Block Timestamp
        require(dailyStamp <= block.timestamp, "Its not Time yet");
        
        uint pointing;
        //Check Emission Amount
        if(block.timestamp <= yearstamps[0]){
            pointing=0;
        }else if(block.timestamp <= yearstamps[1]){
            pointing=1;
        }else if(block.timestamp <= yearstamps[2]){
            pointing=2;
        }else if(block.timestamp <= yearstamps[3]){
            pointing=3;
        }else if(block.timestamp <= yearstamps[4]){
            pointing=4;
        }else if(block.timestamp <= yearstamps[5]){
            pointing=5;
        }else if(block.timestamp <= yearstamps[6]){
            pointing=6;
        }else if(block.timestamp <= yearstamps[7]){
            pointing=7;
        }else{
            pointing=8;
        }
        
        return pointing;
    }
    ///////////////////////////////////////

    //-17)
    //PUMP AND DUMP CHECK Function (no whitelisted members)
    ///////////////////////////////////////
    function _PDACheck(address sender, uint256 amount) internal virtual returns (bool){
        //If bigger as 0, address is monitored
        
        //IF Sender timer is set then true
        if(PADtimePointer[sender] > 0){
            
            //If timewindow is smaller as actual timestamp, renew TimeWindow to 24 Hours and Account Monitoring back to 0 value
            if(PADtimePointer[sender] < block.timestamp){
                PADtimePointer[sender] = block.timestamp+(3600*24);
                PADprotection[sender] =0;
                PADWhitelisting[sender]=false;
                if(amount <= maxDailyTradeVolume){
                    return true;
                }else{
                    return false;
                } 
            //Timestamp is in time
            }else{
                if(amount <= maxDailyTradeVolume){
                    return true;
                }else{
                    return false;
                }  
            }
        }else{
            
            PADtimePointer[sender] = block.timestamp+(3600*24);
            PADprotection[sender]=0;
            if(amount <= maxDailyTradeVolume){
                    return true;
            }else{
                    return false;
            } 
        }
        
        
        
    }
    ///////////////////////////////////////

    //-18)
    //PUMP AND DUMP CHECK Function (whitelisted members)
    ///////////////////////////////////////
    function _PDAWCheck(address sender, uint256 amount) internal virtual returns (bool){
        //If bigger as 0, address is monitored
        
        //IF Sender timer is set then true
        if(PADtimePointer[sender] > 0){
            
            //If timewindow is smaller as actual timestamp, WhiteListing Ends
            if(PADtimePointer[sender] < block.timestamp){
                PADWhitelisting[sender]=false;
                return false;                 
            //Timestamp is in time
            }else{
                if(amount <= maxDailyTradeVolumeWL){
                    return true;
                }else{
                    
                    return false;
                }  
            }
        }else{
            
            PADtimePointer[sender] = block.timestamp+(3600*24);
            PADprotection[sender]=0;
            if(amount <= maxDailyTradeVolumeWL){
                    return true;
            }else{
                    return false;
            } 
        }
        
        
        
    }
    ///////////////////////////////////////

    //-19)
    //PADWhitelisting extension to PAD Security up to 1.5 Million NFM on the 
    //same existing TimeWindow Function
    ///////////////////////////////////////
    function _PDAwhitelisting() public returns (bool){  
        require(PADWhitelisting[msg.sender]==false, "You can only get Whitelisted once a day!");      
        uint256 fromBalance = balances[msg.sender];
        require(fromBalance >= WLFee, "ERC20: transfer amount exceeds balance");
        unchecked {
            balances[msg.sender] = SafeMath.sub(fromBalance,WLFee);
        }
        balances[executer] += WLFee;        
        PADWhitelisting[msg.sender]=true;
        emit Transfer(msg.sender, executer, WLFee);
        return true;         
    }
    ///////////////////////////////////////

    //-20)
    //Issue Burning Function
    ///////////////////////////////////////
    function _issueBurnCoins(uint256 kAmount) internal virtual returns (bool){
        //Require that dailyStamp smaller or equal Block Timestamp
        //require(dailyStamp <= block.timestamp, "Its not Time yet");
        
        bool Cpointing=(_emissionPointer() < 4) ? true : false;
        //Check if Emission time is over
        if(Cpointing==true){
        _burn(executer, kAmount);
                          
        } 
       return true;
    }
    ///////////////////////////////////////

    
    
}

/*
TODOS
-->Burning 
Staking
-->Distribution Array admin contract owner
AFT DAO BUY SELL
SWAP INTEGRATION
BRIDGING
-->LOCKING SYSTEM
*/