// SPDX-License-Identifier: MIT
// Creator: 0xVinasaur
pragma solidity ^0.8.4;

//                                             ╓▄▄▄
//                                      ,▄██▄█▀    ▀█ ,╓▄██▄
//                                     █▀    ╙█▄    ╟█▀     █╕
//                                   ,█▌     ▄███████▀██▄   ▐█
//                                 ╓█▀└▀███▀▀▀└░░░░░░░░ ╜▀█▄╫▌
//                               ╓█▀ ░░░░░░░░░░░░░░░░░░░░░└███████▄
//                             ╓█▀ ░░░░░░░░░░░░░░░░░░░░░░░░░▀█▄    █
//                           ╓█▀ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░╙█▄  ▄█
//                         ,█▀███░░░░░░░░░░░░░░░░░░░░░░░░░░░░░╝█▄█▀
//                        ,█▀░▀▀▀░░░░░░░░░░░░░.█▄░░░░░░░░░░░░░░██▀██╖
//                        █▌░░░░░░░░░░░░░░░░░░╫██░░░░░░░░░░░░░░▐█   ╙█µ
//                        █▒░░░░░██▄▄,▄█░░░░░░░'░░░░░░░░░░░░░░░░█▌   █▌
//                        █▌░░░░░░└▀▀▀▀╙░░░░░░░░░░░░░░░░░░░░░░░░█▌▄██
//                        ╙█▄░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░████▄,
//                         └██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░╫█   ╙█
//                           ╙██▄░░░░░░░░░░░░░,███░░░░░░░░░░░░░░╙█    █
//                             ▄█████▄▄▄▄▄█████▀└░░░░░░░░░░██,░░░██ ▄█
//                         ,████▀░░├█╫▀▀▀▀▀╙.░░░░░╓█░░░░░░░░╟██ ░╙███▄,
//                       ╓█▀╟████▀▀▀╙╙▀▀▀███ ░░░░░█▌░░░░░░░░░░▀█▌░║█▌  ▀█
//                      █▀░███             ╙██▄░░░█▌░░░░░░░░░░░╙█▌░╫█   █▌
//                     █▌░█▀ ╙▀██▄▄,,,,,▄▄██▀▀██░░╙█▌░░░░░░░░░░░╟█░░██▄█▀
//          ,,,,   ,,,,█▌█▌   ,,   ╟█▀╙╙╠▄ ,,,▄██▄▄,███▄▄▄░░░,▄▄██▌░╙████▄      ,,,,
//       ╓███▀▀▀████▀▀▀███▄ ████████▀████▀██▀▀▀▀▀▀██████▀█████████▌░░╫██████ ,███▀▀███
//      ██▀  ,,   █   ,  ╟███▌  ╙██▄  ▀▀  ╫▌▄▄▄,  ,█  █▌ ▐████  ██▌░]██▌  ╙████  ,,,██▌
//     ██▌ ╒██▀████  ╙▀  ▐██▌    ╙███   ,█████▀  ▄██  █▌ ▐████  ██▌.██▌    ╙███  ╙▀███
//     ██▌ └██▄████  ,  ███▌  ▀▀  ╙███  █████  ╓████  █▌ ▐████  █████▌  ▀▀  ╙████▄  ╙██
//      ██▄  `╙╙  █  ╟█  ╫▌  ▄▄▄▄  ╚██  ███▀   ╙╙╙╙█  █▌  ╙╙▀█  `╙╙▀▌  ▄▄▄▄  ╨█  ╙  ▄█▌
//       ╙████▄███████████████▀▀████████████████████████████████████████▀▀███████████▀

interface IStateSender {
    function syncState(address receiver, bytes calldata data) external;
}

/**
@dev To enable cross-chain coloring with Polygon, and dedicated immutable metadata for Traits 
 */
