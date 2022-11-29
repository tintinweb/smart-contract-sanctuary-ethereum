// SPDX-License-Identifier: GPL-3.0

/**
 * @Author Vron
 */

pragma solidity >=0.7.0 <0.9.0;
import "./SafeMath.sol";

interface BUSD {
    function balanceOf(address _address) external returns (uint256);

    function transfer(address _address, uint256 value) external returns (bool);

    function transferFrom(
        address _sender,
        address recipient,
        uint256 value
    ) external returns (bool);
}

interface Context{
    function onlyOwner(address _address) external view;
    function onlyAdmin(address _address) external view;
    function isMarketCreationPaused(address _address) external view;
    function isPlatformActive(address _address) external view;
    function isBettingPaused(address _address) external view;
    function isEventValidationPaused(address _address) external view;
    function _calculateValidatorsNeeded(uint256 _value) external pure returns (uint256);
    function getSystemRewardAddress() external view returns (address);
    function getVCContractAddress() external view returns (address);
    function isUsernameSet(address addr) external view;
    function setUserBonusOnEvent(address user_address, uint256 event_id, uint256 amount) external;
    function getUserBonusOnEvent(address user_address, uint256 event_id) external view returns (uint256);
}

interface Point{
    function deductValidationPoint(address validator_address) external;
}

