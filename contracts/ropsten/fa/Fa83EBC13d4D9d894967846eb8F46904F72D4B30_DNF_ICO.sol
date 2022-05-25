// SPDX-License-Identifier: MIT

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

pragma solidity ^0.8.7;

contract DNF_ICO is Ownable {
    using SafeMath for uint256;

    // IERC20 tokenContract = IERC20(address(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E));
    address tokenAddress = address(0xc8749e244216b3D8A1d093d9aDd7F07Cd5cda3F1);
    IERC20 tokenContract = IERC20(tokenAddress);
    address fundCollector = address(0xF533169233f69e0aC126886cA41cA2a2272C7037);
    mapping(address => bool) public whiteListedWallets;
    mapping(address => uint256) public contributed_amount;

    uint256 public min_contribute = 200 * 10**6;
    uint256 public max_contribute = 2000 * 10**6;

    uint256 public totalContributed = 0;
    uint256 withdrawedFunds = 0;

    bool public isFinalized = false;

    uint256 public maxCap = 40000 * 10**6;

    function contribute(uint256 amount) public {
        require(
            tokenContract.allowance(msg.sender, address(this)) >= amount,
            "Allowance Error"
        );
        tokenContract.transferFrom(msg.sender, address(this), amount);
        contributed_amount[msg.sender] = add256(
            contributed_amount[msg.sender],
            amount
        );
        totalContributed = add256(totalContributed, amount);
        if (add256(totalContributed, min_contribute) > maxCap) {
            isFinalized = true;
        }
    }

    function withdrawFunds() public onlyOwner {
        require(withdrawedFunds < totalContributed);
        tokenContract.transfer(
            fundCollector,
            totalContributed - withdrawedFunds
        );
        withdrawedFunds = totalContributed;
    }

    function getContributionVariables()
        external
        view
        onlyOwner
        returns (
            uint256,
            address,
            address
        )
    {
        return (withdrawedFunds, fundCollector, tokenAddress);
    }

    function addWhitelistedAdress(address Contributer) public onlyOwner {
        whiteListedWallets[Contributer] = true;
    }

    function addToWhitelistMultipleAdress(address[] memory users)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < users.length; i++) {
            whiteListedWallets[users[i]] = true;
        }
    }

    function finalizePresale() public onlyOwner {
        isFinalized = true;
    }

    function resumePresale() public onlyOwner {
        isFinalized = false;
    }

    function updateTokenAddress(address _address) external onlyOwner {
        tokenAddress = _address;
        tokenContract = IERC20(tokenAddress);
    }

    function updateFundCollector(address _address) external onlyOwner {
        fundCollector = _address;
    }

    function updateMaxCap(uint256 new_Cap) public onlyOwner {
        maxCap = new_Cap * 10**6;
    }

    function updateMinContribution(uint256 newMinContribution)
        public
        onlyOwner
    {
        require(
            newMinContribution > 0,
            "MIN CONTRIBUTION CANNOT BE LOWER OR EQUAL TO 0"
        );
        require(
            newMinContribution < max_contribute,
            "MIN CONTRIBUTION CANNOT BE HIGHER OR EQUAL THAN MAX CONTRIBUTION"
        );
        min_contribute = newMinContribution * 10**6;
    }

    function updateMaxContribution(uint256 newMaxContribution)
        public
        onlyOwner
    {
        require(
            newMaxContribution > min_contribute,
            "MAX CONTRIBUTION CANNOT BE LOWER OR EQUAL THAN MIN CONTRIBUTION"
        );
        max_contribute = newMaxContribution * 10**6;
    }

    function add256(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }
}