abstract contract ERCColorable {
    string internal traitMetadataURI;
    string internal traitMetadataURI_EXT; // optional
    IStateSender internal _stateSender;
    address internal _childStateReceiver;
    bool internal _isStateSenderSet;

    /**
     * @dev Sets a new value for the trait metadata URI
     */
    function _setTraitMetadataURI(string memory uri_) internal virtual {
        traitMetadataURI = uri_;
    }

    /**
     * @dev Sets a new value for the metadata file extension
     eg: ".json"
     */
    function _setTraitMetadataURI_EXT(string memory ext_) internal virtual {
        traitMetadataURI_EXT = ext_;
    }

    /**
    * @dev Sets the StateSender on ETH that will propagate state to Polygon
    */
    function _setStateSender(address newStateSender) internal {
        require(newStateSender != address(0), "ERCColorablew: Invalid State Sender");
        _isStateSenderSet = true;
        _stateSender = IStateSender(newStateSender);
    }

    /**
    * @dev Sets the address on Polygon that will receive state from ETH
    */
    function _setChildStateReceiver(address newChildStateReceiver) internal {
        require(newChildStateReceiver != address(0), "ERCColorable: Invalid child state receiver");
        _childStateReceiver = newChildStateReceiver;
    }
}

// Forked from ERC721I by 0xInuarashi
contract ERC721C is ERCColorable {
    string public name;
    string public symbol;
    string internal baseTokenURI;
    string internal baseTokenURI_EXT;

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    uint256 public totalSupply;
    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    // Events
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
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

    // // internal write functions
    // mint
    function _mint(address to_, uint256 tokenId_) internal virtual {
        require(to_ != address(0x0), "ERC721C: _mint() Mint to Zero Address");
        require(
            ownerOf[tokenId_] == address(0x0),
            "ERC721C: _mint() Token to Mint Already Exists!"
        );

        balanceOf[to_]++;
        ownerOf[tokenId_] = to_;

        emit Transfer(address(0x0), to_, tokenId_);
    }

    // transfer
    function _transfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) internal virtual {
        require(
            from_ == ownerOf[tokenId_],
            "ERC721C: _transfer() Transfer Not Owner of Token!"
        );
        require(
            to_ != address(0x0),
            "ERC721C: _transfer() Transfer to Zero Address!"
        );

        // checks if there is an approved address clears it if there is
        if (getApproved[tokenId_] != address(0x0)) {
            _approve(address(0x0), tokenId_);
        }

        ownerOf[tokenId_] = to_;
        balanceOf[from_]--;
        balanceOf[to_]++;

        emit Transfer(from_, to_, tokenId_);
    }

    // approve
    function _approve(address to_, uint256 tokenId_) internal virtual {
        if (getApproved[tokenId_] != to_) {
            getApproved[tokenId_] = to_;
            emit Approval(ownerOf[tokenId_], to_, tokenId_);
        }
    }

    function _setApprovalForAll(
        address owner_,
        address operator_,
        bool approved_
    ) internal virtual {
        require(
            owner_ != operator_,
            "ERC721C: _setApprovalForAll() Owner must not be the Operator!"
        );
        isApprovedForAll[owner_][operator_] = approved_;
        emit ApprovalForAll(owner_, operator_, approved_);
    }

    // token uri
    function _setBaseTokenURI(string memory uri_) internal virtual {
        baseTokenURI = uri_;
    }

    function _setBaseTokenURI_EXT(string memory ext_) internal virtual {
        baseTokenURI_EXT = ext_;
    }

    // // Internal View Functions
    // Embedded Libraries
    function _toString(uint256 value_) internal pure returns (string memory) {
        if (value_ == 0) {
            return "0";
        }
        uint256 _iterate = value_;
        uint256 _digits;
        while (_iterate != 0) {
            _digits++;
            _iterate /= 10;
        } // get digits in value_
        bytes memory _buffer = new bytes(_digits);
        while (value_ != 0) {
            _digits--;
            _buffer[_digits] = bytes1(uint8(48 + uint256(value_ % 10)));
            value_ /= 10;
        } // create bytes of value_
        return string(_buffer); // return string converted bytes of value_
    }

    // Functional Views
    function _isApprovedOrOwner(address spender_, uint256 tokenId_)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            ownerOf[tokenId_] != address(0x0),
            "ERC721C: _isApprovedOrOwner() Owner is Zero Address!"
        );
        address _owner = ownerOf[tokenId_];
        return (spender_ == _owner ||
            spender_ == getApproved[tokenId_] ||
            isApprovedForAll[_owner][spender_]);
    }

    // // public write functions
    function approve(address to_, uint256 tokenId_) public virtual {
        address _owner = ownerOf[tokenId_];
        require(to_ != _owner, "ERC721C: approve() Cannot approve yourself!");
        require(
            msg.sender == _owner || isApprovedForAll[_owner][msg.sender],
            "ERC721C: Caller not owner or Approved!"
        );
        _approve(to_, tokenId_);
    }

    function setApprovalForAll(address operator_, bool approved_)
        public
        virtual
    {
        _setApprovalForAll(msg.sender, operator_, approved_);
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public virtual {
        require(
            _isApprovedOrOwner(msg.sender, tokenId_),
            "ERC721C: transferFrom() _isApprovedOrOwner = false!"
        );
        _transfer(from_, to_, tokenId_);
        // send data to the child chain
        if (_isStateSenderSet) {
            bytes memory syncData = abi.encode(address(this), tokenId_, to_);
            _stateSender.syncState(
                address(_childStateReceiver),
                abi.encode(syncData)
            );
        }
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) public virtual {
        transferFrom(from_, to_, tokenId_);
        if (to_.code.length != 0) {
            (, bytes memory _returned) = to_.staticcall(
                abi.encodeWithSelector(
                    0x150b7a02,
                    msg.sender,
                    from_,
                    tokenId_,
                    data_
                )
            );
            bytes4 _selector = abi.decode(_returned, (bytes4));
            require(
                _selector == 0x150b7a02,
                "ERC721C: safeTransferFrom() to_ not ERC721Receivable!"
            );
        }
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public virtual {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    // 0xInuarashi Custom Functions
    function multiTransferFrom(
        address from_,
        address to_,
        uint256[] memory tokenIds_
    ) public virtual {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            transferFrom(from_, to_, tokenIds_[i]);
        }
    }

    function multiSafeTransferFrom(
        address from_,
        address to_,
        uint256[] memory tokenIds_,
        bytes memory data_
    ) public virtual {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            safeTransferFrom(from_, to_, tokenIds_[i], data_);
        }
    }

    // OZ Standard Stuff
    function supportsInterface(bytes4 interfaceId_) public pure returns (bool) {
        return (interfaceId_ == 0x80ac58cd || interfaceId_ == 0x5b5e139f);
    }

    function tokenURI(uint256 tokenId_)
        public
        view
        virtual
        returns (string memory)
    {
        require(
            ownerOf[tokenId_] != address(0x0),
            "ERC721C: tokenURI() Token does not exist!"
        );
        return
            string(
                abi.encodePacked(
                    baseTokenURI,
                    _toString(tokenId_),
                    baseTokenURI_EXT
                )
            );
    }

    function tokenTraitURI(uint256 tokenId_)
        public
        view
        virtual
        returns (string memory)
    {
        require(
            ownerOf[tokenId_] != address(0x0),
            "ERC721C: tokenTraitURI() Token does not exist!"
        );
        return
            string(
                abi.encodePacked(
                    traitMetadataURI,
                    _toString(tokenId_),
                    traitMetadataURI_EXT
                )
            );
    }

    // public view functions
    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    // never use these for functions ever, they are expensive af and for view only
    function walletOfOwner(address address_)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        uint256 _balance = balanceOf[address_];
        uint256[] memory _tokens = new uint256[](_balance);
        uint256 _index;
        uint256 _loopThrough = totalSupply;
        for (uint256 i = 0; i < _loopThrough; i++) {
            if (ownerOf[i] == address(0x0) && _tokens[_balance - 1] == 0) {
                _loopThrough++;
            }
            if (ownerOf[i] == address_) {
                _tokens[_index] = i;
                _index++;
            }
        }
        return _tokens;
    }

    // not sure when this will ever be needed but it conforms to erc721 enumerable
    function tokenOfOwnerByIndex(address address_, uint256 index_)
        public
        view
        virtual
        returns (uint256)
    {
        uint256[] memory _wallet = walletOfOwner(address_);
        return _wallet[index_];
    }

     function exists(uint256 tokenId_) public view virtual returns (bool) {
        return ownerOf[tokenId_] != address(0x0);
    }
}

