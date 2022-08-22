/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

contract LotteryContract is Ownable {

    uint256 public totalLottery;
    uint256 public currentTicketId;
    uint256 public maxNumberTicketsPerBuyOrClaim;

    enum Status {
        Pending,
        Open,
        Close,
        Claim
    }

    struct Lottery {
        Status status;
        uint256 startTime;
        uint256 endTime;
        uint256 price;
        bool    pause;       
        address token;
        uint256 addFunds;
        uint256 amount;
        uint256[] ticketId;
        uint256 winningTicketBlock;
        uint256 finalNumber;
        uint256[6] rewardAmountPerBracket;
        uint256 claimedRewards;
    }

    struct Ticket {
        uint256 number;
        address owner;
        uint256 lotteryId;
    }

    mapping(uint256 => Lottery) public lotteries;
    mapping(uint256 => Ticket)  private lotteryTicket;
    mapping(uint256 => uint256) private bracketCalculator;

    mapping(address => mapping(uint256 => uint256[])) private userTicketIdsPerLotteryId;
    mapping(uint256 => mapping(uint256 => uint256)) public numberTicketsPerLotteryId;

    mapping(uint256 =>  mapping(uint256 => bool)) public ticketNumber;

    event StartLottery(uint256 indexed lotteryId, uint256 startTime, uint256 endTime, uint256 price, address token);
    // event CloseLottery(uint256 indexed lotteryId, uint256 time);
    event PurchaseTicket(uint256 indexed lotteryId, address indexed buyer, uint256 price, uint256 totalTickets,  uint256 time);
    event GiftTicket(address owner, address receipent, uint256 ticketId, uint256 lotteryId); 
    event AdminGiveTicket(address receipent, uint256 totalTickets, uint256 lotteryId, uint256 time);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
    event AddFunds(uint256 indexed lotteryId, uint256 amount);
    event TicketsClaim(address account, uint256 rewards, uint256 lotteryId, uint256 totalTickets, uint256 time);
    event LotteryDrawn(uint256 lotteryId, uint256 finalNumber, uint256 time);

    
    constructor(){
        bracketCalculator[1] = 1;
        bracketCalculator[2] = 11;
        bracketCalculator[3] = 111;
        bracketCalculator[4] = 1111;
        bracketCalculator[5] = 11111;
        bracketCalculator[6] = 111111;   
    }


    function startLottery(uint256 _endTime, uint256 _startTime, uint256 _price, address _token, uint256[6] memory _reward) public onlyOwner {
        require(block.timestamp <= _startTime && _endTime > _startTime, "Invalid Time");
        require(_price > 0, "Price must be greater than 0");      
        Lottery memory lotteryInfo;
        lotteryInfo = Lottery ({
            status: Status.Open,
            startTime : _startTime,
            endTime   : _endTime,
            price     : _price,
            pause     : false,         
            amount    : 0,
            token     : _token,
            addFunds  : 0,           
            ticketId :  new uint256[](0),
            winningTicketBlock : 0,
            finalNumber :0,
            rewardAmountPerBracket : _reward,
            claimedRewards : 0         
        });
        lotteries[totalLottery] = lotteryInfo;
        totalLottery++;
        emit StartLottery(totalLottery, _startTime, _endTime, _price, _token);
    }

    function currentLotteryId() public view returns(uint256 id){
        for(uint256 i = 0; i < totalLottery; i++){
            if(block.timestamp > lotteries[i].startTime && block.timestamp < lotteries[i].endTime){
                id = i;
            }
        }
        return id;
    }

    // function closeLottery(uint256 _lotteryId) public onlyOwner {
    //   require(block.timestamp > lotteries[_lotteryId].startTime, "Lottery already started");
    //   require(lotteries[_lotteryId].status == Status.Open, "Lottery not open");
    //   lotteries[_lotteryId].status = Status.Close;
    //   emit CloseLottery( _lotteryId, block.timestamp);
    // }

    function adminGiveFreeTickets(uint256 _lotteryId, uint256[] memory _ticketNumber, address _receipent) public onlyOwner{
        require(_ticketNumber.length != 0, "No ticket specified");
        require(_ticketNumber.length <= maxNumberTicketsPerBuyOrClaim, "Too many tickets");
        for (uint256 i = 0; i < _ticketNumber.length; i++) {
            require(!ticketNumber[_ticketNumber[i]][_lotteryId],"This number already exist");
            uint256 thisTicketNumber = _ticketNumber[i];
            numberTicketsPerLotteryId[_lotteryId][1 + (thisTicketNumber % 10)]++;
            numberTicketsPerLotteryId[_lotteryId][11 + (thisTicketNumber % 100)]++;
            numberTicketsPerLotteryId[_lotteryId][111 + (thisTicketNumber % 1000)]++;
            numberTicketsPerLotteryId[_lotteryId][1111 + (thisTicketNumber % 10000)]++;
            numberTicketsPerLotteryId[_lotteryId][11111 + (thisTicketNumber % 100000)]++;
            numberTicketsPerLotteryId[_lotteryId][111111 + (thisTicketNumber % 1000000)]++;
            userTicketIdsPerLotteryId[_receipent][_lotteryId].push(currentTicketId);
            lotteryTicket[currentTicketId] = Ticket({number: thisTicketNumber, owner: _receipent, lotteryId : _lotteryId});
            (lotteries[_lotteryId].ticketId).push(currentTicketId);
            currentTicketId++; 
            ticketNumber[_ticketNumber[i]][_lotteryId] = true;          
        }
        emit AdminGiveTicket(_receipent,_ticketNumber.length, _lotteryId, block.timestamp); 
    }

    function pauseLottery(uint256 _lotteryId) public onlyOwner {
        lotteries[_lotteryId].pause = !lotteries[_lotteryId].pause;
    }

    function changeRewardPer(uint256 _lotteryId, uint256[6] memory _per) public onlyOwner {
        lotteries[_lotteryId].rewardAmountPerBracket = _per;
    }

    function setMaxNumberTicketsPerBuy(uint256 _maxNumberTicketsPerBuy) public onlyOwner {
        require(_maxNumberTicketsPerBuy != 0, "Must be > 0");
        maxNumberTicketsPerBuyOrClaim = _maxNumberTicketsPerBuy;
    }

    function addFunds(uint256 _lotteryId, uint256 _amount) public onlyOwner {
        require(lotteries[_lotteryId].status == Status.Open, "Lottery not open");
        require(block.timestamp < lotteries[_lotteryId].endTime, "Lottery Ended");
        IERC20(lotteries[_lotteryId].token).transferFrom(msg.sender, address(this), _amount);
        lotteries[_lotteryId].addFunds += _amount;
        emit AddFunds(_lotteryId, _amount);
    }

    function withdrawFunds(uint256 _amount, address _token) public onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }

    function drawnLottery(uint256 _lotteryId) public onlyOwner{
        require(lotteries[_lotteryId].token != address(0), "Lottery not exist");
        require(lotteries[_lotteryId].finalNumber == 0, "Already Drawn");
        lotteries[_lotteryId].status = Status.Close;
        lotteries[_lotteryId].finalNumber = uint(keccak256(abi.encodePacked(_lotteryId , blockhash(lotteries[_lotteryId].winningTicketBlock)))) % 1000000;      
        lotteries[_lotteryId].status = Status.Claim;
        emit LotteryDrawn(_lotteryId,  lotteries[_lotteryId].finalNumber, block.timestamp);
    }

    function buyTickets(uint256 _lotteryId, uint256[] memory _ticketNumber, uint256 _amount) public {
        require(_ticketNumber.length != 0, "No ticket specified");
        require(_ticketNumber.length <= maxNumberTicketsPerBuyOrClaim, "Too many tickets");
        require(!lotteries[_lotteryId].pause,"Lottery is paused");
        require(lotteries[_lotteryId].status == Status.Open, "Lottery is not open");
        uint256 amount = lotteries[_lotteryId].price * _ticketNumber.length;
        require(_amount >= amount, "Less Amount");
        IERC20(lotteries[_lotteryId].token).transferFrom(msg.sender, address(this), amount);
        lotteries[_lotteryId].amount += _amount;
        
        for (uint256 i = 0; i < _ticketNumber.length; i++) {
            require(!ticketNumber[_ticketNumber[i]][_lotteryId],"This number already exist");
            uint256 thisTicketNumber = _ticketNumber[i];
            numberTicketsPerLotteryId[_lotteryId][1 + (thisTicketNumber % 10)]++;
            numberTicketsPerLotteryId[_lotteryId][11 + (thisTicketNumber % 100)]++;
            numberTicketsPerLotteryId[_lotteryId][111 + (thisTicketNumber % 1000)]++;
            numberTicketsPerLotteryId[_lotteryId][1111 + (thisTicketNumber % 10000)]++;
            numberTicketsPerLotteryId[_lotteryId][11111 + (thisTicketNumber % 100000)]++;
            numberTicketsPerLotteryId[_lotteryId][111111 + (thisTicketNumber % 1000000)]++;
            userTicketIdsPerLotteryId[msg.sender][_lotteryId].push(currentTicketId);
            lotteryTicket[currentTicketId] = Ticket({number: thisTicketNumber, owner: msg.sender, lotteryId : _lotteryId});
            (lotteries[_lotteryId].ticketId).push(currentTicketId);

            currentTicketId++; 
            lotteries[_lotteryId].winningTicketBlock = block.number + 1;
            ticketNumber[_ticketNumber[i]][_lotteryId] = true;          
        }
        emit PurchaseTicket(_lotteryId, msg.sender, amount, _ticketNumber.length, block.timestamp);            
    }

    
    function claimTickets(uint256 _lotteryId, uint256[] calldata _ticketIds, uint256[] calldata _brackets) external{
        require(_ticketIds.length == _brackets.length, "Not same length");
        require(_ticketIds.length <= maxNumberTicketsPerBuyOrClaim, "Too many tickets");
        require(_ticketIds.length != 0, "Length must be >0");
        require(lotteries[_lotteryId].status == Status.Claim, "Lottery not claimable");
        uint256 rewardInCakeToTransfer;
        for (uint256 i = 0; i < _ticketIds.length; i++) {
            require(_brackets[i] < 6, "Bracket out of range"); // Must be between 0 and 5
            uint256 thisTicketId = _ticketIds[i];
            require(msg.sender == lotteryTicket[thisTicketId].owner, "Not the owner");
            lotteryTicket[thisTicketId].owner = address(0);
            (,uint256 rewardForTicketId) = viewTicketIdRewards(thisTicketId, _lotteryId);
            rewardInCakeToTransfer += rewardForTicketId;
        }
        if(rewardInCakeToTransfer != 0){ 
            lotteries[_lotteryId].claimedRewards += rewardInCakeToTransfer;     
            // Transfer money to msg.sender
            IERC20(lotteries[_lotteryId].token).transfer(msg.sender, rewardInCakeToTransfer);
        }else{
            require(rewardInCakeToTransfer != 0, "No prize for this bracket");
        }
        emit TicketsClaim(msg.sender, rewardInCakeToTransfer, _lotteryId, _ticketIds.length,block.timestamp);
    }

    function giftTicket(address _receipent, uint256 _ticketId) public {
        require(lotteryTicket[_ticketId].owner == msg.sender, "You are not owner");
        lotteryTicket[_ticketId].owner = _receipent;
        for (uint256 i = 0; i < userTicketIdsPerLotteryId[msg.sender][lotteryTicket[_ticketId].lotteryId].length; i++){
            if( userTicketIdsPerLotteryId[msg.sender][lotteryTicket[_ticketId].lotteryId][i] == _ticketId){
                userTicketIdsPerLotteryId[msg.sender][lotteryTicket[_ticketId].lotteryId][i] =  userTicketIdsPerLotteryId[msg.sender][lotteryTicket[_ticketId].lotteryId][ userTicketIdsPerLotteryId[msg.sender][lotteryTicket[_ticketId].lotteryId].length-1];
                delete userTicketIdsPerLotteryId[msg.sender][lotteryTicket[_ticketId].lotteryId][ userTicketIdsPerLotteryId[msg.sender][lotteryTicket[_ticketId].lotteryId].length-1];
                break;
            }
        }
        userTicketIdsPerLotteryId[_receipent][lotteryTicket[_ticketId].lotteryId].push(_ticketId);
        emit GiftTicket(msg.sender, _receipent, _ticketId, lotteryTicket[_ticketId].lotteryId);  
    }

    function reverse(uint256 num) private pure returns(uint256){
        uint256 reverseNum;
        while(num>0){
            uint256 rem = num % 10;
            reverseNum = reverseNum * 10 + rem;
            num /= 10;
        }
        return reverseNum;
    }

    function viewTicketIdRewards(uint256 _ticketId, uint256 _lotteryId) public view returns(uint256, uint256){
        uint256 winningNumber = lotteries[_lotteryId].finalNumber;
        uint256 j=0;
        for (uint256 i = 6; i >= 1; i--) {
            if(reverse(lotteryTicket[_ticketId].number) % (10**(i)) == reverse(winningNumber) % (10**(i))){
                j=i;
                break;
            }
        }
        if(j == 0){
            return (j,0);
        } else {
            uint256 totalUser = numberTicketsPerLotteryId[_lotteryId][bracketCalculator[j] + (winningNumber % 10 ** (j))];      
            uint256 totalAmount = (lotteries[_lotteryId].amount + lotteries[_lotteryId].addFunds) - lotteries[_lotteryId].claimedRewards;
            uint256 rewards = (totalAmount * lotteries[_lotteryId].rewardAmountPerBracket[j - 1] / 100) /  totalUser;
            return (j,rewards);
        }     
    }

    function setFinalNumber (uint256 finalNumber, uint256 _lotteryId) public {
        lotteries[_lotteryId].finalNumber = finalNumber;
    }

    function viewCountWinnersInLottery(uint256 _lotteryId)external view returns (uint256[] memory, uint256[] memory){      
        uint256[] memory countWinner = new uint256[](6); 
        uint256[] memory rewardPerBracket = new uint256[](6); 
        uint256 totalAmount = (lotteries[_lotteryId].amount + lotteries[_lotteryId].addFunds) - lotteries[_lotteryId].claimedRewards;     
        for (uint256 i = 0; i < 6; i++) {
            countWinner[i] = numberTicketsPerLotteryId[_lotteryId][bracketCalculator[i+1] + (lotteries[_lotteryId].finalNumber % 10 ** (i+1))];             
            rewardPerBracket[i] = (totalAmount * lotteries[_lotteryId].rewardAmountPerBracket[i] / 100);
        }
        return (countWinner, rewardPerBracket);
    }

    function viewNumbersAndStatusesForTicketIds(uint256[] calldata _ticketIds)external view returns (uint256[] memory, bool[] memory){
        uint256 length = _ticketIds.length;
        uint256[] memory ticketNumbers = new uint256[](length);
        bool[] memory ticketStatuses = new bool[](length);
        for (uint256 i = 0; i < length; i++) {
            ticketNumbers[i] = lotteryTicket[_ticketIds[i]].number;
            if (lotteryTicket[_ticketIds[i]].owner == address(0)) {
                ticketStatuses[i] = true;
            } else {
                ticketStatuses[i] = false;
            }
        }
        return (ticketNumbers, ticketStatuses);
    }

    function viewUserInfoForLotteryId(address _user, uint256 _lotteryId)external view returns (uint256[] memory, uint256[] memory, bool[] memory, uint256){      
        uint256 numberTicketsBoughtAtLotteryId = userTicketIdsPerLotteryId[_user][_lotteryId].length;
        uint256[] memory lotteryTicketIds = new uint256[](numberTicketsBoughtAtLotteryId);
        uint256[] memory ticketNumbers = new uint256[](numberTicketsBoughtAtLotteryId);
        bool[] memory ticketStatuses = new bool[](numberTicketsBoughtAtLotteryId);
        for (uint256 i = 0; i < numberTicketsBoughtAtLotteryId; i++) {
            lotteryTicketIds[i] = userTicketIdsPerLotteryId[_user][_lotteryId][i];
            ticketNumbers[i] = lotteryTicket[lotteryTicketIds[i]].number;
            if (lotteryTicket[lotteryTicketIds[i]].owner == address(0)) {
                ticketStatuses[i] = true;
            } else {
                ticketStatuses[i] = false;
            }
        }
        return (lotteryTicketIds, ticketNumbers, ticketStatuses, numberTicketsBoughtAtLotteryId);
    }

    function viewRewardPer(uint256 _lotteryId) public view returns(uint256[6] memory){
        return lotteries[_lotteryId].rewardAmountPerBracket;
    }
}