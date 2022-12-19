/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

interface IDSProxy {
    function owner() external view returns (address);
    function setCache(address _cacheAddr) external payable returns (bool);
    function execute(address _target, bytes memory _data) external payable returns (bytes32);
}

/// @notice Constants used in Morphous.
library Constants {
    /// @notice ETH address.
    address internal constant _ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice sETH address.
    address internal constant _stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    /// @notice cETH address.
    address internal constant _cETHER = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

    /// @notice WETH address.
    address internal constant _WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// @notice The address of Morpho Aave markets.
    address internal constant _MORPHO_AAVE = 0x777777c9898D384F785Ee44Acfe945efDFf5f3E0;

    /// @notice Address of Aave Lending Pool contract.
    address internal constant _AAVE_LENDING_POOL = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;

    /// @notice Address of Balancer contract.
    address internal constant _BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    /// @notice The address of Morpho Compound markets.
    address internal constant _MORPHO_COMPOUND = 0x8888882f8f843896699869179fB6E4f7e3B58888;

    /// @notice Address of Factory Guard contract.
    address internal constant _FACTORY_GUARD_ADDRESS = 0x5a15566417e6C1c9546523066500bDDBc53F88C7;

    /////////////////////////////////////////////////////////////////
    /// --- ERRORS
    ////////////////////////////////////////////////////////////////

    /// @dev Error message when the caller is not allowed to call the function.
    error NOT_ALLOWED();

    /// @dev Error message when the caller is not allowed to call the function.
    error INVALID_LENDER();

    /// @dev Error message when the caller is not allowed to call the function.
    error INVALID_INITIATOR();

    /// @dev Error message when the market is invalid.
    error INVALID_MARKET();

    /// @dev Error message when the market is invalid.
    error INVALID_AGGREGATOR();

    /// @dev Error message when the deadline has passed.
    error DEADLINE_EXCEEDED();

    /// @dev Error message for when the amount of received tokens is less than the minimum amount.
    error NOT_ENOUGH_RECEIVED();
}

interface IWETH {
    function allowance(address, address) external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function approve(address, uint256) external;

    function transfer(address, uint256) external returns (bool);

    function transferFrom(address, address, uint256) external returns (bool);

    function deposit() external payable;

    function withdraw(uint256) external;
}

