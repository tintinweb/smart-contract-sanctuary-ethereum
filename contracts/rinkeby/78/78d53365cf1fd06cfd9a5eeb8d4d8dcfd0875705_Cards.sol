// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./RandomGenerator.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./ERC165.sol";
import "./CardCatalog.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";

contract Cards is IERC721, ERC165, IERC721Metadata, IERC721Enumerable {
    struct Card {
        uint16 image;
        uint8 border;
        uint8[] runes;
        uint8[] crystals;
    }

    uint16[] private countDistribution = [6000, 9000];
    uint16[] private runesDistribution = [2408, 4228, 5648, 6848, 7848, 8648, 9048, 9348, 9548, 9698, 9798, 9878, 9938, 9962, 9977, 9987, 9988, 9995];
    uint16[] private crystalDistribution = [1400, 2600, 3600, 4520, 5340, 6070, 6720, 7270, 7780, 8230, 8640, 9000, 9310, 9560, 9770, 9900, 9990];
    uint16[] private borderDistribution = [1500, 2700, 3800, 4800, 5700, 6500, 7200, 7800, 8300, 8700, 9000, 9250, 9450, 9600, 9720, 9820, 9900, 9950, 9985];

    uint64[] private _mintedCards;
    address public minterAddress;
    address public stakerAddress;
    string private _name;
    string private _symbol;
    string private _baseUri;
    RandomGenerator private randomGeneratorContract;
    CardCatalog private cardCatalogContract;

    address[] private _owners;
    mapping (address => uint256[]) private _tokensByOwners;
    mapping (uint256 => address) private _tokenApprovals;
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    mapping (uint256 => uint256) private _tokenLockId;

    constructor(
        address _randomGeneratorContractAddress,
        address _stakerContractAddress,
        address _cardCatalogContractAddress,
        string memory __name,
        string memory __symbol,
        string memory __baseUri
    ) {
        minterAddress = msg.sender;
        stakerAddress = _stakerContractAddress;
        randomGeneratorContract = RandomGenerator(_randomGeneratorContractAddress);
        cardCatalogContract = CardCatalog(_cardCatalogContractAddress);
        _name = __name;
        _symbol = __symbol;
        _baseUri = __baseUri;
    }

    function generateBorder() private view returns (uint8 border) {
        return getIntByDistribution(borderDistribution);
    }

    function generateCount() private view returns (uint8 count) {
        return getIntByDistribution(countDistribution) + 1;
    }

    function generateRunes() private view returns (uint8[] memory) {
        return getArrayByDistribution(generateCount(), runesDistribution);
    }

    function generateCrystals() private view returns (uint8[] memory) {
        return getArrayByDistribution(generateCount(), crystalDistribution);
    }

    function getIntByDistribution(uint16[] memory distribution) private view returns (uint8) {
        uint16 rnd = uint16(randomGeneratorContract.random() % 10000);
        uint8 j;
        for (j = 0; j < distribution.length && rnd >= distribution[j]; j++) {}
        return j;
    }

    function getArrayByDistribution(uint8 count, uint16[] memory distribution) private view returns (uint8[] memory) {
        uint8[] memory values = new uint8[](count);
        uint8 k;
        bool isDuplicate;
        for (uint8 i = 0; i < count; i ++) {
            do {
                values[i] = getIntByDistribution(distribution);
                isDuplicate = false;
                for (k = 0; k < i; k ++) {
                    if (values[i] == values[k]) {
                        isDuplicate = true;
                    }
                }
            } while (isDuplicate);
        }

        return values;
    }

    function mintCard(address cardOwner, uint16 imageId) public onlyMinter {
        _mintedCards.push(cardToInt(Card(
            imageId,
            generateBorder(),
            generateRunes(),
            generateCrystals()
        )));
        _owners.push(cardOwner);
        uint256 tokenId = _mintedCards.length - 1;
        _tokensByOwners[cardOwner].push(tokenId);
    }

    function setBaseUri(string memory baseUri) public onlyMinter {
        _baseUri = baseUri;
    }

    function baseUri() public view returns (string memory) {
        return _baseUri;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
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
            bstr[k] = bytes1(uint8(48 + _i % 10));
            if (k > 0) {
                k--;
            }
            _i /= 10;
        }
        return string(bstr);
    }

    function _cardToUriParams(uint256 tokenId, Card memory card) internal pure returns (string memory) {
        uint8 i;
        bytes memory runesString;
        bytes memory crystalsString;

        bytes memory lowerDash = bytes("_");
        bytes memory dash = bytes("-");

        for (i = 0; i < card.runes.length; i++) {
            runesString = bytes.concat(runesString, bytes(uint2str(card.runes[i] + 1)), lowerDash);
        }
        for (i = 0; i < card.crystals.length; i++) {
            crystalsString = bytes.concat(crystalsString, bytes(uint2str(card.crystals[i] + 1)), lowerDash);
        }
        return string(bytes.concat(
                bytes(uint2str(tokenId)),
                dash,
                bytes(uint2str(card.image + 1)),
                dash,
                bytes(uint2str(card.border + 1)),
                dash,
                bytes(crystalsString),
                dash,
                bytes(runesString)
            ));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        return _cardToUriParams(tokenId, intToCard(_mintedCards[tokenId]));
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(_tokenLockId[tokenId] == 0, "ERC721: token is locked for minting");

//        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _owners[tokenId] = to;

        _tokensByOwners[to][_tokensByOwners[to].length] = tokenId;

        for (uint256 i = 0; i < _tokensByOwners[from].length; i++) {
            if (_tokensByOwners[from][i] == tokenId) {
                _tokensByOwners[from][i] = _tokensByOwners[from][_tokensByOwners[from].length - 1];
                _tokensByOwners[from].pop();
                break;
            }
        }
        _tokensByOwners[from][_tokensByOwners[from].length] = tokenId;

        emit Transfer(from, to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (isContract(to)) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return 1;
    }

    function getTokenRunes(uint256 tokenId) public view returns (uint8[] memory) {
        require(_exists(tokenId));
        return intToCard(_mintedCards[tokenId]).runes;
    }

    function getTokenCrystals(uint256 tokenId) public view returns (uint8[] memory) {
        require(_exists(tokenId));
        return intToCard(_mintedCards[tokenId]).crystals;
    }

    function getTokenImage(uint256 tokenId) public view returns (uint16) {
        require(_exists(tokenId));
        return intToCard(_mintedCards[tokenId]).image;
    }

    function isLocked(uint256 tokenId) public view returns (bool) {
        return _tokenLockId[tokenId] != 0;
    }

    function getLockId(uint256 tokenId) public view returns (uint256) {
        require(isLocked(tokenId));
        return _tokenLockId[tokenId];
    }

    function lockTokens(uint256[] memory tokenIds, uint256 lockId) public onlyStaker {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _tokenLockId[tokenIds[i]] = lockId + 1;
        }
    }

    function unlockTokens(uint256[] memory tokenIds) public onlyStaker {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_tokenLockId[tokenIds[i]] != 0, "Some tokens are not locked");
            delete _tokenLockId[tokenIds[i]];
        }
    }

    function cardEnergy(uint256 tokenId) public view returns (uint16) {
        require(_exists(tokenId), "Getting energy of non-existent token");
        Card memory card = intToCard(_mintedCards[tokenId]);
        uint16 imageEnergy = cardCatalogContract.getCard(card.image).energy;
        uint16 addEnergy = 0;
        uint16 energyMultiplier = 1;
        for (uint256 i = 0; i < card.runes.length; i++) {
            if (card.runes[i] < 16 || card.runes[i] == 17) {
                addEnergy += card.runes[i] + 1;
            }
            else if (card.runes[i] == 16) {
                energyMultiplier *= 2;
            }
            else if (card.runes[i] == 18) {
                addEnergy += 20;
            }
        }
        return energyMultiplier * imageEnergy + addEnergy;
    }

    function getCardsByOwner(address owner) public view returns (uint256[] memory) {
        return _tokensByOwners[owner];
    }

    function cardToInt(Card memory cardStruct) public pure returns (uint64) {
        uint64 cardInt = 0;
        uint8 i;

        uint8 fiveBitsOn = 31;

        // crystals
        for (i = 0; i < cardStruct.crystals.length; i++) {
            cardInt = (cardInt << 5) + cardStruct.crystals[i];
        }
        while (i < 3) {
            cardInt = (cardInt << 5) + fiveBitsOn;
            i++;
        }

        //runes
        for (i = 0; i < cardStruct.runes.length; i++) {
            cardInt = (cardInt << 5) + cardStruct.runes[i];
        }
        while (i < 3) {
            cardInt = (cardInt << 5) + fiveBitsOn;
            i++;
        }

        //border
        cardInt = (cardInt << 5) + cardStruct.border;

        //image
        cardInt = (cardInt << 16) + cardStruct.image;
        return cardInt;
    }

    function intToCard(uint64 cardInt) public pure returns (Card memory) {
        Card memory cardStruct;
        uint8 fiveBitsOn = 31;
        uint8 a;
        uint8 b;
        uint8 c;

        cardStruct.image = uint16(cardInt & 0xffff);
        cardInt = cardInt >> 16;

        cardStruct.border = uint8(cardInt & fiveBitsOn);
        cardInt = cardInt >> 5;

        //runes
        a = uint8(cardInt & fiveBitsOn);
        cardInt = cardInt >> 5;
        b = uint8(cardInt & fiveBitsOn);
        cardInt = cardInt >> 5;
        c = uint8(cardInt & fiveBitsOn);
        cardInt = cardInt >> 5;
        if (a != fiveBitsOn) {
            cardStruct.runes = new uint8[](3);
            cardStruct.runes[0] = c;
            cardStruct.runes[1] = b;
            cardStruct.runes[2] = a;
        } else if (b != fiveBitsOn) {
            cardStruct.runes = new uint8[](2);
            cardStruct.runes[0] = c;
            cardStruct.runes[1] = b;
        } else {
            cardStruct.runes = new uint8[](1);
            cardStruct.runes[0] = c;
        }

        // crystals
        a = uint8(cardInt & fiveBitsOn);
        cardInt = cardInt >> 5;
        b = uint8(cardInt & fiveBitsOn);
        cardInt = cardInt >> 5;
        c = uint8(cardInt & fiveBitsOn);
        cardInt = cardInt >> 5;
        if (a != fiveBitsOn) {
            cardStruct.crystals = new uint8[](3);
            cardStruct.crystals[0] = c;
            cardStruct.crystals[1] = b;
            cardStruct.crystals[2] = a;
        } else if (b != fiveBitsOn) {
            cardStruct.crystals = new uint8[](2);
            cardStruct.crystals[0] = c;
            cardStruct.crystals[1] = b;
        } else {
            cardStruct.crystals = new uint8[](1);
            cardStruct.crystals[0] = c;
        }

        return cardStruct;
    }

    function totalSupply() external view override returns (uint256) {
        return _mintedCards.length;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) external view override returns (uint256) {
        return _tokensByOwners[owner][index];
    }

    function tokenByIndex(uint256 index) external view override returns (uint256) {
        return _mintedCards[index];
    }



    function supportsInterface(bytes4 interfaceId) public view override (ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    modifier onlyMinter {
        require(
            msg.sender == minterAddress,
            "Only owner can call this function."
        );
        _;
    }

    modifier onlyStaker {
        require(
            msg.sender == stakerAddress,
            "Only staker can call this function."
        );
        _;
    }
}