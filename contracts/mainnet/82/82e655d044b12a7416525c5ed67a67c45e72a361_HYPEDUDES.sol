/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

contract ERC721I {
    string public name;
    string public symbol;
    string internal baseURI;
    string internal baseExtension = ".json";

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    uint256 public totalSupply;
    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Mint(address indexed to, uint256 tokenId);

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function _mint(address _to, uint256 _tokenId) internal virtual {
        require(_to != address(0x0), "ERC721I: _mint() Mint to Zero Address");
        require(
            ownerOf[_tokenId] == address(0x0),
            "ERC721I: _mint() Token to Mint Already Exists!"
        );

        ownerOf[_tokenId] = _to;
        balanceOf[_to]++;
        totalSupply++;

        emit Transfer(address(0x0), _to, _tokenId);
        emit Mint(_to, _tokenId);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual {
        require(
            _from == ownerOf[_tokenId],
            "ERC721I: _transfer() Transfer Not Owner of Token!"
        );
        require(
            _to != address(0x0),
            "ERC721I: _transfer() Transfer to Zero Address!"
        );

        if (getApproved[_tokenId] != address(0x0)) {
            _approve(address(0x0), _tokenId);
        }

        ownerOf[_tokenId] = _to;
        balanceOf[_from]--;
        balanceOf[_to]++;

        emit Transfer(_from, _to, _tokenId);
    }

    function _approve(address _to, uint256 _tokenId) internal virtual {
        if (getApproved[_tokenId] != _to) {
            getApproved[_tokenId] = _to;
            emit Approval(ownerOf[_tokenId], _to, _tokenId);
        }
    }

    function _setApprovalForAll(
        address _owner,
        address _operator,
        bool _approved
    ) internal virtual {
        require(
            _owner != _operator,
            "ERC721I: _setApprovalForAll() Owner must not be the Operator!"
        );
        isApprovedForAll[_owner][_operator] = _approved;
        emit ApprovalForAll(_owner, _operator, _approved);
    }

    function _setBaseURI(string memory _uri) internal virtual {
        baseURI = _uri;
    }

    function _toString(uint256 _value) internal pure returns (string memory) {
        if (_value == 0) {
            return "0";
        }
        uint256 _iterate = _value;
        uint256 _digits;
        while (_iterate != 0) {
            _digits++;
            _iterate /= 10;
        }
        bytes memory _buffer = new bytes(_digits);
        while (_value != 0) {
            _digits--;
            _buffer[_digits] = bytes1(uint8(48 + uint256(_value % 10)));
            _value /= 10;
        }
        return string(_buffer);
    }

    function _isApprovedOrOwner(address _spender, uint256 _tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            ownerOf[_tokenId] != address(0x0),
            "ERC721I: _isApprovedOrOwner() Owner is Zero Address!"
        );
        address _owner = ownerOf[_tokenId];
        return (_spender == _owner ||
            _spender == getApproved[_tokenId] ||
            isApprovedForAll[_owner][_spender]);
    }

    function _exists(uint256 _tokenId) internal view virtual returns (bool) {
        return ownerOf[_tokenId] != address(0x0);
    }

    function approve(address _to, uint256 _tokenId) public virtual {
        address _owner = ownerOf[_tokenId];
        require(_to != _owner, "ERC721I: approve() Cannot approve yourself!");
        require(
            msg.sender == _owner || isApprovedForAll[_owner][msg.sender],
            "ERC721I: Caller not owner or Approved!"
        );
        _approve(_to, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved)
        public
        virtual
    {
        _setApprovalForAll(msg.sender, _operator, _approved);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual {
        require(
            _isApprovedOrOwner(msg.sender, _tokenId),
            "ERC721I: transferFrom() _isApprovedOrOwner = false!"
        );
        _transfer(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public virtual {
        transferFrom(_from, _to, _tokenId);
        if (_to.code.length != 0) {
            (, bytes memory _returned) = _to.staticcall(
                abi.encodeWithSelector(
                    0x150b7a02,
                    msg.sender,
                    _from,
                    _tokenId,
                    _data
                )
            );
            bytes4 _selector = abi.decode(_returned, (bytes4));
            require(
                _selector == 0x150b7a02,
                "ERC721I: safeTransferFrom() to_ not ERC721Receivable!"
            );
        }
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function multiTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds
    ) public virtual {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function multiSafeTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        bytes memory _data
    ) public virtual {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], _data);
        }
    }

    function supportsInterface(bytes4 _interfaceId) public pure returns (bool) {
        return (_interfaceId == 0x80ac58cd || _interfaceId == 0x5b5e139f);
    }

    function walletOfOwner(address _address)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        uint256 _balance = balanceOf[_address];
        uint256[] memory _tokens = new uint256[](_balance);
        uint256 _index;
        uint256 _loopThrough = totalSupply;
        for (uint256 i = 0; i < _loopThrough; i++) {
            if (ownerOf[i] == address(0x0) && _tokens[_balance - 1] == 0) {
                _loopThrough++;
            }
            if (ownerOf[i] == _address) {
                _tokens[_index] = i;
                _index++;
            }
        }
        return _tokens;
    }
}

