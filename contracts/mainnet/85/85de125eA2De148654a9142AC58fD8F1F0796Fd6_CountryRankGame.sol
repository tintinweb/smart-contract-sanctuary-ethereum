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

// SPDX-License-Identifier: none
pragma solidity ^0.8.17;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract CountryRankGame {
    // Country ISO code map to countries with holding of CountryRankPoint
    mapping(uint256 => uint256) public countryPool;
    // Country ISO code map to country reserves
    mapping(uint256 => uint256) public countryReserve;
    // Country ISO code map to pool shares issues of each country pool
    mapping(uint256 => uint256) public countryPoolIssuedShares;
    // Country wallet address map to country shares balance
    // Just need one balance as one address can only bind to one country
    mapping(address => uint256) public countrySharesBalance;
    // Wallet address map to country, one wallet to one country (ISO code)
    mapping(address => uint256) public countryPoolCommitted;
    // Country ISO code map to timestamp for reserve drip
    mapping(uint256 => uint256) public dripTimestamp;

    // CurrencyTokenAddress
    address public gameToken;
    // Game Admin address
    address admin;
    // Drip percentage rate
    uint256 public reserveDripAPR;
    // Taxrate
    uint256 public taxRate;
    // Constant of seconds in year
    uint256 immutable secondsInYear;

    // Errors
    error NotAdmin();
    error AlreadyCommittedToDifferentCountry();
    error TransferError();
    error AccountHasNoCommittedCountry();
    error NotEnoughShares();

    // Events
    event CommitToCountry(address indexed player, uint256 indexed countryCode, uint256 amount);
    event WithdrawFromCountry(address indexed player, uint256 indexed countryCode, uint256 amount);

    struct CountryInfo {
        uint256 poolBalance;
        uint256 reserveBalance;
        uint256 lastDripTimestamp;
    }

    constructor(address a, address token) {
        admin = a;
        gameToken = token;
        reserveDripAPR = 50;
        taxRate = 10;
        secondsInYear = 86400 * 365;
    }

    function updateDripAPR(uint256 rate, uint256[] memory countryCodes) public {
        if (msg.sender != admin) {
            revert NotAdmin();
        }

        for (uint256 i = 0; i < countryCodes.length; i++) {
            // Drip all the countries or selected countries before updating to a new rate
            reserveDrip(countryCodes[i]);
        }
        reserveDripAPR = rate;
    }

    function setTaxRate(uint256 rate) public {
        if (msg.sender != admin) {
            revert NotAdmin();
        }
        taxRate = rate;
    }

    function countryCommitted(address addr) public view returns (uint256) {
        return countryPoolCommitted[addr];
    }

    function commitToCountry(uint256 countryCode, uint256 amountToCommit) public {
        if (countryPoolCommitted[msg.sender] == 0) {
            // Initialize and set committed country code
            countryPoolCommitted[msg.sender] = countryCode;
        }

        if (countryPoolCommitted[msg.sender] != countryCode) {
            revert AlreadyCommittedToDifferentCountry();
        }

        bool success = IERC20(gameToken).transferFrom(msg.sender, address(this), amountToCommit);
        if (!success) {
            revert TransferError();
        }

        // Calculate drip amount first
        reserveDrip(countryCode);

        // Calculate # shares to issue
        uint256 tokensInPool = countryPool[countryCode];
        uint256 totalIssuedShares = countryPoolIssuedShares[countryCode];

        uint256 grantedShares;
        if (totalIssuedShares == 0) {
            grantedShares = amountToCommit;
        } else {
            grantedShares = amountToCommit * totalIssuedShares / tokensInPool;
        }
        // grantedShares = amount / share_value
        // share_value = tokensInPool / totalIssuedShares
        // grantedShares = amount / (toktensInPool / totalIssuedShares) = amount * totalIssuedShares / totkensInPool

        countrySharesBalance[msg.sender] += grantedShares;
        countryPool[countryCode] += amountToCommit;
        countryPoolIssuedShares[countryCode] += grantedShares;

        emit CommitToCountry(msg.sender, countryCode, amountToCommit);
    }

    // Wihtdraw committed token from the selected country
    // When withdraw fund from country, country will charge 10% tax from withdraw and keep it in country reserve
    function withdrawFromCountry(uint256 countryCode, uint256 shares) public {
        if (countryPoolCommitted[msg.sender] != countryCode) {
            revert AlreadyCommittedToDifferentCountry();
        }

        if (countrySharesBalance[msg.sender] < shares) {
            revert NotEnoughShares();
        }

        // Calculate drip amount first
        reserveDrip(countryCode);
        uint256 totalTokens = shares * countryPool[countryCode] / countryPoolIssuedShares[countryCode];
        uint256 tax = totalTokens * taxRate / 100;
        uint256 withdrawalTokens = totalTokens - tax;

        // Reduce shares balance
        countrySharesBalance[msg.sender] -= shares;
        // Remove committed country if have 0 shares
        if (countrySharesBalance[msg.sender] == 0) {
            countryPoolCommitted[msg.sender] = 0;
        }

        countryPoolIssuedShares[countryCode] -= shares;

        // Remove tokens from country pool
        countryPool[countryCode] -= totalTokens;

        // Move some tokens to country reserve
        countryReserve[countryCode] += tax;

        bool success = IERC20(gameToken).transfer(msg.sender, withdrawalTokens);
        if (!success) {
            revert TransferError();
        }

        emit WithdrawFromCountry(msg.sender, countryCode, totalTokens);
    }

    // Withdraw from country with no parameters
    // For fully withdraw from selected country 100%
    function withdrawFromCountry() public {
        if (countryPoolCommitted[msg.sender] == 0) {
            revert AccountHasNoCommittedCountry();
        }
        withdrawFromCountry(countryPoolCommitted[msg.sender], countrySharesBalance[msg.sender]);
    }

    // Function internal to drip from country reserve to country pool
    function reserveDrip(uint256 countryCode) internal {
        if (countryReserve[countryCode] != 0) {
            uint256 totalReserve = countryReserve[countryCode];
            // Calaulate amount to put into pool
            uint256 secondsElapsed = block.timestamp - dripTimestamp[countryCode];
            dripTimestamp[countryCode] = block.timestamp;

            uint256 dripAmount = totalReserve * reserveDripAPR * secondsElapsed / 100 / secondsInYear;
            countryReserve[countryCode] -= dripAmount;
            countryPool[countryCode] += dripAmount;
        } else {
            // Reset timestamp to current
            dripTimestamp[countryCode] = block.timestamp;
        }
    }

    function getPlayerTotalSharesOfCountryInToken(address player) public view returns (uint256) {
        if (countryPoolCommitted[player] == 0) {
            return 0;
        }
        return countrySharesBalance[player] * countryPool[countryPoolCommitted[player]]
            / countryPoolIssuedShares[countryPoolCommitted[player]];
    }

    function getCountryPoolInTokenBatch(uint256[] memory countryCodes) public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](countryCodes.length);
        for (uint256 i = 0; i < countryCodes.length; i++) {
            result[i] = countryPool[countryCodes[i]];
        }
        return result;
    }

    function getCountryReserveInTokenBatch(uint256[] memory countryCodes) public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](countryCodes.length);
        for (uint256 i = 0; i < countryCodes.length; i++) {
            result[i] = countryReserve[countryCodes[i]];
        }
        return result;
    }

    function getCountryDripTimestampBatch(uint256[] memory countryCodes) public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](countryCodes.length);
        for (uint256 i = 0; i < countryCodes.length; i++) {
            result[i] = dripTimestamp[countryCodes[i]];
        }
        return result;
    }

    function getCountryInfoBatch(uint256[] memory countryCodes)
        public
        view
        returns (uint256[] memory, uint256[] memory, uint256[] memory)
    {
        uint256[] memory pool = getCountryPoolInTokenBatch(countryCodes);
        uint256[] memory reserve = getCountryReserveInTokenBatch(countryCodes);
        uint256[] memory timestamp = getCountryDripTimestampBatch(countryCodes);
        return (pool, reserve, timestamp);
    }
}