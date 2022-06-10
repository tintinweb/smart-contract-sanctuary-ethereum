/**
 *Submitted for verification at Etherscan.io on 2022-06-10
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
    uint256 public mintPerTransaction;
    uint256 public currentMintIndex;
    uint256 public mintPauseAtCount;
    uint256 public mintLimitCounter;
    mapping(address => uint) public nftOwnerInfo;

    event LandSold(
        address caller,
        string iconAddress,
        uint256 nftCount,
        string tokenType,
        string uniqueId
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
        public
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
        } else if (compareStrings(tokenType, "HARMONY")) {
            return "h";
        } else {
            revert();
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

    function transferToTreasury(uint256 _amount) external {
        ownerRequired();
        require(treasury != address(0), "Land Sale: Treasury not set");
        require(_amount != 0, "Land Sale: Amount cannot be zero");
        require(
            address(this).balance != 0 && address(this).balance >= _amount,
            "Land Sale: Balance not sufficient"
        );

        treasury.transfer(_amount);
    }
}