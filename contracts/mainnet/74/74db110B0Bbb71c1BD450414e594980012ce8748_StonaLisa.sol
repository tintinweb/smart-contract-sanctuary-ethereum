/*
 *     .d8888b.  88888888888  .d88888b.  888b    888        d8888       888      8888888  .d8888b.         d8888 
 *    d88P  Y88b     888     d88P" "Y88b 8888b   888       d88888       888        888   d88P  Y88b       d88888 
 *    Y88b.          888     888     888 88888b  888      d88P888       888        888   Y88b.           d88P888 
 *     "Y888b.       888     888     888 888Y88b 888     d88P 888       888        888    "Y888b.       d88P 888 
 *        "Y88b.     888     888     888 888 Y88b888    d88P  888       888        888       "Y88b.    d88P  888 
 *          "888     888     888     888 888  Y88888   d88P   888       888        888         "888   d88P   888 
 *    Y88b  d88P     888     Y88b. .d88P 888   Y8888  d8888888888       888        888   Y88b  d88P  d8888888888 
 *     "Y8888P"      888      "Y88888P"  888    Y888 d88P     888       88888888 8888888  "Y8888P"  d88P     888
 *
 *                                  A joint venture by DappVinci and Jiggle Labs
 *
 *                                               Attribute Decoder:
 *
 *                   HUE                            ACCESSORY                     READYMADE
 *                   0-15 = Red                     0 = Mini Pipe                 0 = UFO
 *                  16-30 = Red-Orange              1 = Straight Bong             1 = Antennae
 *                  31-60 = Orange                  2 = Curved Bong               2 = Pot
 *                 61-120 = Yellow-Green            3 = Blunt                     3 = Surgical Mask
 *                121-210 = Green-Blue              4 = Unlit Blunt               4 = Mustache
 *                211-300 = Blue-Magenta            5 = Joint                     5 = Moon
 *                301-360 = Magenta-Red             6 = Unlit Joint               6 = Monocle
 *                                                  7 = Pill Bottle               7 = Eye Mask
 *                                                  8 = Weed Leaf                 8 = Eye Patch
 *                                                  9 = Pipe                      9 = Sunglasses                                                                                                
 */
// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        string memory table = TABLE;
        uint256 encodedLen = 4 * ((data.length + 2) / 3);
        string memory result = new string(encodedLen + 32);

        assembly {
            mstore(result, encodedLen)
            let tablePtr := add(table, 1)
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            let resultPtr := add(result, 32)
            for {} lt(dataPtr, endPtr) {}{
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
                resultPtr := add(resultPtr, 1)
            }
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        return result;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
    }
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    string private _name;
    string private _symbol;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
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

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

