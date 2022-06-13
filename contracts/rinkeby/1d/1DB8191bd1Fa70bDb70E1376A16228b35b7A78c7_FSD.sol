// SPDX-License-Identifier: Unlicense

pragma solidity =0.6.8;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "../dependencies/ERC20ConvictionScore.sol";
import "../dependencies/Withdrawable.sol";
import "../dependencies/DSMath.sol";
import "../dependencies/FSOwnable.sol";
import "../interfaces/IFSDNetwork.sol";
import "../interfaces/IFSDVesting.sol";
import "../interfaces/IFSDVestingFactory.sol";
import "../interfaces/IFSD.sol";
import "./ABC.sol";

/**
 * @dev Implementation {FSD} ERC20 Token contract.
 *
 * The FSD contract allows depositing of ETH for bonding to curve and minting
 * FSD in return. Only 70% of the deposit is bonded to curve during VCWL phase
 * and the rest 30% is deposited to `fundingPool`.
 *
 * It also allows burning of FSD tokens to withdraw ETH. A portion of withdrawing ETH
 * reserve is taken as tribute fee which is distributed to existing network users on
 * the basis of their conviction scores.
 *
 * Has utility functions to modify the contract's state.
 *
 * Attributes:
 * - Mintable via an Augmented Bonding Curve
 * - Burnable via an Agumented Bonding Curve
 * - Tracks creations and timestamps
 */
