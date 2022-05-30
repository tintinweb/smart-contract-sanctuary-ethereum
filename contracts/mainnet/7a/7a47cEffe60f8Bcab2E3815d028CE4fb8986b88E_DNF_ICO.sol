// SPDX-License-Identifier: MIT

import "./IERC20Metadata.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

pragma solidity ^0.8.7;

contract DNF_ICO is Ownable {
    using SafeMath for uint256;

    // IERC20 tokenContract = IERC20(address(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E));
    address public tokenAddress =
        address(0x47D1D10c2A15259b1fed015A6c15740e3303d2f3);
    IERC20Metadata tokenContract = IERC20Metadata(tokenAddress);
    address public fundCollector =
        address(0x5E524c46d2D87B1d6249E297eB03C999c3feaC22);
    mapping(address => uint256) public contributedAmount;

    uint256 public minContribution = 200 * 10**6;
    uint256 public maxContribution = 2000 * 10**6;
    uint256 public totalContribution = 0;
    uint256 public maxCap = 40000 * 10**6;

    bool public isFinalized = false;

    event Contribute(address indexed _contributor);

    function contribute(uint256 amount) public {
        require(
            add256(contributedAmount[msg.sender], amount) <= maxContribution,
            "CONTRIBUTION AMOUNT EXCEEDS MAX__TOTALCONTRIBUTION"
        );
        require(
            add256(contributedAmount[msg.sender], amount) >= minContribution,
            "MIN_CONTRIBUTION IS NOT FULLFILLED"
        );
        require(add256(totalContribution, amount) < maxCap, "EXCEEDS MAX_CAP");
        require(!isFinalized, "PRESALE IS FINALIZED");
        require(
            tokenContract.allowance(msg.sender, address(this)) >= amount,
            "Allowance Error"
        );
        tokenContract.transferFrom(msg.sender, address(this), amount);
        if (contributedAmount[msg.sender] == 0) emit Contribute(msg.sender);
        contributedAmount[msg.sender] = add256(
            contributedAmount[msg.sender],
            amount
        );
        totalContribution = add256(totalContribution, amount);
        if (add256(totalContribution, minContribution) > maxCap) {
            isFinalized = true;
        }
    }

    function tokenBalance() public view returns (uint256) {
        return tokenContract.balanceOf(address(this));
    }

    function withdrawFunds() public onlyOwner {
        uint256 balance = tokenContract.balanceOf(address(this));
        require(balance > 0);
        tokenContract.transfer(fundCollector, balance);
    }

    function finalizePresale() public onlyOwner {
        isFinalized = true;
    }

    function resumePresale() public onlyOwner {
        isFinalized = false;
    }

    function updateTokenAddress(address _tokenAddress) external onlyOwner {
        tokenAddress = _tokenAddress;
        tokenContract = IERC20Metadata(tokenAddress);
    }

    function updateFundCollector(address _fundCollector) external onlyOwner {
        fundCollector = _fundCollector;
    }

    function updateMaxCap(uint256 _maxCap) public onlyOwner {
        maxCap = _maxCap * 10**6;
    }

    function updateMinContribution(uint256 _minContribution) public onlyOwner {
        require(
            _minContribution > 0,
            "MIN CONTRIBUTION CANNOT BE LOWER OR EQUAL TO 0"
        );
        require(
            _minContribution < maxContribution,
            "MIN CONTRIBUTION CANNOT BE HIGHER OR EQUAL THAN MAX CONTRIBUTION"
        );
        minContribution = _minContribution * 10**6;
    }

    function updateMaxContribution(uint256 _maxContribution) public onlyOwner {
        require(
            _maxContribution > minContribution,
            "MAX CONTRIBUTION CANNOT BE LOWER OR EQUAL THAN MIN CONTRIBUTION"
        );
        maxContribution = _maxContribution * 10**6;
    }

    function add256(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }
}