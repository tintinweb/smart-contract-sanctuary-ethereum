/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

/**
 * @title ProofOfHumanity Interface
 * @dev See https://github.com/Proof-Of-Humanity/Proof-Of-Humanity.
 */
interface IProofOfHumanity {
    function isRegistered(address _submissionID)
        external
        view
        returns (bool registered);
}
//Factory the Tournaments chess
contract ChessPoH{
    address[] public deployedTournament;

    /* @dev Create the chess tournament 
     * @param _registrationFees The fee of the registration.
     */

    function createTournament (uint _registrationFees) public {
        address newTournament = address(new TournamentChessPoH(msg.sender, _registrationFees));
        deployedTournament.push(newTournament);
    }

    function getDeployedTournaments () public view returns (address[] memory){
        return deployedTournament;
    }
}

// Tournament chess POH
contract TournamentChessPoH{
    address public manager;
    uint registrationFees;
    mapping (address => bool) public gamers;
    uint public gamersCount;
    bool public tournamentFinished;
    address payable ubiburner;
    
    // Proof of Humanity contract.
    IProofOfHumanity private PoH =
        IProofOfHumanity(0xC5E9dDebb09Cd64DfaCab4011A0D5cEDaf7c9BDb);
    
    //log the player lichess user and sender address
    event storedLichessUser(
        string addedLichessUser,
        address sender
    );

    /** @dev Sets the chess tournament manager, the registration fee and the address of ubiburner.
     *  @param _manager Manager of the tournament.
     *  @param _registrationFees The fee of the registration.
     */
    constructor (address _manager, uint _registrationFees) {
        manager = _manager;
        registrationFees = _registrationFees;
        //Set address _ubiburner
        //ubiburner = _ubiburner;
    }

    modifier restricted(){
        require (msg.sender == manager);
        _;
    }

    modifier isOpen(){
        require (!tournamentFinished, "The tournament is over");
        _;
    }

    /** @dev Registration of players (PoHUBI humans only), must pay the registration feed for the value registrationFees.
     * 
     */    
    function registration() public payable isOpen {
        //It is implemented on the mainnet
        //require(PoH.isRegistered(msg.sender), "Not registered"); //is on PoH list
       
        require (msg.value == registrationFees, "Set value = registrationFees in wei" );
        require (!gamers[msg.sender], "You are registred");
        gamers[msg.sender] = true;
        gamersCount++;
    }

    /** @dev Uses the contract balance to pay the winners and send the rest to the ubiburner contract.
     *  @param _first The champion of the tournament.
     *  @param _second The second place of the tournament.
     *  @param _third The third place of the tournament.
     */
    function payWinnersBurner (address payable _first, address payable _second, address payable _third) external restricted {
        require(gamers[_first],"Not a gamer");
        require(gamers[_second],"Not a gamer");
        require(gamers[_third],"Not a gamer");

        uint balance = address(this).balance;
        uint amount25 = balance*25/100;
        uint amount15 = balance*15/100;
        uint amount10 = balance/10;
        uint amount50 = balance - amount25 - amount15 - amount10;

        _first.transfer(amount25);
        _second.transfer(amount15);
        _third.transfer(amount10);

        //ubiburner.transfer(amount50);

        tournamentFinished = true; //end the tournament
    }

    /** @dev Get the registration fee.
     *  @return registration fee.
     */
    function RegistrationFees () public view returns (uint){
        return registrationFees;
    }

    /** @dev log the player lichess user and sender address.
     *param _newLichessUser player lichess user.
     */    
    function store(string memory _newLichessUser) public {
        emit storedLichessUser(
            _newLichessUser,
            msg.sender
        );
    }
}