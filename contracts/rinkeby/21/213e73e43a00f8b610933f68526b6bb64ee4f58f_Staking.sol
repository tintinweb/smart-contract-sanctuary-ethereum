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
    IERC721 NFTToken;
    IERC20 token;
  
    uint256 public stakingtime=1 minutes;
    bool public stakingStatus;



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



































 struct userInfo 
      {
        uint256 totalStaked;
      }
// //-----------------------------------------
// //Mappings
  mapping (IERC721=>   mapping(address => mapping(uint256 => uint256)) )public stakingTime;
  mapping (IERC721=>  mapping(address => userInfo )) public IERC721User;
    mapping (IERC721=> mapping(address => uint256[] )) public IERC721Tokenid;
//-----------------------------------------

//-----------------------------------------
//Stake NFTS to earn Reward in coca coin
    function StakeNFT(IERC721 _nftaddress,uint256 tokenId) external 
    {   
       require(stakingStatus==true,"Staking round is not started"); 
       require(_nftaddress.ownerOf(tokenId) == msg.sender,"nft not found");
       _nftaddress.transferFrom(msg.sender,address(this),tokenId);
       IERC721Tokenid[_nftaddress][msg.sender].push(tokenId);
       stakingTime[_nftaddress][msg.sender][tokenId]=block.timestamp;
       IERC721User[_nftaddress][msg.sender].totalStaked++;
    }
    
//-----------------------------------------

//-----------------------------------------
//Returns all NFT user staked
    function userStakedNFT(IERC721 _nftaddress,address _staker)public view returns(uint256[] memory)
       {
       return IERC721Tokenid[_nftaddress][_staker];
       }

//-----------------------------------------
//User have to pass tokenID to unstake token
    function unstake(IERC721 _nftaddress,uint256 _tokenId)  external 
        {
        uint256 _index=find(msg.sender,_nftaddress,_tokenId);
        require(IERC721Tokenid[_nftaddress][msg.sender][_index] ==_tokenId ,"NFT with this _tokenId not found");
        require(block.timestamp>=stakingTime[_nftaddress][msg.sender][_tokenId]+stakingtime," please withdraw after staking time ends");
        NFTToken.transferFrom(address(this),msg.sender,_tokenId);
        delete IERC721Tokenid[_nftaddress][msg.sender][_index];
        IERC721Tokenid[_nftaddress][msg.sender][_index]=IERC721Tokenid[_nftaddress][msg.sender][IERC721Tokenid[_nftaddress][msg.sender].length-1];
        IERC721Tokenid[_nftaddress][msg.sender].pop();
        stakingTime[_nftaddress][msg.sender][_tokenId]=0;
        IERC721User[_nftaddress][msg.sender].totalStaked--;
    }

//-----------------------------------------
//User have to pass tokenID to check tokenID is ready to unstake or now
       function checkRemainingTIme(address _Useradd,IERC721 _nftaddress,uint256 _tokenId)  public view returns(bool ){ 
        if(IERC721User[_nftaddress][_Useradd].totalStaked>0){
        return (block.timestamp>=stakingTime[_nftaddress][_Useradd][_tokenId]+stakingtime);
        }
        else {
        return false;
        }

        }

//
function find(address _Useradd,IERC721 _nftaddress,uint value) public  view returns(uint) {
        uint i = 0;
        while (IERC721Tokenid[_nftaddress][_Useradd][i] != value) {
            i++;
        }
        return i;
    }

}