abstract contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed _oldOwner,
        address indexed _newOwner
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function _transferOwnership(address _newOwner) internal virtual {
        address _oldOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(_oldOwner, _newOwner);
    }

    function transferOwnership(address _newOwner) public virtual onlyOwner {
        require(
            _newOwner != address(0x0),
            "Ownable: new owner is the zero address!"
        );
        _transferOwnership(_newOwner);
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0x0));
    }
}

library MerkleProof {
    function verify(
        bytes32[] memory _proof,
        bytes32 _root,
        bytes32 _leaf
    ) internal pure returns (bool) {
        return processProof(_proof, _leaf) == _root;
    }

    function processProof(bytes32[] memory _proof, bytes32 _leaf)
        internal
        pure
        returns (bytes32)
    {
        bytes32 _computedHash = _leaf;
        for (uint256 i = 0; i < _proof.length; i++) {
            bytes32 proofElement = _proof[i];
            if (_computedHash <= proofElement) {
                _computedHash = _efficientHash(_computedHash, proofElement);
            } else {
                _computedHash = _efficientHash(proofElement, _computedHash);
            }
        }
        return _computedHash;
    }

    function _efficientHash(bytes32 _a, bytes32 _b)
        private
        pure
        returns (bytes32 value)
    {
        assembly {
            mstore(0x00, _a)
            mstore(0x20, _b)
            value := keccak256(0x00, 0x40)
        }
    }
}

