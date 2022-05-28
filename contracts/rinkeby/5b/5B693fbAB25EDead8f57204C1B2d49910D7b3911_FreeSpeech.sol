// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./base/FollowManager.sol";

// TODO: create the linkedlist contract
// TODO: Block user feature (perform unfollow)
// TODO: create follower Module como en el Safe
// TODO: create follower address validation as modifier
// TODO: think about beneficiary Message schema ??? (distinguir entre creador del Message y el beneficiario!)

contract FreeSpeech is FollowManager {
    // address internal constant SENTINEL_ADDRESS = address(0x1);
    // // mapping of a linked list
    // mapping(address => mapping(address => address)) private followers;
    // mapping(address => uint256) private followersCount;
    // function follow(address follower) public payable {
    //     // follower address cannot be null
    //     require(follower != address(0), "FS101");
    //     // follower address cannot be the sentinel address
    //     require(follower != SENTINEL_ADDRESS, "FS101");
    //     // follower address cannot be the FreeSpeech contract address itself
    //     require(follower != address(this), "FS101");
    //     // you cannot be followed by yourself
    //     require(follower != msg.sender, "FS101");
    //     // TODO: require el user is blocked???
    //     // if its your first follower
    //     if (followersCount[msg.sender] == 0) {
    //         // initialize the followers linked list with the first follower
    //         followers[msg.sender][SENTINEL_ADDRESS] = follower;
    //         followers[msg.sender][follower] = SENTINEL_ADDRESS;
    //         followersCount[msg.sender]++;
    //     } else {
    //         // No duplicate followers allowed
    //         require(followers[msg.sender][follower] == address(0), "FS102");
    //         // set this address as follower for this user
    //         followers[msg.sender][follower] = followers[msg.sender][
    //             SENTINEL_ADDRESS
    //         ];
    //         followers[msg.sender][SENTINEL_ADDRESS] = follower;
    //         followersCount[msg.sender]++;
    //     }
    //     // transfer the amount to the follower
    //     payable(follower).transfer(msg.value);
    //     // TODO: emit followEvent ?¿
    // }
    // function unFollow(address prevFollower, address follower) public {
    //     // follower address cannot be null
    //     require(follower != address(0), "FS101");
    //     // follower address cannot be the sentinel address
    //     require(follower != SENTINEL_ADDRESS, "FS101");
    //     // follower address cannot be the FreeSpeech contract address itself
    //     require(follower != address(this), "FS101");
    //     // prevFollower is valid
    //     require(followers[msg.sender][prevFollower] == follower, "FS103");
    //     followers[msg.sender][prevFollower] = followers[msg.sender][follower];
    //     followers[msg.sender][follower] = address(0);
    //     followersCount[msg.sender]--;
    //     // TODO: emit unFollowEvent ?¿
    // }
    // function getFollowers(address user) public view returns (address[] memory) {
    //     // user without followers returns empty array
    //     if (followersCount[user] == 0) {
    //         address[] memory emptyArray = new address[](0);
    //         return emptyArray;
    //     }
    //     address[] memory followersArray = new address[](followersCount[user]);
    //     // populate the returned array with the user's followers
    //     uint256 index = 0;
    //     address currentFollower = followers[user][SENTINEL_ADDRESS];
    //     while (currentFollower != SENTINEL_ADDRESS) {
    //         followersArray[index] = currentFollower;
    //         currentFollower = followers[user][currentFollower];
    //         index++;
    //     }
    //     return followersArray;
    // }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract FollowManager {
    event Follow(address userAddress, address follower);
    event Unfollow(address userAddress, address follower);

    // sentinel address for linked list
    address internal constant SENTINEL_ADDRESS = address(0x1);

    // followers are a linked list
    mapping(address => mapping(address => address)) private followers;
    mapping(address => uint256) private followersCount;

    function follow(address follower) public payable {
        // follower address cannot be null
        require(follower != address(0), "FS101");

        // follower address cannot be the sentinel address
        require(follower != SENTINEL_ADDRESS, "FS101");

        // follower address cannot be the FreeSpeech contract address itself
        require(follower != address(this), "FS101");

        // you cannot be followed by yourself
        require(follower != msg.sender, "FS101");

        // TODO: require el user is blocked???

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

        // transfer the amount to the follower
        payable(follower).transfer(msg.value);

        emit Follow(msg.sender, follower);
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

        emit Unfollow(msg.sender, follower);
    }

    function getFollowers(address user) public view returns (address[] memory) {
        // user without followers returns empty array
        if (followersCount[user] == 0) {
            address[] memory emptyArray = new address[](0);
            return emptyArray;
        }

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