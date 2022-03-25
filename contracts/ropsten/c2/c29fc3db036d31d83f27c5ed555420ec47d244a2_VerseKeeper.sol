/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

// SPDX-License-Identifier: --BCOM--

pragma solidity =0.8.12;

contract VerseKeeper {

    address public verseKeeper;
    uint256 public totalRequired;

    uint256 immutable minTimeFrame;
    address immutable verseTokenAddress;

    struct KeeperInfo {
        uint256 keeperRate;
        uint256 keeperFrom;
        uint256 keeperTill;
        uint256 keeperBalance;
        uint256 keeperPayouts;
    }

    mapping(address => KeeperInfo) public keeperList;

    modifier onlyVerseKeeper() {
        require(
            msg.sender == verseKeeper,
            "VerseKeeper: ACCESS_DENIED"
        );
        _;
    }

    event recipientCreated(
        address indexed recipient,
        uint256 timeLock,
        uint256 timeReward,
        uint256 instantReward,
        uint256 timestamp
    );

    event tokensScraped(
        address indexed scraper,
        uint256 scrapedAmount,
        uint256 timestamp
    );

    constructor(
        address _verseKeeper,
        uint256 _minTimeFrame,
        address _verseTokenAddress
    ) {
        if (_verseKeeper == address(0)) {
            revert("VerseKeeper: INVALID_KEEPER");
        }

        if (_minTimeFrame == 0) {
            revert("VerseKeeper: INVALID_TIMEFRAME");
        }

        if (_verseTokenAddress == address(0)) {
            revert("VerseKeeper: INVALID_VERSE_TOKEN");
        }

        verseKeeper = _verseKeeper;
        minTimeFrame = _minTimeFrame;
        verseTokenAddress = _verseTokenAddress;
    }

    function allocateTokensBulk(
        address[] memory _recipients,
        uint256[] memory _tokensOpened,
        uint256[] memory _tokensLocked,
        uint256[] memory _timeFrame
    )
        external
        onlyVerseKeeper
    {
        for (uint256 i = 0; i < _recipients.length; i++) {
            allocateTokens(
                _recipients[i],
                _tokensOpened[i],
                _tokensLocked[i],
                _timeFrame[i]
            );
        }
    }

    function allocateTokens(
        address _recipient,
        uint256 _tokensOpened,
        uint256 _tokensLocked,
        uint256 _timeFrame
    )
        public
        onlyVerseKeeper
    {
        require(
            _timeFrame >= minTimeFrame,
            "VerseKeeper: INVALID_TIME_FRAME"
        );

        totalRequired = totalRequired
            + _tokensOpened
            + _tokensLocked;

        _checkVerseBalance(
            totalRequired
        );

        uint256 timestamp = getNow();

        keeperList[_recipient].keeperFrom = timestamp;
        keeperList[_recipient].keeperTill = timestamp
            + _timeFrame;

        keeperList[_recipient].keeperRate = _tokensLocked
            / _timeFrame;

        keeperList[_recipient].keeperBalance = _tokensLocked
            % _timeFrame
            + _tokensOpened;

        emit recipientCreated(
            _recipient,
            _timeFrame,
            _tokensLocked,
            _tokensOpened,
            timestamp
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

        _safeVerseScrape(
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
        uint256 timePassed =
            getNow() < keeperList[_recipient].keeperTill ?
            getNow() - keeperList[_recipient].keeperFrom : _diff(_recipient);

        balance = keeperList[_recipient].keeperRate
            * timePassed
            + keeperList[_recipient].keeperBalance
            - keeperList[_recipient].keeperPayouts;
    }

    function lockedBalance(
        address _recipient
    )
        external
        view
        returns (uint256 balance)
    {
        uint256 timeRemaining =
            keeperList[_recipient].keeperTill > getNow() ?
            keeperList[_recipient].keeperTill - getNow() : 0;

        balance = keeperList[_recipient].keeperRate
            * timeRemaining;
    }

    function getNow()
        public
        view
        returns (uint256 time)
    {
        time = block.timestamp;
    }

    function renounceOwnership()
        external
        onlyVerseKeeper
    {
        delete verseKeeper;
    }

    function _diff(
        address _recipient
    )
        private
        view
        returns (uint256 res)
    {
        res = keeperList[_recipient].keeperTill
            - keeperList[_recipient].keeperFrom;
    }

    bytes4 private constant TRANSFER = bytes4(
        keccak256(
            bytes(
                "transfer(address,uint256)"
            )
        )
    );

    bytes4 private constant BALANCEOF = bytes4(
        keccak256(
            bytes(
                "balanceOf(address)"
            )
        )
    );

    function _safeVerseScrape(
        address _to,
        uint256 _scrapeAmount
    )
        private
    {
        totalRequired -= _scrapeAmount;

        (bool success, bytes memory data) = verseTokenAddress.call(
            abi.encodeWithSelector(
                TRANSFER,
                _to,
                _scrapeAmount
            )
        );

        require(
            success && (
                data.length == 0 || abi.decode(
                    data, (bool)
                )
            ),
            "VerseKeeper: TRANSFER_FAILED"
        );
    }

    function _checkVerseBalance(
        uint256 _required
    )
        private
    {
        (bool success, bytes memory data) = verseTokenAddress.call(
            abi.encodeWithSelector(
                BALANCEOF,
                address(this)
            )
        );

        require(
            success && abi.decode(
                data, (uint256)
            ) >= _required,
            "VerseKeeper: BALANCE_CHECK_FAILED"
        );
    }
}