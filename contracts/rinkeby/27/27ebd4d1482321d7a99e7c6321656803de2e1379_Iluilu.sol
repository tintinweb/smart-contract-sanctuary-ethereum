/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract Iluilu {
    using SafeMath for uint256;

    constructor() {
        admin = msg.sender;
    }

    struct User {
        uint256 userId;
        address userAddress;
        int256 latitude;
        int256 longitude;
        Gender gender;
        string data;
    }

    struct Conversation {
        uint256 id;
        uint256 firstUser;
        uint256 secondUser;
        string data;
    }

    struct Notification {
        uint256 senderId;
        uint256 receiverId;
        string notificationType;
        string message;
        uint256 timeStamp;
    }

    struct Match {
        uint256 matchId;
        uint256 firstUser;
        uint256 secondUser;
    }

    enum LikedStatus {
        liked,
        disliked
    }

    enum Gender {
        male,
        female,
        other
    }

    struct LikedUser {
        LikedStatus likedStatus;
        uint256 likedUser;
        uint256 likedBy;
        uint256 date;
    }
    string private _appInfo;
    address public admin;

    mapping(uint256 => User) public users;
    mapping(uint256 => Conversation) public conversations;
    mapping(uint256 => LikedUser) public likedUsers;
    mapping(address => uint256) public userIds;
    mapping(address => string) public flaggedUserDataMap;
    mapping(uint256 => LikedUser) public likedDataMap;
    mapping(uint256 => Match) public matches;
    mapping(uint256 => Notification[]) public notifications;

    event ConversationNotification(
        string from,
        string to,
        uint256 time,
        string textMsg
    );

    event NotificationEvent(
        uint256 senderId,
        uint256 receiverId,
        string notificationType,
        string message,
        uint256 timeStamp
    );

    uint256 public totalUsers;
    uint256 public conversationIndex;
    uint256 likeDataIndex;
    uint256 totalMatches;
    uint256 totalNotifications;

    function isRegistered() public view returns (bool) {
        uint256 userId = userIds[msg.sender];
        return keccak256(bytes(users[userId].data)) != keccak256(bytes(""));
    }

    function getUserData() public view returns (string memory) {
        return users[userIds[msg.sender]].data;
    }

    function deleteAccount() public payable {
        uint256 userId = userIds[msg.sender];
        delete users[userId];
        delete userIds[msg.sender];
    }

    function updateUser(
        uint256 userId,
        int256 latitude,
        int256 longitude,
        string memory userData,
        Gender gender
    ) public payable {
        users[userIds[msg.sender]] = User(
            userId,
            msg.sender,
            latitude,
            longitude,
            gender,
            userData
        );
    }

    function setNewUser(
        int256 latitude,
        int256 longitude,
        string memory userData,
        Gender gender
    ) public payable {
        users[totalUsers] = User(
            totalUsers,
            msg.sender,
            latitude,
            longitude,
            gender,
            userData
        );
        totalUsers++;
    }

    function setAppInfo(string memory data) public payable {
        _appInfo = data;
    }

    function getAppInfo() public view returns (string memory) {
        return _appInfo;
    }

    function flagUser(address flaggedUserAddress, string memory data)
        public
        payable
    {
        flaggedUserDataMap[flaggedUserAddress] = data;
    }

    // function getLikedUserData()

    function getAllConversation() public view returns (uint256[] memory) {
        uint256[] memory data = new uint256[](conversationIndex);
        uint256 j = 0;
        for (uint256 i = 0; i < conversationIndex; i++) {
            if (
                userIds[msg.sender] == conversations[i].firstUser ||
                userIds[msg.sender] == conversations[i].secondUser
            ) {
                data[j] = conversations[i].id;
                j++;
            }
        }
        return data;
    }

    function likeOrDislikeUser(
        uint256 likedUserId,
        bool isLike,
        uint256 timeStamp
    ) public payable {
        LikedStatus status = LikedStatus.liked;
        if (isLike == false) {
            status = LikedStatus.disliked;
        }
        LikedUser memory likedData = LikedUser(
            status,
            likedUserId,
            userIds[msg.sender],
            timeStamp
        );
        likedDataMap[likeDataIndex] = likedData;
        likeDataIndex++;
    }

    function saveMatch(uint256 firstUser, uint256 secondUser) public payable {
        matches[totalMatches] = Match(totalMatches, firstUser, secondUser);
    }

    function removeMatch(uint256 matchId) public payable {
        delete matches[matchId];
    }

    function removeAllLikesOrDislikes(LikedStatus status) public payable {
        for (uint256 i = 0; i < likeDataIndex; i++) {
            if (
                likedDataMap[i].likedBy == userIds[msg.sender] &&
                likedDataMap[i].likedStatus == status
            ) {
                delete likedDataMap[i];
            }
        }
    }

    function getAllMatches() public view returns (uint256[] memory) {
        uint256[] memory data = new uint256[](totalMatches);
        uint256 j = 0;
        for (uint256 i = 0; i < totalMatches; i++) {
            if (
                matches[i].firstUser == userIds[msg.sender] ||
                matches[i].secondUser == userIds[msg.sender]
            ) {
                data[j] = matches[i].matchId;
                j++;
            }
        }
        return data;
    }

    function removeAllLikedOrDislikedMe(LikedStatus status) public payable {
        for (uint256 i = 0; i < likeDataIndex; i++) {
            if (
                likedDataMap[i].likedUser == userIds[msg.sender] &&
                likedDataMap[i].likedStatus == status
            ) {
                delete likedDataMap[i];
            }
        }
    }

    function removelikeOrDislike(uint256 likedUserId) public payable {
        for (uint256 i = 0; i < likeDataIndex; i++) {
            if (
                likedDataMap[i].likedBy == userIds[msg.sender] &&
                likedDataMap[i].likedUser == likedUserId
            ) {
                delete likedDataMap[i];
            }
        }
    }

    function getLikedOrDislikedUsers(LikedStatus status)
        public
        view
        returns (string[] memory)
    {
        string[] memory data = new string[](totalUsers);
        uint256 j = 0;
        for (uint256 i = 0; i < likeDataIndex; i++) {
            if (
                likedDataMap[i].likedBy == userIds[msg.sender] &&
                likedDataMap[i].likedStatus == status
            ) {
                User memory userJson = users[likedDataMap[i].likedUser];
                data[j] = userJson.data;
                j++;
            }
        }
        return data;
    }

    function getLikedOrDislikedMeUsers(LikedStatus status)
        public
        view
        returns (string[] memory)
    {
        string[] memory data = new string[](totalUsers);
        uint256 j = 0;
        for (uint256 i = 0; i < likeDataIndex; i++) {
            if (
                likedDataMap[i].likedUser == userIds[msg.sender] &&
                likedDataMap[i].likedStatus == status
            ) {
                User memory userJson = users[likedDataMap[i].likedUser];
                data[j] = userJson.data;
                j++;
            }
        }
        return data;
    }

    function notificationsLength(uint256 uid) public view returns (uint256) {
        return notifications[uid].length;
    }

    function isLikedOrDisliked(uint256 queryUser) public view returns (bool) {
        for (uint256 i = 0; i < likeDataIndex; i++) {
            if (
                likedDataMap[i].likedBy == userIds[msg.sender] &&
                likedDataMap[i].likedUser == queryUser
            ) {
                return true;
            }
        }
        return false;
    }

    function getNearbyUsers(
        int256 latitude,
        int256 longitude,
        int256 maxDistance,
        Gender gender
    ) public view returns (string[] memory) {
        string[] memory data = new string[](totalUsers);
        uint256 k = 0;
        for (uint256 i = 0; i < totalUsers; i++) {
            int256 distance = getDistance(
                latitude,
                longitude,
                users[i].latitude,
                users[i].longitude
            );

            if (gender == Gender.other) {
                if (distance < maxDistance) {
                    data[k] = users[i].data;
                    k++;
                }
            } else {
                if (distance < maxDistance && users[i].gender == gender) {
                    data[k] = users[i].data;
                    k++;
                }
            }
        }
        return data;
    }

    function getFilteredData(string[] memory queries)
        public
        view
        returns (string[] memory)
    {
        string[] memory data = new string[](totalUsers);
        uint256 k = 0;
        for (uint256 i = 0; i < totalUsers; i++) {
            bool hasMatch = true;
            for (uint256 j = 0; j < queries.length; j++) {
                if (!containWord(queries[i], users[i].data)) {
                    hasMatch = false;
                    break;
                }
            }
            if (hasMatch) {
                data[k] = users[i].data;
                k++;
            }
        }
        return data;
    }

    function removeConversationWithConversationId(uint256 conversationId)
        public
        payable
    {
        delete conversations[conversationId];
    }

    function getConversationFromUserId(uint256 userId)
        public
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < conversationIndex; i++) {
            if (
                (conversations[i].firstUser == userId &&
                    conversations[i].secondUser == userIds[msg.sender]) ||
                (conversations[i].secondUser == userId &&
                    conversations[i].firstUser == userIds[msg.sender])
            ) {
                return i;
            }
        }
        return conversationIndex;
    }

    function saveConversation(
        uint256 conversationId,
        uint256 user1id,
        uint256 user2id,
        string memory data
    ) public payable {
        if (
            user1id == conversations[conversationId].firstUser &&
            user2id == conversations[conversationId].secondUser
        ) {
            conversations[conversationId] = Conversation(
                conversationId,
                user1id,
                user2id,
                data
            );
        } else {
            conversations[conversationIndex] = Conversation(
                conversationIndex,
                user1id,
                user2id,
                data
            );
            conversationIndex++;
        }
    }

    function containWord(string memory what, string memory where)
        internal
        pure
        returns (bool found)
    {
        bytes memory whatBytes = bytes(what);
        bytes memory whereBytes = bytes(where);

        //require(whereBytes.length >= whatBytes.length);
        if (whereBytes.length < whatBytes.length) {
            return false;
        }

        found = false;
        for (uint256 i = 0; i <= whereBytes.length - whatBytes.length; i++) {
            bool flag = true;
            for (uint256 j = 0; j < whatBytes.length; j++)
                if (whereBytes[i + j] != whatBytes[j]) {
                    flag = false;
                    break;
                }
            if (flag) {
                found = true;
                break;
            }
        }
        return found;
    }

    function getDistance(
        int256 x1,
        int256 x2,
        int256 y1,
        int256 y2
    ) private pure returns (int256) {
        return sqrt(((x2 - x1)**2) + ((y2 - y1)**2));
    }

    function sqrt(int256 x) private pure returns (int256 y) {
        int256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function checkMatch(uint256 userId) public view returns (bool) {
        bool hasLikedMe = false;
        bool likedByMe = false;
        for (uint256 i = 0; i < likeDataIndex; i++) {
            if (likedDataMap[i].likedStatus == LikedStatus.disliked) {
                continue;
            }
            if (
                likedDataMap[i].likedBy == userIds[msg.sender] &&
                likedDataMap[i].likedUser == userId
            ) {
                likedByMe = true;
                if (likedByMe && hasLikedMe) return true;
            }
            if (
                likedDataMap[i].likedUser == userIds[msg.sender] &&
                likedDataMap[i].likedBy == userId
            ) {
                hasLikedMe = true;
                if (likedByMe && hasLikedMe) return true;
            }
        }
        return hasLikedMe && likedByMe;
    }

    function saveNotification(
        uint256 senderId,
        uint256 receiverId,
        string memory notificationType,
        string memory notificationMsg,
        uint256 timeStamp
    ) public payable {
        Notification memory notification = Notification(
            senderId,
            receiverId,
            notificationType,
            notificationMsg,
            timeStamp
        );

        notifications[receiverId].push(notification);
        notifications[senderId].push(notification);
    }

    function sendPushNotification(
        uint256 senderId,
        uint256 receiverId,
        string memory notificationType,
        string memory notificationMsg,
        uint256 timeStamp
    ) public payable {
        emit NotificationEvent(
            senderId,
            receiverId,
            notificationType,
            notificationMsg,
            timeStamp
        );
    }

    function deleteUserNotification(uint256 userId) public payable {
        delete notifications[userId];
    }

    function deleteUserSentNotifications(uint256 userId) public payable {
        for (uint256 i = 0; i < notifications[userId].length; i++) {
            if (notifications[userId][i].senderId == userId) {
                delete notifications[userId][i];
            }
        }
    }
}