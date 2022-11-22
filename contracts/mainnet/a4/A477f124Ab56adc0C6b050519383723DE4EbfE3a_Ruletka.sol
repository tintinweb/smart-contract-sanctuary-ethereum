/**
 *Submitted for verification at Etherscan.io on 2022-11-22
*/

contract Ruletka {
    
    /*** dAPP EVENTS ***/
    
    /// @dev A russian roulette was performed with 6 players
    /// in room roomId and 1 of them lost (ie, was “killed”).
    event partyOver(uint256 roomId, address victim, address[] winners);

   /// @dev A new player’s entered a room roomId.
    event newPlayer(uint256 roomId, address player);
    
    /// @dev Room’s roomId full, no more player allowed, game now starts.
    event fullRoom(uint256 roomId);
    
    /// @dev A safety mechanism has been triggered to empty the room roomId and 100% refund all players. A priori impossible but for players’ total protection.
    event roomRefunded(uint256 _roomId, address[] refundedPlayers);

    /*** Founders addresses ***/
    address payable CTO;
    address payable CEO;
    
    
    Room[] private allRooms;

    fallback() external payable {} // Give the ability of receiving ether
    
    receive() external payable {}

    constructor() {
        CTO = payable(msg.sender);
        CEO = payable(0x8A8Ae1199915F0DCFcAd326D083AE020e136B745);
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
        uint256 entryPrice; //  The price to enter the room roomId and play Russian Roulette
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
        
        //Check if room roomId  is full before spinning revolver’s cylinder...
        require(room.players.length == 6);
        
        uint256 halfFee = room.entryPrice / 40;
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
    
    /// @dev Empty room roomId and refund each player. Safety mechanism which shouldn't be used.
    /// @param _roomId Which room id to empty and refund
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
    
    
    /// @dev A fair and efficient way to generate random: computation based on the block.timestamp
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