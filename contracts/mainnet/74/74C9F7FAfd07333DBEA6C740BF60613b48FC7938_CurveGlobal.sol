/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;



// Part: IConvexDeposit

interface IConvexDeposit {
    // deposit into convex, receive a tokenized deposit.  parameter to stake immediately (we always do this).
    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    // burn a tokenized deposit (Convex deposit tokens) to receive curve lp tokens back
    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);
    function poolLength() external
        view
        returns ( uint256);

    // give us info about a pool based on its pid
    function poolInfo(uint256)
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address,
            bool
        );
}

// Part: ISharerV4

interface ISharerV4{
    
    function setContributors(address, address[] memory, uint256[] memory) external;
}

// Part: IStrategy

interface IStrategy{
     function cloneStrategyConvex(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper,
        address _curveGlobal,
        uint256 _pid,
        address _tradeFactory
    ) external returns (address newStrategy);

    function setHealthCheck(address) external;
}

// Part: Registry

interface Registry{
    function newExperimentalVault(address token, address governance, address guardian, address rewards, string memory name, string memory symbol) external returns (address);
}

// Part: Vault

interface Vault{
    
    function setGovernance(address) external;
    function setManagement(address) external;
    function setDepositLimit(uint256) external;
    function addStrategy(address, uint, uint, uint, uint) external;
}

// File: CurveGlobal.sol

contract CurveGlobal{

    address owner = 0xFEB4acf3df3cDEA7399794D0869ef76A6EfAff52;
    Registry public registry = Registry(address(0x50c1a2eA0a861A967D9d0FFE2AE4012c2E053804));
    IConvexDeposit public convexDeposit = IConvexDeposit(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    address constant public sms = address(0x16388463d60FFE0661Cf7F1f31a7D658aC790ff7);
    address public ychad = address(0xFEB4acf3df3cDEA7399794D0869ef76A6EfAff52);
    address public devms = address(0x846e211e8ba920B353FB717631C015cf04061Cc9);
    address public treasury = address(0x93A62dA5a14C80f265DAbC077fCEE437B1a0Efde);
    address public keeper = address(0x736D7e3c5a6CB2CE3B764300140ABF476F6CFCCF);
    address public rewardsStrat = address(0xc491599b9A20c3A2F0A85697Ee6D9434EFa9f503);
    address public healthCheck = address(0xDDCea799fF1699e98EDF118e0629A974Df7DF012);
    address public tradeFactory = address(0x99d8679bE15011dEAD893EB4F5df474a4e6a8b29);

    address public stratImplementation;


    uint256 public keepCRV = 1000; // the percentage of CRV we re-lock for boost (in basis points).Default is 10%.
    uint256 public performanceFee = 1000;

    address[] public contributors;
    uint256[] public numOfShares;


    constructor() public {
        contributors = [address(0x8Ef63b525fceF7f8662D98F77f5C9A86ae7dFE09),address(0x03ebbFCc5401beef5B4A06c3BfDd26a75cB09A84),address(0x98AA6B78ed23f4ce2650DA85604ceD5653129A21),address(0xA0308730cE2a6E8C9309688433D46bb05260A816),address(0x16388463d60FFE0661Cf7F1f31a7D658aC790ff7)];
        numOfShares = [237,237,237,237,52];
    }
    function initialise(address _stratImplementation) public{
        require(stratImplementation == address(0));
        stratImplementation = _stratImplementation;
    }

    function setStratImplementation(address _stratImplementation) external {
        require(msg.sender == owner);
        stratImplementation = _stratImplementation;
    }
    function setHealthcheck(address _health) external {
        require(msg.sender == owner);
        healthCheck = _health;
    }
    function setStratRewards(address _rewards) external {
        require(msg.sender == owner);
        rewardsStrat = _rewards;
    }



    // Set the amount of CRV to be locked in Yearn's veCRV voter from each harvest. 
    function setKeepCRV(uint256 _keepCRV) external {
        require(msg.sender == owner);
        require(_keepCRV <= 10_000);
        keepCRV = _keepCRV;
    }

    function setPerfFee(uint256 _perf) external {
        require(msg.sender == owner);
        require(_perf <= 10_000);
        performanceFee = _perf;
    }

    function setOwner(address newOwner) external{
        require(msg.sender == owner);
        owner = newOwner;
    }

    function setDefaultRewards(address[] calldata _contributors, uint256[] calldata _numOfShares ) external{
        require(msg.sender == owner || msg.sender == sms);
        contributors = _contributors;
        numOfShares = _numOfShares;
    }

    function createNewCurveVaultAndStrat(uint256 _pid, uint256 _depositLimit) external returns (address vault, address strat){
            
        (address lptoken, , , , , ) = convexDeposit.poolInfo(_pid);

        vault = registry.newExperimentalVault(lptoken, address(this), devms, treasury, "", "");
        Vault(vault).setManagement(sms);
        Vault(vault).setGovernance(sms);
        Vault(vault).setDepositLimit(_depositLimit);
        
        strat = IStrategy(stratImplementation).cloneStrategyConvex(vault, sms, rewardsStrat, keeper,address(this), _pid, tradeFactory);
        ISharerV4(rewardsStrat).setContributors(strat, contributors, numOfShares);

        IStrategy(strat).setHealthCheck(healthCheck);

        Vault(vault).addStrategy(strat, 10_000, 0, type(uint256).max, performanceFee);
    }
}