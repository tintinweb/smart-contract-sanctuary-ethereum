/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// LitBit OmniChain PrivateSale

// Code written by MrGreenCrypto
// SPDX-License-Identifier: None

pragma solidity 0.8.16;

interface IBEP20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract PrivateSale {
    struct Contributions {
        address contributor;
        uint256 contributionAmount;
    }

    Contributions[] listOfContributions;
    mapping(address => uint256) presaleContributions;
    mapping(uint256 => address) contributorByID;
    uint256 public totalContributors;
    uint256 public totalContributionAmount;
    IBEP20 public USD;
    IBEP20 public USDT;
    uint256 public minimum = 50 ether;
    uint256 public maximum = 5000 ether;

    address public constant CEO = 0x9364a23E071419363CD5393348D660D6a3F47a4E;
    modifier onlyOwner() {if(msg.sender != CEO) return; _;}

    constructor(address _usd, address _usdt){
        USD = IBEP20(_usd);
        USDT = IBEP20(_usdt);
    }

    function contributeToPresaleWithUSDC(uint256 amount) public {
        require(amount >= minimum,"Minimum amount not met");
        require(amount <= maximum,"Maximum amount exceeded");
        USD.transferFrom(msg.sender, address(this), amount);
        if(presaleContributions[msg.sender] == 0) contributorByID[totalContributors] = msg.sender;
        presaleContributions[msg.sender] += amount;
        totalContributionAmount += amount;
        totalContributors++;
    }

    function contributeToPresaleWithUSDT(uint256 amount) public {
        require(amount >= minimum,"Minimum amount not met");
        require(amount <= maximum,"Maximum amount exceeded");
        USDT.transferFrom(msg.sender, address(this), amount);
        if(presaleContributions[msg.sender] == 0) contributorByID[totalContributors] = msg.sender;
        presaleContributions[msg.sender] += amount;
        totalContributionAmount += amount;
        totalContributors++;
    }

    function getAllContributors() public view returns(Contributions[] memory) {
        Contributions[] memory allContributors = new Contributions[](totalContributors);
        for(uint256 i = 0; i < totalContributors;i++){
            allContributors[i] = Contributions(contributorByID[i], presaleContributions[contributorByID[i]]);
        }
        return allContributors;
    }

    function withdrawContributions() external onlyOwner{
        USD.transfer(CEO, USD.balanceOf(address(this)));
        USDT.transfer(CEO, USDT.balanceOf(address(this)));        
    }
}