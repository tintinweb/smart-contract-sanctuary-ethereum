/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract RCGCardURISetter1{
	
	string public URI; 

	function setURI1(uint256 _ranNumber) public returns (string memory){
		if (_ranNumber < 50){
			URI = "https://romecardgame.com/military-unit-cards/01-numidian-cavalry.json";
		}
		else if (_ranNumber < 100){
			URI = "https://romecardgame.com/military-unit-cards/02-grecian-infantry.json";
		}
		else if (_ranNumber < 150){
			URI = "https://romecardgame.com/military-unit-cards/03-spanish-infantry.json";
		}
		else if (_ranNumber < 200){
			URI = "https://romecardgame.com/military-unit-cards/04-galic-infantry.json";
		}
		else if (_ranNumber < 250){
			URI = "https://romecardgame.com/military-unit-cards/05-spartan-infantry.json";
		}
		else if (_ranNumber < 300){
			URI = "http://romecardgame.com/military-unit-cards/06-germanic-horde.json";
		}
		else if (_ranNumber < 350){
			URI = "https://romecardgame.com/military-unit-cards/07-roman-legion.json";
		}
		else if (_ranNumber < 400){
			URI = "https://romecardgame.com/military-unit-cards/08-macedonian-elephant-cavalry.json";
		}
		else if (_ranNumber < 450){
			URI = "https://romecardgame.com/military-unit-cards/09-cretan-archers.json";
		}
		else if (_ranNumber < 500){
			URI = "https://romecardgame.com/character-cards/01-king-romulus-the-founder.json";
		}
		else if (_ranNumber < 550){
			URI = "https://romecardgame.com/character-cards/02-camillus-the-second-founder.json";
		}
		else if (_ranNumber < 600){
			URI = "https://romecardgame.com/character-cards/03-aeneas-of-troy.json";
		}
		else if (_ranNumber < 650){
			URI = "https://romecardgame.com/character-cards/04-scipio-africanus.json";
		}
		else if (_ranNumber < 700){
			URI = "https://romecardgame.com/character-cards/05-horatius-the-one-eyed.json";
		}
		else if (_ranNumber < 750){
			URI = "http://romecardgame.com/character-cards/06-scaevola-the-left-handed.json";
		}
		else if (_ranNumber < 800){
			URI = "https://romecardgame.com/character-cards/07-appius-the-builder.json";
		}
		else if (_ranNumber < 850){
			URI = "https://romecardgame.com/character-cards/08-the-horatii-triplets.json";
		}
		else if (_ranNumber < 900){
			URI = "https://romecardgame.com/character-cards/09-fabius-the-delayer.json";
		}
		else if (_ranNumber < 950){
			URI = "https://romecardgame.com/character-cards/10-pyrrhus-of-epirus.json";
		}
		else if (_ranNumber <= 1000){
			URI = "https://romecardgame.com/character-cards/11-brennus.json";
		}	
        return (URI);
    }
}