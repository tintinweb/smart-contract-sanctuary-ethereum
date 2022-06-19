//  SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-0.8/access/Ownable.sol";
import "@openzeppelin/contracts-0.8/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-0.8/utils/Counters.sol";
import "./utils/AccessProtected.sol";

contract PharmaSiuu is Ownable, AccessProtected {

    using SafeMath for uint256;
    using Counters for Counters.Counter;

    /* ========= STATE VARIABLES ========= */

    Counters.Counter nbPharmacies;

    struct medicine {
        uint256 typeId;
        uint256 price;
        uint256 supply;
        bool availability;
    }

    struct pharmacy {
        uint256 id;
        Counters.Counter nbMedicines;
        string location;
    }    

    pharmacy[] public pharmacies;
    mapping(uint256 => mapping(uint256 => medicine)) public tracker; // Used to track medicines in pharmacies
                                                                     // Pharmacy ID => Medicine Type ID => Medicine struct

    /* ========= CONSTRUCTOR ========= */

    constructor() {}

    /* ========= ADMIN FUNCTIONS ========= */

    /**
    * @notice Add new Pharmacy
    *
    * @param _id - Pharmacy identifier
    * @param _location - Location of pharmacy
    */
    function addPharmacy(uint256 _id, string memory _location) public onlyAdmin checkPharmaExists(_id) {
            Counters.Counter memory temp;
            pharmacies.push(pharmacy(_id, temp, _location));
            nbPharmacies.increment();
            emit pharmacyAdded(_id, _location);
    }

    /**
    * @notice Delete Pharmacy from registery
    *
    * @param  _pharmaId - Pharmacy identifier
    */
    function deletePharmacy(uint256 _pharmaId) public onlyAdmin {
        for (uint256 i = _pharmaId; i < pharmacies.length - 1; i++) {
            pharmacies[i] = pharmacies[i + 1];
        }
        pharmacies.pop();

        emit pharmacyDeleted(_pharmaId);
    }

    /**
    * @notice Add new Medicine to Pharmacy
    *
    * @param _pharmaId - Pharmacy identifier
    * @param _typeId - Medicine identifier
    * @param _price - Medicine price
    * @param _supply - Medicine supply
    * @param _availability - Availability of medicine
    */
    function addMedicine(uint256 _pharmaId, 
        uint256 _typeId, 
        uint256 _price, 
        uint256 _supply, 
        bool _availability) 
        public onlyAdmin checkMedicineExists(_pharmaId, _typeId) {
            uint256 pharmaId;
            for(uint256 i; i < nbPharmacies.current(); i++)
                {
                    if(pharmacies[i].id == _pharmaId) {
                        pharmaId = i;
                    } else {
                        revert("Pharmacy ID none existant.");
                    }
                }
            tracker[_pharmaId][_typeId] = medicine(_typeId, _price, _supply, _availability);
            pharmacies[pharmaId].nbMedicines.increment();
            emit medicineAdded(_typeId, _price, _supply, _availability);
    }

    /**
    * @notice Make changes to Pharmacy Medicine parameters
    *
    * @param _pharmaId - Pharmacy identifier
    * @param _typeId - Medicine identifier
    * @param _price - Medicine price
    * @param _supply - Medicine
    * @param _availability - Availability of medicine
    */
    function setMedicineParameters(uint256 _pharmaId,
        uint256 _typeId, 
        uint256 _price, 
        uint256 _supply, 
        bool _availability) 
        public isPharmacist(_msgSender()){
            tracker[_pharmaId][_typeId] = medicine(_typeId, _price, _supply, _availability);
            emit medicineParametersSet(_pharmaId, _typeId, _price, _supply, _availability);
    }

    /* ========= VIEWS ========= */

    /**
    * @notice Get list of pharmacies 
    */
    function getPharmacies() public view returns(pharmacy[] memory) {
        return pharmacies;
    }

    /**
    * @notice Get list of Medicines in a Pharmacy
    *
    * @param _pharmaId - Pharmacy identifier 
    */
    function getPharmaMedicines(uint256 _pharmaId) public view returns(medicine[] memory) {
        uint256 pharmaId;
            for(uint256 i; i < nbPharmacies.current(); i++)
                {
                    if(pharmacies[i].id == _pharmaId) {
                        pharmaId = i;
                    }
                }
        medicine[] memory temp = new medicine[](pharmacies[pharmaId].nbMedicines.current());
            for (uint256 i; i < pharmacies[pharmaId].nbMedicines.current(); i++) {
                temp[i] = tracker[pharmaId][i];
            }
        return temp;
    }

    /* ========= MODIFIERS ========= */
    
    /**
    * @notice Check if Pharmacy is already registered
    */
    modifier checkPharmaExists(uint256 _pharmId) {
        for(uint256 i; i < nbPharmacies.current(); i++) {
            if(pharmacies[i].id == _pharmId) {
                revert("Pharmacy already registered");
            }
        }
        _;
    }

    /**
    * @notice Check if Medicine is already registered in Pharmacy 
    */
    modifier checkMedicineExists(uint256 _pharmId, uint256 _typeId) {
        for(uint256 i; i < nbPharmacies.current(); i++) {
            if(tracker[i][_typeId].typeId == _typeId) {
                revert("Medicine already registered");
            }
        }
        _;
    }

    /* ========= EVENTS ========= */

    event pharmacyAdded(uint256 indexed id, string location);
    event offerParametersSet(uint256 indexed propId, uint256 indexed offerId, uint256 budget, string description);
    event medicineAdded(uint256 indexed typeId, uint256 price, uint256 supply, bool availability);
    event medicineParametersSet(uint256 indexed pharmaId, uint256 typeId, uint256 price, uint256 supply, bool availabiliy);
    event pharmacyDeleted(uint256 indexed pharmaId);
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-0.8/utils/Context.sol";
import "@openzeppelin/contracts-0.8/access/Ownable.sol";

abstract contract AccessProtected is Context, Ownable{

    /* ========= STATE VARIABLES ========= */
    mapping(address => bool) public admins; // user address => admin?
    mapping(address => bool) public pharmacists; // user address => pharmacist?

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @notice Set admin status to address
    * 
    * @param _admin - Address of admin
    * @param  _status - Status for admin (true/false)
    */
    function setAdminStatus(address _admin, bool _status) public onlyOwner {
        admins[_admin] = _status;
        emit adminStatusSet(_admin, _status);
    }

    /**
    * @notice Set Pharmacist status for user
    *
    * @param _user - Address of user
    * @param _status - Status of pharmacist (true/false) 
    */
    function setPharmacist(address _user, bool _status) public onlyAdmin {
        pharmacists[_user] = _status;
        emit pharmacistStatusSet(_user, _status);
    }

    /* ========= VIEWS ========= */

    /**
    * @notice Check admin status of address
    *
    * @param _admin - Address to be checked
    * @return whether address has admin access
     */
    function isAdmin(address _admin) public view returns(bool) {
        return admins[_admin];
    }

    /* ========== MODIFIERS ========== */

    /**
    * @notice Check if caller is admin or contract owner
    */
    modifier onlyAdmin() {
        require(
            admins[_msgSender()] || _msgSender() == owner(),
            "Caller address does not have Admin access"
        );
        _;
    }

    /**
    * @notice Check if caller address is pharmacist
    */
    modifier isPharmacist(address _user) {
        require(!pharmacists[_user],
        "Caller address is blacklisted"
        );
        _;
    }

    /* ========= EVENTS ========= */
    event adminStatusSet(address admin, bool status);
    event pharmacistStatusSet(address user, bool status);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}