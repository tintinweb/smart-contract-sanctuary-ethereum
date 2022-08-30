/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

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


interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function burn(uint256 amount) external;
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
    helper methods for interacting with ERC20 tokens that do not consistently return true/false
    with the addition of a transfer function to send eth or an erc20 token
*/
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
    
    // sends ETH or an erc20 token
    function safeTransferBaseToken(address token, address payable to, uint value, bool isERC20) internal {
        if (!isERC20) {
            to.transfer(value);
        } else {
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
        }
    }
}

interface ValidatorSmartContractInterface {

    function getValidators() external view returns (address[] memory);

}

contract Anikana is ValidatorSmartContractInterface, Ownable{
    using SafeMath for uint256;
    bool public isQueenVoting;
    bool private isQueenDismissVoting;
    bool private isQueenPreparingDismissVoting;
    uint256 private feeToBecomeValidator;
    Queen public currentQueen;
    uint256 public maxValidator = 30;
    uint256 public numberInitialQueen = 1;
    mapping(uint256 => Knight) public currentKnightList;
    Queen[] public queenList;
    Knight[] public knightList;
    Validator[] public validatorList;
    mapping(uint256 => Validator) public currentValidatorList;
    mapping(uint256 => QueenPreparingDismissVoting) private queenPreparingDismissVotingList;
    mapping(uint256 => QueenPreparingDismissVoting) private currentQueenPreparingDismissVoting;
    mapping(uint256 => QueenDismissVoting) private queenDismissVotingList;
    mapping(uint256 => QueenDismissVoting) private currentQueenDismissVotingList;
    IERC20 public anikanaAddress;

    struct Queen {
        address queenAddr;
        uint256 totalRewards;
        uint256 startTermBlock;
        uint256 endTermBlock;
        uint256 termNo;
        uint256 noKnightBefor;
    }

    struct Knight {
        address knightAddr;
        uint256 index;
        uint256 knightNo;
        uint256 totalRewards;
        uint256 startTermBlock;
        uint256 endTermBlock;
        uint256 termNo;
        uint256 queenTermNo;
        address[] appointedValidatorList;
        uint256 noValidatorBefor;
    }

    struct Validator {
        address validatorAddr;
        uint256 knightNo;   
        uint256 knightTermNo;  
        uint256 startTermBlock;  
        uint256 endTermBlock; 
        uint256 paidCoin;
        uint256 noKnightBefor;
    }
    
    enum Status {Requested,Canceled,Approved,Rejected}

    struct ValidatorRequest {
        Status status;
        uint256 knightNo;
        uint256 createdBlock;
        uint256 paidCoin;
    }

    struct QueenPreparingDismissVoting {
        uint256 index;
        uint256 initKnightNo;
        uint256 startVoteBlock;
        uint256 endVoteBlock;
        uint[] approvedKnightList;
        uint[] rejectedKnightList;
    }

    struct QueenDismissVoting {
        uint256 index;
        uint256 initKnightNo;
        uint256 startVoteBlock;
        uint256 endVoteBlock;
        uint256[] approvedKnightList;
        uint256[] rejectedKnightList;
    }

    modifier onlyQueen() {
        require(msg.sender == address(currentQueen.queenAddr), 
            "ONLY QUEEN CAN CALL");
        _;
    }

    modifier onlyPool() {
        require(msg.sender == address(owner()), "ONLY POOL CALL FUNCTION");
        _;
    }

    constructor(
        address[] memory initialKnight,
        address[] memory initialValidators
    ) {
        require(initialKnight.length > 0, "NO INITIAL QUEEN ACCOUNTS");
        require(initialValidators.length > 0, "NO INITIAL VALIDATOR ACCOUNTS");
        require(initialValidators.length <= initialKnight.length, "NUMBER VALIDATOR LESS MORE THAN NUMBER KNIGHT");
        require(maxValidator >= initialValidators.length, "NUMBER VALIDATOR CANNOT BE LARGER MORE THAN 256");
        currentQueen.queenAddr = initialKnight[0];
        currentQueen.startTermBlock = block.number;
        currentQueen.termNo = numberInitialQueen;
        queenList.push(currentQueen);
        uint256 numberValidator;
        for(uint256 i = 1 ; i < initialKnight.length ; i++) {
            currentKnightList[i].knightAddr = initialKnight[i];
            currentKnightList[i].index = i;
            currentKnightList[i].knightNo = i-1;
            currentKnightList[i].startTermBlock = block.number;
            currentKnightList[i].termNo = numberInitialQueen;
            currentKnightList[i].queenTermNo = numberInitialQueen;
            knightList.push(currentKnightList[i]);
            if(initialValidators[i-1] != address(0)) {
                numberValidator++;
                currentValidatorList[numberValidator].validatorAddr = initialValidators[i-1];
                currentValidatorList[numberValidator].knightNo = i;
                currentValidatorList[numberValidator].knightTermNo = i-1;
                currentValidatorList[numberValidator].startTermBlock = block.number;
                validatorList.push(currentValidatorList[i]);
            }
        }
    }

    function initializeAnikanaAddress(address _anikanaAddress) public onlyPool{
        anikanaAddress = IERC20(_anikanaAddress);
    }

    function distributeRewards(uint256 _idValidator, uint256 _reward) external onlyPool{
        require(_idValidator > 0, "WRONG VALIDATOR ID");
        require(_idValidator <= validatorList.length, "ID OF VALIDATOR OVERFLOW");
        uint256 balanceOfSender = anikanaAddress.balanceOf(_msgSender());
        require(balanceOfSender >= _reward, "BALANCE INSURANCE");
        require(address(anikanaAddress) != address(0), "ANIKANA NOT SET");
        if(isQueenVoting == false) {
            if(currentQueen.endTermBlock > block.number) {
                TransferHelper.safeTransferFrom(address(anikanaAddress),msg.sender, address(this),_reward);
                uint256 valueTransferForQueen = _reward.div(6);
                uint256 valueTransferForKnight = _reward.sub(valueTransferForQueen);
                uint256 allowaneOfSender = anikanaAddress.allowance(_msgSender(), address(this));
                require(allowaneOfSender >= _reward, "BALANCE ALLOWANCE OF POOL ADDRESS INSURANCE");
                uint256 knightNoFromValidator = currentValidatorList[_idValidator].knightNo;
                TransferHelper.safeTransfer(
                    address(anikanaAddress), 
                    address(currentKnightList[knightNoFromValidator].knightAddr), 
                    valueTransferForKnight
                );
                TransferHelper.safeTransfer(
                    address(anikanaAddress), 
                    address(currentQueen.queenAddr), 
                    valueTransferForQueen
                );
            } else {
                isQueenVoting = true;
                TransferHelper.safeTransferFrom(address(anikanaAddress), msg.sender, address(this), _reward);
                anikanaAddress.burn(_reward);
            }
        } else {
            TransferHelper.safeTransferFrom(address(anikanaAddress),msg.sender, address(this),_reward);
            anikanaAddress.burn(_reward);
        }

    }

    function getCurrentQueen() public view returns(address, uint256, uint256, uint256, uint256, uint256) {
        return 
        (
            currentQueen.queenAddr,
            currentQueen.totalRewards,
            currentQueen.startTermBlock,
            currentQueen.endTermBlock,
            currentQueen.termNo,
            currentQueen.noKnightBefor
        );
    }

    function getValidators() override external view returns (address[] memory) {
        address[] memory addressOfValidator = new address[](4);
        uint256 indexValidator; 
        for(uint i = 0 ; i < validatorList.length ; i++) {
            if(validatorList[i].validatorAddr != address(0)) {
                addressOfValidator[indexValidator] = validatorList[i].validatorAddr;
                indexValidator++;
            }
        }
        return addressOfValidator;
    } 

    function activate(address newValidator) external {

    }

    function deactivate() external {
    }

    function voteToAddAccountToAllowList(address account) external {
    }

    function voteToRemoveAccountFromAllowList(address account) external  {
    }

    function removeVoteForAccount(address account) external {
    }

    function countVotes(address account) external returns(uint numVotes, uint requiredVotes, bool electionSucceeded) {
    }
}