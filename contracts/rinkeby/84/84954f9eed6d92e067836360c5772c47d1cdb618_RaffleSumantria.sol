//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.12;

//libraries contracts
import "./IERC20.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./console.sol";

//chainlink
import "./VRFConsumerBase.sol";


contract RaffleSumantria is Ownable, VRFConsumerBase {

    event SetRaffle(
        address indexed user,
        string _name,
        uint256 _startDate,
        address _tokenAddress,
        uint256 _prizeAmount,
        uint256 _ticketsLimit,
        uint256 _ticketPrice,
        uint256 _lockDays,
        string _status,
        bool _canceled
    );

    event ActivateRaffle(
        address indexed user,
        uint256 indexed _raffleId
    );

    event CancelRaffle(
        address indexed user,
        uint256 indexed _raffleId
    );

    event SetRaffleName(
        address indexed user,
        uint256 indexed _raffleId,
        string _name
    );

    event SetRaffleStartDate(
        address indexed user,
        uint256 indexed _raffleId,
        uint256 _startDate
    );

    event SetRaffleTokenAddress(
        address indexed user,
        uint256 indexed _raffleId,
        address _tokenAddress
    );

    event SetRafflePrizeAmount(
        address indexed user,
        uint256 indexed _raffleId,
        uint256 _prizeAmount
    );

    event SetRaffleTicketsLimit(
        address indexed user,
        uint256 indexed _raffleId,
        uint256 _ticketsLimit
    );

    event SetRaffleTicketPrice(
        address indexed user,
        uint256 indexed _raffleId,
        uint256 _ticketPrice
    );

    event SetRaffleLockDays(
        address indexed user,
        uint256 indexed _raffleId,
        uint256 _lockDays
    );

    event SetRaffleStatus(
        address indexed user,
        uint256 indexed _raffleId,
        string _status
    );

    event SetRequiredRaffleLink(
        address indexed user,
        uint256 _requireRaffleLink
    );

    event AddPercentage(
        address indexed user,
        uint256 indexed _raffleId,
        uint256 _index,
        uint256 _percentage
    );

    event RemovePercentage(
        address indexed user,
        uint256 indexed _raffleId,
        uint256 _index
    );

    event BuyTickets(
        address indexed user,
        uint256 indexed _raffleId,
        uint256 _ticketsNumber
    );

    event WithdrawTickets(
        address indexed user,
        uint256 indexed _raffleId,
        uint256 _ticketsNumber
    );

    event RequestedRandomness(bytes32 requestId);

    event RaffleWinner(
        address indexed user,
        uint256 indexed _raffleId,
        uint256 _amount
    );

    event WithdrawOwnerFunds(
        address indexed user,
        uint256 indexed _raffleId,
        uint256 _amount
    );

    event RandomRequestFullfiled(
        bytes32 indexed _requestId,
        uint256 _random
    );
    
    event DecidingRaffle(
        bytes32 indexed _requestId
    );

    modifier beforeRaffleStart(uint256 _raffleId) {
        require(
            block.timestamp < raffles[_raffleId].startDate,
            "Raffle: you cannot update raffle parameters after it has started!"
        );
        _;
    }

    modifier checkTicketsAcquisition(uint256 _raffleId, uint256 _ticketsNumber) {
        require(
            raffles[_raffleId].canceled == false,
            "Raffle: this raffle is canceled!"
        );
        require(
            keccak256(bytes(raffles[_raffleId].status)) !=
                keccak256(bytes("ended")),
            "Raffle: this raffle has ended!"
        );
        require(
            raffleTickets[_raffleId].length.add(_ticketsNumber) <=
                raffles[_raffleId].ticketsLimit,
            "Raffle: you need to buy less tickets"
        );
        require(
            raffles[_raffleId].startDate < block.timestamp,
            "Raffle: the raffle has not started yet"
        );
        _;
    }

    /*
        @dev Raffle structure members:

            name (string) -> the name of the raffle

            startDate (uint256 timestamp) -> the date when users will be able to buy tickets for the raffle

            tokenAddress (address) -> address of the token wich will be used as currency for this raffle

            prizeAmount (uint256) -> the amount of tokens that will be shared among winners 
                                  -> the decimals of the prize should have the same length as the token's decimals

            ticketsLimit (uint256) -> the maximum number of tokens that can be bought

            ticketPrice (uint256) -> the price of one raffle ticket
                                  -> the decimals of the price should have the same length as the token's decimals
            
            lockDays (uint256) -> the number of days in wich the users will not be able to refund their tickets

            status (string) -> the status of the raffle: ongoing / ended
            
            canceled (bool) -> true if the raffle is canceled, false otherwise 
    */

    struct Raffle {
        string name;
        uint256 startDate;
        address tokenAddress;
        uint256 prizeAmount;
        uint256 ticketsLimit;
        uint256 ticketPrice;
        uint256 lockDays;
        string status;
        bool canceled;
        uint256 totalPercentage;
    }

    struct Ticket {
        uint256 timeWhenBought;
        address owner;
    }

    struct RaffleRandom {
        uint256 raffleId;
        uint256 random;
    }

    /* main raffles array */
    Raffle[] public raffles;

    /* active raffles array */
    uint256[] public active_raffles;

    /* mapping from main raffles array index to active raffle index */
    mapping(uint256 => uint256) active_raffles_index;

    /* mapping from main raffles array index to an array of percentages wich represents how the prize amount is divided among winners */
    mapping(uint256 => uint256[]) public percentagesToWin;

    /* mapping from raffle id to tickets bought for it */
    mapping(uint256 => Ticket[]) public raffleTickets;

    /* storing raffle id and random number for each requrest */
    mapping(bytes32 => RaffleRandom) randomRequests;

    /* mapping from user address to tickets bought by him for a specific raffle id*/
    mapping(address => mapping(uint256 => uint256[])) public userTickets;


    address public immutable linkTokenContractAddress;
    IERC20 private immutable linkToken;

    address private immutable vrfCoordinatorAddress;
    uint256 public requiredRaffleLink = 0;

    bytes32 private keyHash;

    constructor(
        bytes32 _keyHash,
        address _vrfCoordinatorAddress,
        address _linkTokenContractAddress,
        uint256 _requiredRaffleLink
    )
        public
        VRFConsumerBase(_vrfCoordinatorAddress, _linkTokenContractAddress)
    {
        keyHash = _keyHash;
        linkTokenContractAddress = _linkTokenContractAddress;
        linkToken = IERC20(_linkTokenContractAddress);
        vrfCoordinatorAddress = _vrfCoordinatorAddress;
        requiredRaffleLink = _requiredRaffleLink;
    }

    function _checkRaffleParameters(uint256 _startDate, uint256 _prizeAmount, uint256 _ticketsLimit) internal view {
        require(_startDate > block.timestamp, "Raffle: raffle's start date should be in the future!");
        require(_prizeAmount > 0, "Raffle: raffle's prize amount should be greater than 0!");
        require(_ticketsLimit > 0, "Raffle: raffle's tickets limit should be greater than 0!");
    }

    function setRaffle(
        string memory _name,
        uint256 _startDate,
        address _tokenAddress,
        uint256 _prizeAmount,
        uint256 _ticketsLimit,
        uint256 _ticketPrice,
        uint256 _lockDays
    ) public onlyOwner {

        _checkRaffleParameters(_startDate, _prizeAmount, _ticketsLimit);

        //check if the owner has allowed enough raffle tokens for the prize pool
        IERC20 raffleToken = IERC20(_tokenAddress);
        require(
            raffleToken.allowance(_msgSender(), address(this)) >= _prizeAmount,
            "Raffle: Insufficient tokens for prize poll"
        );
        raffleToken.transferFrom(_msgSender(), address(this), _prizeAmount);

        require(
            linkToken.allowance(_msgSender(), address(this)) >= requiredRaffleLink,
            "Raffle insufficient tokens for adding a new raffle"
        );
        linkToken.transferFrom(_msgSender(), address(this), requiredRaffleLink);

        //add raffle to the main array 
        raffles.push(
            Raffle({
                name: _name,
                startDate: _startDate,
                tokenAddress: _tokenAddress,
                prizeAmount: _prizeAmount,
                ticketsLimit: _ticketsLimit,
                ticketPrice: _ticketPrice,
                lockDays: _lockDays,
                status: "ongoing",
                //pushing the raffle as canceled so activateRaffle function will not revert
                canceled: true,
                totalPercentage: 0
            })
        );
        
        //activating the last raffle in the array
        activateRaffle(raffles.length - 1);

        emit SetRaffle(
            _msgSender(),
            _name,
            _startDate,
            _tokenAddress,
            _prizeAmount,
            _ticketsLimit,
            _ticketPrice,
            _lockDays,
            "ongoing",
            false
        );
    }

    function activateRaffle(uint256 _raffleId) public onlyOwner {
        require(raffles[_raffleId].canceled == true, "Raffle: raffle is already active!");
        raffles[_raffleId].canceled = false;
        active_raffles.push(raffles.length - 1);
        active_raffles_index[raffles.length - 1] = active_raffles.length - 1;
        emit ActivateRaffle(_msgSender(), _raffleId);
    }

    function cancelRaffle(uint256 _raffleId) public onlyOwner {
        require(active_raffles_index[_raffleId] != uint256(-1), "Raffle World: raffle is already canceled!");

        raffles[_raffleId].canceled = true;

        //index from active_raffles of the raffle pointed by _raffleId
        uint256 current_raffle_index = active_raffles_index[_raffleId];
        //index from active raffles of the last raffle from the array
        uint256 last_active_raffle_index = active_raffles_index[active_raffles[active_raffles.length - 1]];

        //replace the value pointed by the index of the current_raffle (the index of the raffle from the raffles array) with the value pointed
        //by last_active_raffle_index (the index from raffles of the last raffle from active_raffles array) 
        active_raffles[current_raffle_index] = active_raffles[last_active_raffle_index];

        //replacing the value pointed by the index of the last active raffle with the value pointed by the index of the current raffle 
        active_raffles_index[active_raffles[active_raffles.length - 1]] = active_raffles_index[_raffleId];
        //replacing the value pointed by _raffleId with a position that is not occupied in the active_raffles array
        active_raffles_index[_raffleId] = uint256(-1); 

        //removing the last raffle from active_raffles array because it has been moved on the current_raffle_index position
        active_raffles.pop();

        emit CancelRaffle(_msgSender(), _raffleId);
    }

    function setRaffleName(uint256 _raffleId, string memory _name) public onlyOwner beforeRaffleStart(_raffleId) {
        raffles[_raffleId].name = _name;
        emit SetRaffleName(_msgSender(), _raffleId, _name);
    }        

    function setRaffleStartDate(uint256 _raffleId, uint256 _startDate) public onlyOwner beforeRaffleStart(_raffleId) {
        require(_startDate > block.timestamp, "Raffle: raffle's start date should be in the future!");
        raffles[_raffleId].startDate = _startDate;
        emit SetRaffleStartDate(_msgSender(), _raffleId, _startDate);
    }

    function setRafflePrizeAmount(uint256 _raffleId, uint256 _prizeAmount) public onlyOwner beforeRaffleStart(_raffleId) {
        require(_prizeAmount > 0, "Raffle: raffle's prize amount should be greater than 0!");
        raffles[_raffleId].prizeAmount = _prizeAmount;
        emit SetRafflePrizeAmount(_msgSender(), _raffleId, _prizeAmount);
    }

    function setRaffleTicketsLimit(uint256 _raffleId, uint256 _ticketsLimit) public onlyOwner beforeRaffleStart(_raffleId) {
        require(_ticketsLimit > 0, "Raffle: raffle's tickets limit should be greater than 0!");
        raffles[_raffleId].ticketsLimit = _ticketsLimit;
        emit SetRaffleTicketsLimit(_msgSender(), _raffleId, _ticketsLimit);
    }

    function setRaffleTicketPrice(uint256 _raffleId, uint256 _ticketPrice) public onlyOwner beforeRaffleStart(_raffleId) {
        raffles[_raffleId].ticketPrice = _ticketPrice;
        emit SetRaffleTicketPrice(_msgSender(), _raffleId, _ticketPrice);
    }

    function setRaffleLockDays(uint256 _raffleId, uint256 _lockDays) public onlyOwner beforeRaffleStart(_raffleId) {
        raffles[_raffleId].lockDays = _lockDays;
        emit SetRaffleLockDays(_msgSender(), _raffleId, _lockDays);
    }

    function _setRaffleStatus(uint256 _raffleId, string memory _status) internal {
        raffles[_raffleId].status = _status;
        emit SetRaffleStatus(_msgSender(), _raffleId, _status);
    } 

    function getRafflesLength() public view returns(uint256) {
        return raffles.length;
    }

    function getActiveRafflesLength() public view returns(uint256) {
        return active_raffles.length;
    }

    function addPercentage(uint256 _raffleId, uint256 _index, uint256 _percentage) public onlyOwner beforeRaffleStart(_raffleId) {

        // if the specified index represents an occupied position in the array then we only need to change the percentage pointed by the index
        if(_index < percentagesToWin[_raffleId].length) {
            
            //we substract the percentage from the current position because its value will be changed below
            raffles[_raffleId].totalPercentage = raffles[_raffleId].totalPercentage.sub(percentagesToWin[_raffleId][_index]);

            //add the current percentage
            raffles[_raffleId].totalPercentage = raffles[_raffleId].totalPercentage.add(_percentage);

            // 2 0's are for the decimal aproximation
            require( raffles[_raffleId].totalPercentage <= 10000, "Raffle: Total percentage should be less or equal with 100");

            percentagesToWin[_raffleId][_index] = _percentage;
            
        } else{
            //if the index does not represents an occupied position, we just push it into the array
            raffles[_raffleId].totalPercentage = raffles[_raffleId].totalPercentage.add(_percentage);
            // 2 0's are for the decimal aproximation
            require( raffles[_raffleId].totalPercentage <= 10000, "Raffle: Total percentage should be less or equal with 100");
            percentagesToWin[_raffleId].push(_percentage);
        }

        emit AddPercentage(_msgSender(), _raffleId, _index, _percentage);
    }

    function removePercentage(uint256 _raffleId, uint256 _index) public onlyOwner beforeRaffleStart(_raffleId) {
        require(_index < percentagesToWin[_raffleId].length, "Raffle: the index does not represent an occupied poistion in the array");
        
        raffles[_raffleId].totalPercentage = raffles[_raffleId].totalPercentage.sub(percentagesToWin[_raffleId][_index]);

        //replacing the percentage from the current index with the last percentage from the array 
        percentagesToWin[_raffleId][_index] = percentagesToWin[_raffleId][percentagesToWin[_raffleId].length - 1];
        
        //remove the last percentage
        percentagesToWin[_raffleId].pop();

        emit RemovePercentage(_msgSender(), _raffleId, _index);
    }

    function setRequiredRaffleLink(uint256 _requiredRaffleLink) public onlyOwner {
        requiredRaffleLink = _requiredRaffleLink;
        emit SetRequiredRaffleLink(_msgSender(), _requiredRaffleLink);
    }

    function _sendRaffleWinnerMoney(uint256 _raffleId, address _winner,  uint256 _percentagesIndex)
        internal
    {
        IERC20 token = IERC20(raffles[_raffleId].tokenAddress);
        uint256 amount = percentagesToWin[_raffleId][_percentagesIndex]
            .mul(raffles[_raffleId].prizeAmount).div(10000);
        token.transfer(_winner, amount);
        emit RaffleWinner(_winner, _raffleId, amount);
    }

    function _decideRaffle(bytes32 _requestId) internal {
        emit DecidingRaffle(_requestId);
        uint256 _raffleId = randomRequests[_requestId].raffleId;
        uint256 random = randomRequests[_requestId].random;
        raffles[_raffleId].status = "ended";
        for(uint256 i = 0; i < percentagesToWin[_raffleId].length; i++) {
            //get index of the winning ticket
            uint256 index = uint256(keccak256(abi.encode(random, i))).mod(
                    raffleTickets[_raffleId].length
            );
            _sendRaffleWinnerMoney(_raffleId, raffleTickets[_raffleId][index].owner, i);
        }
    }

    //request a random number using VRF Coordinator for deciding the raffle
    function getRandomNumber(uint256 _raffleId)
        public
        returns (bytes32 requestId)
    {
        requestRandomness(keyHash, requiredRaffleLink);

        //we store the raffle id acccording to request id so we can know for wich raffle 
        //the request has finished when the callback is called 
        randomRequests[requestId] = RaffleRandom({
            raffleId: _raffleId,
            random: 0
        });
        emit RequestedRandomness(requestId);
    }

    /**
      @dev Callback function used by VRF Coordinator
    **/
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        randomRequests[requestId].random = randomness;

        emit RandomRequestFullfiled(requestId, randomness);
        _decideRaffle(requestId);
    }


    function buyTickets(uint256 _raffleId, uint256 _ticketsNumber) public checkTicketsAcquisition(_raffleId, _ticketsNumber) {

        //checks if the user has enough balance
        uint256 ticketsValue = raffles[_raffleId].ticketPrice.mul(_ticketsNumber);
        IERC20 raffleToken = IERC20(raffles[_raffleId].tokenAddress);

        require(ticketsValue <= raffleToken.allowance(_msgSender(), address(this)),
            "Raffle: you didn't provide enough tokens for the purchase to be made");

        raffleToken.transferFrom(_msgSender(), address(this), ticketsValue);

        for(uint256 i = 0; i < _ticketsNumber;  i++) {
            raffleTickets[_raffleId].push(Ticket({timeWhenBought: block.timestamp, owner: _msgSender()}));
            userTickets[_msgSender()][_raffleId].push(raffleTickets[_raffleId].length - 1);
        }

        emit BuyTickets(_msgSender(), _raffleId, _ticketsNumber);

        if(raffleTickets[_raffleId].length == raffles[_raffleId].ticketsLimit) {
            getRandomNumber(_raffleId);
        }
    }

    function withdrawTickets(uint256 _raffleId, uint256 _ticketsNumber) public {
        require(userTickets[_msgSender()][_raffleId].length > 0, "Raffle: no tickets left!");
        require(keccak256(bytes(raffles[_raffleId].status)) != keccak256(bytes("ended")), "Raffle has eneded!");

        uint256 ticketsLength = userTickets[_msgSender()][_raffleId].length - 1;
        uint256 ticketsRefunded = 0;
        uint256 day = 1 days;

        for(uint256 i = ticketsLength; i >= 0; i--) {
             //get the index from raffle tickets of the ticket pointed by i
            uint256 raffle_tickets_ticket_index = userTickets[_msgSender()][_raffleId][i];

            if(raffleTickets[_raffleId][raffle_tickets_ticket_index].timeWhenBought + raffles[_raffleId].lockDays.mul(day) <= block.timestamp) {
                //replace the ticket that needs to be removed with the last ticket
                raffleTickets[_raffleId][raffle_tickets_ticket_index] = raffleTickets[_raffleId][raffleTickets[_raffleId].length - 1];
                raffleTickets[_raffleId].pop();

                userTickets[_msgSender()][_raffleId][i] = userTickets[_msgSender()][_raffleId][userTickets[_msgSender()][_raffleId].length - 1];
                userTickets[_msgSender()][_raffleId].pop();

                ticketsRefunded = ticketsRefunded.add(1);
            }
            if(ticketsRefunded == _ticketsNumber) break;
            if(i == 0) break;
        }

        uint256 ticketsValue = raffles[_raffleId].ticketPrice.mul(ticketsRefunded);
        IERC20 raffleToken = IERC20(raffles[_raffleId].tokenAddress);
        raffleToken.transfer(_msgSender(), ticketsValue);

        emit WithdrawTickets(_msgSender(), _raffleId, ticketsRefunded);
    }

    function withdrawOwnerFunds(uint256 _raffleId)
        external
        onlyOwner
    {
        IERC20 raffleToken = IERC20(raffles[_raffleId].tokenAddress);
        uint256 ownerFunds = raffles[_raffleId].ticketPrice.mul(raffles[_raffleId].ticketsLimit).sub(raffles[_raffleId].prizeAmount);
        require(
            keccak256(bytes(raffles[_raffleId].status)) ==
                        keccak256(bytes("ended")),
            "Raffle: raffle is not ended yet!"
        );
        require(
            raffleToken.balanceOf(address(this)) >= ownerFunds,
            "Raffle: insufficient balance!"
        );
        raffleToken.transfer(_msgSender(), ownerFunds);
        emit WithdrawOwnerFunds(_msgSender(), _raffleId, ownerFunds);
    }

}