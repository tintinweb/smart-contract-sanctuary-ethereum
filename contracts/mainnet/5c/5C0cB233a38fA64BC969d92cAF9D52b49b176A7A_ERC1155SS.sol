/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title ERC1155SS (ERC1155 Sumo Soul)
 * @author 0xSumo
 */

 abstract contract OwnControll {
    address public owner;
    mapping(address => bool) public admin;
    modifier onlyOwner { require(owner == msg.sender, "Not Owner"); _; }
    modifier onlyAdmin { require(admin[msg.sender], "Not Admin"); _; }
    constructor() { owner = msg.sender; }
    function transferOwnership(address new_) external onlyOwner { owner = new_; }
    function setAdmin(address address_, bool bool_) external onlyOwner { admin[address_] = bool_; }
}


interface ERC1155TokenReceiver {
    function onERC1155Received(address operator_, address from_, uint256 id_, uint256 amount_, bytes calldata data_) external returns (bytes4);
    function onERC1155BatchReceived(address operator_, address from_, uint256[] calldata ids_, uint256[] calldata amounts_, bytes calldata data_) external returns (bytes4);
}

interface IRender {
    function tokenURI(uint256 id_) external view returns (string memory);
}

contract ERC1155SS is OwnControll {
    
    string public name; 
    string public symbol; 
    IRender private Render;

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    event TransferSingle(address indexed operator_, address indexed from_, address indexed to_, uint256 id_, uint256 amount_);
    event TransferBatch(address indexed operator_, address indexed from_, address indexed to_, uint256[] ids_, uint256[] amounts_);

    constructor(string memory name_, string memory symbol_, address render_) {
        name = name_;
        symbol = symbol_;
        Render = IRender(render_);
    }

    function _ERC1155Supported(address from_, address to_, uint256 id_, uint256 amount_, bytes memory data_) internal {
        require(to_.code.length == 0 ? to_ != address(0) : ERC1155TokenReceiver(to_).onERC1155Received(
            msg.sender, from_, id_, amount_, data_) ==
            ERC1155TokenReceiver.onERC1155Received.selector,
            "_ERC1155Supported(): Unsupported Recipient!"
        );
    }

    function _ERC1155BatchSupported(address from_, address to_, uint256[] memory ids_, uint256[] memory amounts_, bytes memory data_) internal {
        require(to_.code.length == 0 ? to_ != address(0) : ERC1155TokenReceiver(to_).onERC1155BatchReceived(
            msg.sender, from_, ids_, amounts_, data_) ==
            ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "_ERC1155BatchSupported(): Unsupported Recipient!"
        );
    }

    function _mintInternal(address to_, uint256 id_, uint256 amount_) internal {
        balanceOf[to_][id_] += amount_;
    }

    function _mint(address to_, uint256 id_, uint256 amount_, bytes memory data_) internal {
        _mintInternal(to_, id_, amount_);
        emit TransferSingle(msg.sender, address(0), to_, id_, amount_);
        _ERC1155Supported(address(0), to_, id_, amount_, data_);
    }

    function _batchMint(address to_, uint256[] memory ids_, uint256[] memory amounts_, bytes memory data_) internal {
        require(_isSameLength(ids_.length, amounts_.length));
        for (uint256 i = 0; i < ids_.length; i++) {
            _mintInternal(to_, ids_[i], amounts_[i]);
        }
        emit TransferBatch(msg.sender, address(0), to_, ids_, amounts_);
        _ERC1155BatchSupported(address(0), to_, ids_, amounts_, data_);
    }

    function _burnInternal(address from_, uint256 id_, uint256 amount_) internal {
        balanceOf[from_][id_] -= amount_;
    }

    function _burn(address from_, uint256 id_, uint256 amount_) internal {
        _burnInternal(from_, id_, amount_);
        emit TransferSingle(msg.sender, from_, address(0), id_, amount_);
    }

    function _batchBurn(address from_, uint256[] memory ids_, uint256[] memory amounts_) internal {
        require(_isSameLength(ids_.length, amounts_.length));  
        for (uint256 i = 0; i < ids_.length; i++) {
            _burnInternal(from_, ids_[i], amounts_[i]);
        }
        emit TransferBatch(msg.sender, from_, address(0), ids_, amounts_);
    }

    function _isSameLength(uint256 a, uint256 b) internal pure returns (bool) {
        return a == b;
    }

    function setRender(address _address) external onlyOwner {
        Render = IRender(_address);
    }

    function mintToken(address to_, uint256 id_, uint256 amount_, bytes memory data_) external onlyAdmin {
        _mint(to_, id_, amount_, data_);
    }

    function mintBatch(address[] calldata to_, uint256 id_, uint256[] memory amount_, bytes memory data_) external onlyOwner {
        require(_isSameLength(to_.length, amount_.length));
        for (uint256 i = 0; i < to_.length;) {
            _mint(to_[i], id_, amount_[i], data_);
            unchecked { ++i; }
        }
    }

    function mintTokenBatch(address to_, uint256[] memory ids_, uint256[] memory amounts_, bytes memory data_) external onlyAdmin {
        _batchMint(to_, ids_, amounts_, data_);
    }

    function burnToken(address from_, uint256 id_, uint256 amount_) external onlyAdmin {
        _burn(from_, id_, amount_);
    }

    function burnTokenBatch(address from_, uint256[] memory ids_, uint256[] memory amounts_) external onlyAdmin {
        _batchBurn(from_, ids_, amounts_);
    }

    function supportsInterface(bytes4 interfaceId_) public pure virtual returns (bool) {
        return interfaceId_ == 0x01ffc9a7 || interfaceId_ == 0xd9b67a26 || interfaceId_ == 0x0e89341c;
    }

    function uri(uint256 id_) public virtual view returns (string memory) {
        return Render.tokenURI(id_);
    }

    function balanceOfBatch(address[] memory owners_, uint256[] memory ids_) public view virtual returns (uint256[] memory) {
        require(_isSameLength(owners_.length, ids_.length));
        uint256[] memory _balances = new uint256[](owners_.length);
        for (uint256 i = 0; i < owners_.length; i++) {
            _balances[i] = balanceOf[owners_[i]][ids_[i]];
        }
        return _balances;
    }
}