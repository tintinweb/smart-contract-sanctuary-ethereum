/**
 *Submitted for verification at Etherscan.io on 2022-05-18
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

// File: contracts/MsscConfirmByCycle.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract MSSC {
    // Events
    event Registration(bytes32 indexed cycleId, Instruction[] instructions);
    event Execution(bytes32 indexed cycleId, Instruction[] instructions);
    event SpendingApproved(address sender, bytes32 cycleId);
    event SpendingDisapproved(address sender, bytes32 cycleId);
    event Deposited(address account, bytes32 cycleId);
    event Withdrawn(address account, bytes32 cycleId);

    struct Instruction {
        bytes32 id;
        address sender;
        address receiver;
        address asset;
        uint256 amount;
        // uint date;
        // string senderName;
        // string receiverName;
    }

    mapping(bytes32 => bool) private _executed;
    mapping(bytes32 => Instruction[]) private _cycles;
    // cycle -> couterparty -> confirmed?
    mapping(bytes32 => mapping(address => bool)) private _confirmations;
    // sender -> cycle -> amount
    mapping(address => mapping(bytes32 => uint256)) private _deposits;
    mapping(address => bytes32[]) private _cyclesWithDeposit;

    /// @notice register settlementCycle, this function can only be perfomed by a Membrane wallet.
    /// @dev caller must transform obfuscatedId string to bytes32, pure strings are not supported.
    /// @param cycleId cycle's bytes32 obfuscatedId to register.
    /// @param instructions instructions to register.
    function registerSettlementCycle(
        bytes32 cycleId,
        Instruction[] calldata instructions
    ) external {
        // get instructions from storage
        Instruction[] storage newInstructions = _cycles[cycleId];
        // ensure that cycleId isn't registered yet
        require(!_exist(cycleId), "settlement cycle already registered");

        for (uint256 i = 0; i < instructions.length; i++) {
            Instruction memory instruction = instructions[i];
            require(
                instruction.sender != address(0) &&
                    instruction.receiver != address(0),
                "no zero addresses"
            );
            require(instruction.amount > 0, "no zero amount");
            require(
                instruction.asset.code.length > 0 ||
                    instruction.asset == address(0),
                "invalid asset"
            );
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
        emit Registration(cycleId, newInstructions);
    }

    /// @notice checks if SettlementCycle can be registered.
    /// @notice it's recommended to call this function and make sure that SettlementCycle is able to be registered before calling {registerSettlementCycle()} and prevent the TX from being reverted.
    /// @param cycleId cycle's bytes32 obfuscatedId to check.
    function canRegister(bytes32 cycleId, Instruction[] calldata instructions)
        public
        view
        returns (bool)
    {
        if (_exist(cycleId)) return false;
        if (!_checkInstructions(instructions)) return false;

        return true;
    }

    /// @notice execute instructions in a SettlementCycle, anyone can call this function as long as it meets some requirements.
    /// @notice further call to {isReadyToExecute()} is recommended before performing this function to ensure that the SettlementCycle meets the requirements to execute instructions.
    /// @dev the logic of checking that the Settlement Cycle is ready to execute isn't done from inside just to save gas.
    /// @param cycleId cycle's bytes32 obfuscatedId to execute.
    function executeInstructions(bytes32 cycleId) public {
        require(_exist(cycleId), "settlement cycle isn't registered");

        // ensure that SettlementCycle can't be executed twice.
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
        emit Execution(cycleId, instructions);
    }

    /// @notice checks if SettlementCycle is meeting requirements (balances, allowances, is not executed and if it is registered) hence ready to execute.
    /// @notice it's recommended to call this function and make sure that SettlementCycle is able to be executed before calling {executeInstructions()} and prevent the TX from being reverted.
    /// @param cycleId cycle's bytes32 obfuscatedId to check.
    function isReadyToExecute(bytes32 cycleId) public view returns (bool) {
        if (!_exist(cycleId)) return false;
        if (_executed[cycleId]) return false;
        if (!_checkBalancesAndAllowancesFromCycle(cycleId)) return false;
        if (!_isApprovedBySenders(cycleId)) return false;

        return true;
    }

    function executed(bytes32 cycleId) external view returns (bool) {
        return _executed[cycleId];
    }

    function getSettlementInstructions(bytes32 cycleId)
        external
        view
        returns (Instruction[] memory)
    {
        return _cycles[cycleId];
    }

    function testReadyToExecute(bytes32 cycleId, int maxIterations)
        public
        view
        returns (bool)
    {
        for (int i = 0; i < maxIterations; i++) {
            isReadyToExecute(cycleId);
        }
        return true;
    }

    function deposit(bytes32 cycleId) external payable {
        _deposits[msg.sender][cycleId] += msg.value;
        _cyclesWithDeposit[msg.sender].push(cycleId);
        emit Deposited(msg.sender, cycleId);
    }

    function deposits(address sender, bytes32 cycleId)
        external
        view
        returns (uint256)
    {
        return _deposits[sender][cycleId];
    }

    function allCyclesWithDeposit(address sender)
        external
        view
        returns (bytes32[] memory)
    {
        return _cyclesWithDeposit[sender];
    }

    function withdraw(bytes32 cycleId) external {
        uint256 amount = _deposits[msg.sender][cycleId];
        require(amount > 0, "nothing to withdraw");
        _deposits[msg.sender][cycleId] = 0;

        _dropCycleWithDeposit(msg.sender, cycleId);
        payable(msg.sender).transfer(amount);
        emit Withdrawn(msg.sender, cycleId);
    }

    /// @dev Approve a settlement cycle to be executed.
    function approveSpending(bytes32 cycleId) external {
        require(
            _isSender(msg.sender, cycleId),
            "not a sender in this settlement cycle"
        );
        _confirmations[cycleId][msg.sender] = true;
        emit SpendingApproved(msg.sender, cycleId);
    }

    /// @dev Remove approval to a settlement cycle.
    function disapproveSpending(bytes32 cycleId) external {
        require(
            _isSender(msg.sender, cycleId),
            "not a sender in this settlement cycle"
        );
        _confirmations[cycleId][msg.sender] = false;
        emit SpendingDisapproved(msg.sender, cycleId);
    }

    /*//////////////////////////////////////////////////////////////
                          PRIVATE OPERATIONS
    //////////////////////////////////////////////////////////////*/

    // Check if an address is a sender of any instruction in the SettleMentCycle.
    function _isSender(address sender, bytes32 cycleId)
        private
        view
        returns (bool)
    {
        //gas savings
        Instruction[] memory instructions = _cycles[cycleId];

        for (uint256 i; i < instructions.length; i++) {
            if (instructions[i].sender == sender) return true;
        }
        return false;
    }

    // Check that cycleId is registered by looking at instructions length, this function may change its logic later
    function _exist(bytes32 cycleId) private view returns (bool) {
        return _cycles[cycleId].length > 0;
    }

    // calculate the total amount of an asset a sender address will transfer in a single SettlementCycle
    function _totalSenderAmount(
        address sender,
        bytes32 cycleId,
        address asset
    ) private view returns (uint256 total) {
        Instruction[] memory instructions = _cycles[cycleId];
        for (uint256 i; i < instructions.length; i++) {
            if (
                instructions[i].sender == sender &&
                asset == instructions[i].asset
            ) {
                total += instructions[i].amount;
            }
        }
    }

    // check that instructions have valid properties.
    function _checkInstructions(Instruction[] calldata instructions)
        private
        view
        returns (bool)
    {
        for (uint256 i; i < instructions.length; i++) {
            Instruction memory instruction = instructions[i];
            if (
                instruction.sender == address(0) ||
                instruction.receiver == address(0)
            ) return false;

            // check that asset is a contract or zero address
            if (
                instruction.asset != address(0) &&
                instruction.asset.code.length <= 0
            ) return false;

            if (instruction.amount <= 0) return false;
        }

        return true;
    }

    // check that senders provided valid allowances and deposits.
    function _checkBalancesAndAllowancesFromCycle(bytes32 cycleId)
        private
        view
        returns (bool)
    {
        Instruction[] memory instructions = _cycles[cycleId];
        for (uint256 i = 0; i < instructions.length; i++) {
            Instruction memory instruction = instructions[i];
            if (_confirmations[cycleId][instruction.sender] == false) {
                return false;
            }

            // Get the sum of all amount to send from sender
            uint256 totalAmount = _totalSenderAmount(
                instruction.sender,
                cycleId,
                instruction.asset
            );

            // is native coin asset a native coin?
            if (instruction.asset == address(0)) {
                if (_deposits[instruction.sender][cycleId] < totalAmount) {
                    return false;
                }
            } else {
                // it is a ERC20
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

    // checks that SettlementCycle is aproved by senders.
    function _isApprovedBySenders(bytes32 cycleId) private view returns (bool) {
        // gas savings
        Instruction[] memory instructions = _cycles[cycleId];

        for (uint256 i; i < instructions.length; i++) {
            if (!_confirmations[cycleId][instructions[i].sender]) return false;
        }
        return true;
    }

    // drops the cycle when withdraw is executed (because deposit > required amount)
    function _dropCycleWithDeposit(address sender, bytes32 cycleId) private {
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
}