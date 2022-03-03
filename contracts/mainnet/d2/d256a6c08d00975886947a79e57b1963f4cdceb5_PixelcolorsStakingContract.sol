// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.0;

import "./RewardToken.sol";

library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}
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
    event Transfer(address indexed from, address indexed to, uint indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint tokenId) external view returns (address owner);

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
    function safeTransferFrom(address from, address to, uint tokenId) external;

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
    function transferFrom(address from, address to, uint tokenId) external;

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
    function approve(address to, uint tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint tokenId) external view returns (address operator);

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
    function safeTransferFrom(address from, address to, uint tokenId, bytes calldata data) external;

    function isNFThasRoyalty(uint _tokenid) external view returns (bool);  
    
    function royaltyInfo(uint256 _tokenId, uint256 _saleprice) external view returns(address[] memory, uint256, uint256);
    
}

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
        uint _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

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
    function onERC721Received(address operator, address from, uint tokenId, bytes calldata data) external returns (bytes4);
}

contract PixelcolorsStakingContract is IERC721Receiver, Ownable{ 
   
    IERC721 public NFTContract;
    RewardToken public rewardToken;
          

    mapping(uint256 => address) public stakedaddress;
    mapping(uint256 => uint256) public depositTime; 
    mapping(uint256 => uint256) public lastrewardClaim;
    mapping(uint256 => uint256) public rewardsEarned;
    mapping(address => uint256[]) public tokenIdsStaked;
    mapping(uint256 => uint256) public tokenIndex;


    uint256 public tokenRewardsPerMinute;

    event Staked(address owner, uint256 amount);

    constructor(){
        tokenRewardsPerMinute=2e17;
        NFTContract = IERC721(0x71Cc8b0ce35BeE7467f7162BA201965BB10DFE68);
        rewardToken = RewardToken(0xEd22DCA00B4d71F08bc184574b028c4Dc53479DE);
    }


    function stake(uint256 _tokenId) external {
     _stake(_tokenId,msg.sender);
    }

    function stakeMultiple(uint256[] memory _ids) external {
        address _userAddress = msg.sender;
        for (uint i=0; i<_ids.length; i++){
             _stake(_ids[i],_userAddress);
        }  
    }


    function totalAccumulatedRewards(address _userAddress) external view returns(uint256){
         uint totalRewards;
         uint[] memory _ids =getStakedTokenIDs(_userAddress);
         for (uint i=0; i<_ids.length; i++){
              totalRewards+=getAccumulatedrewardPerTokenStaked(_ids[i]);
         }
        return totalRewards;
    }
 
    
    function getAccumulatedrewardPerTokenStaked(uint256 _tokenId) public view returns(uint256) {
        uint256 rewards = 0;
        
        if (stakedaddress[_tokenId] != address(0)) {
    
        uint256 minStaked = (block.timestamp - depositTime[_tokenId]) / 60;
        
         uint256 minuteslastClaimTime;  
          if (lastrewardClaim[_tokenId] !=0) {
            minuteslastClaimTime = (block.timestamp - lastrewardClaim[_tokenId]) / 60; // 27382745.2167    
          }
          else {
            minuteslastClaimTime = minStaked;    
          }
        
        rewards = (minuteslastClaimTime * tokenRewardsPerMinute);
        if(_tokenId<=45){
            rewards=(rewards*15)/10;
        }
       } 

        return rewards;
    }  

    function getStakedTokenIDs(address _userAddress) public view returns(uint[] memory){
      return  tokenIdsStaked[_userAddress];
    }


    function claim(uint256 _tokenId) external {
      _claim(_tokenId);
    }

    function totalClaim(uint256[] memory _tokenIds) external {
        for(uint256 i=0;i<_tokenIds.length;i++){
            _claim(_tokenIds[i]);
        }
    }

    function unstake(uint256 _tokenId) external {
        _unstake(_tokenId,msg.sender);
    }

    function unstakeMultiple(uint256[] memory _ids) external {
        address _user = msg.sender;
        for (uint i=0; i<_ids.length; i++){
             _unstake(_ids[i],_user);
        }
    }

    function _unstake(uint256 _tokenId,address _userAddress) internal {

        require(stakedaddress[_tokenId] == _userAddress, "user does not stake this id");
        uint getClaimAmnt = getAccumulatedrewardPerTokenStaked(_tokenId);
         
         if (getClaimAmnt > 0) { 
           rewardToken.mint(stakedaddress[_tokenId],getClaimAmnt);
         }  
         
         delete lastrewardClaim[_tokenId];
         delete rewardsEarned[_tokenId];
         delete stakedaddress[_tokenId];
         delete depositTime[_tokenId];  

         uint[] storage arr = tokenIdsStaked[_userAddress];
         uint index = tokenIndex[_tokenId];
         arr[index]=arr[arr.length-1];
         tokenIndex[arr[arr.length-1]]=index;
         arr.pop();
         tokenIdsStaked[_userAddress]=arr;

         NFTContract.safeTransferFrom(
            address(this),
            _userAddress,
            _tokenId
        );
    }



     function _stake(uint256 _tokenId, address _userAddress) internal {
     
     require(NFTContract.ownerOf(_tokenId) == _userAddress, "Sender is not the owner of the tkn"); 
      stakedaddress[_tokenId] = _userAddress;
      depositTime[_tokenId] = block.timestamp;

      uint[] storage arr = tokenIdsStaked[_userAddress];
      uint len = arr.length;
      tokenIndex[_tokenId]=len;
      arr.push(_tokenId);
      tokenIdsStaked[_userAddress]=arr;
                  
        NFTContract.safeTransferFrom(
            _userAddress,
            address(this),
            _tokenId
        );
        emit Staked(_userAddress, _tokenId);
    }

     function _claim(uint256 _tokenId) internal {
      
      require(stakedaddress[_tokenId] != address(0), "Id not staked");
      uint getClaimAmnt = getAccumulatedrewardPerTokenStaked(_tokenId);

      if (getClaimAmnt > 0) {
         
         lastrewardClaim[_tokenId] = block.timestamp;
         rewardsEarned[_tokenId] += getClaimAmnt;
         rewardToken.mint(stakedaddress[_tokenId],getClaimAmnt);
     }  
    }

    //Admin Functions

    function updateTokenRewardPerMinutes(uint _newRewardPerMinute) external onlyOwner{
        tokenRewardsPerMinute=_newRewardPerMinute;
    }


    function updateRewardToken(address _newRewardToken) external onlyOwner{
        rewardToken=RewardToken(_newRewardToken);
    }

    function updateNFTContract(address _newNFTContract) external onlyOwner{
        NFTContract = IERC721(_newNFTContract);
    }
      
    function onERC721Received(address, address, uint, bytes calldata) public pure override returns (bytes4) {
        return 0x150b7a02;
    }


}