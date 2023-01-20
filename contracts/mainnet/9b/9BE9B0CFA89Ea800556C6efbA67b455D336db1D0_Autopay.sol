// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import { UsingTellor } from "usingtellor/contracts/UsingTellor.sol";
import { IERC20 } from "./interfaces/IERC20.sol";
import "./interfaces/IQueryDataStorage.sol";

/**
 @author Tellor Inc.
 @title Autopay
 @dev This is a contract for automatically paying for Tellor oracle data at
 * specific time intervals, as well as one time tips.
*/
contract Autopay is UsingTellor {
    // Storage
    IERC20 public token; // TRB token address
    IQueryDataStorage public queryDataStorage; // Query data storage contract
    uint256 public fee; // 1000 is 100%, 50 is 5%, etc.

    mapping(bytes32 => bytes32[]) currentFeeds; // mapping queryId to dataFeedIds array
    mapping(bytes32 => mapping(bytes32 => Feed)) dataFeed; // mapping queryId to dataFeedId to details
    mapping(bytes32 => bytes32) public queryIdFromDataFeedId; // mapping dataFeedId to queryId
    mapping(bytes32 => uint256) public queryIdsWithFundingIndex; // mapping queryId to queryIdsWithFunding index plus one (0 if not in array)
    mapping(bytes32 => Tip[]) public tips; // mapping queryId to tips
    mapping(address => uint256) public userTipsTotal; // track user tip total per user

    bytes32[] public feedsWithFunding; // array of dataFeedIds that have funding
    bytes32[] public queryIdsWithFunding; // array of queryIds that have funding

    // Structs
    struct Feed {
        FeedDetails details;
        mapping(uint256 => bool) rewardClaimed; // tracks which tips were already paid out
    }

    struct FeedDetails {
        uint256 reward; // amount paid for each eligible data submission
        uint256 balance; // account remaining balance
        uint256 startTime; // time of first payment window
        uint256 interval; // time between pay periods
        uint256 window; // amount of time data can be submitted per interval
        uint256 priceThreshold; //change in price necessitating an update 100 = 1%
        uint256 rewardIncreasePerSecond; // amount reward increases per second within window (0 for flat rewards)
        uint256 feedsWithFundingIndex; // index plus one of dataFeedID in feedsWithFunding array (0 if not in array)
    }

    struct FeedDetailsWithQueryData {
        FeedDetails details; // feed details for feed id with funding
        bytes queryData; // query data for requested data
    }

    struct SingleTipsWithQueryData {
        bytes queryData; // query data with single tip for requested data
        uint256 tip; // reward amount for request
    }

    struct Tip {
        uint256 amount; // amount tipped
        uint256 timestamp; // time tipped
        uint256 cumulativeTips; // cumulative tips for query ID
    }

    // Events
    event DataFeedFunded(
        bytes32 indexed _queryId,
        bytes32 indexed _feedId,
        uint256 indexed _amount,
        address _feedFunder,
        FeedDetails _feedDetails
    );
    event NewDataFeed(
        bytes32 indexed _queryId,
        bytes32 indexed _feedId,
        bytes _queryData,
        address _feedCreator
    );
    event OneTimeTipClaimed(
        bytes32 indexed _queryId,
        uint256 indexed _amount,
        address indexed _reporter
    );
    event TipAdded(
        bytes32 indexed _queryId,
        uint256 indexed _amount,
        bytes _queryData,
        address _tipper
    );
    event TipClaimed(
        bytes32 indexed _feedId,
        bytes32 indexed _queryId,
        uint256 indexed _amount,
        address _reporter
    );

    // Functions
    /**
     * @dev Initializes system parameters
     * @param _tellor address of Tellor contract
     * @param _queryDataStorage address of query data storage contract
     * @param _fee percentage, 1000 is 100%, 50 is 5%, etc.
     */
    constructor(
        address payable _tellor,
        address _queryDataStorage,
        uint256 _fee
    ) UsingTellor(_tellor) {
        token = IERC20(tellor.token());
        queryDataStorage = IQueryDataStorage(_queryDataStorage);
        fee = _fee;
    }

    /**
     * @dev Function to claim singular tip
     * @param _queryId id of reported data
     * @param _timestamps[] batch of timestamps array of reported data eligible for reward
     */
    function claimOneTimeTip(bytes32 _queryId, uint256[] calldata _timestamps)
        external
    {
        require(
            tips[_queryId].length > 0,
            "no tips submitted for this queryId"
        );
        uint256 _cumulativeReward;
        for (uint256 _i = 0; _i < _timestamps.length; _i++) {
            _cumulativeReward += _getOneTimeTipAmount(
                _queryId,
                _timestamps[_i]
            );
        }
        require(
            token.transfer(
                msg.sender,
                _cumulativeReward - ((_cumulativeReward * fee) / 1000)
            )
        );
        token.approve(address(tellor), (_cumulativeReward * fee) / 1000);
        tellor.addStakingRewards((_cumulativeReward * fee) / 1000);
        if (getCurrentTip(_queryId) == 0) {
            if (queryIdsWithFundingIndex[_queryId] != 0) {
                uint256 _idx = queryIdsWithFundingIndex[_queryId] - 1;
                // Replace unfunded feed in array with last element
                queryIdsWithFunding[_idx] = queryIdsWithFunding[
                    queryIdsWithFunding.length - 1
                ];
                bytes32 _queryIdLastFunded = queryIdsWithFunding[_idx];
                queryIdsWithFundingIndex[_queryIdLastFunded] = _idx + 1;
                queryIdsWithFundingIndex[_queryId] = 0;
                queryIdsWithFunding.pop();
            }
        }
        emit OneTimeTipClaimed(_queryId, _cumulativeReward, msg.sender);
    }

    /**
     * @dev Allows Tellor reporters to claim their tips in batches
     * @param _feedId unique feed identifier
     * @param _queryId ID of reported data
     * @param _timestamps batch of timestamps array of reported data eligible for reward
     */
    function claimTip(
        bytes32 _feedId,
        bytes32 _queryId,
        uint256[] calldata _timestamps
    ) external {
        Feed storage _feed = dataFeed[_queryId][_feedId];
        uint256 _balance = _feed.details.balance;
        require(_balance > 0, "no funds available for this feed");
        uint256 _cumulativeReward;
        for (uint256 _i = 0; _i < _timestamps.length; _i++) {
            require(
                block.timestamp - _timestamps[_i] > 12 hours,
                "buffer time has not passed"
            );
            require(
                getReporterByTimestamp(_queryId, _timestamps[_i]) == msg.sender,
                "message sender not reporter for given queryId and timestamp"
            );
            _cumulativeReward += _getRewardAmount(
                _feedId,
                _queryId,
                _timestamps[_i]
            );
            if (_cumulativeReward >= _balance) {
                // Balance runs out
                require(
                    _i == _timestamps.length - 1,
                    "insufficient balance for all submitted timestamps"
                );
                _cumulativeReward = _balance;
                // Adjust currently funded feeds
                if (feedsWithFunding.length > 1) {
                    uint256 _idx = _feed.details.feedsWithFundingIndex - 1;
                    // Replace unfunded feed in array with last element
                    feedsWithFunding[_idx] = feedsWithFunding[
                        feedsWithFunding.length - 1
                    ];
                    bytes32 _feedIdLastFunded = feedsWithFunding[_idx];
                    bytes32 _queryIdLastFunded = queryIdFromDataFeedId[
                        _feedIdLastFunded
                    ];
                    dataFeed[_queryIdLastFunded][_feedIdLastFunded]
                        .details
                        .feedsWithFundingIndex = _idx + 1;
                }
                feedsWithFunding.pop();
                _feed.details.feedsWithFundingIndex = 0;
            }
            _feed.rewardClaimed[_timestamps[_i]] = true;
        }
        _feed.details.balance -= _cumulativeReward;
        require(
            token.transfer(
                msg.sender,
                _cumulativeReward - ((_cumulativeReward * fee) / 1000)
            )
        );
        token.approve(address(tellor), (_cumulativeReward * fee) / 1000);
        tellor.addStakingRewards((_cumulativeReward * fee) / 1000);
        emit TipClaimed(_feedId, _queryId, _cumulativeReward, msg.sender);
    }

    /**
     * @dev Allows dataFeed account to be filled with tokens
     * @param _feedId unique feed identifier
     * @param _queryId identifier of reported data type associated with feed
     * @param _amount quantity of tokens to fund feed
     */
    function fundFeed(
        bytes32 _feedId,
        bytes32 _queryId,
        uint256 _amount
    ) public {
        FeedDetails storage _feed = dataFeed[_queryId][_feedId].details;
        require(_feed.reward > 0, "feed not set up");
        require(_amount > 0, "must be sending an amount");
        _feed.balance += _amount;
        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "ERC20: transfer amount exceeds balance"
        );
        // Add to array of feeds with funding
        if (_feed.feedsWithFundingIndex == 0 && _feed.balance > 0) {
            feedsWithFunding.push(_feedId);
            _feed.feedsWithFundingIndex = feedsWithFunding.length;
        }
        userTipsTotal[msg.sender] += _amount;
        emit DataFeedFunded(_feedId, _queryId, _amount, msg.sender, _feed);
    }

    /**
     * @dev Initializes dataFeed parameters.
     * @param _queryId unique identifier of desired data feed
     * @param _reward tip amount per eligible data submission
     * @param _startTime timestamp of first autopay window
     * @param _interval amount of time between autopay windows
     * @param _window amount of time after each new interval when reports are eligible for tips
     * @param _priceThreshold amount price must change to automate update regardless of time (negated if 0, 100 = 1%)
     * @param _rewardIncreasePerSecond amount reward increases per second within a window (0 for flat reward)
     * @param _queryData the data used by reporters to fulfill the query
     * @param _amount optional initial amount to fund it with
     */
    function setupDataFeed(
        bytes32 _queryId,
        uint256 _reward,
        uint256 _startTime,
        uint256 _interval,
        uint256 _window,
        uint256 _priceThreshold,
        uint256 _rewardIncreasePerSecond,
        bytes calldata _queryData,
        uint256 _amount
    ) external returns (bytes32 _feedId) {
        require(
            _queryId == keccak256(_queryData),
            "id must be hash of bytes data"
        );
        _feedId = keccak256(
            abi.encode(
                _queryId,
                _reward,
                _startTime,
                _interval,
                _window,
                _priceThreshold,
                _rewardIncreasePerSecond
            )
        );
        FeedDetails storage _feed = dataFeed[_queryId][_feedId].details;
        require(_feed.reward == 0, "feed must not be set up already");
        require(_reward > 0, "reward must be greater than zero");
        require(_interval > 0, "interval must be greater than zero");
        require(
            _window < _interval,
            "window must be less than interval length"
        );
        _feed.reward = _reward;
        _feed.startTime = _startTime;
        _feed.interval = _interval;
        _feed.window = _window;
        _feed.priceThreshold = _priceThreshold;
        _feed.rewardIncreasePerSecond = _rewardIncreasePerSecond;
        currentFeeds[_queryId].push(_feedId);
        queryIdFromDataFeedId[_feedId] = _queryId;
        queryDataStorage.storeData(_queryData);
        emit NewDataFeed(_queryId, _feedId, _queryData, msg.sender);
        if (_amount > 0) {
            fundFeed(_feedId, _queryId, _amount);
        }
        return _feedId;
    }

    /**
     * @dev Function to run a single tip
     * @param _queryId ID of tipped data
     * @param _amount amount to tip
     * @param _queryData the data used by reporters to fulfill the query
     */
    function tip(
        bytes32 _queryId,
        uint256 _amount,
        bytes calldata _queryData
    ) external {
        require(
            _queryId == keccak256(_queryData),
            "id must be hash of bytes data"
        );
        require(_amount > 0, "tip must be greater than zero");
        Tip[] storage _tips = tips[_queryId];
        if (_tips.length == 0) {
            _tips.push(Tip(_amount, block.timestamp, _amount));
            queryDataStorage.storeData(_queryData);
        } else {
            (, uint256 _timestampRetrieved) = _getCurrentValue(_queryId);
            if (_timestampRetrieved < _tips[_tips.length - 1].timestamp) {
                _tips[_tips.length - 1].timestamp = block.timestamp;
                _tips[_tips.length - 1].amount += _amount;
                _tips[_tips.length - 1].cumulativeTips += _amount;
            } else {
                _tips.push(
                    Tip(
                        _amount,
                        block.timestamp,
                        _tips[_tips.length - 1].cumulativeTips + _amount
                    )
                );
            }
        }
        if (
            queryIdsWithFundingIndex[_queryId] == 0 &&
            getCurrentTip(_queryId) > 0
        ) {
            queryIdsWithFunding.push(_queryId);
            queryIdsWithFundingIndex[_queryId] = queryIdsWithFunding.length;
        }
        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "ERC20: transfer amount exceeds balance"
        );
        userTipsTotal[msg.sender] += _amount;
        emit TipAdded(_queryId, _amount, _queryData, msg.sender);
    }

    // Getters
    /**
     * @dev Getter function to read current data feeds
     * @param _queryId id of reported data
     * @return feedIds array for queryId
     */
    function getCurrentFeeds(bytes32 _queryId)
        external
        view
        returns (bytes32[] memory)
    {
        return currentFeeds[_queryId];
    }

    /**
     * @dev Getter function to current oneTime tip by queryId
     * @param _queryId id of reported data
     * @return amount of tip
     */
    function getCurrentTip(bytes32 _queryId) public view returns (uint256) {
        // if no tips, return 0
        if (tips[_queryId].length == 0) {
            return 0;
        }
        (, uint256 _timestampRetrieved) = _getCurrentValue(_queryId);
        Tip memory _lastTip = tips[_queryId][tips[_queryId].length - 1];
        if (_timestampRetrieved < _lastTip.timestamp) {
            return _lastTip.amount;
        } else {
            return 0;
        }
    }

    /**
     * @dev Getter function to read a specific dataFeed
     * @param _feedId unique feedId of parameters
     * @return FeedDetails details of specified feed
     */
    function getDataFeed(bytes32 _feedId)
        external
        view
        returns (FeedDetails memory)
    {
        return (dataFeed[queryIdFromDataFeedId[_feedId]][_feedId].details);
    }

    /**
     * @dev Getter function for currently funded feed details
     * @return FeedDetailsWithQueryData[] array of details for funded feeds
     */
    function getFundedFeedDetails()
        external
        view
        returns (FeedDetailsWithQueryData[] memory)
    {
        bytes32[] memory _feeds = this.getFundedFeeds();
        FeedDetailsWithQueryData[]
            memory _details = new FeedDetailsWithQueryData[](_feeds.length);
        for (uint256 i = 0; i < _feeds.length; i++) {
            FeedDetails memory _feedDetail = this.getDataFeed(_feeds[i]);
            bytes32 _queryId = this.getQueryIdFromFeedId(_feeds[i]);
            bytes memory _queryData = queryDataStorage.getQueryData(_queryId);
            _details[i].details = _feedDetail;
            _details[i].queryData = _queryData;
        }
        return _details;
    }

    /**
     * @dev Getter function for currently funded feeds
     */
    function getFundedFeeds() external view returns (bytes32[] memory) {
        return feedsWithFunding;
    }

    /**
     * @dev Getter function for queryIds with current one time tips
     */
    function getFundedQueryIds() external view returns (bytes32[] memory) {
        return queryIdsWithFunding;
    }

    /**
     * @dev Getter function for currently funded single tips with queryData
     * @return SingleTipsWithQueryData[] array of current tips
     */
    function getFundedSingleTipsInfo()
        external
        view
        returns (SingleTipsWithQueryData[] memory)
    {
        bytes32[] memory _fundedQueryIds = this.getFundedQueryIds();
        SingleTipsWithQueryData[] memory _query = new SingleTipsWithQueryData[](
            _fundedQueryIds.length
        );
        for (uint256 i = 0; i < _fundedQueryIds.length; i++) {
            bytes memory _data = queryDataStorage.getQueryData(
                _fundedQueryIds[i]
            );
            uint256 _reward = this.getCurrentTip(_fundedQueryIds[i]);
            _query[i].queryData = _data;
            _query[i].tip = _reward;
        }
        return _query;
    }

    /**
     * @dev Getter function to get number of past tips
     * @param _queryId id of reported data
     * @return count of tips available
     */
    function getPastTipCount(bytes32 _queryId) external view returns (uint256) {
        return tips[_queryId].length;
    }

    /**
     * @dev Getter function for past tips
     * @param _queryId id of reported data
     * @return Tip struct (amount/timestamp) of all past tips
     */
    function getPastTips(bytes32 _queryId)
        external
        view
        returns (Tip[] memory)
    {
        return tips[_queryId];
    }

    /**
     * @dev Getter function for past tips by index
     * @param _queryId id of reported data
     * @param _index uint index in the Tip array
     * @return amount/timestamp of specific tip
     */
    function getPastTipByIndex(bytes32 _queryId, uint256 _index)
        external
        view
        returns (Tip memory)
    {
        return tips[_queryId][_index];
    }

    /**
     * @dev Getter function to lookup query IDs from dataFeed IDs
     * @param _feedId dataFeed unique identifier
     * @return bytes32 corresponding query ID
     */
    function getQueryIdFromFeedId(bytes32 _feedId)
        external
        view
        returns (bytes32)
    {
        return queryIdFromDataFeedId[_feedId];
    }

    /**
     * @dev Getter function to read potential rewards for a set of oracle submissions
     * NOTE: Does not consider reporter address, 12-hour dispute buffer period, or duplicate timestamps
     * @param _feedId dataFeed unique identifier
     * @param _queryId unique identifier of reported data
     * @param _timestamps array of timestamps of oracle submissions
     * @return _cumulativeReward total potential reward for the set of oracle submissions
     */
    function getRewardAmount(
        bytes32 _feedId,
        bytes32 _queryId,
        uint256[] calldata _timestamps
    ) external view returns (uint256 _cumulativeReward) {
        FeedDetails storage _feed = dataFeed[_queryId][_feedId].details;
        for (uint256 _i = 0; _i < _timestamps.length; _i++) {
            _cumulativeReward += _getRewardAmount(
                _feedId,
                _queryId,
                _timestamps[_i]
            );
        }
        if (_cumulativeReward > _feed.balance) {
            _cumulativeReward = _feed.balance;
        }
        _cumulativeReward -= ((_cumulativeReward * fee) / 1000);
    }

    /**
     * @dev Getter function for reading whether a reward has been claimed
     * @param _feedId feedId of dataFeed
     * @param _queryId id of reported data
     * @param _timestamp id or reported data
     * @return bool rewardClaimed
     */
    function getRewardClaimedStatus(
        bytes32 _feedId,
        bytes32 _queryId,
        uint256 _timestamp
    ) external view returns (bool) {
        return dataFeed[_queryId][_feedId].rewardClaimed[_timestamp];
    }

    /**
     * @dev Getter function for reading whether a reward has been claimed
     * @param _feedId feedId of dataFeed
     * @param _queryId queryId of reported data
     * @param _timestamp[] list of report timestamps
     * @return bool[] list of rewardClaim status
     */
    function getRewardClaimStatusList(
        bytes32 _feedId,
        bytes32 _queryId,
        uint256[] calldata _timestamp
    ) external view returns (bool[] memory) {
        bool[] memory _status = new bool[](_timestamp.length);
        for (uint256 i = 0; i < _timestamp.length; i++) {
            _status[i] = dataFeed[_queryId][_feedId].rewardClaimed[
                _timestamp[i]
            ];
        }
        return _status;
    }

    /**
     * @dev Getter function for retrieving the total amount of tips paid by a given address
     * @param _user address of user to query
     * @return uint256 total amount of tips paid by user
     */
    function getTipsByAddress(address _user) external view returns (uint256) {
        return userTipsTotal[_user];
    }

    // Internal functions
    /**
     * @dev Internal function to read if a reward has been claimed
     * @param _b bytes value to convert to uint256
     * @return _number uint256 converted from bytes
     */
    function _bytesToUint(bytes memory _b)
        internal
        pure
        returns (uint256 _number)
    {
        for (uint256 _i = 0; _i < _b.length; _i++) {
            _number = _number * 256 + uint8(_b[_i]);
        }
    }

    /**
     ** @dev Internal function which determines tip eligibility for a given oracle submission
     * @param _queryId id of reported data
     * @param _timestamp timestamp of one time tip
     * @return _tipAmount of tip
     */
    function _getOneTimeTipAmount(bytes32 _queryId, uint256 _timestamp)
        internal
        returns (uint256 _tipAmount)
    {
        require(
            block.timestamp - _timestamp > 12 hours,
            "buffer time has not passed"
        );
        require(!isInDispute(_queryId, _timestamp), "value disputed");
        require(
            msg.sender == getReporterByTimestamp(_queryId, _timestamp),
            "msg sender must be reporter address"
        );
        Tip[] storage _tips = tips[_queryId];
        uint256 _min = 0;
        uint256 _max = _tips.length;
        uint256 _mid;
        while (_max - _min > 1) {
            _mid = (_max + _min) / 2;
            if (_tips[_mid].timestamp > _timestamp) {
                _max = _mid;
            } else {
                _min = _mid;
            }
        }
        (, uint256 _timestampBefore) = getDataBefore(_queryId, _timestamp);
        require(
            _timestampBefore < _tips[_min].timestamp,
            "tip earned by previous submission"
        );
        require(
            _timestamp >= _tips[_min].timestamp,
            "timestamp not eligible for tip"
        );
        require(_tips[_min].amount > 0, "tip already claimed");
        _tipAmount = _tips[_min].amount;
        _tips[_min].amount = 0;
        uint256 _minBackup = _min;
        // check whether eligible for previous tips in array due to disputes
        (, uint256 _indexNow) = getIndexForDataBefore(_queryId, _timestamp + 1);
        (bool _found, uint256 _indexBefore) = getIndexForDataBefore(
            _queryId,
            _timestampBefore + 1
        );
        if (_indexNow - _indexBefore > 1 || !_found) {
            if (!_found) {
                _tipAmount = _tips[_minBackup].cumulativeTips;
            } else {
                _max = _min;
                _min = 0;
                _mid;
                while (_max - _min > 1) {
                    _mid = (_max + _min) / 2;
                    if (_tips[_mid].timestamp > _timestampBefore) {
                        _max = _mid;
                    } else {
                        _min = _mid;
                    }
                }
                _min++;
                if (_min < _minBackup) {
                    _tipAmount =
                        _tips[_minBackup].cumulativeTips -
                        _tips[_min].cumulativeTips +
                        _tips[_min].amount;
                }
            }
        }
    }

    /**
     * @dev Allows the user to get the latest value for the queryId specified
     * @param _queryId is the id to look up the value for
     * @return _value the value retrieved
     * @return _timestampRetrieved the retrieved value's timestamp
     */

    function _getCurrentValue(bytes32 _queryId)
        internal
        view
        returns (bytes memory _value, uint256 _timestampRetrieved)
    {
        uint256 _count = getNewValueCountbyQueryId(_queryId);
        if (_count == 0) {
            return (bytes(""), 0);
        }
        uint256 _time;
        //loop handles for dispute (value = "" if disputed)
        while (_count > 0) {
            _count--;
            _time = getTimestampbyQueryIdandIndex(_queryId, _count);
            _value = retrieveData(_queryId, _time);
            if (_value.length > 0) {
                return (_value, _time);
            }
        }
        return (bytes(""), _time);
    }

    /**
     * @dev Internal function which determines the reward amount for a given oracle submission
     * @param _feedId id of dataFeed
     * @param _queryId id of reported data
     * @param _timestamp timestamp of reported data eligible for reward
     * @return _rewardAmount potential reward amount for the given oracle submission
     */
    function _getRewardAmount(
        bytes32 _feedId,
        bytes32 _queryId,
        uint256 _timestamp
    ) internal view returns (uint256 _rewardAmount) {
        require(
            block.timestamp - _timestamp < 4 weeks,
            "timestamp too old to claim tip"
        );
        Feed storage _feed = dataFeed[_queryId][_feedId];
        require(!_feed.rewardClaimed[_timestamp], "reward already claimed");
        uint256 _n = (_timestamp - _feed.details.startTime) /
            _feed.details.interval; // finds closest interval _n to timestamp
        uint256 _c = _feed.details.startTime + _feed.details.interval * _n; // finds start timestamp _c of interval _n
        bytes memory _valueRetrieved = retrieveData(_queryId, _timestamp);
        require(_valueRetrieved.length != 0, "no value exists at timestamp");
        (
            bytes memory _valueRetrievedBefore,
            uint256 _timestampBefore
        ) = getDataBefore(_queryId, _timestamp);
        uint256 _priceChange = 0; // price change from last value to current value
        if (_feed.details.priceThreshold != 0) {
            uint256 _v1 = _bytesToUint(_valueRetrieved);
            uint256 _v2 = _bytesToUint(_valueRetrievedBefore);
            if (_v2 == 0) {
                _priceChange = 10000;
            } else if (_v1 >= _v2) {
                _priceChange = (10000 * (_v1 - _v2)) / _v2;
            } else {
                _priceChange = (10000 * (_v2 - _v1)) / _v2;
            }
        }
        _rewardAmount = _feed.details.reward;
        uint256 _timeDiff = _timestamp - _c; // time difference between report timestamp and start of interval
        // ensure either report is first within a valid window, or price change threshold is met
        if (_timeDiff < _feed.details.window && _timestampBefore < _c) {
            // add time based rewards if applicable
            _rewardAmount += _feed.details.rewardIncreasePerSecond * _timeDiff;
        } else {
            require(
                _priceChange > _feed.details.priceThreshold,
                "price threshold not met"
            );
        }

        if (_feed.details.balance < _rewardAmount) {
            _rewardAmount = _feed.details.balance;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

interface IERC20 {
  function transfer(address _to, uint256 _amount) external returns(bool);
  function transferFrom(address _from, address _to, uint256 _amount) external returns(bool);
  function approve(address _spender, uint256 _amount) external returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IQueryDataStorage {
  function storeData(bytes memory _queryData) external; 
  function getQueryData(bytes32 _queryId) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
    * @dev EIP2362 Interface for pull oracles
    * https://github.com/tellor-io/EIP-2362
*/
interface IERC2362
{
	/**
	 * @dev Exposed function pertaining to EIP standards
	 * @param _id bytes32 ID of the query
	 * @return int,uint,uint returns the value, timestamp, and status code of query
	 */
	function valueFor(bytes32 _id) external view returns(int256,uint256,uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMappingContract{
    function getTellorID(bytes32 _id) external view returns(bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ITellor {
    //Controller
    function addresses(bytes32) external view returns (address);

    function uints(bytes32) external view returns (uint256);

    function burn(uint256 _amount) external;

    function changeDeity(address _newDeity) external;

    function changeOwner(address _newOwner) external;
    function changeUint(bytes32 _target, uint256 _amount) external;

    function migrate() external;

    function mint(address _reciever, uint256 _amount) external;

    function init() external;

    function getAllDisputeVars(uint256 _disputeId)
        external
        view
        returns (
            bytes32,
            bool,
            bool,
            bool,
            address,
            address,
            address,
            uint256[9] memory,
            int256
        );

    function getDisputeIdByDisputeHash(bytes32 _hash)
        external
        view
        returns (uint256);

    function getDisputeUintVars(uint256 _disputeId, bytes32 _data)
        external
        view
        returns (uint256);

    function getLastNewValueById(uint256 _requestId)
        external
        view
        returns (uint256, bool);

    function retrieveData(uint256 _requestId, uint256 _timestamp)
        external
        view
        returns (uint256);

    function getNewValueCountbyRequestId(uint256 _requestId)
        external
        view
        returns (uint256);

    function getAddressVars(bytes32 _data) external view returns (address);

    function getUintVar(bytes32 _data) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function isMigrated(address _addy) external view returns (bool);

    function allowance(address _user, address _spender)
        external
        view
        returns (uint256);

    function allowedToTrade(address _user, uint256 _amount)
        external
        view
        returns (bool);

    function approve(address _spender, uint256 _amount) external returns (bool);

    function approveAndTransferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool);

    function balanceOf(address _user) external view returns (uint256);

    function balanceOfAt(address _user, uint256 _blockNumber)
        external
        view
        returns (uint256);

    function transfer(address _to, uint256 _amount)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool success);

    function depositStake() external;

    function requestStakingWithdraw() external;

    function withdrawStake() external;

    function changeStakingStatus(address _reporter, uint256 _status) external;

    function slashReporter(address _reporter, address _disputer) external;

    function getStakerInfo(address _staker)
        external
        view
        returns (uint256, uint256);

    function getTimestampbyRequestIDandIndex(uint256 _requestId, uint256 _index)
        external
        view
        returns (uint256);

    function getNewCurrentVariables()
        external
        view
        returns (
            bytes32 _c,
            uint256[5] memory _r,
            uint256 _d,
            uint256 _t
        );

    function getNewValueCountbyQueryId(bytes32 _queryId)
        external
        view
        returns (uint256);

    function getTimestampbyQueryIdandIndex(bytes32 _queryId, uint256 _index)
        external
        view
        returns (uint256);

    function retrieveData(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (bytes memory);

    //Governance
    enum VoteResult {
        FAILED,
        PASSED,
        INVALID
    }

    function setApprovedFunction(bytes4 _func, bool _val) external;

    function beginDispute(bytes32 _queryId, uint256 _timestamp) external;

    function delegate(address _delegate) external;

    function delegateOfAt(address _user, uint256 _blockNumber)
        external
        view
        returns (address);

    function executeVote(uint256 _disputeId) external;

    function proposeVote(
        address _contract,
        bytes4 _function,
        bytes calldata _data,
        uint256 _timestamp
    ) external;

    function tallyVotes(uint256 _disputeId) external;

    function governance() external view returns (address);

    function updateMinDisputeFee() external;

    function verify() external pure returns (uint256);

    function vote(
        uint256 _disputeId,
        bool _supports,
        bool _invalidQuery
    ) external;

    function voteFor(
        address[] calldata _addys,
        uint256 _disputeId,
        bool _supports,
        bool _invalidQuery
    ) external;

    function getDelegateInfo(address _holder)
        external
        view
        returns (address, uint256);

    function isFunctionApproved(bytes4 _func) external view returns (bool);

    function isApprovedGovernanceContract(address _contract)
        external
        returns (bool);

    function getVoteRounds(bytes32 _hash)
        external
        view
        returns (uint256[] memory);

    function getVoteCount() external view returns (uint256);

    function getVoteInfo(uint256 _disputeId)
        external
        view
        returns (
            bytes32,
            uint256[9] memory,
            bool[2] memory,
            VoteResult,
            bytes memory,
            bytes4,
            address[2] memory
        );

    function getDisputeInfo(uint256 _disputeId)
        external
        view
        returns (
            uint256,
            uint256,
            bytes memory,
            address
        );

    function getOpenDisputesOnId(bytes32 _queryId)
        external
        view
        returns (uint256);

    function didVote(uint256 _disputeId, address _voter)
        external
        view
        returns (bool);

    //Oracle
    function getReportTimestampByIndex(bytes32 _queryId, uint256 _index)
        external
        view
        returns (uint256);

    function getValueByTimestamp(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (bytes memory);

    function getBlockNumberByTimestamp(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (uint256);

    function getReportingLock() external view returns (uint256);

    function getReporterByTimestamp(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (address);

    function reportingLock() external view returns (uint256);

    function removeValue(bytes32 _queryId, uint256 _timestamp) external;
    function getTipsByUser(address _user) external view returns(uint256);
    function tipQuery(bytes32 _queryId, uint256 _tip, bytes memory _queryData) external;
    function submitValue(bytes32 _queryId, bytes calldata _value, uint256 _nonce, bytes memory _queryData) external;
    function burnTips() external;

    function changeReportingLock(uint256 _newReportingLock) external;
    function getReportsSubmittedByAddress(address _reporter) external view returns(uint256);
    function changeTimeBasedReward(uint256 _newTimeBasedReward) external;
    function getReporterLastTimestamp(address _reporter) external view returns(uint256);
    function getTipsById(bytes32 _queryId) external view returns(uint256);
    function getTimeBasedReward() external view returns(uint256);
    function getTimestampCountById(bytes32 _queryId) external view returns(uint256);
    function getTimestampIndexByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(uint256);
    function getCurrentReward(bytes32 _queryId) external view returns(uint256, uint256);
    function getCurrentValue(bytes32 _queryId) external view returns(bytes memory);
    function getDataBefore(bytes32 _queryId, uint256 _timestamp) external view returns(bool _ifRetrieve, bytes memory _value, uint256 _timestampRetrieved);
    function getTimeOfLastNewValue() external view returns(uint256);
    function depositStake(uint256 _amount) external;
    function requestStakingWithdraw(uint256 _amount) external;

    //Test functions
    function changeAddressVar(bytes32 _id, address _addy) external;

    //parachute functions
    function killContract() external;

    function migrateFor(address _destination, uint256 _amount) external;

    function rescue51PercentAttack(address _tokenHolder) external;

    function rescueBrokenDataReporting() external;

    function rescueFailedUpdate() external;

    //Tellor 360
    function addStakingRewards(uint256 _amount) external;

    function _sliceUint(bytes memory _b)
        external
        pure
        returns (uint256 _number);

    function claimOneTimeTip(bytes32 _queryId, uint256[] memory _timestamps)
        external;

    function claimTip(
        bytes32 _feedId,
        bytes32 _queryId,
        uint256[] memory _timestamps
    ) external;

    function fee() external view returns (uint256);

    function feedsWithFunding(uint256) external view returns (bytes32);

    function fundFeed(
        bytes32 _feedId,
        bytes32 _queryId,
        uint256 _amount
    ) external;

    function getCurrentFeeds(bytes32 _queryId)
        external
        view
        returns (bytes32[] memory);

    function getCurrentTip(bytes32 _queryId) external view returns (uint256);

    function getDataAfter(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (bytes memory _value, uint256 _timestampRetrieved);

    function getDataFeed(bytes32 _feedId)
        external
        view
        returns (Autopay.FeedDetails memory);

    function getFundedFeeds() external view returns (bytes32[] memory);

    function getFundedQueryIds() external view returns (bytes32[] memory);

    function getIndexForDataAfter(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (bool _found, uint256 _index);

    function getIndexForDataBefore(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (bool _found, uint256 _index);

    function getMultipleValuesBefore(
        bytes32 _queryId,
        uint256 _timestamp,
        uint256 _maxAge,
        uint256 _maxCount
    )
        external
        view
        returns (uint256[] memory _values, uint256[] memory _timestamps);

    function getPastTipByIndex(bytes32 _queryId, uint256 _index)
        external
        view
        returns (Autopay.Tip memory);

    function getPastTipCount(bytes32 _queryId) external view returns (uint256);

    function getPastTips(bytes32 _queryId)
        external
        view
        returns (Autopay.Tip[] memory);

    function getQueryIdFromFeedId(bytes32 _feedId)
        external
        view
        returns (bytes32);

    function getRewardAmount(
        bytes32 _feedId,
        bytes32 _queryId,
        uint256[] memory _timestamps
    ) external view returns (uint256 _cumulativeReward);

    function getRewardClaimedStatus(
        bytes32 _feedId,
        bytes32 _queryId,
        uint256 _timestamp
    ) external view returns (bool);

    function getTipsByAddress(address _user) external view returns (uint256);

    function isInDispute(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (bool);

    function queryIdFromDataFeedId(bytes32) external view returns (bytes32);

    function queryIdsWithFunding(uint256) external view returns (bytes32);

    function queryIdsWithFundingIndex(bytes32) external view returns (uint256);

    function setupDataFeed(
        bytes32 _queryId,
        uint256 _reward,
        uint256 _startTime,
        uint256 _interval,
        uint256 _window,
        uint256 _priceThreshold,
        uint256 _rewardIncreasePerSecond,
        bytes memory _queryData,
        uint256 _amount
    ) external;

    function tellor() external view returns (address);

    function tip(
        bytes32 _queryId,
        uint256 _amount,
        bytes memory _queryData
    ) external;

    function tips(bytes32, uint256)
        external
        view
        returns (uint256 amount, uint256 timestamp);

    function token() external view returns (address);

    function userTipsTotal(address) external view returns (uint256);

    function valueFor(bytes32 _id)
        external
        view
        returns (
            int256 _value,
            uint256 _timestamp,
            uint256 _statusCode
        );
}

interface Autopay {
    struct FeedDetails {
        uint256 reward;
        uint256 balance;
        uint256 startTime;
        uint256 interval;
        uint256 window;
        uint256 priceThreshold;
        uint256 rewardIncreasePerSecond;
        uint256 feedsWithFundingIndex;
    }

    struct Tip {
        uint256 amount;
        uint256 timestamp;
    }
    function getStakeAmount() external view returns(uint256);
    function stakeAmount() external view returns(uint256);
    function token() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interface/ITellor.sol";
import "./interface/IERC2362.sol";
import "./interface/IMappingContract.sol";

/**
 @author Tellor Inc
 @title UsingTellor
 @dev This contract helps smart contracts read data from Tellor
 */
contract UsingTellor is IERC2362 {
    ITellor public tellor;
    IMappingContract public idMappingContract;

    /*Constructor*/
    /**
     * @dev the constructor sets the oracle address in storage
     * @param _tellor is the Tellor Oracle address
     */
    constructor(address payable _tellor) {
        tellor = ITellor(_tellor);
    }

    /*Getters*/
    /**
     * @dev Retrieves the next value for the queryId after the specified timestamp
     * @param _queryId is the queryId to look up the value for
     * @param _timestamp after which to search for next value
     * @return _value the value retrieved
     * @return _timestampRetrieved the value's timestamp
     */
    function getDataAfter(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bytes memory _value, uint256 _timestampRetrieved)
    {
        (bool _found, uint256 _index) = getIndexForDataAfter(
            _queryId,
            _timestamp
        );
        if (!_found) {
            return ("", 0);
        }
        _timestampRetrieved = getTimestampbyQueryIdandIndex(_queryId, _index);
        _value = retrieveData(_queryId, _timestampRetrieved);
        return (_value, _timestampRetrieved);
    }

    /**
     * @dev Retrieves the latest value for the queryId before the specified timestamp
     * @param _queryId is the queryId to look up the value for
     * @param _timestamp before which to search for latest value
     * @return _value the value retrieved
     * @return _timestampRetrieved the value's timestamp
     */
    function getDataBefore(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bytes memory _value, uint256 _timestampRetrieved)
    {
        (, _value, _timestampRetrieved) = tellor.getDataBefore(
            _queryId,
            _timestamp
        );
    }

    /**
     * @dev Retrieves latest array index of data before the specified timestamp for the queryId
     * @param _queryId is the queryId to look up the index for
     * @param _timestamp is the timestamp before which to search for the latest index
     * @return _found whether the index was found
     * @return _index the latest index found before the specified timestamp
     */
    // slither-disable-next-line calls-loop
    function getIndexForDataAfter(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bool _found, uint256 _index)
    {
        uint256 _count = getNewValueCountbyQueryId(_queryId);
        if (_count == 0) return (false, 0);
        _count--;
        bool _search = true; // perform binary search
        uint256 _middle = 0;
        uint256 _start = 0;
        uint256 _end = _count;
        uint256 _timestampRetrieved;
        // checking boundaries to short-circuit the algorithm
        _timestampRetrieved = getTimestampbyQueryIdandIndex(_queryId, _end);
        if (_timestampRetrieved <= _timestamp) return (false, 0);
        _timestampRetrieved = getTimestampbyQueryIdandIndex(_queryId, _start);
        if (_timestampRetrieved > _timestamp) {
            // candidate found, check for disputes
            _search = false;
        }
        // since the value is within our boundaries, do a binary search
        while (_search) {
            _middle = (_end + _start) / 2;
            _timestampRetrieved = getTimestampbyQueryIdandIndex(
                _queryId,
                _middle
            );
            if (_timestampRetrieved > _timestamp) {
                // get immediate previous value
                uint256 _prevTime = getTimestampbyQueryIdandIndex(
                    _queryId,
                    _middle - 1
                );
                if (_prevTime <= _timestamp) {
                    // candidate found, check for disputes
                    _search = false;
                } else {
                    // look from start to middle -1(prev value)
                    _end = _middle - 1;
                }
            } else {
                // get immediate next value
                uint256 _nextTime = getTimestampbyQueryIdandIndex(
                    _queryId,
                    _middle + 1
                );
                if (_nextTime > _timestamp) {
                    // candidate found, check for disputes
                    _search = false;
                    _middle++;
                    _timestampRetrieved = _nextTime;
                } else {
                    // look from middle + 1(next value) to end
                    _start = _middle + 1;
                }
            }
        }
        // candidate found, check for disputed values
        if (!isInDispute(_queryId, _timestampRetrieved)) {
            // _timestampRetrieved is correct
            return (true, _middle);
        } else {
            // iterate forward until we find a non-disputed value
            while (
                isInDispute(_queryId, _timestampRetrieved) && _middle < _count
            ) {
                _middle++;
                _timestampRetrieved = getTimestampbyQueryIdandIndex(
                    _queryId,
                    _middle
                );
            }
            if (
                _middle == _count && isInDispute(_queryId, _timestampRetrieved)
            ) {
                return (false, 0);
            }
            // _timestampRetrieved is correct
            return (true, _middle);
        }
    }

    /**
     * @dev Retrieves latest array index of data before the specified timestamp for the queryId
     * @param _queryId is the queryId to look up the index for
     * @param _timestamp is the timestamp before which to search for the latest index
     * @return _found whether the index was found
     * @return _index the latest index found before the specified timestamp
     */
    // slither-disable-next-line calls-loop
    function getIndexForDataBefore(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bool _found, uint256 _index)
    {
        return tellor.getIndexForDataBefore(_queryId, _timestamp);
    }

    /**
     * @dev Retrieves multiple uint256 values before the specified timestamp
     * @param _queryId the unique id of the data query
     * @param _timestamp the timestamp before which to search for values
     * @param _maxAge the maximum number of seconds before the _timestamp to search for values
     * @param _maxCount the maximum number of values to return
     * @return _values the values retrieved, ordered from oldest to newest
     * @return _timestamps the timestamps of the values retrieved
     */
    function getMultipleValuesBefore(
        bytes32 _queryId,
        uint256 _timestamp,
        uint256 _maxAge,
        uint256 _maxCount
    )
        public
        view
        returns (bytes[] memory _values, uint256[] memory _timestamps)
    {
        // get index of first possible value
        (bool _ifRetrieve, uint256 _startIndex) = getIndexForDataAfter(
            _queryId,
            _timestamp - _maxAge
        );
        // no value within range
        if (!_ifRetrieve) {
            return (new bytes[](0), new uint256[](0));
        }
        uint256 _endIndex;
        // get index of last possible value
        (_ifRetrieve, _endIndex) = getIndexForDataBefore(_queryId, _timestamp);
        // no value before _timestamp
        if (!_ifRetrieve) {
            return (new bytes[](0), new uint256[](0));
        }
        uint256 _valCount = 0;
        uint256 _index = 0;
        uint256[] memory _timestampsArrayTemp = new uint256[](_maxCount);
        // generate array of non-disputed timestamps within range
        while (_valCount < _maxCount && _endIndex + 1 - _index > _startIndex) {
            uint256 _timestampRetrieved = getTimestampbyQueryIdandIndex(
                _queryId,
                _endIndex - _index
            );
            if (!isInDispute(_queryId, _timestampRetrieved)) {
                _timestampsArrayTemp[_valCount] = _timestampRetrieved;
                _valCount++;
            }
            _index++;
        }

        bytes[] memory _valuesArray = new bytes[](_valCount);
        uint256[] memory _timestampsArray = new uint256[](_valCount);
        // retrieve values and reverse timestamps order
        for (uint256 _i = 0; _i < _valCount; _i++) {
            _timestampsArray[_i] = _timestampsArrayTemp[_valCount - 1 - _i];
            _valuesArray[_i] = retrieveData(_queryId, _timestampsArray[_i]);
        }
        return (_valuesArray, _timestampsArray);
    }

    /**
     * @dev Counts the number of values that have been submitted for the queryId
     * @param _queryId the id to look up
     * @return uint256 count of the number of values received for the queryId
     */
    function getNewValueCountbyQueryId(bytes32 _queryId)
        public
        view
        returns (uint256)
    {
        return tellor.getNewValueCountbyQueryId(_queryId);
    }

    /**
     * @dev Returns the address of the reporter who submitted a value for a data ID at a specific time
     * @param _queryId is ID of the specific data feed
     * @param _timestamp is the timestamp to find a corresponding reporter for
     * @return address of the reporter who reported the value for the data ID at the given timestamp
     */
    function getReporterByTimestamp(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (address)
    {
        return tellor.getReporterByTimestamp(_queryId, _timestamp);
    }

    /**
     * @dev Gets the timestamp for the value based on their index
     * @param _queryId is the id to look up
     * @param _index is the value index to look up
     * @return uint256 timestamp
     */
    function getTimestampbyQueryIdandIndex(bytes32 _queryId, uint256 _index)
        public
        view
        returns (uint256)
    {
        return tellor.getTimestampbyQueryIdandIndex(_queryId, _index);
    }

    /**
     * @dev Determines whether a value with a given queryId and timestamp has been disputed
     * @param _queryId is the value id to look up
     * @param _timestamp is the timestamp of the value to look up
     * @return bool true if queryId/timestamp is under dispute
     */
    function isInDispute(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bool)
    {
        return tellor.isInDispute(_queryId, _timestamp);
    }

    /**
     * @dev Retrieve value from oracle based on queryId/timestamp
     * @param _queryId being requested
     * @param _timestamp to retrieve data/value from
     * @return bytes value for query/timestamp submitted
     */
    function retrieveData(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bytes memory)
    {
        return tellor.retrieveData(_queryId, _timestamp);
    }

    /**
     * @dev allows dev to set mapping contract for valueFor (EIP2362)
     * @param _addy address of mapping contract
     */
    function setIdMappingContract(address _addy) external {
        require(address(idMappingContract) == address(0));
        idMappingContract = IMappingContract(_addy);
    }

    /**
     * @dev Retrieve most recent int256 value from oracle based on queryId
     * @param _id being requested
     * @return _value most recent value submitted
     * @return _timestamp timestamp of most recent value
     * @return _statusCode 200 if value found, 404 if not found
     */
    function valueFor(bytes32 _id)
        external
        view
        override
        returns (
            int256 _value,
            uint256 _timestamp,
            uint256 _statusCode
        )
    {
        bytes32 _queryId = idMappingContract.getTellorID(_id);
        bytes memory _valueBytes;
        (_valueBytes, _timestamp) = getDataBefore(
            _queryId,
            block.timestamp + 1
        );
        if (_timestamp == 0) {
            return (0, 0, 404);
        }
        uint256 _valueUint = _sliceUint(_valueBytes);
        _value = int256(_valueUint);
        return (_value, _timestamp, 200);
    }

    // Internal functions
    /**
     * @dev Convert bytes to uint256
     * @param _b bytes value to convert to uint256
     * @return _number uint256 converted from bytes
     */
    function _sliceUint(bytes memory _b)
        internal
        pure
        returns (uint256 _number)
    {
        for (uint256 _i = 0; _i < _b.length; _i++) {
            _number = _number * 256 + uint8(_b[_i]);
        }
    }
}