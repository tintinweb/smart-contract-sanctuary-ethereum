// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Utilities.sol";
import "./Segments.sol";
import "./IERC4906.sol";

contract NeoCheck is ERC721A, Ownable, IERC4906 {
    
    event CountdownExtended(uint _finalBlock);

    uint public price = 3000000000000000; //.003 eth
    uint public finalMintingBlock;

    mapping(uint => uint) baseColors;
    mapping(address => uint) freeMints;

    constructor() ERC721A("Neo Check", "NEOCHECK") {      
    }

    function mint(uint quantity) public payable {
        require(msg.value >= quantity * price, "not enough eth");
        handleMint(msg.sender, quantity);
    }

    function freeMint(uint quantity) public {
        require(quantity <= freeMints[msg.sender], "not enough free mints");
        handleMint(msg.sender, quantity);
        freeMints[msg.sender] -= quantity;
    }

    function handleMint(address recipient, uint quantity) internal {
        uint supply = _totalMinted();
        if (supply >= 5000) {
            require(utils.secondsRemaining(finalMintingBlock) > 0, "mint is closed");
            if (supply < 8000 && (supply + quantity) >= 8000) {
                finalMintingBlock = block.timestamp + 24 hours;
                emit CountdownExtended(finalMintingBlock);
            }
        } else if (supply + quantity >= 5000) {
            finalMintingBlock = block.timestamp + 24 hours;
            emit CountdownExtended(finalMintingBlock);
        }
        _mint(recipient, quantity);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        return segments.getMetadata(tokenId);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function getMinutesRemaining() public view returns (uint) {
        return utils.minutesRemaining(finalMintingBlock);
    }

    function mintCount() public view returns (uint) {
        return _totalMinted();
    }

    function withdraw() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function freeMintBalance(address addy) public view returns (uint) {
        return freeMints[addy];
    }

    function addFreeMints(address[] calldata addresses, uint quantity) public onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            freeMints[addresses[i]] = quantity;
        }
    }

    function mint4Owner(uint quantity) public onlyOwner {
        handleMint(msg.sender, quantity);
    }
}