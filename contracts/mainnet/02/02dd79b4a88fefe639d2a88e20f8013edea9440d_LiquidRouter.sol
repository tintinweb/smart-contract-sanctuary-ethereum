/**
 *Submitted for verification at Etherscan.io on 2023-01-18
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

interface IPermit2 {
    struct PermitTransferFrom {
        TokenPermissions permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    struct PermitBatchTransferFrom {
        // the tokens and corresponding amounts permitted for a transfer
        TokenPermissions[] permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    struct TokenPermissions {
        // ERC20 token address
        address token;
        // the maximum amount that can be spent
        uint256 amount;
    }

    struct SignatureTransferDetails {
        // recipient address
        address to;
        // spender requested amount
        uint256 requestedAmount;
    }

    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    function permitTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

/// @title Constants
library Constants {
    /// @notice Liquid Transfer Proxy address.
    address public constant _LIQUID_TRANSFER_PROXY =
        0x30285A1cE301fC7Eb57628a7f53d02fBDED3288f;

    /// @notice ETH address.
    address internal constant _ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice sETH address.
    address internal constant _stETH =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    /// @notice WETH address.
    address internal constant _WETH =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address internal constant _PERMIT2 =
        0x000000000022D473030F116dDEE9F6B43aC78BA3;

    /// @dev Used for identifying cases when this contract's balance of a token is to be used
    uint256 internal constant CONTRACT_BALANCE = 0;

    /// @dev Used as a flag for identifying msg.sender, saves gas by sending more 0 bytes
    address internal constant MSG_SENDER = address(1);

    /// @dev Used as a flag for identifying address(this), saves gas by sending more 0 bytes
    address internal constant ADDRESS_THIS = address(2);

    /// @dev Error message when the caller is not allowed to call the function.
    error NOT_ALLOWED();

    /// @dev Error message when the deadline has passed.
    error DEADLINE_EXCEEDED();

    /// @dev Error message for when the amount of received tokens is less than the minimum amount
    error NOT_ENOUGH_RECEIVED();

    /// @dev Error message when Liquid Router is already initialized.
    error ALREADY_INITIALIZED();

    /// @dev Error message when a token is not on the liquidity pool, for adding or removing liquidity
    error NOT_IN_POOL();

    /// @dev Error message when the market is invalid.
    error INVALID_AGGREGATOR();

    /// @notice Error when swap fails.
    error SWAP_FAILED();

    /// @notice Error when slippage is too high.
    error NOT_ENOUGHT_RECEIVED();
}

/// @title Permitter
/// @notice Enables to use permit from the Permit2 contract.
abstract contract Permitter {
    /// @notice Uses permit to transfer tokens.
    /// @param amount Amount of tokens to transfer.
    /// @param permit Permit data.
    /// @param signature Signature data.
    /// @param from Sender address.
    /// @param to Recipient address.
    function usePermit(
        uint256 amount,
        IPermit2.PermitTransferFrom calldata permit,
        bytes calldata signature,
        address from,
        address to
    ) external {
        if (from == Constants.MSG_SENDER) from = msg.sender;
        if (to == Constants.ADDRESS_THIS) to = address(this);

        IPermit2(Constants._PERMIT2).permitTransferFrom(
            permit, IPermit2.SignatureTransferDetails({to: to, requestedAmount: amount}), from, signature
        );
    }

    /// @notice Uses permit to transfer tokens in batch.
    /// @param permits Permit data.
    /// @param transferDetails Transfer details.
    /// @param from Sender address.
    /// @param signature Signature data.
    function usePermitMulti(
        IPermit2.PermitBatchTransferFrom calldata permits,
        IPermit2.SignatureTransferDetails[] memory transferDetails,
        address from,
        bytes calldata signature
    ) external {
        if (from == Constants.MSG_SENDER) from = msg.sender;
        for (uint8 i; i < transferDetails.length; ++i) {
            if (transferDetails[i].to == Constants.ADDRESS_THIS) transferDetails[i].to = address(this);
        }
        IPermit2(Constants._PERMIT2).permitTransferFrom(permits, transferDetails, from, signature);
    }
}

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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
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

interface ITokenTransferProxy {
    function transferFrom(address token, address from, address to, uint256 amount) external;
}

/// @title TokenUtils
/// @notice Utility functions for tokens.
library TokenUtils {
    using SafeTransferLib for ERC20;

    /// @notice Approves a spender to spend an ERC20 token if not already approved.
    /// @param token The ERC20 token to approve.
    /// @param spender The address to approve.
    function _approve(address token, address spender) internal {
        if (spender == address(0)) {
            return;
        }
        if (ERC20(token).allowance(address(this), spender) == 0) {
            ERC20(token).safeApprove(spender, type(uint256).max);
        }
    }

    /// @notice Transfer funds from the sender to the contract, if needed.
    /// @param amountIn The amount of funds to transfer.
    /// @param token The token to transfer.
    function _amountIn(uint256 amountIn, address token) internal returns (uint256) {
        if (amountIn == Constants.CONTRACT_BALANCE) {
            return ERC20(token).balanceOf(address(this));
        } else if (token == Constants._ETH) {
            return msg.value;
        } else {
            ITokenTransferProxy(Constants._LIQUID_TRANSFER_PROXY).transferFrom(
                token, msg.sender, address(this), amountIn
            );
        }
        return amountIn;
    }

    /// @notice Transfer utils from the contract to the recipient, if needed.
    /// @param _token The token to transfer.
    /// @param _to The recipient address.
    /// @param _amount The amount of funds to transfer.
    function _transfer(address _token, address _to, uint256 _amount) internal returns (uint256) {
        if (_amount == type(uint256).max) {
            _amount = _balanceInOf(_token, address(this));
        }

        if (_to != address(0) && _to != address(this) && _amount != 0) {
            if (_token != Constants._ETH) {
                ERC20(_token).safeTransfer(_to, _amount);
            } else {
                SafeTransferLib.safeTransferETH(_to, _amount);
            }

            return _amount;
        }

        return 0;
    }

    /// @notice Get the balance of an account.
    /// @param _token The token to get the balance of.
    /// @param _acc The account to get the balance of.
    function _balanceInOf(address _token, address _acc) internal view returns (uint256) {
        if (_token == Constants._ETH) {
            return _acc.balance;
        } else {
            return ERC20(_token).balanceOf(_acc);
        }
    }
}

/// @title Aggregators
/// @notice Enables to interact with different aggregators.
abstract contract Aggregators {
    /// @notice AugustusSwapper contract address.
    address public constant AUGUSTUS = 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;

    /// @notice 1nch Router v5 contract address.
    address public constant INCH_ROUTER = 0x1111111254EEB25477B68fb85Ed929f73A960582;

    /// @notice LiFi Diamond contract address.
    address public constant LIFI_DIAMOND = 0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE;

    /// @notice Paraswap Token pull contract address.
    address public constant TOKEN_TRANSFER_PROXY = 0x216B4B4Ba9F3e719726886d34a177484278Bfcae;

    /// @notice Emitted when tokens are exchanged.
    /// @param _from Address of the sender.
    /// @param _to Address of the recipient.
    /// @param _tokenFrom Address of the source token.
    /// @param _tokenTo Address of the destination token.
    /// @param _amountFrom Amount of source token exchanged.
    /// @param _amountTo Amount of destination token received.
    event Exchanged(
        address indexed _from,
        address indexed _to,
        address _tokenFrom,
        address _tokenTo,
        uint256 _amountFrom,
        uint256 _amountTo
    );

    /// @notice Checks if the aggregator is valid.
    modifier onlyValidAggregator(address aggregator) {
        if (aggregator != AUGUSTUS && aggregator != INCH_ROUTER && aggregator != LIFI_DIAMOND) {
            revert Constants.INVALID_AGGREGATOR();
        }
        _;
    }

    /// @notice Exchanges tokens using different aggregators.
    /// @param aggregator Aggregator contract address.
    /// @param srcToken Source token address.
    /// @param destToken Destination token address.
    /// @param underlyingAmount Amount of source token to exchange.
    /// @param callData Data to call the aggregator.
    /// @return received Amount of destination token received.
    function exchange(
        address aggregator,
        address srcToken,
        address destToken,
        uint256 underlyingAmount,
        bytes memory callData,
        address recipient
    ) external payable onlyValidAggregator(aggregator) returns (uint256 received) {
        underlyingAmount = TokenUtils._amountIn(underlyingAmount, srcToken);

        bool success;
        if (srcToken == Constants._ETH) {
            (success,) = aggregator.call{value: underlyingAmount}(callData);
        } else {
            TokenUtils._approve(srcToken, aggregator == AUGUSTUS ? TOKEN_TRANSFER_PROXY : aggregator);
            (success,) = aggregator.call(callData);
        }
        if (!success) revert Constants.SWAP_FAILED();

        if (recipient == Constants.MSG_SENDER) {
            recipient = msg.sender;

            if (destToken == Constants._ETH) {
                received = TokenUtils._balanceInOf(Constants._ETH, address(this));
                TokenUtils._transfer(Constants._ETH, recipient, received);
            } else {
                received = TokenUtils._balanceInOf(destToken, address(this));
                TokenUtils._transfer(destToken, recipient, received);
            }
        }

        emit Exchanged(msg.sender, recipient, srcToken, destToken, underlyingAmount, received);
    }

    receive() external payable {}
}

interface IFeeDistributor {
    function claim() external returns (uint256);

    function claim(address _user) external returns (uint256);

    function checkpoint_token() external;

    function checkpoint_total_supply() external;

    function recover_balance(address token) external;

    function kill_me() external;

    function emergency_return() external returns (address);
}

interface ILiquidityGauge {
    struct Reward {
        address token;
        address distributor;
        uint256 period_finish;
        uint256 rate;
        uint256 last_update;
        uint256 integral;
    }

    // solhint-disable-next-line
    function deposit_reward_token(address _rewardToken, uint256 _amount) external;

    // solhint-disable-next-line
    function claim_rewards_for(address _user, address _recipient) external;

    function working_balances(address _address) external view returns (uint256);

    // // solhint-disable-next-line
    // function claim_rewards_for(address _user) external;

    // solhint-disable-next-line
    function deposit(uint256 _value, address _addr) external;

    // solhint-disable-next-line
    function reward_tokens(uint256 _i) external view returns (address);

    // solhint-disable-next-line
    function reward_data(address _tokenReward) external view returns (Reward memory);

    function reward_count() external view returns (uint256);

    function balanceOf(address) external returns (uint256);

    function claimable_reward(address _user, address _reward_token) external view returns (uint256);

    function claimable_tokens(address _user) external returns (uint256);

    function user_checkpoint(address _user) external returns (bool);

    function commit_transfer_ownership(address) external;

    function claim_rewards(address) external;

    function add_reward(address, address) external;

    function set_claimer(address) external;

    function admin() external view returns (address);

    function set_reward_distributor(address _rewardToken, address _newDistrib) external;

    function initialize(
        address staking_token,
        address admin,
        address SDT,
        address voting_escrow,
        address veBoost_proxy,
        address distributor
    ) external;
}

interface IMultiMerkleStash {
    struct claimParam {
        address token;
        uint256 index;
        uint256 amount;
        bytes32[] merkleProof;
    }

    function isClaimed(address token, uint256 index) external view returns (bool);

    function claim(address token, uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof)
        external;

    function merkleRoot(address _address) external returns (bytes32);

    function claimMulti(address account, claimParam[] calldata claims) external;

    function owner() external view returns (address);

    function updateMerkleRoot(address token, bytes32 _merkleRoot) external;
}

/// @title ClaimRewards
/// @notice Enables to claim rewards from various sources.
abstract contract ClaimRewards {
    ///@notice Claims rewards from a MultiMerkleStash contract.
    ///@param multiMerkleStash MultiMerkleStash contract address.
    ///@param token Token address to claim.
    ///@param index Index of the claim.
    ///@param claimer Claimer address.
    ///@param amount Amount of token to claim.
    ///@param merkleProof Merkle proofs to verify the claim.
    function claimBribes(
        address multiMerkleStash,
        address token,
        uint256 index,
        address claimer,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        if (claimer == Constants.MSG_SENDER) claimer = msg.sender;
        IMultiMerkleStash(multiMerkleStash).claim(token, index, claimer, amount, merkleProof);
    }

    /// @notice Claims multiple rewards from a MultiMerkleStash contract.
    /// @param multiMerkleStash MultiMerkleStash contract address.
    /// @param claimer Claimer address.
    /// @param claims Claims to make.
    function claimBribesMulti(address multiMerkleStash, address claimer, IMultiMerkleStash.claimParam[] calldata claims)
        external
    {
        if (claimer == Constants.MSG_SENDER) claimer = msg.sender;
        IMultiMerkleStash(multiMerkleStash).claimMulti(claimer, claims);
    }

    /// @notice Claims rewards from a FeeDistributor contract.
    /// @param veSDTFeeDistributor FeeDistributor contract address.
    /// @param claimer Claimer address.
    function claimSdFrax3CRV(address veSDTFeeDistributor, address claimer) external {
        if (claimer == Constants.MSG_SENDER) claimer = msg.sender;
        IFeeDistributor(veSDTFeeDistributor).claim(claimer);
    }

    /// @notice Claims rewards from a gauge contract.
    /// @param gauge Gauge contract address.
    /// @param recipient Recipient address.
    function claimGauge(address gauge, address recipient) external {
        _claimGauge(gauge, recipient);
    }

    /// @notice Claims rewards from multiple gauge contracts.
    /// @param gauges Gauge contract addresses.
    /// @param recipient Recipient addresses.
    function claimGaugesMulti(address[] calldata gauges, address recipient) external {
        uint256 length = gauges.length;
        for (uint8 i; i < length;) {
            _claimGauge(gauges[i], recipient);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Implementation of claimGauge.
    function _claimGauge(address gauge, address recipient) internal {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);
        ILiquidityGauge(gauge).claim_rewards_for(msg.sender, recipient);
    }
}

interface ILocker {
    /// @notice Deposit & Lock Token
    /// @dev User needs to approve the contract to transfer the token
    /// @param amount The amount of token to deposit
    /// @param lock Whether to lock the token
    /// @param stake Whether to stake the token
    /// @param recipient User to deposit for
    function deposit(uint256 amount, bool lock, bool stake, address recipient) external;

    /// @notice Deposits all the token of a recipient & locks them based on the options choosen
    /// @dev User needs to approve the contract to transfer Token tokens
    /// @param lock Whether to lock the token
    /// @param stake Whether to stake the token
    /// @param recipient User to deposit for
    function depositAll(bool lock, bool stake, address recipient) external;
}

/// @title LockerDeposit
/// @notice Enables to deposit to a Liquid Locker.
abstract contract LockerDeposit {
    /// @notice Deposits to a Liquid Locker.
    /// @param locker Locker address.
    /// @param token Token address.
    /// @param lock Whether to lock the token.
    /// @param stake Whether to stake the token.
    /// @param underlyingAmount Amount of token to deposit.
    /// @param recipient Recipient address.
    function deposit(address locker, address token, bool lock, bool stake, uint256 underlyingAmount, address recipient)
        external
        payable
    {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        underlyingAmount = TokenUtils._amountIn(underlyingAmount, token);

        TokenUtils._approve(token, locker);
        ILocker(locker).deposit(underlyingAmount, lock, stake, recipient);
    }
}

interface IVault {
    function deposit(address _staker, uint256 _amount, bool _earn) external;
}

/// @title StrategyDeposit
/// @notice Enables to deposit to a Liquid Locker Strategy.
abstract contract StrategyDeposit {
    /// @notice Deposits to a Liquid Locker Strategy.
    /// @param vault Vault address.
    /// @param token Token address.
    /// @param underlyingAmount Amount of token to deposit.
    /// @param recipient Recipient address.
    /// @param earn Whether to deposit assets to Curve Gauge or not. Socialize deposits to save gas.
    function deposit(address vault, address token, uint256 underlyingAmount, address recipient, bool earn)
        external
        payable
    {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        underlyingAmount = TokenUtils._amountIn(underlyingAmount, token);

        TokenUtils._approve(token, vault);
        IVault(vault).deposit(recipient, underlyingAmount, earn);
    }
}

interface IFraxRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external;

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external;
}

/// @title FraxLiquidityProviding
/// @notice Enables to add/remove liquidity to/from the Frax Router.
abstract contract FraxLiquidityProviding {
    /// @notice Frax Router contract address.
    address internal constant FRAX_ROUTER = 0xC14d550632db8592D1243Edc8B95b0Ad06703867;

    /// @notice Adds liquidity to the Frax Router.
    /// @param tokenA Token A address.
    /// @param tokenB Token B address.
    /// @param amountADesired Amount of token A to add.
    /// @param amountBDesired Amount of token B to add.
    /// @param amountAMin Minimum amount of token A to add.
    /// @param amountBMin Minimum amount of token B to add.
    /// @param recipient Recipient address.
    /// @param deadline Deadline timestamp.
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address recipient,
        uint256 deadline
    ) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        amountADesired = TokenUtils._amountIn(amountADesired, tokenA);
        amountBDesired = TokenUtils._amountIn(amountBDesired, tokenB);

        if (amountADesired != 0) TokenUtils._approve(tokenA, FRAX_ROUTER);
        if (amountBDesired != 0) TokenUtils._approve(tokenB, FRAX_ROUTER);

        IFraxRouter(FRAX_ROUTER).addLiquidity(
            tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, recipient, deadline
        );
    }

    /// @notice Removes liquidity from the Frax Router.
    /// @param tokenA Token A address.
    /// @param tokenB Token B address.
    /// @param lpToken LP token address.
    /// @param liquidity Amount of LP token to remove.
    /// @param amountAMin Minimum amount of token A to remove.
    /// @param amountBMin Minimum amount of token B to remove.
    /// @param recipient Recipient address.
    /// @param deadline Deadline timestamp.
    function removeLiquidity(
        address tokenA,
        address tokenB,
        address lpToken,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address recipient,
        uint256 deadline
    ) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        liquidity = TokenUtils._amountIn(liquidity, lpToken);
        if (liquidity != 0) TokenUtils._approve(lpToken, FRAX_ROUTER);

        IFraxRouter(FRAX_ROUTER).removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, recipient, deadline);
    }
}

interface IAngleStableMaster {
    function deposit(uint256 amount, address user, address poolManager) external;

    function withdraw(uint256 amount, address burner, address dest, address poolManager) external;
}

/// @title AngleLiquidityProviding
/// @notice Enables to add/remove liquidity to/from the Angle Stable Master.
abstract contract AngleLiquidityProviding {
    /// @notice Angle Stable Master contract address.
    address internal constant STABLE_MASTER = 0x5adDc89785D75C86aB939E9e15bfBBb7Fc086A87;

    /// @notice Adds liquidity to the Angle Stable Master.
    /// @param token Token address.
    /// @param underlyingAmount Amount of token to add.
    /// @param poolManager Pool manager address.
    /// @param recipient Recipient address.
    function addLiquidity(address token, uint256 underlyingAmount, address poolManager, address recipient) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        underlyingAmount = TokenUtils._amountIn(underlyingAmount, token);
        if (underlyingAmount != 0) TokenUtils._approve(token, STABLE_MASTER);

        IAngleStableMaster(STABLE_MASTER).deposit(underlyingAmount, recipient, poolManager);
    }

    /// @notice Removes liquidity from the Angle Stable Master.
    /// @param lpToken LP token address.
    /// @param underlyingAmount Amount of LP token to remove.
    /// @param poolManager Pool manager address.
    /// @param recipient Recipient address.
    function removeLiquidity(address lpToken, uint256 underlyingAmount, address poolManager, address recipient)
        external
    {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        underlyingAmount = TokenUtils._amountIn(underlyingAmount, lpToken);

        IAngleStableMaster(STABLE_MASTER).withdraw(underlyingAmount, address(this), recipient, poolManager);
    }
}

interface ICurvePool {
    function calc_token_amount(uint256[2] memory _amounts, bool _deposit) external view returns (uint256);

    function calc_token_amount(uint256[3] memory _amounts, bool _deposit) external view returns (uint256);

    function calc_token_amount(uint256[4] memory _amounts, bool _deposit) external view returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external payable;

    function add_liquidity(uint256[3] memory _amounts, uint256 _min_mint_amount) external payable;

    function add_liquidity(uint256[4] memory _amounts, uint256 _min_mint_amount) external payable;

    function remove_liquidity(uint256 _amount, uint256[2] memory min_amounts) external;

    function remove_liquidity(uint256 _amount, uint256[3] memory min_amounts) external;

    function remove_liquidity(uint256 _amount, uint256[4] memory min_amounts) external;

    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_amount) external;

    function admin_fee() external view returns (uint256);

    function coins(uint256 index) external view returns (address);

    function balances(uint256) external view returns (uint256);

    function lp_token() external view returns (address);
}

interface IZapper3CRV {
    function add_liquidity(
        address _pool,
        uint256[4] memory _deposit_amounts,
        uint256 _min_mint_amount,
        address _recipient
    ) external;

    function remove_liquidity(address _pool, uint256 _burn_amount, uint256[4] calldata _min_amounts, address _receiver)
        external;

    function remove_liquidity_one_coin(
        address _pool,
        uint256 _burn_amount,
        int128 index,
        uint256 _min_amounts,
        address _receiver
    ) external;

    function calc_token_amount(address _ppol, uint256[4] memory _amounts, bool _is_deposit)
        external
        view
        returns (uint256);
}

interface IZapperFraxBPCrypto {
    function add_liquidity(
        address _pool,
        uint256[3] memory _deposit_amounts,
        uint256 _min_mint_amount,
        bool _use_eth,
        address _receiver
    ) external payable;

    function remove_liquidity(
        address _pool,
        uint256 _burn_amount,
        uint256[3] calldata _min_amounts,
        bool _use_eth,
        address _receiver
    ) external;

    function remove_liquidity_one_coin(
        address _pool,
        uint256 _burn_amount,
        uint256 i,
        uint256 _min_amount,
        bool _use_eth,
        address _receiver
    ) external;

    function calc_token_amount(address _pool, uint256[3] memory _amounts) external view returns (uint256);

    function calc_withdraw_one_coin(address _pool, uint256 _token_amount, uint256 i) external view returns (uint256);
}

interface IZapperFraxBPStable {
    function add_liquidity(
        address _pool,
        uint256[3] memory _deposit_amounts,
        uint256 _min_mint_amount,
        address _receiver
    ) external;

    function remove_liquidity(address _pool, uint256 _burn_amount, uint256[3] calldata _min_amounts, address _receiver)
        external;

    function remove_liquidity_one_coin(
        address _pool,
        uint256 _burn_amount,
        int128 i,
        uint256 _min_amount,
        address _receiver
    ) external;

    function calc_token_amount(address _pool, uint256[3] memory _amounts, bool _is_deposit)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(address _pool, uint256 _token_amount, int128 i) external view returns (uint256);
}

/// @title CurveLiquidityProviding
/// @notice Enables to add/remove liquidity to/from Curve pools.
abstract contract CurveLiquidityProviding {
    /// @notice Curve 3CRV Zap contract address.
    address internal constant ZAP_THREE_POOL = 0xA79828DF1850E8a3A3064576f380D90aECDD3359;

    /// @notice Curve FraxBP Zap contract address.
    address internal constant ZAP_FRAX_STABLE = 0x08780fb7E580e492c1935bEe4fA5920b94AA95Da;

    /// @notice Curve FraxBP Crypto Zap contract address.
    address internal constant ZAP_FRAX_CRYPTO = 0x5De4EF4879F4fe3bBADF2227D2aC5d0E2D76C895;

    /// @notice Adds liquidity to the Curve 2 pool.
    /// @param pool Curve pool address.
    /// @param tokens Array of token addresses.
    /// @param lpToken LP token address.
    /// @param underlyingAmounts Array of amounts of tokens to add.
    /// @param minMintAmount Minimum amount of LP tokens to mint.
    /// @param recipient Recipient address.
    function addLiquidity(
        address pool,
        address[2] calldata tokens,
        address lpToken,
        uint256[2] memory underlyingAmounts,
        uint256 minMintAmount,
        address recipient
    ) external payable {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        uint256 amountETH;
        for (uint8 i; i < tokens.length;) {
            underlyingAmounts[i] = TokenUtils._amountIn(underlyingAmounts[i], tokens[i]);
            if (tokens[i] == Constants._ETH) amountETH = underlyingAmounts[i];
            else if (underlyingAmounts[i] != 0) TokenUtils._approve(tokens[i], pool);
            unchecked {
                ++i;
            }
        }

        ICurvePool(pool).add_liquidity{value: amountETH}(underlyingAmounts, minMintAmount);
        TokenUtils._transfer(lpToken, recipient, type(uint256).max);
    }

    /// @notice Adds liquidity to the Curve 3 pool.
    /// @param pool Curve pool address.
    /// @param tokens Array of token addresses.
    /// @param lpToken LP token address.
    /// @param underlyingAmounts Array of amounts of tokens to add.
    /// @param minMintAmount Minimum amount of LP tokens to mint.
    /// @param recipient Recipient address.
    function addLiquidity(
        address pool,
        address[3] calldata tokens,
        address lpToken,
        uint256[3] memory underlyingAmounts,
        uint256 minMintAmount,
        address recipient
    ) external payable {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        uint256 amountETH;
        for (uint8 i; i < tokens.length;) {
            underlyingAmounts[i] = TokenUtils._amountIn(underlyingAmounts[i], tokens[i]);
            if (tokens[i] == Constants._ETH) amountETH = underlyingAmounts[i];
            else if (underlyingAmounts[i] != 0) TokenUtils._approve(tokens[i], pool);
            unchecked {
                ++i;
            }
        }

        ICurvePool(pool).add_liquidity{value: amountETH}(underlyingAmounts, minMintAmount);
        TokenUtils._transfer(lpToken, recipient, type(uint256).max);
    }

    /// @notice Adds liquidity to the Curve 4 pool.
    /// @param pool Curve pool address.
    /// @param tokens Array of token addresses.
    /// @param lpToken LP token address.
    /// @param underlyingAmounts Array of amounts of tokens to add.
    /// @param minMintAmount Minimum amount of LP tokens to mint.
    /// @param recipient Recipient address.
    function addLiquidity(
        address pool,
        address[4] calldata tokens,
        address lpToken,
        uint256[4] memory underlyingAmounts,
        uint256 minMintAmount,
        address recipient
    ) external payable {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        uint256 amountETH;
        for (uint8 i; i < tokens.length;) {
            underlyingAmounts[i] = TokenUtils._amountIn(underlyingAmounts[i], tokens[i]);
            if (tokens[i] == Constants._ETH) amountETH = underlyingAmounts[i];
            else if (underlyingAmounts[i] != 0) TokenUtils._approve(tokens[i], pool);
            unchecked {
                ++i;
            }
        }

        ICurvePool(pool).add_liquidity{value: amountETH}(underlyingAmounts, minMintAmount);
        TokenUtils._transfer(lpToken, recipient, type(uint256).max);
    }

    /// @notice Adds liquidity to the Curve 3 pool using FraxBP Stable Zap.
    /// @param pool Curve pool address.
    /// @param tokens Array of token addresses.
    /// @param lpToken LP token address.
    /// @param underlyingAmounts Array of amounts of tokens to add.
    /// @param minMintAmount Minimum amount of LP tokens to mint.
    /// @param recipient Recipient address.
    function addLiquidityFraxStable(
        address pool,
        address[3] calldata tokens,
        address lpToken,
        uint256[3] memory underlyingAmounts,
        uint256 minMintAmount,
        address recipient
    ) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        for (uint8 i; i < tokens.length;) {
            underlyingAmounts[i] = TokenUtils._amountIn(underlyingAmounts[i], tokens[i]);
            if (underlyingAmounts[i] != 0) TokenUtils._approve(tokens[i], ZAP_FRAX_STABLE);
            unchecked {
                ++i;
            }
        }
        IZapperFraxBPStable(ZAP_FRAX_STABLE).add_liquidity(pool, underlyingAmounts, minMintAmount, recipient);
        TokenUtils._transfer(lpToken, recipient, type(uint256).max);
    }

    /// @notice Adds liquidity to the Curve 3 pool using FraxBP Crypto Zap.
    /// @param pool Curve pool address.
    /// @param tokens Array of token addresses.
    /// @param lpToken LP token address.
    /// @param underlyingAmounts Array of amounts of tokens to add.
    /// @param minMintAmount Minimum amount of LP tokens to mint.
    function addLiquidityFraxCrypto(
        address pool,
        address[3] calldata tokens,
        address lpToken,
        uint256[3] memory underlyingAmounts,
        uint256 minMintAmount,
        bool useEth,
        address recipient
    ) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        for (uint8 i; i < tokens.length;) {
            underlyingAmounts[i] = TokenUtils._amountIn(underlyingAmounts[i], tokens[i]);
            if (underlyingAmounts[i] != 0) TokenUtils._approve(tokens[i], ZAP_FRAX_CRYPTO);
            unchecked {
                ++i;
            }
        }
        IZapperFraxBPCrypto(ZAP_FRAX_CRYPTO).add_liquidity(pool, underlyingAmounts, minMintAmount, useEth, recipient);
        TokenUtils._transfer(lpToken, recipient, type(uint256).max);
    }

    /// @notice Adds liquidity to the Curve 3 pool using Curve Zap.
    /// @param pool Curve pool address.
    /// @param tokens Array of token addresses.
    /// @param lpToken LP token address.
    /// @param underlyingAmounts Array of amounts of tokens to add.
    /// @param minMintAmount Minimum amount of LP tokens to mint.
    /// @param recipient Recipient address.
    function addLiquidityThreePool(
        address pool,
        address[4] calldata tokens,
        address lpToken,
        uint256[4] memory underlyingAmounts,
        uint256 minMintAmount,
        address recipient
    ) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        for (uint8 i; i < tokens.length;) {
            underlyingAmounts[i] = TokenUtils._amountIn(underlyingAmounts[i], tokens[i]);
            if (underlyingAmounts[i] != 0) TokenUtils._approve(tokens[i], ZAP_THREE_POOL);
            unchecked {
                ++i;
            }
        }
        IZapper3CRV(ZAP_THREE_POOL).add_liquidity(pool, underlyingAmounts, minMintAmount, recipient);
        TokenUtils._transfer(lpToken, recipient, type(uint256).max);
    }

    /// @notice Removes liquidity from a Curve 2 pool.
    /// @param pool Curve pool address.
    /// @param tokens Array of token addresses.
    /// @param lpToken LP token address.
    /// @param underlyingAmount Amount of LP tokens to remove.
    /// @param minAmounts Array of minimum amounts of tokens to receive.
    /// @param recipient Recipient address.
    function removeLiquidity(
        address pool,
        address[2] calldata tokens,
        address lpToken,
        uint256 underlyingAmount,
        uint256[2] calldata minAmounts,
        address recipient
    ) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        underlyingAmount = TokenUtils._amountIn(underlyingAmount, lpToken);

        ICurvePool(pool).remove_liquidity(underlyingAmount, minAmounts);

        for (uint8 i; i < tokens.length;) {
            TokenUtils._transfer(tokens[i], recipient, type(uint256).max);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Removes liquidity from a Curve 3 pool.
    /// @param pool Curve pool address.
    /// @param tokens Array of token addresses.
    /// @param lpToken LP token address.
    /// @param underlyingAmount Amount of LP tokens to remove.
    /// @param minAmounts Array of minimum amounts of tokens to receive.
    /// @param recipient Recipient address.
    function removeLiquidity(
        address pool,
        address[3] calldata tokens,
        address lpToken,
        uint256 underlyingAmount,
        uint256[3] calldata minAmounts,
        address recipient
    ) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        underlyingAmount = TokenUtils._amountIn(underlyingAmount, lpToken);

        ICurvePool(pool).remove_liquidity(underlyingAmount, minAmounts);

        for (uint8 i; i < tokens.length;) {
            TokenUtils._transfer(tokens[i], recipient, type(uint256).max);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Removes liquidity from a Curve 4 pool.
    /// @param pool Curve pool address.
    /// @param tokens Array of token addresses.
    /// @param lpToken LP token address.
    /// @param underlyingAmount Amount of LP tokens to remove.
    /// @param minAmounts Array of minimum amounts of tokens to receive.
    /// @param recipient Recipient address.
    function removeLiquidity(
        address pool,
        address[4] calldata tokens,
        address lpToken,
        uint256 underlyingAmount,
        uint256[4] calldata minAmounts,
        address recipient
    ) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        underlyingAmount = TokenUtils._amountIn(underlyingAmount, lpToken);

        ICurvePool(pool).remove_liquidity(underlyingAmount, minAmounts);

        for (uint8 i; i < tokens.length;) {
            TokenUtils._transfer(tokens[i], recipient, type(uint256).max);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Removes liquidity from a Curve pool into a single token.
    /// @param pool Curve pool address.
    /// @param index Index of the token to receive.
    /// @param lpToken LP token address.
    /// @param underlyingAmount Amount of LP tokens to remove.
    /// @param minAmount Minimum amount of tokens to receive.
    /// @param recipient Recipient address.
    function removeLiquidityOneCoin(
        address pool,
        int128 index,
        address lpToken,
        uint256 underlyingAmount,
        uint256 minAmount,
        address recipient
    ) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        underlyingAmount = TokenUtils._amountIn(underlyingAmount, lpToken);

        ICurvePool(pool).remove_liquidity_one_coin(underlyingAmount, index, minAmount);

        address token = ICurvePool(pool).coins(uint8(int8(index)));
        TokenUtils._transfer(token, recipient, type(uint256).max);
    }

    /// @notice Removes liquidity from FraxBP stable pool.
    /// @param pool Curve pool address.
    /// @param lpToken LP token address.
    /// @param underlyingAmount Amount of LP tokens to remove.
    /// @param minAmounts Array of minimum amounts of tokens to receive.
    /// @param recipient Recipient address.
    function removeLiquidityFraxStable(
        address pool,
        address lpToken,
        uint256 underlyingAmount,
        uint256[3] calldata minAmounts,
        address recipient
    ) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        underlyingAmount = TokenUtils._amountIn(underlyingAmount, lpToken);
        TokenUtils._approve(lpToken, ZAP_FRAX_STABLE);

        IZapperFraxBPStable(ZAP_FRAX_STABLE).remove_liquidity(pool, underlyingAmount, minAmounts, recipient);
    }

    /// @notice Removes liquidity from FraxBP stable pool into a single token.
    /// @param pool Curve pool address.
    /// @param index Index of the token to receive.
    /// @param lpToken LP token address.
    /// @param underlyingAmount Amount of LP tokens to remove.
    /// @param minAmount Minimum amount of tokens to receive.
    /// @param recipient Recipient address.
    function removeLiquidityFraxStableOneCoin(
        address pool,
        int128 index,
        address lpToken,
        uint256 underlyingAmount,
        uint256 minAmount,
        address recipient
    ) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        underlyingAmount = TokenUtils._amountIn(underlyingAmount, lpToken);
        TokenUtils._approve(lpToken, ZAP_FRAX_STABLE);

        IZapperFraxBPStable(ZAP_FRAX_STABLE).remove_liquidity_one_coin(
            pool, underlyingAmount, index, minAmount, recipient
        );
    }

    /// @notice Removes liquidity from FraxBP crypto pool.
    /// @param pool Curve pool address.
    /// @param lpToken LP token address.
    /// @param underlyingAmount Amount of LP tokens to remove.
    /// @param minAmounts Array of minimum amounts of tokens to receive.
    /// @param useEth Whether to use ETH or WETH.
    /// @param recipient Recipient address.
    function removeLiquidityFraxCrypto(
        address pool,
        address lpToken,
        uint256 underlyingAmount,
        uint256[3] calldata minAmounts,
        bool useEth,
        address recipient
    ) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        underlyingAmount = TokenUtils._amountIn(underlyingAmount, lpToken);
        TokenUtils._approve(lpToken, ZAP_FRAX_CRYPTO);

        IZapperFraxBPCrypto(ZAP_FRAX_CRYPTO).remove_liquidity(pool, underlyingAmount, minAmounts, useEth, recipient);
    }

    /// @notice Removes liquidity from FraxBP crypto pool into a single token.
    /// @param pool Curve pool address.
    /// @param index Index of the token to receive.
    /// @param lpToken LP token address.
    /// @param underlyingAmount Amount of LP tokens to remove.
    /// @param minAmount Minimum amount of tokens to receive.
    /// @param useEth Whether to use ETH or WETH.
    /// @param recipient Recipient address.
    function removeLiquidityFraxCryptoOneCoin(
        address pool,
        uint256 index,
        address lpToken,
        uint256 underlyingAmount,
        uint256 minAmount,
        bool useEth,
        address recipient
    ) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        underlyingAmount = TokenUtils._amountIn(underlyingAmount, lpToken);
        TokenUtils._approve(lpToken, ZAP_FRAX_CRYPTO);

        IZapperFraxBPCrypto(ZAP_FRAX_CRYPTO).remove_liquidity_one_coin(
            pool, underlyingAmount, index, minAmount, useEth, recipient
        );
    }

    /// @notice Removes liquidity from 3CRV pool.
    /// @param pool Curve pool address.
    /// @param lpToken LP token address.
    /// @param underlyingAmount Amount of LP tokens to remove.
    /// @param minAmounts Array of minimum amounts of tokens to receive.
    /// @param recipient Recipient address.
    function removeLiquidityThreePool(
        address pool,
        address lpToken,
        uint256 underlyingAmount,
        uint256[4] calldata minAmounts,
        address recipient
    ) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        underlyingAmount = TokenUtils._amountIn(underlyingAmount, lpToken);
        TokenUtils._approve(lpToken, ZAP_THREE_POOL);

        IZapper3CRV(ZAP_THREE_POOL).remove_liquidity(pool, underlyingAmount, minAmounts, recipient);
    }

    /// @notice Removes liquidity from 3CRV pool into a single token.
    /// @param pool Curve pool address.
    /// @param index Index of the token to receive.
    /// @param lpToken LP token address.
    /// @param underlyingAmount Amount of LP tokens to remove.
    /// @param minAmount Minimum amount of tokens to receive.
    /// @param recipient Recipient address.
    function removeLiquidityThreePoolOneCoin(
        address pool,
        int128 index,
        address lpToken,
        uint256 underlyingAmount,
        uint256 minAmount,
        address recipient
    ) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        underlyingAmount = TokenUtils._amountIn(underlyingAmount, lpToken);
        TokenUtils._approve(lpToken, ZAP_THREE_POOL);

        IZapper3CRV(ZAP_THREE_POOL).remove_liquidity_one_coin(pool, underlyingAmount, index, minAmount, recipient);
    }
}

interface IBalancerVault {
    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    struct ExitPoolRequest {
        address[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    function joinPool(bytes32 _poolId, address _sender, address _recipient, JoinPoolRequest memory _request)
        external
        payable;

    function exitPool(bytes32 poolId, address sender, address recipient, ExitPoolRequest memory request)
        external
        payable;

    enum JoinKind {
        INIT,
        EXACT_TOKENS_IN_FOR_BPT_OUT,
        TOKEN_IN_FOR_EXACT_BPT_OUT,
        ALL_TOKENS_IN_FOR_EXACT_BPT_OUT
    }

    enum ExitKind {
        EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
        BPT_IN_FOR_EXACT_TOKENS_OUT,
        EXACT_BPT_IN_FOR_ALL_TOKENS_OUT
    }
}

/// @title BalancerLiquidityProviding
/// @notice Enables to add/remove liquidity to/from the Balancer Vault.
abstract contract BalancerLiquidityProviding {
    /// @notice Balancer Vault contract address.
    address internal constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    /// @notice Adds liquidity to the Balancer Vault.
    /// @param poolId Pool ID.
    /// @param tokens Tokens addresses.
    /// @param underlyingAmounts Amounts of tokens to add.
    /// @param userData User data.
    /// @param recipient Recipient address.
    function addLiquidity(
        bytes32 poolId,
        address[] calldata tokens,
        uint256[] memory underlyingAmounts,
        bytes calldata userData,
        address recipient
    ) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        for (uint8 i; i < tokens.length;) {
            underlyingAmounts[i] = TokenUtils._amountIn(underlyingAmounts[i], tokens[i]);
            if (underlyingAmounts[i] != 0) TokenUtils._approve(tokens[i], BALANCER_VAULT);
            unchecked {
                ++i;
            }
        }

        IBalancerVault.JoinPoolRequest memory pr =
            IBalancerVault.JoinPoolRequest(tokens, underlyingAmounts, userData, false);
        IBalancerVault(BALANCER_VAULT).joinPool(poolId, address(this), recipient, pr);
    }

    /// @notice Removes liquidity from the Balancer Vault.
    /// @param poolId Pool ID.
    /// @param tokens Tokens addresses.
    /// @param lpToken LP token address.
    /// @param underlyingAmount Amount of LP token to remove.
    /// @param minAmountsOut Minimum amounts of tokens to receive.
    /// @param userData User data.
    /// @param recipient Recipient address.
    function removeLiquidty(
        bytes32 poolId,
        address[] calldata tokens,
        address lpToken,
        uint256 underlyingAmount,
        uint256[] calldata minAmountsOut,
        bytes calldata userData,
        address recipient
    ) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        underlyingAmount = TokenUtils._amountIn(underlyingAmount, lpToken);

        IBalancerVault.ExitPoolRequest memory pr =
            IBalancerVault.ExitPoolRequest(tokens, minAmountsOut, userData, false);
        IBalancerVault(BALANCER_VAULT).exitPool(poolId, address(this), recipient, pr);
    }
}

/// @title Router
abstract contract Router is
    Permitter,
    Aggregators,
    ClaimRewards,
    LockerDeposit,
    StrategyDeposit,
    FraxLiquidityProviding,
    AngleLiquidityProviding,
    CurveLiquidityProviding,
    BalancerLiquidityProviding
{}

/// @title LiquidRouter.
/// @notice Enables to execute multiple actions in a single transaction.
/// @author Stake DAO.
contract LiquidRouter is Router {
    /// @notice Checks if timestamp is not expired
    modifier checkDeadline(uint256 deadline) {
        if (block.timestamp > deadline) revert Constants.DEADLINE_EXCEEDED();
        _;
    }

    /// @dev Apply `DELEGATECALL` with the current contract to each calldata in `data`,
    /// and store the `abi.encode` formatted results of each `DELEGATECALL` into `results`.
    /// If any of the `DELEGATECALL`s reverts, the entire transaction is reverted,
    /// and the error is bubbled up.
    function multicall(uint256 deadline, bytes[] calldata data)
        external
        payable
        checkDeadline(deadline)
        returns (bytes[] memory results)
    {
        assembly {
            if data.length {
                results := mload(0x40) // Point `results` to start of free memory.
                mstore(results, data.length) // Store `data.length` into `results`.
                results := add(results, 0x20)

                // `shl` 5 is equivalent to multiplying by 0x20.
                let end := shl(5, data.length)
                // Copy the offsets from calldata into memory.
                calldatacopy(results, data.offset, end)
                // Pointer to the top of the memory (i.e. start of the free memory).
                let memPtr := add(results, end)
                end := add(results, end)

                for {} 1 {} {
                    // The offset of the current bytes in the calldata.
                    let o := add(data.offset, mload(results))
                    // Copy the current bytes from calldata to the memory.
                    calldatacopy(
                        memPtr,
                        add(o, 0x20), // The offset of the current bytes' bytes.
                        calldataload(o) // The length of the current bytes.
                    )
                    if iszero(delegatecall(gas(), address(), memPtr, calldataload(o), 0x00, 0x00)) {
                        // Bubble up the revert if the delegatecall reverts.
                        returndatacopy(0x00, 0x00, returndatasize())
                        revert(0x00, returndatasize())
                    }
                    // Append the current `memPtr` into `results`.
                    mstore(results, memPtr)
                    results := add(results, 0x20)
                    // Append the `returndatasize()`, and the return data.
                    mstore(memPtr, returndatasize())
                    returndatacopy(add(memPtr, 0x20), 0x00, returndatasize())
                    // Advance the `memPtr` by `returndatasize() + 0x20`,
                    // rounded up to the next multiple of 32.
                    memPtr := and(add(add(memPtr, returndatasize()), 0x3f), 0xffffffffffffffe0)
                    if iszero(lt(results, end)) { break }
                }
                // Restore `results` and allocate memory for it.
                results := mload(0x40)
                mstore(0x40, memPtr)
            }
        }
    }
}