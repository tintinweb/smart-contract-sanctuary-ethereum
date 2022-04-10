// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./AuthorityControlled.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./SafeMath.sol";

contract XCC is ERC721A, AuthorityControlled, ReentrancyGuard {
    enum Status {
        Pending,
        Bidding,
        Finished,
        Minted,
        Refunded,
        Droped
    }

    enum BidStatus {
        Bidding,
        Minted,
        Refunded
    }

    struct BidRecord {
        address addr;
        uint256 amount;
        BidStatus status;
    }

    struct BidInfo {
        address addr;
        uint256 amount;
    }

    Status public status;
    string public baseURI;
    uint256 public tokensReserved;
    uint256 public immutable maxSupply;
    uint256 public floorPrice = 0.0025 * 10**18; // 0.0025 ETH
    uint256 public totalBid;
    uint256 public tokens;
    bool public balanceWithdrawn;

    uint256 public immutable limit;
    mapping(address => uint256) public mintedTokenId;

    BidRecord[] public bidRecord;
    BidInfo[] public bidInfo;
    address[] public blacklist;

    mapping(address => uint256) public dropToken;
    mapping(address => uint256) public dropInterest;

    event Bided(address minter, uint256 amount);

    event Minted(address minter, uint256 amount);
    event StatusChanged(Status status);
    event ReservedToken(address minter, address recipient, uint256 amount);
    event BaseURIChanged(string newBaseURI);
    event PriceChanged(uint256 floorPrice);
    event TotalBidChanged(uint256 totalBid);
    event TokensChanged(uint256 tokens);

    constructor(
        string memory initBaseURI,
        uint256 _limit,
        uint256 _collectionSize,
        uint256 _tokens,
        address authority_
    )
        AuthorityControlled(authority_)
        ERC721A("X Chimps Club", "XCC", _limit, _collectionSize)
    {
        baseURI = initBaseURI;
        limit = _limit;
        maxSupply = _collectionSize;
        tokens = _tokens;
    }

    function addBlacklist(address[] memory _blacklist) external onlyManager {
        require(
            status == Status.Bidding,
            "XCC: Only Bidding or Pending status can execute this operation."
        );
        require(_blacklist.length > 0, "XCC: No data found.");
        for (uint256 i = 0; i < _blacklist.length; i++) {
            blacklist.push(_blacklist[i]);
        }
    }

    function deleteBlacklist(address[] memory _blacklist) external onlyManager {
        require(
            status == Status.Bidding,
            "XCC: Only Bidding or Pending status can execute this operation."
        );
        require(_blacklist.length > 0, "XCC: No data found.");
        for (uint256 i = 0; i < _blacklist.length; i++) {
            for (uint256 ii = 0; ii < blacklist.length; ii++) {
                if (blacklist[ii] == _blacklist[i]) {
                    delete blacklist[ii];
                }
            }
        }
    }

    function syncBlacklist(address[] memory _blacklist) external onlyManager {
        require(
            status == Status.Bidding,
            "XCC: Only Bidding or Pending status can execute this operation."
        );
        require(_blacklist.length > 0, "XCC: No data found.");
        delete blacklist;
        blacklist = _blacklist;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function bid() external payable {
        require(status == Status.Bidding, "XCC: Bid is not active.");
        require(
            checkIsBlacklist(msg.sender),
            "XCC: Wallet addresses is forbidden."
        );
        require(
            tx.origin == msg.sender,
            "XCC: contract is not allowed to bid."
        );
        require(msg.value >= floorPrice, "XCC: Need to send more ETH.");
        bool have;
        uint256 recordIndex;
        (have, recordIndex) = getRecordIndex(msg.sender);
        if (have) {
            // exist already
            bidRecord[recordIndex].amount += msg.value;
        } else {
            // not exist yet
            bidRecord.push(
                BidRecord({
                    addr: msg.sender,
                    amount: msg.value,
                    status: BidStatus.Bidding
                })
            );
        }
        bidInfo.push(BidInfo({addr: msg.sender, amount: msg.value}));
        emit Bided(msg.sender, msg.value);
    }

    //Alternates participate in the auction
    function waitBid(address[] memory _addrList, uint256 _latestPrice)
        external
        onlyManager
    {
        require(status == Status.Bidding, "XCC: Bid is not active.");
        require(_addrList.length > 0, "XCC: No data found.");
        for (uint256 i = 0; i < _addrList.length; i++) {
            bool have;
            uint256 recordIndex;
            (have, recordIndex) = getRecordIndex(_addrList[i]);
            if (_latestPrice < SafeMath.mul(floorPrice, i + 1)) {
                _latestPrice = _latestPrice;
            } else {
                _latestPrice = SafeMath.sub(
                    _latestPrice,
                    SafeMath.mul(floorPrice, i + 1)
                );
            }
            if (have) {
                // exist already
                bidRecord[recordIndex].amount += _latestPrice;
            } else {
                // not exist yet
                bidRecord.push(
                    BidRecord({
                        addr: _addrList[i],
                        amount: _latestPrice,
                        status: BidStatus.Bidding
                    })
                );
            }
            bidInfo.push(BidInfo({addr: _addrList[i], amount: _latestPrice}));
            emit Bided(_addrList[i], _latestPrice);
        }
    }

    function mint(address[] memory _addrList) external onlyManager {
        require(
            status == Status.Finished,
            "XCC: Only Finished status can execute this operation."
        );
        require(_addrList.length > 0, "XCC: No data found.");
        for (uint256 i = 0; i < _addrList.length; i++) {
            bool have;
            uint256 recordIndex;
            (have, recordIndex) = getRecordIndex(_addrList[i]);
            if (have) {
                // exist already
                if (bidRecord[recordIndex].status != BidStatus.Bidding) {
                    bidRecord[recordIndex].status = BidStatus.Minted;
                    _safeMint(_addrList[i], 1);
                    mintedTokenId[_addrList[i]] = totalSupply() - 1;
                    emit Minted(_addrList[i], totalSupply() - 1);
                }
            }
        }
        status = Status.Minted;
        refundIfNoWin_();
    }

    function refundIfNoWin() external onlyManager {
        refundIfNoWin_();
    }

    function refundIfNoWin_() internal {
        require(
            status == Status.Minted,
            "XCC: Only Minted status can execute this operation."
        );
        require(bidRecord.length > 0, "XCC: No data found.");
        for (uint256 i = 0; i < bidRecord.length; i++) {
            bool have;
            uint256 recordIndex;
            (have, recordIndex) = getRecordIndex(bidRecord[i].addr);
            if (have) {
                // exist already
                if (bidRecord[recordIndex].status == BidStatus.Bidding) {
                    bidRecord[recordIndex].status = BidStatus.Refunded;
                    payable(bidRecord[i].addr).transfer(bidRecord[i].amount);
                }
            }
        }
        status = Status.Refunded;
        drop_(totalBid, tokens);
    }

    function drop(uint256 totalBid_, uint256 tokens_) external onlyManager {
        drop_(totalBid_, tokens_);
    }

    function drop_(uint256 totalBid_, uint256 tokens_) internal {
        require(
            status == Status.Refunded,
            "XCC: Only Refunded status can execute this operation."
        );
        require(bidRecord.length > 0, "XCC: No data found.");
        for (uint256 i = 0; i < bidRecord.length; i++) {
            bool have;
            uint256 recordIndex;
            (have, recordIndex) = getRecordIndex(bidRecord[i].addr);
            if (have) {
                // exist already
                if (bidRecord[recordIndex].status == BidStatus.Minted) {
                    // drop token
                    dropToken[bidRecord[recordIndex].addr] = SafeMath.mul(
                        SafeMath.div(bidRecord[recordIndex].amount, totalBid_),
                        tokens_
                    );
                    //drop interest
                    dropInterest[bidRecord[recordIndex].addr] = SafeMath.div(
                        bidRecord[recordIndex].amount,
                        totalBid_
                    );
                }
            }
        }
        status = Status.Droped;
    }

    function checkIsBlacklist(address addr) internal view returns (bool) {
        require(addr != address(0), "XCC: zero address");
        for (uint256 i = 0; i < blacklist.length; i++) {
            if (blacklist[i] == addr) {
                return false;
            }
        }
        return true;
    }

    function withdraw(address to_, uint256 amount_)
        external
        nonReentrant
        onlyManager
    {
        require(status != Status.Bidding, "XCC: invalid status for withdrawn.");
        if (to_ == address(0)) {
            to_ = msg.sender;
        }
        if (amount_ == 0) {
            amount_ = address(this).balance;
        }
        (bool success, ) = payable(to_).call{value: amount_}("");
        require(success, "Transfer failed.");
    }

    function setBaseURI(string calldata newBaseURI) external onlyManager {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    function setStatus(Status _status) external onlyManager {
        status = _status;
        emit StatusChanged(_status);
    }

    function setPrice(uint256 _floorPrice) external onlyManager {
        floorPrice = _floorPrice;
        emit PriceChanged(_floorPrice);
    }

    function setTotalBid(uint256 _totalBid) external onlyManager {
        totalBid = _totalBid;
        emit TotalBidChanged(_totalBid);
    }

    function setTokens(uint256 _tokens) external onlyManager {
        tokens = _tokens;
        emit TokensChanged(_tokens);
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

    function ownedTokenId(address owner) public view returns (uint256) {
        return mintedTokenId[owner];
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function getRecordIndex(address _addr) public view returns (bool, uint256) {
        for (uint256 i = 0; i < bidRecord.length; i++) {
            if (bidRecord[i].addr == _addr) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function getRecordLength() public view returns (uint256) {
        return bidRecord.length;
    }
}