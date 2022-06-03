// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "OERC721.sol";
import "MerkleProof_flat.sol";

contract chaoticDJs is OERC721 {
    using Strings for uint256;

    bytes32 private _glRoot;
    uint256 private _glPrice;
    uint256 private _glUserMintLimit;
    uint256 private _glMintLimit;
    uint256 private _glActive;

    mapping(address => uint256) _glUserMints; //Amount of mints performed by this user
    uint256 private _glMints; //Amount of mints performed in this mint


    bytes32 private _wlRoot;
    uint256 private _wlPrice;
    uint256 private _wlUserMintLimit;
    uint256 private _wlMintLimit;
    uint256 private _wlActive;

    mapping(address => uint256) _wlUserMints; //Amount of mints performed by this user
    uint256 private _wlMints; //Amount of mints performed in this mint


    uint256 private _pmPrice;
    uint256 private _pmUserMintLimit;
    uint256 private _pmMintLimit;
    uint256 private _pmActive;

    mapping(address => uint256) _pmUserMints; //Amount of mints performed by this user

    uint256 _maxSupply;

    uint256 private _reveal;

    constructor() {
        _name = "Chaotic DJs";
        _symbol = "CDS";
    }

    //Read Functions===========================================================================================================================================================

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        if(_reveal == 1) {return string(abi.encodePacked(uriLink, tokenId.toString(), ".json"));}

        return string(abi.encodePacked(uriLink, "secret.json"));
    }

    function glData(address user) external view returns(uint256 userMints, uint256 mints, uint256 price, uint256 userMintLimit, uint256 mintLimit, bytes32 root, bool active) {
        userMints = _glUserMints[user];
        mints = _glMints;
        price = _glPrice;
        userMintLimit = _glUserMintLimit;
        mintLimit = _glMintLimit;
        active = _glActive == 1;
        root = _glRoot;
    }

    function wlData(address user) external view returns(uint256 userMints, uint256 mints, uint256 price, uint256 userMintLimit, uint256 mintLimit, bytes32 root, bool active) {
        userMints = _wlUserMints[user];
        mints = _wlMints;
        price = _wlPrice;
        userMintLimit = _wlUserMintLimit;
        mintLimit = _wlMintLimit;
        active = _wlActive == 1;
        root = _wlRoot;
    }

    function pmData(address user) external view returns(uint256 userMints, uint256 price, uint256 userMintLimit, bool active) {
        userMints = _pmUserMints[user];
        price = _pmPrice;
        userMintLimit = _pmUserMintLimit;
        active = _pmActive == 1;
    }

    function maxSupply() external view returns(uint256) {return _maxSupply;}

    //Moderator Functions======================================================================================================================================================

    function setGlData(uint256 price, uint256 userMintLimit, uint256 mintLimit, bytes32 root, uint256 active) external Manager {
        _glPrice = price;
        _glUserMintLimit = userMintLimit;
        _glMintLimit = mintLimit;
        _glActive = active;
        _glRoot = root;
    }

    function setWlData(uint256 price, uint256 userMintLimit, uint256 mintLimit, bytes32 root, uint256 active) external Manager {
        _wlPrice = price;
        _wlUserMintLimit = userMintLimit;
        _wlMintLimit = mintLimit;
        _wlActive = active;
        _wlRoot = root;
    }

    function setPmData(uint256 price, uint256 userMintLimit, uint256 active) external Manager {
        _pmPrice = price;
        _pmUserMintLimit = userMintLimit;
        _pmActive = active;
    }

    function setMaxSupply(uint256 maxSupply) external Manager {
        _maxSupply = maxSupply;
    }

    function setReveal(uint256 reveal) external Manager {
        _reveal = reveal;
    }

    //User Functions======================================================================================================================================================

    function glMint(bytes32[] calldata _merkleProof) external payable {
        require(_glMints < _glMintLimit, "CDS: WL has sold out");
        require(_glActive == 1, "CDS: WL minting is closed");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, _glRoot, leaf), "NOT_GOLD_LISTED");

        uint256 price = _glPrice;

        require(msg.value % price == 0, "CDS: Wrong Value");

        uint256 amount = msg.value / price;

        require((_glMints += amount) <= _glMintLimit, "CDS: Mint Limit Exceeded");
        require((_glUserMints[msg.sender] += amount) <= _glUserMintLimit, "CDS: User Mint Limit Exceeded");

        _mint(msg.sender, amount);

        require(_totalSupply <= _maxSupply, "CDS: Supply Exceeded");
    }

    function wlMint(bytes32[] calldata _merkleProof) external payable {
        require(_wlMints < _wlMintLimit, "CDS: WL has sold out");
        require(_wlActive == 1, "CDS: WL minting is closed");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, _wlRoot, leaf), "NOT_GOLD_LISTED");

        uint256 price = _wlPrice;

        require(msg.value % price == 0, "CDS: Wrong Value");

        uint256 amount = msg.value / price;

        require((_wlMints += amount) <= _wlMintLimit, "CDS: Mint Limit Exceeded");
        require((_wlUserMints[msg.sender] += amount) <= _wlUserMintLimit, "CDS: User Mint Limit Exceeded");

        _mint(msg.sender, amount);

        require(_totalSupply <= _maxSupply, "CDS: Supply Exceeded");
    }

    function pmMint() external payable {
        require(_pmActive == 1, "CDS: WL minting is closed");

        uint256 price = _pmPrice;

        require(msg.value % price == 0, "CDS: Wrong Value");

        uint256 amount = msg.value / price;

        require((_pmUserMints[msg.sender] += amount) <= _pmUserMintLimit, "CDS: User Mint Limit Exceeded");

        _mint(msg.sender, amount);

        require(_totalSupply <= _maxSupply, "CDS: Supply Exceeded");
    }



}