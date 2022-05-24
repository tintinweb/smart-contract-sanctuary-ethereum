/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

contract Contract {
    /*/////////////////////////////////////////////////////////////
     *                             EVENTS
     * ///////////////////////////////////////////////////////////*/

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );

    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );

    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    /*/////////////////////////////////////////////////////////////
     *                    METADATA STORAGE/LOGIC
     * ///////////////////////////////////////////////////////////*/

    string public name = "Destroyers of TechTok";

    string public symbol = "TECHTOK";

    string uri;

    address public deployer;

    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        require(_tokenId == uint256(1));
        return string(abi.encodePacked(uri, _tokenId, ".json"));
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(uri, "root.json"));
    }

    /*/////////////////////////////////////////////////////////////
     *                 ERC721 BALANCE/OWNER STORAGE
     * ///////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0));
        return _balanceOf[_owner];
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        require(_tokenId != uint256(0));
        return _ownerOf[_tokenId];
    }

    /*/////////////////////////////////////////////////////////////
     *                  ERC721 APPROVAL STORAGE
     * ///////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) private _operatorApproval;

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool)
    {
        return _operatorApproval[_owner][_operator] || _operator == deployer;
    }

    function approve(address _approved, uint256 _tokenId) external {
        address owner = _ownerOf[_tokenId];
        require(_approved != owner);
        require(msg.sender == owner);
        getApproved[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != msg.sender);
        _operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /*/////////////////////////////////////////////////////////////
     *                       CONSTRUCTOR
     * ///////////////////////////////////////////////////////////*/

    constructor(string memory _uri) {
        uri = _uri;
        deployer = msg.sender;
    }

    /*/////////////////////////////////////////////////////////////
     *                     MINT & BURN LOGIC
     * ///////////////////////////////////////////////////////////*/

    function burn(uint256 _tokenId) external {
        address owner = _ownerOf[_tokenId];
        require(msg.sender == owner);

        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[_tokenId];

        delete getApproved[_tokenId];

        emit Transfer(owner, address(0), _tokenId);
    }

    function mint(address _to, uint256 _tokenId) external payable {
        require(_to != address(0), "INVALID_RECIPIENT");
        require(msg.sender == deployer, "NO_PERMISSIONS");
        require(_ownerOf[_tokenId] == address(0), "ALREADY_MINTED");

        unchecked {
            _balanceOf[_to]++;
        }

        _ownerOf[_tokenId] = _to;

        emit Transfer(address(0), _to, _tokenId);
    }

    /*/////////////////////////////////////////////////////////////
     *                       ERC165 LOGIC
     * ///////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceID)
        external
        pure
        returns (bool)
    {
        return
            interfaceID == 0x80ac58cd || // ERC721
            interfaceID == 0x5b5e139f || // ERC721Metadata
            interfaceID == 0x01ffc9a7; // ERC165
    }

    /*/////////////////////////////////////////////////////////////
     *                       ERC721 LOGIC
     * ///////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata data
    ) external {}

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {}

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        require(_from == _ownerOf[_tokenId], "WRONG_FROM");

        require(_to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == _from ||
                _operatorApproval[_from][msg.sender] ||
                msg.sender == getApproved[_tokenId],
            "NOT_AUTHORIZED"
        );

        unchecked {
            _balanceOf[_from]--;

            _balanceOf[_to]++;
        }

        _ownerOf[_tokenId] = _to;

        delete getApproved[_tokenId];

        emit Transfer(_from, _to, _tokenId);
    }
}