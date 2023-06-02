// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "./access/Governable.sol";
import "./interfaces/ICurvePool.sol";
import "./interfaces/ILido.sol";
import "./interfaces/IWETH9.sol";

/**
 * @title YiqiTreasury
 * @notice This contract is used to manage the Yiqi treasury
 * @dev All ETH it receives is converted to stETH and deposited into the Lido stETH pool
 * @dev The stETH is then redistributed among the NFT holders, rewarding late burners with extra stETH
 */
contract YiqiTreasury is Governable {
    address internal s_yiqi;

    ILido internal immutable i_stETH;

    IWETH9 internal immutable i_WETH;

    ICurvePool internal immutable i_curveEthStEthPool;

    uint256 internal s_numOutstandingNFTs;

    address internal s_teamMultisig;

    uint256 internal immutable i_deployedTime;

    uint8 internal s_numTeamWithdrawsPerformed;

    address internal constant RESERVES = 0x97990B693835da58A281636296D2Bf02787DEa17;

    modifier onlyYiqi() {
        require(msg.sender == s_yiqi, "YiqiTreasury: Only Yiqi can call this function.");
        _;
    }

    constructor(
        address _yiqi,
        ILido _stETH,
        IWETH9 _WETH,
        ICurvePool _curveEthStEthPool,
        address _yamGovernance,
        address _teamMultisig
    ) {
        s_yiqi = _yiqi;
        i_stETH = _stETH;
        i_WETH = _WETH;
        i_curveEthStEthPool = _curveEthStEthPool;
        i_deployedTime = block.timestamp;
        s_teamMultisig = _teamMultisig;
        _setGov(_yamGovernance);
    }

    /////////////////////////////////////////////////
    ///             OnlyYiqi functions              ///
    /////////////////////////////////////////////////

    /**
     * @dev Deposits ETH into Lido's contract and then deposits the wstETH into the Uniswap position
     * @dev Stores the liquidity amount in a YiqiTokenNFT mapping and returns the amount of wstETH received
     * @return The amount of stETH received
     */
    function depositETHFromMint() external payable onlyYiqi returns (uint256) {
        s_numOutstandingNFTs++;

        // Deposit ETH into Lido and receive stETH
        uint256 stETHAmount = depositETHForStETH(msg.value);

        return stETHAmount;
    }

    /**
     * @dev Swaps stETH for ETH and returns the amount received
     * @param receiver The address of the owner of the NFT who will receive the funds
     * @param minAmountOut The minimum amount of ETH to receive from the burn
     */
    function withdrawByYiqiBurned(address receiver, uint256 minAmountOut) external onlyYiqi returns (uint256 ethAmount) {
        uint256 reclaimableStETH = calculateReclaimableStETHFromBurn();

        s_numOutstandingNFTs--;

        swapStETHForETH(reclaimableStETH, minAmountOut);

        ethAmount = address(this).balance;
        TransferHelper.safeTransferETH(receiver, ethAmount);
    }

    receive() external payable {
        if (msg.sender != address(i_curveEthStEthPool)) depositETHForStETH(msg.value);
    }

    /////////////////////////////////////////////////
    ///             OnlyGov functions             ///
    /////////////////////////////////////////////////

    /**
     * @notice Withdraws 2% of the StETH balance to the team multisig and yam governance reserves
     * @dev Can only be called every 6 months
     * @param minAmountOut The minimum amount of ETH to receive from the swap from the 2% of stETH
     */
    function withdrawTeamAndTreasuryFee(uint256 minAmountOut) external onlyGov {
        require(
            block.timestamp >=
            i_deployedTime + (6 * 30 days) * uint256(s_numTeamWithdrawsPerformed + 1),
            "YiqiTreasury: Can only withdraw every 6 months"
        );
        s_numTeamWithdrawsPerformed++;

        uint256 stETHAmount = i_stETH.balanceOf(address(this));
        uint256 withdrawableStETHAmount = (stETHAmount * 2) / 100;

        swapStETHForETH(withdrawableStETHAmount, minAmountOut);

        i_WETH.deposit{value: address(this).balance}();

        uint256 wethAmount = i_WETH.balanceOf(address(this));

        uint256 wethFeeAmount = wethAmount / 2;

        TransferHelper.safeTransfer(address(i_WETH), s_teamMultisig, wethFeeAmount);
        TransferHelper.safeTransfer(address(i_WETH), RESERVES, wethFeeAmount);
    }

    /**
     * @notice Sets the Yiqi address
     * @param _yiqi The address of the Yiqi contract
     */
    function setYiqi(address _yiqi) external onlyGov {
        s_yiqi = _yiqi;
    }

    /**
     * @notice Sets the team multisig address
     * @param _teamMultisig The address of the team multisig
     */
    function setTeamMultisig(address _teamMultisig) external onlyGov {
        s_teamMultisig = _teamMultisig;
    }

    /**
     * @notice Removes all liquidity
     * @dev Emergency function - can only be called by governance
     * @param receiver The address of the owner of the NFT who will receive the funds
     */
    function removeLiquidity(address receiver) external onlyGov {
        TransferHelper.safeTransfer(address(i_stETH), receiver, i_stETH.balanceOf(address(this)));
    }

    /////////////////////////////////////////////////
    ///                Getters                    ///
    /////////////////////////////////////////////////

    /**
     * @notice Calculates the amount of stETH that can be reclaimed from the treasury by burning 1 Yiqi NFT
     * @return reclaimableStETH The amount of stETH that can be reclaimed
     */
    function calculateReclaimableStETHFromBurn() public view returns (uint256 reclaimableStETH) {
        uint256 stETHAmount = i_stETH.balanceOf(address(this)) / s_numOutstandingNFTs;

        // Retain 5% of the stETH for the treasury
        reclaimableStETH = (stETHAmount * 95) / 100;
    }

    /**
     * @notice Returns the amount of NFTs left that can be burnt
     * @return The amount of burnable Yiqi NFTs
     */
    function getNumOutstandingNFTs() external view returns (uint256) {
        return s_numOutstandingNFTs;
    }

    /////////////////////////////////////////////////
    ///           Internal functions              ///
    /////////////////////////////////////////////////

    /**
     * @dev Deposits ETH into Lido's contract and returns the amount of stETH received
     * @param amount The amount to deposit in Lido's stETH contract
     * @return The amount of stETH received
     */
    function depositETHForStETH(uint256 amount) internal returns (uint256) {
        i_stETH.submit{value: amount}(address(0));
        return i_stETH.balanceOf(address(this));
    }

    /**
     * @dev Swaps stETH for ETH and returns the amount received
     * @dev Uses sushiswap router
     * @param stETHAmount The amount of stETH to swap
     * @param minAmountOut The minimum amount of ETH to receive
     */
    function swapStETHForETH(uint256 stETHAmount, uint256 minAmountOut) internal {
        i_stETH.approve(address(i_curveEthStEthPool), stETHAmount);
        i_curveEthStEthPool.exchange(1, 0, stETHAmount, minAmountOut);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract Governable {
    address public gov;

    constructor() {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }

    function _setGov(address _gov) internal {
        gov = _gov;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface ICurvePool {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external payable;

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        bool use_eth
    ) external payable;

    function coins(uint256 i) external view returns (address);
}

interface ICurvePool2 {
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external payable;

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        bool use_eth
    ) external payable;
}

// SPDX-FileCopyrightText: 2020 Lido <[email protected]>

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Liquid staking pool
 *
 * For the high-level description of the pool operation please refer to the paper.
 * Pool manages withdrawal keys and fees. It receives ether submitted by users on the ETH 1 side
 * and stakes it via the deposit_contract.sol contract. It doesn't hold ether on it's balance,
 * only a small portion (buffer) of it.
 * It also mints new tokens for rewards generated at the ETH 2.0 side.
 *
 * At the moment withdrawals are not possible in the beacon chain and there's no workaround.
 * Pool will be upgraded to an actual implementation when withdrawals are enabled
 * (Phase 1.5 or 2 of Eth2 launch, likely late 2022 or 2023).
 */
interface ILido is IERC20 {
    // User functions

    /**
     * @notice Adds eth to the pool
     * @return StETH Amount of StETH generated
     */
    function submit(address _referral) external payable returns (uint256 StETH);

    // Records a deposit made by a user
    event Submitted(address indexed sender, uint256 amount, address referral);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}