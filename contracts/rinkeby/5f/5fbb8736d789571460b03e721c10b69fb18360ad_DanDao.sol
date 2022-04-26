// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.12;

import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";
import "./MerkleProof.sol";
import "./ERC2981.sol";
import "./AccessControl.sol";
import "./Address.sol";
import "./Ownable.sol";

contract DanDao is
    ERC1155,
    ERC1155Burnable,
    ERC1155Supply,
    AccessControl,
    ERC2981,
    Ownable
{
    struct User {
        uint256 count;
        uint256 mintedTime;
    }

    using Address for address;

    using MerkleProof for bytes32[];

    uint256 public constant DD = 0;

    uint256 public maxSupply;

    string private _name;

    string private _symbol;

    bytes32 private _merkleRoot;

    uint256 private _publicPrice;

    bool private _publicActive;

    address private _ddAddress;

    mapping(address => User) private refundList;

    mapping(address => bool) private freeMintList;

    uint256 private maxFreeMint = 666;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        uint256 publicPrice_,
        string memory uri_,
        bytes32 merkleRoot_
    ) ERC1155(uri_) {
        _name = name_;
        _symbol = symbol_;
        maxSupply = maxSupply_;
        _publicPrice = publicPrice_ * 10**15;
        _publicActive = false;
        _ddAddress = _msgSender();
        _merkleRoot = merkleRoot_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setDefaultRoyalty(_msgSender(), 10000);
    }

    function withdraw(address addr) external onlyOwner {
        payable(addr).transfer(address(this).balance);
    }

    function whiteMint(uint256 amount, address[] memory addrs)
        external
        payable
    {
        require(totalSupply(DD) + amount <= maxSupply, "Exceeded max supply");
        require(amount == 1, "Exceeded max");
        require(!freeMintList[_msgSender()], "minted");
        require(
            MerkleProof.verify(addrs, _merkleRoot, _msgSender()),
            "Not part of list"
        );
        unchecked {
            freeMintList[_msgSender()] = true;
        }
        _mint(_msgSender(), DD, amount, "");
    }

    function mint(uint256 amount) external payable {
        require(_publicActive, "Not yet started");
        require(totalSupply(DD) + amount <= maxSupply, "Exceeded max supply");
        if (totalSupply(DD) + amount <= maxFreeMint) {
            require(amount == 1 && !freeMintList[_msgSender()], "error");
            freeMintList[_msgSender()] = true;
        } else {
            require(_publicPrice * amount <= msg.value, "Value incorrect");
            unchecked {
                refundList[_msgSender()].count =
                    refundList[_msgSender()].count +
                    amount;
                refundList[_msgSender()].mintedTime = block.timestamp;
            }
        }
        _mint(_msgSender(), DD, amount, "");
    }

    function airDrop(address[] memory addrs, uint256 amount)
        external
        onlyOwner
    {
        require(
            totalSupply(DD) + addrs.length * amount <= maxSupply,
            "Exceeded max supply"
        );
        for (uint256 i = 0; i < addrs.length; i++) {
            _mint(addrs[i], DD, amount, "");
        }
    }

    function refund(uint256 amount) external {
        require(amount <= refundList[_msgSender()].count, "amount incorrect");
        require(
            refundList[_msgSender()].count <= balanceOf(_msgSender(), DD),
            "amount incorrect"
        );
        require(
            block.timestamp < refundList[_msgSender()].mintedTime + 604800,
            "overtime"
        );
        unchecked {
            refundList[_msgSender()].count =
                refundList[_msgSender()].count -
                amount;
        }
        bytes memory data = "refund";
        safeTransferFrom(
            _msgSender(),
            _ddAddress,
            DD,
            amount,
            data
        );
        payable(_msgSender()).transfer(amount * _publicPrice);
    }

    function setBaseData(uint256 newPrice, bool newActive, uint256 newMaxSupply, uint256 _maxFreeMint, bytes32 newRoot) external onlyOwner {
        _publicPrice = newPrice * 10**15;
        _publicActive = newActive;
        maxSupply = newMaxSupply;
        maxFreeMint = _maxFreeMint;
        _merkleRoot = newRoot;
    }

    function setURI(string memory newURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setURI(newURI);
    }

    function getUserStatus(address addr)
        public
        view
        returns (
            bool,
            uint256,
            bool
        )
    {
        return (freeMintList[addr], _publicPrice, _publicActive);
    }

    function burn(address account, uint256 amount) external {
        require(_msgSender() == _ddAddress, "Invalid address");
        _burn(account, DD, amount);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function merkleRoot() external view returns (bytes32) {
        return _merkleRoot;
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, ERC2981, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}