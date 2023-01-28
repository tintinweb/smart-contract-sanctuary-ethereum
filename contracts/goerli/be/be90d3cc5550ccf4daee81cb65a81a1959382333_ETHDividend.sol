/**
 *Submitted for verification at Etherscan.io on 2023-01-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
}

interface IREWARD {
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function claimReward(address shareHolder) external;
}

contract ETHDividend is IREWARD{   
    
    using SafeMath for uint256;

    address public _owner;

    address public _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
        uint256 reserved;
    }
    mapping (address => Share) public shares;
    
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 private totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public totalReserved;

    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    modifier onlyToken() {
        require(msg.sender == _token); 
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }
        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        uint256 amount = msg.value;
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }
        uint256 amount = calEarning(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            shares[shareholder].reserved += amount;
            totalReserved += amount;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function getUnpaidEarning(address shareholder) public view returns (uint256) {
        uint calReward = calEarning(shareholder);
        uint reservedReward = shares[shareholder].reserved;
        return calReward.add(reservedReward);
    }

    function rescueToken(address tokenAddress,address _receiver, uint256 tokens) external onlyOwner {
        IERC20(tokenAddress).transfer(_receiver, tokens);
    }

    function rescueFunds(address _receiver) external onlyOwner {
        payable(_receiver).transfer(address(this).balance);
    }

    function setToken(address _tk) external onlyOwner {
        _token = _tk;
    }

    function claimDividend() external {
        address user = msg.sender;
        transferShares(user);
    }

    function claimReward(address shareHolder) external override onlyToken {
        transferShares(shareHolder);
    }

    function transferShares(address user) internal {
        distributeDividend(user);
        uint subtotal = shares[user].reserved;
        if(subtotal > 0) {
            shares[user].reserved = 0;
            totalReserved = totalReserved.sub(subtotal);
            payable(user).transfer(subtotal);
        }
    }

    function calEarning(address shareholder) internal view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }
        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }
        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    receive() external payable {}

}