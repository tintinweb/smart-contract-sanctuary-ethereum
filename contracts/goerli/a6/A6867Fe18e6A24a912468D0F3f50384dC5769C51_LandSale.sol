/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LandSale {
    string public name = "Land Sale";
    string public tokenType;
    address public owner;
    address public admin;
    address payable public treasury;

    bool public mintStatus;
    uint256 public mintCost;
    uint256 public mintPerTransaction;
    uint256 public currentMintIndex;
    uint256 public mintPauseAtCount;
    uint256 public mintLimitCounter;
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

    function adminRequired() internal view {
        require(msg.sender == admin, "Land Sale: Caller is not an admin");
    }

    function setName(string memory _name) internal {
        name = _name;
    }

    function setAdmin(address _admin) external {
        ownerRequired();
        admin = _admin;
    }

    function toggleMintStatus(bool reset) external {
        adminRequired();
        mintStatus = !mintStatus;
        if (mintStatus && reset) mintLimitCounter = 0;
    }

    function setMintCost(uint256 _mintCost) external {
        adminRequired();
        require(_mintCost != 0, "Land Sale: Mint Cost cannot be zero");
        mintCost = _mintCost;
    }

    function setMintPerTransaction(uint256 _mintPerTransaction) external {
        adminRequired();
        mintPerTransaction = _mintPerTransaction;
    }

    function setMintPauseAtCount(uint256 _mintPauseAtCount) external {
        adminRequired();
        mintPauseAtCount = _mintPauseAtCount;
    }

    function setTreasury(address payable _treasury) external {
        ownerRequired();
        require(
            _treasury != address(0),
            "Land Sale: Address cannot be a zero address"
        );
        treasury = _treasury;
    }

    function buyLand(string memory iconAddress, uint256 nftCount)
        external
        payable
        virtual
    {
        require(mintStatus == true, "Land Sale: Mint is disabled");
        require(
            msg.sender != address(0),
            "Land Sale: Caller cannot be a zero address"
        );
        require(
            mintPerTransaction > 0,
            "Land Sale: Mint Per Transaction cannot be zero"
        );
        require(nftCount >= mintPerTransaction, "Land Sale:");

        require(
            nftCount + mintLimitCounter >= mintPauseAtCount,
            "Land Sale: Value cannot be less than per NFT mint cost"
        );

        currentMintIndex = currentMintIndex + nftCount;
        ownerInfo[msg.sender] = ownerInfo[msg.sender] + nftCount;
        emit LandSold(
            msg.sender,
            iconAddress,
            nftCount,
            tokenType,
            currentMintIndex
        );
        mintLimitCounter = mintLimitCounter + nftCount;
        if (mintLimitCounter >= mintPauseAtCount) mintStatus = false;
    }

    function transferToTreasury(uint256 _amount) external {
        ownerRequired();
        require(treasury != address(0), "Land Sale: Treasury not set");
        require(_amount != 0, "Land Sale: Amount cannot be zero");
        require(
            address(this).balance != 0,
            "Land Sale: Balance not sufficient"
        );

        treasury.transfer(_amount);
    }
}