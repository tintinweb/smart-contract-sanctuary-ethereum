/**
 *Submitted for verification at Etherscan.io on 2022-11-28
*/

/** 
 *  SourceUnit: d:\GitWork\06-AJWorking\Poll-Vote\nft-contracts\contracts\SpaceFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: d:\GitWork\06-AJWorking\Poll-Vote\nft-contracts\contracts\SpaceFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

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




/** 
 *  SourceUnit: d:\GitWork\06-AJWorking\Poll-Vote\nft-contracts\contracts\SpaceFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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


/** 
 *  SourceUnit: d:\GitWork\06-AJWorking\Poll-Vote\nft-contracts\contracts\SpaceFactory.sol
*/

// NFT Auction Contract 
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/utils/math/SafeMath.sol";
////import "@openzeppelin/contracts/access/Ownable.sol";

interface INFTCollection {
	function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract SpaceFactory is Ownable {
    using SafeMath for uint256;    

    address public feeAddress;
    uint256 public createFee;
    
    // Auction struct which holds all the required info
    struct Space {
        uint256 spaceId;
        string logo;
        string name;
        string about;
        string category;
        address nftAddr;
        uint256 nftType;  // 0:ERC721, 1: ERC1155
        address creator;
        uint256 createLimit; // holder who has over createLimit can create proposal
        string socialMetadata;        
    }

    // spaceId => Space mapping
    mapping(uint256 => Space) public spaces;
	uint256 public currentSpaceId;   
    
    // SpaceCreated is fired when an space is created
    event SpaceCreated(
        uint256 spaceId,
        string logo,
        string name,
        string about,
        string category,
        address nftAddr,
        uint256 nftType,
        address creator,
        uint256 createLimit,
        string socialMetadata
    );
    
    event SpaceUpdated(
        uint256 spaceId,
        string logo,
        string name,
        string about,
        string category,
        address nftAddr,
        uint256 nftType,
        address creator,
        uint256 createLimit,
        string socialMetadata
    );
    
    constructor (address _feeAddress) {
		require(_feeAddress != address(0), "Invalid commonOwner");
        feeAddress = _feeAddress;
        createFee = 0.001 ether;        
        currentSpaceId = 0;
	}

    
    function setFeeAddress(address _feeAddress) external onlyOwner {
        require(_feeAddress != address(0x0), "invalid address");		
        feeAddress = _feeAddress;		
    }
    function setFeeValue(uint256 _createFee) external onlyOwner {	
        createFee = _createFee;
    }

    function createSpace(
        string memory _logo, 
        string memory _name,
        string memory _about, 
        string memory _category, 
        address _nftAddr, 
        uint256 _createLimit,
        string memory _socialMetadata
        ) external payable 
    {   
        require(IsERC721(_nftAddr) || IsERC1155(_nftAddr), "Invalid Collection Address");

        uint256 nftType = 0;
        if (IsERC1155(_nftAddr)) {
            nftType = 1;
        }

        if (createFee > 0) {
            require(msg.value >= createFee, "too small amount");
            (bool result, ) = payable(feeAddress).call{value: createFee}("");
            require(result, "Failed to send fee to feeAddress");
        }
        
        
		currentSpaceId = currentSpaceId.add(1);
		spaces[currentSpaceId].spaceId = currentSpaceId;
		spaces[currentSpaceId].logo = _logo;
		spaces[currentSpaceId].name = _name;
        spaces[currentSpaceId].about = _about;
        spaces[currentSpaceId].category = _category;
        spaces[currentSpaceId].nftAddr = _nftAddr;
        spaces[currentSpaceId].nftType = nftType;
        spaces[currentSpaceId].creator = msg.sender;
        spaces[currentSpaceId].createLimit = _createLimit;
		spaces[currentSpaceId].socialMetadata = _socialMetadata;
        emit SpaceCreated(currentSpaceId, _logo, _name, _about, _category, _nftAddr, nftType, msg.sender, _createLimit, _socialMetadata);
    }

    function updateSpace(
        uint256 _spaceId,
        string memory _logo, 
        string memory _name,
        string memory _about, 
        string memory _category, 
        address _nftAddr, 
        uint256 _createLimit,
        string memory _socialMetadata
        ) external 
    {   
        require(IsERC721(_nftAddr) || IsERC1155(_nftAddr), "Invalid Collection Address");
        require(_spaceId <= currentSpaceId, 'invalid _spaceId');
        require(msg.sender == spaces[_spaceId].creator || msg.sender == owner(), "Error, you are not the creator"); 

        uint256 nftType = 0;
        if (IsERC1155(_nftAddr)) {
            nftType = 1;
        }

		spaces[_spaceId].logo = _logo;
		spaces[_spaceId].name = _name;
        spaces[_spaceId].about = _about;
        spaces[_spaceId].category = _category;
        spaces[_spaceId].nftAddr = _nftAddr;
        spaces[_spaceId].nftType = nftType;
        spaces[_spaceId].createLimit = _createLimit;
		spaces[_spaceId].socialMetadata = _socialMetadata;
        emit SpaceUpdated(_spaceId, _logo, _name, _about, _category, _nftAddr, nftType, msg.sender, _createLimit, _socialMetadata);
    }

    function IsERC721(address collection) view private returns(bool) {
        INFTCollection nft = INFTCollection(collection); 
        try nft.supportsInterface(0x80ac58cd) returns (bool result) {
            return result;
        } catch {
            return false;
        }
    }

	function IsERC1155(address collection) view private returns(bool) {
        INFTCollection nft = INFTCollection(collection); 
        try nft.supportsInterface(0xd9b67a26) returns (bool result) {
            return result;
        } catch {
            return false;
        }
    }

    function withdraw() external onlyOwner {
		uint balance = address(this).balance;
		require(balance > 0, "insufficient balance");		
		(bool result, ) = payable(msg.sender).call{value: balance}("");
        require(result, "Failed to withdraw balance"); 
	}
    receive() external payable {}
}