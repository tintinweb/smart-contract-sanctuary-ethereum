/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



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





contract WIX_StakingDAPP  {

    using SafeMath for uint256;
   string public name = "WIX STAKING DAPP";
   address public owner ;
   address public walletForTax ;
    IERC20  public WIX ;
  mapping(address => bool) public hasStaked;
    address[] public stakers;


  uint256 public Plan1 = 7 days;  
  uint256 public Plan2 =  14 days;  
  uint256 public Plan3 = 30 days;  
uint256 public Plan4 =  60 days;  
uint256 public Plan5 = 90 days;  
uint256 public Plan6 = 180 days;  

uint256 public totalStakedOfPlan1;
uint256 public totalStakedOfPlan2;
uint256 public totalStakedOfPlan3;
uint256 public totalStakedOfPlan4;
uint256 public totalStakedOfPlan5;
uint256 public totalStakedOfPlan6;
  
  
 uint256 public totalStakedOfPlan1Apy = 50; // 0.5%;
 uint256 public totalStakedOfPlan2Apy = 100; // 1%;
 uint256 public totalStakedOfPlan3Apy = 300; // 3%;
 uint256 public totalStakedOfPlan4Apy = 500; // 5%;
 uint256 public totalStakedOfPlan5Apy = 800; // 8%;
  uint256 public totalStakedOfPlan6Apy = 1500; // 15%;
  uint256 public taxUnstake = 1800; // 18%; 18//


mapping(address => uint256) public stakingBalancePlan1;
mapping(address => uint256) public stakingBalancePlan2;
mapping(address => uint256) public stakingBalancePlan3;
mapping(address => uint256) public stakingBalancePlan4;
mapping(address => uint256) public stakingBalancePlan5;
mapping(address => uint256) public stakingBalancePlan6;

mapping(address => uint256) public stakingStartTime1;
mapping(address => uint256) public stakingStartTime2;
mapping(address => uint256) public stakingStartTime3;
mapping(address => uint256) public stakingStartTime4;
mapping(address => uint256) public stakingStartTime5;
mapping(address => uint256) public stakingStartTime6;



 constructor(IERC20 _TokenAdress , address walletForUnstakeTax ) public  {
        WIX  = _TokenAdress;
        owner = msg.sender;
        walletForTax = walletForUnstakeTax;
    }




      function stakeTokens(uint256 _amount , uint256 _plan ) public {
        //must be more than 0
        require(_amount > 0, "amount cannot be 0");

        //User adding test tokens
        WIX.transferFrom(msg.sender, address(this), _amount);

        if(_plan == Plan1  ){

            totalStakedOfPlan1 = totalStakedOfPlan1 + _amount;
            stakingBalancePlan1[msg.sender] = stakingBalancePlan1[msg.sender] + _amount;
            stakingStartTime1[msg.sender]= block.timestamp;

        }
        if(_plan == Plan2  ){

            totalStakedOfPlan2 = totalStakedOfPlan2 + _amount;
            stakingBalancePlan2[msg.sender] = stakingBalancePlan2[msg.sender] + _amount;
             stakingStartTime2[msg.sender]= block.timestamp;

        }
        if(_plan == Plan3  ){

            totalStakedOfPlan3 = totalStakedOfPlan3 + _amount;
             stakingBalancePlan3[msg.sender] = stakingBalancePlan3[msg.sender] + _amount;
              stakingStartTime3[msg.sender]= block.timestamp;

        }

         if(_plan == Plan4  ){

            totalStakedOfPlan4 = totalStakedOfPlan4 + _amount;
             stakingBalancePlan4[msg.sender] = stakingBalancePlan4[msg.sender] + _amount;
              stakingStartTime4[msg.sender]= block.timestamp;

        }

         if(_plan == Plan5  ){

            totalStakedOfPlan5 = totalStakedOfPlan5 + _amount;
             stakingBalancePlan5[msg.sender] = stakingBalancePlan5[msg.sender] + _amount;
              stakingStartTime5[msg.sender]= block.timestamp;

        }

          if(_plan == Plan6  ){

            totalStakedOfPlan6 = totalStakedOfPlan6 + _amount;
             stakingBalancePlan6[msg.sender] = stakingBalancePlan6[msg.sender] + _amount;
              stakingStartTime6[msg.sender]= block.timestamp;

        }

        //checking if user staked before or not, if NOT staked adding to array of stakers
        if (!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }

        //updating staking status
        
        hasStaked[msg.sender] = true;
    }




    function unstakeTokens(uint256 _plan) public {

        if(_plan == Plan1  ){

    require(stakingStartTime1[msg.sender] + 7 days < block.timestamp , "plase try after staking  Time period hours");
    uint256 _amount = stakingBalancePlan1[msg.sender];
        WIX.transfer(msg.sender, _amount);

        totalStakedOfPlan1 = totalStakedOfPlan1 - _amount;
        stakingBalancePlan1[msg.sender] = stakingBalancePlan1[msg.sender] - _amount;
        stakingStartTime1[msg.sender]= 0;

        }
        if(_plan == Plan2  ){

            require(stakingStartTime2[msg.sender] + 14 days < block.timestamp , "plase try after staking  Time period hours");
            uint256 _amount = stakingBalancePlan2[msg.sender];
            WIX.transfer(msg.sender, _amount);
             totalStakedOfPlan2 = totalStakedOfPlan2 - _amount;
            stakingBalancePlan2[msg.sender] =  stakingBalancePlan2[msg.sender] - _amount;
            stakingStartTime2[msg.sender]= 0;
        }
        if(_plan == Plan3  ){

            require(stakingStartTime3[msg.sender] + 30 days < block.timestamp , "plase try after staking  Time period hours");
            uint256 _amount = stakingBalancePlan3[msg.sender];
            WIX.transfer(msg.sender, _amount);
             totalStakedOfPlan3 = totalStakedOfPlan3 - _amount;
            stakingBalancePlan3[msg.sender] =  stakingBalancePlan3[msg.sender] - _amount;
            stakingStartTime3[msg.sender]= 0;

        }

          if(_plan == Plan4  ){

            require(stakingStartTime4[msg.sender] + 60 days < block.timestamp , "plase try after staking  Time period hours");
            uint256 _amount = stakingBalancePlan4[msg.sender];
            WIX.transfer(msg.sender, _amount);
             totalStakedOfPlan4 = totalStakedOfPlan4 - _amount;
            stakingBalancePlan4[msg.sender] =  stakingBalancePlan4[msg.sender] - _amount;
            stakingStartTime4[msg.sender]= 0;

        }

          if(_plan == Plan5 ){

            require(stakingStartTime5[msg.sender] + 90 days < block.timestamp , "plase try after staking  Time period hours");
            uint256 _amount = stakingBalancePlan5[msg.sender];
            WIX.transfer(msg.sender, _amount);
             totalStakedOfPlan5 = totalStakedOfPlan5 - _amount;
            stakingBalancePlan5[msg.sender] =  stakingBalancePlan5[msg.sender] - _amount;
            stakingStartTime5[msg.sender]= 0;

        }

          if(_plan == Plan6 ){

            require(stakingStartTime6[msg.sender] + 180 days < block.timestamp , "plase try after staking  Time period hours");
            uint256 _amount = stakingBalancePlan6[msg.sender];
            WIX.transfer(msg.sender, _amount);
             totalStakedOfPlan6 = totalStakedOfPlan6 - _amount;
            stakingBalancePlan6[msg.sender] =  stakingBalancePlan6[msg.sender] - _amount;
            stakingStartTime6[msg.sender]= 0;

        }

    }





 function unstakeTokensBeforeTime(uint256 _plan) public  {

        if(_plan == Plan1  ){

    require(stakingStartTime1[msg.sender] + 7 days > block.timestamp , "plase try before staking  Time period hours");
    uint256 _amount = stakingBalancePlan1[msg.sender];

    uint256 amounttax =   _amount.mul(taxUnstake).div(10000);
    uint256 amountForSend = _amount.sub(amounttax);
    
        WIX.transfer(walletForTax, _amount);
        WIX.transfer(msg.sender, amountForSend);

        totalStakedOfPlan1 = totalStakedOfPlan1 - _amount;
        stakingBalancePlan1[msg.sender] = stakingBalancePlan1[msg.sender] - _amount;
        stakingStartTime1[msg.sender]= 0;

        }
        if(_plan == Plan2  ){

            require(stakingStartTime2[msg.sender] + 14 days > block.timestamp , "plase try before staking  Time period hours");
            uint256 _amount = stakingBalancePlan2[msg.sender];
            uint256 amounttax =   _amount.mul(taxUnstake).div(10000);
             uint256 amountForSend = _amount.sub(amounttax);
    
               WIX.transfer(walletForTax, _amount);
               WIX.transfer(msg.sender, amountForSend);

             totalStakedOfPlan2 = totalStakedOfPlan2 - _amount;
            stakingBalancePlan2[msg.sender] =  stakingBalancePlan2[msg.sender] - _amount;
            stakingStartTime2[msg.sender]= 0;
        }
        if(_plan == Plan3  ){

            require(stakingStartTime3[msg.sender] + 30 days > block.timestamp , "plase try before staking  Time period hours");
            uint256 _amount = stakingBalancePlan3[msg.sender];
            uint256 amounttax =   _amount.mul(taxUnstake).div(10000);
            uint256 amountForSend = _amount.sub(amounttax);
    
           WIX.transfer(walletForTax, _amount);
            WIX.transfer(msg.sender, amountForSend);

             totalStakedOfPlan3 = totalStakedOfPlan3 - _amount;
            stakingBalancePlan3[msg.sender] =  stakingBalancePlan3[msg.sender] - _amount;
            stakingStartTime3[msg.sender]= 0;

        }

          if(_plan == Plan4  ){

            require(stakingStartTime4[msg.sender] + 60 days > block.timestamp , "plase try before staking  Time period hours");
            uint256 _amount = stakingBalancePlan4[msg.sender];
             uint256 amounttax =   _amount.mul(taxUnstake).div(10000);
             uint256 amountForSend = _amount.sub(amounttax);
    
             WIX.transfer(walletForTax, _amount);
             WIX.transfer(msg.sender, amountForSend);
             totalStakedOfPlan4 = totalStakedOfPlan4 - _amount;
            stakingBalancePlan4[msg.sender] =  stakingBalancePlan4[msg.sender] - _amount;
            stakingStartTime4[msg.sender]= 0;

        }

          if(_plan == Plan5 ){

            require(stakingStartTime5[msg.sender] + 90 days > block.timestamp , "plase try before staking  Time period hours");
            uint256 _amount = stakingBalancePlan5[msg.sender];
              uint256 amounttax =   _amount.mul(taxUnstake).div(10000);
               uint256 amountForSend = _amount.sub(amounttax);
    
               WIX.transfer(walletForTax, _amount);
             WIX.transfer(msg.sender, amountForSend);
             totalStakedOfPlan5 = totalStakedOfPlan5 - _amount;
            stakingBalancePlan5[msg.sender] =  stakingBalancePlan5[msg.sender] - _amount;
            stakingStartTime5[msg.sender]= 0;

        }

          if(_plan == Plan6 ){

            require(stakingStartTime6[msg.sender] + 180 days > block.timestamp , "plase try before staking  Time period hours");
            uint256 _amount = stakingBalancePlan6[msg.sender];
              uint256 amounttax =   _amount.mul(taxUnstake).div(10000);
               uint256 amountForSend = _amount.sub(amounttax);
    
               WIX.transfer(walletForTax, _amount);
               WIX.transfer(msg.sender, amountForSend);
             totalStakedOfPlan6 = totalStakedOfPlan6 - _amount;
            stakingBalancePlan6[msg.sender] =  stakingBalancePlan6[msg.sender] - _amount;
            stakingStartTime6[msg.sender]= 0;

        }

    }



   function Reward(uint256 plan ) public {

  if(plan == Plan1  ){

    require(stakingStartTime1[msg.sender] + 7 days < block.timestamp , "plase try after staking  Time period hours");
     uint256 _amount = stakingBalancePlan1[msg.sender];
        uint interest = _amount.mul(totalStakedOfPlan1Apy).div(10000);
        WIX.transfer(msg.sender, interest);

   

        }
        if(plan == Plan2  ){

            require(stakingStartTime2[msg.sender] + 14 days < block.timestamp , "plase try after staking  Time period hours");
            uint256 _amount = stakingBalancePlan2[msg.sender];
            uint interest = _amount.mul(totalStakedOfPlan2Apy).div(10000);
             WIX.transfer(msg.sender, interest);
        }
        if(plan == Plan3  ){

            require(stakingStartTime3[msg.sender] + 30 days < block.timestamp , "plase try after staking  Time period hours");
              uint256 _amount = stakingBalancePlan3[msg.sender];
              uint interest = _amount.mul(totalStakedOfPlan3Apy).div(10000);
               WIX.transfer(msg.sender, interest);

        }

        if(plan == Plan4  ){

            require(stakingStartTime4[msg.sender] + 60 days < block.timestamp , "plase try after staking  Time period hours");
              uint256 _amount = stakingBalancePlan4[msg.sender];
              uint interest = _amount.mul(totalStakedOfPlan4Apy).div(10000);
               WIX.transfer(msg.sender, interest);

        }

        if(plan == Plan5  ){

            require(stakingStartTime5[msg.sender] + 90 days < block.timestamp , "plase try after staking  Time period hours");
              uint256 _amount = stakingBalancePlan5[msg.sender];
              uint interest = _amount.mul(totalStakedOfPlan5Apy).div(10000);
               WIX.transfer(msg.sender, interest);

        }

         if(plan == Plan6  ){

            require(stakingStartTime6[msg.sender] + 180 days < block.timestamp , "plase try after staking  Time period hours");
              uint256 _amount = stakingBalancePlan6[msg.sender];
              uint interest = _amount.mul(totalStakedOfPlan6Apy).div(10000);
               WIX.transfer(msg.sender, interest);

        }
      

    }


    function setPlans( uint256 _plan1 , uint256 _plan2 , uint256 _plan3 , uint256 _plan4 , uint256 _plan5 , uint256 _plan6) public {
        require(msg.sender == owner , "only Owner can run this function");
      
        Plan1 = _plan1;
        Plan2 = _plan2 ;
        Plan3 =  _plan3;
        Plan4 =  _plan4;
        Plan5 =  _plan5;
        Plan6 =  _plan6;

 
    }

      function setPlansApy( uint256 _APY1 , uint256 _APY2 , uint256 _APY3 ,  uint256 _APY4 ,  uint256 _APY5 ,  uint256 _APY6) public {
        require(msg.sender == owner , "only Owner can run this function");
        
        totalStakedOfPlan1Apy = _APY1;
        totalStakedOfPlan2Apy = _APY2;
        totalStakedOfPlan3Apy =  _APY3;
         totalStakedOfPlan4Apy =  _APY4;
        totalStakedOfPlan5Apy =  _APY5;
        totalStakedOfPlan6Apy =  _APY6;

 
    }

    function transferOwnership(address newOwner) public   {
        require(msg.sender == owner , "only Owner can run this function");
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
    
}