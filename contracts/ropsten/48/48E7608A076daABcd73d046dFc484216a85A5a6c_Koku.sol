// SPDX-License-Identifier: unlicensed
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.13;

//import "hardhat/console.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

abstract contract Contract721 {
    // This doesn't have to match the real contract name. Call it what you like.
    function tokensOfOwner(address _owner) public view virtual returns (uint256[] memory);
}

contract Koku is Ownable {
    using SafeMath for uint256;

    /**
    * @dev Throws if called with any other non-contract added.
    */
    modifier onlyOwnedContracts(address _contract) {
        require(contracts[_contract], "The rewarded contract must be added");
        _;
    }

    bool private pause = false;

    mapping (address => bool) public contracts;
    mapping (address => uint256) public contractsRewardStart;
    mapping (address => uint256) public contractsRewardRate;
    mapping (address => uint256) public contractsRewardInterval;
    mapping (address => mapping (uint256 => uint256)) public contractsLastUpdated;

    event RewardPaid(address indexed user, uint256 reward);

    constructor()
    {
    }

    function claimContractsReward(address[] calldata _contracts) public returns (uint256)  {
        require(!pause, "Rewards are paused");

        uint256 claimableRewards;
        uint256[] memory wallet;

        for(uint i; i < _contracts.length; i++) {
            wallet = Contract721(_contracts[i]).tokensOfOwner(
                msg.sender
            );
            claimableRewards += getContractClaimable(_contracts[i], msg.sender);
            for (uint256 j; j < wallet.length; j++) {
                contractsLastUpdated[_contracts[i]][wallet[j]] = block.timestamp;
            }
        }
        emit RewardPaid(msg.sender, claimableRewards);
        return claimableRewards;
    }

    function claimContractReward(address _contract) public onlyOwnedContracts(_contract) returns (uint256) {
        require(!pause, "Rewards are paused");

        uint256 reward = getContractClaimable(_contract, msg.sender);
        emit RewardPaid(msg.sender, reward);
        uint256[] memory wallet = Contract721(_contract).tokensOfOwner(msg.sender);
        for (uint256 i; i < wallet.length; i++) 
        {
            contractsLastUpdated[_contract][wallet[i]] = block.timestamp;
        }

        return reward;
    }

    function claimTokenReward(address _contract, uint256 _token) public onlyOwnedContracts(_contract) returns (uint256) {
        require(!pause, "Rewards are paused");
        
        uint256[] memory wallet = Contract721(_contract).tokensOfOwner(msg.sender);
        
        uint256 reward;

        for (uint256 i; i < wallet.length; i++) 
        {
            if (_token == wallet[i])
            {
                reward = getTokenClaimable(_contract, _token);
                emit RewardPaid(msg.sender, reward);
                contractsLastUpdated[_contract][wallet[i]] = block.timestamp;
                return reward;
            }
        }
        return reward;
    }
    
    function claimTokensReward(address _contract, uint256[] calldata _tokens) public onlyOwnedContracts(_contract) returns (uint256) {
        require(!pause, "Rewards are paused");
        
        uint256[] memory wallet = Contract721(_contract).tokensOfOwner(msg.sender);
        
        uint256 reward;

        for (uint256 i; i < wallet.length; i++) 
        {
            for (uint256 j; j < _tokens.length; j++) 
            {
                if (wallet[i] == _tokens[j])
                {
                    reward = getTokenClaimable(_contract, wallet[i]);
                    contractsLastUpdated[_contract][wallet[i]] = block.timestamp;
                }
            }
        }
        emit RewardPaid(msg.sender, reward);
        return reward;
    }

    function getContractsClaimable(address[] calldata _contracts, address _user) public view returns (uint256) {

        uint256 claimableRewards;
        for(uint i; i < _contracts.length; i++) {
            claimableRewards += getContractClaimable(_contracts[i], _user);
        }

        return claimableRewards;
    }

    function getContractClaimable(address _contract, address _user) public view onlyOwnedContracts(_contract) returns (uint256) {

        uint256 time = block.timestamp;
        //Get Wallet of owner

        uint256[] memory wallet = Contract721(_contract).tokensOfOwner(_user);
        uint256 claimableRewards;

        for (uint256 i; i < wallet.length; i++) {
            if (contractsLastUpdated[_contract][wallet[i]] == 0) {
                claimableRewards += contractsRewardRate[_contract].mul(time.sub(contractsRewardStart[_contract])).div(contractsRewardInterval[_contract]);
            } else {
                claimableRewards += contractsRewardRate[_contract].mul(time.sub(contractsLastUpdated[_contract][wallet[i]])).div(contractsRewardInterval[_contract]);
            }
        }
        return claimableRewards;
    }

    function getTokenClaimable( address _contract, uint256 _token) public onlyOwnedContracts(_contract) view returns (uint256) 
    {
        uint256 time = block.timestamp;

        uint256 claimableRewards;
        
        if (contractsLastUpdated[_contract][_token] == 0) {
            claimableRewards += contractsRewardRate[_contract].mul(time.sub(contractsRewardStart[_contract])).div(contractsRewardInterval[_contract]);
        } else {
            claimableRewards += contractsRewardRate[_contract].mul(time.sub(contractsLastUpdated[_contract][_token])).div(contractsRewardInterval[_contract]);
        }

        return claimableRewards;
    }

    function getTokensAndClaimable( address _contract, address _user ) public onlyOwnedContracts(_contract) view returns (uint256[] memory, uint256[] memory)
    {
        uint256 time = block.timestamp;
        uint256[] memory wallet = Contract721(_contract).tokensOfOwner(_user);
        uint256[] memory claimableRewards = new uint256[](wallet.length);

        for (uint256 i; i < wallet.length; i++) 
        {
            if (contractsLastUpdated[_contract][wallet[i]] == 0) {
                claimableRewards[i] = contractsRewardRate[_contract].mul(time.sub(contractsRewardStart[_contract])).div(contractsRewardInterval[_contract]);
            } else {
                claimableRewards[i] = contractsRewardRate[_contract].mul(time.sub(contractsLastUpdated[_contract][wallet[i]])).div(contractsRewardInterval[_contract]);
            }
        }

        return (wallet, claimableRewards);
    }

    function getContractStart( address _contract) public onlyOwnedContracts(_contract) view returns (uint256) 
    {
        return contractsRewardStart[_contract];
    }

    function getContractRate( address _contract) public onlyOwnedContracts(_contract) view returns (uint256) 
    {
        return contractsRewardRate[_contract];
    }
   
    function getContractInterval( address _contract) public onlyOwnedContracts(_contract) view returns (uint256) 
    {
        return contractsRewardInterval[_contract];
    }
 
    function setContract( address _contract, uint256 _start, uint256 _rate, uint256 _interval) public onlyOwner
    {
        contracts[_contract] = true;
        contractsRewardStart[_contract] = _start; //ex. 1651795200 May 6, 2022 12:00:00
        contractsRewardRate[_contract] = _rate; //ex. 1 = 1 koku
        contractsRewardInterval[_contract] = _interval; //86400 = 1 day
    }
     
    function clearContract( address _contract) public onlyOwner
    {
        contracts[_contract] = false;
    }

    function setContractRewardStart(address _contract, uint256 _start) public onlyOwner onlyOwnedContracts(_contract) {
        //ex. 1651795200 May 6, 2022 12:00:00
        contractsRewardStart[_contract] = _start;
    }
    
    function setContractRewardRate(address _contract, uint256 _rate) public onlyOwner onlyOwnedContracts(_contract) {
        //ex. 1 = 1 koku
        contractsRewardRate[_contract] = _rate;
    }
        
    function setContractRewardInterval(address _contract, uint256 _interval) public onlyOwner onlyOwnedContracts(_contract) {
        //86400 = 1 day
        contractsRewardInterval[_contract] = _interval;
    }

    function setRewardsPause(bool _pause) public onlyOwner {
        pause = _pause;
    }
}