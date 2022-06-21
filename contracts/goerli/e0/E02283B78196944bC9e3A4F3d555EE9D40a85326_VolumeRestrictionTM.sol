pragma solidity 0.5.8;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/math/Math.sol";
import "../../../libraries/BokkyPooBahsDateTimeLibrary.sol";
import "../../../libraries/VolumeRestrictionLib.sol";
import "../TransferManager.sol";

contract VolumeRestrictionTM is VolumeRestrictionTMStorage, TransferManager {
    using SafeMath for uint256;

    // Emit when the token holder is added/removed from the exemption list
    event ChangedExemptWalletList(address indexed _wallet, bool _exempted);
    // Emit when the new individual restriction is added corresponds to new token holders
    event AddIndividualRestriction(
        address indexed _holder,
        uint256 _allowedTokens,
        uint256 _startTime,
        uint256 _rollingPeriodInDays,
        uint256 _endTime,
        RestrictionType _typeOfRestriction
    );
    // Emit when the new daily (Individual) restriction is added
    event AddIndividualDailyRestriction(
        address indexed _holder,
        uint256 _allowedTokens,
        uint256 _startTime,
        uint256 _rollingPeriodInDays,
        uint256 _endTime,
        RestrictionType _typeOfRestriction
    );
    // Emit when the individual restriction is modified for a given address
    event ModifyIndividualRestriction(
        address indexed _holder,
        uint256 _allowedTokens,
        uint256 _startTime,
        uint256 _rollingPeriodInDays,
        uint256 _endTime,
        RestrictionType _typeOfRestriction
    );
    // Emit when individual daily restriction get modified
    event ModifyIndividualDailyRestriction(
        address indexed _holder,
        uint256 _allowedTokens,
        uint256 _startTime,
        uint256 _rollingPeriodInDays,
        uint256 _endTime,
        RestrictionType _typeOfRestriction
    );
    // Emit when the new global restriction is added
    event AddDefaultRestriction(
        uint256 _allowedTokens,
        uint256 _startTime,
        uint256 _rollingPeriodInDays,
        uint256 _endTime,
        RestrictionType _typeOfRestriction
    );
    // Emit when the new daily (Default) restriction is added
    event AddDefaultDailyRestriction(
        uint256 _allowedTokens,
        uint256 _startTime,
        uint256 _rollingPeriodInDays,
        uint256 _endTime,
        RestrictionType _typeOfRestriction
    );
    // Emit when default restriction get modified
    event ModifyDefaultRestriction(
        uint256 _allowedTokens,
        uint256 _startTime,
        uint256 _rollingPeriodInDays,
        uint256 _endTime,
        RestrictionType _typeOfRestriction
    );
    // Emit when daily default restriction get modified
    event ModifyDefaultDailyRestriction(
        uint256 _allowedTokens,
        uint256 _startTime,
        uint256 _rollingPeriodInDays,
        uint256 _endTime,
        RestrictionType _typeOfRestriction
    );
    // Emit when the individual restriction gets removed
    event IndividualRestrictionRemoved(address indexed _holder);
    // Emit when individual daily restriction removed
    event IndividualDailyRestrictionRemoved(address indexed _holder);
    // Emit when the default restriction gets removed
    event DefaultRestrictionRemoved();
    // Emit when the daily default restriction gets removed
    event DefaultDailyRestrictionRemoved();

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
     * @notice Used to verify the transfer/transferFrom transaction and prevent tranaction
     * whose volume of tokens will voilate the maximum volume transfer restriction
     * @param _from Address of the sender
     * @param _amount The amount of tokens to transfer
     */
    function executeTransfer(address _from, address /*_to */, uint256 _amount, bytes calldata /*_data*/) external onlySecurityToken returns (Result success) {
        uint256 fromTimestamp;
        uint256 sumOfLastPeriod;
        uint256 daysCovered;
        uint256 dailyTime;
        uint256 endTime;
        bool isGlobal;
        (success, fromTimestamp, sumOfLastPeriod, daysCovered, dailyTime, endTime, ,isGlobal) = _verifyTransfer(_from, _amount);
        if (fromTimestamp != 0 || dailyTime != 0) {
            _updateStorage(
                _from,
                _amount,
                fromTimestamp,
                sumOfLastPeriod,
                daysCovered,
                dailyTime,
                endTime,
                isGlobal
            );
        }
        return success;
    }

    /**
     * @notice Used to verify the transfer/transferFrom transaction and prevent tranaction
     * whose volume of tokens will voilate the maximum volume transfer restriction
     * @param _from Address of the sender
     * @param _amount The amount of tokens to transfer
     */
    function verifyTransfer(
        address _from,
        address /*_to*/ ,
        uint256 _amount,
        bytes memory /*_data*/
    )
        public
        view
        returns (Result, bytes32)
    {

        (Result success,,,,,,,) = _verifyTransfer(_from, _amount);
        if (success == Result.INVALID)
            return (success, bytes32(uint256(address(this)) << 96));
        return (Result.NA, bytes32(0));
    }

    /**
     * @notice Used to verify the transfer/transferFrom transaction and prevent tranaction
     * whose volume of tokens will voilate the maximum volume transfer restriction
     * @param _from Address of the sender
     * @param _amount The amount of tokens to transfer
     */
    function _verifyTransfer(
        address _from,
        uint256 _amount
    )
        internal
        view
        returns (Result, uint256, uint256, uint256, uint256, uint256, uint256, bool)
    {
        // If `_from` is present in the exemptionList or it is `0x0` address then it will not follow the vol restriction
        if (!paused && _from != address(0) && exemptions.exemptIndex[_from] == 0) {
            // Checking the individual restriction if the `_from` comes in the individual category
            if ((individualRestrictions.individualRestriction[_from].endTime >= now && individualRestrictions.individualRestriction[_from].startTime <= now)
                || (individualRestrictions.individualDailyRestriction[_from].endTime >= now && individualRestrictions.individualDailyRestriction[_from].startTime <= now)) {

                return _restrictionCheck(_amount, _from, false, individualRestrictions.individualRestriction[_from]);
                // If the `_from` doesn't fall under the individual category. It will processed with in the global category automatically
            } else if ((globalRestrictions.defaultRestriction.endTime >= now && globalRestrictions.defaultRestriction.startTime <= now)
                || (globalRestrictions.defaultDailyRestriction.endTime >= now && globalRestrictions.defaultDailyRestriction.startTime <= now)) {

                return _restrictionCheck(_amount, _from, true, globalRestrictions.defaultRestriction);
            }
        }
        return (Result.NA, 0, 0, 0, 0, 0, 0, false);
    }

    /**
     * @notice Add/Remove wallet address from the exempt list
     * @param _wallet Ethereum wallet/contract address that need to be exempted
     * @param _exempted Boolean value used to add (i.e true) or remove (i.e false) from the list
     */
    function changeExemptWalletList(address _wallet, bool _exempted) public withPerm(ADMIN) {
        require(_wallet != address(0));
        require((exemptions.exemptIndex[_wallet] == 0) == _exempted);
        if (_exempted) {
            exemptions.exemptAddresses.push(_wallet);
            exemptions.exemptIndex[_wallet] = exemptions.exemptAddresses.length;
        } else {
            exemptions.exemptAddresses[exemptions.exemptIndex[_wallet] - 1] = exemptions.exemptAddresses[exemptions.exemptAddresses.length - 1];
            exemptions.exemptIndex[exemptions.exemptAddresses[exemptions.exemptIndex[_wallet] - 1]] = exemptions.exemptIndex[_wallet];
            delete exemptions.exemptIndex[_wallet];
            exemptions.exemptAddresses.length--;
        }
        emit ChangedExemptWalletList(_wallet, _exempted);
    }

    /**
     * @notice Use to add the new individual restriction for a given token holder
     * @param _holder Address of the token holder, whom restriction will be implied
     * @param _allowedTokens Amount of tokens allowed to be trade for a given address.
     * @param _startTime Unix timestamp at which restriction get into effect
     * @param _rollingPeriodInDays Rolling period in days (Minimum value should be 1 day)
     * @param _endTime Unix timestamp at which restriction effects will gets end.
     * @param _restrictionType Whether it will be `Fixed` (fixed no. of tokens allowed to transact)
     * or `Percentage` (tokens are calculated as per the totalSupply in the fly).
     */
    function addIndividualRestriction(
        address _holder,
        uint256 _allowedTokens,
        uint256 _startTime,
        uint256 _rollingPeriodInDays,
        uint256 _endTime,
        RestrictionType _restrictionType
    )
        public
        withPerm(ADMIN)
    {
        // It will help to reduce the chances of transaction failure (Specially when the issuer
        // wants to set the startTime near to the current block.timestamp) and minting delayed because
        // of the gas fee or network congestion that lead to the process block timestamp may grater
        // than the given startTime.
        uint256 startTime = _getValidStartTime(_startTime);
        require(_holder != address(0) && exemptions.exemptIndex[_holder] == 0, "Invalid address");
        _checkInputParams(_allowedTokens, startTime, _rollingPeriodInDays, _endTime, _restrictionType, now, false);

        if (individualRestrictions.individualRestriction[_holder].endTime != 0) {
            removeIndividualRestriction(_holder);
        }
        individualRestrictions.individualRestriction[_holder] = VolumeRestriction(
            _allowedTokens,
            startTime,
            _rollingPeriodInDays,
            _endTime,
            _restrictionType
        );
        VolumeRestrictionLib
            .addRestrictionData(
                holderToRestrictionType,
                _holder,
                TypeOfPeriod.MultipleDays,
                individualRestrictions.individualRestriction[_holder].endTime,
                getDataStore()
            );
        emit AddIndividualRestriction(
            _holder,
            _allowedTokens,
            startTime,
            _rollingPeriodInDays,
            _endTime,
            _restrictionType
        );
    }

    /**
     * @notice Use to add the new individual daily restriction for all token holder
     * @param _holder Address of the token holder, whom restriction will be implied
     * @param _allowedTokens Amount of tokens allowed to be traded for all token holder.
     * @param _startTime Unix timestamp at which restriction get into effect
     * @param _endTime Unix timestamp at which restriction effects will gets end.
     * @param _restrictionType Whether it will be `Fixed` (fixed no. of tokens allowed to transact)
     * or `Percentage` (tokens are calculated as per the totalSupply in the fly).
     */
    function addIndividualDailyRestriction(
        address _holder,
        uint256 _allowedTokens,
        uint256 _startTime,
        uint256 _endTime,
        RestrictionType _restrictionType
    )
        public
        withPerm(ADMIN)
    {
        uint256 startTime = _getValidStartTime(_startTime);
        _checkInputParams(_allowedTokens, startTime, 1, _endTime, _restrictionType, now, false);
        if (individualRestrictions.individualDailyRestriction[_holder].endTime != 0) {
            removeIndividualDailyRestriction(_holder);
        }
        individualRestrictions.individualDailyRestriction[_holder] = VolumeRestriction(
            _allowedTokens,
            startTime,
            1,
            _endTime,
            _restrictionType
        );
        VolumeRestrictionLib
            .addRestrictionData(
                holderToRestrictionType,
                _holder,
                TypeOfPeriod.OneDay,
                individualRestrictions.individualRestriction[_holder].endTime,
                getDataStore()
            );
        emit AddIndividualDailyRestriction(
            _holder,
            _allowedTokens,
            startTime,
            1,
            _endTime,
            _restrictionType
        );
    }

    /**
     * @notice Use to add the new individual daily restriction for multiple token holders
     * @param _holders Array of address of the token holders, whom restriction will be implied
     * @param _allowedTokens Array of amount of tokens allowed to be trade for a given address.
     * @param _startTimes Array of unix timestamps at which restrictions get into effect
     * @param _endTimes Array of unix timestamps at which restriction effects will gets end.
     * @param _restrictionTypes Array of restriction types value whether it will be `Fixed` (fixed no. of tokens allowed to transact)
     * or `Percentage` (tokens are calculated as per the totalSupply in the fly).
     */
    function addIndividualDailyRestrictionMulti(
        address[] memory _holders,
        uint256[] memory _allowedTokens,
        uint256[] memory _startTimes,
        uint256[] memory _endTimes,
        RestrictionType[] memory _restrictionTypes
    )
        public
    {
        //NB - we duplicate _startTimes below to allow function reuse
        _checkLengthOfArray(_holders, _allowedTokens, _startTimes, _startTimes, _endTimes, _restrictionTypes);
        for (uint256 i = 0; i < _holders.length; i++) {
            addIndividualDailyRestriction(
                _holders[i],
                _allowedTokens[i],
                _startTimes[i],
                _endTimes[i],
                _restrictionTypes[i]
            );
        }
    }

    /**
     * @notice Use to add the new individual restriction for multiple token holders
     * @param _holders Array of address of the token holders, whom restriction will be implied
     * @param _allowedTokens Array of amount of tokens allowed to be trade for a given address.
     * @param _startTimes Array of unix timestamps at which restrictions get into effect
     * @param _rollingPeriodInDays Array of rolling period in days (Minimum value should be 1 day)
     * @param _endTimes Array of unix timestamps at which restriction effects will gets end.
     * @param _restrictionTypes Array of restriction types value whether it will be `Fixed` (fixed no. of tokens allowed to transact)
     * or `Percentage` (tokens are calculated as per the totalSupply in the fly).
     */
    function addIndividualRestrictionMulti(
        address[] memory _holders,
        uint256[] memory _allowedTokens,
        uint256[] memory _startTimes,
        uint256[] memory _rollingPeriodInDays,
        uint256[] memory _endTimes,
        RestrictionType[] memory _restrictionTypes
    )
        public
    {
        _checkLengthOfArray(_holders, _allowedTokens, _startTimes, _rollingPeriodInDays, _endTimes, _restrictionTypes);
        for (uint256 i = 0; i < _holders.length; i++) {
            addIndividualRestriction(
                _holders[i],
                _allowedTokens[i],
                _startTimes[i],
                _rollingPeriodInDays[i],
                _endTimes[i],
                _restrictionTypes[i]
            );
        }
    }

    /**
     * @notice Use to add the new default restriction for all token holder
     * @param _allowedTokens Amount of tokens allowed to be traded for all token holder.
     * @param _startTime Unix timestamp at which restriction get into effect
     * @param _rollingPeriodInDays Rolling period in days (Minimum value should be 1 day)
     * @param _endTime Unix timestamp at which restriction effects will gets end.
     * @param _restrictionType Whether it will be `Fixed` (fixed no. of tokens allowed to transact)
     * or `Percentage` (tokens are calculated as per the totalSupply in the fly).
     */
    function addDefaultRestriction(
        uint256 _allowedTokens,
        uint256 _startTime,
        uint256 _rollingPeriodInDays,
        uint256 _endTime,
        RestrictionType _restrictionType
    )
        external
        withPerm(ADMIN)
    {
        uint256 startTime = _getValidStartTime(_startTime);
        _checkInputParams(_allowedTokens, startTime, _rollingPeriodInDays, _endTime, _restrictionType, now, false);
        globalRestrictions.defaultRestriction = VolumeRestriction(
            _allowedTokens,
            startTime,
            _rollingPeriodInDays,
            _endTime,
            _restrictionType
        );
        emit AddDefaultRestriction(
            _allowedTokens,
            startTime,
            _rollingPeriodInDays,
            _endTime,
            _restrictionType
        );
    }

    /**
     * @notice Use to add the new default daily restriction for all token holder
     * @param _allowedTokens Amount of tokens allowed to be traded for all token holder.
     * @param _startTime Unix timestamp at which restriction get into effect
     * @param _endTime Unix timestamp at which restriction effects will gets end.
     * @param _restrictionType Whether it will be `Fixed` (fixed no. of tokens allowed to transact)
     * or `Percentage` (tokens are calculated as per the totalSupply in the fly).
     */
    function addDefaultDailyRestriction(
        uint256 _allowedTokens,
        uint256 _startTime,
        uint256 _endTime,
        RestrictionType _restrictionType
    )
        external
        withPerm(ADMIN)
    {
        uint256 startTime = _getValidStartTime(_startTime);
        _checkInputParams(_allowedTokens, startTime, 1, _endTime, _restrictionType, now, false);
        globalRestrictions.defaultDailyRestriction = VolumeRestriction(
            _allowedTokens,
            startTime,
            1,
            _endTime,
            _restrictionType
        );
        emit AddDefaultDailyRestriction(
            _allowedTokens,
            startTime,
            1,
            _endTime,
            _restrictionType
        );
    }

    /**
     * @notice use to remove the individual restriction for a given address
     * @param _holder Address of the user
     */
    function removeIndividualRestriction(address _holder) public withPerm(ADMIN) {
        _removeIndividualRestriction(_holder);
    }

    function _removeIndividualRestriction(address _holder) internal {
        require(_holder != address(0));
        require(individualRestrictions.individualRestriction[_holder].endTime != 0);
        individualRestrictions.individualRestriction[_holder] = VolumeRestriction(0, 0, 0, 0, RestrictionType(0));
        VolumeRestrictionLib.deleteHolderFromList(holderToRestrictionType, _holder, getDataStore(), TypeOfPeriod.OneDay);
        bucketData.userToBucket[_holder].lastTradedDayTime = 0;
        bucketData.userToBucket[_holder].sumOfLastPeriod = 0;
        bucketData.userToBucket[_holder].daysCovered = 0;
        emit IndividualRestrictionRemoved(_holder);
    }

    /**
     * @notice use to remove the individual restriction for a given address
     * @param _holders Array of address of the user
     */
    function removeIndividualRestrictionMulti(address[] memory _holders) public withPerm(ADMIN) {
        for (uint256 i = 0; i < _holders.length; i++) {
            _removeIndividualRestriction(_holders[i]);
        }
    }

    /**
     * @notice use to remove the individual daily restriction for a given address
     * @param _holder Address of the user
     */
    function removeIndividualDailyRestriction(address _holder) public withPerm(ADMIN) {
        _removeIndividualDailyRestriction(_holder);
    }

    function _removeIndividualDailyRestriction(address _holder) internal {
        require(_holder != address(0));
        require(individualRestrictions.individualDailyRestriction[_holder].endTime != 0);
        individualRestrictions.individualDailyRestriction[_holder] = VolumeRestriction(0, 0, 0, 0, RestrictionType(0));
        VolumeRestrictionLib.deleteHolderFromList(holderToRestrictionType, _holder, getDataStore(), TypeOfPeriod.MultipleDays);
        bucketData.userToBucket[_holder].dailyLastTradedDayTime = 0;
        emit IndividualDailyRestrictionRemoved(_holder);
    }

    /**
     * @notice use to remove the individual daily restriction for a given address
     * @param _holders Array of address of the user
     */
    function removeIndividualDailyRestrictionMulti(address[] memory _holders) public withPerm(ADMIN) {
        for (uint256 i = 0; i < _holders.length; i++) {
            _removeIndividualDailyRestriction(_holders[i]);
        }
    }

    /**
     * @notice Use to remove the default restriction
     */
    function removeDefaultRestriction() public withPerm(ADMIN) {
        require(globalRestrictions.defaultRestriction.endTime != 0);
        globalRestrictions.defaultRestriction = VolumeRestriction(0, 0, 0, 0, RestrictionType(0));
        emit DefaultRestrictionRemoved();
    }

    /**
     * @notice Use to remove the daily default restriction
     */
    function removeDefaultDailyRestriction() external withPerm(ADMIN) {
        require(globalRestrictions.defaultDailyRestriction.endTime != 0);
        globalRestrictions.defaultDailyRestriction = VolumeRestriction(0, 0, 0, 0, RestrictionType(0));
        emit DefaultDailyRestrictionRemoved();
    }

    /**
     * @notice Use to modify the existing individual restriction for a given token holder
     * @param _holder Address of the token holder, whom restriction will be implied
     * @param _allowedTokens Amount of tokens allowed to be trade for a given address.
     * @param _startTime Unix timestamp at which restriction get into effect
     * @param _rollingPeriodInDays Rolling period in days (Minimum value should be 1 day)
     * @param _endTime Unix timestamp at which restriction effects will gets end.
     * @param _restrictionType Whether it will be `Fixed` (fixed no. of tokens allowed to transact)
     * or `Percentage` (tokens are calculated as per the totalSupply in the fly).
     */
    function modifyIndividualRestriction(
        address _holder,
        uint256 _allowedTokens,
        uint256 _startTime,
        uint256 _rollingPeriodInDays,
        uint256 _endTime,
        RestrictionType _restrictionType
    )
        public
        withPerm(ADMIN)
    {
        _isAllowedToModify(individualRestrictions.individualRestriction[_holder].startTime);
        uint256 startTime = _getValidStartTime(_startTime);
        _checkInputParams(_allowedTokens, startTime, _rollingPeriodInDays, _endTime, _restrictionType, now, false);
        individualRestrictions.individualRestriction[_holder] = VolumeRestriction(
            _allowedTokens,
            startTime,
            _rollingPeriodInDays,
            _endTime,
            _restrictionType
        );
        emit ModifyIndividualRestriction(
            _holder,
            _allowedTokens,
            startTime,
            _rollingPeriodInDays,
            _endTime,
            _restrictionType
      );
    }

    /**
     * @notice Use to modify the existing individual daily restriction for a given token holder
     * @dev Changing of startTime will affect the 24 hrs span. i.e if in earlier restriction days start with
     * morning and end on midnight while after the change day may start with afternoon and end with other day afternoon
     * @param _holder Address of the token holder, whom restriction will be implied
     * @param _allowedTokens Amount of tokens allowed to be trade for a given address.
     * @param _startTime Unix timestamp at which restriction get into effect
     * @param _endTime Unix timestamp at which restriction effects will gets end.
     * @param _restrictionType Whether it will be `Fixed` (fixed no. of tokens allowed to transact)
     * or `Percentage` (tokens are calculated as per the totalSupply in the fly).
     */
    function modifyIndividualDailyRestriction(
        address _holder,
        uint256 _allowedTokens,
        uint256 _startTime,
        uint256 _endTime,
        RestrictionType _restrictionType
    )
        public
        withPerm(ADMIN)
    {
        uint256 startTime = _getValidStartTime(_startTime);
        uint256 checkTime = (individualRestrictions.individualDailyRestriction[_holder].startTime <= now ? individualRestrictions.individualDailyRestriction[_holder].startTime : now);
        _checkInputParams(_allowedTokens, startTime, 1, _endTime, _restrictionType, checkTime, true);
        individualRestrictions.individualDailyRestriction[_holder] = VolumeRestriction(
            _allowedTokens,
            startTime,
            1,
            _endTime,
            _restrictionType
        );
        emit ModifyIndividualDailyRestriction(
            _holder,
            _allowedTokens,
            startTime,
            1,
            _endTime,
            _restrictionType
        );
    }

    /**
     * @notice Use to modify the existing individual daily restriction for multiple token holders
     * @param _holders Array of address of the token holders, whom restriction will be implied
     * @param _allowedTokens Array of amount of tokens allowed to be trade for a given address.
     * @param _startTimes Array of unix timestamps at which restrictions get into effect
     * @param _endTimes Array of unix timestamps at which restriction effects will gets end.
     * @param _restrictionTypes Array of restriction types value whether it will be `Fixed` (fixed no. of tokens allowed to transact)
     * or `Percentage` (tokens are calculated as per the totalSupply in the fly).
     */
    function modifyIndividualDailyRestrictionMulti(
        address[] memory _holders,
        uint256[] memory _allowedTokens,
        uint256[] memory _startTimes,
        uint256[] memory _endTimes,
        RestrictionType[] memory _restrictionTypes
    )
        public
    {
        //NB - we duplicate _startTimes below to allow function reuse
        _checkLengthOfArray(_holders, _allowedTokens, _startTimes, _startTimes, _endTimes, _restrictionTypes);
        for (uint256 i = 0; i < _holders.length; i++) {
            modifyIndividualDailyRestriction(
                _holders[i],
                _allowedTokens[i],
                _startTimes[i],
                _endTimes[i],
                _restrictionTypes[i]
            );
        }
    }

    /**
     * @notice Use to modify the existing individual restriction for multiple token holders
     * @param _holders Array of address of the token holders, whom restriction will be implied
     * @param _allowedTokens Array of amount of tokens allowed to be trade for a given address.
     * @param _startTimes Array of unix timestamps at which restrictions get into effect
     * @param _rollingPeriodInDays Array of rolling period in days (Minimum value should be 1 day)
     * @param _endTimes Array of unix timestamps at which restriction effects will gets end.
     * @param _restrictionTypes Array of restriction types value whether it will be `Fixed` (fixed no. of tokens allowed to transact)
     * or `Percentage` (tokens are calculated as per the totalSupply in the fly).
     */
    function modifyIndividualRestrictionMulti(
        address[] memory _holders,
        uint256[] memory _allowedTokens,
        uint256[] memory _startTimes,
        uint256[] memory _rollingPeriodInDays,
        uint256[] memory _endTimes,
        RestrictionType[] memory _restrictionTypes
    )
        public
    {
        _checkLengthOfArray(_holders, _allowedTokens, _startTimes, _rollingPeriodInDays, _endTimes, _restrictionTypes);
        for (uint256 i = 0; i < _holders.length; i++) {
            modifyIndividualRestriction(
                _holders[i],
                _allowedTokens[i],
                _startTimes[i],
                _rollingPeriodInDays[i],
                _endTimes[i],
                _restrictionTypes[i]
            );
        }
    }

    /**
     * @notice Use to modify the global restriction for all token holder
     * @param _allowedTokens Amount of tokens allowed to be traded for all token holder.
     * @param _startTime Unix timestamp at which restriction get into effect
     * @param _rollingPeriodInDays Rolling period in days (Minimum value should be 1 day)
     * @param _endTime Unix timestamp at which restriction effects will gets end.
     * @param _restrictionType Whether it will be `Fixed` (fixed no. of tokens allowed to transact)
     * or `Percentage` (tokens are calculated as per the totalSupply in the fly).
     */
    function modifyDefaultRestriction(
        uint256 _allowedTokens,
        uint256 _startTime,
        uint256 _rollingPeriodInDays,
        uint256 _endTime,
        RestrictionType _restrictionType
    )
        external
        withPerm(ADMIN)
    {
        _isAllowedToModify(globalRestrictions.defaultRestriction.startTime);
        uint256 startTime = _getValidStartTime(_startTime);
        _checkInputParams(_allowedTokens, startTime, _rollingPeriodInDays, _endTime, _restrictionType, now, false);
        globalRestrictions.defaultRestriction = VolumeRestriction(
            _allowedTokens,
            startTime,
            _rollingPeriodInDays,
            _endTime,
            _restrictionType
        );
        emit ModifyDefaultRestriction(
            _allowedTokens,
            startTime,
            _rollingPeriodInDays,
            _endTime,
            _restrictionType
        );
    }

    /**
     * @notice Use to modify the daily default restriction for all token holder
     * @dev Changing of startTime will affect the 24 hrs span. i.e if in earlier restriction days start with
     * morning and end on midnight while after the change day may start with afternoon and end with other day afternoon.
     * @param _allowedTokens Amount of tokens allowed to be traded for all token holder.
     * @param _startTime Unix timestamp at which restriction get into effect
     * @param _endTime Unix timestamp at which restriction effects will gets end.
     * @param _restrictionType Whether it will be `Fixed` (fixed no. of tokens allowed to transact)
     * or `Percentage` (tokens are calculated as per the totalSupply in the fly).
     */
    function modifyDefaultDailyRestriction(
        uint256 _allowedTokens,
        uint256 _startTime,
        uint256 _endTime,
        RestrictionType _restrictionType
    )
        external
        withPerm(ADMIN)
    {
        uint256 startTime = _getValidStartTime(_startTime);
        // If old startTime is already passed then new startTime should be greater than or equal to the
        // old startTime otherwise any past startTime can be allowed in compare to earlier startTime.
        _checkInputParams(_allowedTokens, startTime, 1, _endTime, _restrictionType,
            (globalRestrictions.defaultDailyRestriction.startTime <= now ? globalRestrictions.defaultDailyRestriction.startTime : now),
            true
        );
        globalRestrictions.defaultDailyRestriction = VolumeRestriction(
            _allowedTokens,
            startTime,
            1,
            _endTime,
            _restrictionType
        );
        emit ModifyDefaultDailyRestriction(
            _allowedTokens,
            startTime,
            1,
            _endTime,
            _restrictionType
        );
    }

    /**
    * @notice Internal function used to validate the transaction for a given address
    * If it validates then it also update the storage corressponds to the default restriction
    */
    function _restrictionCheck(
        uint256 _amount,
        address _from,
        bool _isDefault,
        VolumeRestriction memory _restriction
    )
        internal
        view
        returns (
        Result success,
        uint256 fromTimestamp,
        uint256 sumOfLastPeriod,
        uint256 daysCovered,
        uint256 dailyTime,
        uint256 endTime,
        uint256 allowedAmountToTransact,
        bool allowedDaily
    ) {
        // using the variable to avoid stack too deep error
        VolumeRestriction memory dailyRestriction = _isDefault ? globalRestrictions.defaultDailyRestriction :individualRestrictions.individualDailyRestriction[_from];
        BucketDetails memory _bucketDetails = _isDefault ? bucketData.defaultUserToBucket[_from]: bucketData.userToBucket[_from];
        daysCovered = _restriction.rollingPeriodInDays;
        // This variable works for both allowedDefault or allowedIndividual
        bool allowedDefault = true;
        if (_restriction.endTime >= now && _restriction.startTime <= now) {
            if (_bucketDetails.lastTradedDayTime < _restriction.startTime) {
                // It will execute when the txn is performed first time after the addition of individual restriction
                fromTimestamp = _restriction.startTime;
            } else {
                // Picking up the last timestamp
                fromTimestamp = _bucketDetails.lastTradedDayTime;
            }

            // Check with the bucket and parse all the new timestamps to calculate the sumOfLastPeriod
            // re-using the local variables to avoid the stack too deep error.
            (sumOfLastPeriod, fromTimestamp, daysCovered) = _bucketCheck(
                _from,
                _isDefault,
                fromTimestamp,
                BokkyPooBahsDateTimeLibrary.diffDays(fromTimestamp, now),

                daysCovered,
                _bucketDetails
            );
            // validation of the transaction amount
            // reusing the local variable to avoid stack too deep error
            // here variable allowedAmountToTransact is representing the allowedAmount
            (allowedDefault, allowedAmountToTransact) = _checkValidAmountToTransact(_amount, _from, _isDefault, _restriction, sumOfLastPeriod);
            if (!allowedDefault) {
                allowedDefault = false;
            }
        }

        // reusing the local variable to avoid stack too deep error
        // here variable endTime is representing the allowedDailyAmount
        (allowedDaily, dailyTime, endTime) = _dailyTxCheck(_amount, _from, _isDefault, _bucketDetails.dailyLastTradedDayTime, dailyRestriction);
        success = ((allowedDaily && allowedDefault) == true ? Result.NA : Result.INVALID);
        allowedAmountToTransact = _validAllowedAmount(dailyRestriction, _restriction, allowedAmountToTransact, endTime);
        endTime = dailyRestriction.endTime;
        allowedDaily = _isDefault;
    }

    function _validAllowedAmount(
        VolumeRestriction memory dailyRestriction,
        VolumeRestriction memory restriction,
        uint256 allowedAmount,
        uint256 allowedDailyAmount
    )
        internal
        view
        returns (uint256)
    {
        if (now > dailyRestriction.endTime || now < dailyRestriction.startTime)
            return allowedAmount;
        else if (now > restriction.endTime || now < restriction.startTime)
            return allowedDailyAmount;
        else
            return Math.min(allowedDailyAmount, allowedAmount);
    }

    /**
     * @notice The function is used to check specific edge case where the user restriction type change from
     * default to individual or vice versa. It will return true when last transaction traded by the user
     * and the current txn timestamp lies in the same day.
     * NB - Instead of comparing the current day transaction amount, we are comparing the total amount traded
     * on the lastTradedDayTime that makes the restriction strict. The reason is not availability of amount
     * that transacted on the current day (because of bucket desgin).
     */
    function _isValidAmountAfterRestrictionChanges(
        bool _isDefault,
        address _from,
        uint256 _amount,
        uint256 _sumOfLastPeriod,
        uint256 _allowedAmount
    )
        internal
        view
        returns(bool)
    {
        // Always use the alternate bucket details as per the current transaction restriction
        BucketDetails storage bucketDetails = _isDefault ? bucketData.userToBucket[_from] : bucketData.defaultUserToBucket[_from];
        uint256 amountTradedLastDay = _isDefault ? bucketData.bucket[_from][bucketDetails.lastTradedDayTime]: bucketData.defaultBucket[_from][bucketDetails.lastTradedDayTime];
        return VolumeRestrictionLib.isValidAmountAfterRestrictionChanges(
            amountTradedLastDay,
            _amount,
            _sumOfLastPeriod,
            _allowedAmount,
            bucketDetails.lastTradedTimestamp
        );
    }

    function _dailyTxCheck(
        uint256 _amount,
        address _from,
        bool _isDefault,
        uint256 _dailyLastTradedDayTime,
        VolumeRestriction memory _restriction
    )
        internal
        view
        returns(bool, uint256, uint256)
    {
        // Checking whether the daily restriction is added or not if yes then calculate
        // the total amount get traded on a particular day (~ _fromTime)
        if ( now <= _restriction.endTime && now >= _restriction.startTime) {
            uint256 txSumOfDay = 0;
            if (_dailyLastTradedDayTime == 0 || _dailyLastTradedDayTime < _restriction.startTime)
                // This if condition will be executed when the individual daily restriction executed first time
                _dailyLastTradedDayTime = _restriction.startTime.add(BokkyPooBahsDateTimeLibrary.diffDays(_restriction.startTime, now).mul(1 days));
            else if (now.sub(_dailyLastTradedDayTime) >= 1 days)
                _dailyLastTradedDayTime = _dailyLastTradedDayTime.add(BokkyPooBahsDateTimeLibrary.diffDays(_dailyLastTradedDayTime, now).mul(1 days));
            // Assgining total sum traded on dailyLastTradedDayTime timestamp
            if (_isDefault)
                txSumOfDay = bucketData.defaultBucket[_from][_dailyLastTradedDayTime];
            else
                txSumOfDay = bucketData.bucket[_from][_dailyLastTradedDayTime];
            (bool isAllowed, uint256 allowedAmount) = _checkValidAmountToTransact(_amount, _from, _isDefault, _restriction, txSumOfDay);
            return (isAllowed, _dailyLastTradedDayTime, allowedAmount);
        }
        return (true, _dailyLastTradedDayTime, _amount);
    }

    /// Internal function for the bucket check
    function _bucketCheck(
        address _from,
        bool isDefault,
        uint256 _fromTime,
        uint256 _diffDays,
        uint256 _rollingPeriodInDays,
        BucketDetails memory _bucketDetails
    )
        internal
        view
        returns (uint256, uint256, uint256)
    {
        uint256 counter = _bucketDetails.daysCovered;
        uint256 sumOfLastPeriod = _bucketDetails.sumOfLastPeriod;
        uint256 i = 0;
        if (_diffDays >= _rollingPeriodInDays) {
            // If the difference of days is greater than the rollingPeriod then sumOfLastPeriod will always be zero
            sumOfLastPeriod = 0;
            counter = counter.add(_diffDays);
        } else {
            for (i = 0; i < _diffDays; i++) {
                counter++;
                // This condition is to check whether the first rolling period is covered or not
                // if not then it continues and adding 0 value into sumOfLastPeriod without subtracting
                // the earlier value at that index
                if (counter >= _rollingPeriodInDays) {
                    // Subtracting the former value(Sum of all the txn amount of that day) from the sumOfLastPeriod
                    // The below line subtracts (the traded volume on days no longer covered by rolling period) from sumOfLastPeriod.
                    // Every loop execution subtracts one day's trade volume.
                    // Loop starts from the first day covered in sumOfLastPeriod upto the day that is covered by rolling period.
                    uint256 temp = _bucketDetails.daysCovered.sub(counter.sub(_rollingPeriodInDays));
                    temp = _bucketDetails.lastTradedDayTime.sub(temp.mul(1 days));
                    if (isDefault)
                        sumOfLastPeriod = sumOfLastPeriod.sub(bucketData.defaultBucket[_from][temp]);
                    else
                        sumOfLastPeriod = sumOfLastPeriod.sub(bucketData.bucket[_from][temp]);
                }
                // Adding the last amount that is transacted on the `_fromTime` not actually doing it but left written to understand
                // the alogrithm
                //_bucketDetails.sumOfLastPeriod = _bucketDetails.sumOfLastPeriod.add(uint256(0));
            }
        }
        // calculating the timestamp that will used as an index of the next bucket
        // i.e buckets period will be look like this T1 to T2-1, T2 to T3-1 ....
        // where T1,T2,T3 are timestamps having 24 hrs difference
        _fromTime = _fromTime.add(_diffDays.mul(1 days));
        return (sumOfLastPeriod, _fromTime, counter);
    }

    function _checkValidAmountToTransact(
        uint256 _amountToTransact,
        address _from,
        bool _isDefault,
        VolumeRestriction memory _restriction,
        uint256 _sumOfLastPeriod
    )
        internal
        view
        returns (bool, uint256)
    {
        uint256 allowedAmount = _allowedAmountToTransact(_sumOfLastPeriod, _restriction);
        // Validation on the amount to transact
        bool allowed = allowedAmount >= _amountToTransact;
        return ((allowed && _isValidAmountAfterRestrictionChanges(_isDefault, _from, _amountToTransact, _sumOfLastPeriod, allowedAmount)), allowedAmount);
    }

    function _allowedAmountToTransact(
        uint256 _sumOfLastPeriod,
        VolumeRestriction memory _restriction
    )
        internal
        view
        returns (uint256)
    {
        uint256 _allowedAmount = 0;
        if (_restriction.typeOfRestriction == RestrictionType.Percentage) {
            _allowedAmount = (_restriction.allowedTokens.mul(securityToken.totalSupply())) / uint256(10) ** 18;
        } else {
            _allowedAmount = _restriction.allowedTokens;
        }
        return _allowedAmount.sub(_sumOfLastPeriod);
    }

    function _updateStorage(
        address _from,
        uint256 _amount,
        uint256 _lastTradedDayTime,
        uint256 _sumOfLastPeriod,
        uint256 _daysCovered,
        uint256 _dailyLastTradedDayTime,
        uint256 _endTime,
        bool isDefault
    )
        internal
    {

        if (isDefault){
            BucketDetails storage defaultUserToBucketDetails = bucketData.defaultUserToBucket[_from];
            _updateStorageActual(_from, _amount, _lastTradedDayTime, _sumOfLastPeriod, _daysCovered, _dailyLastTradedDayTime, _endTime, true,  defaultUserToBucketDetails);
        }
        else {
            BucketDetails storage userToBucketDetails = bucketData.userToBucket[_from];
            _updateStorageActual(_from, _amount, _lastTradedDayTime, _sumOfLastPeriod, _daysCovered, _dailyLastTradedDayTime, _endTime, false, userToBucketDetails);
        }
    }

    function _updateStorageActual(
        address _from,
        uint256 _amount,
        uint256 _lastTradedDayTime,
        uint256 _sumOfLastPeriod,
        uint256 _daysCovered,
        uint256 _dailyLastTradedDayTime,
        uint256 _endTime,
        bool isDefault,
        BucketDetails storage details
    )
        internal
    {
        // Cheap storage technique
        if (details.lastTradedDayTime != _lastTradedDayTime) {
            // Assigning the latest transaction timestamp of the day
            details.lastTradedDayTime = _lastTradedDayTime;
        }
        if (details.dailyLastTradedDayTime != _dailyLastTradedDayTime) {
            // Assigning the latest transaction timestamp of the day
            details.dailyLastTradedDayTime = _dailyLastTradedDayTime;
        }
        if (details.daysCovered != _daysCovered) {
            details.daysCovered = _daysCovered;
        }
        // Assigning the latest transaction timestamp
        details.lastTradedTimestamp = now;

        if (_amount != 0) {
            if (_lastTradedDayTime !=0) {
                details.sumOfLastPeriod = _sumOfLastPeriod.add(_amount);
                // Increasing the total amount of the day by `_amount`
                if (isDefault)
                    bucketData.defaultBucket[_from][_lastTradedDayTime] = bucketData.defaultBucket[_from][_lastTradedDayTime].add(_amount);
                else
                    bucketData.bucket[_from][_lastTradedDayTime] = bucketData.bucket[_from][_lastTradedDayTime].add(_amount);
            }
            if ((_dailyLastTradedDayTime != _lastTradedDayTime) && _dailyLastTradedDayTime != 0 && now <= _endTime) {
                // Increasing the total amount of the day by `_amount`
                if (isDefault)
                    bucketData.defaultBucket[_from][_dailyLastTradedDayTime] = bucketData.defaultBucket[_from][_dailyLastTradedDayTime].add(_amount);
                else
                    bucketData.bucket[_from][_dailyLastTradedDayTime] = bucketData.bucket[_from][_dailyLastTradedDayTime].add(_amount);
            }
        }
    }

    function _checkInputParams(
        uint256 _allowedTokens,
        uint256 _startTime,
        uint256 _rollingPeriodDays,
        uint256 _endTime,
        RestrictionType _restrictionType,
        uint256 _earliestStartTime,
        bool isModifyDaily
    )
        internal
        pure
    {
        if (isModifyDaily)
            require(_startTime >= _earliestStartTime, "Invalid startTime");
        else
            require(_startTime > _earliestStartTime, "Invalid startTime");
        require(_allowedTokens > 0);
        if (_restrictionType != RestrictionType.Fixed) {
            require(_allowedTokens <= 100 * 10 ** 16, "Invalid value");
        }
        // Maximum limit for the rollingPeriod is 365 days
        require(_rollingPeriodDays >= 1 && _rollingPeriodDays <= 365, "Invalid rollingperiod");
        require(
            BokkyPooBahsDateTimeLibrary.diffDays(_startTime, _endTime) >= _rollingPeriodDays,
            "Invalid times"
        );
    }

    function _isAllowedToModify(uint256 _startTime) internal view {
        require(_startTime > now);
    }

    function _getValidStartTime(uint256 _startTime) internal view returns(uint256) {
        if (_startTime == 0)
            _startTime = now + 1;
        return _startTime;
    }

    /**
     * @notice return the amount of tokens for a given user as per the partition
     * @param _partition Identifier
     * @param _tokenHolder Whom token amount need to query
     * @param _additionalBalance It is the `_value` that transfer during transfer/transferFrom function call
     */
    function getTokensByPartition(bytes32 _partition, address _tokenHolder, uint256 _additionalBalance) external view returns(uint256) {
        uint256 allowedAmountToTransact;
        uint256 fromTimestamp;
        uint256 dailyTime;
        uint256 currentBalance = (msg.sender == address(securityToken)) ? (securityToken.balanceOf(_tokenHolder)).add(_additionalBalance) : securityToken.balanceOf(_tokenHolder);
        if (paused)
            return (_partition == UNLOCKED ? currentBalance: 0);

        (,fromTimestamp,,,dailyTime,,allowedAmountToTransact,) = _verifyTransfer(_tokenHolder, 0);
        if (_partition == LOCKED) {
            if (allowedAmountToTransact == 0 && fromTimestamp == 0 && dailyTime == 0)
                return 0;
            else if (allowedAmountToTransact == 0)
                return currentBalance;
            else
                return (currentBalance.sub(allowedAmountToTransact));
        }
        else if (_partition == UNLOCKED) {
            if (allowedAmountToTransact == 0 && fromTimestamp == 0 && dailyTime == 0)
                return currentBalance;
            else if (allowedAmountToTransact == 0)
                return 0;
            else
                return allowedAmountToTransact;
        }
    }

    /**
     * @notice Use to get the bucket details for a given address
     * @param _user Address of the token holder for whom the bucket details has queried
     * @return uint256 lastTradedDayTime
     * @return uint256 sumOfLastPeriod
     * @return uint256 days covered
     * @return uint256 24h lastTradedDayTime
     * @return uint256 Timestamp at which last transaction get executed
     */
    function getIndividualBucketDetailsToUser(address _user) public view returns(uint256, uint256, uint256, uint256, uint256) {
        return _getBucketDetails(bucketData.userToBucket[_user]);
    }

    /**
     * @notice Use to get the bucket details for a given address
     * @param _user Address of the token holder for whom the bucket details has queried
     * @return uint256 lastTradedDayTime
     * @return uint256 sumOfLastPeriod
     * @return uint256 days covered
     * @return uint256 24h lastTradedDayTime
     * @return uint256 Timestamp at which last transaction get executed
     */
    function getDefaultBucketDetailsToUser(address _user) public view returns(uint256, uint256, uint256, uint256, uint256) {
        return _getBucketDetails(bucketData.defaultUserToBucket[_user]);
    }

    function _getBucketDetails(BucketDetails storage _bucket) internal view returns(
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    ) {
        return(
            _bucket.lastTradedDayTime,
            _bucket.sumOfLastPeriod,
            _bucket.daysCovered,
            _bucket.dailyLastTradedDayTime,
            _bucket.lastTradedTimestamp
        );
    }

    /**
     * @notice Use to get the volume of token that being traded at a particular day (`_at` + 24 hours) for a given user
     * @param _user Address of the token holder
     * @param _at Timestamp
     */
    function getTotalTradedByUser(address _user, uint256 _at) external view returns(uint256) {
        return (bucketData.bucket[_user][_at].add(bucketData.defaultBucket[_user][_at]));
    }

    /**
     * @notice This function returns the signature of configure function
     */
    function getInitFunction() public pure returns(bytes4) {
        return bytes4(0);
    }

    /**
     * @notice Use to return the list of exempted addresses
     */
    function getExemptAddress() external view returns(address[] memory) {
        return exemptions.exemptAddresses;
    }

    function getIndividualRestriction(address _investor) external view returns(uint256, uint256, uint256, uint256, RestrictionType) {
        return _volumeRestrictionSplay(individualRestrictions.individualRestriction[_investor]);
    }

    function getIndividualDailyRestriction(address _investor) external view returns(uint256, uint256, uint256, uint256, RestrictionType) {
        return _volumeRestrictionSplay(individualRestrictions.individualDailyRestriction[_investor]);
    }

    function getDefaultRestriction() external view returns(uint256, uint256, uint256, uint256, RestrictionType) {
        return _volumeRestrictionSplay(globalRestrictions.defaultRestriction);
    }

    function getDefaultDailyRestriction() external view returns(uint256, uint256, uint256, uint256, RestrictionType) {
        return _volumeRestrictionSplay(globalRestrictions.defaultDailyRestriction);
    }

    function _volumeRestrictionSplay(VolumeRestriction memory _volumeRestriction) internal pure returns(uint256, uint256, uint256, uint256, RestrictionType) {
        return (
            _volumeRestriction.allowedTokens,
            _volumeRestriction.startTime,
            _volumeRestriction.rollingPeriodInDays,
            _volumeRestriction.endTime,
            _volumeRestriction.typeOfRestriction
        );
    }

    /**
     * @notice Provide the restriction details of all the restricted addresses
     * @return address List of the restricted addresses
     * @return uint256 List of the tokens allowed to the restricted addresses corresponds to restricted address
     * @return uint256 List of the start time of the restriction corresponds to restricted address
     * @return uint256 List of the rolling period in days for a restriction corresponds to restricted address.
     * @return uint256 List of the end time of the restriction corresponds to restricted address.
     * @return uint8 List of the type of restriction to validate the value of the `allowedTokens`
     * of the restriction corresponds to restricted address
     */
    function getRestrictionData() external view returns(
        address[] memory allAddresses,
        uint256[] memory allowedTokens,
        uint256[] memory startTime,
        uint256[] memory rollingPeriodInDays,
        uint256[] memory endTime,
        RestrictionType[] memory typeOfRestriction
    ) {
        return VolumeRestrictionLib.getRestrictionData(holderToRestrictionType, individualRestrictions, getDataStore());
    }

    function _checkLengthOfArray(
        address[] memory _holders,
        uint256[] memory _allowedTokens,
        uint256[] memory _startTimes,
        uint256[] memory _rollingPeriodInDays,
        uint256[] memory _endTimes,
        RestrictionType[] memory _restrictionTypes
    )
        internal
        pure
    {
        require(
            _holders.length == _allowedTokens.length &&
            _allowedTokens.length == _startTimes.length &&
            _startTimes.length == _rollingPeriodInDays.length &&
            _rollingPeriodInDays.length == _endTimes.length &&
            _endTimes.length == _restrictionTypes.length,
            "Length mismatch"
        );
    }

    /**
     * @notice Returns the permissions flag that are associated with Percentage transfer Manager
     */
    function getPermissions() public view returns(bytes32[] memory allPermissions) {
        allPermissions = new bytes32[](1);
        allPermissions[0] = ADMIN;
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

/**
 * @title Storage layout for VolumeRestrictionTM
 */
contract VolumeRestrictionTMStorage {

    enum RestrictionType { Fixed, Percentage }

    enum TypeOfPeriod { MultipleDays, OneDay, Both }

    // Store the type of restriction corresponds to token holder address
    mapping(address => TypeOfPeriod) holderToRestrictionType;

    struct VolumeRestriction {
        // If typeOfRestriction is `Percentage` then allowedTokens will be in
        // the % (w.r.t to totalSupply) with a multiplier of 10**16 . else it
        // will be fixed amount of tokens
        uint256 allowedTokens;
        uint256 startTime;
        uint256 rollingPeriodInDays;
        uint256 endTime;
        RestrictionType typeOfRestriction;
    }

    struct IndividualRestrictions {
        // Restriction stored corresponds to a particular token holder
        mapping(address => VolumeRestriction) individualRestriction;
        // Daily restriction stored corresponds to a particular token holder
        mapping(address => VolumeRestriction) individualDailyRestriction;
    }

    // Individual and daily restrictions for investors
    IndividualRestrictions individualRestrictions;

    struct GlobalRestrictions {
      // Global restriction that applies to all token holders
      VolumeRestriction defaultRestriction;
      // Daily global restriction that applies to all token holders (Total ST traded daily is restricted)
      VolumeRestriction defaultDailyRestriction;
    }

    // Individual and daily restrictions for investors
    GlobalRestrictions globalRestrictions;

    struct BucketDetails {
        uint256 lastTradedDayTime;
        uint256 sumOfLastPeriod;   // It is the sum of transacted amount within the last rollingPeriodDays
        uint256 daysCovered;    // No of days covered till (from the startTime of VolumeRestriction)
        uint256 dailyLastTradedDayTime;
        uint256 lastTradedTimestamp; // It is the timestamp at which last transaction get executed
    }

    struct BucketData {
        // Storing _from => day's timestamp => total amount transact in a day --individual
        mapping(address => mapping(uint256 => uint256)) bucket;
        // Storing _from => day's timestamp => total amount transact in a day --individual
        mapping(address => mapping(uint256 => uint256)) defaultBucket;
        // Storing the information that used to validate the transaction
        mapping(address => BucketDetails) userToBucket;
        // Storing the information related to default restriction
        mapping(address => BucketDetails) defaultUserToBucket;
    }

    BucketData bucketData;

    // Hold exempt index
    struct Exemptions {
        mapping(address => uint256) exemptIndex;
        address[] exemptAddresses;
    }

    Exemptions exemptions;

}

pragma solidity 0.5.8;

import "../Module.sol";
import "../../interfaces/ITransferManager.sol";

/**
 * @title Base abstract contract to be implemented by all Transfer Manager modules
 */
contract TransferManager is ITransferManager, Module {

    bytes32 public constant LOCKED = "LOCKED";
    bytes32 public constant UNLOCKED = "UNLOCKED";

    modifier onlySecurityToken() {
        require(msg.sender == address(securityToken), "Sender is not owner");
        _;
    }

    // Provide default versions of ERC1410 functions that can be overriden

    /**
     * @notice return the amount of tokens for a given user as per the partition
     * @dev returning the balance of token holder against the UNLOCKED partition. 
     * This condition is valid only when the base contract doesn't implement the
     * `getTokensByPartition()` function.  
     */
    function getTokensByPartition(bytes32 _partition, address _tokenHolder, uint256 /*_additionalBalance*/) external view returns(uint256) {
        if (_partition == UNLOCKED)
            return securityToken.balanceOf(_tokenHolder);
        return uint256(0);
    }

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

import "../interfaces/IDataStore.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../modules/TransferManager/VRTM/VolumeRestrictionTMStorage.sol";

library VolumeRestrictionLib {

    using SafeMath for uint256;

    uint256 internal constant ONE = uint256(1);
    uint8 internal constant INDEX = uint8(2);
    bytes32 internal constant INVESTORFLAGS = "INVESTORFLAGS";
    bytes32 internal constant INVESTORSKEY = 0xdf3a8dd24acdd05addfc6aeffef7574d2de3f844535ec91e8e0f3e45dba96731; //keccak256(abi.encodePacked("INVESTORS"))
    bytes32 internal constant WHITELIST = "WHITELIST";


    function deleteHolderFromList(
        mapping(address => VolumeRestrictionTMStorage.TypeOfPeriod) storage _holderToRestrictionType,
        address _holder,
        IDataStore _dataStore,
        VolumeRestrictionTMStorage.TypeOfPeriod _typeOfPeriod
    )
        public
    {
        // Deleting the holder if holder's type of Period is `Both` type otherwise
        // it will assign the given type `_typeOfPeriod` to the _holder typeOfPeriod
        // `_typeOfPeriod` it always be contrary to the removing restriction
        // if removing restriction is individual then typeOfPeriod is TypeOfPeriod.OneDay
        // in uint8 its value is 1. if removing restriction is daily individual then typeOfPeriod
        // is TypeOfPeriod.MultipleDays in uint8 its value is 0.
        if (_holderToRestrictionType[_holder] != VolumeRestrictionTMStorage.TypeOfPeriod.Both) {
            uint256 flags = _dataStore.getUint256(_getKey(INVESTORFLAGS, _holder));
            flags = flags & ~(ONE << INDEX);
            _dataStore.setUint256(_getKey(INVESTORFLAGS, _holder), flags);
        } else {
            _holderToRestrictionType[_holder] = _typeOfPeriod;
        }
    }

    function addRestrictionData(
        mapping(address => VolumeRestrictionTMStorage.TypeOfPeriod) storage _holderToRestrictionType,
        address _holder,
        VolumeRestrictionTMStorage.TypeOfPeriod _callFrom,
        uint256 _endTime,
        IDataStore _dataStore
    )
        public
    {
        uint256 flags = _dataStore.getUint256(_getKey(INVESTORFLAGS, _holder));
        if (!_isExistingInvestor(_holder, _dataStore)) {
            _dataStore.insertAddress(INVESTORSKEY, _holder);
            //KYC data can not be present if added is false and hence we can set packed KYC as uint256(1) to set added as true
            _dataStore.setUint256(_getKey(WHITELIST, _holder), uint256(1));
        }
        if (!_isVolRestricted(flags)) {
            flags = flags | (ONE << INDEX);
            _dataStore.setUint256(_getKey(INVESTORFLAGS, _holder), flags);
        }
        VolumeRestrictionTMStorage.TypeOfPeriod _type = _getTypeOfPeriod(_holderToRestrictionType[_holder], _callFrom, _endTime);
        _holderToRestrictionType[_holder] = _type;
    }

    function isValidAmountAfterRestrictionChanges(
        uint256 _amountTradedLastDay,
        uint256 _amount,
        uint256 _sumOfLastPeriod,
        uint256 _allowedAmount,
        uint256 _lastTradedTimestamp
    )
        public
        view
        returns(bool)
    {
        // if restriction is to check whether the current transaction is performed within the 24 hours
        // span after the last transaction performed by the user
        if (BokkyPooBahsDateTimeLibrary.diffSeconds(_lastTradedTimestamp, now) < 86400) {
            (,, uint256 lastTxDay) = BokkyPooBahsDateTimeLibrary.timestampToDate(_lastTradedTimestamp);
            (,, uint256 currentTxDay) = BokkyPooBahsDateTimeLibrary.timestampToDate(now);
            // This if statement is to check whether the last transaction timestamp (of `individualRestriction[_from]`
            // when `_isDefault` is true or defaultRestriction when `_isDefault` is false) is comes within the same day of the current
            // transaction timestamp or not.
            if (lastTxDay == currentTxDay) {
                // Not allow to transact more than the current transaction restriction allowed amount
                if ((_sumOfLastPeriod.add(_amount)).add(_amountTradedLastDay) > _allowedAmount)
                    return false;
            }
        }
        return true;
    }

    /**
     * @notice Provide the restriction details of all the restricted addresses
     * @return address List of the restricted addresses
     * @return uint256 List of the tokens allowed to the restricted addresses corresponds to restricted address
     * @return uint256 List of the start time of the restriction corresponds to restricted address
     * @return uint256 List of the rolling period in days for a restriction corresponds to restricted address.
     * @return uint256 List of the end time of the restriction corresponds to restricted address.
     * @return uint8 List of the type of restriction to validate the value of the `allowedTokens`
     * of the restriction corresponds to restricted address
     */
    function getRestrictionData(
        mapping(address => VolumeRestrictionTMStorage.TypeOfPeriod) storage _holderToRestrictionType,
        VolumeRestrictionTMStorage.IndividualRestrictions storage _individualRestrictions,
        IDataStore _dataStore
    )
        public
        view
        returns(
            address[] memory allAddresses,
            uint256[] memory allowedTokens,
            uint256[] memory startTime,
            uint256[] memory rollingPeriodInDays,
            uint256[] memory endTime,
            VolumeRestrictionTMStorage.RestrictionType[] memory typeOfRestriction
            )
    {
        address[] memory investors = _dataStore.getAddressArray(INVESTORSKEY);
        uint256 counter;
        uint256 i;
        for (i = 0; i < investors.length; i++) {
            if (_isVolRestricted(_dataStore.getUint256(_getKey(INVESTORFLAGS, investors[i])))) {
                counter = counter + (_holderToRestrictionType[investors[i]] == VolumeRestrictionTMStorage.TypeOfPeriod.Both ? 2 : 1);
            }
        }
        allAddresses = new address[](counter);
        allowedTokens = new uint256[](counter);
        startTime = new uint256[](counter);
        rollingPeriodInDays = new uint256[](counter);
        endTime = new uint256[](counter);
        typeOfRestriction = new VolumeRestrictionTMStorage.RestrictionType[](counter);
        counter = 0;
        for (i = 0; i < investors.length; i++) {
            if (_isVolRestricted(_dataStore.getUint256(_getKey(INVESTORFLAGS, investors[i])))) {
                allAddresses[counter] = investors[i];
                if (_holderToRestrictionType[investors[i]] == VolumeRestrictionTMStorage.TypeOfPeriod.MultipleDays) {
                    _setValues(_individualRestrictions.individualRestriction[investors[i]], allowedTokens, startTime, rollingPeriodInDays, endTime, typeOfRestriction, counter);
                }
                else if (_holderToRestrictionType[investors[i]] == VolumeRestrictionTMStorage.TypeOfPeriod.OneDay) {
                    _setValues(_individualRestrictions.individualDailyRestriction[investors[i]], allowedTokens, startTime, rollingPeriodInDays, endTime, typeOfRestriction, counter);
                }
                else if (_holderToRestrictionType[investors[i]] == VolumeRestrictionTMStorage.TypeOfPeriod.Both) {
                    _setValues(_individualRestrictions.individualRestriction[investors[i]], allowedTokens, startTime, rollingPeriodInDays, endTime, typeOfRestriction, counter);
                    counter++;
                    allAddresses[counter] = investors[i];
                    _setValues(_individualRestrictions.individualDailyRestriction[investors[i]], allowedTokens, startTime, rollingPeriodInDays, endTime, typeOfRestriction, counter);
                }
                counter++;
            }
        }
    }

    function _setValues(
        VolumeRestrictionTMStorage.VolumeRestriction memory _restriction,
        uint256[] memory _allowedTokens,
        uint256[] memory _startTime,
        uint256[] memory _rollingPeriodInDays,
        uint256[] memory _endTime,
        VolumeRestrictionTMStorage.RestrictionType[] memory _typeOfRestriction,
        uint256 _index
    )
        internal
        pure
    {
        _allowedTokens[_index] = _restriction.allowedTokens;
        _startTime[_index] = _restriction.startTime;
        _rollingPeriodInDays[_index] = _restriction.rollingPeriodInDays;
        _endTime[_index] = _restriction.endTime;
        _typeOfRestriction[_index] = _restriction.typeOfRestriction;
    }

    function _isVolRestricted(uint256 _flags) internal pure returns(bool) {
        uint256 volRestricted = (_flags >> INDEX) & ONE;
        return (volRestricted > 0 ? true : false);
    }

    function _getTypeOfPeriod(
        VolumeRestrictionTMStorage.TypeOfPeriod _currentTypeOfPeriod,
        VolumeRestrictionTMStorage.TypeOfPeriod _callFrom,
        uint256 _endTime
    )
        internal
        pure
        returns(VolumeRestrictionTMStorage.TypeOfPeriod)
    {
        if (_currentTypeOfPeriod != _callFrom && _endTime != uint256(0))
            return VolumeRestrictionTMStorage.TypeOfPeriod.Both;
        else
            return _callFrom;
    }

    function _isExistingInvestor(address _investor, IDataStore _dataStore) internal view returns(bool) {
        uint256 data = _dataStore.getUint256(_getKey(WHITELIST, _investor));
        //extracts `added` from packed `_whitelistData`
        return uint8(data) == 0 ? false : true;
    }

    function _getKey(bytes32 _key1, address _key2) internal pure returns(bytes32) {
        return bytes32(keccak256(abi.encodePacked(_key1, _key2)));
    }

}

pragma solidity 0.5.8;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        uint year;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        uint year;
        uint month;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        uint fromYear;
        uint fromMonth;
        uint fromDay;
        uint toYear;
        uint toMonth;
        uint toDay;
        (fromYear, fromMonth, fromDay) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        uint fromYear;
        uint fromMonth;
        uint fromDay;
        uint toYear;
        uint toMonth;
        uint toDay;
        (fromYear, fromMonth, fromDay) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

pragma solidity 0.5.8;

/**
 * @title Interface to be implemented by all Transfer Manager modules
 */
interface ITransferManager {
    //  If verifyTransfer returns:
    //  FORCE_VALID, the transaction will always be valid, regardless of other TM results
    //  INVALID, then the transfer should not be allowed regardless of other TM results
    //  VALID, then the transfer is valid for this TM
    //  NA, then the result from this TM is ignored
    enum Result {INVALID, NA, VALID, FORCE_VALID}

    /**
     * @notice Determines if the transfer between these two accounts can happen
     */
    function executeTransfer(address _from, address _to, uint256 _amount, bytes calldata _data) external returns(Result result);

    function verifyTransfer(address _from, address _to, uint256 _amount, bytes calldata _data) external view returns(Result result, bytes32 partition);

    /**
     * @notice return the amount of tokens for a given user as per the partition
     * @param _partition Identifier
     * @param _tokenHolder Whom token amount need to query
     * @param _additionalBalance It is the `_value` that transfer during transfer/transferFrom function call
     */
    function getTokensByPartition(bytes32 _partition, address _tokenHolder, uint256 _additionalBalance) external view returns(uint256 amount);

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

pragma solidity ^0.5.2;

/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Calculates the average of two numbers. Since these are integers,
     * averages of an even and odd number cannot be represented, and will be
     * rounded down.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}