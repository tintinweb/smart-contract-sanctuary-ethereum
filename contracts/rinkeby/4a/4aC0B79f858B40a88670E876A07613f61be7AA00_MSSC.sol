//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MSSC {
    struct Instruction {
        uint256 id;
        address sender;
        address receiver;
        address asset;
        uint256 amount;
        // uint date;
        // string senderName;
        // string receiverName;
    }

    mapping(uint256 => bool) private _executed;
    mapping(uint256 => Instruction[]) private _cycles;
    // cycle -> couterparty -> confirmed?
    mapping(uint256 => mapping(address => bool)) private _confirmations;
    // sender -> cycle -> amount
    mapping(address => mapping(uint256 => uint256)) private _deposits;
    mapping(address => uint256[]) private _cyclesWithDeposit;

    function executed(uint256 cycleId) public view returns (bool) {
        return _executed[cycleId];
    }

    function getSettlementInstructions(uint256 cycleId)
        public
        view
        returns (Instruction[] memory)
    {
        return _cycles[cycleId];
    }

    function canRegistedsr(uint256 cycleId, Instruction[] memory instructions)
        public
        view
        returns (bool)
    {
        return false;
    }

    function testReadyToExecute(uint256 cycleId, int maxIterations) public view returns (bool) {
        for(int i = 0; i < maxIterations; i++) {
            isReadyToExecute(cycleId);
        }
        return true;
    }

    function isReadyToExecute(uint256 cycleId) public view returns (bool) {
        if (_executed[cycleId]) {
            return false;
        }
        if (_cycles[cycleId].length == 0) return false;
        Instruction[] memory instructions = _cycles[cycleId];
        for (uint256 i = 0; i < instructions.length; i++) {
            Instruction memory instruction = instructions[i];
            if (_confirmations[cycleId][instruction.sender] == false) {
                return false;
            }

            // Get the sum of all amount to send from sender
            uint256 totalAmount = _totalSenderAmount(instruction.sender,cycleId);

            if (instruction.asset == address(0)) {
                // TODO: verify deposit for many instructions from the same sender (different receivers)
                if (
                    _deposits[instruction.sender][cycleId] < totalAmount
                ) {
                    return false;
                }
            } else {
                // TODO: verify deposit for many instructions from the same sender (different receivers)
                if (
                    IERC20(instruction.asset).balanceOf(instruction.sender) <
                    totalAmount
                ) {
                    return false;
                }
                if (
                    IERC20(instruction.asset).allowance(
                        instruction.sender,
                        address(this)
                    ) < totalAmount
                ) {
                    return false;
                }
            }
        }
        return true;
    }

    function _totalSenderAmount(address sender, uint256 cycleId)
        private
        view
        returns (uint256 total)
    {
        Instruction[] memory instructions = _cycles[cycleId];
        for (uint256 i; i < instructions.length; i++) {
            if (instructions[i].sender == sender)
                total += instructions[i].amount;
        }
    }

    function deposit(uint256 cycleId) public payable {
        _deposits[msg.sender][cycleId] += msg.value;
        _cyclesWithDeposit[msg.sender].push(cycleId);
        emit Deposited(cycleId);
    }

    function deposits(address sender, uint256 cycleId)
        public
        view
        returns (uint256)
    {
        return _deposits[sender][cycleId];
    }

    function allCyclesWithDeposit(address sender)
        public
        view
        returns (uint256[] memory)
    {
        return _cyclesWithDeposit[sender];
    }

    function _dropCycleWithDeposit(address sender, uint256 cycleId) private {
        uint len = _cyclesWithDeposit[sender].length;
        for (uint i = 0; i < len; i++) {
            if (_cyclesWithDeposit[sender][i] == cycleId) {
                _cyclesWithDeposit[sender][i] = _cyclesWithDeposit[msg.sender][
                    len - 1
                ];
                _cyclesWithDeposit[sender].pop();
                break;
            }
        }
    }

    function withdraw(uint256 cycleId) public {
        uint256 amount = _deposits[msg.sender][cycleId];
        require(amount > 0, "nothing to withdraw");
        _deposits[msg.sender][cycleId] = 0;
        // only drops the cycle when withdraw is executed (because deposit > required amount)
        _dropCycleWithDeposit(msg.sender, cycleId);
        payable(msg.sender).transfer(amount);
        emit Withdrawn(cycleId);
    }

    function approveSpending(uint256 cycleId) public {
        _confirmations[cycleId][msg.sender] = true;
        emit SpendingApproved(cycleId);
    }

    function disapproveSpending(uint256 cycleId) public {
        _confirmations[cycleId][msg.sender] = false;
        emit SpendingDisapproved(cycleId);
    }

    function registerSettlementCycle(
        uint256 cycleId,
        Instruction[] calldata instructions
    ) external {
        Instruction[] storage newInstructions = _cycles[cycleId];
        require(
            newInstructions.length == 0,
            "settlement cycle already registered"
        );
        for (uint256 i = 0; i < instructions.length; i++) {
            Instruction memory instruction = instructions[i];
            newInstructions.push(
                Instruction({
                    id: instruction.id,
                    sender: instruction.sender,
                    receiver: instruction.receiver,
                    asset: instruction.asset,
                    amount: instruction.amount //,
                    // date: instruction.date,
                    // senderName: instruction.senderName,
                    // receiverName: instruction.receiverName
                })
            );
        }
        emit Registration(cycleId);
    }

    function executeInstructions(uint256 cycleId) public {
        require(
            _executed[cycleId] == false,
            "settlement cycle already executed"
        );
        _executed[cycleId] = true;
        Instruction[] storage instructions = _cycles[cycleId];
        for (uint256 i = 0; i < instructions.length; i++) {
            Instruction storage instruction = instructions[i];
            require(
                _confirmations[cycleId][instruction.sender],
                "unconfirmed cycle"
            );
            if (instruction.asset == address(0)) {
                require(
                    _deposits[instruction.sender][cycleId] >=
                        instruction.amount,
                    "insufficient amount"
                );
                _deposits[instruction.sender][cycleId] -= instruction.amount;
                payable(instruction.receiver).transfer(instruction.amount);
            } else {
                IERC20(instruction.asset).transferFrom(
                    instruction.sender,
                    instruction.receiver,
                    instruction.amount
                );
            }
        }
        emit Execution(cycleId);
    }

    event Registration(uint256 cycleId);
    event Execution(uint256 cycleId);
    event SpendingApproved(uint256 cycleId);
    event SpendingDisapproved(uint256 cycleId);
    event Deposited(uint256 cycleId);
    event Withdrawn(uint256 cycleId);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}