interface ILido {
    function submit(address _referral) external payable;
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

library TokenUtils {
    using SafeTransferLib for ERC20;

    function _approve(address _token, address _to, uint256 _amount) internal {
        if (_token == Constants._ETH) return;

        if (ERC20(_token).allowance(address(this), _to) < _amount || _amount == 0) {
            ERC20(_token).safeApprove(_to, _amount);
        }
    }

    function _transferFrom(address _token, address _from, uint256 _amount) internal returns (uint256) {
        if (_amount == type(uint256).max) {
            _amount = _balanceInOf(_token, _from);
        }

        if (_from != address(0) && _from != address(this) && _token != Constants._ETH && _amount != 0) {
            ERC20(_token).safeTransferFrom(_from, address(this), _amount);

            return _amount;
        }

        return 0;
    }

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

    function _depositSTETH(uint256 _amount) internal {
        ILido(Constants._stETH).submit{value: _amount}(address(this));
    }

    function _depositWETH(uint256 _amount) internal {
        IWETH(Constants._WETH).deposit{value: _amount}();
    }

    function _withdrawWETH(uint256 _amount) internal {
        uint256 _balance = _balanceInOf(Constants._WETH, address(this));

        if (_amount > _balance) {
            _amount = _balance;
        }

        IWETH(Constants._WETH).withdraw(_amount);
    }

    function _balanceInOf(address _token, address _acc) internal view returns (uint256) {
        if (_token == Constants._ETH) {
            return _acc.balance;
        } else {
            return ERC20(_token).balanceOf(_acc);
        }
    }
}

abstract contract TokenActions {
    using SafeTransferLib for ERC20;

    function approveToken(address _token, address _to, uint256 _amount) external {
        TokenUtils._approve(_token, _to, _amount);
    }

    function transferFrom(address _token, address _from, uint256 _amount) external returns (uint256) {
        return TokenUtils._transferFrom(_token, _from, _amount);
    }

    function transfer(address _token, address _to, uint256 _amount) external returns (uint256) {
        return TokenUtils._transfer(_token, _to, _amount);
    }

    function depositSTETH(uint256 _amount) external {
        TokenUtils._depositSTETH(_amount);
    }

    function depositWETH(uint256 _amount) external {
        TokenUtils._depositWETH(_amount);
    }

    function withdrawWETH(uint256 _amount) external {
        TokenUtils._withdrawWETH(_amount);
    }

    function balanceInOf(address _token, address _acc) public view returns (uint256) {
        return TokenUtils._balanceInOf(_token, _acc);
    }
}

/// @notice Contract that allows to swap tokens through different aggregators.
abstract contract Aggregators {
    using SafeTransferLib for ERC20;

    /// @notice Error when swap fails.
    error SWAP_FAILED();

    /// @notice AugustusSwapper contract address.
    address public constant AUGUSTUS = 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;

    /// @notice 1nch Router v5 contract address.
    address public constant INCH_ROUTER = 0x1111111254EEB25477B68fb85Ed929f73A960582;

    /// @notice Paraswap Token pull contract address.
    address public constant TOKEN_TRANSFER_PROXY = 0x216B4B4Ba9F3e719726886d34a177484278Bfcae;

    event ExchangeAggregator(address _tokenFrom, address _tokenTo, uint256 _amountFrom, uint256 _amountTo);

    modifier onlyValidAggregator(address _aggregator) {
        if (_aggregator != AUGUSTUS && _aggregator != INCH_ROUTER) revert Constants.INVALID_AGGREGATOR();
        _;
    }

    function exchange(
        address aggregator,
        address srcToken,
        address destToken,
        uint256 underlyingAmount,
        bytes memory callData
    ) external payable onlyValidAggregator(aggregator) returns (uint256 received) {
        bool success;
        uint256 before = destToken == Constants._ETH ? address(this).balance : ERC20(destToken).balanceOf(address(this));

        if (srcToken == Constants._ETH) {
            (success,) = aggregator.call{value: underlyingAmount}(callData);
        } else {
            TokenUtils._approve(srcToken, aggregator == AUGUSTUS ? TOKEN_TRANSFER_PROXY : INCH_ROUTER, underlyingAmount);
            (success,) = aggregator.call(callData);
        }
        if (!success) revert SWAP_FAILED();

        if (destToken == Constants._ETH) {
            received = address(this).balance - before;
        } else {
            received = ERC20(destToken).balanceOf(address(this)) - before;
        }

        emit ExchangeAggregator(srcToken, destToken, underlyingAmount, received);
    }
}

interface IMorpho {
    function supply(address _poolToken, uint256 _amount) external;
    function supply(address _poolToken, address _onBehalf, uint256 _amount) external;
    function supply(address _poolToken, address _onBehalf, uint256 _amount, uint256 _maxGasForMatching) external;

    function withdraw(address _poolToken, uint256 _amount) external;
    function withdraw(address _poolToken, uint256 _amount, address _receiver) external;

    function borrow(address _poolToken, uint256 _amount) external;
    function borrow(address _poolToken, uint256 _maxGasForMatching, uint256 _amount) external;

    function repay(address _poolToken, address _onBehalf, uint256 _amount) external;

