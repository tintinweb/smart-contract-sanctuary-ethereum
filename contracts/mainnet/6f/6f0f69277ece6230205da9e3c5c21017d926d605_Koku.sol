// SPDX-License-Identifier: unlicensed
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.13;

//import "hardhat/console.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

abstract contract ERC721 {
    // This doesn't have to match the real contract name. Call it what you like.
    function tokensOfOwner(address _owner) public view virtual returns (uint256[] memory);
    function ownerOf(uint256 tokenId) public view virtual returns (address);
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

    function claimContractsReward(address[] calldata _contracts) public  {
        require(!pause, "Rewards are paused");

        uint256 reward;
        uint256 timeStamp = block.timestamp;

        for(uint i; i < _contracts.length; i++)
        {
            (uint256[] memory tokens,uint256[] memory rewards) = getTokensAndClaimable(_contracts[i], msg.sender);
            for (uint256 j; j < tokens.length; j++)
            {
                reward += rewards[j];
                contractsLastUpdated[_contracts[i]][tokens[j]] = timeStamp;
            }
        }
        
        require(reward > 0, "None to claim");
        emit RewardPaid(msg.sender, reward);
    }

    function claimContractReward(address _contract) public onlyOwnedContracts(_contract) {
        require(!pause, "Rewards are paused");

        uint256 reward;
        uint256 timeStamp = block.timestamp;
        (uint256[] memory tokens,uint256[] memory rewards) = getTokensAndClaimable(_contract, msg.sender);

        for (uint256 i; i < tokens.length; i++) 
        {
            reward += rewards[i];
            contractsLastUpdated[_contract][tokens[i]] = timeStamp;
        }

        require(reward > 0, "None to claim");
        emit RewardPaid(msg.sender, reward);
    }

    function claimTokenReward(address _contract, uint256 _token) onlyOwnedContracts(_contract) public {
        require(!pause, "Rewards are paused");

        require(ERC721(_contract).ownerOf(_token) == msg.sender, "Wrong token owner");

        uint256 reward = getTokenClaimable(_contract, _token);
        contractsLastUpdated[_contract][_token] = block.timestamp;

        require(reward > 0, "None to claim");
        emit RewardPaid(msg.sender, reward);
    }
    
    function claimTokensReward(address _contract, uint256[] calldata _tokens) public onlyOwnedContracts(_contract){
        require(!pause, "Rewards are paused");
        
        uint256 total;
        uint256 reward;
        uint256 time = block.timestamp;
        
        for (uint256 i; i < _tokens.length; i++) 
        {
            require(ERC721(_contract).ownerOf(_tokens[i]) == msg.sender, "Not Owner");
            reward = getTokenClaimable(_contract, _tokens[i]);
            if (reward > 0)
            {
                total += reward;
                contractsLastUpdated[_contract][_tokens[i]] = time;
            }
        }
        require(total > 0, "None to claim");
        emit RewardPaid(msg.sender, total);
    }

    function getTokenClaimable( address _contract, uint256 _token) public view returns (uint256) 
    {       
        uint256 lastDate = (contractsLastUpdated[_contract][_token] > contractsRewardStart[_contract]) ? contractsLastUpdated[_contract][_token] : contractsRewardStart[_contract];
        uint256 rewardPeriods = (block.timestamp - lastDate) / contractsRewardInterval[_contract] * contractsRewardRate[_contract];
        return (rewardPeriods * contractsRewardRate[_contract]);
    }

    function getContractClaimable(address _contract, address _user) public view onlyOwnedContracts(_contract) returns (uint256) {

        uint256 time = block.timestamp;
        //Get Wallet of owner

        uint256[] memory wallet = ERC721(_contract).tokensOfOwner(_user);
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

    function getContractsClaimable(address[] calldata _contracts, address _user) public view returns (uint256) {

        uint256 claimableRewards;
        for(uint i; i < _contracts.length; i++) {
            claimableRewards += getContractClaimable(_contracts[i], _user);
        }

        return claimableRewards;
    }
    
    function getTokensAndClaimable( address _contract, address _user ) public onlyOwnedContracts(_contract) view returns (uint256[] memory, uint256[] memory)
    {
        uint256 time = block.timestamp;
        uint256[] memory wallet = ERC721(_contract).tokensOfOwner(_user);
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