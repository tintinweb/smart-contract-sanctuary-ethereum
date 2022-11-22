// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "./Ownable.sol";
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


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

// File: contracts/EDM.sol

contract Staking is Ownable{
//-----------------------------------------
//Variables
    using SafeMath for uint256;

  
    uint256 public stakingtime=1 minutes;
    bool public stakingStatus;
//-----------------------------------------

//-----------------------------------------
//Mappings
   
    mapping(address =>  mapping(IERC721 => uint256) ) public TotalNFT;
    mapping(address => mapping(IERC721 =>uint256[] ) ) public Tokenid;
    mapping(address=> mapping(IERC721 => mapping(uint256 =>uint256))) public stakingTime;
//-----------------------------------------
//constructor
    constructor()  
    {
        
      
    }
//-----------------------------------------
//Stake NFTS to earn Reward in coca coin
    function StakeMetatrader(IERC721 _NFTToken,uint256 tokenId) external 
    {   
      IERC721 NFTToken=IERC721(_NFTToken);
       require(stakingStatus==true,"Staking round is not started"); 
       require(NFTToken.ownerOf(tokenId) == msg.sender,"nft not found");
       NFTToken.transferFrom(msg.sender,address(this),tokenId);
       Tokenid[msg.sender][NFTToken].push(tokenId);
       TotalNFT[msg.sender][NFTToken]+=1;
       stakingTime[msg.sender][NFTToken][tokenId]=block.timestamp;
    }
    
//-----------------------------------------

//-----------------------------------------
//Returns total number of specific _nfttoken NFT that user has staked
    function userTotalStakedNFT(address _staker,IERC721 _NFTToken)public view returns(uint256)
       {
       return TotalNFT[_staker][_NFTToken];
       }




//Returns all token ids of specific _nfttoken NFT that user has staked
    function userStakedNFT(address _staker,IERC721 _NFTToken)public view returns(uint256[] memory)
       {
       return Tokenid[_staker][_NFTToken];
       }




//-----------------------------------------
//User have to pass tokenID to unstake token
    function unstake(IERC721 _NFTToken,uint256 _tokenId)  external 
        {
            IERC721 NFTToken=IERC721(_NFTToken);
        uint256 _index=find(NFTToken,_tokenId);
        require(Tokenid[msg.sender][NFTToken][_index] ==_tokenId ,"NFT with this _tokenId not found");
        require(block.timestamp>=stakingTime[msg.sender][NFTToken][_tokenId]+stakingtime," please withdraw after staking time ends");
        NFTToken.transferFrom(address(this),msg.sender,_tokenId);
        delete Tokenid[msg.sender][NFTToken][_index];
        Tokenid[msg.sender][NFTToken][_index]=Tokenid[msg.sender][NFTToken][Tokenid[msg.sender][NFTToken].length-1];
        Tokenid[msg.sender][NFTToken].pop();
        // stakingTime[msg.sender][_tokenId]=0;
        TotalNFT[msg.sender][NFTToken]-=1;
    }

//-----------------------------------------
//User have to pass tokenID to check tokenID is ready to unstake or now
       function checkRemainingTIme(uint256 _tokenId)  public view returns(bool ){ 
        
        // return (block.timestamp>=stakingTime[msg.sender][_tokenId]+stakingtime);

        }

//
function find(IERC721 _NFTToken,uint value) public  view returns(uint) {
        uint i = 0;
        while (Tokenid[msg.sender][_NFTToken][i] != value) {
            i++;
        }
        return i;
    }

    function changeStakingTime(uint256 _time) public onlyOwner{
    stakingtime=_time;
    }

     
    function ChangestakingStatus(bool _status) external onlyOwner{
        stakingStatus=_status;
    }

    function rescueERC20(IERC20 _add,uint256 _amount) external onlyOwner {
        _add.transfer(msg.sender,_amount);
    }
      function withdrawFunds(uint256 _amount)  external onlyOwner {
        payable(msg.sender).transfer(_amount);
    }
    function rescueERC721(IERC721 _add,uint256 id) external onlyOwner {
        _add.transferFrom(address(this),msg.sender, id);
    }


}