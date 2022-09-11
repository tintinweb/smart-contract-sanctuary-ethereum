//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

/**
                    ███████╗███████╗ ██████╗ ██╗   ██╗
                    ██╔════╝██╔════╝██╔═══██╗██║   ██║
                    ███████╗███████╗██║   ██║██║   ██║
                    ╚════██║╚════██║██║   ██║╚██╗ ██╔╝
                    ███████║███████║╚██████╔╝ ╚████╔╝ 
                    ╚══════╝╚══════╝ ╚═════╝   ╚═══╝  
                                                      
                    ██████╗ ██╗     ██████╗          
                    ██╔═══██╗██║     ██╔══██╗         
                    ██║   ██║██║     ██████╔╝         
                    ██║   ██║██║     ██╔═══╝          
                    ╚██████╔╝███████╗██║              
                    ╚═════╝ ╚══════╝╚═╝  

                      SSOV Option Liquidity Pools
                
      Allows LPs to add liquidity for select option tokens along with a discount
      to market price. Option token holders can sell their tokens to LPs at
      anytime during the option token's epoch.
*/

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BaseLP} from "./BaseLP.sol";

contract OptionLP is BaseLP {
    using SafeERC20 for IERC20;

    struct LpPosition {
        uint256 lpId;
        // Epoch for LP position
        uint256 epoch;
        // Strike price
        uint256 strike;
        // Available liquidity in LP position
        uint256 liquidity;
        // Amount of liquidity used to purchase options
        uint256 liquidityUsed;
        // Discount in % to market price
        uint256 discount;
        // Amount of options purchased
        uint256 purchased;
        // Buyer address
        address buyer;
        // Is position killed
        bool killed;
    }

    string public name;

    // mapping (epoch strike token address) => LpPosition[])
    mapping(address => LpPosition[]) internal allLpPositions;
    // mapping (user => striken token => lpId[])
    mapping(address => mapping(address => uint256[])) internal userLpPositions;

    /*==== CONSTRUCTOR ====*/

    /// @dev An OptionLP contract maps to the same underlying and duration.
    /// @dev I.e., A contract maps to ETH monthly SSOV and ETH monthly SSOV-p.
    /// @param _name Name of contract, i.e., ETH-MONTHLY, RDPX-WEEKLY
    constructor(string memory _name) {
        name = _name;
    }

    /*==== USER METHODS ====*/

    /**
     * Adds a new LP position for a token
     * @param token Token address
     * @param isPut Is the LP for puts
     * @param strike Strikes to purchase at
     * @param liquidityPerStrike Liquidity alloted per strike
     * @param discountToMarket Discount to market offered per strike in %
     * @param to Address to send option tokens to if purchase succeeds
     * @return Whether new LP position was created
     */
    function addToLp(
        address token,
        bool isPut,
        uint256 strike,
        uint256 liquidityPerStrike,
        uint256 discountToMarket,
        address to
    ) external nonReentrant returns (bool) {
        _isEligibleSender();

        address ssov = tokenVaultRegistry[token][isPut];
        if (ssov == address(0)) {
            revert SsovDoesNotExist();
        }
        if (getSsovExpiry(ssov) <= block.timestamp) {
            revert SsovEpochExpired();
        }
        if (
            !_addLiquidityForStrike(
                ssov,
                getSsovEpoch(ssov),
                strike,
                liquidityPerStrike,
                discountToMarket,
                to
            )
        ) {
            revert LpPositionFailedToAdd();
        }
        return true;
    }

    /**
     * Adds multiple new LP positions for a token
     * @param token Token address
     * @param isPut Is the LP for puts
     * @param strikes Strikes to purchase at
     * @param liquidityPerStrike Liquidity alloted per strike
     * @param discountToMarket Discount to market offered per strike in %
     * @param to Address to send option tokens to if purchase succeeds
     * @return Whether new LP position was created
     */
    function multiaddToLp(
        address token,
        bool isPut,
        uint256[] memory strikes,
        uint256[] memory liquidityPerStrike,
        uint256[] memory discountToMarket,
        address to
    ) external nonReentrant returns (bool) {
        _isEligibleSender();

        address ssov = tokenVaultRegistry[token][isPut];
        if (ssov == address(0)) {
            revert SsovDoesNotExist();
        }
        if (getSsovExpiry(ssov) <= block.timestamp) {
            revert SsovEpochExpired();
        }
        if (
            strikes.length == 0 ||
            strikes.length > MULTI_ADD_LIMIT ||
            strikes.length != liquidityPerStrike.length ||
            liquidityPerStrike.length != discountToMarket.length
        ) {
            revert InvalidParams();
        }

        uint256 epoch = getSsovEpoch(ssov);

        for (uint256 i; i < strikes.length; ) {
            if (
                !_addLiquidityForStrike(
                    ssov,
                    epoch,
                    strikes[i],
                    liquidityPerStrike[i],
                    discountToMarket[i],
                    to
                )
            ) {
                revert LpPositionFailedToAdd();
            }
            unchecked {
                ++i;
            }
        }
        return true;
    }

    /// @dev helper function to add liquidity
    function _addLiquidityForStrike(
        address ssov,
        uint256 currentEpoch,
        uint256 strike,
        uint256 liquidity,
        uint256 discount,
        address buyer
    ) internal returns (bool) {
        if (liquidity == 0) {
            revert InvalidLiquidity();
        }
        if (discount == 0 || discount > 100) {
            revert InvalidDiscount();
        }

        address strikeToken = getSsovOptionToken(ssov, currentEpoch, strike);
        if (strikeToken == address(0)) {
            revert InvalidStrike();
        }

        if (getOptionTokenInfo[strikeToken].ssov == address(0)) {
            getOptionTokenInfo[strikeToken].ssov = address(ssov);
            getOptionTokenInfo[strikeToken].strike = strike;
        }
        getOptionTokenInfo[strikeToken].tokenLiquidity += liquidity;

        uint256 lpId = allLpPositions[strikeToken].length;
        LpPosition memory lpPos = LpPosition({
            lpId: lpId,
            epoch: currentEpoch,
            strike: strike,
            liquidity: liquidity,
            liquidityUsed: 0,
            discount: discount,
            purchased: 0,
            buyer: buyer,
            killed: false
        });

        allLpPositions[strikeToken].push(lpPos);
        userLpPositions[buyer][strikeToken].push(lpId);

        IERC20(addresses.usd).safeTransferFrom(
            msg.sender,
            address(this),
            liquidity
        );

        emit LiquidityForStrikeAdded(strikeToken, lpId);
        return true;
    }

    /**
     * Fills an LP position with available liquidity
     * @param strikeToken epoch strike token address
     * @param lpIndex Index of LP position
     * @param amount Amount of options to buy from each LP position
     * @return Whether LP positions were filled
     */
    function fillLpPosition(
        address strikeToken,
        uint256 lpIndex,
        uint256 amount
    ) external nonReentrant returns (bool) {
        _isEligibleSender();
        address ssov = getOptionTokenInfo[strikeToken].ssov;
        if (ssov == address(0)) {
            revert SsovDoesNotExist();
        }
        _fillLpPosition(ssov, getSsovEpoch(ssov), strikeToken, lpIndex, amount);
        return true;
    }

    /**
     * Fills multiple LP positions with available liquidity
     * @param strikeToken epoch strike token address
     * @param lpIndices Index of LP position
     * @param amount Amount of options to buy from each LP position
     * @return Whether LP positions were filled
     */
    function multifillLpPosition(
        address strikeToken,
        uint256[] memory lpIndices,
        uint256[] memory amount
    ) external nonReentrant returns (bool) {
        _isEligibleSender();

        address ssov = getOptionTokenInfo[strikeToken].ssov;
        if (ssov == address(0)) {
            revert SsovDoesNotExist();
        }
        if (lpIndices.length == 0 || lpIndices.length != amount.length) {
            revert InvalidParams();
        }

        uint256 epoch = getSsovEpoch(ssov);
        for (uint256 i; i < lpIndices.length; ) {
            _fillLpPosition(ssov, epoch, strikeToken, lpIndices[i], amount[i]);
            unchecked {
                ++i;
            }
        }
        return true;
    }

    /// @dev helper function to fill an LP position at index
    function _fillLpPosition(
        address ssov,
        uint256 currentEpoch,
        address strikeToken,
        uint256 lpIndex,
        uint256 amount
    ) internal returns (bool) {
        if (amount <= DUST_THRESHOLD) {
            revert AmountTooSmall();
        }
        if (lpIndex >= allLpPositions[strikeToken].length) {
            revert InvalidLpIndex();
        }

        LpPosition memory lpPosition = allLpPositions[strikeToken][lpIndex];
        if (lpPosition.killed) {
            revert LpPositionKilled();
        }
        if (lpPosition.epoch != currentEpoch) {
            revert InvalidEpochToFill();
        }

        // Calculate total premium
        uint256 premium = getSsovUsdPremiumCalculation(
            ssov,
            getOptionTokenInfo[strikeToken].strike,
            amount
        );

        // Factor in discount
        premium = (premium * (PERCENT - lpPosition.discount)) / PERCENT;
        if (premium >= lpPosition.liquidity) {
            revert InsuffientLiquidity();
        }

        // Update LP position
        allLpPositions[strikeToken][lpIndex].liquidity -= premium;
        allLpPositions[strikeToken][lpIndex].liquidityUsed += premium;
        allLpPositions[strikeToken][lpIndex].purchased += amount;
        getOptionTokenInfo[strikeToken].tokenLiquidity -= premium;

        // if liquidity is lower than threshold, kill the position
        if (allLpPositions[strikeToken][lpIndex].liquidity < DUST_THRESHOLD) {
            if (!_clearLpDust(strikeToken, lpIndex)) {
                revert LpDustFailedToClear();
            }
        }

        // Transfer option tokens to buyer
        IERC20(strikeToken).safeTransferFrom(
            msg.sender,
            lpPosition.buyer,
            amount
        );
        // Transfer premium to seller
        IERC20(addresses.usd).safeTransfer(msg.sender, premium);
        emit LPPositionFilled(
            strikeToken,
            lpIndex,
            amount,
            premium,
            msg.sender
        );
        return true;
    }

    /**
     * Kills an active LP position
     * @param strikeToken epoch strike token address
     * @param lpIndex Index of LP position
     * @return Whether LP position is killed
     */
    function killLpPosition(address strikeToken, uint256 lpIndex)
        external
        nonReentrant
        returns (bool)
    {
        _isEligibleSender();

        if (getOptionTokenInfo[strikeToken].ssov == address(0)) {
            revert SsovDoesNotExist();
        }
        _killLpPosition(strikeToken, lpIndex);
        return true;
    }

    /**
     * Kills multiple active LP positions
     * @param strikeToken epoch strike token address
     * @param lpIndices Index of LP position
     * @return Whether LP positions are killed
     */
    function multikillLpPosition(
        address strikeToken,
        uint256[] memory lpIndices
    ) external nonReentrant returns (bool) {
        _isEligibleSender();

        if (getOptionTokenInfo[strikeToken].ssov == address(0)) {
            revert SsovDoesNotExist();
        }
        if (lpIndices.length == 0) {
            revert InvalidParams();
        }
        for (uint256 i; i < lpIndices.length; ) {
            _killLpPosition(strikeToken, lpIndices[i]);
            unchecked {
                ++i;
            }
        }
        return true;
    }

    /// @dev helper function to kill an LP position at index
    function _killLpPosition(address strikeToken, uint256 lpIndex)
        internal
        returns (bool)
    {
        if (lpIndex >= allLpPositions[strikeToken].length) {
            revert InvalidLpIndex();
        }

        LpPosition memory lpPosition = allLpPositions[strikeToken][lpIndex];
        if (lpPosition.buyer != msg.sender) {
            revert OnlyBuyerCanKill();
        }
        if (lpPosition.killed) {
            revert LpPositionKilled();
        }
        if (
            !_killAndTransfer(
                strikeToken,
                lpIndex,
                lpPosition.buyer,
                lpPosition.liquidity
            )
        ) {
            revert PositionFailedToKillAndTransfer();
        }

        emit LPPositionKilled(strikeToken, lpIndex);
        return true;
    }

    /// @dev helper function to clear LP dust position at index
    function _clearLpDust(address strikeToken, uint256 lpIndex)
        internal
        returns (bool)
    {
        LpPosition memory lpPosition = allLpPositions[strikeToken][lpIndex];

        if (
            !_killAndTransfer(
                strikeToken,
                lpIndex,
                lpPosition.buyer,
                lpPosition.liquidity
            )
        ) {
            revert PositionFailedToKillAndTransfer();
        }

        emit LPDustCleared(strikeToken, lpIndex);

        return true;
    }

    /// @dev helper function to kill position and
    /// @dev transfer liquidity left in position back to LP
    function _killAndTransfer(
        address strikeToken,
        uint256 lpIndex,
        address buyer,
        uint256 liquidity
    ) internal returns (bool) {
        // Mark position as killed
        allLpPositions[strikeToken][lpIndex].killed = true;
        getOptionTokenInfo[strikeToken].tokenLiquidity -= liquidity;

        // Transfer out remaining liquidity from LP position
        // Don't update liquidity in LP position - if it is killed,
        // this tracks liquidity that was transferred out during kill
        IERC20(addresses.usd).safeTransfer(buyer, liquidity);
        return true;
    }

    /*==== VIEW METHODS ====*/

    /**
     * Returns all LP positions for a given user
     * @param user address of user
     * @param strikeToken epoch strike token address
     * @return positions the user's LP positions
     */
    function getUserLpPositions(address user, address strikeToken)
        external
        view
        returns (LpPosition[] memory positions)
    {
        uint256[] memory userPositionsId = userLpPositions[user][strikeToken];
        uint256 numPositions = userPositionsId.length;
        positions = new LpPosition[](numPositions);
        for (uint256 i; i < numPositions; ) {
            positions[i] = allLpPositions[strikeToken][userPositionsId[i]];
            unchecked {
                ++i;
            }
        }
    }

    /**
     * Returns all LP positions for a given strikeToken
     * @param strikeToken epoch strike token address
     * @return all LP positions
     */
    function getAllLpPositions(address strikeToken)
        external
        view
        returns (LpPosition[] memory)
    {
        return allLpPositions[strikeToken];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ISSOV} from "./interfaces/ISSOV.sol";
import {Pausable} from "./helpers/Pausable.sol";
import {ContractWhitelist} from "./helpers/ContractWhitelist.sol";

contract BaseLP is Ownable, ReentrancyGuard, Pausable, ContractWhitelist {
    using SafeERC20 for IERC20;

    uint256 internal constant MULTI_ADD_LIMIT = 5;
    uint256 internal constant PERCENT = 1e2;
    uint256 internal constant USDC_DECIMALS = 1e6;
    uint256 internal constant PREMIUM_DECIMALS = 1e8;
    uint256 internal constant DUST_THRESHOLD = 1e7; // $10
    uint256 internal constant TOKEN_DUST_THRESHOLD = 1e15; // 0.001 $token
    uint256 internal constant AMOUNT_PRICE_TO_USDC_DECIMALS =
        (1e18 * 1e8) / 1e6;

    struct OptionTokenInfo {
        // SSOV for option token
        address ssov;
        // Strike price
        uint256 strike;
        // liquidity
        uint256 tokenLiquidity;
    }

    struct Addresses {
        // Stablecoin token (1e6 precision)t
        address usd;
    }

    Addresses public addresses;

    // mapping (option token => OptionTokenInfo)
    mapping(address => OptionTokenInfo) public getOptionTokenInfo;
    // mapping (ssov address => expires)
    mapping(address => uint256[]) internal ssovExpiries;
    // mapping (token address => (isPut => SSOV address))
    mapping(address => mapping(bool => address)) internal tokenVaultRegistry;

    event LiquidityForStrikeAdded(
        address indexed epochStrikeToken,
        uint256 index
    );
    event LPPositionFilled(
        address indexed epochStrikeToken,
        uint256 index,
        uint256 amount,
        uint256 premium,
        address indexed seller
    );
    event LPPositionKilled(address indexed epochStrikeToken, uint256 index);
    event LPDustCleared(address indexed epochStrikeToken, uint256 index);
    event SsovForTokenRegistered(address token, bool isPut, address ssov);
    event SsovForTokenRemoved(address token, bool isPut, address ssov);
    event AddressesSet(Addresses _addresses);
    event SsovExpiryUpdated(address ssov, uint256 expiry);
    event EmergencyWithdrawn(address caller);

    /*==== ADMIN METHODS ====*/

    /// @notice Pauses the vault for emergency cases
    /// @dev Can only be called by the owner
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the vault
    /// @dev Can only be called by the owner
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Sets (adds) a list of addresses to the address list
    /// @dev Can only be called by the owner
    /// @param _addresses addresses of contracts in the Addresses struct
    function setAddresses(Addresses calldata _addresses)
        external
        onlyOwner
        returns (bool)
    {
        addresses = _addresses;
        emit AddressesSet(_addresses);
        return true;
    }

    /// @notice Transfers all funds to msg.sender
    /// @dev Can only be called by the owner
    /// @param tokens The list of erc20 tokens to withdraw
    /// @param transferNative Whether should transfer the native currency
    function emergencyWithdrawn(address[] calldata tokens, bool transferNative)
        external
        onlyOwner
    {
        _whenPaused();
        if (transferNative) payable(msg.sender).transfer(address(this).balance);

        IERC20 token;

        for (uint256 i = 0; i < tokens.length; i++) {
            token = IERC20(tokens[i]);
            token.safeTransfer(msg.sender, token.balanceOf(address(this)));
        }

        emit EmergencyWithdrawn(msg.sender);
    }

    /**
     * Register the vault for token
     * @param token Token address
     * @param isPut Is puts
     * @param vault SSOV address
     * @return Whether was registration successful
     */
    function registerSsovForToken(
        address token,
        bool isPut,
        address vault
    ) external onlyOwner returns (bool) {
        require(
            token != address(0) && vault != address(0),
            "addresses cannot be null"
        );
        tokenVaultRegistry[token][isPut] = vault;
        emit SsovForTokenRegistered(token, isPut, vault);
        return true;
    }

    /**
     * Unregister the vault for token
     * @param token Token address
     * @param isPut Is puts
     * @return Whether was registration successful
     */
    function unregisterSsovForToken(address token, bool isPut)
        external
        onlyOwner
        returns (bool)
    {
        address toRemoveVault = tokenVaultRegistry[token][isPut];
        tokenVaultRegistry[token][isPut] = address(0);
        emit SsovForTokenRemoved(token, isPut, toRemoveVault);
        return true;
    }

    /// @notice Add a contract to the whitelist
    /// @dev Can only be called by the admin
    /// @param _contract Address of the contract that needs to be added to the whitelist
    function addToContractWhitelist(address _contract) external onlyOwner {
        _addToContractWhitelist(_contract);
    }

    /// @notice Remove a contract to the whitelist
    /// @dev Can only be called by the admin
    /// @param _contract Address of the contract that needs to be removed from the whitelist
    function removeFromContractWhitelist(address _contract) external onlyOwner {
        _removeFromContractWhitelist(_contract);
    }

    /// @notice Updates the list of epoch expiries
    /// @param ssov addresses of ssov
    /// @dev Can be run by a bot
    function updateSsovEpoch(address ssov) external returns (bool) {
        uint256 expiry = getSsovExpiry(ssov);
        require(expiry > block.timestamp, "Expiry must be in the future");
        if (
            ssovExpiries[ssov].length == 0 ||
            ssovExpiries[ssov][ssovExpiries[ssov].length - 1] != expiry
        ) {
            ssovExpiries[ssov].push(expiry);
            emit SsovExpiryUpdated(ssov, expiry);
            return true;
        }
        return false;
    }

    /*==== SSOV VIEW METHODS ====*/

    function getSsov(address vault) public pure returns (ISSOV) {
        return ISSOV(vault);
    }

    function getSsovExpiry(address vault) public view returns (uint256) {
        uint256 currentEpoch = getSsovEpoch(vault);
        (, uint256 expiry) = getSsov(vault).getEpochTimes(currentEpoch);
        return expiry;
    }

    function getSsovOptionToken(
        address vault,
        uint256 epoch,
        uint256 strike
    ) public view returns (address) {
        return getSsov(vault).getEpochStrikeData(epoch, strike).strikeToken;
    }

    function getSsovOptionTokens(address vault, uint256 epoch)
        public
        view
        returns (address[] memory tokens)
    {
        uint256[] memory strikes = getSsovEpochStrikes(vault, epoch);
        tokens = new address[](strikes.length);
        for (uint256 i; i < strikes.length; ++i) {
            tokens[i] = getSsovOptionToken(vault, epoch, strikes[i]);
        }
    }

    function getSsovEpochStrikes(address vault, uint256 epoch)
        public
        view
        returns (uint256[] memory strikes)
    {
        return getSsov(vault).getEpochData(epoch).strikes;
    }

    function getSsovEpoch(address vault) public view returns (uint256) {
        return getSsov(vault).currentEpoch();
    }

    function getSsovPremiumCalculation(
        address vault,
        uint256 strike,
        uint256 amount
    ) public view returns (uint256) {
        return
            getSsov(vault).calculatePremium(
                strike,
                amount,
                getSsovExpiry(vault)
            );
    }

    function getSsovUsdPremiumCalculation(
        address vault,
        uint256 strike,
        uint256 amount
    ) public view returns (uint256) {
        return
            (getSsovPremiumCalculation(vault, strike, amount) *
                getSsov(vault).getCollateralPrice()) /
            AMOUNT_PRICE_TO_USDC_DECIMALS;
    }

    function getSsovEpochExpiries(address ssov)
        public
        view
        returns (uint256[] memory)
    {
        return ssovExpiries[ssov];
    }

    function getTokenVaultRegistry(address token, bool isPut)
        public
        view
        returns (address)
    {
        return tokenVaultRegistry[token][isPut];
    }

    /*==== ERRORS ====*/
    error AmountTooSmall();
    error InsuffientLiquidity();
    error InvalidAmount();
    error InvalidDiscount();
    error InvalidEpochToFill();
    error InvalidLiquidity();
    error InvalidLpIndex();
    error InvalidMarkup();
    error InvalidParams();
    error InvalidStrike();
    error LpPositionKilled();
    error LpPositionFailedToAdd();
    error LpPositionFailedToFill();
    error LpPositionFailedToKill();
    error LpDustFailedToClear();
    error PositionFailedToKillAndTransfer();
    error OptionTokenExpired();
    error OnlyBuyerCanKill();
    error SsovDoesNotExist();
    error SsovEpochExpired();
    error SsovEpochIsZero();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

struct EpochStrikeData {
    address strikeToken;
    uint256 totalCollateral;
    uint256 activeCollateral;
    uint256 totalPremiums;
    uint256 checkpointPointer;
    uint256[] rewardStoredForPremiums;
    uint256[] rewardDistributionRatiosForPremiums;
}

struct EpochData {
    bool expired;
    uint256 startTime;
    uint256 expiry;
    uint256 settlementPrice;
    uint256 totalCollateralBalance; // Premium + Deposits from all strikes
    uint256 collateralExchangeRate; // Exchange rate for collateral to underlying (Only applicable to CALL options)
    uint256 settlementCollateralExchangeRate; // Exchange rate for collateral to underlying on settlement (Only applicable to CALL options)
    uint256[] strikes;
    uint256[] totalRewardsCollected;
    uint256[] rewardDistributionRatios;
    address[] rewardTokensToDistribute;
}

interface ISSOV {
    function getEpochStrikeData(uint256 epoch, uint256 strike)
        external
        view
        returns (EpochStrikeData memory);

    function getEpochData(uint256 epoch)
        external
        view
        returns (EpochData memory);

    function currentEpoch() external view returns (uint256);

    function calculatePremium(
        uint256 _strike,
        uint256 _amount,
        uint256 _expiry
    ) external view returns (uint256 premium);

    function getCollateralPrice() external view returns (uint256);

    function getEpochTimes(uint256 _epoch)
        external
        view
        returns (uint256, uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/// @title Lighter version of the Openzeppelin Pausable contract
/// @author witherblock
/// @notice Helps pause a contract to block the execution of selected functions
/// @dev Difference from the Openzeppelin version is changing the modifiers to internal fns and requires to reverts
abstract contract Pausable {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Internal function to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _whenNotPaused() internal view {
        if (paused()) revert ContractPaused();
    }

    /**
     * @dev Internal function to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _whenPaused() internal view {
        if (!paused()) revert ContractNotPaused();
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual {
        _whenNotPaused();
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual {
        _whenPaused();
        _paused = false;
        emit Unpaused(msg.sender);
    }

    error ContractPaused();
    error ContractNotPaused();
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/// @title ContractWhitelist
/// @author witherblock
/// @notice A helper contract that lets you add a list of whitelisted contracts that should be able to interact with restricited functions
abstract contract ContractWhitelist {
    /// @dev contract => whitelisted or not
    mapping(address => bool) public whitelistedContracts;

    /*==== SETTERS ====*/

    /// @dev add to the contract whitelist
    /// @param _contract the address of the contract to add to the contract whitelist
    function _addToContractWhitelist(address _contract) internal {
        require(isContract(_contract), "Address must be a contract");
        require(
            !whitelistedContracts[_contract],
            "Contract already whitelisted"
        );

        whitelistedContracts[_contract] = true;

        emit AddToContractWhitelist(_contract);
    }

    /// @dev remove from  the contract whitelist
    /// @param _contract the address of the contract to remove from the contract whitelist
    function _removeFromContractWhitelist(address _contract) internal {
        require(whitelistedContracts[_contract], "Contract not whitelisted");

        whitelistedContracts[_contract] = false;

        emit RemoveFromContractWhitelist(_contract);
    }

    // modifier is eligible sender modifier
    function _isEligibleSender() internal view {
        // the below condition checks whether the caller is a contract or not
        if (msg.sender != tx.origin)
            require(
                whitelistedContracts[msg.sender],
                "Contract must be whitelisted"
            );
    }

    /*==== VIEWS ====*/

    /// @dev checks for contract or eoa addresses
    /// @param addr the address to check
    /// @return bool whether the passed address is a contract address
    function isContract(address addr) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    /*==== EVENTS ====*/

    event AddToContractWhitelist(address indexed _contract);

    event RemoveFromContractWhitelist(address indexed _contract);
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