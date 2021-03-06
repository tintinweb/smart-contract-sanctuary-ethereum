/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

pragma solidity ^0.4.25;

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier correctOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public correctOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract ERC721 {
    // Required
    function totalSupply() public view returns (uint256 total);

    function balanceOf(address _owner) public view returns (uint256 balance);

    function ownerOf(uint256 _tokenId) external view returns (address owner);

    function approve(address _to, uint256 _tokenId) external;

    function transfer(address _to, uint256 _tokenId) external;

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);
}

contract ERC721Metadata {
    /// @dev Given a token Id, returns a byte array that is supposed to be converted into string.
    function getMetadata(uint256 _tokenId, string)
        public
        pure
        returns (bytes32[4] buffer, uint256 count)
    {
        if (_tokenId == 1) {
            buffer[0] = "Hello World! :D";
            count = 15;
        } else if (_tokenId == 2) {
            buffer[0] = "I would definitely choose a medi";
            buffer[1] = "um length string.";
            count = 49;
        } else if (_tokenId == 3) {
            buffer[0] = "Lorem ipsum dolor sit amet, mi e";
            buffer[1] = "st accumsan dapibus augue lorem,";
            buffer[2] = " tristique vestibulum id, libero";
            buffer[3] = " suscipit varius sapien aliquam.";
            count = 128;
        }
    }
}

contract CanvasAdministration {
    event ContractTransfer(address newContract);

    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

    // Keep track if contract is paused or not.
    bool public paused = false;

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyAdministration() {
        require(
            msg.sender == cooAddress ||
                msg.sender == cfoAddress ||
                msg.sender == ceoAddress
        );
        _;
    }

    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }
}

contract CanvasBase is CanvasAdministration {
    // Events
    event SquareCreation(address owner, uint256 squareId);
    event Transfer(address from, address to, uint256 tokenId);

    struct Square {
        uint16 coordStartX;
        uint16 coordStartY;
        uint16 coordEndX;
        uint16 coordEndY;
        // When this square was created.
        uint64 spawnTime;
    }

    /*** STORAGE ***/

    Square[] squares;

    // @dev A mapping from square ids to the address that owns them..
    mapping(uint256 => address) public squareIndexToOwner;

    // @dev A mapping from owner address to count of tokens that address owns.
    mapping(address => uint256) ownershipTokenCount;

    // @dev A mapping from SquareIDs to an address that is approved to call transferFrom()..
    mapping(uint256 => address) public squareIndexToApproved;

    function _transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        ownershipTokenCount[_to]++;
        squareIndexToOwner[_tokenId] = _to;

        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete squareIndexToApproved[_tokenId];
        }

        emit Transfer(_from, _to, _tokenId);
    }

    function _createSquare(address _owner) public returns (uint256) {
        uint16 coordX = _calculateCoordX(squares.length + 1);
        uint16 coordY = _calculateCoordY(squares.length + 1);

        Square memory _square =
            Square({
                coordStartX: coordX,
                coordEndX: coordX + 4,
                coordStartY: coordY,
                coordEndY: coordY + 4,
                spawnTime: uint64(now)
            });

        uint256 newSquareId = squares.push(_square) - 1;

        // Make sure no more squares past 40,000
        require(newSquareId < 40000);

        emit SquareCreation(_owner, newSquareId);

        _transfer(0, _owner, newSquareId);

        return newSquareId;
    }

    function _calculateCoordX(uint256 squareId) internal pure returns (uint16) {
        return uint16(((squareId - 1) % 200) * 5);
    }

    function _calculateCoordY(uint256 squareId) internal pure returns (uint16) {
        return uint16((((squareId) - 1) / 200) * 5);
    }
}

