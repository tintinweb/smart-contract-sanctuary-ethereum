// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IERC1155 {
    function transfer(uint256 id, address to) external;

    function balanceOf(address account, uint256 id) external view returns (uint256); 
}

abstract contract ERC721 {
    event Transfer(address from, address to, uint amount);

    event Approval(address owner, address spender, uint tokenId);

    event ApprovalForAll(address owner, address spender, bool approved);

    struct Properits {
        uint hat;
        uint clothes;
    }

    string private _name;

    string private _symbol;

    mapping(uint256 => Properits) public _metadata;

    mapping(uint256 => address) internal _owners;

    mapping(address => uint256) private _balances;

    mapping(uint256 => address) private _tokenApprovals;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    IERC1155 public erc1155;

    constructor(string memory name_, string memory symbol_, address _erc1155) {
        _name = name_;
        _symbol = symbol_;
        erc1155 = IERC1155(_erc1155);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x80ac58cd;    
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId)) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        //_beforeTokenTransfer(address(0), to, tokenId);

        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);
     
        owner = ERC721.ownerOf(tokenId);

        delete _tokenApprovals[tokenId];

        unchecked {
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        delete _tokenApprovals[tokenId];

        unchecked {
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        erc1155.transfer(0, to);
        erc1155.transfer(1, to);
        erc1155.transfer(2, to);
    }
    
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Strings} from "./Strings.sol";
import {ERC721} from "./ERC721.sol";

contract PFP is ERC721 {
    using Strings for uint256;

    uint public currentIndex = 1;

    string public baseURI;
    string public suffix;

    constructor(string memory _baseURI, address _erc1155) 
        ERC721("Sandpock PFP", "S PFP", _erc1155) 
    {
        baseURI = _baseURI;
    }

    function mint() public {
        _mint(msg.sender, currentIndex++);
    }

    function tokenURI(uint tokenId) public view override returns (string memory) {
        ERC721.Properits storage properits = ERC721._metadata[tokenId];
        
        address owner = _owners[tokenId];
        bool _hat;
        bool _clothes;

        if (erc1155.balanceOf(owner, 0) > 0 || 
            erc1155.balanceOf(owner, 1) > 0 || 
            erc1155.balanceOf(owner, 2) > 0) 
        {
            _hat = true;
        }

        if (erc1155.balanceOf(owner, 3) > 0 || 
            erc1155.balanceOf(owner, 4) > 0 || 
            erc1155.balanceOf(owner, 5) > 0) 
        {
            _clothes = true;
        }  

        if (_hat && _clothes) {
            return 
            string.concat(
                baseURI, 
                tokenId.toString(), 
                properits.hat.toString(), 
                properits.clothes.toString(), 
                suffix
            );
        } else if (_hat) {
            return 
            string.concat(
                baseURI, 
                tokenId.toString(), 
                properits.hat.toString(), 
                "X", 
                suffix
            );
        } else if (_clothes) {
            return 
            string.concat(
                baseURI, 
                tokenId.toString(), 
                "X", 
                properits.hat.toString(), 
                suffix
            );
        } else {
            return 
            string.concat(
                baseURI, 
                tokenId.toString(), 
                "X", 
                "X", 
                suffix
            );
        }
    }

    function setProperits(uint256 tokenId, uint[2] memory data) public {
        if (ERC721._owners[tokenId] != msg.sender) {
            revert ();
        }
        if (erc1155.balanceOf(msg.sender, 0) == 0) {
            revert ();
        }
        if (erc1155.balanceOf(msg.sender, 1) == 0) {
            revert ();
        }
        if (erc1155.balanceOf(msg.sender, 2) == 0) {
            revert ();
        }
        if (erc1155.balanceOf(msg.sender, 3) == 0) {
            revert ();
        }
        if (erc1155.balanceOf(msg.sender, 4) == 0) {
            revert ();
        }
        if (erc1155.balanceOf(msg.sender, 5) == 0) {
            revert ();
        }
 
        ERC721.Properits memory properits = ERC721.Properits({
            hat: data[0],
            clothes: data[1]
        });

        _metadata[tokenId] = properits;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library Strings {
    function toString(uint256 value) internal pure returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}