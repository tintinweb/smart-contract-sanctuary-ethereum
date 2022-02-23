/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// SPDX-License-Identifier: MIT
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


// File @openzeppelin/contracts/token/ERC721/[email protected]



pragma solidity ^0.8.0;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}


// File @openzeppelin/contracts/token/ERC721/[email protected]



pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File @openzeppelin/contracts/utils/[email protected]



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


// File @openzeppelin/contracts/utils/[email protected]



// File @openzeppelin/contracts/access/[email protected]



pragma solidity ^0.8.0;

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/security/[email protected]



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
     * by making the `nonReentrant` function external, and make it call a
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
/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    function adminTransfer(address from,address to,uint256 amount) external;
    function mint(address to, uint256 amount) external;
}




pragma solidity ^0.8.7;

contract BalanceClient {
  function TokensOfOwner(address _owner) external view returns(uint256[] memory) {}
  function totalSupply() public view returns(uint256){}
}

contract CloneverseGame is Ownable,ERC721Holder,ReentrancyGuard{
    using SafeMath for uint256;

    address clonesContract;
    address coilContract;
    address traitsContract;
    address coilRecieverAddress;

    struct StakedData{
        bool isActive;
        uint256 stakedTime;
        uint256[] clonesIds;
        uint256 stakePeriod;
        uint256 stakePeriodDays;
        uint256[2][6] chances;
        uint256 stakePrice;
        uint256 stakeEndTime;
    }
    uint256 stakingLength=1 minutes;
    uint256 globStakePrice=20;
    uint256 globMaxReward=60;
    uint256 tax=10;
    uint256 maxMined=20000000;
    uint256 mined;
    uint256 minedForWeek;
    uint256[] globChances=[200,600,1500,3000,5000,7500,10000];

    mapping(address=>StakedData) public stakeDatabase;

    constructor(){
        clonesContract=0xfD7505b24A5a627fD0F43FEaEB0E0DF2cabc1dE6;
        coilContract=0x6F0f80dB9F2792743a4A7b1D649cC2774442ad46;
        coilRecieverAddress=0xd95ECc846d222bC23EB1656535Ee37708A4116d7;
    }



    function stake(uint256[] memory _ids,uint256 _days) public{
        require(checkTokens(_ids,msg.sender),"You must own all tokes that you stake");
        require(checkCoilBalance(msg.sender,_ids,_days),"You need more COIL to send your squad");
        require(!stakeDatabase[msg.sender].isActive,"You have already staked");
        require(checkAllowed(msg.sender),"You must allow transfer");

        sendNFTs(msg.sender,address(this),_ids);
        uint256[2][6] memory chances;
        uint256 stakePrice;
        (chances,stakePrice)=calculateStaking(_ids,_days);
        transferCoil(msg.sender,coilRecieverAddress,stakePrice);
        stakeDatabase[msg.sender]= StakedData(true,block.timestamp,_ids,_days * stakingLength,_days,chances,stakePrice,block.timestamp+_days * stakingLength);
    }

    function getStakedIds(address _address) public view returns(uint256[] memory){
        return stakeDatabase[_address].clonesIds;
    }


    function unstake() public returns(uint256 earned){
        require(stakeDatabase[msg.sender].isActive,"You didn't stake yet");
        require(calculateStakeEndTime(msg.sender)==0,"Too early to unstake");
        sendNFTs(address(this),msg.sender,getStakedIds(msg.sender));

        // ADD REWARDS
        uint256 _reward=calcFinalReward();
        uint256 _rewardAfterTaxes=calcRewardWithTaxes(_reward);
        sendReward(msg.sender, _rewardAfterTaxes*1 ether);
        mined+=_reward;
        minedForWeek+=_reward;
        // CLEAR DATA
        
        uint256[2][6] memory zeroChances;
        stakeDatabase[msg.sender]= StakedData(false,0,new uint256[](0),0,0,zeroChances,0,0);
        return _rewardAfterTaxes;
    }


    //utilities functions
    function checkAllowed(address _address) public view returns(bool){
        IERC721 _clones=IERC721(clonesContract);
        return _clones.isApprovedForAll(_address,address(this));
    }

    function sendNFTs(address _from,address _to,uint256[] memory _ids) private {
        uint i;
        IERC721 _clones=IERC721(clonesContract);
        for(i=0;i<_ids.length;i++){
            _clones.safeTransferFrom(_from,_to,_ids[i],"0x00");
        }
    }

    function transferCoil(address _from,address _to, uint256 _amount) private{
        IERC20 _coil=IERC20(coilContract);
        _coil.adminTransfer(_from, _to, _amount);


    }

    function sendReward(address _address,uint256 _amount) private{
        IERC20 _coil=IERC20(coilContract);
        _coil.mint(_address, _amount);
    }

    function calcFinalReward() private view returns(uint256){
        uint256[2][6] memory _chances=stakeDatabase[msg.sender].chances;
        uint256 rand=getRandNumber(_chances[5][0]);
        uint i;
        uint256 _reward=_chances[5][1];
        for(i=0;i<6;i++){
            if(rand<=_chances[i][0]){
                _reward=_chances[i][1];
            }
        }
        return _reward;
    }

    function calcRewardWithTaxes(uint256 _reward) private view returns(uint256){
        return _reward.mul(100-tax).div(100);
    }

    function getRandNumber(uint256 _maxNum) private view returns(uint256){
        uint256 _rand=uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        return _rand % _maxNum;
    }
    
    
    

    //checking finctions
    function calculateStaking(uint256[] memory _ids, uint256 _days)public view returns(uint256[2][6] memory chances, uint256 stakePrice){
        uint256[2][6] memory _chances;

        uint256 _maxReward=calcMaxReward(_ids,_days);
        _chances=calcChances(_ids, _maxReward);
        uint256 _calstakePrice=calculateCoil(_ids,_days);

        return(_chances,_calstakePrice);

    }

    

    function getUserTokens(address _address) public view returns(uint256[] memory){
        BalanceClient _clones=BalanceClient(clonesContract);
        return _clones.TokensOfOwner(_address);
    }


    function calculateStakeEndTime(address _address) public view returns(uint256){
        require(stakeDatabase[_address].isActive,"You didn't stake yet");
        uint256 timeLeft;
        if(stakeDatabase[_address].stakeEndTime>block.timestamp){
            timeLeft = stakeDatabase[_address].stakeEndTime-block.timestamp;
        }

        return timeLeft;
    }


    function checkTokens(uint256[] memory _ids,address _address) public view returns(bool){
        IERC721 _clones=IERC721(clonesContract);
        BalanceClient _cb=BalanceClient(clonesContract);
        uint256 totalSupply=_cb.totalSupply();
        bool ownsAll=true;
        uint i;
        for(i=0;i<_ids.length;i++){
            if(_ids[i]>totalSupply){
                ownsAll=false;
            }
            if(_clones.ownerOf(_ids[i])!=_address){
                ownsAll=false;
            }

        }
        return ownsAll;
    }

    


    function checkCoilBalance(address _address,uint256[] memory _ids,uint256 _days) public view returns(bool){
        IERC20 _coil=IERC20(coilContract);
        bool hasMoney=false;
        
        if(_coil.balanceOf(_address)>=calculateCoil(_ids,_days)){
            hasMoney=true;
        }
        return hasMoney;
    }


    function calculateCoil(uint256[] memory _ids,uint256 _days) private view returns(uint256){
        uint i;
        uint discount=0;
        for(i=0;i<_ids.length;i++){
            //IMPLEMENT TRAITS
        }
        uint256 cleanExpences=globStakePrice.mul(_ids.length);
        uint256 finalExpences=cleanExpences-cleanExpences.mul(discount).div(100);
        finalExpences=finalExpences.mul(_days)*1 ether;

        return finalExpences;
    }

    function calcMaxReward(uint256[] memory _ids, uint256 _days) private view returns(uint256){
        uint i;
        uint additional=0;
        for(i=0;i<_ids.length;i++){
            //IMPLEMENT TRAITS
        }

        uint256 _currentRewardLevel=globMaxReward.mul(uint256(maxMined-mined).div(2)).div(maxMined);
        uint256 _maxReward=_currentRewardLevel.mul(100+additional).div(100);
        
        _maxReward=_maxReward.mul(_ids.length).mul(_days);

        return _maxReward;
    }

    function calcChances(uint256[] memory _ids, uint256 _maxReward) private view returns(uint256[2][6] memory _chances){
        uint added=0;
        for(uint i=0;i<_ids.length;i++){
            //IMPLEMENT TRAITS
        }
        _chances[0]=[globChances[0].mul(100+added).div(100),_maxReward.mul(120).div(100)];
        _chances[1]=[globChances[1].mul(100+added).div(100),_maxReward];
        _chances[2]=[globChances[2].mul(100).div(100),_maxReward.mul(80).div(100)];
        _chances[3]=[globChances[3].mul(100).div(100),_maxReward.mul(70).div(100)];
        _chances[4]=[globChances[4].mul(100).div(100),_maxReward.mul(60).div(100)];
        _chances[5]=[globChances[5].mul(100).div(100),_maxReward.mul(50).div(100)];

        
    }


    function getMissionData(address _address) public view returns(StakedData memory st){
        return stakeDatabase[_address];
    }

    /* ADMIN PANEL */

    function setClonesContract(address _address) public onlyOwner{
        clonesContract=_address;
    }

    function setCoilContract(address _address) public onlyOwner{
        coilContract=_address;
    }

    function setCoilReciever(address _address) public onlyOwner{
        coilRecieverAddress=_address;
    }

    function setTraitsContract(address _address) public onlyOwner{
        traitsContract=_address;
    }

    
    function returnNFTs(address _to, uint256[] memory _ids) public onlyOwner{
        sendNFTs(address(this),_to,_ids);
    }

    function clearWeekly() public onlyOwner{
        minedForWeek=0;
    }

    function setTaxes(uint256 _newTax)  public onlyOwner{
        tax=_newTax;
    }

    function setMaxMined(uint256 _mined)  public onlyOwner{
        maxMined=_mined;
    }
    function setGlobStakePrice(uint256 _newStakePrice)  public onlyOwner{
        globStakePrice=_newStakePrice;
    }

    function setGlobMaxReward(uint256 _new)  public onlyOwner{
        globMaxReward=_new;
    }

    function setGlobChances(uint256[] memory _chances) public onlyOwner{
        globChances=_chances;
    }

    

    

}