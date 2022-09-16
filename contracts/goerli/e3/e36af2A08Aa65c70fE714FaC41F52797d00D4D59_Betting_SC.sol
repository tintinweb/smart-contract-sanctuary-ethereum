/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// SPDX-License-Identifier: UNLICENCED

pragma solidity ^0.8.15 ;

    contract Betting_SC {

        address public owner;

        struct Database {
            uint256 amount_betted;
            string Player;
            address Betters_address;
            }
        bool public WinnerDeclared;
        bool public BetsPayed;
        uint8 A;
        uint8 B;
        uint256 deadline;
        bool public locked;
        Database [] public database;

        constructor(uint8 _A, uint8 _B, uint256 _deadline) {
            A = _A;
            B = _B;
            deadline = block.timestamp + (_deadline * 1 hours);
            owner = msg.sender;
        }
        modifier onlyOwner(){
            require(msg.sender == owner, "ERROR1");
            _;
        }
        modifier noReentrancy() {
            require(!locked, "ERROR11");
            locked = true;
            _;
            locked = false;
        }
        modifier BettingClose(){
            require(block.timestamp <= deadline, "ERROR2");
            _;
        }
        modifier minBalance(){
            require(address(msg.sender).balance > msg.value, "ERROR12");
            _;
        }

        function addCapital() public onlyOwner noReentrancy minBalance payable {}

        function Bet_Money(uint256 _Age, string memory _Player) public noReentrancy BettingClose minBalance payable {
            require(_Age >= 18, "ERROR4");
            require(keccak256(abi.encode(_Player)) == keccak256(abi.encode('A')) || keccak256(abi.encode(_Player)) == keccak256(abi.encode('B')), "ERROR10");
            require(WinnerDeclared == false, "ERROR3");
            uint256 j = 0;
            while (j < getLength()){
                Database storage betting_database = database[j];
                require(betting_database.Betters_address != msg.sender, "ERROR5");
                ++j;
            }
            database.push(Database(msg.value, _Player, msg.sender));
        }
        function add_more() public noReentrancy BettingClose minBalance payable{
            require(WinnerDeclared== false, "ERROR3");
            uint256 j = 0;
            while (j < getLength()){
                Database storage betting_database = database[j];
                if (betting_database.Betters_address == msg.sender){
                    break;
                }
                ++j;
            }
            Database storage betting_database = database[j];
            require(betting_database.Betters_address == msg.sender, "ERROR6");
            betting_database.amount_betted = betting_database.amount_betted + msg.value;
        }
        function Refund() public noReentrancy BettingClose{
            uint256 j = 0;
            while (j < getLength()){
                Database storage betting_database = database[j];
                if (betting_database.Betters_address == msg.sender){
                    break;
                }
                ++j;
            }
            Database storage betting_database = database[j];
            if (betting_database.Betters_address != msg.sender){
                revert("ERROR7");
            }
            payable(msg.sender).transfer(betting_database.amount_betted);
            for (uint256 x = j; x < getLength()-1; ++x){
                database[x] = database[x+1];
            }
            database.pop();
        }
        function ViewContractBalance() public view returns(uint256){
            return address(this).balance;
        }
        function getLength() public view returns (uint) {
            return database.length;
        }
        function getPlayer(uint _index) public view returns (string memory text) {
            Database storage betting_database = database[_index];
            return (betting_database.Player);
        }
        function oddsPlayerA() public view returns (uint8){
            return A;
        }
        function oddsPlayerB() public view returns (uint8){
            return B;
        }
        function Deadline() public view returns (uint256){
            return deadline;
        }
        function CurrentTime() public view returns (uint256){
            return block.timestamp;
        }

        function Declare_Winner(string memory winner) public onlyOwner noReentrancy {
            require(BetsPayed == false, "ERROR8");
            require(keccak256(abi.encode(winner)) == keccak256(abi.encode('A')) || keccak256(abi.encode(winner)) == keccak256(abi.encode('B')), "ERROR10");
            uint8 Y = 0;
            if (keccak256(abi.encode(winner)) == keccak256(abi.encode("A"))){
                Y = A;
            }
            else if (keccak256(abi.encode(winner)) == keccak256(abi.encode("B"))){
                Y = B;
            }
            for(uint256 x=0; x < getLength(); ++x){
                if (keccak256(abi.encode(getPlayer(x))) == keccak256(abi.encode(winner))){
                    Database storage betting_database = database[x];
                    betting_database.amount_betted = betting_database.amount_betted * Y;
                }
                else {
                    Database storage betting_database = database[x];
                    betting_database.amount_betted = betting_database.amount_betted * 0;
                }
            }
            WinnerDeclared = true;
            PayBets();
        }
        function PayBets() public onlyOwner {
            require(WinnerDeclared == true, "ERROR9");
            for (uint256 x=0; x < getLength(); ++x){
                Database storage betting_database = database[x];
                if (betting_database.amount_betted > 0) {
                    payable(betting_database.Betters_address).transfer(betting_database.amount_betted);
                }
            }
            payable(msg.sender).transfer(address(this).balance);
            BetsPayed = true;
        }
    }