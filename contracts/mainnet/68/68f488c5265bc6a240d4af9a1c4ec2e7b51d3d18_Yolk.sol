// SPDX-License-Identifier: MIT

//$YOLK is NOT an investment and has NO economic value. 
//It will be earned by active holding within the Hatchlingz ecosystem. 


pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Context.sol";


interface IHatchlingz {
    function _walletBalanceOfLegendary(address owner) external view returns (uint256);
    function _walletBalanceOfRare(address owner) external view returns (uint256);
    function _walletBalanceOfCommon(address owner) external view returns (uint256);
}

contract Yolk is ERC20, Ownable {

    IHatchlingz public Hatchlingz;

    uint256 constant public LEGENDARY_RATE = 10 ether;
    uint256 constant public RARE_RATE = 5 ether;
    uint256 constant public COMMON_RATE = 2 ether;
    uint256 constant public EndTime = 1742011200; // 2025-03-15 04:00:00
    uint256 constant public initialYOLKAmount = 1000000 ether;
    
    bool rewardPaused = false;
    bool initialYOLKComplete = false;

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;
    mapping(address => bool) public allowedAddresses;

    constructor(address HatchlingzAddress) ERC20("Yolk", "YOLK") {
        Hatchlingz = IHatchlingz(HatchlingzAddress);
    }
    
    //#region ONLYOWNER
    function setHatchlingz(address hatchlingzAddress) external onlyOwner {
        Hatchlingz = IHatchlingz(hatchlingzAddress);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setAllowedAddresses(address _address, bool _access) public onlyOwner {
        allowedAddresses[_address] = _access;
    }

    function toggleReward() external onlyOwner {
        rewardPaused = !rewardPaused;
    }
    //#endRegion ONLYOWNER

    function updateReward(address from, address to) public {
        require(msg.sender == address(Hatchlingz) || allowedAddresses[msg.sender]);

        if(lastUpdate[from] == 0) {
            lastUpdate[from] = block.timestamp;
        }
        
        if(from != address(0)) {
            rewards[from] += getPendingReward(from);
            lastUpdate[from] = block.timestamp;
        }

        if(to != address(0)) {
            rewards[to] += getPendingReward(to);
            lastUpdate[to] = block.timestamp;
        }
    }

    function claimReward() external {
        require(!rewardPaused, "Claiming reward has been paused."); 
        _mint(msg.sender, rewards[msg.sender] + getPendingReward(msg.sender));
        rewards[msg.sender] = 0;
        lastUpdate[msg.sender] = block.timestamp;
    }

    function initialYOLK() external onlyOwner {
        require(!initialYOLKComplete, "Initial YOLK already claimed");
        _mint(msg.sender, initialYOLKAmount);
        initialYOLKComplete = true;
    }

    function burn(address user, uint256 amount) external {
        require(allowedAddresses[msg.sender] || msg.sender == address(Hatchlingz), "Address does not have permission to burn.");

     
            if (getTotalClaimable(user) >= amount) {
                updateReward(user, address(0));
                rewards[user] = rewards[user] - amount;
            } else if (getTotalClaimable(user) < amount) {
                updateReward(user, address(0));
                uint256 credit = amount - rewards[user];
                rewards[user] = 0;
                _burn(user, credit);
            }
      
    }

    function getTotalClaimable(address user) public view returns(uint256) {
        return rewards[user] + getPendingReward(user);
    }

    function getPendingReward(address user) internal view returns(uint256) {
        uint256 EndOrCurrentTime = block.timestamp > EndTime ? EndTime : block.timestamp;
        uint256 EndOrUpdateTime = lastUpdate[user] > EndTime ? EndTime : lastUpdate[user];

        return (Hatchlingz._walletBalanceOfCommon(user) * COMMON_RATE * (EndOrCurrentTime - EndOrUpdateTime) / 86400)
                + (Hatchlingz._walletBalanceOfRare(user) * RARE_RATE * (EndOrCurrentTime - EndOrUpdateTime) / 86400)
                + (Hatchlingz._walletBalanceOfLegendary(user) * LEGENDARY_RATE * (EndOrCurrentTime - EndOrUpdateTime) / 86400);
    }
}