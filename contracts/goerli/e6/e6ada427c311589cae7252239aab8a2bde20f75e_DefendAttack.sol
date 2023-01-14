/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

error LOSERS();

interface FrontLinesInterface {
    function setDefendingQ00tantSquad(address _q00tantSquad) external;
    function attack(address _cornSquad) external;
}

interface TantSquadInterface {
    function squadPower() external returns (uint);
}

interface CornSquadInterface {
    function squadPower() external returns (uint);
}

contract DefendAttack {

    address public FrontLinesAddress = 0x0F9B1418694ADAEe240Cb0d76B805d197da5ae8a;

    FrontLinesInterface FrontLinesContract = FrontLinesInterface(FrontLinesAddress);
    
    //set defend on our tant squads & attack from their corn squads. award them 0 points LOL
    function lol(address q00tantSquad, address cornSquad) external {

        FrontLinesContract.setDefendingQ00tantSquad(q00tantSquad);
        FrontLinesContract.attack(cornSquad);
    }

    //revert if we are going to lose the attack, let pass if we will win. DEATH TO CORNS
    function deathToCorns(address q00tantSquad, address cornSquad) external {
        TantSquadInterface TantSquadContract = TantSquadInterface(q00tantSquad);
        CornSquadInterface CornSquadContract = CornSquadInterface(cornSquad);

        uint tantPower = TantSquadContract.squadPower();
        uint cornPower = CornSquadContract.squadPower();

        uint tantsRandom = badAssTants(tantPower);
        uint cornsRandom = loserAssCorns(cornPower);

        if (cornsRandom > tantsRandom) revert LOSERS();

        FrontLinesContract.setDefendingQ00tantSquad(q00tantSquad);
        FrontLinesContract.attack(cornSquad);
    }

    //call attack with all corns 250 armies until a block comes that kills them all. MEGA DEATH TO CORNS
    function megaDeathToCorns(address q00tantSquad, address[] memory cornSquad) external {
        FrontLinesContract.setDefendingQ00tantSquad(q00tantSquad);

        for(uint i = 0; i < cornSquad.length; i++) {
        FrontLinesContract.attack(cornSquad[i]);
        }
    }

    //revert if we are going to lose the attack, let pass if we will win (no set defend). DEATH TO CORNS
    function deathToCornsNoSet(address q00tantSquad, address cornSquad) external {
        TantSquadInterface TantSquadContract = TantSquadInterface(q00tantSquad);
        CornSquadInterface CornSquadContract = CornSquadInterface(cornSquad);

        uint tantPower = TantSquadContract.squadPower();
        uint cornPower = CornSquadContract.squadPower();

        uint tantsRandom = badAssTants(tantPower);
        uint cornsRandom = loserAssCorns(cornPower);

        if (cornsRandom > tantsRandom) revert LOSERS();

        FrontLinesContract.attack(cornSquad);
    }

    //call attack with all corns 250 armies until a block comes that kills them all (no set defend). MEGA DEATH TO CORNS
    function megaDeathToCornsNoSet(address[] memory cornSquad) external {

        for(uint i = 0; i < cornSquad.length; i++) {
        FrontLinesContract.attack(cornSquad[i]);
        }
    }

    function badAssTants(uint squadPower) public view returns (uint16) {
        return uint16(uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.difficulty)))%squadPower);
    }

    function loserAssCorns(uint squadPower) public view returns (uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%squadPower);
    }

}