contract StonaLisa is ERC721, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _nextTokenId;
    using Strings for uint256;
    bool public saleON = false;
    string public base_url;
    string private beneficiary;
    string internal constant head = '<svg id="StonaLisa by DappVinci" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"><rect width="1000" height="1000"/><g class="st h"><path d="M267 73c-176-28 587-67 509 24 37 7 50 75 41 115-9 42-90 142-124 9-11 39-22 30-20-11-41 85 0-56-60 21-9-12-20-104-122-104-74 0-85 47-108 67-7 8-11 18-10 29-9 7-11 15-11 23 0 74-9 21-26 21-10 0-13 14-15 14-4 0-9-51-44-51-25 0-51 22-66-20-45 98-19-59-47 50C164 105 147 89 267 73z"/><path d="M267 625c13 56-74 40-99 37-11-1-4-37 5-41C174 621 264 615 267 625z"/><path d="M178 578c-56-45 155-31 53-77 237 30-115 49 40 87C297 594 205 600 178 578z"/><path d="M817 565c-37-29-73-54-116-66-2-1 25-4 23-5-163-60 117-41-81-68 0-18 234-31 98 37C823 486 818 498 817 565z"/><path d="M296 364c107-58 77 99 64 80-3-4-9-12-14-11-56 12-60-25-108 8-24 17-93 18-33-6C256 414 354 382 296 364z"/><path d="M651 303c-22 3-14 6-36-7 17 6 200 4 204 4-27 19-53 7-76 7C710 309 680 309 651 303z"/><path d="M407 192c7-20 19-8 38-17 8-4 10-18 12-18 0 28 38 19 51 30C526 202 484 170 407 192z"/><path d="M539 261c-3 0-33 16-34 15s-6-3-9-4c-2-1-8 12-15-4 0-3-13 4-9 6 11 8 29 3 23 7-26 8-30-10-34-10-7 0-3 13-6 12-6-2-1-27 5-31 10-6 49 4 60 4 7 0 9-5 17-6 5 0-18-56-25-56-55-15-106-1-107 2-20 100-15 58 14 58 23 0 20 23 16 20s2 12-14 9c-1 0-1-2 0-2 13-4 13-7 6-10-4 0 0 5-9 5-6 0-2-14-17-3-2 1-9-5-9-1 3 28 2 58 19 91 6 11 39 37 52 36 19-1 46-20 58-32C543 335 547 261 539 261zM449 331c7 1 18-15 27-5 7 8-31 18-36 0C440 320 446 331 449 331zM450 365c0 0 18-6 19-2C472 371 449 365 450 365zM440 352c12-1 41-8 50-3 1 1 1 2 0 2C431 360 439 352 440 352z"/><path d="M507 265c0 3-4-3-13-3-18 0-31 11-22 2C479 257 507 255 507 265z"/><path d="M403 264c13-11 33-5 32 4-1 0-8-6-14-7C413 261 409 267 403 264z"/><path d="M449 569c-177-36 2-101 7-157 35 46 64-22 85-6 51 38-14 122 22 126 19 2 63-21 58-14-14 16 87-14-16 22C496 578 494 578 449 569z"/><path d="M639 630c1-8 25-8 25-8S647 632 639 630z"/><path d="M628 608c0 0 13-15 36-17C688 589 628 608 628 608z"/><path d="M586 834c-38-21-96-22-43 6 58 31 74 35 17 0C512 810 660 875 586 834z"/><path d="M636 849c-65-55 69-8 2-31C510 774 710 912 636 849z"/><path d="M307 783c0-6-44 46-50 46s26-41 26-47c0-7-34 23-27 11 2-3 8-10 8-17 0-13-29 44-29 27 0-14 24-70 51-56-70 34 67 8 36 41-8 9-23 33-23 25C298 808 307 784 307 783z"/><path d="M356 912c-13 12-11 27-14 28-4 2-28-14 13-59-31 23-22 40-26 41s-15-27 12-54c-53 61-15-23 18-30-47-15-28-79 20-79 45 0 105 47 138 56 8 2-9 6-19 5 65 46 67 70-14 27 66 60 62 74-10 26 51 48 49 60-22 17 18 17 20 29-32 0 16 26-63 3-55 78C365 975 335 954 356 912z"/></g><path class="a0 i" d="M503 353c-7-16 12-24-3-29 7 11-7 14 2 29-15-1 5 19-39-3-12-4 45 37 45 6C508 353 506 354 503 353z"/><g class="a1 h i"><path d="M454 595c-7-1-16-1-23 0 4 130 6 134-21 105-3-2-17 10-11 13 23 18-3 10-3 45 24 6 52 20 75 33 21-16 22-40 13-57C461 691 450 765 454 595z"/><path d="M400 700c-9-6 3-12 3-20 0-8-9-11-3-20-11 4-1 14-1 20C399 689 389 695 400 700z"/></g><g class="a2 h i"><path d="M516 667c0-6 10-16-1-20 6 9-3 12-3 20 0 8 12 14 3 20C527 682 516 675 516 667z"/><path d="M374 597c40 52 57 114 57 114s-21 26-14 54c36 14 94 51 100 46-37-27-17-7-6-42 12-39-24-47-9-62 15-15 33-1 4-20-12-8-5-3-6 8-4 28-18 7-43 11-13-45-34-86-63-123C417 552 337 608 374 597z"/></g><path class="a3 i" d="M499 327c6 9-3 12-3 20 0 7 7 12 6 18-5-13-74-34-8 6 17 8 5-16 5-24C500 340 510 331 499 327z"/><path class="a4 i" d="M501 363c3 3 1 10-7 10C447 344 470 340 501 363z"/><path class="a5 i" d="M502 330c6 9-3 12-3 20 0 8 12 13 3 20 1-4-37-23-37-20 0 4 36 23 37 20 11-5 1-11 1-20C503 344 513 333 502 330z"/><path class="a6 i" d="M500 367c4-1-23-20-27-18C469 350 496 368 500 367z"/><path class="a7 h i" d="M420 766c24 11 8 3 38 18 4-8 8-14 13-21 5 2 6 2 7-2-1 0-1-1-2-2 4-7 4-5 1-8 2-3 3-6 5-9-12-6-24-13-36-19-6 11-4 9-8 8-4 7-2 6-6 5 0 2-2 3-1 4C431 745 438 732 420 766z"/><path class="a8 h i" d="M532 776c-48-24-39 4 14-33-85-8-50 62-33-51-73 90 4 68-60 10 7 64 35 52-16 33 0 0-2 4 35 29-57 6-1 18 5 5-17 38-13 38 3 1-6 13 39 46 7 0C530 781 532 776 532 776z"/><g class="a9 i"><path class="h" d="M385 393c-1-2-6-11-1-14 9-7 9-3 13 0 10 8 15-12 20-4C420 379 395 414 385 393z"/><path d="M446 355c-1 1-14-5-25 20 0 0-6-1-4-4C434 348 448 349 446 355z"/><path class="h" d="M386 375c-9-6 3-12 3-20 0-8-9-11-3-20-11 4-1 14-1 20C385 364 375 370 386 375z"/></g><path class="r0 i" d="M382 143c-41-23-90-22-136-18 47-9 92-5 136 15-59-43-229-19-191 14C259 204 412 160 382 143zM259 157c0-9 57-9 57 0C316 167 259 167 259 157z"/><path class="r1 i" d="M425 147c37-37-34-56-34-56-7-13 43-30 49-26s0 11-1 20c-5 52 71 60 67 5 0-9-10-13-7-23 8-21 83-2 38 24-49 33 3 41 4 46C512 132 465 136 425 147zM518 64c-19 0-2 12 12 13C556 76 530 64 518 64zM428 71c-10-1-19 3-26 10C411 79 420 76 428 71z"/><path class="r2 i" d="M403 110c-20 0-20-6 0-6 0-17 0-11-2-13-8-6 5-5 111-6 9 0 35-43 44-38 6 3-3 6-31 38 36-1 24 4 22 4-1 0-1 0 0 13 19 0 20 6 1 7-6 0 15 44-24 46C407 161 403 163 403 110z"/><path class="r3 i" d="M528 324c-16-16 47-46 15-39-26 34-55 33-70 27-16-6-21-21-23-16-6 18-33 28-63 13 8 17 21 1 21 32-7 8-24 27 2 7 45 80 113 23 116-16C592 350 529 327 528 324z"/><g class="r4 i"><path d="M493 316c0 43-34 11-35 23C456 345 501 357 493 316z"/><path d="M456 341c-1-12-35 21-35-22C413 359 459 346 456 341z"/></g><path class="r5 i" d="M721 97c-90 37 8 157 63 68C785 165 701 178 721 97zM696 151c4 0-2 22 42 39C735 193 695 182 696 151z"/><path class="r6 i" d="M516 279c-1-12-10-24-26-24-35 0-37 53 0 53 16 0 25-11 26-23 15-1-9 26-2 51 2 6-3-8 3-23C522 301 528 289 516 279zM490 305c-31 1-29-45 0-45S521 304 490 305z"/><path class="r7 i" d="M409 240c21 0 33 7 43 7 6 0 26-8 54-9 70-1 27 64-7 64-22 0-39-15-49-15-7 0-20 20-39 21C381 308 352 241 409 240zM392 268c11 21 32 20 54 8C436 253 413 257 392 268zM527 263c-20-10-51-10-61 12C486 285 517 285 527 263z"/><path class="r8 i" d="M443 252c353-70-38-4-49 10C370 329 470 325 443 252z"/><path class="r9 i" d="M408 311c-31 0-40-60 12-60 56 0 98-14 95 33-2 35-62 31-62-7 0-12 6-14-4-14C436 261 459 311 408 311zM450 253c-27 1-13-1-8 7 0 0 10-3 14 0C456 260 475 252 450 253z"/><style type="text/css">.i{opacity:0;}.h{fill:hsl(';
    string internal constant tail = '{opacity:1;}</style></svg>';

    mapping (uint => uint) public idToSeed;

    constructor() ERC721("Stona Lisa", "STONALISA") {
        _nextTokenId.increment();
        base_url = "https://stonalisa.xyz/";
        beneficiary = '0x3841EF007E2A80b199EaBD5E0EC74b93bA2cd943';
    }

