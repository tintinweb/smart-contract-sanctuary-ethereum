// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Totem is ReentrancyGuard {
    mapping(uint256 => uint256) public challengeCount;
    mapping(address => bool) isProfessor;
    mapping(address => bool) hasAccount;
    mapping(uint256 => Course) public courses;
    mapping(bytes32 => address) public whitelistedTokens;
    mapping(address => mapping(bytes32 => uint256)) public accountBalances;

    constructor() {
        owner = msg.sender;
    }

    event CourseAdded(
        string name,
        address indexed courseOwner,
        uint256 totalStaked,
        address stakedTokenAddress,
        uint256 indexed courseId
    );



    event StudentAdded(uint256 indexed courseId, address indexed studentAddress);
    event ChallengeAdded(uint256 indexed challengeId, uint256 indexed courseId,uint256 challengeReward);
    event SubmittedChallenge(uint256 indexed courseId, uint256 indexed challengeId, string asnwer);
    event ValidatedSubmit(uint256 indexed challengeId, uint256 indexed courseId, uint256 score,uint256 rewardAmount, address indexed studentAddress);
    event Claimed(uint256 indexed challengeId,uint256 indexed courseId, address indexed studentAddress, uint256 reward);




    enum Status {
        notSubmitted,
        Submitted,
        Validated,
        Claimed
    }

    struct Course {
        string name;
        bool isActive;
        address courseOwner;
        uint256 totalStaked;
        address stakedTokenAddress;
        mapping(address => bool) students;
        mapping(uint256 => Challenge) Challenges;
        uint256 studentId;
        uint256 courseId;
    }

    struct Challenge {
        mapping(address => Status) studentStatus;
        mapping(address => uint256) studentReward;
        uint256 rewardAmount;
        uint256 challengeId;
        mapping(address => string) storedAnswer;
    }

    Status public status;

    address owner;
    uint256 courseCount;
    uint256 studentCount;
    Course[] public allCourses;

    function whitelistTokens(bytes32 symbol, address tokenAddress) external {
        require(msg.sender == owner, "This function is not public");
        whitelistedTokens[symbol] = tokenAddress;
    }

    function depositTokens(uint256 amount, bytes32 symbol) external {
        accountBalances[msg.sender][symbol] += amount;
        IERC20(whitelistedTokens[symbol]).transferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    function withdrawTokens(uint256 amount, bytes32 symbol) external {
        require(
            accountBalances[msg.sender][symbol] >= amount,
            "Insufficient funds"
        );
        IERC20(whitelistedTokens[symbol]).transfer(msg.sender, amount);
    }


    function addCourse(
        string memory name,
        address ownerAddress,
        uint256 stakeAmount,
        address tokenAddress
    ) public {
        IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            stakeAmount
        );
        courseCount++;
        courses[courseCount].name = name;
        courses[courseCount].isActive = true;
        courses[courseCount].courseOwner = ownerAddress;
        //Transfer tokenAddress stakeAmonunt to this contract
        courses[courseCount].totalStaked = stakeAmount;
        courses[courseCount].stakedTokenAddress = tokenAddress;
        courses[courseCount].courseId = courseCount;
    
        emit CourseAdded(
            name,
            ownerAddress,
            stakeAmount,
            tokenAddress,
            courseCount
        );
    }

    function addStudents(address studentAddress, uint256 courseId) public {
        require(courses[courseId].courseOwner == msg.sender, "You're not the professor of this Course");
        courses[courseId].students[studentAddress] = true;
        emit StudentAdded(courseId, studentAddress);
    }

    function addChallenge(uint256 courseId, uint256 challengeReward) public {
        require(courses[courseId].courseOwner == msg.sender, "You're not the professor of this Course");
        challengeCount[courseId]=challengeCount[courseId]+1;
        // courses[courseId].Challenges[challengeCount[courseId]];
        courses[courseId]
            .Challenges[challengeCount[courseId]]
            .rewardAmount = challengeReward;
        emit ChallengeAdded(challengeCount[courseId], courseId, challengeReward);
    }

    function submitChallenge(
        string memory answer,
        uint256 courseId,
        uint256 challengeId
    ) public {
        //add only student require
        require(courses[courseId].students[msg.sender] = true, 'Address not a student of this Course');
        //require that challenge exists
        require(courses[courseId].Challenges[challengeId].rewardAmount > 0, 'Challenge doesnt Exist');
        courses[courseId].Challenges[challengeId].studentStatus[
            msg.sender
        ] = Status.Submitted;
        courses[courseId]
            .Challenges[challengeId]
            .storedAnswer[msg.sender] = answer;
        emit SubmittedChallenge(courseId, challengeId, answer);
    }

    function validateSubmit(
        uint256 challengeId,
        uint256 courseId,
        uint256 score,
        address studentAddress
    ) public {
        require(courses[courseId].courseOwner == msg.sender, "You're not the professor of this Course");
        require(
            courses[courseId].Challenges[challengeId].studentStatus[
                studentAddress
            ] == Status.Submitted
        );
        courses[courseId].Challenges[challengeId].studentStatus[
            studentAddress
        ] = Status.Validated;
        courses[courseId].Challenges[challengeId].studentReward[studentAddress] =
            (score *
            courses[courseId].Challenges[challengeId].rewardAmount)/100;
        emit ValidatedSubmit(challengeId, courseId,score,
            courses[courseId].Challenges[challengeId].rewardAmount , studentAddress
        );
    }

    function Claim(uint256 challengeId, uint256 courseId) public {
        require(
            courses[courseId].Challenges[challengeId].studentStatus[
                msg.sender
            ] == Status.Validated
        );
        courses[courseId].Challenges[challengeId].studentStatus[
            msg.sender
        ] = Status.Claimed;
        IERC20(courses[courseCount].stakedTokenAddress).transfer(
            msg.sender,
            courses[courseId].Challenges[challengeId].studentReward[msg.sender]
        );
        emit Claimed(challengeId,courseId, msg.sender, courses[courseId].Challenges[challengeId].rewardAmount);
    }

    function getChallengeReward(uint256 courseId, uint256 challengeId) public view returns(uint256 reward) {
        return courses[courseId].Challenges[challengeId].rewardAmount;
        //  courses[courseId].Challenges[challengeCount[courseId]].rewardAmount
    }

     function getStudentReward(uint256 courseId, uint256 challengeId,  address studentAddress) public view returns(uint256 reward) {
        return courses[courseId].Challenges[challengeId].studentReward[studentAddress];
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}