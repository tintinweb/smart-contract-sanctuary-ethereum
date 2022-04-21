// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract YSNFT06 is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant maxSupply = 556;
    uint256 public claimStartTime = 1649862000;
    uint256 constant maxClaimPerTx = 6;
    string public baseTokenURI;
    bool public isPaused = false;
    address public YSNFT;

    mapping(uint256 => bool) public tokenClaimAry;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address _ysnft
    ) ERC721A(_name, _symbol) {
        baseTokenURI = _uri;
        YSNFT = _ysnft;
    }

    function claimFreeGift(uint256[] calldata _tokenIDs, uint256 _amount)
        external
        nonReentrant
    {
        require(!isPaused, "YSNFT06: currently paused");
        require(
            block.timestamp >= claimStartTime,
            "YSNFT06: free claim is not started yet"
        );
        uint256 claimAmountLeft = _tokenIDs.length % 3;
        require(claimAmountLeft == 0, "YSNFT06: claimAmountLeft incorrect");

        uint256 claimAmount = _tokenIDs.length / 3;
        require(claimAmount == _amount, "YSNFT06: claimAmount incorrect");
        require(
            claimAmount <= maxClaimPerTx,
            "YSNFT06: over max claim per transaction"
        );
        uint256 supply = totalSupply();
        require((supply + _amount) <= maxSupply, "YSNFT06: reach max supply");

        ERC721A YSMain = ERC721A(YSNFT);
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            bool isOwner = YSMain.ownerOf(_tokenIDs[i]) == _msgSender();
            require(isOwner, "YSNFT06: incorrect exchange token id");
            require(
                !tokenClaimed(_tokenIDs[i]),
                "YSNFT06: token has been claimed"
            );
            tokenClaimAry[_tokenIDs[i]] = true;
        }
        _safeMint(_msgSender(), _amount);
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseTokenURI = _baseURI;
    }

    function setPause(bool _isPaused) external onlyOwner returns (bool) {
        isPaused = _isPaused;

        return true;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function tokensClaimed(uint256[] calldata _tokenIDs)
        external
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            if (tokenClaimAry[_tokenIDs[i]]) {
                return _tokenIDs[i];
            }
        }
        return 9999;
    }

    function tokenClaimed(uint256 _tokenID) public view returns (bool) {
        return tokenClaimAry[_tokenID];
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}