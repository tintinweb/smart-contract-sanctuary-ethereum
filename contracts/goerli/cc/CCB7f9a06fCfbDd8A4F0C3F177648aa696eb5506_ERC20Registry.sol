//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title ERC20Registry
/// @author Paul Czajka [[email protected]]
/// @notice Tokenscope ERC20 token registry
contract ERC20Registry is Ownable {
    // This contract stores up to 256 unique facts for each token.
    // A fact has two parts:
    //   id: a uint8 value, 0 - 255
    //   code: a string description of the fact
    //
    // Fact codes are not stored on-chain: they are emitted as events
    // upon creation. Fact ids are assigned in sequential order, and
    // this contract is only aware of the current highwater fact id,
    // which defines the list of valid fact ids as 0 through highwater inclusive.
    //
    // Each fact code needs to be formulated such that a fact value of '1'
    // means the fact has been validated by governance.  A fact value
    // of '0' means the fact has not been validated, so it can be either not true
    // or not yet validated. Client contract authors special take note of this.
    //
    // Each uint8 fact id correlates to the bit-position of a uint256,
    // so the entire 256 fact-space for a single token can be condensed
    // into a single uint256. This flattened representation of the entire
    // fact space is termed a 'factSet'.
    //
    // Client contracts can query a set of facts for a token in one of two ways:
    // - areFactsValidated() accepts an array of uint8 fact ids
    // - isFactSetValidated() accepts a flattened uint256 factSet
    // These methods return true IFF all represented facts have been validated.
    //
    // Note that isFactSetValidated() will not produce correct results if supplied
    // with a uint256-casted fact id.  Use factsToFactSet() to convert individual
    // fact ids to a correct factSet representation.

    // Standard facts
    uint8 public constant IS_REGISTERED = 0; // Token exists in this contract. Set to 1 when added to registry
    uint8 public constant IS_VALID_ERC20 = 1; // Token conforms to ERC20 standard. Set by governance

    /// High-water mark for the highest fact id (factSet bit-position)
    uint8 public highwaterFact = 1;

    /// Maps a token address to its set of validated facts
    mapping(address => uint256) public tokenFacts;

    /// Emitted when a new fact is created.
    /// @param fact The unique fact identifer: also the identifier of the fact in token factSets.
    /// @param code The short descriptive code for this fact.
    event ERC20FactCreated(uint8 fact, string code);

    /// Emitted when a token's set of validated facts is added/updated
    /// @param token The token
    /// @param validatedFacts The new validated fact set of the token
    event ERC20ValidatedFacts(address indexed token, uint256 validatedFacts);

    /// @param _governor The owning Governance contract
    constructor(address _governor) {
        // Governance contract is owner
        transferOwnership(_governor);

        // factCreated events are the effective "catalog" of facts available.
        // Emit the first to common facts so they show up in the catalog like all the rest.
        emit ERC20FactCreated(IS_REGISTERED, "IS_REGISTERED");
        emit ERC20FactCreated(IS_VALID_ERC20, "IS_VALID_ERC20");
    }

    /// The token must be registered
    /// @param _token The token
    modifier isRegistered(address _token) {
        require(
            tokenFacts[_token] & IS_REGISTERED == IS_REGISTERED,
            "TOKEN_NOT_REGISTERED"
        );
        _;
    }

    /// The fact set must only represent facts that have been defined (bit position <= high water mark)
    /// @param _factSet The fact set
    modifier validFactSet(uint256 _factSet) {
        if (highwaterFact < 255) {
            // The highest valid factSet value would have all bits set to 1 for all created facts.
            // "1 << (highwaterFact + 1)" creates a factSet that exceeds this number by 1:
            // subtracting one yields the value where all bits are set to 1 for all created facts.
            require(
                _factSet <= (1 << (highwaterFact + 1)) - 1,
                "INVALID_FACT_SET"
            );
        }
        _;
    }

    function _isValidated(address _token, uint256 _factSet)
        private
        view
        returns (bool)
    {
        // An individual fact is validated if its bit-position is set to 1.
        // We can validate multiple facts at once.
        return tokenFacts[_token] & _factSet == _factSet;
    }

    /*/////////////////////////////////////////////////////////////////////////////////
        Registry Administration
    /////////////////////////////////////////////////////////////////////////////////*/

    /// Create a new fact available for all tokens.
    /// Existing tokens will have a `false` value for this fact, which can be updated by governance actions
    /// @param factCode The code for the fact being created
    /// @dev The fact identifer will be the next available bit-position, according to present `highwaterFact`
    function createFact(string calldata factCode) external onlyOwner {
        require(highwaterFact < 255, "MAX_FACTS_REACHED");

        emit ERC20FactCreated(++highwaterFact, factCode);
    }

    /// Add or update an ERC20 token with its set of validated facts.
    /// @param _token The token
    /// @param _factSet The set of all validated facts for the token
    /// @dev If the token already exists, its present factSet will be entirely overwritten by this new value.
    function addUpdateERC20(address _token, uint256 _factSet)
        external
        onlyOwner
        validFactSet(_factSet)
    {
        // The IS_REGISTERED attr is always true in storage
        //  (1 << IS_REGISTERED) = 1
        tokenFacts[_token] = _factSet | 1;

        emit ERC20ValidatedFacts(_token, _factSet | 1);
    }

    /*/////////////////////////////////////////////////////////////////////////////////
        Registry Querying
    /////////////////////////////////////////////////////////////////////////////////*/

    /// Convenience method to determine if a particular token exists in this registry
    /// @param _token The token
    /// @return bool
    function tokenIsRegistered(address _token) external view returns (bool) {
        // Second argument: 1 << IS_REGISTERED = 1
        return _isValidated(_token, 1);
    }

    /// Convenience method to determine if a particular token is a valid ERC20 implementation
    /// @param _token The token
    /// @return bool
    function tokenIsValidERC20(address _token)
        external
        view
        isRegistered(_token)
        returns (bool)
    {
        // Second argument: 1 << IS_VALID_ERC20 = 2
        return _isValidated(_token, 2);
    }

    /// Return whether specific facts have all been validated for a token.
    /// @param _token The token
    /// @param _facts The array of uint8 fact ids to be validated
    /// @return bool
    function factsAreValidated(address _token, uint8[] calldata _facts)
        external
        view
        isRegistered(_token)
        returns (bool)
    {
        return factSetIsValidated(_token, factsToFactSet(_facts));
    }

    /// Return whether a token conforms to a set of facts.
    /// This method returns true if the token conforms to all flagged facts:
    /// any facts above and beyond the flagged ones are not accounted for and wil have no impact on the result.
    /// @param _token The token
    /// @param _factSet The flattened uint256 fact set to be validated
    function factSetIsValidated(address _token, uint256 _factSet)
        public
        view
        isRegistered(_token)
        validFactSet(_factSet)
        returns (bool)
    {
        return _isValidated(_token, _factSet);
    }

    /*/////////////////////////////////////////////////////////////////////////////////
        Utility Conversion Methods
    /////////////////////////////////////////////////////////////////////////////////*/

    /// Convert an array of fact values into a single factSet value
    /// @dev Does not validate that any particular fact values exist
    /// @param _facts The array of fact values to convert into a fact set
    /// @return factSet
    function factsToFactSet(uint8[] calldata _facts)
        public
        pure
        returns (uint256 factSet)
    {
        uint256 len = _facts.length;
        for (uint256 i = 0; i < len; ++i) {
            factSet = factSet | (1 << _facts[i]);
        }
    }

    /// Convert an factSet value into an array of fact values
    /// @dev Does not validate that any particular fact values exist
    /// @param _factSet The fact set to convert into an array of fact values
    /// @return uint8[]
    function factSetToFacts(uint256 _factSet)
        external
        pure
        returns (uint8[] memory)
    {
        // We can't create a dynamic memory array, so we need to loop twice:
        // 1) Discover the number of facts. Then we size the facts array appropriately
        // 2) Populate the facts array
        uint8 n;
        uint256 factSetCopy = _factSet;

        // Determine the number of facts
        for (uint8 i = 0; i < 255; ++i) {
            if (factSetCopy & 1 == 1) {
                ++n;
            }
            factSetCopy = factSetCopy >> 1;
        }

        // Size the return array appropriately
        uint8[] memory facts = new uint8[](n);
        n = 0;
        factSetCopy = _factSet;

        // Populate the facts
        for (uint8 i = 0; i < 255; ++i) {
            if (factSetCopy & 1 == 1) {
                facts[n++] = i;
            }
            factSetCopy = factSetCopy >> 1;
        }

        return facts;
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