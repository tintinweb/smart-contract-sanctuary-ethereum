// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MultiSignReceiverChangeTx {
    event RcTxSubmit(uint256 indexed txId);
    event RcTxApprove(address indexed signer, uint256 indexed txId);
    event RcTxRevoke(address indexed signer, uint256 indexed txId);
    event RcTxExecute(uint256 indexed txId);

    struct RcTransaction {
        address receiver;
        bool executed;
    }

    RcTransaction[] public rcTransactions;
    address[] public rcTxSigners;
    uint256 public rcTxRequired;
    mapping(address => bool) public isRcTxSigner;
    mapping(uint256 => mapping(address => bool)) public rcTxApproved;

    modifier onlyRcTxSigner() {
        require(
            isRcTxSigner[msg.sender],
            "MultiSignReceiverChangeTx: not tx signer"
        );
        _;
    }

    modifier rcTxExists(uint256 _txId) {
        require(
            _txId < rcTransactions.length,
            "MultiSignReceiverChangeTx: tx does not exist"
        );
        _;
    }

    modifier rcTxNotApproved(uint256 _txId) {
        require(
            !rcTxApproved[_txId][msg.sender],
            "MultiSignReceiverChangeTx: tx already approved"
        );
        _;
    }

    modifier rcTxNotExecuted(uint256 _txId) {
        require(
            !rcTransactions[_txId].executed,
            "MultiSignReceiverChangeTx: tx already executed"
        );
        _;
    }

    constructor(address[] memory _signers, uint256 _required) {
        require(
            _signers.length > 0,
            "MultiSignReceiverChangeTx: tx signers required"
        );
        require(
            _required > 0 && _required <= _signers.length,
            "MultiSignReceiverChangeTx: invalid required number of tx signers"
        );

        for (uint256 i; i < _signers.length; i++) {
            address signer = _signers[i];
            require(
                signer != address(0),
                "MultiSignReceiverChangeTx: invalid tx signer"
            );
            require(
                !isRcTxSigner[signer],
                "MultiSignReceiverChangeTx: tx signer is not unique"
            );

            isRcTxSigner[signer] = true;
            rcTxSigners.push(signer);
        }

        rcTxRequired = _required;
    }

    function getRcTransactions()
        external
        view
        returns (RcTransaction[] memory)
    {
        return rcTransactions;
    }

    function rcTxSubmit(address _receiver) external onlyRcTxSigner {
        rcTransactions.push(
            RcTransaction({receiver: _receiver, executed: false})
        );
        emit RcTxSubmit(rcTransactions.length - 1);
    }

    function rcTxApprove(uint256 _txId)
        external
        onlyRcTxSigner
        rcTxExists(_txId)
        rcTxNotApproved(_txId)
        rcTxNotExecuted(_txId)
    {
        rcTxApproved[_txId][msg.sender] = true;
        emit RcTxApprove(msg.sender, _txId);
    }

    function getRcTxApprovalCount(uint256 _txId)
        public
        view
        returns (uint256 count)
    {
        for (uint256 i; i < rcTxSigners.length; i++) {
            if (rcTxApproved[_txId][rcTxSigners[i]]) {
                count += 1;
            }
        }
    }

    function rcTxRevoke(uint256 _txId)
        external
        onlyRcTxSigner
        rcTxExists(_txId)
        rcTxNotExecuted(_txId)
    {
        require(
            rcTxApproved[_txId][msg.sender],
            "MultiSignReceiverChangeTx: tx not approved"
        );

        rcTxApproved[_txId][msg.sender] = false;
        emit RcTxRevoke(msg.sender, _txId);
    }

    function rcTxExecute(uint256 _txId)
        public
        virtual
        onlyRcTxSigner
        rcTxExists(_txId)
        rcTxNotExecuted(_txId)
    {
        require(
            getRcTxApprovalCount(_txId) >= rcTxRequired,
            "MultiSignReceiverChangeTx: the required number of approvals is insufficient"
        );

        RcTransaction storage rcTransaction = rcTransactions[_txId];
        rcTransaction.executed = true;
        emit RcTxExecute(_txId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../erc20/IERC20.sol";
import "./MultiSignReceiverChangeTx.sol";

contract VestingFounder is MultiSignReceiverChangeTx {
    uint8 public constant decimals = 18;

    struct Transaction {
        uint256 value;
        uint256 expired;
        bool executed;
    }

    Transaction[] public transactions;
    IERC20 public token;
    address public owner;
    address public receiver = 0x6C02a68DA8d687E297d5703932CB63eDc0B61E01;
    address[] public signers = [
        0xd5e7F7f96109Ea5d86ea58f8cEE67505d414769b,
        0xFB643159fB9d6B4064D0EC3a5048503deC72cAf2,
        0xaFdA9e685A401E8B791ceD4F13a3aB4Ed0ff12e3,
        0x0377DA3EA8c9b56E4428727FeF417eFf12950e3f,
        0x1bE9e3393617B74E3A92487a86EE2d2D4De0BfaA
    ];
    // 36 Months Timestamp
    uint256[] public vestingTimestamp = [
        1709251200,
        1711929600,
        1714521600,
        1717200000,
        1719792000,
        1722470400,
        1725148800,
        1727740800,
        1730419200,
        1733011200,
        1735689600,
        1738368000,
        1740787200,
        1743465600,
        1746057600,
        1748736000,
        1751328000,
        1754006400,
        1756684800,
        1759276800,
        1761955200,
        1764547200,
        1767225600,
        1769904000,
        1772323200,
        1775001600,
        1777593600,
        1780272000,
        1782864000,
        1785542400,
        1788220800,
        1790812800,
        1793491200,
        1796083200,
        1798761600,
        1801440000
    ];
    mapping(address => bool) public isSigner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlySigner() {
        require(isSigner[msg.sender], "Not signer");
        _;
    }

    modifier txExists(uint256 _txId) {
        require(_txId < transactions.length, "TX does not exist");
        _;
    }

    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "TX already executed");
        _;
    }

    constructor() MultiSignReceiverChangeTx(signers, signers.length) {
        owner = msg.sender;

        for (uint256 i; i < signers.length; i++) {
            address signer = signers[i];
            require(signer != address(0), "Invalid signer");
            require(!isSigner[signer], "Signer is not unique");

            isSigner[signer] = true;
        }

        // 36 Months = 80,000,000
        // 2,222,222 * 35 = 77,777,770
        for (uint256 i = 0; i < vestingTimestamp.length - 1; i++) {
            transactions.push(
                Transaction({
                    value: 2222222 * 10**decimals,
                    expired: vestingTimestamp[i],
                    executed: false
                })
            );
        }

        // 80,000,000 - 77,777,770 = 2,222,230
        transactions.push(
            Transaction({
                value: 2222230 * 10**decimals,
                expired: vestingTimestamp[vestingTimestamp.length - 1],
                executed: false
            })
        );
    }

    function setTokenAddress(address _token) public onlyOwner {
        token = IERC20(_token);
    }

    function getBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function getTransactions() external view returns (Transaction[] memory) {
        return transactions;
    }

    function withdraw(uint256 _txId)
        external
        onlySigner
        txExists(_txId)
        notExecuted(_txId)
    {
        Transaction storage transaction = transactions[_txId];
        require(
            block.timestamp >= transaction.expired,
            "Tokens have not been unlocked"
        );
        require(
            getBalance() >= transaction.value,
            "Not enough for the balance."
        );

        token.transfer(receiver, transaction.value);
        transaction.executed = true;
    }

    function rcTxExecute(uint256 _txId)
        public
        override
        onlyRcTxSigner
        rcTxExists(_txId)
        rcTxNotExecuted(_txId)
    {
        require(
            getRcTxApprovalCount(_txId) >= rcTxRequired,
            "The required number of approvals is insufficient"
        );

        RcTransaction storage rcTransaction = rcTransactions[_txId];
        receiver = rcTransaction.receiver;
        rcTransaction.executed = true;
        emit RcTxExecute(_txId);
    }
}