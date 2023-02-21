/**
 *Submitted for verification at Etherscan.io on 2023-02-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Import Solidity Modules

// Note: unaudited 2023-02-21

interface ERC1155TokenReceiver {
    function onERC1155Received(address operator_, address from_, uint256 id_,
        uint256 amount_, bytes calldata data_) external returns (bytes4);
    function onERC1155BatchReceived(address operator_, address from_,
        uint256[] calldata ids_, uint256[] calldata amounts_, bytes calldata data_)
        external returns (bytes4);
}

contract ERC1155 {

    event TransferSingle(address indexed operator_, address indexed from_, 
        address indexed to_, uint256 id_, uint256 amount_);
    event TransferBatch(address indexed operator_, address indexed from_, 
        address indexed to_, uint256[] ids_, uint256[] amounts_);
    event ApprovalForAll(address indexed owner_, address indexed operator_, 
        bool approved_);
    event URI(string value_, uint256 indexed id_);

    mapping(address => mapping(uint256 => uint256)) public balanceOf;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    string public name; 
    string public symbol; 

    constructor(string memory name_, string memory symbol_) {
        name = name_; 
        symbol = symbol_; 
    }

    // Internal Logics
    function _isSameLength(uint256 a, uint256 b) internal pure returns (bool) {
        return a == b;
    }
    function _isApprovedOrOwner(address from_) internal view returns (bool) {
        return msg.sender == from_ 
            || isApprovedForAll[from_][msg.sender];
    }
    function _ERC1155Supported(address from_, address to_, uint256 id_,
    uint256 amount_, bytes memory data_) internal {
        require(to_.code.length == 0 ? to_ != address(0) :
            ERC1155TokenReceiver(to_).onERC1155Received(
                msg.sender, from_, id_, amount_, data_) ==
            ERC1155TokenReceiver.onERC1155Received.selector,
                "_ERC1155Supported(): Unsupported Recipient!"
        );
    }
    function _ERC1155BatchSupported(address from_, address to_, uint256[] memory ids_,
    uint256[] memory amounts_, bytes memory data_) internal {
        require(to_.code.length == 0 ? to_ != address(0) :
            ERC1155TokenReceiver(to_).onERC1155BatchReceived(
                msg.sender, from_, ids_, amounts_, data_) ==
            ERC1155TokenReceiver.onERC1155BatchReceived.selector,
                "_ERC1155BatchSupported(): Unsupported Recipient!"
        );
    }

    // ERC1155 Logics
    function setApprovalForAll(address operator_, bool approved_) public virtual {
        isApprovedForAll[msg.sender][operator_] = approved_;
        emit ApprovalForAll(msg.sender, operator_, approved_);
    }

    function safeTransferFrom(address from_, address to_, uint256 id_, 
    uint256 amount_, bytes memory data_) public virtual {
        require(_isApprovedOrOwner(from_));
        
        balanceOf[from_][id_] -= amount_;
        balanceOf[to_][id_] += amount_;

        emit TransferSingle(msg.sender, from_, to_, id_, amount_);

        _ERC1155Supported(from_, to_, id_, amount_, data_);
    }

    function safeBatchTransferFrom(address from_, address to_, uint256[] memory ids_,
    uint256[] memory amounts_, bytes memory data_) public virtual {
        require(_isSameLength(ids_.length, amounts_.length));
        require(_isApprovedOrOwner(from_));

        for (uint256 i = 0; i < ids_.length; i++) {
            balanceOf[from_][ids_[i]] -= amounts_[i];
            balanceOf[to_][ids_[i]] += amounts_[i];
        }

        emit TransferBatch(msg.sender, from_, to_, ids_, amounts_);

        _ERC1155BatchSupported(from_, to_, ids_, amounts_, data_);
    }

    // Internal Mint / Burn Logic
    function _mint(address to_, uint256 id_, uint256 amount_, bytes memory data_)
    internal {
        balanceOf[to_][id_] += amount_;

        emit TransferSingle(msg.sender, address(0), to_, id_, amount_);

        _ERC1155Supported(address(0), to_, id_, amount_, data_);
    }

    function _batchMint(address to_, uint256[] memory ids_, uint256[] memory amounts_,
    bytes memory data_) internal {
        require(_isSameLength(ids_.length, amounts_.length));

        for (uint256 i = 0; i < ids_.length; i++) {
            balanceOf[to_][ids_[i]] += amounts_[i];
        }

        emit TransferBatch(msg.sender, address(0), to_, ids_, amounts_);

        _ERC1155BatchSupported(address(0), to_, ids_, amounts_, data_);
    }

    function _batchBurn(address from_, uint256[] memory ids_, 
    uint256[] memory amounts_) internal {
        require(_isSameLength(ids_.length, amounts_.length));
        
        for (uint256 i = 0; i < ids_.length; i++) {
            balanceOf[from_][ids_[i]] -= amounts_[i];
        }

        emit TransferBatch(msg.sender, from_, address(0), ids_, amounts_);
    }
    
    function _burn(address from_, uint256 id_, uint256 amount_) internal {
        balanceOf[from_][id_] -= amount_;
        emit TransferSingle(msg.sender, from_, address(0), id_, amount_);
    }

    // ERC165 Logic
    function supportsInterface(bytes4 interfaceId_) public pure virtual returns (bool) {
        return 
        interfaceId_ == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
        interfaceId_ == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
        interfaceId_ == 0x0e89341c;   // ERC165 Interface ID for ERC1155MetadataURI
    }

    // View Functions
    function balanceOfBatch(address[] memory owners_, uint256[] memory ids_) public
    view virtual returns (uint256[] memory) {
        require(_isSameLength(owners_.length, ids_.length));

        uint256[] memory _balances = new uint256[](owners_.length);

        for (uint256 i = 0; i < owners_.length; i++) {
            _balances[i] = balanceOf[owners_[i]][ids_[i]];
        }
        return _balances;
    }
}

// MockERC1155 Product
contract MockERC1155 is ERC1155 {
    
    constructor(string memory name_, string memory symbol) ERC1155(name_, symbol) {}

    function mint(address to_, uint256[] calldata tokenIds_,
    uint256[] calldata amounts_) external {
        uint256 l = tokenIds_.length;
        uint256 i; unchecked { do {
            _mint(to_, tokenIds_[i], amounts_[i], "");
        } while (++i < l); }
    }
}