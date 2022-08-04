// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "../Utils.sol";

contract EulStakes {
    address public immutable eul;
    string public constant name = "EUL Stakes";
    mapping(address => mapping(address => uint)) userStaked;

    event Stake(address indexed who, address indexed underlying, address sender, uint newAmount);

    constructor(address eul_) {
        eul = eul_;
    }

    /// @notice Retrieve current amount staked
    /// @param account User address
    /// @param underlying Token staked upon
    /// @return Amount of EUL token staked
    function staked(address account, address underlying) external view returns (uint) {
        return userStaked[account][underlying];
    }

    /// @notice Staking operation item. Positive amount means to increase stake on this underlying, negative to decrease.
    struct StakeOp {
        address underlying;
        int amount;
    }

    /// @notice Modify stake of a series of underlyings. If the sum of all amounts is positive, then this amount of EUL will be transferred in from the sender's wallet. If negative, EUL will be transferred out to the sender's wallet.
    /// @param ops Array of operations to perform
    function stake(StakeOp[] memory ops) public {
        int delta = 0;

        for (uint i = 0; i < ops.length; ++i) {
            StakeOp memory op = ops[i];
            if (op.amount == 0) continue;

            require(op.amount > -1e36 && op.amount < 1e36, "amount out of range");

            uint newAmount;

            {
                int newAmountSigned = int(userStaked[msg.sender][op.underlying]) + op.amount;
                require(newAmountSigned >= 0, "insufficient staked");
                newAmount = uint(newAmountSigned);
            }

            userStaked[msg.sender][op.underlying] = newAmount;
            emit Stake(msg.sender, op.underlying, msg.sender, newAmount);

            delta += op.amount;
        }

        if (delta > 0) {
            Utils.safeTransferFrom(eul, msg.sender, address(this), uint(delta));
        } else if (delta < 0) {
            Utils.safeTransfer(eul, msg.sender, uint(-delta));
        }
    }

    /// @notice Increase stake on an underlying, and transfer this stake to a beneficiary
    /// @param beneficiary Who is given credit for this staked EUL
    /// @param underlying The underlying token to be staked upon
    /// @param amount How much EUL to stake
    function stakeGift(address beneficiary, address underlying, uint amount) external {
        require(amount < 1e36, "amount out of range");
        if (amount == 0) return;

        uint newAmount = userStaked[beneficiary][underlying] + amount;

        userStaked[beneficiary][underlying] = newAmount;
        emit Stake(beneficiary, underlying, msg.sender, newAmount);

        Utils.safeTransferFrom(eul, msg.sender, address(this), amount);
    }

    /// @notice Applies a permit() signature to EUL and then applies a sequence of staking operations
    /// @param ops Array of operations to perform
    /// @param value The value field of the permit message
    /// @param deadline The deadline field of the permit message
    /// @param v Signature field
    /// @param r Signature field
    /// @param s Signature field
    function stakePermit(StakeOp[] memory ops, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        IERC20Permit(eul).permit(msg.sender, address(this), value, deadline, v, r, s);

        stake(ops);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./Interfaces.sol";

library Utils {
    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), string(data));
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), string(data));
    }

    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), string(data));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;


interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IERC20Permit {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external;
    function permit(address owner, address spender, uint value, uint deadline, bytes calldata signature) external;
}

interface IERC3156FlashBorrower {
    function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata data) external returns (bytes32);
}

interface IERC3156FlashLender {
    function maxFlashLoan(address token) external view returns (uint256);
    function flashFee(address token, uint256 amount) external view returns (uint256);
    function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata data) external returns (bool);
}