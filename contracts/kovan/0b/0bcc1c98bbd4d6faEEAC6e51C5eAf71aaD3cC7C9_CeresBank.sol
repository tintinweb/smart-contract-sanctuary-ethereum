// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interface/ICeresBank.sol";
import "./interface/ICeresCoin.sol";
import "./interface/IOracle.sol";
import "./interface/ICeresFactory.sol";
import "./interface/ICeresStaking.sol";
import "./interface/IRedeemReceiver.sol";
import "./interface/ICeresVault.sol";
import "./library/CeresLibrary.sol";
import "./common/CeresBase.sol";
import "./common/Ownable.sol";
import "./CeresFactory.sol";

contract CeresBank is CeresBase, ICeresBank, Ownable {

    uint256 public override collateralRatio;
    uint256 public override minCR = 500000;
    uint256 public override updateCooldown = 12 hours;
    uint256 public override ratioStep = 2500;
    uint256 public override minRatioStep = 0;
    uint256 public override maxRatioStep = 150;

    uint256 public maxBurnedCRSAmount = 500000e18;
    uint256 public maxMintedASCAmount = 100000e18;
    uint256 public minMintedASCAmount = 500e18;
    uint256 public minterCRSBonus = 4e18;
    uint256 public minterPercentVault = 10000;
    uint256 public burnCRSPercent = 1000000;
    uint256 public minASCMineablePrice = 1.05e6;
    uint256 public maxASCRedeemablePrice = 0.95e6;
    address public vault;
    uint256 public override minMinerStakingRatio;
    uint256 public nextVolIndex;

    ICeresCoin public asc;
    ICeresCoin public crs;
    mapping(address => uint256) public override nextUpdateTime;
    
    constructor (address _owner, address _factory, address _asc, address _crs) Ownable(_owner) CeresBase(_factory){

        collateralRatio = 1e6;
        asc = ICeresCoin(_asc);
        crs = ICeresCoin(_crs);
    }

    /* ---------- Views ---------- */
    function ascPriceMineable() public view returns (bool){
        return factory.getTokenPrice(address(asc)) >= minASCMineablePrice;
    }

    function ascPriceRedeemable() public view returns (bool){
        return factory.getTokenPrice(address(asc)) <= maxASCRedeemablePrice;
    }
    
    function getGlobalCollateralValue() external pure returns (uint256)  {
        // TODO k: get in vault contract
        return 5000000000e18; //5billion d18
    }

    /* ---------- Function: Mint ---------- */
    function mintFromStaking(address collateral, uint256 collateralAmount) external override onlyStakings
        returns (ICeresBank.MintResult memory result){

        require(factory.isStakingMineable(collateral) == true, "Collateral is not available to mint in CeresBank");
        require(block.timestamp > nextUpdateTime[msg.sender], "Please wait for update cooldown!");
        require(collateralRatio > minCR, "Must be greater than minimal collateral ratio!");
        require(ascPriceMineable(), "ASC price now is not mineable!");

        // transfer col to vault
        SafeERC20.safeTransfer(IERC20(collateral), vault, collateralAmount);

        // calc amounts
        (uint256 ascMintTotal, uint256 mintToCRS, uint256 mintToVol) = _calcMintAmount(collateral, collateralAmount);

        require(ascMintTotal <= maxMintedASCAmount, "Exceed maximum ASC to be minted");
        require(ascMintTotal >= minMintedASCAmount, "Must be greater than minMintedASC");

        // if transfer vol to mint
        address stakingVolAddress;
        uint256 volAmountTransferred;
        if (mintToVol > 0) {
            (bool qualified, address _vol, uint256 _volAmount) = _transferVol(mintToVol);
            if (qualified) {
                stakingVolAddress = factory.getStaking(_vol);
                volAmountTransferred = _volAmount;
            } else {// vol not qualified, burn crs rollback to 100%
                mintToCRS += mintToVol;
            }
        }

        address stakingCRS = factory.getStaking(address(crs));
        uint256 crsBurnAmount = mintToCRS * CERES_PRECISION / factory.getTokenPrice(address(crs));
        require(crsBurnAmount <= maxBurnedCRSAmount, "Exceed maximum CRS to be burned");

        if (crsBurnAmount > 0) {
            ICeresStaking(stakingCRS).approveBank(crsBurnAmount);
            crs.burnFrom(stakingCRS, crsBurnAmount);
        }

        // mint asc to this TODO k: minterPercentVault
        asc.mint(address(this), ascMintTotal * (CERES_PRECISION + minterPercentVault) / CERES_PRECISION);

        // distribute mint
        uint256 mintToCol = ascMintTotal - mintToCRS - mintToVol;
        asc.transfer(msg.sender, mintToCol);

        if (mintToCRS > 0)
            asc.transfer(stakingCRS, mintToCRS);

        if (mintToVol > 0 && stakingVolAddress != address(0))
            asc.transfer(address(stakingVolAddress), mintToVol);

        if (minterPercentVault > 0)
            asc.transfer(vault, ascMintTotal * minterPercentVault / CERES_PRECISION);

        // bonus to miner
        crs.transfer(msg.sender, minterCRSBonus);

        // update cr
        uint256 decreaseRatioStep = CeresLibrary.calcRatioStep(collateral, collateralAmount, ratioStep, minRatioStep, maxRatioStep);
        require(decreaseRatioStep < maxRatioStep, "ratioStep must be less than maxRatioStep");
        require(decreaseRatioStep > minRatioStep, "ratioStep must be greater than minRatioStep");
        collateralRatio = collateralRatio - decreaseRatioStep;
        nextUpdateTime[msg.sender] = block.timestamp + updateCooldown;

        return ICeresBank.MintResult(collateralAmount, crsBurnAmount, volAmountTransferred, mintToCol, mintToCRS, mintToVol, minterCRSBonus, stakingVolAddress);
    }

    function _calcMintAmount(address _collateral, uint256 _collateralAmount) internal view returns (uint256 ascMintTotal, uint256 crsValueD18, uint256 volValueD18) {

        uint256 colPrice = factory.getTokenPrice(_collateral);
        uint256 crsPrice = factory.getTokenPrice(address(crs));

        // calc value in usd, 18 decimals
        uint256 colValueD18 = CeresLibrary.toAmountD18(_collateral, _collateralAmount) * colPrice / CERES_PRECISION;

        // total mint
        ascMintTotal = colValueD18 * CERES_PRECISION / collateralRatio;

        uint256 nonColValueD18 = ascMintTotal - colValueD18;
        crsValueD18 = nonColValueD18 * burnCRSPercent / CERES_PRECISION;
        volValueD18 = nonColValueD18 - crsValueD18;

    }

    function _transferVol(uint256 _volValueD18) internal returns (bool qualified, address _vol, uint256 _volAmount){
        
        _vol = factory.volTokens(nextVolIndex);
        address stakingVolAddress = factory.getStaking(_vol);
        
        if (stakingVolAddress != address(0)) {

            ICeresStaking stakingVol = ICeresStaking(stakingVolAddress);
            if (stakingVol.value() > _volValueD18 / 10 ** 12) {
                qualified = true;
                uint256 volPrice = factory.getTokenPrice(_vol);
                _volAmount = CeresLibrary.toAmountActual(_vol, _volValueD18 * CERES_PRECISION / volPrice);
                stakingVol.approveBank(_volAmount);
                SafeERC20.safeTransferFrom(IERC20(_vol), stakingVolAddress, vault, _volAmount);
            }
        }
    }

    /* ---------- Function: Redeem ---------- */
    function redeem(uint ascAmount) external override onlyOwner {
        require(ascAmount > 0, "Redeem amount can not be zero!");
        
        // update oracles
        address[] memory _tokens = new address[](2);
        _tokens[0] = address(asc);
        _tokens[1] = address(crs);
        factory.updateOracles(_tokens);
        
        require(ascPriceMineable(), "ASC price now is not redeemable!");
        
        address stakingASC = factory.getStaking(address(asc));
        ICeresStaking(stakingASC).approveBank(ascAmount);
        asc.burnFrom(stakingASC, ascAmount);

        uint256 redeemColPercent = collateralRatio ** 2 / CERES_PRECISION;
        
        // redeem col value in d18
        uint256 colValue = ascAmount * redeemColPercent / CERES_PRECISION;
        
        // crs mint to staking asc
        uint256 crsPrice = factory.getTokenPrice(address(crs));
        uint256 crsAmount = ascAmount * (1e6 - redeemColPercent) / crsPrice;
        crs.mint(stakingASC, crsAmount);
        
        // notify redeem
        IRedeemReceiver(stakingASC).notifyRedeem(ascAmount, crsAmount, colValue);
    }

    /* ---------- Function: Claim ---------- */
    function claimColFromStaking(uint256 colValueD18, address claimToken) external override onlyStakings returns (uint256 tokenAmount) {
        uint256 tokenPrice = factory.getTokenPrice(claimToken);
        tokenAmount = colValueD18 * CERES_PRECISION / tokenPrice;
        ICeresVault(vault).claimFromBank(msg.sender, claimToken, tokenAmount);
    }

    /* ---------- Settings ---------- */
    function setCollateralRatio(uint256 _collateralRatio) external onlyOwner {
        collateralRatio = _collateralRatio;
    }

    function setMinCR(uint256 _minCR) external onlyOwner {
        minCR = _minCR;
    }

    function setUpdateCooldown(uint256 _updateCooldown) external onlyOwner {
        updateCooldown = _updateCooldown;
    }

    function setRatioStep(uint256 _ratioStep) external onlyOwner {
        ratioStep = _ratioStep;
    }

    function setMinRatioStep(uint256 _minRatioStep) external onlyOwner {
        minRatioStep = _minRatioStep;
    }

    function setMaxRatioStep(uint256 _maxRatioStep) external onlyOwner {
        maxRatioStep = _maxRatioStep;
    }

    function setMaxBurnedCRSAmount(uint256 _maxBurnedCRSAmount) external onlyOwner {
        maxBurnedCRSAmount = _maxBurnedCRSAmount;
    }

    function setMaxMintedASCAmount(uint256 _maxMintedASCAmount) external onlyOwner {
        maxMintedASCAmount = _maxMintedASCAmount;
    }

    function setMinMintedASCAmount(uint256 _minMintedASCAmount) external onlyOwner {
        minMintedASCAmount = _minMintedASCAmount;
    }

    function setMinterCRSBonus(uint256 _minterCRSBonus) external onlyOwner {
        minterCRSBonus = _minterCRSBonus;
    }

    function setMinterPercentVault(uint256 _minterPercentVault) external onlyOwner {
        minterPercentVault = _minterPercentVault;
    }

    function setBurnCRSPercent(uint256 _burnCRSPercent) external onlyOwner {
        require(_burnCRSPercent <= CERES_PRECISION, "Burn percent can not be bigger than 1.");
        burnCRSPercent = _burnCRSPercent;
    }

    function setMinASCMineablePrice(uint256 _minASCMineablePrice) external onlyOwner {
        minASCMineablePrice = _minASCMineablePrice;
    }

    function setVault(address _vault) external onlyOwner {
        vault = _vault;
    }

    function setFactory(address _factory) external onlyOwner {
        factory = CeresFactory(_factory);
    }

    function setMinMinerStakingRatio(uint256 _minMinerStakingRatio) external onlyOwner {
        minMinerStakingRatio = _minMinerStakingRatio;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/ICeresFactory.sol";
import "./interface/ICeresCreator.sol";
import "./interface/IOracle.sol";
import "./common/Ownable.sol";

contract CeresFactory is ICeresFactory, Ownable {

    address public override getBank;
    address public override getReward;
    uint256 public stakingCount;
    address[] public tokens;
    address[] public override volTokens;
    mapping(address => TokenInfo) public tokenInfo;
    mapping(address => bool) public override isValidStaking;
    ICeresCreator public creator;

    modifier tokenAdded(address token) {
        require(tokenInfo[token].tokenAddress != address(0), "Token is not added");
        _;
    }

    constructor(address _owner, address _creator) Ownable(_owner) {
        creator = ICeresCreator(_creator);
    }

    /* ---------- Views ---------- */
    function getTokens() external view override returns (address[] memory){
        return tokens;
    }

    function getTokensLength() external view override returns (uint256){
        return tokens.length;
    }

    function getVolTokensLength() external view override returns (uint256){
        return volTokens.length;
    }

    function getTokenInfo(address token) external view override returns (TokenInfo memory){
        return tokenInfo[token];
    }

    function getStaking(address token) external view override returns (address) {
        return tokenInfo[token].stakingAddress;
    }

    function getOracle(address token) external view override returns (address) {
        return tokenInfo[token].oracleAddress;
    }

    function getQuoteToken() external view returns (address) {
        return creator.quoteToken();
    }

    function isStakingRewards(address staking) external view override returns (bool) {
        return tokenInfo[staking].isStakingRewards;
    }

    function isStakingMineable(address staking) external view override returns (bool) {
        return tokenInfo[staking].isStakingMineable;
    }

    function getTokenPrice(address token) external view override returns (uint256) {
        return IOracle(tokenInfo[token].oracleAddress).getPrice();
    }

    function getValidStakings() external view override returns (address[] memory _stakings){
        _stakings = new address[](stakingCount);

        uint256 index = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            address staking = tokenInfo[tokens[i]].stakingAddress;
            if (staking != address(0)) {
                _stakings[index] = staking;
                index++;
            }
        }
        return _stakings;
    }

    /* ---------- RAA ---------- */
    function createStaking(address token, bool ifCreateOracle) external override returns (address staking, address oracle){

        require(tokenInfo[token].tokenAddress == address(0), "Staking already created!");

        staking = creator.createStaking(token);
        tokenInfo[token].tokenAddress = token;
        tokenInfo[token].stakingAddress = staking;

        if (ifCreateOracle) {
            oracle = createOracle(token);
            tokenInfo[token].oracleAddress = oracle;
        }

        tokens.push(token);
        stakingCount++;
        isValidStaking[staking] = true;
    }

    function createStakingWithLiquidity(address token, uint256 tokenAmount, uint256 quoteAmount, bool ifCreateOracle)
        external override returns (address staking, address oracle){

        require(tokenInfo[token].tokenAddress == address(0), "Staking already created!");

        staking = creator.createStaking(token);

        // create pair, add liquidity
        IERC20(token).transferFrom(msg.sender, address(creator), tokenAmount);
        IERC20(creator.quoteToken()).transferFrom(msg.sender, address(creator), quoteAmount);
        creator.addLiquidity(token, tokenAmount, quoteAmount, msg.sender);

        tokenInfo[token].tokenAddress = token;
        tokenInfo[token].stakingAddress = staking;

        if (ifCreateOracle) {
            oracle = createOracle(token);
            tokenInfo[token].oracleAddress = oracle;
        }

        tokens.push(token);
        stakingCount++;
        isValidStaking[staking] = true;
    }

    function createOracle(address token) public override returns (address oracle) {
        require(tokenInfo[token].oracleAddress == address(0), "Oracle already created!");

        oracle = creator.createOracle(token);
        tokenInfo[token].oracleAddress = oracle;
    }

    /* ---------- Functions ---------- */
    function addStaking(address token, uint256 tokenType, address staking, address oracle, bool isStakingRewards,
        bool isStakingMineable) external override onlyOwner {

        require(tokenInfo[token].tokenAddress == address(0), "Staking already added!");
        require(token != address(0) && staking != address(0), "Staking parameters can not be zero address!");
        require(tokenType > 0, "Token type must be bigger than zero!");

        _beforeTypeChange(token, tokenType);

        tokenInfo[token].tokenAddress = token;
        tokenInfo[token].tokenType = tokenType;
        tokenInfo[token].stakingAddress = staking;
        tokenInfo[token].isStakingRewards = isStakingRewards;
        tokenInfo[token].isStakingMineable = isStakingMineable;
        tokens.push(token);

        if (oracle != address(0))
            tokenInfo[token].oracleAddress = oracle;

        stakingCount ++;
        isValidStaking[staking] = true;
    }

    function removeStaking(address token, address staking) external override onlyOwner {
        isValidStaking[staking] = false;
        if (tokenInfo[token].stakingAddress == staking)
            tokenInfo[token].stakingAddress = address(0);
        stakingCount--;
    }
    
    function updateOracles(address[] memory tokens) external override {
        for (uint256 i = 0; i < tokens.length; i++)
            updateOracle(tokens[i]);
    }

    function updateOracle(address token) public override {
        address oracle = tokenInfo[token].oracleAddress;
        if (IOracle(oracle).updatable())
            IOracle(oracle).update();
    }

    /* ---------- Settings ---------- */
    function setBank(address _bank) external override onlyOwner {
        getBank = _bank;
    }

    function setCreator(address _creator) external override onlyOwner {
        creator = ICeresCreator(_creator);
    }

    function setReward(address _reward) external override onlyOwner {
        getReward = _reward;
    }

    function setTokenType(address _token, uint256 _tokenType) external override onlyOwner tokenAdded(_token) {
        _beforeTypeChange(_token, _tokenType);
        tokenInfo[_token].tokenType = _tokenType;
    }

    function setStaking(address _token, address _staking) external override onlyOwner tokenAdded(_token) {
        isValidStaking[tokenInfo[_token].stakingAddress] = false;
        isValidStaking[_staking] = true;
        tokenInfo[_token].stakingAddress = _staking;
    }

    function setOracle(address _token, address _oracle) external override onlyOwner tokenAdded(_token) {
        tokenInfo[_token].oracleAddress = _oracle;
    }

    function setIsStakingRewards(address _token, bool _isStakingRewards) external override onlyOwner tokenAdded(_token) {
        tokenInfo[_token].isStakingRewards = _isStakingRewards;
    }

    function setIsStakingMineable(address _token, bool _isStakingMineable) external override onlyOwner tokenAdded(_token) {
        tokenInfo[_token].isStakingMineable = _isStakingMineable;
    }
    
    // records vol address before type change every time
    function _beforeTypeChange(address _token, uint256 _tokenType) internal {

        uint256 oldType = tokenInfo[_token].tokenType;
        if (_tokenType != 4 && oldType != 4)
            return;

        if (oldType != 4 && _tokenType == 4) // add
            volTokens.push(_token);

        if (oldType == 4 && _tokenType != 4) {// delete
            for (uint256 i = 0; i < volTokens.length; i++) {
                if (volTokens[i] == _token)
                    delete volTokens[i];
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interface/ICeresFactory.sol";

contract CeresBase {

    uint256 public constant CERES_PRECISION = 1e6;
    uint256 public constant SHARE_PRECISION = 1e18;
    
    ICeresFactory public factory;
    
    modifier onlyBank() {
        require(msg.sender == factory.getBank(), "Only Bank!");
        _;
    }
    
    modifier onlyStakings() {
        require(factory.isValidStaking(msg.sender) == true, "Only Staking!");
        _;
    }

    constructor(address _factory){
        factory = ICeresFactory(_factory);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract Ownable is Context {
    
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor(address _owner_) {
        _setOwner(_owner_);
    }
    
    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Only Owner!");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICeresBank {

    struct MintResult {
        uint256 lockedCol;
        uint256 burnedCRS;
        uint256 lockedVol;
        uint256 mintToCol;
        uint256 mintToCRS;
        uint256 mintToVol;
        uint256 bonusToMiner;
        address volStaking;
    }

    /* ---------- Views ---------- */
    function collateralRatio() external view returns (uint256);
    function minCR() external view returns(uint256);
    function nextUpdateTime(address staking) external view returns (uint256);
    function updateCooldown() external view returns (uint256);
    function ratioStep() external view returns (uint256);
    function minRatioStep() external view returns (uint256);
    function maxRatioStep() external view returns (uint256);
    function minMinerStakingRatio() external view returns (uint256);

    /* ---------- Functions ---------- */
    function mintFromStaking(address collateral, uint collateralAmount) external returns (MintResult memory result);
    function redeem(uint ascAmount) external;
    function claimColFromStaking(uint256 colValueD18, address token) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface ICeresCoin is IERC20Metadata {

    /* ---------- Functions ---------- */
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICeresCreator {
    
    /* ---------- Views ---------- */
    function quoteToken() external view returns (address);

    /* ---------- Functions ---------- */
    function createStaking(address token) external returns (address);
    function createOracle(address token) external returns (address);
    function addLiquidity(address token, uint256 tokenAmount, uint256 quoteAmount, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICeresFactory {
    
    struct TokenInfo {
        address tokenAddress;
        uint256 tokenType; // 1: asc, 2: crs, 3: col, 4: vol;
        address stakingAddress;
        address oracleAddress;
        bool isStakingRewards;
        bool isStakingMineable;
    }

    /* ---------- Views ---------- */
    function getBank() external view returns (address);
    function getReward() external view returns (address);
    function getTokenInfo(address token) external returns(TokenInfo memory);
    function getStaking(address token) external view returns (address);
    function getOracle(address token) external view returns (address);
    function isValidStaking(address sender) external view returns (bool);
    function volTokens(uint256 index) external view returns (address);

    function getTokens() external view returns (address[] memory);
    function getTokensLength() external view returns (uint256);
    function getVolTokensLength() external view returns (uint256);
    function getValidStakings() external view returns (address[] memory);
    function getTokenPrice(address token) external view returns(uint256);
    function isStakingRewards(address staking) external view returns (bool);
    function isStakingMineable(address staking) external view returns (bool);

    /* ---------- Functions ---------- */
    function setBank(address newAddress) external;
    function setReward(address newReward) external;
    function setCreator(address creator) external;
    function setTokenType(address token, uint256 tokenType) external;
    function setStaking(address token, address staking) external;
    function setOracle(address token, address oracle) external;
    function setIsStakingRewards(address token, bool isStakingRewards) external;
    function setIsStakingMineable(address token, bool isStakingMineable) external;
    function updateOracles(address[] memory tokens) external;
    function updateOracle(address token) external;
    function addStaking(address token, uint256 tokenType, address staking, address oracle, bool isStakingRewards, bool isStakingMineable) external;
    function removeStaking(address token, address staking) external;

    /* ---------- RRA ---------- */
    function createStaking(address token, bool ifCreateOracle) external returns (address staking, address oracle);
    function createStakingWithLiquidity(address token, uint256 tokenAmount, uint256 quoteAmount, bool ifCreateOracle) external returns (address staking, address oracle);
    function createOracle(address token) external returns (address);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICeresStaking {

    struct UserLock {
        uint256 shareAmount;
        uint256 timeEnd;
    }

    /* ---------- Views ---------- */
    function token() external view returns (address);
    function totalStaking() external view returns (uint256);
    function stakingBalanceOf(address account) external view returns (uint256);
    function totalShare() external view returns (uint256);
    function shareBalanceOf(address account) external view returns (uint256);
    function unlockedShareBalanceOf(address account) external view returns (uint256);
    function unlockedStakingBalanceOf(address account) external view returns (uint256);
    function lockTime() external view returns (uint256);
    function earned(address account) external view returns (uint256);
    function rewardRate() external view returns (uint256);
    function rewardsDuration() external view returns (uint256);
    function periodFinish() external view returns (uint256);
    function yieldAPR() external view returns (uint256);
    function value() external view returns (uint256);

    /* ---------- Functions ---------- */
    function stake(uint256 amount) external;
    function withdraw(uint256 shareAmount) external;
    function claimRewardWithPercent(uint256) external;
    function reinvestReward() external;
    function applyReward() external;
    function notifyReward(uint256 amount, uint256 duration) external;
    function approveBank(uint256 amount) external;
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICeresVault {

    /* ---------- Events ---------- */
    event Claim(address indexed from, uint256 amount);
    event Withdraw(address indexed from, uint256 amount);

    /* ---------- Functions ---------- */
    function withdraw(address token, uint256 amount) external;
    function claimFromBank(address staking, address token, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IOracle {

    /* ---------- Views ---------- */
    function token() external view returns (address);
    function getPrice() external view returns (uint256);
    function updatable() external view returns (bool);

    /* ---------- Functions ---------- */
    function update() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRedeemReceiver {

    /* ---------- Views ---------- */
    function redeemEarnedCrs(address account) external view returns (uint256);
    function redeemEarnedColValue(address account) external view returns (uint256);

    /* ---------- Functions ---------- */
    function notifyRedeem(uint256 ascAmount, uint256 crsAmount, uint256 colValue) external;
    function claimRedeemWithPercent(uint256 percent, address token) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

library CeresLibrary {

    function toAmountD18(address _token, uint256 _amount) internal view returns (uint256) {
        return _amount * 10 ** (18 - IERC20Metadata(_token).decimals());
    }

    function toAmountActual(address _token, uint256 _amountD18) internal view returns (uint256) {
        return _amountD18 / 10 ** (18 - IERC20Metadata(_token).decimals());
    }

    function calcRatioStep(address _collateral, uint256 _collateralAmount, uint256 _baseRatioStep, uint256 _minRatioStep, uint256 _maxRatioStep)
    internal view returns (uint256) {
        /* fixme: add code to calculated RatioStep according to _collateral && _collateralAmount */
        return uint256(blockhash(block.number - 1)) % 15 + 5;
    }
}