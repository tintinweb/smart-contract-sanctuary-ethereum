// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AlphaLocker.sol";

contract DevAlphaDistributor is Ownable {
    using SafeMath for uint256;

    IERC20 public alpha;
    AlphaLocker public alphaLocker;
    address public devWallet;
    address public marketingAndGrowthWallet;

    uint256 public devSharePercent;
    uint256 public marketingAndGrowthSharePercent;

    event WalletUpdated(string wallet, address indexed user, address newAddr);
    event DistributionUpdated(uint devSharePercent, uint marketingAndGrowthSharePercent);

    constructor (
        IERC20 _alpha,
        AlphaLocker _alphaLocker,
        address _devWallet,
        address _marketingAndGrowthWallet
    )  {
        require(address(_alpha) != address(0), "_alpha is a zero address");
        require(address(_alphaLocker) != address(0), "_alphaLocker is a zero address");
        alpha = _alpha;
        alphaLocker = _alphaLocker;
        devWallet = _devWallet;
        marketingAndGrowthWallet = _marketingAndGrowthWallet;

        devSharePercent = 80;
        marketingAndGrowthSharePercent = 20;
    }

    function alphaBalance() external view returns(uint) {
        return alpha.balanceOf(address(this));
    }

    function setDevWallet(address _devWallet)  external onlyOwner {
        devWallet = _devWallet;
        emit WalletUpdated("Dev Wallet", msg.sender, _devWallet);
    }

    function setMarketingAndGrowthWallet(address _marketingAndGrowthWallet)  external onlyOwner {
        marketingAndGrowthWallet = _marketingAndGrowthWallet;
        emit WalletUpdated("Marketing and Growth Wallet", msg.sender, _marketingAndGrowthWallet);
    }

    function setWalletDistribution(uint _devSharePercent, uint _marketingAndGrowthSharePercent)  external onlyOwner {
        require(_devSharePercent.add(_marketingAndGrowthSharePercent) == 100, "distributor: Incorrect percentages");
        devSharePercent = _devSharePercent;
        marketingAndGrowthSharePercent = _marketingAndGrowthSharePercent;
        emit DistributionUpdated(_devSharePercent, _marketingAndGrowthSharePercent);
    }

    function distribute(uint256 _total) external onlyOwner {
        require(_total > 0, "No ALPHA to distribute");

        uint devWalletShare = _total.mul(devSharePercent).div(100);
        uint marketingAndGrowthWalletShare = _total.sub(devWalletShare);

        require(alpha.transfer(devWallet, devWalletShare), "transfer: devWallet failed");
        require(alpha.transfer(marketingAndGrowthWallet, marketingAndGrowthWalletShare), "transfer: marketingAndGrowthWallet failed");
    }

    // funtion to claim the locked tokens for devAlphaDistributor, which will transfer the locked tokens for dev to devAddr after the devLockingPeriod
    function claimLockedTokens(uint256 r) external onlyOwner {

        alphaLocker.claimAll(r);
    }
    // Update alphaLocker address by the owner.
    function alphaLockerUpdate(address _alphaLocker) public onlyOwner {
        alphaLocker = AlphaLocker(_alphaLocker);
    }
}