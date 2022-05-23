// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract FreeSpeech {
    address internal constant SENTINEL_ADDRESS = address(0x1);

    mapping(address => mapping(address => address)) private followers;
    mapping(address => uint256) private followersCount;

    function follow(address follower) public payable {
        // follower address cannot be null, the sentinel address or the FreeSpeech contract address itself.
        require(
            follower != address(0) &&
                follower != SENTINEL_ADDRESS &&
                follower != address(this),
            "FS101"
        );

        // if its your first follower
        if (followersCount[msg.sender] == 0) {
            followers[msg.sender][SENTINEL_ADDRESS] = follower;
            followers[msg.sender][follower] = SENTINEL_ADDRESS;
            followersCount[msg.sender]++;
        } else {
            // No duplicate followers allowed.
            require(followers[msg.sender][follower] == address(0), "FS102");

            // set this address as follower for this user
            followers[msg.sender][follower] = SENTINEL_ADDRESS;
            followers[msg.sender][SENTINEL_ADDRESS] = follower;
            followersCount[msg.sender]++;
        }

        // TODO: emit followEvent ?¿

        // TODO: send the amount to the follower user address
    }

    function unFollow(address prevFollower, address follower) public {
        // follower address cannot be null, the sentinel address or the FreeSpeech contract address itself.
        require(
            follower != address(0) &&
                follower != SENTINEL_ADDRESS &&
                follower != address(this),
            "FS101"
        );

        // prevFollower is valid
        require(followers[msg.sender][prevFollower] == follower, "FS103");

        followers[msg.sender][prevFollower] = followers[msg.sender][follower];
        followers[msg.sender][follower] = address(0);
        followersCount[msg.sender]--;

        // TODO: emit unFollowEvent ?¿
    }

    function getFollowers(address user) public view returns (address[] memory) {
        address[] memory followersArray = new address[](followersCount[user]);

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