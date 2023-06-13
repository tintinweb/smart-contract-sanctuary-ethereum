// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract GuessingGame {
    event CommitMade(address indexed _from, bytes32 _hash);
    event RevealStart(address indexed _from, uint256 _deadline);
    event RevealMade(address indexed _from, uint256 _guess);
    event WinnerDeclared(address indexed _winner, uint256 _amount);
    uint256 public constant DAY = 86400; //seconds
    uint256 public constant WEEK = DAY * 7; //seconds

    enum Phase {
        Commit,
        Reveal
    }

    struct Rules {
        uint256 minGuess;
        uint256 maxGuess;
        uint256 minPlayers;
        uint256 entryFee;
    }

    struct Commit {
        bytes32 commit;
        bool revealed;
        uint256 guess;
    }
    Phase public phase;
    Rules public RULES;

    mapping(address => Commit) private commits;
    mapping(address => bool) private hasWithdrawn;
    address[] public players;

    uint256 public revealDeadline;
    uint256 public expired;

    /**************** Game calculation */
    uint256 sum;
    uint256 public revealedPlayers;

    address public owner;

    address public winner;
    bool winnerHasWithdrawn;
    uint256 winningAmount;

    bool isInit = false;
    //genug um einen Getter zu haben und Variable im Frontend auslesen zu können?
    bool public isStarted = false;

    function init(
        uint256 _minGuess,
        uint256 _maxGuess,
        uint256 _minPlayers,
        uint256 _entryFee,
        address _owner
    ) external {
        require(!isInit, "The game has already been initialized");
        owner = _owner;
        RULES = Rules(_minGuess, _maxGuess, _minPlayers, _entryFee);
        isInit = true;
        expired = block.timestamp + WEEK;
    }

    receive() external payable {
        revert(
            "This contract does not accept Ether, if you don't participate in the Game."
        );
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only the owner can use this function.");
        _;
    }

    modifier gameExpired() {
        require(block.timestamp < expired, "Game is expired.");
        _;
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    function getPlayerCount() public view returns (uint256) {
        return players.length;
    }

    function commitHash(bytes32 _hash) public payable gameExpired {
        require(phase == Phase.Commit, "The commit phase is over.");
        require(msg.value == RULES.entryFee, "Insufficient entry fee.");
        require(
            commits[msg.sender].commit == 0,
            "You have already entered a guess."
        );
        players.push(msg.sender);
        commits[msg.sender].commit = _hash;
        emit CommitMade(msg.sender, _hash);
    }

    function reveal(uint256 guess, uint256 salt) public gameExpired {
        bytes32 commit = keccak256(abi.encodePacked(guess, salt));
        require(phase == Phase.Reveal, "It's not the time to reveal yet.");
        require(block.timestamp < revealDeadline, "Reveal deadline is over.");
        require(commits[msg.sender].commit != 0, "There is no commit.");
        require(!commits[msg.sender].revealed, "Guess was already revealed.");
        require(commit == commits[msg.sender].commit, "Wrong guess or salt.");

        commits[msg.sender].revealed = true;
        commits[msg.sender].guess = guess;
        sum += guess;
        revealedPlayers += 1;
        emit RevealMade(msg.sender, guess);
    }

    function withdraw() public {
        uint256 time = block.timestamp;
        require(time > expired && !isStarted, "You cannot withdraw.");
        require(commits[msg.sender].commit != 0, "You didn't participate.");
        require(!hasWithdrawn[msg.sender], "You already withdrawed.");
        hasWithdrawn[msg.sender] = true;
        payable(msg.sender).transfer(RULES.entryFee);
    }

    function startRevealPhase() public onlyOwner gameExpired {
        require(phase == Phase.Commit, "Already started reveal phase.");
        require(players.length >= RULES.minPlayers, "Not enough players.");
        phase = Phase.Reveal;
        revealDeadline = block.timestamp + DAY;
        emit RevealStart(owner, revealDeadline);
    }

    function finishGame() public onlyOwner gameExpired {
        uint256 time = block.timestamp;
        require(
            time > revealDeadline || revealedPlayers == players.length,
            "The reveal deadline isn't over yet."
        );
        require(revealedPlayers != 0, "Nobody revealed their guess yet.");
        require(!isStarted, "Game already started");
        isStarted = true;
        uint256 target = ((sum / revealedPlayers) * 66) / 100;
        uint256 minDiff = calcWinningDiff(RULES.maxGuess, target);
        uint256 countWinners = getAmountOfWinners(minDiff, target, 0);
        address[] memory possibleWinners = getPossibleWinners(
            minDiff,
            target,
            countWinners
        );
        uint256 randomNumber = random();
        uint256 winnerIndex = randomNumber % (possibleWinners.length);
        winner = possibleWinners[winnerIndex];
        winningAmount = (address(this).balance * 95) / 100;
        emit WinnerDeclared(winner, winningAmount);
    }

    function payout() public {
        require(winner == msg.sender, "You are not the winner.");
        require(!winnerHasWithdrawn, "You already withdrawed your win.");
        winnerHasWithdrawn = true;
        payable(winner).transfer(winningAmount);
    }

    function retrieveWinningFee() public onlyOwner {
        require(winnerHasWithdrawn, "The winner hasn't payout their win.");
        require(address(this).balance > 0, "You already collected your fee.");
        payable(msg.sender).transfer(address(this).balance);
    }

    function calcWinningDiff(
        uint256 minDiff,
        uint256 target
    ) private view returns (uint256) {
        for (uint256 i = 0; i < players.length; i++) {
            if (
                commits[players[i]].revealed == true &&
                absDiff(commits[players[i]].guess, target) <= minDiff
            ) {
                minDiff = absDiff(commits[players[i]].guess, target);
            }
        }
        return minDiff;
    }

    function absDiff(
        uint256 num1,
        uint256 num2
    ) private pure returns (uint256) {
        if (num1 >= num2) {
            return num1 - num2;
        } else {
            return num2 - num1;
        }
    }

    function getAmountOfWinners(
        uint256 minDiff,
        uint256 target,
        uint256 count
    ) private view returns (uint256) {
        for (uint256 i = 0; i < players.length; i++) {
            if (
                commits[players[i]].revealed == true &&
                minDiff == absDiff(commits[players[i]].guess, target)
            ) {
                count++;
            }
        }
        return count;
    }

    function getPossibleWinners(
        uint256 minDiff,
        uint256 target,
        uint256 countWinners
    ) private view returns (address[] memory) {
        address[] memory possibleWinners = new address[](countWinners);
        uint256 amount = 0;
        for (uint256 i = 0; i < players.length; i++) {
            if (
                commits[players[i]].revealed == true &&
                minDiff == absDiff(commits[players[i]].guess, target)
            ) {
                possibleWinners[amount] = players[i];
                amount++;
            }
        }
        return possibleWinners;
    }

    // this is pseudo random generator, A miner can actually influence this
    // it's better to use chainlink for that e.g. GM has to get random number first before starting the game
    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.prevrandao,
                        block.number
                    )
                )
            );
    }
}