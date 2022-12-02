/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/math/SafeMath.sol
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

pragma solidity 0.8.17;
contract DesignDaoPublic {
    uint public timer;
    using SafeMath for uint;
    uint public nftIndex;
  
    uint8 public committeeMembersCounter;
    
   
    uint[] public winnersIdexes;
    
  
    // ["0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2","0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"]
    struct NFT {
        string uri;
        address owner;
        string title;
        string description;
        uint8 approvedVotes;
        uint8 rejectedVotes;
        uint256 votes;
        bool isApprovedByCommittee;
        bool winnerStatus;
    }

    mapping(uint => NFT) public nftInfoo;

    mapping(uint => mapping(address => bool)) public voteCheck;

    event PublicVote(address sender, uint index , NFT _NFT);
     
    event Announcewinner(uint index, NFT _NFT,uint timestamp);
    event Winner(uint index, uint timestamp);

    constructor() {
        // daoCommittee= new DesignDao();
        timer= block.timestamp+30 minutes;
    }

    function addInfo
        (
        string calldata _uri,
        address _owner,
        string calldata _title,
        string calldata _description,
        uint8 _approvedVotes,
        uint8 _rejectedVotes,
        uint256 _votes,
        bool _isApprovedByCommittee,
        bool _winnerStatus
        ) 
    public 
        {
        nftInfoo[nftIndex]= NFT({ uri:_uri,owner:_owner,title:_title,
        description:_description,approvedVotes:_approvedVotes,
        rejectedVotes:_rejectedVotes,votes:_votes,
        isApprovedByCommittee:_isApprovedByCommittee,winnerStatus:_winnerStatus
        });
        nftIndex++;
        if(block.timestamp>timer){
            updateWinner();
        }
    }

    function voteNfts(uint index) public {
        if(block.timestamp>timer){
            updateWinner();
        }
        require(
            nftInfoo[index].isApprovedByCommittee == true,
            "Not Approved by Committee"
        );
        require(nftInfoo[index].winnerStatus==false,"Already winner");
        require( voteCheck[index][msg.sender] == false, "Already Voted" );
        require( index < nftIndex , " Choose Correct NFT to vote ");
        nftInfoo[index].votes++;
        voteCheck[index][msg.sender] = true;
        emit PublicVote( msg.sender, index, nftInfoo[index] );
    }


    // blocktimestamp > timer
    // timestamp-timer/86400= 2
    // timer = 


    function winnerIndex() public view returns (NFT[] memory, uint){
       
        
        uint highest;
        uint highvotes;
        NFT[] memory res=new NFT[](nftIndex);
        if(block.timestamp>=timer){
            for(uint i; i < nftIndex; i++){
                if (nftInfoo[i].winnerStatus==true){
                    continue;
                }
                res[i]=nftInfoo[i];
                if(nftInfoo[i].votes > highvotes){
                    highvotes=nftInfoo[i].votes;
                    highest=i;
                }
            }
        }
        res[highest]=res[nftIndex-1];
        delete res[nftIndex-1];
        return (res, highest);
    }

    function updateWinner() internal {
        
        
       (, uint index) = winnerIndex();
       nftInfoo[index].winnerStatus = true;
       winnersIdexes.push(index);
       
        emit Winner(index, timer);
       if(block.timestamp>timer){
            uint dayz= (block.timestamp-(timer - 30 minutes))/1800;
            timer = timer +  (dayz* 1800);
        }
       
    }

    function setTimer(uint _timer) public{
        timer=_timer;
    }
   


}