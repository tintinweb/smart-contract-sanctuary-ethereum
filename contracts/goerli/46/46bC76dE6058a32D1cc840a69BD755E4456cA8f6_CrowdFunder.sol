// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Cause.sol";

contract CrowdFunder {
    //STATE VARIABLES
    address payable public immutable i_crowdFunderOwner;
    mapping(address => address) public walletToCauseOwned;
    mapping(address => uint256) public hasCause;
    mapping(address => uint256) public causeToId;
    uint256 public immutable i_percentCut;
    uint256 public s_nextCauseId;
    Cause[] public s_causes;

    //CUSTOM ERRORS
    error CrowdFunder__Unauthorised();
    error CrowdFunder__AlreadyHasACause();
    error CrowdFunder__ErrorWithdrawing();

    //EVENTS
    event CauseCreated(address indexed causeAddress);
    event DonationReceived(uint256 indexed amount);
    event WithdrawalMade(uint256 indexed amount);

    //MODIFIERS
    modifier onlyOwner() {
        if (msg.sender != i_crowdFunderOwner) {
            revert CrowdFunder__Unauthorised();
        }
        _;
    }

    //CONSTRUCTOR
    constructor(
        uint256 percentCut /*Percentage given in Basis Points ie 100 basis points=1% */
    ) {
        i_crowdFunderOwner = payable(msg.sender);
        i_percentCut = percentCut;
        s_nextCauseId = 1;
    }

    //RECEIVE AND FALLBACK FUNCTIONS
    receive() external payable {
        sponsorSite();
    }

    fallback() external payable {
        sponsorSite();
    }

    //PURE FUNCTIONS
    //Create Cause Function
    function createCause(string memory causeName, uint256 goal) public returns (address) {
        if (hasCause[msg.sender] != 0) {
            revert CrowdFunder__AlreadyHasACause();
        }
        Cause newCause = new Cause(
            causeName,
            goal,
            payable(msg.sender),
            i_percentCut,
            s_nextCauseId
        );
        newCause.unlock();
        s_causes.push(newCause);
        walletToCauseOwned[msg.sender] = address(newCause);
        hasCause[msg.sender] = s_nextCauseId;
        causeToId[address(newCause)] = s_nextCauseId;
        s_nextCauseId = s_nextCauseId + 1;
        emit CauseCreated(address(newCause));
        return address(newCause);
    }

    function sponsorSite() public payable {
        emit DonationReceived(msg.value);
    }

    //Withdraw Function
    function withdraw() public payable onlyOwner {
        uint256 amount = address(this).balance;
        bool success = payable(msg.sender).send(amount);
        if (!success) {
            revert CrowdFunder__ErrorWithdrawing();
        }
    }

    //Block Cause Function
    function lock(uint256 causeId) public onlyOwner {
        Cause cause = s_causes[causeId - 1];
        cause.lock();
    }

    function unlock(uint256 causeId) public onlyOwner {
        Cause cause = s_causes[causeId - 1];
        cause.unlock();
    }

    //Handover Function

    function handover(address newOwner) public {
        require((hasCause[msg.sender] != 0) && (hasCause[newOwner] == 0));
        hasCause[newOwner] = hasCause[msg.sender];
        hasCause[msg.sender] = 0;
        walletToCauseOwned[newOwner] = walletToCauseOwned[msg.sender];
        walletToCauseOwned[msg.sender] = address(0);
    }

    //VIEW FUNCTIONS
    function getCauseById(uint256 causeId) public view returns (address) {
        address causeAddress = address(s_causes[causeId - 1]);
        return causeAddress;
    }

    function getCauseAddressByOwnerWallet(address owner) public view returns (address) {
        address causeAddress = walletToCauseOwned[owner];
        return causeAddress;
    }

    function getCauseIdByOwnerAddress(address owner) public view returns (uint256) {
        uint256 causeId = hasCause[owner];
        return causeId;
    }

    function getCauseIdByCauseAddress(address causeAddress) public view returns (uint256) {
        uint256 causeId = causeToId[causeAddress];
        return causeId;
    }

    function getMyCauseId() public view returns (uint256) {
        uint256 causeId = hasCause[msg.sender];
        return (causeId);
    }

    function getLatestCauseAddress() public view returns (address) {
        address latestCauseAddress = address(s_causes[s_nextCauseId - 2]);
        return latestCauseAddress;
    }

    function getLatestCauseId() public view returns (uint256) {
        uint256 latestCauseId = s_nextCauseId - 1;
        return latestCauseId;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getContractOwner() public view returns (address) {
        return i_crowdFunderOwner;
    }

    function getPercentCut() public view returns (uint256) {
        return i_percentCut;
    }

    function confirmCause(address causeToCheck) public view returns (bool) {
        /*Returns true if the Cause is truly deployed by this contract */
        if (causeToId[causeToCheck] != 0) {
            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Cause {
    //Type Declarations
    struct donation {
        address donor;
        int256 amount;
    }

    //State Variables
    uint256 public s_causeBalance;
    uint256 public immutable i_goal;
    uint256 public immutable i_percentCut;
    uint256 public immutable i_causeId;
    uint256 public s_numRefunds;
    bool public s_isGoalReached;
    bool public s_isOpenToDonations;
    bool public s_isBlocked;
    bool public s_isWithdrawn;
    address public s_causeOwner;
    address public s_causeCreatorContract;
    string public s_causeName;
    string public s_causeURI;
    mapping(address => uint256) public donorToAmountDonated;
    donation[] public donationList;

    //Custom Errors
    error Cause__IsNotOpenToDonations();
    error Cause__CannotInCurrentState();
    error Cause__NotAuthorized();
    error Cause__ErrorWithdrawing();
    error Cause__AlreadyInState();
    error Cause__YouDoNotHaveADonation();

    //Events
    event DonationMade(address indexed donor, uint256 amount);
    event WithdrawalMade(address indexed withdrawer, uint256 amount);
    event IsOpenToDonationsSwitched(bool isOpenToDonations);
    event OwnershipChanged(address indexed newOwner);
    event CauseURISet(string causeURI);
    event CauseLocked(bool isLocked);
    event CauseUnlocked(bool isLocked);
    event Refunded(address refundee, uint256 amount);

    modifier onlyOwner() {
        if (msg.sender != s_causeOwner) {
            revert Cause__NotAuthorized();
        }
        _;
    }

    modifier onlyParentContract() {
        if (msg.sender != s_causeCreatorContract) {
            revert Cause__NotAuthorized();
        }
        _;
    }

    //Constructor
    constructor(
        string memory causeName,
        uint256 goal,
        address payable causeOwner,
        uint256 percentCut,
        uint256 causeId
    ) {
        s_causeCreatorContract = msg.sender;
        s_causeName = causeName;
        s_causeOwner = causeOwner;
        i_goal = goal;
        s_isOpenToDonations = true;
        i_percentCut = percentCut;
        i_causeId = causeId;
        s_isBlocked = true;
        s_numRefunds = 0;
    }

    //Receive and Fallback Functions
    receive() external payable {
        donate();
    }

    fallback() external payable {
        donate();
    }

    //PURE FUNCTIONS
    //Donate Function
    function donate() public payable {
        if (s_isGoalReached) {
            revert Cause__CannotInCurrentState();
        }
        if (!s_isOpenToDonations) {
            revert Cause__CannotInCurrentState();
        }
        if (s_isBlocked) {
            revert Cause__CannotInCurrentState();
        }
        if (s_isWithdrawn) {
            revert Cause__CannotInCurrentState();
        }

        s_causeBalance += msg.value;
        donation memory newDonation = donation(msg.sender, int256(msg.value));
        donationList.push(newDonation);
        donorToAmountDonated[msg.sender] += msg.value;
        if (s_causeBalance >= i_goal) {
            s_isGoalReached = true;
        }
        emit DonationMade(msg.sender, msg.value);
    }

    //Withdraw Function
    function withdraw() public onlyOwner {
        if (s_isBlocked) {
            revert Cause__CannotInCurrentState();
        }
        uint256 amount = address(this).balance;
        uint256 parentContractCut = ((amount * i_percentCut) / 10000);
        bool paymentToParentSuccess = payable(s_causeCreatorContract).send(parentContractCut);
        if (!paymentToParentSuccess) {
            revert Cause__ErrorWithdrawing();
        }
        bool withdrawalSuccess = payable(msg.sender).send(address(this).balance);
        if (!withdrawalSuccess) {
            revert Cause__ErrorWithdrawing();
        } else {
            s_causeBalance = 0;
            s_isWithdrawn = true;
            emit WithdrawalMade(msg.sender, amount);
        }
    }

    function changeOwnership(address payable newOwner) public onlyOwner {
        if (s_isBlocked) {
            revert Cause__CannotInCurrentState();
        }
        s_causeOwner = newOwner;
        emit OwnershipChanged(newOwner);
    }

    function switchIsOpenToDonations() public onlyOwner {
        if (s_isOpenToDonations) {
            s_isOpenToDonations = false;
        } else {
            s_isOpenToDonations = true;
        }
        emit IsOpenToDonationsSwitched(s_isOpenToDonations);
    }

    function setCauseURI(
        string memory causeURI /* Will be the URI of an IPFS Json file  */
    ) public onlyOwner {
        if (s_isBlocked) {
            revert Cause__CannotInCurrentState();
        }
        s_causeURI = causeURI;
        emit CauseURISet(s_causeURI);
    }

    function lock() public onlyParentContract {
        if (s_isBlocked) {
            revert Cause__AlreadyInState();
        }
        s_isBlocked = true;
        emit CauseLocked(s_isBlocked);
    }

    function unlock() public onlyParentContract {
        if (!s_isBlocked) {
            revert Cause__AlreadyInState();
        }
        s_isBlocked = false;
        emit CauseUnlocked(s_isBlocked);
    }

    function demandRefund() public payable {
        if (s_isWithdrawn) {
            revert Cause__CannotInCurrentState();
        }
        if (donorToAmountDonated[msg.sender] == 0) {
            revert Cause__YouDoNotHaveADonation();
        }
        uint256 amount = donorToAmountDonated[msg.sender];
        donorToAmountDonated[msg.sender] = 0;
        bool success = payable(msg.sender).send(amount);
        if (!success) {
            revert Cause__ErrorWithdrawing();
        }
        donation memory newDonation = donation(msg.sender, -int256(amount));
        donationList.push(newDonation);

        s_numRefunds = s_numRefunds + 1;
        s_causeBalance = s_causeBalance - amount;
        if (s_causeBalance < i_goal) {
            s_isGoalReached = false;
        }

        emit Refunded(msg.sender, amount);
    }

    //VIEW FUNCTIONS
    function getCauseBalance() public view returns (uint256) {
        return s_causeBalance;
    }

    function getGoal() public view returns (uint256) {
        return i_goal;
    }

    function getCauseName() public view returns (string memory) {
        return s_causeName;
    }

    function getCauseOwner() public view returns (address) {
        return s_causeOwner;
    }

    function getIsGoalReached() public view returns (bool) {
        return s_isGoalReached;
    }

    function getIsOpenToDonations() public view returns (bool) {
        return s_isOpenToDonations;
    }

    function getCauseURI() public view returns (string memory) {
        return s_causeURI;
    }

    function getIsWithdrawn() public view returns (bool) {
        return s_isWithdrawn;
    }

    function getIsLocked() public view returns (bool) {
        return s_isBlocked;
    }

    function getMyDonation() public view returns (uint256) {
        uint256 donationAmount = donorToAmountDonated[msg.sender];
        return donationAmount;
    }

    function getNumDonations() public view returns (uint256) {
        uint256 numDonations = donationList.length;
        return numDonations;
    }

    function getDonationList() public view returns (donation[] memory) {
        return donationList;
    }

    function getNumRefunds() public view returns (uint256) {
        return s_numRefunds;
    }
}