/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LandSale {
    string public name = "Land Sale";
    string public tokenType;
    address public owner;
    address payable public treasury;

    bool public mintStatus;
    uint256 public mintCost;
    uint256 public mintPerTransaction;
    uint256 public currentMintIndex;
    uint256 public mintPauseAtCount;
    mapping(address => uint) public ownerInfo;

    event LandSold(
        address caller,
        string iconAddress,
        uint256 nftCount,
        string tokenType,
        uint256 mintIndex
    );

    constructor(string memory _tokenType) {
        owner = msg.sender;
        mintCost = 0.016748 ether; // 80 ICX
        mintPerTransaction = 20;
        tokenType = _tokenType;
        mintPauseAtCount = 50;
    }

    function ownerRequired() internal view {
        require(msg.sender == owner, "Land Sale: Caller is not an owner");
    }

    function setName(string memory _name) internal {
        name = _name;
    }

    function toggleMintStatus() external {
        ownerRequired();
        mintStatus = !mintStatus;
    }

    function resetMintCount() external {
        ownerRequired();
        mintPauseAtCount = 0;
    }

    function setMintCost(uint256 _mintCost) external {
        ownerRequired();
        require(_mintCost != 0, "Land Sale: Mint Cost cannot be zero");
        mintCost = _mintCost;
    }

    function setMintPerTransaction(uint256 _mintPerTransaction) external {
        ownerRequired();
        mintPerTransaction = _mintPerTransaction;
    }

    function setTreasury(address payable _treasury) external {
        ownerRequired();
        require(
            _treasury != address(0),
            "Land Sale: Address cannot be a zero address"
        );
        treasury = _treasury;
    }

    function buyLand(string memory iconAddress) external payable virtual {
        require(mintStatus == true, "Land Sale: Mint is disabled");
        require(
            msg.sender != address(0),
            "Land Sale: Caller cannot be a zero address"
        );
        require(
            mintPerTransaction > 0,
            "Land Sale: Mint Per Transaction cannot be zero"
        );
        require(
            msg.value >= mintCost,
            "Land Sale: Value cannot be less than per NFT mint cost"
        );

        uint256 totalNftCount = msg.value / mintCost;
        uint256 surplusCount;
        if (totalNftCount > mintPerTransaction) {
            surplusCount = totalNftCount - mintPerTransaction;
            // update total NFT count
            totalNftCount = totalNftCount - surplusCount;
        }

        if (currentMintIndex + totalNftCount > mintPauseAtCount) {
            // update surplus count to be refunded
            uint256 rejectedNftCount = (totalNftCount -
                (mintPauseAtCount - currentMintIndex));
            surplusCount = surplusCount + rejectedNftCount;
            totalNftCount = totalNftCount - rejectedNftCount;
        }

        if (surplusCount > 0) {
            // Refund the surplus value
            payable(msg.sender).transfer(mintCost * surplusCount);
        }

        currentMintIndex = currentMintIndex + totalNftCount;
        ownerInfo[msg.sender] = ownerInfo[msg.sender] + totalNftCount;
        emit LandSold(
            msg.sender,
            iconAddress,
            totalNftCount,
            tokenType,
            currentMintIndex
        );
        if (currentMintIndex >= mintPauseAtCount) mintStatus = false;
    }

    function transferAllToTreasury() external {
        ownerRequired();
        require(treasury != address(0), "Land Sale: Treasury not set");
        require(
            address(this).balance != 0,
            "Land Sale: Balance not sufficient"
        );

        treasury.transfer(address(this).balance);
    }
}