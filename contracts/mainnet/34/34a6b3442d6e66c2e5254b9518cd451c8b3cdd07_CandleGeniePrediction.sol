/**
 *Submitted for verification at Etherscan.io on 2022-07-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


/*

      ___           ___           ___          _____                        ___                    ___           ___           ___                       ___     
     /  /\         /  /\         /__/\        /  /::\                      /  /\                  /  /\         /  /\         /__/\        ___          /  /\    
    /  /:/        /  /::\        \  \:\      /  /:/\:\                    /  /:/_                /  /:/_       /  /:/_        \  \:\      /  /\        /  /:/_   
   /  /:/        /  /:/\:\        \  \:\    /  /:/  \:\   ___     ___    /  /:/ /\              /  /:/ /\     /  /:/ /\        \  \:\    /  /:/       /  /:/ /\  
  /  /:/  ___   /  /:/~/::\   _____\__\:\  /__/:/ \__\:| /__/\   /  /\  /  /:/ /:/_            /  /:/_/::\   /  /:/ /:/_   _____\__\:\  /__/::\      /  /:/ /:/_ 
 /__/:/  /  /\ /__/:/ /:/\:\ /__/::::::::\ \  \:\ /  /:/ \  \:\ /  /:/ /__/:/ /:/ /\          /__/:/__\/\:\ /__/:/ /:/ /\ /__/::::::::\ \__\/\:\__  /__/:/ /:/ /\
 \  \:\ /  /:/ \  \:\/:/__\/ \  \:\~~\~~\/  \  \:\  /:/   \  \:\  /:/  \  \:\/:/ /:/          \  \:\ /~~/:/ \  \:\/:/ /:/ \  \:\~~\~~\/    \  \:\/\ \  \:\/:/ /:/
  \  \:\  /:/   \  \::/       \  \:\  ~~~    \  \:\/:/     \  \:\/:/    \  \::/ /:/            \  \:\  /:/   \  \::/ /:/   \  \:\  ~~~      \__\::/  \  \::/ /:/ 
   \  \:\/:/     \  \:\        \  \:\         \  \::/       \  \::/      \  \:\/:/              \  \:\/:/     \  \:\/:/     \  \:\          /__/:/    \  \:\/:/  
    \  \::/       \  \:\        \  \:\         \__\/         \__\/        \  \::/                \  \::/       \  \::/       \  \:\         \__\/      \  \::/   
     \__\/         \__\/         \__\/                                     \__\/                  \__\/         \__\/         \__\/                     \__\/    
     
                                                                              
                                                                    CANDLE GENIE PREDICTION V5🗲      
                                                                      
                                                                       https://candlegenie.io


*/


