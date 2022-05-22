/* SPDX-License-Identifier: MIT OR Apache-2.0 */
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IEvolveStorage.sol";

contract EvolveStorage is  Context, Ownable, IEvolveStorage{
    using SafeMath for uint256;

    address public factoryAddrss;
    uint256 public startCompetitionId = 0;
    uint256 public startPresetId = 0;

    mapping(uint256 => Preset) public presetList;
    mapping(uint256 => Competion ) public competionList;


    constructor(){
        factoryAddrss = _msgSender();
    }
   /* -------------------------------------------------------------------------- */
   /*                                 permissions                                */
    modifier ownerOrFactory {
        require(_msgSender() == factoryAddrss || _msgSender() == owner() || owner() == tx.origin , "To call this method you have to be owner or subAdmin!");
         _;
    }

    function updateFactoryAddress(address _factory) external override onlyOwner returns(bool result){
        factoryAddrss = _factory;
        result = true;
    }
   /* -------------------------------------------------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                        work with Competition methods                       */



    //    enum CompetionWinner {TEAMA , TEAMB , DRAW, OPEN}
    function updateCompetionWinner(uint _competionId, uint8 _winnerTeam) external override ownerOrFactory returns(bool){
        require(isExistsCompetionList(_competionId), "can't find competion with this competionId!");
        require(_winnerTeam >= 0 && _winnerTeam <= 3, "winner need to be somting between 0 to 3");
        Competion storage competion = competionList[_competionId];
        if(_winnerTeam == 0){
            competion.winners = CompetionWinner.TEAMA;
        }else if(_winnerTeam == 1){
            competion.winners = CompetionWinner.TEAMB;
        }else if(_winnerTeam == 2){
            competion.winners = CompetionWinner.DRAW;
        }else if(_winnerTeam == 3){
            competion.winners = CompetionWinner.OPEN;
        }
        
        return true;
    }



    //  enum CompetionStatus { PENDING, CANCELED, DONE }
    function updateCompetionStatus(uint _competionId, uint8 _status) external override ownerOrFactory returns(bool){
        require(isExistsCompetionList(_competionId), "can't find competion with this competionId!");
        require(_status >= 0 && _status <= 2, "status need to be somting between 0 to 2");
        Competion storage competion = competionList[_competionId];
        if(_status == 0){
            competion.status = CompetionStatus.PENDING;
        }else if(_status == 1){
            competion.status = CompetionStatus.CANCELED;
        }else if(_status == 2){
            competion.status = CompetionStatus.DONE;
        }
        return true;
    }

    function addNewCompetion(uint256 _presetId, address[] calldata _teamA, address[] calldata _teamB, uint256 _priceRate, uint256 _createAt) external override ownerOrFactory returns(uint256 competitionId){
        require(isExistsPresetList(_presetId), "can't find preset with this id!");
        competitionId = startCompetitionId;
        competionList[competitionId] = Competion(presetList[_presetId],_teamA, _teamB, CompetionStatus.PENDING, CompetionWinner.OPEN, _priceRate, _createAt);
        startCompetitionId += 1;
        return competitionId;
    }


    /* -------------------------------------------------------------------------- */





   /* -------------------------------------------------------------------------- */
   /*                           work with presetMethods                          */
    function addNewPreset(uint256 _matchPrice, uint256 _numberOfTeamMemebr, uint256 _createAt ) external override ownerOrFactory returns(uint presetId) {
        uint _lastPresetId = startPresetId;
        Preset memory currentPreset = Preset(_matchPrice, _numberOfTeamMemebr, block.timestamp, _createAt);
        presetList[_lastPresetId] = currentPreset;
        startPresetId += 1;
        return _lastPresetId;
    }
   /* -------------------------------------------------------------------------- */

    // read methods 

    function getPreset(uint256 _presetId) external view override returns(uint256 matchPrice,uint256 numberOfTeamMemebr){
     return (presetList[_presetId].matchPrice, presetList[_presetId].numberOfTeamMemebr);
    }

    function getCompetion(uint256 _competionId) external view override 
        returns(uint256 presetPrice,uint256 playerCount,address[] memory _teamA, address[] memory _teamB, uint _competionStatus, uint _competionWinner, uint256 _priceRate){
        Preset memory competionPreset = competionList[_competionId].preset;
        presetPrice = competionPreset.matchPrice;
        playerCount = competionPreset.numberOfTeamMemebr;
        _teamA = competionList[_competionId].teamA;
        _teamB = competionList[_competionId].teamB;
        _competionStatus = uint(competionList[_competionId].status);
        _competionWinner = uint(competionList[_competionId].winners);
        _priceRate = competionList[_competionId].priceRate;
    }

    // utilse methods

    function isExistsCompetionList(uint key) internal view returns (bool) {
        if(competionList[key].teamA.length != 0){
            return true;
        } 
        return false;
    }
     function isExistsPresetList(uint256 key) internal view returns (bool) {
        if(presetList[key].date != 0){
            return true;
        } 
        return false;
    }

}

/* SPDX-License-Identifier: MIT OR Apache-2.0 */
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;
interface IEvolveStorage{
     struct Preset {
        uint256 matchPrice;
        uint256 numberOfTeamMemebr;
        uint256 date;
        uint256 createAt;
    }
    struct Competion {
        Preset preset;
        address[] teamA;
        address[] teamB;
        CompetionStatus status;
        CompetionWinner winners;
        uint256 priceRate;
        uint256 createAt;
    }
    enum CompetionStatus { PENDING, CANCELED, DONE }
    enum CompetionWinner {TEAMA , TEAMB , DRAW, OPEN}
    
    function addNewPreset(uint256 _matchPrice, uint256 _numberOfTeamMemebr , uint256 _createAt) external returns(uint);
    function updateCompetionWinner(uint _competionId, uint8 _winnerTeam) external returns(bool);
    function updateCompetionStatus(uint _competionId, uint8 _status) external returns(bool);
    function updateFactoryAddress(address _factory) external returns(bool);
    function addNewCompetion(uint256 _presetId, address[] calldata _teamA, address[] calldata _teamB, uint256 _priceRate, uint256 _createAt) external returns(uint256 competitionId);
    
    function getPreset(uint256 _presetId) external view returns(uint256,uint256);
    function getCompetion(uint256 _competionId) external view returns(uint256 presetPrice,uint256 playerCount,address[] memory _teamA, address[] memory _teamB, uint _competionStatus, uint _competionWinner, uint256 _priceRate);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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