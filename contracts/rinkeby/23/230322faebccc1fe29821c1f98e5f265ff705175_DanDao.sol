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

    mapping(address => uint256) private _count;

    mapping(address => User) private refundList;

    mapping(address => bool) private freeMintList;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        uint256 publicPrice_,
        string memory uri_
    ) ERC1155(uri_) {
        _name = name_;
        _symbol = symbol_;
        maxSupply = maxSupply_;
        _publicPrice = publicPrice_ * 10**15;
        _publicActive = false;
        _ddAddress = _msgSender();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setDefaultRoyalty(_msgSender(), 1000);
    }

    function withdraw(address addr) external onlyOwner {
        payable(addr).transfer(address(this).balance);
    }

    function whiteMint(
        uint256 amount,
        uint256 allowed,
        bytes32[] calldata proof
    ) external payable {
        require(totalSupply(DD) + amount <= maxSupply, "Exceeded max supply");
        require(_count[_msgSender()] + amount <= allowed, "Exceeded max");
        require(
            MerkleProof.verify(
                proof,
                _merkleRoot,
                keccak256(abi.encodePacked(_msgSender(), allowed))
            ),
            "Not part of list"
        );
        unchecked {
            _count[_msgSender()] = _count[_msgSender()] + amount;
        }
        _mint(_msgSender(), DD, amount, "");
    }

    function mint(uint256 amount) external payable {
        require(_publicActive, "Not yet started");
        require(totalSupply(DD) + amount <= maxSupply, "Exceeded max supply");
        if (!freeMintList[_msgSender()] && amount == 1) {
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
            0xBc422cf41a1afcf68fade465F9462D058C912048,
            DD,
            amount,
            data
        );
        payable(_msgSender()).transfer(amount * _publicPrice);
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
    }

    function setBaseData(uint256 newPrice, bool newActive) external onlyOwner {
        _publicPrice = newPrice * 10**15;
        _publicActive = newActive;
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

    function setMerkleRoot(bytes32 newRoot)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _merkleRoot = newRoot;
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