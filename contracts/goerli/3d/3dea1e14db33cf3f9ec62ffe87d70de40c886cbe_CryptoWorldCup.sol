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

    //Sweetstake public finalResult;

    mapping (uint => address) public sweetstakeToOwner;
    mapping (address => uint) ownerSweetstakeCount;
    mapping (address => uint[]) ownerToSweetstake;
    mapping (address => bool) public addressWinner;


    uint counterWinners = 0;

    function _createSweetstake(string _team1, string _team2, uint _score1, uint _score2) external payable {
        require(msg.value == 0.001 ether);
        require( ownerSweetstakeCount[msg.sender]<=5); //one addres can't have more than 5 Sweetstakes
        bool validSweetstake = true;
        for (uint i = 0; i<ownerToSweetstake[msg.sender].length; i++){
            if((compareStrings(sweetstakes[ownerToSweetstake[msg.sender][i]].team1, _team1) && compareStrings(sweetstakes[ownerToSweetstake[msg.sender][i]].team2, _team2) && sweetstakes[ownerToSweetstake[msg.sender][i]].score1 == _score1 && sweetstakes[ownerToSweetstake[msg.sender][i]].score2 == _score2) || (compareStrings(sweetstakes[ownerToSweetstake[msg.sender][i]].team2, _team1) && compareStrings(sweetstakes[ownerToSweetstake[msg.sender][i]].team1, _team2) && sweetstakes[ownerToSweetstake[msg.sender][i]].score1 == _score2 && sweetstakes[ownerToSweetstake[msg.sender][i]].score2 == _score1)){
                validSweetstake = false;
            }
        }
        require(validSweetstake);
        uint id = sweetstakes.push(Sweetstake(_team1, _team2, _score1, _score2)) - 1;
        sweetstakeToOwner[id] = msg.sender;
        ownerSweetstakeCount[msg.sender]++;
        ownerToSweetstake[msg.sender].push(id);

    }

    //Funcion que devuelve los nfts de una direccion
    function getSweetstakeByOwner(address _owner) external view returns (uint[]) {
        return ownerToSweetstake[_owner];
    }

    function setFinalResult(string _team1, string _team2, uint _score1, uint _score2) public onlyOwner{
        //finalResult = new Sweetstake(_team1, _team2, _score1, _score2);
        for (uint i = 0; i<sweetstakes.length; i++){
            if((compareStrings(sweetstakes[i].team1, _team1) && compareStrings(sweetstakes[i].team2, _team2) && sweetstakes[i].score1 == _score1 && sweetstakes[i].score2 == _score2) || (compareStrings(sweetstakes[i].team2, _team1) && compareStrings(sweetstakes[i].team1, _team2) && sweetstakes[i].score1 == _score2 && sweetstakes[i].score2 == _score1)){
                counterWinners++;
                addressWinner[sweetstakeToOwner[i]] = true;
            }
            
        }
    }

    function claimAward() public {
        require(addressWinner[msg.sender]==true);
        msg.sender.transfer((address(this).balance)/counterWinners);
    }

    /*function payWinners(string _team1, string _team2, uint _score1, uint _score2) external payable onlyOwner  {
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

    }*/





    function compareStrings(string memory a, string memory b) public view returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }




}