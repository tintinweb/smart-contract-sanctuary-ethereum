pragma solidity 0.5.8;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Wallet.sol";
import "./VestingEscrowWalletStorage.sol";

/**
 * @title Wallet for core vesting escrow functionality
 */
contract VestingEscrowWallet is VestingEscrowWalletStorage, Wallet {
    using SafeMath for uint256;

    // States used to represent the status of the schedule
    enum State {CREATED, STARTED, COMPLETED}

    // Emit when new schedule is added
    event AddSchedule(
        address indexed _beneficiary,
        bytes32 _templateName,
        uint256 _startTime
    );
    // Emit when schedule is modified
    event ModifySchedule(
        address indexed _beneficiary,
        bytes32 _templateName,
        uint256 _startTime
    );
    // Emit when all schedules are revoked for user
    event RevokeAllSchedules(address indexed _beneficiary);
    // Emit when schedule is revoked
    event RevokeSchedule(address indexed _beneficiary, bytes32 _templateName);
    // Emit when tokes are deposited to wallet
    event DepositTokens(uint256 _numberOfTokens, address _sender);
    // Emit when all unassigned tokens are sent to treasury
    event SendToTreasury(uint256 _numberOfTokens, address _sender);
    // Emit when is sent tokes to user
    event SendTokens(address indexed _beneficiary, uint256 _numberOfTokens);
    // Emit when template is added
    event AddTemplate(bytes32 _name, uint256 _numberOfTokens, uint256 _duration, uint256 _frequency);
    // Emit when template is removed
    event RemoveTemplate(bytes32 _name);
    // Emit when the treasury wallet gets changed
    event TreasuryWalletChanged(address _newWallet, address _oldWallet);

    /**
     * @notice Constructor
     * @param _securityToken Address of the security token
     * @param _polyAddress Address of the polytoken
     */
    constructor (address _securityToken, address _polyAddress)
    public
    Module(_securityToken, _polyAddress)
    {
    }

    /**
     * @notice This function returns the signature of the configure function
     */
    function getInitFunction() public pure returns (bytes4) {
        return this.configure.selector;
    }

    /**
     * @notice Used to initialize the treasury wallet address
     * @param _treasuryWallet Address of the treasury wallet
     */
    function configure(address _treasuryWallet) public onlyFactory {
        _setWallet(_treasuryWallet);
    }

    /**
     * @notice Used to change the treasury wallet address
     * @param _newTreasuryWallet Address of the treasury wallet
     */
    function changeTreasuryWallet(address _newTreasuryWallet) public {
        _onlySecurityTokenOwner();
        _setWallet(_newTreasuryWallet);
    }

    function _setWallet(address _newTreasuryWallet) internal {
        emit TreasuryWalletChanged(_newTreasuryWallet, treasuryWallet);
        treasuryWallet = _newTreasuryWallet;
    }

    /**
     * @notice Used to deposit tokens from treasury wallet to the vesting escrow wallet
     * @param _numberOfTokens Number of tokens that should be deposited
     */
    function depositTokens(uint256 _numberOfTokens) external withPerm(ADMIN) {
        _depositTokens(_numberOfTokens);
    }

    function _depositTokens(uint256 _numberOfTokens) internal {
        require(_numberOfTokens > 0, "Should be > 0");
        require(
            securityToken.transferFrom(msg.sender, address(this), _numberOfTokens),
            "Failed transferFrom"
        );
        unassignedTokens = unassignedTokens.add(_numberOfTokens);
        emit DepositTokens(_numberOfTokens, msg.sender);
    }

    /**
     * @notice Sends unassigned tokens to the treasury wallet
     * @param _amount Amount of tokens that should be send to the treasury wallet
     */
    function sendToTreasury(uint256 _amount) public withPerm(OPERATOR) {
        require(_amount > 0, "Amount cannot be zero");
        require(_amount <= unassignedTokens, "Amount is greater than unassigned tokens");
        unassignedTokens = unassignedTokens - _amount;
        require(securityToken.transfer(getTreasuryWallet(), _amount), "Transfer failed");
        emit SendToTreasury(_amount, msg.sender);
    }

    /**
     * @notice Returns the treasury wallet address
     */
    function getTreasuryWallet() public view returns(address) {
        if (treasuryWallet == address(0)) {
            address wallet = IDataStore(getDataStore()).getAddress(TREASURY);
            require(wallet != address(0), "Invalid address");
            return wallet;
        } else
            return treasuryWallet;
    }

    /**
     * @notice Pushes available tokens to the beneficiary's address
     * @param _beneficiary Address of the beneficiary who will receive tokens
     */
    function pushAvailableTokens(address _beneficiary) public withPerm(OPERATOR) {
        _sendTokens(_beneficiary);
    }

    /**
     * @notice Used to withdraw available tokens by beneficiary
     */
    function pullAvailableTokens() external whenNotPaused {
        _sendTokens(msg.sender);
    }

    /**
     * @notice Adds template that can be used for creating schedule
     * @param _name Name of the template will be created
     * @param _numberOfTokens Number of tokens that should be assigned to schedule
     * @param _duration Duration of the vesting schedule
     * @param _frequency Frequency of the vesting schedule
     */
    function addTemplate(bytes32 _name, uint256 _numberOfTokens, uint256 _duration, uint256 _frequency) external withPerm(ADMIN) {
        _addTemplate(_name, _numberOfTokens, _duration, _frequency);
    }

    function _addTemplate(bytes32 _name, uint256 _numberOfTokens, uint256 _duration, uint256 _frequency) internal {
        require(_name != bytes32(0), "Invalid name");
        require(!_isTemplateExists(_name), "Already exists");
        _validateTemplate(_numberOfTokens, _duration, _frequency);
        templateNames.push(_name);
        templates[_name] = Template(_numberOfTokens, _duration, _frequency, templateNames.length - 1);
        emit AddTemplate(_name, _numberOfTokens, _duration, _frequency);
    }

    /**
     * @notice Removes template with a given name
     * @param _name Name of the template that will be removed
     */
    function removeTemplate(bytes32 _name) external withPerm(ADMIN) {
        require(_isTemplateExists(_name), "Template not found");
        require(templateToUsers[_name].length == 0, "Template is used");
        uint256 index = templates[_name].index;
        if (index != templateNames.length - 1) {
            templateNames[index] = templateNames[templateNames.length - 1];
            templates[templateNames[index]].index = index;
        }
        templateNames.length--;
        // delete template data
        delete templates[_name];
        emit RemoveTemplate(_name);
    }

    /**
     * @notice Returns count of the templates those can be used for creating schedule
     * @return Count of the templates
     */
    function getTemplateCount() external view returns(uint256) {
        return templateNames.length;
    }

    /**
     * @notice Gets the list of the template names those can be used for creating schedule
     * @return bytes32 Array of all template names were created
     */
    function getAllTemplateNames() external view returns(bytes32[] memory) {
        return templateNames;
    }

    /**
     * @notice Adds vesting schedules for each of the beneficiary's address
     * @param _beneficiary Address of the beneficiary for whom it is scheduled
     * @param _templateName Name of the template that will be created
     * @param _numberOfTokens Total number of tokens for created schedule
     * @param _duration Duration of the created vesting schedule
     * @param _frequency Frequency of the created vesting schedule
     * @param _startTime Start time of the created vesting schedule
     */
    function addSchedule(
        address _beneficiary,
        bytes32 _templateName,
        uint256 _numberOfTokens,
        uint256 _duration,
        uint256 _frequency,
        uint256 _startTime
    )
        external
        withPerm(ADMIN)
    {
        _addSchedule(_beneficiary, _templateName, _numberOfTokens, _duration, _frequency, _startTime);
    }

    function _addSchedule(
        address _beneficiary,
        bytes32 _templateName,
        uint256 _numberOfTokens,
        uint256 _duration,
        uint256 _frequency,
        uint256 _startTime
    )
        internal
    {
        _addTemplate(_templateName, _numberOfTokens, _duration, _frequency);
        _addScheduleFromTemplate(_beneficiary, _templateName, _startTime);
    }

    /**
     * @notice Adds vesting schedules from template for the beneficiary
     * @param _beneficiary Address of the beneficiary for whom it is scheduled
     * @param _templateName Name of the exists template
     * @param _startTime Start time of the created vesting schedule
     */
    function addScheduleFromTemplate(address _beneficiary, bytes32 _templateName, uint256 _startTime) external withPerm(ADMIN) {
        _addScheduleFromTemplate(_beneficiary, _templateName, _startTime);
    }

    function _addScheduleFromTemplate(address _beneficiary, bytes32 _templateName, uint256 _startTime) internal {
        require(_beneficiary != address(0), "Invalid address");
        require(_isTemplateExists(_templateName), "Template not found");
        uint256 index = userToTemplateIndex[_beneficiary][_templateName];
        require(
            schedules[_beneficiary].length == 0 ||
            schedules[_beneficiary][index].templateName != _templateName,
            "Already added"
        );
        require(_startTime >= now, "Date in the past");
        uint256 numberOfTokens = templates[_templateName].numberOfTokens;
        if (numberOfTokens > unassignedTokens) {
            _depositTokens(numberOfTokens.sub(unassignedTokens));
        }
        unassignedTokens = unassignedTokens.sub(numberOfTokens);
        if (!beneficiaryAdded[_beneficiary]) {
            beneficiaries.push(_beneficiary);
            beneficiaryAdded[_beneficiary] = true;
        }
        schedules[_beneficiary].push(Schedule(_templateName, 0, _startTime));
        userToTemplates[_beneficiary].push(_templateName);
        userToTemplateIndex[_beneficiary][_templateName] = schedules[_beneficiary].length - 1;
        templateToUsers[_templateName].push(_beneficiary);
        templateToUserIndex[_templateName][_beneficiary] = templateToUsers[_templateName].length - 1;
        emit AddSchedule(_beneficiary, _templateName, _startTime);
    }

    /**
     * @notice Modifies vesting schedules for each of the beneficiary
     * @param _beneficiary Address of the beneficiary for whom it is modified
     * @param _templateName Name of the template was used for schedule creation
     * @param _startTime Start time of the created vesting schedule
     */
    function modifySchedule(address _beneficiary, bytes32 _templateName, uint256 _startTime) external withPerm(ADMIN) {
        _modifySchedule(_beneficiary, _templateName, _startTime);
    }

    function _modifySchedule(address _beneficiary, bytes32 _templateName, uint256 _startTime) internal {
        _checkSchedule(_beneficiary, _templateName);
        require(_startTime > now, "Date in the past");
        uint256 index = userToTemplateIndex[_beneficiary][_templateName];
        Schedule storage schedule = schedules[_beneficiary][index];
        /*solium-disable-next-line security/no-block-members*/
        require(now < schedule.startTime, "Schedule started");
        schedule.startTime = _startTime;
        emit ModifySchedule(_beneficiary, _templateName, _startTime);
    }

    /**
     * @notice Revokes vesting schedule with given template name for given beneficiary
     * @param _beneficiary Address of the beneficiary for whom it is revoked
     * @param _templateName Name of the template was used for schedule creation
     */
    function revokeSchedule(address _beneficiary, bytes32 _templateName) external withPerm(ADMIN) {
        _checkSchedule(_beneficiary, _templateName);
        uint256 index = userToTemplateIndex[_beneficiary][_templateName];
        _sendTokensPerSchedule(_beneficiary, index);
        uint256 releasedTokens = _getReleasedTokens(_beneficiary, index);
        unassignedTokens = unassignedTokens.add(templates[_templateName].numberOfTokens.sub(releasedTokens));
        _deleteUserToTemplates(_beneficiary, _templateName);
        _deleteTemplateToUsers(_beneficiary, _templateName);
        emit RevokeSchedule(_beneficiary, _templateName);
    }

    function _deleteUserToTemplates(address _beneficiary, bytes32 _templateName) internal {
        uint256 index = userToTemplateIndex[_beneficiary][_templateName];
        Schedule[] storage userSchedules = schedules[_beneficiary];
        if (index != userSchedules.length - 1) {
            userSchedules[index] = userSchedules[userSchedules.length - 1];
            userToTemplates[_beneficiary][index] = userToTemplates[_beneficiary][userToTemplates[_beneficiary].length - 1];
            userToTemplateIndex[_beneficiary][userSchedules[index].templateName] = index;
        }
        userSchedules.length--;
        userToTemplates[_beneficiary].length--;
        delete userToTemplateIndex[_beneficiary][_templateName];
    }

    function _deleteTemplateToUsers(address _beneficiary, bytes32 _templateName) internal {
        uint256 templateIndex = templateToUserIndex[_templateName][_beneficiary];
        if (templateIndex != templateToUsers[_templateName].length - 1) {
            templateToUsers[_templateName][templateIndex] = templateToUsers[_templateName][templateToUsers[_templateName].length - 1];
            templateToUserIndex[_templateName][templateToUsers[_templateName][templateIndex]] = templateIndex;
        }
        templateToUsers[_templateName].length--;
        delete templateToUserIndex[_templateName][_beneficiary];
    }

    /**
     * @notice Revokes all vesting schedules for given beneficiary's address
     * @param _beneficiary Address of the beneficiary for whom all schedules will be revoked
     */
    function revokeAllSchedules(address _beneficiary) public withPerm(ADMIN) {
        _revokeAllSchedules(_beneficiary);
    }

    function _revokeAllSchedules(address _beneficiary) internal {
        require(_beneficiary != address(0), "Invalid address");
        _sendTokens(_beneficiary);
        Schedule[] storage userSchedules = schedules[_beneficiary];
        for (uint256 i = 0; i < userSchedules.length; i++) {
            uint256 releasedTokens = _getReleasedTokens(_beneficiary, i);
            Template memory template = templates[userSchedules[i].templateName];
            unassignedTokens = unassignedTokens.add(template.numberOfTokens.sub(releasedTokens));
            delete userToTemplateIndex[_beneficiary][userSchedules[i].templateName];
            _deleteTemplateToUsers(_beneficiary, userSchedules[i].templateName);
        }
        delete schedules[_beneficiary];
        delete userToTemplates[_beneficiary];
        emit RevokeAllSchedules(_beneficiary);
    }

    /**
     * @notice Returns beneficiary's schedule created using template name
     * @param _beneficiary Address of the beneficiary who will receive tokens
     * @param _templateName Name of the template was used for schedule creation
     * @return beneficiary's schedule data (numberOfTokens, duration, frequency, startTime, claimedTokens, State)
     */
    function getSchedule(address _beneficiary, bytes32 _templateName) external view returns(uint256, uint256, uint256, uint256, uint256, State) {
        _checkSchedule(_beneficiary, _templateName);
        uint256 index = userToTemplateIndex[_beneficiary][_templateName];
        Schedule memory schedule = schedules[_beneficiary][index];
        return (
            templates[schedule.templateName].numberOfTokens,
            templates[schedule.templateName].duration,
            templates[schedule.templateName].frequency,
            schedule.startTime,
            schedule.claimedTokens,
            _getScheduleState(_beneficiary, _templateName)
        );
    }

    function _getScheduleState(address _beneficiary, bytes32 _templateName) internal view returns(State) {
        _checkSchedule(_beneficiary, _templateName);
        uint256 index = userToTemplateIndex[_beneficiary][_templateName];
        Schedule memory schedule = schedules[_beneficiary][index];
        if (now < schedule.startTime) {
            return State.CREATED;
        } else if (now > schedule.startTime && now < schedule.startTime.add(templates[_templateName].duration)) {
            return State.STARTED;
        } else {
            return State.COMPLETED;
        }
    }

    /**
     * @notice Returns list of the template names for given beneficiary's address
     * @param _beneficiary Address of the beneficiary
     * @return List of the template names that were used for schedule creation
     */
    function getTemplateNames(address _beneficiary) external view returns(bytes32[] memory) {
        require(_beneficiary != address(0), "Invalid address");
        return userToTemplates[_beneficiary];
    }

    /**
     * @notice Returns count of the schedules were created for given beneficiary
     * @param _beneficiary Address of the beneficiary
     * @return Count of beneficiary's schedules
     */
    function getScheduleCount(address _beneficiary) external view returns(uint256) {
        require(_beneficiary != address(0), "Invalid address");
        return schedules[_beneficiary].length;
    }

    function _getAvailableTokens(address _beneficiary, uint256 _index) internal view returns(uint256) {
        Schedule memory schedule = schedules[_beneficiary][_index];
        uint256 releasedTokens = _getReleasedTokens(_beneficiary, _index);
        return releasedTokens.sub(schedule.claimedTokens);
    }

    function _getReleasedTokens(address _beneficiary, uint256 _index) internal view returns(uint256) {
        Schedule memory schedule = schedules[_beneficiary][_index];
        Template memory template = templates[schedule.templateName];
        /*solium-disable-next-line security/no-block-members*/
        if (now > schedule.startTime) {
            uint256 periodCount = template.duration.div(template.frequency);
            /*solium-disable-next-line security/no-block-members*/
            uint256 periodNumber = (now.sub(schedule.startTime)).div(template.frequency);
            if (periodNumber > periodCount) {
                periodNumber = periodCount;
            }
            return template.numberOfTokens.mul(periodNumber).div(periodCount);
        } else {
            return 0;
        }
    }

    /**
     * @notice Used to bulk send available tokens for each of the beneficiaries
     * @param _fromIndex Start index of array of beneficiary's addresses
     * @param _toIndex End index of array of beneficiary's addresses
     */
    function pushAvailableTokensMulti(uint256 _fromIndex, uint256 _toIndex) public withPerm(OPERATOR) {
        require(_toIndex < beneficiaries.length, "Array out of bound");
        for (uint256 i = _fromIndex; i <= _toIndex; i++) {
            if (schedules[beneficiaries[i]].length !=0)
                pushAvailableTokens(beneficiaries[i]);
        }
    }

    /**
     * @notice Used to bulk add vesting schedules for each of beneficiary
     * @param _beneficiaries Array of the beneficiary's addresses
     * @param _templateNames Array of the template names
     * @param _numberOfTokens Array of number of tokens should be assigned to schedules
     * @param _durations Array of the vesting duration
     * @param _frequencies Array of the vesting frequency
     * @param _startTimes Array of the vesting start time
     */
    function addScheduleMulti(
        address[] memory _beneficiaries,
        bytes32[] memory _templateNames,
        uint256[] memory _numberOfTokens,
        uint256[] memory _durations,
        uint256[] memory _frequencies,
        uint256[] memory _startTimes
    )
        public
        withPerm(ADMIN)
    {
        require(
            _beneficiaries.length == _templateNames.length && /*solium-disable-line operator-whitespace*/
            _beneficiaries.length == _numberOfTokens.length && /*solium-disable-line operator-whitespace*/
            _beneficiaries.length == _durations.length && /*solium-disable-line operator-whitespace*/
            _beneficiaries.length == _frequencies.length && /*solium-disable-line operator-whitespace*/
            _beneficiaries.length == _startTimes.length,
            "Arrays sizes mismatch"
        );
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            _addSchedule(_beneficiaries[i], _templateNames[i], _numberOfTokens[i], _durations[i], _frequencies[i], _startTimes[i]);
        }
    }

    /**
     * @notice Used to bulk add vesting schedules from template for each of the beneficiary
     * @param _beneficiaries Array of beneficiary's addresses
     * @param _templateNames Array of the template names were used for schedule creation
     * @param _startTimes Array of the vesting start time
     */
    function addScheduleFromTemplateMulti(
        address[] memory _beneficiaries,
        bytes32[] memory _templateNames,
        uint256[] memory _startTimes
    )
        public
        withPerm(ADMIN)
    {
        require(_beneficiaries.length == _templateNames.length && _beneficiaries.length == _startTimes.length, "Arrays sizes mismatch");
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            _addScheduleFromTemplate(_beneficiaries[i], _templateNames[i], _startTimes[i]);
        }
    }

    /**
     * @notice Used to bulk revoke vesting schedules for each of the beneficiaries
     * @param _beneficiaries Array of the beneficiary's addresses
     */
    function revokeSchedulesMulti(address[] memory _beneficiaries) public withPerm(ADMIN) {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            _revokeAllSchedules(_beneficiaries[i]);
        }
    }

    /**
     * @notice Used to bulk modify vesting schedules for each of the beneficiaries
     * @param _beneficiaries Array of the beneficiary's addresses
     * @param _templateNames Array of the template names
     * @param _startTimes Array of the vesting start time
     */
    function modifyScheduleMulti(
        address[] memory _beneficiaries,
        bytes32[] memory _templateNames,
        uint256[] memory _startTimes
    )
        public
        withPerm(ADMIN)
    {
        require(
            _beneficiaries.length == _templateNames.length && /*solium-disable-line operator-whitespace*/
            _beneficiaries.length == _startTimes.length,
            "Arrays sizes mismatch"
        );
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            _modifySchedule(_beneficiaries[i], _templateNames[i], _startTimes[i]);
        }
    }

    function _checkSchedule(address _beneficiary, bytes32 _templateName) internal view {
        require(_beneficiary != address(0), "Invalid address");
        uint256 index = userToTemplateIndex[_beneficiary][_templateName];
        require(
            index < schedules[_beneficiary].length &&
            schedules[_beneficiary][index].templateName == _templateName,
            "Schedule not found"
        );
    }

    function _isTemplateExists(bytes32 _name) internal view returns(bool) {
        return templates[_name].numberOfTokens > 0;
    }

    function _validateTemplate(uint256 _numberOfTokens, uint256 _duration, uint256 _frequency) internal view {
        require(_numberOfTokens > 0, "Zero amount");
        require(_duration % _frequency == 0, "Invalid frequency");
        uint256 periodCount = _duration.div(_frequency);
        require(_numberOfTokens % periodCount == 0);
        uint256 amountPerPeriod = _numberOfTokens.div(periodCount);
        require(amountPerPeriod % securityToken.granularity() == 0, "Invalid granularity");
    }

    function _sendTokens(address _beneficiary) internal {
        for (uint256 i = 0; i < schedules[_beneficiary].length; i++) {
            _sendTokensPerSchedule(_beneficiary, i);
        }
    }

    function _sendTokensPerSchedule(address _beneficiary, uint256 _index) internal {
        uint256 amount = _getAvailableTokens(_beneficiary, _index);
        if (amount > 0) {
            schedules[_beneficiary][_index].claimedTokens = schedules[_beneficiary][_index].claimedTokens.add(amount);
            require(securityToken.transfer(_beneficiary, amount), "Transfer failed");
            emit SendTokens(_beneficiary, amount);
        }
    }

    /**
     * @notice Return the permissions flag that are associated with VestingEscrowWallet
     */
    function getPermissions() public view returns(bytes32[] memory) {
        bytes32[] memory allPermissions = new bytes32[](2);
        allPermissions[0] = ADMIN;
        allPermissions[1] = OPERATOR;
        return allPermissions;
    }

}

