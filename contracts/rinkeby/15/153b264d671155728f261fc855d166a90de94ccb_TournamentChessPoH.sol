/**
 *Submitted for verification at Etherscan.io on 2022-09-06
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

    /** @dev Sets the chess tournament manager, the registration fee and the address of ubiburner.
     *  @param _manager Manager of the tournament.
     *  @param _registrationFees The fee of the registration.
     *  @param _ubiburner Address ubiburner.
     */
    constructor (address _manager, uint _registrationFees, address payable _ubiburner) {
        manager = _manager;
        registrationFees = _registrationFees;
        ubiburner = _ubiburner;
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
        uint amount30 = balance*3/10;
        uint amount20 = balance*2/10;
        uint amount10 = balance/10;
        uint amount40 = balance - amount30 - amount20 - amount10;

        _first.transfer(amount30);
        _second.transfer(amount20);
        _third.transfer(amount10);
        ubiburner.transfer(amount40);

        tournamentFinished = true; //end the tournament

    }

    /** @dev Get the registration fee.
     *  @return registration fee.
     */
    function RegistrationFees () public view returns (uint){
        return registrationFees;
    }

    //For testing purposes only. Eliminate in the mainet implementation
    /** @dev Get the key of the tournament.
     *  @return key of the tournament.
     */    
    function getKey() public view returns(string memory){
        require(gamers[msg.sender], "You must register to see the tournament key");
        return "pohubi1";
    }
}