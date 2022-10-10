/**
 *Submitted for verification at Etherscan.io on 2022-10-10
*/

/**
 *Submitted for verification at Etherscan.io on 2022-10-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract ChokinfoLottery {
    using SafeMath for uint256;
    IERC20 public token_CKIO;
    address erctoken = 0x58a90728E4Fdc6cF5dd337FD23D1014d82BF0fc7; /** 9 decimal main token address **/
    uint256 public PERCENTS_DIVIDER = 1000;
    uint256 public GESTION        = 100; /** 100 = 10% **/
    uint256 public BURN           = 150; /**  150 = 15% **/
    uint256 public CONTRAT        = 50; /**  50 = 5% **/
    uint256 public STACKOIN       = 50; /**  50 = 5% **/
    uint256 public GROS_LOTS      = 50; /**  50 = 5% **/
    uint256 public PLAY_TO_EARN   = 100; /**  100 = 10% **/
    uint256 public MIN_BUY = 100 ether; /** 100 CKIO **/
    uint256 public MAX_BUY = 10000 ether; /** 10 000 CKIO **/

    /* lottery */
	bool public LOTTERY_ACTIVATED;
    uint256 public LOTTERY_START_TIME;
    uint256 public LOTTERY_PERCENT = 580; /** 50% du CKIO sera envoyé au gagnant **/
    uint256 public LOTTERY_STEP = 10 * 60 ; /** Loterie se lance toute les 10min **/
    uint256 public LOTTERY_TICKET_PRICE = 100 ether; /** Prix d'un ticket = 100 CKIO **/
    uint256 public MAX_LOTTERY_TICKET = 100; /** 100 ticket max = 10 000 CKIO **/
    uint256 public MAX_LOTTERY_PARTICIPANTS = 30; 
    uint256 public lotteryRound = 0;
    uint256 public currentPot = 0;
    uint256 public participants = 0;
    uint256 public totalTickets = 0;

    /* statistics */
    uint256 public totalLotteryBonus;
    uint256 public totalEntries;

    /* addresses */
    address payable public Gestion;
    address payable public Burn;
    address payable public Contrat;
    address payable public StacKoin;
    address payable public Gros_lots;
    address payable public Play_to_Earn;


    struct User {
        uint256 userTotalEntries;
        uint256 totalLotteryBonus;
    }

    struct LotteryHistory {
        uint256 round;
        address winnerAddress;
        uint256 pot;
        uint256 totalLotteryParticipants;
        uint256 totalLotteryTickets;
    }

    LotteryHistory[] internal lotteryHistory;
    mapping(address => User) public users;
    mapping(uint256 => mapping(address => uint256)) public ticketOwners; /** round => address => amount of owned points **/
    mapping(uint256 => mapping(uint256 => address)) public participantAdresses; /** round => id => address **/
    event LotteryWinner(address indexed investor, uint256 pot, uint256 indexed round);

    constructor(address payable _Gestion, address payable _Burn, address payable _Contrat, address payable _StacKoin, address payable _Gros_lots, address payable _Play_to_Earn) {
        Gestion = _Gestion;
        Burn = _Burn;
        Contrat = _Contrat;
        StacKoin = _StacKoin;
        Gros_lots = _Gros_lots;
        Play_to_Earn = _Play_to_Earn;
        token_CKIO = IERC20(erctoken);
    }

    /** lottery **/
    function LOTTERY_STARTED(bool value) public {
        require(msg.sender == Gestion, "Admin use only.");
        LOTTERY_ACTIVATED = value;
        LOTTERY_START_TIME = block.timestamp;
    }

    /** transfer amount of SPO **/
    function gamble(uint256 amount) public payable{
        require(LOTTERY_ACTIVATED);
        require(amount >= MIN_BUY && amount <= MAX_BUY, "MIN/MAX requirement not satisfied.");
        User storage user = users[msg.sender];
        token_CKIO.transferFrom(address(msg.sender), address(this), amount);
        user.userTotalEntries = user.userTotalEntries.add(amount);
        totalEntries = totalEntries.add(amount);
		_buyTickets(msg.sender, amount);
    }

    /** lottery section! **/
    function _buyTickets(address userAddress, uint256 amount) private {
        require(amount != 0, "zero purchase amount");
        uint256 userTickets = ticketOwners[lotteryRound][userAddress];
        uint256 numTickets = amount.div(LOTTERY_TICKET_PRICE); // 50% of deposit

        /** if the user has no tickets before this point, but they just purchased a ticket **/
        if(userTickets == 0) {
            participantAdresses[lotteryRound][participants] = userAddress;

            if(numTickets > 0){
              participants = participants.add(1);
            }
        }

        if (userTickets.add(numTickets) > MAX_LOTTERY_TICKET) {
            numTickets = MAX_LOTTERY_TICKET.sub(userTickets);
        }

        ticketOwners[lotteryRound][userAddress] = userTickets.add(numTickets);
        /** 50% of deposit will be put into the pot **/
        currentPot = currentPot.add(amount.mul(LOTTERY_PERCENT).div(PERCENTS_DIVIDER));
        /** 50% of deposit will be for tax **/
        uint256 _GestionFee = amount.mul(GESTION).div(PERCENTS_DIVIDER);
        uint256 _BurnFee = amount.mul(BURN).div(PERCENTS_DIVIDER);
        uint256 _ContratFee = amount.mul(CONTRAT).div(PERCENTS_DIVIDER);
        uint256 _StacKoinFee = amount.mul(STACKOIN).div(PERCENTS_DIVIDER);
        uint256 _GrosLotsFee = amount.mul(GROS_LOTS).div(PERCENTS_DIVIDER);
        uint256 _PlayToEarnFee = amount.mul(PLAY_TO_EARN).div(PERCENTS_DIVIDER);

        token_CKIO.transfer(Gestion, _GestionFee);
        token_CKIO.transfer(Burn, _BurnFee);
        token_CKIO.transfer(Contrat, _ContratFee);
        token_CKIO.transfer(StacKoin, _StacKoinFee);
        token_CKIO.transfer(Gros_lots, _GrosLotsFee);
        token_CKIO.transfer(Play_to_Earn, _PlayToEarnFee);
        totalTickets = totalTickets.add(numTickets);

        if(block.timestamp.sub(LOTTERY_START_TIME) >= LOTTERY_STEP || participants >= MAX_LOTTERY_PARTICIPANTS){
            chooseWinner();
        }
    }

   /** will auto execute, when condition is met. buy, hatch and sell, can be triggered manually by admin if theres no user action. **/
    function chooseWinner() public {
       require(((block.timestamp.sub(LOTTERY_START_TIME) >= LOTTERY_STEP) || participants >= MAX_LOTTERY_PARTICIPANTS),
        "Lottery must run for LOTTERY_STEP or there must be MAX_LOTTERY_PARTICIPANTS particpants");
        /** only draw winner if participant > 0. **/
        if(participants != 0){
            uint256[] memory init_range = new uint256[](participants);
            uint256[] memory end_range = new uint256[](participants);

            uint256 last_range = 0;

            for(uint256 i = 0; i < participants; i++){
                uint256 range0 = last_range.add(1);
                uint256 range1 = range0.add(ticketOwners[lotteryRound][participantAdresses[lotteryRound][i]].div(1e9));

                init_range[i] = range0;
                end_range[i] = range1;
                last_range = range1;
            }

            uint256 random = _getRandom().mod(last_range).add(1);

            for(uint256 i = 0; i < participants; i++){
                if((random >= init_range[i]) && (random <= end_range[i])){

                    /** winner found **/
                    address winnerAddress = participantAdresses[lotteryRound][i];
                    User storage user = users[winnerAddress];

                    /** winner will have the prize in their claimable rewards. **/
                    uint256 reward = currentPot.mul(LOTTERY_PERCENT).div(PERCENTS_DIVIDER);
                    token_CKIO.transfer(winnerAddress, reward);

                    /** record users total lottery rewards **/
                    user.totalLotteryBonus = user.totalLotteryBonus.add(reward);
                    totalLotteryBonus = totalLotteryBonus.add(reward);

                    /** record round **/
                    lotteryHistory.push(LotteryHistory(lotteryRound, winnerAddress, reward, participants, totalTickets));
                    emit LotteryWinner(winnerAddress, reward, lotteryRound);

                    /** reset lotteryRound **/
                    currentPot = 0;
                    participants = 0;
                    totalTickets = 0;
                    LOTTERY_START_TIME = block.timestamp;
                    lotteryRound = lotteryRound.add(1);
                    break;
                }
            }
        }else{
            /** if lottery step is done but no participant, reset lottery start time. **/
            LOTTERY_START_TIME = block.timestamp;
        }
       
    }

    /**  select lottery winner **/
    function _getRandom() private view returns(uint256){
        bytes32 _blockhash = blockhash(block.number-1);
        return uint256(keccak256(abi.encode(_blockhash,block.timestamp,currentPot, block.difficulty, getBalance())));
    }

    function getLotteryHistory(uint256 index) public view returns(uint256 round, address winnerAddress, uint256 pot,
	  uint256 totalLotteryParticipants, uint256 totalLotteryTickets) {
		round = lotteryHistory[index].round;
		winnerAddress = lotteryHistory[index].winnerAddress;
		pot = lotteryHistory[index].pot;
		totalLotteryParticipants = lotteryHistory[index].totalLotteryParticipants;
		totalLotteryTickets = lotteryHistory[index].totalLotteryTickets;
	}

    function getLotteryInfo() public view returns (uint256 lotteryStartTime,  uint256 lotteryStep, uint256 lotteryCurrentPot,
	  uint256 lotteryParticipants, uint256 maxLotteryParticipants, uint256 totalLotteryTickets, uint256 lotteryTicketPrice, 
      uint256 maxLotteryTicket, uint256 lotteryPercent, uint256 round){
		lotteryStartTime = LOTTERY_START_TIME;
		lotteryStep = LOTTERY_STEP;
		lotteryTicketPrice = LOTTERY_TICKET_PRICE;
		maxLotteryParticipants = MAX_LOTTERY_PARTICIPANTS;
		round = lotteryRound;
		lotteryCurrentPot = currentPot;
		lotteryParticipants = participants;
	    totalLotteryTickets = totalTickets;
        maxLotteryTicket = MAX_LOTTERY_TICKET;
        lotteryPercent = LOTTERY_PERCENT;
	}

    function getUserInfo(address _adr) public view returns(uint256 _userTotalEntries, uint256 _totalLotteryBonus) {
         User storage user = users[_adr];
         _userTotalEntries = user.userTotalEntries;
         _totalLotteryBonus = user.totalLotteryBonus;
	}

    function getTimeStamp() public view returns (uint256) {
        return block.timestamp;
    }

    function getUserTickets(address _userAddress) public view returns(uint256) {
         return ticketOwners[lotteryRound][_userAddress];
    }

    function getLotteryTimer() public view returns(uint256) {
        return LOTTERY_START_TIME.add(LOTTERY_STEP);
    }

    function getBalance() public view returns(uint256){
        return token_CKIO.balanceOf(address(this));
    }

    function getSiteInfo() public view returns (uint256 _totalEntries, uint256 _totalLotteryBonus) {
        return (totalEntries, totalLotteryBonus);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    /** wallet addresses **/
    function CHANGE_OWNERSHIP(address value) external {
        require(msg.sender == Gestion, "Admin use only.");
        Gestion = payable(value);
    }

    function PRC_GESTION(uint256 value) external {
        require(msg.sender == Gestion, "Admin use only.");
        require(value >= 10 && value <= 150); /** 15% max **/
        GESTION = value;
    }

    function PRC_BURN(uint256 value) external {
        require(msg.sender == Gestion, "Admin use only.");
        require(value >= 10 && value <= 150); /** 15% max **/
        BURN = value;
    }

    function PRC_CONTRAT(uint256 value) external {
        require(msg.sender == Gestion, "Admin use only.");
        require(value >= 10 && value <= 150); /** 15% max **/
        CONTRAT = value;
    }

    function PRC_STACKOIN(uint256 value) external {
        require(msg.sender == Gestion, "Admin use only.");
        require(value >= 10 && value <= 150); /** 15% max **/
        STACKOIN = value;
    }

    function PRC_GROS_LOTS(uint256 value) external {
        require(msg.sender == Gestion, "Admin use only.");
        require(value >= 10 && value <= 150); /** 15% max **/
        GROS_LOTS = value;
    }

    function PRC_PLAYTOEARN(uint256 value) external {
        require(msg.sender == Gestion, "Admin use only.");
        require(value >= 10 && value <= 150); /** 15% max **/
        PLAY_TO_EARN = value;
    }

    /* lottery setters */
    function SET_LOTTERY_STEP(uint256 value) external {
        require(msg.sender == Gestion, "Admin use only.");
         /** hour conversion **/
        LOTTERY_STEP = value * 60 * 60;
    }

    function SET_LOTTERY_PERCENT(uint256 value) external {
        require(msg.sender == Gestion, "Admin use only");
        require(value >= 10 && value <= 1000); /** 100% max **/
        LOTTERY_PERCENT = value;
    }

    function SET_LOTTERY_TICKET_PRICE(uint256 value) external {
        require(msg.sender == Gestion, "Admin use only.");
        LOTTERY_TICKET_PRICE = value * 1e9;
    }

    function SET_MAX_LOTTERY_TICKET(uint256 value) external {
        require(msg.sender == Gestion, "Admin use only");
        require(value >= 1 && value <= 100);
        MAX_LOTTERY_TICKET = value;
    }

    function SET_MAX_LOTTERY_PARTICIPANTS(uint256 value) external {
        require(msg.sender == Gestion, "Admin use only.");
        require(value >= 2 && value <= 200); /** min 10, max 200 **/
        MAX_LOTTERY_PARTICIPANTS = value;
    }

    function SET_MIN_BUY(uint256 value) external {
        require(msg.sender == Gestion, "Admin use only");
        MIN_BUY = value * 1e9;
    }

    function SET_MAX_BUY(uint256 value) external {
        require(msg.sender == Gestion, "Admin use only");
        MAX_BUY = value * 1e9;
    }  
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}