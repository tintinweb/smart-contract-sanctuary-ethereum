// SPDX-License-Identifier: MIT
// An example of a consumer contract that directly pays for each request.
pragma solidity ^0.8.7;

interface VRFV2WrapperInterface {
    function calculateRequestPrice(uint32 _callbackGasLimit)
        external
        view
        returns (uint256);

    function estimateRequestPrice(
        uint32 _callbackGasLimit,
        uint256 _requestGasPriceWei
    ) external view returns (uint256);

    function lastRequestId() external view returns (uint256);
}

interface LinkTokenInterface {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining);

    function approve(address spender, uint256 value)
        external
        returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function decreaseApproval(address spender, uint256 addedValue)
        external
        returns (bool success);

    function increaseApproval(address spender, uint256 subtractedValue)
        external;

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(address to, uint256 value)
        external
        returns (bool success);

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);
}

abstract contract VRFV2WrapperConsumerBase {
    LinkTokenInterface internal immutable LINK;
    VRFV2WrapperInterface internal immutable VRF_V2_WRAPPER;

    constructor(address _link, address _vrfV2Wrapper) {
        LINK = LinkTokenInterface(_link);
        VRF_V2_WRAPPER = VRFV2WrapperInterface(_vrfV2Wrapper);
    }

    function requestRandomness(
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords
    ) internal returns (uint256 requestId) {
        LINK.transferAndCall(
            address(VRF_V2_WRAPPER),
            VRF_V2_WRAPPER.calculateRequestPrice(_callbackGasLimit),
            abi.encode(_callbackGasLimit, _requestConfirmations, _numWords)
        );
        return VRF_V2_WRAPPER.lastRequestId();
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal virtual;

    function rawFulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) external {
        require(
            msg.sender == address(VRF_V2_WRAPPER),
            "only VRF V2 wrapper can fulfill"
        );
        fulfillRandomWords(_requestId, _randomWords);
    }
}

interface OwnableInterface {
    function owner() external returns (address);

    function transferOwnership(address recipient) external;

    function acceptOwnership() external;
}

contract ConfirmedOwnerWithProposal is OwnableInterface {
    address private s_owner;
    address private s_pendingOwner;

    event OwnershipTransferRequested(address indexed from, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);

    constructor(address newOwner, address pendingOwner) {
        require(newOwner != address(0), "Cannot set owner to zero");

        s_owner = newOwner;
        if (pendingOwner != address(0)) {
            _transferOwnership(pendingOwner);
        }
    }

    function transferOwnership(address to) public override onlyOwner {
        _transferOwnership(to);
    }

    function acceptOwnership() external override {
        require(msg.sender == s_pendingOwner, "Must be proposed owner");

        address oldOwner = s_owner;
        s_owner = msg.sender;
        s_pendingOwner = address(0);

        emit OwnershipTransferred(oldOwner, msg.sender);
    }

    function owner() public view override returns (address) {
        return s_owner;
    }

    function _transferOwnership(address to) private {
        require(to != msg.sender, "Cannot transfer to self");

        s_pendingOwner = to;

        emit OwnershipTransferRequested(s_owner, to);
    }

    function _validateOwnership() internal view {
        require(msg.sender == s_owner, "Only callable by owner");
    }

    modifier onlyOwner() {
        _validateOwnership();
        _;
    }
}

contract ConfirmedOwner is ConfirmedOwnerWithProposal {
    constructor(address newOwner)
        ConfirmedOwnerWithProposal(newOwner, address(0))
    {}
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    function approve(address to, uint256 tokenId) external;

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
}

