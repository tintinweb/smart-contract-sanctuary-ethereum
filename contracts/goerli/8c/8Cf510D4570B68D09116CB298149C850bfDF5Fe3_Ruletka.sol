/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

contract Ruletka {
    
    /*** EVENTS ***/
    
    /// @dev A russian Roulette has been executed between 6 players
    /// in room roomId and unfortunately, victim got shot and didn't 
    /// make it out alive... RIP
    event partyOver(uint256 roomId, address victim, address[] winners);

    /// @dev A new player has enter a room
    event newPlayer(uint256 roomId, address player);
    
    /// @dev A room is full, we close the door. Game can start.
    event fullRoom(uint256 roomId);
    
    /// @dev A safety mechanism has been triggered to empty the room and refund entirely the players (Should never happen)
    event roomRefunded(uint256 _roomId, address[] refundedPlayers);

    /*** Founders addresses ***/
    address payable CTO;
    address payable CEO;
    
    
    Room[] private allRooms;

    fallback() external payable {} // Give the ability of receiving ether
    
    receive() external payable {}

    constructor() {
        CTO = payable(msg.sender);
        CEO = payable(msg.sender);
    }
    
    /*** ACCESS MODIFIERS ***/
    /// @dev Access modifier for CTO-only functionality
    modifier onlyCTO() {
        require(msg.sender == CTO, "Only owner !!!");
        _;
    }
    
    /// @dev Assigns a new address to act as the CTO.
    /// @param _newCTO The address of the new CTO
    function setCTO(address payable _newCTO) public onlyCTO {
        require(_newCTO != address(0));
        CTO = _newCTO;
    }
    
    /// @dev Assigns a new address to act as the CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address payable _newCEO) public onlyCTO {
        require(_newCEO != address(0));
        CEO = _newCEO;
    }
    
    /*** DATATYPES ***/
    struct Room {
        string name;
        uint256 entryPrice; //  The price to enter the room and play Russian Roulette
        uint256 balance;
        address[] players;
    }
    
    
    /// For creating Room
    function createRoom(string memory _name, uint256 _entryPrice) public onlyCTO{
        address[] memory players;
        Room memory _room = Room({
            name: _name,
            players: players,
            balance: 0,
            entryPrice: _entryPrice
        });
        allRooms.push(_room);
    }

    function enter(uint256 _roomId) public payable {
        Room storage room = allRooms[_roomId-1]; //if _roomId doesn't exist in array, exits.
        
        require(room.players.length < 6);
        require(msg.value >= room.entryPrice);
        
        room.players.push(msg.sender);
        room.balance += room.entryPrice;
        
        emit newPlayer(_roomId, msg.sender);
        
        if(room.players.length == 6){
            emit fullRoom(_roomId);
            executeRoom(_roomId);
        }
    }
    
    function enterWithReferral(uint256 _roomId, address payable referrer) public payable {
        
        Room storage room = allRooms[_roomId-1]; //if _roomId doesn't exist in array, exits.
        
        require(room.players.length < 6);
        require(msg.value >= room.entryPrice);
        
        uint256 referrerCut = room.entryPrice / 100; // Referrer get one percent of the bet as reward
        referrer.transfer(referrerCut);
         
        room.players.push(msg.sender);
        room.balance += room.entryPrice - referrerCut;
        
        emit newPlayer(_roomId, msg.sender);
        
        if(room.players.length == 6){
            emit fullRoom(_roomId);
            executeRoom(_roomId);
        }
    }
    
    function executeRoom(uint256 _roomId) public {
        
        Room storage room = allRooms[_roomId-1]; //if _roomId doesn't exist in array, exits.
        
        //Check if the room is really full before shooting people...
        require(room.players.length == 6);
        
        uint256 halfFee = room.entryPrice / 20;
        CTO.transfer(halfFee);
        CEO.transfer(halfFee);
        room.balance -= halfFee * 2;
        
        uint256 deadSeat = random();
        
        distributeFunds(_roomId, deadSeat);
        
        delete room.players;
    }
    
    function distributeFunds(uint256 _roomId, uint256 _deadSeat) private returns(uint256) {
        
        Room storage room = allRooms[_roomId-1]; //if _roomId doesn't exist in array, exits.
        uint256 balanceToDistribute = room.balance / 5;
        
        address victim = room.players[_deadSeat];
        address[] memory winners = new address[](5);
        uint256 j = 0; 
        for (uint i = 0; i<6; i++) {
            if(i != _deadSeat){
                payable(room.players[i]).transfer(balanceToDistribute);
                //room.players[i].transfer(balanceToDistribute);
                room.balance -= balanceToDistribute;
                winners[j] = room.players[i];
                j++;
            }
        }
        
        emit partyOver(_roomId, victim, winners);
       
        return address(this).balance;
    }
    
     /// @dev Empty the room and refund each player. Safety mechanism which shouldn't be used.
    /// @param _roomId The Room id to empty and refund
    function refundPlayersInRoom(uint256 _roomId) public onlyCTO{
        Room storage room = allRooms[_roomId-1]; //if _roomId doesn't exist in array, exits.
        uint256 nbrOfPlayers = room.players.length;
        uint256 balanceToRefund = room.balance / nbrOfPlayers;
        for (uint i = 0; i<nbrOfPlayers; i++) {
            payable(room.players[i]).transfer(balanceToRefund);
            //room.players[i].transfer(balanceToRefund);
            room.balance -= balanceToRefund;
        }
        
        emit roomRefunded(_roomId, room.players);
        delete room.players;
    }
    
    
    /// @dev A clean and efficient way to generate random and make sure that it
    /// will remain the same across the executing nodes of random value 
    /// Ethereum Blockchain. We base our computation on the block.timestamp
    /// and difficulty which will remain the same across the nodes to ensure
    /// same result for the same execution.
    function random() private view returns (uint256) {
        return uint256(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%6);
    }
    
    function getRoom(uint256 _roomId) public view returns (
        string memory name,
        address[] memory players,
        uint256 entryPrice,
        uint256 balance
    ) {
        Room storage room = allRooms[_roomId-1];
        name = room.name;
        players = room.players;
        entryPrice = room.entryPrice;
        balance = room.balance;
    }
  
    function payout(address payable _to) public onlyCTO {
        _payout(_to);
    }

    /// For paying out balance on contract
    function _payout(address payable _to) private {
        if (_to == address(0)) {
            CTO.transfer(address(this).balance / 2);
            CEO.transfer(address(this).balance);
        } else {
            _to.transfer(address(this).balance);
        }
    }
}