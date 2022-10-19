/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// SPDX-License-Identifier: MIT
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


interface IERC20 {
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
}

// AutomationCompatible.sol imports the functions from both ./AutomationBase.sol and
// ./interfaces/AutomationCompatibleInterface.sol
interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

contract Staking is AutomationCompatibleInterface {

    AggregatorV3Interface internal priceFeed;

    using SafeMath for uint;

    IERC20 public contractSAWA;

    uint public percent = 30; // Percent in year
    uint public totalStaked;
    address public owner;
    mapping (address => uint) public countTokenStaked;
    mapping (address => uint) public countTimeStaked;

    // Chainlink
    mapping(address => bool) public autoReward;
    mapping(address => uint) public autoRewardSum;
    mapping(address => uint) public rewardListId;
    address[] public rewardListAddresses;

    uint[] public arr;// test
    uint public priceLink;
    address public contractLinkPrice;

     /**
     * Network: Goerli
     * Aggregator: LINK/USD
     * Address: 0xb4c4a493AB6356497713A78FFA6c60FB53517c63
     */
    constructor() {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(0xb4c4a493AB6356497713A78FFA6c60FB53517c63);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function stake(uint _amount) public {
        uint _balance = contractSAWA.balanceOf(msg.sender);
        uint _profit = getProfit();

        // Auto reinvest
        if (_profit > 0) {
            reinvest();
        }

        // Adding SAWA to the staking 
        require(_amount <= _balance, "Balance SAWA is low");
        contractSAWA.transferFrom(msg.sender, address(this), _amount);
        countTokenStaked[msg.sender] = SafeMath.add(countTokenStaked[msg.sender], _amount);
        countTimeStaked[msg.sender] = block.timestamp;
        totalStaked = SafeMath.add(totalStaked, _amount);
    }

    function reinvest() public {
        uint _profit = getProfit();
        require(_profit > 0, "Profit eqel zero");
        countTimeStaked[msg.sender] = block.timestamp;
        countTokenStaked[msg.sender] = SafeMath.add(countTokenStaked[msg.sender], _profit);
        totalStaked = totalStaked + _profit; 
    }

    function getProfit() view private returns (uint) {
        uint _profitInSec = ((countTokenStaked[msg.sender] / 100 * percent) / 31536000);
        uint _profit = _profitInSec * ((block.timestamp - countTimeStaked[msg.sender]));
        return _profit;
    }

    function getProfitAddress(address _adr) view private returns (uint) {
        uint _profitInSec = ((countTokenStaked[_adr] / 100 * percent) / 31536000);
        uint _profit = _profitInSec * ((block.timestamp - countTimeStaked[_adr]));
        return _profit;
    }

    function withdrawProfit() public {
        uint _profit = getProfit();
        require(_profit > 0, "Profit eqel zero");
        countTimeStaked[msg.sender] = block.timestamp;
        contractSAWA.transfer(msg.sender, _profit);
    }

    function withdrawStakedSAWA(uint _count, uint _reinvestSwitcher) public {
        require(_count <= countTokenStaked[msg.sender], "Staked count is less then _count");
        uint _profit = getProfit();

        if (_reinvestSwitcher == 1) {
            //Withdraw staked amount and Reinvest profit
            countTimeStaked[msg.sender] = block.timestamp;
            countTokenStaked[msg.sender] = SafeMath.sub(countTokenStaked[msg.sender], _count) + _profit;

            contractSAWA.transfer( msg.sender, _count);

            totalStaked = SafeMath.sub(totalStaked, _count) + _profit;
        } else {
            //Withdraw staked amount + profit
            countTimeStaked[msg.sender] = block.timestamp;
            countTokenStaked[msg.sender] = SafeMath.sub(countTokenStaked[msg.sender], _count); 

            contractSAWA.transfer(msg.sender, SafeMath.add(_count, _profit));
            
            totalStaked = SafeMath.sub(totalStaked, _count);
        }
    }

    function setAutoReward(bool _val, uint sum) public {
        autoReward[msg.sender] = _val;

        if(_val == true) {
            rewardListAddresses.push(msg.sender);
            rewardListId[msg.sender] = rewardListAddresses.length - 1;
            autoRewardSum[msg.sender] = sum;
        } else {
            delete rewardListAddresses[rewardListId[msg.sender]];
        }
    }

    // Settings admin functions
    function setPercent(uint _percent) public onlyOwner {
        percent = _percent;
    }

    function setAddressContractSAWA(IERC20 _contractSAWA) public  onlyOwner {
        contractSAWA = _contractSAWA;
    }

    // CHAINLINK FUNCTIONS
    /* Returns the latest price */
    function getLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory performData) {
        uint _count;
        upkeepNeeded = false;

        for (uint i = 0; i < rewardListAddresses.length; i++) {
            address _adr = rewardListAddresses[i]; 
            uint _profit = getProfitAddress(_adr);

            if(autoRewardSum[_adr] > _profit) {
                _count++;
            }
        }
        
        uint[] memory indexes = new uint[](_count);
        uint indexCurrent;
       
        for (uint i = 0; i < rewardListAddresses.length; i++) {
            address _adr = rewardListAddresses[i]; 
            uint _profit = getProfitAddress(_adr);

            if(autoRewardSum[_adr] > _profit) {
                indexes[indexCurrent] = i;
                upkeepNeeded = true;
                indexCurrent++;
            }
        } 
        
        performData = abi.encode(indexes);
        return (upkeepNeeded, performData);
    }

    function performUpkeep(bytes calldata  performData ) external override {
        (uint[] memory indexes) = abi.decode(performData, (uint[]));

        arr = indexes;
    }

    function autoWithdrawProfit(address _adr) private {
        uint _profit = getProfitAddress(_adr);
        require(_profit > 0, "Profit eqel zero");
        countTimeStaked[_adr] = block.timestamp;
        contractSAWA.transfer(_adr, _profit);
    }

}