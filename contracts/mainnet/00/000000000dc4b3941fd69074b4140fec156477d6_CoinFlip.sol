/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// File: contracts/CoinFlip.sol

pragma solidity ^0.8.7;

contract CoinFlip {
    struct GameData {
        address p1;
        address p2;
        uint16 status;
        uint wager;

        bytes32 p1Hash;
        bytes32 p2Hash;
    }

    address private immutable OWNER_ADDRESS;

    mapping(uint176 => uint232) games;
    mapping(uint176 => bytes32) playerHashes;
    mapping(uint176 => uint) verifiedNumbers;

    event GameCreated(uint176 gameId, address player1, uint wager);
    event GameJoined(uint176 gameId, address player1, address player2, uint wager);
    // Between here the house will submit their own random number hash
    event GameRevealStart(uint176 gameId);
    event GameReady(uint176 gameId);
    // After all players have revealed their numbers the house will reveal and complete the game
    event GameCompleted(uint176 gameId, address player1, address player2, uint wager, uint ran);
    event GameCanceled(uint176 gameId);

    constructor() {
        OWNER_ADDRESS = msg.sender;
    }

    // ~68k gas
    function createGame(bytes32 hash) payable external returns (uint176 id) {
        // Ensure there isnt more than one decimal point in ETH (So we can pack it into a uint16)
        require(msg.value >= 0.2 ether && msg.value % 0.1 ether == 0, "Bad Wager Val");

        id = encodeGameID(msg.sender, msg.value);

        // Ensure game id doesn't already exist
        require(games[id] == 0, "Game exists");

        // Fill game data with status 1 (awaiting opponent)
        games[id] = encodeGameData(1, address(0));
        playerHashes[id + 1] = hash;
        emit GameCreated(id, msg.sender, msg.value);
    }

    // ~52k gas
    function joinGame(uint176 id, bytes32 hash) payable external {
        GameData memory g = getGameData(id, false);

        require(g.status == 1, "Bad Status");
        require(g.wager == msg.value, "Wrong Wager");

        // Update game data with player2 and status 2 (awaiting randomness)
        games[id] = encodeGameData(2, msg.sender);
        playerHashes[id+2] = hash;

        emit GameJoined(id, g.p1, msg.sender, g.wager);
    }

    // ~51k gas
    function houseJoinGame(uint176 id, bytes32 hash) external {
        require(msg.sender == OWNER_ADDRESS);

        GameData memory g = getGameData(id, false);

        require(g.status == 2, "Bad Status");

        playerHashes[id+3] = hash;
        games[id] = encodeGameData(3, g.p2);

        emit GameRevealStart(id);
    }

    // ~50 - 54k gas
    function reveal(uint176 id, uint N) external {
        GameData memory g = getGameData(id, false);

        require(g.status == 3, "Bad Status");

        if (g.p1 == msg.sender) {
            bytes32 providedHash = playerHashes[id+1];
            bytes32 realHash = getHash(N);
            require(providedHash == realHash, "Bad Hash");

            delete playerHashes[id+1];
            verifiedNumbers[id+1] = N;
            if (verifiedNumbers[id+2] != 0) {
                games[id] = encodeGameData(4, g.p2);
                emit GameReady(id);
            }
            return;
        } else if (g.p2 == msg.sender) {
            bytes32 providedHash = playerHashes[id+2];
            bytes32 realHash = getHash(N);
            require(providedHash == realHash, "Bad Hash");

            delete playerHashes[id+2];
            verifiedNumbers[id+2] = N;
            if (verifiedNumbers[id+1] != 0) {
                games[id] = encodeGameData(4, g.p2);
                emit GameReady(id);
            }
            return;
        }

        require(false, "Wrong Sender");
    }

    // ~48k gas
    function houseReveal(uint176 id, uint N) external {
        require(msg.sender == OWNER_ADDRESS);

        GameData memory g = getGameData(id, false);

        require(g.status == 4, "Bad Status");

        // Verify house hash
        bytes32 providedHash = playerHashes[id+3];
        bytes32 realHash = getHash(N);
        require(providedHash == realHash, "Bad Hash");

        uint ran = uint(keccak256(abi.encodePacked(verifiedNumbers[id+1], verifiedNumbers[id+2], N))) % 10000000;

        delete games[id];
        delete verifiedNumbers[id+1];
        delete verifiedNumbers[id+2];

        uint payout = g.wager * 2;
        uint fee = payout * 3 / 100;
        payout -= fee;

        // Player 1 wins
        if (ran % 2 == 0) {
            payable(g.p1).transfer(payout);
        } else {
            payable(g.p2).transfer(payout);
        }

        payable(OWNER_ADDRESS).transfer(fee);

        emit GameCompleted(id, g.p1, g.p2, g.wager, ran);
    }

    function encodeGameID(address player1, uint wager) pure private returns (uint176 id) {
        // Player1  -  160 bits
        // Wager -  16 bits

        id = uint176(uint160(player1));
        id |= uint176(wager / 100000000000000000)<<160;
    }

    function decodeGameID(uint176 encoded) pure private returns (address player1, uint wager) {
        player1 = address(uint160(encoded));
        wager = uint(encoded>>160) * 100000000000000000;
    }

    function encodeGameData(uint16 status, address player2) pure private returns (uint232) {
        // Status  -  16 bits
        // Player2 -  160 bits
        // Total: 176 bits

        // Status 0 = no game
        // Status 1 = Awaiting Opponent
        // Status 2 = Awaiting house hash
        // Status 3 = Player Reveal
        // Status 4 = Awaiting house reveal & payout

        uint232 encoded = uint232(status);
        encoded |= uint232(uint160(player2)) << 16;

        return encoded;
    }

    function decodeGameData(uint232 encoded) pure private returns (uint16 status, address player2) {
        status = uint16(encoded);
        player2 = address(uint160(encoded>>16));
    }

    function getGameData(uint176 id, bool needHash) public view returns (GameData memory g) {
        require(games[id] != 0, "Game doesn't exist");

        (g.p1, g.wager) = decodeGameID(id);
        (g.status, g.p2) = decodeGameData(games[id]);
        if (needHash) {
            (g.p1Hash, g.p2Hash) = (playerHashes[id+1], playerHashes[id+2]);
        }
    }

    function getHash(uint N) private view returns (bytes32 b) {
        b = keccak256(abi.encodePacked(msg.sender, N));
    }

    function cancelGame(uint176 id) external {
        GameData memory g = getGameData(id, false);

        // Take fee (if necessary) from the player that canceled
        if (g.p1 == msg.sender) {
            delete games[id];
            delete playerHashes[id+1];

            if (g.status == 1) {
                // No player 2 yet
                payable(g.p1).transfer(g.wager);
                return;
            }

            if (g.status >= 2)
                delete playerHashes[id+2];

            if (g.status >= 3) {
                delete playerHashes[id+3];
                delete verifiedNumbers[id+1];
                delete verifiedNumbers[id+2];
            }

            payable(OWNER_ADDRESS).transfer(0.01 ether);
            payable(g.p1).transfer(g.wager - 0.01 ether);
            payable(g.p2).transfer(g.wager);
            emit GameCanceled(id);
            return;
        } else if (g.p2 == msg.sender) {
            delete games[id];
            delete playerHashes[id+1];
            delete playerHashes[id+2];

            if (g.status >= 3) {
                delete playerHashes[id+3];
                delete verifiedNumbers[id+1];
                delete verifiedNumbers[id+2];
            }

            payable(OWNER_ADDRESS).transfer(0.01 ether);
            payable(g.p1).transfer(g.wager);
            payable(g.p2).transfer(g.wager - 0.01 ether);
            emit GameCanceled(id);
            return;
        }

        require(false, "Wrong Address");
    }

    function destruct() external {
        require(msg.sender == OWNER_ADDRESS);

        selfdestruct(payable(OWNER_ADDRESS));
    }
}