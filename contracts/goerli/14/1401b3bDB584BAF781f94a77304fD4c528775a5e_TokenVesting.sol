// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './access/Ownable.sol';

/**
 * @title Token Vesting Contract
 */
contract TokenVesting is Ownable {
    /**
     * @dev Event is triggered when TGE timestamp is changed
     * @param _tgeTimestamp uint256 timestamp
     */
    event TgeTimestampChanged(uint256 _tgeTimestamp);

    /**
     * @dev Event is triggered when vesting schedule is changed
     * @param _name string vesting schedule name
     * @param _amount uint256 vesting schedule amount
     */
    event VestingScheduleCreated(string _name, uint256 _amount);

    /**
     * @dev Event is triggered when vesting schedule is revoked
     * @param _name string vesting schedule name
     */
    event VestingScheduleRevoked(string _name);

    /**
     * @dev Event is triggered when allocation added
     * @param _beneficiary address of beneficiary
     * @param _vestingScheduleName string vesting schedule name
     * @param _amount uint256 amount of tokens
     * @param _currentAllocation uint256 current allocation for vesting schedule
     */
    event AllocationAdded(
        address _beneficiary,
        string _vestingScheduleName,
        uint256 _amount,
        uint256 _currentAllocation
    );

    /**
     * @dev Event is triggered when allocation removed
     * @param _beneficiary address of beneficiary
     * @param _vestingScheduleName string vesting schedule name
     * @param _amount uint256 amount of tokens
     * @param _currentAllocation uint256 current allocation for vesting schedule
     */
    event AllocationRemoved(
        address _beneficiary,
        string _vestingScheduleName,
        uint256 _amount,
        uint256 _currentAllocation
    );

    /**
     * @dev Event is triggered when contract paused or unpaused
     * @param _paused bool is paused
     */
    event ContractPaused(bool _paused);

    /**
     * @dev Event is triggered when beneficiary deleted
     * @param _beneficiary address of beneficiary
     */
    event BeneficiaryDeleted(address _beneficiary);

    /**
     * @dev Event is triggered when tokens claimed
     * @param _beneficiary address of beneficiary
     * @param _vestingScheduleName string vesting schedule name
     * @param _amount uint256 amount of tokens
     * @param _releasedAmount uint256 released amount of beneficiary tokens for current vesting schedule
     */
    event TokensClaimed(address _beneficiary, string _vestingScheduleName, uint256 _amount, uint256 _releasedAmount);

    struct VestingSchedule {
        string name;
        uint256 terms;
        uint256 cliff;
        uint256 duration;
        uint256 totalAmount;
        uint256 allocatedAmount;
        uint256 releasedAmount;
        bool initialized;
        bool revoked;
    }

    struct Vesting {
        string name;
        uint256 amount;
        uint256 timestamp;
    }

    struct VestingExpectation {
        Vesting vesting;
        uint256 beneficiaryAmount;
    }

    struct BeneficiaryOverview {
        string name;
        uint256 terms;
        uint256 cliff;
        uint256 duration;
        uint256 allocatedAmount;
        uint256 withdrawnAmount;
    }

    struct Beneficiary {
        uint256 allocatedAmount;
        uint256 withdrawnAmount;
    }

    IERC20 private immutable token;
    string[] private vestingSchedulesNames;
    uint256 private vestingSchedulesTotalAmount;
    uint256 private validVestingSchedulesCount;
    uint256 public tgeTimestamp;
    address public treasuryAddress;
    bool public paused;
    mapping(string => VestingSchedule) private vestingSchedules;
    mapping(address => mapping(string => Beneficiary)) private beneficiaries;

    constructor(address _tokenContractAddress) {
        require(_tokenContractAddress != address(0x0), 'TokenVesting: token contract address cannot be a zero');
        token = IERC20(_tokenContractAddress);
        treasuryAddress = 0xD62Ba193D0c0C556D4D37DbbC5e431330471a557;
    }

    /**
     * @dev Revokes all schedules and sends tokens to a set address
     */
    function emergencyWithdrawal() external onlyOwner {
        require(token.balanceOf(address(this)) > 0, 'TokenVesting: nothing to withdraw');
        string[] memory activeVestingScheduleNames = getValidVestingScheduleNames();
        for (uint256 i = 0; i < activeVestingScheduleNames.length; i++) {
            _revokeVestingSchedule(activeVestingScheduleNames[i]);
        }
        token.transfer(treasuryAddress, token.balanceOf(address(this)));
    }

    /**
     * @dev Pauses contract
     */
    function pauseContract() external onlyOwner {
        require(!paused, 'TokenVesting: Contract is already paused!');
        paused = true;
        emit ContractPaused(paused);
    }

    /**
     * @dev Unpauses contract
     */
    function unpauseContract() external onlyOwner {
        require(paused, 'TokenVesting: Contract is active!');
        paused = false;
        emit ContractPaused(paused);
    }

    /**
     * @dev Gets ERC20 token address
     * @return address of token
     */
    function getToken() external view returns (address) {
        return address(token);
    }

    /**
     * @dev Sets TGE timestamp
     * @param _tgeTimestamp uint256 TGE timestamp
     */
    function setTgeTimestamp(uint256 _tgeTimestamp) external onlyOwner {
        require(!paused, 'TokenVesting: Contract is paused!');
        tgeTimestamp = _tgeTimestamp;
        emit TgeTimestampChanged(_tgeTimestamp);
    }

    /**
     * @dev Creates a new vesting schedule
     * @param _name string vesting schedule name
     * @param _terms vesting schedule terms in seconds
     * @param _cliff cliff in seconds after which tokens will begin to vest
     * @param _duration the number of terms during which the tokens will be vested
     * @param _amount total amount of tokens to be released at the end of the vesting
     */
    function createVestingSchedule(
        string calldata _name,
        uint256 _terms,
        uint256 _cliff,
        uint256 _duration,
        uint256 _amount
    ) external onlyOwner {
        require(!paused, 'TokenVesting: Contract is paused!');
        require(bytes(_name).length > 0, 'TokenVesting: cannot create vesting schedule with empty name');
        require(isNameUnique(_name), 'TokenVesting: cannot create vesting schedule with the same name');
        require(
            getUnusedAmount() >= _amount,
            'TokenVesting: cannot create vesting schedule because not sufficient tokens'
        );
        require(_duration > 0, 'TokenVesting: duration must be > 0');
        require(_amount > 0, 'TokenVesting: amount must be > 0');
        vestingSchedules[_name] = VestingSchedule({
            name: _name,
            terms: _terms,
            cliff: _cliff,
            duration: _duration,
            totalAmount: _amount,
            allocatedAmount: 0,
            releasedAmount: 0,
            initialized: true,
            revoked: false
        });
        vestingSchedulesTotalAmount += _amount;
        vestingSchedulesNames.push(_name);
        validVestingSchedulesCount++;
        emit VestingScheduleCreated(_name, _amount);
    }

    /**
     * @dev Revokes vesting schedule
     * @param _name string schedule name
     */
    function revokeVestingSchedule(string memory _name) external onlyOwner {
        require(!paused, 'TokenVesting: Contract is paused!');
        _revokeVestingSchedule(_name);
    }

    /**
     * @dev Gets the vesting schedule information
     * @param _name string vesting schedule name
     * @return VestingSchedule structure information
     */
    function getVestingSchedule(string calldata _name) external view returns (VestingSchedule memory) {
        return vestingSchedules[_name];
    }

    /**
     * @dev Gets all vesting schedules
     * @return VestingSchedule structure list of all vesting schedules
     */
    function getAllVestingSchedules() external view returns (VestingSchedule[] memory) {
        VestingSchedule[] memory allVestingSchedules = new VestingSchedule[](vestingSchedulesNames.length);
        for (uint32 i = 0; i < vestingSchedulesNames.length; i++) {
            allVestingSchedules[i] = vestingSchedules[vestingSchedulesNames[i]];
        }
        return allVestingSchedules;
    }

    /**
     * @dev Gets all active vesting schedules
     * @return VestingSchedule structure list of all active vesting schedules
     */
    function getValidVestingSchedules() external view returns (VestingSchedule[] memory) {
        VestingSchedule[] memory validVestingSchedules = new VestingSchedule[](validVestingSchedulesCount);
        uint32 j;
        for (uint32 i = 0; i < vestingSchedulesNames.length; i++) {
            if (isVestingScheduleValid(vestingSchedulesNames[i])) {
                validVestingSchedules[j] = vestingSchedules[vestingSchedulesNames[i]];
                j++;
            }
        }
        return validVestingSchedules;
    }

    /**
     * INDECISIVE do we need it?
     * @dev Gets vesting schedules count
     * @return uint256 number of vesting schedules
     */
    function getVestingSchedulesCount() external view returns (uint256) {
        return vestingSchedulesNames.length;
    }

    /**
     * INDECISIVE do we need it?
     * @dev Gets valid vesting schedules count
     * @return uint256 number of vesting schedules
     */
    function getValidVestingSchedulesCount() external view returns (uint256) {
        return validVestingSchedulesCount;
    }

    /**
     * @dev Adds vesting schedule allocation
     * @param _name string vesting schedule name
     * @param _amount uint256 amount of tokens
     */
    function addVestingScheduleAllocation(uint256 _amount, string calldata _name) external onlyOwner {
        require(!paused, 'TokenVesting: Contract is paused!');
        require(_amount != 0, 'TokenVesting: amount must be bigger than zero');
        vestingSchedules[_name].allocatedAmount += _amount;
    }

    /**
     * @dev Removes vesting schedule allocation
     * @param _name string vesting schedule name
     * @param _amount uint256 amount of tokens
     */
    function removeVestingScheduleAllocation(uint256 _amount, string calldata _name) external onlyOwner {
        require(!paused, 'TokenVesting: Contract is paused!');
        require(_amount != 0, 'TokenVesting: amount must be bigger than zero');
        vestingSchedules[_name].allocatedAmount -= _amount;
    }

    /**
     * @dev Adds beneficiary allocation
     * @param _beneficiary address of user
     * @param _vestingScheduleName string
     * @param _amount uint256 amount of tokens
     */
    function addBeneficiaryAllocation(
        address _beneficiary,
        string memory _vestingScheduleName,
        uint256 _amount
    ) external onlyOwner {
        require(!paused, 'TokenVesting: Contract is paused!');
        require(_beneficiary != address(0x0), 'TokenVesting: beneficiary cannot be a zero');
        require(
            bytes(_vestingScheduleName).length > 0,
            'TokenVesting: cannot add allocation for empty vesting schedule'
        );
        require(_amount > 0, 'TokenVesting: amount must be > 0');
        require(isVestingScheduleValid(_vestingScheduleName), 'TokenVesting: vesting schedule is not active');
        require(
            getScheduleUnallocatedAmount(_vestingScheduleName) >= _amount,
            'TokenVesting: cannot allocate greater than unallocated vesting schedule amount'
        );

        beneficiaries[_beneficiary][_vestingScheduleName].allocatedAmount += _amount;
        vestingSchedules[_vestingScheduleName].allocatedAmount += _amount;

        emit AllocationAdded(
            _beneficiary,
            _vestingScheduleName,
            _amount,
            beneficiaries[_beneficiary][_vestingScheduleName].allocatedAmount
        );
    }

    /**
     * @dev Removes beneficiary allocation
     * @param _beneficiary address of user
     * @param _vestingScheduleName string
     * @param _amount uint256 amount of tokens
     */
    function removeBeneficiaryAllocation(
        address _beneficiary,
        string calldata _vestingScheduleName,
        uint256 _amount
    ) external onlyOwner {
        require(!paused, 'TokenVesting: Contract is paused!');
        require(_beneficiary != address(0x0), 'TokenVesting: beneficiary cannot be a zero');
        require(_amount > 0, 'TokenVesting: amount must be > 0');
        require(
            bytes(_vestingScheduleName).length > 0,
            'TokenVesting: cannot remove allocation from empty vesting schedule'
        );
        require(isVestingScheduleValid(_vestingScheduleName), 'TokenVesting: vesting schedule is not active');
        require(
            getBeneficiaryUnreleasedAmount(_beneficiary, _vestingScheduleName) >= _amount,
            'TokenVesting: cannot remove greater allocation than unreleased amount'
        );

        beneficiaries[_beneficiary][_vestingScheduleName].allocatedAmount -= _amount;
        vestingSchedules[_vestingScheduleName].allocatedAmount -= _amount;

        emit AllocationRemoved(
            _beneficiary,
            _vestingScheduleName,
            _amount,
            beneficiaries[_beneficiary][_vestingScheduleName].allocatedAmount
        );
    }

    /**
     * @dev Gets beneficiary
     * @param _beneficiary address of user
     * @param _vestingScheduleName string vesting schedule name
     * @return Beneficiary struct
     */
    function getBeneficiary(address _beneficiary, string calldata _vestingScheduleName)
        external
        view
        returns (Beneficiary memory)
    {
        return beneficiaries[_beneficiary][_vestingScheduleName];
    }

    /**
     * @dev Deletes beneficiary
     * @param _beneficiary address of user
     */
    function deleteBeneficiary(address _beneficiary) external onlyOwner {
        require(!paused, 'TokenVesting: Contract is paused!');
        for (uint32 i = 0; i < vestingSchedulesNames.length; i++) {
            uint256 unreleasedAmount = getBeneficiaryUnreleasedAmount(_beneficiary, vestingSchedulesNames[i]);
            beneficiaries[_beneficiary][vestingSchedulesNames[i]].allocatedAmount -= unreleasedAmount;
            vestingSchedules[vestingSchedulesNames[i]].allocatedAmount -= unreleasedAmount;
        }
        emit BeneficiaryDeleted(_beneficiary);
    }

    /**
     * @dev Gets the beneficiary's next vestings
     * @param _beneficiary address of user
     * @return VestingExpectations[] structure
     */
    function getBeneficiaryNextVestings(address _beneficiary) external view returns (VestingExpectation[] memory) {
        string[] memory scheduleNames = getBeneficiaryActiveScheduleNames(_beneficiary);
        require(scheduleNames.length != 0, 'TokenVesting: None active vestings allocated to this address');
        VestingExpectation[] memory vestingExpectations = new VestingExpectation[](scheduleNames.length);
        for (uint32 i = 0; i < scheduleNames.length; i++) {
            VestingExpectation memory vestingExpectation = VestingExpectation({
                vesting: getNextVesting(scheduleNames[i]),
                beneficiaryAmount: getNextUnlockAmount(_beneficiary, scheduleNames[i])
            });
            vestingExpectations[i] = vestingExpectation;
        }
        return vestingExpectations;
    }

    /**
     * @dev Gets beneficiary overview
     * @param _beneficiary address of user
     * @return BeneficiaryOverview[] structure
     */
    function getBeneficiaryOverview(address _beneficiary) external view returns (BeneficiaryOverview[] memory) {
        string[] memory scheduleNames = getBeneficiaryScheduleNames(_beneficiary);
        require(scheduleNames.length != 0, 'TokenVesting: None active vestings allocated to this address');
        BeneficiaryOverview[] memory beneficiaryOverview = new BeneficiaryOverview[](scheduleNames.length);
        for (uint32 i = 0; i < scheduleNames.length; i++) {
            BeneficiaryOverview memory overview = BeneficiaryOverview({
                name: scheduleNames[i],
                terms: vestingSchedules[scheduleNames[i]].terms,
                cliff: vestingSchedules[scheduleNames[i]].cliff,
                duration: vestingSchedules[scheduleNames[i]].duration,
                allocatedAmount: beneficiaries[_beneficiary][scheduleNames[i]].allocatedAmount,
                withdrawnAmount: beneficiaries[_beneficiary][scheduleNames[i]].withdrawnAmount
            });
            beneficiaryOverview[i] = overview;
        }
        return beneficiaryOverview;
    }

    /**
     * @dev Gets the next vesting
     * @param _vestingScheduleName string
     * @return Vesting structure
     */
    function getNextVesting(string memory _vestingScheduleName) public view returns (Vesting memory) {
        require(!isVestingScheduleFinished(_vestingScheduleName), 'TokenVesting: vesting schedule finished');
        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleName];
        uint256 passedVestings = getPassedVestings(_vestingScheduleName);
        Vesting memory vesting;
        vesting.name = _vestingScheduleName;
        vesting.timestamp = tgeTimestamp + vestingSchedule.cliff + vestingSchedule.terms * (passedVestings + 1);
        vesting.amount = vestingSchedule.totalAmount / vestingSchedule.duration;
        return vesting;
    }

    /**
     * INDECISIVE public/internal
     * @dev Gets the amount of tokens locked for all schedules
     * @return uint256 unreleased amount of tokens
     */
    function getTotalLockedAmount() public view returns (uint256) {
        uint256 lockedAmount;
        string[] memory vestingScheduleNames = getAllVestingScheduleNames();
        for (uint32 i = 0; i < vestingScheduleNames.length; i++) {
            lockedAmount += getScheduleLockedAmount(vestingScheduleNames[i]);
        }
        return lockedAmount;
    }

    /**
     * @dev Claims caller's tokens
     * @param _vestingScheduleName string vesting schedule name
     * @param _amount uint256 amount of tokens
     */
    function claimTokens(string memory _vestingScheduleName, uint256 _amount) public {
        require(!paused, 'TokenVesting: Contract is paused!');
        require(
            bytes(_vestingScheduleName).length > 0,
            'TokenVesting: cannot add allocation for empty vesting schedule'
        );
        require(isVestingScheduleValid(_vestingScheduleName), 'TokenVesting: vesting schedule is not active');
        require(_amount > 0, 'TokenVesting: amount must be > 0');
        require(
            getScheduleLockedAmount(_vestingScheduleName) >= _amount,
            'TokenVesting: cannot claim greater than locked vesting schedule amount'
        );
        require(
            getBeneficiaryUnclaimedAmount(_msgSender(), _vestingScheduleName) >= _amount,
            'TokenVesting: cannot claim greater than unclaimed amount'
        );
        sendTokens(_msgSender(), _amount);
        vestingSchedulesTotalAmount += _amount;
        vestingSchedules[_vestingScheduleName].releasedAmount += _amount;
        beneficiaries[_msgSender()][_vestingScheduleName].withdrawnAmount += _amount;
        emit TokensClaimed(
            _msgSender(),
            _vestingScheduleName,
            _amount,
            beneficiaries[_msgSender()][_vestingScheduleName].withdrawnAmount
        );
    }

    /**
     * @dev Claims all caller's tokens for selected vesting schedule
     * @param _vestingScheduleName string vesting schedule name
     */
    function claimAllTokensForVestingSchedule(string memory _vestingScheduleName) public {
        require(!paused, 'TokenVesting: Contract is paused!');
        uint256 amount = getBeneficiaryUnclaimedAmount(_msgSender(), _vestingScheduleName);
        claimTokens(_vestingScheduleName, amount);
    }

    /**
     * @dev Claims all caller's tokens
     */
    function claimAllTokens() public {
        require(!paused, 'TokenVesting: Contract is paused!');
        string[] memory unclaimedVestingScheduleNames = getBeneficiaryUnclaimedScheduleNames(_msgSender());
        require(unclaimedVestingScheduleNames.length > 0, 'TokenVesting: there are no unclaimed tokens');
        for (uint32 i = 0; i < unclaimedVestingScheduleNames.length; i++) {
            claimAllTokensForVestingSchedule(unclaimedVestingScheduleNames[i]);
        }
    }

    /**
     * @dev Returns the amount of tokens not involved in vesting schedules
     * @return uint256 amount of tokens
     */
    function getUnusedAmount() internal view returns (uint256) {
        return token.balanceOf(address(this)) - vestingSchedulesTotalAmount;
    }

    /**
     * @dev Returns current timestamp
     * @return uint256 timestamp
     */
    function getCurrentTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /**
     * @dev Checks is vesting schedule name unique
     * @param _name string vesting schedule name
     */
    function isNameUnique(string memory _name) internal view returns (bool) {
        for (uint32 i = 0; i < vestingSchedulesNames.length; i++) {
            if (keccak256(bytes(vestingSchedulesNames[i])) == keccak256(bytes(_name))) {
                return false;
            }
        }
        return true;
    }

    /**
     * @dev Checks is vesting schedule active
     * @param _vestingScheduleName string vesting schedule name
     * @return bool true if active
     */
    function isVestingScheduleValid(string memory _vestingScheduleName) internal view returns (bool) {
        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleName];
        return vestingSchedule.initialized && !vestingSchedule.revoked;
    }

    /**
     * @dev Gets all vesting schedule names
     * @return string list of schedule names
     */
    function getAllVestingScheduleNames() internal view virtual returns (string[] memory) {
        return vestingSchedulesNames;
    }

    /**
     * @dev Gets all active vesting schedule names
     * @return string list of schedule names
     */
    function getValidVestingScheduleNames() internal view returns (string[] memory) {
        string[] memory validVestingSchedulesNames = new string[](validVestingSchedulesCount);
        uint32 j;
        for (uint32 i = 0; i < vestingSchedulesNames.length; i++) {
            if (isVestingScheduleValid(vestingSchedulesNames[i])) {
                validVestingSchedulesNames[j] = vestingSchedulesNames[i];
                j++;
            }
        }
        return validVestingSchedulesNames;
    }

    /**
     * @dev Revokes vesting schedule
     * @param _name string schedule name
     */
    function _revokeVestingSchedule(string memory _name) internal {
        require(!isNameUnique(_name), 'TokenVesting: Vesting schedule does not exist!');
        require(vestingSchedules[_name].revoked != true, 'TokenVesting: Vesting already revoked!');
        vestingSchedules[_name].revoked = true;
        vestingSchedulesTotalAmount -= getScheduleUnreleasedAmount(_name);
        validVestingSchedulesCount--;
        emit VestingScheduleRevoked(_name);
    }

    /**
     * @dev Checks is vesting schedule started
     * @param _vestingScheduleName string vesting schedule name
     * @return bool true if started
     */
    function isVestingScheduleStarted(string memory _vestingScheduleName) internal view returns (bool) {
        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleName];
        return getCurrentTimestamp() >= tgeTimestamp + vestingSchedule.cliff;
    }

    /**
     * @dev Checks is vesting schedule finished
     * @param _vestingScheduleName string vesting schedule name
     * @return bool true if finished
     */
    function isVestingScheduleFinished(string memory _vestingScheduleName) internal view returns (bool) {
        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleName];
        return
            getCurrentTimestamp() >
            tgeTimestamp + vestingSchedule.cliff + vestingSchedule.duration * vestingSchedule.terms;
    }

    /**
     * @dev Gets the vesting schedule passed duration
     * @param _vestingScheduleName string
     * @return uint256 number of passed vesting
     */
    function getPassedVestings(string memory _vestingScheduleName) internal view returns (uint256) {
        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleName];
        if (isVestingScheduleStarted(_vestingScheduleName)) {
            return (getCurrentTimestamp() - tgeTimestamp - vestingSchedule.cliff) / vestingSchedule.terms;
        }
        if (isVestingScheduleFinished(_vestingScheduleName)) {
            return vestingSchedule.duration;
        }
        return 0;
    }

    /**
     * @dev Returns the amount of tokens that can be released from vesting schedule
     * @param _vestingScheduleName string vesting schedule name
     * @return uint256 unreleased amount of tokens
     */
    function getScheduleUnreleasedAmount(string memory _vestingScheduleName) internal view returns (uint256) {
        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleName];
        return vestingSchedule.totalAmount - vestingSchedule.releasedAmount;
    }

    /**
     * @dev Returns the amount of locked tokens
     * @param _vestingScheduleName string vesting schedule name
     * @return uint256 locked amount of tokens
     */
    function getScheduleLockedAmount(string memory _vestingScheduleName) internal view returns (uint256) {
        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleName];
        return vestingSchedule.allocatedAmount - vestingSchedule.releasedAmount;
    }

    /**
     * @dev Returns the amount of tokens that can be allocated from vesting schedule
     * @param _vestingScheduleName string vesting schedule name
     * @return uint256 unallocated amount of tokens
     */
    function getScheduleUnallocatedAmount(string memory _vestingScheduleName) internal view returns (uint256) {
        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleName];
        return vestingSchedule.totalAmount - vestingSchedule.allocatedAmount;
    }

    /**
     * @dev Gets beneficiary schedule names
     * @param _beneficiary address of user
     * @return string[] array schedule names assigned to beneficiary
     */
    function getBeneficiaryScheduleNames(address _beneficiary) internal view returns (string[] memory) {
        uint256 beneficiaryScheduleNamesCount;
        string[] memory vestingScheduleNames = getValidVestingScheduleNames();
        for (uint32 i = 0; i < validVestingSchedulesCount; i++) {
            if (beneficiaries[_beneficiary][vestingScheduleNames[i]].allocatedAmount > 0) {
                beneficiaryScheduleNamesCount++;
            }
        }

        string[] memory beneficiaryScheduleNames = new string[](beneficiaryScheduleNamesCount);
        uint256 j;
        for (uint32 i = 0; i < validVestingSchedulesCount; i++) {
            if (beneficiaries[_beneficiary][vestingScheduleNames[i]].allocatedAmount > 0) {
                beneficiaryScheduleNames[j] = vestingScheduleNames[i];
                j++;
            }
        }
        return beneficiaryScheduleNames;
    }

    /**
     * @dev Gets beneficiary unclaimed schedule names
     * @param _beneficiary address of user
     * @return string[] array schedule names assigned to beneficiary
     */
    function getBeneficiaryUnclaimedScheduleNames(address _beneficiary) internal view returns (string[] memory) {
        uint256 beneficiaryScheduleNamesCount;
        string[] memory vestingScheduleNames = getValidVestingScheduleNames();
        for (uint32 i = 0; i < validVestingSchedulesCount; i++) {
            if (getBeneficiaryUnclaimedAmount(_beneficiary, vestingScheduleNames[i]) > 0) {
                beneficiaryScheduleNamesCount++;
            }
        }

        string[] memory beneficiaryScheduleNames = new string[](beneficiaryScheduleNamesCount);
        uint256 j;
        for (uint32 i = 0; i < validVestingSchedulesCount; i++) {
            if (getBeneficiaryUnclaimedAmount(_beneficiary, vestingScheduleNames[i]) > 0) {
                beneficiaryScheduleNames[j] = vestingScheduleNames[i];
                j++;
            }
        }
        return beneficiaryScheduleNames;
    }

    /**
     * @dev Gets beneficiary active schedule names
     * @param _beneficiary address of user
     * @return string[] array schedule names assigned to beneficiary
     */
    function getBeneficiaryActiveScheduleNames(address _beneficiary) internal view returns (string[] memory) {
        uint256 beneficiaryActiveScheduleNamesCount;
        string[] memory activeVestingScheduleNames = getValidVestingScheduleNames();
        for (uint32 i = 0; i < validVestingSchedulesCount; i++) {
            if (
                beneficiaries[_beneficiary][activeVestingScheduleNames[i]].allocatedAmount > 0 &&
                !isVestingScheduleFinished(activeVestingScheduleNames[i])
            ) {
                beneficiaryActiveScheduleNamesCount++;
            }
        }

        string[] memory beneficiaryActiveScheduleNames = new string[](beneficiaryActiveScheduleNamesCount);
        uint256 j;
        for (uint32 i = 0; i < validVestingSchedulesCount; i++) {
            if (
                beneficiaries[_beneficiary][activeVestingScheduleNames[i]].allocatedAmount > 0 &&
                !isVestingScheduleFinished(activeVestingScheduleNames[i])
            ) {
                beneficiaryActiveScheduleNames[j] = activeVestingScheduleNames[i];
                j++;
            }
        }
        return beneficiaryActiveScheduleNames;
    }

    /**
     * @dev Gets beneficiary next unlocked amount
     * @param _beneficiary address of user
     * @param _vestingScheduleName string
     * @return uint256 allocation
     */
    function getNextUnlockAmount(address _beneficiary, string memory _vestingScheduleName)
        internal
        view
        returns (uint256)
    {
        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleName];
        return beneficiaries[_beneficiary][_vestingScheduleName].allocatedAmount / vestingSchedule.duration;
    }

    /**
     * @dev Returns the unlocked amount of tokens for selected beneficiary and vesting schedule
     * @param _beneficiary address of user
     * @param _vestingScheduleName string vesting schedule name
     * @return uint256 unlocked amount of tokens
     */
    function getBeneficiaryUnlockedAmount(address _beneficiary, string memory _vestingScheduleName)
        internal
        view
        returns (uint256)
    {
        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleName];
        Beneficiary memory beneficiary = beneficiaries[_beneficiary][_vestingScheduleName];
        if (isVestingScheduleFinished(_vestingScheduleName)) {
            return beneficiary.allocatedAmount;
        }
        return (getPassedVestings(_vestingScheduleName) * beneficiary.allocatedAmount) / vestingSchedule.duration;
    }

    /**
     * @dev Returns the amount of tokens that can be claimed by beneficiary
     * @param _beneficiary address of user
     * @param _vestingScheduleName string vesting schedule name
     * @return uint256 unclaimed amount of tokens
     */
    function getBeneficiaryUnclaimedAmount(address _beneficiary, string memory _vestingScheduleName)
        internal
        view
        returns (uint256)
    {
        uint256 unlockedAmount = getBeneficiaryUnlockedAmount(_beneficiary, _vestingScheduleName);
        return unlockedAmount - beneficiaries[_beneficiary][_vestingScheduleName].withdrawnAmount;
    }

    /**
     * @dev Returns the amount of tokens that unreleased by beneficiary
     * @param _beneficiary address of user
     * @param _vestingScheduleName string vesting schedule name
     * @return uint256 unclaimed amount of tokens
     */
    function getBeneficiaryUnreleasedAmount(address _beneficiary, string memory _vestingScheduleName)
        internal
        view
        returns (uint256)
    {
        Beneficiary memory beneficiary = beneficiaries[_beneficiary][_vestingScheduleName];
        return beneficiary.allocatedAmount - beneficiary.withdrawnAmount;
    }

    /**
     * @dev Sends tokens to selected address
     * @param _to address of account
     * @param _amount uint256 amount of tokens
     */
    function sendTokens(address _to, uint256 _amount) internal {
        require(_to != address(0x0), 'TokenVesting: receiver be a zero');
        require(_amount <= getTotalLockedAmount(), 'TokenVesting: withdrawing greater tokens than locked');
        token.transfer(_to, _amount);
    }

    function transferOwnership(address newOwner) public virtual override onlyOwner{
        require(!paused, 'TokenVesting: Contract is paused!');
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _transferOwnership(newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
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