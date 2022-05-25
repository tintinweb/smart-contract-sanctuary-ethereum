// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// TODO: create the linkedlist contract
// TODO: create follower address validation as modifier

contract FreeSpeech {
    address internal constant SENTINEL_ADDRESS = address(0x1);

    // mapping of a linked list
    mapping(address => mapping(address => address)) private followers;
    mapping(address => uint256) private followersCount;

    function follow(address follower) public payable {
        // follower address cannot be null
        require(
            follower != address(0) &&
                follower != SENTINEL_ADDRESS &&
                follower != address(this),
            "FS101"
        );

        // TODO: you cannot be followed by yourself

        // if its your first follower
        if (followersCount[msg.sender] == 0) {
            // initialize the followers linked list with the first follower
            followers[msg.sender][SENTINEL_ADDRESS] = follower;
            followers[msg.sender][follower] = SENTINEL_ADDRESS;
            followersCount[msg.sender]++;
        } else {
            // No duplicate followers allowed
            require(followers[msg.sender][follower] == address(0), "FS102");

            // set this address as follower for this user
            followers[msg.sender][follower] = followers[msg.sender][
                SENTINEL_ADDRESS
            ];
            followers[msg.sender][SENTINEL_ADDRESS] = follower;
            followersCount[msg.sender]++;
        }

        // TODO: emit followEvent ?¿

        // TODO: send the amount to the follower user address
    }

    function unFollow(address prevFollower, address follower) public {
        // follower address cannot be null
        require(follower != address(0), "FS101");

        // follower address cannot be the sentinel address
        require(follower != SENTINEL_ADDRESS, "FS101");

        // follower address cannot be the FreeSpeech contract address itself
        require(follower != address(this), "FS101");

        // prevFollower is valid
        require(followers[msg.sender][prevFollower] == follower, "FS103");

        followers[msg.sender][prevFollower] = followers[msg.sender][follower];
        followers[msg.sender][follower] = address(0);
        followersCount[msg.sender]--;

        // TODO: emit unFollowEvent ?¿
    }

    function getFollowers(address user) public view returns (address[] memory) {
        address[] memory followersArray = new address[](followersCount[user]);

        // TODO: this fails the first time

        // populate the returned array with the user's followers
        uint256 index = 0;
        address currentFollower = followers[user][SENTINEL_ADDRESS];

        while (currentFollower != SENTINEL_ADDRESS) {
            followersArray[index] = currentFollower;
            currentFollower = followers[user][currentFollower];
            index++;
        }

        return followersArray;
    }
}