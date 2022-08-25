pragma solidity 0.5.7;

import "SafeERC20.sol";
import "IERC20.sol";
import "SafeMath.sol";
import "IRSV.sol";
import "Ownable.sol";
import "Basket.sol";
import "Proposal.sol";


interface IVault {
    function withdrawTo(address, uint256, address) external;
}

/**
 * The Manager contract is the point of contact between the Reserve ecosystem and the
 * surrounding world. It manages the Issuance and Redemption of RSV, a decentralized stablecoin
 * backed by a basket of tokens.
 *
 * The Manager also implements a Proposal system to handle administration of changes to the
 * backing of RSV. Anyone can propose a change to the backing.  Once the `owner` approves the
 * proposal, then after a pre-determined delay the proposal is eligible for execution by
 * anyone. However, the funds to execute the proposal must come from the proposer.
 *
 * There are two different ways to propose changes to the backing of RSV:
 * - proposeSwap()
 * - proposeWeights()
 *
 * In both cases, tokens are exchanged with the Vault and a new RSV backing is set. You can
 * think of the first type of proposal as being useful when you don't want to rebalance the
 * Vault by exchanging absolute quantities of tokens; its downside is that you don't know
 * precisely what the resulting basket weights will be. The second type of proposal is more
 * useful when you want to fine-tune the Vault weights and accept the downside that it's
 * difficult to know what capital will be required when the proposal is executed.
 */

/* On "unit" comments:
 *
 * The units in use around weight computations are fiddly, and it's pretty annoying to get them
 * properly into the Solidity type system. So, there are many comments of the form "unit:
 * ...". Where such a comment is describing a field, method, or return parameter, the comment means
 * that the data in that place is to be interpreted to have that type. Many places also have
 * comments with more complicated expressions; that's manually working out the dimensional analysis
 * to ensure that the given expression has correct units.
 *
 * Some dimensions used in this analysis:
 * - 1 RSV: 1 Reserve
 * - 1 qRSV: 1 quantum of Reserve.
 *      (RSV & qRSV are convertible by .mul(10**reserve.decimals() qRSV/RSV))
 * - 1 qToken: 1 quantum of an external Token.
 * - 1 aqToken: 1 atto-quantum of an external Token.
 *      (qToken and aqToken are convertible by .mul(10**18 aqToken/qToken)
 * - 1 BPS: 1 Basis Point. Effectively dimensionless; convertible with .mul(10000 BPS).
 *
 * Note that we _never_ reason in units of Tokens or attoTokens.
 */
