/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

//SPDX-License-Identifier: NONE;

pragma solidity 0.8.7;

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)
/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
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


// TODO: just for testing / meeting
//import "hardhat/console.sol";

interface IGoerliWETH{
    function deposit() external payable;
    function withdraw(uint amount) external;
    function approve(address account, uint amount) external returns (bool);
    function allowance(address from, address to) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

interface IGoerli_aWETH{    
    function approve(address account, uint amount) external returns (bool);
    function allowance(address from, address to) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

interface IAaveLendingPoolGoerli{    
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external;    
}

interface IAaveWETHGatewayGoerli {
    function depositETH(address pool, address onBehalfOf, uint16 referralCode) external payable;
    function withdrawETH(address pool, uint256 amount, address to) external;
}

interface IDevUSDC {
    function mintTo(address receiver, uint256 amountIn6Dec) external;
    function balanceOf(address account) external view returns (uint256);
}

interface IAggregatorV3Interface {
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
   // TODO: just for testing / meeting
   function decimals() external view returns (uint8);
   function description() external view returns (string memory);
}

contract StakingContract is ReentrancyGuard{

    IGoerliWETH internal contractWETHonGoerli = IGoerliWETH(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);        
    IGoerli_aWETH internal aWETHonGoerli = IGoerli_aWETH(0x27B4692C93959048833f40702b22FE3578E77759);   
    IAggregatorV3Interface internal ethToUSDpriceFeedGoerli = IAggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    IAaveLendingPoolGoerli internal aaveLendingPoolGoerli = IAaveLendingPoolGoerli(0x368EedF3f56ad10b9bC57eed4Dac65B26Bb667f6);   
    IAaveWETHGatewayGoerli internal aaveWETHgatewayGoerli = IAaveWETHGatewayGoerli(0xd5B55D3Ed89FDa19124ceB5baB620328287b915d);
    IDevUSDC internal devUSDC;
    address thisStakingContractAddr;


    struct Stake {
        uint256 timestamp;
        uint256 amount;        
    }

    mapping(address => Stake) userStakes;

    constructor() {
        devUSDC = IDevUSDC(0x73ea53705A961400E3998168ca44a8b8cb40530F);    
        thisStakingContractAddr = address(this);
    }
    
    function getStakeAmount(address _user) public view returns (uint256) {
        return userStakes[_user].amount;
    }
   
    function getStakeTimestamp(address _user) public view returns (uint256) {
        return userStakes[_user].timestamp;
    }

    function getETHpriceGoerliInUSDCIn8Dec() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = ethToUSDpriceFeedGoerli.latestRoundData();
        return price;
    }


    function stake() external payable nonReentrant{
        require(userStakes[msg.sender].amount == 0, "You're already staking, but you can unstake and re-stake.");
        require(msg.value >= 5 ether, "Minimum staking amount is 5 ETH");

        //console.log(thisStakingContractAddr, "thisStakingContractAddr");
        //console.log(address(this), "(address(this)");

        //console.log(msg.value, "msg.value");
        aaveWETHgatewayGoerli.depositETH{value: msg.value}(address(aaveLendingPoolGoerli),thisStakingContractAddr,0);

        //aaveLendingPoolGoerli.supply(address(contractWETHonGoerli), msg.value, thisStakingContractAddr, 0);
        
        userStakes[msg.sender].timestamp = block.timestamp;
        userStakes[msg.sender].amount = msg.value;        

        //console.log(userStakes[msg.sender].amount, "userStakes[msg.sender].amount after STAKING");
    }

    function unstake() external nonReentrant{
        require(userStakes[msg.sender].amount != 0, "You're not staking at the moment." );
        
        uint256 stakingTimestamp = userStakes[msg.sender].timestamp;
        uint256 amountVar = userStakes[msg.sender].amount;

        //console.log(userStakes[msg.sender].amount, "userStakes[msg.sender].amount trying to UNSTAKE");
        
        userStakes[msg.sender].timestamp = 0;
        userStakes[msg.sender].amount = 0;
       
        //console.log("BEFORE approval for lendingpool to pull in aWETH that is owned by this contract:");
        //console.log(aWETHonGoerli.allowance(thisStakingContractAddr, address(aaveWETHgatewayGoerli)));

        require(aWETHonGoerli.approve(address(aaveWETHgatewayGoerli), amountVar), "aWETH approval to Aave lendingpool failed!");  

        //console.log("AFTER approval for lendingpool to pull in aWETH that is owned by this contract:");
        //console.log(aWETHonGoerli.allowance(thisStakingContractAddr, address(aaveWETHgatewayGoerli)));             

        aaveWETHgatewayGoerli.withdrawETH(address(aaveLendingPoolGoerli),amountVar,thisStakingContractAddr);

        
        // calculates the amount of time that funds were staked for, in full days
        uint256 unstakingTimestamp = block.timestamp;
        uint256 secondsStaked = (unstakingTimestamp - stakingTimestamp);
        //console.log(secondsStaked, "seconds Staked <=====================");

        uint256 daysStaked = secondsStaked / 60 / 60 / 24; // will automatically round down to full integer
        //console.log(daysStaked, "days Staked <=====================");

        //calculates ETH's value (Chainlink pricefeed)        
        uint256 priceETHtoUSDCin2Dec = uint256(getETHpriceGoerliInUSDCIn8Dec())/1000000;
        uint256 valueOfETHstakeInUSDCin2Dec = (priceETHtoUSDCin2Dec * amountVar);

        //console.log(priceETHtoUSDCin2Dec, "price ETH to USDC in Cents (2 decimals)<=====================");

        // calculates reward in USDC (10% of funds every 356 days)        
        uint256 rewardIn2Dec = (valueOfETHstakeInUSDCin2Dec * daysStaked * 274) / 1000000;

        devUSDC.mintTo(msg.sender, rewardIn2Dec);         
        
        (bool successETHtx, ) = msg.sender.call{value: amountVar}("");
        require(successETHtx, "ETH transfer failed.");
    }

    // TODO: just for testing / meeting
    function returnChainlinkUSDCDecimals()external view returns(uint8){
        return ethToUSDpriceFeedGoerli.decimals();
   
    } 
    // TODO: just for testing / meeting
    function returnChainlinkDescription()external view returns(string memory){
        return ethToUSDpriceFeedGoerli.description();
   
    } 
    
    receive() external payable {}
}