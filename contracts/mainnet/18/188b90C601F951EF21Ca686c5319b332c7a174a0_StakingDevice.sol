// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721SBurnable.sol";
import "./SafeMath.sol";
import "./IERC721S.sol";

interface IRandomNumGenerator {
    function getRandomNumber(
        uint256 _seed,
        uint256 _limit,
        uint256 _random
    ) external view returns (uint16);
}

interface IAFF {
    function burn(address from, uint256 amount) external;
}

interface IGoldStaking {
    function stakeDevice(address owner, uint16[] memory tokenIds) external;

    function randomBusinessOwner(uint256 seed) external view returns (address);
}

/**
 * @title StakingDevice Contract
 * @dev Extends ERC721S Non-Fungible Token Standard basic implementation
 */
contract StakingDevice is ERC721SBurnable {
    using SafeMath for uint256;

    string public baseTokenURI;
    uint16 private mintedCount;
    uint16 public MAX_SUPPLY;

    uint256 public mintPrice;
    uint16 public maxByMint;

    address public stakingAddress;
    address public tokenAddress;
    IRandomNumGenerator randomGen;

    mapping(uint16 => uint8) private multifiers;

    event Steel(address from, address to, uint16 tokenId);

    constructor() ERC721S("Staking Device", "GPU") {
        MAX_SUPPLY = 10000;
        mintPrice = 450 ether;
        maxByMint = 20;
    }

    function setMintPrice(uint256 newMintPrice) external onlyOwner {
        mintPrice = newMintPrice;
    }

    function setMaxByMint(uint16 newMaxByMint) external onlyOwner {
        maxByMint = newMaxByMint;
    }

    function setMaxSupply(uint16 _max_supply) external onlyOwner {
        MAX_SUPPLY = _max_supply;
    }

    function setContractAddress(
        address _stakingAddress,
        address _tokenAddress,
        IRandomNumGenerator _randomGen
    ) external onlyOwner {
        stakingAddress = _stakingAddress;
        tokenAddress = _tokenAddress;
        randomGen = _randomGen;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function getMultifier(uint16 tokenId) public view returns (uint8) {
        return multifiers[tokenId];
    }

    function getMultifiers(uint16[] memory tokenIds)
        public
        view
        returns (uint8[] memory)
    {
        uint8[] memory _multifiers = new uint8[](tokenIds.length);
        for (uint8 i; i < tokenIds.length; i++) {
            _multifiers[i] = multifiers[tokenIds[i]];
        }
        return _multifiers;
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // Hardcode the Manager's approval so that users don't have to waste gas approving
        if (_msgSender() != stakingAddress)
            require(
                _isApprovedOrOwner(_msgSender(), tokenId),
                "ERC721S: transfer caller is not owner nor approved"
            );
        _transfer(from, to, tokenId);
    }

    function totalSupply() public view virtual returns (uint256) {
        return mintedCount;
    }

    function getTokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(owner);
        uint256 supply = totalSupply();

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 resultIndex = 0;
            uint256 tokenId;

            for (tokenId = 0; tokenId < supply; tokenId++) {
                if (_owners[tokenId] == owner) {
                    result[resultIndex] = tokenId;
                    resultIndex++;
                    if (resultIndex >= tokenCount) {
                        break;
                    }
                }
            }
            return result;
        }
    }

    function _getRandom(uint256 _tokenId) public view returns (uint8) {
        uint256 random = randomGen.getRandomNumber(
            _tokenId,
            100,
            totalSupply()
        );

        if (random >= 99) {
            return 9;
        } else if (random >= 97) {
            return 8;
        } else if (random >= 93) {
            return 7;
        } else if (random >= 87) {
            return 6;
        } else if (random >= 80) {
            return 5;
        } else if (random >= 71) {
            return 4;
        } else if (random >= 61) {
            return 3;
        } else if (random >= 50) {
            return 2;
        } else if (random >= 37) {
            return 1;
        } else {
            return 0;
        }
    }

    function mintByUser(
        uint8 _numberOfTokens,
        uint256 _amount,
        bool _stake
    ) external {
        require(tx.origin == msg.sender, "Only EOA");
        require(
            totalSupply() + _numberOfTokens <= MAX_SUPPLY,
            "Max Limit To Presale"
        );
        require(_numberOfTokens <= maxByMint, "Exceeds Amount");

        require(mintPrice.mul(_numberOfTokens) <= _amount, "Low Price To Mint");

        IAFF(tokenAddress).burn(msg.sender, _amount);

        uint16[] memory tokenIds = _stake
            ? new uint16[](_numberOfTokens)
            : new uint16[](0);

        for (uint8 i = 0; i < _numberOfTokens; i += 1) {
            address recipient = _selectRecipient(i);
            uint16 tokenId = uint16(totalSupply() + i);

            uint8 randomNumber = _getRandom(tokenId);
            multifiers[tokenId] = randomNumber;

            if (recipient != msg.sender) {
                emit Steel(msg.sender, recipient, tokenId);
            }

            if (_stake && recipient == msg.sender) {
                tokenIds[i] = tokenId;
                _safeMint(stakingAddress, tokenId);
            } else {
                _safeMint(msg.sender, tokenId);
            }
        }
        mintedCount = mintedCount + _numberOfTokens;

        if (_stake && tokenIds.length > 0) {
            IGoldStaking(stakingAddress).stakeDevice(msg.sender, tokenIds);
        }
    }

    function _selectRecipient(uint256 seed) private view returns (address) {
        if (
            randomGen.getRandomNumber(
                totalSupply() + seed,
                100,
                totalSupply()
            ) >= 10
        ) {
            return msg.sender;
        }

        address thief = IGoldStaking(stakingAddress).randomBusinessOwner(
            totalSupply() + seed
        );
        if (thief == address(0x0)) {
            return msg.sender;
        }
        return thief;
    }
}