contract Manager is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // ROLES

    // Manager is already Ownable, but in addition it also has an `operator`.
    address public operator;

    // DATA

    Basket public trustedBasket;
    IVault public trustedVault;
    IRSV public trustedRSV;
    IProposalFactory public trustedProposalFactory;

    // Proposals
    mapping(uint256 => IProposal) public trustedProposals;
    uint256 public proposalsLength;
    uint256 public delay = 24 hours;

    // Controls
    bool public issuancePaused;
    bool public emergency;

    // The spread between issuance and redemption in basis points (BPS).
    uint256 public seigniorage;              // 0.1% spread -> 10 BPS. unit: BPS
    uint256 constant BPS_FACTOR = 10000;     // This is what 100% looks like in BPS. unit: BPS
    uint256 constant WEIGHT_SCALE = 10**18; // unit: aqToken/qToken

    event ProposalsCleared();

    // RSV traded events
    event Issuance(address indexed user, uint256 indexed amount);
    event Redemption(address indexed user, uint256 indexed amount);

    // Pause events
    event IssuancePausedChanged(bool indexed oldVal, bool indexed newVal);
    event EmergencyChanged(bool indexed oldVal, bool indexed newVal);
    event OperatorChanged(address indexed oldAccount, address indexed newAccount);
    event SeigniorageChanged(uint256 oldVal, uint256 newVal);
    event VaultChanged(address indexed oldVaultAddr, address indexed newVaultAddr);
    event DelayChanged(uint256 oldVal, uint256 newVal);

    // Proposals
    event WeightsProposed(uint256 indexed id,
        address indexed proposer,
        address[] tokens,
        uint256[] weights);

    event SwapProposed(uint256 indexed id,
        address indexed proposer,
        address[] tokens,
        uint256[] amounts,
        bool[] toVault);

    event ProposalAccepted(uint256 indexed id, address indexed proposer);
    event ProposalCanceled(uint256 indexed id, address indexed proposer, address indexed canceler);
    event ProposalExecuted(uint256 indexed id,
        address indexed proposer,
        address indexed executor,
        address oldBasket,
        address newBasket);

    // ============================ Constructor ===============================

    /// Begins in `emergency` state.
    constructor(
        address vaultAddr,
        address rsvAddr,
        address proposalFactoryAddr,
        address basketAddr,
        address operatorAddr,
        uint256 _seigniorage) public
    {
        require(_seigniorage <= 1000, "max seigniorage 10%");
        trustedVault = IVault(vaultAddr);
        trustedRSV = IRSV(rsvAddr);
        trustedProposalFactory = IProposalFactory(proposalFactoryAddr);
        trustedBasket = Basket(basketAddr);
        operator = operatorAddr;
        seigniorage = _seigniorage;
        emergency = true; // it's not an emergency, but we want everything to start paused.
    }

    // ============================= Modifiers ================================

    /// Modifies a function to run only when issuance is not paused.
    modifier issuanceNotPaused() {
        require(!issuancePaused, "issuance is paused");
        _;
    }

    /// Modifies a function to run only when there is not some emergency that requires upgrades.
    modifier notEmergency() {
        require(!emergency, "contract is paused");
        _;
    }

    /// Modifies a function to run only when the caller is the operator account.
    modifier onlyOperator() {
        require(_msgSender() == operator, "operator only");
        _;
    }

    /// Modifies a function to run and complete only if the vault is collateralized.
    modifier vaultCollateralized() {
        require(isFullyCollateralized(), "undercollateralized");
        _;
        assert(isFullyCollateralized());
    }

    // ========================= Public + External ============================

    /// Set if issuance should be paused.
    function setIssuancePaused(bool val) external onlyOperator {
        emit IssuancePausedChanged(issuancePaused, val);
        issuancePaused = val;
    }

    /// Set if all contract actions should be paused.
    function setEmergency(bool val) external onlyOperator {
        emit EmergencyChanged(emergency, val);
        emergency = val;
    }

    /// Set the vault.
    function setVault(address newVaultAddress) external onlyOwner {
        emit VaultChanged(address(trustedVault), newVaultAddress);
        trustedVault = IVault(newVaultAddress);
    }

    /// Clear the list of proposals.
    function clearProposals() external onlyOperator {
        proposalsLength = 0;
        emit ProposalsCleared();
    }

    /// Set the operator.
    function setOperator(address _operator) external onlyOwner {
        emit OperatorChanged(operator, _operator);
        operator = _operator;
    }

    /// Set the seigniorage, in BPS.
    function setSeigniorage(uint256 _seigniorage) external onlyOwner {
        require(_seigniorage <= 1000, "max seigniorage 10%");
        emit SeigniorageChanged(seigniorage, _seigniorage);
        seigniorage = _seigniorage;
    }

    /// Set the Proposal delay in hours.
    function setDelay(uint256 _delay) external onlyOwner {
        emit DelayChanged(delay, _delay);
        delay = _delay;
    }

    /// Ensure that the Vault is fully collateralized.  That this is true should be an
    /// invariant of this contract: it's true before and after every txn.
    function isFullyCollateralized() public view returns(bool) {
        uint256 scaleFactor = WEIGHT_SCALE.mul(uint256(10) ** trustedRSV.decimals());
        // scaleFactor unit: aqToken/qToken * qRSV/RSV

        for (uint256 i = 0; i < trustedBasket.size(); i++) {

            address trustedToken = trustedBasket.tokens(i);
            uint256 weight = trustedBasket.weights(trustedToken); // unit: aqToken/RSV
            uint256 balance = IERC20(trustedToken).balanceOf(address(trustedVault)); //unit: qToken

            // Return false if this token is undercollateralized:
            if (trustedRSV.totalSupply().mul(weight) > balance.mul(scaleFactor)) {
                // checking units: [qRSV] * [aqToken/RSV] == [qToken] * [aqToken/qToken * qRSV/RSV]
                return false;
            }
        }
        return true;
    }

    /// Get amounts of basket tokens required to issue an amount of RSV.
    /// The returned array will be in the same order as the current basket.tokens.
    /// return unit: qToken[]
    function toIssue(uint256 rsvAmount) public view returns (uint256[] memory) {
        // rsvAmount unit: qRSV.
        uint256[] memory amounts = new uint256[](trustedBasket.size());

        uint256 feeRate = uint256(seigniorage.add(BPS_FACTOR));
        // feeRate unit: BPS
        uint256 effectiveAmount = rsvAmount.mul(feeRate).div(BPS_FACTOR);
        // effectiveAmount unit: qRSV == qRSV*BPS/BPS

        // On issuance, amounts[i] of token i will enter the vault. To maintain full backing,
        // we have to round _up_ each amounts[i].
        for (uint256 i = 0; i < trustedBasket.size(); i++) {
            address trustedToken = trustedBasket.tokens(i);
            amounts[i] = _weighted(
                effectiveAmount,
                trustedBasket.weights(trustedToken),
                RoundingMode.UP
            );
            // unit: qToken = _weighted(qRSV, aqToken/RSV, _)
        }

        return amounts; // unit: qToken[]
    }

    /// Get amounts of basket tokens that would be sent upon redeeming an amount of RSV.
    /// The returned array will be in the same order as the current basket.tokens.
    /// return unit: qToken[]
    function toRedeem(uint256 rsvAmount) public view returns (uint256[] memory) {
        // rsvAmount unit: qRSV
        uint256[] memory amounts = new uint256[](trustedBasket.size());

        // On redemption, amounts[i] of token i will leave the vault. To maintain full backing,
        // we have to round _down_ each amounts[i].
        for (uint256 i = 0; i < trustedBasket.size(); i++) {
            address trustedToken = trustedBasket.tokens(i);
            amounts[i] = _weighted(
                rsvAmount,
                trustedBasket.weights(trustedToken),
                RoundingMode.DOWN
            );
            // unit: qToken = _weighted(qRSV, aqToken/RSV, _)
        }

        return amounts;
    }

    /// Handles issuance.
    /// rsvAmount unit: qRSV
    function issue(uint256 rsvAmount) external
        issuanceNotPaused
        notEmergency
        vaultCollateralized
    {
        require(rsvAmount > 0, "cannot issue zero RSV");
        require(trustedBasket.size() > 0, "basket cannot be empty");

        // Accept collateral tokens.
        uint256[] memory amounts = toIssue(rsvAmount); // unit: qToken[]
        for (uint256 i = 0; i < trustedBasket.size(); i++) {
            IERC20(trustedBasket.tokens(i)).safeTransferFrom(
                _msgSender(),
                address(trustedVault),
                amounts[i]
            );
            // unit check for amounts[i]: qToken.
        }

        // Compensate with RSV.
        trustedRSV.mint(_msgSender(), rsvAmount);
        // unit check for rsvAmount: qRSV.

        emit Issuance(_msgSender(), rsvAmount);
    }

    /// Handles redemption.
    /// rsvAmount unit: qRSV
    function redeem(uint256 rsvAmount) external notEmergency vaultCollateralized {
        require(rsvAmount > 0, "cannot redeem 0 RSV");
        require(trustedBasket.size() > 0, "basket cannot be empty");

        // Burn RSV tokens.
        trustedRSV.burnFrom(_msgSender(), rsvAmount);
        // unit check: rsvAmount is qRSV.

        // Compensate with collateral tokens.
        uint256[] memory amounts = toRedeem(rsvAmount); // unit: qToken[]
        for (uint256 i = 0; i < trustedBasket.size(); i++) {
            trustedVault.withdrawTo(trustedBasket.tokens(i), amounts[i], _msgSender());
            // unit check for amounts[i]: qToken.
        }

        emit Redemption(_msgSender(), rsvAmount);
    }

    /**
     * Propose an exchange of current Vault tokens for new Vault tokens.
     *
     * These parameters are phyiscally a set of arrays because Solidity doesn't let you pass
     * around arrays of structs as parameters of transactions. Semantically, read these three
     * lists as a list of triples (token, amount, toVault), where:
     *
     * - token is the address of an ERC-20 token,
     * - amount is the amount of the token that the proposer says they will trade with the vault,
     * - toVault is the direction of that trade. If toVault is true, the proposer offers to send
     *   `amount` of `token` to the vault. If toVault is false, the proposer expects to receive
     *   `amount` of `token` from the vault.
     *
     * If and when this proposal is accepted and executed, then:
     *
     * 1. The Manager checks that the proposer has allowed adequate funds, for the proposed
     *    transfers from the proposer to the vault.
     * 2. The proposed set of token transfers occur between the Vault and the proposer.
     * 3. The Vault's basket weights are raised and lowered, based on these token transfers and the
     *    total supply of RSV **at the time when the proposal is executed**.
     *
     * Note that the set of token transfers will almost always be at very slightly lower volumes
     * than requested, due to the rounding error involved in (a) adjusting the weights at execution
     * time and (b) keeping the Vault fully collateralized. The contracts should never attempt to
     * trade at higher volumes than requested.
     *
     * The intended behavior of proposers is that they will make proposals that shift the Vault
     * composition towards some known target of Reserve's management while maintaining full
     * backing; the expected behavior of Reserve's management is to accept only such proposals,
     * excepting during dire emergencies.
     *
     * Note: This type of proposal does not reliably remove token addresses!
     * If you want to remove token addresses entirely, use proposeWeights.
     *
     * Returns the new proposal's ID.
     */
    function proposeSwap(
        address[] calldata tokens,
        uint256[] calldata amounts, // unit: qToken
        bool[] calldata toVault
    )
    external notEmergency vaultCollateralized returns(uint256)
    {
        require(tokens.length == amounts.length && amounts.length == toVault.length,
            "proposeSwap: unequal lengths");
        uint256 proposalID = proposalsLength++;

        trustedProposals[proposalID] = trustedProposalFactory.createSwapProposal(
            _msgSender(),
            tokens,
            amounts,
            toVault
        );
        trustedProposals[proposalID].acceptOwnership();

        emit SwapProposed(proposalID, _msgSender(), tokens, amounts, toVault);
        return proposalID;
    }


    /**
     * Propose a new basket, defined by a list of tokens address, and their basket weights.
     *
     * Note: With this type of proposal, the allowances of tokens that will be required of the
     * proposer may change between proposition and execution. If the supply of RSV rises or falls,
     * then more or fewer tokens will be required to execute the proposal.
     *
     * Returns the new proposal's ID.
     */

    function proposeWeights(address[] calldata tokens, uint256[] calldata weights)
    external notEmergency vaultCollateralized returns(uint256)
    {
        require(tokens.length == weights.length, "proposeWeights: unequal lengths");
        require(tokens.length > 0, "proposeWeights: zero length");

        uint256 proposalID = proposalsLength++;

        trustedProposals[proposalID] = trustedProposalFactory.createWeightProposal(
            _msgSender(),
            new Basket(Basket(0), tokens, weights)
        );
        trustedProposals[proposalID].acceptOwnership();

        emit WeightsProposed(proposalID, _msgSender(), tokens, weights);
        return proposalID;
    }

    /// Accepts a proposal for a new basket, beginning the required delay.
    function acceptProposal(uint256 id) external onlyOperator notEmergency vaultCollateralized {
        require(proposalsLength > id, "proposals length <= id");
        trustedProposals[id].accept(now.add(delay));
        emit ProposalAccepted(id, trustedProposals[id].proposer());
    }

    /// Cancels a proposal. This can be done anytime before it is enacted by any of:
    /// 1. Proposer 2. Operator 3. Owner
    function cancelProposal(uint256 id) external notEmergency vaultCollateralized {
        require(
            _msgSender() == trustedProposals[id].proposer() ||
            _msgSender() == owner() ||
            _msgSender() == operator,
            "cannot cancel"
        );
        require(proposalsLength > id, "proposals length <= id");
        trustedProposals[id].cancel();
        emit ProposalCanceled(id, trustedProposals[id].proposer(), _msgSender());
    }

    /// Executes a proposal by exchanging collateral tokens with the proposer.
    function executeProposal(uint256 id) external onlyOperator notEmergency vaultCollateralized {
        require(proposalsLength > id, "proposals length <= id");
        address proposer = trustedProposals[id].proposer();
        Basket trustedOldBasket = trustedBasket;

        // Complete proposal and compute new basket
        trustedBasket = trustedProposals[id].complete(trustedRSV, trustedOldBasket);

        // For each token in either basket, perform transfers between proposer and Vault
        for (uint256 i = 0; i < trustedOldBasket.size(); i++) {
            address trustedToken = trustedOldBasket.tokens(i);
            _executeBasketShift(
                trustedOldBasket.weights(trustedToken),
                trustedBasket.weights(trustedToken),
                trustedToken,
                proposer
            );
        }
        for (uint256 i = 0; i < trustedBasket.size(); i++) {
            address trustedToken = trustedBasket.tokens(i);
            if (!trustedOldBasket.has(trustedToken)) {
                _executeBasketShift(
                    trustedOldBasket.weights(trustedToken),
                    trustedBasket.weights(trustedToken),
                    trustedToken,
                    proposer
                );
            }
        }

        emit ProposalExecuted(
            id,
            proposer,
            _msgSender(),
            address(trustedOldBasket),
            address(trustedBasket)
        );
    }


    // ============================= Internal ================================

    /// _executeBasketShift transfers the necessary amount of `token` between vault and `proposer`
    /// to rebalance the vault's balance of token, as it goes from oldBasket to newBasket.
    /// @dev To carry out a proposal, this is executed once per relevant token.
    function _executeBasketShift(
        uint256 oldWeight, // unit: aqTokens/RSV
        uint256 newWeight, // unit: aqTokens/RSV
        address trustedToken,
        address proposer
    ) internal {
        if (newWeight > oldWeight) {
            // This token must increase in the vault, so transfer from proposer to vault.
            // (Transfer into vault: round up)
            uint256 transferAmount =_weighted(
                trustedRSV.totalSupply(),
                newWeight.sub(oldWeight),
                RoundingMode.UP
            );
            // transferAmount unit: qTokens

            if (transferAmount > 0) {
                IERC20(trustedToken).safeTransferFrom(
                    proposer,
                    address(trustedVault),
                    transferAmount
                );
            }

        } else if (newWeight < oldWeight) {
            // This token will decrease in the vault, so transfer from vault to proposer.
            // (Transfer out of vault: round down)
            uint256 transferAmount =_weighted(
                trustedRSV.totalSupply(),
                oldWeight.sub(newWeight),
                RoundingMode.DOWN
            );
            // transferAmount unit: qTokens
            if (transferAmount > 0) {
                trustedVault.withdrawTo(trustedToken, transferAmount, proposer);
            }
        }
    }

    // When you perform a weighting of some amount of RSV, it will involve a division, and
    // precision will be lost. When it rounds, do you want to round UP or DOWN? Be maximally
    // conservative.
    enum RoundingMode {UP, DOWN}

    /// From a weighting of RSV (e.g., a basket weight) and an amount of RSV,
    /// compute the amount of the weighted token that matches that amount of RSV.
    function _weighted(
        uint256 amount, // unit: qRSV
        uint256 weight, // unit: aqToken/RSV
        RoundingMode rnd
    ) internal view returns(uint256) // return unit: qTokens
    {
        uint256 scaleFactor = WEIGHT_SCALE.mul(uint256(10)**(trustedRSV.decimals()));
        // scaleFactor unit: aqTokens/qTokens * qRSV/RSV
        uint256 shiftedWeight = amount.mul(weight);
        // shiftedWeight unit: qRSV/RSV * aqTokens

        // If the weighting is precise, or we're rounding down, then use normal division.
        if (rnd == RoundingMode.DOWN || shiftedWeight.mod(scaleFactor) == 0) {
            return shiftedWeight.div(scaleFactor);
            // return unit: qTokens == qRSV/RSV * aqTokens * (qTokens/aqTokens * RSV/qRSV)
        }
        return shiftedWeight.div(scaleFactor).add(1); // return unit: qTokens
    }
}

