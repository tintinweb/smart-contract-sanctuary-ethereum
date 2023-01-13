/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


interface IDaoPublic{

     struct NFT {   
        string uri;
        address owner;
        uint index;
        uint votes;
        uint position2D;
        // uint256 votes;
        bool isApprovedByCommittee;
        bool winnerStatus;
        uint winTime;
    }

    function addInfo (string calldata uri,address _owner, bool _isApprovedByCommittee) external ;
    function timer() external view returns(uint);
    function announceWinner() external;

    
}


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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
} 


contract DaoCommittee {
    // using SafeMathUpgradeable for uint;
    IERC20 public tomi;
    uint public nftIndex;
    uint public committeeMembersCounter;
    IDaoPublic public DaoPublic;
  
    struct NFT {
        string uri;
        address owner;
        uint approvedVotes;
        uint rejectedVotes;
        bool isApprovedByCommittee;
        bool rejected;
    }
   
    mapping(address => bool) public Committee;

    mapping(uint => NFT) public nftStore;

    mapping(uint => mapping(address => uint8)) public committeeVoteCheck;

    event NftAdded( uint index,NFT NFT, uint uploadTime );
    event CommitteeVote(address committeeMember,uint index, bool decision, NFT _NFT);
    
    modifier onlyComittee() {
        require(Committee[msg.sender] == true,"Not Committee Member");
        _;
    }

      constructor(IERC20 _tomi ) {
        Committee[msg.sender] = true;
        committeeMembersCounter++;
        tomi= _tomi;
    }
    
    function addNfts( string calldata uri_)  public {
        require (tomi.balanceOf(msg.sender)>=10 ether,"You must have 10 TomiToken ");
            nftStore[nftIndex] =NFT (uri_,msg.sender,0,0,false,false);
            emit NftAdded(nftIndex, nftStore[nftIndex], block.timestamp);
            nftIndex++;
            if (block.timestamp>=DaoPublic.timer()){
                DaoPublic.announceWinner();
       }
    }

    function voteByCommittee(uint index, bool decision) public onlyComittee {
        // if (block.timestamp>=DaoPublic.timer()){
        //    DaoPublic.updateWinner();
        // }
        require(committeeVoteCheck[index][msg.sender] == 0, " Already Voted ");
        require(nftStore[index].owner != address(0), "NFT doesnot exist");
        require (nftStore[index].isApprovedByCommittee==false, "NFT already approved");
        require (nftStore[index].rejected == false, "NFT already approved");

        uint votesTarget =(committeeMembersCounter /2)+1;
               
        if (decision == true) {
            nftStore[index].approvedVotes++;
            committeeVoteCheck[index][msg.sender] = 1;
            if (nftStore[index].approvedVotes >= votesTarget) {
                nftStore[index].isApprovedByCommittee = true;
                DaoPublic.addInfo ( nftStore[index].uri, nftStore[index].owner, true );
            }
            emit CommitteeVote(msg.sender,index , decision , nftStore[index]);

        } else {
            nftStore[index].rejectedVotes++;
            committeeVoteCheck[index][msg.sender] = 2;

            if (nftStore[index].rejectedVotes >= votesTarget) {
                nftStore[index].isApprovedByCommittee = false;
                nftStore[index].rejected =true;
            }
            emit CommitteeVote(msg.sender,index , decision,nftStore[index] );
        }
    }
  

   function AddComitteMemberBatch(address[] calldata _addresses)
        public
        onlyComittee {
        for (uint8 i; i < _addresses.length; i++) {
            require(
                Committee[_addresses[i]] == false,
                "Already Committee Member"
            );
            Committee[_addresses[i]] = true;
            committeeMembersCounter++;
        }
        }

    function addCommitteeMember(address _memberToAdd) public onlyComittee {
        require(Committee[_memberToAdd] == false, "Already Committee member");
        Committee[_memberToAdd] = true;
        committeeMembersCounter++;
    }

    function removeCommitteeMember(address _memberToRemove) public onlyComittee {
        require(Committee[_memberToRemove] == true, "Not Committee member");
        Committee[_memberToRemove] = false;
        committeeMembersCounter--;
    }

    function withdrawFromCommittee() public onlyComittee {
        Committee[msg.sender] = false;
        committeeMembersCounter--;
    }

    function removeCommitteeMemberBatch(address[] calldata _addresses)
        public
        onlyComittee {
        for (uint8 i; i < _addresses.length; i++) {
            require(
                Committee[_addresses[i]] == true,
                "Not in Committee"
            );
            Committee[_addresses[i]] = false;
            committeeMembersCounter--;
        }
        }

    function updateDaoPublicAddress (IDaoPublic _add) public onlyComittee {
        DaoPublic= _add;
    }
}