// solhint-disable not-rely-on-time, var-name-mixedcase, reason-string /*
contract FSD is FSOwnable, ABC, ERC20ConvictionScore, Withdrawable, IFSD {
    /* ========== LIBRARIES ========== */

    using DSMath for uint256;
    using Address for address payable;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    // 70% bonding curve ratio
    uint256 private constant BONDING_CURVE_RATIO = 0.7 ether;
    // Uniswap Router
    IUniswapV2Router02 private constant ROUTER =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    // DAI
    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    // WETH
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // Funding pool needs to achieve 500 ether
    address public immutable fundingPool;
    // Timelock address
    address public immutable timelock;
    // FSD Network address
    IFSDNetwork public fsdNetwork;
    // FSD minter contract address
    address public minter;
    // currect phase of the FSD token
    Phase public override currentPhase;
    // Indicator of token tranfer pause
    bool public paused;
    // 3.5% tribute fee on exit
    uint256 private tributeFee = 0.035 ether;

    /* ========== EVENTS ========== */

    /**
     * @dev Emitted when the pause functionality is triggered.
     */
    event PauseToggled();

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Initialises the contract's state with {fundingPool} and {timelock} addresses.
     * It also passes token name and symbol to {ERC20ConvictionScore} contract and
     * the name to the Permit extension.
     */
    constructor(address _fundingPool, address _timelock)
        public
        ERC20Permit("FSD")
        ERC20ConvictionScore("FairSide Token", "FSD")
    {
        fundingPool = _fundingPool;
        timelock = _timelock;
    }

    /**
     * @dev receive functions for ETH
     */
    // solhint-disable-next-line
    receive() external payable {}

    /* ========== VIEWS ========== */

    /**
     * @dev Returns the amount of FSD available for minting after
     * reserve is increased by delta.
     */
    function getTokensMinted(uint256 investment)
        external
        view
        override
        returns (uint256)
    {
        return calculateDeltaOfFSD(getReserveBalance(), int256(investment));
    }

    /**
     * @dev Returns the amount of FSD available for burning after
     * reserve is decreased by delta.
     */
    function getTokensBurned(uint256 withdrawal)
        external
        view
        returns (uint256)
    {
        return calculateDeltaOfFSD(getReserveBalance(), -int256(withdrawal));
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @dev Allows minting of FSD tokens by depositing ETH for bonding in the contract.
     * During the Final phase, 100% of the deposited ETH are bonded.
     *
     * Requirements:
     * - bonding ETH amount cannot be zero
     * - the minted FSD amount must not be less than parameter {tokenMinimum}
     */
    function mint(address to, uint256 tokenMinimum)
        external
        payable
        override
        onlyMinterOrNetwork
        returns (uint256)
    {
        require(msg.value != 0, "FSD::mint: Deposit amount cannot be zero");

        return _mintInternal(to, tokenMinimum);
    }

    /**
     * @dev Allows minting of FSD tokens by depositing ETH for bonding in the contract.
     * During the Final phase, 100% of the deposited ETH are bonded.
     *
     * Requirements:
     * - bonding ETH amount cannot be zero
     * - the minted FSD amount must not be less than parameter {tokenMinimum}
     */
    function mintDirect(address to, uint256 amount)
        external
        override
        onlyMinter
    {
        require(
            currentPhase == Phase.Premine || currentPhase == Phase.KOL,
            "FSD::mintTo: Invalid Phase"
        );

        // if (amount >= uint256(governanceMinimumBalance)) {
        //     _bestowGovernanceStatus(to);
        // }

        _mint(to, amount);
    }

    /**
     * @dev Allows burning of FSD tokens for ETH that are withdrawable through
     * {Withdrawable::withdraw} function.
     * It also takes cut of {tributeFee} and adds it as tribute which is distributed
     * to the existing users of the network based on their conviction scores.
     *
     * Requirements:
     * - the FSD token amount being burned must not exceed parameter {tokenMaximum}
     */
    function burn(uint256 capitalDesired, uint256 tokenMaximum) external {
        require(currentPhase == Phase.Final, "FSD::burn: Invalid Phase");

        uint256 etherBalanceAtBurn = getReserveBalance();

        uint256 tokenAmount = calculateDeltaOfFSD(
            etherBalanceAtBurn,
            -int256(capitalDesired)
        );

        require(tokenAmount <= tokenMaximum, "FSD::burn: High Slippage");

        _burn(msg.sender, tokenAmount);

        // See: https://github.com/dapphub/ds-math#wmul
        uint256 tribute = capitalDesired.wmul(tributeFee);
        uint256 reserveWithdrawn = capitalDesired - tribute;

        (uint256 totalOpenReq, ) = fsdNetwork.getAdoptionStats();
        require(
            reserveWithdrawn <=
                (etherBalanceAtBurn - totalOpenReq).wmul(0.01 ether),
            "FSD::burn: Withdraw exceeds 1% of the capital pool"
        );

        _increaseWithdrawal(msg.sender, reserveWithdrawn);

        uint256 mintAmount = calculateDeltaOfFSD(
            etherBalanceAtBurn - reserveWithdrawn,
            int256(tribute)
        );

        _mint(address(this), mintAmount);
        _addTribute(mintAmount);
    }

    /**
     * @dev Allows claiming of all available tributes represented by param {num}.
     * It internally calls `_claimTribute` & `_claimGovernanceTribute`.
     *
     */
    function claimAvailableTributes(uint256 num) external override {
        _claimTribute(num);
        if (
            isGovernance[msg.sender] &&
            governanceThreshold <=
            getPriorConvictionScore(
                msg.sender,
                governanceTributes[num].blockNumber
            )
        ) _claimGovernanceTribute(num);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function phaseAdvance() external onlyOwner {
        require(
            currentPhase != Phase.Final,
            "FSD::phaseAdvance: FSD is already at its final phase"
        );
        currentPhase = Phase(uint8(currentPhase) + 1);
    }

    /**
     * @dev Allows claiming of all available tributes represented by param {num}.
     * It internally calls `_claimTribute` & `_claimGovernanceTribute`.
     *
     */
    function registerTribute(uint256 registrationTribute)
        external
        override
        onlyFSD
    {
        _registerTribute(registrationTribute);
    }

    /**
     * @dev Allows claiming of all available tributes represented by param {num}.
     * It internally calls `_claimTribute` & `_claimGovernanceTribute`.
     *
     */
    function registerGovernanceTribute(uint256 registrationTribute)
        external
        override
        onlyFSD
    {
        _registerGovernanceTribute(registrationTribute);
    }

    /**
     * @dev Adds staking rewards tribute gathered upon registration which is distributed
     * to the existing users of the network based on their conviction scores.
     *
     * Requirements:
     * - only {fsdNetwork} can call this function
     */
    function addRegistrationTribute(uint256 registrationTribute)
        external
        onlyOwner
    {
        _addTribute(registrationTribute);
    }

    /**
     * @dev Adds governance rewards tribute gathered upon registration which is distributed
     * to the existing users of the network based on their conviction scores.
     *
     * Requirements:
     * - only {fsdNetwork} can call this function
     */
    function addRegistrationTributeGovernance(uint256 registrationTribute)
        external
        onlyOwner
    {
        _addGovernanceTribute(registrationTribute);
    }

    /**
     * @dev Allows paying of claims upon processing of Cost Share Requests.
     * It pays claims in DAI when parameter {inStable} in true and otherwise perform
     * account for later withdrawal of ETH by the {beneficiary}.
     *
     * Requirements:
     * - only callable by FSD contract.
     */
    function payClaim(
        address beneficiary,
        uint256 amount,
        bool inStable
    ) external override onlyFSD {
        if (inStable) {
            IERC20(DAI).safeTransfer(beneficiary, amount);
        } else {
            _increaseWithdrawal(beneficiary, amount);
        }
    }

    /**
     * @dev Liquidates ETH to DAI through Uniswap AMM and returns the converted
     * DAI amount.
     *
     * Requirements:
     * - only FSD contract can call this function.
     * - the amount of DAI received after conversion must be greater or equal to param {min}
     */
    function liquidateEth(uint256 amount, uint256 min)
        external
        override
        onlyFSD
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = DAI;
        uint256[] memory amounts = ROUTER.swapExactETHForTokens{value: amount}(
            min,
            path,
            address(this),
            block.timestamp
        );
        return amounts[amounts.length - 1];
    }

    /**
     * @dev Liquidates DAI to ETH through Uniswap AMM.
     *
     * Requirements:
     * - only FSD contract can call this function.
     * - the amount of ETH received after conversion must be greater or equal to param {min}
     */
    function liquidateDai(uint256 amount, uint256 min)
        external
        override
        onlyFSD
    {
        IERC20(DAI).approve(address(ROUTER), amount);

        address[] memory path = new address[](2);
        path[0] = DAI;
        path[1] = WETH;
        ROUTER.swapExactTokensForETH(
            amount,
            min,
            path,
            address(this),
            block.timestamp
        );
    }

    /**
     * @dev Sets the gearing factor of the FSD formula.
     *
     * Requirements:
     * - only FSD contract can call this function.
     * - gearing factor must be more than zero.
     */
    function setGearingFactor(uint256 _gearingFactor) external onlyFSD {
        gearingFactor = _gearingFactor;
    }

    /**
     * @dev Renounces the contract's ownership by setting {owner} to address(0)
     * leaving the contract permanently without an owner.
     *
     * Requirements:
     * - only callable by {owner} or {timelock} contract.
     */
    function abdicate() external onlyTimelockOrOwner {
        _renounceOwnership();
    }

    /**
     * @dev Allows updating of governance threshold.
     *
     * Requirements:
     * - only callable by {owner} or {timelock} contract.
     */
    function updateGovernanceThreshold(uint256 _governanceThreshold)
        external
        onlyTimelockOrOwner
    {
        governanceThreshold = _governanceThreshold;
    }

    /**
     * @dev Allows updating of governance minimum balance.
     *
     * Requirements:
     * - only callable by {owner} or {timelock} contract.
     */
    function updateGovernanceMinimumBalance(int256 _governanceMinimumBalance)
        external
        onlyTimelockOrOwner
    {
        governanceMinimumBalance = _governanceMinimumBalance;
    }

    /**
     * @dev Allows updating of FSD minimum balance to acquire Conviction Score.
     *
     * Requirements:
     * - only callable by {owner} or {timelock} contract.
     */
    function updateminimumBalance(int256 _minimumBalance)
        external
        onlyTimelockOrOwner
    {
        minimumBalance = _minimumBalance;
    }

    /**
     * @dev Allows setting convictionless status of the {user}.
     * It also resets the conviction if it is already set.
     *
     * Requirements:
     * - only callable by {owner} or {timelock} contract.
     */
    function setConvictionless(address user, bool isConvictionless)
        external
        onlyTimelockOrOwner
    {
        convictionless[user] = isConvictionless;

        if (getPriorConvictionScore(user, block.number - 1) != 0) {
            _resetConviction(user);
        }
    }

    /**
     * @dev Sets membership fee.
     *
     * Requirements:
     * - only callable by governance or timelock contracts.
     */
    function setTributeFee(uint256 _tributeFee) external onlyTimelockOrOwner {
        tributeFee = _tributeFee;
    }

    /**
     * @dev Allows updating of {FairSideConviction} address. Invocable only once.
     *
     * Requirements:
     * - only callable by {owner} contract
     * - the param {_fairSideConviction} cannot be a zero address value
     */
    function setFairSideConviction(address _fairSideConviction)
        external
        onlyOwner
    {
        require(
            fairSideConviction == IFairSideConviction(0),
            "FSD::setFairSideConviction: Already Set!"
        );
        fairSideConviction = IFairSideConviction(_fairSideConviction);
        convictionless[_fairSideConviction] = true;
    }

    /**
     * @dev Allows updating of {_fsdNetwork} address. Invocable only once.
     *
     * Requirements:
     * - only callable by {owner} contract
     * - the param {_fsdNetwork} cannot be a zero address value
     */
    function setFairSideNetwork(IFSDNetwork _fsdNetwork) external onlyOwner {
        require(
            fsdNetwork == IFSDNetwork(0),
            "FSD::setFairSideNetwork: Already Set!"
        );
        fsdNetwork = _fsdNetwork;
    }

    /**
     * @dev Allows updating of {minter} address. Invocable only once.
     *
     * Requirements:
     * - only callable by {owner} contract
     * - the param {_minter} cannot be a zero address value
     */
    function setMinter(address _minter) external onlyOwner {
        require(
            _minter != address(0),
            "Vesting::setMinter: Cannot be the zero address"
        );
        require(minter == address(0), "Vesting::setMinter: Already set");
        minter = _minter;
        convictionless[address(minter)] = true;
    }

    /**
     * @dev Allows pausing token transfers.
     *
     * Requirements:
     * - only callable by {owner} contract
     */
    function togglePause() external onlyOwner {
        paused = !paused;
        emit PauseToggled();
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * ABC wrapper, returns the change in FSD supply upon
     * the total reserves and change in reserves.
     */
    function calculateDeltaOfFSD(uint256 _reserve, int256 _reserveDelta)
        internal
        view
        returns (uint256)
    {
        (
            uint256 openRequestsInEth,
            uint256 availableCostShareBenefits
        ) = fsdNetwork.getAdoptionStats();
        return
            _calculateDeltaOfFSD(
                _reserve,
                _reserveDelta,
                openRequestsInEth,
                availableCostShareBenefits
            );
    }

    function _mintInternal(address to, uint256 tokenMinimum)
        private
        returns (uint256)
    {
        uint256 bonded = msg.value;
        uint256 mintAmount = calculateDeltaOfFSD(
            getReserveBalance() - msg.value,
            int256(bonded)
        );

        require(mintAmount >= tokenMinimum, "FSD:: High Slippage");

        // if (mintAmount >= uint256(governanceMinimumBalance)) {
        //     _bestowGovernanceStatus(to);
        // }

        _mint(to, mintAmount);

        if (fundingPool.balance < 500 ether) {
            // See: https://github.com/dapphub/ds-math#wmul
            bonded = bonded.wmul(BONDING_CURVE_RATIO);

            uint256 maxAllowedInFundingPool = 500 ether - fundingPool.balance;
            uint256 amountAfterBonding = msg.value - bonded;

            uint256 toFundingPool = amountAfterBonding > maxAllowedInFundingPool
                ? maxAllowedInFundingPool
                : amountAfterBonding;

            payable(fundingPool).sendValue(toFundingPool);
        }

        return mintAmount;
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _onlyTimelockOrOwner() private view {
        require(
            msg.sender == timelock || msg.sender == owner(),
            "FSD:: only Timelock or Owner can call"
        );
    }

    function _onlyFSD() private view {
        require(msg.sender == address(fsdNetwork), "FSD:: only FSD can call");
    }

    function _onlyMinter() private view {
        require(msg.sender == minter, "FSD:: only FSD minter can call");
    }

    function _onlyMinterOrNetwork() private view {
        require(
            msg.sender == minter || msg.sender == address(fsdNetwork),
            "FSD:: only FSD minter or network can call"
        );
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        ERC20ConvictionScore._beforeTokenTransfer(from, to, amount);

        require(!paused, "FSD: token transfer while paused");
    }

    /* ========== MODIFIERS ========== */

    modifier onlyTimelockOrOwner() {
        _onlyTimelockOrOwner();
        _;
    }

    modifier onlyFSD() {
        _onlyFSD();
        _;
    }

    modifier onlyMinter() {
        _onlyMinter();
        _;
    }

    modifier onlyMinterOrNetwork() {
        _onlyMinterOrNetwork();
        _;
    }

    // /**
    //  * @dev Allows claiming of tribute represented by param {num}.
    //  * It internally calls `_claimGovernanceTribute`.
    //  *
    //  * Requirements:
    //  * - `msg.sender` should have governance status
    //  * - `msg.sender`'s conviction score must be greater or equal to {governanceThreshold}
    //  */
    // function claimGovernanceTribute(uint256 num) external override {
    //     require(
    //         isGovernance[msg.sender] &&
    //             governanceThreshold <=
    //             getPriorConvictionScore(
    //                 msg.sender,
    //                 governanceTributes[num].blockNumber
    //             ),
    //         "FSD::claimGovernanceTribute: Not a governance member"
    //     );
    //     _claimGovernanceTribute(num);
    // }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.6.8;

import "../dependencies/SafeUint224.sol";
import "../interfaces/IFairSideConviction.sol";
import "./CurveLock.sol";
import "./DSMath.sol";

/**
 * @dev Implementation of {ERC20ConvictionScore} contract.
 *
 * The ERC20ConvictionScore contract keeps track of conviction scores of users
 * on checkpoints basis.
 *
 * Allow assigning and removal of governance committee status of users if they
 * meet the {governanceMinimumBalance} and {governanceThreshold}.
 *
 * Allows users to exit from FSD network by minting conviction NFT and locking in
 * their FSD tokens and conviction score.
 *
 * Allows redemption of conviction NFT by owner assimilation of redeemed conviction
 * score with user's conviction score.
 */
// solhint-disable not-rely-on-time, var-name-mixedcase, reason-string /*
abstract contract ERC20ConvictionScore is CurveLock {
    /* ========== LIBRARIES ========== */

    using SafeUint224 for *;

    /* ========== STATE VARIABLES ========== */

    // Ten days in seconds
    uint256 private constant TEN_DAYS = 10 days;

    // The FairSideConviction ERC-721 token address
    IFairSideConviction public fairSideConviction;

    // Mapping indicating whether a user is part of the governance committee
    mapping(address => bool) public override isGovernance;

    // Mapping indicating whether a user should accrue conviction or not
    mapping(address => bool) public convictionless;

    // // Mapping indicating a user's conviction score update
    // mapping(address => uint256) public lastConvictionTs;

    // Conviction score necessary to become part of governance
    uint256 public override governanceThreshold = 10 * 10000e18; // 10 days * 10,000 units

    // Minimum balance
    int256 public override minimumBalance = 1000 ether; // 1,000 tokens

    // Minimum governance balance
    int256 public governanceMinimumBalance = 10000 ether; // 10,000 tokens

    /**
     * @dev A checkpoint for marking the conviction score from a given block
     * fromBlock: Block number of the checkpoint.
     * convictionScore: Conviction score at a given block.
     * ts: Timestamp of the block.
     */
    struct Checkpoint {
        uint32 fromBlock;
        uint224 convictionScore;
        uint256 ts;
    }

    // Conviction score based on # of days multiplied by # of FSD & NFT
    // A record of conviction score checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    // The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Initialises the contract's state and setup ERC20 name and symbol.
     *
     * Sets the {convictionless} status for {TOTAL_CONVICTION_SCORE} and {TOTAL_GOVERNANCE_SCORE}.
     */
    constructor(string memory name, string memory symbol)
        public
        ERC20(name, symbol)
    {
        convictionless[TOTAL_CONVICTION_SCORE] = true;
        convictionless[TOTAL_GOVERNANCE_SCORE] = true;
    }

    // solhint-disable-next-line
    function claimAvailableTributes(uint256 num) external virtual override {}

    // solhint-disable-next-line
    function registerTribute(uint256 num) external virtual override {}

    // solhint-disable-next-line
    function registerGovernanceTribute(uint256 num) external virtual override {}

    /* ========== VIEWS ========== */

    /**
     * @notice Determine the prior amount of conviction score for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the conviction score balance at
     * @return convictionScore The amount of conviction score the account had as of the given block
     */
    function getPriorConvictionScore(address account, uint256 blockNumber)
        public
        view
        override
        returns (uint224 convictionScore)
    {
        require(
            blockNumber < block.number,
            "ERC20ConvictionScore::getPriorConvictionScore: not yet determined"
        );

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].convictionScore;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;

        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow

            Checkpoint memory cp = checkpoints[account][center];

            if (cp.fromBlock == blockNumber) {
                return cp.convictionScore;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center > 0 ? center - 1 : 0;
            }
        }

        return checkpoints[account][lower].convictionScore;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @dev Updates the conviction score for `msg.sender`.
     * Internally calls `updateConvictionScore(address)` function.
     */
    function updateConvictionScore() external returns (uint256) {
        return updateConvictionScore(msg.sender);
    }

    /**
     * @dev Updates the conviction score for {user}.
     * Internally calls `_updateConvictionScore` and `_updateConvictionTotals` functions.
     */
    function updateConvictionScore(address user) public returns (uint256) {
        (
            uint224 convictionDelta,
            int224 governanceDelta
        ) = _updateConvictionScore(user, 0);

        _updateConvictionTotals(convictionDelta, governanceDelta);

        return uint256(convictionDelta);
    }

    /**
     * @dev Allows exiting from FSD Network by minting a conviction NFT
     * on {FairSideConviction} contract which locks their FSD amount
     * and conviction score.
     *
     * It resets the user's conviction score in contract.
     *
     * Requirements:
     * - score or locked amount, both must not be zero.
     */
    function tokenizeConviction(uint256 locked)
        external
        override
        returns (uint256)
    {
        if (locked > 0) {
            _transfer(msg.sender, address(fairSideConviction), locked);
        } else {
            updateConvictionScore(msg.sender);
        }

        (, , uint224 score, ) = _getCheckpointInfo(msg.sender);

        require(
            score != 0 || locked != 0,
            "ERC20ConvictionScore::tokenizeConviction: Invalid tokenized conviction"
        );

        bool wasGovernance = isGovernance[msg.sender];
        _resetConviction(msg.sender);

        return
            fairSideConviction.createConvictionNFT(
                msg.sender,
                uint256(score),
                locked,
                wasGovernance
            );
    }

    /**
     * @dev Allows redemption of conviction NFT and receives its locked FSD along
     * with locked conviction score.
     *
     * Increases the conviction score of user and total conviction score by
     * the conviction score redeemed from NFT.
     *
     * Increases total governance conviction score by redeemed conviction score
     * if the redeemer is already a part of governance committee or else it is
     * increased by the conventional conviction of user.
     */
    function acquireConviction(uint256 id) external returns (uint256) {
        (uint224 convictionDelta, , bool wasGovernance) = fairSideConviction
            .burn(msg.sender, id);

        (, , , uint256 prevTimestamp) = _getCheckpointInfo(msg.sender);
        uint224 userNew = _increaseConvictionScore(msg.sender, convictionDelta);
        int224 governanceDelta;

        if (isGovernance[msg.sender]) {
            governanceDelta = convictionDelta.safeSign(
                "ERC20ConvictionScore::acquireConviction: Abnormal NFT conviction"
            );
        } else if (
            wasGovernance ||
            _meetsGovernanceMinimum(
                balanceOf(msg.sender),
                userNew,
                prevTimestamp
            )
        ) {
            isGovernance[msg.sender] = true;

            governanceDelta = userNew.safeSign(
                "ERC20ConvictionScore::acquireConviction: Abnormal total conviction"
            );
        }

        _updateConvictionTotals(convictionDelta, governanceDelta);

        return uint256(convictionDelta);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @dev Sets governance status of the user when it meets the {governanceThreshold}.
     */
    function _bestowGovernanceStatus(address user) internal {
        if (!isGovernance[user]) {
            isGovernance[user] = true;
        }
    }

    /**
     * @dev Returns the boolean value indicating if user meets governance minimum
     */
    function _meetsGovernanceMinimum(
        uint256 balance,
        uint224 convictionScore,
        uint256 ts
    ) internal view returns (bool) {
        return
            (convictionScore >= governanceThreshold) &&
            (balance >= uint256(governanceMinimumBalance)) &&
            (block.timestamp - ts) >= TEN_DAYS;
    }

    /**
     * @dev Returns last checkpoint info of a user.
     */
    function _getCheckpointInfo(address user)
        internal
        view
        returns (
            uint32 checkpointCount,
            uint32 prevFromBlock,
            uint224 prevConvictionScore,
            uint256 prevTimestamp
        )
    {
        checkpointCount = numCheckpoints[user];

        if (checkpointCount > 0) {
            Checkpoint memory checkpoint = checkpoints[user][
                checkpointCount - 1
            ];

            prevFromBlock = checkpoint.fromBlock;
            prevConvictionScore = checkpoint.convictionScore;
            prevTimestamp = checkpoint.ts;
        }
    }

    /**
     * @dev Writes checkpoint for a user.
     *
     * Requirements:
     * - block.number must not exceed `uint32`.
     */
    function _writeCheckpoint(
        address user,
        uint32 nCheckpoints,
        uint224 newCS
    ) internal {
        uint32 blockNumber = block.number.safe32(
            "ERC20ConvictionScore::_writeCheckpoint: block number exceeds 32 bits"
        );

        Checkpoint storage checkpoint = checkpoints[user][nCheckpoints - 1];

        if (nCheckpoints > 0 && checkpoint.fromBlock == blockNumber) {
            checkpoint.convictionScore = newCS;
        } else {
            checkpoints[user][nCheckpoints] = Checkpoint(
                blockNumber,
                newCS,
                block.timestamp
            );

            numCheckpoints[user] = nCheckpoints + 1;
        }
    }

    /**
     * @dev Increases conviction score of a {user} by {amount}
     * and write the checkpoint.
     *
     * Requirements:
     * - {amount} must not overflow `uint224`.
     */
    function _increaseConvictionScore(address user, uint224 amount)
        internal
        returns (uint224 newConvictionScore)
    {
        (
            uint32 checkpointCount,
            ,
            uint224 prevConvictionScore,

        ) = _getCheckpointInfo(user);

        if (amount == 0) return prevConvictionScore;

        newConvictionScore = prevConvictionScore.add224(
            amount,
            "ERC20ConvictionScore::_increaseConvictionScore: conviction score amount overflows"
        );

        _writeCheckpoint(user, checkpointCount, newConvictionScore);
    }

    /**
     * @dev Decreases conviction score of a {user} by {amount}
     * and write the checkpoint.
     *
     * Requirements:
     * - {amount} must not overflow `uint224`.
     */
    function _decreaseConvictionScore(address user, uint224 amount)
        internal
        returns (uint224 newConvictionScore)
    {
        (
            uint32 checkpointCount,
            ,
            uint224 prevConvictionScore,

        ) = _getCheckpointInfo(user);

        if (amount == 0) return prevConvictionScore;

        newConvictionScore = prevConvictionScore.sub224(
            amount,
            "ERC20ConvictionScore::_decreaseConvictionScore: conviction score amount underflows"
        );

        _writeCheckpoint(user, checkpointCount, newConvictionScore);
    }

    /**
     * @dev Apply conviction score of a {user} by {delta}
     * and write the checkpoint.
     *
     * Conviction score is increased if delta is greater than 0 and
     * decreased when delta is less than 0.
     *
     * Requirements:
     * - {amount} must not overflow `uint224`.
     */
    function _applyConvictionDelta(address user, int224 delta)
        internal
        returns (uint224 newConvictionScore)
    {
        (
            uint32 checkpointCount,
            ,
            uint224 prevConvictionScore,

        ) = _getCheckpointInfo(user);

        if (delta == 0) return prevConvictionScore;

        newConvictionScore = delta > 0
            ? prevConvictionScore.add224(
                uint224(delta),
                "ERC20ConvictionScore::_applyConvictionDelta: conviction score amount overflows"
            )
            : prevConvictionScore.sub224(
                uint224(-delta),
                "ERC20ConvictionScore::_applyConvictionDelta: conviction score amount underflows"
            );

        _writeCheckpoint(user, checkpointCount, newConvictionScore);
    }

    /**
     * @dev Resets the user's staking and governance conviction scores with
     * updating the state variables of {TOTAL_CONVICTION_SCORE} and {TOTAL_GOVERNANCE_SCORE}.
     */
    function _resetConviction(address user) internal {
        (uint32 userNum, , uint224 convictionDelta, ) = _getCheckpointInfo(
            user
        );
        _writeCheckpoint(user, userNum, 0);

        _decreaseConvictionScore(TOTAL_CONVICTION_SCORE, convictionDelta);

        if (isGovernance[user]) {
            isGovernance[user] = false;
            _decreaseConvictionScore(TOTAL_GOVERNANCE_SCORE, convictionDelta);
        }
    }

    /**
     * @dev Updates the state variables of {TOTAL_CONVICTION_SCORE} and {TOTAL_GOVERNANCE_SCORE}
     * by {convictionDelta} and {governanceDelta}, respectively.
     */
    function _updateConvictionTotals(
        uint224 convictionDelta,
        int224 governanceDelta
    ) internal {
        _increaseConvictionScore(TOTAL_CONVICTION_SCORE, convictionDelta);
        _applyConvictionDelta(TOTAL_GOVERNANCE_SCORE, governanceDelta);
    }

    /**
     * @dev Updates the conviction score of a user and returns the conviction
     * and governance delta.
     *
     * If the user maintains {governanceMinimumBalance} and once the accrued
     * conviction amount exceeds {governanceThreshold}, then it is awarded governance
     * committee status and the user becomes eligible to vote.
     *
     * Updates the user's conviction score with the newly accrued amount since last update.
     *
     * Removes the governance committee status of user if its balance falls below
     * than {governanceMinimumBalance}.
     *
     * Returns the change in conventional conviction and governance conviction.
     *
     * Requirements:
     * - the amounts in accounting of conviction scores must not overflow.
     */
    function _updateConvictionScore(address user, int256 amount)
        internal
        returns (uint224 convictionDelta, int224 governanceDelta)
    {
        if (convictionless[user]) return (0, 0);

        uint256 balance = balanceOf(user);

        if (balance < uint256(minimumBalance)) return (0, 0);

        (
            uint32 checkpointCount,
            ,
            uint224 prevConvictionScore,
            uint256 prevTimestamp
        ) = _getCheckpointInfo(user);

        convictionDelta = (balance.mul(block.timestamp - prevTimestamp) /
            1 days).safe224(
                "ERC20ConvictionScore::_updateConvictionScore: Conviction score has reached maximum limit"
            );

        if (checkpointCount == 0) {
            _writeCheckpoint(user, 0, 0);
            return (convictionDelta, 0);
        }

        bool hasMinimumGovernanceBalance = (int256(balance) + amount) >=
            governanceMinimumBalance;

        if (
            convictionDelta == 0 &&
            isGovernance[user] &&
            !hasMinimumGovernanceBalance
        ) {
            isGovernance[user] = false;

            governanceDelta = -prevConvictionScore.safeSign(
                "ERC20ConvictionScore::_updateConvictionScore: Abnormal total conviction"
            );

            return (convictionDelta, governanceDelta);
        }

        uint224 userNew = prevConvictionScore.add224(
            convictionDelta,
            "ERC20ConvictionScore::_updateConvictionScore: conviction score amount overflows"
        );

        _writeCheckpoint(user, checkpointCount, userNew);

        if (address(fairSideConviction) == user) {
            governanceDelta = 0;
        } else if (isGovernance[user]) {
            if (hasMinimumGovernanceBalance) {
                governanceDelta = convictionDelta.safeSign(
                    "ERC20ConvictionScore::_updateConvictionScore: Abnormal conviction increase"
                );
            } else {
                isGovernance[user] = false;
                governanceDelta = -getPriorConvictionScore(
                    user,
                    block.number - 1
                ).safeSign(
                        "ERC20ConvictionScore::_updateConvictionScore: Abnormal total conviction"
                    );
            }
        } else if (
            userNew >= governanceThreshold &&
            hasMinimumGovernanceBalance &&
            (block.timestamp - prevTimestamp) >= TEN_DAYS
        ) {
            isGovernance[user] = true;
            governanceDelta = userNew.safeSign(
                "ERC20ConvictionScore::_updateConvictionScore: Abnormal total conviction"
            );
        }
    }

    /**
     * @dev A transfer hook that updates sender and recipient's conviction scores
     * and also update the total staking and governance scores.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        CurveLock._beforeTokenTransfer(from, to, amount);

        (
            uint224 convictionDeltaA,
            int224 governanceDeltaA
        ) = _updateConvictionScore(from, -int256(amount));

        (
            uint224 convictionDeltaB,
            int224 governanceDeltaB
        ) = _updateConvictionScore(to, int256(amount));

        uint224 convictionDelta = convictionDeltaA.add224(
            convictionDeltaB,
            "ERC20ConvictionScore::_beforeTokenTransfer: Total Conviction Overflow"
        );

        int224 governanceDelta = governanceDeltaA.addSigned224(
            governanceDeltaB,
            "ERC20ConvictionScore::_beforeTokenTransfer: Governance Conviction Overflow"
        );

        _updateConvictionTotals(convictionDelta, governanceDelta);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /* ========== MODIFIERS ========== */

    // function claimGovernanceTribute(uint256 num) external virtual override {}
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.6.8;

import "@openzeppelin/contracts/utils/Address.sol";
import "./DSMath.sol";

/**
 * @dev Implementation of {Withdrawable} contract.
 *
 * The Withdrawable contract allows assigning withdrawable ETH amounts
 * to users that they can later withdraw using the {withdraw} function.
 *
 * This contract is used in the inheritance chain of FSD contract and
 * the amounts withdrawable through {withdraw} function are the ETH
 * amounts available to user either after burning FSD tokens or when
 * the Cost Share Request(CSR) of the user is approved and the payout
 * is in ETH.
 */
// solhint-disable not-rely-on-time, var-name-mixedcase, reason-string /*
contract Withdrawable {
    /* ========== LIBRARIES ========== */

    using DSMath for uint256;
    using Address for address payable;

    /* ========== STATE VARIABLES ========== */

    // Prevent re-entrancy in burn

    // mapping of user to withdrawable amount.
    mapping(address => uint256) public availableWithdrawal;

    // total withdrawable amount for all users in ETH.
    uint256 public pendingWithdrawals;

    /* ========== EVENTS ========== */

    /* ========== CONSTRUCTOR ========== */

    /* ========== VIEWS ========== */

    /**
     * @dev Returns available ETH balance minus pending withdraws.
     */
    function getReserveBalance() public view returns (uint256) {
        return address(this).balance.sub(pendingWithdrawals);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @dev Allows withdrawing of ETH claimable amount by `msg.sender`.
     * Updates the user's available withdrawal amount and the total
     * pending claimable amount.
     */
    function withdraw() external {
        uint256 reserveAmount = availableWithdrawal[msg.sender];
        require(reserveAmount > 0, "FSD::withdraw: Insufficient Withdrawal");
        delete availableWithdrawal[msg.sender];
        pendingWithdrawals = pendingWithdrawals.sub(reserveAmount);
        msg.sender.sendValue(reserveAmount);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @dev Increases withdrawable amount for a user.
     * Updates the user's available withdrawal amount and the total
     * pending claimable amount.
     */
    function _increaseWithdrawal(address user, uint256 amount) internal {
        availableWithdrawal[user] = availableWithdrawal[user].add(amount);
        pendingWithdrawals = pendingWithdrawals.add(amount);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /* ========== MODIFIERS ========== */
}

// SPDX-License-Identifier: Unlicense

/// Copied from: https://github.com/dapphub/ds-math/blob/master/src/math.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >0.4.13;

library DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    //rounds to zero if x*y < WAD / 2
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    //rounds to zero if x*y < WAD / 2
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    //rounds to zero if x*y < RAY / 2
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.8;

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
// solhint-disable not-rely-on-time, var-name-mixedcase, reason-string /*
abstract contract FSOwnable {
    /* ========== STATE VARIABLES ========== */
    address private _owner;

    /* ========== EVENTS ========== */

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /* ========== VIEWS ========== */

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _renounceOwnership();
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "FSOwnable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @dev Allows current owner to renounce their ownership.
     */
    function _renounceOwnership() internal {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /* ========== MODIFIERS ========== */

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "FSOwnable: caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.6.8;

interface IFSDNetwork {
    function getAdoptionStats() external view returns (uint256, uint256);
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.6.8;

interface IFSDVesting {
    function claimVestedTokens() external;

    function updateVestedTokens(uint256 _amount) external;
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.6.8;

interface IFSDVestingFactory {
    function createVestingPRE(address beneficiary, uint256 amount)
        external
        returns (address);

    function createVestingVC(address beneficiary, uint256 amount)
        external
        returns (address);

    function createVestingKOL(address beneficiary, uint256 amount)
        external
        returns (address);
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.6.8;

interface IFSD {
    /**
     * @dev Phases of the FSD token.
     * Premine: Token pre-mine
     * KOL: KOL token pre-mine
     * VCWL: Venture Capital white-list
     * CWL: Community white-list
     * Final: Curve indefinitely open
     */
    enum Phase {
        Premine,
        KOL,
        VCWL,
        CWL,
        Final
    }

    function currentPhase() external returns (Phase);

    function getTokensMinted(uint256 investment)
        external
        view
        returns (uint256);

    function payClaim(
        address beneficiary,
        uint256 amount,
        bool inStable
    ) external;

    function liquidateEth(uint256 amount, uint256 min)
        external
        returns (uint256);

    function liquidateDai(uint256 amount, uint256 min) external;

    function mint(address to, uint256 tokenMinimum)
        external
        payable
        returns (uint256);

    function mintDirect(address to, uint256 amount) external;
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.6.8;

import "../dependencies/DSMath.sol";
import "../dependencies/FairSideFormula.sol";

/**
 * @dev Implementation of Augmented Bonding Curve (ABC) contract.
 *
 * Attributes:
 * - Calculates amount of FSD to be minted given a particular token supply and an amount of reserve
 * - Calculates amount of reserve to be unlocked given a particular token supply and an amount of FSD tokens
 * - Tracks creations and timestamps
 */
// solhint-disable not-rely-on-time, var-name-mixedcase, reason-string /*
contract ABC {
    /* ========== LIBRARIES ========== */

    using DSMath for uint256;

    /* ========== STATE VARIABLES ========== */

    /**
     * @dev The factor used to adjust maximum Cost Share Benefits the network
     * can offer in relation to its Capital Pool of funds in ETH. (initial Gearing factor = 10)
     */
    uint256 public gearingFactor = 1000;

    /* ========== EVENTS ========== */

    /* ========== CONSTRUCTOR ========== */

    /* ========== VIEWS ========== */

    /* ========== MUTATIVE FUNCTIONS ========== */

    /* ========== RESTRICTED FUNCTIONS ========== */

    /* ========== INTERNAL FUNCTIONS ========== */

    // Returns absolute value of the parameter {a}.
    function _abs(int256 a) internal pure returns (uint256) {
        return uint256(a < 0 ? -a : a);
    }

    /**
     * @dev Returns the delta amount representing change in the supply of FSD token
     * supply after the change in reserve amount is considered.
     *
     * Requirement:
     * - the reserve amount should not go below {Fshare}.
     */
    function _calculateDeltaOfFSD(
        uint256 _reserve,
        int256 _reserveDelta,
        uint256 _openRequests,
        uint256 _availableCSB
    ) internal view returns (uint256) {
        // FSHARE = Total Available Cost Share Benefits / Gearing Factor
        uint256 fShare = _availableCSB.mul(100) / gearingFactor;
        // Floor of 4000 ETH
        if (fShare < 4000 ether) fShare = 4000 ether;

        // Capital Pool = Total Funds held in ETH – Open Cost Share Requests
        // Open Cost Share Request = Cost share request awaiting assessor consensus
        uint256 capitalPool = _reserve - _openRequests;

        uint256 currentSupply = FairSideFormula.g(capitalPool, fShare);

        uint256 nextSupply;
        if (_reserveDelta < 0) {
            uint256 capitalPostWithdrawal = capitalPool.sub(
                _abs(_reserveDelta)
            );
            require(
                capitalPostWithdrawal >= fShare,
                "ABC::_calculateDeltaOfFSD: Insufficient Capital to Withdraw"
            );
            nextSupply = FairSideFormula.g(capitalPostWithdrawal, fShare);
        } else {
            nextSupply = FairSideFormula.g(
                capitalPool.add(uint256(_reserveDelta)),
                fShare
            );
        }

        return
            _reserveDelta < 0
                ? currentSupply.sub(nextSupply)
                : nextSupply.sub(currentSupply);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /* ========== MODIFIERS ========== */
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.6.8;

library SafeUint224 {
    function safe224(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint224)
    {
        require(n <= type(uint224).max, errorMessage);
        return uint224(n);
    }

    function safeSign(uint224 n, string memory errorMessage)
        internal
        pure
        returns (int224)
    {
        require(n <= uint224(type(int224).max), errorMessage);
        return int224(n);
    }

    function add224(
        uint224 a,
        uint224 b,
        string memory errorMessage
    ) internal pure returns (uint224) {
        uint224 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function addSigned224(
        int224 a,
        int224 b,
        string memory errorMessage
    ) internal pure returns (int224) {
        int224 c = a + b;
        require(b > 0 ? c > a : c <= a, errorMessage); // Should never occur
        return c;
    }

    function sub224(
        uint224 a,
        uint224 b,
        string memory errorMessage
    ) internal pure returns (uint224) {
        uint224 c = a - b;
        require(c <= a, errorMessage);
        return c;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.6.8;

interface IFairSideConviction {
    function createConvictionNFT(
        address,
        uint256,
        uint256,
        bool
    ) external returns (uint256);

    function burn(address, uint256)
        external
        returns (
            uint224,
            uint256,
            bool
        );
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.6.8;

import "./TributeAccrual.sol";

/**
 * @dev Implementation of {CurveLock} contract.
 *
 * The contract enables locking the transfer of FSD in the same block
 * as it is minted or burned.
 *
 * This contract lies in inheritance chain of FSD contract.
 */
// solhint-disable not-rely-on-time, var-name-mixedcase, reason-string /*
abstract contract CurveLock is TributeAccrual {
    /* ========== STATE VARIABLES ========== */

    // mapping of user to locking block number.
    mapping(address => uint256) internal _curveBlock;

    /* ========== CONSTRUCTOR ========== */

    /* ========== VIEWS ========== */

    /* ========== MUTATIVE FUNCTIONS ========== */

    /* ========== RESTRICTED FUNCTIONS ========== */

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @dev A hook function that is executed upon transfer, mint and burn of tokens.
     *
     * It enables to disallow user performing FSD transfers within the same block as they
     * enter or exit the FSD system.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        ERC20._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            require(
                _curveBlock[to] < block.number,
                "CurveLock::_beforeTokenTransfer: Cannot transfer after a mint/burn"
            );
            _curveBlock[to] = block.number;
        } else {
            require(
                _curveBlock[from] < block.number,
                "CurveLock::_beforeTokenTransfer: Cannot transfer after a mint/burn"
            );
            if (to == address(0)) {
                _curveBlock[from] = block.number;
            }
        }
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /* ========== MODIFIERS ========== */
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.6.8;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/drafts/ERC20Permit.sol";
import "../dependencies/SafeUint32.sol";
import "../dependencies/SafeUint224.sol";
import "../interfaces/IERC20ConvictionScore.sol";

/**
 * @dev Implementation of {TributeAccrual} contract.
 *
 * The TributeAccrual contract implements logic to keep accounting of
 * tribute amounts. The tributes are accrued as percentage fee deducted
 * when users withdraw their FSD for exiting the network.
 *
 * The accumulated tributes are distributed to the remaining users of
 * the FSD Network based on their conviction scores.
 *
 * Provides function to view and claim the claimable tribute amounts for users.
 */
// solhint-disable not-rely-on-time, var-name-mixedcase, reason-string /*
abstract contract TributeAccrual is ERC20Permit, IERC20ConvictionScore {
    /* ========== LIBRARIES ========== */

    using SafeMath for uint256;
    using SafeUint32 for *;
    using SafeUint224 for *;

    /* ========== STATE VARIABLES ========== */

    /**
     * @dev {Tribute} struct contains parameters for a tribute.
     * blockNumber: Block number at which tribute was added.
     * amount: Amount of FSD for distribution associated with tribute.
     * claimed: Mapping from `address` -> `bool` representing tribute
     * claimed status of an address.
     */
    struct Tribute {
        uint32 blockNumber;
        uint224 amount;
        mapping(address => bool) claimed;
    }

    // mapping of tribute id to tribute struct.
    mapping(uint256 => Tribute) internal tributes;

    // pending tributes waiting for approval.
    uint224 internal pendingTributes;

    // total number of tributes.
    uint256 internal totalTributes;

    // mapping of governance tribute id to governance tribute struct.
    mapping(uint256 => Tribute) internal governanceTributes;

    // pending governance tributes waiting for approval.
    uint224 internal pendingGovernanceTributes;

    // total number governance tributes.
    uint256 internal totalGovernanceTributes;

    // Address to signify snapshotted total conviction score and governance conviction score
    address internal constant TOTAL_CONVICTION_SCORE = address(0);
    address internal constant TOTAL_GOVERNANCE_SCORE =
        address(type(uint160).max);

    /* ========== EVENTS ========== */

    // Event emitted when a user claims its share from a tribute.
    event TributeClaimed(address indexed beneficiary, uint256 amount);
    // Event emitted when a user claims its share from a governance tribute.
    event GovernanceTributeClaimed(address indexed beneficiary, uint256 amount);

    /* ========== CONSTRUCTOR ========== */

    /* ========== VIEWS ========== */

    /**
     * @dev Returns total amount of FSD that are claimable by `msg.sender`
     * in all staking tributes and all governance tributes.
     */
    function totalAvailableTribute(uint256 offset)
        external
        view
        override
        returns (uint256 total)
    {
        uint256 _totalTributes = totalTributes;
        for (uint256 i = offset; i < _totalTributes; i++)
            total = total.add(availableTribute(i));

        uint256 _totalGovernanceTributes = totalGovernanceTributes;
        for (uint256 i = offset; i < _totalGovernanceTributes; i++)
            total = total.add(availableGovernanceTribute(i));
    }

    /**
     * @dev Returns tribute share of `msg.sender` in staking tribute represented by {num}.
     */
    function availableTribute(uint256 num)
        public
        view
        override
        returns (uint256)
    {
        Tribute storage tribute = tributes[num];

        if (tributes[num].claimed[msg.sender]) return 0;

        uint256 userCS = uint256(
            getPriorConvictionScore(msg.sender, tribute.blockNumber)
        );
        uint256 totalCS = uint256(
            getPriorConvictionScore(TOTAL_CONVICTION_SCORE, tribute.blockNumber)
        );
        uint256 amount = uint256(tribute.amount);

        return amount.mul(userCS).div(totalCS);
    }

    /**
     * @dev Returns tribute share of `msg.sender` in governance tribute represented by {num}.
     */
    function availableGovernanceTribute(uint256 num)
        public
        view
        override
        returns (uint256)
    {
        Tribute storage tribute = governanceTributes[num];

        if (governanceTributes[num].claimed[msg.sender]) return 0;

        uint256 userCS = uint256(
            getPriorConvictionScore(msg.sender, tribute.blockNumber)
        );
        uint256 totalCS = uint256(
            getPriorConvictionScore(TOTAL_GOVERNANCE_SCORE, tribute.blockNumber)
        );
        uint256 amount = uint256(tribute.amount);

        return amount.mul(userCS).div(totalCS);
    }

    function getPriorConvictionScore(address user, uint256 blockNumber)
        public
        view
        virtual
        override
        returns (uint224);

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @dev Allows claiming of staking tribute by `msg.sender`.
     * It updates the claimed status of user against the tribute
     * being claimed.
     *
     * Requirements:
     * - claiming amount must not be 0.
     */
    function _claimTribute(uint256 num) internal {
        uint256 tribute = availableTribute(num);

        require(
            tribute != 0,
            "TributeAccrual::_claimTribute: No fees are claimable"
        );

        tributes[num].claimed[msg.sender] = true;

        _transfer(address(this), msg.sender, tribute);

        emit TributeClaimed(msg.sender, tribute);
    }

    /**
     * @dev Allows claiming of governance tribute by `msg.sender`.
     * It updates the claimed status of user against the tribute
     * being claimed.
     *
     * Requirements:
     * - claiming amount must not be 0.
     */
    function _claimGovernanceTribute(uint256 num) internal {
        uint256 tribute = availableGovernanceTribute(num);

        require(
            tribute != 0,
            "TributeAccrual::_claimGovernanceTribute: No fees are claimable"
        );

        governanceTributes[num].claimed[msg.sender] = true;

        _transfer(address(this), msg.sender, tribute);

        emit GovernanceTributeClaimed(msg.sender, tribute);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @dev Increases the pending tributes.
     *
     * Requirements:
     * - reverts if tribute amount exceeds `uint224`.
     */
    function _registerTribute(uint256 tribute) internal {
        uint224 _tribute = tribute.safe224(
            "TributeAccrual::_registerTribute: Tribute overflow"
        );

        pendingTributes = pendingTributes.add224(
            _tribute,
            "TributeAccrual::_registerTribute: Tribute overflow"
        );
    }

    /**
     * @dev Increases the pending governance tributes.
     *
     * Requirements:
     * - reverts if tribute amount exceeds `uint224`.
     */
    function _registerGovernanceTribute(uint256 tribute) internal {
        uint224 _tribute = tribute.safe224(
            "TributeAccrual::_registerGovernanceTribute: Tribute overflow"
        );

        pendingGovernanceTributes = pendingGovernanceTributes.add224(
            _tribute,
            "TributeAccrual::_registerGovernanceTribute: Tribute overflow"
        );
    }

    /**
     * @dev Adds tribute amount to the {tributes} mapping against a
     * new tribute id.
     *
     * Tribute amounts added in the same block are stored against the same
     * block number.
     *
     * Requirements:
     * - reverts if tribute amount exceeds `uint224`.
     * - reverts if block.number exceeds `uint32`.
     */
    function _addTribute(uint256 tribute) internal {
        uint224 _tribute = tribute.safe224(
            "TributeAccrual::_addTribute: Tribute overflow"
        );

        Tribute storage lastTribute = tributes[totalTributes - 1];

        if (lastTribute.blockNumber == block.number) {
            lastTribute.amount = lastTribute.amount.add224(
                _tribute,
                "TributeAccrual::_addTribute: Addition of tributes overflow"
            );
        } else {
            Tribute storage newTribute = tributes[totalTributes++];
            newTribute.amount = _tribute;
            newTribute.blockNumber = block.number.safe32(
                "TributeAccrual::_addTribute: Block number overflow"
            );
        }

        pendingTributes = pendingTributes.sub224(
            _tribute,
            "TributeAccrual::_addTribute: Pending tribute underflow"
        );
    }

    /**
     * @dev Adds governance tribute amount to the {governanceTributes} mapping
     * against a new tribute id.
     *
     * Tribute amounts added in the same block are stored against the same
     * block number.
     *
     * Requirements:
     * - reverts if tribute amount exceeds `uint224`.
     * - reverts if block.number exceeds `uint32`.
     */
    function _addGovernanceTribute(uint256 tribute) internal {
        uint224 _tribute = tribute.safe224(
            "TributeAccrual::_addTribute: Tribute overflow"
        );

        Tribute storage lastTribute = governanceTributes[
            totalGovernanceTributes - 1
        ];

        if (lastTribute.blockNumber == block.number) {
            lastTribute.amount = lastTribute.amount.add224(
                _tribute,
                "TributeAccrual::_addTribute: Addition of tributes overflow"
            );
        } else {
            Tribute storage newTribute = governanceTributes[
                totalGovernanceTributes++
            ];
            newTribute.amount = _tribute;
            newTribute.blockNumber = block.number.safe32(
                "TributeAccrual::_addTribute: Block number overflow"
            );
        }

        pendingGovernanceTributes = pendingGovernanceTributes.sub224(
            _tribute,
            "TributeAccrual::_addGovernanceTribute: Pending tribute underflow"
        );
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /* ========== MODIFIERS ========== */
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.5 <0.8.0;

import "../token/ERC20/ERC20.sol";
import "./IERC20Permit.sol";
import "../cryptography/ECDSA.sol";
import "../utils/Counters.sol";
import "./EIP712.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping (address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) internal EIP712(name, "1") {
    }

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual override {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                _nonces[owner].current(),
                deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _nonces[owner].increment();
        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.6.8;

library SafeUint32 {
    function safe32(
        uint256 n,
        string memory errorMessage
    ) internal pure returns (uint32) {
        require(n <= type(uint32).max, errorMessage);
        return uint32(n);
    }

    function safeSign(
        uint32 n,
        string memory errorMessage
    ) internal pure returns (int32) {
        require(n <= uint32(type(int32).max), errorMessage);
        return int32(n);
    }

    function add32(
        uint32 a,
        uint32 b,
        string memory errorMessage
    ) internal pure returns (uint32) {
        uint32 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function addSigned32(
        int32 a,
        int32 b,
        string memory error
    ) internal pure returns (int32) {
        int32 c = a + b;
        require(b > 0 ? c > a : c <= a, error); // Should never occur
        return c;
    }

    function sub32(
        uint32 a,
        uint32 b,
        string memory errorMessage
    ) internal pure returns (uint32) {
        uint32 c = a - b;
        require(c <= a, errorMessage);
        return c;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.6.8;

import "./ITributeAccrual.sol";

interface IERC20ConvictionScore is ITributeAccrual {
    function getPriorConvictionScore(address user, uint256 blockNumber)
        external
        view
        returns (uint224);

    function governanceThreshold() external view returns (uint256);

    function isGovernance(address member) external view returns (bool);

    function minimumBalance() external view returns (int256);

    function tokenizeConviction(uint256 locked) external returns (uint256);

    function claimAvailableTributes(uint256 num) external;

    function registerTribute(uint256 num) external;

    function registerGovernanceTribute(uint256 num) external;

    // function claimTribute(uint256 num) external;

    // function claimGovernanceTribute(uint256 num) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;
    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) internal {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = _getChainId();
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view virtual returns (bytes32) {
        if (_getChainId() == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                typeHash,
                name,
                version,
                _getChainId(),
                address(this)
            )
        );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }

    function _getChainId() private view returns (uint256 chainId) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.6.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITributeAccrual is IERC20 {
    function totalAvailableTribute(uint256 offset)
        external
        view
        returns (uint256 total);

    function availableTribute(uint256 num) external view returns (uint256);

    function availableGovernanceTribute(uint256 num)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: Unlicense

pragma solidity =0.6.8;

import "./ABDKMathQuad.sol";

// solhint-disable not-rely-on-time, var-name-mixedcase, reason-string /*
library FairSideFormula {
    using ABDKMathQuad for bytes16;

    // A constant (adjusted before launch, in precalculated values below assumed to be 0.00006)
    bytes16 private constant A = 0x3ff0f75104d551d68c692f6e82949a56;
    // C constant (adjusted before launch, in precalculated values below assumed to be 55,000,000)
    bytes16 private constant C = 0x4018a39de00000000000000000000000;
    // π / 4
    bytes16 private constant PI_4 = 0x3ffe921fb78121fb78121fb78121fb78;
    // π / 2
    bytes16 private constant PI_2 = 0x3fff921fb78121fb78121fb78121fb78;
    // 0.2447: constant in the approximation of arctan
    bytes16 private constant APPROX_A = 0x3ffcf525460aa64c2f837b4a2339c0eb;
    // 0.0663: constant in the approximation of arctan
    bytes16 private constant APPROX_B = 0x3ffb0f9096bb98c7e28240b780346dc5;
    // 1: in quadruple precision form
    bytes16 private constant ONE = 0x3fff0000000000000000000000000000;
    // 2: in quadruple precision form
    bytes16 private constant TWO = 0x40000000000000000000000000000000;
    // 975.61: older outer constant (I couldn't reverse engineer the exact formula)
    // 22330.695286005: new outer constant from formula C^(1/4)/(4*sqrt(2)*A^(3/4))  // 22330.695286005448
    bytes16 private constant MULTIPLIER_FULL =
        0x400d5ceac7f90df35db03465b840a3b4;
    /* // 3.06356:
    bytes16 private constant MULTIPLIER_ARCTAN =
        0x40008822bbecaab8a5ce5b4245f5ad96; */
    // In the new implementation this becomes 2
    bytes16 private constant MULTIPLIER_ARCTAN =
        0x40000000000000000000000000000000;
    /* // 1.53178
    bytes16 private constant MULTIPLIER_LOG =
        0x3fff8822bbecaab8a5ce5b4245f5ad96; */
    // In the new implementation this becomes 1
    bytes16 private constant MULTIPLIER_LOG =
        0x3fff0000000000000000000000000000;
    // formula of MULTIPLIER_INNER_ARCTAN is (sqrt(2)/(AC)**(1/4))
    // 0.163209: old value for A = 0.001025 and C = 5,500,000
    // 0.186589: new value for A = 0.00006 and C = 55,000,000
    /* bytes16 private constant MULTIPLIER_INNER_ARCTAN =
        0x3ffc4e40852b4d8ba40d90e23af31b15; */
    // old value
    bytes16 private constant MULTIPLIER_INNER_ARCTAN =
        0x3ffc7e225fa658c4bd33d29563a9f383; // new value
    // formula of MULTIPLIER_INNER_LOG_A is sqrt(A*C)
    // 75.0833: old value for A = 0.001025 and C = 5,500,000
    // 57.4456: new value for A = 0.00006 and C = 55,000,000
    /* bytes16 private constant MULTIPLIER_INNER_LOG_A =
        0x40052c554c985f06f694467381d7dbf4; */
    // old value
    bytes16 private constant MULTIPLIER_INNER_LOG_A =
        0x4004cb9096bb98c7e28240b780346dc5; // new value
    // formula of MULTIPLIER_INNER_LOG_B is sqrt(2) * (A*C)^(1/4)
    // 12.2542: old value for A = 0.001025 and C = 5,500,000
    // 10.7187: new value for A = 0.00006 and C = 55,000,000
    /* bytes16 private constant MULTIPLIER_INNER_LOG_B =
        0x400288226809d495182a9930be0ded28; */
    // old value
    bytes16 private constant MULTIPLIER_INNER_LOG_B =
        0x400256ff972474538ef34d6a161e4f76;
    // 10e18
    bytes16 private constant NORMALIZER = 0x403abc16d674ec800000000000000000;

    // 0.0776509570923569
    bytes16 private constant ARCTAN_2_A = 0x3ffb3e0eee136fb4e88c3b51afdd813b;
    // 0.287434475393028
    bytes16 private constant ARCTAN_2_B = 0x3ffd2655391e3950b9c4210dcff7e0e5;
    // 0.6399276529
    bytes16 private constant ARCTAN_3_A = 0x3ffe47a498ea05e88353e06682770573;

    // calculate arctan (only good between [-1,1]) using approximation
    // (a*x + x^2 + x^3) / (1 + (a+1)*x + (a+1)*x^2 + x^3 )
    // for a = 0.6399276529
    function _arctan(bytes16 x) private pure returns (bytes16) {
        bytes16 x_2 = x.mul(x);
        bytes16 x_3 = x_2.mul(x);
        bytes16 a_plus_1 = ARCTAN_3_A.add(ONE);
        bytes16 a_plus_1_x = a_plus_1.mul(x);
        bytes16 nominator = ARCTAN_3_A.mul(x).add(x_2).add(x_3);
        bytes16 denominator = ONE.add(a_plus_1_x).add(a_plus_1.mul(x_2)).add(
            x_3
        );
        return PI_2.mul(nominator).div(denominator);
    }

    // extends aproximation to the whole range of real numbers
    function arctan(bytes16 x) public pure returns (bytes16 arc) {
        // Tautology:
        // - arctan(x) = π / 2 - arctan(1 / x), x > 0
        // - arctan(x) = - π / 2 - arctan(1 / x), x < 0
        if (x.cmp(ONE) != int8(1) && x.cmp(ONE.neg()) != int256(-1)) {
            arc = _arctan(x);
        } else {
            arc = (x.sign() == -1 ? PI_2.neg() : PI_2).sub(_arctan(ONE.div(x)));
        }
    }

    function _arctan2(bytes16 a) private pure returns (bytes16) {
        return
            a.mul(PI_4).sub(
                a.mul(a.abs().sub(ONE)).mul(APPROX_A.add(APPROX_B.mul(a.abs())))
            );
    }

    function arctan2(bytes16 x) public pure returns (bytes16 arc) {
        // Tautology:
        // - arctan(x) = π / 2 - arctan(1 / x), x > 0
        // - arctan(x) = - π / 2 - arctan(1 / x), x < 0
        if (x.cmp(ONE) != int8(1) && x.cmp(ONE.neg()) != int256(-1)) {
            arc = _arctan2(x);
        } else {
            arc = (x.sign() == -1 ? PI_2.neg() : PI_2).sub(
                _arctan2(ONE.div(x))
            );
        }
    }

    function _pow3(bytes16 x) private pure returns (bytes16) {
        return x.mul(x).mul(x);
    }

    // Calculates (4√x)^3 and (√x)^3
    function rootPows(bytes16 x) private pure returns (bytes16, bytes16) {
        bytes16 x3_2 = x.mul(x.sqrt());
        bytes16 x3_4 = x3_2.sqrt();
        return (x3_4, x3_2);
    }

    // For x <= 3811 use first arctan approximation
    // For x > 3811 use the second one
    // If the result is negative we need to add PI because of a special property in the formula of arctan addition
    function arcsMix(bytes16 x, bytes16 fS3_4) private pure returns (bytes16) {
        bytes16 arcInner = MULTIPLIER_INNER_ARCTAN.mul(x).div(fS3_4);
        bytes16 arcA;
        if (x.cmp(ABDKMathQuad.fromUInt(3811)) != int256(1)) {
            arcA = arctan(
                TWO.mul(arcInner).div(TWO.sub(arcInner.mul(arcInner)))
            );
        } else {
            arcA = arctan2(
                TWO.mul(arcInner).div(TWO.sub(arcInner.mul(arcInner)))
            );
        }
        if (uint128(arcA) >= 0x80000000000000000000000000000000) {
            arcA = arcA.add(PI_2.mul(TWO));
        }
        return arcA;
    }

    // Calculates ln terms (positive, negative)
    function lns(
        bytes16 x,
        bytes16 fS3_4,
        bytes16 fS3_2
    ) private pure returns (bytes16, bytes16) {
        bytes16 a = MULTIPLIER_INNER_LOG_A.mul(fS3_2);
        bytes16 b = x.mul(x);
        a = a.add(b);
        b = MULTIPLIER_INNER_LOG_B.mul(fS3_4).mul(x);
        return (a.add(b).abs().ln(), a.sub(b).abs().ln());
    }

    /**
     * For a = 0.001025 and c = 5500000:
     *
     * 975.61 * fS^(3/4) * (
     *      -3.06356 * arctan(
     *          1 - (
     *              (0.163209 * x) / fS^(3/4)
     *          )
     *      )
     *      +3.06356 * arctan(
     *          1 + (
     *              (0.163209 * x) / fS^(3/4)
     *          )
     *      )
     *      -1.53178 * log(
     *          75.0833 * fS^(3/2) - 12.2542 * fS^(3/4) * x + x^2)
     *      )
     *      +1.53178 * log(
     *          75.0833 * fS^(3/2) + 12.2542 * fS^(3/4) * x + x^2)
     *      )
     *  )
     */
    // this is old formula
    function _g(bytes16 x, bytes16 fShare) private pure returns (bytes16) {
        // A is 3/4 and B is 3/2
        (bytes16 fShareA, bytes16 fShareB) = rootPows(fShare);
        bytes16 multiplier = fShareA.mul(MULTIPLIER_FULL);
        // (positive, negative)
        bytes16 arcA = arcsMix(x, fShareA);
        // (positive, negative)
        (bytes16 lnA, bytes16 lnB) = lns(x, fShareA, fShareB);

        bytes16 result = multiplier.mul(
            arcA.mul(MULTIPLIER_ARCTAN).add(lnA.mul(MULTIPLIER_LOG)).sub(
                lnB.mul(MULTIPLIER_LOG)
            )
        );
        return result;
    }

    function _normalize(bytes16 x) public pure returns (uint256) {
        return x.mul(NORMALIZER).toUInt();
    }

    function _denormalize(uint256 a) public pure returns (bytes16) {
        return ABDKMathQuad.fromUInt(a).div(NORMALIZER);
    }

    // g represents the relation between capital and token supply (integral of 1 / f(x))
    function g(uint256 x, uint256 fShare) public pure returns (uint256) {
        bytes16 _x = _denormalize(x);
        bytes16 _fShare = _denormalize(fShare);
        return _normalize(_g(_x, _fShare));
    }

    // f(x) = A + (fShare / C) * (x / fShare)^4
    function _f(bytes16 x, bytes16 fShare) private pure returns (bytes16) {
        return A.add(_pow3(x).mul(x).div(_pow3(fShare).mul(C)));
    }

    // f represents the relation between capital and token price
    function f(uint256 x, uint256 fShare) public pure returns (uint256) {
        bytes16 _x = _denormalize(x);
        bytes16 _fShare = _denormalize(fShare);
        return _normalize(_f(_x, _fShare));
    }

    // C = initial minted amount of tokens
    // fShare = minimal capital requirement

    // beginning
    // A = 0.001025
    // C = 5500000

    // current desired constants
    // A = 0.00006 -> 0.00008
    // C = 55000000

    // function tests(uint256 x, uint256 fShare) public pure returns (int256,int256,int256,int256) {
    //     bytes16 _x = ABDKMathQuad.fromUInt(x);
    //     bytes16 _fShare = ABDKMathQuad.fromUInt(fShare);
    //     // A is 3/4 and B is 3/2
    //     (bytes16 fShareA, bytes16 fShareB) = rootPows(_fShare);
    //     // (0.163209 * x) / fS^(3/4)
    //     bytes16 innerArc = MULTIPLIER_INNER_ARCTAN.mul(_x).div(fShareA);
    //     // 1 - innerArc
    //     bytes16 innerFirst = ONE.sub(innerArc);
    //     // 1 + innerArc
    //     bytes16 innerSecond = ONE.add(innerArc);
    //     return (_normalize(arctan(innerFirst)), arctan(innerFirst).toInt(),_normalize(arctan(innerSecond)), arctan(innerSecond).toInt());
    // }
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math Quad Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.5.0 || ^0.6.0 || ^0.7.0;

/**
 * Smart contract library of mathematical functions operating with IEEE 754
 * quadruple-precision binary floating-point numbers (quadruple precision
 * numbers).  As long as quadruple precision numbers are 16-bytes long, they are
 * represented by bytes16 type.
 */
library ABDKMathQuad {
  /*
   * 0.
   */
  bytes16 private constant POSITIVE_ZERO = 0x00000000000000000000000000000000;

  /*
   * -0.
   */
  bytes16 private constant NEGATIVE_ZERO = 0x80000000000000000000000000000000;

  /*
   * +Infinity.
   */
  bytes16 private constant POSITIVE_INFINITY = 0x7FFF0000000000000000000000000000;

  /*
   * -Infinity.
   */
  bytes16 private constant NEGATIVE_INFINITY = 0xFFFF0000000000000000000000000000;

  /*
   * Canonical NaN value.
   */
  bytes16 private constant NaN = 0x7FFF8000000000000000000000000000;

  /**
   * Convert signed 256-bit integer number into quadruple precision number.
   *
   * @param x signed 256-bit integer number
   * @return quadruple precision number
   */
  function fromInt (int256 x) internal pure returns (bytes16) {
    if (x == 0) return bytes16 (0);
    else {
      // We rely on overflow behavior here
      uint256 result = uint256 (x > 0 ? x : -x);

      uint256 msb = msb (result);
      if (msb < 112) result <<= 112 - msb;
      else if (msb > 112) result >>= msb - 112;

      result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16383 + msb << 112;
      if (x < 0) result |= 0x80000000000000000000000000000000;

      return bytes16 (uint128 (result));
    }
  }

  /**
   * Convert quadruple precision number into signed 256-bit integer number
   * rounding towards zero.  Revert on overflow.
   *
   * @param x quadruple precision number
   * @return signed 256-bit integer number
   */
  function toInt (bytes16 x) internal pure returns (int256) {
    uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

    require (exponent <= 16638); // Overflow
    if (exponent < 16383) return 0; // Underflow

    uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
      0x10000000000000000000000000000;

    if (exponent < 16495) result >>= 16495 - exponent;
    else if (exponent > 16495) result <<= exponent - 16495;

    if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
      require (result <= 0x8000000000000000000000000000000000000000000000000000000000000000);
      return -int256 (result); // We rely on overflow behavior here
    } else {
      require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int256 (result);
    }
  }

  /**
   * Convert unsigned 256-bit integer number into quadruple precision number.
   *
   * @param x unsigned 256-bit integer number
   * @return quadruple precision number
   */
  function fromUInt (uint256 x) internal pure returns (bytes16) {
    if (x == 0) return bytes16 (0);
    else {
      uint256 result = x;

      uint256 msb = msb (result);
      if (msb < 112) result <<= 112 - msb;
      else if (msb > 112) result >>= msb - 112;

      result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16383 + msb << 112;

      return bytes16 (uint128 (result));
    }
  }

  /**
   * Convert quadruple precision number into unsigned 256-bit integer number
   * rounding towards zero.  Revert on underflow.  Note, that negative floating
   * point numbers in range (-1.0 .. 0.0) may be converted to unsigned integer
   * without error, because they are rounded to zero.
   *
   * @param x quadruple precision number
   * @return unsigned 256-bit integer number
   */
  function toUInt (bytes16 x) internal pure returns (uint256) {
    uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

    if (exponent < 16383) return 0; // Underflow

    require (uint128 (x) < 0x80000000000000000000000000000000); // Negative

    require (exponent <= 16638); // Overflow
    uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
      0x10000000000000000000000000000;

    if (exponent < 16495) result >>= 16495 - exponent;
    else if (exponent > 16495) result <<= exponent - 16495;

    return result;
  }

  /**
   * Convert signed 128.128 bit fixed point number into quadruple precision
   * number.
   *
   * @param x signed 128.128 bit fixed point number
   * @return quadruple precision number
   */
  function from128x128 (int256 x) internal pure returns (bytes16) {
    if (x == 0) return bytes16 (0);
    else {
      // We rely on overflow behavior here
      uint256 result = uint256 (x > 0 ? x : -x);

      uint256 msb = msb (result);
      if (msb < 112) result <<= 112 - msb;
      else if (msb > 112) result >>= msb - 112;

      result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16255 + msb << 112;
      if (x < 0) result |= 0x80000000000000000000000000000000;

      return bytes16 (uint128 (result));
    }
  }

  /**
   * Convert quadruple precision number into signed 128.128 bit fixed point
   * number.  Revert on overflow.
   *
   * @param x quadruple precision number
   * @return signed 128.128 bit fixed point number
   */
  function to128x128 (bytes16 x) internal pure returns (int256) {
    uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

    require (exponent <= 16510); // Overflow
    if (exponent < 16255) return 0; // Underflow

    uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
      0x10000000000000000000000000000;

    if (exponent < 16367) result >>= 16367 - exponent;
    else if (exponent > 16367) result <<= exponent - 16367;

    if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
      require (result <= 0x8000000000000000000000000000000000000000000000000000000000000000);
      return -int256 (result); // We rely on overflow behavior here
    } else {
      require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int256 (result);
    }
  }

  /**
   * Convert signed 64.64 bit fixed point number into quadruple precision
   * number.
   *
   * @param x signed 64.64 bit fixed point number
   * @return quadruple precision number
   */
  function from64x64 (int128 x) internal pure returns (bytes16) {
    if (x == 0) return bytes16 (0);
    else {
      // We rely on overflow behavior here
      uint256 result = uint128 (x > 0 ? x : -x);

      uint256 msb = msb (result);
      if (msb < 112) result <<= 112 - msb;
      else if (msb > 112) result >>= msb - 112;

      result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16319 + msb << 112;
      if (x < 0) result |= 0x80000000000000000000000000000000;

      return bytes16 (uint128 (result));
    }
  }

  /**
   * Convert quadruple precision number into signed 64.64 bit fixed point
   * number.  Revert on overflow.
   *
   * @param x quadruple precision number
   * @return signed 64.64 bit fixed point number
   */
  function to64x64 (bytes16 x) internal pure returns (int128) {
    uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

    require (exponent <= 16446); // Overflow
    if (exponent < 16319) return 0; // Underflow

    uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
      0x10000000000000000000000000000;

    if (exponent < 16431) result >>= 16431 - exponent;
    else if (exponent > 16431) result <<= exponent - 16431;

    if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
      require (result <= 0x80000000000000000000000000000000);
      return -int128 (result); // We rely on overflow behavior here
    } else {
      require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (result);
    }
  }

  /**
   * Convert octuple precision number into quadruple precision number.
   *
   * @param x octuple precision number
   * @return quadruple precision number
   */
  function fromOctuple (bytes32 x) internal pure returns (bytes16) {
    bool negative = x & 0x8000000000000000000000000000000000000000000000000000000000000000 > 0;

    uint256 exponent = uint256 (x) >> 236 & 0x7FFFF;
    uint256 significand = uint256 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    if (exponent == 0x7FFFF) {
      if (significand > 0) return NaN;
      else return negative ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
    }

    if (exponent > 278526)
      return negative ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
    else if (exponent < 245649)
      return negative ? NEGATIVE_ZERO : POSITIVE_ZERO;
    else if (exponent < 245761) {
      significand = (significand | 0x100000000000000000000000000000000000000000000000000000000000) >> 245885 - exponent;
      exponent = 0;
    } else {
      significand >>= 124;
      exponent -= 245760;
    }

    uint128 result = uint128 (significand | exponent << 112);
    if (negative) result |= 0x80000000000000000000000000000000;

    return bytes16 (result);
  }

  /**
   * Convert quadruple precision number into octuple precision number.
   *
   * @param x quadruple precision number
   * @return octuple precision number
   */
  function toOctuple (bytes16 x) internal pure returns (bytes32) {
    uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

    uint256 result = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    if (exponent == 0x7FFF) exponent = 0x7FFFF; // Infinity or NaN
    else if (exponent == 0) {
      if (result > 0) {
        uint256 msb = msb (result);
        result = result << 236 - msb & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        exponent = 245649 + msb;
      }
    } else {
      result <<= 124;
      exponent += 245760;
    }

    result |= exponent << 236;
    if (uint128 (x) >= 0x80000000000000000000000000000000)
      result |= 0x8000000000000000000000000000000000000000000000000000000000000000;

    return bytes32 (result);
  }

  /**
   * Convert double precision number into quadruple precision number.
   *
   * @param x double precision number
   * @return quadruple precision number
   */
  function fromDouble (bytes8 x) internal pure returns (bytes16) {
    uint256 exponent = uint64 (x) >> 52 & 0x7FF;

    uint256 result = uint64 (x) & 0xFFFFFFFFFFFFF;

    if (exponent == 0x7FF) exponent = 0x7FFF; // Infinity or NaN
    else if (exponent == 0) {
      if (result > 0) {
        uint256 msb = msb (result);
        result = result << 112 - msb & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        exponent = 15309 + msb;
      }
    } else {
      result <<= 60;
      exponent += 15360;
    }

    result |= exponent << 112;
    if (x & 0x8000000000000000 > 0)
      result |= 0x80000000000000000000000000000000;

    return bytes16 (uint128 (result));
  }

  /**
   * Convert quadruple precision number into double precision number.
   *
   * @param x quadruple precision number
   * @return double precision number
   */
  function toDouble (bytes16 x) internal pure returns (bytes8) {
    bool negative = uint128 (x) >= 0x80000000000000000000000000000000;

    uint256 exponent = uint128 (x) >> 112 & 0x7FFF;
    uint256 significand = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    if (exponent == 0x7FFF) {
      if (significand > 0) return 0x7FF8000000000000; // NaN
      else return negative ?
          bytes8 (0xFFF0000000000000) : // -Infinity
          bytes8 (0x7FF0000000000000); // Infinity
    }

    if (exponent > 17406)
      return negative ?
          bytes8 (0xFFF0000000000000) : // -Infinity
          bytes8 (0x7FF0000000000000); // Infinity
    else if (exponent < 15309)
      return negative ?
          bytes8 (0x8000000000000000) : // -0
          bytes8 (0x0000000000000000); // 0
    else if (exponent < 15361) {
      significand = (significand | 0x10000000000000000000000000000) >> 15421 - exponent;
      exponent = 0;
    } else {
      significand >>= 60;
      exponent -= 15360;
    }

    uint64 result = uint64 (significand | exponent << 52);
    if (negative) result |= 0x8000000000000000;

    return bytes8 (result);
  }

  /**
   * Test whether given quadruple precision number is NaN.
   *
   * @param x quadruple precision number
   * @return true if x is NaN, false otherwise
   */
  function isNaN (bytes16 x) internal pure returns (bool) {
    return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF >
      0x7FFF0000000000000000000000000000;
  }

  /**
   * Test whether given quadruple precision number is positive or negative
   * infinity.
   *
   * @param x quadruple precision number
   * @return true if x is positive or negative infinity, false otherwise
   */
  function isInfinity (bytes16 x) internal pure returns (bool) {
    return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF ==
      0x7FFF0000000000000000000000000000;
  }

  /**
   * Calculate sign of x, i.e. -1 if x is negative, 0 if x if zero, and 1 if x
   * is positive.  Note that sign (-0) is zero.  Revert if x is NaN. 
   *
   * @param x quadruple precision number
   * @return sign of x
   */
  function sign (bytes16 x) internal pure returns (int8) {
    uint128 absoluteX = uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    require (absoluteX <= 0x7FFF0000000000000000000000000000); // Not NaN

    if (absoluteX == 0) return 0;
    else if (uint128 (x) >= 0x80000000000000000000000000000000) return -1;
    else return 1;
  }

  /**
   * Calculate sign (x - y).  Revert if either argument is NaN, or both
   * arguments are infinities of the same sign. 
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return sign (x - y)
   */
  function cmp (bytes16 x, bytes16 y) internal pure returns (int8) {
    uint128 absoluteX = uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    require (absoluteX <= 0x7FFF0000000000000000000000000000); // Not NaN

    uint128 absoluteY = uint128 (y) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    require (absoluteY <= 0x7FFF0000000000000000000000000000); // Not NaN

    // Not infinities of the same sign
    require (x != y || absoluteX < 0x7FFF0000000000000000000000000000);

    if (x == y) return 0;
    else {
      bool negativeX = uint128 (x) >= 0x80000000000000000000000000000000;
      bool negativeY = uint128 (y) >= 0x80000000000000000000000000000000;

      if (negativeX) {
        if (negativeY) return absoluteX > absoluteY ? -1 : int8 (1);
        else return -1; 
      } else {
        if (negativeY) return 1;
        else return absoluteX > absoluteY ? int8 (1) : -1;
      }
    }
  }

  /**
   * Test whether x equals y.  NaN, infinity, and -infinity are not equal to
   * anything. 
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return true if x equals to y, false otherwise
   */
  function eq (bytes16 x, bytes16 y) internal pure returns (bool) {
    if (x == y) {
      return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF <
        0x7FFF0000000000000000000000000000;
    } else return false;
  }

  /**
   * Calculate x + y.  Special values behave in the following way:
   *
   * NaN + x = NaN for any x.
   * Infinity + x = Infinity for any finite x.
   * -Infinity + x = -Infinity for any finite x.
   * Infinity + Infinity = Infinity.
   * -Infinity + -Infinity = -Infinity.
   * Infinity + -Infinity = -Infinity + Infinity = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function add (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
    uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

    if (xExponent == 0x7FFF) {
      if (yExponent == 0x7FFF) { 
        if (x == y) return x;
        else return NaN;
      } else return x; 
    } else if (yExponent == 0x7FFF) return y;
    else {
      bool xSign = uint128 (x) >= 0x80000000000000000000000000000000;
      uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      if (xExponent == 0) xExponent = 1;
      else xSignifier |= 0x10000000000000000000000000000;

      bool ySign = uint128 (y) >= 0x80000000000000000000000000000000;
      uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      if (yExponent == 0) yExponent = 1;
      else ySignifier |= 0x10000000000000000000000000000;

      if (xSignifier == 0) return y == NEGATIVE_ZERO ? POSITIVE_ZERO : y;
      else if (ySignifier == 0) return x == NEGATIVE_ZERO ? POSITIVE_ZERO : x;
      else {
        int256 delta = int256 (xExponent) - int256 (yExponent);
  
        if (xSign == ySign) {
          if (delta > 112) return x;
          else if (delta > 0) ySignifier >>= uint256 (delta);
          else if (delta < -112) return y;
          else if (delta < 0) {
            xSignifier >>= uint256 (-delta);
            xExponent = yExponent;
          }
  
          xSignifier += ySignifier;
  
          if (xSignifier >= 0x20000000000000000000000000000) {
            xSignifier >>= 1;
            xExponent += 1;
          }
  
          if (xExponent == 0x7FFF)
            return xSign ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
          else {
            if (xSignifier < 0x10000000000000000000000000000) xExponent = 0;
            else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  
            return bytes16 (uint128 (
                (xSign ? 0x80000000000000000000000000000000 : 0) |
                (xExponent << 112) |
                xSignifier)); 
          }
        } else {
          if (delta > 0) {
            xSignifier <<= 1;
            xExponent -= 1;
          } else if (delta < 0) {
            ySignifier <<= 1;
            xExponent = yExponent - 1;
          }

          if (delta > 112) ySignifier = 1;
          else if (delta > 1) ySignifier = (ySignifier - 1 >> uint256 (delta - 1)) + 1;
          else if (delta < -112) xSignifier = 1;
          else if (delta < -1) xSignifier = (xSignifier - 1 >> uint256 (-delta - 1)) + 1;

          if (xSignifier >= ySignifier) xSignifier -= ySignifier;
          else {
            xSignifier = ySignifier - xSignifier;
            xSign = ySign;
          }

          if (xSignifier == 0)
            return POSITIVE_ZERO;

          uint256 msb = msb (xSignifier);

          if (msb == 113) {
            xSignifier = xSignifier >> 1 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            xExponent += 1;
          } else if (msb < 112) {
            uint256 shift = 112 - msb;
            if (xExponent > shift) {
              xSignifier = xSignifier << shift & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
              xExponent -= shift;
            } else {
              xSignifier <<= xExponent - 1;
              xExponent = 0;
            }
          } else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

          if (xExponent == 0x7FFF)
            return xSign ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
          else return bytes16 (uint128 (
              (xSign ? 0x80000000000000000000000000000000 : 0) |
              (xExponent << 112) |
              xSignifier));
        }
      }
    }
  }

  /**
   * Calculate x - y.  Special values behave in the following way:
   *
   * NaN - x = NaN for any x.
   * Infinity - x = Infinity for any finite x.
   * -Infinity - x = -Infinity for any finite x.
   * Infinity - -Infinity = Infinity.
   * -Infinity - Infinity = -Infinity.
   * Infinity - Infinity = -Infinity - -Infinity = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function sub (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    return add (x, y ^ 0x80000000000000000000000000000000);
  }

  /**
   * Calculate x * y.  Special values behave in the following way:
   *
   * NaN * x = NaN for any x.
   * Infinity * x = Infinity for any finite positive x.
   * Infinity * x = -Infinity for any finite negative x.
   * -Infinity * x = -Infinity for any finite positive x.
   * -Infinity * x = Infinity for any finite negative x.
   * Infinity * 0 = NaN.
   * -Infinity * 0 = NaN.
   * Infinity * Infinity = Infinity.
   * Infinity * -Infinity = -Infinity.
   * -Infinity * Infinity = -Infinity.
   * -Infinity * -Infinity = Infinity.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function mul (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
    uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

    if (xExponent == 0x7FFF) {
      if (yExponent == 0x7FFF) {
        if (x == y) return x ^ y & 0x80000000000000000000000000000000;
        else if (x ^ y == 0x80000000000000000000000000000000) return x | y;
        else return NaN;
      } else {
        if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
        else return x ^ y & 0x80000000000000000000000000000000;
      }
    } else if (yExponent == 0x7FFF) {
        if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
        else return y ^ x & 0x80000000000000000000000000000000;
    } else {
      uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      if (xExponent == 0) xExponent = 1;
      else xSignifier |= 0x10000000000000000000000000000;

      uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      if (yExponent == 0) yExponent = 1;
      else ySignifier |= 0x10000000000000000000000000000;

      xSignifier *= ySignifier;
      if (xSignifier == 0)
        return (x ^ y) & 0x80000000000000000000000000000000 > 0 ?
            NEGATIVE_ZERO : POSITIVE_ZERO;

      xExponent += yExponent;

      uint256 msb =
        xSignifier >= 0x200000000000000000000000000000000000000000000000000000000 ? 225 :
        xSignifier >= 0x100000000000000000000000000000000000000000000000000000000 ? 224 :
        msb (xSignifier);

      if (xExponent + msb < 16496) { // Underflow
        xExponent = 0;
        xSignifier = 0;
      } else if (xExponent + msb < 16608) { // Subnormal
        if (xExponent < 16496)
          xSignifier >>= 16496 - xExponent;
        else if (xExponent > 16496)
          xSignifier <<= xExponent - 16496;
        xExponent = 0;
      } else if (xExponent + msb > 49373) {
        xExponent = 0x7FFF;
        xSignifier = 0;
      } else {
        if (msb > 112)
          xSignifier >>= msb - 112;
        else if (msb < 112)
          xSignifier <<= 112 - msb;

        xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

        xExponent = xExponent + msb - 16607;
      }

      return bytes16 (uint128 (uint128 ((x ^ y) & 0x80000000000000000000000000000000) |
          xExponent << 112 | xSignifier));
    }
  }

  /**
   * Calculate x / y.  Special values behave in the following way:
   *
   * NaN / x = NaN for any x.
   * x / NaN = NaN for any x.
   * Infinity / x = Infinity for any finite non-negative x.
   * Infinity / x = -Infinity for any finite negative x including -0.
   * -Infinity / x = -Infinity for any finite non-negative x.
   * -Infinity / x = Infinity for any finite negative x including -0.
   * x / Infinity = 0 for any finite non-negative x.
   * x / -Infinity = -0 for any finite non-negative x.
   * x / Infinity = -0 for any finite non-negative x including -0.
   * x / -Infinity = 0 for any finite non-negative x including -0.
   * 
   * Infinity / Infinity = NaN.
   * Infinity / -Infinity = -NaN.
   * -Infinity / Infinity = -NaN.
   * -Infinity / -Infinity = NaN.
   *
   * Division by zero behaves in the following way:
   *
   * x / 0 = Infinity for any finite positive x.
   * x / -0 = -Infinity for any finite positive x.
   * x / 0 = -Infinity for any finite negative x.
   * x / -0 = Infinity for any finite negative x.
   * 0 / 0 = NaN.
   * 0 / -0 = NaN.
   * -0 / 0 = NaN.
   * -0 / -0 = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function div (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
    uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

    if (xExponent == 0x7FFF) {
      if (yExponent == 0x7FFF) return NaN;
      else return x ^ y & 0x80000000000000000000000000000000;
    } else if (yExponent == 0x7FFF) {
      if (y & 0x0000FFFFFFFFFFFFFFFFFFFFFFFFFFFF != 0) return NaN;
      else return POSITIVE_ZERO | (x ^ y) & 0x80000000000000000000000000000000;
    } else if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) {
      if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
      else return POSITIVE_INFINITY | (x ^ y) & 0x80000000000000000000000000000000;
    } else {
      uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      if (yExponent == 0) yExponent = 1;
      else ySignifier |= 0x10000000000000000000000000000;

      uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      if (xExponent == 0) {
        if (xSignifier != 0) {
          uint shift = 226 - msb (xSignifier);

          xSignifier <<= shift;

          xExponent = 1;
          yExponent += shift - 114;
        }
      }
      else {
        xSignifier = (xSignifier | 0x10000000000000000000000000000) << 114;
      }

      xSignifier = xSignifier / ySignifier;
      if (xSignifier == 0)
        return (x ^ y) & 0x80000000000000000000000000000000 > 0 ?
            NEGATIVE_ZERO : POSITIVE_ZERO;

      assert (xSignifier >= 0x1000000000000000000000000000);

      uint256 msb =
        xSignifier >= 0x80000000000000000000000000000 ? msb (xSignifier) :
        xSignifier >= 0x40000000000000000000000000000 ? 114 :
        xSignifier >= 0x20000000000000000000000000000 ? 113 : 112;

      if (xExponent + msb > yExponent + 16497) { // Overflow
        xExponent = 0x7FFF;
        xSignifier = 0;
      } else if (xExponent + msb + 16380  < yExponent) { // Underflow
        xExponent = 0;
        xSignifier = 0;
      } else if (xExponent + msb + 16268  < yExponent) { // Subnormal
        if (xExponent + 16380 > yExponent)
          xSignifier <<= xExponent + 16380 - yExponent;
        else if (xExponent + 16380 < yExponent)
          xSignifier >>= yExponent - xExponent - 16380;

        xExponent = 0;
      } else { // Normal
        if (msb > 112)
          xSignifier >>= msb - 112;

        xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

        xExponent = xExponent + msb + 16269 - yExponent;
      }

      return bytes16 (uint128 (uint128 ((x ^ y) & 0x80000000000000000000000000000000) |
          xExponent << 112 | xSignifier));
    }
  }

  /**
   * Calculate -x.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function neg (bytes16 x) internal pure returns (bytes16) {
    return x ^ 0x80000000000000000000000000000000;
  }

  /**
   * Calculate |x|.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function abs (bytes16 x) internal pure returns (bytes16) {
    return x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  }

  /**
   * Calculate square root of x.  Return NaN on negative x excluding -0.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function sqrt (bytes16 x) internal pure returns (bytes16) {
    if (uint128 (x) >  0x80000000000000000000000000000000) return NaN;
    else {
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      if (xExponent == 0x7FFF) return x;
      else {
        uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xExponent == 0) xExponent = 1;
        else xSignifier |= 0x10000000000000000000000000000;

        if (xSignifier == 0) return POSITIVE_ZERO;

        bool oddExponent = xExponent & 0x1 == 0;
        xExponent = xExponent + 16383 >> 1;

        if (oddExponent) {
          if (xSignifier >= 0x10000000000000000000000000000)
            xSignifier <<= 113;
          else {
            uint256 msb = msb (xSignifier);
            uint256 shift = (226 - msb) & 0xFE;
            xSignifier <<= shift;
            xExponent -= shift - 112 >> 1;
          }
        } else {
          if (xSignifier >= 0x10000000000000000000000000000)
            xSignifier <<= 112;
          else {
            uint256 msb = msb (xSignifier);
            uint256 shift = (225 - msb) & 0xFE;
            xSignifier <<= shift;
            xExponent -= shift - 112 >> 1;
          }
        }

        uint256 r = 0x10000000000000000000000000000;
        r = (r + xSignifier / r) >> 1;
        r = (r + xSignifier / r) >> 1;
        r = (r + xSignifier / r) >> 1;
        r = (r + xSignifier / r) >> 1;
        r = (r + xSignifier / r) >> 1;
        r = (r + xSignifier / r) >> 1;
        r = (r + xSignifier / r) >> 1; // Seven iterations should be enough
        uint256 r1 = xSignifier / r;
        if (r1 < r) r = r1;

        return bytes16 (uint128 (xExponent << 112 | r & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF));
      }
    }
  }

  /**
   * Calculate binary logarithm of x.  Return NaN on negative x excluding -0.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function log_2 (bytes16 x) internal pure returns (bytes16) {
    if (uint128 (x) > 0x80000000000000000000000000000000) return NaN;
    else if (x == 0x3FFF0000000000000000000000000000) return POSITIVE_ZERO; 
    else {
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      if (xExponent == 0x7FFF) return x;
      else {
        uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xExponent == 0) xExponent = 1;
        else xSignifier |= 0x10000000000000000000000000000;

        if (xSignifier == 0) return NEGATIVE_INFINITY;

        bool resultNegative;
        uint256 resultExponent = 16495;
        uint256 resultSignifier;

        if (xExponent >= 0x3FFF) {
          resultNegative = false;
          resultSignifier = xExponent - 0x3FFF;
          xSignifier <<= 15;
        } else {
          resultNegative = true;
          if (xSignifier >= 0x10000000000000000000000000000) {
            resultSignifier = 0x3FFE - xExponent;
            xSignifier <<= 15;
          } else {
            uint256 msb = msb (xSignifier);
            resultSignifier = 16493 - msb;
            xSignifier <<= 127 - msb;
          }
        }

        if (xSignifier == 0x80000000000000000000000000000000) {
          if (resultNegative) resultSignifier += 1;
          uint256 shift = 112 - msb (resultSignifier);
          resultSignifier <<= shift;
          resultExponent -= shift;
        } else {
          uint256 bb = resultNegative ? 1 : 0;
          while (resultSignifier < 0x10000000000000000000000000000) {
            resultSignifier <<= 1;
            resultExponent -= 1;
  
            xSignifier *= xSignifier;
            uint256 b = xSignifier >> 255;
            resultSignifier += b ^ bb;
            xSignifier >>= 127 + b;
          }
        }

        return bytes16 (uint128 ((resultNegative ? 0x80000000000000000000000000000000 : 0) |
            resultExponent << 112 | resultSignifier & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF));
      }
    }
  }

  /**
   * Calculate natural logarithm of x.  Return NaN on negative x excluding -0.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function ln (bytes16 x) internal pure returns (bytes16) {
    return mul (log_2 (x), 0x3FFE62E42FEFA39EF35793C7673007E5);
  }

  /**
   * Calculate 2^x.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function pow_2 (bytes16 x) internal pure returns (bytes16) {
    bool xNegative = uint128 (x) > 0x80000000000000000000000000000000;
    uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
    uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    if (xExponent == 0x7FFF && xSignifier != 0) return NaN;
    else if (xExponent > 16397)
      return xNegative ? POSITIVE_ZERO : POSITIVE_INFINITY;
    else if (xExponent < 16255)
      return 0x3FFF0000000000000000000000000000;
    else {
      if (xExponent == 0) xExponent = 1;
      else xSignifier |= 0x10000000000000000000000000000;

      if (xExponent > 16367)
        xSignifier <<= xExponent - 16367;
      else if (xExponent < 16367)
        xSignifier >>= 16367 - xExponent;

      if (xNegative && xSignifier > 0x406E00000000000000000000000000000000)
        return POSITIVE_ZERO;

      if (!xNegative && xSignifier > 0x3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        return POSITIVE_INFINITY;

      uint256 resultExponent = xSignifier >> 128;
      xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      if (xNegative && xSignifier != 0) {
        xSignifier = ~xSignifier;
        resultExponent += 1;
      }

      uint256 resultSignifier = 0x80000000000000000000000000000000;
      if (xSignifier & 0x80000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
      if (xSignifier & 0x40000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
      if (xSignifier & 0x20000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
      if (xSignifier & 0x10000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
      if (xSignifier & 0x8000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
      if (xSignifier & 0x4000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
      if (xSignifier & 0x2000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
      if (xSignifier & 0x1000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
      if (xSignifier & 0x800000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
      if (xSignifier & 0x400000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
      if (xSignifier & 0x200000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
      if (xSignifier & 0x100000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
      if (xSignifier & 0x80000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
      if (xSignifier & 0x40000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
      if (xSignifier & 0x20000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000162E525EE054754457D5995292026 >> 128;
      if (xSignifier & 0x10000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
      if (xSignifier & 0x8000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
      if (xSignifier & 0x4000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
      if (xSignifier & 0x2000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000162E43F4F831060E02D839A9D16D >> 128;
      if (xSignifier & 0x1000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
      if (xSignifier & 0x800000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
      if (xSignifier & 0x400000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
      if (xSignifier & 0x200000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
      if (xSignifier & 0x100000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
      if (xSignifier & 0x80000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
      if (xSignifier & 0x40000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
      if (xSignifier & 0x20000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
      if (xSignifier & 0x10000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
      if (xSignifier & 0x8000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
      if (xSignifier & 0x4000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
      if (xSignifier & 0x2000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
      if (xSignifier & 0x1000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
      if (xSignifier & 0x800000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
      if (xSignifier & 0x400000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
      if (xSignifier & 0x200000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000162E42FEFB2FED257559BDAA >> 128;
      if (xSignifier & 0x100000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
      if (xSignifier & 0x80000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
      if (xSignifier & 0x40000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
      if (xSignifier & 0x20000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
      if (xSignifier & 0x10000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000B17217F7D20CF927C8E94C >> 128;
      if (xSignifier & 0x8000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
      if (xSignifier & 0x4000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000002C5C85FDF477B662B26945 >> 128;
      if (xSignifier & 0x2000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000162E42FEFA3AE53369388C >> 128;
      if (xSignifier & 0x1000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000B17217F7D1D351A389D40 >> 128;
      if (xSignifier & 0x800000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
      if (xSignifier & 0x400000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
      if (xSignifier & 0x200000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000162E42FEFA39FE95583C2 >> 128;
      if (xSignifier & 0x100000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
      if (xSignifier & 0x80000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
      if (xSignifier & 0x40000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000002C5C85FDF473E242EA38 >> 128;
      if (xSignifier & 0x20000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000162E42FEFA39F02B772C >> 128;
      if (xSignifier & 0x10000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
      if (xSignifier & 0x8000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
      if (xSignifier & 0x4000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000002C5C85FDF473DEA871F >> 128;
      if (xSignifier & 0x2000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000162E42FEFA39EF44D91 >> 128;
      if (xSignifier & 0x1000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000B17217F7D1CF79E949 >> 128;
      if (xSignifier & 0x800000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
      if (xSignifier & 0x400000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
      if (xSignifier & 0x200000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000162E42FEFA39EF366F >> 128;
      if (xSignifier & 0x100000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000B17217F7D1CF79AFA >> 128;
      if (xSignifier & 0x80000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
      if (xSignifier & 0x40000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
      if (xSignifier & 0x20000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000162E42FEFA39EF358 >> 128;
      if (xSignifier & 0x10000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000B17217F7D1CF79AB >> 128;
      if (xSignifier & 0x8000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000058B90BFBE8E7BCD5 >> 128;
      if (xSignifier & 0x4000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000002C5C85FDF473DE6A >> 128;
      if (xSignifier & 0x2000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000162E42FEFA39EF34 >> 128;
      if (xSignifier & 0x1000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000B17217F7D1CF799 >> 128;
      if (xSignifier & 0x800000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000058B90BFBE8E7BCC >> 128;
      if (xSignifier & 0x400000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000002C5C85FDF473DE5 >> 128;
      if (xSignifier & 0x200000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000162E42FEFA39EF2 >> 128;
      if (xSignifier & 0x100000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000B17217F7D1CF78 >> 128;
      if (xSignifier & 0x80000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000058B90BFBE8E7BB >> 128;
      if (xSignifier & 0x40000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000002C5C85FDF473DD >> 128;
      if (xSignifier & 0x20000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000162E42FEFA39EE >> 128;
      if (xSignifier & 0x10000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000B17217F7D1CF6 >> 128;
      if (xSignifier & 0x8000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000058B90BFBE8E7A >> 128;
      if (xSignifier & 0x4000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000002C5C85FDF473C >> 128;
      if (xSignifier & 0x2000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000162E42FEFA39D >> 128;
      if (xSignifier & 0x1000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000B17217F7D1CE >> 128;
      if (xSignifier & 0x800000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000058B90BFBE8E6 >> 128;
      if (xSignifier & 0x400000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000002C5C85FDF472 >> 128;
      if (xSignifier & 0x200000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000162E42FEFA38 >> 128;
      if (xSignifier & 0x100000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000B17217F7D1B >> 128;
      if (xSignifier & 0x80000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000058B90BFBE8D >> 128;
      if (xSignifier & 0x40000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000002C5C85FDF46 >> 128;
      if (xSignifier & 0x20000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000162E42FEFA2 >> 128;
      if (xSignifier & 0x10000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000B17217F7D0 >> 128;
      if (xSignifier & 0x8000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000058B90BFBE7 >> 128;
      if (xSignifier & 0x4000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000002C5C85FDF3 >> 128;
      if (xSignifier & 0x2000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000162E42FEF9 >> 128;
      if (xSignifier & 0x1000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000B17217F7C >> 128;
      if (xSignifier & 0x800000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000058B90BFBD >> 128;
      if (xSignifier & 0x400000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000002C5C85FDE >> 128;
      if (xSignifier & 0x200000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000162E42FEE >> 128;
      if (xSignifier & 0x100000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000B17217F6 >> 128;
      if (xSignifier & 0x80000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000058B90BFA >> 128;
      if (xSignifier & 0x40000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000002C5C85FC >> 128;
      if (xSignifier & 0x20000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000162E42FD >> 128;
      if (xSignifier & 0x10000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000B17217E >> 128;
      if (xSignifier & 0x8000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000058B90BE >> 128;
      if (xSignifier & 0x4000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000002C5C85E >> 128;
      if (xSignifier & 0x2000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000162E42E >> 128;
      if (xSignifier & 0x1000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000B17216 >> 128;
      if (xSignifier & 0x800000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000058B90A >> 128;
      if (xSignifier & 0x400000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000002C5C84 >> 128;
      if (xSignifier & 0x200000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000162E41 >> 128;
      if (xSignifier & 0x100000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000B1720 >> 128;
      if (xSignifier & 0x80000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000058B8F >> 128;
      if (xSignifier & 0x40000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000002C5C7 >> 128;
      if (xSignifier & 0x20000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000162E3 >> 128;
      if (xSignifier & 0x10000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000B171 >> 128;
      if (xSignifier & 0x8000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000058B8 >> 128;
      if (xSignifier & 0x4000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000002C5B >> 128;
      if (xSignifier & 0x2000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000162D >> 128;
      if (xSignifier & 0x1000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000B16 >> 128;
      if (xSignifier & 0x800 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000058A >> 128;
      if (xSignifier & 0x400 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000002C4 >> 128;
      if (xSignifier & 0x200 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000161 >> 128;
      if (xSignifier & 0x100 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000000B0 >> 128;
      if (xSignifier & 0x80 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000057 >> 128;
      if (xSignifier & 0x40 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000002B >> 128;
      if (xSignifier & 0x20 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000015 >> 128;
      if (xSignifier & 0x10 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000000A >> 128;
      if (xSignifier & 0x8 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000004 >> 128;
      if (xSignifier & 0x4 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000001 >> 128;

      if (!xNegative) {
        resultSignifier = resultSignifier >> 15 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        resultExponent += 0x3FFF;
      } else if (resultExponent <= 0x3FFE) {
        resultSignifier = resultSignifier >> 15 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        resultExponent = 0x3FFF - resultExponent;
      } else {
        resultSignifier = resultSignifier >> resultExponent - 16367;
        resultExponent = 0;
      }

      return bytes16 (uint128 (resultExponent << 112 | resultSignifier));
    }
  }

  /**
   * Calculate e^x.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function exp (bytes16 x) internal pure returns (bytes16) {
    return pow_2 (mul (x, 0x3FFF71547652B82FE1777D0FFDA0D23A));
  }

  /**
   * Get index of the most significant non-zero bit in binary representation of
   * x.  Reverts if x is zero.
   *
   * @return index of the most significant non-zero bit in binary representation
   *         of x
   */
  function msb (uint256 x) private pure returns (uint256) {
    require (x > 0);

    uint256 result = 0;

    if (x >= 0x100000000000000000000000000000000) { x >>= 128; result += 128; }
    if (x >= 0x10000000000000000) { x >>= 64; result += 64; }
    if (x >= 0x100000000) { x >>= 32; result += 32; }
    if (x >= 0x10000) { x >>= 16; result += 16; }
    if (x >= 0x100) { x >>= 8; result += 8; }
    if (x >= 0x10) { x >>= 4; result += 4; }
    if (x >= 0x4) { x >>= 2; result += 2; }
    if (x >= 0x2) result += 1; // No need to shift x anymore

    return result;
  }
}