contract HYPEDUDES is ERC721I, Ownable {
    constructor() payable ERC721I("HYPEDUDES", "HD") {
        setNotRevealedURI("ipfs://QmVRboxi4tnfSHPQCwANunTfEo4kiEs4EXw1Y64rB79wCX/hidden.json");

        _mintMany(msg.sender, 55);
    }

    uint256 public mintPrice = 0.035 ether;
    uint256 public maxSupply = 5555;
    uint256 public maxMintsPerTx = 4;

    bytes32 public merkleRoot;

    uint256 public maxMintsPerWhitelist = 4;
    mapping(address => uint256) public whitelistMints;
    bool public whitelistMintEnabled = false;
    uint256 public whitelistMintStartTime;
    uint256 public whitelistMintDuration;

    bool public publicMintEnabled = false;
    uint256 public publicMintStartTime;

    bool public paused = false;
    bool public revealed = false;
    uint256 public revealedAt;
    string public notRevealedUri;

    modifier onlySender() {
        require(msg.sender == tx.origin, "No smart contracts!");
        _;
    }

    modifier whitelistMinting() {
        require(
            whitelistMintEnabled && block.timestamp >= whitelistMintStartTime,
            "Whitelist Mints are not enabled yet!"
        );
        _;
    }

    modifier publicMinting() {
        require(
            publicMintEnabled && block.timestamp >= publicMintStartTime,
            "Public Mints are not enabled yet!"
        );
        _;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        require(
            ownerOf[_tokenId] != address(0x0),
            "ERC721I: tokenURI() Token does not exist!"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        return
            string(
                abi.encodePacked(baseURI, _toString(_tokenId), baseExtension)
            );
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function reveal(string memory _uri) public onlyOwner {
        require(!revealed, "The contract is already revealed!");

        _setBaseURI(_uri);
        revealed = true;
        revealedAt = block.timestamp;
    }

    function emergencyReveal(string memory _uri) public onlyOwner {
        require(
            block.timestamp < revealedAt + 86400,
            "You cannot use this function. Emergency time is closed!"
        );

        _setBaseURI(_uri);
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        require(
            _maxSupply >= totalSupply,
            "maxSupply cannot be set lower than totalSupply!"
        );

        maxSupply = _maxSupply;
    }

    function setMaxMintsPerTx(uint256 _maxMintsPerTx) public onlyOwner {
        maxMintsPerTx = _maxMintsPerTx;
    }

    function setMaxMintsPerWhitelist(uint256 _maxMintsPerWhitelist)
        public
        onlyOwner
    {
        maxMintsPerWhitelist = _maxMintsPerWhitelist;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function flipWhitelist(
        uint256 _whitelistMintStartTime,
        uint256 _whitelistMintDuration
    ) public onlyOwner {
        publicMintEnabled = false;
        whitelistMintEnabled = true;
        whitelistMintStartTime = _whitelistMintStartTime;
        whitelistMintDuration = _whitelistMintDuration;
    }

    function flipPublicMint(uint256 _publicMintStartTime) public onlyOwner {
        whitelistMintEnabled = false;
        publicMintEnabled = true;
        publicMintStartTime = _publicMintStartTime;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function _mintMany(address _to, uint256 _amount) internal virtual {
        require(
            maxSupply >= totalSupply + _amount,
            "Not enough tokens remaining!"
        );

        uint256 _startId = totalSupply + 1;

        for (uint256 i = 0; i < _amount; i++) {
            _mint(_to, _startId + i);
        }
    }

    function ownerMint(address _to, uint256 _amount) public onlyOwner {
        _mintMany(_to, _amount);
    }

    function ownerMintToMany(
        address[] calldata _tos,
        uint256[] calldata _amounts
    ) public onlyOwner {
        require(_tos.length == _amounts.length, "Array lengths mismatch!");

        for (uint256 i = 0; i < _tos.length; i++) {
            _mintMany(_tos[i], _amounts[i]);
        }
    }

    function whitelistMint(uint256 _amount, bytes32[] calldata _merkleProof)
        public
        payable
        onlySender
        whitelistMinting
    {
        require(!paused, "The contract is paused!");
        require(
            block.timestamp < whitelistMintStartTime + whitelistMintDuration,
            "The presales is closed!"
        );
        require(
            MerkleProof.verify(
                _merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "You are not whitelisted!"
        );
        require(msg.value == _amount * mintPrice, "Invalid value sent!");
        require(maxMintsPerTx >= _amount, "Amount exceeds max mints per tx!");
        require(
            maxMintsPerWhitelist >= whitelistMints[msg.sender] + _amount,
            "You don't have enough whitelist mints remaining!"
        );
        require(
            maxSupply >= totalSupply + _amount,
            "Not enough tokens remaining!"
        );

        whitelistMints[msg.sender] += _amount;

        _mintMany(msg.sender, _amount);
    }

    function publicMint(uint256 _amount)
        public
        payable
        onlySender
        publicMinting
    {
        require(!paused, "The contract is paused!");
        require(msg.value == _amount * mintPrice, "Invalid value sent!");
        require(maxMintsPerTx >= _amount, "Amount exceeds max mints per tx!");
        require(
            maxSupply >= totalSupply + _amount,
            "Not enough tokens remaining!"
        );

        _mintMany(msg.sender, _amount);
    }

    function _sendETH(address payable _address, uint256 _amount) internal {
        (bool success, ) = payable(_address).call{value: _amount}("");
        require(success, "Transfer failed");
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;

        _sendETH(payable(msg.sender), _balance);
    }

    function partialWithdraw(uint256 _amount) public onlyOwner {
        require(address(this).balance >= _amount, "Insufficient balance!");

        _sendETH(payable(msg.sender), _amount);
    }
}