    function claimRewards(address[] calldata _poolTokens, bool _tradeForMorphoToken) external returns (uint256);
}

interface ICToken {
    function underlying() external view returns (address);
}

interface IPoolToken {
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

/// @notice Supply a token to an MorphoRouter-Aave or MorphoRouter-Compound _market.
/// @author @Mutative_
abstract contract MorphoCore {
    modifier onlyValidMarket(address _market) {
        if (_market != Constants._MORPHO_AAVE && _market != Constants._MORPHO_COMPOUND) {
            revert Constants.INVALID_MARKET();
        }
        _;
    }

    function _getToken(address _market, address _poolToken) internal view returns (address) {
        if (_market == Constants._MORPHO_AAVE) return IPoolToken(_poolToken).UNDERLYING_ASSET_ADDRESS();
        else if (_market == Constants._MORPHO_COMPOUND && _poolToken == Constants._cETHER) return Constants._WETH;
        else if (_market == Constants._MORPHO_COMPOUND) return ICToken(_poolToken).underlying();
        else revert Constants.INVALID_MARKET();
    }
}

/// @notice Borrow a token from a MorphoRouter-Aave or MorphoRouter-Compound _market.
/// @author @Mutative_
abstract contract MorphoBorrowRepay is MorphoCore {
    event Borrowed(address indexed token, uint256 amount);
    event BorrowedWithMaxGas(address indexed token, uint256 amount, uint256 maxGas);

    event Repaid(address indexed token, address onBehalf, uint256 amount);

    function borrow(address _market, address _poolToken, uint256 _amount) external onlyValidMarket(_market) {
        address _token = _getToken(_market, _poolToken);
        IMorpho(_market).borrow(_poolToken, _amount);

        emit Borrowed(_token, _amount);
    }

    function borrow(address _market, address _poolToken, uint256 _amount, uint256 _maxGasForMatching)
        external
        onlyValidMarket(_market)
    {
        address _token = _getToken(_market, _poolToken);
        IMorpho(_market).borrow(_poolToken, _amount, _maxGasForMatching);

        emit BorrowedWithMaxGas(_token, _amount, _maxGasForMatching);
    }

    function repay(address _market, address _poolToken, address _onBehalf, uint256 _amount)
        external
        onlyValidMarket(_market)
    {
        address _token = _getToken(_market, _poolToken);

        TokenUtils._approve(_token, _market, _amount);
        IMorpho(_market).repay(_poolToken, _onBehalf, _amount);

        emit Repaid(_token, _onBehalf, _amount);
    }
}

interface IRewardsDistributor {
    function claim(address _account, uint256 _claimable, bytes32[] calldata _proof) external;
}

abstract contract MorphoClaimRewards is MorphoCore {
    /// @notice Rewards Distributor to claim $MORPHO token.
    address internal constant _REWARDS_DISTRIBUTOR = 0x3B14E5C73e0A56D607A8688098326fD4b4292135;

    event RewardClaimed(uint256 _claimable);
    event MorphoClaimed(address _account, uint256 _claimable);

    function claim(address _account, uint256 _claimable, bytes32[] calldata _proof) external {
        IRewardsDistributor(_REWARDS_DISTRIBUTOR).claim(_account, _claimable, _proof);

        emit MorphoClaimed(_account, _claimable);
    }

    function claim(address _market, address[] calldata _poolTokens, bool _tradeForMorphoToken)
        external
        onlyValidMarket(_market)
    {
        uint256 _claimed = IMorpho(_market).claimRewards(_poolTokens, _tradeForMorphoToken);

        emit RewardClaimed(_claimed);
    }
}

/// @notice Supply a token to an MorphoRouter-Aave or MorphoRouter-Compound _market.
/// @author @Mutative_
abstract contract MorphoSupplyWithdraw is MorphoCore {
    using SafeTransferLib for ERC20;

    event SuppliedOnBehalf(address indexed token, uint256 amount, address indexed onBehalfOf);
    event SuppliedWithMaxGas(address indexed token, uint256 amount, address indexed onBehalOf, uint256 maxGas);

    event Withdrawn(address indexed token, uint256 amount);

    function supply(address _market, address _poolToken, address _onBehalf, uint256 _amount)
        external
        onlyValidMarket(_market)
    {
        address _token = _getToken(_market, _poolToken);

        TokenUtils._approve(_token, _market, _amount);
        IMorpho(_market).supply(_poolToken, _onBehalf, _amount);

        emit SuppliedOnBehalf(_poolToken, _amount, _onBehalf);
    }

    function supply(address _market, address _poolToken, address _onBehalf, uint256 _amount, uint256 _maxGasForMatching)
        external
        onlyValidMarket(_market)
    {
        address _token = _getToken(_market, _poolToken);

        TokenUtils._approve(_token, _market, _amount);
        IMorpho(_market).supply(_poolToken, _onBehalf, _amount, _maxGasForMatching);

        emit SuppliedWithMaxGas(_poolToken, _amount, _onBehalf, _maxGasForMatching);
    }

    function withdraw(address _market, address _poolToken, uint256 _amount) external onlyValidMarket(_market) {
        IMorpho(_market).withdraw(_poolToken, _amount);

        emit Withdrawn(_poolToken, _amount);
    }
}

/// @notice Morpho Router.
/// @author @Mutative_
abstract contract MorphoRouter is Aggregators, MorphoBorrowRepay, MorphoClaimRewards, MorphoSupplyWithdraw {}

/// @title Morphous
/// @notice Allows interaction with the Morpho protocol for DSProxy or any delegateCall type contract.
/// @author @Mutative_
contract Morphous is MorphoRouter, TokenActions {
    /// @notice Address of this contract.
    address public immutable _MORPHEUS;

    /// @notice Checks if timestamp is not expired
    /// @param deadline Timestamp to not be expired.
    modifier checkDeadline(uint256 deadline) {
        if (block.timestamp > deadline) revert Constants.DEADLINE_EXCEEDED();
        _;
    }

    constructor() {
        _MORPHEUS = address(this);
    }

    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @param deadline The time by which this function must be called before failing
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(uint256 deadline, bytes[] calldata data)
        public
        payable
        checkDeadline(deadline)
        returns (bytes32[] memory results)
    {
        results = new bytes32[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = IDSProxy(address(this)).execute(_MORPHEUS, data[i]);
        }
    }

    receive() external payable {}
}