// Manages ownership.
contract SquareOwnership is CanvasBase, ERC721 {
    // @notice Name & Symbol for the NFT, defined by ERC721
    string public constant name = "CryptoCanvas";
    string public constant symbol = "CANV";

    // The contract that will return kitty metadata
    ERC721Metadata public erc721Metadata;

    bytes4 constant InterfaceSignature_ERC165 =
        bytes4(keccak256("supportsInterface(bytes4)"));

    bytes4 constant InterfaceSignature_ERC721 =
        bytes4(keccak256("name()")) ^
            bytes4(keccak256("symbol()")) ^
            bytes4(keccak256("totalSupply()")) ^
            bytes4(keccak256("balanceOf(address)")) ^
            bytes4(keccak256("ownerOf(uint256)")) ^
            bytes4(keccak256("approve(address,uint256)")) ^
            bytes4(keccak256("transfer(address,uint256)")) ^
            bytes4(keccak256("transferFrom(address,address,uint256)")) ^
            bytes4(keccak256("tokensOfOwner(address)")) ^
            bytes4(keccak256("tokenMetadata(uint256,string)"));

    /// @notice Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
    ///  Returns true for any standardized interfaces implemented by this contract. We implement
    ///  ERC-165 (obviously!) and ERC-721.
    function supportsInterface(bytes4 _interfaceID)
        external
        pure
        returns (bool)
    {
        // DEBUG ONLY
        //require((InterfaceSignature_ERC165 == 0x01ffc9a7) && (InterfaceSignature_ERC721 == 0x9a20483d));

        return ((_interfaceID == InterfaceSignature_ERC165) ||
            (_interfaceID == InterfaceSignature_ERC721));
    }

    function _owns(address _claimer, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        return squareIndexToOwner[_tokenId] == _claimer;
    }

    function _approvedFor(address _claimer, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        return squareIndexToApproved[_tokenId] == _claimer;
    }
    
    function _approve(uint256 _tokenId, address _approved) internal {
        squareIndexToApproved[_tokenId] = _approved;
    }

    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    function totalSupply() public view returns (uint256) {
        return squares.length;
    }

    /// @dev Set the address of the sibling contract that tracks metadata.
    ///  CEO only.
    function setMetadataAddress(address _contractAddress) public onlyCEO {
        erc721Metadata = ERC721Metadata(_contractAddress);
    }

    function ownerOf(uint256 _tokenId) external view returns (address owner) {
        owner = squareIndexToOwner[_tokenId];

        require(owner != address(0));
    }

    /// @dev Required for ERC-721 compliance.
    function transfer(address _to, uint256 _tokenId) external whenNotPaused {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        require(_to != address(this));

        // You can only send your own square.
        require(_owns(msg.sender, _tokenId));

        // Reassign ownership, clear pending approvals, emit Transfer event.
        _transfer(msg.sender, _to, _tokenId);
    }

    /// @dev Required for ERC-721 compliance.
    function approve(address _to, uint256 _tokenId) external whenNotPaused {
        // Only an owner can grant transfer approval.
        require(_owns(msg.sender, _tokenId));

        // Register the approval (replacing any previous approval).
        _approve(_tokenId, _to);

        // Emit approval event.
        emit Approval(msg.sender, _to, _tokenId);
    }

    /// @dev Required for ERC-721 compliance.
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external whenNotPaused {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any kitties (except very briefly
        // after a gen0 cat is created and before it goes on auction).
        require(_to != address(this));
        // Check for approval and valid ownership
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transfer(_from, _to, _tokenId);
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalSquares = totalSupply();
            uint256 resultIndex = 0;

            uint256 squareId;

            for (squareId = 1; squareId <= totalSquares; squareId++) {
                if (squareIndexToOwner[squareId] == _owner) {
                    result[resultIndex] = squareId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function _memcpy(uint _dest, uint _src, uint _len) private pure {
        // Copy word-length chunks while possible
        for(; _len >= 32; _len -= 32) {
            assembly {
                mstore(_dest, mload(_src))
            }
            _dest += 32;
            _src += 32;
        }

        // Copy remaining bytes
        uint256 mask = 256 ** (32 - _len) - 1;
        assembly {
            let srcpart := and(mload(_src), not(mask))
            let destpart := and(mload(_dest), mask)
            mstore(_dest, or(destpart, srcpart))
        }
    }

    function _toString(bytes32[4] _rawBytes, uint256 _stringLength) private pure returns (string) {
        string memory outputString = new string(_stringLength);
        uint256 outputPtr;
        uint256 bytesPtr;

        assembly {
            outputPtr := add(outputString, 32)
            bytesPtr := _rawBytes
        }

        _memcpy(outputPtr, bytesPtr, _stringLength);

        return outputString;
    }

    function tokenMetadata(uint256 _tokenId, string _preferredTransport) external view returns (string infoUrl) {
        require(erc721Metadata != address(0));
        bytes32[4] memory buffer;
        uint256 count;
        (buffer, count) = erc721Metadata.getMetadata(_tokenId, _preferredTransport);

        return _toString(buffer, count);
    }
}

contract Pausible is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() public onlyOwner whenNotPaused returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }

    function unpause() public onlyOwner whenPaused returns (bool) {
        paused = false;
        emit Unpause();
        return true;
    }
}

/** Main Contract **/
contract CanvasCore is Pausible, SquareOwnership {
    address public newContractAddress;

    constructor() public {
        paused = false;

        ceoAddress = msg.sender;
        cooAddress = msg.sender;
        cfoAddress = msg.sender;

        _createSquare(msg.sender);
    }

    function setNewAddress(address _v2Address) external onlyCEO whenPaused {
        newContractAddress = _v2Address;
        emit ContractTransfer(_v2Address);
    }

    function getSquare(uint256 tokenId)
        external
        view
        returns (
            uint16 coordX,
            uint16 coordY,
            address ownerId
        )
    {
        Square storage square = squares[tokenId];

        coordX = square.coordStartX;
        coordY = square.coordStartY;
        ownerId = squareIndexToOwner[tokenId];
    }
}