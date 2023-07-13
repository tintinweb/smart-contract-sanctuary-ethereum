/**
 *Submitted for verification at Etherscan.io on 2023-07-12
*/

// created by cryptodo.app
//   _____                      _          _____         
//  / ____|                    | |        |  __ \        
// | |      _ __  _   _  _ __  | |_  ___  | |  | |  ___  
// | |     | '__|| | | || '_ \ | __|/ _ \ | |  | | / _ \ 
// | |____ | |   | |_| || |_) || |_| (_) || |__| || (_) |
//  \_____||_|    \__, || .__/  \__|\___/ |_____/  \___/ 
//                 __/ || |                              
//                |___/ |_|      

// SPDX-License-Identifier: MIT

//     www.cryptodo.app

pragma solidity 0.8.16;

contract Yooji  {

    address devAddress=0x1C8B6988Eb92E03e6796356e8D63d0877Cd30c21;
    uint8   constant  refFee=5;
    uint8   immutable ownerFee;
    address feeAddress=devAddress;
    uint8   withdrawFee=5;
    
    address  public    owner; 
    uint8    devFee=5;

    constructor 
    (uint8 ownerFee_,
     uint ticketsPrice_, uint32 ticketsAmount_, uint startTime_, uint endTime_, uint8[] memory winnersPercentage_, uint8[] memory valuePercentage_) payable
    {   
        require(ownerFee_<31,"set fee no more than 30");
        owner = msg.sender;
        ownerFee=ownerFee_;
        createBlock(ticketsPrice_,ticketsAmount_,startTime_,endTime_,winnersPercentage_,valuePercentage_);
    }

    modifier onlyOwner() {
       require(msg.sender == owner, "Not owner");
       _;
    }
    modifier onlyDev() {
       require(msg.sender == devAddress, "Not dev");
       _;
    }

    struct LotteryBlock {
        mapping (uint=>address) ticketsOwner;
        mapping (uint=>uint8)   ticketWon;
        
        uint8 [] winnersPercentage;      
        uint8 [] valuePercentage; 

        address[] members;

        uint32   ticketsWonAmount;
        uint32   ticketsAmount;
        uint32   ticketsBought; 
        uint     ticketsPrice;

        uint     startTime;
        uint     surplus;
        uint     endTime;
        
        
        bool     ended;
        uint     pot;

        uint     addPot;
        
        uint32 currentWinner;
        uint32 currentRefund;
    }

    struct userBlock{
        
        mapping (uint32=>uint32)  ticketsAmount;
        mapping (uint32=>uint32)  wonticketsAmount;

        address inviter;

        uint balance;

        bool registered;
    }

    mapping (uint32=>LotteryBlock) public BlockID;
    mapping (address=>userBlock)   private UserID;
    
    
    uint32 public  ID;
    uint   private counter; 

    event CreateLottery (uint32 ID, uint StartTime, uint EndTime);
    event Winner        (uint32 ID,uint Ticket,uint PrizeValue);
    event TicketsBought (address User,uint32 Amount);
    event Withdraw      (address User, uint Amount);
    event EndLottery    (uint32 ID,uint EndTime);
    
//_____________________________________________________________________________________________________________________________________________________________________________________________
    
    
    function createBlock
    (uint ticketsPrice_, uint32 ticketsAmount_, uint startTime_, uint endTime_, uint8[] memory winnersPercentage_, uint8[] memory valuePercentage_) 
     payable public onlyOwner {
        
        require(winnersPercentage_.length==valuePercentage_.length,"array's length must be equal to");
        require(startTime_<endTime_,"start time must be more than end time");
        require(winnersPercentage_.length>0,"choose percentage of winners");
        require(ticketsAmount_>9,"tickets amount must be more than ten");
        require(winnersPercentage_.length<101,"Enter fewer winners");
        
        bool sent=payable(devAddress).send(msg.value*devFee/100);
        require(sent,"Send is failed");

        BlockID[ID].addPot+=msg.value-(msg.value*devFee/100);
        BlockID[ID].pot+=msg.value-(msg.value*devFee/100);
        
        uint16   winnerPercentage;
        uint16   totalPercentage;
        

        for(uint i=0;i<valuePercentage_.length;i++){
            totalPercentage+=valuePercentage_[i];
            winnerPercentage+=winnersPercentage_[i];
            require(valuePercentage_[i]>0 && winnersPercentage_[i]>0,"need to set percentage above zero");
            if (ticketsAmount_<100)
            require(winnersPercentage_[i]>9,"set percentage above 9");
        }
        require(totalPercentage==100 && winnerPercentage<101,"requires the correct ratio of percentages");
        
        BlockID[ID].startTime=startTime_+block.timestamp;
        BlockID[ID].winnersPercentage=winnersPercentage_;
        BlockID[ID].valuePercentage=valuePercentage_;
        BlockID[ID].endTime=endTime_+block.timestamp;
        BlockID[ID].ticketsPrice=ticketsPrice_;
        BlockID[ID].ticketsAmount=ticketsAmount_;
       
        emit CreateLottery(ID,startTime_+block.timestamp,endTime_+block.timestamp);

        ID++;
    }

    function addValue(uint32 ID_) external payable onlyOwner {
        require(BlockID[ID_].startTime<block.timestamp && !BlockID[ID_].ended,"Lottery didn't started or already ended");
        require(msg.value>100,"set more than 100 wei");
        
        bool sent=payable(devAddress).send(msg.value*devFee/100);
        require(sent,"Send is failed");

        BlockID[ID_].addPot+=msg.value-(msg.value*devFee/100);
        BlockID[ID_].pot+=msg.value-(msg.value*devFee/100);
        
    }

    function endBlock(uint32 ID_) external onlyOwner {
        require(BlockID[ID_].currentRefund==0 && BlockID[ID_].currentWinner==0,"You should refund money or set amount of winners");
        require(BlockID[ID_].endTime<block.timestamp,"Lottery are still running");
        require(BlockID[ID_].startTime>0,"Lottery didn't started");
        require(!BlockID[ID_].ended,"Lottery is over,gg");

        setWinners(ID_);
    }

    function refundMoney(uint32 ID_,uint32 amount) external onlyOwner {
       require(!BlockID[ID_].ended,"lottery is over");
    
       BlockID[ID_].surplus=BlockID[ID_].pot;
       moneyBack(ID_,amount);
       BlockID[ID_].ended=true;
    }

//_____________________________________________________________________________________________________________________________________________________________________________________________

    function changeFeeAddress(address feeAddress_) external onlyDev {
        feeAddress=feeAddress_;      
    }

    function changeDevAddress(address devAddress_) external onlyDev {
        devAddress=devAddress_;
    }

    function chagneFeeValue (uint8 withdrawFee_) external onlyDev {
        require(withdrawFee_<6,"set less than 6%");
        withdrawFee=withdrawFee_;
    }

    function setDevFee (uint8 devFee_) external onlyDev {
        require(devFee_>0,"set above 0");
        devFee=devFee_;
    }

//_____________________________________________________________________________________________________________________________________________________________________________________________

    function setWinners(uint32 ID_) private {
        require(!BlockID[ID_].ended,"lottery is over");
        require(BlockID[ID_].currentWinner==0,"use staged completion");

        uint32 ticketsBought=BlockID[ID_].ticketsBought;
        uint32 winnersAmount;
        uint8[] memory valuePercentage_=BlockID[ID_].valuePercentage;
        BlockID[ID_].surplus=BlockID[ID_].pot;

        if (ticketsBought>0){
            if (ticketsBought<10)
                moneyBack(ID_,30);
            else{
                unchecked{
                    for (uint i=0;i<valuePercentage_.length;i++){
                        winnersAmount=ticketsBought*BlockID[ID_].winnersPercentage[i]/100;  
                        if(winnersAmount<1) winnersAmount=1;   
                        uint prizeValue=(BlockID[ID_].pot*valuePercentage_[i]/100)/winnersAmount;  
                        setTickets(winnersAmount,prizeValue,ID_);
                    }
                }
            }
            if(BlockID[ID_].surplus>0)
            refundSurplus(ID_);
        }
        BlockID[ID_].ended=true;
        emit EndLottery(ID_,block.timestamp);
    }

        function refundSurplus(uint32 ID_) private {
            UserID[owner].balance+=BlockID[ID_].surplus;
            BlockID[ID_].surplus=0;
    }

    function setTickets (uint32 winnersAmount_, uint prizeValue_,uint32 ID_) private {
        uint prize;
        bool newTicket;
        unchecked{
        for (uint32 a=0;a<winnersAmount_;a++){
                uint wonTicket;
                newTicket=false;
                while (!newTicket){
                        wonTicket = random(BlockID[ID_].ticketsBought)+1;
                        if (BlockID[ID_].ticketWon[wonTicket]!=1)
                            newTicket=true;
                }
                
                UserID[BlockID[ID_].ticketsOwner[wonTicket]].balance+=prizeValue_;
                UserID[BlockID[ID_].ticketsOwner[wonTicket]].wonticketsAmount[ID_]++;
                BlockID[ID_].ticketWon[wonTicket]=1;

                emit Winner(ID_,wonTicket,prizeValue_);
            }
            BlockID[ID_].ticketsWonAmount+=winnersAmount_;
            prize+=prizeValue_*winnersAmount_;
        }
        BlockID[ID_].surplus-=prize;
    }
    
    function setAmountOfWinners(uint32 amount_,uint32 ID_) external onlyOwner {
        require(BlockID[ID_].endTime<block.timestamp,"Lottery are still running");
        require(BlockID[ID_].currentRefund==0,"You started refund");
        require(BlockID[ID_].startTime>0,"Lottery didn't started");
        require(!BlockID[ID_].ended,"Lottery is over");

        uint32[] memory winnersCounter_= new uint32[](BlockID[ID_].winnersPercentage.length);
        uint  [] memory value_= new uint[](BlockID[ID_].winnersPercentage.length);
        uint8 [] memory winnerPercentage=BlockID[ID_].winnersPercentage;
        uint32 ticketsBought=BlockID[ID_].ticketsBought;

        uint32  crWinner = BlockID[ID_].currentWinner;
        uint32  counter_=amount_;

        for (uint8 i=0; i<winnersCounter_.length;i++){
            if (i>0)
                winnersCounter_[i]=winnersCounter_[i-1]+ticketsBought*winnerPercentage[i]/100;
            else  
                winnersCounter_[i]=ticketsBought*winnerPercentage[i]/100;
            if(winnersCounter_[i]<1) winnersCounter_[i]=1;
            value_[i]=(BlockID[ID_].pot*BlockID[ID_].valuePercentage[i]/100)/(ticketsBought*winnerPercentage[i]/100);
        }
        
       for (uint8 l=0; l<winnersCounter_.length;l++){
           if (crWinner>=winnersCounter_[l]) continue;
           if (crWinner+counter_>winnersCounter_[l] && crWinner+counter_>counter) {
               setTickets((winnersCounter_[l]-crWinner),value_[l],ID_);   
               counter_-=winnersCounter_[l]-crWinner;
               crWinner+=winnersCounter_[l]-crWinner;
            } else {
               setTickets(counter_,value_[l],ID_);
               counter_-=counter_;
               crWinner+=counter_;
            }
            if (crWinner==winnersCounter_[winnersCounter_.length-1]){
                if(BlockID[ID_].surplus>0)
                refundSurplus(ID_);
                
                BlockID[ID_].ended=true;
                emit EndLottery(ID_,block.timestamp);
                break;
            }   

            if (counter==0) break;
        }

        BlockID[ID_].currentWinner=crWinner;
    }


    function moneyBack(uint32 ID_, uint32 amount_) private {
        uint32  ticketsBought=BlockID[ID_].ticketsBought;
        uint256 ticketRefund=(BlockID[ID_].pot-BlockID[ID_].addPot)/ticketsBought;
        unchecked{
            for (uint32 i=BlockID[ID_].currentRefund;i<BlockID[ID_].currentRefund+amount_;i++){
                    UserID[BlockID[ID_].members[i]].balance+=ticketRefund*UserID[BlockID[ID_].members[i]].ticketsAmount[ID_];
                    if(i==BlockID[ID_].members.length-1){
                        BlockID[ID_].surplus-=ticketRefund*ticketsBought;
                        BlockID[ID_].currentRefund=i;
                        break;
                    }
                }
            BlockID[ID_].surplus-=ticketRefund*ticketsBought;
            if(BlockID[ID_].surplus>0)
                refundSurplus(ID_);
            BlockID[ID_].currentRefund+=amount_;
        }
    }

     function random(uint num) private returns(uint){
        counter++;
        return uint(keccak256(abi.encodePacked(block.number,counter, msg.sender))) % num;
    }

//_____________________________________________________________________________________________________________________________________________________________________________________________  
    

    function accRegister(address inviter_) external {
        require(!UserID[msg.sender].registered,"Already registerd");
        if (inviter_==address(0))
            UserID[msg.sender].inviter=owner;
        else
            UserID[msg.sender].inviter=inviter_;
        UserID[msg.sender].registered=true;
    }
    
    function buyTickets(uint32 amount,uint32 ID_) external payable {
        require(BlockID[ID_].startTime<block.timestamp && BlockID[ID_].endTime>block.timestamp,"Lottery didn't started or already ended");
        require(UserID[msg.sender].registered,"Wallet not registered");
        require(amount>0,"You need to buy at least 1 ticket");
        require(msg.value==amount*BlockID[ID_].ticketsPrice,"Inncorect value");
        require(amount+BlockID[ID_].ticketsBought<=BlockID[ID_].ticketsAmount,"Buy fewer tickets");

        if(UserID[msg.sender].ticketsAmount[ID_]==0)
            BlockID[ID_].members.push(msg.sender);

        for (uint32 i=BlockID[ID_].ticketsBought+1;i<BlockID[ID_].ticketsBought+1+amount;i++){
            BlockID[ID_].ticketsOwner[i]=msg.sender;
        }
        UserID[msg.sender].ticketsAmount[ID_]+=amount;
        BlockID[ID_].ticketsBought+=amount;

        BlockID[ID_].pot+=msg.value-(msg.value/100*devFee)-(msg.value*ownerFee/100)-(msg.value*refFee/100);

        UserID[UserID[msg.sender].inviter].balance+=msg.value*refFee/100;
        
        bool sent = payable(devAddress).send(msg.value*devFee/100);
        require(sent,"Send is failed");

        UserID[owner].balance+=msg.value/100*ownerFee;

        emit TicketsBought(msg.sender,amount);

        if (BlockID[ID_].ticketsBought==BlockID[ID_].ticketsAmount)
            setWinners(ID_);
    }


    function withdraw() external {
        require(msg.sender!=address(0),"Zero address");
        require(UserID[msg.sender].balance>0,"Nothing to withdraw");

        uint amount = UserID[msg.sender].balance;
        UserID[msg.sender].balance=0;
        bool feeSent = payable(feeAddress).send(amount/20);
        require(feeSent,"Send is failed");
        bool sent = payable(msg.sender).send(amount-amount/20);
        require(sent,"Send is failed");
        
        emit Withdraw(msg.sender,amount);
    }

//_____________________________________________________________________________________________________________________________________________________________________________________________

   function checkLotteryPercentage(uint32 ID_) external view returns(uint8[] memory winnersPercentage,uint8[] memory valuePercentage){
        return(BlockID[ID_].winnersPercentage,BlockID[ID_].valuePercentage);
    }
   
    function checkTickets(address user,uint32 ID_) external view returns (uint32[] memory tickets){
        uint32[] memory tickets_ = new uint32[] (UserID[msg.sender].ticketsAmount[ID_]);
        uint32 a;
        uint32 amount=BlockID[ID_].ticketsBought;
        for (uint32 i=1;i<amount+1;i++){
            if(BlockID[ID_].ticketsOwner[i]==user){
                tickets_[a]=i;
                a++;
            }
        }
        return(tickets_);
    }

    function checkWonTickets(address user,uint32 ID_) external view returns (uint[] memory tickets){
        uint[] memory wonTickets_ = new uint[] (UserID[user].wonticketsAmount[ID_]);
        uint32 allTickets = BlockID[ID_].ticketsBought;
        uint32 a;
        for (uint32 i=1;i<allTickets+1;i++){
            if(BlockID[ID_].ticketWon[i]>0 && BlockID[ID_].ticketsOwner[i]==user){
                wonTickets_[a]=i;
                a++;
            }
        }
   
        return(wonTickets_);
    }

    function checkBalance(address user) external view returns (uint balance){
        return(UserID[user].balance);
    }

    function checkTicketOwner(uint32 ID_,uint32 ticket) external view returns(address user){
        return(BlockID[ID_].ticketsOwner[ticket]);
    }

    function checkLotterysWinners(uint32 ID_) external view returns (uint[] memory winners){
        uint[] memory wonTickets=new uint[](BlockID[ID_].ticketsWonAmount);
        uint32 a;
        for (uint32 i=1;i<BlockID[ID_].ticketsBought+1;i++){
            if(BlockID[ID_].ticketWon[i]>0){
                wonTickets[a]=i;
                a++;
            }
        }
        return(wonTickets);
    } 

    function checkTicketPrice(uint32 ID_) external view returns (uint ticketsPrice){
        return(BlockID[ID_].ticketsPrice);
    }

    function checkLotterysEnd(uint32 ID_) external view returns (uint endTime) {
        return(BlockID[ID_].endTime);
    }

    function checkLotterysPot(uint32 ID_) external view returns (uint pot) {
        return(BlockID[ID_].pot);
    }  

    function checkID () external view returns (uint32 Id) {
        return (ID-1);
    }
}