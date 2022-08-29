/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

//SPDX-License-Identifier: MIT
pragma solidity  0.8.14;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
   
}

//import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


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

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Loan is Ownable {

    IERC20 public tokenA;

//    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Rinkeby
     * Aggregator: USDC/ETH
     * Address: 0xdCA36F27cbC4E38aE16C4E9f99D39b42337F6dcf
     */
    

    constructor(/*IERC20 _anna,*/ IERC20 _tokenA) {
//        priceFeed = AggregatorV3Interface(0xdCA36F27cbC4E38aE16C4E9f99D39b42337F6dcf);
        //Anna = _anna;
        tokenA = _tokenA;
        interestRate100x = 100;   // bps
        price = 2000*(10**12);  // 1 ETH = 2000 usdc , for testing
        
    }
    
    uint256 depositId;
    address[] depositors;
    uint16 interestRate100x;
    
    uint32 constant MATURITY_TIME = 1; //24*60*60;  // 1 month
    uint32 constant WITHDRAWL_TIME = 1; //7*24*60*60; // 1 week
    mapping (address => mapping (uint256 => Deposit)) public depositData;
    mapping (uint256 => bool) public isActiveD; // Deposit ID is active?
    mapping (uint256 => bool) public isActiveW; // withdrawl Id is active?
    mapping (address => uint256[]) public myDeposits;    // depositId => address  
    

    struct Deposit {
        uint32 timeOfDeposit;
        uint16 interestRate100x; // 100x interest rate per month
        uint256 tokenAAmount;  // USDC
        uint256 weiAmount;
        int256 EthPriceInUSD;   // current price
    }
    
    // deposit
    event Deposits(/*address indexed Depositor,*/ uint256 DepositId, uint256 TokenDeposit, uint256 WeiDeposit);
    function depositETH() public payable returns(bool){
        require((msg.sender).balance>=msg.value, "Not enough Eth balance");
        depositId++;
        int256 prices = getLatestPrice();
        uint256 tokenADeopsit = msg.value*uint256(prices)/(10**12);  
        depositData[msg.sender][depositId] = Deposit(uint32(block.timestamp), 
                                   interestRate100x,tokenADeopsit,msg.value,prices/(10**12));
        isActiveD[depositId] = true;
        myDeposits[msg.sender].push(depositId);
        emit Deposits(depositId,0,msg.value);
        return true;
    }
    function depositTokenA(uint256 _amountInBits) public returns(bool){
        require(tokenA.balanceOf(msg.sender)>=_amountInBits, "Not enough token balance");
        depositId++;
        int256 prices = getLatestPrice();
        uint256 tokenADeopsit = _amountInBits;  
        uint256 weiAmt = tokenADeopsit*(10**12)/uint256(prices);
        //user(as owner) needs to give approval to this contract (spender) in USDZ contract.
        
        tokenA.transferFrom(msg.sender,address(this),tokenADeopsit);
        
        depositData[msg.sender][depositId] = Deposit(uint32(block.timestamp), 
                                   interestRate100x,tokenADeopsit,weiAmt,prices/(10**12));
        isActiveD[depositId] = true;
        myDeposits[msg.sender].push(depositId);
        emit Deposits(depositId,tokenADeopsit,0);
        return true;
    }
    function viewMyActiveDeposits() public view returns(uint256[]memory) {
        uint256 z = myDeposits[msg.sender].length;
        uint256[] memory x = new uint256[](z);
        uint k;
        for(uint i=0;i<myDeposits[msg.sender].length;i++){
            uint j = myDeposits[msg.sender][i];
            if (isActiveD[j]){               
                x[k] = j;
                k++;
            }
        }
        return x;
    }
    function viewMyDepositId(uint256 _Id) public view returns(uint32 TimeOfDeposit, uint16 InterestRate,uint256 WeiAmount, int256 TokenPrice){
        return (depositData[msg.sender][_Id].timeOfDeposit,
                depositData[msg.sender][_Id].interestRate100x, 
                depositData[msg.sender][_Id].weiAmount,
                depositData[msg.sender][_Id].EthPriceInUSD/*/(10**12)*/ );
    }
    
    uint256 requestId;
    struct Request {
        uint32 time;
        uint256 tokenAToPay;
        uint256 weiToPay;
        address depositor;
    }
    mapping (uint256 => uint256) public requests;  // depositId to requestId
    mapping (uint256 => Request) public requestData;   // requestId to Request
    // requestForWthdrawl
    event WithdrawRequest(string Coin, uint256 AmountToWithdraw, uint256 RequestId);
    function requestForWthdrawl(uint256 _Id/*depositId*/) public {
        require(depositData[msg.sender][_Id].timeOfDeposit>0 || owner() == msg.sender , "Not the depositor");
        require(isActiveD[_Id], "Deposit Id not active");
        require( (uint32(block.timestamp) - MATURITY_TIME) >= depositData[msg.sender][_Id].timeOfDeposit, "Too Early");
        isActiveD[_Id] = false;
        int priceNow = getLatestPrice()/(10**12);
        requestId++;
        requests[_Id] = requestId;
        isActiveW[requestId] = true;
        uint16 months = 1;
        //months = uint16(uint32(block.timestamp - depositData[msg.sender][_Id].timeOfDeposit)/(30*24*60*60));
        if(priceNow>=depositData[msg.sender][_Id].EthPriceInUSD){
            uint256 interest = depositData[msg.sender][_Id].tokenAAmount*interestRate100x*months/10000;
            uint256 tokenApayable = (depositData[msg.sender][_Id].tokenAAmount + interest); //tknBits
            requestData[requestId] = Request(uint32(block.timestamp),tokenApayable,0,msg.sender);
            emit WithdrawRequest("tokenA",tokenApayable, requestId);
            
        } else {
            uint256 interest = depositData[msg.sender][_Id].weiAmount*interestRate100x*months/10000;
            uint256 weiPayable = (depositData[msg.sender][_Id].weiAmount + interest);
            requestData[requestId] = Request(uint32(block.timestamp),0,weiPayable,msg.sender);
            emit WithdrawRequest("Wei",weiPayable,requestId);
            
        }
        
    }
    // withdrawl
    uint public failed;
    uint public total;
    event Withdraw(uint256 USDCW,uint256 WEIW);
    function withdrawl(uint256 _Id/*requestId*/) public payable returns(uint256) {
        require((uint32(block.timestamp)-WITHDRAWL_TIME) > requestData[_Id].time, "Not yet due ");
        require(requestData[_Id].depositor==msg.sender || owner() == msg.sender ,"Not the depositor");
        require(isActiveW[_Id], "Request Id not active");
        isActiveW[_Id] = false;
        uint256 tokenAWithdraw = requestData[_Id].tokenAToPay;
        uint256 weiWithdraw = requestData[_Id].weiToPay;
        uint256 contractBalance = viewBalance();
        uint256 contractTokenBalance = viewtokenABalance(); 
        if(tokenAWithdraw == 0) {
            if (weiWithdraw>contractBalance){
                payable(requestData[_Id].depositor).transfer(contractBalance);
                failed++;
                total++;
                emit Withdraw(0,contractBalance);
                return contractBalance;

            }else {
                payable(requestData[_Id].depositor).transfer(weiWithdraw);
                total++;
                emit Withdraw(0,weiWithdraw);
                return weiWithdraw;    
            }
            
        } else {
            if(tokenAWithdraw>contractTokenBalance){
                tokenA.transfer(requestData[_Id].depositor,contractTokenBalance);
                failed++;
                total++;
                emit Withdraw(contractTokenBalance,0);
                return contractTokenBalance;    
            }else {
                tokenA.transfer(requestData[_Id].depositor,tokenAWithdraw);
                total++;
                emit Withdraw(tokenAWithdraw,0);
                return tokenAWithdraw;    
            }
            
        }
        
    }

    function viewBalance()public view returns (uint256){
        return address(this).balance;
    }
    function viewtokenABalance()public view returns (uint256){
        return tokenA.balanceOf(address(this));
    }
    function viewMyBalance()public view returns (uint256){
        return (msg.sender).balance;
    }
    function viewMytokenABalance()public view returns (uint256){
        return tokenA.balanceOf(msg.sender);
    }
    function viewFailed() public view returns(uint256,uint256){
        return (failed,total);
    }


    fallback () external payable {
    }
    receive () external payable {
    }
    // function getLatestPrice() public view returns (int) {
    //     (
    //         /*uint80 roundID*/,
    //         int price,
    //         /*uint startedAt*/,
    //         /*uint timeStamp*/,
    //         /*uint80 answeredInRound*/
    //     ) = priceFeed.latestRoundData();
    //     return price;
    // }
    int public price;
    function setPriceManual(int _USDperETH) public {
        price = _USDperETH*(10**12);
    }
    function getLatestPrice() public view returns (int) {
        return price;
    }
    function setInterestRate(uint16 _rate) public onlyOwner {
        require(interestRate100x>=100, "Rate cannot be less than 1% per month");
        interestRate100x = _rate;
    }

    function removeAllEth() public onlyOwner {
        payable(owner()).transfer(viewBalance());
        emit Withdraw(0,viewBalance());
    }
    function removeEth(uint _amount) public onlyOwner {
        payable(owner()).transfer(_amount);
        emit Withdraw(0,_amount);
    }
    function removeAllToken() public onlyOwner {
        tokenA.transfer(owner(),viewtokenABalance());
        emit Withdraw(viewtokenABalance(),0);
    }
    function removeToken(uint _amount) public onlyOwner{
        tokenA.transfer(owner(),_amount);
        emit Withdraw(_amount,0);
    }
    function destruct() public onlyOwner {
        removeAllToken();
        selfdestruct(payable(owner()));
    }
}