// SPDX-License-Identifier: --BCOM--

pragma solidity =0.8.17;

import "./MerkleProof.sol";
import "./VerseHelper.sol";

contract VerseClaimer is VerseHelper {

    bytes32 public immutable merkleRoot;
    uint256 public immutable createTime;

    uint256 immutable minimumTimeFrame;

    struct KeeperInfo {
        uint256 keeperRate;
        uint256 keeperTill;
        uint256 keeperInstant;
        uint256 keeperPayouts;
    }

    mapping(address => KeeperInfo) public keeperList;

    constructor(
        bytes32 _merkleRoot,
        uint256 _minimumTimeFrame,
        address _verseTokenAddress
    )
        VerseHelper(_verseTokenAddress)
    {
        require(
            _minimumTimeFrame > 0,
            "VerseClaimer: INVALID_TIMEFRAME"
        );

        require(
            _merkleRoot > 0,
            "VerseClaimer: INVALID_MERKLE_ROOT"
        );

        createTime = getNow();
        merkleRoot = _merkleRoot;
        minimumTimeFrame = _minimumTimeFrame;
    }

    function enrollRecipient(
        uint256 _index,
        address _recipient,
        uint256 _tokensLocked,
        uint256 _tokensOpened,
        uint256 _timeFrame,
        bytes32[] calldata _merkleProof
    )
        external
    {
        _enrollRecipient(
            _index,
            _recipient,
            _tokensLocked,
            _tokensOpened,
            _timeFrame,
            _merkleProof
        );
    }

    function enrollRecipientBulk(
        uint256 _index,
        address[] calldata _recipient,
        uint256[] calldata _tokensLocked,
        uint256[] calldata _tokensOpened,
        uint256[] calldata _timeFrame,
        bytes32[][] calldata _merkleProof
    )
        external
    {
        require(
            _recipient.length < 10,
            "VerseClaimer: TOO_MANY"
        );

        for (uint256 i = 0; i < _recipient.length; i++) {
            _enrollRecipient(
                _index + i,
                _recipient[i],
                _tokensLocked[i],
                _tokensOpened[i],
                _timeFrame[i],
                _merkleProof[i]
            );
        }
    }

    function _enrollRecipient(
        uint256 _index,
        address _recipient,
        uint256 _tokensLocked,
        uint256 _tokensOpened,
        uint256 _timeFrame,
        bytes32[] memory _merkleProof
    )
        private
    {
        require(
            keeperList[_recipient].keeperTill == 0,
            "VerseClaimer: RECIPIENT_ALREADY_ENROLLED"
        );

        bytes32 node = keccak256(
            abi.encodePacked(
                _index,
                _recipient,
                _tokensLocked,
                _tokensOpened,
                _timeFrame
            )
        );

        require(
            MerkleProof.verify(
                _merkleProof,
                merkleRoot,
                node
            ),
            "VerseClaimer: INVALID_PROOF"
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
            _timeFrame >= minimumTimeFrame,
            "VerseClaimer: INVALID_TIME_FRAME"
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

        _checkVerseBalance(
            totalRequired
        );

        emit recipientEnrolled(
            _recipient,
            _timeFrame,
            _tokensLocked,
            _tokensOpened
        );
    }

    function enrollAndScrape(
        uint256 _index,
        uint256 _tokensLocked,
        uint256 _tokensOpened,
        uint256 _timeFrame,
        bytes32[] calldata _merkleProof
    )
        external
    {
        _enrollRecipient(
            _index,
            msg.sender,
            _tokensLocked,
            _tokensOpened,
            _timeFrame,
            _merkleProof
        );

        _scrapeTokens(
            msg.sender
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