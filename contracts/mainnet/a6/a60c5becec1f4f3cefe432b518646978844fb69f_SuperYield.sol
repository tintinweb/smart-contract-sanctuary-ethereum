/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

pragma solidity ^0.4.25;

/**
Telegram- https://t.me/SuperYield

  SuperYield contract: returns 111%-141% of each investment!

  Automatic payouts!

  No bugs, no backdoors, NO OWNER - fully automatic!

  Made and checked by professionals!
 
  1. Send any sum to smart contract address
     - sum from 0.01 to 10 ETH
     - min 250000 gas limit
     - max 50 gwei gas price
     - you are added to a queue
  2. Wait a little bit
  3. ...
  4. PROFIT! You have got 111-141%

  How is that?
  1. The first investor in the queue (you will become the
     first in some time) receives next investments until
     it become 111-141% of his initial investment.
  
  2. You will receive payments in several parts or all at once
  
  3. Once you receive 111-141% of your initial investment you are
     removed from the queue.
  
  4. You can make multiple deposits
  
  5. The balance of this contract should normally be 0 because
     all the money are immediately go to payouts
  
  6. The more deposits you make the more multiplier you get. See MULTIPLIERS var
  
  7. If you are the last depositor (no deposits after you in 20 mins)
     you get 2% of all the ether that were on the contract. 
     The last depositor Send 0 to withdraw it.
     Do it BEFORE NEXT RESTART!
  
  8. The contract automatically restarts each 24 hours at 12:00 GMT
  
  9. Deposits will not be accepted 20 mins before next restart. But prize can be withdrawn.
  

     So the last pays to the first (or to several first ones
     if the deposit big enough) and the investors paid 111-141% are removed from the queue
     

                new investor --|               brand new investor --|
                 investor5     |                 new investor       |
                 investor4     |     =======>      investor5        |
                 investor3     |                   investor4        |
    (part. paid) investor2    <|                   investor3        |
    (fully paid) investor1   <-|                   investor2   <----|  (pay until full %)

*/

