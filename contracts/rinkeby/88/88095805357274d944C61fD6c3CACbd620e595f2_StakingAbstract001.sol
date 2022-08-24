// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

// Here these are not referncing a specific version
// Upgrate then to a specific version
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingAbstract001 is IERC721Receiver, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    // External contract references using an interface
    // External reference to erc721 token contract
    IERC721 public utilityToken;
    // External interface reference to token
    IERC20 public someToken;

    // Set erc721 token reference
    function setUtilityToken(IERC721 _utilityToken) public onlyOwner {
        utilityToken = _utilityToken;
    }

    // Set erc20 token reference
    function setSomeToken(IERC20 _someToken) public onlyOwner {
        someToken = _someToken;
    }

    // Setting the maximum token
    // Is this required? Does this mean that anyone can send in tokens?
    // CHECK: determine if anyone can send tokens to the address
    uint256 public maximumSomeToken;

    // This sets the maximum token
    // This is required based on setting of other amount
    // CHECK: if this is referenced, then it has value
    // CHECK: if it is not referenced, then it can be released
    function setMaxSomeToken(uint256 _maximumSomeToken) public onlyOwner {
        maximumSomeToken = _maximumSomeToken;
    }

    // Set external contract references so that they can be assigned
    // CHECK: dtermine where these are assigned

    // Setting erc721 contract address reference
    address public utilityTokenContractAddress;
    // Setting erc20 contract address reference
    address public someTokenContractAddress;

    // Set both external addresses

    // Set erc721 utility contract address
    function setUtilityTokenContractAddress(address _utilityTokenContractAddress) public onlyOwner {
          utilityTokenContractAddress = _utilityTokenContractAddress;
      }

    // Set erc20 utility contract address
    function setSomeTokenContractAddress(address _someTokenContractAddress) public onlyOwner {
        someTokenContractAddress = _someTokenContractAddress;
    }

    /* REWARDS */

    // Value for tokens per block
    // Reference: https://ethereum.org/en/developers/docs/blocks/
    // Reference for merge: https://blog.ethereum.org/2021/11/29/how-the-merge-impacts-app-layer/
    uint256 public tokensPerBlock;

    // Set tokens per block
    // Calculate rewards output relative to token issuance and value
    function setTokensPerBlock(uint256 _tokensPerBlock) public onlyOwner {
        tokensPerBlock = _tokensPerBlock;
        emit StakeRewardUpdated(tokensPerBlock);
    }

    /**
     * @notice
     * A Stake struct is used to represent the way a staked nft is stored
     * A Stake will contain the tokenId being staked, the block.timestamp from which the staking begins, and the address of the owner
     */
    struct Stake {
        address user;
        uint256 tokenId;
        uint256 stakedFromBlock;
    }

    /**
    * @notice Stakeholder is a staker that has active stakes
     */
    struct Stakeholder{
        address user;
        Stake[] addressStakes;
    }

    /**
     * @notice
     * StakingSummary is a struct that is used to contain all stakes performed by a certain account
     */
     struct StakingSummary{
         Stake[] stakes;
     }

     StakingSummary[] internal userStakingSummary;

    /**
    * @notice
    *   This is a array where we store all Stakes that are performed on the Contract
    *   The stakes for each address are stored at a certain index, the index can be found using the stakes mapping
    */
    Stakeholder[] public stakeholders;

    /**
    * @notice
    * stakes is used to keep track of the INDEX for the stakers in the stakes array
     */
    mapping(address => uint256) public stakes;
    mapping(address => Stake[]) private addressStakes;
    mapping(address => Stakeholder[]) private allStakeholders;

    uint256[] internal s;

    // function getS() public view returns (uint256[] memory) {
    //     return s;
    // }

    // RUNNING
    uint256[] public stakedTokens;

    // RUNNING
    function getStakedTokens() public view returns (uint256[] memory) {
        return stakedTokens;
    }

    /**
    * @notice _addStakeholder takes care of adding a stakeholder to the stakeholders array
     */
    function _addStakeholder(address staker) internal returns (uint256) {
        // Push a empty item to the Array to make space for our new stakeholder
        stakeholders.push();
        // Calculate the index of the last item in the array by Len-1
        uint256 userIndex = stakeholders.length - 1;
        // Assign the address to the new index
        stakeholders[userIndex].user = staker;
        // Add index to the stakeHolders
        stakes[staker] = userIndex;
        return userIndex;
    }

    // TokenID => Stake
    mapping(uint256 => Stake) public receipt;

    /**
    * @notice Staked event is triggered whenever a user stakes tokens, address is indexed to make it filterable
     */
     event Staked(address indexed user, uint256 indexed tokenId, uint256 staredFromBlock, uint256 index);

    /**
    * @notice Staked event is triggered whenever a user stakes tokens, address is indexed to make it filterable
     */
    //  event Staked(address indexed user, uint256 amount, uint256 index, uint256 timestamp);

    // event Staked(address indexed user, uint256 tokenId, uint256 blockNumber);
    // These would need notice definition
    event Unstaked(address indexed user, uint256 indexed tokenId, uint256 blockNumber);
    event StakePayout(address indexed staker, uint256 tokenId, uint256 stakeAmount, uint256 fromBlock, uint256 toBlock);
    event StakeRewardUpdated(uint256 rewardPerBlock);
    event MaximumSpaceUpdated(uint256 maximumSomeToken);

    // Need to add documentation status
    modifier onlyStaker(uint256 tokenId) {

        // UtilityToken utilityToken = UtilityToken(utilityTokenContractAddress);
        // require that this contract has the NFT
        require(utilityToken.ownerOf(tokenId) == address(this), "onlyStaker: Contract is not owner of this NFT");

        // require that this token is staked
        require(receipt[tokenId].stakedFromBlock != 0, "onlyStaker: Token is not staked");

        // require that msg.sender is the owner of this nft
        require(receipt[tokenId].user == msg.sender, "onlyStaker: Caller is not NFT stake owner");

        _;
    }

    // Need to add documentation status
    modifier requireTimeElapsed(uint256 tokenId) {
        // require that some time has elapsed (IE you can not stake and unstake in the same block)
        require(
            receipt[tokenId].stakedFromBlock < block.number,
            "requireTimeElapsed: Can not stake/unstake/harvest in same block"
        );
        _;
    }

    // In this version of the constructor items are declared at initialization
    // constructor(
    //     IERC721 _utilityToken,
    //     IERC20 _someToken,
    //     uint256 _tokensPerBlock
    // ) {
    //     utilityToken = _utilityToken;
    //     someToken = _someToken;
    //     tokensPerBlock = _tokensPerBlock;

    //     emit StakeRewardUpdated(tokensPerBlock);
    // }

    constructor() {
        // This push is needed so we avoid index 0 causing bug of index-1
        stakeholders.push();
    }

    /**
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
     // Check what the documentation is in and add here
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "No sending tokens directly to StakingAbstract");
        return IERC721Receiver.onERC721Received.selector;
    }

    //User must give this contract permission to take ownership of it.
    function stakeUtilityToken(uint256 tokenId) nonReentrant external {
        // UtilityToken utilityToken = UtilityToken(utilityTokenContractAddress);

        // require(account == _msgSender() || _msgSender() == address(utilityToken), "Invalid staking address");
        // require(utilityToken.ownerOf(tokenId) == _msgSender(), "You have to owhn the token to stake it");
        // allow for staking multiple NFTS at one time.
        // for (uint256 i = 0; i < tokenId.length; i++) {
        //     _stakeUtilityToken(tokenId[i]);
        // }

        _stakeUtilityToken(tokenId);

    }

    function _stakeUtilityToken(uint256 tokenId) internal returns (bool) {

      // Mappings in solidity creates all values, but empty, so we can just check the address
        uint256 index = stakes[msg.sender];
        // block.timestamp = timestamp of the current block in seconds since the epoch
        // uint256 timestamp = block.timestamp;
        // See if the staker already has a staked index or if its the first time
        if(index == 0){
            // This stakeholder stakes for the first time
            // We need to add him to the stakeHolders and also map it into the Index of the stakes
            // The index returned will be the index of the stakeholder in the stakeholders array
            index = _addStakeholder(msg.sender);
        }

        // Use the index to push a new Stake
        // push a newly created Stake with the current block timestamp.
        stakeholders[index].addressStakes.push(Stake(msg.sender, tokenId, block.number));

        stakedTokens.push(tokenId);

        _updateTokenIds(msg.sender);

        /***********************/

        // UtilityToken utilityToken = UtilityToken(utilityTokenContractAddress);

        // require this token is not already staked
        require(receipt[tokenId].stakedFromBlock == 0, "Stake: Token is already staked");

        // require this token is not already owned by this contract
        require(utilityToken.ownerOf(tokenId) != address(this), "Stake: Token is already staked in this contract");

        // Approve address for transfer
        // Allows non-owner wallets to stake their NFT
        // utilityToken.approve(address(this), tokenId);

        // take possession of the NFT
        utilityToken.transferFrom(_msgSender(), address(this), tokenId);

        // check that this contract is the owner
        require(utilityToken.ownerOf(tokenId) == address(this), "Stake: Failed to take possession of NFT");

        // start the staking from this block.
        receipt[tokenId].user = msg.sender;
        receipt[tokenId].tokenId = tokenId;
        receipt[tokenId].stakedFromBlock = block.number;

        emit Staked(msg.sender, tokenId, block.number, index);

        return true;
    }

    function unstakeUtilityToken(uint256 tokenId) nonReentrant external {
        _unstakeUtilityToken(tokenId);
    }

    function _unstakeUtilityToken(uint256 tokenId) internal onlyStaker(tokenId) requireTimeElapsed(tokenId) returns (bool) {


        // UtilityToken utilityToken = UtilityToken(utilityTokenContractAddress);
        // payout stake, this should be safe as the function is non-reentrant
        _payoutStake(tokenId);

        // delete stake record, effectively unstaking it
        delete receipt[tokenId];


        // return token
        utilityToken.safeTransferFrom(address(this), _msgSender(), tokenId);

        /***********************/

        uint256 userIndex = stakes[msg.sender];
        Stake[] memory currentStakeList = stakeholders[userIndex].addressStakes;
        uint256 stakedItemsLength = currentStakeList.length;
        uint256 unstakedTokenIdx;

        for (uint256 i = 0; i < stakedItemsLength; i++) {
            Stake memory stake = currentStakeList[i];
            if (stake.tokenId == tokenId) {
                unstakedTokenIdx = i;
            }
        }

        Stake memory lastStake = currentStakeList[ currentStakeList.length - 1 ];
        stakeholders[userIndex].addressStakes[unstakedTokenIdx].user = lastStake.user;
        stakeholders[userIndex].addressStakes[unstakedTokenIdx].tokenId = lastStake.tokenId;
        stakeholders[userIndex].addressStakes[unstakedTokenIdx].stakedFromBlock = lastStake.stakedFromBlock;
        stakeholders[userIndex].addressStakes.pop();

        // Stake memory currentStake = stakeholders[userIndex].addressStakes[tokenId];
        // delete currentStake;

        // delete stakeholders[userIndex].addressStakes[tokenId];

        // _updateTokenIds(msg.sender);

        emit Unstaked(msg.sender, tokenId, block.number);

        return true;
    }

    function harvest(uint256 tokenId) public nonReentrant onlyStaker(tokenId) requireTimeElapsed(tokenId) {
        // This 'payout first' should be safe as the function is nonReentrant
        _payoutStake(tokenId);
        // update receipt with a new block number
        receipt[tokenId].stakedFromBlock = block.number;
    }

    function getTokenBalance() public view returns (uint256) {
        // SomeToken someToken = SomeToken(someTokenContractAddress);
        return someToken.balanceOf(address(this));
    }

    function getCurrentStakeEarned(uint256 tokenId) public view returns (uint256) {
        // UtilityToken utilityToken = UtilityToken(utilityTokenContractAddress);
        // modified
        // uint256 warp = utilityToken.tokenId;
        // return _getTimeStaked(tokenId).mul(tokensPerBlock * warp);


        return _getTimeStaked(tokenId).mul(tokensPerBlock);
    }

    /******** CURRENTLY WRITE FUNCTION / NEEDS TO STORE VALUES IN STRUCT USING STAKING EVENTS **********/

    function _updateTokenIds(address _user) internal returns (bool) {

        // Keep a summary in memory since we need to calculate this
        StakingSummary memory summary = StakingSummary(stakeholders[stakes[_user]].addressStakes);
        uint256 stakedItemsLength = summary.stakes.length;

        // uint256[] storage f;

        for (uint i = 0; i < stakedItemsLength; i++) {
            Stake memory stake = summary.stakes[i];
            // uint256[] memory f;

            // mapping(uint256 => stakes[tokenId]);

            uint256 p = stake.tokenId;
            s.push(p);
        }

        return true;

    }

    /********** THIS IS RUNNING AND RETURNS TUPLE **********/
    /********** USE AS MODEL TO RETURN TOKENID INT VALUES **********/

    function getStakingSummary(address _user) public view returns (StakingSummary memory) {
        StakingSummary memory summary = StakingSummary(stakeholders[stakes[_user]].addressStakes);
        return summary;
    }

    function reclaimTokens() external onlyOwner {
        // SomeToken someToken = someToken(someTokenContractAddress);
        someToken.transfer(msg.sender, someToken.balanceOf(address(this)));
    }

    function _payoutStake(uint256 tokenId) internal {
        /* NOTE : Must be called from non-reentrant function to be safe!*/

        // SomeToken token = Token(someTokenContractAddress);

        // double check that the receipt exists and we're not staking from block 0
        require(receipt[tokenId].stakedFromBlock > 0, "_payoutStake: No staking from block 0");

        // UtilityToken utilityToken = UtilityToken(utilityTokenContractAddress);
        // uint256 warp = utilityToken.tokenId;

        // earned amount is difference between the stake start block, current block multiplied by stake amount
        uint256 timeStaked = _getTimeStaked(tokenId).sub(1); // don't pay for the tx block of withdrawl

        // uint256 payout = timeStaked.mul(tokensPerBlock * warp);
        uint256 payout = timeStaked.mul(tokensPerBlock);

        // If contract does not have enough tokens to pay out, return the NFT without payment
        // This prevent a NFT being locked in the contract when empty
        if (someToken.balanceOf(address(this)) < payout) {
            emit StakePayout(msg.sender, tokenId, 0, receipt[tokenId].stakedFromBlock, block.number);
            return;
        }

        // payout stake
        // someToken.transferController(receipt[tokenId].owner, payout);
        someToken.transfer(receipt[tokenId].user, payout);
        // someToken.burn(receipt[tokenId].user, payout);

        emit StakePayout(msg.sender, tokenId, payout, receipt[tokenId].stakedFromBlock, block.number);
    }

    function _getTimeStaked(uint256 tokenId) internal view returns (uint256) {
        if (receipt[tokenId].stakedFromBlock == 0) {
            return 0;
        }
        return block.number.sub(receipt[tokenId].stakedFromBlock);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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