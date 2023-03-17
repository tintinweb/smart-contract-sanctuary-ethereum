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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
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
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ISimpleToken {
    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 __decimals,
        uint256 _totalSupply
    ) external payable;
}

interface IStandardToken {
    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 __decimals,
        uint256 _totalSupply,
        uint256 _maxWallet,
        uint256 _maxTransactionAmount,
        address[3] memory _accounts,
        bool _isMarketingFeeBaseToken,
        uint16[4] memory _fees
    ) external payable;
}

interface IReflectionToken {
    function initialize(
        string memory __name,
        string memory __symbol,
        uint8 __decimals,
        uint256 _totalSupply,
        uint256 _maxWallet,
        uint256 _maxTransactionAmount,
        address[3] memory _accounts,
        bool _isMarketingFeeBaseToken,
        uint16[6] memory _fees
    ) external payable;
}

interface IDividendToken {
    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_,
        uint256 _maxWallet,
        uint256 _maxTransactionAmount,
        address[5] memory addrs, // reward, router, marketing wallet, lp wallet, dividendTracker, base Token
        uint16[6] memory feeSettings, // rewards, liquidity, marketing
        uint256 minimumTokenBalanceForDividends_,
        uint8 _tokenForMarketingFee
    ) external payable;
}

interface ISimpleTokenWithAntiBot {
    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 __decimals,
        uint256 _totalSupply,
        address _gemAntiBot
    ) external payable;
}

interface IStandardTokenWithAntiBot {
    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 __decimals,
        uint256 _totalSupply,
        uint256 _maxWallet,
        uint256 _maxTransactionAmount,
        address[3] memory _accounts,
        bool _isMarketingFeeBaseToken,
        uint16[4] memory _fees,
        address _gemAntiBot
    ) external payable;
}

interface IReflectionTokenWithAntiBot {
    function initialize(
        string memory __name,
        string memory __symbol,
        uint8 __decimals,
        uint256 _totalSupply,
        uint256 _maxWallet,
        uint256 _maxTransactionAmount,
        address[3] memory _accounts,
        bool _isMarketingFeeBaseToken,
        uint16[6] memory _fees,
        address _gemAntiBot
    ) external payable;
}

interface IDividendTokenWithAntiBot {
    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_,
        uint256 _maxWallet,
        uint256 _maxTransactionAmount,
        address[5] memory addrs, // reward, router, marketing wallet, lp wallet, dividendTracker, base Token
        uint16[6] memory feeSettings, // rewards, liquidity, marketing
        uint256 minimumTokenBalanceForDividends_,
        uint8 _tokenForMarketingFee,
        address _gemAntiBot
    ) external payable;
}

