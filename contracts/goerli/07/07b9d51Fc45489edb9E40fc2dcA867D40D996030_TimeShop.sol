/*

░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░                                                        ░░
░░    9 9 9 9 9    9 9 9 9 9    9 9 9 9 9    9 9 9 9 9    ░░
░░   9         9  9         9  9         9  9         9   ░░
░░   9         9  9         9  9         9  9         9   ░░
░░   9         9  9         9  9         9  9         9   ░░
░░    9 9 9 9 9    9 9 9 9 9    9 9 9 9 9    9 9 9 9 9    ░░
░░   .         9  .         9  .         9  .         9   ░░
░░   .         9  .         9  .         9  .         9   ░░
░░   .         9  .         9  .         9  .         9   ░░
░░    9 9 9 9 9    9 9 9 9 9    9 9 9 9 9    9 9 9 9 9    ░░
░░                                                        ░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Utilities.sol";
import "./Segments.sol";
import "./IERC4906.sol";

contract TimeShop is ERC721A, Ownable, IERC4906 {
    
    event CountdownExtended(uint _finalBlock);

    uint public price = 3000000000000000; //.003 eth
    bool public isCombinable = false;
    uint public finalMintingBlock;

    mapping(uint => uint) newValues;
    mapping(address => uint) freeMints;

    constructor() ERC721A("Time Shop", "TIME") {}

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
        if (supply >= 1000) {
            require(utils.secondsRemaining(finalMintingBlock) > 0, "mint is closed");
            if (supply < 5000 && (supply + quantity) >= 5000) {
                finalMintingBlock = block.timestamp + 24 hours;
                emit CountdownExtended(finalMintingBlock);
            }
        } else if (supply + quantity >= 1000) {
            finalMintingBlock = block.timestamp + 24 hours;
            emit CountdownExtended(finalMintingBlock);
        }
        _mint(recipient, quantity);
    }

    function combine(uint[] memory tokens) public {
        require(isCombinable, "combining not active");
        uint sum;
        for (uint i = 0; i < tokens.length; i++) {
            require(ownerOf(tokens[i]) == msg.sender, "must own all tokens");
            sum = sum + getValue(tokens[i]);
        }
        if (sum > 31535999999) {
            revert("sum must be 31535999999 or less");
        }
        for (uint i = 1; i < tokens.length; i++) {
            _burn(tokens[i]);
            newValues[tokens[i]] = 0;
            emit MetadataUpdate(tokens[i]);
        }

        // Why was 6 afraid of 7? Because 7 8 9!
        newValues[tokens[0]] = sum;
        emit MetadataUpdate(tokens[0]);
    }

    function getValue(uint256 tokenId) public view returns (uint) {
        if (!_exists(tokenId)) {
            return 0;
        } else if (newValues[tokenId] > 0) {
            return newValues[tokenId];
        } else {
            return utils.initValue(tokenId);
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        bool burned;
        uint value;

        if (newValues[tokenId] > 0) {
            value = newValues[tokenId];
            burned = false;
        } else if (newValues[tokenId] == 0 && !_exists(tokenId)) {
            value = 0;
            burned = true;
        } else {
            value = utils.initValue(tokenId);
            burned = false;
        }

        return segments.getMetadata(tokenId, value, burned);
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

    function toggleCombinable() public onlyOwner {
        isCombinable = !isCombinable;
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
}