/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: contracts/Escrow.sol


pragma solidity 0.8.15;


contract Escrow {
    enum EscrowStatus {
        Launched,
        Ongoing,
        RequestRevised,
        Delivered,
        Dispute,
        Cancelled,
        Complete
    }

    struct EscrowDetail {
        EscrowStatus status;
        bytes32 title;
        address tokenAddress;
        uint256 deadline;
        address payable buyer;
        address payable seller;
        uint256 requestRevisedDeadline;
        uint256 amount;
        address escrowAddress;
        uint8 feePercent;
    }

    EscrowDetail escrowDetail;
    address payable public addressToPayFee;
    uint256 rejectCount = 0;
    address public tokenAddress;
    mapping(address => bool) public areTrustedHandlers;

    constructor(
        address payable _addressToPayFee,
        address _tokenAddress,
        uint256 _duration,
        uint256 amount,
        bytes32 title,
        address payable buyer,
        address payable seller,
        uint8 _feePercent,
        address[] memory _handlers
    ) {
        require(_duration == 0 || _duration >= 86400, '___INVALID_DURATION___'); // SHOULD BE MIN 1 DAY
        require(_feePercent > 0 || _feePercent < 100, '___INVALID_FEE_PERCENT___');
        uint256 duration = 915151608; //29 years default
        if (_duration >= 0) {
            duration = _duration;
        }
        addressToPayFee = _addressToPayFee;
        tokenAddress = _tokenAddress;
        areTrustedHandlers[msg.sender] = true;
        addTrustedHandlers(_handlers);
        escrowDetail = EscrowDetail(
            EscrowStatus.Launched,
            title,
            _tokenAddress,
            duration + block.timestamp,
            buyer,
            seller,
            0,
            amount,
            address(this),
            _feePercent
        ); // solhint-disable-line not-rely-on-time
    }

    fallback() external payable {
        require(uint8(escrowDetail.status) < 5, '___NOT_ELIGIBLE___');
        require(msg.value > 0, '___INVALID_AMOUNT___');
    }

    receive() external payable {
        require(uint8(escrowDetail.status) < 5, '___NOT_ELIGIBLE___');
        require(msg.value > 0, '___INVALID_AMOUNT___');
    }

    function getBalance() public view returns (uint256) {
        if (tokenAddress == address(0)) {
            return address(this).balance;
        }
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function addTrustedHandlers(address[] memory _handlers) public trusted {
        for (uint256 i = 0; i < _handlers.length; i++) {
            areTrustedHandlers[_handlers[i]] = true;
        }
    }

    function sendAndStatusUpdate(address payable toFund, EscrowStatus status) private {
        uint256 fee = (escrowDetail.amount * escrowDetail.feePercent) / 100; // %1
        if (tokenAddress == address(0)) {
            addressToPayFee.transfer(fee); // %1
            toFund.transfer(escrowDetail.amount - fee);
        } else {
            IERC20 token = IERC20(tokenAddress);
            token.transfer(addressToPayFee, fee); // %1
            token.transfer(toFund, escrowDetail.amount - fee);
        }
        escrowDetail.status = status;
    }

    function sellerLaunchedApprove() public onlySeller {
        require(getBalance() > 0, '___NO_FUNDS___');
        require(escrowDetail.status == EscrowStatus.Launched, '___NOT_IN_LAUNCHED_STATUS___');
        escrowDetail.status = EscrowStatus.Ongoing;
    }

    function sellerDeliver() external onlySeller {
        require(escrowDetail.status == EscrowStatus.Ongoing, '___NOT_IN_ONGOING_STATUS___');
        escrowDetail.status = EscrowStatus.Delivered;
    }

    function buyerConfirmDelivery() external onlyBuyer {
        require(escrowDetail.status == EscrowStatus.Delivered, '___NOT_IN_DELIVERED_STATUS___');
        sendAndStatusUpdate(escrowDetail.seller, EscrowStatus.Complete);
    }

    function buyerDeliverReject(uint256 _deliverRejectDuration) external onlyBuyer {
        require(escrowDetail.status == EscrowStatus.Delivered, '___NOT_IN_DELIVERED_STATUS___');
        require(_deliverRejectDuration >= 86400, '___REJECT_MIN_DAY___'); //1 day min
        rejectCount++;
        EscrowStatus state = EscrowStatus.RequestRevised;
        if (rejectCount > 1) {
            state = EscrowStatus.Dispute;
            escrowDetail.status = state;
        } else {
            escrowDetail.status = state;
            escrowDetail.requestRevisedDeadline = _deliverRejectDuration + block.timestamp;
        }
    }

    function sellerRejectDeliverReject() external onlySeller {
        require(escrowDetail.status == EscrowStatus.RequestRevised, '___NOT_IN_REJECT_DELIVERY_STATUS___');
        escrowDetail.status = EscrowStatus.Dispute;
    }

    function sellerApproveDeliverReject() external onlySeller {
        require(escrowDetail.status == EscrowStatus.RequestRevised, '___NOT_IN_REJECT_DELIVERY_STATUS___');
        escrowDetail.status = EscrowStatus.Ongoing;
        escrowDetail.deadline = escrowDetail.requestRevisedDeadline;
    }

    function cancel() external {
        require(uint8(escrowDetail.status) < 3, '___NOT_ELIGIBLE___');
        require(msg.sender == escrowDetail.buyer || msg.sender == escrowDetail.seller, '___INVALID_BUYER_SELLER___');

        if (
            msg.sender == escrowDetail.buyer &&
            (escrowDetail.status == EscrowStatus.Ongoing || escrowDetail.status == EscrowStatus.RequestRevised)
        ) {
            require(escrowDetail.deadline <= block.timestamp && block.timestamp >= escrowDetail.requestRevisedDeadline, '___NOT_EXPIRED___');
        }

        sendAndStatusUpdate(escrowDetail.buyer, EscrowStatus.Cancelled);
    }

    function fund(address payable toFund) external trusted {
        require(toFund == escrowDetail.buyer || toFund == escrowDetail.seller, '___INVALID_BUYER_SELLER___');
        require(EscrowStatus.Cancelled != escrowDetail.status, '___ALREADY_CANCELLED___');
        require(escrowDetail.status != EscrowStatus.Complete, '___NOT_IN_COMPLETE_STATUS___');
        sendAndStatusUpdate(toFund, EscrowStatus.Complete);
    }

    function getDetails() public view returns (EscrowDetail memory escrow) {
        return escrowDetail;
    }

    modifier onlyBuyer() {
        require(msg.sender == escrowDetail.buyer, '___ONLY_BUYER___');
        _;
    }

    modifier onlySeller() {
        require(msg.sender == escrowDetail.seller, '___ONLY_SELLER___');
        _;
    }

    modifier trusted() {
        require(areTrustedHandlers[msg.sender], '___NOT_TRUSTED___');
        _;
    }
}

// File: contracts/EscrowFactory.sol


pragma solidity 0.8.15;



contract EscrowFactory {
    uint8 feePercent = 1;
    uint256 public counter;
    address[] escrows;
    address[] processedTrustedHandlers;
    mapping(address => address[]) public myEscrows;
    mapping(address => bool) public areTrustedHandlers;
    mapping(address => bool) public areTokenTrusted;
    address feeAddress = address(this);
    event Created(address);

    constructor(address _backup, address[] memory trustedTokens) {
        processedTrustedHandlers.push(msg.sender);
        areTrustedHandlers[msg.sender] = true;
        processedTrustedHandlers.push(_backup);
        areTrustedHandlers[_backup] = true;
        areTokenTrusted[address(0)] = true; // for native currencies
        switchActiveTrustedTokens(trustedTokens, true);
    }

    function createEscrow(
        address payable seller,
        address tokenAddress,
        uint256 amount,
        bytes32 title,
        uint256 _duration
    ) external payable returns (address) {
        require(msg.sender != seller, '___INVALID_SAME___');
        require(seller != address(0), '___NON_EXIST_ADDRESS___');
        require(areTokenTrusted[tokenAddress], '___NOT_TRUSTED___');
        require(_duration == 0 || _duration >= 86400, '___INVALID_DURATION___'); // ONE_DAY_AS_SECONDS

        IERC20 token = IERC20(tokenAddress);

        if (tokenAddress != address(0)) {
            require(token.balanceOf(msg.sender) >= amount, '___TOKEN_UNAVAILABLE___');
        } else {
            require(msg.value == amount, '___DIFFER_AMOUNT_VAL___');
        }

        Escrow escrow = new Escrow(
            payable(feeAddress),
            tokenAddress,
            _duration,
            amount,
            title,
            payable(msg.sender),
            seller,
            feePercent,
            getProcessedHandlers(true)
        );

        if (tokenAddress == address(0)) {
            payable(address(escrow)).transfer(msg.value);
        } else {
            token.transferFrom(msg.sender, address(escrow), amount);
        }

        escrows.push(address(escrow));
        myEscrows[msg.sender].push(address(escrow));
        myEscrows[seller].push(address(escrow));
        emit Created(address(escrow));
        return address(escrow);
    }

    function getProcessedHandlers(bool _trusted) public view returns (address[] memory) {
        address[] memory processedHandlers = new address[](processedTrustedHandlers.length);
        uint j = 0;
        for (uint i = 0; i < processedTrustedHandlers.length; i++) {
            if (areTrustedHandlers[processedTrustedHandlers[i]] == _trusted) {
                processedHandlers[j] = processedTrustedHandlers[i];
                j++;
            }
        }
        return processedHandlers;
    }

    function withdraw(address payable to, address tokenAddress, uint256 amount) external trusted {   
        if (tokenAddress == address(0)) {
            to.transfer(amount);
        } else {
            IERC20(tokenAddress).transfer(to, amount);
        }
    }

    function switchActiveTrustedHandlers(address[] memory _handlers, bool approve) public trusted {
        for (uint256 i = 0; i < _handlers.length; i++) {
            areTrustedHandlers[_handlers[i]] = approve;
            processedTrustedHandlers.push(_handlers[i]);
        }
    }

    function switchActiveTrustedTokens(address[] memory _tokens, bool approve) public trusted {
        for (uint256 i = 0; i < _tokens.length; i++) {
            areTokenTrusted[_tokens[i]] = approve;
        }
    }

    function checkTrusted(address _addr) public view trusted returns (bool) {
        return areTrustedHandlers[_addr];
    }

    function checkTrustedToken(address _token) public view trusted returns (bool) {
        return areTokenTrusted[_token];
    }

    function getFee() public view trusted returns (uint8) {
        return feePercent;
    }

    function updateFeePercent(uint8 _feePercent) external trusted {
        require(_feePercent > 0 || _feePercent < 100, '___INVALID_FEE_PERCENT___');
        feePercent = _feePercent;
    }

    function updateFeeAddress(address _feeAddress) external trusted {
        feeAddress = _feeAddress;
    }

    fallback() external payable {
        require(msg.value > 0, '___INVALID_AMOUNT___');
    }
    receive() external payable {
        require(msg.value > 0, '___INVALID_AMOUNT___');
    }

    function balanceOf(address tokenAddress) public view returns (uint256) {
        if (tokenAddress == address(0)) {
            return address(this).balance;
        }
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function getMyEscrows() public view returns (address[] memory escrowAddresses) {
        return myEscrows[msg.sender];
    }

    // recent to oldest
    function getEscrowDetailsPaging(uint256 offset) external view trusted returns (address[] memory escrowAddresses, uint256 total) {
        uint256 limit = 10;
        if (limit > escrows.length - offset) {
            limit = escrows.length - offset;
        }

        address[] memory values = new address[](limit);
        for (uint256 i = 0; i < limit; i++) {
            values[i] = escrows[escrows.length - 1 - offset - i];
        }
        return (values, escrows.length);
    }

    modifier trusted() {
        require(areTrustedHandlers[msg.sender], '___NOT_TRUSTED___');
        _;
    }
}