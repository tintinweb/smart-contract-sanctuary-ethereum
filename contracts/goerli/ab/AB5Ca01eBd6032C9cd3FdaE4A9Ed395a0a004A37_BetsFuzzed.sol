// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../Utils/UltibetsCore.sol";

contract BetsFuzzed is UltibetsCore, ReentrancyGuard {
    /// emitted when bet is placed
    event BetPlaced(
        address indexed bettor,
        uint256 indexed eventID,
        EventResult prediction,
        uint256 amount
    );

    /// emitted when user withdraws
    event Withdrawn(
        address indexed bettor,
        uint256 indexed eventID,
        EventResult prediction,
        uint256 amount
    );

    /// @param _ultiBetsTreasury address of the treasury contract
    constructor(address _ultiBetsTreasury, address _ultibetsBuyback) {
        require(_ultiBetsTreasury != address(0));
        require(_ultibetsBuyback != address(0));
        ultiBetsTreasury = _ultiBetsTreasury;
        ultiBetsBuyback = _ultibetsBuyback;
    }

    ///@notice function for bettors to place bet.
    ///@param _eventID the event id, _betValue bet value
    function placeBet(
        uint256 _eventID,
        EventResult _eventValue
    ) external payable {
        require(
            eventList[_eventID].status == EventStatus.Open &&
                block.timestamp <=
                eventList[_eventID].startTime - noticeBetTime,
            "Non available bet."
        );

        uint256 betAmount = msg.value;

        bool isAlreadyBet = betDataList[
            betDataByBettor[msg.sender][_eventID][_eventValue]
        ].betAmount > 0;

        if (isAlreadyBet) {
            uint256 betId = betDataList[
                betDataByBettor[msg.sender][_eventID][_eventValue]
            ].betId;
            betDataList[betId].betAmount += betAmount;
        } else {
            totalBetNumber += 1;
            BetData memory bet = BetData(
                totalBetNumber,
                msg.sender,
                _eventID,
                betAmount,
                0,
                _eventValue,
                block.timestamp
            );
            betDataList[totalBetNumber] = bet;
            betDataByBettor[msg.sender][_eventID][_eventValue] = totalBetNumber;
            dailyBetsByBettor[msg.sender][eventList[_eventID].eDate].push(
                totalBetNumber
            );
        }

        betAmountsPerSideByEvent[_eventID][_eventValue] += betAmount;
        eventList[_eventID].bettingVolume += betAmount;

        emit BetPlaced(msg.sender, _eventID, _eventValue, betAmount);
    }

    ///@notice function to withdraw bet amount when bet is stopped in emergency
    function claimBetCancelled(
        uint256 _eventID,
        EventResult _eventResult
    ) external nonReentrant {
        require(
            checkBetResult(msg.sender, _eventID, _eventResult) ==
                BetStatus.Cancel,
            "Can't claim the bet!"
        );

        uint256 betAmount = betDataList[
            betDataByBettor[msg.sender][_eventID][_eventResult]
        ].betAmount;
        betDataList[betDataByBettor[msg.sender][_eventID][_eventResult]]
            .paidAmount = betAmount;
        uint256 contractBalBefore = getBalance();
        payable(msg.sender).transfer(betAmount);

        // POST assertions
        assert(contractBalBefore - getBalance() == betAmount);
    }

    /// @notice function for bettors to withdraw gains
    function withdrawGain(
        uint256 _eventID,
        EventResult _betValue
    ) external nonReentrant {
        require(
            checkBetResult(msg.sender, _eventID, _betValue) == BetStatus.Win,
            "You are not the winner."
        );
        require(
            checkBetClaimable(msg.sender, _eventID, _betValue),
            "You already withdrew!"
        );

        uint256 gain = getWinAmount(msg.sender, _eventID, _betValue);

        betDataList[betDataByBettor[msg.sender][_eventID][_betValue]]
            .paidAmount = gain;

        uint256 contractBalBefore = getBalance();

        payable(msg.sender).transfer(gain);

        // POST assertions
        assert(contractBalBefore - getBalance() == gain);

        emit Withdrawn(msg.sender, _eventID, _betValue, gain);
    }

    ///@notice Used to withdraw platform fee to treasury address
    ///please note that this action can only be performed by an administrator.
    function withdrawEarnedFees() external nonReentrant onlyAdmin {
        require(feeBalance > 0, "No fees to withdraw");
        uint256 amount = feeBalance;
        feeBalance = 0;
        uint256 contractBalBefore = getBalance();
        payable(ultiBetsTreasury).transfer(amount / 2);
        payable(ultiBetsBuyback).transfer(amount / 2);

        // POST assertions
        assert(contractBalBefore - getBalance() == amount);
    }

    ///@notice Emergency withdrawal of funds to the treasury address
    ///please note that this action can only be performed by an administrator.
    function EmergencySafeWithdraw() external onlyAdmin {
        payable(ultiBetsTreasury).transfer(getBalance());

        // POST assertions
        assert(getBalance() == 0);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../Utils/CustomAdmin.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract UltibetsCore is CustomAdmin {
    using EnumerableSet for EnumerableSet.UintSet;

    enum EventResult {
        Home,
        Draw,
        Away,
        Active
    }

    enum EventStatus {
        Open,
        End,
        Cancel
    }

    enum EventType {
        Double,
        Triple
    }

    enum BetStatus {
        Win,
        Lose,
        Cancel,
        Canceled,
        Active,
        NoBet
    }

    struct CategoryInfo {
        string name;
        EventType eType;
        uint8 numberOfSubcategories;
    }

    struct EventInfo {
        uint256 eventID;
        string description;
        uint256 startTime;
        uint256 eDate;
        EventStatus status;
        EventResult result;
        uint8 category;
        uint8 subcategory;
        uint256 bettingVolume;
    }

    struct EventDetailPerBettor {
        uint256 eventID;
        string description;
        uint8 category;
        uint8 subcategory;
        uint256 startTime;
        EventType eType;
        uint256[] sidePoolVolumes;
        uint256[] sideBetAmounts;
    }

    struct BetData {
        uint256 betId;
        address bettor;
        uint256 eventID;
        uint256 betAmount;
        uint256 paidAmount;
        EventResult prediction;
        uint256 betTime;
    }

    struct BetHistoryData {
        uint256 eventID;
        string description;
        EventType eType;
        uint256 startTime;
        uint256 betAmount;
        uint256 paidAmount;
        uint16 odds;
        uint16 percentOfSidePool;
        EventStatus status;
        EventResult prediction;
        EventResult result;
    }

    uint256 public totalEventNumber;
    uint256 public totalBetNumber;

    mapping(uint8 => CategoryInfo) public categoryList;
    uint8 public categoryNumber;
    mapping(uint8 => mapping(uint8 => string)) subcategories;
    mapping(uint8 => EnumerableSet.UintSet) liveEventsByCategory;
    mapping(uint8 => mapping(uint256 => EnumerableSet.UintSet)) dailyEventsByCategory;

    mapping(uint256 => EventInfo) eventList;
    mapping(uint256 => BetData) betDataList;
    mapping(address => mapping(uint256 => uint256[])) dailyBetsByBettor; //bet list of a bettor
    mapping(address => mapping(uint256 => mapping(EventResult => uint256))) betDataByBettor; //betting history of a bettor   bettor => eventid => event result => betdata
    mapping(uint256 => mapping(EventResult => uint256)) betAmountsPerSideByEvent; //betting amount for an event

    uint256 public constant feePercentage = 2; /// Ultibets fee percentage
    uint256 public feeBalance; /// total balance of the  Ultibets fee
    address public ultiBetsTreasury; /// address of Treasury contract
    address public ultiBetsBuyback; /// address of Treasury contract

    uint16 public noticeBetTime = 30 minutes; //can't bet since 30 min before the event

    event EventCanceled(uint256 eventID);

    event Results(uint256 eventID, EventResult result);

    event ReferLink(address referee, address referrer);

    event RemoveExpiredEvents(uint8 category, uint256 eventID);

    event NewCategory(string name, EventType eType);

    ///@notice Balance of the contract.
    ///@return Returns the balance of the contract
    function getBalance() public view virtual returns (uint256) {
        return address(this).balance;
    }

    /// @notice View function that for bettors to view bets history
    /// @return   betListOfBettor
    function dailyBetsOfBettor(
        address _bettor,
        uint256 _date1,
        uint256 _timestamp1,
        uint256 _date2,
        uint256 _timestamp2
    ) external view returns (BetHistoryData[] memory) {
        require(_date2 > _date1 && _timestamp2 > _timestamp1, "Invalid Params");
        uint256 betNum1 = numberOfDailyBetsByBettor(_bettor, _date1);
        uint256 betNum2 = numberOfDailyBetsByBettor(_bettor, _date2);
        BetHistoryData[] memory betList = new BetHistoryData[](
            betNum1 + betNum2
        );

        for (uint256 i; i < betNum1; i++) {
            BetData memory bet = betDataList[dailyBetsByBettor[_bettor][_date1][i]];
            EventInfo memory eventData = eventList[bet.eventID];
            if (bet.betTime >= _timestamp1) {
                BetHistoryData memory betH = getHistoryData(bet, eventData);
                betList[i] = betH;
            }
        }
        for (uint256 i; i < betNum2; i++) {
            BetData memory bet = betDataList[dailyBetsByBettor[_bettor][_date2][i]];
            EventInfo memory eventData = eventList[bet.eventID];
            if (bet.betTime <= _timestamp2) {
                BetHistoryData memory betH = getHistoryData(bet, eventData);
                betList[betNum1 + i] = betH;
            }
        }

        return betList;
    }

    function getHistoryData(BetData memory _bet, EventInfo memory _event)
        internal
        view
        returns (BetHistoryData memory)
    {
        uint16 odds = uint16(
            (betAmountsPerSideByEvent[_bet.eventID][_bet.prediction] * 1000) /
                eventList[_bet.eventID].bettingVolume
        ); //1000 for 0.1%
        uint16 percentOfSidePool = uint16(
            (_bet.betAmount * 1000) /
                betAmountsPerSideByEvent[_bet.eventID][_bet.prediction]
        ); //1000 for 0.1%
        return
            BetHistoryData(
                _bet.eventID,
                _event.description,
                categoryList[_event.category].eType,
                _event.startTime,
                _bet.betAmount,
                _bet.paidAmount,
                odds,
                percentOfSidePool,
                _event.status,
                _bet.prediction,
                _event.result
            );
    }

    function numberOfDailyBetsByBettor(address _bettor, uint256 _date)
        public
        view
        returns (uint256)
    {
        return dailyBetsByBettor[_bettor][_date].length;
    }

    /// @notice view function to view bet results
    function viewResult(uint256 _eventID)
        external
        view
        returns (EventResult result)
    {
        result = eventList[_eventID].result;
    }

    function addCategory(
        string memory _name,
        EventType _type,
        string[] memory _subcategories
    ) external onlyAdmin {
        categoryNumber++;
        categoryList[categoryNumber] = CategoryInfo(
            _name,
            _type,
            uint8(_subcategories.length)
        );
        for (uint8 i; i < _subcategories.length; i++) {
            subcategories[categoryNumber][i + 1] = _subcategories[i];
        }
        emit NewCategory(_name, _type);
    }

    function addSubcategory(string memory _name, uint8 _categoryID)
        external
        onlyAdmin
    {
        subcategories[_categoryID][
            categoryList[_categoryID].numberOfSubcategories + 1
        ] = _name;
    }

    function addEvent(
        string memory _description,
        uint8 _category,
        uint8 _subcategory,
        uint256 _eventStartTime,
        uint256 _eventDate
    ) public onlyAdmin {
        totalEventNumber++;
        eventList[totalEventNumber] = EventInfo(
            totalEventNumber,
            _description,
            _eventStartTime,
            _eventDate,
            EventStatus.Open,
            EventResult.Active,
            _category,
            _subcategory,
            0
        );
        liveEventsByCategory[_category].add(totalEventNumber);
        dailyEventsByCategory[_category][_eventDate].add(totalEventNumber);
    }

    function removeExpiredEvents(uint8 _category, uint256[] memory _eventIDs)
        public
        onlyAdmin
    {
        for (uint256 i; i <= _eventIDs.length; i++) {
            removeExpiredEvent(_category, _eventIDs[i]);
        }
    }

    function removeExpiredEvent(uint8 _category, uint256 _eventID) internal {
        liveEventsByCategory[_category].remove(_eventID);
        uint256 date = eventList[_eventID].eDate;
        dailyEventsByCategory[_category][date].remove(_eventID);

        emit RemoveExpiredEvents(_category, _eventID);
    }

    ///@notice emergency function to cancel event
    ///please note that this action can only be performed by an administrator.
    function cancelEvent(uint256 _eventID) external onlyAdmin {
        require(
            eventList[_eventID].status == EventStatus.Open,
            "Invalid event!"
        );
        eventList[_eventID].status = EventStatus.Cancel;
        removeExpiredEvent(eventList[_eventID].category, _eventID);
        emit EventCanceled(_eventID);
    }

    function checkBetResult(
        address _bettor,
        uint256 _eventID,
        EventResult _eventResult
    ) public view returns (BetStatus result) {
        BetData memory bet = betDataList[betDataByBettor[_bettor][_eventID][_eventResult]];
        EventInfo memory evt = eventList[_eventID];

        if (bet.betAmount > 0) {
            if (evt.status == EventStatus.Open) result = BetStatus.Active;
            else if (evt.status == EventStatus.Cancel && bet.paidAmount == 0)
                result = BetStatus.Cancel;
            else if (evt.status == EventStatus.Cancel && bet.paidAmount > 0)
                result = BetStatus.Canceled;
            else if (evt.status == EventStatus.End) {
                if (evt.result == _eventResult) result = BetStatus.Win;
                else result = BetStatus.Lose;
            }
        } else result = BetStatus.NoBet;
    }

    function checkBetClaimable(
        address _bettor,
        uint256 _eventID,
        EventResult _eventResult
    ) public view returns (bool) {
        BetData memory bet = betDataList[betDataByBettor[_bettor][_eventID][_eventResult]];
        if (bet.paidAmount > 0) return false;
        else return true;
    }

    ///@notice report betting result.
    ///please note that this action can only be performed by an oracle.

    function reportResult(uint256 _eventID, EventResult _result)
        external
        OnlyOracle
    {
        EventInfo memory evt = eventList[_eventID];
        require(evt.status == EventStatus.Open, "Can't report result!");

        uint256 feeBet = (evt.bettingVolume * feePercentage) / 100;
        feeBalance += feeBet;
        eventList[_eventID].status = EventStatus.End;
        eventList[_eventID].result = _result;

        removeExpiredEvent(eventList[_eventID].category, _eventID);

        emit Results(_eventID, _result);
    }

    function getLiveEventsByCategory(uint8 _category)
        external
        view
        returns (EventInfo[] memory)
    {
        uint256 numberOfEvents = liveEventsByCategory[_category].length();
        EventInfo[] memory eventDataList = new EventInfo[](numberOfEvents);
        for (uint256 i; i < numberOfEvents; i++) {
            eventDataList[i] = eventList[liveEventsByCategory[_category].at(i)];
        }

        return eventDataList;
    }

    function getDailyEventsByCategory(
        uint8 _category,
        uint256 _date1,
        uint256 _timestamp1,
        uint256 _date2,
        uint256 _timestamp2
    ) external view returns (EventInfo[] memory) {
        require(_date2 > _date1 && _timestamp2 > _timestamp1, "Invalid Params");

        EventInfo[] memory eventDataList = new EventInfo[](
            dailyEventsByCategory[_category][_date1].length() +
                dailyEventsByCategory[_category][_date2].length()
        );
        for (
            uint256 i;
            i < dailyEventsByCategory[_category][_date1].length();
            i++
        ) {
            EventInfo memory eventData = eventList[
                dailyEventsByCategory[_category][_date1].at(i)
            ];
            if (eventData.startTime >= _timestamp1)
                eventDataList[i] = eventData;
        }

        for (
            uint256 i;
            i < dailyEventsByCategory[_category][_date2].length();
            i++
        ) {
            EventInfo memory eventData = eventList[
                dailyEventsByCategory[_category][_date2].at(i)
            ];
            if (eventData.startTime <= _timestamp2)
                eventDataList[
                    dailyEventsByCategory[_category][_date1].length() + i
                ] = eventData;
        }

        return eventDataList;
    }

    function readSubcategory(uint8 _category, uint8 _subcategory)
        external
        view
        returns (string memory)
    {
        require(categoryNumber > _category, "Invalid category number.");
        require(
            categoryList[_category].numberOfSubcategories >= _subcategory,
            "Invalid subcategory number."
        );
        return subcategories[_category][_subcategory];
    }

    function getWinAmount(
        address _bettor,
        uint256 _eventID,
        EventResult _betValue
    ) internal view returns (uint256) {
        uint256 betAmount = betDataList[betDataByBettor[_bettor][_eventID][_betValue]]
            .betAmount;

        uint256 winAmount = (((eventList[_eventID].bettingVolume * betAmount) /
            betAmountsPerSideByEvent[_eventID][_betValue]) *
            (100 - feePercentage)) / 100;

        return winAmount;
    }

    function getEventDetailByBettor(uint256 _eventID, address _bettor)
        external
        view
        returns (EventDetailPerBettor memory)
    {
        uint256[] memory sidePoolVolumes;
        uint256[] memory sideBetAmounts;
        uint8 category = eventList[_eventID].category;
        EventType eType = categoryList[category].eType;
        if (eType == EventType.Double) {
            sidePoolVolumes = new uint256[](2);
            sidePoolVolumes[0] = betAmountsPerSideByEvent[_eventID][
                EventResult.Home
            ];
            sidePoolVolumes[1] = betAmountsPerSideByEvent[_eventID][
                EventResult.Away
            ];

            sideBetAmounts = new uint256[](2);
            sideBetAmounts[0] = betDataList[betDataByBettor[_bettor][_eventID][
                EventResult.Home
            ]].betAmount;
            sideBetAmounts[1] = betDataList[betDataByBettor[_bettor][_eventID][
                EventResult.Away
            ]].betAmount;
        } else {
            sidePoolVolumes = new uint256[](3);
            sidePoolVolumes[0] = betAmountsPerSideByEvent[_eventID][
                EventResult.Home
            ];
            sidePoolVolumes[1] = betAmountsPerSideByEvent[_eventID][
                EventResult.Draw
            ];
            sidePoolVolumes[2] = betAmountsPerSideByEvent[_eventID][
                EventResult.Away
            ];

            sideBetAmounts = new uint256[](3);
            sideBetAmounts[0] = betDataList[betDataByBettor[_bettor][_eventID][
                EventResult.Home
            ]].betAmount;
            sideBetAmounts[1] = betDataList[betDataByBettor[_bettor][_eventID][
                EventResult.Draw
            ]].betAmount;
            sideBetAmounts[2] = betDataList[betDataByBettor[_bettor][_eventID][
                EventResult.Away
            ]].betAmount;
        }

        return
            EventDetailPerBettor(
                _eventID,
                eventList[_eventID].description,
                category,
                eventList[_eventID].subcategory,
                eventList[_eventID].startTime,
                eType,
                sidePoolVolumes,
                sideBetAmounts
            );
    }

    function setNoticeTime(uint16 _time) external onlyAdmin {
        noticeBetTime = _time;
    }

    function setUltiBetsTreasury(address _treasury) external onlyAdmin {
        ultiBetsTreasury = _treasury;
    }

    function setUltibetsBuyBack(address _buyback) external onlyAdmin {
        ultiBetsBuyback = _buyback;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";

///@title This contract enables to create multiple contract administrators.
contract CustomAdmin is Ownable {
    mapping(address => bool) public admins;
    mapping(address => bool) public Oracles;

    event AdminAdded(address indexed _address);
    event AdminRemoved(address indexed _address);
    event OracleAdded(address indexed _address);
    event OracleRemoved(address indexed _address);

    ///@notice Validates if the sender is actually an administrator.
    modifier onlyAdmin() {
        require(
            admins[msg.sender] || msg.sender == owner(),
            "Only Admin and Owner can perform this function"
        );
        _;
    }

    modifier OnlyOracle() {
        require(
            Oracles[msg.sender] || msg.sender == owner(),
            "Only Oracle and Owner can perform this function"
        );
        _;
    }

    ///@notice Labels the specified address as an admin.
    ///@param _address The address to add as admin.
    function addAdmin(address _address) public onlyAdmin {
        require(_address != address(0));
        require(!admins[_address]);

        //The owner is already an admin and cannot be added.
        require(_address != owner());

        admins[_address] = true;

        emit AdminAdded(_address);
    }

    ///@notice Labels the specified address as an oracle.
    ///@param _address The address to add as oracle.
    function addOracle(address _address) public onlyAdmin {
        require(_address != address(0));
        require(!Oracles[_address]);

        //The owner is already an Oracle and cannot be added.
        require(_address != owner());

        Oracles[_address] = true;

        emit OracleAdded(_address);
    }

    ///@notice Adds multiple addresses to be admins.
    ///@param _accounts The wallet addresses to add as admins.
    function addManyAdmins(address[] memory _accounts) external onlyAdmin {
        for (uint8 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];

            ///Zero address cannot be an admin.
            ///The owner is already an admin and cannot be assigned.
            ///The address cannot be an existing admin.
            if (
                account != address(0) && !admins[account] && account != owner()
            ) {
                admins[account] = true;

                emit AdminAdded(_accounts[i]);
            }
        }
    }

    ///@notice Adds multiple addresses to be oracles.
    ///@param _accounts The wallet addresses to add as oracles.
    function addManyOracle(address[] memory _accounts) external onlyAdmin {
        for (uint8 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];

            ///Zero address cannot be an Oracle.
            ///The owner is already an admin and cannot be assigned.
            ///The address cannot be an existing Oracle.
            if (
                account != address(0) && !Oracles[account] && account != owner()
            ) {
                Oracles[account] = true;

                emit OracleAdded(_accounts[i]);
            }
        }
    }

    ///@notice Removes admin status from the specific address.
    ///@param _address The address to remove as admin.
    function removeAdmin(address _address) external onlyAdmin {
        require(_address != address(0));
        require(admins[_address]);

        //The owner cannot be removed as admin.
        require(_address != owner());

        admins[_address] = false;
        emit AdminRemoved(_address);
    }

    ///@notice Removes oracle status from the specific address.
    ///@param _address The address to remove as oracle.
    function removeOracle(address _address) external onlyAdmin {
        require(_address != address(0));
        require(Oracles[_address]);

        //The owner cannot be removed as Oracle.
        require(_address != owner());

        Oracles[_address] = false;
        emit OracleRemoved(_address);
    }

    ///@notice Removes admin status from the provided addresses.
    ///@param _accounts The addresses to remove as admin.
    function removeManyAdmins(address[] memory _accounts) external onlyAdmin {
        for (uint8 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];

            ///Zero address can neither be added or removed.
            ///The owner is the super admin and cannot be removed.
            ///The address must be an existing admin in order for it to be removed.
            if (
                account != address(0) && admins[account] && account != owner()
            ) {
                admins[account] = false;

                emit AdminRemoved(_accounts[i]);
            }
        }
    }

    ///@notice Removes oracle status from the provided addresses.
    ///@param _accounts The addresses to remove as oracle.
    function removeManyOracles(address[] memory _accounts) external onlyAdmin {
        for (uint8 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];

            ///Zero address can neither be added or removed.
            ///The address must be an existing oracle in order for it to be removed.
            if (
                account != address(0) && Oracles[account] && account != owner()
            ) {
                Oracles[account] = false;

                emit OracleRemoved(_accounts[i]);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}