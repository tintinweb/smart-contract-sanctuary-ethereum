// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/interfaces/IFeeRuleRegistry.sol";
import "contracts/interfaces/IRule.sol";

contract FeeRuleRegistry is IFeeRuleRegistry, Ownable {
    mapping(uint256 => address) public override rules;

    uint256 public override counter;
    uint256 public override basisFeeRate;
    address public override feeCollector;
    uint256 public constant override BASE = 1e18;

    event RegisteredRule(uint256 index, address rule);
    event UnregisteredRule(uint256 index);
    event SetBasisFeeRate(uint256 basisFeeRate);
    event SetFeeCollector(address feeCollector);

    constructor(uint256 basisFeeRate_, address feeCollector_) {
        if (basisFeeRate_ != 0) setBasisFeeRate(basisFeeRate_);
        setFeeCollector(feeCollector_);
    }

    function setBasisFeeRate(uint256 basisFeeRate_) public override onlyOwner {
        require(basisFeeRate_ <= BASE, "Out of range");
        require(basisFeeRate_ != basisFeeRate, "Same as current one");
        basisFeeRate = basisFeeRate_;
        emit SetBasisFeeRate(basisFeeRate);
    }

    function setFeeCollector(address feeCollector_) public override onlyOwner {
        require(feeCollector_ != address(0), "Zero address");
        require(feeCollector_ != feeCollector, "Same as current one");
        feeCollector = feeCollector_;
        emit SetFeeCollector(feeCollector);
    }

    function registerRule(address rule_) external override onlyOwner {
        require(rule_ != address(0), "Not allow to register zero address");
        rules[counter] = rule_;
        emit RegisteredRule(counter, rule_);
        counter = counter + 1;
    }

    function unregisterRule(uint256 ruleIndex_) external override onlyOwner {
        require(
            rules[ruleIndex_] != address(0),
            "Rule not set or unregistered"
        );
        rules[ruleIndex_] = address(0);
        emit UnregisteredRule(ruleIndex_);
    }

    function calFeeRateMulti(address usr_, uint256[] calldata ruleIndexes_)
        external
        view
        override
        returns (uint256 scaledRate)
    {
        scaledRate =
            (calFeeRateMultiWithoutBasis(usr_, ruleIndexes_) * basisFeeRate) /
            BASE;
    }

    function calFeeRateMultiWithoutBasis(
        address usr_,
        uint256[] calldata ruleIndexes_
    ) public view override returns (uint256 scaledRate) {
        uint256 len = ruleIndexes_.length;
        if (len == 0) {
            scaledRate = BASE;
        } else {
            scaledRate = _calDiscount(usr_, rules[ruleIndexes_[0]]);
            for (uint256 i = 1; i < len; i++) {
                require(
                    ruleIndexes_[i] > ruleIndexes_[i - 1],
                    "Not ascending order"
                );

                scaledRate =
                    (scaledRate * _calDiscount(usr_, rules[ruleIndexes_[i]])) /
                    BASE;
            }
        }
    }

    function calFeeRate(address usr_, uint256 ruleIndex_)
        external
        view
        override
        returns (uint256 scaledRate)
    {
        scaledRate =
            (calFeeRateWithoutBasis(usr_, ruleIndex_) * basisFeeRate) /
            BASE;
    }

    function calFeeRateWithoutBasis(address usr_, uint256 ruleIndex_)
        public
        view
        override
        returns (uint256 scaledRate)
    {
        scaledRate = _calDiscount(usr_, rules[ruleIndex_]);
    }

    /* Internal Functions */
    function _calDiscount(address usr_, address rule_)
        internal
        view
        returns (uint256 discount)
    {
        if (rule_ != address(0)) {
            discount = IRule(rule_).calDiscount(usr_);
            require(discount <= BASE, "Discount out of range");
        } else {
            discount = BASE;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
pragma solidity ^0.8.0;

interface IFeeRuleRegistry {
    /* State Variables Getter */
    function rules(uint256) external view returns (address);
    function counter() external view returns (uint256);
    function basisFeeRate() external view returns (uint256);
    function feeCollector() external view returns (address);
    function BASE() external view returns (uint256);

    /* Restricted Functions */
    function setBasisFeeRate(uint256) external;
    function setFeeCollector(address) external;
    function registerRule(address rule) external;
    function unregisterRule(uint256 ruleIndex) external;

    /* View Functions */
    function calFeeRateMulti(address usr, uint256[] calldata ruleIndexes) external view returns (uint256 scaledRate);
    function calFeeRate(address usr, uint256 ruleIndex) external view returns (uint256 scaledRate);
    function calFeeRateMultiWithoutBasis(address usr, uint256[] calldata ruleIndexes) external view returns (uint256 scaledRate);
    function calFeeRateWithoutBasis(address usr, uint256 ruleIndex) external view returns (uint256 scaledRate);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRule {
    /* State Variables Getter */
    function DISCOUNT() external view returns (uint256);
    function BASE() external view returns (uint256);

    /* View Functions */
    function verify(address) external view returns (bool);
    function calDiscount(address) external view returns (uint256);
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