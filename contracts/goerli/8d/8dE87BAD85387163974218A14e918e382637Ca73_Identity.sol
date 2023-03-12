/**
 *Submitted for verification at Etherscan.io on 2023-03-12
*/

pragma solidity >=0.8.0;

// SPDX-License-Identifier: AGPL-3.0-only
contract Identity {
    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    string public name = "Antony Identity";
    string public symbol = "0xAntony";

    address public deployer;
    string baseUri;

    mapping(uint256 => address) internal _ownerOf;
    mapping(address => uint256) internal _balanceOf;

    uint256 public totalSupply = 0;
    uint256 internal _startId = 0;

    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    constructor(string memory _baseUri) {
        deployer = msg.sender;
        baseUri = _baseUri;
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "NOT_AUTHORIZED");
        _;
    }

    function updateDeployer(address _deployer) external onlyDeployer {
        deployer = _deployer;
    }

    function updateBaseUri(string memory _uri) external onlyDeployer {
        baseUri = _uri;
    }

    function _nextTokenId() internal view returns (uint256) {
        return _startId + 1;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        uint16 digits;
        uint256 temp = value;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + (value % 10)));
            value /= 10;
        }

        return string(buffer);
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseUri, "contract.json"));
    }

    function tokenURI(uint256 id) public view returns (string memory) {
        require(_ownerOf[id] != address(0), "NOT_MINTED");
        return string(abi.encodePacked(baseUri, "metadata/", toString(id), ".json"));
    }

    function ownerOf(uint256 id) public view returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    function approve(address spender, uint256 id) external {
        address owner = _ownerOf[id];

        require(spender != owner);
        require(msg.sender == owner || isApprovedForAll[owner][msg.sender] || msg.sender == deployer, "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) external {
        require(operator != msg.sender);

        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 id) public {
        require(from == _ownerOf[id], "WRONG_FORM");
        require(to != address(0), "INVALID_RECIPIENT");
        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id]
                || msg.sender == deployer,
            "NOT_AUTHORIZED"
        );

        unchecked {
            _balanceOf[from]--;
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(address from, address to, uint256 id) external {
        transferFrom(from, to, id);

        require(
            to.code.length == 0
                || ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "")
                    == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) external {
        transferFrom(from, to, id);

        require(
            to.code.length == 0
                || ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data)
                    == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    // ERC165
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == 0x01ffc9a7 // ERC165 Interface ID for ERC165
            || interfaceId == 0x80ac58cd // ERC165 Interface ID for ERC721
            || interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    function mint(address to) public payable onlyDeployer returns (uint256) {
        require(to != address(0), "INVALID_RECIPIENT");

        uint256 id = _nextTokenId();

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        unchecked {
            _balanceOf[to]++;
            totalSupply++;
            _startId++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);

        return id;
    }

    function safeMint(address to) external {
        uint256 id = mint(to);

        require(
            to.code.length == 0
                || ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "")
                    == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeMint(address to, bytes memory data) external {
        uint256 id = mint(to);

        require(
            to.code.length == 0
                || ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data)
                    == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function burn(uint256 id) external {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");
        require(
            owner == msg.sender || getApproved[id] == msg.sender || isApprovedForAll[owner][msg.sender]
                || msg.sender == deployer,
            "NOT_AUTHORIZED"
        );

        unchecked {
            _balanceOf[owner]--;
            totalSupply--;
        }

        delete _ownerOf[id];
        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}