/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

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
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface ICommunityRelations {
    function setAccountLevel(address account, uint8 types) external;

    function getAccountLevel(address account) external view returns(uint8);

    function getInviter(address account) external view returns(address, uint8);
}

contract StakeNFTPool is Ownable {

    using SafeMath for uint256;

    address nullAddress = 0x0000000000000000000000000000000000000000;

    address public poularNFTAddress;
    
    address public velTokenAddress;
    address public devlAddress;

    address public relationAddress;

    uint256 public claimRate = 1; //persent;

    uint256 public stakePeriod = 0;

    uint256 internal maxPerNftReward = 5200 * 10 ** 9;

    uint256 public secondRewardPerNFT =  167181; 

    //Mapping of mouse to timestamp
    mapping(uint256 => uint256) internal tokenIdToTimeStamp;

    mapping(uint256 => uint256) internal tokenIdReleaseTimeStamp;

    //Mapping of mouse to staker
    mapping(uint256 => address) internal tokenIdToStaker;

    //Mapping of staker to mice
    mapping(address => uint256[]) internal stakerToTokenIds;

    mapping(uint256 => uint256) internal perNftTotalReward;

    event StakeTokendIds(address indexed staker, uint256[] tokendIds);
    event UnStake(address indexed staker, uint256[] tokenIds);
    event ClaimReward(address indexed stake, uint256 rewards);

    constructor(
        address _velTokenAddress,
        address _poularNFTAddress,
        address _devlAddress 
        ) {
        velTokenAddress = _velTokenAddress;
        poularNFTAddress = _poularNFTAddress;
        devlAddress = _devlAddress;
    }

    function setVelTokenAddress(address _velTokenAddress) external onlyOwner {
        velTokenAddress = _velTokenAddress;
    }

    function setPoularNFTAddress(address _poularNFTAddress) external onlyOwner {
        poularNFTAddress = _poularNFTAddress;
    }

    function setRelationAddress(address _relationAddress) external onlyOwner {
        relationAddress = _relationAddress;
    }

    function setDevlAddress(address _devlAddress) external onlyOwner {
        devlAddress = _devlAddress;
    }

    function setClaimRate(uint256 rate) external onlyOwner {
        claimRate = rate;
    }

    function remove(address staker, uint256 index) internal {
        if (index >= stakerToTokenIds[staker].length) return;

        for (uint256 i = index; i < stakerToTokenIds[staker].length - 1; i++) {
            stakerToTokenIds[staker][i] = stakerToTokenIds[staker][i + 1];
        }
        stakerToTokenIds[staker].pop();
    }

    function removeTokenIdFromStaker(address staker, uint256 tokenId) internal {
        for (uint256 i = 0; i < stakerToTokenIds[staker].length; i++) {
            if (stakerToTokenIds[staker][i] == tokenId) {
                //This is the tokenId to remove;
                remove(staker, i);
            }
        }
    }

    function stakeByIds(uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                IERC721(poularNFTAddress).ownerOf(tokenIds[i]) == msg.sender &&
                    tokenIdToStaker[tokenIds[i]] == nullAddress,
                "This NFT must be stakable by you!"
            );
            uint256 tokenBalance = IERC20(velTokenAddress).balanceOf(address(this));
            require(tokenBalance > 0, "The mine has been hollowed out");
            //Second stake
            if(tokenIdToStaker[tokenIds[i]] == msg.sender 
            && block.timestamp > tokenIdReleaseTimeStamp[tokenIds[i]]
            && tokenIdToTimeStamp[tokenIds[i]] > 0) {
                uint256 lastTime =  block.timestamp;
                uint256 velTotalRewards = lastTime.sub(tokenIdToTimeStamp[tokenIds[i]]) * secondRewardPerNFT;
                require(tokenBalance > velTotalRewards, "The mine will be hollowed out, you can release");
                if(velTotalRewards > 0) {
                    IERC20(velTokenAddress).transfer(msg.sender, velTotalRewards);
                }
            } else {
                IERC721(poularNFTAddress).transferFrom(
                    msg.sender,
                    address(this),
                    tokenIds[i]
                );
                stakerToTokenIds[msg.sender].push(tokenIds[i]);
                tokenIdToStaker[tokenIds[i]] = msg.sender;
            }
            tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
            tokenIdReleaseTimeStamp[tokenIds[i]] = block.timestamp.add(stakePeriod);
            setRelation(msg.sender, 1);
        }
        emit StakeTokendIds(msg.sender, tokenIds);
    }

    function unstakeAll() public {
        require(
            stakerToTokenIds[msg.sender].length > 0,
            "Must have at least one NFT staked!"
        );
        uint256 velTotalRewards = 0;
        for (uint256 i = stakerToTokenIds[msg.sender].length; i > 0; i--) {
            uint256 tokenId = stakerToTokenIds[msg.sender][i - 1];
            require(block.timestamp >= tokenIdReleaseTimeStamp[tokenId], "It's not the release date yet");
            IERC721(poularNFTAddress).transferFrom(
                address(this),
                msg.sender,
                tokenId
            );
            uint256 lastTime =  block.timestamp;
            //block number 
            uint256 perTokenReward = (lastTime - tokenIdToTimeStamp[tokenId]) * secondRewardPerNFT;
            if (perNftTotalReward[tokenId].add(perTokenReward) >= maxPerNftReward) {
                perTokenReward = maxPerNftReward.sub(perNftTotalReward[tokenId]);
            }
            require(perTokenReward <= maxPerNftReward, "error reward");
            perNftTotalReward[tokenId] = perNftTotalReward[tokenId].add(perTokenReward);
            velTotalRewards = velTotalRewards.add(perTokenReward);

            removeTokenIdFromStaker(msg.sender, tokenId);
            tokenIdReleaseTimeStamp[tokenId] = 0;
            tokenIdToTimeStamp[tokenId] = block.timestamp; 
            tokenIdToStaker[tokenId] = nullAddress;
            setRelation(msg.sender, 0);
        }
        uint256 tokenBalance = IERC20(velTokenAddress).balanceOf(address(this));
        //require(tokenBalance > 0, "The mine has been hollowed out");
        if(tokenBalance > 0 && tokenBalance < velTotalRewards) {
            velTotalRewards = tokenBalance;
        }
        if(velTotalRewards > 0 && tokenBalance >= velTotalRewards) {
            (uint256 transferAmount, uint256 fee) = calculateFee(velTotalRewards);
            IERC20(velTokenAddress).transfer(msg.sender, transferAmount);
            IERC20(velTokenAddress).transfer(devlAddress, fee);
            emit ClaimReward(msg.sender, velTotalRewards);
        }
        emit UnStake(msg.sender, stakerToTokenIds[msg.sender]);
    }

    function unstakeByIds(uint256[] memory tokenIds) public {
        require(tokenIds.length > 0, "tokenId error");
        uint256 velTotalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[tokenIds[i]] == msg.sender,
                "Message Sender was not original staker!"
            );
            require(block.timestamp >= tokenIdReleaseTimeStamp[tokenIds[i]], "It's not the release date yet");
            IERC721(poularNFTAddress).transferFrom(
                address(this),
                msg.sender,
                tokenIds[i]
            );
            uint256 lastTime =  block.timestamp;
            uint256 perTokenReward = (lastTime - tokenIdToTimeStamp[tokenIds[i]]) * secondRewardPerNFT;
            if (perNftTotalReward[tokenIds[i]].add(perTokenReward) >= maxPerNftReward) {
                perTokenReward = maxPerNftReward.sub(perNftTotalReward[tokenIds[i]]);
            }
            require(perTokenReward <= maxPerNftReward, "error reward");
            perNftTotalReward[tokenIds[i]] = perNftTotalReward[tokenIds[i]].add(perTokenReward);
            velTotalRewards = velTotalRewards.add(perTokenReward);

            removeTokenIdFromStaker(msg.sender, tokenIds[i]);
            tokenIdReleaseTimeStamp[tokenIds[i]] = 0;
            tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
            tokenIdToStaker[tokenIds[i]] = nullAddress;
            setRelation(msg.sender, 0);
        }
        uint256 tokenBalance = IERC20(velTokenAddress).balanceOf(address(this));
        //require(tokenBalance > 0, "The mine has been hollowed out");
        if(tokenBalance > 0 && tokenBalance < velTotalRewards) {
            velTotalRewards = tokenBalance;
        }
        if(velTotalRewards > 0 && tokenBalance >= velTotalRewards) {
            (uint256 transferAmount, uint256 fee) = calculateFee(velTotalRewards);
            IERC20(velTokenAddress).transfer(msg.sender, transferAmount);
            IERC20(velTokenAddress).transfer(devlAddress, fee);
            emit ClaimReward(msg.sender, velTotalRewards);
        }
        emit UnStake(msg.sender, tokenIds);
    }

    function setRelation(address account, uint8 types) private {
        if(relationAddress != address(0)) {
            ICommunityRelations(relationAddress).setAccountLevel(account, types);
        }
    }

    function claimByTokenId(uint256 tokenId) public {
        require(
            tokenIdToStaker[tokenId] == msg.sender,
            "Token is not claimable by you!"
        );
        uint256 lastTime =  block.timestamp;
        uint256 velTotalRewards = (lastTime - tokenIdToTimeStamp[tokenId]) * secondRewardPerNFT;
        uint256 tokenBalance = IERC20(velTokenAddress).balanceOf(address(this));
        require(tokenBalance > 0, "The mine has been hollowed out");
        if (tokenBalance > 0 && tokenBalance < velTotalRewards) {
            velTotalRewards = tokenBalance;
        }
        if (perNftTotalReward[tokenId].add(velTotalRewards) >= maxPerNftReward) {
            velTotalRewards = maxPerNftReward.sub(perNftTotalReward[tokenId]);
        }
        require(velTotalRewards <= maxPerNftReward, "error reward");
        perNftTotalReward[tokenId] = perNftTotalReward[tokenId].add(velTotalRewards);
        (uint256 transferAmount, uint256 fee) = calculateFee(velTotalRewards);
        IERC20(velTokenAddress).transfer(msg.sender, transferAmount);
        IERC20(velTokenAddress).transfer(devlAddress, fee);
        tokenIdToTimeStamp[tokenId] = lastTime;
        emit ClaimReward(msg.sender, velTotalRewards);
    }

    function claimAll() public {
        uint256[] memory tokenIds = stakerToTokenIds[msg.sender];
        require(tokenIds.length > 0, "you have no stake NFT");
        uint256 velTotalRewards = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[tokenIds[i]] == msg.sender,
                "Token is not claimable by you!"
            );
            uint256 lastTime =  block.timestamp;
            uint256 perTokenReward = lastTime.sub(tokenIdToTimeStamp[tokenIds[i]]) * secondRewardPerNFT;
            if (perNftTotalReward[tokenIds[i]].add(perTokenReward) >= maxPerNftReward) {
                perTokenReward = maxPerNftReward.sub(perNftTotalReward[tokenIds[i]]);
            }
            perNftTotalReward[tokenIds[i]] = perNftTotalReward[tokenIds[i]].add(perTokenReward);
            require(perTokenReward <= maxPerNftReward, "error reward");
            velTotalRewards = velTotalRewards.add(perTokenReward);
            tokenIdToTimeStamp[tokenIds[i]] = lastTime;
        }
        uint256 tokenBalance = IERC20(velTokenAddress).balanceOf(address(this));
        require(tokenBalance > 0, "The mine has been hollowed out");
        if(tokenBalance > 0 && tokenBalance < velTotalRewards) {
            velTotalRewards = tokenBalance;
        }
        if(velTotalRewards > 0) {
            (uint256 transferAmount, uint256 fee) = calculateFee(velTotalRewards);
            IERC20(velTokenAddress).transfer(msg.sender, transferAmount);
            IERC20(velTokenAddress).transfer(devlAddress, fee);
            emit ClaimReward(msg.sender, velTotalRewards);
        }
    }

    function calculateFee(uint256 amount) private view returns(uint256 transferAmount, uint256 fee) {
        fee = amount.mul(claimRate).div(100);
        transferAmount = amount.sub(fee);
    }

    function getAllRewards(address staker) public view returns (uint256) {
        uint256[] memory tokenIds = stakerToTokenIds[staker];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 lastTime =  block.timestamp;
            uint256 reward =  (lastTime - tokenIdToTimeStamp[tokenIds[i]]) * secondRewardPerNFT;
            if(reward > maxPerNftReward) {
                reward = maxPerNftReward;
            }
            totalRewards = totalRewards + reward;
        }

        return totalRewards;
    }

    function getRewardsByTokenId(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        require(
            tokenIdToStaker[tokenId] != nullAddress,
            "Token is not staked!"
        );
        uint256 lastTime =  block.timestamp;
        uint256 secondsStaked = lastTime - tokenIdToTimeStamp[tokenId];
        uint256 reward = secondsStaked * secondRewardPerNFT;
        return reward > maxPerNftReward ? maxPerNftReward : reward;
    }

    function getStaker(uint256 tokenId) public view returns (address) {
        return tokenIdToStaker[tokenId];
    }

    function getTokensStaked(address staker) public view returns (uint256[] memory) {
        return stakerToTokenIds[staker];
    }
}