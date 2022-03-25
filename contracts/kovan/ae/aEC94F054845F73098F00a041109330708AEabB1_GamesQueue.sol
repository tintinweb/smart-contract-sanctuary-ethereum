pragma solidity ^0.8.0;

contract GamesQueue {

    // create games queue
    mapping(uint => bytes32) public gamesCreateQueue;
    uint public firstCreated = 1;
    uint public lastCreated = 0;

    // resolve games queue
    mapping(uint => bytes32) public gamesResolvedQueue;
    uint public firstResolved = 1;
    uint public lastResolved = 0;

    function enqueueGamesCreated(bytes32 data) public {
        lastCreated += 1;
        gamesCreateQueue[lastCreated] = data;
    }

    function dequeueGamesCreated() public returns (bytes32 data) {
        require(lastCreated >= firstCreated);  // non-empty queue

        data = gamesCreateQueue[firstCreated];

        delete gamesCreateQueue[firstCreated];
        firstCreated += 1;
    }

    function enqueueGamesResolved(bytes32 data) public {
        lastResolved += 1;
        gamesResolvedQueue[lastResolved] = data;
    }

    function dequeueGamesResolved() public returns (bytes32 data) {
        require(lastResolved >= firstResolved);  // non-empty queue

        data = gamesResolvedQueue[firstResolved];

        delete gamesResolvedQueue[firstResolved];
        firstResolved += 1;
    }
}