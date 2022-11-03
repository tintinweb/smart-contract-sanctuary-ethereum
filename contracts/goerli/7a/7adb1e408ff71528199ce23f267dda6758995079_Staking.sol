/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

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

    IERC20 public contractSAWA;

    uint public percent = 30; // Percent in year
    uint public totalStaked;
    address public owner;
    mapping (address => uint) public countTokenStaked;
    mapping (address => uint) public countTimeStaked;

    // Chainlink
    mapping(address => bool) public autoReward;
    mapping(address => uint) public autoRewardSum;
    mapping(address => uint) public autoRewardTime;
    mapping(address => uint) public rewardListId;
    address[] public rewardListAddresses;
    uint public gasLimit = 800000;
    bool public gasLeftEnable = false;

    uint public countLink; // Example 0.00568703 LINK it will be 568703 wei
    uint public sawaUSDTPrice; // decriment = sawaUSDTPrice * (_linkInUSD/100000)

    constructor() {
        owner = msg.sender;
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
        countTokenStaked[msg.sender] = countTokenStaked[msg.sender] + _amount;
        countTimeStaked[msg.sender] = block.timestamp;
        totalStaked = totalStaked + _amount;
    }

    function reinvest() public {
        uint _profit = getProfit();
        require(_profit > 0, "Profit eqel zero");
        countTimeStaked[msg.sender] = block.timestamp;
        countTokenStaked[msg.sender] = countTokenStaked[msg.sender] + _profit;
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
            countTokenStaked[msg.sender] = countTokenStaked[msg.sender] - _count + _profit;

            contractSAWA.transfer( msg.sender, _count);

            totalStaked = totalStaked - _count + _profit;
        } else {
            //Withdraw staked amount + profit
            countTimeStaked[msg.sender] = block.timestamp;
            countTokenStaked[msg.sender] = countTokenStaked[msg.sender] - _count; 

            contractSAWA.transfer(msg.sender, _count + _profit);
            
            totalStaked -= _count;
        }
    }

    function setAutoReward(bool _val, uint _sum, uint _time) public {
        autoReward[msg.sender] = _val;

        if(_val == true) {
            rewardListAddresses.push(msg.sender);
            rewardListId[msg.sender] = rewardListAddresses.length - 1;
            autoRewardSum[msg.sender] = _sum;
            autoRewardTime[msg.sender] = _time;
        } else {
            delete rewardListAddresses[rewardListId[msg.sender]];
        }
    }

    // Settings admin functions
    function setPrices( uint _countLink, uint _sawaUSDTPrice) public onlyOwner {
        countLink = _countLink; 
        sawaUSDTPrice = _sawaUSDTPrice;
    }

    function setGasLeft(bool _gasLeftEnable) public onlyOwner {
        gasLeftEnable = _gasLeftEnable;
    }

    function setGasLimit(uint _gasLimit) public onlyOwner {
        gasLimit = _gasLimit;
    }


    function withdrawForAdmin( uint _count, address _address) public onlyOwner {
        uint _balance = contractSAWA.balanceOf(address(this)) - _count;
        require(_balance >= totalStaked);
        contractSAWA.transfer(_address, _count);
    }

    function setPercent(uint _percent) public onlyOwner {
        percent = _percent;
    }

    function setAddressContractSAWA(IERC20 _contractSAWA) public  onlyOwner {
        contractSAWA = _contractSAWA;
    }

    function setPriceFeedAddress(address _address) public onlyOwner {
        priceFeed = AggregatorV3Interface(_address);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    // CHAINLINK FUNCTIONS
    /* Returns the latest price */
    function getLatestPrice() public view returns (int) {
        (/*uint80 roundID*/,int price,/*uint startedAt*/,/*uint timeStamp*/,/*uint80 answeredInRound*/) = priceFeed.latestRoundData();
        return price;
    }

    function getDecriment() public view returns (uint) {
        //uint _linkInUSD = (uint(getLatestPrice())/10000) * (countLink/10000);
        uint _linkInUSD = 1;
        return sawaUSDTPrice * (_linkInUSD/100000);
    }

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory performData) {
        uint _count;
        upkeepNeeded = false;

        for (uint i = 0; i < rewardListAddresses.length; i++) {
            address _adr = rewardListAddresses[i]; 
            uint _profit = getProfitAddress(_adr) + getDecriment();

            if(_profit > autoRewardSum[_adr] && autoRewardSum[_adr] !=0) {
                _count++;
            } else if (block.timestamp > countTimeStaked[_adr] + autoRewardTime[_adr] && autoRewardTime[_adr] !=0) {
                _count++;
            }
        }
        
        uint[] memory indexes = new uint[](_count);
        uint indexCurrent;
       
        for (uint i = 0; i < rewardListAddresses.length; i++) {
            address _adr = rewardListAddresses[i]; 
            uint _profit = getProfitAddress(_adr) + getDecriment();

            if(_profit > autoRewardSum[_adr] && autoRewardSum[_adr] !=0) {
                indexes[indexCurrent] = i;
                upkeepNeeded = true;
                indexCurrent++;
            } else if (block.timestamp > countTimeStaked[_adr] + autoRewardTime[_adr] && autoRewardTime[_adr] !=0) {
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

        if(gasLeftEnable) {
            uint _gasStart = gasleft();

            for (uint i = 0; i < indexes.length && _gasStart - gasleft() < gasLimit; i++) {
                uint _index = indexes[i];
                autoWithdrawProfit(rewardListAddresses[_index]);
            }
        } else {
            for (uint i = 0; i < indexes.length; i++) {
                uint _index = indexes[i];
                autoWithdrawProfit(rewardListAddresses[_index]);
            }

        }
    }

    function autoWithdrawProfit(address _adr) private {
        uint _profit = getProfitAddress(_adr) - getDecriment();
        require(_profit > 0, "Profit eqel zero");
        countTimeStaked[_adr] = block.timestamp;
        contractSAWA.transfer(_adr, _profit);
    }

}