// Open0x Ownable (by 0xInuarashi)
abstract contract Ownable {
    address public owner;
    event OwnershipTransferred(
        address indexed oldOwner_,
        address indexed newOwner_
    );

    constructor() {
        owner = msg.sender;
    }

    function _onlyOwner() internal view {
      require(owner == msg.sender, "Ownable: caller is not the owner");
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _transferOwnership(address newOwner_) internal virtual {
        address _oldOwner = owner;
        owner = newOwner_;
        emit OwnershipTransferred(_oldOwner, newOwner_);
    }

    function transferOwnership(address newOwner_) public virtual onlyOwner {
        require(
            newOwner_ != address(0x0),
            "Ownable: new owner is the zero address!"
        );
        _transferOwnership(newOwner_);
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0x0));
    }
}

abstract contract MerkleAllowlist {
    bytes32 internal _merkleAllowlistRoot;

    function _setAllowlistMerkleRoot(bytes32 merkleRoot_) internal virtual {
        _merkleAllowlistRoot = merkleRoot_;
    }

    function isAllowlisted(address address_, bytes32[] memory proof_)
        public
        view
        returns (bool)
    {
        bytes32 _leaf = keccak256(abi.encodePacked(address_));
        for (uint256 i = 0; i < proof_.length; i++) {
            _leaf = _leaf < proof_[i]
                ? keccak256(abi.encodePacked(_leaf, proof_[i]))
                : keccak256(abi.encodePacked(proof_[i], _leaf));
        }
        return _leaf == _merkleAllowlistRoot;
    }
}

