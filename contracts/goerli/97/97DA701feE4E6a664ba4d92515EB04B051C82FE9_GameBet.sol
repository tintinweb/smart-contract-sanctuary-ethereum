// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract GameBet {

    // Waiting for the pool, record the address of player A
    address _matching = address(0);


    /*
     * waiting event, There are no players in the matching pool, waiting for matching
     * {@owner} current player
     */
    event Wiatting(address indexed owner);

    /*
     * game start event
     * {@player1} player1
     * {@player2} player2
     * {@bet} Both parties' respective stakes (units is ETH, Default is 3 ETH)
     */
    event GameBegin(address indexed player1, address indexed player2, uint256 bet);
    
    /*
     * game emd event
     * {@player1} player1
     * {@player2} player2
     * {@points} points
     * {@winner} winner
     * {@_amou} win amount
     */
    event GameEnd(address indexed player1, address indexed player2, uint points, address indexed winner, uint _amou);

    /*
     * bet refunded event
     * {@player} player
     * {@bet} refund amount
     */
    event BetRefunded(address indexed player, uint256 bet);

    // Game logic implementation 
    function play() payable public {
        require(msg.value >= 3 * 1e15, "No stakes!");

        // If there is no matching object, enter the matching pool
        if(_matching == address(0)){
            emit Wiatting(msg.sender);
            _matching = msg.sender;
            return;
        }

        // game start
        emit GameBegin(_matching, msg.sender, 3 * 1e15);

        // Use the random number of [1-6] to get the dice point
        uint256 points = rand(5) + 1;

        // If player A wins
        if(points <= 3){
            // Winning rewards are dice points
            uint256 winningAmount = points;

            // Pays player A's winnings
            payable(_matching).transfer(winningAmount* 1e15);
            emit GameEnd(_matching, msg.sender, points, _matching, winningAmount* 1e15);

            // Refund all bets of player A
            payable(_matching).transfer(3 * 1e15);
            emit BetRefunded(_matching, 3 * 1e15);

            /* 
             * When player A earns less than all of player B's bets, 
             * refund player B's remaining bet
             */
            if(winningAmount < 3){
                payable(msg.sender).transfer((3 - winningAmount)* 1e15);
                emit BetRefunded(msg.sender, (3 - winningAmount)* 1e15);
            }
        }
        // If player B wins 
        else {
            // Winning reward is dice point minus 3
            uint256 winningAmount = points - 3;

            // Pays player B's winnings
            payable(msg.sender).transfer(winningAmount* 1e15);
            emit GameEnd(_matching, msg.sender, points, msg.sender, winningAmount * 1e15);

            // Refund all bets of player B
            payable(msg.sender).transfer(3 * 1e15);
            emit BetRefunded(msg.sender, 3 * 1e15);

            /* 
             * When player B earns less than all of player A's bets, 
             * refund player A's remaining bet
             */
            if(winningAmount < 3){
                payable(_matching).transfer((3 - winningAmount)* 1e15);
                emit BetRefunded(_matching, (3 - winningAmount)* 1e15);
            }
        }

        // After the game is over, the waiting area is empty
         _matching = address(0);
    }

    /*
     * Linear congruence generator--LCG, 
     * generates pseudo-random numbers
     */
    function rand(uint256 _length) private view returns(uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        return random%_length;
    }
}