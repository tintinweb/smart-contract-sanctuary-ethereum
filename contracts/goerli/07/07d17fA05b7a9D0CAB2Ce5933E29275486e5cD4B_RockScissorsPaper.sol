// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

enum Choice {
    UNKNOWN,
    ROCK,
    SCISSORS,
    PAPER
}
enum GameState {
    UNKNOWN,
    OPEN,
    OVER,
    DRAW
}

struct Game {
    uint256 id;
    uint256 entrance_deposit_wei;
    address payable maker; // MANDATORY
    address payable taker;
    GameState state; // enum GameState { ON, OVER, BLOCKED }
    address winner;
    mapping(address => Choice) choises; // enum Choice { ROCK, SCISSORS,  PAPER }
}

contract RockScissorsPaper {
    uint256 _games_count;
    uint256 _game_entrance_deposit_wei; // <= TODO MOVE TO GAME
    uint256 _withdraw_commission_permille;

    address _contract_owner;

    mapping(address => uint256) _ballances_wei;

    mapping(uint256 => Game) _games;

    modifier guard__msg_sender_is_contract_owner() {
        require(msg.sender == _contract_owner);
        _;
    }

    modifier guard__game(uint256 id) {
        require(_games[id].maker != address(0x0), "No game for id");
        _;
    }

    modifier guard__player_makes_game_entrance_deposit() {
        uint256 value_wei = msg.value; // players deposited amount of { ether } (in wei)
        require(
            value_wei == _game_entrance_deposit_wei,
            "To MAKE/TAKE a game you need to send value=getGameEntranceDeposit_wei() alongside this function"
        );
        _;
    }

    modifier guard__address_is_not_zero(address account) {
        require(
            account != address(0x0),
            "reciever must differ from address(0x0) - we don't burn"
        );
        _;
    }

    event Event_Game(
        uint256 indexed id,
        uint256 entrance_deposit_wei,
        address maker,
        address taker,
        GameState state,
        address winner,
        //
        string ___function___
    );

    /// address from == msg.sender
    /// address to   == address(this)
    event Event_Deposit(
        address from,
        address to,
        uint256 value,
        string function_name
    );

    event Event_Payout(
        address from,
        address to,
        uint256 payout_wei,
        uint256 totalDeposit_wei,
        uint256 withdraw_commission_wei,
        string function_name
    );

    constructor() {
        _contract_owner = address(msg.sender);
        _withdraw_commission_permille = 125; // == 12,5% (base: 2*playersDeposit)

        _game_entrance_deposit_wei = 0.1 * 10**18; // <= TODO? MOVE->game
    }

    /// CONTRACT_OWNER
    ///
    function transferContractOwnerShip(address newContractOwner)
        public
        guard__msg_sender_is_contract_owner
    {
        _contract_owner = newContractOwner;
    }

    /// caller needs to send  value==getGameEntranceDeposit_wei()
    ///
    /// @dev ++_games_count == creates a higher number first, then uses the increased value for new Game.
    /// there will NEVER be a game with id==0 in the games hashmap
    /// _games_count==0 means there are NO games in total
    function makeGame(Choice makers_choice)
        public
        payable
        guard__player_makes_game_entrance_deposit
        returns (uint256 id)
    {
        address payable maker = payable(msg.sender);
        id = ++_games_count;

        Game storage game = _games[id];
        game.id = id;
        game.entrance_deposit_wei = _game_entrance_deposit_wei; // <= TODO ? MOVE->game
        game.maker = maker;
        game.choises[maker] = makers_choice;

        game.taker = payable(address(0x0));
        game.winner = payable(address(0x0));
        game.state = GameState.OPEN;

        deposit(); // => emit Event_Deposit

        emit Event_Game(
            id,
            game.entrance_deposit_wei,
            game.maker,
            game.taker,
            game.state,
            game.winner,
            "makeGame"
        );

        return id;
    }

    /// caller needs to send  value==getGameEntranceDeposit_wei()
    ///
    function takeGame(uint256 id, Choice takers_choice)
        public
        payable
        guard__player_makes_game_entrance_deposit
        guard__game(id)
        returns (address winner)
    {
        Game storage game = _games[id];

        require(game.state == GameState.OPEN, "This game is OVER/DRAW");

        address payable maker = payable(game.maker);
        address payable taker = payable(msg.sender);
        require(
            taker != maker,
            "Who takes the game must be different from the one who made the game"
        );

        game.taker = taker;
        game.choises[taker] = takers_choice;

        // --- DEPOSIT ---
        // the taker makes his deposit of game.entrance_deposit_wei
        //
        deposit(); // => emit Event_Deposit

        // --- PICK_WINNER ---
        Choice makers_choice = game.choises[maker];

        // enum Choice { ROCK, SCISSORS, PAPER }
        if (
            (makers_choice == Choice.ROCK &&
                takers_choice == Choice.SCISSORS) ||
            (makers_choice == Choice.SCISSORS &&
                takers_choice == Choice.PAPER) ||
            (makers_choice == Choice.PAPER && takers_choice == Choice.ROCK)
        ) {
            winner = maker;
            game.state = GameState.OVER;
        } else if (
            (takers_choice == Choice.ROCK &&
                makers_choice == Choice.SCISSORS) ||
            (takers_choice == Choice.SCISSORS &&
                makers_choice == Choice.PAPER) ||
            (takers_choice == Choice.PAPER && makers_choice == Choice.ROCK)
        ) {
            winner = taker;
            game.state = GameState.OVER;
        } else if (
            (takers_choice == Choice.ROCK && makers_choice == Choice.ROCK) ||
            (takers_choice == Choice.SCISSORS &&
                makers_choice == Choice.SCISSORS) ||
            (takers_choice == Choice.PAPER && makers_choice == Choice.PAPER)
        ) {
            // NO_WINNER
            winner = address(0x0);
            game.state = GameState.DRAW;
        }
        // UPDATE_GAME
        game.winner = winner;

        emit Event_Game(
            game.id,
            game.entrance_deposit_wei,
            game.maker,
            game.taker,
            game.state,
            game.winner,
            "takeGame"
        );

        // PAYOUT
        if (game.state == GameState.OVER) {
            // address payable reciever = payable(
            //     0xE78eE1116D0aEDc53A3df0DEC701edb9B6cAceeA
            // );

            address payable reciever = payable(game.winner);

            require(
                reciever != address(0x0),
                "reciever must differ from address(0x0) - we don't burn"
            );

            require(
                _ballances_wei[game.taker] >= game.entrance_deposit_wei,
                "_ballances_wei[game.taker] >= game.entrance_deposit_wei"
            );
            require(
                _ballances_wei[game.maker] >= game.entrance_deposit_wei,
                "_ballances_wei[game.maker] >= game.entrance_deposit_wei"
            );

            _ballances_wei[game.taker] -= game.entrance_deposit_wei;
            _ballances_wei[game.maker] -= game.entrance_deposit_wei;

            //
            // --- CALCULATE_COMMISSION ---
            //
            // https://ethereum.stackexchange.com/questions/41616/assign-decimal-to-a-variable-in-solidity
            //
            uint256 totalDeposit_wei = game.entrance_deposit_wei * 2;

            uint256 withdraw_commission_wei = (totalDeposit_wei *
                _withdraw_commission_permille) / 1000; // must return a whole nuber

            uint256 payout_wei = totalDeposit_wei - withdraw_commission_wei;

            reciever.transfer(payout_wei);

            //
            // --- EVENT ---
            //
            emit Event_Payout(
                address(this), // address from,
                reciever, // address to,
                payout_wei, // uint256 value,
                totalDeposit_wei,
                withdraw_commission_wei,
                "takeGame" //string function_name
            );
        }
        //
        else if (game.state == GameState.DRAW) {
            // WTF
        }

        return winner;
    }

    function isGameOver(uint256 id) public view guard__game(id) returns (bool) {
        return (_games[id].state == GameState.OVER);
    }

    function isGameDraw(uint256 id) public view guard__game(id) returns (bool) {
        return (_games[id].state == GameState.DRAW);
    }

    function getWinner(uint256 id)
        public
        view
        guard__game(id)
        returns (address)
    {
        GameState gameState = _games[id].state;
        require(gameState != GameState.DRAW, "Game is DRAW - no winner yet");
        require(
            gameState != GameState.OPEN,
            "Game needs a TAKER - no winner yet"
        );

        return _games[id].winner;
    }

    function getGameEntranceDeposit_wei() public view returns (uint256) {
        return _game_entrance_deposit_wei;
    }

    function setGameEntranceDeposit_wei(uint256 game_entrance_deposit_wei)
        public
        guard__msg_sender_is_contract_owner
    {
        _game_entrance_deposit_wei = game_entrance_deposit_wei;
    }

    function getWithdrawCommission_permille() public view returns (uint256) {
        return _withdraw_commission_permille;
    }

    /// @dev 250 permille == 25%
    ///
    function setWithdrawCommission_permille(uint256 permille)
        public
        guard__msg_sender_is_contract_owner
    {
        _withdraw_commission_permille = permille;
    }

    /// .deposit() is used as endpoint to recieve eth
    ///
    /// EXAMPLE:
    /// const tx = await deposit().send({from:alice, value:toWei({ eth: "0.01" }) });
    ///
    function deposit() public payable {
        //
        address from = msg.sender;
        address to = address(this);
        uint256 value = msg.value;
        string memory function_name = "deposit";

        _ballances_wei[msg.sender] += value;

        emit Event_Deposit(from, to, value, function_name);
    }

    function transfer(uint256 amount_wei, address payable reciever)
        private
        guard__address_is_not_zero(reciever)
    {
        require(
            _ballances_wei[reciever] >= amount_wei,
            "amount_wei must be lessThenOrEqual the recievers current ballance"
        );

        _ballances_wei[reciever] -= amount_wei;

        reciever.transfer(amount_wei);
    }
}