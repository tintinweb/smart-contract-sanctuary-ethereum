// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeMath} from "./SafeMath.sol";
import {Counters} from "./Counters.sol";
import {Base64} from "./Base64.sol";

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

interface ERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event ConsecutiveTransfer(
        uint256 indexed fromTokenId,
        uint256 toTokenId,
        address indexed fromAddress,
        address indexed toAddress
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

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface ERC721Metadata {
    function name() external view returns (string memory _name);

    function symbol() external view returns (string memory _symbol);

    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Transfers is ERC721, ERC721Metadata {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _nextTokenId;

    string private _name;

    string private _symbol;

    bool public _minting;

    uint256 constant MAX_TOKENS = 2000;
    uint256 constant MAX_TOKENS_PER_MINT = 10;
    uint256 constant PRICE = 0;
    uint256 public _countToken;

    uint256 public immutable _percentageTotal;
    uint256 public _percentageRoyalty;

    uint256 public _transferTotal;

    address public _owner;
    address public _receiver;

    // Mapping from owner address to token ID.
    mapping(address => uint256) private _tokens;

    // Mapping owner address to token count.
    mapping(address => uint256) private _balances;

    // Mapping from token ID to owner address.
    mapping(uint256 => address) private _owners;

    // Mapping from token ID to approved address.
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals.
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping token ID to number of transfers.
    mapping(uint256 => uint256) private _transferCount;

    string[] ROMAN_DIGITS = [
        "M",
        "CM",
        "D",
        "CD",
        "C",
        "XC",
        "L",
        "XL",
        "X",
        "IX",
        "V",
        "IV",
        "I"
    ];

    uint256[] ROMAN_VALUES = [
        1,
        4,
        5,
        9,
        10,
        40,
        50,
        90,
        100,
        400,
        500,
        900,
        1000
    ];

    function getTransfersCount(uint256 tokenId)
        public
        view
        returns (uint256 transfersCount)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        return _transferCount[tokenId];
    }

    modifier onlyOwner() {
        require(_msgSender() == _owner, "Merge: msg.sender is not owner");
        _;
    }

    constructor(address owner_) {
        _name = "transfers";
        _symbol = "T";

        _owner = owner_;
        _receiver = owner_;

        _percentageTotal = 10000;
        _percentageRoyalty = 1000;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view returns (uint256) {
        return _countToken;
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(
            _exists(tokenId),
            "ERC721: transfer attempt for nonexistent token"
        );
        require(
            ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");
        require(from != to, "ERC721: transfer attempt to self");

        _approve(address(0), tokenId);

        _balances[to] += 1;
        _balances[from] -= 1;

        _owners[tokenId] = to;
        _transferCount[tokenId] += 1;

        emit Transfer(from, to, tokenId);
    }

    function setRoyaltyBips(uint256 percentageRoyalty_) external onlyOwner {
        require(
            percentageRoyalty_ <= _percentageTotal,
            "Merge: Illegal argument more than 100%"
        );
        _percentageRoyalty = percentageRoyalty_;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address, uint256)
    {
        uint256 royaltyAmount = (salePrice * _percentageRoyalty) /
            _percentageTotal;
        return (_receiver, royaltyAmount);
    }

    function setOwner(address newOwner) external onlyOwner {
        _owner = newOwner;
    }

    function setRoyaltyReceiver(address receiver_) external onlyOwner {
        _receiver = receiver_;
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        return _owners[tokenId];
    }

    function _mint(uint256 _amount) public payable {
        require(_minting, "Minting is currently not active");
        require(
            MAX_TOKENS > _amount + _nextTokenId.current() + 1,
            "Not enough tokens left to buy."
        );
        require(
            _amount > 0 && _amount < MAX_TOKENS_PER_MINT + 1,
            "Amount of tokens exceeds amount of tokens you can purchase in a single purchase."
        );
        require(
            _balances[_msgSender()] + _amount < MAX_TOKENS_PER_MINT + 1,
            "Amount of tokens would exceed amount of tokens you can purchase during mint."
        );
        require(
            msg.value >= PRICE * _amount,
            "Amount of ether sent not correct."
        );

        for (uint256 i = 0; i < _amount; i++) {
            _balances[_msgSender()] += 1;
            _owners[_nextTokenId.current()] = _msgSender();
            _nextTokenId.increment();
        }
    }

    function startMint() external onlyOwner {
        _minting = true;
    }

    function stopMint() external onlyOwner {
        _minting = false;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _transfer(from, to, tokenId);
    }

    function balanceOf(address owner) public view override returns (uint256) {
        return _balances[owner];
    }

    function getTransfersOf(uint256 tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        return _transferCount[tokenId];
    }

    function tokenOf(address owner) public view virtual returns (uint256) {
        uint256 token = _tokens[owner];
        return token;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }
        return _operatorApprovals[owner][operator];
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _transferCount[tokenId] != 0;
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );

        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function getSvg(uint256 tokenId) private view returns (string memory) {
        uint256 i = 0;
        string memory roman_num;
        uint256 num = _transferCount[tokenId];

        while (num > 0) {
            while (ROMAN_VALUES[i] <= num) {
                roman_num = string(
                    abi.encodePacked(roman_num, ROMAN_VALUES[i])
                );
                num -= ROMAN_VALUES[i];
            }
            i -= 1;
        }
        string[3] memory parts;
        parts[
            0
        ] = '<svg width="800" height="800" xmlns="http://www.w3.org/2000/svg"><rect width="100%" height="100%"/><text xml:space="preserve" text-anchor="middle" font-family="Noto Sans JP" font-size="80" x="50%" y="50%" alignment-baseline="middle" stroke-width="0" stroke="#000" fill="#fff">';
        parts[1] = roman_num;
        parts[2] = "</text></svg>";

        return string(abi.encodePacked(parts[0], parts[1], parts[2]));
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        string memory svgData = getSvg(tokenId);

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Transfers", "description": "", "image_data": "',
                        bytes(svgData),
                        '"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (isContract(to)) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                }
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
        return true;
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        bytes4 _ERC165_ = 0x01ffc9a7;
        bytes4 _ERC721_ = 0x80ac58cd;
        bytes4 _ERC2981_ = 0x2a55205a;
        bytes4 _ERC721Metadata_ = 0x5b5e139f;
        return
            interfaceId == _ERC165_ ||
            interfaceId == _ERC721_ ||
            interfaceId == _ERC2981_ ||
            interfaceId == _ERC721Metadata_;
    }

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    function _burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId);
        _approve(address(0), tokenId);

        delete _tokens[owner];
        delete _owners[tokenId];

        _transferTotal -= 1;
        _transferCount[tokenId] += 1;
        _balances[owner] -= 1;

        emit Transfer(owner, address(0), tokenId);
    }
}