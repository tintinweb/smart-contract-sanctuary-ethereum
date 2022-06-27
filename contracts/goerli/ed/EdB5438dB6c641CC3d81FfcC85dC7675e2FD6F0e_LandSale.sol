/**
 *Submitted for verification at Etherscan.io on 2022-06-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract LandSale {
    string public name = "Land Sale";

    string public tokenType;
    address public owner;
    address public admin;
    address payable public treasury;

    bool public mintStatus;
    uint256 public mintCost;
    uint256 public bridgeCost;
    uint256 public mintPerTransaction;

    uint256 public currentMintIndex;
    uint256 public mintPauseAtCount;
    uint256 public mintLimitCounter;

    uint256 public apeMintCost;
    uint256 public currentApeCoinMintIndex;

    mapping(address => uint) public nftOwnerInfo;

    event LandSold(
        address caller,
        string iconAddress,
        uint256 nftCount,
        string tokenType,
        string uniqueId
    );

    modifier adminOnly() {
        require(msg.sender == admin, "Land Sale: Caller is not an admin");
        _;
    }

    modifier ownerOnly() {
        require(msg.sender == owner, "Land Sale: Caller is not an owner");
        _;
    }

    constructor(string memory _tokenType) {
        owner = msg.sender;
        mintCost = 0.0001 ether; // Will be changed
        apeMintCost = 0.0001 * 10**18;
        bridgeCost = 0.00001 ether; // will be changed
        mintPerTransaction = 20;
        tokenType = _tokenType;
        mintPauseAtCount = 50;
    }

    function setAdmin(address _admin) external ownerOnly {
        admin = _admin;
    }

    function setName(string memory _name) external adminOnly {
        name = _name;
    }

    function toggleMintStatus(bool reset) external adminOnly {
        mintStatus = !mintStatus;
        if (mintStatus && reset) mintLimitCounter = 0;
    }

    function setMintCost(uint256 _mintCost) external adminOnly {
        require(_mintCost != 0, "Land Sale: Mint Cost cannot be zero");
        mintCost = _mintCost;
    }

    function setBridgeCost(uint256 _bridgeCost) external adminOnly {
        require(_bridgeCost != 0, "Land Sale: Bridge Cost cannot be zero");
        bridgeCost = _bridgeCost;
    }

    function setMintPerTransaction(uint256 _mintPerTransaction)
        external
        adminOnly
    {
        mintPerTransaction = _mintPerTransaction;
    }

    function setMintPauseAtCount(uint256 _mintPauseAtCount) external adminOnly {
        mintPauseAtCount = _mintPauseAtCount;
    }

    function setTreasury(address payable _treasury) external ownerOnly {
        require(
            _treasury != address(0),
            "Land Sale: Address cannot be a zero address"
        );
        treasury = _treasury;
    }

    function uint2str(uint _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        unchecked {
            if (_i == 0) {
                return "0";
            }
            uint j = _i;
            uint len;
            while (j != 0) {
                len++;
                j /= 10;
            }
            bytes memory bstr = new bytes(len);
            uint k = len - 1;
            while (_i != 0) {
                bstr[k--] = bytes1(uint8(48 + (_i % 10)));
                _i /= 10;
            }
            return string(bstr);
        }
    }

    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    function getInitialCharacterOfToken()
        internal
        view
        returns (string memory _uintAsString)
    {
        if (compareStrings(tokenType, "ETH")) {
            return "e";
        } else if (compareStrings(tokenType, "MATIC")) {
            return "m";
        } else if (compareStrings(tokenType, "JEWEL")) {
            return "j";
        } else {
            revert("Invalid Token Type");
        }
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
        require(
            nftCount + mintLimitCounter <= mintPauseAtCount,
            "Land Sale: Total NFT Limit Exceeded"
        );
        require(
            nftCount <= mintPerTransaction,
            "Land Sale: NFT count per transaaction exceeded"
        );

        require(
            msg.value == nftCount * mintCost,
            "Land Sale: Payment Mismatch"
        );

        currentMintIndex = currentMintIndex + nftCount;
        nftOwnerInfo[msg.sender] = nftOwnerInfo[msg.sender] + nftCount;
        string memory uid = string.concat(
            getInitialCharacterOfToken(),
            uint2str(currentMintIndex)
        );
        emit LandSold(msg.sender, iconAddress, nftCount, tokenType, uid);
        mintLimitCounter = mintLimitCounter + nftCount;
        if (mintLimitCounter >= mintPauseAtCount) mintStatus = false;
    }

    function buyLandViaApeCoin(
        address to,
        string memory iconAddress,
        uint256 nftCount
    ) external virtual adminOnly {
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
            nftCount + mintLimitCounter <= mintPauseAtCount,
            "Land Sale: Total NFT Limit Exceeded"
        );
        require(
            nftCount <= mintPerTransaction,
            "Land Sale: NFT count per transaaction exceeded"
        );

        currentApeCoinMintIndex = currentApeCoinMintIndex + nftCount;
        nftOwnerInfo[to] = nftOwnerInfo[to] + nftCount;
        string memory uid = string.concat("a", uint2str(currentMintIndex));
        emit LandSold(to, iconAddress, nftCount, "APECOIN", uid);
        mintLimitCounter = mintLimitCounter + nftCount;
        if (mintLimitCounter >= mintPauseAtCount) mintStatus = false;
    }

    function transferToTreasury(uint256 _amount) external ownerOnly {
        require(treasury != address(0), "Land Sale: Treasury not set");
        require(_amount != 0, "Land Sale: Amount cannot be zero");
        require(
            address(this).balance != 0 && address(this).balance >= _amount,
            "Land Sale: Balance not sufficient"
        );

        treasury.transfer(_amount);
    }
}