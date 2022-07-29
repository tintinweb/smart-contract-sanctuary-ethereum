// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

// SafeMath
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

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

    //That course is gonna be stored on the storage
    struct Course {
        bytes32 id;
        bytes32 title;
        uint256 price;
        CourseAuthor author;
        PurchaseStatus purchaseStatus;
    }

    mapping(bytes32 => CourseAuthorCoursesStatus) private allCourseAuthorsCoursesStatus;

    // mapping of courseHash to Course data
    mapping(address => Course[]) private customerOwnedCourses;

    //list of all courses stored in this contract
    mapping(bytes32 => Course) private allCourses;

    // list of all course authors who have course stored in this contract
    mapping(address => CourseAuthor) private allCourseAuthors;

    //list of all courses that a course author has published
    mapping(address => Course[]) private allCourseAuthorsPublishedCourses;

    constructor() {
        setContractOwner(msg.sender);
    }

    error Marketplace__OnlyContractOwner();
    error Marketplace__OnlyCourseAuthor();
    error Marketplace__CourseOwnerAddressIsSame();
    error Marketplace__CourseOwnerRewardPercentageOutOfBound();
    error Marketplace__CourseOwnerAlreadyExist();
    error Marketplace__CourseAlreadyBought();
    error Marketplace__CourseAuthorDoesNotExist();
    error Marketplace__CourseDoesNotExist();
    error Marketplace__CourseDoesAlreadyExist();
    error Marketplace__CourseMustBeActivated();
    error Marketplace__CourseIsAlreadyDeactivated();
    error Marketplace__CourseIsAlreadyActivated();

    //common error with funds transfer/withdrawal
    error Marketplace__InsufficientFunds();
    error Marketplace__WithdrawalFundsFailed();
    error Marketplace__TransferFundsFailed();

    // Modifier
    /**
     * Prevents a course to be puchased if not activated yet
     */
    modifier canPurchaseCourse(bytes32 courseId) {
        //check the status of the course set by the course author
        CourseAuthorCoursesStatus memory courseStatus = allCourseAuthorsCoursesStatus[courseId];
        if (courseStatus.availability == CourseAvailabilityEnum.Deactivated)
            revert Marketplace__CourseMustBeActivated();

        //finally check for the purchase status
        Course memory course = getCourseFromId(courseId);
        if (course.purchaseStatus == PurchaseStatus.Purchased) {
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
    function withdrawMarketplaceFunds(uint256 amount) public onlyContractOwner {
        /**
         * @param uint Amount to withdraw (in Wei)
         */
        uint256 contractBalance = address(this).balance;

        if (contractBalance <= amount) revert Marketplace__InsufficientFunds();

        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        if (!sent) revert Marketplace__WithdrawalFundsFailed();
    }

    // Function
    /**
     * Change course's author recipient address
     */
    function changeCourseAuthorAddress(address courseAuthorAddress, address newAddress)
        external
        onlyContractOwner
    {
        CourseAuthor storage existingOwner = allCourseAuthors[courseAuthorAddress];
        if (existingOwner._address == address(0)) revert Marketplace__CourseAuthorDoesNotExist();
        if (newAddress == existingOwner._address) revert Marketplace__CourseOwnerAddressIsSame();

        existingOwner._address = newAddress;
    }

    // Function
    /**
     * Add a new course author with his negotiated reward percentage
     */
    function addCourseAuthor(address courseAuthorAddress, uint8 rewardPercentage)
        external
        onlyContractOwner
    {
        if (rewardPercentage > 100) revert Marketplace__CourseOwnerRewardPercentageOutOfBound();

        CourseAuthor memory existingOwner = allCourseAuthors[courseAuthorAddress];
        if (existingOwner._address != address(0)) revert Marketplace__CourseOwnerAlreadyExist();

        CourseAuthor memory courseOwner = CourseAuthor({
            _address: courseAuthorAddress,
            rewardPercentage: rewardPercentage
        });
        allCourseAuthors[courseAuthorAddress] = courseOwner;
    }

    // Function
    /**
     * Add a new course to the contract
     */
    function addCourse(
        bytes32 id,
        bytes32 title,
        uint32 price
    ) external {
        CourseAuthor memory existingOwner = allCourseAuthors[msg.sender];

        if (msg.sender != existingOwner._address) {
            revert Marketplace__OnlyCourseAuthor();
        }

        if (existingOwner._address == address(0)) revert Marketplace__CourseAuthorDoesNotExist();

        //check if course already exist
        Course memory existingCourse = allCourses[id];
        if (existingCourse.id > 0) revert Marketplace__CourseDoesAlreadyExist();

        Course memory course = Course({
            id: id,
            title: title,
            price: price,
            author: existingOwner,
            purchaseStatus: PurchaseStatus.NotPurchased
        });

        allCourses[id] = course;

        //activate the course by default
        CourseAuthorCoursesStatus memory AuthorCourseStatus = CourseAuthorCoursesStatus({
            id: id,
            availability: CourseAvailabilityEnum.Activated
        });
        allCourseAuthorsCoursesStatus[id] = AuthorCourseStatus;

        //finally, add the course to the list of published courses for the current author
        allCourseAuthorsPublishedCourses[msg.sender].push(course);
    }

    // Function
    /**
     * Activate a course, this may be necessary if it was previously deactivated
     */
    function activateCourse(bytes32 courseId) external onlyContractOwner {
        CourseAuthorCoursesStatus storage authorCourseStatus = allCourseAuthorsCoursesStatus[
            courseId
        ];
        if (authorCourseStatus.availability == CourseAvailabilityEnum.Activated) {
            revert Marketplace__CourseIsAlreadyActivated();
        }
        authorCourseStatus.availability = CourseAvailabilityEnum.Activated;
    }

    // Function
    /**
     * Deactivate a course, this may be needed if the author does not want to promote his course anymore
     * Course cannot be purchased anymore but must remain available for users who purchased it
     */
    function deactivateCourse(bytes32 courseId) external {
        Course memory existingCourse = getCourseFromId(courseId);
        CourseAuthor memory existingOwner = allCourseAuthors[existingCourse.author._address];
        if (existingOwner._address == address(0)) revert Marketplace__CourseAuthorDoesNotExist();

        if (msg.sender != existingOwner._address) {
            revert Marketplace__OnlyCourseAuthor();
        }

        CourseAuthorCoursesStatus storage authorCourseStatus = allCourseAuthorsCoursesStatus[
            courseId
        ];

        if (authorCourseStatus.availability == CourseAvailabilityEnum.Deactivated) {
            revert Marketplace__CourseIsAlreadyDeactivated();
        }
        authorCourseStatus.availability = CourseAvailabilityEnum.Deactivated;
    }

    // Function
    /**
     * Retrieves the status of a course (activated or deactivated)
     */
    function getCourseStatus(bytes32 courseId) public view returns (CourseAvailabilityEnum status) {
        Course memory course = getCourseFromId(courseId);

        CourseAuthorCoursesStatus memory authorCourseStatus = allCourseAuthorsCoursesStatus[
            course.id
        ];

        return authorCourseStatus.availability;
    }

    // Function
    /**
     * Split purchase as following : 
     1. The course author is funded with a negotiated reward % of the course price
     2. The rest left goes to the marketplace contract
     */
    function splitAmount(CourseAuthor memory courseOwner, uint256 amount) private {
        /**
         * @param uint Amount to transfer (in Wei)
         */
        uint256 courseAuthorAmount = amount.mul(courseOwner.rewardPercentage).div(100);
        uint256 contractOwnerAmount = amount - courseAuthorAmount;

        //Transfer funds to course author
        (bool successTransferCourseAuthor, ) = courseOwner._address.call{value: courseAuthorAmount}(
            ""
        );
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
    function purchaseCourse(bytes32 courseId) external payable canPurchaseCourse(courseId) {
        if (msg.value < 1) revert Marketplace__InsufficientFunds();

        if (!hasCourseAlreadyBeenBought(msg.sender, courseId)) {
            Course memory course = getCourseFromId(courseId);
            course.price = msg.value;
            course.purchaseStatus = PurchaseStatus.Purchased;
            //get latest update from course author (he/she may have changed his fund's recipient address)
            CourseAuthor memory courseOwner = allCourseAuthors[course.author._address];
            course.author = courseOwner;
            customerOwnedCourses[msg.sender].push(course);

            splitAmount(course.author, course.price);
            return;
        }

        revert Marketplace__CourseAlreadyBought();
    }

    function getCoursePrice(bytes32 courseId) external view returns (uint256 price) {
        return getCourseFromId(courseId).price;
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
        Course[] memory owned = customerOwnedCourses[_address];
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
        uint32 resultCount;

        Course[] memory owned = customerOwnedCourses[_address];
        for (uint32 i = 0; i < owned.length; i++) {
            if (owned[i].purchaseStatus == PurchaseStatus.Purchased) resultCount++;
        }

        bytes32[] memory ids = new bytes32[](resultCount);
        uint256 j;
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
        CourseAuthor memory existingAuthor = allCourseAuthors[_address];
        if (existingAuthor._address == address(0)) revert Marketplace__CourseAuthorDoesNotExist();

        return existingAuthor.rewardPercentage;
    }

    // Function
    /**
     * For a given course id, returns a course object
     */
    function getCourseFromId(bytes32 courseId) private view returns (Course memory) {
        Course memory course = allCourses[courseId];
        if (course.id > 0) {
            return course;
        }
        revert Marketplace__CourseDoesNotExist();
    }

    function getCourseAuthorPublishedCourses(address authorAddress)
        public
        view
        returns (bytes32[] memory courses)
    {
        CourseAuthor memory existingAuthor = allCourseAuthors[authorAddress];
        if (existingAuthor._address == address(0)) revert Marketplace__CourseAuthorDoesNotExist();

        Course[] memory publishedCourses = allCourseAuthorsPublishedCourses[authorAddress];
        bytes32[] memory ids = new bytes32[](publishedCourses.length);
        uint256 j;
        for (uint256 i = 0; i < publishedCourses.length; i++) {
            ids[j] = publishedCourses[i].id;
            j++;
        }
        return ids;
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