/**
 *Submitted for verification at Etherscan.io on 2023-06-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract RCGCardURISetter1{
	
	string public URI; 

	function setURI1(uint256 _ranNumber) public returns (string memory){
		
		if (_ranNumber < 100){
			URI = "https://romecardgame.com/character-cards/01-king-romulus-the-founder.json";
		}
		else if (_ranNumber < 200){
			URI = "http://romecardgame.com/character-cards/06-scaevola-the-left-handed.json";
		}
		else if (_ranNumber < 300){
			URI = "https://romecardgame.com/character-cards/03-aeneas-of-troy.json";
		}
		else if (_ranNumber < 400){
			URI = "https://romecardgame.com/character-cards/04-scipio-africanus.json";
		}
		else if (_ranNumber < 500){
			URI = "https://romecardgame.com/character-cards/05-horatius-the-one-eyed.json";
		}
		else if (_ranNumber < 600){
			URI = "http://romecardgame.com/character-cards/06-scaevola-the-left-handed.json";
		}
		else if (_ranNumber < 700){
			URI = "https://romecardgame.com/character-cards/07-appius-the-builder.json";
		}
		else if (_ranNumber < 800){
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