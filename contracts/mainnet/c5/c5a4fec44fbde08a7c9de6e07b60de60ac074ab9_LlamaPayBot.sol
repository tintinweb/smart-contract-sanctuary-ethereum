//SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

interface LlamaPay {
    function withdraw(
        address from,
        address to,
        uint216 amountPerSec
    ) external;

    function withdrawable(
        address from,
        address to,
        uint216 amountPerSec
    )
        external
        view
        returns (
            uint256 withdrawableAmount,
            uint256 lastUpdate,
            uint256 owed
        );
}

interface LlamaPayFactory {
    function getLlamaPayContractByToken(address _token)
        external
        view
        returns (address predictedAddress, bool isDeployed);
}

contract LlamaPayBot {
    using SafeTransferLib for ERC20;

    address public immutable factory;
    address public bot;
    address public llama;
    address public newLlama = address(0);
    uint256 public fee = 50000; // Covers bot gas cost for calling function

    event WithdrawScheduled(
        address owner,
        address token,
        address from,
        address to,
        uint216 amountPerSec,
        uint40 starts,
        uint40 frequency,
        bytes32 id
    );

    event WithdrawCancelled(
        address owner,
        address token,
        address from,
        address to,
        uint216 amountPerSec,
        uint40 starts,
        uint40 frequency,
        bytes32 id
    );

    event WithdrawExecuted(
        address owner,
        address token,
        address from,
        address to,
        uint216 amountPerSec,
        uint40 starts,
        uint40 frequency,
        bytes32 id
    );

    mapping(address => uint256) public balances;
    mapping(bytes32 => address) public owners;
    mapping(address => address) public redirects;

    constructor(
        address _factory,
        address _bot,
        address _llama
    ) {
        factory = _factory;
        bot = _bot;
        llama = _llama;
    }

    function deposit() external payable {
        require(msg.sender != bot, "bot cannot deposit");
        balances[msg.sender] += msg.value;
    }

    function refund() external {
        uint256 toSend = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: toSend}("");
        require(sent, "failed to send ether");
    }

    function scheduleWithdraw(
        address _token,
        address _from,
        address _to,
        uint216 _amountPerSec,
        uint40 _starts,
        uint40 _frequency
    ) external returns (bytes32 id) {
        id = calcWithdrawId(
            _token,
            _from,
            _to,
            _amountPerSec,
            _starts,
            _frequency
        );
        require(owners[id] == address(0), "already exists");
        owners[id] = msg.sender;
        emit WithdrawScheduled(
            msg.sender,
            _token,
            _from,
            _to,
            _amountPerSec,
            _starts,
            _frequency,
            id
        );
    }

    function cancelWithdraw(
        address _token,
        address _from,
        address _to,
        uint216 _amountPerSec,
        uint40 _starts,
        uint40 _frequency
    ) external returns (bytes32 id) {
        id = calcWithdrawId(
            _token,
            _from,
            _to,
            _amountPerSec,
            _starts,
            _frequency
        );
        require(msg.sender == owners[id], "not owner");
        owners[id] = address(0);
        emit WithdrawCancelled(
            msg.sender,
            _token,
            _from,
            _to,
            _amountPerSec,
            _starts,
            _frequency,
            id
        );
    }

    function setRedirect(address _to) external {
        redirects[msg.sender] = _to;
    }

    function cancelRedirect() external {
        redirects[msg.sender] = address(0);
    }

    function executeWithdraw(
        address _owner,
        address _token,
        address _from,
        address _to,
        uint216 _amountPerSec,
        uint40 _starts,
        uint40 _frequency,
        bytes32 _id,
        bool _execute,
        bool _emitEvent
    ) external {
        require(msg.sender == bot, "not bot");
        if (_execute) {
            (address llamapay, bool isDeployed) = LlamaPayFactory(factory)
                .getLlamaPayContractByToken(_token);
            require(isDeployed, "invalid llamapay contract");
            if (redirects[_to] != address(0)) {
                (uint256 withdrawableAmount, , ) = LlamaPay(llamapay)
                    .withdrawable(_from, _to, _amountPerSec);
                LlamaPay(llamapay).withdraw(_from, _to, _amountPerSec);
                ERC20(_token).safeTransferFrom(
                    _to,
                    redirects[_to],
                    withdrawableAmount
                );
            } else {
                LlamaPay(llamapay).withdraw(_from, _to, _amountPerSec);
            }
        }
        if (_emitEvent) {
            emit WithdrawExecuted(
                _owner,
                _token,
                _from,
                _to,
                _amountPerSec,
                _starts,
                _frequency,
                _id
            );
        }
    }

    function execute(bytes[] calldata _calls, address _from) external {
        require(msg.sender == bot, "not bot");
        uint256 i;
        uint256 len = _calls.length;
        uint256 startGas = gasleft();
        for (i = 0; i < len; ++i) {
            address(this).delegatecall(_calls[i]);
        }
        uint256 gasUsed = ((startGas - gasleft()) + 21000) + fee;
        uint256 totalSpent = gasUsed * tx.gasprice;
        balances[_from] -= totalSpent;
        (bool sent, ) = bot.call{value: totalSpent}("");
        require(sent, "failed to send ether to bot");
    }

    function batchExecute(bytes[] calldata _calls) external {
        require(msg.sender == bot, "not bot");
        uint256 i;
        uint256 len = _calls.length;
        for (i = 0; i < len; ++i) {
            address(this).delegatecall(_calls[i]);
        }
    }

    function changeBot(address _newBot) external {
        require(msg.sender == llama, "not llama");
        bot = _newBot;
    }

    function changeLlama(address _newLlama) external {
        require(msg.sender == llama, "not llama");
        newLlama = _newLlama;
    }

    function confirmNewLlama() external {
        require(msg.sender == newLlama, "not new llama");
        llama = newLlama;
    }

    function changeFee(uint256 _newFee) external {
        require(msg.sender == llama, "not llama");
        fee = _newFee;
    }

    function calcWithdrawId(
        address _token,
        address _from,
        address _to,
        uint216 _amountPerSec,
        uint40 _starts,
        uint40 _frequency
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _token,
                    _from,
                    _to,
                    _amountPerSec,
                    _starts,
                    _frequency
                )
            );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}