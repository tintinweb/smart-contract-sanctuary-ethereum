// SPDX-License-Identifier: --WISE--

pragma solidity =0.8.18;

import "./ClaimerHelper.sol";

contract ClaimerContract is ClaimerHelper {

    address public immutable collector;
    uint256 public immutable createTime;
    uint256 public immutable minimumTime;

    struct KeeperInfo {
        uint256 keeperRate;
        uint256 keeperTill;
        uint256 keeperInstant;
        uint256 keeperPayouts;
    }

    mapping(address => KeeperInfo) public keeperList;

    modifier onlyCollector() {
        require(
            msg.sender == collector,
            "ClaimerContract: INVALID_COLLECTOR"
        );
        _;
    }

    constructor(
        address _collector,
        uint256 _timeFrame,
        address _tokenAddress
    )
        ClaimerHelper(
            _tokenAddress
        )
    {
        if (_timeFrame == 0) {
            revert("ClaimerContract: INVALID_TIMEFRAME");
        }

        collector = _collector;
        createTime = getNow();
        minimumTime = _timeFrame;
    }

    function enrollAndScrape(
        address _recipient,
        uint256 _tokensLocked,
        uint256 _tokensOpened,
        uint256 _timeFrame
    )
        external
        onlyCollector
    {
        _enrollRecipient(
            _recipient,
            _tokensLocked,
            _tokensOpened,
            _timeFrame
        );

        _scrapeTokens(
            _recipient
        );
    }

    function _enrollRecipient(
        address _recipient,
        uint256 _tokensLocked,
        uint256 _tokensOpened,
        uint256 _timeFrame
    )
        private
    {
        require(
            keeperList[_recipient].keeperTill == 0,
            "ClaimerContract: RECIPIENT_ALREADY_ENROLLED"
        );

        _allocateTokens(
            _recipient,
            _tokensLocked,
            _tokensOpened,
            _timeFrame
        );
    }

    function _allocateTokens(
        address _recipient,
        uint256 _tokensLocked,
        uint256 _tokensOpened,
        uint256 _timeFrame
    )
        private
    {
        require(
            _timeFrame >= minimumTime,
            "ClaimerContract: INVALID_TIME_FRAME"
        );

        totalRequired = totalRequired
            + _tokensOpened
            + _tokensLocked;

        keeperList[_recipient].keeperTill = createTime
            + _timeFrame;

        keeperList[_recipient].keeperRate = _tokensLocked
            / _timeFrame;

        keeperList[_recipient].keeperInstant = _tokensLocked
            % _timeFrame
            + _tokensOpened;

        _checkBalance(
            totalRequired
        );

        emit recipientEnrolled(
            _recipient,
            _timeFrame,
            _tokensLocked,
            _tokensOpened
        );
    }

    function scrapeMyTokens()
        external
    {
        _scrapeTokens(
            msg.sender
        );
    }

    function _scrapeTokens(
        address _recipient
    )
        private
    {
        uint256 scrapeAmount = availableBalance(
            _recipient
        );

        keeperList[_recipient].keeperPayouts += scrapeAmount;

        _safeScrape(
            _recipient,
            scrapeAmount
        );

        emit tokensScraped(
            _recipient,
            scrapeAmount,
            getNow()
        );
    }

    function availableBalance(
        address _recipient
    )
        public
        view
        returns (uint256 balance)
    {
        uint256 timeNow = getNow();
        uint256 timeMax = keeperList[_recipient].keeperTill;

        if (timeMax == 0) return 0;

        uint256 timePassed = timeNow > timeMax
            ? timeMax - createTime
            : timeNow - createTime;

        balance = keeperList[_recipient].keeperRate
            * timePassed
            + keeperList[_recipient].keeperInstant
            - keeperList[_recipient].keeperPayouts;
    }

    function lockedBalance(
        address _recipient
    )
        external
        view
        returns (uint256 balance)
    {
        uint256 timeNow = getNow();

        uint256 timeRemaining =
            keeperList[_recipient].keeperTill > timeNow ?
            keeperList[_recipient].keeperTill - timeNow : 0;

        balance = keeperList[_recipient].keeperRate
            * timeRemaining;
    }
}