abstract contract MerklePubRaffle {
    bytes32 internal _merklePubRaffleRoot;

    function _setPubRaffleMerkleRoot(bytes32 merkleRoot_) internal virtual {
        _merklePubRaffleRoot = merkleRoot_;
    }

    function isPubRaffleListed(address address_, bytes32[] memory proof_)
        public
        view
        returns (bool)
    {
        bytes32 _leaf = keccak256(abi.encodePacked(address_));
        for (uint256 i = 0; i < proof_.length; i++) {
            _leaf = _leaf < proof_[i]
                ? keccak256(abi.encodePacked(_leaf, proof_[i]))
                : keccak256(abi.encodePacked(proof_[i], _leaf));
        }
        return _leaf == _merklePubRaffleRoot;
    }
}

abstract contract AllowlistMint {
    // Allowlist Minting
    bool internal _allowlistMintEnabled;
    uint256 public _allowlistMintTime;

    function _setAllowlistMint(bool bool_, uint256 time_) internal {
        _allowlistMintEnabled = bool_;
        _allowlistMintTime = time_;
    }

    function _isAllowlistMintEnabled() internal view {
      require(
            _allowlistMintEnabled && _allowlistMintTime <= block.timestamp,
            "Allowlist Mint is not enabled yet!"
        );
    }

    modifier allowlistMintEnabled() {
        _isAllowlistMintEnabled();
        _;
    }

    function allowlistMintStatus() external view returns (bool) {
        return _allowlistMintEnabled && _allowlistMintTime <= block.timestamp;
    }
}