//CONTEXT
abstract contract Context 
{
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

// REENTRANCY GUARD
abstract contract ReentrancyGuard 
{
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}


//OWNABLE
abstract contract Ownable is Context 
{
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() { address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function OwnershipTransfer(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function OwnershipRenounce() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

//PAUSABLE
abstract contract Pausable is Context 
{

    bool private _paused;

    constructor() {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

   function _pause() internal virtual whenNotPaused {
        _paused = true;
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
    }

}

// OPERATOR
abstract contract CandleGenieOperator
{
   function owner() public view virtual returns (address);
}

// REFERRALS
abstract contract CandleGenieReferrals
{
    function RegisterReferral(address user, address referral) public virtual;
    function HandleReferral(address user, uint256 amount, uint256 rate) public virtual;
}


//CONTRACT
contract CandleGeniePrediction is Ownable, Pausable, ReentrancyGuard 
{

    enum Position {Bull, Bear}

    struct Round 
    {
        uint256 epoch;
        uint256 bullAmount;
        uint256 bearAmount;
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        int256 lockPrice;
        int256 closePrice;
        uint32 startTimestamp;
        uint32 lockTimestamp;
        uint32 closeTimestamp;
        bool closed;
        bool cancelled;
        address[] players;
    }

    struct Bet 
    {
        Position position;
        uint256 betTimestamp;
        uint256 claimTimestamp;
        uint256 amount;
        bool claimed; 
    }


     // Epoch
    uint256 public currentEpoch;

    // Mappings
    mapping(uint256 => Round) public Rounds;
    mapping(uint256 => mapping(address => Bet)) public Bets;
    mapping(address => uint256[]) public UserBets;

    // Variables
    string public priceSource;
    uint256 public rewardRate = 95;
    uint256 public roundDuration = 5 minutes;
    uint256 public minBetAmount = 0.01 ether;
    bool internal showPlayers;

    // State
    bool public startOnce;
    bool public lockOnce;

    // Events
    event RoundStarted(uint256 indexed epoch);
    event RoundLocked(uint256 indexed epoch, int256 price);
    event RoundEnded(uint256 indexed epoch, int256 price);
    event RoundEndedCancelled(uint256 indexed epoch);
    event BearBet(address indexed sender, uint256 indexed epoch, uint256 amount);
    event BullBet(address indexed sender, uint256 indexed epoch, uint256 amount);
    event Refunded(address indexed sender, uint256 indexed epoch, uint256 amount);
    event Claimed(address indexed sender, uint256 indexed epoch, uint256 amount);
    event Paused(uint256 indexed epoch);
    event Unpaused(uint256 indexed epoch);
    event RoundDuratioUpdated(uint256 roundDuration);
    event MinBetAmountUpdated(uint256 indexed epoch, uint256 minBetAmount);

    //Statics
    uint256 internal bullBetsCount;
    uint256 internal bullBetsTotal;
    uint256 internal bearBetsCount;
    uint256 internal bearBetsTotal;
    uint256 internal paidBetsCount;
    uint256 internal paidBetsTotal;

    // Operator
    address internal operator;

    // Referrals 
    CandleGenieReferrals Referrals;
    uint256 public referralRate;

    receive() external payable {}


    modifier onlyOwnerOrOperator() 
    {
        require(msg.sender == owner() || msg.sender == operator, "Caller is not owner or operator");
        _;
    }

    modifier notContract() 
    {
        require(!_isContract(msg.sender), "Contracts not allowed");
        require(msg.sender == tx.origin, "Proxy contracts not allowed");
        _;
    }

    // INTERNAL FUNCTIONS ---------------->
    
    function _isContract(address addr) internal view returns (bool) 
    {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
    
    function _safeTransferBNB(address payable to, uint256 amount) internal 
    {
        to.transfer(amount);
    }

    function _safeStartRound(uint256 epoch, uint256 houseBetBullAmount, uint256 houseBetBearAmount) internal 
    {

        Round storage rounde = Rounds[epoch];
        rounde.epoch = epoch;

        rounde.startTimestamp = uint32(block.timestamp);
        rounde.lockTimestamp =  uint32(block.timestamp + roundDuration);
        rounde.closeTimestamp =  uint32(block.timestamp + (2 * roundDuration));

        if (houseBetBullAmount > 0 && houseBetBearAmount > 0)
        {
            rounde.bullAmount += houseBetBullAmount;
            rounde.bearAmount += houseBetBearAmount;
        }

        emit RoundStarted(epoch);
    }

    function _safeLockRound(uint256 epoch, int256 price) internal 
    {
        Round storage round = Rounds[epoch];
        round.lockPrice = price;
        emit RoundLocked(epoch, price);

    }

    function _safeEndRound(uint256 epoch, int256 price) internal 
    {
        Round storage round = Rounds[epoch];
        round.closePrice = price;
        round.closed = true;
        
        emit RoundEnded(epoch, price);
    }

    function _calculateRewards(uint256 epoch) internal 
    {
        
        Round storage round = Rounds[epoch];
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;

        uint256 totalAmount = round.bullAmount + round.bearAmount;
        
        // Bull wins
        if (round.closePrice > round.lockPrice) 
        {
            rewardBaseCalAmount = round.bullAmount;
            rewardAmount = totalAmount * rewardRate / 100;
        }
        // Bear wins
        else if (round.closePrice < round.lockPrice) 
        {
            rewardBaseCalAmount = round.bearAmount;
            rewardAmount = totalAmount * rewardRate / 100;
        }
        
        round.rewardBaseCalAmount = rewardBaseCalAmount;
        round.rewardAmount = rewardAmount;

    }

    function _safeCancelRound(uint256 epoch) internal 
    {
        Round storage round = Rounds[epoch];
        round.cancelled = true;
        round.closed = false;
        emit RoundEndedCancelled(epoch);
    }

    function _safeClaim(uint256[] calldata epochs) internal
    {
        
        uint256 amountToClaim; 

        for (uint256 i = 0; i < epochs.length; i++) 
        {
            // Reward
            if (claimable(epochs[i], msg.sender))
            {
                Round memory round = Rounds[epochs[i]];
                uint256 rewardAmount = (Bets[epochs[i]][msg.sender].amount * round.rewardAmount) / round.rewardBaseCalAmount;
                // Mark
                Bets[epochs[i]][msg.sender].claimed = true;
                Bets[epochs[i]][msg.sender].claimTimestamp = block.timestamp;
                // Sum
                amountToClaim += rewardAmount;
                //Stats
                paidBetsCount++;
                paidBetsTotal += rewardAmount;
                // Emit
                emit Claimed(msg.sender, epochs[i], rewardAmount);
            }
        }

        require(amountToClaim > 0, "Not found any eligible rewards");

        if (amountToClaim > 0) 
        {
            _safeTransferBNB(payable(msg.sender), amountToClaim);
        }

    }

    function _safeRefund(uint256[] calldata epochs) internal
    {
        uint256 amountToRefund; 

        for (uint256 i = 0; i < epochs.length; i++) 
        {
            // Refund
            if (refundable(epochs[i], msg.sender))
            {
                uint256 refundAmount = Bets[epochs[i]][msg.sender].amount;
                // Mark
                Bets[epochs[i]][msg.sender].claimed = true;
                Bets[epochs[i]][msg.sender].claimTimestamp = block.timestamp;
                // Sum
                amountToRefund += refundAmount;
                // Emit
                emit Refunded(msg.sender, epochs[i], refundAmount);
            }
            
        }

        require(amountToRefund > 0, "Not found any eligible refunds");

        if (amountToRefund > 0) 
        {
            _safeTransferBNB(payable(msg.sender), amountToRefund);
        }

    }

    function _bettable(uint256 epoch) internal view returns (bool) 
    {
        return
            Rounds[epoch].startTimestamp != 0 &&
            Rounds[epoch].lockTimestamp != 0 &&
            block.timestamp > Rounds[epoch].startTimestamp &&
            block.timestamp < Rounds[epoch].lockTimestamp;
    }

    // EXTERNAL FUNCTIONS ---------------->


    function FundsInject() external payable onlyOwner {}
    
    function FundsExtract(uint256 value) external onlyOwnerOrOperator 
    {
        _safeTransferBNB(payable(owner()),  value);
    }

    function SetOperator(address _operator) external onlyOwner
    {
        operator = _operator;
    }

    function FeedOperator(uint256 value) external onlyOwnerOrOperator 
    {
        _safeTransferBNB(payable(CandleGenieOperator(operator).owner()),  value);
    }

    function SetPriceSource(string memory _priceSource) external onlyOwnerOrOperator 
    {
        require(bytes(_priceSource).length > 0, "Price source can not be empty");
        priceSource = _priceSource;
    }

    function SetRewardRate(uint256 _rewardRate) external onlyOwnerOrOperator 
    {
        rewardRate = _rewardRate;
    }

    function SetMinBetAmount(uint256 _minBetAmount) external onlyOwnerOrOperator 
    {
        minBetAmount = _minBetAmount;

        emit MinBetAmountUpdated(currentEpoch, minBetAmount);
    }

    function SetRoundDuration(uint256 _roundDuration) external onlyOwnerOrOperator
    {
        roundDuration = _roundDuration;
        emit RoundDuratioUpdated(_roundDuration);
    }

    function SetReferralsContract(address _referralsContract) external onlyOwnerOrOperator 
    {
        Referrals = CandleGenieReferrals(_referralsContract);
    }

    function SetReferralsRate(uint256 _rate) external onlyOwnerOrOperator 
    {
        referralRate = _rate;
    }

    function SetShowPlayers(bool _value) external onlyOwnerOrOperator 
    {
        showPlayers = _value;
    }

    // GAME FUNCTIONS ---------------->

    function Pause() external onlyOwnerOrOperator whenNotPaused 
    {
        _pause();
        emit Paused(currentEpoch);
    }

    function Resume() external onlyOwnerOrOperator whenPaused 
    {
        startOnce = false;
        lockOnce = false;
        _unpause();
        emit Unpaused(currentEpoch);
    }

    function RoundStart() external onlyOwnerOrOperator whenNotPaused 
    {
        require(!startOnce, "Start function can only run once");

        // EPOCH++
        currentEpoch++;

        _safeStartRound(currentEpoch, 0, 0);
        startOnce = true;
    }

    function RoundLock(int256 price) external onlyOwnerOrOperator whenNotPaused 
    {
        require(startOnce, "Round not started");
        require(!lockOnce, "Lock function can only run once");

        _safeLockRound(currentEpoch, price);

        // EPOCH++
        currentEpoch++;

        _safeStartRound(currentEpoch, 0, 0);
        
        lockOnce = true;
        
    }

    function RoundExecute(int256 price, uint256 houseBetBullAmount, uint256 houseBetBearAmount) external onlyOwnerOrOperator whenNotPaused 
    {                                                                                               
        require(startOnce && lockOnce,"Can only execute round after startRound and lockRound is triggered");
        require(Rounds[currentEpoch - 2].closeTimestamp != 0, "Can only execute round after previous round started");
        require(block.timestamp >= Rounds[currentEpoch - 2].closeTimestamp, "Can only execute round round after previous round ended");
        require(block.timestamp >= Rounds[currentEpoch].lockTimestamp, "Can only execute round after lock timestamp reached");
        require(block.timestamp <= Rounds[currentEpoch].closeTimestamp, "Can only execute round before current close timestamp");

        // EXECUTE
        _safeLockRound(currentEpoch, price);                                     
        _safeEndRound(currentEpoch - 1, price);                                  
        _calculateRewards(currentEpoch - 1);                                                            
      
        // EPOCH++
        currentEpoch++;                                                              

        // START
        _safeStartRound(currentEpoch, houseBetBullAmount, houseBetBearAmount);                                                                 
           
    }

    function RoundCancel(uint256 epoch) external onlyOwnerOrOperator 
    {
        _safeCancelRound(epoch);
    }


    // USER FUNCTIONS ---------------->

    function BetBull(uint256 epoch) external payable whenNotPaused nonReentrant notContract 
    {
        require(epoch == currentEpoch, "Bet is too early/late");
        require(_bettable(epoch), "Round not bettable");
        require(msg.value >= minBetAmount, "Bet amount must be greater than minimum amount");
        require(Bets[epoch][msg.sender].amount == 0, "Can only bet once per round");

        uint256 amount = msg.value;
        Round storage round = Rounds[epoch];
        round.bullAmount = round.bullAmount + amount;

        // Bet
        Bet storage bet = Bets[epoch][msg.sender];
        bet.position = Position.Bull;
        bet.amount = amount;
        bet.betTimestamp = block.timestamp;
        UserBets[msg.sender].push(epoch);

        // Stats
        bullBetsCount++;
        bullBetsTotal += amount;

        // Players
        if (showPlayers)
        {
            round.players.push(msg.sender);
        }

        // Referrals
        if (address(Referrals) != address(0))
        {
            Referrals.HandleReferral(msg.sender, amount, referralRate);
        }

        emit BullBet(msg.sender, currentEpoch, amount);
    }
    
    
    function BetBear(uint256 epoch) external payable whenNotPaused nonReentrant notContract 
    {
        require(epoch == currentEpoch, "Bet is too early/late");
        require(_bettable(epoch), "Round not bettable");
        require(msg.value >= minBetAmount, "Bet amount must be greater than minimum amount");
        require(Bets[epoch][msg.sender].amount == 0, "Can only bet once per round");
 
        uint256 amount = msg.value;
        Round storage round = Rounds[epoch];
        round.bearAmount = round.bearAmount + amount;

        // Bet
        Bet storage bet = Bets[epoch][msg.sender];
        bet.position = Position.Bear;
        bet.amount = amount;
        bet.betTimestamp = block.timestamp;
        UserBets[msg.sender].push(epoch);

        // Stats
        bearBetsCount++;
        bearBetsTotal += amount;

        // Players
        if (showPlayers)
        {
            round.players.push(msg.sender);
        }

        // Referrals
        if (address(Referrals) != address(0))
        {
            Referrals.HandleReferral(msg.sender, amount, referralRate);
        }

        emit BearBet(msg.sender, epoch, amount);

    }

    function Claim(uint256[] calldata epochs) external nonReentrant notContract 
    {
        _safeClaim(epochs);
    }

    function ClaimReferred(uint256[] calldata epochs, address referrer) external nonReentrant notContract 
    {

        // Claim
        _safeClaim(epochs);
    
        // Referral Register
        if (address(Referrals) != address(0))
        {
            if (referrer != address(0))
            {
                Referrals.RegisterReferral(referrer, msg.sender);
            }   
        }

    }

    function Refund(uint256[] calldata epochs) external nonReentrant notContract 
    {
        _safeRefund(epochs);
    }


     // PUBLIC FUNCTIONS ---------------->

    function claimable(uint256 epoch, address user) public view returns (bool) 
    {
        Bet memory bet = Bets[epoch][user];
        Round memory round = Rounds[epoch];
        
        if (epoch >= currentEpoch - 1 || !round.closed || bet.amount <= 0 || bet.claimed || round.lockPrice <= 0 || round.closePrice <= 0  || round.lockPrice == round.closePrice) 
        {
            return false;
        }
        
        bool isBullWin = round.closePrice > round.lockPrice && bet.position == Position.Bull;
        bool isBearWin = round.closePrice < round.lockPrice && bet.position == Position.Bear;
        
        return isBullWin || isBearWin;

    }
    
    function refundable(uint256 epoch, address user) public view returns (bool) 
    {
        Bet memory bet = Bets[epoch][user];
        Round memory round = Rounds[epoch];
        
        if (epoch >= currentEpoch - 1 || bet.amount <= 0 || bet.claimed || round.closeTimestamp <= 0 || block.timestamp < round.closeTimestamp + 5) 
        {
            return false;
        }

        bool isRoundNotClosed = !round.closed;
        bool isRoundCancelled = round.cancelled;
        bool isTied = round.lockPrice > 0 && round.closePrice > 0 && round.lockPrice == round.closePrice;
        bool isInvalid = round.lockPrice == 0 && round.closePrice == 0;

        return isRoundNotClosed || isRoundCancelled || isTied || isInvalid;
    }

    function getUserRounds(address user, uint256 cursor, uint256 size) external view returns (uint256[] memory, Bet[] memory, uint256)
    {
        uint256 length = size;

        if (length > UserBets[user].length - cursor) 
        {
            length = UserBets[user].length - cursor;
        }

        uint256[] memory epochs = new uint256[](length);
        Bet[] memory bets  = new Bet[](length);

        for (uint256 i = 0; i < length; i++) 
        {
            epochs[i] = UserBets[user][cursor + i];
            bets[i] = Bets[epochs[i]][user];
        }

        return (epochs, bets, cursor + length);
    }
    
    function getRound(uint256 epoch) external view returns (Round memory) {
        return Rounds[epoch];
    }

    function getUserRoundsLength(address user) external view returns (uint256) {
        return UserBets[user].length;
    }

    function getRoundPlayers(uint256 epoch) external view returns (address[] memory) {
        return Rounds[epoch].players;
    }

    function getStats() external view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        return (bullBetsCount, bullBetsTotal, bearBetsCount, bearBetsTotal, paidBetsCount, paidBetsTotal);
    }


}