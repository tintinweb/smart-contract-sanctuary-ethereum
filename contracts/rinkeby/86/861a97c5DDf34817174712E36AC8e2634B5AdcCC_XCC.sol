// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./ERC721A.sol";

contract XCC is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    enum Status {
        Pending,
        PreSale,
        PublicSale,
        Finished
    }

    struct SaleRecord {
        address addr;
        uint256 amount;
        uint256 blockNum;
    }

    Status public status;
    string public baseURI;
    address private _signer;
    uint256 public tokensReserved;
    uint256 public immutable maxSupply;
    uint256 public immutable reserveAmount;
    uint256 public constant PRICE = 0.0502 * 10**18; // 0.0502 ETH
    bool public balanceWithdrawn;
    
    uint256 public immutable presaleLimit;
    uint256 public immutable publicsaleLimit;

    mapping(address => uint256) public presaleMinted;
    mapping(address => uint256) public publicsaleMinted;
    SaleRecord[] public presaleRecord;
    address[] public publicsaleRecord;
    address[] public whitelist;

    event Minted(address minter, uint256 amount);
    event StatusChanged(Status status);
    event SignerChanged(address signer);
    event ReservedToken(address minter, address recipient, uint256 amount);
    event BaseURIChanged(string newBaseURI);

    constructor(
        string memory initBaseURI,
        address signer,
        uint256 _presaleLimit,
        uint256 _publicsaleLimit,
        uint256 _collectionSize,
        uint256 _reserveAmount
    ) ERC721A("X Chimps Club", "XCC", _presaleLimit, _collectionSize) {
        baseURI = initBaseURI;
        _signer = signer;
        presaleLimit = _presaleLimit;
        publicsaleLimit = _publicsaleLimit;
        maxSupply = _collectionSize;
        reserveAmount = _reserveAmount;
    }

    function addWhitelist(address[] memory _whitelist) external onlyOwner {
        require(status == Status.PreSale || status == Status.Pending, "XCC: Only PreSale or Pending status can execute this operation.");
        require(_whitelist.length > 0, "XCC: No data found.");
        for (uint256 i = 0; i < _whitelist.length; i++) {
            whitelist.push(_whitelist[i]);
        }
    }

    function deleteWhitelist(address[] memory _whitelist) external onlyOwner {
        require(status == Status.PreSale || status == Status.Pending, "XCC: Only PreSale or Pending status can execute this operation.");
        require(_whitelist.length > 0, "XCC: No data found.");
        for (uint256 i = 0; i < _whitelist.length; i++) {
            for (uint256 ii = 0; ii < whitelist.length; ii++) {
                if (whitelist[ii] == _whitelist[i]) {
                    delete whitelist[ii];
                }
            }
        }
    }

    function syncWhitelist(address[] memory _whitelist) external onlyOwner {
        require(status == Status.PreSale || status == Status.Pending, "XCC: Only PreSale or Pending status can execute this operation.");
        require(_whitelist.length > 0, "XCC: No data found.");
        delete whitelist;
        whitelist = _whitelist;
    }

    function _hash(string calldata salt, address _address)
        internal
        view
        returns (bytes32)
    {
        return keccak256(abi.encode(salt, address(this), _address));
    }

    function _verify(bytes32 hash, bytes memory token)
        internal
        view
        returns (bool)
    {
        return (_recover(hash, token) == _signer);
    }

    function _recover(bytes32 hash, bytes memory token)
        internal
        pure
        returns (address)
    {
        return hash.toEthSignedMessageHash().recover(token);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function reserve(address recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "XCC: zero address");
        require(amount > 0, "XCC: invalid amount");
        require(
            totalSupply() + amount <= collectionSize,
            "XCC: max supply exceeded"
        );
        require(
            tokensReserved + amount <= reserveAmount,
            "XCC: max reserve amount exceeded"
        );
        require(
            amount % maxBatchSize == 0,
            "XCC: can only mint a multiple of the maxBatchSize"
        );

        uint256 numChunks = amount / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(recipient, maxBatchSize);
        }
        tokensReserved += amount;
        emit ReservedToken(msg.sender, recipient, amount);
    }

    function presaleMint(
        uint256 amount//,
        // string calldata salt,
        // bytes calldata token
    ) external payable {
        require(status == Status.PreSale, "XCC: Presale is not active.");
        require(checkIsWhitelist(msg.sender), "XCC: Only wallet addresses in the whitelist can participate in the pre-sale.");
        require(
            tx.origin == msg.sender,
            "XCC: contract is not allowed to mint."
        );
        // require(_verify(_hash(salt, msg.sender), token), "XCC: Invalid token.");
        require(
            presaleMinted[msg.sender] + amount <= presaleLimit,
            "XCC: Max mint amount per wallet exceeded."
        );
        require(
            totalSupply() + amount + reserveAmount - tokensReserved <=
                collectionSize,
            "XCC: Max supply exceeded."
        );

        _safeMint(msg.sender, amount);
        presaleMinted[msg.sender] += amount;
        presaleRecord.push(SaleRecord({addr: msg.sender, amount: amount, blockNum: block.number}));
        refundIfOver(PRICE * amount);

        emit Minted(msg.sender, amount);
    }

    function mint() external payable {
        require(status == Status.PublicSale, "XCC: Public sale is not active.");
        require(
            tx.origin == msg.sender,
            "XCC: contract is not allowed to mint."
        );
        require(
            publicsaleMinted[msg.sender] + 1 <= publicsaleLimit,
            "XCC: Max mint amount per wallet exceeded."
        );
        require(
            totalSupply() + 1 + reserveAmount - tokensReserved <=
                collectionSize,
            "XCC: Max supply exceeded."
        );

        _safeMint(msg.sender, 1);
        publicsaleMinted[msg.sender] += 1;
        publicsaleRecord.push(msg.sender);
        refundIfOver(PRICE);

        emit Minted(msg.sender, 1);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "XCC: Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function checkIsWhitelist(address addr) internal view returns (bool) {
        require(addr != address(0), "XCC: zero address");
        for (uint256 i = 0; i < whitelist.length; i++) {
            if (whitelist[i] == addr) {
                return true;
            }
        }
        return false;
    }

    function withdraw(address to_, uint256 amount_) external nonReentrant onlyOwner {
        // require(
        //     status == Status.Finished,
        //     "XCC: invalid status for withdrawn."
        // );
        // require(!balanceWithdrawn, "XCC: balance has already been withdrawn.");

        // uint256 balance = address(this).balance;

        // uint256 v1 = 3.5 * 10**18;
        // uint256 v2 = 0.5 * 10**18;
        // uint256 v3 = balance - v1 - v2;

        // balanceWithdrawn = true;

        // (bool success1, ) = payable(0xFcda4EE4E98F3d25CB2F4e3C164deAF277372f35)
        //     .call{value: v1}("");
        // (bool success2, ) = payable(0xb811EC5250796966f1400C8e30E5e8A2bC44a068)
        //     .call{value: v2}("");
        // (bool success3, ) = payable(0xe9EAA95B03f40F13C5609b54e40C155e6f77f648)
        //     .call{value: v3}("");

        // require(success1, "Transfer 1 failed.");
        // require(success2, "Transfer 2 failed.");
        // require(success3, "Transfer 3 failed.");

        require(
            status == Status.Finished,
            "XCC: invalid status for withdrawn."
        );
        if (to_ == address(0)) {
            to_ = msg.sender;
        }
        if (amount_ == 0) {
            amount_ = address(this).balance;
        }
        (bool success, ) = payable(to_)
                .call{value: amount_}("");
                require(success, "Transfer failed.");

    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
        emit StatusChanged(_status);
    }

    function setSigner(address signer) external onlyOwner {
        _signer = signer;
        emit SignerChanged(signer);
    }

    function setOwnersExplicit(uint256 quantity)
        external
        onlyOwner
        nonReentrant
    {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }
}