abstract contract PubRaffleMint {
    // Public Raffle Minting
    bool internal _pubRaffleMintEnabled;
    uint256 public _pubRaffleMintTime;

    function _setPubRaffleMint(bool bool_, uint256 time_) internal {
        _pubRaffleMintEnabled = bool_;
        _pubRaffleMintTime = time_;
    }

    function _isPubRaffleMintEnabled() internal view {
      require(
            _pubRaffleMintEnabled && _pubRaffleMintTime <= block.timestamp,
            "Public Raffle Mint is not enabled yet!"
        );
    }

    modifier pubRaffleMintEnabled() {
        _isPubRaffleMintEnabled();
        _;
    }

    function pubRaffleMintStatus() external view returns (bool) {
        return _pubRaffleMintEnabled && _pubRaffleMintTime <= block.timestamp;
    }
}

abstract contract PublicMint {
    // Public Minting
    bool public _publicMintEnabled;
    uint256 public _publicMintTime;

    function _setPublicMint(bool bool_, uint256 time_) internal {
        _publicMintEnabled = bool_;
        _publicMintTime = time_;
    }

    function _isPublicMintEnabled() internal view {
      require(
            _publicMintEnabled && _publicMintTime <= block.timestamp,
            "Public Mint is not enabled yet!"
        );
    }

    modifier publicMintEnabled() {
        _isPublicMintEnabled();
        _;
    }

    function publicMintStatus() external view returns (bool) {
        return _publicMintEnabled && _publicMintTime <= block.timestamp;
    }
}

abstract contract Security {
    function _onlySender() internal view {
      require(msg.sender == tx.origin, "No Smart Contracts!");
    }

    // Prevent Smart Contracts
    modifier onlySender() {
        _onlySender();
        _;
    }
}

