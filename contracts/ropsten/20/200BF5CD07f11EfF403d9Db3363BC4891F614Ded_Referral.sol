// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

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

//Theres two ways of designing this referral system:
//Everytime a user borrows - the app checks if he's borrowing through a referral link
//When a user interacts with the app for the first time, the referral connection is made and ALL subsequent borrows trigger a transaction fee
contract Referral {

    using SafeMath for uint256;

    address public owner;
    uint256 public maxPromoCodesPerUser=3;//number of promo codes that a single address can create
    uint256 public referralPercentage=40;//percentage of the borrow fee that goes to the affiliate



    /// @notice which user created this promo code. User can be associated with multiple promo codes
    mapping (string => address) public promo_code_ownership;
    /// @notice all promo codes owned by user
    mapping (address => string[]) public all_promo_codes_owned_by_user;
    /// @notice Keeps track of whether a user signed up using a promo code; only relevant if using a workflow where a a referrer connection is permanently established upon initial interaction with all
    mapping (address => address) public affiliate_link;


    constructor() public{
        owner=msg.sender;
    }


    /// @notice Addes an affiliate promo code for the transaction sender
    /// @param new_promo_code Promo code to add
    function set_promo_code_ownership(string calldata new_promo_code) public{
        require(promo_code_ownership[new_promo_code]==address(0), "Promo code already used");
        require(all_promo_codes_owned_by_user[msg.sender].length<maxPromoCodesPerUser, "Too many promo codes");
        promo_code_ownership[new_promo_code]=msg.sender;
        all_promo_codes_owned_by_user[msg.sender].push(new_promo_code);
    }
    /// @notice Removes an affiliate promo code for the transaction sender
    /// @param existing_promo_code Promo code to remove
    function remove_promo_code(string calldata existing_promo_code) public{
        require(promo_code_ownership[existing_promo_code]==msg.sender, "No permission to remove");
        promo_code_ownership[existing_promo_code]=address(0);

        for(uint i =0; i<all_promo_codes_owned_by_user[msg.sender].length; i++){
            if(keccak256(abi.encodePacked((all_promo_codes_owned_by_user[msg.sender][i]))) == keccak256(abi.encodePacked((existing_promo_code)))){
                for(uint j =i; j<all_promo_codes_owned_by_user[msg.sender].length-1; j++){
                    all_promo_codes_owned_by_user[msg.sender][j]=all_promo_codes_owned_by_user[msg.sender][j+1];
                }
                all_promo_codes_owned_by_user[msg.sender].pop();
            }
        }

    }
/*
    /// @notice PERMANENTLY establishes a referrer connection - should be called upon initial interaction with app
    /// @param user The user that is signing up
    /// @param promo_code_used The promo code that is used when signing up (if any)
    function establish_promo_link(address user, string calldata promo_code_used) public{
        //Needs to fail silently
        

        

        if(bytes(promo_code_used).length==0){//No referral code
            return;
        }

        address affliate_owner=promo_code_ownership[promo_code_used];
        if(affliate_owner == address(0)){//Invalid promo code
            return;
        }
        if(affiliate_link[user] != address(0)){//Already signed up using affiliate code
            return;
        }
        if(promo_code_ownership[promo_code_used]==user){//Can't sign up using own affiliate
            return;
        }

        affiliate_link[user]=affliate_owner;

    }
*/
/////////////////////////////////////////////////////////////////////////////Utility Functions////////////////////////////////////////////////////
    function getReferralPercentage() public view returns(uint256){
        return referralPercentage;
    }
    function setReferralPercentage(uint256 newReferralPercentage) external{
        require(owner==msg.sender,"Only owner");
        referralPercentage=newReferralPercentage;
    }
    function setMaxPromoCodesPerUser(uint256 newMax) external{
        require(owner==msg.sender,"Only owner");
        maxPromoCodesPerUser=newMax;
    }
    
    /// @notice Utility function used to fetch the address that created a specific promo code
    /// @param promo_code The promo code
    function findReferrer(string calldata promo_code)public view returns(address){

        if(bytes(promo_code).length==0){//No referral code
            return address(0);
        }

        return promo_code_ownership[promo_code];
    }
    /// @notice Utility function used to fetch the owner of the affiliate link that a user used when signing up (if any)
    /// @param user The user
    function getAffiliateOwner(address user) public view returns(address){
        return affiliate_link[user];
    }
    /// @notice Utility function used to fetch all the promo codes created by the user
    /// @param user The user
    function fetchAllPromoCodesOwnedByUser(address user)public view returns(string[] memory){
        return all_promo_codes_owned_by_user[user];
    }

}