// SPDX-License-Identifier: GPL

pragma solidity ^0.8.0;

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

interface ICallistoNFT {
    event NewBid(
        uint256 indexed tokenID,
        uint256 indexed bidAmount,
        bytes bidData
    );
    event TokenTrade(
        uint256 indexed tokenID,
        address indexed new_owner,
        address indexed previous_owner,
        uint256 priceInWEI
    );
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event TransferData(bytes data);

    struct Properties {
        // In this example properties of the given NFT are stored
        // in a dynamically sized array of strings
        // properties can be re-defined for any specific info
        // that a particular NFT is intended to store.

        /* Properties could look like this:
        bytes   property1;
        bytes   property2;
        address property3;
        */

        string[] properties;
    }

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function standard() external view returns (string memory);

    function balanceOf(address _who) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function transfer(
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bool);

    function silentTransfer(address _to, uint256 _tokenId)
        external
        returns (bool);

    function priceOf(uint256 _tokenId) external view returns (uint256);

    function bidOf(uint256 _tokenId)
        external
        view
        returns (
            uint256 price,
            address payable bidder,
            uint256 timestamp
        );

    function getTokenProperties(uint256 _tokenId)
        external
        view
        returns (Properties memory);

    function getTokenProperty(uint256 _tokenId, uint256 _propertyId)
        external
        view
        returns (string memory);

    function setBid(uint256 _tokenId, bytes calldata _data) external payable; // bid amount is defined by msg.value

    function setPrice(uint256 _tokenId, uint256 _amountInWEI) external;

    function withdrawBid(uint256 _tokenId) external returns (bool);

    function getUserContent(uint256 _tokenId)
        external
        view
        returns (string memory _content, bool _all);

    function setUserContent(uint256 _tokenId, string calldata _content)
        external
        returns (bool);
}

abstract contract NFTReceiver {
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external virtual returns (bytes4);
}

