/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RPS {
    uint256 roomNumber = 0;

    enum Hand {
        ROCK,
        PAPER,
        SCISSORS
    }

    struct Player {
        address payable addr;
        Hand hand;
        uint256 batting;
    }

    struct Game {
        Player representative;
        Player challenger;
        bytes32 encryptHand;
        uint8 win; // 방장기준 : 0 - 승리, 1 - 패배, 2 - 비김
        uint8 status; // 0 - 준비상태, 1 - 결과대기상태
    }
    // 게임방
    mapping(uint256 => Game) rooms;

    // hand modifier
    modifier isHand(Hand _hand) {
        // 0 - 주먹, 1 - 보, 2 - 가위 이외의 양의 정수 입력시 오류
        require(uint8(_hand) < 3);
        _;
    }

    // room modifier
    modifier isRoom(uint256 _roomNumber) {
        // 해당 게임방이 없을 경우 오류
        require(rooms[_roomNumber].representative.addr != address(0));
        _;
    }

    /* 가위바위보 게임을 하기 위한 방 */
    // 방장은 인자로 자신이 낼 가위/바위/보 값과 베팅 금액을 넘겨줍니다.
    function createRoom(bytes32 _encryptHand)
        public
        payable
        returns (uint256 _roomNumber)
    {
        rooms[roomNumber] = Game({
            encryptHand: _encryptHand,
            representative: Player({
                addr: payable(msg.sender),
                hand: Hand.ROCK,
                batting: msg.value
            }),
            challenger: Player({
                addr: payable(msg.sender),
                hand: Hand.ROCK,
                batting: 0
            }),
            win: 2, // 비긴상태
            status: 0 // 준비상태
        });
        _roomNumber = roomNumber++;
    }

    function joinRoom(uint256 _roomNumber, Hand _hand)
        public
        payable
        isHand(_hand)
        isRoom(_roomNumber)
        returns (uint8 _win)
    {
        // 도전자 정보 등록
        rooms[_roomNumber].challenger = Player({
            addr: payable(msg.sender),
            hand: _hand,
            batting: msg.value
        });

        if (
            // 방장이 비긴 경우
            rooms[_roomNumber].representative.hand ==
            rooms[_roomNumber].challenger.hand
        ) {
            rooms[_roomNumber].win = 2;
        } else if (
            // 방장이 이긴 경우
            (rooms[_roomNumber].representative.hand == Hand.ROCK &&
                rooms[_roomNumber].challenger.hand == Hand.SCISSORS) ||
            (rooms[_roomNumber].representative.hand == Hand.SCISSORS &&
                rooms[_roomNumber].challenger.hand == Hand.PAPER) ||
            (rooms[_roomNumber].representative.hand == Hand.PAPER &&
                rooms[_roomNumber].challenger.hand == Hand.ROCK)
        ) {
            rooms[_roomNumber].win = 1;
        } else {
            // 방장이 진 경우
            rooms[_roomNumber].win = 0;
        }
        _win = rooms[_roomNumber].win;
    }

    // 방장이 제시한 값 확인
    function checkHand(
        uint256 _roomNumber,
        Hand _hand,
        uint256 _nonce
    ) public isHand(_hand) isRoom(_roomNumber) returns (bool) {
        require(rooms[_roomNumber].status == 0);
        uint256 _value = uint256(_hand) + _nonce;
        bytes32 _encryptHand = keccak256(abi.encode(_value));
        if (_encryptHand == rooms[_roomNumber].encryptHand) {
            rooms[_roomNumber].representative.hand = _hand;
            rooms[_roomNumber].status = 1; // 결과 대기
            return true;
        } else {
            return false;
        }
    }

    // 게임의 결과에 따라 베팅 금액을 송금
    function payout(uint256 _roomNumber) public isRoom(_roomNumber) {
        require(rooms[_roomNumber].status == 1);
        // 방장이 이긴 경우
        if (rooms[_roomNumber].win == 1) {
            rooms[_roomNumber].representative.addr.transfer(
                rooms[_roomNumber].representative.batting +
                    rooms[_roomNumber].challenger.batting
            );
            // 비긴 경우
        } else if (rooms[_roomNumber].win == 2) {
            rooms[_roomNumber].representative.addr.transfer(
                rooms[_roomNumber].representative.batting
            );
            rooms[_roomNumber].challenger.addr.transfer(
                rooms[_roomNumber].challenger.batting
            );
            // 방장이 진 경우
        } else {
            rooms[_roomNumber].challenger.addr.transfer(
                rooms[_roomNumber].representative.batting +
                    rooms[_roomNumber].challenger.batting
            );
        }
        delete rooms[_roomNumber];
    }
}