function mint(uint256 _amount) external payable nonReentrant {
    require(_amount > 0 && _amount < 11, "Amount must be 1-10");
    uint id = _nextTokenId.current();
    require(id + _amount < 4201, "Sold out");
    if (msg.sender != owner()) {
        require(saleON, "Sale OFF");
        require(msg.value == 0.042 ether * _amount);
    }
    for (uint i = 0; i < _amount; i++) {
        idToSeed[id] = (uint(keccak256(abi.encodePacked(block.number, id, msg.sender))));
        _nextTokenId.increment();
        _mint(msg.sender, id);
        id++;
    }
}

    function drawSVG(uint256 _tokenId) private view returns(string memory) {
    uint seed = idToSeed[_tokenId];
    return Base64.encode(bytes(
            abi.encodePacked(
                head,
                ((seed % 360)).toString(),
                ",100%,50%);} .a",
                ((seed / (10 ** 69)) % 10).toString(),
                "{opacity:1;} .r",
                ((seed / (10 ** 70)) % 10).toString(),
                tail
            )));
}

    function tokenURI(uint256 _tokenId) public view virtual override returns(string memory) {
    require(_exists(_tokenId),"Nonexistent token");
    uint seed = idToSeed[_tokenId];
    return string(abi.encodePacked(
            'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
                '{"name":"', 'Stona Lisa #', _tokenId.toString(),
                '", "description":"', 'Nifty on-chain digital readymades by DappVinci: A high art remix of a classic.',
                '", "attributes": [{"trait_type": "Hue", "value": "', ((seed % 360)).toString(),
                '"},{"trait_type": "Accessory", "value": "', ((seed / (10 ** 69)) % 10).toString(),
                '"},{"trait_type": "Readymade", "value": "', ((seed / (10 ** 70)) % 10).toString(),
                '"}], "external_url":"', base_url, _tokenId.toString(),
                '", "image": "', 'data:image/svg+xml;base64,', drawSVG(_tokenId),
                '"}'
                )))));
}

     function contractURI() external view returns(string memory) {
        return string(abi.encodePacked(
                'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
                    '{"name":"', 'Stona Lisa',
                    '", "description":"', 'A dank joint venture between art, blockchain, and culture',
                    '",  "external_url":"', base_url,
                    '", "image": "', 'data:image/svg+xml;base64,', drawSVG(1),
                    '", "seller_fee_basis_points": "', '420',
                    '", "fee_recipient": "', beneficiary,
                    '"}'
                    )))));
    }

    function setBaseURL(string memory _newURL) public onlyOwner {
        base_url = _newURL;
    }

    function setBeneficiary(string memory _newBeneficiary) public onlyOwner {
        beneficiary = _newBeneficiary;
    }

    function totalSupply() external view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    function toggleSale() external onlyOwner {
        saleON = !saleON;
    }

    function getLicenseNAME() public pure returns (string memory) {
        return "COMMERCIAL";
    }

    function getLicenseURI() public pure returns (string memory) {
        return "ar://zmc1WTspIhFyVY82bwfAIcIExLFH5lUcHHUN0wXg4W8/2";
    }

    function withdraw() external payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}