contract CallistoNFT is ICallistoNFT {
    using Address for address;

    mapping(uint256 => Properties) internal _tokenProperties;
    mapping(uint32 => Fee) public feeLevels; // level # => (fee receiver, fee percentage)

    uint256 public bidLock = 1 days; // Time required for a bid to become withdrawable.

    struct Bid {
        address payable bidder;
        uint256 amountInWEI;
        uint256 timestamp;
    }

    struct Fee {
        address payable feeReceiver;
        uint256 feePercentage; // Will be divided by 100000 during calculations
        // feePercentage of 100 means 0.1% fee
        // feePercentage of 2500 means 2.5% fee
    }

    mapping(uint256 => uint256) internal _asks; // tokenID => price of this token (in WEI)
    mapping(uint256 => Bid) internal _bids; // tokenID => price of this token (in WEI)
    mapping(uint256 => uint32) internal _tokenFeeLevels; // tokenID => level ID / 0 by default

    // Token name
    string internal _name;

    // Token symbol
    string internal _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) internal _owners;

    // Mapping owner address to token count
    mapping(address => uint256) internal _balances;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 _defaultFee
    ) {
        _name = name_;
        _symbol = symbol_;
        feeLevels[0].feeReceiver = payable(msg.sender);
        feeLevels[0].feePercentage = _defaultFee;
    }

    // Reward is always paid based on BID
    modifier checkTrade(uint256 _tokenId) {
        _;
        (uint256 _bid, address payable _bidder, ) = bidOf(_tokenId);
        if (priceOf(_tokenId) > 0 && priceOf(_tokenId) <= _bid) {
            uint256 _reward = _bid - _claimFee(_bid, _tokenId);

            emit TokenTrade(_tokenId, _bidder, ownerOf(_tokenId), _reward);

            payable(ownerOf(_tokenId)).transfer(_reward);

            bytes memory _empty;
            delete _bids[_tokenId];
            delete _asks[_tokenId];
            _transfer(ownerOf(_tokenId), _bidder, _tokenId, _empty);
        }
    }

    function standard() public pure override returns (string memory) {
        return "CallistoNFT";
    }

    function priceOf(uint256 _tokenId) public view override returns (uint256) {
        address owner = _owners[_tokenId];
        require(owner != address(0), "NFT: owner query for nonexistent token");
        return _asks[_tokenId];
    }

    function bidOf(uint256 _tokenId)
        public
        view
        override
        returns (
            uint256 price,
            address payable bidder,
            uint256 timestamp
        )
    {
        address owner = _owners[_tokenId];
        require(owner != address(0), "NFT: owner query for nonexistent token");
        return (
            _bids[_tokenId].amountInWEI,
            _bids[_tokenId].bidder,
            _bids[_tokenId].timestamp
        );
    }

    function getTokenProperties(uint256 _tokenId)
        public
        view
        override
        returns (Properties memory)
    {
        return _tokenProperties[_tokenId];
    }

    function getTokenProperty(uint256 _tokenId, uint256 _propertyId)
        public
        view
        override
        returns (string memory)
    {
        return _tokenProperties[_tokenId].properties[_propertyId];
    }

    function getUserContent(uint256 _tokenId)
        public
        view
        override
        returns (string memory _content, bool _all)
    {
        return (_tokenProperties[_tokenId].properties[0], true);
    }

    function setUserContent(uint256 _tokenId, string calldata _content)
        public
        override
        returns (bool success)
    {
        require(
            msg.sender == ownerOf(_tokenId),
            "NFT: only owner can change NFT content"
        );
        _tokenProperties[_tokenId].properties[0] = _content;
        return true;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "NFT: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "NFT: owner query for nonexistent token");
        return owner;
    }

    function setPrice(uint256 _tokenId, uint256 _amountInWEI)
        public
        override
        checkTrade(_tokenId)
    {
        require(
            ownerOf(_tokenId) == msg.sender,
            "Setting asks is only allowed for owned NFTs!"
        );
        _asks[_tokenId] = _amountInWEI;
    }

    function setBid(uint256 _tokenId, bytes calldata _data)
        public
        payable
        override
        checkTrade(_tokenId)
    {
        (uint256 _previousBid, address payable _previousBidder, ) = bidOf(
            _tokenId
        );
        require(
            msg.value > _previousBid,
            "New bid must exceed the existing one"
        );

        uint256 _bid;

        // Return previous bid if the current one exceeds it.
        if (_previousBid != 0) {
            _previousBidder.transfer(_previousBid);
        }
        // Refund overpaid amount.
        if (priceOf(_tokenId) < msg.value) {
            _bid = priceOf(_tokenId);
        } else {
            _bid = msg.value;
        }
        _bids[_tokenId].amountInWEI = _bid;
        _bids[_tokenId].bidder = payable(msg.sender);
        _bids[_tokenId].timestamp = block.timestamp;

        emit NewBid(_tokenId, _bid, _data);

        // Send back overpaid amount.
        // WARHNING: Creates possibility for reentrancy.
        if (priceOf(_tokenId) < msg.value) {
            payable(msg.sender).transfer(msg.value - priceOf(_tokenId));
        }
    }

    function withdrawBid(uint256 _tokenId) public override returns (bool) {
        (uint256 _bid, address payable _bidder, uint256 _timestamp) = bidOf(
            _tokenId
        );
        require(msg.sender == _bidder, "Can not withdraw someone elses bid");
        require(block.timestamp > _timestamp + bidLock, "Bid is time-locked");

        _bidder.transfer(_bid);
        delete _bids[_tokenId];
        return true;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function transfer(
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public override returns (bool) {
        _transfer(msg.sender, _to, _tokenId, _data);
        emit TransferData(_data);
        return true;
    }

    function silentTransfer(address _to, uint256 _tokenId)
        public
        override
        returns (bool)
    {
        require(
            CallistoNFT.ownerOf(_tokenId) == msg.sender,
            "NFT: transfer of token that is not own"
        );
        require(_to != address(0), "NFT: transfer to the zero address");

        _asks[_tokenId] = 0; // Zero out price on transfer

        // When a user transfers the NFT to another user
        // it does not automatically mean that the new owner
        // would like to sell this NFT at a price
        // specified by the previous owner.

        // However bids persist regardless of token transfers
        // because we assume that the bidder still wants to buy the NFT
        // no matter from whom.

        _beforeTokenTransfer(msg.sender, _to, _tokenId);

        _balances[msg.sender] -= 1;
        _balances[_to] += 1;
        _owners[_tokenId] = _to;

        emit Transfer(msg.sender, _to, _tokenId);
        return true;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _claimFee(uint256 _amountFrom, uint256 _tokenId)
        internal
        returns (uint256)
    {
        uint32 _level = _tokenFeeLevels[_tokenId];
        address _feeReceiver = feeLevels[_level].feeReceiver;
        uint256 _feePercentage = feeLevels[_level].feePercentage;

        uint256 _feeAmount = (_amountFrom * _feePercentage) / 100000;
        payable(_feeReceiver).transfer(_feeAmount);
        return _feeAmount;
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _mint(to, tokenId);
    }

    function configureNFT(uint256 tokenId) internal {
        if (_tokenProperties[tokenId].properties.length == 0) {
            _tokenProperties[tokenId].properties.push("");
        }
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "NFT: mint to the zero address");
        require(!_exists(tokenId), "NFT: token already minted");

        configureNFT(tokenId);

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal {
        address owner = CallistoNFT.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal {
        require(
            CallistoNFT.ownerOf(tokenId) == from,
            "NFT: transfer of token that is not own"
        );
        require(to != address(0), "NFT: transfer to the zero address");

        _asks[tokenId] = 0; // Zero out price on transfer

        // When a user transfers the NFT to another user
        // it does not automatically mean that the new owner
        // would like to sell this NFT at a price
        // specified by the previous owner.

        // However bids persist regardless of token transfers
        // because we assume that the bidder still wants to buy the NFT
        // no matter from whom.

        _beforeTokenTransfer(from, to, tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        if (to.isContract()) {
            NFTReceiver(to).onERC721Received(
                msg.sender,
                msg.sender,
                tokenId,
                data
            );
        }

        emit Transfer(from, to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}