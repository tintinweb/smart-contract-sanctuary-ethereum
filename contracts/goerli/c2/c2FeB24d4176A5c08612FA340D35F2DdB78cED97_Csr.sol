// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns(bytes4);
}

contract Csr {

    event Generated(uint indexed index, address indexed a, string value);

    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    // ERC 165
    mapping(bytes4 => bool) internal supportedInterfaces;

    /**
     * @dev A mapping from NFT ID to the address that owns it.
     */
    mapping (uint256 => address) internal idToOwner;

    /**
     * @dev Mapping from NFT ID to approved address.
     */
    mapping (uint256 => address) internal idToApproval;

    /**
     * @dev Mapping from owner address to mapping of operator addresses.
     */
    mapping (address => mapping (address => bool)) internal ownerToOperators;

    /**
     * @dev Mapping from owner to list of owned NFT IDs.
     */
    mapping(address => uint256[]) internal ownerToIds;

    /**
     * @dev Mapping from NFT ID to its index in the owner tokens list.
     */
    mapping(uint256 => uint256) internal idToOwnerIndex;

    /**
     * @dev Total number of tokens.
     */
    uint internal numTokens = 0;

    /**
     * @dev Guarantees that the msg.sender is an owner or operator of the given NFT.
     * @param _tokenId ID of the NFT to validate.
     */
    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender]);
        _;
    }

    /**
     * @dev Guarantees that the msg.sender is allowed to transfer NFT.
     * @param _tokenId ID of the NFT to transfer.
     */
    modifier canTransfer(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tokenOwner == msg.sender
            || idToApproval[_tokenId] == msg.sender
            || ownerToOperators[tokenOwner][msg.sender]
        );
        _;
    }

    /**
     * @dev Guarantees that _tokenId is a valid Token.
     * @param _tokenId ID of the NFT to validate.
     */
    modifier validNFToken(uint256 _tokenId) {
        require(idToOwner[_tokenId] != address(0));
        _;
    }

    struct Trait {
        string background;
        uint len;
        mapping(uint => OneTrait) elements;
    }

    struct OneTrait {
        uint figure;
        uint cx;
        uint cy;
        uint width;
        uint height;
        string color;
    }

    /** 
     * @dev Nfts collection.
     */
    mapping(uint => Trait) nfts;

    /**
     * @dev List of nft figures color.
     */
    string[] internal colors = ['bf392b','e74c3c','9b59b6','8d44ad','2980b9','3398da','1abc9b','169f85','26ae60','2fcb71','f1c40f','f39c13','e57e23','d35400','808b96','17202a','e6b0aa','f7dc6f','f8c370','7fb3d5'];
    
    /**
     * @dev List of nfts background color.
     */
    string[] internal background = ['f2d7d5', 'fadbd8', 'ebdef0', 'e8daee', 'd3e6f1', 'd6eaf8','d0f2eb', 'cfece7','d4efdf','d5f5e3','fbf3cf','fdebd0','f9e5d3','f6ddcc','fbfcfc'];   
    
    string internal nftName = "CircleSquareRectangle";
    string internal nftSymbol = "CSR";
    
    string internal constant s1 = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 500 500"><rect y="0" x="0" width="500" height="500" fill="#';
    string internal constant s2 = '</svg>';
    string internal constant s3 = '"/>';

    uint public constant TOKEN_LIMIT = 515; // nfts limit
    uint[] internal nftsQty; // max quantity of nfts by type
    uint[] internal nftsQtyCurrent = [0,0,0]; // current quantity of nfts by type

    /**
     * @dev Contract constructor.
     */
    constructor() {
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        supportedInterfaces[0x780e9d63] = true; // ERC721 Enumerable
        supportedInterfaces[0x5b5e139f] = true; // ERC721 Metadata

        nftsQty.push(464); // 0
        nftsQty.push(32); // 1
        nftsQty.push(16); // 2

        // generate
        // kind 0
        draw(1, 0);
        _addNFToken(msg.sender, 1);
        // kind 1
        draw(2, 1);
        _addNFToken(msg.sender, 2);
        // kind 2
        draw(3, 2);
        _addNFToken(msg.sender, 3);

        numTokens = 3;
        nftsQtyCurrent[0] = 1;
        nftsQtyCurrent[1] = 1;
        nftsQtyCurrent[2] = 1;
    }

    /**
     * Generate random number between A and B.
     * @param _seed integer seed number
     * @param _a minimum number
     * @param _b maximim number
     * @return integer number
     */
    function minMax(uint _seed, uint _a, uint _b) internal view returns (uint) {
        return uint(uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, _seed)))%uint(_b-_a+1))+_a;
    }

    /**
     * Convert uint to string.
     * @param _i uint
     * @return _uintAsString string
     */
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
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /**
     * @dev create rectangle.
     * @param _cx cx coordinate.
     * @param _cy cy coordinate.
     * @param _radius figure's radius.
     * @param fill figure's color.
     * @param stroke figure's stroke color.
     */
    function createCircle(uint _cx, uint _cy, uint _radius, string memory fill, string memory stroke) internal pure returns(string memory) {
        return string.concat('<circle cx="', uint2str(_cx), '" cy="', uint2str(_cy), '" r="', uint2str(_radius), '"', (bytes(stroke).length > 0 ? string.concat(' stroke="#', stroke, '" stroke-width="10"') : ''), ' fill="', (bytes(fill).length > 0 ? string.concat('#', fill) : 'none'), s3);
    }

    /**
     * @dev create rectangle.
     * @param _y y coordinate.
     * @param _x x coordinate.
     * @param _height figure's height.
     * @param _width figure's width.
     * @param color figure's color.
     */
    function createRectangle(uint _y, uint _x, uint _height, uint _width, string memory color) pure internal returns(string memory) {
        return string.concat('<rect y="', uint2str(_y), '" x="', uint2str(_x), '" height="', uint2str(_height), '" width="', uint2str(_width), '" fill="#', color, s3);
    }
    
    /**
     * @dev create one figure.
     * Available circle, square, rectangle
     * @param _figure figure.
     * @param _cx xc coordinate.
     * @param _cy cy coordinate.
     * @param _width figure's width.
     * @param _width figure's width.
     * @param color figure's color.
     */
    function createFigure(uint _figure, uint _cx, uint _cy, uint _width, uint _height, string memory color) internal view returns(string memory) {
        string memory out;
        if (_figure >= 0 && _figure <= 35) {
            out = string.concat(out, createCircle(_cx, _cy, _width, color, ''));
        } else if (_figure > 35 && _figure <= 75) {
            out = string.concat(out, createRectangle(_cx, _cy, _height, _width, color));
        } else if (_figure > 75 && _figure <= 95) {
            out = string.concat(out, createCircle(_cx, _cy, _width, '', color));
        } else if (_figure > 95) {
            _width = minMax(_cx * _cy * 2, 65, 100);
            for (uint i = 0; i < 3; i++) { 
                out = string.concat(out, createCircle(_cx, _cy, _width, '', color));
                _width-=15;
            }
        }
        return out;
    }

    /**
     * @dev return generated nft.
     * @param _tokenId id of nft.
     * @return nfts string
     */
    function drawByKind(uint _tokenId) internal view returns (string memory) {
        require(numTokens >= _tokenId, "no nft");
        string memory out;
        uint figure;
        uint cx;
        uint cy;
        uint width;
        uint height;
        string memory color;
        bool _generate;
        out = string.concat(out, s1, nfts[_tokenId].background, s3);
        if (nfts[_tokenId].elements[0].figure == 0) _generate = true;
        for(uint i = 0; i<nfts[_tokenId].len; i++) {
            figure = nfts[_tokenId].elements[i].figure;
            cx = nfts[_tokenId].elements[i].cx;
            cy = nfts[_tokenId].elements[i].cy;
            width = nfts[_tokenId].elements[i].width;
            if (_generate) {
                figure = minMax(i * 12, 0, 100);
                cx = minMax(cx * cy * figure * i * 16, cx - 25, cx + 25);
                cy = minMax(cx * cy * i * 17, cy - 25, cy + 25);
                width = minMax(cx * cy * figure * i * 19, 5, 100);
                height = (figure > 55 && figure <= 75) ? minMax(cx * cy * 512, 45, 100) : width;
            }
            if (bytes(nfts[_tokenId].elements[i].color).length == 0 || _generate) {
                color = colors[minMax(block.timestamp * i, 0, colors.length - 1)];
            } else {
                color = nfts[_tokenId].elements[i].color;
            }
            out = string.concat(out, createFigure(figure, cx, cy, width, height, color));
        }
        return string.concat(out, s2);
    }

    /**
     * Generate new NFT.
     * @param _tokenId uint - token id.
     * @param _kind uint8 - type of nft.
     */
    function draw(uint _tokenId, uint8 _kind) internal returns (string memory) {
        Trait storage t = nfts[_tokenId];
        OneTrait memory ot;
        uint figure;
        uint8 k = _kind;
        bool isShow;
        uint cx;
        uint cy;
        uint width;
        uint height;
        uint index;
        string memory out;
        string memory color;
        string memory backgroundColor = background[minMax(block.timestamp, 0, background.length - 1)];
        out = string.concat(out, s1, backgroundColor, s3);
        for(uint y = 0; y < 500; y+=50) {

            for(uint x = 0; x < 500; x+=50) {

                isShow = minMax(y * x * 128, 0, 100) > 80;
                if (isShow) {
                    figure = minMax(y * x * 64, 0, 100);
                    cx = minMax(y * x * figure, (x < 25 ? 0 : x - 25), x + 25);
                    cy = minMax(y * x * cx, (y < 25 ? 0 : y - 25), y + 25);
                    width = minMax(x * y * cy, 5, 100);
                    color = colors[minMax(x * y * width, 0, colors.length - 1)];
                    height = (figure > 55 && figure <= 75) ? minMax(cx * cy * 512, 45, 100) : width;
                    out = string.concat(out, createFigure(figure, cx, cy, width, height, color));
                    if (k == 1) {
                        color = '';
                    }
                    if (k == 2) {
                        figure = 0;
                        color = '';
                    }
                    ot = OneTrait(figure, cx, cy, width, height, color);
                    t.elements[index] = ot;
                    index++;
                }
            }
        }
        t.background = backgroundColor;
        t.len = index;
        return string.concat(out, s2);
    }

    /**
     * Create Circle Square Rectangle figure.
     */
    function createCsr() external payable returns (string memory) {
        return _mint(msg.sender);
    }

    //////////////////////////
    //// ERC 721 and 165  ////
    //////////////////////////
    function isContract(address _addr) internal view returns (bool addressCheck) {
        uint256 size;
        assembly { size := extcodesize(_addr) } // solhint-disable-line
        addressCheck = size > 0;
    }

    /**
     * @dev Function to check which interfaces are suported by this contract.
     * @param _interfaceID Id of the interface.
     * @return True if _interfaceID is supported, false otherwise.
     */
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return supportedInterfaces[_interfaceID];
    }

    /**
     * @dev Transfers the ownership of an NFT from one address to another address. This function can
     * be changed to payable.
     * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
     * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
     * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
     * function checks if `_to` is a smart contract (code size > 0). If so, it calls
     * `onERC721Received` on `_to` and throws if the return value is not
     * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
     * @param _from The current owner of the NFT.
     * @param _to The new owner.
     * @param _tokenId The NFT to transfer.
     * @param _data Additional data with no specified format, sent in call to `_to`.
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) external {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

    /**
     * @dev Transfers the ownership of an NFT from one address to another address. This function can
     * be changed to payable.
     * @notice This works identically to the other function with an extra data parameter, except this
     * function just sets data to ""
     * @param _from The current owner of the NFT.
     * @param _to The new owner.
     * @param _tokenId The NFT to transfer.
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    /**
     * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
     * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
     * address. Throws if `_tokenId` is not a valid NFT. This function can be changed to payable.
     * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
     * they maybe be permanently lost.
     * @param _from The current owner of the NFT.
     * @param _to The new owner.
     * @param _tokenId The NFT to transfer.
     */
    function transferFrom(address _from, address _to, uint256 _tokenId) external canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from);
        require(_to != address(0));
        _transfer(_to, _tokenId);
    }

    /**
     * @dev Set or reaffirm the approved address for an NFT. This function can be changed to payable.
     * @notice The zero address indicates there is no approved address. Throws unless `msg.sender` is
     * the current NFT owner, or an authorized operator of the current owner.
     * @param _approved Address to be approved for the given NFT ID.
     * @param _tokenId ID of the token to be approved.
     */
    function approve(address _approved, uint256 _tokenId) external canOperate(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(_approved != tokenOwner);
        idToApproval[_tokenId] = _approved;
        emit Approval(tokenOwner, _approved, _tokenId);
    }

    /**
     * @dev Enables or disables approval for a third party ("operator") to manage all of
     * `msg.sender`'s assets. It also emits the ApprovalForAll event.
     * @notice This works even if sender doesn't own any tokens at the time.
     * @param _operator Address to add to the set of authorized operators.
     * @param _approved True if the operators is approved, false to revoke approval.
     */
    function setApprovalForAll(address _operator, bool _approved) external {
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
     * considered invalid, and this function throws for queries about the zero address.
     * @param _owner Address for whom to query the balance.
     * @return Balance of _owner.
     */
    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0));
        return _getOwnerNFTCount(_owner);
    }

    /**
     * @dev Returns the address of the owner of the NFT. NFTs assigned to zero address are considered
     * invalid, and queries about them do throw.
     * @param _tokenId The identifier for an NFT.
     * @return _owner Address of _tokenId owner.
     */
    function ownerOf(uint256 _tokenId) external view returns (address _owner) {
        _owner = idToOwner[_tokenId];
        require(_owner != address(0));
    }

    /**
     * @dev Get the approved address for a single NFT.
     * @notice Throws if `_tokenId` is not a valid NFT.
     * @param _tokenId ID of the NFT to query the approval of.
     * @return Address that _tokenId is approved for.
     */
    function getApproved(uint256 _tokenId) external view validNFToken(_tokenId) returns (address) {
        return idToApproval[_tokenId];
    }

    /**
     * @dev Checks if `_operator` is an approved operator for `_owner`.
     * @param _owner The address that owns the NFTs.
     * @param _operator The address that acts on behalf of the owner.
     * @return True if approved for all, false otherwise.
     */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return ownerToOperators[_owner][_operator];
    }

    /**
     * @dev Actually preforms the transfer.
     * @notice Does NO checks.
     * @param _to Address of a new owner.
     * @param _tokenId The NFT that is being transferred.
     */
    function _transfer(address _to, uint256 _tokenId) internal {
        address from = idToOwner[_tokenId];
        _clearApproval(_tokenId);

        _removeNFToken(from, _tokenId);
        _addNFToken(_to, _tokenId);

        emit Transfer(from, _to, _tokenId);
    }

    /**
     * @dev Mints a new NFT.
     * @notice This is an internal function which should be called from user-implemented external
     * mint function. Its purpose is to show and properly initialize data structures when using this
     * implementation.
     * @param _to The address that will own the minted NFT.
     */
    function _mint(address _to) internal returns (string memory) {
        require(_to != address(0),'null adress');
        require(numTokens < TOKEN_LIMIT);
        uint8 kind; // NFT_SIMPLE
        if (msg.value == 50000000000000000) {
            kind = 1; // NFT_NO_COLOR
        } else if(msg.value == 80000000000000000) {
            kind = 2; // NFT_RANDOM
        }
        // simple nfts check
        if(kind == 0 && msg.value != 30000000000000000) { revert(); }
        // can generate nfts by type
        require(nftsQty[kind] >= nftsQtyCurrent[kind] + 1, "no nfts by this type.");
        uint id = numTokens + 1;
        string memory uri = draw(id, kind);
        emit Generated(id, _to, uri);

        numTokens++;
        nftsQtyCurrent[kind]++;
        _addNFToken(_to, id);

        emit Transfer(address(0), _to, id);
        return uri;
    }

    /**
     * @dev Assigns a new NFT to an address.
     * @notice Use and override this function with caution. Wrong usage can have serious consequences.
     * @param _to Address to which we want to add the NFT.
     * @param _tokenId Which NFT we want to add.
     */
    function _addNFToken(address _to, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == address(0));
        idToOwner[_tokenId] = _to;
        ownerToIds[_to].push(_tokenId);
        uint256 length = ownerToIds[_to].length;
        idToOwnerIndex[_tokenId] = length - 1;
    }

    /**
     * @dev Removes a NFT from an address.
     * @notice Use and override this function with caution. Wrong usage can have serious consequences.
     * @param _from Address from wich we want to remove the NFT.
     * @param _tokenId Which NFT we want to remove.
     */
    function _removeNFToken(address _from, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == _from);
        delete idToOwner[_tokenId];

        uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
        uint256 lastTokenIndex = ownerToIds[_from].length - 1;

        if (lastTokenIndex != tokenToRemoveIndex) {
            uint256 lastToken = ownerToIds[_from][lastTokenIndex];
            ownerToIds[_from][tokenToRemoveIndex] = lastToken;
            idToOwnerIndex[lastToken] = tokenToRemoveIndex;
        }

        ownerToIds[_from].pop();
    }

    /**
     * @dev Helper function that gets NFT count of owner. This is needed for overriding in enumerable
     * extension to remove double storage (gas optimization) of owner nft count.
     * @param _owner Address for whom to query the count.
     * @return Number of _owner NFTs.
     */
    function _getOwnerNFTCount(address _owner) internal view returns (uint256) {
        return ownerToIds[_owner].length;
    }

    /**
     * @dev Actually perform the safeTransferFrom.
     * @param _from The current owner of the NFT.
     * @param _to The new owner.
     * @param _tokenId The NFT to transfer.
     * @param _data Additional data with no specified format, sent in call to `_to`.
     */
    function _safeTransferFrom(address _from,  address _to,  uint256 _tokenId,  bytes memory _data) private canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from);
        require(_to != address(0));

        _transfer(_to, _tokenId);

        if (isContract(_to)) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == MAGIC_ON_ERC721_RECEIVED);
        }
    }

    /**
     * @dev Clears the current approval of a given NFT ID.
     * @param _tokenId ID of the NFT to be transferred.
     */
    function _clearApproval(uint256 _tokenId) private {
        if (idToApproval[_tokenId] != address(0)) {
            delete idToApproval[_tokenId];
        }
    }

    //// Enumerable

    /**
     * @dev Count NFTs tracked by this contract
     * @return A count of valid NFTs tracked by this contract, where each one of
     * them has an assigned and queryable owner not equal to the zero address
     */
    function totalSupply() public view returns (uint256) {
        return numTokens;
    }

    /**
     * @dev Throws if `_index` >= `totalSupply()`.
     * @param _index A counter less than `totalSupply()`
     * @return The token identifier for the `_index`th NFT,
     */
    function tokenByIndex(uint256 _index) public view returns (uint256) {
        require(_index < numTokens);
        return _index;
    }

    /**
     * @dev returns the n-th NFT ID from a list of owner's tokens.
     * @param _owner Token owner's address.
     * @param _index Index number representing n-th token in owner's list of tokens.
     * @return Token id.
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        require(_index < ownerToIds[_owner].length);
        return ownerToIds[_owner][_index];
    }

    //// Metadata

    /**
      * @dev Returns a descriptive name for a collection of NFTokens.
      * @return _name Representing name.
      */
    function name() external view returns (string memory _name) {
        _name = nftName;
    }

    /**
     * @dev Returns an abbreviated name for NFTokens.
     * @return _symbol Representing symbol.
     */
    function symbol() external view returns (string memory _symbol) {
        _symbol = nftSymbol;
    }

    /**
     * @dev A distinct URI (RFC 3986) for a given NFT.
     * @param _tokenId Id for which we want uri.
     * @return URI of _tokenId.
     */
    function tokenURI(uint256 _tokenId) external view validNFToken(_tokenId) returns (string memory) {
        return drawByKind(_tokenId);
    }
}