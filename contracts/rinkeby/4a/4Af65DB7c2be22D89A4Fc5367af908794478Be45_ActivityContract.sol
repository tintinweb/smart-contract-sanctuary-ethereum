// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

/**
 * @title Minerva Activity Contract
 * @author Slowqueso/Lynda Barn/Kartik Ranjan
 * @notice This contract allows users to create a MOU or Agreement between Activity hosts and Activity Members.
 * @dev Data Price Feeds are implemented for ETH / USD
 */
contract ActivityContract is KeeperCompatibleInterface {
    // Type Declarations
    /**
     * @notice Global Variables for owner, price feed and logical minimum USD for making contract prices.
     */
    uint256[] internal minUSD = [3, 20, 40, 60, 100];
    AggregatorV3Interface private s_priceFeed;
    address private immutable i_owner;
    uint256 private s_lastUpdated;
    uint256 private s_counter;

    // Custom Type Variables
    /**
     * @dev 4 States of Activity.
     * `OPEN `- The activity allows members to join
     * `IN_PROGRESS` - Checks for how long the progress is
     * `CLOSED` - Activity does not accept anymore members
     * `FAILED` - Activity deleted
     */
    enum ActivityStatus {
        OPEN,
        IN_PROGRESS,
        CLOSED,
        FAILED
    }

    constructor() {
        s_priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        i_owner = msg.sender;
        s_lastUpdated = block.timestamp;
    }

    /**
     * @notice struct for `Activities`
     */
    struct Activity {
        uint256 id;
        address payable owner;
        string title;
        string desc;
        uint256 joinPrice;
        uint256 level;
        ActivityStatus status;
        uint256 dateOfCreation;
        uint256 totalTimeInMonths;
        uint256 maxMembers;
        address payable[] members;
        uint256 waitingPeriodInMonths;
    }

    /**
     * @notice struct for Activity Members
     * @dev `dateOfJoin` is in a DDMMYY format.
     */
    struct Member {
        string username;
        uint256 tenureInMonths;
        uint256 dateOfJoin;
        uint256 forActivity;
        uint256 timeJoined;
    }

    /**
     * @notice struct for each Terms and Conditions for Activities
     */
    struct Term {
        string title;
        string desc;
        uint256 id;
    }

    // Arrays and Mappings
    mapping(uint256 => Activity) Activities;
    mapping(address => Member) Members;
    mapping(uint256 => Term[]) Terms;
    uint256[] arrayForLength;
    address payable[] memberAddress;
    uint256[] activitiesForUpkeep;

    // Security modifiers
    /**
     * @dev to allow only Activity owners to execute the function
     */
    modifier onlyActivityOwners(uint256 _id) {
        require(
            msg.sender == Activities[_id].owner,
            "You are not allowed to perform this task!"
        );
        _;
    }

    /**
     * @dev Checks activity status and Member requirements
     */
    modifier isActivityJoinable(uint256 _id) {
        require(
            Activities[_id].status == ActivityStatus.OPEN &&
                Activities[_id].members.length <= Activities[_id].maxMembers,
            "Activity is not looking for members right now!"
        );
        _;
    }

    /**
     * @dev To allow functions to be executed only by Contract owner - Minerva
     */
    modifier onlyOwner() {
        require(msg.sender == i_owner);
        _;
    }

    /**
     * @dev To check existence of an activity
     */
    modifier doesActivityExist(uint256 _id) {
        require(Activities[_id].id > 0, "Activity Does not exist");
        _;
    }

    /**
     * @dev to check if the sender is a member of the activity
     */
    modifier isMemberOfActivity(uint256 _id) {
        bool isNotMember = true;
        for (uint256 i = 0; i < Activities[_id].members.length; i++) {
            if (Activities[_id].members[i] == payable(msg.sender)) {
                isNotMember = false;
            }
        }
        require(isNotMember, "You are already a member of this activity");
        _;
    }

    //Events
    event ActivityCreated(
        uint256 _id,
        string _title,
        uint256 _totalTimeInMonths,
        uint256 _level,
        uint256 dateOfCreation
    );
    event MemberJoined(
        uint256 _id,
        string _username,
        uint256 _dateOfJoin,
        uint256 _tenureInMonths
    );
    event TermAdded(Term[] terms);

    // Create Activity
    /**
     * @notice Function for creating an Activity
     * @dev emits Event - `ActivityCreated`
     */
    function createActivity(
        string memory _username,
        string memory _title,
        string memory _desc,
        uint256 _totalTimeInMonths,
        uint256 _price,
        uint256 _level,
        uint256 _maxMembers,
        uint256 dateOfCreation,
        uint256 _waitingPeriodInMonths //DDMMYY
    ) public payable {
        require(_price <= minUSD[_level - 1], "ETH limit crossed");
        uint256 id = arrayForLength.length + 1;
        memberAddress.push(payable(msg.sender));
        Activity memory activity = Activity(
            id,
            payable(msg.sender),
            _title,
            _desc,
            _price,
            _level,
            ActivityStatus.OPEN,
            block.timestamp,
            _totalTimeInMonths,
            _maxMembers,
            memberAddress,
            _waitingPeriodInMonths
        );
        Members[msg.sender] = Member(
            _username,
            _totalTimeInMonths,
            dateOfCreation,
            id,
            block.timestamp
        );
        arrayForLength.push(id);
        Activities[id] = activity;
        emit ActivityCreated(
            id,
            _title,
            _totalTimeInMonths,
            _level,
            dateOfCreation
        );
        delete memberAddress;
    }

    // Join Activity
    /**
     * @dev Modifiers used - `isActivityJoinable`, `doesActivityExist`, `isMemberOfActivity`. Events emitted - `MemberJoined`.
     * @notice Function for external users (in terms of Activity) to participate in the Activity.
     */
    function joinActivity(
        uint256 _activityID,
        string memory _username,
        uint256 _dateOfJoin,
        uint256 _tenureInMonths
    )
        public
        payable
        doesActivityExist(_activityID)
        isActivityJoinable(_activityID)
        isMemberOfActivity(_activityID)
    {
        Activity storage activity = Activities[_activityID];
        require(
            getConversionRate(msg.value) <= activity.joinPrice &&
                getConversionRate(msg.value) >= activity.joinPrice - 1,
            "Send required ETH"
        );
        Members[msg.sender] = Member(
            _username,
            _tenureInMonths,
            _dateOfJoin,
            _activityID,
            block.timestamp
        );
        activity.members.push(payable(msg.sender));
        (bool sent, ) = activity.owner.call{value: msg.value}("");
        emit MemberJoined(_activityID, _username, _dateOfJoin, _tenureInMonths);
        require(sent, "Failed to send ETH");
    }

    /**
     * @dev Modifiers - `onlyActivityOwners`, `doesActivityExist`, Events emitted - `TermAdded`
     * @notice Method to allow activity owners to add terms and conditions to their Activities
     */
    function addTermForActivity(
        uint256 _activityID,
        string memory _title,
        string memory _desc
    ) public doesActivityExist(_activityID) onlyActivityOwners(_activityID) {
        Term[] storage term = Terms[_activityID];
        term.push(Term(_title, _desc, _activityID));
        emit TermAdded(term);
    }

    // Keepers

    function checkUpkeep(
        bytes memory /* checkData */
    )
        external
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool checkIfDayPassed = ((block.timestamp - s_lastUpdated) > 1 days);
        bool activitiesAdded = false;
        bool hasBalance = address(this).balance > 0;
        s_counter++;
        Activity memory activity;
        if (checkIfDayPassed) {
            for (uint256 i = 1; i < arrayForLength.length + 1; i++) {
                activity = Activities[i];
                if (activity.status == ActivityStatus.OPEN) {
                    if (
                        !((block.timestamp - activity.dateOfCreation) >
                            (activity.waitingPeriodInMonths * 30 * 1 days))
                    ) {
                        if (!(activity.members.length > 1)) {
                            activitiesForUpkeep.push(i);
                            activitiesAdded = true;
                        }
                    }
                }
            }
        }
        s_lastUpdated = block.timestamp;
        upkeepNeeded = (checkIfDayPassed && activitiesAdded && hasBalance);
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        // (bool upkeepNeeded, ) = checkUpkeep("");
        // require(!upkeepNeeded, "Upkeep not needed");
        Activity storage activity;
        for (uint i = 0; i < activitiesForUpkeep.length; i++) {
            uint256 id = activitiesForUpkeep[i];
            activity = Activities[id];
            activity.status = ActivityStatus.CLOSED;
        }
        delete activitiesForUpkeep;
        s_lastUpdated = block.timestamp;
        s_counter++;
    }

    // Miscellaneous
    function getPrice() internal view returns (uint256) {
        (, int256 answer, , , ) = s_priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function getConversionRate(uint256 ethAmount)
        internal
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount);
        return ethAmountInUsd / 1e36;
    }

    function getActivity(uint256 activityID)
        public
        view
        returns (Activity memory)
    {
        Activity memory returnActivity = Activities[activityID];
        return (returnActivity);
    }

    function getOwner() public view onlyOwner returns (address) {
        return (i_owner);
    }

    function getMembersOfActivity(uint256 _activityID)
        public
        view
        returns (address payable[] memory)
    {
        address payable[] memory returnMembers;
        Activity memory activity = Activities[_activityID];
        returnMembers = activity.members;
        return (returnMembers);
    }

    function getMemberDetails(address _memberAddress)
        public
        view
        returns (Member memory)
    {
        Member memory member = Members[_memberAddress];
        return (member);
    }

    function getTermsForActivity(uint256 _activityID)
        public
        view
        returns (Term[] memory)
    {
        return Terms[_activityID];
    }

    function getCounterValue() public view returns (uint256) {
        return (s_counter);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}