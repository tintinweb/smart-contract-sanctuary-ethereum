/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/Ponzi/PonziToken/DividendDistributor.sol


pragma solidity ^0.8.7;


contract DividendDistributor {
    address public TOKEN;
    IERC20 public USDT;
    
    struct Share {
        uint256 amount;
        uint256 excluded;
        uint256 rewardConfirmed;
        uint256 rewardClaimed;
    }

    address[] public shareholders;
    mapping(address => uint256) public shareholderIndexes;
    
    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor;
    
    modifier onlyToken() {
        require(msg.sender == TOKEN);
        _;
    }
    constructor(address USDTToken) {
        TOKEN = msg.sender;
        USDT = IERC20(USDTToken);
        dividendsPerShareAccuracyFactor = 10**36;
    }

    function getTotalShareHoldersAmount() public view returns (uint256) {
        return shareholders.length;
    }
    
    function depositUSDT(uint256 amount) public onlyToken {
        totalDividends = totalDividends + amount;
        dividendsPerShare = dividendsPerShare + dividendsPerShareAccuracyFactor * amount / totalShares;
    }

    function setShare(address shareholder, uint256 tokenAmount) public onlyToken {
        if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }

        if (tokenAmount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        }else if (tokenAmount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares - shares[shareholder].amount + tokenAmount;

        shares[shareholder].amount = tokenAmount;
        shares[shareholder].excluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share * dividendsPerShare / dividendsPerShareAccuracyFactor;
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length - 1];
        shareholderIndexes[shareholders[shareholders.length - 1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function distributeDividend(address shareholder) internal {
        if (shares[shareholder].amount == 0) return;

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed + amount;
            shares[shareholder].rewardConfirmed = shares[shareholder].rewardConfirmed + amount;
            shares[shareholder].excluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function getUnpaidEarnings(address shareholder) internal view returns (uint256) {
        if (shares[shareholder].amount == 0) return 0;

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);

        uint256 shareholderTotalExcluded = shares[shareholder].excluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) return 0;

        return shareholderTotalDividends - shareholderTotalExcluded;
    }

    function getUnclaimedRewards(address shareholder) public view returns (uint256) {
        return shares[shareholder].rewardConfirmed + getUnpaidEarnings(shareholder);
    }

    function getClaimedRewards(address shareholder) public view returns (uint256) {
        return shares[shareholder].rewardClaimed;
    }
    
    receive() external payable {}

    function claimRewards(address shareholder) public onlyToken {
        distributeDividend(shareholder);
        require(shares[shareholder].rewardConfirmed > 0, "Nothing Rewards");

        USDT.transfer(shareholder, shares[shareholder].rewardConfirmed);
        shares[shareholder].rewardClaimed = shares[shareholder].rewardClaimed + shares[shareholder].rewardConfirmed;
        shares[shareholder].rewardConfirmed = 0;
    }
}