pragma solidity 0.5.7;

import "IERC20.sol";
import "SafeMath.sol";
import "Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity 0.5.7;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity 0.5.7;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/[email protected]`.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/[email protected]`.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/[email protected]`.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity 0.5.7;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/[email protected]`.
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
}

pragma solidity 0.5.7;

interface IRSV {
    // Standard ERC20 functions
    function transfer(address, uint256) external returns(bool);
    function approve(address, uint256) external returns(bool);
    function transferFrom(address, address, uint256) external returns(bool);
    function totalSupply() external view returns(uint256);
    function balanceOf(address) external view returns(uint256);
    function allowance(address, address) external view returns(uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // RSV-specific functions
    function decimals() external view returns(uint8);
    function mint(address, uint256) external;
    function burnFrom(address, uint256) external;
    function relayTransfer(address, address, uint256) external returns(bool);
    function relayTransferFrom(address, address, address, uint256) external returns(bool);
    function relayApprove(address, address, uint256) external returns(bool);
}

pragma solidity 0.5.7;

import "Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where there is an account
 * (owner) that can be granted exclusive access to specific functions.
 *
 * This module is used through inheritance by using the modifier `onlyOwner`.
 *
 * To change ownership, use a 2-part nominate-accept pattern.
 *
 * This contract is loosely based off of https://git.io/JenNF but additionally requires new owners
 * to accept ownership before the transition occurs.
 */
contract Ownable is Context {
    address private _owner;
    address private _nominatedOwner;

    event NewOwnerNominated(address indexed previousOwner, address indexed nominee);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the current nominated owner.
     */
    function nominatedOwner() external view returns (address) {
        return _nominatedOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        require(_msgSender() == _owner, "caller is not owner");
    }

    /**
     * @dev Nominates a new owner `newOwner`.
     * Requires a follow-up `acceptOwnership`.
     * Can only be called by the current owner.
     */
    function nominateNewOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "new owner is 0 address");
        emit NewOwnerNominated(_owner, newOwner);
        _nominatedOwner = newOwner;
    }

    /**
     * @dev Accepts ownership of the contract.
     */
    function acceptOwnership() external {
        require(_nominatedOwner == _msgSender(), "unauthorized");
        emit OwnershipTransferred(_owner, _nominatedOwner);
        _owner = _nominatedOwner;
    }

    /** Set `_owner` to the 0 address.
     * Only do this to deliberately lock in the current permissions.
     *
     * THIS CANNOT BE UNDONE! Call this only if you know what you're doing and why you're doing it!
     */
    function renounceOwnership(string calldata declaration) external onlyOwner {
        string memory requiredDeclaration = "I hereby renounce ownership of this contract forever.";
        require(
            keccak256(abi.encodePacked(declaration)) ==
            keccak256(abi.encodePacked(requiredDeclaration)),
            "declaration incorrect");

        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

pragma solidity 0.5.7;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity 0.5.7;


/**
 * This Basket contract is essentially just a data structure; it represents the tokens and weights
 * in some Reserve-backing basket, either proposed or accepted.
 *
 * @dev Each `weights` value is an integer, with unit aqToken/RSV. (That is, atto-quantum-Tokens
 * per RSV). If you prefer, you can think about this as if the weights value is itself an
 * 18-decimal fixed-point value with unit qToken/RSV. (It would be prettier if these were just
 * straightforwardly qTokens/RSV, but that introduces unacceptable rounding error in some of our
 * basket computations.)
 *
 * @dev For example, let's say we have the token USDX in the vault, and it's represented to 6
 * decimal places, and the RSV basket should include 3/10ths of a USDX for each RSV. Then the
 * corresponding basket weight will be represented as 3*(10**23), because:
 *
 * @dev 3*(10**23) aqToken/RSV == 0.3 Token/RSV * (10**6 qToken/Token) * (10**18 aqToken/qToken)
 *
 * @dev For further notes on units, see the header comment for Manager.sol.
*/

contract Basket {
    address[] public tokens;
    mapping(address => uint256) public weights; // unit: aqToken/RSV
    mapping(address => bool) public has;
    // INVARIANT: {addr | addr in tokens} == {addr | has[addr] == true}
    
    // SECURITY PROPERTY: The value of prev is always a Basket, and cannot be set by any user.
    
    // WARNING: A basket can be of size 0. It is the Manager's responsibility
    //                    to ensure Issuance does not happen against an empty basket.

    /// Construct a new basket from an old Basket `prev`, and a list of tokens and weights with
    /// which to update `prev`. If `prev == address(0)`, act like it's an empty basket.
    constructor(Basket trustedPrev, address[] memory _tokens, uint256[] memory _weights) public {
        require(_tokens.length == _weights.length, "Basket: unequal array lengths");

        // Initialize data from input arrays
        tokens = new address[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            require(!has[_tokens[i]], "duplicate token entries");
            weights[_tokens[i]] = _weights[i];
            has[_tokens[i]] = true;
            tokens[i] = _tokens[i];
        }

        // If there's a previous basket, copy those of its contents not already set.
        if (trustedPrev != Basket(0)) {
            for (uint256 i = 0; i < trustedPrev.size(); i++) {
                address tok = trustedPrev.tokens(i);
                if (!has[tok]) {
                    weights[tok] = trustedPrev.weights(tok);
                    has[tok] = true;
                    tokens.push(tok);
                }
            }
        }
        require(tokens.length <= 10, "Basket: bad length");
    }

    function getTokens() external view returns(address[] memory) {
        return tokens;
    }

    function size() external view returns(uint256) {
        return tokens.length;
    }
}

pragma solidity 0.5.7;

import "IERC20.sol";
import "SafeERC20.sol";
import "IRSV.sol";
import "Ownable.sol";
import "Basket.sol";

/**
 * A Proposal represents a suggestion to change the backing for RSV.
 *
 * The lifecycle of a proposal:
 * 1. Creation
 * 2. Acceptance
 * 3. Completion
 *
 * A time can be set during acceptance to determine when completion is eligible.  A proposal can
 * also be cancelled before it is completed. If a proposal is cancelled, it can no longer become
 * Completed.
 *
 * This contract is intended to be used in one of two possible ways. Either:
 * - A target RSV basket is proposed, and quantities to be exchanged are deduced at the time of
 *   proposal execution.
 * - A specific quantity of tokens to be exchanged is proposed, and the resultant RSV basket is
 *   determined at the time of proposal execution.
 */

interface IProposal {
    function proposer() external returns(address);
    function accept(uint256 time) external;
    function cancel() external;
    function complete(IRSV rsv, Basket oldBasket) external returns(Basket);
    function nominateNewOwner(address newOwner) external;
    function acceptOwnership() external;
}

interface IProposalFactory {
    function createSwapProposal(address,
        address[] calldata tokens,
        uint256[] calldata amounts,
        bool[] calldata toVault
    ) external returns (IProposal);

    function createWeightProposal(address proposer, Basket basket) external returns (IProposal);
}

contract ProposalFactory is IProposalFactory {
    function createSwapProposal(
        address proposer,
        address[] calldata tokens,
        uint256[] calldata amounts,
        bool[] calldata toVault
    )
        external returns (IProposal)
    {
        IProposal proposal = IProposal(new SwapProposal(proposer, tokens, amounts, toVault));
        proposal.nominateNewOwner(msg.sender);
        return proposal;
    }

    function createWeightProposal(address proposer, Basket basket) external returns (IProposal) {
        IProposal proposal = IProposal(new WeightProposal(proposer, basket));
        proposal.nominateNewOwner(msg.sender);
        return proposal;
    }
}

contract Proposal is IProposal, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public time;
    address public proposer;

    enum State { Created, Accepted, Cancelled, Completed }
    State public state;
    
    event ProposalCreated(address indexed proposer);
    event ProposalAccepted(address indexed proposer, uint256 indexed time);
    event ProposalCancelled(address indexed proposer);
    event ProposalCompleted(address indexed proposer, address indexed basket);

    constructor(address _proposer) public {
        proposer = _proposer;
        state = State.Created;
        emit ProposalCreated(proposer);
    }

    /// Moves a proposal from the Created to Accepted state.
    function accept(uint256 _time) external onlyOwner {
        require(state == State.Created, "proposal not created");
        time = _time;
        state = State.Accepted;
        emit ProposalAccepted(proposer, _time);
    }

    /// Cancels a proposal if it has not been completed.
    function cancel() external onlyOwner {
        require(state != State.Completed);
        state = State.Cancelled;
        emit ProposalCancelled(proposer);
    }

    /// Moves a proposal from the Accepted to Completed state.
    /// Returns the tokens, quantitiesIn, and quantitiesOut, required to implement the proposal.
    function complete(IRSV rsv, Basket oldBasket)
        external onlyOwner returns(Basket)
    {
        require(state == State.Accepted, "proposal must be accepted");
        require(now > time, "wait to execute");
        state = State.Completed;

        Basket b = _newBasket(rsv, oldBasket);
        emit ProposalCompleted(proposer, address(b));
        return b;
    }

    /// Returns the newly-proposed basket. This varies for different types of proposals,
    /// so it's abstract here.
    function _newBasket(IRSV trustedRSV, Basket oldBasket) internal returns(Basket);
}