pragma solidity 0.5.8;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/ISecurityToken.sol";
/**
 * @title Storage for Module contract
 * @notice Contract is abstract
 */
contract ModuleStorage {
    address public factory;

    ISecurityToken public securityToken;

    // Permission flag
    bytes32 public constant ADMIN = "ADMIN";
    bytes32 public constant OPERATOR = "OPERATOR";

    bytes32 internal constant TREASURY = 0xaae8817359f3dcb67d050f44f3e49f982e0359d90ca4b5f18569926304aaece6; // keccak256(abi.encodePacked("TREASURY_WALLET"))

    IERC20 public polyToken;

    /**
     * @notice Constructor
     * @param _securityToken Address of the security token
     * @param _polyAddress Address of the polytoken
     */
    constructor(address _securityToken, address _polyAddress) public {
        securityToken = ISecurityToken(_securityToken);
        factory = msg.sender;
        polyToken = IERC20(_polyAddress);
    }

}

pragma solidity 0.5.8;

import "../Module.sol";

/**
 * @title Interface to be implemented by all Wallet modules
 * @dev abstract contract
 */
contract Wallet is Module {

}

pragma solidity 0.5.8;

/**
 * @title Wallet for core vesting escrow functionality
 */
contract VestingEscrowWalletStorage {

    struct Schedule {
        // Name of the template
        bytes32 templateName;
        // Tokens that were already claimed
        uint256 claimedTokens;
        // Start time of the schedule
        uint256 startTime;
    }

    struct Template {
        // Total amount of tokens
        uint256 numberOfTokens;
        // Schedule duration (How long the schedule will last)
        uint256 duration;
        // Schedule frequency (It is a cliff time period)
        uint256 frequency;
        // Index of the template in an array template names
        uint256 index;
    }

    // Number of tokens that are hold by the `this` contract but are unassigned to any schedule
    uint256 public unassignedTokens;
    // Address of the Treasury wallet. All of the unassigned token will transfer to that address.
    address public treasuryWallet;
    // List of all beneficiaries who have the schedules running/completed/created
    address[] public beneficiaries;
    // Flag whether beneficiary has been already added or not
    mapping(address => bool) internal beneficiaryAdded;

    // Holds schedules array corresponds to the affiliate/employee address
    mapping(address => Schedule[]) public schedules;
    // Holds template names array corresponds to the affiliate/employee address
    mapping(address => bytes32[]) internal userToTemplates;
    // Mapping use to store the indexes for different template names for a user.
    // affiliate/employee address => template name => index
    mapping(address => mapping(bytes32 => uint256)) internal userToTemplateIndex;
    // Holds affiliate/employee addresses coressponds to the template name
    mapping(bytes32 => address[]) internal templateToUsers;
    // Mapping use to store the indexes for different users for a template.
    // template name => affiliate/employee address => index
    mapping(bytes32 => mapping(address => uint256)) internal templateToUserIndex;
    // Store the template details corresponds to the template name
    mapping(bytes32 => Template) templates;

    // List of all template names
    bytes32[] public templateNames;
}

