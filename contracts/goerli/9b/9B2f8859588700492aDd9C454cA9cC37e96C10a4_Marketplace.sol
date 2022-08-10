// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// SafeMath
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

error Marketplace__OnlyContractOwner();
error Marketplace__OnlyCourseAuthor();
error Marketplace__CourseAuthorAddressIsSame();
error Marketplace__CourseAuthorRewardPercentageOutOfBound();
error Marketplace__CourseAuthorAlreadyExist();
error Marketplace__CourseAlreadyBought();
error Marketplace__CourseAuthorDoesNotExist();
error Marketplace__CourseDoesNotExist();
error Marketplace__CourseDoesAlreadyExist();
error Marketplace__CourseMustBeActivated();
error Marketplace__CourseIsAlreadyDeactivated();
error Marketplace__CourseIsAlreadyActivated();
error Marketplace__CannotPurchaseOwnCourse();

//common error with funds transfer/withdrawal
error Marketplace__InsufficientFunds();
error Marketplace__WithdrawalFundsFailed();
error Marketplace__TransferFundsFailed();

/** @title A marketplace contract
 *  @author Brice Grenard
 *  @notice This contract is a demo of a simple marketplace where programming courses can be promoted and sold
 *  @dev The price feed has been developped outside this contract but could obviously been added in here using Chainlink
 */
