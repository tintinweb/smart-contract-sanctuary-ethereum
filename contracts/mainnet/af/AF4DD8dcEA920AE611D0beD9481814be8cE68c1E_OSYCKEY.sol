// SPDX-License-Identifier: MIT

/***************************************************************************
          ___        __         _     __           __   __ ___
        / __ \      / /_  _____(_)___/ /____       \ \ / /  _ \
       / / / /_  __/ __/ / ___/ / __  / __  )       \ / /| |
      / /_/ / /_/ / /_  (__  ) / /_/ / ____/         | | | |_
      \____/\____/\__/ /____/_/\__,_/\____/          |_|  \___/
                                       
****************************************************************************/

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";

contract OSYCKEY is Ownable, ERC1155 {
    string private name_;
    string private symbol_;

    mapping(uint8 => uint16) public MAX_SUPPLY;
    mapping(uint8 => uint16) public mintedCount;

    bool public publicSale;
    bool public isAllowToTransfer;
    address private admin;

    string private constant CONTRACT_NAME = "OSYC Key Contract";
    bytes32 private constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );
    bytes32 private constant MINT_TYPEHASH =
        keccak256("Mint(address user,uint8 key,uint8 count)");

    constructor(
        string memory _name,
        string memory _symbol,
        address _admin
    ) {
        name_ = _name;
        symbol_ = _symbol;
        admin = _admin;
    }

    function name() public view virtual returns (string memory) {
        return name_;
    }

    function symbol() public view virtual returns (string memory) {
        return symbol_;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        _setURI(_baseURI);
    }

    function setPublicSale(bool _publicSale) external onlyOwner {
        publicSale = _publicSale;
    }

    function setConfig(uint8 keyId, uint16 _max_supply) external onlyOwner {
        MAX_SUPPLY[keyId] = _max_supply;
    }

    function allowToTransfer(bool _isAllowToTransfer) external onlyOwner {
        isAllowToTransfer = _isAllowToTransfer;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(isAllowToTransfer, "Not allow to trasfer");
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(isAllowToTransfer, "Not allow to trasfer");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(isAllowToTransfer, "Not allow to trasfer");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function mintKey(
        uint8 keyId,
        uint8 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        require(tx.origin == msg.sender, "Only EOA");
        require(balanceOf(msg.sender, keyId) == 0, "Aleady Minted");
        require(
            mintedCount[keyId] + amount < MAX_SUPPLY[keyId],
            "Max Limit To Presale"
        );

        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(CONTRACT_NAME)),
                getChainId(),
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(MINT_TYPEHASH, msg.sender, keyId, amount)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(signatory == admin, "Invalid signatory");

        _mint(msg.sender, keyId, amount, "");
        mintedCount[keyId] = mintedCount[keyId] + amount;
    }

    function mintKeyPublic(uint8 keyId) external payable {
        require(tx.origin == msg.sender, "Only EOA");
        require(publicSale, "Not allowed for public sale");
        require(
            mintedCount[keyId] + 1 < MAX_SUPPLY[keyId],
            "Max Limit To Presale"
        );

        _mint(msg.sender, keyId, 1, "");
        mintedCount[keyId] = mintedCount[keyId] + 1;
    }

    function reserveKey(
        address account,
        uint8 keyId,
        uint8 amount
    ) external onlyOwner {
        require(
            mintedCount[keyId] + amount < MAX_SUPPLY[keyId],
            "Max Limit To Presale"
        );

        _mint(account, keyId, amount, "");
        mintedCount[keyId] = mintedCount[keyId] + amount;
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}