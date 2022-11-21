//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "./Ownable.sol";
import "./SafeERC20.sol";

interface AvenNFT {
    function isFounder(address _account) external view returns (bool);
}

contract AvenPrivateSale is Ownable {
    using SafeERC20 for IERC20;

    struct Contribution {
        uint256 amount;
        uint256 contributedAt;
    }

    mapping(address => Contribution[]) public contributions;
    bool public saleStarted = false;
    bool public saleEnded = false;
    bool public salePaused = false;
    address contributedToken = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    uint256 contributedTokenDecimal = 6;
    address avenNFTAddress = 0x06B3e19355a2eef4Ee90F3f6dD41A2e7f7b52F4A;
    uint256 public minContributionAmount = 100 * (10**contributedTokenDecimal);
    uint256 public maxContributionAmount = 2000 * (10**contributedTokenDecimal);
    uint256 public hardCap = 50000 * (10**contributedTokenDecimal);
    mapping(address => bool) public whitelisted;

    modifier onlyFounder() {
        if(!whitelisted[msg.sender]) {
            bool isFounder = AvenNFT(avenNFTAddress).isFounder(msg.sender);
            require(isFounder, "You need founder NFT to continue");
        }
        _;
    }

    function contribute(uint256 _amount) public onlyFounder {
        require(saleStarted, "Sale has not started yet.");
        require(!saleEnded, "Sale has ended");
        require(!salePaused, "Sale is paused");
        require(_amount >= minContributionAmount, "Contribution is less than min required amount.");
        require(_amount <= maxContributionAmount, "Contribution is greater than max required amount.");
        require(IERC20(contributedToken).balanceOf(msg.sender) >= _amount);

        IERC20(contributedToken).transferFrom(msg.sender, address(this), _amount);

        Contribution storage _contribution = contributions[msg.sender].push();
        _contribution.amount = _amount;
        _contribution.contributedAt = block.timestamp;
    }

    function getContributionList() public view returns (Contribution[] memory) {
        return contributions[msg.sender];
    }

    function setWhitelist(address _account, bool _state) public onlyOwner {
        whitelisted[_account] = _state;
    }

    function setMinContribution(uint256 _minContributionAmount) public onlyOwner {
        minContributionAmount = _minContributionAmount;
    }

    function setMaxContribution(uint256 _maxContributionAmount) public onlyOwner {
        maxContributionAmount = _maxContributionAmount;
    }

    function setHardCap(uint256 _hardCap) public onlyOwner {
        hardCap = _hardCap;
    }

    function startSale() public onlyOwner {
        require(!saleEnded, "Sale has ended.");
        saleStarted = true;
    }

    function endSale() public onlyOwner {
        require(saleStarted, "Sale has not started yet.");
        saleEnded = true;
    }

    function pauseSale(bool _state) public onlyOwner {
        require(saleStarted, "Sale has not started yet.");
        require(!saleEnded, "Sale has ended.");
        salePaused = _state;
    }

    function setAvenNFTAddress(address _avenNFTAddress) public onlyOwner {
        avenNFTAddress = _avenNFTAddress;
    }

    function setContributedToken(address _contributedToken, uint256 _contributedTokenDecimal) public onlyOwner {
        contributedToken = _contributedToken;
        contributedTokenDecimal = _contributedTokenDecimal;
    }

    function withdraw() public payable onlyOwner {
        require(saleEnded, "Sale has not ended yet.");
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}