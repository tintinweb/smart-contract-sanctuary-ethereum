// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./variables.sol";

contract Acchedya is Ownable, variables {
    // // // // // //
    // STUDENT SECTION
    // // // // // //

    function getstudIndex(address _studAddr)
        public
        view
        returns (studentIndex[] memory)
    {
        return (studIndex[_studAddr]);
    }

    function AddStudent(
        address _studentAddress,
        string memory _collegename,
        string memory _studentId,
        string memory _name,
        string memory _year,
        string memory _course,
        string memory _rollNo,
        string memory _doj,
        string[] memory _certs,
        string[] memory _certNames,
        string memory _certType
    ) public {
        colReq[msg.sender] = colReq[msg.sender] + 1;
        Roles[
            0xc951d7098b66ba0b8b77265b6e9cf0e187d73125a42bcd0061b09a68be421810
        ][_studentAddress] = true;
        studIndex[_studentAddress].push(
            studentIndex(msg.sender, colReq[msg.sender])
        );
        studentDetails[msg.sender][colReq[msg.sender]].push(
            student(
                _collegename,
                _studentId,
                _name,
                _year,
                _course,
                _rollNo,
                _doj,
                _certs,
                _certNames,
                _certType,
                block.timestamp,
                "COLLEGE",
                msg.sender,
                3
            )
        );
    }

    function studentVerified(
        address _clg,
        address _studentAddress,
        uint32 _verified
    ) public {
        Roles[
            0xc951d7098b66ba0b8b77265b6e9cf0e187d73125a42bcd0061b09a68be421810
        ][_studentAddress] = true;
        studentDetails[msg.sender][colReq[_clg]][0].verified = _verified;
    }

    function AddStudentself(
        address _collegeAddr,
        string memory _collegename,
        string memory _studentId,
        string memory _name,
        string memory _year,
        string memory _course,
        string memory _rollNo,
        string memory _doj,
        string[] memory _certs,
        string[] memory _certNames,
        string memory _certType
    ) public {
        colReq[_collegeAddr] = colReq[_collegeAddr] + 1;
        waiting[msg.sender] = "STUDENT_WAITING";
        studIndex[msg.sender].push(
            studentIndex(_collegeAddr, colReq[_collegeAddr])
        );
        studentDetails[_collegeAddr][colReq[_collegeAddr]].push(
            student(
                _collegename,
                _studentId,
                _name,
                _year,
                _course,
                _rollNo,
                _doj,
                _certs,
                _certNames,
                _certType,
                block.timestamp,
                "STUDENT",
                _collegeAddr,
                1
            )
        );
    }

    function getStudentSelf(address _collegeAddr, uint256 _colReq)
        public
        view
        returns (student[] memory)
    {
        return (studentDetails[_collegeAddr][_colReq]);
    }

    function reurnedVale() public view returns (uint256) {
        return (colReq[msg.sender]);
    }

    // // // // // //
    // COLLEGE SECTION
    // // // // // //

    function AddCollege(
        address _collegeAddr,
        string memory _collegeName,
        string memory _address,
        string memory _phone,
        string memory _email,
        uint32 _status
    ) public {
        address collegeWalletAddres = _collegeAddr;
        address theOwner = owner();
        waiting[msg.sender] = "COLLEGE_WAITING";
        collegeDetails[theOwner].push(
            college(
                collegeWalletAddres,
                _collegeName,
                _address,
                _phone,
                _email,
                _status,
                msg.sender
            )
        );
    }

    function getCollege() public view returns (college[] memory) {
        uint i;
        address theOwner = owner();
        uint256 len = collegeDetails[theOwner].length;
        college[] memory collegeDet = new college[](len);

        for (i = 0; i < len; i++) {
            if (msg.sender != owner()) {
                if (msg.sender == collegeDetails[theOwner][i].access) {
                    collegeDet[i] = collegeDetails[theOwner][i];
                }
            } else {
                require(msg.sender == owner(), "You are not the owner.");
                collegeDet[i] = collegeDetails[theOwner][i];
            }
        }

        return (collegeDet);
    }

    function verifyCollege(
        uint32 _index,
        uint32 code,
        address clgAddr
    ) public onlyOwner {
        collegeDetails[msg.sender][_index].collegeStatus = code;
        //grant role
        GrantRole(
            0x112ca87938ff9caa27257dbd0ca0f4fabbcf5fd4948bc02864cc3fbce825277f,
            clgAddr
        );
        GrantRole(
            0x02045258af11576776f56337f0666fcac2b654a57c15c8a528e83f2b72f40eef,
            clgAddr
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract variables is Ownable {
    using SafeMath for uint;
    using SafeMath for uint32;
    using SafeMath for uint256;

    ////////////////////////////////
    // company variables
    ////////////////////////////////

    struct employee {
        string joiningDate;
        string leftDate;
        string designation;
        uint256 timestamp;
        string[] certs;
        string[] certName;
        string certType;
        string AddedBy;
        address companyAdd;
        uint32 verified;
    }

    struct company {
        address companyWalAddress;
        string companyName;
        string companyAddres;
        string companyPhone;
        string companyEmail;
        string companySector;
        uint256 companyStatus;
        address access;
    }

    struct jobRequests {
        address companyAddress;
        address employeeAddress;
        string companyName;
        string employeeName;
        string reasonForInvitation;
        uint32 status;
    }

    // /// // // // // // // // / /

    struct student {
        string collegeName;
        string ID;
        string name;
        string year;
        string course;
        string rollNo;
        string DOJ;
        string[] certs;
        string[] certName;
        string certType;
        uint256 timestamp;
        string AddedBy;
        address collegeAdd;
        uint32 verified;
    }

    struct college {
        address collegeWalAddress;
        string collegeName;
        string collegeAddres;
        string collegePhone;
        string collegeEmail;
        uint32 collegeStatus;
        address access;
    }

    struct studentIndex {
        address clgAddr;
        uint256 index;
    }

    mapping(address => mapping(uint256 => student[])) studentDetails;
    mapping(address => college[]) collegeDetails;
    mapping(address => bool) public CollegeAddress;
    mapping(address => bool) public CompanyAddress;
    mapping(address => uint256) colReq;
    mapping(address => studentIndex[]) studIndex;
    mapping(address => uint256) userID;

    // // // // // // // // //
    // company mappings
    // // // // // // // // //

    mapping(bytes32 => mapping(address => bool)) public Roles;
    mapping(address => mapping(uint256 => employee[])) employeeCert;
    mapping(address => company[]) companyDetails;
    mapping(address => jobRequests[]) jobInvites;
    mapping(address => string) waiting;
    mapping(address => address[]) companyReqs;

    bytes32 public constant COLLEGE = keccak256(abi.encodePacked("COLLEGE"));
    bytes32 public constant COMPANY = keccak256(abi.encodePacked("COMPANY"));
    bytes32 public constant STUDENT = keccak256(abi.encodePacked("STUDENT"));
    bytes32 public constant RETRIEVER =
        keccak256(abi.encodePacked("RETRIEVER"));

    modifier onlyRole(bytes32 _role) {
        require(Roles[_role][msg.sender], " Not Authorized");
        _;
    }

    function GrantRole(bytes32 _role, address _account) public onlyOwner {
        Roles[_role][_account] = true;
    }

    function checkAddress(address _account)
        public
        view
        returns (string memory)
    {
        if (
            Roles[
                0xc951d7098b66ba0b8b77265b6e9cf0e187d73125a42bcd0061b09a68be421810
            ][_account]
        ) {
            return ("STUDENT");
        } else if (
            Roles[
                0x6b930a54bc9a8d9d32021a28e2282ffedf33210754271fcab1eb90abc2021a1c
            ][_account]
        ) {
            return ("COMPANY");
        } else if (
            Roles[
                0x112ca87938ff9caa27257dbd0ca0f4fabbcf5fd4948bc02864cc3fbce825277f
            ][_account]
        ) {
            return ("COLLEGE");
        } else {
            return ("NONE");
        }
    }

    function walletReg() public view returns (string memory) {
        return (waiting[msg.sender]);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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