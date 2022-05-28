/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.16 <0.9.0;

contract PaperScissorsStone {
    enum Actions {Invalid, Paper, Scissors, Stone}
    enum Status {Initial, Holder, Both, Completed}  
    struct Room{
        address holder;
        address participant;
        uint256 game_start_time;
        uint256 bet;
        Status status;
        bytes32 holder_action;
        Actions participant_action;
    }

    mapping(address => Room) public room;
    address [] public room_keys;
    uint constant public MIN_BET        = 1e15; // 0.001 ETH
    uint constant public REVEAL_TIMEOUT = 1 days;
    
    address owner;
    uint maker_fee; // the number of patitions of holder's fee 
    uint taker_fee; // the number of partitions of taker's fee
    uint partitions; // the number of total partition
    uint accumulate_fee;
    modifier validFee(uint _maker_fee, uint _taker_fee, uint _partitions) {
        require(
            _maker_fee >= 0 && _taker_fee >= 0 && _maker_fee + _taker_fee <= _partitions,
            "Wrong configuration of fee"
        ); 
        _;
    } 
    constructor(uint _maker_fee, uint _taker_fee, uint _partitions) validFee(_maker_fee, _taker_fee, _partitions) {
        owner = msg.sender;
        // maker/taker fee = 1/2 % => (1,2,100)
        maker_fee = _maker_fee;
        taker_fee = _taker_fee;
        partitions = _partitions;
    }
    
    modifier isOwner(){
        require(
            owner == msg.sender, 
            "You are not the contract owner"
        );
        _;
    }
    function AddHolder(address _holder) private {
        room_keys.push(_holder);
    } 
    function RemoveHolder(address _holder) private {
        uint idx;
        for(idx = 0; idx < room_keys.length; ++idx) {
            if(room_keys[idx] == _holder)
                break;
        }
        room_keys[idx] = room_keys[room_keys.length - 1];
        room_keys.pop();
    }
    function ListRooms() public view returns (address [] memory, address [] memory, uint256 [] memory, uint256 [] memory,
                                              Status [] memory, bytes32 [] memory, Actions [] memory){
        address [] memory holders = new address [] (room_keys.length);
        address [] memory participants = new address [] (room_keys.length);
        uint256 [] memory game_start_time = new uint256 [] (room_keys.length);
        uint256 [] memory bet = new uint256 [] (room_keys.length);
        Status [] memory status = new Status [] (room_keys.length);
        bytes32 [] memory holder_actions = new bytes32 [] (room_keys.length);
        Actions [] memory participant_actions = new Actions [] (room_keys.length);
        for(uint i = 0; i < room_keys.length; ++i){
            holders[i] = room[room_keys[i]].holder;
            participants[i] = room[room_keys[i]].participant;
            game_start_time[i] = room[room_keys[i]].game_start_time;
            bet[i] = room[room_keys[i]].bet;
            status[i] = room[room_keys[i]].status;
            holder_actions[i] = room[room_keys[i]].holder_action;
            participant_actions[i] = room[room_keys[i]].participant_action;
        }
        return (holders, participants, game_start_time, bet, status, holder_actions, participant_actions);
    }

    function getFee() public view returns (uint, uint, uint) {
        return (maker_fee, taker_fee, partitions);
    }

    function AdjustFee (uint _maker_fee, uint _taker_fee, uint _partitions) public isOwner validFee (_maker_fee, _taker_fee, _partitions) {
        maker_fee = _maker_fee;
        taker_fee = _taker_fee;
        partitions = _partitions; 
    }

    function ClaimFee(address payable claim_address, uint amount) payable public isOwner{
        require(amount <= address(this).balance, "No enough fee");
        require(amount <= accumulate_fee, "No enough fee");
        accumulate_fee -= amount;
        claim_address.transfer(amount);
    }

    modifier TimeOut(address _holder) {
        require(
            room[_holder].status == Status.Both, 
            "The game had not started yet."
        );
        require(
            block.timestamp > (room[_holder].game_start_time + REVEAL_TIMEOUT),
            "Please wait a little longer for reveal."
        );
        _;
    }

    modifier validParticipant(address _holder) {
        require(
            room[_holder].participant == msg.sender, 
            "Please check the room holder."
        );
        _;
    }

    event Exceed_Time_Out_EVENT(address _holder, address _participant);

    function ExceedTimeout(address _holder) public payable TimeOut(_holder) validParticipant(_holder) {
        room[_holder].status = Status.Completed;
        emit Exceed_Time_Out_EVENT(room[_holder].holder, room[_holder].participant);
        uint256 player_bet = (room[_holder].bet / partitions) * (partitions - taker_fee);
        uint256 owner_fee = room[_holder].bet - player_bet;
        RemoveHolder(_holder);
        reset(_holder);
        payable(msg.sender).transfer(player_bet);
        accumulate_fee += owner_fee;
    }

    // Check whether someone already held the game.
    modifier validHeld() {
        require(
            room[msg.sender].status == Status.Initial,
            "You have held a room."
        );
        _;
    }

    modifier validRoom(address _holder) {
        require(
            room[_holder].status == Status.Holder && room[_holder].bet == msg.value, 
            "The address is wrong or the bet is wrong." 
        );
        _;
    }

    modifier validBet() {
        require(
            msg.value >= MIN_BET,
            "Your bet value is lower than MIN_BET."
        );
        _;
    }

    modifier existRoom(address _holder) {
        require(room[_holder].status != Status.Initial, "There is no room.");
        _;
    }

    event Create_Eliminate_Room_EVENT(address _holder, uint256 _bet, Status _status);
    event Participate_Room_EVENT(address _holder, address _participant, uint256 _game_start_time);
    
    function HoldGame(bytes32 _holder_action) public payable validHeld validBet {
        room[msg.sender] = Room({
            holder: msg.sender,
            participant: address(0x0),        
            game_start_time: 0,
            bet: msg.value,
            status: Status.Holder,
            holder_action: _holder_action,
            participant_action: Actions.Invalid
        });
        AddHolder(msg.sender);
        emit Create_Eliminate_Room_EVENT(room[msg.sender].holder, room[msg.sender].bet, room[msg.sender].status);
    }

    function LeaveGame(address payable _holder) public existRoom(_holder){
        require(msg.sender == _holder && room[_holder].status == Status.Holder, "You are not the holder of the room or the game has started");
        uint256 bet = room[_holder].bet;
        reset(_holder);
        _holder.transfer(bet); 
        Status status = room[_holder].status;
        RemoveHolder((_holder));
        emit Create_Eliminate_Room_EVENT(_holder, bet, status);
    }
    
    modifier validActions(Actions _action) {
        require( _action == Actions.Paper || _action == Actions.Scissors || _action == Actions.Stone,
                "Your action is not one of papaer, scissors or and stone."
        );
        _;
    }

    function Participate(address _holder, Actions _action) public payable validRoom(_holder) validActions(_action) {
        room[_holder].participant = msg.sender;
        room[_holder].game_start_time = block.timestamp;
        room[_holder].bet += msg.value;
        room[_holder].status = Status.Both;
        room[_holder].participant_action = _action; 
        emit Participate_Room_EVENT(room[_holder].holder, room[_holder].participant, room[_holder].game_start_time);
    }

    function getRoom(address _holder) public view existRoom(_holder) returns (address, address, uint256) {
        return (room[_holder].holder, room[_holder].participant, room[_holder].bet);
    }

    // Return contract balance
    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    // Return contract revenue balance
    function getContractRevenueBalance() public view returns (uint) {
        return accumulate_fee;
    }

    modifier validReveal() {
        require (
            room[msg.sender].status == Status.Both,
            "You are not in a game."
        );
        _;
    }

    function ToString(Actions _action) private pure returns (string memory) {
        if(_action == Actions.Paper) return "1";
        else if(_action == Actions.Scissors) return "2";
        else if(_action == Actions.Stone) return "3";
        else return "0";
    }

    error InvalidPassphrase(string passphrase);

    function HolderReveal(Actions _action, string memory privateKey) public validReveal validActions(_action){
        string memory _passphrase = string(abi.encodePacked(ToString(_action), "_", privateKey)); 
        bytes32 encryptedActionsCheck = sha256(abi.encodePacked(_passphrase));
        if(encryptedActionsCheck == room[msg.sender].holder_action) {
            room[msg.sender].status = Status.Completed;        
            Actions _participant_action = room[msg.sender].participant_action; 
            Actions _holder_action      = _action;
            address payable _holder = payable(room[msg.sender].holder);
            address payable _participant = payable(room[msg.sender].participant);
            uint256 _bet = room[msg.sender].bet;
            RemoveHolder(_holder);
            reset(_holder);
            emit Create_Eliminate_Room_EVENT(_holder, _bet, Status.Completed);
            if(_holder_action == _participant_action) {
                // draw 
                uint256 holder_bet = (_bet / partitions) / 2 * (partitions - maker_fee);
                uint256 participant_bet = (_bet / partitions) / 2 * (partitions - taker_fee);
                uint256 owner_fee = _bet - holder_bet - participant_bet;
                accumulate_fee += owner_fee;
                _holder.transfer(holder_bet);    
                _participant.transfer(participant_bet);    
            }       
            else if(_holder_action == Actions.Paper    && _participant_action == Actions.Stone || 
                    _holder_action == Actions.Scissors && _participant_action == Actions.Paper ||
                    _holder_action == Actions.Stone    && _participant_action == Actions.Scissors) {
                // holder win
                uint256 holder_bet = (_bet / partitions) * (partitions - maker_fee);
                uint256 owner_fee = _bet - holder_bet;
                accumulate_fee += owner_fee;
                _holder.transfer(holder_bet);
            } 
            else {
                // participant win
                uint256 participant_bet = (_bet / partitions) * (partitions - taker_fee);
                uint256 owner_fee = _bet - participant_bet;
                accumulate_fee += owner_fee;
                _participant.transfer(participant_bet);
            }
        }
        else {
            revert InvalidPassphrase({
                passphrase: _passphrase   
            });
        }
    }

    function reset(address _holder) private {
        room[_holder].holder              = address(0x0);
        room[_holder].participant         = address(0x0);
        room[_holder].game_start_time     = 0;
        room[_holder].bet                 = 0;
        room[_holder].status              = Status.Initial; 
        room[_holder].holder_action       = 0x0;
        room[_holder].participant_action  = Actions.Invalid;
    }
}