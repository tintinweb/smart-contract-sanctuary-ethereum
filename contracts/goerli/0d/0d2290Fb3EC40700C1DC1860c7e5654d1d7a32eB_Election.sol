/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract Election {
    address public admin;
    bool public ended;
    bool public started;
    uint256 duration;
    uint256 public poll_end_time;
    uint256 public candidate_count;

    uint256[] private list_of_winners;
    uint256 private winning_nb_votes;

    uint256[] private votes_per_candidate;
    bytes32[] candidate_names;
    string[] candidate_img_urls;

    mapping(address => bool) public voted;
    mapping(address => bool) public registered;

    bool public draw;

    constructor(
        uint256 _duration,
        uint256 _candidate_count,
        bytes32[] memory _candidate_names,
        string[] memory _candidate_img_urls
    ) {
        duration = _duration;
        candidate_count = _candidate_count;
        ended = false;
        started = false;
        winning_nb_votes = 0;
        draw = false;

        admin = msg.sender;

        for (uint256 i = 0; i < _candidate_names.length; i++) {
            candidate_names.push(_candidate_names[i]);
            candidate_img_urls.push(_candidate_img_urls[i]);
            votes_per_candidate.push(0);
        }
    }

    function start_election() public {
        require(msg.sender == admin, "You're not the admin");
        require(!started, "Election has already started!");
        require(!ended, "Election has already ended!");

        poll_end_time = block.timestamp + duration;
        started = true;
    }

    function end_election() public {
        require(msg.sender == admin, "You're not the admin");
        require(started, "Election has not started!");
        require(block.timestamp > poll_end_time, "poll has not ended");
        require(!ended, "Election has already ended!");

        ended = true;
        update_winner();
    }

    function vote(uint256 candidate) public {
        require(!voted[msg.sender], "You have already voted!");
        require(started, "Election has not started!");
        require(block.timestamp < poll_end_time, "poll has already ended");
        require(!ended, "Election has already ended!");

        voted[msg.sender] = true;
        votes_per_candidate[candidate] += 1;
    }

    function register_candidates(bytes32 name, string memory image_url) public {
        require(!registered[msg.sender], "You have already registered!");
        require(candidate_names.length < candidate_count);
        require(!started, "Election has already started");
        candidate_names.push(name);
        candidate_img_urls.push(image_url);
        votes_per_candidate.push(0);
        registered[msg.sender] = true;
    }

    function check_registered(address prospect) public view returns (bool) {
        return registered[prospect];
    }

    function check_voted(address voter) public view returns (bool) {
        return voted[voter];
    }

    function get_end_time() public view returns (uint256) {
        return poll_end_time;
    }

    function get_candidate_names() public view returns (bytes32[] memory) {
        bytes32[] memory items = new bytes32[](candidate_names.length);
        for (uint256 i = 0; i < candidate_names.length; i++) {
            items[i] = candidate_names[i];
        }
        return items;
    }

    function get_candidate_images() public view returns (string[] memory) {
        string[] memory items = new string[](candidate_img_urls.length);
        for (uint256 i = 0; i < candidate_img_urls.length; i++) {
            items[i] = candidate_img_urls[i];
        }
        return items;
    }

    function is_admin(address user) public view returns (bool) {
        if (user == admin) {
            return true;
        }

        return false;
    }

    function update_winner() public {
        require(started, "Election has not begun yet");
        for (uint256 i = 0; i < candidate_names.length; i++) {
            if (votes_per_candidate[i] > winning_nb_votes) {
                for (uint256 j = 0; j < list_of_winners.length; j++) {
                    list_of_winners.pop();
                }
                list_of_winners.push(i);
                winning_nb_votes = votes_per_candidate[i];
            } else if (votes_per_candidate[i] == winning_nb_votes) {
                //case in which there are possibly 2 or more winners
                list_of_winners.push(i);
            }
        }

        if (list_of_winners.length > 1) {
            draw = true;
        }
    }

    function get_winner() public view returns (bytes32[] memory) {
        require(started, "Vote has not begun yet");
        require(ended, "Poll has not ended yet!");
        bytes32[] memory winners = new bytes32[](list_of_winners.length);
        for (uint256 i = 0; i < list_of_winners.length; i++) {
            winners[i] = candidate_names[list_of_winners[i]];
        }
        return winners;
    }

    function get_winner_images() public view returns (string[] memory) {
        require(started, "Vote has not begun yet");
        require(ended, "Poll has not ended yet!");
        string[] memory winnerImages = new string[](list_of_winners.length);
        for (uint256 i = 0; i < list_of_winners.length; i++) {
            winnerImages[i] = candidate_img_urls[list_of_winners[i]];
        }
        return winnerImages;
    }

    function get_winning_votes() public view returns (uint256) {
        return winning_nb_votes;
    }

    function get_time_left() public view returns (uint256) {
        require(started, "Vote has not begun yet");
        return block.timestamp - poll_end_time;
    }
}