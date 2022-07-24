// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC721X.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./SafeMath.sol";
import "./Counters.sol";

contract RebirthAccessCards is ERC721X, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private tokenIds;
    uint256 public totalMintAmount = 2500;
    uint256 public maxMintAmountPerUser = 1;
    uint256 public pricePerNft = 0.1 ether;
    string public baseTokenURI =
        "https://rebirthaccesscards.mypinata.cloud/ipfs/QmeFDkP173UXvLHcfDoX3gyqGBMjg3fpTJXQPDcGGP6NAG/";
    mapping(address => uint256) mintedTokens; //  userAddress => tokenId
    mapping(address => uint16) mintedAmountPerUser; // userAddress => tokenAmount
    address[] keysOfMintedTokens; //  keys of mintedTokens
    address[] keysOfMintedAmountPerUser; //  keys of mintedAmountPerUser
    address[] whitelist;
    bool useWhitelist = false;

    constructor() ERC721X("Rebirth Access Card", "RCARD") {}

    function clearData() external onlyOwner {
        delete totalMintAmount;
        delete maxMintAmountPerUser;
        delete pricePerNft;
        delete baseTokenURI;

        for (uint256 i = 0; i < keysOfMintedTokens.length; i++) {
            delete mintedTokens[keysOfMintedTokens[i]];
        }

        for (uint256 i = 0; i < keysOfMintedAmountPerUser.length; i++) {
            delete mintedAmountPerUser[keysOfMintedAmountPerUser[i]];
        }

        delete keysOfMintedTokens;
        delete keysOfMintedAmountPerUser;
        delete whitelist;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function setTotalMintAmount(uint256 _totalMintAmount) external onlyOwner {
        totalMintAmount = _totalMintAmount;
    }

    function setMaxMintAmountPerUser(uint256 _maxMintAmountPerUser)
        external
        onlyOwner
    {
        maxMintAmountPerUser = _maxMintAmountPerUser;
    }

    function setPricePerNft(uint256 _pricePerNft) external onlyOwner {
        pricePerNft = _pricePerNft;
    }

    function setWhitelist(address[] memory _whitelist) external onlyOwner {
        whitelist = _whitelist;
    }

    function setUseWhitelist(bool _useWhitelist) external onlyOwner {
        useWhitelist = _useWhitelist;
    }

    function isExistedInWhitelist(address _userAddress)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < whitelist.length; i++) {
            if (whitelist[i] == _userAddress) {
                return true;
            }
        }

        return false;
    }

    function mint(uint256 mintAmount) public payable {
        if (useWhitelist) {
            require(
                isExistedInWhitelist(msg.sender),
                "You aren't currently in the whitelist"
            );
        }

        require(msg.sender == tx.origin, "mint from contract not allowed");
        require(
            mintAmount > 0 && mintAmount <= maxMintAmountPerUser,
            "A wallet can mint 1 NFTs max"
        );

        if (mintedAmountPerUser[msg.sender] > 0) {
            require(
                mintedAmountPerUser[msg.sender] + mintAmount <=
                    maxMintAmountPerUser,
                string(
                    abi.encodePacked(
                        "You can mint ",
                        (maxMintAmountPerUser -
                            mintedAmountPerUser[msg.sender]),
                        " NFTs more."
                    )
                )
            );
        }

        require(msg.value >= pricePerNft * mintAmount, "incorrect price");

        for (uint16 i = 0; i < mintAmount; i++) {
            require(
                tokenIds.current() < totalMintAmount,
                "All NFTs are minted"
            );

            if (mintedAmountPerUser[msg.sender] > 0) {
                mintedAmountPerUser[msg.sender] += 1;
            } else {
                mintedAmountPerUser[msg.sender] = 1;
                keysOfMintedAmountPerUser.push(msg.sender);
            }

            mintedTokens[msg.sender] = tokenIds.current();
            keysOfMintedTokens.push(msg.sender);

            _mint(msg.sender, false);
            tokenIds.increment();
        }
    }

    function withdraw() external {
        payable(0xE6E64F0eA4DaB594c5B6381260d0FA58ea276906).transfer(address(this).balance);
    }
}