contract Marketplace {
    // Library usage
    using SafeMath for uint256;

    address payable private contractOwner;

    receive() external payable {}

    enum PurchaseStatus {
        NotPurchased,
        Purchased
    }

    enum CourseAvailabilityEnum {
        Activated,
        Deactivated
    }

    struct CourseAuthorCoursesStatus {
        bytes32 id; //course id
        CourseAvailabilityEnum availability;
    }

    struct CourseAuthor {
        address _address; //An author may (have to)/change account address
        uint8 rewardPercentage; //A course author negotiates to earn a percentage of his course proposed price
    }

    struct Course {
        bytes32 id;
        CourseAuthor author;
        PurchaseStatus purchaseStatus;
    }

    bytes32[] private s_allCoursesIds;

    //list of all courses stored in this contract
    mapping(bytes32 => Course) public s_allCourses;

    // mapping of courseHash to Course data
    mapping(address => Course[]) private s_customerOwnedCourses;

    // list of all course authors who have course stored in this contract
    mapping(address => CourseAuthor) private s_allCourseAuthors;

    //list of all courses that a course author has published
    mapping(address => Course[]) private s_allCourseAuthorsPublishedCourses;

    mapping(bytes32 => CourseAuthorCoursesStatus) private s_allCourseAuthorsCoursesStatus;

    constructor() {
        setContractOwner(msg.sender);
    }

    /* events */
    event CourseAuthorAdded(address indexed author);
    event CourseAdded(bytes32 indexed courseId);
    event CoursePurchased(bytes32 indexed courseId);
    event CourseActivated(bytes32 indexed courseId);
    event CourseDeactivated(bytes32 indexed courseId);
    event WithdrawFunds(address indexed toAddress, bool indexed success);
    event CourseAuthorAddressChanged();

    // Modifier
    /**
     * Prevents a course to be purchased logic
     */
    modifier canPurchaseCourse(bytes32 courseId) {
        //prevents an author to buy any of his/her own courses
        Course memory course = s_allCourses[courseId];
        if (course.author._address == msg.sender) revert Marketplace__CannotPurchaseOwnCourse();

        //check the status of the course set by the course author
        CourseAuthorCoursesStatus memory courseStatus = s_allCourseAuthorsCoursesStatus[courseId];
        if (courseStatus.availability == CourseAvailabilityEnum.Deactivated)
            revert Marketplace__CourseMustBeActivated();

        //finally check for the purchase status
        if (s_allCourses[courseId].purchaseStatus == PurchaseStatus.Purchased) {
            revert Marketplace__CourseAlreadyBought();
        }
        _;
    }

    // Modifier
    /**
     * Prevents contract interaction with someone else who is not the contract author
     */
    modifier onlyContractOwner() {
        if (msg.sender != contractOwner) {
            revert Marketplace__OnlyContractOwner();
        }
        _;
    }

    modifier onlyAuthor() {
        CourseAuthor memory author = s_allCourseAuthors[msg.sender];

        if (msg.sender != author._address) {
            revert Marketplace__OnlyCourseAuthor();
        }
        _;
    }

    modifier checkCourseShouldNotExist(bytes32 courseId) {
        Course memory existingCourse = s_allCourses[courseId];
        if (existingCourse.id > 0) revert Marketplace__CourseDoesAlreadyExist();
        _;
    }

    modifier checkCourseShouldExist(bytes32 courseId) {
        if (s_allCourses[courseId].id == 0) {
            revert Marketplace__CourseDoesNotExist();
        }
        _;
    }

    // Function
    /**
     * Get current contract owner
     */
    function getContractOwner() external view returns (address _address) {
        return contractOwner;
    }

    // Function
    /**
     * Set a new contract owner
     */
    function setContractOwner(address newContractOwner) private {
        contractOwner = payable(newContractOwner);
    }

    // Function
    /**
     * Transfer contract ownership
     */
    function transferOwnership(address newContractOwner) external onlyContractOwner {
        setContractOwner(newContractOwner);
    }

    // Function
    /**
     * Allows contract owner to withdraw some or all of the funds earned from purchases.
     */
    function withdrawMarketplaceFunds(uint256 amount) external onlyContractOwner {
        /**
         * @param uint Amount to withdraw (in Wei)
         */
        uint256 contractBalance = address(this).balance;

        if (contractBalance <= amount) revert Marketplace__InsufficientFunds();

        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        emit WithdrawFunds(address(this), sent);

        if (!sent) revert Marketplace__WithdrawalFundsFailed();
    }

    // Function
    /**
     * Change course's author recipient address
     */
    function changeCourseAuthorAddress(address newAddress) external onlyAuthor {
        CourseAuthor storage existingAuthor = s_allCourseAuthors[msg.sender];
        if (newAddress == existingAuthor._address) revert Marketplace__CourseAuthorAddressIsSame();

        existingAuthor._address = newAddress;
        s_allCourseAuthors[newAddress] = existingAuthor;

        bytes32[2][] memory courses = getCourseAuthorPublishedCourses(msg.sender);
        for (uint32 i = 0; i < courses.length; i++) {
            Course storage course = s_allCourses[courses[i][0]];
            course.author._address = newAddress;
        }
        emit CourseAuthorAddressChanged();
    }

    // Function
    /**
     * Add a new course author with his negotiated reward percentage
     */
    function addCourseAuthor(address courseAuthorAddress, uint8 rewardPercentage)
        external
        onlyContractOwner
    {
        if (rewardPercentage > 100) revert Marketplace__CourseAuthorRewardPercentageOutOfBound();

        CourseAuthor memory existingOwner = s_allCourseAuthors[courseAuthorAddress];
        if (existingOwner._address != address(0)) revert Marketplace__CourseAuthorAlreadyExist();

        CourseAuthor memory courseAuthor = CourseAuthor({
            _address: courseAuthorAddress,
            rewardPercentage: rewardPercentage
        });
        s_allCourseAuthors[courseAuthorAddress] = courseAuthor;
        emit CourseAuthorAdded(courseAuthorAddress);
    }

    // Function
    /**
     * Add a new course to the contract
     */
    function addCourse(bytes32 id) external onlyAuthor checkCourseShouldNotExist(id) {
        Course memory course = Course({
            id: id,
            author: s_allCourseAuthors[msg.sender],
            purchaseStatus: PurchaseStatus.NotPurchased
        });

        s_allCourses[id] = course;
        s_allCoursesIds.push(id);

        //activate the course by default
        CourseAuthorCoursesStatus memory AuthorCourseStatus = CourseAuthorCoursesStatus({
            id: id,
            availability: CourseAvailabilityEnum.Activated
        });
        s_allCourseAuthorsCoursesStatus[id] = AuthorCourseStatus;

        //finally, add the course to the list of published courses for the current author
        s_allCourseAuthorsPublishedCourses[msg.sender].push(course);

        emit CourseAdded(id);
    }

    // Function
    /**
     * Activate a course, this may be necessary if it was previously deactivated
     */
    function activateCourse(bytes32 courseId) external onlyAuthor checkCourseShouldExist(courseId) {
        CourseAuthorCoursesStatus storage authorCourseStatus = s_allCourseAuthorsCoursesStatus[
            courseId
        ];
        if (authorCourseStatus.availability == CourseAvailabilityEnum.Activated) {
            revert Marketplace__CourseIsAlreadyActivated();
        }
        authorCourseStatus.availability = CourseAvailabilityEnum.Activated;
        emit CourseActivated(courseId);
    }

    // Function
    /**
     * Deactivate a course, this may be needed if the author does not want to promote his course anymore
     * Course cannot be purchased anymore but must remain available for users who purchased it
     */
    function deactivateCourse(bytes32 courseId)
        external
        onlyAuthor
        checkCourseShouldExist(courseId)
    {
        CourseAuthorCoursesStatus storage authorCourseStatus = s_allCourseAuthorsCoursesStatus[
            courseId
        ];

        if (authorCourseStatus.availability == CourseAvailabilityEnum.Deactivated) {
            revert Marketplace__CourseIsAlreadyDeactivated();
        }
        authorCourseStatus.availability = CourseAvailabilityEnum.Deactivated;
        emit CourseDeactivated(courseId);
    }

    // Function
    /**
     * Retrieves the status of a course (activated or deactivated)
     */
    function getCourseStatus(bytes32 courseId)
        public
        view
        checkCourseShouldExist(courseId)
        returns (CourseAvailabilityEnum status)
    {
        CourseAuthorCoursesStatus memory authorCourseStatus = s_allCourseAuthorsCoursesStatus[
            courseId
        ];

        return authorCourseStatus.availability;
    }

    // Function
    /**
     * Split purchase as following : 
     1. The course author is funded with a negotiated reward % of the course price
     2. The rest left goes to the marketplace contract
     */
    function splitAmount(CourseAuthor memory courseAuthor, uint256 amount) private {
        /**
         * @param uint Amount to transfer (in Wei)
         */
        uint256 courseAuthorAmount = amount.mul(courseAuthor.rewardPercentage).div(100);
        uint256 contractOwnerAmount = amount - courseAuthorAmount;

        //Transfer funds to course author
        (bool successTransferCourseAuthor, ) = courseAuthor._address.call{
            value: courseAuthorAmount
        }("");
        if (!successTransferCourseAuthor) revert Marketplace__TransferFundsFailed();

        //Tranfer the rest to contract
        (bool successTransferContract, ) = address(this).call{value: contractOwnerAmount}("");
        if (!successTransferContract) revert Marketplace__TransferFundsFailed();
    }

    // Function
    /**
     * Purchase a course (must be activated first)
     funds are transfered to different parties(course author and contract owner)
     */
    function purchaseCourse(bytes32 courseId)
        external
        payable
        checkCourseShouldExist(courseId)
        canPurchaseCourse(courseId)
    {
        if (msg.value < 1) revert Marketplace__InsufficientFunds();

        if (!hasCourseAlreadyBeenBought(msg.sender, courseId)) {
            Course memory course = s_allCourses[courseId];
            course.purchaseStatus = PurchaseStatus.Purchased;
            //get latest update from course author (he/she may have changed his fund's recipient address)
            course.author = s_allCourseAuthors[course.author._address];
            s_customerOwnedCourses[msg.sender].push(course);

            emit CoursePurchased(courseId);
            splitAmount(course.author, msg.value);

            return;
        }

        revert Marketplace__CourseAlreadyBought();
    }

    // Function
    /**
     * For a given address and course id, check if a course has already been bought
     */
    function hasCourseAlreadyBeenBought(address _address, bytes32 courseHashId)
        public
        view
        returns (bool)
    {
        Course[] memory owned = s_customerOwnedCourses[_address];
        for (uint256 i = 0; i < owned.length; i++) {
            if (owned[i].id == courseHashId && owned[i].purchaseStatus == PurchaseStatus.Purchased)
                return true;
        }
        return false;
    }

    // Function
    /**
     * For a given address, returns all bought courses
     */
    function getUserBoughtCoursesIds(address _address) external view returns (bytes32[] memory) {
        uint32 resultCount = 0;

        Course[] memory owned = s_customerOwnedCourses[_address];
        if (owned.length == 0) return new bytes32[](resultCount);

        for (uint32 i = 0; i < owned.length; i++) {
            if (owned[i].purchaseStatus == PurchaseStatus.Purchased) resultCount++;
        }

        bytes32[] memory ids = new bytes32[](resultCount);
        uint256 j = 0;
        for (uint256 i = 0; i < owned.length; i++) {
            if (owned[i].purchaseStatus == PurchaseStatus.Purchased) {
                ids[j] = owned[i].id;
                j++;
            }
        }

        return ids;
    }

    function getCourseAuthorRewardPercentage(address _address)
        external
        view
        returns (uint8 rewardPercentage)
    {
        CourseAuthor memory existingAuthor = s_allCourseAuthors[_address];
        if (existingAuthor._address == address(0)) revert Marketplace__CourseAuthorDoesNotExist();

        return existingAuthor.rewardPercentage;
    }

    // Function
    /**
     * For a given course id, returns a course object
     */
    function getCourseFromId(bytes32 courseId)
        private
        view
        checkCourseShouldExist(courseId)
        returns (Course memory)
    {
        return s_allCourses[courseId];
    }

    // Function
    /**
     * For a given author address, returns a 2 dimensional array object
     * Returned object is
     * 1. a course ID
     * 2. its availability (activated/deactivated)
     */
    function getCourseAuthorPublishedCourses(address authorAddress)
        public
        view
        returns (bytes32[2][] memory courses)
    {
        if (s_allCourseAuthors[authorAddress]._address == address(0))
            revert Marketplace__CourseAuthorDoesNotExist();

        Course[] memory publishedCourses = s_allCourseAuthorsPublishedCourses[authorAddress];
        bytes32[2][] memory return_publishedCourses = new bytes32[2][](publishedCourses.length);

        for (uint256 i = 0; i < publishedCourses.length; i++) {
            bytes32 courseId = publishedCourses[i].id;
            CourseAvailabilityEnum courseAvailabilityStatus = getCourseStatus(courseId);

            uint256 status = (courseAvailabilityStatus == CourseAvailabilityEnum.Activated ? 0 : 1);
            return_publishedCourses[i] = [courseId, bytes32(status)];
        }
        return return_publishedCourses;
    }

    // Function
    /**
     * Returns all courses ids stored in contract
     */
    function getAllCourses() external view returns (bytes32[] memory courses) {
        return s_allCoursesIds;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}