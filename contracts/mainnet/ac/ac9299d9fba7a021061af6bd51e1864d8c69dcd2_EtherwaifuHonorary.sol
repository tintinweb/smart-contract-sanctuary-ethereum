// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./IEtherwaifuMarketplace.sol";

contract EtherwaifuHonorary is ERC721Enumerable, Ownable {
    address constant etherwaifuDaoAddress = 0x4574cA86141CA75F725cD99d07dab120b9CCa5D2;
    address etherwaifuGenesisAddress = 0x36697e362Ee7E9CA977b7550B3e4f955fc5BF27d;
    address etherwaifuWrapperAddress = 0x9357a3B394798c1575218d18910e926b275Ea07a;
    address etherwaifuMarketplaceAddress = 0xF074A87DCCacAfE17755190fa42c70EC9D94E580;
    address public precommitAirdropWinner = address(0);

    string baseURI = "https://etherwaifu.com/api/honorary/erc721MetadataById/";

    uint256 seed = 0;

    constructor() ERC721("Etherwaifu Neo", "EWFN") {
        transferOwnership(etherwaifuDaoAddress);
    }

    function setEnv(address _etherwaifuGenesisAddress, address _etherwaifuWrapperAddress, address _etherwaifuMarketplaceAddress) external onlyOwner {
        etherwaifuGenesisAddress = _etherwaifuGenesisAddress;
        etherwaifuWrapperAddress = _etherwaifuWrapperAddress;
        etherwaifuMarketplaceAddress = _etherwaifuMarketplaceAddress;
    }

    function mint() external onlyOwner {
        _honoraryMint(owner());
    }

    function mint(address to) external onlyOwner {
        _honoraryMint(to);
    }

    function _honoraryMint(address to) private {
        precommitAirdropWinner = address(0);
        uint256 _tokenId = totalSupply() + 1;
        _safeMint(owner(), _tokenId);
        if(to == owner()) {
            return;
        }

        _safeTransfer(owner(), to, _tokenId, "");
    }

    function airdropToRandom(address[] memory addresses) external onlyOwner {
        address _winner = addresses[_random(addresses.length)];
        _honoraryMint(_winner);
    }

    function airdropCommit() external onlyOwner {
        require(precommitAirdropWinner != address(0), "No precommitted address");
        _honoraryMint(precommitAirdropWinner);
    }

    function airdropToRandomERC721(address nftAddress, address[] memory wrapperAddresses) external onlyOwner {
        (uint256 _tokenId, address _winner) = _getRandomOwner(IERC721Enumerable(nftAddress));

        for(uint256 i = 0; i < wrapperAddresses.length; i++) {
            if(_winner == wrapperAddresses[i]) {
                _winner = IERC721(_winner).ownerOf(_tokenId);
                break;
            }
        }

        // have a human review it, then call airdropCommit()
        precommitAirdropWinner = _winner;
    }

    function setBaseURI(string memory newURI) external onlyOwner {
        baseURI = newURI;
    }

    function airdropToRandomEtherwaifuHolder() external onlyOwner {
        (uint256 _tokenId, address _winner) = _getRandomOwner(IERC721Enumerable(etherwaifuGenesisAddress));

        if(_winner == etherwaifuWrapperAddress) {
            _winner = IERC721(_winner).ownerOf(_tokenId);
        } else if(_winner == etherwaifuMarketplaceAddress) {
            (_winner, , , , , ) =  IEtherwaifuMarketplace(_winner).getAuction(_tokenId);
        }

        // have a human review it, then call airdropCommit()
        precommitAirdropWinner = _winner;
    }

    function _getRandomOwner(IERC721Enumerable nftAddress) internal returns (uint256, address) {
        uint256 _totalSupply = nftAddress.totalSupply();
        uint256 _randomIndex = _random(_totalSupply);
        uint256 _tokenId;
        if(address(nftAddress) == etherwaifuGenesisAddress) {
            // starts at id 0
            _tokenId = _randomIndex;
        } else {
            _tokenId = nftAddress.tokenByIndex(_randomIndex);
        }

        address _owner = nftAddress.ownerOf(_tokenId);
        return (_tokenId, _owner);
    }

    function _random(uint256 maxExclusive) internal returns (uint256 randomNumber) {
        // the blockhash of the current block (and future block) is 0 because it doesn't exist
        seed = uint256(keccak256(abi.encodePacked(keccak256(abi.encodePacked(blockhash(block.number - 1), seed)), block.timestamp)));
        return seed % maxExclusive;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}