contract TokenFactory is Ownable {
    using Counters for Counters.Counter;

    enum TokenType {
        SIMPLE,
        STANDARD,
        REFELCTION,
        DIVIDEND,
        SIMPLE_ANTIBOT,
        STANDARD_ANTIBOT,
        REFELCTION_ANTIBOT,
        DIVIDEND_ANTIBOT
    }

    struct Token {
        address tokenAddress;
        TokenType tokenType;
    }

    Counters.Counter private tokenCounter;
    mapping(uint256 => Token) public tokens;

    address[8] implementations = [
        0xBe7b2C218c18938a70dc45B878032D316536a170,
        0xeD8e15540A7f27E059Ab01991AA226bBe624CaEE,
        0xA07d849172c9327cd1950a45284fc9b0B5a31402,
        0x78319EC8C8DFF892F40D102Ff679d8D89c08358D,
        0xca491C966A09eED5817FA5fF3422475f8dd349Ef,
        0x08234718C9778D9e79984AD90E4fF0b1b4134C97,
        0x9543E9183694BC78Dc1175a867EfDd6A7Dc29Bd6,
        0xc1C0803CA7988ED6945CDa55aC553e34324f6d67
    ];

    uint256[4] fees = [0.1 ether, 0.1 ether, 0.1 ether, 0.1 ether];

    constructor() {}

    function createSimpleToken(
        string memory _name,
        string memory _symbol,
        uint8 __decimals,
        uint256 _totalSupply
    ) external payable {
        require(msg.value >= fees[0], "createSimpleToken::Fee is not enough");
        address newToken = Clones.clone(implementations[0]);
        ISimpleToken(newToken).initialize{value: msg.value}(
            _name,
            _symbol,
            __decimals,
            _totalSupply
        );
        uint256 counter = tokenCounter.current();
        tokens[counter].tokenAddress = newToken;
        tokens[counter].tokenType = TokenType.SIMPLE;
        tokenCounter.increment();
    }

    function createStandardToken(
        string memory _name,
        string memory _symbol,
        uint8 __decimals,
        uint256 _totalSupply,
        uint256 _maxWallet,
        uint256 _maxTransactionAmount,
        address[3] memory _accounts,
        bool _isMarketingFeeBaseToken,
        uint16[4] memory _fees
    ) external payable {
        require(msg.value >= fees[1], "createStandardToken::Fee is not enough");
        address newToken = Clones.clone(implementations[1]);
        IStandardToken(newToken).initialize{value: msg.value}(
            _name,
            _symbol,
            __decimals,
            _totalSupply,
            _maxWallet,
            _maxTransactionAmount,
            _accounts,
            _isMarketingFeeBaseToken,
            _fees
        );
        uint256 counter = tokenCounter.current();
        tokens[counter].tokenAddress = newToken;
        tokens[counter].tokenType = TokenType.STANDARD;
        tokenCounter.increment();
    }

    function createReflectionToken(
        string memory __name,
        string memory __symbol,
        uint8 __decimals,
        uint256 _totalSupply,
        uint256 _maxWallet,
        uint256 _maxTransactionAmount,
        address[3] memory _accounts,
        bool _isMarketingFeeBaseToken,
        uint16[6] memory _fees
    ) external payable {
        require(
            msg.value >= fees[2],
            "createReflectionToken::Fee is not enough"
        );
        address newToken = Clones.clone(implementations[2]);
        IReflectionToken(newToken).initialize{value: msg.value}(
            __name,
            __symbol,
            __decimals,
            _totalSupply,
            _maxWallet,
            _maxTransactionAmount,
            _accounts,
            _isMarketingFeeBaseToken,
            _fees
        );
        uint256 counter = tokenCounter.current();
        tokens[counter].tokenAddress = newToken;
        tokens[counter].tokenType = TokenType.REFELCTION;
        tokenCounter.increment();
    }

    function createDividendToken(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_,
        uint256 _maxWallet,
        uint256 _maxTransactionAmount,
        address[5] memory addrs, // reward, router, marketing wallet, lp wallet, dividendTracker, base Token
        uint16[6] memory feeSettings, // rewards, liquidity, marketing
        uint256 minimumTokenBalanceForDividends_,
        uint8 _tokenForMarketingFee
    ) external payable {
        require(msg.value >= fees[3], "createDividendToken::Fee is not enough");
        address newToken = Clones.clone(implementations[3]);
        IDividendToken(newToken).initialize{value: msg.value}(
            name_,
            symbol_,
            decimals_,
            totalSupply_,
            _maxWallet,
            _maxTransactionAmount,
            addrs, // reward, router, marketing wallet, lp wallet, dividendTracker, base Token
            feeSettings, // rewards, liquidity, marketing
            minimumTokenBalanceForDividends_,
            _tokenForMarketingFee
        );
        uint256 counter = tokenCounter.current();
        tokens[counter].tokenAddress = newToken;
        tokens[counter].tokenType = TokenType.DIVIDEND;
        tokenCounter.increment();
    }

    function createSimpleTokenWithAntiBot(
        string memory _name,
        string memory _symbol,
        uint8 __decimals,
        uint256 _totalSupply,
        address _gemAntiBot
    ) external payable {
        require(msg.value >= fees[0], "createSimpleToken::Fee is not enough");
        address newToken = Clones.clone(implementations[4]);
        ISimpleTokenWithAntiBot(newToken).initialize{value: msg.value}(
            _name,
            _symbol,
            __decimals,
            _totalSupply,
            _gemAntiBot
        );
        uint256 counter = tokenCounter.current();
        tokens[counter].tokenAddress = newToken;
        tokens[counter].tokenType = TokenType.SIMPLE_ANTIBOT;
        tokenCounter.increment();
    }

    function createStandardTokenWithAntiBot(
        string memory _name,
        string memory _symbol,
        uint8 __decimals,
        uint256 _totalSupply,
        uint256 _maxWallet,
        uint256 _maxTransactionAmount,
        address[3] memory _accounts,
        bool _isMarketingFeeBaseToken,
        uint16[4] memory _fees,
        address _gemAntiBot
    ) external payable {
        require(msg.value >= fees[1], "createStandardToken::Fee is not enough");
        address newToken = Clones.clone(implementations[5]);
        IStandardTokenWithAntiBot(newToken).initialize{value: msg.value}(
            _name,
            _symbol,
            __decimals,
            _totalSupply,
            _maxWallet,
            _maxTransactionAmount,
            _accounts,
            _isMarketingFeeBaseToken,
            _fees,
            _gemAntiBot
        );
        uint256 counter = tokenCounter.current();
        tokens[counter].tokenAddress = newToken;
        tokens[counter].tokenType = TokenType.STANDARD_ANTIBOT;
        tokenCounter.increment();
    }

    function createReflectionTokenWithAntiBot(
        string memory __name,
        string memory __symbol,
        uint8 __decimals,
        uint256 _totalSupply,
        uint256 _maxWallet,
        uint256 _maxTransactionAmount,
        address[3] memory _accounts,
        bool _isMarketingFeeBaseToken,
        uint16[6] memory _fees,
        address _gemAntiBot
    ) external payable {
        require(
            msg.value >= fees[2],
            "createReflectionToken::Fee is not enough"
        );
        address newToken = Clones.clone(implementations[6]);
        IReflectionTokenWithAntiBot(newToken).initialize{value: msg.value}(
            __name,
            __symbol,
            __decimals,
            _totalSupply,
            _maxWallet,
            _maxTransactionAmount,
            _accounts,
            _isMarketingFeeBaseToken,
            _fees,
            _gemAntiBot
        );
        uint256 counter = tokenCounter.current();
        tokens[counter].tokenAddress = newToken;
        tokens[counter].tokenType = TokenType.REFELCTION_ANTIBOT;
        tokenCounter.increment();
    }

    function createDividendTokenWithAntiBot(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_,
        uint256 _maxWallet,
        uint256 _maxTransactionAmount,
        address[5] memory addrs, // reward, router, marketing wallet, lp wallet, dividendTracker, base Token
        uint16[6] memory feeSettings, // rewards, liquidity, marketing
        uint256 minimumTokenBalanceForDividends_,
        uint8 _tokenForMarketingFee,
        address _gemAntiBot
    ) external payable {
        require(msg.value >= fees[3], "createDividendToken::Fee is not enough");
        address newToken = Clones.clone(implementations[7]);
        IDividendTokenWithAntiBot(newToken).initialize{value: msg.value}(
            name_,
            symbol_,
            decimals_,
            totalSupply_,
            _maxWallet,
            _maxTransactionAmount,
            addrs, // reward, router, marketing wallet, lp wallet, dividendTracker, base Token
            feeSettings, // rewards, liquidity, marketing
            minimumTokenBalanceForDividends_,
            _tokenForMarketingFee,
            _gemAntiBot
        );
        uint256 counter = tokenCounter.current();
        tokens[counter].tokenAddress = newToken;
        tokens[counter].tokenType = TokenType.DIVIDEND_ANTIBOT;
        tokenCounter.increment();
    }

    function getAllTokens() external view returns (Token[] memory) {
        Token[] memory _tokens = new Token[](tokenCounter.current());
        for (uint256 i = 0; i < tokenCounter.current(); i++) {
            _tokens[i].tokenAddress = tokens[i].tokenAddress;
            _tokens[i].tokenType = tokens[i].tokenType;
        }
        return _tokens;
    }

    receive() external payable {}
}