pragma solidity 0.5.8;

import "../interfaces/IModule.sol";
import "../Pausable.sol";
import "../interfaces/IModuleFactory.sol";
import "../interfaces/IDataStore.sol";
import "../interfaces/ISecurityToken.sol";
import "../interfaces/ICheckPermission.sol";
import "../storage/modules/ModuleStorage.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

/**
 * @title Interface that any module contract should implement
 * @notice Contract is abstract
 */
contract Module is IModule, ModuleStorage, Pausable {
    /**
     * @notice Constructor
     * @param _securityToken Address of the security token
     */
    constructor (address _securityToken, address _polyAddress) public
    ModuleStorage(_securityToken, _polyAddress)
    {
    }

    //Allows owner, factory or permissioned delegate
    modifier withPerm(bytes32 _perm) {
        require(_checkPerm(_perm, msg.sender), "Invalid permission");
        _;
    }

    function _checkPerm(bytes32 _perm, address _caller) internal view returns (bool) {
        bool isOwner = _caller == Ownable(address(securityToken)).owner();
        bool isFactory = _caller == factory;
        return isOwner || isFactory || ICheckPermission(address(securityToken)).checkPermission(_caller, address(this), _perm);
    }

    function _onlySecurityTokenOwner() internal view {
        require(msg.sender == Ownable(address(securityToken)).owner(), "Sender is not owner");
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "Sender is not factory");
        _;
    }

    /**
     * @notice Pause (overridden function)
     */
    function pause() public {
        _onlySecurityTokenOwner();
        super._pause();
    }

    /**
     * @notice Unpause (overridden function)
     */
    function unpause() public {
        _onlySecurityTokenOwner();
        super._unpause();
    }

    /**
     * @notice used to return the data store address of securityToken
     */
    function getDataStore() public view returns(IDataStore) {
        return IDataStore(securityToken.dataStore());
    }

    /**
    * @notice Reclaims ERC20Basic compatible tokens
    * @dev We duplicate here due to the overriden owner & onlyOwner
    * @param _tokenContract The address of the token contract
    */
    function reclaimERC20(address _tokenContract) external {
        _onlySecurityTokenOwner();
        require(_tokenContract != address(0), "Invalid address");
        IERC20 token = IERC20(_tokenContract);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(msg.sender, balance), "Transfer failed");
    }

   /**
    * @notice Reclaims ETH
    * @dev We duplicate here due to the overriden owner & onlyOwner
    */
    function reclaimETH() external {
        _onlySecurityTokenOwner();
        msg.sender.transfer(address(this).balance);
    }
}