contract Crayzillas is
    ERC721C,
    Ownable,
    MerkleAllowlist,
    MerklePubRaffle,
    AllowlistMint,
    PubRaffleMint,
    PublicMint,
    Security
{
    // Constructor
    constructor() payable ERC721C("Crayzillas", "CRAY") {}

    // Project Constraints
    uint256 public mintPrice = 0.077 ether;
    uint256 public maxSupply = 7777;

    string public crayzillasProvenance;

    // Public Limits
    uint256 public maxMintsPerPublic = 2; 
    mapping(address => uint256) public addressToPublicMints;

    // Allowlist Limits
    uint256 public maxMintsPerAllowlist = 2; 
    mapping(address => uint256) public addressToAllowlistMints;

    // PubRaffle Limits
    uint256 public maxMintsPerPubRaffle = 2; 
    mapping(address => uint256) public addressToPubRaffleMints;

    // Administrative Functions
    function setMintPrice(uint256 mintPrice_) external onlyOwner {
        mintPrice = mintPrice_;
    }

    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    // Public, PubRaffle, and Allowlist Mint Limits
    function setMaxMintsPerPublic(uint256 maxMintsPerPublic_)
        external
        onlyOwner
    {
        maxMintsPerPublic = maxMintsPerPublic_;
    }

    function setMaxMintsPerPubRaffle(uint256 maxMintsPerPubRaffle_) external onlyOwner {
        maxMintsPerPubRaffle = maxMintsPerPubRaffle_;
    }

    function setMaxMintsPerAllowlist(uint256 maxMintsPerAllowlist_) external onlyOwner {
        maxMintsPerAllowlist = maxMintsPerAllowlist_;
    }

    // Token URI
    function setBaseTokenURI(string calldata uri_) external onlyOwner {
        _setBaseTokenURI(uri_);
    }

    function setBaseTokenURI_EXT(string calldata ext_) external onlyOwner {
        _setBaseTokenURI_EXT(ext_);
    }

    // Allowlist MerkleRoot
    function setAllowlistMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        _setAllowlistMerkleRoot(merkleRoot_);
    }

    // Public Raffle MerkleRoot
    function setPubRaffleMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        _setPubRaffleMerkleRoot(merkleRoot_);
    }

    // Public Mint
    function setPublicMint(bool bool_, uint256 time_) external onlyOwner {
        _setPublicMint(bool_, time_);
    }

    // Allowlist Mint
    function setAllowlistMint(bool bool_, uint256 time_) external onlyOwner {
        _setAllowlistMint(bool_, time_);
    }

    // Public Raffle Mint
    function setPubRaffleMint(bool bool_, uint256 time_) external onlyOwner {
        _setPubRaffleMint(bool_, time_);
    }

    function setProvenanceHash(string memory provenanceHash_) external onlyOwner {
        crayzillasProvenance = provenanceHash_;
    }

    function setStateSender(address newStateSender) external onlyOwner {
        _setStateSender(newStateSender);
    }

    function setChildReceiver(address newChildStateReceiver) external onlyOwner {
        _setChildStateReceiver(newChildStateReceiver);
    }

    function withdraw() public onlyOwner {
        payable(owner).transfer(payable(address(this)).balance);
    }

    // Internal Functions
    function _mintMany(address to_, uint256 amount_) internal {
        require(
            maxSupply >= totalSupply + amount_,
            "Not enough Crayzillas remaining!"
        );

        uint256 _startId = totalSupply + 1; // iterate from 1

        for (uint256 i = 0; i < amount_; i++) {
            _mint(to_, _startId + i);
        }

        totalSupply += amount_;
    }

    // Owner Mint
    function ownerMint(address[] calldata tos_, uint256[] calldata amounts_)
        external
        onlyOwner
    {
        require(tos_.length == amounts_.length, "Array lengths mismatch!");

        for (uint256 i = 0; i < tos_.length; i++) {
            _mintMany(tos_[i], amounts_[i]);
        }
    }

    // Allowlist Mint
    function allowlistMint(bytes32[] calldata proof_, uint256 amount_)
        external
        payable
        onlySender
        allowlistMintEnabled
    {
        require(isAllowlisted(msg.sender, proof_), "You are not allowlisted!");
        require(
            maxMintsPerAllowlist >= addressToAllowlistMints[msg.sender] + amount_,
            "You don't have enough waxlist mints!"
        );
        require(msg.value == mintPrice * amount_, "Invalid value sent!");

        // Add address to WL minted
        addressToAllowlistMints[msg.sender] += amount_;

        // Now, mint to msg.sender
        _mintMany(msg.sender, amount_);
    }

    // Public Raffle Mint
    function pubRaffleMint(bytes32[] calldata proof_, uint256 amount_)
        external
        payable
        onlySender
        allowlistMintEnabled
    {
        require(isPubRaffleListed(msg.sender, proof_), "You have not won a public raffle mint allocation!");
        require(
            maxMintsPerPubRaffle >= addressToPubRaffleMints[msg.sender] + amount_,
            "You don't have enough public raffle mints!"
        );
        require(msg.value == mintPrice * amount_, "Invalid value sent!");

        // Add address to pub raffle minted
        addressToPubRaffleMints[msg.sender] += amount_;

        // Now, mint to msg.sender
        _mintMany(msg.sender, amount_);
    }

    // Public Mint
    function publicMint(uint256 amount_)
        external
        payable
        onlySender
        publicMintEnabled
    {
        require(
            maxMintsPerPublic >= addressToPublicMints[msg.sender] + amount_,
            "You don't have enough Public Mints!"
        );
        require(msg.value == mintPrice * amount_, "Invalid value sent!");

        // Add address to Public Mints
        addressToPublicMints[msg.sender] += amount_;

        // Now, mint to msg.sender
        _mintMany(msg.sender, amount_);
    }
}