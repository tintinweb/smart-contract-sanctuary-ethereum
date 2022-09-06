/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

contract ChessPoH{
    address payable public manager;
    uint registrationFees;
    mapping (address => bool) public gamers;
    uint public gamersCount;

    constructor (uint registrat, address payable creator ) {
        manager = creator;
        registrationFees = registrat;
    }

    modifier restricted(){
        require (msg.sender == manager);
        _;
    }

    function registration() public payable{
        require (msg.value == registrationFees, "Coloque value = registrationFees" );
        require (gamers[msg.sender] == false, "Usted ya se registro");
        gamers[msg.sender] = true;
        gamersCount++;
    }

    function payWinnersBurner (address payable firt, address payable second, address payable third, address payable ubiburner) public restricted {
       
        uint amount30 = address(this).balance*3/10;
        uint amount20 = address(this).balance*2/10;
        uint amount10 = address(this).balance/10;
        uint amount40 = address(this).balance - amount30 - amount20 - amount10;

        firt.transfer(amount30);
        second.transfer(amount20);
        third.transfer(amount10);
        ubiburner.transfer(amount40);
    }

    function RegistrationFees () public view returns (uint){
        return registrationFees;
    }

    function key() public view returns(string memory){
        require(gamers[msg.sender]==true, "Tiene que inscribirse para ver la clave del torneo");
        return "pohubi1";
    }

}