contract SuperYield {
    //Address for tech expences
    address constant private TECH = 0x4AC5c13Cc0097c8844c1374fA3deDf01861Ea65E;
    //Address for promo expences
    address constant private PROMO = 0x4AC5c13Cc0097c8844c1374fA3deDf01861Ea65E;
    uint constant public TECH_PERCENT = 3;
    uint constant public PROMO_PERCENT = 3;
    uint constant public PRIZE_PERCENT = 2;
    uint constant public MAX_INVESTMENT = 10 ether;
    uint constant public MIN_INVESTMENT_FOR_PRIZE = 0.05 ether;
    uint constant public MAX_IDLE_TIME = 20 minutes; 

    uint8[] MULTIPLIERS = [
        111, //For first deposit made at this stage
        113, //For second
        117, //For third
        121, //For forth
        125, //For fifth
        130, //For sixth
        135, //For seventh
        141  //For eighth and on
    ];

    struct Deposit {
        address depositor;
        uint128 deposit; 
        uint128 expect;
    }

    struct DepositCount {
        int128 stage;
        uint128 count;
    }

    struct LastDepositInfo {
        uint128 index;
        uint128 time;
    }

    Deposit[] private queue;
    uint public currentReceiverIndex = 0;
    uint public currentQueueSize = 0;
    LastDepositInfo public lastDepositInfo;

    uint public prizeAmount = 0;
    int public stage = 0;
    mapping(address => DepositCount) public depositsMade;



    function () public payable {
	require(tx.gasprice <= 50000000000 wei, "Gas price is too high! Do not cheat!");
        if(msg.value > 0){
            require(gasleft() >= 220000, "We require more gas!");
            require(msg.value <= MAX_INVESTMENT, "The investment is too much!"); 

            checkAndUpdateStage();

            require(getStageStartTime(stage+1) >= now + MAX_IDLE_TIME);

            addDeposit(msg.sender, msg.value);

            pay();
        }else if(msg.value == 0 && lastDepositInfo.index > 0 && msg.sender == queue[lastDepositInfo.index].depositor) {
            withdrawPrize();
        }
    }

    function pay() private {
        uint balance = address(this).balance;
        uint128 money = 0;
        if(balance > prizeAmount)
            money = uint128(balance - prizeAmount);

        for(uint i=currentReceiverIndex; i<currentQueueSize; i++){

            Deposit storage dep = queue[i];

            if(money >= dep.expect){
                dep.depositor.transfer(dep.expect);
		        money -= dep.expect;

                delete queue[i];
            }else{
                dep.depositor.transfer(money); 
                dep.expect -= money;     
                break;                   
            }

            if(gasleft() <= 50000)       
                break;                     
        }

        currentReceiverIndex = i; 
    }

    function addDeposit(address depositor, uint value) private {
        DepositCount storage c = depositsMade[depositor];
        if(c.stage != stage){
            c.stage = int128(stage);
            c.count = 0;
        }

        if(value >= MIN_INVESTMENT_FOR_PRIZE)
            lastDepositInfo = LastDepositInfo(uint128(currentQueueSize), uint128(now));

        uint multiplier = getDepositorMultiplier(depositor);
        push(depositor, value, value*multiplier/100);

        c.count++;

        prizeAmount += value*PRIZE_PERCENT/100;

        uint support = value*TECH_PERCENT/100;
        TECH.transfer(support);
        uint adv = value*PROMO_PERCENT/100;
        PROMO.transfer(adv);
    }

    function checkAndUpdateStage() private{
        int _stage = getCurrentStageByTime();

        require(_stage >= stage, "We should only go forward in time");

        if(_stage != stage){
            proceedToNewStage(_stage);
        }
    }

    function proceedToNewStage(int _stage) private {
        stage = _stage;
        currentQueueSize = 0;
        currentReceiverIndex = 0;
        delete lastDepositInfo;
    }

    function withdrawPrize() private {
        require(lastDepositInfo.time > 0 && lastDepositInfo.time <= now - MAX_IDLE_TIME, "The last depositor is not confirmed yet");
        require(currentReceiverIndex <= lastDepositInfo.index, "The last depositor should still be in queue");

        uint balance = address(this).balance;
        if(prizeAmount > balance) 
            prizeAmount = balance;

        uint prize = prizeAmount;
        queue[lastDepositInfo.index].depositor.transfer(prize);

        prizeAmount = 0;
        proceedToNewStage(stage + 1);
    }

    function push(address depositor, uint deposit, uint expect) private {
        Deposit memory dep = Deposit(depositor, uint128(deposit), uint128(expect));
        assert(currentQueueSize <= queue.length); 
        if(queue.length == currentQueueSize)
            queue.push(dep);
        else
            queue[currentQueueSize] = dep;

        currentQueueSize++;
    }

    function getDeposit(uint idx) public view returns (address depositor, uint deposit, uint expect){
        Deposit storage dep = queue[idx];
        return (dep.depositor, dep.deposit, dep.expect);
    }

    function getDepositsCount(address depositor) public view returns (uint) {
        uint c = 0;
        for(uint i=currentReceiverIndex; i<currentQueueSize; ++i){
            if(queue[i].depositor == depositor)
                c++;
        }
        return c;
    }

    function getDeposits(address depositor) public view returns (uint[] idxs, uint128[] deposits, uint128[] expects) {
        uint c = getDepositsCount(depositor);

        idxs = new uint[](c);
        deposits = new uint128[](c);
        expects = new uint128[](c);

        if(c > 0) {
            uint j = 0;
            for(uint i=currentReceiverIndex; i<currentQueueSize; ++i){
                Deposit storage dep = queue[i];
                if(dep.depositor == depositor){
                    idxs[j] = i;
                    deposits[j] = dep.deposit;
                    expects[j] = dep.expect;
                    j++;
                }
            }
        }
    }

    function getQueueLength() public view returns (uint) {
        return currentQueueSize - currentReceiverIndex;
    }

    function getDepositorMultiplier(address depositor) public view returns (uint) {
        DepositCount storage c = depositsMade[depositor];
        uint count = 0;
        if(c.stage == getCurrentStageByTime())
            count = c.count;
        if(count < MULTIPLIERS.length)
            return MULTIPLIERS[count];

        return MULTIPLIERS[MULTIPLIERS.length - 1];
    }

    function getCurrentStageByTime() public view returns (int) {
        return int(now - 12 hours) / 1 days - 17847; 
    }

    function getStageStartTime(int _stage) public pure returns (uint) {
        return 12 hours + uint(_stage + 17847)*1 days;
    }

    function getCurrentCandidateForPrize() public view returns (address addr, int timeLeft){
        if(currentReceiverIndex <= lastDepositInfo.index && lastDepositInfo.index < currentQueueSize){
            Deposit storage d = queue[lastDepositInfo.index];
            addr = d.depositor;
            timeLeft = int(lastDepositInfo.time + MAX_IDLE_TIME) - int(now);
        }
    }
}