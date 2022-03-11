/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.11;

interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns (bytes4);
}


contract Collection {
    address private _minter = msg.sender;
    uint256 private _tokens = 0;
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0));
        return _balances[_owner];
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        address _owner = _owners[_tokenId];
        require(_owner != address(0));
        return _owner;
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public {
        transferFrom(_from, _to, _tokenId);
        if (_to.code.length > 0) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, data);
            require(retval == bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")));
        }
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        address _owner = _owners[_tokenId];
        require(
            msg.sender == _owner ||
            _operatorApprovals[_owner][msg.sender] ||
            msg.sender == _tokenApprovals[_tokenId]
        );
        require(_from == _owner);
        require(_to != address(0));
        require(_owner != address(0));
        _tokenApprovals[_tokenId] = address(0);
        emit Approval(_owner, address(0), _tokenId);
        _balances[_from] -= 1;
        _balances[_to] += 1;
        _owners[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external {
        address _owner = _owners[_tokenId];
        require(msg.sender == _owner || _operatorApprovals[_owner][msg.sender]);
        _tokenApprovals[_tokenId] = _approved;
        emit Approval(_owner, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) external view returns (address) {
        require(_owners[_tokenId] != address(0));
        return _tokenApprovals[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return
            interfaceID == 0x01ffc9a7 ||
            interfaceID == 0x80ac58cd ||
            interfaceID == 0x5b5e139f;
    }

    function name() external pure returns (string memory _name) {
        return "Sharimot";
    }

    function symbol() external pure returns (string memory _symbol) {
        return "SHA";
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        require(_owners[_tokenId] != address(0));
        return _tokenURIs[_tokenId];
    }

    function mint(string memory _tokenURI) external {
        require(msg.sender == _minter);
        uint256 _tokenId = _tokens;
        _tokenURIs[_tokenId] = _tokenURI;
        _balances[msg.sender] += 1;
        _owners[_tokenId] = msg.sender;
        _tokens += 1;
        emit Transfer(address(0), msg.sender, _tokenId);
    }

    function migrate(address _to) external {
        require(msg.sender == _minter);
        _minter = _to;
    }
}