pragma solidity 0.5.8;

/**
 * @title Interface for all security tokens
 */
interface ISecurityToken {
    // Standard ERC20 interface
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns(uint8);
    function totalSupply() external view returns(uint256);
    function balanceOf(address owner) external view returns(uint256);
    function allowance(address owner, address spender) external view returns(uint256);
    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);
    function approve(address spender, uint256 value) external returns(bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @notice Transfers of securities may fail for a number of reasons. So this function will used to understand the
     * cause of failure by getting the byte value. Which will be the ESC that follows the EIP 1066. ESC can be mapped
     * with a reson string to understand the failure cause, table of Ethereum status code will always reside off-chain
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @param _data The `bytes _data` allows arbitrary data to be submitted alongside the transfer.
     * @return byte Ethereum status code (ESC)
     * @return bytes32 Application specific reason code
     */
    function canTransfer(address _to, uint256 _value, bytes calldata _data) external view returns (byte statusCode, bytes32 reasonCode);

    // Emit at the time when module get added
    event ModuleAdded(
        uint8[] _types,
        bytes32 indexed _name,
        address indexed _moduleFactory,
        address _module,
        uint256 _moduleCost,
        uint256 _budget,
        bytes32 _label,
        bool _archived
    );

    // Emit when the token details get updated
    event UpdateTokenDetails(string _oldDetails, string _newDetails);
    // Emit when the token name get updated
    event UpdateTokenName(string _oldName, string _newName);
    // Emit when the granularity get changed
    event GranularityChanged(uint256 _oldGranularity, uint256 _newGranularity);
    // Emit when is permanently frozen by the issuer
    event FreezeIssuance();
    // Emit when transfers are frozen or unfrozen
    event FreezeTransfers(bool _status);
    // Emit when new checkpoint created
    event CheckpointCreated(uint256 indexed _checkpointId, uint256 _investorLength);
    // Events to log controller actions
    event SetController(address indexed _oldController, address indexed _newController);
    //Event emit when the global treasury wallet address get changed
    event TreasuryWalletChanged(address _oldTreasuryWallet, address _newTreasuryWallet);
    event DisableController();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TokenUpgraded(uint8 _major, uint8 _minor, uint8 _patch);

    // Emit when Module get archived from the securityToken
    event ModuleArchived(uint8[] _types, address _module); //Event emitted by the tokenLib.
    // Emit when Module get unarchived from the securityToken
    event ModuleUnarchived(uint8[] _types, address _module); //Event emitted by the tokenLib.
    // Emit when Module get removed from the securityToken
    event ModuleRemoved(uint8[] _types, address _module); //Event emitted by the tokenLib.
    // Emit when the budget allocated to a module is changed
    event ModuleBudgetChanged(uint8[] _moduleTypes, address _module, uint256 _oldBudget, uint256 _budget); //Event emitted by the tokenLib.

    // Transfer Events
    event TransferByPartition(
        bytes32 indexed _fromPartition,
        address _operator,
        address indexed _from,
        address indexed _to,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    // Operator Events
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);
    event AuthorizedOperatorByPartition(bytes32 indexed partition, address indexed operator, address indexed tokenHolder);
    event RevokedOperatorByPartition(bytes32 indexed partition, address indexed operator, address indexed tokenHolder);

    // Issuance / Redemption Events
    event IssuedByPartition(bytes32 indexed partition, address indexed to, uint256 value, bytes data);
    event RedeemedByPartition(bytes32 indexed partition, address indexed operator, address indexed from, uint256 value, bytes data, bytes operatorData);

    // Document Events
    event DocumentRemoved(bytes32 indexed _name, string _uri, bytes32 _documentHash);
    event DocumentUpdated(bytes32 indexed _name, string _uri, bytes32 _documentHash);

    // Controller Events
    event ControllerTransfer(
        address _controller,
        address indexed _from,
        address indexed _to,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    event ControllerRedemption(
        address _controller,
        address indexed _tokenHolder,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    // Issuance / Redemption Events
    event Issued(address indexed _operator, address indexed _to, uint256 _value, bytes _data);
    event Redeemed(address indexed _operator, address indexed _from, uint256 _value, bytes _data);

    /**
     * @notice Initialization function
     * @dev Expected to be called atomically with the proxy being created, by the owner of the token
     * @dev Can only be called once
     */
    function initialize(address _getterDelegate) external;

    /**
     * @notice The standard provides an on-chain function to determine whether a transfer will succeed,
     * and return details indicating the reason if the transfer is not valid.
     * @param _from The address from whom the tokens get transferred.
     * @param _to The address to which to transfer tokens to.
     * @param _partition The partition from which to transfer tokens
     * @param _value The amount of tokens to transfer from `_partition`
     * @param _data Additional data attached to the transfer of tokens
     * @return ESC (Ethereum Status Code) following the EIP-1066 standard
     * @return Application specific reason codes with additional details
     * @return The partition to which the transferred tokens were allocated for the _to address
     */
    function canTransferByPartition(
        address _from,
        address _to,
        bytes32 _partition,
        uint256 _value,
        bytes calldata _data
    )
        external
        view
        returns (byte statusCode, bytes32 reasonCode, bytes32 partition);

    /**
     * @notice Transfers of securities may fail for a number of reasons. So this function will used to understand the
     * cause of failure by getting the byte value. Which will be the ESC that follows the EIP 1066. ESC can be mapped
     * with a reson string to understand the failure cause, table of Ethereum status code will always reside off-chain
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @param _data The `bytes _data` allows arbitrary data to be submitted alongside the transfer.
     * @return byte Ethereum status code (ESC)
     * @return bytes32 Application specific reason code
     */
    function canTransferFrom(address _from, address _to, uint256 _value, bytes calldata _data) external view returns (byte statusCode, bytes32 reasonCode);

    /**
     * @notice Used to attach a new document to the contract, or update the URI or hash of an existing attached document
     * @dev Can only be executed by the owner of the contract.
     * @param _name Name of the document. It should be unique always
     * @param _uri Off-chain uri of the document from where it is accessible to investors/advisors to read.
     * @param _documentHash hash (of the contents) of the document.
     */
    function setDocument(bytes32 _name, string calldata _uri, bytes32 _documentHash) external;

    /**
     * @notice Used to remove an existing document from the contract by giving the name of the document.
     * @dev Can only be executed by the owner of the contract.
     * @param _name Name of the document. It should be unique always
     */
    function removeDocument(bytes32 _name) external;

    /**
     * @notice Used to return the details of a document with a known name (`bytes32`).
     * @param _name Name of the document
     * @return string The URI associated with the document.
     * @return bytes32 The hash (of the contents) of the document.
     * @return uint256 the timestamp at which the document was last modified.
     */
    function getDocument(bytes32 _name) external view returns (string memory documentUri, bytes32 documentHash, uint256 documentTime);

    /**
     * @notice Used to retrieve a full list of documents attached to the smart contract.
     * @return bytes32 List of all documents names present in the contract.
     */
    function getAllDocuments() external view returns (bytes32[] memory documentNames);

    /**
     * @notice In order to provide transparency over whether `controllerTransfer` / `controllerRedeem` are useable
     * or not `isControllable` function will be used.
     * @dev If `isControllable` returns `false` then it always return `false` and
     * `controllerTransfer` / `controllerRedeem` will always revert.
     * @return bool `true` when controller address is non-zero otherwise return `false`.
     */
    function isControllable() external view returns (bool controlled);

    /**
     * @notice Checks if an address is a module of certain type
     * @param _module Address to check
     * @param _type type to check against
     */
    function isModule(address _module, uint8 _type) external view returns(bool isValid);

    /**
     * @notice This function must be called to increase the total supply (Corresponds to mint function of ERC20).
     * @dev It only be called by the token issuer or the operator defined by the issuer. ERC1594 doesn't have
     * have the any logic related to operator but its superset ERC1400 have the operator logic and this function
     * is allowed to call by the operator.
     * @param _tokenHolder The account that will receive the created tokens (account should be whitelisted or KYCed).
     * @param _value The amount of tokens need to be issued
     * @param _data The `bytes _data` allows arbitrary data to be submitted alongside the transfer.
     */
    function issue(address _tokenHolder, uint256 _value, bytes calldata _data) external;

    /**
     * @notice issue new tokens and assigns them to the target _tokenHolder.
     * @dev Can only be called by the issuer or STO attached to the token.
     * @param _tokenHolders A list of addresses to whom the minted tokens will be dilivered
     * @param _values A list of number of tokens get minted and transfer to corresponding address of the investor from _tokenHolders[] list
     * @return success
     */
    function issueMulti(address[] calldata _tokenHolders, uint256[] calldata _values) external;

    /**
     * @notice Increases totalSupply and the corresponding amount of the specified owners partition
     * @param _partition The partition to allocate the increase in balance
     * @param _tokenHolder The token holder whose balance should be increased
     * @param _value The amount by which to increase the balance
     * @param _data Additional data attached to the minting of tokens
     */
    function issueByPartition(bytes32 _partition, address _tokenHolder, uint256 _value, bytes calldata _data) external;

    /**
     * @notice Decreases totalSupply and the corresponding amount of the specified partition of msg.sender
     * @param _partition The partition to allocate the decrease in balance
     * @param _value The amount by which to decrease the balance
     * @param _data Additional data attached to the burning of tokens
     */
    function redeemByPartition(bytes32 _partition, uint256 _value, bytes calldata _data) external;

    /**
     * @notice This function redeem an amount of the token of a msg.sender. For doing so msg.sender may incentivize
     * using different ways that could be implemented with in the `redeem` function definition. But those implementations
     * are out of the scope of the ERC1594.
     * @param _value The amount of tokens need to be redeemed
     * @param _data The `bytes _data` it can be used in the token contract to authenticate the redemption.
     */
    function redeem(uint256 _value, bytes calldata _data) external;

    /**
     * @notice This function redeem an amount of the token of a msg.sender. For doing so msg.sender may incentivize
     * using different ways that could be implemented with in the `redeem` function definition. But those implementations
     * are out of the scope of the ERC1594.
     * @dev It is analogy to `transferFrom`
     * @param _tokenHolder The account whose tokens gets redeemed.
     * @param _value The amount of tokens need to be redeemed
     * @param _data The `bytes _data` it can be used in the token contract to authenticate the redemption.
     */
    function redeemFrom(address _tokenHolder, uint256 _value, bytes calldata _data) external;

    /**
     * @notice Decreases totalSupply and the corresponding amount of the specified partition of tokenHolder
     * @dev This function can only be called by the authorised operator.
     * @param _partition The partition to allocate the decrease in balance.
     * @param _tokenHolder The token holder whose balance should be decreased
     * @param _value The amount by which to decrease the balance
     * @param _data Additional data attached to the burning of tokens
     * @param _operatorData Additional data attached to the transfer of tokens by the operator
     */
    function operatorRedeemByPartition(
        bytes32 _partition,
        address _tokenHolder,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    ) external;

    /**
     * @notice Validate permissions with PermissionManager if it exists, If no Permission return false
     * @dev Note that IModule withPerm will allow ST owner all permissions anyway
     * @dev this allows individual modules to override this logic if needed (to not allow ST owner all permissions)
     * @param _delegate address of delegate
     * @param _module address of PermissionManager module
     * @param _perm the permissions
     * @return success
     */
    function checkPermission(address _delegate, address _module, bytes32 _perm) external view returns(bool hasPermission);

    /**
     * @notice Returns module list for a module type
     * @param _module Address of the module
     * @return bytes32 Name
     * @return address Module address
     * @return address Module factory address
     * @return bool Module archived
     * @return uint8 Array of module types
     * @return bytes32 Module label
     */
    function getModule(address _module) external view returns (bytes32 moduleName, address moduleAddress, address factoryAddress, bool isArchived, uint8[] memory moduleTypes, bytes32 moduleLabel);

    /**
     * @notice Returns module list for a module name
     * @param _name Name of the module
     * @return address[] List of modules with this name
     */
    function getModulesByName(bytes32 _name) external view returns(address[] memory modules);

    /**
     * @notice Returns module list for a module type
     * @param _type Type of the module
     * @return address[] List of modules with this type
     */
    function getModulesByType(uint8 _type) external view returns(address[] memory modules);

    /**
     * @notice use to return the global treasury wallet
     */
    function getTreasuryWallet() external view returns(address treasuryWallet);

    /**
     * @notice Queries totalSupply at a specified checkpoint
     * @param _checkpointId Checkpoint ID to query as of
     */
    function totalSupplyAt(uint256 _checkpointId) external view returns(uint256 supply);

    /**
     * @notice Queries balance at a specified checkpoint
     * @param _investor Investor to query balance for
     * @param _checkpointId Checkpoint ID to query as of
     */
    function balanceOfAt(address _investor, uint256 _checkpointId) external view returns(uint256 balance);

    /**
     * @notice Creates a checkpoint that can be used to query historical balances / totalSuppy
     */
    function createCheckpoint() external returns(uint256 checkpointId);

    /**
     * @notice Gets list of times that checkpoints were created
     * @return List of checkpoint times
     */
    function getCheckpointTimes() external view returns(uint256[] memory checkpointTimes);

    /**
     * @notice returns an array of investors
     * NB - this length may differ from investorCount as it contains all investors that ever held tokens
     * @return list of addresses
     */
    function getInvestors() external view returns(address[] memory investors);

    /**
     * @notice returns an array of investors at a given checkpoint
     * NB - this length may differ from investorCount as it contains all investors that ever held tokens
     * @param _checkpointId Checkpoint id at which investor list is to be populated
     * @return list of investors
     */
    function getInvestorsAt(uint256 _checkpointId) external view returns(address[] memory investors);

    /**
     * @notice returns an array of investors with non zero balance at a given checkpoint
     * @param _checkpointId Checkpoint id at which investor list is to be populated
     * @param _start Position of investor to start iteration from
     * @param _end Position of investor to stop iteration at
     * @return list of investors
     */
    function getInvestorsSubsetAt(uint256 _checkpointId, uint256 _start, uint256 _end) external view returns(address[] memory investors);

    /**
     * @notice generates subset of investors
     * NB - can be used in batches if investor list is large
     * @param _start Position of investor to start iteration from
     * @param _end Position of investor to stop iteration at
     * @return list of investors
     */
    function iterateInvestors(uint256 _start, uint256 _end) external view returns(address[] memory investors);

    /**
     * @notice Gets current checkpoint ID
     * @return Id
     */
    function currentCheckpointId() external view returns(uint256 checkpointId);

    /**
     * @notice Determines whether `_operator` is an operator for all partitions of `_tokenHolder`
     * @param _operator The operator to check
     * @param _tokenHolder The token holder to check
     * @return Whether the `_operator` is an operator for all partitions of `_tokenHolder`
     */
    function isOperator(address _operator, address _tokenHolder) external view returns (bool isValid);

    /**
     * @notice Determines whether `_operator` is an operator for a specified partition of `_tokenHolder`
     * @param _partition The partition to check
     * @param _operator The operator to check
     * @param _tokenHolder The token holder to check
     * @return Whether the `_operator` is an operator for a specified partition of `_tokenHolder`
     */
    function isOperatorForPartition(bytes32 _partition, address _operator, address _tokenHolder) external view returns (bool isValid);

    /**
     * @notice Return all partitions
     * @param _tokenHolder Whom balance need to queried
     * @return List of partitions
     */
    function partitionsOf(address _tokenHolder) external view returns (bytes32[] memory partitions);

    /**
     * @notice Gets data store address
     * @return data store address
     */
    function dataStore() external view returns (address dataStoreAddress);

    /**
    * @notice Allows owner to change data store
    * @param _dataStore Address of the token data store
    */
    function changeDataStore(address _dataStore) external;


    /**
     * @notice Allows to change the treasury wallet address
     * @param _wallet Ethereum address of the treasury wallet
     */
    function changeTreasuryWallet(address _wallet) external;

    /**
     * @notice Allows the owner to withdraw unspent POLY stored by them on the ST or any ERC20 token.
     * @dev Owner can transfer POLY to the ST which will be used to pay for modules that require a POLY fee.
     * @param _tokenContract Address of the ERC20Basic compliance token
     * @param _value Amount of POLY to withdraw
     */
    function withdrawERC20(address _tokenContract, uint256 _value) external;

    /**
    * @notice Allows owner to increase/decrease POLY approval of one of the modules
    * @param _module Module address
    * @param _change Change in allowance
    * @param _increase True if budget has to be increased, false if decrease
    */
    function changeModuleBudget(address _module, uint256 _change, bool _increase) external;

    /**
     * @notice Changes the tokenDetails
     * @param _newTokenDetails New token details
     */
    function updateTokenDetails(string calldata _newTokenDetails) external;

    /**
    * @notice Allows owner to change token name
    * @param _name new name of the token
    */
    function changeName(string calldata _name) external;

    /**
    * @notice Allows the owner to change token granularity
    * @param _granularity Granularity level of the token
    */
    function changeGranularity(uint256 _granularity) external;

    /**
     * @notice Freezes all the transfers
     */
    function freezeTransfers() external;

    /**
     * @notice Un-freezes all the transfers
     */
    function unfreezeTransfers() external;

    /**
     * @notice Permanently freeze issuance of this security token.
     * @dev It MUST NOT be possible to increase `totalSuppy` after this function is called.
     */
    function freezeIssuance(bytes calldata _signature) external;

    /**
      * @notice Attachs a module to the SecurityToken
      * @dev  E.G.: On deployment (through the STR) ST gets a TransferManager module attached to it
      * @dev to control restrictions on transfers.
      * @param _moduleFactory is the address of the module factory to be added
      * @param _data is data packed into bytes used to further configure the module (See STO usage)
      * @param _maxCost max amount of POLY willing to pay to the module.
      * @param _budget max amount of ongoing POLY willing to assign to the module.
      * @param _label custom module label.
      * @param _archived whether to add the module as an archived module
      */
    function addModuleWithLabel(
        address _moduleFactory,
        bytes calldata _data,
        uint256 _maxCost,
        uint256 _budget,
        bytes32 _label,
        bool _archived
    ) external;

    /**
     * @notice Function used to attach a module to the security token
     * @dev  E.G.: On deployment (through the STR) ST gets a TransferManager module attached to it
     * @dev to control restrictions on transfers.
     * @dev You are allowed to add a new moduleType if:
     * @dev - there is no existing module of that type yet added
     * @dev - the last member of the module list is replacable
     * @param _moduleFactory is the address of the module factory to be added
     * @param _data is data packed into bytes used to further configure the module (See STO usage)
     * @param _maxCost max amount of POLY willing to pay to module. (WIP)
     * @param _budget max amount of ongoing POLY willing to assign to the module.
     * @param _archived whether to add the module as an archived module
     */
    function addModule(address _moduleFactory, bytes calldata _data, uint256 _maxCost, uint256 _budget, bool _archived) external;

    /**
    * @notice Archives a module attached to the SecurityToken
    * @param _module address of module to archive
    */
    function archiveModule(address _module) external;

    /**
    * @notice Unarchives a module attached to the SecurityToken
    * @param _module address of module to unarchive
    */
    function unarchiveModule(address _module) external;

    /**
    * @notice Removes a module attached to the SecurityToken
    * @param _module address of module to archive
    */
    function removeModule(address _module) external;

    /**
     * @notice Used by the issuer to set the controller addresses
     * @param _controller address of the controller
     */
    function setController(address _controller) external;

    /**
     * @notice This function allows an authorised address to transfer tokens between any two token holders.
     * The transfer must still respect the balances of the token holders (so the transfer must be for at most
     * `balanceOf(_from)` tokens) and potentially also need to respect other transfer restrictions.
     * @dev This function can only be executed by the `controller` address.
     * @param _from Address The address which you want to send tokens from
     * @param _to Address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @param _data data to validate the transfer. (It is not used in this reference implementation
     * because use of `_data` parameter is implementation specific).
     * @param _operatorData data attached to the transfer by controller to emit in event. (It is more like a reason string
     * for calling this function (aka force transfer) which provides the transparency on-chain).
     */
    function controllerTransfer(address _from, address _to, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external;

    /**
     * @notice This function allows an authorised address to redeem tokens for any token holder.
     * The redemption must still respect the balances of the token holder (so the redemption must be for at most
     * `balanceOf(_tokenHolder)` tokens) and potentially also need to respect other transfer restrictions.
     * @dev This function can only be executed by the `controller` address.
     * @param _tokenHolder The account whose tokens will be redeemed.
     * @param _value uint256 the amount of tokens need to be redeemed.
     * @param _data data to validate the transfer. (It is not used in this reference implementation
     * because use of `_data` parameter is implementation specific).
     * @param _operatorData data attached to the transfer by controller to emit in event. (It is more like a reason string
     * for calling this function (aka force transfer) which provides the transparency on-chain).
     */
    function controllerRedeem(address _tokenHolder, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external;

    /**
     * @notice Used by the issuer to permanently disable controller functionality
     * @dev enabled via feature switch "disableControllerAllowed"
     */
    function disableController(bytes calldata _signature) external;

    /**
     * @notice Used to get the version of the securityToken
     */
    function getVersion() external view returns(uint8[] memory version);

    /**
     * @notice Gets the investor count
     */
    function getInvestorCount() external view returns(uint256 investorCount);

    /**
     * @notice Gets the holder count (investors with non zero balance)
     */
    function holderCount() external view returns(uint256 count);

    /**
      * @notice Overloaded version of the transfer function
      * @param _to receiver of transfer
      * @param _value value of transfer
      * @param _data data to indicate validation
      * @return bool success
      */
    function transferWithData(address _to, uint256 _value, bytes calldata _data) external;

    /**
      * @notice Overloaded version of the transferFrom function
      * @param _from sender of transfer
      * @param _to receiver of transfer
      * @param _value value of transfer
      * @param _data data to indicate validation
      * @return bool success
      */
    function transferFromWithData(address _from, address _to, uint256 _value, bytes calldata _data) external;

    /**
     * @notice Transfers the ownership of tokens from a specified partition from one address to another address
     * @param _partition The partition from which to transfer tokens
     * @param _to The address to which to transfer tokens to
     * @param _value The amount of tokens to transfer from `_partition`
     * @param _data Additional data attached to the transfer of tokens
     * @return The partition to which the transferred tokens were allocated for the _to address
     */
    function transferByPartition(bytes32 _partition, address _to, uint256 _value, bytes calldata _data) external returns (bytes32 partition);

    /**
     * @notice Get the balance according to the provided partitions
     * @param _partition Partition which differentiate the tokens.
     * @param _tokenHolder Whom balance need to queried
     * @return Amount of tokens as per the given partitions
     */
    function balanceOfByPartition(bytes32 _partition, address _tokenHolder) external view returns(uint256 balance);

    /**
      * @notice Provides the granularity of the token
      * @return uint256
      */
    function granularity() external view returns(uint256 granularityAmount);

    /**
      * @notice Provides the address of the polymathRegistry
      * @return address
      */
    function polymathRegistry() external view returns(address registryAddress);

    /**
    * @notice Upgrades a module attached to the SecurityToken
    * @param _module address of module to archive
    */
    function upgradeModule(address _module) external;

    /**
    * @notice Upgrades security token
    */
    function upgradeToken() external;

    /**
     * @notice A security token issuer can specify that issuance has finished for the token
     * (i.e. no new tokens can be minted or issued).
     * @dev If a token returns FALSE for `isIssuable()` then it MUST always return FALSE in the future.
     * If a token returns FALSE for `isIssuable()` then it MUST never allow additional tokens to be issued.
     * @return bool `true` signifies the minting is allowed. While `false` denotes the end of minting
     */
    function isIssuable() external view returns (bool issuable);

    /**
     * @notice Authorises an operator for all partitions of `msg.sender`.
     * NB - Allowing investors to authorize an investor to be an operator of all partitions
     * but it doesn't mean we operator is allowed to transfer the LOCKED partition values.
     * Logic for this restriction is written in `operatorTransferByPartition()` function.
     * @param _operator An address which is being authorised.
     */
    function authorizeOperator(address _operator) external;

    /**
     * @notice Revokes authorisation of an operator previously given for all partitions of `msg.sender`.
     * NB - Allowing investors to authorize an investor to be an operator of all partitions
     * but it doesn't mean we operator is allowed to transfer the LOCKED partition values.
     * Logic for this restriction is written in `operatorTransferByPartition()` function.
     * @param _operator An address which is being de-authorised
     */
    function revokeOperator(address _operator) external;

    /**
     * @notice Authorises an operator for a given partition of `msg.sender`
     * @param _partition The partition to which the operator is authorised
     * @param _operator An address which is being authorised
     */
    function authorizeOperatorByPartition(bytes32 _partition, address _operator) external;

    /**
     * @notice Revokes authorisation of an operator previously given for a specified partition of `msg.sender`
     * @param _partition The partition to which the operator is de-authorised
     * @param _operator An address which is being de-authorised
     */
    function revokeOperatorByPartition(bytes32 _partition, address _operator) external;

    /**
     * @notice Transfers the ownership of tokens from a specified partition from one address to another address
     * @param _partition The partition from which to transfer tokens.
     * @param _from The address from which to transfer tokens from
     * @param _to The address to which to transfer tokens to
     * @param _value The amount of tokens to transfer from `_partition`
     * @param _data Additional data attached to the transfer of tokens
     * @param _operatorData Additional data attached to the transfer of tokens by the operator
     * @return The partition to which the transferred tokens were allocated for the _to address
     */
    function operatorTransferByPartition(
        bytes32 _partition,
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    )
        external
        returns (bytes32 partition);

    /*
    * @notice Returns if transfers are currently frozen or not
    */
    function transfersFrozen() external view returns (bool isFrozen);

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) external;

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() external view returns (bool);

    /**
     * @return the address of the owner.
     */
    function owner() external view returns (address ownerAddress);

    function controller() external view returns(address controllerAddress);

    function moduleRegistry() external view returns(address moduleRegistryAddress);

    function securityTokenRegistry() external view returns(address securityTokenRegistryAddress);

    function polyToken() external view returns(address polyTokenAddress);

    function tokenFactory() external view returns(address tokenFactoryAddress);

    function getterDelegate() external view returns(address delegate);

    function controllerDisabled() external view returns(bool isDisabled);

    function initialized() external view returns(bool isInitialized);

    function tokenDetails() external view returns(string memory details);

    function updateFromRegistry() external;

}

pragma solidity 0.5.8;

/**
 * @title Interface that every module factory contract should implement
 */
interface IModuleFactory {
    event ChangeSetupCost(uint256 _oldSetupCost, uint256 _newSetupCost);
    event ChangeCostType(bool _isOldCostInPoly, bool _isNewCostInPoly);
    event GenerateModuleFromFactory(
        address _module,
        bytes32 indexed _moduleName,
        address indexed _moduleFactory,
        address _creator,
        uint256 _setupCost,
        uint256 _setupCostInPoly
    );
    event ChangeSTVersionBound(string _boundType, uint8 _major, uint8 _minor, uint8 _patch);

    //Should create an instance of the Module, or throw
    function deploy(bytes calldata _data) external returns(address moduleAddress);

    /**
     * @notice Get the tags related to the module factory
     */
    function version() external view returns(string memory moduleVersion);

    /**
     * @notice Get the tags related to the module factory
     */
    function name() external view returns(bytes32 moduleName);

    /**
     * @notice Returns the title associated with the module
     */
    function title() external view returns(string memory moduleTitle);

    /**
     * @notice Returns the description associated with the module
     */
    function description() external view returns(string memory moduleDescription);

    /**
     * @notice Get the setup cost of the module in USD
     */
    function setupCost() external returns(uint256 usdSetupCost);

    /**
     * @notice Type of the Module factory
     */
    function getTypes() external view returns(uint8[] memory moduleTypes);

    /**
     * @notice Get the tags related to the module factory
     */
    function getTags() external view returns(bytes32[] memory moduleTags);

    /**
     * @notice Used to change the setup fee
     * @param _newSetupCost New setup fee
     */
    function changeSetupCost(uint256 _newSetupCost) external;

    /**
     * @notice Used to change the currency and amount setup cost
     * @param _setupCost new setup cost
     * @param _isCostInPoly new setup cost currency. USD or POLY
     */
    function changeCostAndType(uint256 _setupCost, bool _isCostInPoly) external;

    /**
     * @notice Function use to change the lower and upper bound of the compatible version st
     * @param _boundType Type of bound
     * @param _newVersion New version array
     */
    function changeSTVersionBounds(string calldata _boundType, uint8[] calldata _newVersion) external;

    /**
     * @notice Get the setup cost of the module
     */
    function setupCostInPoly() external returns (uint256 polySetupCost);

    /**
     * @notice Used to get the lower bound
     * @return Lower bound
     */
    function getLowerSTVersionBounds() external view returns(uint8[] memory lowerBounds);

    /**
     * @notice Used to get the upper bound
     * @return Upper bound
     */
    function getUpperSTVersionBounds() external view returns(uint8[] memory upperBounds);

    /**
     * @notice Updates the tags of the ModuleFactory
     * @param _tagsData New list of tags
     */
    function changeTags(bytes32[] calldata _tagsData) external;

    /**
     * @notice Updates the name of the ModuleFactory
     * @param _name New name that will replace the old one.
     */
    function changeName(bytes32 _name) external;

    /**
     * @notice Updates the description of the ModuleFactory
     * @param _description New description that will replace the old one.
     */
    function changeDescription(string calldata _description) external;

    /**
     * @notice Updates the title of the ModuleFactory
     * @param _title New Title that will replace the old one.
     */
    function changeTitle(string calldata _title) external;

}

pragma solidity 0.5.8;

/**
 * @title Interface that every module contract should implement
 */
interface IModule {
    /**
     * @notice This function returns the signature of configure function
     */
    function getInitFunction() external pure returns(bytes4 initFunction);

    /**
     * @notice Return the permission flags that are associated with a module
     */
    function getPermissions() external view returns(bytes32[] memory permissions);

}

pragma solidity 0.5.8;

interface IDataStore {
    /**
     * @dev Changes security token atatched to this data store
     * @param _securityToken address of the security token
     */
    function setSecurityToken(address _securityToken) external;

    /**
     * @dev Stores a uint256 data against a key
     * @param _key Unique key to identify the data
     * @param _data Data to be stored against the key
     */
    function setUint256(bytes32 _key, uint256 _data) external;

    function setBytes32(bytes32 _key, bytes32 _data) external;

    function setAddress(bytes32 _key, address _data) external;

    function setString(bytes32 _key, string calldata _data) external;

    function setBytes(bytes32 _key, bytes calldata _data) external;

    function setBool(bytes32 _key, bool _data) external;

    /**
     * @dev Stores a uint256 array against a key
     * @param _key Unique key to identify the array
     * @param _data Array to be stored against the key
     */
    function setUint256Array(bytes32 _key, uint256[] calldata _data) external;

    function setBytes32Array(bytes32 _key, bytes32[] calldata _data) external ;

    function setAddressArray(bytes32 _key, address[] calldata _data) external;

    function setBoolArray(bytes32 _key, bool[] calldata _data) external;

    /**
     * @dev Inserts a uint256 element to the array identified by the key
     * @param _key Unique key to identify the array
     * @param _data Element to push into the array
     */
    function insertUint256(bytes32 _key, uint256 _data) external;

    function insertBytes32(bytes32 _key, bytes32 _data) external;

    function insertAddress(bytes32 _key, address _data) external;

    function insertBool(bytes32 _key, bool _data) external;

    /**
     * @dev Deletes an element from the array identified by the key.
     * When an element is deleted from an Array, last element of that array is moved to the index of deleted element.
     * @param _key Unique key to identify the array
     * @param _index Index of the element to delete
     */
    function deleteUint256(bytes32 _key, uint256 _index) external;

    function deleteBytes32(bytes32 _key, uint256 _index) external;

    function deleteAddress(bytes32 _key, uint256 _index) external;

    function deleteBool(bytes32 _key, uint256 _index) external;

    /**
     * @dev Stores multiple uint256 data against respective keys
     * @param _keys Array of keys to identify the data
     * @param _data Array of data to be stored against the respective keys
     */
    function setUint256Multi(bytes32[] calldata _keys, uint256[] calldata _data) external;

    function setBytes32Multi(bytes32[] calldata _keys, bytes32[] calldata _data) external;

    function setAddressMulti(bytes32[] calldata _keys, address[] calldata _data) external;

    function setBoolMulti(bytes32[] calldata _keys, bool[] calldata _data) external;

    /**
     * @dev Inserts multiple uint256 elements to the array identified by the respective keys
     * @param _keys Array of keys to identify the data
     * @param _data Array of data to be inserted in arrays of the respective keys
     */
    function insertUint256Multi(bytes32[] calldata _keys, uint256[] calldata _data) external;

    function insertBytes32Multi(bytes32[] calldata _keys, bytes32[] calldata _data) external;

    function insertAddressMulti(bytes32[] calldata _keys, address[] calldata _data) external;

    function insertBoolMulti(bytes32[] calldata _keys, bool[] calldata _data) external;

    function getUint256(bytes32 _key) external view returns(uint256);

    function getBytes32(bytes32 _key) external view returns(bytes32);

    function getAddress(bytes32 _key) external view returns(address);

    function getString(bytes32 _key) external view returns(string memory);

    function getBytes(bytes32 _key) external view returns(bytes memory);

    function getBool(bytes32 _key) external view returns(bool);

    function getUint256Array(bytes32 _key) external view returns(uint256[] memory);

    function getBytes32Array(bytes32 _key) external view returns(bytes32[] memory);

    function getAddressArray(bytes32 _key) external view returns(address[] memory);

    function getBoolArray(bytes32 _key) external view returns(bool[] memory);

    function getUint256ArrayLength(bytes32 _key) external view returns(uint256);

    function getBytes32ArrayLength(bytes32 _key) external view returns(uint256);

    function getAddressArrayLength(bytes32 _key) external view returns(uint256);

    function getBoolArrayLength(bytes32 _key) external view returns(uint256);

    function getUint256ArrayElement(bytes32 _key, uint256 _index) external view returns(uint256);

    function getBytes32ArrayElement(bytes32 _key, uint256 _index) external view returns(bytes32);

    function getAddressArrayElement(bytes32 _key, uint256 _index) external view returns(address);

    function getBoolArrayElement(bytes32 _key, uint256 _index) external view returns(bool);

    function getUint256ArrayElements(bytes32 _key, uint256 _startIndex, uint256 _endIndex) external view returns(uint256[] memory);

    function getBytes32ArrayElements(bytes32 _key, uint256 _startIndex, uint256 _endIndex) external view returns(bytes32[] memory);

    function getAddressArrayElements(bytes32 _key, uint256 _startIndex, uint256 _endIndex) external view returns(address[] memory);

    function getBoolArrayElements(bytes32 _key, uint256 _startIndex, uint256 _endIndex) external view returns(bool[] memory);
}

pragma solidity 0.5.8;

interface ICheckPermission {
    /**
     * @notice Validate permissions with PermissionManager if it exists, If no Permission return false
     * @dev Note that IModule withPerm will allow ST owner all permissions anyway
     * @dev this allows individual modules to override this logic if needed (to not allow ST owner all permissions)
     * @param _delegate address of delegate
     * @param _module address of PermissionManager module
     * @param _perm the permissions
     * @return success
     */
    function checkPermission(address _delegate, address _module, bytes32 _perm) external view returns(bool hasPerm);
}

pragma solidity 0.5.8;

/**
 * @title Utility contract to allow pausing and unpausing of certain functions
 */
contract Pausable {
    event Pause(address account);
    event Unpause(address account);

    bool public paused = false;

    /**
    * @notice Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    /**
    * @notice Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    /**
    * @notice Called by the owner to pause, triggers stopped state
    */
    function _pause() internal whenNotPaused {
        paused = true;
        /*solium-disable-next-line security/no-block-members*/
        emit Pause(msg.sender);
    }

    /**
    * @notice Called by the owner to unpause, returns to normal state
    */
    function _unpause() internal whenPaused {
        paused = false;
        /*solium-disable-next-line security/no-block-members*/
        emit Unpause(msg.sender);
    }

}

pragma solidity ^0.5.2;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.5.2;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.2;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}