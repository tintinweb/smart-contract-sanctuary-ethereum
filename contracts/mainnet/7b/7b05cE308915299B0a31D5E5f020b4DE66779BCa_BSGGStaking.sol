// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IBSGGStaking.sol";

contract BSGGStaking is IBSGGStaking, ERC721, ERC721Enumerable, Pausable, Ownable {
    uint32 public ticketCounter;
    uint32 public ticketTypeCounter;

    // Stake holders can withdraw the amounts they staked, no profit
    bool public emergencyMode = false;

    // Shortlisted accounts only can by tickets
    bool public privilegedMode = false;

    // Accounts which can buy tickets when privilegedMode is enbabled
    mapping(address => bool) public privilegedAccounts;

    IERC20 public immutable BSGG;

    mapping(uint => Ticket) public tickets;
    mapping(uint => TicketType) public ticketTypes;


    // If min / max limit mode is enabled
    bool public maxLimitMode = false;

    // Limit the min volumes accounts can stake
    uint public minLimitAmount;

    // Limit the max volumes accounts can stake at a time
    uint public maxLimitAmount;
    

    // Total staked amount by the account. Limiting by the maxLimitAmount;
    // ticketType => address => amount
    mapping(uint => mapping(address => uint)) public activeStaked;

    modifier allGood() {
        require(!emergencyMode, "Emergency mode is enabled. Withdrawal only");
        _;
    }

    modifier alarmed() {
        require(emergencyMode, "Emergency mode is not activated");
        _;
    }

    modifier minMaxLimit(uint _ticketTypeId, uint _amount) {
        if (maxLimitMode == true) {
            uint stakedAlready = activeStaked[_ticketTypeId][msg.sender];
            require((_amount + stakedAlready) <= maxLimitAmount, "Max staked amount per account is reached");
            require((stakedAlready + _amount) >= minLimitAmount, "Amount is less than min allowed");
        }
        _;
    }

    constructor(IERC20 _BSGG) ERC721("BSGGStaking", "BSGGStaking") {
        BSGG = _BSGG;
    }

    /// @notice Pause new Staking
    /// @return bool
    function pause() external onlyOwner returns (bool) {
        _pause();
        emit Paused(true);
        return true;
    }

    /// @notice Unpause new Staking
    /// @return bool
    function unpause() external onlyOwner returns (bool){
        _unpause();
        emit Paused(false);
        return true;
    }

    /// @notice Allocate BSGG for distribution
    /// @param _amount Amount of BSGG
    /// @param _ticketTypeId Ticket id that will be funded
    /// @return bool
    function allocateBSGG(uint _amount, uint _ticketTypeId) external onlyOwner allGood returns (bool) {
        require(_ticketTypeId < ticketTypeCounter, "Bad ticket type");
        require(ticketTypes[_ticketTypeId].active == true, "Ticket type must be active");
        require(_amount <= BSGG.balanceOf(msg.sender), "Insuficient funds");
        require(_amount <= BSGG.allowance(msg.sender, address(this)), "Allowance required");
        
        uint16 totalSeasons = uint16(ticketTypes[_ticketTypeId].seasons.length);
        uint16 currentSeason = this.currentSeasonId(_ticketTypeId);

        totalSeasons -= currentSeason;

        uint amountPerSeason = uint(_amount / totalSeasons);
        uint amountLeft = _amount;

        for (uint16 i = currentSeason; i < uint16(ticketTypes[_ticketTypeId].seasons.length); i++) {
            uint currentSeasonAmount = amountPerSeason;

            // Last season takes the rest amount in full
            if (i == (uint16(ticketTypes[_ticketTypeId].seasons.length) - 1)) {
                currentSeasonAmount = amountLeft;
            }

            if (currentSeasonAmount > 0) {
                ticketTypes[_ticketTypeId].seasons[i].BSGGAllocation += currentSeasonAmount;
                ticketTypes[_ticketTypeId].seasons[i].BSGGAllTimeAllocation += currentSeasonAmount;

                amountLeft -= currentSeasonAmount;
            }   
        }

        // Send Tokens to Staking Smart Contract
        bool success = BSGG.transferFrom(msg.sender, address(this), _amount);
        
        require(success == true, "Transfer Failed");

        emit AllocatedNewBSGG(_amount, _ticketTypeId);

        return true;
    }

    /// @notice Creates a new ticket type
    /// @param _minLockAmount Minimal amount of BSGG to stake
    /// @param _lockDuration Fund lock period in seconds
    /// @param _gainMultiplier Total reward rate per stake period (0 - 0%, 1500000 is 150%)
    /// @param _seasons Total number of seasons
    /// @return bool
    function addTicketType(
        uint128 _minLockAmount,
        uint32 _lockDuration,
        uint32 _gainMultiplier,
        uint16 _seasons
    ) external onlyOwner allGood returns (bool) {
        require(_minLockAmount >= 1 ether, "Bad minimum lock amount");
        require(_lockDuration >= 1 hours, "Lock duration is too short");
        require(_gainMultiplier > 0, "Gain multiplier lower or equal to base");
        require(_seasons > 0, "Seasons must be equal to 1 or higher");

        ticketTypes[ticketTypeCounter].id               = ticketTypeCounter;
        ticketTypes[ticketTypeCounter].active           = true;
        ticketTypes[ticketTypeCounter].minLockAmount    = _minLockAmount;
        ticketTypes[ticketTypeCounter].lockDuration     = _lockDuration;
        ticketTypes[ticketTypeCounter].gainMultiplier   = _gainMultiplier;
        ticketTypes[ticketTypeCounter].APR              = uint(_gainMultiplier) * 365 * 86400 / uint(_lockDuration);

        uint timeStart = block.timestamp;

        // Create seasons for ticket type
        for (uint16 i = 0; i < _seasons; i++) {
            Season memory s = Season({
                startTime: timeStart,
                BSGGAllocation: 0,
                BSGGAllTimeAllocation: 0,
                BSGGTotalTokensLocked: 0
            });

            ticketTypes[ticketTypeCounter].seasons.push(s);
            timeStart += _lockDuration;
        }

        ticketTypeCounter++;

        emit TicketTypeAdded(ticketTypeCounter);

        return true;
    }

    /// @notice Updates a ticket type, for new stake holders only
    /// @param _id Ticket type id
    /// @param _minLockAmount Minimal amount of BSGG to stake
    /// @param _lockDuration Fund lock period in seconds
    /// @param _gainMultiplier Total reward rate per stake period (0 - 0%, 1500000 is 150%)
    /// @return bool
    function updateTicketType(
        uint32 _id,
        uint128 _minLockAmount,
        uint32 _lockDuration,
        uint32 _gainMultiplier
    ) external onlyOwner allGood returns(bool) {
        require(_id < ticketTypeCounter, "Invalid ticket type");
        require(_minLockAmount >= 1 ether, "Invalid minimum lock amount");
        require(_lockDuration >= 1 hours, "Lock duration is too short");
        require(_gainMultiplier > 0, "Gain multiplier is lower or equal to base");

        ticketTypes[_id].minLockAmount    = _minLockAmount;
        ticketTypes[_id].lockDuration     = _lockDuration;
        ticketTypes[_id].gainMultiplier   = _gainMultiplier;
        ticketTypes[_id].APR = uint(_gainMultiplier) * 365 * 86400 / uint(_lockDuration);

        emit TicketTypeUpdated(_id);

        return true;
    }

    /// @notice Deactivate a ticket type
    /// @param _ticketTypeId Ticket type id
    /// @return bool
    function deactivateTicketType(uint32 _ticketTypeId) external onlyOwner allGood returns(bool) {
        require( _ticketTypeId < ticketTypeCounter, "Not existing ticket type id");
        ticketTypes[_ticketTypeId].active = false;

        emit TicketTypeUpdated(_ticketTypeId);

        return true;
    }

    /// @notice Activate selected ticket type
    /// @param _ticketTypeId Ticket type id
    /// @return bool
    function activateTicketType(uint32 _ticketTypeId) external onlyOwner allGood returns(bool) {
        require( _ticketTypeId < ticketTypeCounter, "Not existing ticket type id");
        ticketTypes[_ticketTypeId].active = true;

        emit TicketTypeUpdated(_ticketTypeId);

        return true;
    }

    /// @notice Stake and lock BSGG
    /// @param _amount BSGG stake amount
    /// @param _ticketTypeId ticket type id
    /// @param _to ticket receiver
    /// @return bool
    function buyTicket(
        uint _amount, 
        uint32 _ticketTypeId, 
        address _to
    ) external override whenNotPaused allGood minMaxLimit(_ticketTypeId, _amount) returns(bool) {
        require(ticketTypes[_ticketTypeId].active, "Ticket is not available");
        require(_amount >= ticketTypes[_ticketTypeId].minLockAmount, "Too small stake amount");
        require(_amount <= BSGG.balanceOf(msg.sender), "Insuficient funds");
        require(_amount <= BSGG.allowance(msg.sender, address(this)), "Allowance is required");
        
        uint amountToGain = (_amount * ticketTypes[_ticketTypeId].gainMultiplier) / 1e6;

        uint16 currentSeason = this.currentSeasonId(_ticketTypeId);

        require(amountToGain <= ticketTypes[_ticketTypeId].seasons[currentSeason].BSGGAllocation, "Sold out");

        if (privilegedMode == true) {
            require(privilegedAccounts[msg.sender] == true, "Privileged mode is enabled");
        }

        uint32 ticketId = ++ticketCounter;

        tickets[ticketId].id                 = ticketId;
        tickets[ticketId].ticketType         = _ticketTypeId;
        tickets[ticketId].seasonId           = currentSeason;
        tickets[ticketId].mintTimestamp      = block.timestamp;
        tickets[ticketId].lockedToTimestamp  = block.timestamp + ticketTypes[_ticketTypeId].lockDuration;
        tickets[ticketId].amountLocked       = _amount;
        tickets[ticketId].amountToGain       = amountToGain;

        // Re-allocate unused amount from previous seasons
        _reallocateSeasonUnallocated(_ticketTypeId, currentSeason);

        ticketTypes[_ticketTypeId].seasons[currentSeason].BSGGTotalTokensLocked += _amount;
        ticketTypes[_ticketTypeId].seasons[currentSeason].BSGGAllocation -= tickets[ticketId].amountToGain;

        activeStaked[_ticketTypeId][msg.sender] += _amount;

        (bool success) = BSGG.transferFrom(msg.sender, address(this), _amount);
        require(success == true, "Transfer Failed");

        // Mint the token
        _safeMint(_to, ticketId);

        emit TicketBought(
            _to, 
            ticketId, 
            _amount,
            tickets[ticketId].amountToGain, 
            ticketTypes[_ticketTypeId].lockDuration
        );

        return true;
    }

    /// @notice Unlock and send staked tokens and rewards to staker(with or without penalties depending on the time passed).
    /// @param _ticketId ticket type id
    /// @return bool
    function redeemTicket(uint _ticketId) external override allGood returns(bool) {
        require(ownerOf(_ticketId) == msg.sender, "Not token owner");

        (uint pendingStakeAmountToWithdraw, uint pendingRewardTokensToClaim) = this.getPendingTokens(_ticketId);
        uint totalAmountToWithdraw = pendingStakeAmountToWithdraw + pendingRewardTokensToClaim;

        require(totalAmountToWithdraw <= BSGG.balanceOf(address(this)), "Insuficient funds");

        uint totalAmountToReAllocate = (tickets[_ticketId].amountToGain - pendingRewardTokensToClaim) + (tickets[_ticketId].amountLocked - pendingStakeAmountToWithdraw);
        
        ticketTypes[tickets[_ticketId].ticketType].seasons[tickets[_ticketId].seasonId].BSGGAllocation += totalAmountToReAllocate;
        ticketTypes[tickets[_ticketId].ticketType].seasons[tickets[_ticketId].seasonId].BSGGTotalTokensLocked -= tickets[_ticketId].amountLocked;

        activeStaked[tickets[_ticketId].ticketType][msg.sender] -= tickets[_ticketId].amountLocked;

        delete tickets[_ticketId];
        _burn(_ticketId);

        (bool success) = BSGG.transfer(msg.sender, totalAmountToWithdraw);
        require(success == true, "Transfer Failed");

        emit TicketRedeemed(msg.sender, _ticketId);

        return true;
    }

    /// @notice Unlock and send staked tokens in case of emergency, staked amount only
    /// @param _ticketId ticket type id
    /// @return bool
    function redeemTicketEmergency(uint _ticketId) external alarmed returns(bool) {
        require(ownerOf(_ticketId) == msg.sender, "Not token owner");

        require(tickets[_ticketId].amountLocked <= BSGG.balanceOf(address(this)), "Insuficient funds");

        uint amountRedeem = tickets[_ticketId].amountLocked;

        delete tickets[_ticketId];
        _burn(_ticketId);

        (bool success) = BSGG.transfer(msg.sender, amountRedeem);
        require(success == true, "Transfer Failed");

        emit TicketRedeemed(msg.sender, _ticketId);

        return true;
    }

    /// @notice Get amount of staked tokens and reward
    /// @param _ticketId Ticket type id
    /// @return stakeAmount , rewardAmount
    function getPendingTokens(uint _ticketId) external view returns (uint stakeAmount, uint rewardAmount) {
        uint lockDuration = tickets[_ticketId].lockedToTimestamp - tickets[_ticketId].mintTimestamp;
        uint halfPeriodTimestamp = tickets[_ticketId].lockedToTimestamp - (lockDuration / 2);

        if (block.timestamp < tickets[_ticketId].lockedToTimestamp) {
            stakeAmount = (tickets[_ticketId].amountLocked * 800000) / 1e6; // 20% penalty applied to staked amount

            // If staked for at least the half of the period
            if (block.timestamp >= halfPeriodTimestamp){
                uint pendingReward = _calculatePendingRewards(
                    block.timestamp,
                    tickets[_ticketId].mintTimestamp,
                    tickets[_ticketId].lockedToTimestamp,
                    tickets[_ticketId].amountToGain
                );
                rewardAmount = pendingReward / 2; // The account can get 50% of pending rewards
            }
        } else { // Lock period is over. The account can receive all staked and reward tokens.
            stakeAmount = tickets[_ticketId].amountLocked;
            rewardAmount = tickets[_ticketId].amountToGain;
        }
    }

    /// @notice Checks pending rewards by the date. Returns 0 in deleted ticket Id
    /// @param _ticketId Ticket type id
    /// @return amount
    function getPendingRewards(uint _ticketId) external view returns (uint amount) {
        amount = _calculatePendingRewards(
            block.timestamp < tickets[_ticketId].lockedToTimestamp ? block.timestamp : tickets[_ticketId].lockedToTimestamp,
            tickets[_ticketId].mintTimestamp,
            tickets[_ticketId].lockedToTimestamp,
            tickets[_ticketId].amountToGain
        );
    }

    /// @notice Outputs parameters of all account tickets
    /// @param _account Account Address
    /// @return accountInfo
    function getAccountInfo(address _account) external view returns(AccountSet memory accountInfo) {
        uint countOfTicket = balanceOf(_account);
        Ticket[] memory accountTickets = new Ticket[](countOfTicket);
        uint allocatedBSGG;
        uint pendingBSGGEarning;

        for (uint i = 0; i < countOfTicket; i++){
            uint ticketId = tokenOfOwnerByIndex(_account, i);
            accountTickets[i] = tickets[ticketId];
            allocatedBSGG += tickets[ticketId].amountLocked;
            pendingBSGGEarning += this.getPendingRewards(ticketId);
        }

        accountInfo.accountTickets = accountTickets;
        accountInfo.allocatedBSGG = allocatedBSGG;
        accountInfo.pendingBSGGEarning = pendingBSGGEarning;
    }

    /// @notice Returns all available tickets and their parameters
    /// @return allTicketTypes
    function getTicketTypes() external view returns(TicketType[] memory allTicketTypes) {
        allTicketTypes = new TicketType[](ticketTypeCounter);
        for (uint i = 0; i < ticketTypeCounter; i++) {
            allTicketTypes[i] = ticketTypes[i];
        }
    }

    /// @notice TVL across all pools
    /// @return TVL Total Tokens Locked in all ticket types
    function getTVL() external view returns(uint TVL){
        for (uint i = 0; i < ticketTypeCounter; i++) {
            for (uint16 j = 0; j < ticketTypes[i].seasons.length; j++) {
                TVL += ticketTypes[i].seasons[j].BSGGTotalTokensLocked;
                TVL += ticketTypes[i].seasons[j].BSGGAllocation;
            }
        }
    }

    /// @notice Get amount the account has active staked in a ticket type
    /// @param _ticketTypeId Ticket Type ID
    /// @param _account Account
    /// @return uint
    function getActiveStaked(uint _ticketTypeId, address _account) external view returns (uint) {
        return activeStaked[_ticketTypeId][_account];
    }

    /// @notice Set emergency state
    /// @param code A security code. Requiered in case of unaccidentaly call of this function
    /// @return bool
    function triggerEmergency(uint code) external onlyOwner allGood returns(bool) {
        require(code == 111000111, "You need write 111000111");

        emergencyMode = true;
        _pause();

        emit EmergencyModeEnabled();

        return true;
    }

    /// @notice Enable PrivilegedMode, shortlisted accounts only can buy tickets
    /// @return bool
    function enablePrivilegedMode() external onlyOwner returns(bool) {
        privilegedMode = true;
        emit PrivilegedMode(privilegedMode);

        return true;
    }

    /// @notice Disable PrivilegedMode, all accounts can buy tickets
    /// @return bool
    function disablePrivilegedMode() external onlyOwner returns(bool) {
        privilegedMode = false;
        emit PrivilegedMode(privilegedMode);

        return true;
    }

    /// @notice Add previledged accounts
    /// @param _accounts Account to make privileged
    /// @return bool
    function addPrivilegedAccounts(address[] memory _accounts) external onlyOwner returns(bool) {
        require(_accounts.length < 400, "Too many accounts to add");

        for (uint16 i = 0; i < _accounts.length; i++) {
            privilegedAccounts[_accounts[i]] = true;
        }

        emit PrivilegedMode(privilegedMode);

        return true;
    }

    /// @notice Remove previledged accounts
    /// @param _accounts Account to make privileged
    /// @return bool
    function removePrivilegedAccounts(address[] memory _accounts) external onlyOwner returns(bool) {
        require(_accounts.length < 400, "Too many accounts to remove");

        for (uint16 i = 0; i < _accounts.length; i++) {
            privilegedAccounts[_accounts[i]] = false;
        }

        emit PrivilegedMode(privilegedMode);

        return true;
    }

    /// @notice Maximum allocation (balance) available for a season by ticket type id
    /// @param _ticketTypeId Ticket type id
    /// @return uint256
    function maxAllocationSeason(uint _ticketTypeId) external view returns (uint256) {
        uint currentTime = block.timestamp;
        uint maxBalance = 0;

        for (uint16 i = 0; i < ticketTypes[_ticketTypeId].seasons.length; i++) {
            if (ticketTypes[_ticketTypeId].seasons[i].startTime > currentTime) {
                break;
            }

            maxBalance += ticketTypes[_ticketTypeId].seasons[i].BSGGAllocation;
        }

        return maxBalance;
    }

    /// @notice Total staked amount (balance) by users in ticket type id
    /// @param _ticketTypeId Ticket type id
    /// @return uint256
    function amountLockedSeason(uint _ticketTypeId) external view returns (uint256) {
        uint currentTime = block.timestamp;
        uint amount = 0;

        for (uint16 i = 0; i < ticketTypes[_ticketTypeId].seasons.length; i++) {
            if (ticketTypes[_ticketTypeId].seasons[i].startTime > currentTime) {
                break;
            }

            amount += ticketTypes[_ticketTypeId].seasons[i].BSGGTotalTokensLocked;
        }

        return amount;
    }

    /// @notice Get current season id by ticket type id
    /// @param _ticketTypeId Ticket type id
    /// @return uint16
    function currentSeasonId(uint _ticketTypeId) external view returns (uint16) {
        uint currentTime = block.timestamp;

        uint16 seasonId = 0;

        for (uint16 i = 0; i < ticketTypes[_ticketTypeId].seasons.length; i++) {
            if (ticketTypes[_ticketTypeId].seasons[i].startTime > currentTime) {
                break;
            }

            seasonId = i;
        }

        return seasonId;
    }


    /// @notice Withdraw previously allocated BSGG, but only not reserved for accounts
    /// @param _amount Amount of BSGG to remove from allocation
    /// @param _ticketTypeId Ticket type id
    /// @return bool
    function withdrawNonReservedBSGG(uint _amount, uint32 _ticketTypeId, uint16 _seasonId, address _account) external onlyOwner returns(bool) {
        uint withdrawAmount = ticketTypes[_ticketTypeId].seasons[_seasonId].BSGGAllocation >= _amount ? _amount : ticketTypes[_ticketTypeId].seasons[_seasonId].BSGGAllocation;
        
        require(withdrawAmount <= BSGG.balanceOf(address(this)), "Insuficient funds");

        ticketTypes[_ticketTypeId].seasons[_seasonId].BSGGAllTimeAllocation -= withdrawAmount;
        ticketTypes[_ticketTypeId].seasons[_seasonId].BSGGAllocation -= withdrawAmount;

        (bool success) = BSGG.transfer(_account, withdrawAmount);
        require(success == true, "Transfer Failed");

        emit TicketTypeUpdated(_ticketTypeId);

        return true;
    }

    /// @notice Set Max and Min amounts for staking per account
    /// @param _minAmount Min amount
    /// @param _maxAmount Max amount
    /// @param _status Enabled true/ false
    /// @return bool
    function changeMinMaxLimits(uint _minAmount, uint _maxAmount, bool _status) external onlyOwner returns(bool) {
        require(_minAmount <= _maxAmount, "Invalid min and max amounts");

        maxLimitMode = _status;
        minLimitAmount = _minAmount;
        maxLimitAmount = _maxAmount;

        emit MinMaxLimitChanged(_minAmount, _maxAmount, _status);

        return true;
    }

    /// @notice Calculates pending rewards
    /// @return amount amount
    function _calculatePendingRewards(
        uint timestamp,
        uint mintTimestamp,
        uint lockedToTimestamp,
        uint amountToGain
    ) pure internal returns (uint amount){
        return amountToGain * (timestamp - mintTimestamp) / (lockedToTimestamp - mintTimestamp);
    }

    /// @notice Reuse unallocated balance from previous seasons
    /// @param _ticketTypeId Ticket type id
    /// @return amount
    function _reallocateSeasonUnallocated(uint _ticketTypeId, uint16 _currentSeasonId) internal returns (bool){
        uint reAllocationAmount = 0;

        for (uint16 i = 0; i < ticketTypes[_ticketTypeId].seasons.length; i++) {
            // Season is sold out
            if (ticketTypes[_ticketTypeId].seasons[i].BSGGAllocation <= 0) {
                continue;
            }

            // Current season or seson not available yet
            if (i == _currentSeasonId || ticketTypes[_ticketTypeId].seasons[i].startTime >= block.timestamp) {
                break;
            }

            reAllocationAmount += ticketTypes[_ticketTypeId].seasons[i].BSGGAllocation;
            ticketTypes[_ticketTypeId].seasons[i].BSGGAllTimeAllocation -= ticketTypes[_ticketTypeId].seasons[i].BSGGAllocation;
            ticketTypes[_ticketTypeId].seasons[i].BSGGAllocation = 0;
        }

        if (reAllocationAmount > 0) {
            ticketTypes[_ticketTypeId].seasons[_currentSeasonId].BSGGAllTimeAllocation += reAllocationAmount;
            ticketTypes[_ticketTypeId].seasons[_currentSeasonId].BSGGAllocation += reAllocationAmount;
        }

        return true;
    }
    
    function _beforeTokenTransfer(address from, address to, uint ticketId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, ticketId);
    }

    /// @notice The following functions are overrides required by Solidity
    /// @param interfaceId Interface ID
    /// @return bool
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IBSGGStaking {
    struct Ticket {
        uint128 id;
        uint32 ticketType;
        uint16 seasonId;
        uint mintTimestamp;
        uint lockedToTimestamp;
        uint amountLocked;
        uint amountToGain;
    }

    struct Season {
        uint startTime;
        uint BSGGAllocation;
        uint BSGGAllTimeAllocation;
        uint BSGGTotalTokensLocked;
    }

    struct TicketType {
        uint32 id;
        bool active;
        uint128 minLockAmount;
        uint32 lockDuration;
        uint32 gainMultiplier;
        Season[] seasons;
        uint APR;
    }

    struct AccountSet {
        Ticket[] accountTickets;
        uint allocatedBSGG;
        uint pendingBSGGEarning;
    }

    event TicketTypeAdded(uint32 ticketTypeId);
    event TicketTypeUpdated(uint32 ticketTypeId);
    event TicketBought(address owner, uint ticketId, uint stakeAmount, uint gainAmount, uint lockDuration);
    event TicketRedeemed(address owner, uint ticketId);
    event AllocatedNewBSGG(uint amount, uint ticketTypeId);
    event EmergencyModeEnabled();
    event PrivilegedMode(bool status);
    event Paused(bool status);
    event MinMaxLimitChanged(uint minAmount, uint maxAmount, bool status);


    function allocateBSGG(uint _amount, uint _ticketTypeId) external returns(bool);
    function addTicketType(uint128 _minLockAmount, uint32 _lockDuration, uint32 _gainMultiplier, uint16 _seasons) external returns(bool);
    function updateTicketType(uint32 _id, uint128 _minLockAmount, uint32 _lockDuration,uint32 _gainMultiplier) external returns(bool);
    function deactivateTicketType(uint32 _ticketTypeId) external returns(bool);
    function activateTicketType(uint32 _ticketTypeId) external returns(bool);
    function buyTicket(uint _amount, uint32 _ticketTypeId, address _to) external returns(bool);
    function redeemTicket(uint _ticketId) external returns(bool);  
    function getPendingTokens(uint _ticketId) external view returns (uint, uint);
    function getPendingRewards(uint _ticketId) external view returns (uint);
    function getAccountInfo(address _account) external view returns(AccountSet memory);
    function getTicketTypes() external view returns(TicketType[] memory);
    function getTVL() external view returns(uint);
    function getActiveStaked(uint _ticketTypeId, address _account) external view returns (uint);
    function triggerEmergency(uint code) external returns(bool);
    function enablePrivilegedMode() external returns(bool);
    function disablePrivilegedMode() external returns(bool);
    function addPrivilegedAccounts(address[] memory _accounts) external returns(bool);
    function removePrivilegedAccounts(address[] memory _accounts) external returns(bool);
    function redeemTicketEmergency(uint _ticketId) external returns(bool);
    function maxAllocationSeason(uint _ticketTypeId) external view returns (uint256);
    function currentSeasonId(uint _ticketTypeId) external view returns (uint16);
    function withdrawNonReservedBSGG(uint _amount, uint32 _ticketTypeId, uint16 _seasonId, address _account) external returns(bool);
    function changeMinMaxLimits(uint _minAmount, uint _maxAmount, bool _status) external returns(bool);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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