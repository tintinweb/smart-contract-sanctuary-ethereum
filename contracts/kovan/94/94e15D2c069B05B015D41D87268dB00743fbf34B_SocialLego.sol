// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract SocialLego is KeeperCompatibleInterface, Ownable {
    address keeperRegistryAddress;

    modifier onlyKeeper() {
        require(msg.sender == keeperRegistryAddress);
        _;
    }

    uint256 public lastCheckIn = block.timestamp;
    uint256 public checkInTimeInterval = 864000; //default to six months
    address public nextOwner;

    struct Comment {
        address commenter;
        string message;
        uint256 timestamp;
    }

    struct Post {
        uint256 numberOfLikes;
        uint256 timestamp;
        string message;
        string url;
        uint256 totalComments; // list of userPosts. probably can remove
        mapping(uint256 => Comment) commentStructs; // mapping of postkey to post
    }

    struct userProfile {
        bool exists;
        address userAddress; // Might not need
        string profileImageUrl;
        string userProfileBio;
        string userNickname;
        uint256 followerCount;
        uint256 joinDate;
        uint256 featuredPost;
        uint256 userPosts; // list of userPosts. probably can remove
        mapping(uint256 => Post) postStructs; // mapping of postkey to post
    }

    mapping(address => userProfile) userProfileStructs; // mapping useraddress to user profile
    address[] userProfileList; // list of user profiles
    event sendMessageEvent(
        address senderAddress,
        address recipientAddress,
        uint256 time,
        string message
    );
    event newPost(address senderAddress, uint256 postID);

    constructor(address _keeperRegistryAddress) {
        keeperRegistryAddress = _keeperRegistryAddress;
    }

    function sendMessage(address recipientAddress, string memory message)
        public
    {
        require(
            userProfileStructs[msg.sender].exists == true,
            "Create an Account to Post"
        ); // Check to see if they have an account
        emit sendMessageEvent(
            msg.sender,
            recipientAddress,
            block.timestamp,
            message
        );
    }

    function newProfile(string memory newProfileBio, string memory nickName)
        public
        returns (
            // onlyOwner
            bool success
        )
    {
        require(
            userProfileStructs[msg.sender].exists == false,
            "Account Already Created"
        ); // Check to see if they have an account
        userProfileStructs[msg.sender].userProfileBio = newProfileBio;
        userProfileStructs[msg.sender].userNickname = nickName;
        userProfileStructs[msg.sender].followerCount = 0;
        userProfileStructs[msg.sender].exists = true;
        userProfileStructs[msg.sender].joinDate = block.timestamp;
        userProfileStructs[msg.sender].featuredPost = 0;
        userProfileStructs[msg.sender].userProfileBio = "";
        userProfileList.push(msg.sender);
        return true;
    }

    function getUserProfile(address userAddress)
        public
        view
        returns (
            string memory profileBio,
            uint256 totalPosts,
            uint256 joinDate,
            uint256 followerCount,
            string memory userNickname,
            uint256 featuredPost,
            string memory profileImageUrl
        )
    {
        return (
            userProfileStructs[userAddress].userProfileBio,
            userProfileStructs[userAddress].userPosts,
            userProfileStructs[userAddress].joinDate,
            userProfileStructs[userAddress].followerCount,
            userProfileStructs[userAddress].userNickname,
            userProfileStructs[userAddress].featuredPost,
            userProfileStructs[userAddress].profileImageUrl
        );
    }

    function addPost(string memory messageText, string memory url)
        public
        returns (bool success)
    {
        require(
            userProfileStructs[msg.sender].exists == true,
            "Create an Account to Post"
        ); // Check to see if they have an account
        uint256 postID = (userProfileStructs[msg.sender].userPosts); // ID is just an increment. No need to be random since it is associated to each unique account
        userProfileStructs[msg.sender].userPosts += 1;
        userProfileStructs[msg.sender]
            .postStructs[postID]
            .message = messageText;
        userProfileStructs[msg.sender].postStructs[postID].timestamp = block
            .timestamp;
        userProfileStructs[msg.sender].postStructs[postID].numberOfLikes = 0;
        userProfileStructs[msg.sender].postStructs[postID].url = url;
        emit newPost(msg.sender, postID); // emit a post to be used on the explore page
        return true;
    }

    function addComment(
        address postOwner,
        uint256 postID,
        string memory commentText
    ) public returns (bool success) {
        require(
            userProfileStructs[msg.sender].exists == true,
            "Create an Account to Comment"
        ); // Check to see if they have an account
        require(
            userProfileStructs[postOwner].postStructs[postID].timestamp != 0,
            "No Post Exists"
        ); //Check to see if comment exists. Timestamps default to 0
        uint256 commentID = userProfileStructs[postOwner]
            .postStructs[postID]
            .totalComments; // ID is just an increment. No need to be random since it is associated to each unique account
        userProfileStructs[postOwner].postStructs[postID].totalComments += 1;
        userProfileStructs[postOwner]
            .postStructs[postID]
            .commentStructs[commentID]
            .commenter = msg.sender;
        userProfileStructs[postOwner]
            .postStructs[postID]
            .commentStructs[commentID]
            .message = commentText;
        userProfileStructs[postOwner]
            .postStructs[postID]
            .commentStructs[commentID]
            .timestamp = block.timestamp;
        return true;
    }

    function getComment(
        address postOwner,
        uint256 postID,
        uint256 commentID
    )
        public
        view
        returns (
            address commenter,
            string memory message,
            uint256 timestamp,
            string memory userNickname,
            string memory profileImageUrl
        )
    {
        return (
            userProfileStructs[postOwner]
                .postStructs[postID]
                .commentStructs[commentID]
                .commenter,
            userProfileStructs[postOwner]
                .postStructs[postID]
                .commentStructs[commentID]
                .message,
            userProfileStructs[postOwner]
                .postStructs[postID]
                .commentStructs[commentID]
                .timestamp,
            userProfileStructs[
                userProfileStructs[postOwner]
                    .postStructs[postID]
                    .commentStructs[commentID]
                    .commenter
            ].userNickname,
            userProfileStructs[
                userProfileStructs[postOwner]
                    .postStructs[postID]
                    .commentStructs[commentID]
                    .commenter
            ].profileImageUrl
        );
    }

    // Please Hire me

    function changeUserBio(string memory bioText)
        public
        returns (bool success)
    {
        require(
            userProfileStructs[msg.sender].exists == true,
            "Create an Account First"
        ); // Check to see if they have an account
        userProfileStructs[msg.sender].userProfileBio = bioText;
        return true;
    }

    function changeUserProfilePicture(string memory url)
        public
        returns (bool success)
    {
        require(
            userProfileStructs[msg.sender].exists == true,
            "Create an Account First"
        ); // Check to see if they have an account
        userProfileStructs[msg.sender].profileImageUrl = url;
        return true;
    }

    function changeUserNickname(string memory newNickName)
        public
        returns (bool success)
    {
        require(
            userProfileStructs[msg.sender].exists == true,
            "Create an Account First"
        ); // Check to see if they have an account
        userProfileStructs[msg.sender].userNickname = newNickName;
        return true;
    }

    function changeFeaturedPost(uint256 postNumber)
        public
        returns (bool success)
    {
        require(
            userProfileStructs[msg.sender].exists == true,
            "Create an Account First"
        ); // Check to see if they have an account
        userProfileStructs[msg.sender].featuredPost = postNumber;
        return true;
    }

    function getUserPost(address userAddress, uint256 postKey)
        external
        view
        returns (
            string memory message,
            uint256 numberOfLikes,
            uint256 timestamp,
            string memory url,
            string memory userNickname,
            uint256 totalComments
        )
    {
        return (
            userProfileStructs[userAddress].postStructs[postKey].message,
            userProfileStructs[userAddress].postStructs[postKey].numberOfLikes,
            userProfileStructs[userAddress].postStructs[postKey].timestamp,
            userProfileStructs[userAddress].postStructs[postKey].url,
            userProfileStructs[userAddress].userNickname,
            userProfileStructs[userAddress].postStructs[postKey].totalComments
        ); // stack is too deep if I try to call profileImageUrl as well
    }

    function getAllUserPosts(address userAddress)
        public
        view
        returns (uint256 userPosts)
    {
        return (userProfileStructs[userAddress].userPosts);
    }

    function getTotalUsers() public view returns (uint256 totalUsers) {
        return userProfileList.length;
    }

    function likePost(address userAddress, uint256 postKey)
        public
        returns (bool success)
    {
        require(
            userProfileStructs[msg.sender].exists == true,
            "Create an Account First"
        ); // Check to see if they have an account
        userProfileStructs[userAddress].postStructs[postKey].numberOfLikes += 1;
        return true;
    }

    function followUser(address userAddress) public returns (bool success) {
        require(
            userProfileStructs[msg.sender].exists == true,
            "Create an Account First"
        ); // Check to see if they have an account
        userProfileStructs[userAddress].followerCount += 1;
        return true;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Hire me so I don’t grow to be your competitor ;)

    function changeInheritance(address newInheritor) public onlyOwner {
        nextOwner = newInheritor;
    }

    function ownerCheckIn() public onlyOwner {
        lastCheckIn = block.timestamp;
    }

    function changeCheckInTime(uint256 newCheckInTimeInterval)
        public
        onlyOwner
    {
        checkInTimeInterval = newCheckInTimeInterval; // let owner change check in case he know he will be away for a while.
    }

    function passDownInheritance() internal {
        transferOwnership(nextOwner);
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        return (
            block.timestamp > (lastCheckIn + checkInTimeInterval),
            bytes("")
        ); // make sure to check in at least once every 6 months
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override onlyKeeper {
        passDownInheritance();
    }

    function withdraw(uint256 amount) public onlyOwner returns (bool) {
        require(amount <= address(this).balance);
        payable(msg.sender).transfer(amount); //if the owner send to sender
        return true;
    }

    function withdrawErc20(IERC20 token) public onlyOwner {
        require(
            token.transfer(msg.sender, token.balanceOf(address(this))),
            "Transfer failed"
        );
    }

    receive() external payable {
        // nothing to do but accept money
    }
}