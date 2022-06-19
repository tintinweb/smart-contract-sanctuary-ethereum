pragma solidity ^0.4.19;


import "./ownable.sol";


contract CryptoWorldCup is Ownable {

    //event NewSweetstake(uint sweetstakeId, string _team1, string _team2, uint _score1 uint _score2);


    struct Sweetstake {
        string team1;
        string team2;
        uint score1;
        uint score2;
    }

    Sweetstake[] public sweetstakes;

    mapping (uint => address) public sweetstakeToOwner;
    mapping (address => uint) ownerSweetstakeCount;
    mapping (address => uint[]) ownerToSweetstake;

    mapping (address => uint) public addressWinner;

    function _createSweetstake(string _team1, string _team2, uint _score1, uint _score2) external payable {
        require(msg.value == 0.001 ether);
        uint id = sweetstakes.push(Sweetstake(_team1, _team2, _score1, _score2)) - 1;
        sweetstakeToOwner[id] = msg.sender;
        ownerSweetstakeCount[msg.sender]++;
        ownerToSweetstake[msg.sender].push(id);
        //NewSweetstake(id, _team1, _team2, _score1, _score2);
    }

    //Funcion que devuelve los nfts de una direccion
    function getSweetstakeByOwner(address _owner) external view returns (uint[]) {
        return ownerToSweetstake[_owner];
    }

    function payWinners(string _team1, string _team2, uint _score1, uint _score2) external payable onlyOwner  {
        address[] memory addressWinners;
        uint counterWinners = 0;
        //mapping (address => uint) addressWinner;
        //count how many sweetstakes each adress has
        for (uint i = 0; i<sweetstakes.length; i++){
            require((compareStrings(sweetstakes[i].team1, _team1) && compareStrings(sweetstakes[i].team2, _team2) && sweetstakes[i].score1 == _score1 && sweetstakes[i].score2 == _score2) || (compareStrings(sweetstakes[i].team2, _team1) && compareStrings(sweetstakes[i].team1, _team2) && sweetstakes[i].score1 == _score2 && sweetstakes[i].score2 == _score1));
            counterWinners++;
            //sweetstakeToOwner.transfer()
            //addressWinner[sweetstakeToOwner[i]]++;
            //addressWinners.push(sweetstakeToOwner[i]);
        }
        //pay to winners
        for (uint j = 0; j<addressWinners.length; j++){
            require((compareStrings(sweetstakes[i].team1, _team1) && compareStrings(sweetstakes[i].team2, _team2) && sweetstakes[i].score1 == _score1 && sweetstakes[i].score2 == _score2) || (compareStrings(sweetstakes[i].team2, _team1) && compareStrings(sweetstakes[i].team1, _team2) && sweetstakes[i].score1 == _score2 && sweetstakes[i].score2 == _score1));
            sweetstakeToOwner[i].transfer((address(this).balance)/counterWinners);
            //addressWinners[i].transfer((address(this).balance)/addressWinner[addressWinners[i]]);
        }

    }


    function compareStrings(string memory a, string memory b) public view returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }




}