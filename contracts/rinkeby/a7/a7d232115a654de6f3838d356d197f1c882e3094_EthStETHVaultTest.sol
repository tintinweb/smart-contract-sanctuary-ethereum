//SPDX-License-Identifier: MIT
//
///@notice The EthStETHVault contract stakes ETH tokens into stETH on Ethereum.
///@dev https://docs.polkadot.lido.fi/fundamentals/liquid-staking
//
pragma solidity  0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../BasicStVaultTest.sol";
import "../../bni/constant/EthConstantTest.sol";
import "../../../libs/Const.sol";

contract EthStETHVaultTest is BasicStVaultTest {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function initialize1(
        address _treasury, address _admin,
        address _priceOracle
    ) public initializer {
        super.initialize(
            "STI Staking ETH", "stiStETH",
            _treasury, _admin,
            _priceOracle,
            Const.NATIVE_ASSET, // ETH
            EthConstantTest.stETH
        );

        oneEpoch = 24 hours;

        // stToken.safeApprove(address(curveStEth), type(uint).max);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity  0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "../bni/priceOracle/IPriceOracle.sol";
import "../../interfaces/IERC20UpgradeableExt.sol";
import "../../interfaces/IStVault.sol";
import "../../interfaces/IStVaultNFT.sol";
import "../../libs/Const.sol";
import "../../libs/Token.sol";

contract BasicStVaultTest is IStVault,
    ERC20Upgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint public yieldFee;
    uint public watermark;
    uint public fees;

    address public treasuryWallet;
    address public admin;
    IPriceOracle public priceOracle;
    IStVaultNFT public nft;

    IERC20Upgradeable public token;
    IERC20Upgradeable public stToken;
    uint8 internal tokenDecimals;
    uint8 internal stTokenDecimals;
    uint internal oneToken;
    uint internal oneStToken;

    uint public bufferedDeposits;
    uint public pendingWithdrawals;
    uint public pendingRedeems;
    uint internal emergencyUnbondings;

    uint public unbondingPeriod;
    uint public minInvestAmount;
    uint public minRedeemAmount;

    uint public lastInvestTs;
    uint public investInterval;
    uint public lastRedeemTs;
    uint public redeemInterval;
    uint public lastCollectProfitTs;
    uint public oneEpoch;

    mapping(address => uint) depositedBlock;
    mapping(uint => WithdrawRequest) nft2WithdrawRequest;

    uint baseApr;
    uint baseTokenRate;
    uint baseAprLastUpdate;

    event Deposit(address user, uint amount, uint shares);
    event Withdraw(address user, uint shares, uint amount, uint reqId, uint pendingAmount);
    event Claim(address user, uint reqId, uint amount);
    event ClaimMulti(address user, uint amount, uint claimedCount);
    event Invest(uint amount);
    event Redeem(uint stAmount);
    event EmergencyWithdraw(uint stAmount);
    event CollectProfitAndUpdateWatermark(uint currentWatermark, uint lastWatermark, uint fee);
    event AdjustWatermark(uint currentWatermark, uint lastWatermark);
    event TransferredOutFees(uint fees, address token);

    modifier onlyOwnerOrAdmin {
        require(msg.sender == owner() || msg.sender == admin, "Only owner or admin");
        _;
    }

    function initialize(
        string memory _name, string memory _symbol,
        address _treasury, address _admin,
        address _priceOracle,
        address _token, address _stToken
    ) public virtual initializer {
        require(_treasury != address(0), "treasury invalid");

        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __ERC20_init_unchained(_name, _symbol);

        yieldFee = 2000; //20%
        treasuryWallet = _treasury;
        admin = _admin;
        priceOracle = IPriceOracle(_priceOracle);

        token = IERC20Upgradeable(_token);
        stToken = IERC20Upgradeable(_stToken);
        // tokenDecimals = _assetDecimals(address(token));
        // stTokenDecimals = IERC20UpgradeableExt(address(stToken)).decimals();
        oneToken = 10**tokenDecimals;
        oneStToken = 10**stTokenDecimals;

        minInvestAmount = 1;
        minRedeemAmount = 1;

        _updateApr();
    }

    ///@notice Function to set deposit and yield fee
    ///@param _yieldFeePerc deposit fee percentage. 2000 for 20%
    function setFee(uint _yieldFeePerc) external onlyOwner{
        require(_yieldFeePerc < 3001, "Yield Fee cannot > 30%");
        yieldFee = _yieldFeePerc;
    }

    function setTreasuryWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0), "wallet invalid");
        treasuryWallet = _wallet;
    }

    function setAdmin(address _newAdmin) external onlyOwner{
        admin = _newAdmin;
    }

    function setNFT(address _nft) external onlyOwner {
        require(address(nft) == address(0), "Already set");
        nft = IStVaultNFT(_nft);
    }

    function setStakingPeriods(
        uint _unbondingPeriod,
        uint _investInterval,
        uint _redeemInterval,
        uint _oneEpoch
    ) external onlyOwner {
        unbondingPeriod = _unbondingPeriod;
        investInterval = _investInterval;
        redeemInterval = _redeemInterval;
        oneEpoch = _oneEpoch;
    }

    function setStakingAmounts(uint _minInvestAmount, uint _minRedeemAmount) external virtual onlyOwner {
        require(_minInvestAmount > 0, "minInvestAmount must be > 0");
        require(_minRedeemAmount > 0, "minRedeemAmount must be > 0");
        minInvestAmount = _minInvestAmount;
        minRedeemAmount = _minRedeemAmount;
    }

    function deposit(uint _amount) external nonReentrant whenNotPaused{
        _deposit(msg.sender, _amount);
    }

    function depositETH() external payable nonReentrant whenNotPaused{
        _deposit(msg.sender, msg.value);
    }

    function _deposit(address _account, uint _amount) internal {
        // require(_amount > 0, "Invalid amount");
        // depositedBlock[_account] = block.number;

        // if (address(token) != Const.NATIVE_ASSET) {
        //     token.safeTransferFrom(_account, address(this), _amount);
        // } else {
        //     // The native asset is already received.
        // }
        // bufferedDeposits += _amount;

        // uint pool = getAllPool() - _amount;
        // uint _totalSupply = totalSupply();
        // uint _shares = (pool == 0 || _totalSupply == 0) ? _amount : _amount * _totalSupply / pool;

        // _mint(_account, _shares);
        // adjustWatermark(_amount, true);
        // emit Deposit(_account, _amount, _shares);
    }

    function withdraw(uint _shares) external nonReentrant returns (uint _amount, uint _reqId) {
        // require(_shares > 0, "Invalid Amount");
        // require(balanceOf(msg.sender) >= _shares, "Not enough balance");
        // require(depositedBlock[msg.sender] != block.number, "Withdraw within same block");

        // uint withdrawAmt = getPoolByShares(_shares);
        // _burn(msg.sender, _shares);
        // adjustWatermark(withdrawAmt, false);

        // uint _bufferedDeposits = getBufferedDeposits();
        // uint _fees = fees;
        // uint _buffered = (_bufferedDeposits <= _fees) ? 0 : _bufferedDeposits - fees;

        // if (_buffered >= withdrawAmt) {
        //     _amount = withdrawAmt;
        //     withdrawAmt = 0;
        // } else {
        //     _amount = _buffered;
        //     withdrawAmt -= _buffered;
        // }

        // bufferedDeposits = _bufferedDeposits - _amount;

        // if (withdrawAmt > 0) {
        //     uint tokenPerStToken = getPooledTokenByStToken(oneStToken);
        //     uint stTokenAmt = oneStToken * withdrawAmt / tokenPerStToken;
        //     (uint withdrawnStAmount, uint withdrawnAmount) = withdrawStToken(stTokenAmt);
        //     if (withdrawnStAmount > 0) {
        //         _amount += withdrawnAmount;
        //         stTokenAmt -= withdrawnStAmount;
        //     }
        //     withdrawAmt = tokenPerStToken * stTokenAmt / oneStToken;

        //     if (stTokenAmt > 0) {
        //         pendingWithdrawals += withdrawAmt;
        //         if (paused() == false) {
        //             pendingRedeems += stTokenAmt;
        //         } else {
        //             // We reduce the emergency bonding because the share is burnt.
        //             uint _emergencyUnbondings = getEmergencyUnbondings();
        //             emergencyUnbondings = (_emergencyUnbondings <= stTokenAmt) ? 0 : _emergencyUnbondings - stTokenAmt;
        //         }

        //         _reqId = nft.mint(msg.sender);
        //         nft2WithdrawRequest[_reqId] = WithdrawRequest({
        //             tokenAmt: withdrawAmt,
        //             stTokenAmt: stTokenAmt,
        //             requestTs: block.timestamp
        //         });
        //     }
        // }

        // if (_amount > 0) {
        //     _transferOutToken(msg.sender, _amount);
        // }
        // emit Withdraw(msg.sender, _shares, _amount, _reqId, withdrawAmt);
    }

    function withdrawStToken(uint _stAmountToWithdraw) internal virtual returns (
        uint _withdrawnStAmount,
        uint _withdrawnAmount
    ) {
    }

    function claim(uint _reqId) external nonReentrant returns (uint _amount) {
        // require(nft.isApprovedOrOwner(msg.sender, _reqId), "Not owner");
        // WithdrawRequest memory usersRequest = nft2WithdrawRequest[_reqId];

        // require(block.timestamp >= (usersRequest.requestTs + unbondingPeriod), "Not able to claim yet");

        // uint tokenAmt = usersRequest.tokenAmt;
        // _amount = _getClaimableAmount(bufferedWithdrawals(), tokenAmt);
        // require(_amount > 0, "No enough token");

        // nft.burn(_reqId);
        // pendingWithdrawals -= tokenAmt;

        // _transferOutToken(msg.sender, _amount);
        // emit Claim(msg.sender, _reqId, _amount);
    }

    function claimMulti(uint[] memory _reqIds) external nonReentrant returns (
        uint _amount,
        uint _claimedCount,
        bool[] memory _claimed
    ) {
        // uint buffered = bufferedWithdrawals();
        // uint amount;
        // uint length = _reqIds.length;
        // _claimed = new bool[](length);

        // for (uint i = 0; i < length; i++) {
        //     uint _reqId = _reqIds[i];
        //     if (nft.isApprovedOrOwner(msg.sender, _reqId) == false) continue;

        //     WithdrawRequest memory usersRequest = nft2WithdrawRequest[_reqId];
        //     if (block.timestamp < (usersRequest.requestTs + unbondingPeriod)) continue;

        //     uint tokenAmt = usersRequest.tokenAmt;
        //     amount = _getClaimableAmount(buffered, tokenAmt);
        //     if (amount == 0) continue;

        //     _amount += amount;
        //     buffered -= amount;
        //     pendingWithdrawals -= tokenAmt;

        //     nft.burn(_reqId);
        //     _claimedCount ++;
        //     _claimed[i] = true;
        // }

        // if (_amount > 0) {
        //     _transferOutToken(msg.sender, _amount);
        //     emit ClaimMulti(msg.sender, _amount, _claimedCount);
        // }
    }

    function invest() external onlyOwnerOrAdmin whenNotPaused {
        _investInternal();
    }

    function _investInternal() internal {
        // _collectProfitAndUpdateWatermark();
        // uint _buffered = _transferOutFees();
        // if (_buffered >= minInvestAmount && block.timestamp >= (lastInvestTs + investInterval)) {
        //     uint _invested = _invest(_buffered);
        //     bufferedDeposits = _buffered - _invested;
        //     lastInvestTs = block.timestamp;
        //     emit Invest(_invested);
        // }
    }

    function _invest(uint _amount) internal virtual returns (uint _invested) {}

    function redeem() external onlyOwnerOrAdmin whenNotPaused {
        uint redeemed = _redeemInternal(pendingRedeems);
        pendingRedeems -= redeemed;
    }

    function _redeemInternal(uint _stAmount) internal returns (uint _redeemed) {
        // require(_stAmount >= minRedeemAmount, "too small");
        // require(block.timestamp >= (lastRedeemTs + redeemInterval), "Not able to redeem yet");

        // _redeemed = _redeem(_stAmount);
        // emit Redeem(_redeemed);
    }

    function _redeem(uint _stAmount) internal virtual returns (uint _redeemed) {}

    function claimUnbonded() external onlyOwnerOrAdmin {
        // _claimUnbonded();
    }

    function _claimUnbonded() internal virtual {}

    ///@notice Withdraws funds staked in mirror to this vault and pauses deposit, yield, invest functions
    function emergencyWithdraw() external onlyOwnerOrAdmin whenNotPaused {
        _pause();
        _yield();

        _emergencyWithdrawInternal();
    }

    function _emergencyWithdrawInternal() internal {
        // uint _pendingRedeems = pendingRedeems;
        // uint redeemed = _emergencyWithdraw(_pendingRedeems);
        // pendingRedeems = (_pendingRedeems <= redeemed) ? 0 : _pendingRedeems - redeemed;
        // emit EmergencyWithdraw(redeemed);
    }

    function _emergencyWithdraw(uint _pendingRedeems) internal virtual returns (uint _redeemed) {}

    function emergencyPendingRedeems() external view returns (uint _redeems) {
        // if (paused()) {
        //     _redeems = stToken.balanceOf(address(this));
        // }
    }

    function emergencyRedeem() external onlyOwnerOrAdmin whenPaused {
        _emergencyWithdrawInternal();
    }

    ///@notice Unpauses deposit, yield, invest functions, and invests funds.
    function reinvest() external onlyOwnerOrAdmin whenPaused {
        require(getEmergencyUnbondings() == 0, "Emergency unbonding is not finished");
        require(getTokenUnbonded() == 0, "claimUnbonded should be called");
        _unpause();

        emergencyUnbondings = 0;
        _investInternal();
    }

    function yield() external onlyOwnerOrAdmin whenNotPaused {
        _yield();
    }

    function _yield() internal virtual {}

    function collectProfitAndUpdateWatermark() external onlyOwnerOrAdmin whenNotPaused {
        _collectProfitAndUpdateWatermark();
    }

    function _collectProfitAndUpdateWatermark() private {
        // uint currentWatermark = getAllPool();
        // uint lastWatermark = watermark;
        // uint fee;
        // if (currentWatermark > lastWatermark) {
        //     uint profit = currentWatermark - lastWatermark;
        //     fee = profit * yieldFee / Const.DENOMINATOR;
        //     fees += fee;
        //     watermark = currentWatermark - fee;
        // }
        // lastCollectProfitTs = block.timestamp;
        // emit CollectProfitAndUpdateWatermark(currentWatermark, lastWatermark, fee);
    }

    /// @param signs True for positive, false for negative
    function adjustWatermark(uint amount, bool signs) private {
        // uint lastWatermark = watermark;
        // watermark = signs == true
        //             ? watermark + amount
        //             : (watermark > amount) ? watermark - amount : 0;
        // emit AdjustWatermark(watermark, lastWatermark);
    }

    function withdrawFees() external onlyOwnerOrAdmin {
        _transferOutFees();
    }

    function _transferOutFees() internal returns (uint _tokenAmt) {
        // _tokenAmt = getBufferedDeposits();
        // uint _fees = fees;
        // if (_fees != 0 && _tokenAmt != 0) {
        //     uint feeAmt = _fees;
        //     if (feeAmt < _tokenAmt) {
        //         _fees = 0;
        //         _tokenAmt -= feeAmt;
        //     } else {
        //         _fees -= _tokenAmt;
        //         feeAmt = _tokenAmt;
        //         _tokenAmt = 0;
        //     }
        //     fees = _fees;
        //     bufferedDeposits = _tokenAmt;

        //     _transferOutToken(treasuryWallet, feeAmt);
        //     emit TransferredOutFees(feeAmt, address(token)); // Decimal follows token
        // }
    }

    function _transferOutToken(address _to, uint _amount) internal {
        // (address(token) != Const.NATIVE_ASSET)
        //     ? token.safeTransfer(_to, _amount)
        //     : Token.safeTransferETH(_to, _amount);
    }

    function _tokenBalanceOf(address _account) internal view returns (uint) {
        return 0;
        // return (address(token) != Const.NATIVE_ASSET)
        //     ? token.balanceOf(_account)
        //     : _account.balance;
    }

    function _assetDecimals(address _asset) internal view returns (uint8 _decimals) {
        _decimals = (_asset == Const.NATIVE_ASSET) ? 18 : IERC20UpgradeableExt(_asset).decimals();
    }

    function _getFreeBufferedDeposits() internal view returns (uint _buffered) {
        uint balance = _tokenBalanceOf(address(this));
        uint _pendingWithdrawals = pendingWithdrawals;
        // While unbonding, the balance could be less than pendingWithdrawals.
        // After unbonded, the balance could be greater than pendingWithdrawals
        //  because the rewards are accumulated in unbonding period on some staking pools.
        //  In this case, the _buffered can be greater than bufferedDeposits.
        // And also if the emergency withdrawal is unbonded, the _buffered will be greater than bufferedDeposits.
        _buffered = (balance > _pendingWithdrawals) ? balance - _pendingWithdrawals : 0;
    }

    function getBufferedDeposits() public virtual view returns (uint) {
        return MathUpgradeable.max(bufferedDeposits, _getFreeBufferedDeposits());
    }

    function bufferedWithdrawals() public view returns (uint) {
        return _tokenBalanceOf(address(this)) - bufferedDeposits;
    }

    function getEmergencyUnbondings() public virtual view returns (uint) {
        return emergencyUnbondings;
    }

    function getInvestedStTokens() public virtual view returns (uint _stAmount) {
        return 0;
    }

    ///@param _amount Amount of tokens
    function getStTokenByPooledToken(uint _amount) public virtual view returns(uint) {
        return Token.changeDecimals(_amount, tokenDecimals, stTokenDecimals);
    }

    ///@param _stAmount Amount of stTokens
    function getPooledTokenByStToken(uint _stAmount) public virtual view returns(uint) {
        return _stAmount * oneToken / getStTokenByPooledToken(oneToken);
    }

    ///@dev it doesn't include the unbonding stTokens according to the burnt shares.
    function getAllPool() public virtual view returns (uint _pool) {
        return 0;
        // if (paused() == false) {
        //     uint stBalance = stToken.balanceOf(address(this))
        //                     + getInvestedStTokens()
        //                     - pendingRedeems;
        //     if (stBalance > 0) {
        //         _pool = getPooledTokenByStToken(stBalance);
        //     }
        //     _pool += bufferedDeposits;
        //     _pool -= fees;
        // } else {
        //     uint stBalance = stToken.balanceOf(address(this))
        //                     + getInvestedStTokens()
        //                     + getEmergencyUnbondings()
        //                     - pendingRedeems;
        //     if (stBalance > 0) {
        //         _pool = getPooledTokenByStToken(stBalance);
        //     }
        //     // If the emergency withdrawal is unbonded,
        //     //  then getEmergencyUnbondings() is less than emergencyUnbondings,
        //     //  and _getFreeBufferedDeposits will be greater than bufferedDeposits.
        //     _pool += _getFreeBufferedDeposits();
        //     _pool -= fees;
        // }
    }

    function getSharesByPool(uint _amount) public view returns (uint) {
        uint pool = getAllPool();
        return (pool == 0) ? _amount : _amount * totalSupply() / pool;
    }

    function getPoolByShares(uint _shares) public view returns (uint) {
        uint _totalSupply = totalSupply();
        return (_totalSupply == 0) ? _shares : _shares * getAllPool() / _totalSupply;
    }

    function getAllPoolInUSD() public view returns (uint) {
        uint pool = getAllPool();
        return getValueInUSD(address(token), pool);
    }

    ///@return the value in USD. it's scaled by 1e18;
    function getValueInUSD(address _asset, uint _amount) internal view returns (uint) {
        return 0;
        // (uint priceInUSD, uint8 priceDecimals) = priceOracle.getAssetPrice(_asset);
        // uint8 _decimals = _assetDecimals(_asset);
        // return Token.changeDecimals(_amount, _decimals, 18) * priceInUSD / (10 ** (priceDecimals));
    }

    ///@notice Returns the pending rewards in USD.
    function getPendingRewards() public virtual view returns (uint) {
        return 0;
    }

    function getAPR() public virtual view returns (uint) {
        (uint _baseApr,,) = getBaseApr();
        return _baseApr;
    }

    function resetApr() external onlyOwner {
        _resetApr();
        _updateApr();
    }

    function _resetApr() internal virtual {
        baseApr = 0;
        baseTokenRate = 0;
        baseAprLastUpdate = 0;
    }

    function _updateApr() internal virtual {
        (uint _baseApr, uint _baseTokenRate, bool _update) = getBaseApr();
        if (_update) {
            baseApr = _baseApr;
            baseTokenRate = _baseTokenRate;
            baseAprLastUpdate = block.timestamp;
        }
    }

    function getBaseApr() public view returns (uint, uint, bool) {
        uint _baseApr = baseApr;
        uint _baseTokenRate = baseTokenRate;
        uint _baseAprLastUpdate = baseAprLastUpdate;

        if (_baseApr == 0 || (_baseAprLastUpdate + 1 weeks) <= block.timestamp) {
            uint newTokenRate = getPoolByShares(1e18);
            if (0 < _baseTokenRate && _baseTokenRate < newTokenRate) {
                uint newApr = (newTokenRate-_baseTokenRate) * Const.YEAR_IN_SEC * Const.APR_SCALE
                            / (_baseTokenRate * (block.timestamp-_baseAprLastUpdate));
                return (newApr, newTokenRate, true);
            } else {
                return (0, newTokenRate, true);
            }
        } else {
            return (_baseApr, _baseTokenRate, false);
        }
    }

    function getBaseAprData() public view returns (uint, uint, uint) {
        return (baseApr, baseTokenRate, baseAprLastUpdate);
    }

    function getWithdrawRequest(uint _reqId) external view returns (
        bool _claimable,
        uint _tokenAmt, uint _stTokenAmt,
        uint _requestTs, uint _waitForTs
    ) {
        WithdrawRequest memory usersRequest = nft2WithdrawRequest[_reqId];
        _tokenAmt = usersRequest.tokenAmt;
        _stTokenAmt = usersRequest.stTokenAmt;
        _requestTs = usersRequest.requestTs;

        uint endTs = _requestTs + unbondingPeriod;
        if (endTs > block.timestamp) {
            _waitForTs = endTs - block.timestamp;
        } else if (_getClaimableAmount(bufferedWithdrawals(), _tokenAmt) > 0) {
            _claimable = true;
        }
    }

    function _getClaimableAmount(uint _buffered, uint _withdrawAmt) internal view returns (uint) {
        // The tokens withdrawn from the staking pool can be slightly less than the calculated withdrawAmt.
        uint minWithdrawAmt = _withdrawAmt * (1e8 - 1) / 1e8;
        return (_buffered < minWithdrawAmt) ? 0 : MathUpgradeable.min(_buffered, _withdrawAmt);
    }

    function getTokenUnbonded() public virtual view returns (uint) {
        return 0;
    }

    receive() external payable {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[20] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity  0.8.9;

library EthConstantTest {
    uint internal constant CHAINID = 4;

    address internal constant MATIC = 0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0; // Should be replaced with testnet address
    address internal constant stETH = 0xF4242f9d78DB7218Ad72Ee3aE14469DBDE8731eD;
    address internal constant stMATIC = 0x9ee91F9f426fA633d227f7a9b000E28b9dfd8599; // Should be replaced with testnet address
    address internal constant USDC = 0xDf5324ebe6F6b852Ff5cBf73627eE137e9075276;
    address internal constant USDT = 0x21e48034753E490ff04f2f75f7CAEdF081B320d5;
    address internal constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library Const {

    uint internal constant DENOMINATOR = 10000;

    uint internal constant APR_SCALE = 1e18;
    
    uint internal constant YEAR_IN_SEC = 365 days;

    address internal constant NATIVE_ASSET = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity  0.8.9;

interface IPriceOracle {

    /**
     * @notice Sets or replaces price sources of assets
     * @param assets The addresses of the assets
     * @param sources The addresses of the price sources
     */
    function setAssetSources(address[] memory assets, address[] memory sources) external;

    /**
     * @notice Returns the address of the source for an asset address
     * @param asset The address of the asset
     * @return The address of the source
     */
    function getSourceOfAsset(address asset) external view returns (address);

    /**
     * @notice Returns a list of prices from a list of assets addresses
     * @param assets The list of assets addresses
     * @return prices The prices of the given assets
     */
    function getAssetsPrices(address[] memory assets) external view returns (uint[] memory prices, uint8[] memory decimalsArray);

    /**
     * @notice Returns a list of prices from a list of assets addresses
     * @param asset The asset address
     * @return price The prices of the given assets
     */
    function getAssetPrice(address asset) external view returns (uint price, uint8 decimals);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20UpgradeableExt is IERC20Upgradeable {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IStVault is IERC20Upgradeable {

    struct WithdrawRequest {
        uint tokenAmt;
        uint stTokenAmt;
        uint requestTs;
    }

    // fee percentage that treasury takes from rewards.
    function yieldFee() external view returns(uint);
    // treasury wallet address.
    function treasuryWallet() external view returns(address);
    // administrator address.
    function admin() external view returns(address);

    // underlying token such as ETH, WMATIC, and so on.
    function token() external view returns(IERC20Upgradeable);
    // staked token such as stETH, stMATIC, and so on.
    function stToken() external view returns(IERC20Upgradeable);

    // the buffered deposit token amount that is not yet staked into the staking pool.
    function bufferedDeposits() external view returns(uint);
    // On some staking pools, the rewards are accumulated until unbonded even though redeem is requested. This function considers it.
    function getBufferedDeposits() external view returns(uint);
    // the buffered withdrawal token amount that is unstaked from the staking pool but not yet withdrawn from the user.
    function bufferedWithdrawals() external view returns(uint);
    // the token amount that shares is already burnt but not withdrawn.
    function pendingWithdrawals() external view returns(uint);
    // the total amount of withdrawal stToken that is not yet requested to the staking pool.
    function pendingRedeems() external view returns(uint);
    // the amount of stToken that is emergency unbonding, and shares according to them are not burnt yet.
    function getEmergencyUnbondings() external view returns(uint);
    // the amount of stToken that has invested into L2 vaults to get extra benefit.
    function getInvestedStTokens() external view returns(uint);
    
    // the seconds to wait for unbonded since withdarwal requested. For example, 30 days in case of unstaking stDOT to get xcDOT
    function unbondingPeriod() external view returns(uint);
    // the minimum amount of token to invest.
    function minInvestAmount() external view returns(uint);
    // the minimum amount of stToken to redeem.
    function minRedeemAmount() external view returns(uint);

    // the timestamp that the last investment was executed on.
    function lastInvestTs() external view returns(uint);
    // minimum seconds to wait before next investment. For example, MetaPool's stNEAR buffer is replenished every 5 minutes.
    function investInterval() external view returns(uint);
    // the timestamp that the last redeem was requested on.
    function lastRedeemTs() external view returns(uint);
    // minimum seconds to wait before next redeem. For example, Lido have up to 20 redeem requests to stDOT in parallel. Therefore, the next redeem should be requested after about 1 day.
    function redeemInterval() external view returns(uint);
    // the timestamp that the profit last collected on.
    function lastCollectProfitTs() external view returns(uint);
    // the timestamp of one epoch. Each epoch, the stToken price or balance will increase as staking-rewards are added to the pool.
    function oneEpoch() external view returns(uint);

    ///@return the total amount of tokens in the vault.
    function getAllPool() external view returns (uint);
    ///@return the amount of shares that corresponds to `_amount` of token.
    function getSharesByPool(uint _amount) external view returns (uint);
    ///@return the amount of token that corresponds to `_shares` of shares.
    function getPoolByShares(uint _shares) external view returns (uint);
    ///@return the total USD value of tokens in the vault.
    function getAllPoolInUSD() external view returns (uint);
    ///@return the USD value of rewards that is avilable to claim. It's scaled by 1e18.
    function getPendingRewards() external view returns (uint);
    ///@return the APR in the vault. It's scaled by 1e18.
    function getAPR() external view returns (uint);
    ///@return _claimable specifys whether user can claim tokens for it.
    ///@return _tokenAmt is amount of token to claim.
    ///@return _stTokenAmt is amount of stToken to redeem.
    ///@return _requestTs is timestmap when withdrawal requested.
    ///@return _waitForTs is timestamp to wait for.
    function getWithdrawRequest(uint _reqId) external view returns (
        bool _claimable,
        uint _tokenAmt, uint _stTokenAmt,
        uint _requestTs, uint _waitForTs
    );
    ///@return the unbonded token amount that is claimable from the staking pool.
    function getTokenUnbonded() external view returns (uint);

    ///@dev deposit `_amount` of token.
    function deposit(uint _amount) external;
    ///@dev deposit the native asset.
    function depositETH() external payable;
    ///@dev request a withdrawal that corresponds to `_shares` of shares.
    ///@return _amount is the amount of withdrawn token.
    ///@return _reqId is the NFT token id indicating the request for rest of withdrawal. 0 if no request is made.
    function withdraw(uint _shares) external returns (uint _amount, uint _reqId);
    ///@dev claim token with NFT token
    ///@return _amount is the amount of claimed token.
    function claim(uint _reqId) external returns (uint _amount);
    ///@dev claim token with NFT tokens
    ///@return _amount is the amount of claimed token.
    ///@return _claimedCount is the count of reqIds that are claimed.
    ///@return _claimed is the flag indicating whether the token is claimed.
    function claimMulti(uint[] memory _reqIds) external returns (uint _amount, uint _claimedCount, bool[] memory _claimed);
    ///@dev stake the buffered deposits into the staking pool. It's called by admin.
    function invest() external;
    ///@dev redeem the requested withdrawals from the staking pool. It's called by admin.
    function redeem() external;
    ///@dev claim the unbonded tokens from the staking pool. It's called by admin.
    function claimUnbonded() external;
    ///@dev request a withdrawal for all staked tokens. It's called by admin.
    function emergencyWithdraw() external;
    ///@dev the total amount of emergency withdrawal stToken that is not yet requested to the staking pool.
    function emergencyPendingRedeems() external view returns (uint _redeems);
    ///@dev In emergency mode, redeem the rest of stTokens. Especially it's needed for stNEAR because the MetaPool has a buffer limit.
    function emergencyRedeem() external;
    ///@dev reinvest the tokens, and set the vault status as normal. It's called by admin.
    function reinvest() external;
    ///@dev take rewards and reinvest them. It's called by admin.
    function yield() external;
    ///@dev collect profit and update the watermark
    function collectProfitAndUpdateWatermark() external;
    ///@dev transfer out fees.
    function withdrawFees() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IStVaultNFT is IERC721Upgradeable {

    function mint(address _to) external returns (uint);
    function burn(uint _tokenId) external;
    function totalSupply() external view returns (uint);
    function isApprovedOrOwner(address _spender, uint _tokenId) external view returns (bool);
    function exists(uint _tokenId) external view returns (bool);

    function setStVault(address _stVault) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library Token {
    function changeDecimals(uint amount, uint curDecimals, uint newDecimals) internal pure returns(uint) {
        if (curDecimals == newDecimals) {
            return amount;
        } else if (curDecimals < newDecimals) {
            return amount * (10 ** (newDecimals - curDecimals));
        } else {
            return amount / (10 ** (curDecimals - newDecimals));
        }
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "ETH transfer failed");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}