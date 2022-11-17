// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract HermitCrabsNFT is ERC721, ERC721Enumerable, Ownable {

    event RaffleStarted(uint256 startBlock, uint256 targetBlock, uint256 number, address startedBy);
    event RaffleRevealed(uint256 targetBlock, uint256 winningToken, address winner, uint256 colorglyphIndex);
    string private _baseURIextended;
    mapping (address => uint) public index;
    mapping (address => string) public names;
    mapping (address => uint) mints;
    uint256 public constant MAX_SUPPLY = 263;
    uint256 public constant MAX_PUBLIC_MINT = 1;
    bool public REVEALED = false;
    bool public open = false;
    uint256 public crabTransfers = 0;
    uint256 public deploymentBlock = 0;
 
    //Base Extension
    string public constant baseExtension = ".json";
    ERC721 nft;
    ERC721 colorGlyphs;
    address colorGlyphsAddress = address(0x60F3680350F65Beb2752788cB48aBFCE84a4759E);
    mapping(address => bool) public crabbedAddresses;
    // Array with address 
    address[] public nftAddresses;

    mapping(uint => uint) numberIndexes;
    mapping (uint => uint) started;
    mapping (uint => uint) public numbersToUse;

    uint256 public constant salePrice = 0.002 ether;

    constructor(address cgAddress) ERC721("HermitCrabs", "HC") {
        colorGlyphsAddress = cgAddress;
        started[500] = 1;
        started[5000] = 1;
        started[100000] = 1;

        //Colorglyph numbers
        numberIndexes[500] = 141;
        numberIndexes[5000] = 158;
        numberIndexes[100000] = 159;
        deploymentBlock = block.number;
    }

    function raffle(uint number) public {
        require(started[number] == 1, "Raffle either not supposed to happen for this number, or already triggered");
        require(crabTransfers >= number, "Transfers are not at or equal to requirement");
        require(totalSupply() == MAX_SUPPLY, "All mints not done yet" );
        started[number] = block.number;
        numbersToUse[number] = block.number + 1000;
        emit RaffleStarted(block.number, numbersToUse[number], number, msg.sender);
    }

    function raffleReveal(uint number) public {
        require(block.number > numbersToUse[number], "Enough time has not passed");
        require(numbersToUse[number] > 0, "There is not supposed to be a raffle for this number, or it has not started yet");
        require(IERC721(colorGlyphsAddress).ownerOf(numberIndexes[number]) == address(this), "Contract does not own the glyph!");
        uint256 entropyBlock;
        bytes memory buffer = new bytes(32);
        if ((block.number - numbersToUse[number]) > 255) {
            entropyBlock = block.number;
        } else {
            entropyBlock = numbersToUse[number];
        }
        uint256 entropy = uint256(blockhash(entropyBlock));
        assembly { mstore(add(buffer, 32), entropy) }
        uint256 whoWon = uint256(keccak256(buffer)) % totalSupply();
        address whoToSendTo = ownerOf(whoWon);
        IERC721(colorGlyphsAddress).transferFrom(address(this), whoToSendTo, numberIndexes[number]);
        emit RaffleRevealed(numbersToUse[number], whoWon, whoToSendTo, numberIndexes[number]);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function setRevealed() external onlyOwner {
        REVEALED = true;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override(ERC721, IERC721) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        require(balanceOf(to) == 0, "Hermits like to be alone");
        if(!crabbedAddresses[to]) {
            crabTransfers += 1;
            crabbedAddresses[to] = true;
        }
        
        super._beforeTokenTransfer(from, to, tokenId);

    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function reserve(uint256 n) public onlyOwner {
      uint supply = totalSupply();
      uint i;
      for (i = 0; i < n; i++) {
          _safeMint(msg.sender, supply + i);
      }
    }
    function openMint() public onlyOwner() {
        open = true;
    }
    function mint (uint numberOfTokens) payable public {
        uint256 ts = totalSupply();
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(mints[msg.sender] != 1, "Can only mint one total");
        require(msg.value == salePrice);
        require(open == true, "Minting has not started yet");
        _safeMint(msg.sender, ts);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        ); 
        if (!REVEALED) return _baseURIextended;
        return
            string(
                abi.encodePacked(
                    _baseURIextended,
                    Strings.toString(_tokenId),
                    baseExtension
                )
            );
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}