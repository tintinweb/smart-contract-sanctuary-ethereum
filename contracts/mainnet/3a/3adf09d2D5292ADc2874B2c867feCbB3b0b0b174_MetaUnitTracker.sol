// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IMetaUnitTracker} from "./IMetaUnitTracker.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";


/**
 * @author MetaPlayerOne DAO
 * @title MetaUnitRegister
 * @notice Manages registration of all transactions on platform.
 */
contract MetaUnitTracker is IMetaUnitTracker, ReentrancyGuard {
    address private _owner_of;
    Transaction[] private _transactions;
    mapping(address => uint256) private _resales_sum_by_user_address;
    mapping(address => uint256) private _quantity_of_transaction_by_user_address;
    mapping(address => address[]) private _sale_contract_acceptance;
    mapping(address => mapping(address => bool)) private _accepted;
    mapping(address => bool) private _is_committee;

    /**
     * @dev setup owner and commitee of this contract.
     */
    constructor(address owner_of_, address[] memory committee_) {
        _owner_of = owner_of_;
        for (uint256 i = 0; i < committee_.length; i ++) {
            _is_committee[committee_[i]] = true;
        }
    }

    /**
     * @dev helps MetaUnit receive data about sales and resales.
     * @param eth_address_ address which sold NFT on platform.
     * @param value_ price which he received form this order.
     */
    function track(address eth_address_, uint256 value_) public nonReentrant {
        uint256 counter = 0;
        for (uint256 i = 0; i < _sale_contract_acceptance[msg.sender].length; i++) if (_accepted[msg.sender][_sale_contract_acceptance[msg.sender][i]]) counter ++;
        require(counter >= 3, "Sale contact is not approved");
        _transactions.push(Transaction(eth_address_, value_, block.timestamp));
        _resales_sum_by_user_address[eth_address_] += value_;
        _quantity_of_transaction_by_user_address[eth_address_] += 1;
    }

    /**
     * @dev setup sale contracts.
     */
    function setSaleContractsAddresses(address[] memory contract_addresses_, bool action_) public {
        require(_is_committee[msg.sender], "Permission denied");
        for (uint256 i = 0; i < contract_addresses_.length; i++) {
            if (action_ && !_accepted[contract_addresses_[i]][msg.sender]) {
                _accepted[contract_addresses_[i]][msg.sender] = action_;
                _sale_contract_acceptance[contract_addresses_[i]].push(msg.sender);
            } else if (!action_) _accepted[contract_addresses_[i]][msg.sender] = action_;
        }
    }

    /**
     * @dev helps us receive sum of resales 
     * @param eth_address_ address of user which resales should be retrieved.
     * @return resales_sum sum of resales for specified user address.
     */
    function getUserResalesSum(address eth_address_) public view returns (uint256) {
        return _resales_sum_by_user_address[eth_address_];
    }

    /**
     * @dev helps us receive quantity of transactions 
     * @param eth_address_ address of user which transactions should be retrieved.
     * @return quantity quantity of transactions for specified user address.
     */
    function getUserTransactionQuantity(address eth_address_) public view returns (uint256) {
        return _quantity_of_transaction_by_user_address[eth_address_];
    }

    /**
     * @dev helps us retrive all transactions.
     * @return transactions all transactions.
     */
    function getTransactions() public view returns (Transaction[] memory transactions) {
        return _transactions;
    }

    /**
     * @dev helps us retrive all transactions in defined periods.
     */
    function getTransactionsForPeriod(uint256 from_, uint256 to_) public view returns (address[] memory, uint256[] memory) {
        uint256 len = 0;
        for (uint256 i = 0; i < _transactions.length; i ++) {
            if (_transactions[i].timestamp > from_ && _transactions[i].timestamp < to_) {
                len += 1;
            }
        }
        require(len > 0, "No transactions in this period");
        address[] memory addresses = new address[](len);
        uint256[] memory values = new uint256[](len);
        uint256 counter = 0;
        for (uint256 i = 0; i < _transactions.length; i ++) {
            if (_transactions[i].timestamp > from_ && _transactions[i].timestamp < to_) {
                addresses[counter] = _transactions[i].owner_of;
                values[counter] = _transactions[i].value;
                counter +=1;
            }
        }
        return (addresses, values);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMetaUnitTracker {
    struct Transaction { address owner_of; uint256 value; uint256 timestamp; }

    function track(address eth_address_, uint256 value_) external;
    function getUserResalesSum(address eth_address_) external view returns(uint256);
    function getUserTransactionQuantity(address eth_address_) external view returns(uint256);
    function getTransactions() external view returns (Transaction[] memory);
    function getTransactionsForPeriod(uint256 from_, uint256 to_) external view returns (address[] memory, uint256[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}