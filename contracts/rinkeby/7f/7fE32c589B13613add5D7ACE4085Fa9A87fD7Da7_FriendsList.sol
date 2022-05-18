// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IFriendsList.sol";
import "./structs/FriendInfo.sol";
contract FriendsList is IFriendsList {
    //Gives us the list of friends 
    //Interface with it by friends[user] => friendslist
    mapping(address => address[]) public override friends;

    //Tells us whether or not two users are friends yet
    //Tells us what index the friend is in the array
    //We store this in a double mapping since we maintain a O(1) for the indexing of the array.  Beyond 15 friends and we're more efficient than looping.
    //Also since we're just leaving in the empty slots in the friends list to be thrown out for free in the UI we get even more efficient than looping
    //Interface with it by friendStatus[user][friend].friendYet => yes or no defaults to no
    //Interface with it by friendStatus[user][friend].friendIndex => index of the friend's address in the array
    mapping(address => mapping(address => FriendInfo)) private friendStatus;

    //=========================================
    //================ Friends ================
    //=========================================
    
    
    function addFriend(address _friend) public override notAlreadyFriends(msg.sender, _friend) {
        address[] storage friendList = friends[msg.sender];
        FriendInfo storage status = friendStatus[msg.sender][_friend];
        status.friendIndex = friendList.length;   //Don't have to minus 1 since we do it before we push to the array
        friendList.push(_friend);
        status.friendYet = true;
        emit AddFriend(msg.sender, _friend);
    }

    function removeFriend(address _friend) public override alreadyFriends(msg.sender, _friend) {
        address[] storage friendList = friends[msg.sender];
        uint256 index = getFriendIndex(msg.sender, _friend);
        friendList[index] = address(0);
        friendStatus[msg.sender][_friend].friendYet = false;
        //Don't need to reset the index here since we no longer are pointing to a real address
        emit RemoveFriend(msg.sender, _friend);
    }

    //=======================================
    //================ Batch ================
    //=======================================

    function addSeveralFriends(address[] memory _friends) public override  {
        for(uint256 i = 0; i < _friends.length; i++) {
            addFriend(_friends[i]);
        }
    }

    function removeSeveralFriends(address[] memory _friends) public override  {
        for(uint256 i = 0; i < _friends.length; i++) {
            removeFriend(_friends[i]);
        }
    }

    //=======================================
    //================ Views ================
    //=======================================

    function getFriends(address _addr) public override view  returns (address[] memory) {
        return friends[_addr];
    }

    function getFriendStatus(address _user, address _friend) public override view  returns (bool) { 
        return friendStatus[_user][_friend].friendYet;
    }

    function getFriendIndex(address _user, address _friend) public override view  returns (uint256) { 
        return friendStatus[_user][_friend].friendIndex;
    }
    

    //===========================================
    //================ Modifiers ================
    //===========================================

    modifier notSender(address friend) {
        require(msg.sender != friend);
        _;
    }

    modifier notAlreadyFriends(address _user, address _friend) {
        require(!getFriendStatus(_user, _friend));
        _;
    }

    modifier alreadyFriends(address _user, address _friend) {
        require(getFriendStatus(_user, _friend));
        _;
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFriendsList {

    event AddFriend(address indexed sender, address indexed added);
    event RemoveFriend(address indexed sender, address indexed removed); 

    function addFriend(address _friend) external ;

    function removeFriend(address _friend) external;

    function addSeveralFriends(address[] memory _friends) external;

    function removeSeveralFriends(address[] memory _friends) external;

    function getFriends(address _addr) external view returns (address[] memory);

    function getFriendStatus(address _user, address _friend) external view returns (bool);

    function getFriendIndex(address _user, address _friend) external view returns (uint256);

    function friends(address user, uint index) external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
struct FriendInfo {
    bool friendYet;
    uint256 friendIndex;
}