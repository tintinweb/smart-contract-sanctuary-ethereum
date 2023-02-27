/**
 *Submitted for verification at Etherscan.io on 2023-02-27
*/

// Sources flattened with hardhat v2.11.2 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: BUSL-1.1
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


// File contracts/Rabbit.sol

pragma solidity ^0.8.17;

// import "hardhat/console.sol";

interface IStarknetCore {
    /**
       Sends a message to an L2 contract.

       Returns the hash of the message.
    */
    function sendMessageToL2(uint toAddress, uint selector, uint[] calldata payload)
        external payable returns (bytes32);

    /**
       Consumes a message that was sent from an L2 contract.

       Returns the hash of the message.
    */
    function consumeMessageFromL2(uint fromAddress, uint[] calldata payload)
        external returns (bytes32);
}

contract Rabbit {

    /* Starknet deposit function selector
       It's obtained from the @l1_handler function name (in this 
       case 'deposit_handler') using the following Python code:

       from starkware.starknet.compiler.compile import get_selector_from_name
       print(get_selector_from_name('deposit_handler'))
    */
    uint constant DEPOSIT_SELECTOR = 0x1696B17FB8498D5E407EB2F58D76080BF011D88BB933EFA9A4AC548391251AF;
    uint constant MESSAGE_WITHDRAW_RECEIVED = 0x1010101010101010;
    uint constant UNLOCKED = 1;
    uint constant LOCKED = 2;

    address public immutable owner;
    IStarknetCore public immutable starknetCore;
    uint public rabbitStarknetAddress;
    IERC20 public paymentToken;

    // balance of trader's funds available for withdrawal
    mapping(address => uint) public withdrawableBalance;

    // total of trader's deposits to date
    mapping(address => uint) public deposits;

    // total of trader's withdrawals to date
    mapping(address => uint) public withdrawals;

    uint nextDepositId = 1;
    uint reentryLockStatus = UNLOCKED;

    struct Receipt {
        uint fromAddress;
        address toAddress;
        uint[] payload;
    }

    event Deposit(uint indexed id, address indexed trader, uint amount, bool isResend);
    event Withdraw(address indexed trader, uint amount);
    event WithdrawTo(address indexed to, uint amount);
    event WithdrawalReceipt(address indexed trader, uint amount);
    event UnknownReceipt(uint indexed messageType, uint[] payload);
    event MsgNotFound(uint indexed fromAddress, uint[] payload);

    constructor(address _owner, address _starknetCore, address _paymentToken) {
        owner = _owner;
        starknetCore = IStarknetCore(_starknetCore);
        paymentToken = IERC20(_paymentToken);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    modifier nonReentrant() {
        require(reentryLockStatus == UNLOCKED, "NO_REENTRY");
        reentryLockStatus = LOCKED;
        _;
        reentryLockStatus = UNLOCKED;
    }

    function setRabbitStarknetAddress(uint _rabbitStarknetAddress) external onlyOwner {
        rabbitStarknetAddress = _rabbitStarknetAddress;
    }

    function setPaymentToken(address _paymentToken) external onlyOwner {
        paymentToken = IERC20(_paymentToken);
    }

    function allocateDepositId() private returns (uint depositId) {
        depositId = nextDepositId;
        nextDepositId++;
        return depositId;
    }

    // re-entrancy shouldn't be possible anyway, but have nonReentrant modifier as well
    function deposit(uint amount) external nonReentrant {
        bool success = makeTransferFrom(msg.sender, address(this) , amount);
        require(success, "TRANSFER_FAILED");
        deposits[msg.sender] += amount;
        depositOnStarknet(amount, msg.sender, false);
    }

    function resend (uint amount, address trader) external onlyOwner {
        depositOnStarknet(amount, trader, true);
    }

    function depositOnStarknet(uint amount, address trader, bool isResend) private {
        uint depositId = allocateDepositId();
        emit Deposit(depositId, trader, amount, isResend);
        uint traderInt = uint(uint160(trader));
        uint[] memory payload = new uint[](3);
        payload[0] = depositId;
        payload[1] = traderInt;
        payload[2] = amount;
        starknetCore.sendMessageToL2(rabbitStarknetAddress, DEPOSIT_SELECTOR, payload);
    }

    function withdrawTokensTo(uint amount, address to) onlyOwner external {
        require(amount > 0, "WRONG_AMOUNT");
        require(to != address(0), "ZERO_ADDRESS");

        bool success = makeTransfer(to, amount);
        require(success, "TRANSFER_FAILED");


        emit WithdrawTo(to, amount);
    }
    

    // re-entrancy shouldn't be possible anyway, but have nonReentrant modifier as well
    function withdraw() nonReentrant external {
        uint amount = withdrawableBalance[msg.sender];
        require(amount != 0, "INSUFFICIENT_FUNDS");
        withdrawableBalance[msg.sender] = 0;
        emit Withdraw(msg.sender, amount); 
        bool success = makeTransfer(msg.sender, amount);
        require(success, "TRANSFER_FAILED");
    }

    // re-entrancy shouldn't be possible anyway, but have nonReentrant modifier as well
    function consumeMessages(Receipt[] calldata receipts) nonReentrant external {
        for (uint i = 0; i < receipts.length; i++) {            
            Receipt calldata receipt = receipts[i];
            uint[] calldata payload = receipt.payload;
            if (receipt.fromAddress == rabbitStarknetAddress) {
                // Consume the message from the Starknet core contract. This will
                // revert the (Ethereum) transaction if the message does not exist.
                try starknetCore.consumeMessageFromL2(rabbitStarknetAddress, payload) {
                    uint messageType = payload[0];
                    if (messageType == MESSAGE_WITHDRAW_RECEIVED) {
                        handleWithdrawalReceipt(payload);
                    } else {
                        emit UnknownReceipt(messageType, payload);
                    }
                } catch {
                    emit MsgNotFound(rabbitStarknetAddress, payload);
                }
            }
        }
    }

    function handleWithdrawalReceipt(uint[] calldata payload) private {
        uint next = 1;
        uint len = payload.length;
        while (next < len - 1) {
            address trader = address(uint160(payload[next]));
            uint amount = payload[next + 1];
            withdrawals[trader] += amount;
            withdrawableBalance[trader] += amount;
            emit WithdrawalReceipt(trader, amount);
            next = next + 2;
        }
    }

    function makeTransfer(address to, uint256 amount) private returns (bool success) {
        return tokenCall(abi.encodeWithSelector(paymentToken.transfer.selector, to, amount));
    }

    function makeTransferFrom(address from, address to, uint256 amount) private returns (bool success) {
        return tokenCall(abi.encodeWithSelector(paymentToken.transferFrom.selector, from, to, amount));
    }

    function tokenCall(bytes memory data) private returns (bool) {
        (bool success, bytes memory returndata) = address(paymentToken).call(data);
        if (success && returndata.length > 0) {
            success = abi.decode(returndata, (bool));
        }
        return success;
    }
}