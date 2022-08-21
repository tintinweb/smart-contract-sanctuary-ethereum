// SPDX-License-Identifier: UNLICENCED

pragma solidity ^0.8.0;
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ECDSA.sol";

contract Druzhba {
    using SafeERC20 for IERC20;
    IERC20 private token;

    enum DealState {
        ZERO,
        START,
        PAYMENT_COMPLETE,
        DISPUTE,
        CANCELED_ARBITER,
        CANCELED_TIMEOUT_ARBITER,
        CANCELED_BUYER,
        CANCELED_SELLER,
        CLEARED_SELLER,
        CLEARED_ARBITER
    }

    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encodePacked("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"));
    bytes32 private constant ACCEPT_DEAL_TYPEHASH = keccak256(abi.encodePacked("AcceptDeal(uint32 id,address seller,address buyer,uint256 amt,uint256 fee,uint256 deadline)"));
    bytes32 private DOMAIN_SEPARATOR;

    struct Deal {
        address seller;
        address buyer;
        uint256 locked_total;
        uint256 fee;
        DealState state;
        bool in_use;
        uint32 id;
    }
    // TODO Enumerable mapping (???)
    mapping(uint => Deal) public dealMapping;

    // TODO add OpenZeppelin's EnumerableSet (set of arbiters)
    address public arbiter;
    address public signer;
    address private proposedSigner;
    mapping(address => uint256) public lockedBalanceMapping;

    /***********************
    +       Events        +
    ***********************/

    event LockedTransfer(address indexed from, address indexed to, uint256 amount);
    event StateChanged(uint32 indexed id, DealState newState);
    event ArbiterChanged(address indexed oldArbiter, address indexed newArbiter);
    event SignerChanged(address indexed prevSigner, address indexed newSigner);

    constructor(uint256 chainId, address _token, address _arbiter, address _signer) {
        token = IERC20(_token);
        arbiter = _arbiter;
        signer = _signer;

        DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256(bytes("Druzhba")),
            keccak256(bytes("1")),
            chainId,
            address(this)
        ));
    }

    modifier notInUse(uint id) {
        require(dealMapping[id].in_use == false, "Already in use");
        _;
    }

    modifier inUse(uint id) {
        require(dealMapping[id].in_use == true, "Not in use");
        _;
    }

    modifier isArbiter() {
        require(arbiter == msg.sender, "Not an arbiter");
        _;
    }

    modifier isSigner() {
        require(signer == msg.sender, "Not a signer");
        _;
    }

    modifier isSeller(uint id) {
        require(dealMapping[id].seller == msg.sender, "Not a seller");
        _;
    }

    modifier isBuyer(uint id) {
        require(dealMapping[id].buyer == msg.sender, "Not a buyer");
        _;
    }

    function _lockedTransfer(address from, address to, uint256 amount) internal {
        if (from != address(0)) {
            assert(lockedBalanceMapping[from] >= amount);
            lockedBalanceMapping[from] -= amount;
        }

        if (to != address(0)) {
            lockedBalanceMapping[to] += amount;
        }
        emit LockedTransfer(from, to, amount);
    }

    // TODO Check for allowance
    function lockForAdvertiseSeller(uint256 amount) external {
        _lockedTransfer(address(0), msg.sender, amount);
        token.safeTransferFrom(msg.sender, address(this), amount);
    }

    // TODO разработать план борьбы с блокировщиками
    function acceptDealBuyer(address seller, uint256 amount, uint256 fee, uint32 id, uint256 deadline, bytes memory signature) external notInUse(id) {
        require(seller != msg.sender, "seller == buyer");
        require(lockedBalanceMapping[seller] >= amount + fee, "Seller doesn't have enough funds locked");

        address dealSigner = ECDSA.recover(dealHash(id, seller, msg.sender, amount, fee, deadline), signature);
        require(dealSigner == signer, "Invalid signer or signature");
        require(block.timestamp < deadline, "Signature expired");

        _lockedTransfer(seller, address(this), amount + fee);
        dealMapping[id] = Deal(seller, msg.sender, amount + fee, fee, DealState.START, true, id);
        emit StateChanged(id, DealState.START);
    }

    function cancelTimeoutArbiter(uint32 id) external inUse(id) isArbiter {
        Deal storage deal = dealMapping[id];
        require(deal.state == DealState.START, "Wrong deal state");
        _lockedTransfer(address(this), deal.seller, deal.locked_total);
        deal.state = DealState.CANCELED_TIMEOUT_ARBITER;
        deal.in_use = false;
        emit StateChanged(id, DealState.CANCELED_TIMEOUT_ARBITER);
    }

    function cancelDealBuyer(uint32 id) external inUse(id) isBuyer(id) {
        Deal storage deal = dealMapping[id];
        require(deal.state == DealState.START, "Wrong deal state");
        _lockedTransfer(address(this), deal.seller, deal.locked_total);
        deal.state = DealState.CANCELED_BUYER;
        deal.in_use = false;
        emit StateChanged(id, DealState.CANCELED_BUYER);
    }

    function completePaymentBuyer(uint32 id) external inUse(id) isBuyer(id) {
        require(dealMapping[id].state == DealState.START, "Wrong deal state");
        dealMapping[id].state = DealState.PAYMENT_COMPLETE;
        emit StateChanged(id, DealState.PAYMENT_COMPLETE);
    }

    function clearDealSeller(uint32 id) external inUse(id) isSeller(id) {
        Deal storage deal = dealMapping[id];
        require(deal.state == DealState.PAYMENT_COMPLETE, "Wrong deal state");
        _lockedTransfer(address(this), deal.buyer, deal.locked_total - deal.fee);
        _lockedTransfer(address(this), arbiter, deal.fee);
        deal.state = DealState.CLEARED_SELLER;
        deal.in_use = false;
        emit StateChanged(id, DealState.CLEARED_SELLER);
    }

    function callHelpSeller(uint32 id) external inUse(id) isSeller(id) {
        require(dealMapping[id].state == DealState.PAYMENT_COMPLETE, "Wrong deal state");
        dealMapping[id].state = DealState.DISPUTE;
        emit StateChanged(id, DealState.DISPUTE);
    }

    function callHelpBuyer(uint32 id) external inUse(id) isBuyer(id) {
        require(dealMapping[id].state == DealState.PAYMENT_COMPLETE, "Wrong deal state");
        dealMapping[id].state = DealState.DISPUTE;
        emit StateChanged(id, DealState.DISPUTE);
    }

    function cancelDealArbiter(uint32 id) external inUse(id) isArbiter {
        Deal storage deal = dealMapping[id];
        require(deal.state == DealState.DISPUTE, "Wrong deal state");
        _lockedTransfer(address(this), deal.seller, deal.locked_total);
        deal.state = DealState.CANCELED_ARBITER;
        deal.in_use = false;
        emit StateChanged(id, DealState.CANCELED_ARBITER);
    }

    function clearDealArbiter(uint32 id) external inUse(id) isArbiter {
        Deal storage deal = dealMapping[id];
        require(deal.state == DealState.DISPUTE, "Wrong deal state");
        _lockedTransfer(address(this), deal.buyer, deal.locked_total - deal.fee);
        _lockedTransfer(address(this), arbiter, deal.fee);
        deal.state = DealState.CLEARED_ARBITER;
        deal.in_use = false;
        emit StateChanged(id, DealState.CLEARED_ARBITER);
    }

    function claimableBalance(address recipient) external view returns (uint256) {
        return lockedBalanceMapping[recipient];
    }

    function getDealState(uint32 id) external view returns (DealState) {
        return dealMapping[id].state;
    }

    function claim() external {
        uint256 amount = lockedBalanceMapping[msg.sender];
        _lockedTransfer(msg.sender, address(0), amount);
        token.safeTransfer(msg.sender, amount);
    }

    function dealHash(uint32 id, address seller, address buyer, uint256 amount, uint256 fee, uint256 deadline) internal view returns (bytes32) {
        bytes32 structHash = keccak256(abi.encode(ACCEPT_DEAL_TYPEHASH, id, seller, buyer, amount, fee, deadline));
        // EIP-191 compiant hash for EIP-712-like data
        return keccak256(abi.encodePacked(uint16(0x1901), DOMAIN_SEPARATOR, structHash));
    }

    function changeArbiter(address newArbiter) external isArbiter {
        require(newArbiter != address(0), "New arbiter is the zero address");
        address oldArbiter = arbiter;
        arbiter = newArbiter;
        emit ArbiterChanged(oldArbiter, newArbiter);
    }

    function proposeSigner(address newSigner) external isSigner {
        require(newSigner != address(0), "New signer is the zero address");
        proposedSigner = newSigner;
    }

    function approveSigner(address newSigner) external isArbiter {
        require(proposedSigner != address(0), "Cannot change to the zero address");
        require(proposedSigner == newSigner, "Does not match proposed signer");
        address oldSigner = signer;
        signer = proposedSigner;
        emit SignerChanged(oldSigner, newSigner);
    }
}