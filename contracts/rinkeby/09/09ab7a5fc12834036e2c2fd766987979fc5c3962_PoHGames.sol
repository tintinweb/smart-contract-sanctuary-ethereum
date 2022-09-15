/**
 *Submitted for verification at Etherscan.io on 2022-09-15
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
//Factory the PoH Tournaments 
contract PoHGames{
    address[] public deployedTournament;

    /* @dev Create the  tournament 
     * @param -nameTournament tournament name
     * @param _date tournament date
     * @param _hour tournament hour
     * @param _platform tournament platform
     * @param _registrationFees The fee of the registration.
     */

    function createTournament (string memory _nameTourname, string memory _date, uint _hour, string memory _platform, uint _registrationFees) public {
        address newTournament = address(new TournamentPoH(_nameTourname, _date, _hour, _platform, msg.sender, _registrationFees));
        deployedTournament.push(newTournament);
    }

    function getDeployedTournaments () public view returns (address[] memory){
        return deployedTournament;
    }
}

// Tournament POH
contract TournamentPoH{
    struct Request{
        address manager;
        uint registrationFees;
        string nameTourname;
        string date;
        uint hour; 
        string platform;
        mapping (address => bool) gamers;
        uint gamersCount;
        bool tournamentFinished;
    }
    
    Request public request;
    address payable ubiburner;
    
    // Proof of Humanity contract.
    IProofOfHumanity private PoH =
        IProofOfHumanity(0xC5E9dDebb09Cd64DfaCab4011A0D5cEDaf7c9BDb);
    
    //log the player platform user and sender address
    event storedPlatformUser(
        string addedPlatformUser,
        address sender
    );

    //log the players wind
    event storedPlayersWind(
        address first,
        address second,
        address third
    );

    /** @dev Sets the PoH tournament manager, the registration fee and the address of ubiburner.
     *  @param _manager Manager of the tournament.
     *  @param _registrationFees The fee of the registration.
     */
    constructor (string memory _nameTourname, string memory _date, uint _hour, string memory _platform, address _manager, uint _registrationFees) {
        request.nameTourname = _nameTourname;
        request.date = _date; 
        request.hour = _hour;
        request.platform = _platform;
        request.manager = _manager;
        request.registrationFees = _registrationFees;
        //Set address _ubiburner
        //ubiburner = _ubiburner;
    }

    modifier restricted(){
        require (msg.sender == request.manager);
        _;
    }

    modifier isOpen(){
        require (!request.tournamentFinished, "The tournament is over");
        _;
    }

    /** @dev Registration of players (PoH humans only), must pay the registration feed for the value registrationFees.
     *  @dev log the player platform user and sender address
     *  param userPlatform player platform user.
     */    
    function registration(string memory _newUserPlatform) public payable isOpen {
        //It is implemented on the mainnet
        //require(PoH.isRegistered(msg.sender), "Not registered"); //is on PoH list
       
        require (msg.value == request.registrationFees, "Set value = registrationFees in wei" );
        require (!request.gamers[msg.sender], "You are registred");
        request.gamers[msg.sender] = true;
        
        emit storedPlatformUser(
            _newUserPlatform,
            msg.sender
        );

        request.gamersCount++;
    }

    /** @dev Uses the contract balance to pay the winners and send the rest to the ubiburner contract.
     *  @dev log the players wind
     *  @param _first The champion of the tournament.
     *  @param _second The second place of the tournament.
     *  @param _third The third place of the tournament.
     */
    function payWinnersBurner (address payable _first, address payable _second, address payable _third) external restricted {
        require(request.gamers[_first],"Not a gamer");
        require(request.gamers[_second],"Not a gamer");
        require(request.gamers[_third],"Not a gamer");

        uint balance = address(this).balance;
        uint amount25 = balance*25/100;
        uint amount15 = balance*15/100;
        uint amount10 = balance/10;
        uint amount50 = balance - amount25 - amount15 - amount10;

        _first.transfer(amount25);
        _second.transfer(amount15);
        _third.transfer(amount10);

        //ubiburner.transfer(amount50);

        request.tournamentFinished = true; //end the tournament
        //log the players wind
        emit storedPlayersWind(
            _first,
            _second,
            _third
        );
    }

    /** @dev Get the registration fee.
     *  @return registration fee.
     */
    function RegistrationFees () public view returns (uint){
        return request.registrationFees;
    }
}