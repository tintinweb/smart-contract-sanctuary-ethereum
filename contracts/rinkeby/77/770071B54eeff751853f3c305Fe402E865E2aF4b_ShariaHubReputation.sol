/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// File: reputation/ShariaHubReputationInterface.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ShariaHubReputationInterface {
//    modifier onlyUsersContract(){_;}
//    modifier onlyLendingContract(){_;}
    function burnReputation(uint delayDays)  external;
    function incrementReputation(uint completedProjectsByTier)  external;
    function initLocalNodeReputation(address localNode)  external;
    function initCommunityReputation(address community)  external;
    function getCommunityReputation(address target) external view returns(uint256);
    function getLocalNodeReputation(address target) external view returns(uint256);
}

// File: storage/ShariaHubStorageInterface.sol


pragma solidity ^0.8.9;


/**
 * Interface for the eternal storage.
 * Thanks RocketPool!
 * https://github.com/rocket-pool/rocketpool/blob/master/contracts/interface/RocketStorageInterface.sol
 */
interface ShariaHubStorageInterface {

    //modifier for access in sets and deletes
//    modifier onlyShariaHubContracts() {_;}

    // Setters
    function setAddress(bytes32 _key, address _value) external;
    function setUint(bytes32 _key, uint _value) external;
    function setString(bytes32 _key, string memory _value) external;
    function setBytes(bytes32 _key, bytes memory _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setInt(bytes32 _key, int _value) external;
    // Deleters
    function deleteAddress(bytes32 _key) external;
    function deleteUint(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;

    // Getters
    function getAddress(bytes32 _key) external view returns (address);
    function getUint(bytes32 _key) external view returns (uint);
    function getString(bytes32 _key) external view returns (string memory );
    function getBytes(bytes32 _key) external view returns (bytes memory );
    function getBool(bytes32 _key) external view returns (bool);
    function getInt(bytes32 _key) external view returns (int);
}

// File: ShariaHubBase.sol


pragma solidity ^0.8.9;



contract ShariaHubBase {

    uint8 public version;

    ShariaHubStorageInterface public ShariaHubStorage;

    constructor(address _storageAddress) {
        require(_storageAddress != address(0));
        ShariaHubStorage = ShariaHubStorageInterface(_storageAddress);
    }

}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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

// File: reputation/ShariaHubReputation.sol


pragma solidity ^0.8.9;




contract ShariaHubReputation is ShariaHubBase, ShariaHubReputationInterface {

    //10 with 2 decilmals
    uint constant maxReputation = 1000;
    uint constant reputationStep = 100;
    //Tier 1 x 20 people
    uint constant minProyect = 20;
    uint constant public initReputation = 500;

    //0.05
    uint constant incrLocalNodeMultiplier = 5;

    using SafeMath for uint;

    event ReputationUpdated(address indexed affected, uint newValue);

    /*** Modifiers ************/

    /// @dev Only allow access from the latest version of a contract in the Rocket Pool network after deployment
    modifier onlyUsersContract() {
        require(ShariaHubStorage.getAddress(keccak256(abi.encodePacked("contract.name", "users"))) == msg.sender);
        _;
    }

    modifier onlyLendingContract() {
        require(ShariaHubStorage.getAddress(keccak256(abi.encodePacked("contract.address", msg.sender))) == msg.sender);
        _;
    }

    /// @dev constructor
    constructor(address _storageAddress) ShariaHubBase(_storageAddress)  {
      // Version
      version = 1;
    }

    function burnReputation(uint delayDays) external onlyLendingContract {
        address lendingContract = msg.sender;
        //Get temporal parameters
        uint maxDelayDays = ShariaHubStorage.getUint(keccak256(abi.encodePacked("lending.maxDelayDays", lendingContract)));
        require(maxDelayDays != 0);
        require(delayDays != 0);

        //Affected players
        address community = ShariaHubStorage.getAddress(keccak256(abi.encodePacked("lending.community", lendingContract)));
        require(community != address(0));
        //Affected local node
        address localNode = ShariaHubStorage.getAddress(keccak256(abi.encodePacked("lending.localNode", lendingContract)));
        require(localNode != address(0));

        //***** Community
        uint previousCommunityReputation = ShariaHubStorage.getUint(keccak256(abi.encodePacked("community.reputation", community)));
        //Calculation and update
        uint newCommunityReputation = burnCommunityReputation(delayDays, maxDelayDays, previousCommunityReputation);
        ShariaHubStorage.setUint(keccak256(abi.encodePacked("community.reputation", community)), newCommunityReputation);
        emit ReputationUpdated(community, newCommunityReputation);

        //***** Local node
        uint previousLocalNodeReputation = ShariaHubStorage.getUint(keccak256(abi.encodePacked("localNode.reputation", localNode)));
        uint newLocalNodeReputation = burnLocalNodeReputation(delayDays, maxDelayDays, previousLocalNodeReputation);
        ShariaHubStorage.setUint(keccak256(abi.encodePacked("localNode.reputation", localNode)), newLocalNodeReputation);
        emit ReputationUpdated(localNode, newLocalNodeReputation);

    }

    function incrementReputation(uint completedProjectsByTier) external onlyLendingContract {
        address lendingContract = msg.sender;
        //Affected players
        address community = ShariaHubStorage.getAddress(keccak256(abi.encodePacked("lending.community", lendingContract)));
        require(community != address(0));
        //Affected local node
        address localNode = ShariaHubStorage.getAddress(keccak256(abi.encodePacked("lending.localNode", lendingContract)));
        require(localNode != address(0));

        //Tier
        uint projectTier = ShariaHubStorage.getUint(keccak256(abi.encodePacked("lending.tier", lendingContract)));
        require(projectTier > 0);
        require(completedProjectsByTier > 0);

        //***** Community
        uint previousCommunityReputation = ShariaHubStorage.getUint(keccak256(abi.encodePacked("community.reputation", community)));
        //Calculation and update
        uint newCommunityReputation = incrementCommunityReputation(previousCommunityReputation, completedProjectsByTier);
        ShariaHubStorage.setUint(keccak256(abi.encodePacked("community.reputation", community)), newCommunityReputation);
        emit ReputationUpdated(community, newCommunityReputation);

        //***** Local node
        uint borrowers = ShariaHubStorage.getUint(keccak256(abi.encodePacked("lending.communityMembers", lendingContract)));
        uint previousLocalNodeReputation = ShariaHubStorage.getUint(keccak256(abi.encodePacked("localNode.reputation", localNode)));
        uint newLocalNodeReputation = incrementLocalNodeReputation(previousLocalNodeReputation, projectTier, borrowers);
        ShariaHubStorage.setUint(keccak256(abi.encodePacked("localNode.reputation", localNode)), newLocalNodeReputation);
        emit ReputationUpdated(localNode, newLocalNodeReputation);
    }

    function incrementCommunityReputation(uint previousReputation, uint completedProjectsByTier) public pure returns(uint) {
        require(completedProjectsByTier > 0);
        uint nextRep = previousReputation.add(reputationStep.div(completedProjectsByTier));
        if (nextRep >= maxReputation) {
            return maxReputation;
        } else {
            return nextRep;
        }
    }

    function incrementLocalNodeReputation(uint previousReputation, uint tier, uint borrowers) public pure returns(uint) {
        require(tier >= 1);
        //this should 20 but since it's hardcoded in ShariaHubLending, let's be safe.
        //TODO store min borrowers in ShariaHubStorage
        require(borrowers > 0); 
        uint increment = (tier.mul(borrowers).div(minProyect)).mul(incrLocalNodeMultiplier);
        uint nextRep = previousReputation.add(increment);
        if (nextRep >= maxReputation) {
            return maxReputation;
        } else {
            return nextRep;
        }
    }

    function burnLocalNodeReputation(uint delayDays, uint maxDelayDays, uint prevReputation) public pure returns(uint) {
        if (delayDays >= maxDelayDays){
            return 0;
        }
        uint decrement = prevReputation.mul(delayDays).div(maxDelayDays);
        if (delayDays < maxDelayDays && decrement < reputationStep) {
            return prevReputation.sub(decrement);
        } else {
            return prevReputation.sub(reputationStep);
        }
    }

    function burnCommunityReputation(uint delayDays, uint maxDelayDays, uint prevReputation) public pure returns(uint) {
        if (delayDays < maxDelayDays) {
            return prevReputation.sub(prevReputation.mul(delayDays).div(maxDelayDays));
        } else {
            return 0;
        }
    }

    function initLocalNodeReputation(address localNode) onlyUsersContract external {
        require(ShariaHubStorage.getUint(keccak256(abi.encodePacked("localNode.reputation", localNode))) == 0);
        ShariaHubStorage.setUint(keccak256(abi.encodePacked("localNode.reputation", localNode)), initReputation);
    }

    function initCommunityReputation(address community) onlyUsersContract external {
        require(ShariaHubStorage.getUint(keccak256(abi.encodePacked("comunity.reputation", community))) == 0);
        ShariaHubStorage.setUint(keccak256(abi.encodePacked("community.reputation", community)), initReputation);
    }

    function getCommunityReputation(address target) public view returns(uint256) {
        return ShariaHubStorage.getUint(keccak256(abi.encodePacked("community.reputation", target)));
    }

    function getLocalNodeReputation(address target) public view returns(uint256) {
        return ShariaHubStorage.getUint(keccak256(abi.encodePacked("localNode.reputation", target)));
    }

}