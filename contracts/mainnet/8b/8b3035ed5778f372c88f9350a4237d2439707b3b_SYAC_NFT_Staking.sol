/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

/**
 *Submitted for verification at BscScan.com on 2022-02-19
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
 function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burnbyContract(uint256 _amount) external;
    function withdrawStakingReward(address _address,uint256 _amount) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol



/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol



/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://eips.ethereum.org/EIPS/eip-20
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
interface IERC721 {
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
contract Ownable   {
    address public _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**

     * @dev Initializes the contract setting the deployer as the initial owner.

     */

    constructor()  {
        _owner = msg.sender;

        emit OwnershipTransferred(address(0), _owner);
    }

    /**

     * @dev Returns the address of the current owner.

     */

    function owner() public view returns (address) {
        return _owner;
    }

    /**

     * @dev Throws if called by any account other than the owner.

     */

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");

        _;
    }

    /**

     * @dev Transfers ownership of the contract to a new account (`newOwner`).

     * Can only be called by the current owner.

     */

    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;
    }
}

// File: contracts/EDM.sol

contract SYAC_NFT_Staking is Ownable{
//-----------------------------------------
//Variables
    using SafeMath for uint256;
    IERC721 NFTToken;
    IERC20 token;
        //-----------------------------------------
            //Structs
    struct userInfo 
      {
        uint256 totlaWithdrawn;
        uint256 withdrawable;
        uint256 availableToWithdraw;
      }
    struct Stake {
    uint24 tokenId;
    uint48 timestamp;
    address owner;
  }
        //-----------------------------------------
                //Mappings
    mapping(address => mapping(uint256 => uint256)) public stakingTime;
    mapping(address => userInfo ) public User;
    mapping(uint256=>bool) public alreadyAwarded;
    mapping(address=>mapping(uint256=>uint256)) public depositTime;
    mapping(uint256=>Stake) public vault;
    uint256 time= 1 days;
    uint256 public totalSupply=3981;
    uint256 lockingtime= 1 days;
    uint256 public firstReward =300 ether;
            //-----------------------------------------
            //constructor
    constructor(IERC721 _NFTToken,IERC20 _token)  
    {
        NFTToken   =_NFTToken;
        token=_token;
        
    }
    function balanceOf(address account) public view returns (uint256) {
    uint256 balance = 0;
    uint256 supply =totalSupply;
    for(uint i = 1; i <= supply; i++) {
      if (vault[i].owner == account) {
        balance += 1;
      }
    }
    return balance;
  }
   function userStakedNFT(address account) public view returns (uint256[] memory ownerTokens) {

    uint256 supply=totalSupply;
    uint256[] memory tmp = new uint256[](supply);

    uint256 index = 0;
    for(uint tokenId = 1; tokenId <= supply; tokenId++) {
      if (vault[tokenId].owner == account) {
        tmp[index] = vault[tokenId].tokenId;
        index +=1;
      }
    }

    uint256[] memory tokens = new uint256[](index);
    for(uint i = 0; i < index; i++) {
      tokens[i] = tmp[i];
    }

    return tokens;
  }

            //-----------------------------------------
            //Stake NFTS to earn Reward in coca coin
    function stake(uint256[] calldata tokenIds) external 
    { 
       uint256 tokenId;
       for(uint256 i=0;i<tokenIds.length;i++){
       tokenId = tokenIds[i];
       require(NFTToken.ownerOf(tokenId) == msg.sender,"nft not found");
       NFTToken.transferFrom(msg.sender,address(this),tokenId);
       vault[tokenId] = Stake({
        owner: msg.sender,
        tokenId: uint24(tokenId),
        timestamp: uint48(block.timestamp)
      });
       if(!alreadyAwarded[tokenId])depositTime[msg.sender][tokenId]=block.timestamp;
       }
    }
            //-----------------------------------------
            //check your Reward By this function
    function rewardOfUser(address Add) public view returns(uint256)
     {
        uint256 RewardToken;
        uint256[] memory AllStakedNft=userStakedNFT(Add);

        for(uint256 i = 0 ; i < AllStakedNft.length ; i++){
              if((block.timestamp>depositTime[Add][AllStakedNft[i]]+lockingtime)&&!alreadyAwarded[AllStakedNft[i]]){
              RewardToken+=firstReward;
              }
             RewardToken += (((block.timestamp - (vault[AllStakedNft[i]].timestamp)).div(time)))*15 ether;        
     }
    return RewardToken+User[Add].availableToWithdraw;
     }


                    //-----------------------------------------
                            //Withdraw your reward
   
    function WithdrawReward()  public 
      {
       uint256 reward = rewardOfUser(msg.sender);
       uint256[] memory allStakedNft=userStakedNFT(msg.sender);
       require(reward > 0,"you don't have reward yet!");
       require(token.balanceOf(address(token))>=reward,"Contract Don't have enough tokens to give reward");
       token.withdrawStakingReward(msg.sender,reward);
       for(uint8 i=0;i<allStakedNft.length;i++){
       vault[allStakedNft[i]].timestamp=uint48(block.timestamp);
       alreadyAwarded[allStakedNft[i]]=true;
       }
       User[msg.sender].totlaWithdrawn +=  reward;
       User[msg.sender].availableToWithdraw =  0;
      }

        //-----------------------------------------
    //User have to pass tokenID to unstake token

    function unstake(uint256[] memory _tokenId)  external 
        {
        User[msg.sender].availableToWithdraw+=rewardOfUser(msg.sender);
        uint256 tokenId;
        for(uint256 i=0;i<_tokenId.length;i++){
        tokenId=_tokenId[i];
        if(rewardOfUser(msg.sender)>0)alreadyAwarded[_tokenId[i]]=true;
        Stake memory staked = vault[tokenId];
        require(staked.owner == msg.sender, "not an owner");
        NFTToken.transferFrom(address(this),msg.sender,tokenId);
        delete vault[tokenId];
        }       
    }
    function isStaked(address _stakeHolder)public view returns(bool){
            if(userStakedNFT(_stakeHolder).length>0){
            return true;
            }else{
            return false;
          }
     }
    function totalStaked(address _stakeHolder)public view returns(uint256){
           return userStakedNFT(_stakeHolder).length;
     }
                                    //-----------------------------------------
                                            //Only Owner
                                        
            function WithdrawToken()public onlyOwner{
            require(token.transfer(msg.sender,token.balanceOf(address(this))),"Token transfer Error!");
            } 
            function changeFirstReward(uint256 _reward)external onlyOwner{
             firstReward=_reward;
            }
            function setTotalSupply(uint256 _totalSupply)external onlyOwner{
                totalSupply=_totalSupply;
            }
            }