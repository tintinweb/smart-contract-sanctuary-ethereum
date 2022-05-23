/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

// File: contracts/Owner.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {
    address private owner;

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    /**
     * @dev Set contract deployer as owner
     */
    constructor() public {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

// File: contracts/ERC20.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

interface ERC20 {
    function totalSupply() external returns (uint256);

    function balanceOf(address tokenOwner) external returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        external
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function approve(address spender, uint256 tokens)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

// File: contracts/Payout.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;
pragma experimental ABIEncoderV2;


contract Payout is Owner {
    bytes32 constant NULL = "0x0";
    enum Status {
        SUBMITTED,
        DEPOSITED,
        WITHDRAWED
    }
    struct UserTransaction {
        address user;
        uint256 amount;
        bytes32 depositTxHash;
        uint256 chainId;
        address token;
        bytes32 withdrawTxHash;
        Status status;
    }

    address owner;
    mapping(address => UserTransaction[]) db;
    event CashOut(
        address user,
        uint256 txIndex,
        uint256 amount,
        uint256 chainId,
        address token
    );

    function cashOut(uint256 chainId, address token)
        public
        payable
        returns (UserTransaction memory)
    {
        address user = msg.sender;
        uint256 amount = msg.value;
        db[user].push(
            UserTransaction(
                user,
                amount,
                NULL,
                chainId,
                token,
                NULL,
                Status.SUBMITTED
            )
        );
        uint256 txIndex = db[user].length - 1;
        emit CashOut(user, txIndex, amount, chainId, token);
        return db[user][txIndex];
    }

    function withdraw(
        address user,
        address token,
        uint256 amount
    ) public {
        ERC20(token).transfer(user, amount);
    }

    function listUserTransactions(address user)
        public
        view
        returns (UserTransaction[] memory)
    {
        return db[user];
    }

    function readUserTransaction(address user, uint256 txIndex)
        public
        view
        returns (UserTransaction memory)
    {
        return db[user][txIndex];
    }

    function updateUserTransactionDepositTxHash(
        address user,
        uint256 txIndex,
        bytes32 depositTxHash
    ) public isOwner returns (UserTransaction memory) {
        db[user][txIndex].depositTxHash = depositTxHash;
        db[user][txIndex].status = Status.DEPOSITED;
        return db[user][txIndex];
    }

    function updateUserTransactionWithdrawTxHash(
        address user,
        uint256 txIndex,
        bytes32 withdrawTxHash
    ) public isOwner returns (UserTransaction memory) {
        db[user][txIndex].withdrawTxHash = withdrawTxHash;
        db[user][txIndex].status = Status.WITHDRAWED;
        return db[user][txIndex];
    }
}