/**
 * A WeightProposal represents a suggestion to change the backing for RSV to a new distribution
 * of tokens. You can think of it as designating what a _single RSV_ should be backed by, but
 * deferring on the precise quantities of tokens that will be need to be exchanged until a later
 * point in time.
 *
 * When this proposal is completed, it simply returns the target basket.
 */
contract WeightProposal is Proposal {
    Basket public trustedBasket;

    constructor(address _proposer, Basket _trustedBasket) Proposal(_proposer) public {
        require(_trustedBasket.size() > 0, "proposal cannot be empty");
        trustedBasket = _trustedBasket;
    }

    /// Returns the newly-proposed basket
    function _newBasket(IRSV, Basket) internal returns(Basket) {
        return trustedBasket;
    }
}

/**
 * A SwapProposal represents a suggestion to transfer fixed amounts of tokens into and out of the
 * vault. Whereas a WeightProposal designates how much a _single RSV_ should be backed by,
 * a SwapProposal first designates what quantities of tokens to transfer in total and then
 * solves for the new resultant basket later.
 *
 * When this proposal is completed, it calculates what the weights for the new basket will be
 * and returns it. If RSV supply is 0, this kind of Proposal cannot be used. 
 */

// On "unit" comments, see comment at top of Manager.sol.
contract SwapProposal is Proposal {
    address[] public tokens;
    uint256[] public amounts; // unit: qToken
    bool[] public toVault;

    uint256 constant WEIGHT_SCALE = uint256(10)**18; // unit: aqToken / qToken

    constructor(address _proposer,
                address[] memory _tokens,
                uint256[] memory _amounts, // unit: qToken
                bool[] memory _toVault )
        Proposal(_proposer) public
    {
        require(_tokens.length > 0, "proposal cannot be empty");
        require(_tokens.length == _amounts.length && _amounts.length == _toVault.length,
                "unequal array lengths");
        tokens = _tokens;
        amounts = _amounts;
        toVault = _toVault;
    }

    /// Return the newly-proposed basket, based on the current vault and the old basket.
    function _newBasket(IRSV trustedRSV, Basket trustedOldBasket) internal returns(Basket) {

        uint256[] memory weights = new uint256[](tokens.length);
        // unit: aqToken/RSV

        uint256 scaleFactor = WEIGHT_SCALE.mul(uint256(10)**(trustedRSV.decimals()));
        // unit: aqToken/qToken * qRSV/RSV

        uint256 rsvSupply = trustedRSV.totalSupply();
        // unit: qRSV

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 oldWeight = trustedOldBasket.weights(tokens[i]);
            // unit: aqToken/RSV

            if (toVault[i]) {
                // We require that the execution of a SwapProposal takes in no more than the funds
                // offered in its proposal -- that's part of the premise. It turns out that,
                // because we're rounding down _here_ and rounding up in
                // Manager._executeBasketShift(), it's possible for the naive implementation of
                // this mechanism to overspend the proposer's tokens by 1 qToken. We avoid that,
                // here, by making the effective proposal one less. Yeah, it's pretty fiddly.
                
                weights[i] = oldWeight.add( (amounts[i].sub(1)).mul(scaleFactor).div(rsvSupply) );
                //unit: aqToken/RSV == aqToken/RSV == [qToken] * [aqToken/qToken*qRSV/RSV] / [qRSV]
            } else {
                weights[i] = oldWeight.sub( amounts[i].mul(scaleFactor).div(rsvSupply) );
                //unit: aqToken/RSV
            }
        }

        return new Basket(trustedOldBasket, tokens, weights);
        // unit check for weights: aqToken/RSV
    }
}