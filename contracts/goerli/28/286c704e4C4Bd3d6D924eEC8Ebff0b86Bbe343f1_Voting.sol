/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Voting {
    uint256 public constant MAX_VOTES_PER_VOTER = 3;

    struct Movie {
        uint256 id;
        string title;
        string cover;
        uint256 votes;
    }
    event Voted();
    event NewMovie();

    mapping(uint256 => Movie) public movies;
    uint256 public moviesCount;

    mapping(address => uint256) public votes;

    constructor() {
        moviesCount = 0;
    }

    function vote(uint256 _movieID) public {
        require(
            votes[msg.sender] < MAX_VOTES_PER_VOTER,
            "Voter has no votes left."
        );
        require(
            _movieID > 0 && _movieID <= moviesCount,
            "Movie ID is out of range."
        );

        votes[msg.sender]++;
        movies[_movieID].votes++;

        emit Voted();
    }

    function addMovie(string memory _title, string memory _cover) public {
        moviesCount++;

        Movie memory movie = Movie(moviesCount, _title, _cover, 0);
        movies[moviesCount] = movie;

        emit NewMovie();
        vote(moviesCount);
    }
}