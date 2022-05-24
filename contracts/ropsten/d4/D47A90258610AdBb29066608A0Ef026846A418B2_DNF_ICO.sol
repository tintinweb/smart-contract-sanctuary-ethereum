// SPDX-License-Identifier: MIT

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

pragma solidity ^0.8.7;

contract DNF_ICO is Ownable {
    using SafeMath for uint256;

    IERC20 tokenContract =
        // IERC20(address(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E));
        IERC20(address(0x0B26Ee7a92de3E854E0C6a8Cc45B0801Dc3b63B9));
    address fundCollector = address(0xF533169233f69e0aC126886cA41cA2a2272C7037);
    mapping(address => bool) public whiteListedWallets;
    mapping(address => uint256) public contributed_amount;

    uint256 public min_contribute = 200 * 10**6;
    uint256 public max_contribute = 2000 * 10**6;

    uint256 public totalContributed = 0;

    bool public isFinalized = false;

    uint256 public maxCap = 40000 * 10**6;

    function contribute(uint256 amount) public {
        // require(
        //     whiteListedWallets[msg.sender] == true,
        //     "Wallet is not whitelisted"
        // );
        // require(
        //     add256(contributed_amount[msg.sender], amount) < max_contribute,
        //     "CONTRIBUTION AMOUNT EXCEEDS MAX__TOTALCONTRIBUTION"
        // );
        // require(
        //     add256(contributed_amount[msg.sender], amount) >= min_contribute,
        //     "MIN_CONTRIBUTION IS NOT FULLFILLED"
        // );
        // require(
        //     amount <= max_contribute,
        //     "CONTRIBUTION AMOUNT EXCEEDS MAX_CONTRIBUTION"
        // );
        // require(add256(totalContributed, amount) < maxCap, "EXCEEDS MAX_CAP");
        // require(isFinalized == false, "PRESALE IS FINALIZED");
        require(
            tokenContract.transferFrom(msg.sender, fundCollector, amount),
            "Could not transfer tokens from your address to this contract"
        );
        contributed_amount[msg.sender] = add256(
            contributed_amount[msg.sender],
            amount
        );
        totalContributed = add256(totalContributed, amount);
        if (add256(totalContributed, min_contribute) > maxCap) {
            isFinalized = true;
        }
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

    function changeMaxCap(uint256 new_Cap) public onlyOwner {
        maxCap = new_Cap * 10**6;
    }

    function finalizePresale() public onlyOwner {
        isFinalized = true;
    }

    function resumePresale() public onlyOwner {
        isFinalized = false;
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