// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract TetrisGame {
	struct Highscore {
		address	wallet;
		string	name;
		uint256 score;
	}

	mapping(uint256 => Highscore) public highscores;

	uint256 public numberOfHighscores = 0;

	function createHighscore(address _wallet, string memory _name, uint256 _score) public returns (uint256) {
		Highscore storage highscore = highscores[numberOfHighscores];

		highscore.wallet = _wallet;
		highscore.name = _name;
		highscore.score = _score;

		numberOfHighscores++;

		return numberOfHighscores - 1;
	}

	function collectPrize(address payable recipient) public payable {
        recipient.transfer(msg.value);
    }

	// function donateToHighscore(uint256 _id) public payable {
	// 	uint256 amount = msg.value;

	// 	Highscore storage highscore = highscores[_id];

	// 	highscore.donators.push(msg.sender);
	// 	highscore.donations.push(amount);

	// 	(bool sent,) = payable(highscore.owner).call{value: amount}("");

	// 	if(sent) {
	// 		highscore.amountCollected = highscore.amountCollected + amount;
	// 	}
	// }

	// function getDonators(uint256 _id) view public returns (address[] memory, uint256[] memory) {
	// 	return (highscores[_id].donators, highscores[_id].donations);
	// }

	function getHighscores() public view returns (Highscore[] memory) {
		Highscore[] memory allHighscores = new Highscore[](numberOfHighscores);

		for(uint i = 0; i < numberOfHighscores; i++) {
			Highscore storage item = highscores[i];

			allHighscores[i] = item;
		}

		return allHighscores;
	}
}