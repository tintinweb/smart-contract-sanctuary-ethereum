/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

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

    function createTournament (string memory _nameTournament, string memory _date, string memory _hour, string memory _platform, uint _registrationFees) public {
        address newTournament = address(new TournamentPoH(_nameTournament, _date, _hour, _platform, msg.sender, _registrationFees));
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
        string nameTournament;
        string date;
        string hour; 
        string platform;
        mapping (address => bool) gamers;
        uint gamersCount;
        bool regisClose;
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
    constructor (string memory _nameTournament, string memory _date, string memory _hour, string memory _platform, address _manager, uint _registrationFees) {
        request.nameTournament = _nameTournament;
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
     *  param _newUserPlatform player platform user.
     *  param _registrationFees registration fee of tournament
     */    
    function registration(string memory _newUserPlatform, uint _registrationFees) public payable isOpen {
        //It is implemented on the mainnet
        //require(PoH.isRegistered(msg.sender), "Not registered"); //is on PoH list
       
        require (_registrationFees == request.registrationFees, "Set value = registrationFees in wei" );
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

        request.tournamentFinished = true;//close the tournament

        //log the players wind
        emit storedPlayersWind(
            _first,
            _second,
            _third
        );
    }

    /** @dev Get the tournament name.
     *  @return name tournament.
     */
    function getTournamentName () public view returns (string memory){
        return request.nameTournament;
    }

    /** @dev Get the value of status of tournament completion.
     *  @return status.
     */
    function getTournamentFinished () public view returns(bool){
        return request.tournamentFinished;
    }

    /** @dev Set the status tournament registration closed
     */
    function setRegistrationClose () payable external restricted{     
        request.regisClose = true;
    }

    /** @dev Get the status tournament registration closed
     *  @return status tournament registration closed
     */
    function getRegistrationClose () public view returns(bool) {     
        return request.regisClose;
    }

    /** @dev Get the sender address status.
     *  @param _address sender address
     *  @return sender address status.
     */
    function getGamers (address _address) public view returns(bool){
        return request.gamers[_address];
    }

    function getSummary() public view returns(
        address, uint, string memory, string memory, string memory, string memory, uint, bool
        ) {
        return(
            request.manager,
            request.registrationFees,
            request.nameTournament,
            request.date,
            request.hour,
            request.platform,
            request.gamersCount,
            request.tournamentFinished
        );
    }
}