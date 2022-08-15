//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;
import "./Pool.sol";
import "./SpaceCoin.sol";

/**
 * @notice Router implementation for Pool usage
 * @dev Contract goals:
 * Add and remove liquidity.
 * Swap tokens, rejecting if the slippage is above a given amount
 * 
 * @dev Process for transferring tokens to an LP pool:
 * 1. Trader grants allowance on the Router contract for Y tokens
 * 2. Trader executes a function on the Router which pulls the funds 
 *    from the Trader and transfers them to the LP Pool
 */
contract Router {
    /*****************************************
     * Constants and Immutables
     *****************************************/

    /// @notice Address of the pool the router interacts with
    address payable public pool;

    /// @notice Address of the spaceCoin token used in the pool
    address public spaceCoin;

    /*****************************************
     * Events
     *****************************************/

    /**
     * @notice Event fired when liquidity is added
     * @param user Address of the user providing liquidity
     * @param inEth Amount of ETH user specified to deposit
     * @param inSpc Amount of SPC user specified to deposit
     * @param optEth Amount of ETH actually deposited
     * @param optSpc Amount of SPC actually deposited
     */
    event DepositEvent(
        address indexed user,
        uint256 inEth,
        uint256 inSpc,
        uint256 optEth,
        uint256 optSpc
    );

    /**
     * @notice Event fired when liquidity is removed
     * @param user Address of the user removes liquidity
     * @param burnLp Amount of LP token to be burned 
     * @param outEth Amount of ETH received from LP Token
     * @param outSpc Amount of Spc received from LP Token
     */
    event WithdrawEvent(
        address indexed user,
        uint256 burnLp,
        uint256 outEth,
        uint256 outSpc
    );

    /**
     * @notice Event fired when tokens are swapped
     * @param user Address of the user who swaps tokens
     * @param inEth Amount of ETH deposited for swap
     * @param outSpc Amount of SPC received from swap
     */
    event SwapEthForSpcEvent(
        address indexed user,
        uint256 inEth,
        uint256 outSpc
    );

    /**
     * @notice Event fired when tokens are swapped
     * @param user Address of the user who swaps tokens
     * @param inSpc Amount of SPC deposited for swap
     * @param outEth Amount of ETH received from swap
     */
    event SwapSpcForEthEvent(
        address indexed user,
        uint256 inSpc,
        uint256 outEth
    );

    /*****************************************
     * Construction and Initialization
     *****************************************/

    /**
     * @notice Initializes the Router contract 
     * @param _pool Address for the Pool contract
     */
    constructor(address payable _pool) {
        pool = _pool;
        spaceCoin = Pool(pool).spaceCoin();
    }

    /// @notice Allow contract to receive ETH
    receive() external payable {}

    /*****************************************
     * Helper functions
     *****************************************/

    /** 
     * @notice Need to verify that `depositEth` and `depositSpc` follow the 
     * pricing rules of Constant Product, otherwise user might provide
     * too much of one asset. The pool contract has no protection for users
     * @param depositEth Amount of ETH user specified to deposit
     * @param depositSpc Amount of SPC user specified to deposit
     * @return optimalEth Amount of ETH that should be deposited
     * @return optimalSpc Amount of ETH that should be deposited
     */
    function _getOptimalAmounts(uint256 depositEth, uint256 depositSpc) 
        internal
        view
        returns (uint256, uint256) 
    {
        // Get the amount of reserves in the pool
        (uint256 reserveEth, uint256 reserveSpc) = Pool(pool).getReserve();

        if ((reserveEth == 0) && (reserveSpc == 0)) {
          // Nothing to compute - take user for their word
          return (depositEth, depositSpc);
        }

        // Fix `depositEth` and compute how much SPC needs to be deposited w/ it
        /// @dev delta x = x  * delta y / y
        uint256 optimalSpc = reserveSpc * depositEth / reserveEth;

        // If `depositSpc > optimalSpc`, then we are done
        if (optimalSpc <= depositSpc) {
            return (depositEth, optimalSpc);
        }

        // If we don't have enough SPC coin, then work backwards. Start with 
        // the SPC coin we do have and compute `optimalETH`
        uint256 optimalEth = reserveEth * depositSpc / reserveSpc;

        // It must be that `optimalEth < depositEth` since `depositSpc < optimalSpc`
        require(
            optimalEth <= depositEth, 
            "_getOptimalAmounts: how did you get here?"
        );
        
        return (optimalEth, depositSpc);
    }

    /*****************************************
     * User functions
     *****************************************/

    /** 
     * @notice Function to add liquidity
     * @dev Assumes `msg.sender` has granted allowance for SPC
     * @dev Expects ETH to be sent to function via `msg.value` since we cannot
     * use WETH and we cannot pull ETH from accounts
     * @dev Extra ETH will be returned to user
     * @param inSpc Maximum/Ideal amount of SPC to deposit
     * @return ownedLp Amount of LP tokens minted
     */
    function deposit(uint256 inSpc) external payable returns (uint256 ownedLp)
    {
        require(msg.value > 0, "addLiquidity: `msg.value` must be > 0");
        require(inSpc > 0, "addLiquidity: `inSpc` must be > 0");

        // In case the user attempts to over-pay for LP, we compute optimal values
        (uint256 optEth, uint256 optSpc) = _getOptimalAmounts(msg.value, inSpc);

        require(optEth <= msg.value, "Optimal ETH must be no larger than inputed ETH");
        require(optSpc <= inSpc, "Optimal SPC must be no larger than inputed SPC");

        bool success;

        // Extract ETH from user to pool: requires user's approval
        (success,) = payable(pool).call{value: optEth}("");
        require(success, "addLiquidity: failed to transfer ETH");

        // Send any leftover ETH back to caller
        if (msg.value > optEth) {
            (success,) = payable(msg.sender).call{value: msg.value - optEth}("");
            require(success, "addLiquidity: failed to refund ETH");
        }

        // Extract SPC from user to pool; requires allowance to be set prior
        SpaceCoin(spaceCoin).transferFrom(msg.sender, pool, optSpc);

        // Call mint function. Benefit of router is to transfer and mint
        // within the same transaction
        ownedLp = Pool(pool).mint(msg.sender);

        // Emit event
        emit DepositEvent(msg.sender, msg.value, inSpc, optEth, optSpc);
    }

    /**
     * @notice Function to remove liquidity
     * @dev Emits `WithdrawEvent` event
     * @param burnLp Amount of LP tokens owned
     * @return outEth Amount of ETH obtained from burning LP
     * @return outSpc Amount of SPC obtained from burning LP
     */
    function withdraw(uint256 burnLp) 
        external
        returns (uint256 outEth, uint256 outSpc) 
    {
        require(burnLp > 0, "removeLiquidity: `burnLp` must be > 0");
        require(
            Pool(pool).balanceOf(msg.sender) >= burnLp,
            "removeLiquidity: not enough LP to burn"
        );

        // Send LP tokens from user to pool
        Pool(pool).transferFrom(msg.sender, pool, burnLp);

        // Call burn function
        (outEth, outSpc) = Pool(pool).burn(msg.sender);

        // Emit event
        emit WithdrawEvent(msg.sender, burnLp, outEth, outSpc);
    }

    /**
     * @notice Swap ETH for SPC using the pool
     * @dev Expects ETH to be sent to function via `msg.value` since we cannot
     * use WETH and we cannot pull ETH from accounts
     * @dev Extra ETH will be returned to user
     * @param minOutSpc Minimum amount of SPC to receive or else tx reverts. 
     * Used to implicitly define max slippage
     */
    function swapEthForSpc(uint256 minOutSpc) external payable {
        require(msg.value > 0, "swapEthForSpc: Amount of ETH supplied must be > 0");

        // Transfer ETH to pool
        (bool success,) = payable(pool).call{value: msg.value}("");
        require(success, "addLiquidity: failed to transfer ETH");

        // Compute expected amount of SPC to receive for swapping ETH
        uint256 outSpc = Pool(pool).calcEthForSpc(msg.value);

        // Revert if slippage exceeds user limit
        require(minOutSpc < outSpc, "swapEthForSpc: exceeded max slippage");

        // Perform the swap
        Pool(pool).swapEthForSpc(msg.sender, outSpc);

        // Emit event
        emit SwapEthForSpcEvent(msg.sender, msg.value, outSpc);
    }

    /**
     * @notice Swap SPC for ETH using the pool
     * @param inSpc Amount of SPC to use for the swap. This will be taken from
     * the user's account. Requires allowance from user
     * @param minOutEth Minimum amount of ETH to receive or else tx reverts
     */
    function swapSpcForEth(uint256 inSpc, uint256 minOutEth) external {
        require(inSpc > 0, "swapEthForSpc: Amount of SPC supplied must be > 0");

        // Transfer SPC to pool
        SpaceCoin(spaceCoin).transferFrom(msg.sender, pool, inSpc);

        // Compute expected amount of ETH to receive for swapping SPC
        uint256 outEth = Pool(pool).calcSpcForEth(inSpc);

        // Revert if slippage exceeds user limit
        require(minOutEth < outEth, "swapSpcForEth: exceeded max slippage");

        // Perform the swap
        Pool(pool).swapSpcForEth(msg.sender, outEth);

        // Emit event
        emit SwapSpcForEthEvent(msg.sender, inSpc, outEth);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SpaceCoin.sol";

/**
 * @notice Pool token implementation
 * @dev Contract goals:
 *  Mints LP tokens for liquidity deposits (ETH + SPC tokens)
 *  Burns LP tokens to return liquidity to holder
 *  Accepts trades with a 1% fee
 */
contract Pool is ERC20("LiquidityToken", "LP") {
    /*****************************************
     * Constants and Immutables
     *****************************************/

    // @notice Owner address
    address immutable public owner;

    /// @notice Charge 1% on every swap (i.e. 1/100)
    uint256 constant public FEE_PERC = 1;

    /// @notice Amount of LP tokens minted to noone. This 
    /// saves us from dividing by 0
    /// @dev Choice of 1000 is inspired by Uniswap-v2
    uint256 constant public MIN_LP = 1000;

    /// @notice Address for the second token in the pair
    /// @dev We will often set this as the SPC token
    address public immutable spaceCoin;

    /// @notice Stores the amount of tokenX owned by contract
    /// @dev Used to calculate new assets in a `mint` call
    uint256 private reserveEth;

    /// @notice Stores the amount of tokenY owned by contract
    uint256 private reserveSpc;

    /*****************************************
     * Events
     *****************************************/

    /**
     * @notice Event when minting an LP token
     * @param user Address of the individual minting a token
     * @param eth Amount of token X being put in
     * @param spc Amount of token Y being put in
     * @param lp Amount of LP token being minted
     */
    event MintEvent(
        address indexed user,
        uint256 eth,
        uint256 spc,
        uint256 lp
    );

    /**
     * @notice Event when burning an LP token
     * @param user Address of the individual burning an LP token
     * @param lp Amount of LP token being burned
     * @param eth Amount of token X being returned
     * @param spc Amount of token Y being returned
     */
    event BurnEvent(
        address indexed user,
        uint256 lp,
        uint256 eth,
        uint256 spc
    );

    /**
     * @notice Event when swapping tokens
     * @param user Address of the individual making a swap
     * @param inEth Amount of ETH deposited for swap
     * @param feeEth Amount of ETH fee for swap
     * @param outSpc Amount of SPC obtained from swap
     */
    event SwapEthForSpcEvent(
        address indexed user,
        uint256 inEth,
        uint256 feeEth,
        uint256 outSpc
    );

    /**
     * @notice Event when swapping tokens
     * @param user Address of the individual making a swap
     * @param inSpc Amount of SPC deposited for swap
     * @param feeSpc Amount of SPC fee for swap
     * @param outEth Amount of ETH obtained from swap
     */
    event SwapSpcForEthEvent(
        address indexed user,
        uint256 inSpc,
        uint256 feeSpc,
        uint256 outEth
    );

    /*****************************************
     * Construction and Initialization
     *****************************************/

    /**
     * @notice Initializes the Pool contract 
     * @param _spaceCoin Address for the `SpaceCoin` contract
     */
    constructor(address _spaceCoin) {
        spaceCoin = _spaceCoin;
        owner = msg.sender;
    }

    /// @notice Allow contract to receive ETH
    receive() external payable {}

    /*****************************************
     * Helper functions
     *****************************************/

    /**
     * @notice Compute the balance amount of owned assets in contract
     * @return balanceEth Amount of ETH
     * @return balanceSpc Amount of SPC
     */
    function _getBalance() internal view returns (
        uint256 balanceEth,
        uint256 balanceSpc
    ) {
        // Get current balance of ETH token
        balanceEth = address(this).balance;
        // Get current balance of SPC token
        balanceSpc = SpaceCoin(spaceCoin).balanceOf(address(this));
    }

    /**
     * @notice Get reserves held in the contract
     * @return reverseEth Amount of ETH
     * @return reverseSPc Amount of SPC
     */
    function getReserve() public view returns (uint256, uint256) {
        return (reserveEth, reserveSpc);
    }

    /**
     * @notice Helper function to calculate amount of SPC if we trade ETH
     * @dev Takes fee into account. Formula is:
     *  delta y = y * (1-fee) * delta x / (x + (1-fee) * delta x).
     * See https://betterprogramming.pub/uniswap-v2-in-depth-98075c826254
     */
    function calcEthForSpc(uint256 inEth)
        external
        view
        returns (uint256 outSpc) 
    {
        // Use Uniswap's trick to move dividing by fee decimals to the denominator
        uint256 deltaEthMulFee = inEth * (100 - FEE_PERC);
        outSpc = reserveSpc * deltaEthMulFee / (reserveEth * 100 + deltaEthMulFee);
    }

    /**
     * @notice Helper function to calculate amount of ETH if we trade SPC
     * @dev Takes fee into account. Formula is:
     *  delta x = x * (1-fee) * delta y / (y + (1-fee) * delta y).
     * See https://betterprogramming.pub/uniswap-v2-in-depth-98075c826254
     */
    function calcSpcForEth(uint256 inSpc) 
        external
        view
        returns (uint256 outEth) 
    {
        // Use Uniswap's trick to move dividing by fee decimals to the denominator
        uint256 deltaSpcMulFee = inSpc * (100 - FEE_PERC);
        outEth = reserveEth * deltaSpcMulFee / (reserveSpc * 100 + deltaSpcMulFee);
    }

    /*****************************************
     * User functions
     *****************************************/

    /**
     * @notice Mint LP tokens by contributing tokenX and tokenY
     * @dev Emits a `MintEvent` event
     * @param to Address performing the mint
     * @return deltaLp Amount of LP tokens minted
     */
    function mint(address to) external returns (uint256 deltaLp) {
        // Get snapshot of balances of tokens
        (uint256 balanceEth, uint256 balanceSpc) = _getBalance();

        // Get total amount of LP tokens
        uint256 totalLp = totalSupply();

        // Sanity checks before performing a subtraction.
        // Holds since user/router needs to have transferred assets prior.
        // This check also implicitly checks the invariant should increase
        require(balanceEth > reserveEth, "mint: did the user send ETH?");
        require(balanceSpc > reserveSpc, "mint: did the user send SPC?");

        // Compute amount user/router transferred. It is up to user/router to 
        // transfer correct amount. Excess tokens are not returned to the user
        uint256 deltaEth = balanceEth - reserveEth;
        uint256 deltaSpc = balanceSpc - reserveSpc;

        if (totalLp == 0) {
            /**
             * If it is the first time depositing liquidity, we compute using 
             * a different formula:
             *    sqrt(deltaEth * deltaSpc) - MIN_LP
             * We also mint MIN_LP tokens to noone: address(0).
             * Based on: https://betterprogramming.pub/uniswap-v2-in-depth-98075c826254
             */
            uint256 tmpLp = sqrt(deltaEth * deltaSpc);
            require(tmpLp > MIN_LP, "mint: first mint must be larger");
            deltaLp = tmpLp - MIN_LP;

            // Throw away the minimum amount by minting to self
            _mint(address(owner), MIN_LP);
        } else {
            /**
             * Compute amount of LP tokens to mint as the amount of contributed 
             * asset times the balance amount of LP token. More specifically:
             *    min { L * (delta x / x) or L * (delta y / y) }
             */
            // Compute both amounts
            uint256 deltaLpFromEth = totalLp * deltaEth / balanceEth;
            uint256 deltaLpFromSpc = totalLp * deltaSpc / balanceSpc;
            // Take the minimum of the two
            if (deltaLpFromEth <= deltaLpFromSpc) {
                deltaLp = deltaLpFromEth;
            } else {
                deltaLp = deltaLpFromSpc;
            }
        }

        // Check `deltaLp` is a sane variable
        require(deltaLp > 0, "mint: amount of LP to mint must be positive");

        // Call mint function
        _mint(to, deltaLp);

        // Emit event to logs
        emit MintEvent(to, deltaEth, deltaSpc, deltaLp);

        // Sync reserves to balances. Since no transfers of ETH/SPC happen in 
        // this function, balances computed at start of fn are accurate
        /// @dev Syncing reserves to balances prevents Spartan hacks
        reserveEth = balanceEth;
        reserveSpc = balanceSpc;
    }

    /**
     * @notice Burn LP tokens in exchange for tokenX and tokenY
     * @dev Assumes that LP tokens will be transferred from `to` to this contract.
     * @dev Emits a `BurnEvent` event
     * @param to Address performing the burn
     * @return deltaEth Amount of ETH returned for burning LP
     * @return deltaSpc Amount of SPC returned for burning LP
     */
    function burn(address to)
        external
        returns (uint256 deltaEth, uint256 deltaSpc)
    {
        uint256 balanceEth;
        uint256 balanceSpc;

        // Get snapshot of balances of tokens
        (balanceEth, balanceSpc) = _getBalance();

        // Get total amount of LP tokens
        uint256 totalLp = totalSupply();

        // Sanity check on supply of LP tokens
        require(totalLp > 0, "burn: supply of LP must be > 0 to burn");

        // Get balance of Lp tokens owned by address
        uint256 deltaLp = balanceOf(address(this));
        
        // Compute amount of owed assets according to the formulas:
        //  delta x = (delta L / L) * x
        //  delta y = (delta L / L) * y
        deltaEth = balanceEth * deltaLp / totalLp;
        deltaSpc = balanceSpc * deltaLp / totalLp;

        // Sanity checks on amount of ETH and SPC to return
        // This also implicitly checks that the invariant should decrease
        require(deltaEth > 0, "burn: deltaEth <= 0");
        require(deltaSpc > 0, "burn: deltaSpc <= 0");

        // Burn the LP tokens: we have assumed the LP tokens are owned by 
        // this contract instead of the user `to`
        _burn(address(this), deltaLp);

        // Transfer ETH
        (bool success,) = payable(to).call{value: deltaEth}("");
        require(success, "burn: failed to transfer ETH");

        // Transfer SPC
        ERC20(spaceCoin).transfer(to, deltaSpc);

        // Emit event to logs
        emit BurnEvent(to, deltaLp, deltaEth, deltaSpc);

        // Re-fetch balances after transfers and sync reserves. We need to 
        // recompute balances since SPC and ETH were just transferred out
        (reserveEth, reserveSpc) = _getBalance();
    }

    /**
     * @notice Swap ETH for SPC
     * @dev Assume that the ETH tokens have been transferred to address
     * @dev Emits a `SwapEthForSpcEvent` event
     * @param to Address to send swapped tokens to
     * @param outSpc Amount of SPC desired post-swap 
     */
    function swapEthForSpc(address to, uint256 outSpc) external {
        // Check desired amount of SPC is not too small nor too big
        require(outSpc > 0, "swapEthForSpc: `outSpc` must be > 0");
        require(outSpc < reserveSpc, "swapEthForSpc: desired SPC too big");

        /**
         * @dev Perform an optimistic transfer - inspired by Uniswap-v2. 
         * In other words, trust that `outSpc` preserves invariant
         * @dev Doing so allows to compute actual balances post-trade. The 
         * alternative would be to calculate the expected balances, but
         * this has less guarantees. For example, SPC might have a tax on
         * transfer, which would not be captured by xy=k
         */
        ERC20(spaceCoin).transfer(to, outSpc);

        // Fetch new (actual) balance of ETH
        (uint256 balanceEth, uint256 balanceSpc) = _getBalance();

        // User/router must have deposited ETH prior to this call
        require(
            balanceEth > reserveEth, 
            "swapEthForSpc: reserve of ETH > balance"
        );

        // Fees are charged on the difference i.e. the amount of ETH sent
        uint256 feeEth = (balanceEth - reserveEth) * FEE_PERC / 100;

        // When checking invariant, do not count fees
        uint256 balanceEthNoFee = balanceEth - feeEth;

        // Check that the invariant is constant after transfer
        // If not, entire transaction will revert, including optimistic swap
        /// @dev We allow the new invariant to be larger if user deposits more
        require(
            (balanceEthNoFee * balanceSpc) >= (reserveEth * reserveSpc), 
            "swapEthForSpc: invariant cannot decrease"
        );

        // Emit event
        emit SwapEthForSpcEvent(
            to,
            balanceEth - reserveEth,
            feeEth,
            outSpc
        );

        // Sync reserves with new (re-computed) balances
        (reserveEth, reserveSpc) = _getBalance();
    }

    /**
     * @notice Swap ETH for SPC
     * @dev Assume that the SPC tokens have been transferred to address 
     * @dev Emits a `SwapSpcForEthEvent` event
     * @param to Address to send swapped tokens to
     * @param outEth Amount of SPC desired post-swap 
     */
    function swapSpcForEth(address to, uint256 outEth) external {
        // Check desired amount of Eth is not too small nor too big
        require(outEth > 0, "swapSpcForEth: `outEth` must be > 0");
        require(outEth < reserveSpc, "swapSpcForEth: desired ETH too big");

        // Optimistic transfer of ETH. See comments in `swapEthForSpc`
        (bool success,) = payable(to).call{value: outEth}("");
        require(success, "swap: failed to transfer ETH");

        // Fetch balance of SPC
        (uint256 balanceEth, uint256 balanceSpc) = _getBalance();

        // User/router must have deposited ETH prior to this call
        require(
            balanceSpc > reserveSpc,
            "swapSpcForEth: reserve of SPC > balance"
        );

        // Fees are charged on the difference i.e. the amount of SPC sent
        uint256 feeSpc = (balanceSpc - reserveSpc) * FEE_PERC / 100;

        // Simulate new reserves after trade and not counting fees
        uint256 balanceSpcNoFee = balanceSpc - feeSpc;

        // Check that the invariant is constant
        // If not, entire transaction will revert, including optimistic swap
        /// @dev We allow the new invariant to be larger if user deposits more
        require(
            (balanceEth * balanceSpcNoFee) >= (reserveEth * reserveSpc), 
            "swapSpcForEth: invariant cannot decrease"
        );

        // Emit event
        emit SwapSpcForEthEvent(
            to,
            balanceSpc - reserveSpc,
            feeSpc,
            outEth
        );

        // Sync reserves with new (re-computed) balances
        (reserveEth, reserveSpc) = _getBalance();
    }

    /**
     * @notice Helper function to compute square roots
     * @param x Value to take a square root of
     * @return y Square root of `x`
     * @dev Copied from https://ethereum.stackexchange.com/questions/2910/can-i-square-root-in-solidity
     */
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @notice SpaceCoin (SPC) token implementation
 */
contract SpaceCoin is ERC20("SpaceCoin", "SPC") {
    /// @notice Stores the address of the contract deployer
    /// @dev Call it `deployer` to distinguish from token owners
    address public immutable deployer;

    /// @notice Address of the treasury account
    address public immutable treasury;

    /// @notice Flag to control if tax is on or off (default off)
    bool public taxOn;

    /// @notice Tax percentage
    uint256 private constant TAX_AMOUNT = 2;

    /// @notice Max total supply of 500k
    uint256 public constant MAX_SUPPLY = 500000 * 10**18;

    /**
     * @notice Event to represent a change in tax
     * @param taxOn If the tax is on or off
     */
    event ToggleTaxEvent(bool taxOn);

    /**
     * @notice Modifier that restricts to only the deployer
     */
    modifier onlyDeployer() {
        require(msg.sender == deployer, "onlyDeployer: not the deployer");
        _;
    }

    /**
     * @notice Initializes the SpaceCoin contract
     * @param _treasury Address for the treasury account. Cannot be empty
     */
    constructor(address _treasury) {
        deployer = msg.sender;
        treasury = _treasury;

        // Mints maximum amount of tokens to deployer
        _mint(deployer, MAX_SUPPLY);
    }

    /**
     * @notice Wrapper around `ERC20._transfer` but takes tax into account
     * @dev Used in both public `transfer` and `transferFrom` functions. Emits a `Transfer` emit
     * @param from Address sending tokens. Cannot be empty
     * @param to Address receiving tokens. Cannot be empty
     * @param amount Amount to transfer. The `from` address must have at least this amount
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // Defer to `_transfer` for other checks
        require(amount > 0, "_transfer: `amount` must be non-positive");
        if (taxOn) {
            // If tax, pass 98% to address `to` and 2% to treasury
            /// @dev Divide by 6 because decimals 4 plus 2 for percentages
            uint256 taxAmount = (TAX_AMOUNT * amount) / 100;
            require(
                taxAmount < amount,
                "_transfer: tax must be less than `amount`"
            );
            uint256 transferAmount = amount - taxAmount;
            super._transfer(from, to, transferAmount);
            super._transfer(from, treasury, taxAmount);
        } else {
            // If no tax, call parent with default args
            super._transfer(from, to, amount);
        }
    }

    /**
     * @notice Turn the tax on or off. Can be called only by deployer
     */
    function toggleTax() public onlyDeployer {
        taxOn = !taxOn;
        emit ToggleTaxEvent(taxOn);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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
     * @dev Moves `amount` of tokens from `from` to `to`.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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