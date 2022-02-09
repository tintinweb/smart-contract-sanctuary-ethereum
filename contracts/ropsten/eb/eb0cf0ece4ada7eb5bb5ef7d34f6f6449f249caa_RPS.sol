/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract RPS {
    constructor() payable {}

    /*
    event GameCreated(address originator, uint256 originator_bet);
    event GameJoined(address originator, address taker, uint256 originator_bet, uint256 taker_bet);
    event OriginatorWin(address originator, address taker, uint256 betAmount);
    event TakerWin(address originator, address taker, uint256 betAmount);
   */
    event CreatedRoom(uint256 roomNumber, uint256 betAmount);
    event JoinedRoom(uint256 roomNumber, Stage stage);
    event DrawGame(uint256 betAmount);
    event OriginatorWin(address originator);
    event TakerWin(address taker);
    event GameStarted(GameStatus gameStarted);
    event GameEnd(GameStatus gameEnd);

    // advenced : add none
    enum Hand {
        rock,
        paper,
        scissors,
        none
    }

    enum PlayerStatus {
        STATUS_WIN,
        STATUS_LOSE,
        STATUS_TIE,
        STATUS_PENDING
    }

    enum GameStatus {
        STATUS_NOT_STARTED,
        STATUS_STARTED,
        STATUS_COMPLETE,
        STATUS_ERROR
    }

    enum Stage {
        STAGE_COMMIT,
        STAGE_FIRST_REVEAL,
        STAGE_SECOND_REVEAL,
        STAGE_COMPARE,
        STAGE_DISTRIBUTE
    }

    // player structure
    struct Player {
        Hand hand;
        // advenced
        bytes32 commitment;
        address payable addr;
        PlayerStatus playerStatus;
        uint256 playerBetAmount;
    }

    struct Game {
        uint256 betAmount;
        GameStatus gameStatus;
        // advenced
        Stage stage;
        Player originator;
        Player taker;
    }

    mapping(uint256 => Game) rooms;
    uint256 roomLen = 0;

    // reveal 단계에서 사용
    modifier isValidHand(Hand _hand) {
        require(
            (_hand == Hand.rock) ||
                (_hand == Hand.paper) ||
                (_hand == Hand.scissors)
        );
        _;
    }

    // reveal 단계에서 사용
    modifier isPlayer(uint256 roomNum, address sender) {
        require(
            sender == rooms[roomNum].originator.addr ||
                sender == rooms[roomNum].taker.addr
        );
        _;
    }

    // hand 부분에 hashed 값이 들어가면 됨
    // isVaildHand는 주석처리 예정
    // remove isValidHand(_hand)
    // Hand _hand 인자 commitment로 수정
    // commit phase에서는 Player.hand 는 none으로 처리
    function createRoom(bytes32 _commitment)
        public
        payable
        returns (uint256 roomNum)
    {
        rooms[roomLen] = Game({
            betAmount: msg.value,
            gameStatus: GameStatus.STATUS_NOT_STARTED,
            stage: Stage.STAGE_COMMIT,
            originator: Player({
                hand: Hand.none,
                commitment: _commitment,
                addr: payable(msg.sender),
                playerStatus: PlayerStatus.STATUS_PENDING,
                playerBetAmount: msg.value
            }),
            taker: Player({ // will change
                hand: Hand.none,
                commitment: _commitment,
                addr: payable(msg.sender),
                playerStatus: PlayerStatus.STATUS_PENDING,
                playerBetAmount: 0
            })
        });
        roomNum = roomLen;
        roomLen = roomLen + 1;

        emit CreatedRoom(roomNum, msg.value);
    }

    // 방 넘버는 프론트에서 지정해줌, hand 부분에만 hashed 값이 들어가면 됨
    // isVaildHand는 주석처리 예정
    // msg.value 값 고정 - originator와 같은 값으로
    // Hand _hand 인자 commitment로 수정
    // isValidHand(_hand) 삭제
    function joinRoom(uint256 roomNum, bytes32 _commitment) public payable {
        // Emit gameJoined(game.originator.addr, msg.sender, game.betAmount, msg.value);
        // second commit 으로 stage 수정
        rooms[roomNum].taker = Player({
            hand: Hand.none,
            commitment: _commitment,
            addr: payable(msg.sender),
            playerStatus: PlayerStatus.STATUS_PENDING,
            playerBetAmount: msg.value
        });
        rooms[roomNum].betAmount = rooms[roomNum].betAmount + msg.value;
        // compareHands(roomNum);
        rooms[roomNum].stage = Stage.STAGE_FIRST_REVEAL;
        // game started
        rooms[roomNum].gameStatus = GameStatus.STATUS_STARTED;
        // reveal

        emit JoinedRoom(roomNum, Stage.STAGE_FIRST_REVEAL);
        emit GameStarted(GameStatus.STATUS_STARTED);
    }

    // commit phase 끝
    // reveal phase를 만들어야 함
    // reveal phase에서 player 찾고 firstReveal, secondReveal만 체크하면 될 듯
    // player 찾는건 msg.sender로
    // 두 phase가 다 끝나면 compareHands로 넘어가기
    // roomNum은 프론트에서 자동으로 주기
    // password로 reveal 할 때 넣기
    function reveal(
        uint256 roomNum,
        Hand _hand,
        bytes32 password
    ) public isValidHand(_hand) isPlayer(roomNum, msg.sender) {
        // only run reveal stage
        require(
            rooms[roomNum].stage == Stage.STAGE_FIRST_REVEAL ||
                rooms[roomNum].stage == Stage.STAGE_SECOND_REVEAL,
            "not at reveal stage"
        );

        // Find the player
        if (rooms[roomNum].originator.addr == msg.sender) {
            // Check the hash to ensure the commitment is correct
            require(
                keccak256(abi.encodePacked(msg.sender, _hand, password)) ==
                    rooms[roomNum].originator.commitment,
                "invalid hash"
            );
            rooms[roomNum].originator.hand = _hand;
        } else if (rooms[roomNum].taker.addr == msg.sender) {
            require(
                keccak256(abi.encodePacked(msg.sender, _hand, password)) ==
                    rooms[roomNum].taker.commitment,
                "invalid hash"
            );
            rooms[roomNum].taker.hand = _hand;
        } else revert("unknown player");

        // change phase
        if (rooms[roomNum].stage == Stage.STAGE_FIRST_REVEAL) {
            rooms[roomNum].stage = Stage.STAGE_SECOND_REVEAL;
        } else {
            rooms[roomNum].stage = Stage.STAGE_COMPARE;
            compareHands(roomNum);
        }
    }

    // reveal phase에서 받은 가위/바위/보 값으로 compareHands 실행
    // reveal 끝나면 바로 compareHands, compareHands 끝나면 payout이 실행되게
    function compareHands(uint256 roomNum) private {
        require(
            rooms[roomNum].stage == Stage.STAGE_COMPARE,
            "not at compare stage"
        );

        uint8 originator = uint8(rooms[roomNum].originator.hand);
        uint8 taker = uint8(rooms[roomNum].taker.hand);

        if (taker == originator) {
            //draw
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_TIE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_TIE;
            emit DrawGame(rooms[roomNum].originator.playerBetAmount);
        } else if ((taker + 1) % 3 == originator) {
            // originator wins
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_WIN;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_LOSE;
            emit OriginatorWin(rooms[roomNum].originator.addr);
        } else if ((originator + 1) % 3 == taker) {
            // taker wins
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_LOSE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_WIN;
            emit TakerWin(rooms[roomNum].taker.addr);
        } else {
            rooms[roomNum].gameStatus = GameStatus.STATUS_ERROR;
        }

        // check error
        require(
            rooms[roomNum].gameStatus != GameStatus.STATUS_ERROR,
            "error in game"
        );

        // change stage
        rooms[roomNum].stage = Stage.STAGE_DISTRIBUTE;

        payout(roomNum);
    }

    // reveal에서 호출하고 호출했기 때문에 isPlayer는 따로 필요없다.
    // reveal에서 isPlayer를 검사하기 때문
    // isPlayer(roomNum, msg.sender)
    function payout(uint256 roomNum) public payable {
        // check stage
        require(
            rooms[roomNum].stage == Stage.STAGE_DISTRIBUTE,
            "cannot yet distribute"
        );

        if (
            rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_TIE &&
            rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_TIE
        ) {
            rooms[roomNum].originator.addr.transfer(
                rooms[roomNum].originator.playerBetAmount
            );
            rooms[roomNum].taker.addr.transfer(
                rooms[roomNum].taker.playerBetAmount
            );
        } else {
            if (
                rooms[roomNum].originator.playerStatus ==
                PlayerStatus.STATUS_WIN
            ) {
                rooms[roomNum].originator.addr.transfer(
                    rooms[roomNum].betAmount
                );
            } else if (
                rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_WIN
            ) {
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].betAmount);
            } else {
                rooms[roomNum].originator.addr.transfer(
                    rooms[roomNum].originator.playerBetAmount
                );
                rooms[roomNum].taker.addr.transfer(
                    rooms[roomNum].taker.playerBetAmount
                );
            }
        }
        rooms[roomNum].gameStatus = GameStatus.STATUS_COMPLETE;
        emit GameEnd(GameStatus.STATUS_COMPLETE);
    }
}