contract GeometricFormsRaffle is VRFV2WrapperConsumerBase, ConfirmedOwner {
    event RaffleStarted(
        uint256 indexed request_id,
        address indexed nft,
        address indexed owner,
        uint256 id_minimum,
        uint256 id_maximum
    );
    event WinnerSelected(
        uint256 indexed request_id,
        address indexed nft,
        address indexed winner,
        uint256 winning_nft_id
    );
    event RequestFulfilled(
        uint256 indexed requestId,
        address indexed nft,
        uint256 indexed seed
    );
    event RaffleCancelled(uint256 request_id, address indexed nft);

    struct raffle {
        uint256 id;
        address owner;
        address nft;
        uint256 umin;
        uint256 umax;
        uint256 seed;
        address reward;
        uint256 reward_id;
        bool concluded;
    }
    mapping(uint256 => bool) public fulfilled;
    mapping(uint256 => raffle) public raffles;
    raffle public lastRaffle;
    uint32 gas_limit;
    uint16 confirmations;
    uint256 fee;

    constructor(
        address _link,
        address _vrfV2Wrapper,
        uint32 _gas_limit,
        uint16 _confirmations,
        uint256 _fee
    )
        ConfirmedOwner(msg.sender)
        VRFV2WrapperConsumerBase(_link, _vrfV2Wrapper)
    {
        gas_limit = _gas_limit;
        fee = _fee;
        confirmations = _confirmations;
    }

    function requestRandomWords(
        address _nft,
        uint256 umin,
        uint256 umax,
        address _reward,
        uint256 _reward_id
    ) external returns (uint256 requestId) {
        uint256 fee_ = calculateFee();
        LINK.transferFrom(msg.sender, address(this), fee_);

        requestId = requestRandomness(gas_limit, confirmations, 1);
        lastRaffle = raffle(
            lastRaffle.id + 1,
            msg.sender,
            _nft,
            umin,
            umax,
            0,
            _reward,
            _reward_id,
            false
        );
        raffles[requestId] = lastRaffle;
        IERC721(_reward).safeTransferFrom(
            msg.sender,
            address(this),
            _reward_id
        );
        emit RaffleStarted(requestId, _nft, msg.sender, umin, umax);
    }

    function fulfillRandomWords(
        uint256 _request_id,
        uint256[] memory _random_words
    ) internal override {
        require(raffles[_request_id].id > 0, "request not found");
        require(raffles[_request_id].seed == 0, "request already fulfilled");
        raffles[_request_id].seed = _random_words[0];
        fulfilled[_request_id] = true;
        emit RequestFulfilled(
            _request_id,
            raffles[_request_id].nft,
            _random_words[0]
        );
    }

    function cancelRaffle(uint256 _request_id) external {
        require(
            raffles[_request_id].owner == msg.sender,
            "Only the reward owner can cancel the raffle"
        );
        require(
            raffles[_request_id].concluded == false,
            "Raffle already concluded"
        );
        IERC721(raffles[_request_id].reward).transferFrom(
            address(this),
            msg.sender,
            raffles[_request_id].reward_id
        );
        raffles[_request_id].concluded = true;
        emit RaffleCancelled(_request_id, raffles[_request_id].nft);
    }

    function selectWinner(uint256 _request_id)
        external
        returns (address winner)
    {
        require(raffles[_request_id].id > 0, "request not found");
        require(raffles[_request_id].seed != 0, "Seed not set");
        require(
            raffles[_request_id].concluded == false,
            "Raffle already concluded"
        );
        raffles[_request_id].concluded = true;
        uint256 range = raffles[_request_id].umax - raffles[_request_id].umin;
        uint256 winner_id = raffles[_request_id].umin +
            (raffles[_request_id].seed % (range + 1));
        winner = IERC721(raffles[_request_id].nft).ownerOf(winner_id);
        IERC721(raffles[_request_id].reward).transferFrom(
            address(this),
            winner,
            raffles[_request_id].reward_id
        );
        emit WinnerSelected(
            _request_id,
            raffles[_request_id].nft,
            winner,
            winner_id
        );
    }

    function withdrawLink() public onlyOwner {
        LINK.transfer(msg.sender, LINK.balanceOf(address(this)));
    }

    function calculateFee() public view returns (uint256 _fee) {
        _fee = VRF_V2_WRAPPER.calculateRequestPrice(gas_limit);
        return _fee + (_fee / fee);
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function setGasLimit(uint32 _gas_limit) external onlyOwner {
        gas_limit = _gas_limit;
    }

    function setConfirmations(uint16 _confirmations) external onlyOwner {
        confirmations = _confirmations;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}