// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IERC721.sol";

contract BFOOT is Ownable, ERC20 {

    IERC721 public bigFootNFT;

    mapping(address => uint256) bigFootAddressToAccumulatedBFOOTs; // accumulated bfoots before
    mapping(address => uint256) bigFootAddressToLastClaimedTimeStamp; // last time a claimed happened for a user

    uint256 public deployedTime = block.timestamp;
    uint256 public bigFootClaimEndTime = deployedTime;
    uint256 public bigFootClaimStart = deployedTime;

    uint256 public bigFootIssuanceRate = 5 * 10**5; // 10 per day
    uint256 public bigFootIssuancePeriod = 1 days;

    /** EVENTS */
    event setBigFootNFTEvent(address indexed slotieNFT);
    event ClaimedRewardFromBfoot(address indexed user, uint256 reward, uint256 timestamp);
    event AccumulatedRewardFromBfoot(address indexed user, uint256 reward, uint256 timestamp);
    event setBigFootIssuanceRateEvent(uint256 indexed issuanceRate);
    event setBigFootIssuancePeriodEvent(uint256 indexed issuancePeriod);
    event setBigFootClaimStartEvent(uint256 indexed slotieClaimStart);
    event setBigFootClaimEndTimeEvent(uint256 indexed slotieClaimEndTime);
    event setDeployTimeEvent(uint256 indexed deployTime);

    /** MODIFIERS */
    modifier bigFootCanClaim() {
        require(bigFootNFT.balanceOf(msg.sender) > 0, "NOT A BIGFOOT HOLDER");
        require(block.timestamp >= bigFootClaimStart, "BFOOT CLAIM LOCKED");
        require(address(bigFootNFT) != address(0), "BIGFOOT NFT NOT SET");
        _;
    }

    constructor(address _bigFootNFT) ERC20("BFOOT", "$BFOOT") Ownable() {
        _mint(msg.sender, 300000000 * 10**uint(decimals()));
        bigFootNFT = IERC721(_bigFootNFT);
    }

    /** OVERRIDE ERC-20 */
    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account);
    }

    function totalSupply() public view override returns (uint256) {
        return super.totalSupply();
    }

    function decimals() public view virtual override returns (uint8) {
        return 5;
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external onlyOwner {
        _burn(_from, _amount);
    }

    function setBigFootNFT(address newBigFootNFT) external onlyOwner {
        bigFootNFT = IERC721(newBigFootNFT);
        emit setBigFootNFTEvent(newBigFootNFT);
    }

    function setBigFootIssuanceRate(uint256 newBigFootIssuanceRate) external onlyOwner {
        bigFootIssuanceRate = newBigFootIssuanceRate;
        emit setBigFootIssuanceRateEvent(newBigFootIssuanceRate);
    }

    function setBigFootIssuancePeriod(uint256 newBigFootIssuancePeriod) external onlyOwner {
        bigFootIssuancePeriod = newBigFootIssuancePeriod;
        emit setBigFootIssuancePeriodEvent(newBigFootIssuancePeriod);
    }

    function setBigFootClaimEndTime(uint256 newBigFootClaimEndTime) external onlyOwner {
        bigFootClaimEndTime = newBigFootClaimEndTime;
        emit setBigFootClaimEndTimeEvent(newBigFootClaimEndTime);
    }

    function setBigFootClaimStart(uint256 newBigFootClaimStart) external onlyOwner {
        bigFootClaimStart = newBigFootClaimStart;
        emit setBigFootClaimStartEvent(newBigFootClaimStart);
    }

    function setDeployTime(uint256 newDeployTime) external onlyOwner {
        deployedTime = newDeployTime;
        emit setDeployTimeEvent(newDeployTime);
    }

    function _bigFootClaim(address recipient) internal {

        uint256 balance = bigFootNFT.balanceOf(recipient);
        uint256 lastClaimed = bigFootAddressToLastClaimedTimeStamp[recipient];  
        uint256 accumulatedBfoots = bigFootAddressToAccumulatedBFOOTs[recipient];
        uint256 currentTime = block.timestamp;

        if (currentTime >= bigFootClaimEndTime) {
            currentTime = bigFootClaimEndTime; // we can only claim up to bigFootClaimEndTime
        }

        if (deployedTime > lastClaimed) {
            lastClaimed = deployedTime; // we start from time of deployment
        } else if (lastClaimed == bigFootClaimEndTime) {
            lastClaimed = currentTime; // if we claimed all we set reward to zero
        }
        
        uint256 reward = (currentTime - lastClaimed) * bigFootIssuanceRate * balance / bigFootIssuancePeriod;

        if (currentTime >= bigFootClaimStart && accumulatedBfoots != 0) {
            reward = reward + accumulatedBfoots;
            delete bigFootAddressToAccumulatedBFOOTs[recipient];
        }

        bigFootAddressToLastClaimedTimeStamp[recipient] = currentTime;
        if (reward > 0) {            
            if (currentTime < bigFootClaimStart) {
                bigFootAddressToAccumulatedBFOOTs[recipient] = bigFootAddressToAccumulatedBFOOTs[recipient] + reward;
                emit AccumulatedRewardFromBfoot(recipient, reward, currentTime);
            } else {
                _transfer(owner(), recipient, reward);
                emit ClaimedRewardFromBfoot(recipient, reward, currentTime);
            }
        }            
    }

    function getBigFootBalance(address recipient) external view returns (uint256) {
        require(address(bigFootNFT) != address(0), "BIGFOOT NFT NOT SET");
        return bigFootNFT.balanceOf(recipient); 
    }

    function bigFootClaim() external bigFootCanClaim {
        _bigFootClaim(msg.sender);
    }

    function bigFootGetClaimableBalance(address recipient) external view returns (uint256) {
        require(address(bigFootNFT) != address(0), "BIGFOOT NFT NOT SET");

        uint256 balance = bigFootNFT.balanceOf(recipient);
        uint256 lastClaimed = bigFootAddressToLastClaimedTimeStamp[recipient];  
        uint256 accumulatedBfoots = bigFootAddressToAccumulatedBFOOTs[recipient];
        uint256 currentTime = block.timestamp;

        if (currentTime >= bigFootClaimEndTime) {
            currentTime = bigFootClaimEndTime;
        }

        if (deployedTime > lastClaimed) {
            lastClaimed = deployedTime;
        } else if (lastClaimed == bigFootClaimEndTime) {
            lastClaimed = currentTime;
        }
        
        uint256 reward = (currentTime - lastClaimed) * bigFootIssuanceRate * balance / bigFootIssuancePeriod;

        if (accumulatedBfoots != 0) {
            reward = reward + accumulatedBfoots;
        }

        return reward;
    }
}