// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "../IERC1410.sol"; // Interface for the ERC1410 token contract
import "../openzeppelin/IERC20.sol"; // Interface for the ERC20 token contract
import "../openzeppelin/SafeMath.sol";

contract DividendsDistribution {
    using SafeMath for uint256;

    struct Dividend {
        bytes32 partition;
        uint256 blockNumber;
        uint256 exDividendDate;
        uint256 recordDate;
        uint256 payoutDate;
        uint256 amount;
        uint256 totalSupplyOfShares;
        address payoutToken;
        bool isERC20Payout;
        uint256 amountRemaining;
        bool recycled;
        mapping(address => bool) claimed;
    }

    string public contractVersion = "0.1.0";
    IERC1410 public sharesToken;
    uint256 public reclaim_time;
    mapping(address => uint256) public balances;
    Dividend[] public dividends;

    event DividendDeposited(
        address indexed depositor,
        uint256 dividendIndex,
        uint256 blockNumber,
        uint256 amount,
        bytes32 partition,
        bool isERC20
    );
    event DividendClaimed(
        address indexed claimer,
        uint256 dividendIndex,
        uint256 amount,
        bool isERC20
    );
    event DividendRecycled(
        address indexed recycler,
        uint256 dividendIndex,
        uint256 amount
    );

    modifier onlyOwnerOrManager() {
        require(
            sharesToken.isOwner(msg.sender) ||
                sharesToken.isManager(msg.sender),
            "Sender is not the owner or manager"
        );
        _;
    }

    constructor(IERC1410 _sharesToken, uint256 _reclaim_time) {
        sharesToken = _sharesToken;
        reclaim_time = _reclaim_time;
    }

    function depositDividend(
        uint256 _blockNumber,
        uint256 _exDividendDate,
        uint256 _recordDate,
        uint256 _payoutDate,
        uint256 _amount,
        address _payoutToken,
        bytes32 _partition
    ) external onlyOwnerOrManager {
        require(_amount > 0, "Amount must be greater than zero");
        require(
            _payoutDate > block.timestamp,
            "Payout date must be in the future"
        );

        uint256 totalSupplyOfShares = sharesToken.totalSupplyAt(
            _partition,
            _blockNumber
        );
        require(
            totalSupplyOfShares > 0,
            "Total supply of shares must be greater than zero"
        );

        // Transfer the ERC20 tokens to this contract
        IERC20(_payoutToken).transferFrom(msg.sender, address(this), _amount);

        balances[_payoutToken] = balances[_payoutToken].add(_amount);

        uint256 dividendIndex = dividends.length;

        dividends.push();
        Dividend storage newDividend = dividends[dividendIndex];
        newDividend.blockNumber = _blockNumber;
        newDividend.partition = _partition;
        newDividend.exDividendDate = _exDividendDate;
        newDividend.recordDate = _recordDate;
        newDividend.payoutDate = _payoutDate;
        newDividend.amount = _amount;
        newDividend.totalSupplyOfShares = totalSupplyOfShares;
        newDividend.payoutToken = _payoutToken;
        newDividend.isERC20Payout = (_payoutToken != address(0));
        newDividend.amountRemaining = _amount;
        newDividend.recycled = false;

        emit DividendDeposited(
            msg.sender,
            dividendIndex,
            _blockNumber,
            _amount,
            _partition,
            _payoutToken != address(0)
        );
    }

    function claimDividend(uint256 _dividendIndex) external {
        require(
            _dividendIndex < dividends.length && _dividendIndex >= 0,
            "Invalid dividend index"
        );

        Dividend storage dividend = dividends[_dividendIndex];
        require(
            block.timestamp >= dividend.payoutDate,
            "Cannot claim dividend before payout date"
        );
        require(
            !dividend.claimed[msg.sender],
            "Dividend already claimed by the sender"
        );
        require(!dividend.recycled, "Dividend has been recycled");

        uint256 shareBalance = sharesToken.balanceOfAt(
            dividend.partition,
            msg.sender,
            dividend.blockNumber
        );
        require(shareBalance > 0, "Sender does not hold any shares");

        uint256 claimAmount = dividend.amount.mul(shareBalance).div(
            dividend.totalSupplyOfShares
        );
        require(
            claimAmount <= dividend.amountRemaining,
            "Insufficient remaining dividend amount"
        );

        dividend.claimed[msg.sender] = true;
        dividend.amountRemaining = dividend.amountRemaining.sub(claimAmount);
        if (dividend.isERC20Payout) {
            require(
                dividend.payoutToken != address(0),
                "Invalid payout token address"
            );
            IERC20(dividend.payoutToken).transfer(msg.sender, claimAmount);
        } else {
            payable(msg.sender).transfer(claimAmount);
        }

        emit DividendClaimed(
            msg.sender,
            _dividendIndex,
            claimAmount,
            dividend.isERC20Payout
        );
    }

    function recycleDividend(
        uint256 _dividendIndex
    ) external onlyOwnerOrManager {
        require(_dividendIndex < dividends.length, "Invalid dividend index");

        Dividend storage dividend = dividends[_dividendIndex];
        require(!dividend.recycled, "Dividend has already been recycled");
        require(
            block.timestamp >= dividend.payoutDate.add(reclaim_time),
            "Cannot recycle dividend before reclaim time"
        );

        uint256 remainingAmount = dividend.amountRemaining;
        require(remainingAmount > 0, "No remaining dividend amount to recycle");

        dividend.recycled = true;
        balances[dividend.payoutToken] = balances[dividend.payoutToken].sub(
            remainingAmount
        );
        dividend.amountRemaining = 0;

        if (dividend.isERC20Payout) {
            require(
                dividend.payoutToken != address(0),
                "Invalid payout token address"
            );
            IERC20(dividend.payoutToken).transfer(msg.sender, remainingAmount);
        } else {
            payable(msg.sender).transfer(remainingAmount);
        }

        emit DividendRecycled(msg.sender, _dividendIndex, remainingAmount);
    }

    function getClaimableAmount(
        address _address,
        uint256 _dividendIndex
    ) external view returns (uint256) {
        require(_dividendIndex < dividends.length, "Invalid dividend index");
        Dividend storage dividend = dividends[_dividendIndex];
        if (block.timestamp < dividend.payoutDate) {
            return 0;
        }
        if (
            dividend.claimed[_address] ||
            dividend.recycled ||
            dividend.amountRemaining == 0 ||
            sharesToken.balanceOf(_address) == 0
        ) {
            return 0;
        }

        uint256 shareBalance = sharesToken.balanceOfAt(
            dividend.partition,
            _address,
            dividend.blockNumber
        );
        uint256 claimAmount = dividend.amount.mul(shareBalance).div(
            dividend.totalSupplyOfShares
        );
        return claimAmount;
    }

    function hasClaimedDividend(
        address _address,
        uint256 _dividendIndex
    ) external view returns (bool) {
        require(_dividendIndex < dividends.length, "Invalid dividend index");
        Dividend storage dividend = dividends[_dividendIndex];
        return dividend.claimed[_address];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IERC1410 {
    // Token Information
    function balanceOf(address _tokenHolder) external view returns (uint256);

    function balanceOfAt(
        bytes32 partition,
        address _owner,
        uint256 _blockNumber
    ) external view returns (uint256);

    function totalSupplyAt(
        bytes32 partition,
        uint256 _blockNumber
    ) external view returns (uint256);

    function balanceOfByPartition(
        bytes32 _partition,
        address _tokenHolder
    ) external view returns (uint256);

    function partitionsOf(
        address _tokenHolder
    ) external view returns (bytes32[] memory);

    function totalSupply() external view returns (uint256);

    // Token Issue
    function operatorIssueByPartition(
        bytes32 _partition,
        address _tokenHolder,
        uint256 _value
    ) external;

    // Token Transfers
    function transferByPartition(
        bytes32 _partition,
        address _to,
        uint256 _value
    ) external returns (bytes32);

    function operatorTransferByPartition(
        bytes32 _partition,
        address _from,
        address _to,
        uint256 _value
    ) external returns (bytes32);

    function canTransferByPartition(
        address _from,
        address _to,
        bytes32 _partition,
        uint256 _value
    ) external view returns (bytes1, bytes32, bytes32);

    // Owner / Manager Information
    function isOwner(address _account) external view returns (bool);

    function isManager(address _manager) external view returns (bool);

    function owner() external view returns (address);

    // Shareholder Information
    function isWhitelisted(address _tokenHolder) external view returns (bool);

    // Operator Information
    function isOperator(address _operator) external view returns (bool);

    function isOperatorForPartition(
        bytes32 _partition,
        address _operator
    ) external view returns (bool);

    // Operator Management
    function authorizeOperator(address _operator) external;

    function revokeOperator(address _operator) external;

    function authorizeOperatorByPartition(
        bytes32 _partition,
        address _operator
    ) external;

    function revokeOperatorByPartition(
        bytes32 _partition,
        address _operator
    ) external;

    // Issuance / Redemption
    function issueByPartition(
        bytes32 _partition,
        address _tokenHolder,
        uint256 _value
    ) external;

    function redeemByPartition(bytes32 _partition, uint256 _value) external;

    function operatorRedeemByPartition(
        bytes32 _partition,
        address _tokenHolder,
        uint256 _value
    ) external;

    // Transfer Events
    event TransferByPartition(
        bytes32 indexed _fromPartition,
        address _operator,
        address indexed _from,
        address indexed _to,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    // Operator Events
    event AuthorizedOperator(address indexed operator);
    event RevokedOperator(address indexed operator);
    event AuthorizedOperatorByPartition(
        bytes32 indexed partition,
        address indexed operator
    );
    event RevokedOperatorByPartition(
        bytes32 indexed partition,
        address indexed operator
    );

    // Issuance / Redemption Events
    event IssuedByPartition(
        bytes32 indexed partition,
        address indexed to,
        uint256 value
    );
    event RedeemedByPartition(
        bytes32 indexed partition,
        address indexed operator,
        address indexed from,
        uint256 value
    );
}

/* SPDX-License-Identifier: MIT */

pragma solidity ^0.8.13;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/* SPDX-License-Identifier: MIT */

pragma solidity ^0.8.13;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}