// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

contract LP {
    uint256 public liquidity = 1e12;
    uint256 public reinforcementDefault = 1e9;
    uint256 public multiplier = 1e6;
    uint256 public totalAmountBet;
    uint256 public maxPayOut;
    uint256 public margin = 50000;
    uint8 public lastEventId;
    mapping(uint256 => EventInfo) public eventInfos;

    struct EventInfo {
        uint8 eventId;
        uint8 market;
        uint256 reinforcement;
        uint256[] ratioWin;
        uint256 maxPayOut;
        uint256[] payOut;
    }

    function createEvent(uint256[] memory _ratioWin, uint8 _market) public {
        EventInfo storage eventInfo = eventInfos[lastEventId];
        eventInfo.eventId = lastEventId;
        eventInfo.market = _market;
        eventInfo.reinforcement = reinforcementDefault;
        eventInfo.ratioWin = _ratioWin;
        lastEventId++;
    }

    function placeBet(
        uint256 _amount,
        uint8 _outcome,
        uint8 _eventId
    ) public {
        EventInfo storage eventInfo = eventInfos[_eventId];
        if (_outcome < 0 || _outcome > eventInfo.market)
            revert IncorectOutcome();
        uint256[3] memory _odds = calculateOdd(_amount, _outcome,_eventId);
        if (_odds[_outcome] <= multiplier) revert OverMaxAmountBet();
        uint256 spending = eventInfo.maxPayOut - max(eventInfo.payOut,eventInfo.payOut[_outcome] + (_amount * _odds[_outcome]) / multiplier);
        if (
            eventInfo.maxPayOut + spending >=
            liquidity + _amount + totalAmountBet
        ) revert NotEnoughLiquidity();
        for (uint8 i = 0; i < 3; i++) {
            if (i == _outcome) {
                eventInfo.ratioWin[i] =
                    (((((eventInfo.ratioWin[i] / 100) * eventInfo.reinforcement) /
                        multiplier +
                        _amount) * multiplier) / (eventInfo.reinforcement + _amount)) *
                    100;
            } else {
                eventInfo.ratioWin[i] =
                    (((((eventInfo.ratioWin[i] / 100) * eventInfo.reinforcement) / multiplier) *
                        multiplier) / (eventInfo.reinforcement + _amount)) *
                    100;
            }
        }
        //update state
        uint256 preMaxpayOut = eventInfo.maxPayOut;
        totalAmountBet += _amount;
        eventInfo.reinforcement += _amount;
        eventInfo.payOut[_outcome] += (_amount * _odds[_outcome]) / multiplier;
        eventInfo.maxPayOut = max(eventInfo.payOut,0);
        maxPayOut += eventInfo.maxPayOut - preMaxpayOut;

        emit PlaceBet(_amount, _odds[_outcome], _outcome, eventInfo.reinforcement, eventInfo.maxPayOut);
    }

    function calculateOdd(uint256 _amount, uint8 _outcome, uint8 _eventId)
        public
        view
        returns (uint256[3] memory)
    { 
         EventInfo storage eventInfo = eventInfos[_eventId];
        uint256[3] memory _odds;
        for (uint8 i = 0; i < eventInfo.market; i++) {
            if (i == _outcome) {
                _odds[i] =
                    ((eventInfo.reinforcement + _amount) * multiplier) /
                    ((eventInfo.reinforcement * eventInfo.ratioWin[i]) / multiplier / 100 + _amount);
            } else {
                _odds[i] =
                    ((eventInfo.reinforcement + _amount) * multiplier) /
                    ((eventInfo.reinforcement * eventInfo.ratioWin[i]) / multiplier / 100);
            }
        }

        return (
            [
                (_odds[0] * multiplier) / (multiplier + margin),
                (_odds[1] * multiplier) / (multiplier + margin),
                (_odds[2] * multiplier) / (multiplier + margin)
            ]
        );
    }

    function max(uint256[] memory numbers, uint256 number) public pure returns (uint256) {
        require(numbers.length > 0);
        uint256 maxNumber;
        for (uint256 i = 0; i < numbers.length; i++) {
            if (numbers[i] > maxNumber) maxNumber = numbers[i];
        }
        if(maxNumber < number) maxNumber = number;
        return (maxNumber);
    }

    event PlaceBet(
        uint256 amount,
        uint256 odd,
        uint8 outcome,
        uint256 liquidity,
        uint256 payOut
    );

    error IncorectOutcome();
    error NotEnoughLiquidity();
    error OverMaxAmountBet();
}