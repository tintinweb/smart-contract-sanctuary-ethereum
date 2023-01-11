/**
 *Submitted for verification at Etherscan.io on 2023-01-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
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


contract DaoPublic {
    address public daoCommittee;
    uint public timer;
    using SafeMath for uint;
    uint public nftIndex;
    uint public time;
    uint public committeeMembersCounter;
    uint[] public winnersIdexes;
    IERC20 public tomi;
    
    struct NFT {   
        string uri;
        address owner;
        uint256 votes;
        bool isApprovedByCommittee;
        bool winnerStatus;
        uint winTime;
    }

    mapping(uint => NFT) public nftInfoo;

    mapping(uint => mapping(address => bool)) public voteCheck;

    event PublicVote(address voter, uint index , NFT _NFT);
    event NftApproved(uint index, NFT _NFT,uint startTime );
     
    event Winner(uint index, NFT nftInfo);

    modifier onlydaoCommitte {
        require(msg.sender == address(daoCommittee), "Only DaoCommitte can call");
        _;
    }

     constructor(IERC20 _tomi) {
        tomi= _tomi;
    }
    function setValues (uint _time, address _daoCommitteeContract, uint _timer ) public {
        daoCommittee= _daoCommitteeContract;
        time= _time;
        timer= block.timestamp+_timer;
    }

    function addInfo (string calldata uri,address _owner, bool _isApprovedByCommittee )  external onlydaoCommitte {
        nftInfoo[nftIndex]= NFT( uri,_owner, 0, _isApprovedByCommittee,false,0);
        nftIndex++;
        emit NftApproved(nftIndex,nftInfoo[nftIndex],block.timestamp );
    }

    function voteNfts(uint index) public {
        require (tomi.balanceOf(msg.sender)>=10*10**18,"You must have 10 TomiToken ");
        require(nftInfoo[index].winnerStatus==false,"Already winner");
        require( voteCheck[index][msg.sender] == false, "Already Voted" );
        require( index < nftIndex , " Choose Correct NFT to vote ");
        nftInfoo[index].votes++;
        voteCheck[index][msg.sender] = true;
        emit PublicVote( msg.sender, index, nftInfoo[index] );

        if (block.timestamp>=timer){
           updateWinner();
       }
    }


    function winnerIndex() public view returns (uint){
        uint highest;
        uint highvotes;
        if(block.timestamp>=timer){
        for(uint i; i< nftIndex; i++){
            if(nftInfoo[i].winnerStatus==false && nftInfoo[i].isApprovedByCommittee==true){
               if(nftInfoo[i].votes>0 ){
                  if(nftInfoo[i].votes > highvotes){
                       highvotes=nftInfoo[i].votes;
                       highest=i;
                  }
               }

            }
        }
         
    }
     return highest;
    }


    function updateWinner() internal {
        uint index = winnerIndex();

        // if nft is already winner or winTime > 0
        if (nftInfoo[index].winnerStatus==true || nftInfoo[index].winTime > 0){
             if(block.timestamp>timer){
            uint dayz= (block.timestamp-(timer -time))/time;
            timer = timer +  (dayz* time);
        }
            return;
        }
        nftInfoo[index].winnerStatus = true;
        nftInfoo[index].winTime = timer;
        winnersIdexes.push(index);
        emit Winner(index, nftInfoo[index]);
        if(block.timestamp>timer){
            uint dayz= (block.timestamp-(timer -time))/time;
            timer = timer +  (dayz* time);
        }
    }

    function setTimer(uint _time) public{
        time=_time;
    }

    function updateDaoCommitteeAddress ( address _address) public {
        daoCommittee= _address;
    }
}