contract SafuBet {
    // 0x7f78dd0cc6e097d55002cfbAD7c70E53f66d4159
    using SafeMath for uint256;
    // mapping maps event to its index in allActiveEvent
    mapping(uint256 => uint256) private event_index;
    // [eventID][MSG.SENDER] = true or false determines if user betted on an event
    mapping(uint256 => mapping(address => bool)) private bets;
    // [eventID] = true or false - determines if a BetEvent is still active
    mapping(uint256 => bool) private activeEvents;
    // maps an event to its record
    mapping(uint256 => BetEvent) private events;
    // maps an event and a bettor to bettors bets information [eventID][msg.sender]
    mapping(uint256 => mapping(address => Betted)) private userBets;
    // maps an address to the amount won on a particular event
    mapping(uint256 => mapping(address => uint256)) private _amountWonByUserOnEvent;
    // maps bet event occurrence to the number of users who selected it
    mapping(uint256 => mapping(Occurences => address[]))
        private eventBetOccurenceCount;
    // maps bet event occurence and the amount betted on it
    mapping(uint256 => mapping(Occurences => uint256))
        private eventBetOccurenceAmount;
    // maps an event to the occurence that won after validation
    mapping(uint256 => Occurences) private occuredOccurrence;
    // maps a user to all their bets
    mapping(address => uint256[]) private userBetHistory;
    // maps a user to the events created by the user
    mapping(address=>uint256[]) private userEventHistory;
    // maps a validator to an event - used in checking if a validator validated an event
    mapping(address => mapping(uint256 => bool))
        private validatorValidatedEvent;
    // maps a validator to the occurrence chosen
    mapping(uint256 => mapping(address => mapping(Occurences => bool)))
        private selectedValidationOccurrence;
    // maps an event and its occurence to validators that chose it
    mapping(uint256 => mapping(Occurences => address[]))
        private eventOccurenceValidators;
    // maps an event and a user to know if user has reclaimed the event's wager
    mapping(uint256 => mapping(address => bool)) private reclaimedBetWager;
    // maps an event to the amount lost in bet by bettors who choose the wrong event outcome
    mapping(uint256 => uint256) private amountLostInBet;
    // maps a bet event to validators who validated it
    mapping(uint256 => address[]) private eventValidators;
    // maps a validator to all the events they validated
    mapping (address => uint256[]) private validationHistory;
    // maps an event and a bettor to whether the reward has been claimed
    mapping(uint256 => mapping(address => bool)) private claimedReward;
    // maps an event and a validator to whether the validator has claimed reward
    mapping (uint256 => mapping (address => bool)) private validatorClaimedReward;
    // maps an a validator to their validator reward on an event [ADDR][EVENT ID] = _VALUE
    mapping (address=>mapping(uint256=>uint256)) private validatorRewardOnEvent;
    // maps an event to the divs for validators, system and all event bettors
    mapping(uint256 => Distribution) private divs;
    // maps user to total amount wagered
    mapping(address => uint256) private _totalAmountWagered;
    // maps user to total winnings
    mapping(address => uint256) private _totalWinnings;
    mapping(address=>mapping(uint256=>uint256)) private creator_reward;
    // maps a user to their active user status
    mapping(address => bool) private _isActiveUser;
    // maps an event to whether the crumbs has been claimed
    mapping(uint256 => bool) private _eventCrumbClaimed;
    // map holds each event tax
    mapping(uint256=>uint256) private eventTax;
    // maps user to event tax
    mapping(address=>mapping(uint256=>uint256)) private userEventTax;

    // event is emitted when a validator validates an event
    event ValidateEvent(
        uint256 indexed eventID,
        Occurences occurence,
        address validator_address
    );

    ////////////////////////////////////

    // event emitted once event is created
    event CreateEvent(
        uint256 indexed event_id,
        Category category,
        string eventName,
        uint256 pool_size,
        uint256 eventTime,
        string eventOne,
        string eventTwo,
        address betCreator
    );

    // event emitted when a wager is made
    event PlaceBet(
        uint256 indexed event_id,
        address bettor_address,
        uint256 amount,
        Occurences occured
    );

    // event emitted when a user claims bet reward/winnings
    event Claim(address indexed user_address, uint256 _amount);

    /**
     * @dev WIN = 0, LOOSE = 1, LOOSE_OR_WIN = 2 and INVALID = 3
     * On the client side, the user is only to see the follwoing
     * {WIN}, {LOOSE}, {DRAW}
     */
    enum Occurences {
        WIN,
        LOOSE,
        LOOSE_OR_WIN,
        INVALID,
        UNKNOWN
    } //  possible bet outcome
    enum Category {
        SPORTS,
        ESPORTS,
        OTHERS
    } // event categories

    /**
     * @dev stores Betevent information
     *
     * Requirement:
     * event creator must be an admin
     */
    struct BetEvent {
        uint256 eventID;
        Category categories;
        string eventName;
        string description;
        string url;
        uint256 poolSize; // size of event pool
        uint256 startTime; // time event will occur
        uint256 endTime;
        uint256 validationElapseTime; // time event validation elapses
        string eventOne; // eventOne vs
        string eventTwo; //eventTwo
        bool validated; // false if event is not yet validated
        uint256 validatorsNeeded;
        Occurences occured;
        uint256 bettorsCount;
        uint256 noOfBettorsRewarded;
        uint256 amountClaimed;
        bool isBoosted;
        uint256 boostTime;
        uint256 boostAmount;
        bool isCreatorBetted;
        address betCreator;
        string referral;
    }

    /**
     * @dev stores user bet records
     * bettor balance must be greater or equal to 0
    */
    struct Betted {
        uint256 eventID;
        address bettorAddress;
        uint256 amount;
        Occurences occurence;
    }

    /**
     * @dev struct stores distribution divs
     * for each event
    */
    struct Distribution {
        uint256 validatorDiv;
        uint256 bettorsDiv;
        uint256 systemDiv;
        uint256 creatorDiv;
        uint256 VCDiv;
        uint256 royalty;
    }

    BUSD private BUSD_token;
    Context private context_address;
    address private royalty = address(0);
    Point private point_address;
    BetEvent[] private _event_id;
    uint256[] allActiveEvent; // list of active events
    uint256[] private validatedEvent; // list of validated events
    uint256[] private cancelledEvent; // list of cancelled events
    address[] private activeUsersList; // list of active users
    uint256 private totalAmountBetted; // total amount that has been betted on the platform
    uint256 private totalAmountClaimed; // total amount claimed on the platform
    uint256 private totalValidatorRewardClaimed; // total amount claimed by validators on the platform

    /**
     * @dev modifier ensures user can only select WIN, LOOSE or LOOSE_OR_WIN
     * as the occurence they wager on or pick as occured occurence (for validators)
    */
    modifier isValidOccurence(Occurences chosen) {
        require(
            chosen == Occurences.WIN ||
                chosen == Occurences.LOOSE ||
                chosen == Occurences.LOOSE_OR_WIN,
            "IOS"
        );
        _;
    }
    

    /**
     * @dev modifier check if a user has already claimed their bet reward
    */
    modifier hasClaimedReward(uint256 event_id) {
        // check if user betted and validated event
        if (bets[event_id][msg.sender] == true && validatorValidatedEvent[msg.sender][event_id] == true) {
            // user betted and validated event - check if user has claimed both rewards
            require(claimedReward[event_id][msg.sender] == false && validatorClaimedReward[event_id][msg.sender] == false, "RC");
            _;
        } else if(bets[event_id][msg.sender] == true){
            require(claimedReward[event_id][msg.sender] == false, "RC");
            _;
        } else {
            require(validatorClaimedReward[event_id][msg.sender] == false, "RC");
            _;
        }
        
    }

    /**
     * @dev modifier hinders validators from Validating
     * events that do not have opposing bets.
     */
    modifier hasOpposingBets(uint256 event_id) {
        if (
            eventBetOccurenceCount[event_id][Occurences.WIN].length != 0 &&
            eventBetOccurenceCount[event_id][Occurences.LOOSE].length != 0
        ) {
            _;
        } else if (
            eventBetOccurenceCount[event_id][Occurences.WIN].length != 0 &&
            eventBetOccurenceCount[event_id][Occurences.LOOSE_OR_WIN].length !=
            0
        ) {
            _;
        } else if (
            eventBetOccurenceCount[event_id][Occurences.LOOSE].length != 0 &&
            eventBetOccurenceCount[event_id][Occurences.LOOSE_OR_WIN].length !=
            0
        ) {
            _;
        } else {
            revert("VEWNOBNA");
        }
    }


    /**
     *@dev modifier restricts access of assigned subcatehory to addresses it was assigned to.
    */

    constructor(address busd_token, address _context, address _point_address) {
        BUSD_token = BUSD(address(busd_token));
        point_address = Point(address(_point_address));
        context_address = Context(address(_context));
    }

    // create event
    function createEvent(
        Category _category,
        string memory _name,
        string memory _description,
        string memory _url,
        uint256 _time,
        uint256 _endTime,
        string memory _event1,
        string memory _event2
    ) external returns (bool) {
        _createEvent(
            _category,
            _name,
            _description,
            _url,
            _time,
            _endTime,
            _event1,
            _event2,
            msg.sender
        );

        return true;
    }

    // function creates betting event
    function _createEvent(
        Category _category,
        string memory _name,
        string memory _description,
        string memory _url,
        uint256 _time,
        uint256 _endTime,
        string memory _event1,
        string memory _event2,
        address _creator
    ) private  {
        context_address.isMarketCreationPaused(_creator);
        context_address.isPlatformActive(_creator);
        context_address.isUsernameSet(_creator);
        uint256 _elapseTime = 48 hours;
        // ensure eventTime is greater current timestamp
        require(
            _time > currentTime(),
            "IT1"
        );
        require(_endTime > currentTime() && _endTime > _time, "IT2");
        string memory ref = "";
        events[_event_id.length] = BetEvent(
            _event_id.length,
            _category,
            _name,
            _description,
            _url,
            0,
            _time,
            _endTime,
            _endTime + _elapseTime,
            _event1,
            _event2,
            false,
            context_address._calculateValidatorsNeeded(0),
            Occurences.UNKNOWN,
            0,
            0,
            0,
            false,
            0,
            0,
            false,
            _creator,
            ref
        ); // create event
        activeEvents[_event_id.length] = true; // set event as active
        allActiveEvent.push(_event_id.length); // add event to active event list
        event_index[_event_id.length] = allActiveEvent.length - 1;
        userEventHistory[_creator].push(_event_id.length); // add event to user event history
        _event_id.push(events[_event_id.length]); // increment number of events created
        // check if address is already an active user
        incrementNoOfActiveUsers(_creator);
        
        emit CreateEvent(
            _event_id.length - 1,
            _category,
            _name,
            0,
            _time,
            _event1,
            _event2,
            _creator
        );
    }

    // function places bet
    function placeBet(
        uint256[] memory event_id,
        uint256[] memory _amount,
        Occurences[] memory _occured
    ) external returns (bool) {
        _placeBet(event_id, _amount, _occured, msg.sender);
        return true;
    }

    // function places a bet
    function _placeBet(
        uint256[] memory event_id,
        uint256[] memory _amount,
        Occurences[] memory _occurred,
        address _bettor
    ) private returns (bool) {
        context_address.isPlatformActive(_bettor);
        context_address.isBettingPaused(_bettor);
        context_address.isUsernameSet(_bettor);
        // check if event list, _amount and occurrence are equal
        require(event_id.length == _amount.length && event_id.length == _occurred.length, "LE");
       
            // check bal
            require(
                BUSD_token.balanceOf(_bettor) >= _amount[0],
                "IB"
            );
            // ensure bet amount is not 0
            require(_amount[0] > 0, "AMBGT0");
            // check if bet event date has passed
            require(
                events[event_id[0]].startTime >= currentTime(),
                "BNA"
            );
            // check if event exist and is active
            require(
                activeEvents[event_id[0]] == true,
                "ENA"
            );
            // check if event creator already wagered on event
            require(events[event_id[0]].isCreatorBetted == true || _bettor == events[event_id[0]].betCreator, "ONW");
       
             // check if address is already an active user
            incrementNoOfActiveUsers(_bettor);
        for(uint i=0; i<event_id.length; i++){
            BetEvent storage newEvent = events[event_id[i]]; // get event details
            // check if bettor is event creator
            if(_bettor == events[event_id[i]].betCreator && events[event_id[i]].isCreatorBetted == false){
                newEvent.isCreatorBetted = true;  // mark event as wagered by creator
            }
            // check if user already Betted - increase betted amount on previous bet
            if (bets[event_id[i]][_bettor] == true) {
                // check if user current bet occurrence and old one is same
                require(userBets[event_id[i]][_bettor].occurence == _occurred[i], "CAONA");
                // user already betted on event - increase stake on already placed bet
                BUSD_token.transferFrom(_bettor, address(this), _amount[i]);
                userBets[event_id[i]][_bettor].amount = userBets[event_id[i]][
                    _bettor
                ].amount.add(_amount[i]);
                eventBetOccurenceAmount[event_id[i]][
                    _occurred[i]
                ] = eventBetOccurenceAmount[event_id[i]][_occurred[i]].add(_amount[i]); // increment the amount betted on the occurence
                newEvent.poolSize = newEvent.poolSize.add(_amount[i]); // update pool amount
                newEvent.validatorsNeeded = context_address._calculateValidatorsNeeded(newEvent.poolSize); // update no of validators needed
                _incrementTotalAmountBetted(_amount[i]); // increment amount betted on platform
                _totalAmountWagered[_bettor] = _totalAmountWagered[_bettor].add(_amount[i]);  // increment total amount wagered by user
                emit PlaceBet(event_id[i], _bettor, _amount[i], _occurred[i]);
            }else{
                // user first BET
                // deduct tax
                _amount[i] = (_amount[i] * 98) / 100;
                eventTax[event_id[i]] = (_amount[i] * 2) / 100;
                userEventTax[_bettor][event_id[i]] = eventTax[event_id[i]];
                BUSD_token.transferFrom(_bettor, address(this), _amount[i]);
                addUserToOccurrenceBetCount(event_id[i], _occurred[i], _bettor); // increment number of users who betted on an event occurencece
                _incrementEventOccurrenceBetAmount(event_id[i], _occurred[i], _amount[i]); // increment the amount betted on the occurence
                bets[event_id[i]][_bettor] = true; // mark user as betted on event
                userBets[event_id[i]][_bettor] = Betted(
                    event_id[i],
                    _bettor,
                    _amount[i],
                    _occurred[i]
                ); // place user bet
                newEvent.poolSize = newEvent.poolSize.add(_amount[i]); // update pool amount
                newEvent.validatorsNeeded = context_address._calculateValidatorsNeeded(newEvent.poolSize); // update no of validators needed
                newEvent.bettorsCount = newEvent.bettorsCount.add(1); // increment users that betted on the event
                addEventToUserHistory(event_id[i]);
                _incrementTotalAmountBetted(_amount[i]); // increment amount betted on platform
                _totalAmountWagered[_bettor] = _totalAmountWagered[_bettor].add(_amount[i]);  // increment total amount wagered by user
                emit PlaceBet(event_id[i], _bettor, _amount[i], _occurred[i]);
            }
        }
        return true;
    }

    // function gets users who selected a specific outcome for a betting event
    function getOccurrenceBetCount(uint256 event_id, Occurences _occured)
        external
        view
        returns (uint256)
    {
        return eventBetOccurenceCount[event_id][_occured].length;
    }

    // function adds a user to list of users who wagered on an event outcome
    function addUserToOccurrenceBetCount(
        uint256 event_id,
        Occurences _occurred,
        address _address
    ) private {
        eventBetOccurenceCount[event_id][_occurred].push(_address);
    }

    // function gets amount wagered on a specific event occurrence
    function getEventOccurrenceBetAmount(uint256 event_id, Occurences _occurred)
        external
        view
        returns (uint256)
    {
        return eventBetOccurenceAmount[event_id][_occurred];
    }

    // function increments amount wagered on an event outcome
    function _incrementEventOccurrenceBetAmount(
        uint256 event_id,
        Occurences _occurred,
        uint256 _amount
    ) private {
        eventBetOccurenceAmount[event_id][_occurred] = eventBetOccurenceAmount[
            event_id
        ][_occurred].add(_amount);
    }

    // functions sets event occured occurrence after validation
    function setEventOccurredOccurrence(uint256 event_id, Occurences _occured)
        private
    {
        occuredOccurrence[event_id] = _occured;
    }

    // function gets event  occurred occurrence after validation
    function getEventOccurredOccurrence(uint256 event_id)
        internal
        view
        returns (Occurences)
    {
        return occuredOccurrence[event_id];
    }

    // function remove event form active event list and puts it in validated event list
    function removeFromActiveEvents(uint256 event_id) internal {
        // check if event is active
        require(activeEvents[event_id] == false, "EF");
        allActiveEvent[event_index[event_id]] = allActiveEvent[
            allActiveEvent.length - 1
        ];
        allActiveEvent.pop();
    }

    // function gets all active events
    function getActiveEvents() external view returns (uint256[] memory) {
        return allActiveEvent;
    }

    // function gets all validated event
    function getValidatedEvents() external view returns (uint256[] memory) {
        return validatedEvent;
    }

    // function get total betting event
    function totalEvents() external view returns (uint256) {
        return _event_id.length;
    }

    // function adds event to user bet history
    function addEventToUserHistory(uint256 event_id) internal {
        userBetHistory[msg.sender].push(event_id);
    }

    // function returns user bet histroy
    function getUserBetHistory(address _address) external view returns (uint256[] memory) {
        return userBetHistory[_address];
    }

    // function returns list of events created by a user
    function getUserEventHistory(address _address) external view returns (uint256[] memory){
        return userEventHistory[_address];
    }

    // function increments amount wagered on the platform
    function _incrementTotalAmountBetted(uint256 _amount) internal {
        totalAmountBetted = totalAmountBetted.add(_amount);
    }

    // function returns total amount wagered on the platform (total bet createed)
    function totalBetCreated() external view returns (uint256){
        return totalAmountBetted;
    }
    
    /**
     * @dev function gets the total amount wagered by a user
     * REQUIREMENTS
     * [_address] must be provided.
    */
    function getTotalUserWagerAmount(address _address) external view returns (uint256) {
        return _totalAmountWagered[_address];
    }
    
    /**
     * @dev function gets a user's total winnings
     * REQUIREMENTS
     * [_address] must be provided and must be the address of the user whose total winnings is to be retrieved
    */
    function getUserTotalWinnings(address _address) external view returns (uint256) {
        return _totalWinnings[_address];
    }
    /**
     * @dev function sets user total winning
    */
    function setTotalWinnings(address _address, uint256 _value) internal {
        _totalWinnings[_address] = _totalWinnings[_address].add(_value);
    }

    /**
     *@dev function sets validator reward on an event
    */
    function setValidatorRewardOnEvent(address _address, uint256 event_id, uint256 _value)
        private
    {
        validatorRewardOnEvent[_address][event_id] = _value;
    }

    /**
     *@dev function sets & increments the total amount claimed by validators
    */
    function setTotalValidatorRewardClaimed(uint256 _value)
        private
    {
        totalValidatorRewardClaimed = totalValidatorRewardClaimed.add(_value);
    }

    // function returns validator reward on an event
    function getValidatorRewardOnEvent(address _address, uint256 event_id)
        external view
        returns (uint256)
    {
        return validatorRewardOnEvent[_address][event_id];
    }

    // function returns total amount claimed in within the validation sys
    function getTotalValidatorRewardClaimed()
        external view
        returns (uint256)
    {
        return totalValidatorRewardClaimed;
    }

    /**
    * @dev function gets the amount wagered by an address on an event
    * REQUIREMENTS
    * [_bettor] and [event_id] must be provided.
    */
    function getUserEventWager(uint256 event_id, address _bettor) external view returns (uint256) {
        return userBets[event_id][_bettor].amount;
    }

    /**
    * @dev function gets the amount won by an address on an event
    */
    function getUserEventWon(uint256 event_id, address _bettor) external view returns (uint256) {
        return _amountWonByUserOnEvent[event_id][_bettor];
    }

    /**
     * @dev function sets amount won by an address on an event
    */
    function setAmountWonByUserOnEvent(uint256 event_id, address _bettor, uint256 _value) internal{
        _amountWonByUserOnEvent[event_id][_bettor] = _amountWonByUserOnEvent[event_id][_bettor].add(_value);
    }

    /**
     * @dev function returns the information
     * of a bet event and the number of bettors it has
     */
    function getEvent(uint256 index) external view returns (BetEvent memory) {
        // check if bet event exist
        require(events[index].startTime > 0, "EF");
        return events[index];
    }

   

    /**
     * @dev function is used to validate an event
     * by validators.
     *
     * Requirements:
     * validator must have 1000 or more points
     * event validationElapseTime must not exceed block.timestamp.
     * eventTime must exceed block.timestamp
     */
    function validateEvent(uint256 event_id, Occurences occurence)
        external
        returns (bool)
    {
        _validateEvent(event_id, occurence, msg.sender);
        return true;
    }

    /**
     * @dev function is used to validate an event
     * by validators.
     *
     * Requirements:
     * valdator must provide the event intended to be validated and the occurence that occured for the event
     * number of validators required to validate event must not have been exceeded
     * validator must have 1000 or more points
     * event validationElapseTime must not exceed block.timestamp.
     * eventTime must exceed block.timestamp
     *
     * Restriction:
     * validator cannot validate an event twice or more
     */
    function _validateEvent(
        uint256 event_id,
        Occurences occurence,
        address validator_address
    )
        private
        hasOpposingBets(event_id)
        isValidOccurence(occurence)
    {
        context_address.isPlatformActive(validator_address);
        context_address.isUsernameSet(validator_address);
        context_address.isEventValidationPaused(validator_address);
        // check if event exist
        require(event_id <= _event_id.length, "EF");
        // check if event has been validated
        require(events[event_id].validated == false, "EV");
        // check if number of validators required to validate event has been exceeded
        require(
            eventValidators[event_id].length <=
                events[event_id].validatorsNeeded,
            "NVNR"
        );
        // check if eventTime has been exceeded
        require(
            events[event_id].startTime < currentTime(),
            "EHO"
        );
        // check if event end time has reached
        require(
            events[event_id].endTime < currentTime(),
            "ENRFV"
        );
        // check if event validation time has elapsed
        require(events[event_id].validationElapseTime > currentTime(), "EVTE");
        // check if validator has validated event before
        require(
            validatorValidatedEvent[validator_address][event_id] == false,
            "VETNA"
        );

        // validator validates event
        eventOccurenceValidators[event_id][occurence].push(validator_address); // add validator to list of individuals that voted this occurence
        validatorValidatedEvent[validator_address][event_id] = true; // mark validator as validated event
        eventValidators[event_id].push(validator_address); // add validator to list of validators that validated event
        selectedValidationOccurrence[event_id][validator_address][occurence] = true;
        point_address.deductValidationPoint(msg.sender);
        validationHistory[validator_address].push(event_id);

        // 5 minutes to validation elapse time - check if event has 60% of required validators
        if (
            (events[event_id].validatorsNeeded / 100) * 80 >=
            eventValidators[event_id].length
        ) {
            // event has 70% of needed validators
            _markAsValidated(event_id); // mark as validated
            _cummulateEventValidation(event_id); // cumulate validators event occurence vote
            // check if event occurred occurence isn't INVALID
            if (occuredOccurrence[event_id] != Occurences.INVALID) {
                _distributionFormular(event_id); // calculate divs
                _rewardSystem(event_id); // reward system
                _rewardVC(event_id); // reward VC
            }
        }
        // check if validators needed has beeen reached
        if (
            eventValidators[event_id].length ==
            events[event_id].validatorsNeeded
        ) {
            _markAsValidated(event_id); // mark as validated
            _cummulateEventValidation(event_id); // cumulate validators event occurence vote
            // check if event occurred occurence isn't INVALID
            if (occuredOccurrence[event_id] != Occurences.INVALID) {
                _distributionFormular(event_id); // calculate divs
                _rewardSystem(event_id); // reward system
                _rewardVC(event_id); // reward VC
            }
        }
        emit ValidateEvent(event_id, occurence, validator_address); // emit ValidateEvent event
    }

    /**
     * @dev function returns list of events validated by a validator
    */
    function validatorHistory(address _validator) external view returns (uint256[] memory){
        return validationHistory[_validator];
    }

    /**
     * @dev function checks for the event occurence which
     * validators voted the most as the occured event
     * occurence.
     * Returns 0 if occurence is WIN
     * Returns 1 if occurence is LOOSE
     * Returns 2 if occurence is LOOSE_OR_WIN
     * Returns 3 if none of the above occurences won out.
     */
    function _cummulateEventValidation(uint256 event_id) private {
        BetEvent storage event_occurrence = events[event_id]; // init betEvent instance

        // check the occurence that has the highest vote
        if (
            eventOccurenceValidators[event_id][Occurences.WIN].length >
            eventOccurenceValidators[event_id][Occurences.LOOSE].length &&
            eventOccurenceValidators[event_id][Occurences.WIN].length >
            eventOccurenceValidators[event_id][Occurences.LOOSE_OR_WIN].length
        ) {
            // set occured occurence
            occuredOccurrence[event_id] = Occurences.WIN;
            // set event occured occurence
            event_occurrence.occured = occuredOccurrence[event_id];
            // assign amount to be shared
            amountLostInBet[event_id] = amountLostInBet[event_id].add(
                eventBetOccurenceAmount[event_id][Occurences.LOOSE] +
                    eventBetOccurenceAmount[event_id][Occurences.LOOSE_OR_WIN]
            );
        } else if (
            eventOccurenceValidators[event_id][Occurences.LOOSE].length >
            eventOccurenceValidators[event_id][Occurences.WIN].length &&
            eventOccurenceValidators[event_id][Occurences.LOOSE].length >
            eventOccurenceValidators[event_id][Occurences.LOOSE_OR_WIN].length
        ) {
            occuredOccurrence[event_id] = Occurences.LOOSE;
            // set event occured occurence
            event_occurrence.occured = occuredOccurrence[event_id];
            // assign amount to be shared
            amountLostInBet[event_id] = amountLostInBet[event_id].add(
                eventBetOccurenceAmount[event_id][Occurences.WIN] +
                    eventBetOccurenceAmount[event_id][Occurences.LOOSE_OR_WIN]
            );
        } else if (
            eventOccurenceValidators[event_id][Occurences.LOOSE_OR_WIN].length >
            eventOccurenceValidators[event_id][Occurences.WIN].length &&
            eventOccurenceValidators[event_id][Occurences.LOOSE_OR_WIN].length >
            eventOccurenceValidators[event_id][Occurences.LOOSE].length
        ) {
            occuredOccurrence[event_id] = Occurences.LOOSE_OR_WIN;
            // set event occured occurence
            event_occurrence.occured = occuredOccurrence[event_id];
            // assign amount to be shared
            amountLostInBet[event_id] = amountLostInBet[event_id].add(
                eventBetOccurenceAmount[event_id][Occurences.LOOSE] +
                    eventBetOccurenceAmount[event_id][Occurences.WIN]
            );
        } else {
            occuredOccurrence[event_id] = Occurences.INVALID;
            // set event occured occurence
            event_occurrence.occured = occuredOccurrence[event_id];
        }
    }

    /**
     * @dev function check if validator selected the
     * right event occurence reached through concensus
     */
    function _isSelectedRightOccurrence(uint256 event_id)
        internal
        view
        returns (bool)
    {
        // check if validator selected right event outcome
        if (
            selectedValidationOccurrence[event_id][msg.sender][
                occuredOccurrence[event_id]
            ] == true
        ) {
            // validator selected right event outcome
            return true;
        }
        // validator selected wrong event outcome
        return false;
    }

    /**
     * @dev function calculates the distribution of funds
     * after an event has been validated
     */
    function _distributionFormular(uint256 event_id) internal {
        // calculate what is left after winners reward has been removed
        uint256 winners_percent = (eventBetOccurenceAmount[event_id][occuredOccurrence[event_id]] * 100) / events[event_id].poolSize;
        uint256 winners_reward = (amountLostInBet[event_id] * winners_percent) / 100;
        uint256 div_amount = amountLostInBet[event_id].sub(winners_reward);
        div_amount = div_amount.add(eventTax[event_id]);
        Distribution storage setDivs = divs[event_id];
        setDivs.bettorsDiv = setDivs.bettorsDiv.add((div_amount * 10) / 100);  // bettors reward
        setDivs.systemDiv = setDivs.systemDiv.add((div_amount * 3) / 100);  // system reward
        setDivs.validatorDiv = setDivs.validatorDiv.add((div_amount * 80 ) / 100); // validator reward
        setDivs.creatorDiv = setDivs.creatorDiv.add((div_amount * 1) / 100); // creator reward
        setDivs.VCDiv = setDivs.VCDiv.add((div_amount * 4) / 100); // VC reward
        setDivs.royalty = setDivs.royalty.add((div_amount * 2) / 100); // Royalty reward
    }

    /**
     * @dev function is used in claiming reward
     */
    function claimReward(uint256 event_id) external returns (bool) {
        _claimReward(event_id, msg.sender);
        return true;
    }

    /**
     * @dev function helps a user claim rewards
     *
     * Requirements:
     * [event_id] must be an event that has been validated
     * [msg.sender] must either be a bettor that participated in the event or validator
     * that validated the event
     */
    function _claimReward(uint256 event_id, address user_address)
        internal
        hasClaimedReward(event_id)
    {
        // check if event exist
        require(events[event_id].poolSize > 0, "EF");
        // check if event occurrence is not UNKNOWN OR INVALID
        require(
            events[event_id].occured == Occurences.WIN ||
                events[event_id].occured == Occurences.LOOSE ||
                events[event_id].occured == Occurences.LOOSE_OR_WIN,
            "RWI"
        );
        // check if user has reclaimed wager 
        require(reclaimedBetWager[event_id][user_address] == false, "WAR");
        // check if event has been validated
        require(events[event_id].validated == true, "ENV");
        BetEvent storage getEventDetails = events[event_id];
        uint256 user_reward;
        // check if user is a bettor of the event
        if(bets[event_id][user_address] == true){
            uint256 event_bonus = divs[event_id].bettorsDiv / events[event_id].bettorsCount;  // get user bonus on event
            context_address.setUserBonusOnEvent(user_address, event_id, event_bonus);
            // check if addr is event creator
            if(events[event_id].betCreator == user_address){
                // addr created event - reward addr
                creator_reward[user_address][event_id] = divs[event_id].creatorDiv;
                getEventDetails.amountClaimed = getEventDetails.amountClaimed.add(
                    divs[event_id].creatorDiv
                ); // increment event winnings claimed
                BUSD_token.transfer(user_address, divs[event_id].creatorDiv);
            }
            // check if user selected occured occurrence
            if (
                userBets[event_id][user_address].occurence ==
                occuredOccurrence[event_id]
            ) {
                // user selected occured occurrence - calculate user reward
                uint256 winners_percent = (userBets[event_id][user_address].amount * 100) / events[event_id].poolSize;
                user_reward = (amountLostInBet[event_id] * winners_percent) / 100;
                user_reward = user_reward.add(
                    userBets[event_id][user_address].amount.add(userEventTax[user_address][event_id])
                ); // refund user original bet amount
                user_reward = user_reward.add(
                    event_bonus
                ); // divide div amount by number of bettors - add amount to user reward
                claimedReward[event_id][user_address] = true; // user marked as collected reward
                _incrementTotalAmountClaimed(user_reward); // increment total amount claimed on platform
                getEventDetails.noOfBettorsRewarded = getEventDetails
                    .noOfBettorsRewarded
                    .add(1); // increment no. of event bettors rewarded
                getEventDetails.amountClaimed = getEventDetails.amountClaimed.add(
                    user_reward
                ); // increment event winnings claimed
                setTotalWinnings(user_address, user_reward);
                setAmountWonByUserOnEvent(event_id, user_address, user_reward);
                BUSD_token.transfer(user_address, user_reward); // transfer user reward to user
            } else {
                // user chose wrong occurrence - reward user from div
                claimedReward[event_id][user_address] = true; // user marked as collected reward
                _incrementTotalAmountClaimed(event_bonus); // increment total amount claimed on platform
                getEventDetails.noOfBettorsRewarded = getEventDetails
                    .noOfBettorsRewarded
                    .add(1); // increment no. of event bettors rewarded
                getEventDetails.amountClaimed = getEventDetails.amountClaimed.add(
                    event_bonus
                ); // increment event winnings claimed
                setTotalWinnings(user_address, event_bonus);
                setAmountWonByUserOnEvent(event_id, user_address, event_bonus);
                BUSD_token.transfer(user_address, event_bonus); // transfer user reward to user
            }
        }
        // check if user validated event
        if (validatorValidatedEvent[user_address][event_id] == true && _isSelectedRightOccurrence(event_id) == true) {
            // validator selected the reached occured occurence - reward validator
            user_reward = divs[event_id].validatorDiv / eventOccurenceValidators[event_id][occuredOccurrence[event_id]].length;
            validatorClaimedReward[event_id][user_address] = true;  // mark validator as claimed reward  
            _incrementTotalAmountClaimed(user_reward);  // increment total amount claimed on 
            getEventDetails.amountClaimed = getEventDetails.amountClaimed.add(
                    user_reward
                ); // increment event winnings claimed
            setValidatorRewardOnEvent(user_address, event_id, user_reward); // set validator reward on event
            setTotalValidatorRewardClaimed(user_reward);
            setTotalWinnings(user_address, user_reward);
            BUSD_token.transfer(user_address, user_reward);  // transfer user reward to user
        }
        emit Claim(user_address, user_reward); // emit claim event
    }

    function isBetRewardClaimed(uint256 event_id, address _address) 
        external
        view
        returns (bool)
    {
        return claimedReward[event_id][_address];
    }
    
    /**
     * @dev function handles user reclaiming their bet wager
    */
    function reclaimWager(uint256 event_id) external returns (bool) {
        _reclaimBettingWager(event_id, msg.sender);
        return true;
    }
    
    /**
     * @dev function handles user reclaiming their wager on
     * an event, if the event was not validated.
    */
    function _reclaimBettingWager(uint256 event_id, address user_address) internal {
        // check if event exist
        require(events[event_id].startTime > 0, "EF");
        // check if event was validated and outcome was invalid
        require(events[event_id].occured == Occurences.UNKNOWN || events[event_id].occured == Occurences.INVALID, "EVCR");
        // check if event time has elapsed
        require(events[event_id].validationElapseTime < currentTime(), "WUEVOE");
        // check if user betted on event
        require(bets[event_id][user_address] == true, "WNF");
        // check if user has reclaimed wager
        require(reclaimedBetWager[event_id][user_address] == false, "WAR");
        
        // refund user wager
        reclaimedBetWager[event_id][user_address] = true;  // mark user as collected wager
        uint256 amount = userEventTax[user_address][event_id].add(userBets[event_id][user_address].amount);
        BUSD_token.transfer(user_address, amount);  // refund user wager
        
    }

    function isBetWagerReclaimed(uint256 event_id, address _address) 
        external
        view
        returns (bool)
    {
        return reclaimedBetWager[event_id][_address];
    }

    /**
     * @dev function handles rewarding system after
     * validation concensus has been reached
    */
    function _rewardSystem(uint256 event_id) internal {
        BetEvent storage eventDetails = events[event_id];
        uint256 amount = divs[event_id].systemDiv;
        // uint256 royalty_amount = divs[event_id].royalty;
        eventDetails.amountClaimed = eventDetails.amountClaimed.add(
                   amount
                ); // increment event winnings claimed
        BUSD_token.transfer(royalty, divs[event_id].royalty);
        BUSD_token.transfer(context_address.getSystemRewardAddress(), amount);  // transfer funds to team wallet
    }

    /**
     * @dev function handles rewarding of VC contract
     * after validation concensus has been reached
    */
    function _rewardVC(uint256 event_id) internal{
        BetEvent storage eventDetails = events[event_id];
        eventDetails.amountClaimed = eventDetails.amountClaimed.add(
            divs[event_id].VCDiv
        );
        BUSD_token.transfer(context_address.getVCContractAddress(), divs[event_id].VCDiv);
    }

    /**
     * @dev function marks an event as validated
     */
    function _markAsValidated(uint256 event_id) private {
        BetEvent storage thisEvent = events[event_id]; // initialize event instance

        thisEvent.validated = true;

        activeEvents[event_id] = false; // set event as not active

        removeFromActiveEvents(event_id); // remove event from avalaibleEvents array
        validatedEvent.push(event_id); // add event to list of validated event
    }

    /**
     * @dev function increments the total winnings claimed
     * on the platform
     */
    function _incrementTotalAmountClaimed(uint256 _value) internal {
        totalAmountClaimed = totalAmountClaimed.add(_value);
    }

    // function returns the platform's total payout/winnings
    function getTotalPayout() external view returns (uint256){
        return totalAmountClaimed;
    }

    // function returns the amount an addr got reward for creating an event
    function getCreatorRewardOnEvent(address user_address, uint256 event_id)
        external view
        returns (uint256)
    {
        return  creator_reward[user_address][event_id];
    }

    function currentTime() public view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @dev function withdraws funds left in smart contract after a particular
     * event winnings distribution.
     * This ensures funds are not mistakenly locked away in the smart contract
     *
     * REQUIREMENTS
     * [event_id] must an event that exist and is validated.
     * [event_id] must be an event in which all winnings have been distributed
     * [msg.sender] must be _owner
     */
    function _transferCrumbs(uint256 event_id, address _address)
        private
    {
        context_address.onlyOwner(msg.sender);
        // check if event has been validated
        require(events[event_id].validated == true, "ENV");
        // check if all winnings have been distributed
        require(
            events[event_id].noOfBettorsRewarded ==
                events[event_id].bettorsCount,
            "WNDC"
        );
        // check if event crumbs has been claimed
        require(_eventCrumbClaimed[event_id] == false, "ECC");

        BetEvent memory eventDetails = events[event_id];
        uint256 leftOverFunds = eventDetails.poolSize -
            eventDetails.amountClaimed; // funds left over after Winnings distribution
        _eventCrumbClaimed[event_id] = true; // mark event crumbs as claimed
        BUSD_token.transfer(_address, leftOverFunds);
    }

    /**
     * @dev function withdraws funds left in smart contract after a particular
     * event winnings distribution.
     * This ensures funds are not mistakenly locked away in the smart contract
     *
     * REQUIREMENTS
     * [event_id] must an event that exist and is validated.
     * [event_id] must be an event in which all winnings have been distributed
     * [msg.sender] must be _owner
     */
    function transferCrumbs(uint256 event_id, address _address)
        external
        returns (bool)
    {
        _transferCrumbs(event_id, _address);
        return true;
    }
    /**
     * @dev function changes the address for the Royalty contract
    */
    function changeRoyaltyAddress(address _address)
        external 
        returns (bool)
    {
        context_address.onlyOwner(msg.sender);
        royalty = _address;
        return true;
    }

    // function returns Royalty contract address
    function getRoyaltyAddress()
        external
        view
        returns (address)
    {
        return royalty;
    }

    /**
     * @dev function is used to change the contract address
     * of BUSD
     */
    function changeTokenContractAddress(address _busd)
        external
        returns (bool)
    {
        context_address.onlyOwner(msg.sender);
        BUSD_token = BUSD(address(_busd));
        return true;
    }

    // function returns token contract address
    function getTokenContractAddress()
        external view
        returns (address)
    {
        return address(BUSD_token);
    }

    /**
     *@dev function changes the address of the Validator Point contract
    */
    function changePointContractAddress(address _point) 
        external 
        returns (bool)
    {
        context_address.onlyOwner(msg.sender);
        point_address = Point(address(_point));
        return true;
    }

    // function returns Validator Point contract address
    function getPointContractAddress()
        external view
        returns (address)
    {
        return address(point_address);
    }

    /**
     *@dev function changes the address of the Context contract
    */
    function changeContextContractAddress(address _contextAddress)
        external
        returns (bool)
    {
        context_address.onlyOwner(msg.sender);
        context_address = Context(address(_contextAddress));
        return true;
    }

    // function returns Context contract address
    function getContextContractAddress()
        external view
        returns (address)
    {
        return address(context_address);
    }



    /**
    * @dev function increments the number of active users
    */
    function incrementNoOfActiveUsers(address _address) internal {
        // check if address is an active user
        if(_isActiveUser[_address] == false) {
            _isActiveUser[_address] = true; // mark address as active user
            activeUsersList.push(_address); // add address to active user list
        }
    }

    /**
     * @dev function returns list of active users
    */
    function getActiveUsersList() external view returns (address[] memory){
        return activeUsersList;
    }

    /**
    * @dev function returns number of active users
    */
    function getNoOfActiveUsers() external view returns (uint256){
        return activeUsersList.length;
    }

    // calls internal function _boostEvent
    function boostEvent(uint256 _boostAmount, uint256 event_id) external {
       _boostEvent(_boostAmount, event_id);
    }

    /**
     * @dev function is used to boost/promote an event
    */
    function _boostEvent(uint256 _boostAmount, uint256 event_id) private{
         uint256 boostCost = 1000000000000000000;
        // check event endtime
        require(events[event_id].endTime > currentTime(), "EAE");
        // check bal
        require(BUSD_token.balanceOf(msg.sender) >= boostCost && _boostAmount == boostCost, "IB");
        // check event hasn't been validated
        require(events[event_id].validated == false, "EV");
        // check if user wagered on event
        require(bets[event_id][msg.sender] == true, "NS");
        BUSD_token.transferFrom(msg.sender, context_address.getSystemRewardAddress(), boostCost);
        BetEvent storage theEvent = events[event_id];
        theEvent.isBoosted = true;
        theEvent.boostTime = block.timestamp + 20 minutes;
    }

    /**
     * @dev function check if validator has claimed validator reward.
     * Returns true if claimed and false otherwise.
    */
    function isValidatorRewardClaimed(uint256 event_id, address _address) external view returns (bool) {
        return validatorClaimedReward[event_id][_address];
    }

    /**
     *@dev function sets the referral link for an event to make it sharable.
    */
    function setRefLink(address addr, uint256 event_id, string memory ref) external {
        // check if bettor is market creator and if ref link is set
        if(addr == events[event_id].betCreator && bytes(events[event_id].referral).length < 1){
            BetEvent storage updateEvent = events[event_id];
            updateEvent.referral = ref;
        }
    }
}