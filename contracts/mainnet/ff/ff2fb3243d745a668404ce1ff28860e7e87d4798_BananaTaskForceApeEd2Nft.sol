/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom( address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom( address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address _owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}

abstract contract ERC721 is IERC721, IERC721Metadata {
    using Address for address;

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

    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function balanceOf(address owner) external view virtual override returns (uint256) {
        require(owner != address(0), "address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "invalid token ID");
        return owner;
    }

    function name() external view virtual override returns (string memory) {
        return _name;
    }

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function approve(address to, uint256 tokenId) external virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external virtual override {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "transfer to non ERC721Receiver implementer");
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
        require(to != address(0), "mint to the zero address");
        require(!_exists(tokenId), "token already minted");
        require(!_exists(tokenId), "token already minted");

        unchecked {
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "transfer from incorrect owner");
        require(to != address(0), "transfer to the zero address");
        require(ERC721.ownerOf(tokenId) == from, "transfer from incorrect owner");
        delete _tokenApprovals[tokenId];

        unchecked {
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
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
        require(owner != operator, "approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "invalid token ID");
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}

contract BananaTaskForceApeEd2Nft is ERC721 {

    address public owner;
    bool public enabled;
    address payable public wallet;
    uint256 public total;
    uint256 public remaining;
    bool public opened;

    string private _baseTokenURI;
    uint256 private nonce = 0;
    uint256 private blockSize;
    uint256[] private blockLog;

    SaleMode public saleMode;

    uint256 public reserved;
    uint256 public reserveLimit;

    enum SaleMode { FREELIST, WHITELIST, PUBLIC1, PUBLIC2 }
    struct Mode {
        uint256 price;
        uint256 limit;
        bool useWhitelist;
        mapping(address => uint256) purchases;
        mapping(address => bool) whitelist;
    }
    mapping(SaleMode => Mode) private modes;

    modifier onlyOwner() {
        require(msg.sender == owner, "can only be called by the contract owner");
        _;
    }

    modifier isEnabled() {
        require(enabled, "sale is currently disabled");
        _;
    }

    constructor() ERC721("Banana Task Force Ape Genesis Collection", "BTFA") {
        owner = msg.sender;
        _baseTokenURI = "https://bafybeicxrpwqlno3hrtli7qtjp6sh35arge4why5t73c75uib73tk2mnsi.ipfs.nftstorage.link/";

        wallet = payable(0x2411eD788bACdB0394570c8B3A393Af0AB9Cfb4F);
        saleMode = SaleMode.FREELIST;
        reserveLimit = 500;

        modes[SaleMode.FREELIST].price = 0;
        modes[SaleMode.FREELIST].limit = 2;
        modes[SaleMode.FREELIST].useWhitelist = true;

        modes[SaleMode.WHITELIST].price = 100000000000000000;
        modes[SaleMode.WHITELIST].limit = 10;
        modes[SaleMode.WHITELIST].useWhitelist = true;

        modes[SaleMode.PUBLIC1].price = 125000000000000000;
        modes[SaleMode.PUBLIC1].limit = 8;
        modes[SaleMode.PUBLIC1].useWhitelist = false;

        modes[SaleMode.PUBLIC2].price = 150000000000000000;
        modes[SaleMode.PUBLIC2].limit = 5;
        modes[SaleMode.PUBLIC2].useWhitelist = false;

        total = 8000;
        blockSize = 100;
        remaining = total;
        for (uint256 i = 0; i < total / blockSize; i++) {
            blockLog.push(blockSize);
        }
    }

    function tokenURI(uint256 tokenId) external override view returns (string memory) {
        require(_exists(tokenId));

        if (opened) {
            return string(abi.encodePacked(_baseTokenURI, uint2str(tokenId), ".json"));
        } else {
            return "https://bafybeiemdtocmgniv4m7zajx7aiuimqxdjwkxy5snvouqkgirq2lkxlpai.ipfs.nftstorage.link/Closed.gif";
        }
    }

    function status() public view returns (bool canBuy, uint256 boxCost, uint256 boxRemaining, uint256 hasPurchased, uint256 purchaseLimit) { 
        canBuy = enabled && canPurchase(msg.sender, 1);
        boxCost = modes[saleMode].price;
        boxRemaining = remaining;
        hasPurchased =  modes[saleMode].purchases[msg.sender];
        purchaseLimit =  modes[saleMode].limit;
    }

    function purchaseBlindbox(uint256 amount) public payable isEnabled {
        require (remaining >= amount, "Not enough blindboxes available");
        require(canPurchase(msg.sender, amount), "You cannot purchase at this time.");
        require (msg.value == modes[saleMode].price * amount, "Incorrect Eth value.");

        if (modes[saleMode].price > 0) {
            wallet.transfer(modes[saleMode].price * amount);
        }

        for (uint256 i = 0; i < amount; i++) {
            mint(msg.sender);
        }
        modes[saleMode].purchases[msg.sender] += amount;
    }

    function mint(address who) private {
        uint256 nftBlock = requestRandomWords();
        uint256 blockRoll = nftBlock % blockLog.length;
        while (blockLog[blockRoll] == 0) {
            blockRoll++;

            if (blockRoll >= blockLog.length) {
                blockRoll = 0;
            }
        }

        uint256 nftRoll = requestRandomWords();
        uint256 roll = nftRoll % blockSize + 1;
        while (_exists(blockRoll * blockSize + roll)) {
            roll++;

            if (roll > blockSize) {
                roll = 1;
            }
        }

        _mint(who, blockRoll * blockSize + roll);
        blockLog[blockRoll]--;
        remaining--;
    }

    // Admin

    function setOwner(address who) external onlyOwner {
        owner = who;
    } 

    function openBoxes() external onlyOwner {
        opened = true;
    } 

    function setPrice(SaleMode mode, uint256 price) external onlyOwner {
        modes[mode].price = price;
    }

    function setEnabled(bool on) external onlyOwner {
        enabled = on;
    }

    function setMode(SaleMode mode) external onlyOwner {
        saleMode = mode;
    }

    function setUseWhitelist(SaleMode mode, bool on) external onlyOwner {
        modes[mode].useWhitelist = on;
    }

    function setWhitelist(SaleMode mode, address who, bool whitelisted) external onlyOwner {
        modes[mode].whitelist[who] = whitelisted;
    }

    function setWhitelisted(SaleMode mode, address[] calldata who, bool whitelisted) external onlyOwner {
        for (uint256 i = 0; i < who.length; i++) {
            modes[mode].whitelist[who[i]] = whitelisted;
        }
    }

    function setBuyLimits(SaleMode mode, uint256 limit) external onlyOwner {
        modes[mode].limit = limit;
    }

    function reserveNfts(address who, uint256 amount) external onlyOwner {
        require(reserved + amount <= reserveLimit, "NFTS have already been reserved");

        for (uint256 i = 0; i < amount; i++) {
            mint(who);
        }

        reserved += amount;
    }

    // Private

    function canPurchase(address who, uint256 amount) private view returns (bool) {
        return modes[saleMode].purchases[who] + amount <= modes[saleMode].limit && 
            (modes[saleMode].useWhitelist == false || modes[saleMode].whitelist[who]);
    }

    function uint2str(uint _i) private pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function requestRandomWords() private returns (uint256) {
        nonce += 1;
        return uint(keccak256(abi.encodePacked(nonce, msg.sender, blockhash(block.number - 1))));
    }

}