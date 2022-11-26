/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

// Sources flattened with hardhat v2.12.0 https://hardhat.org

// File contracts/dependencies/openzeppelin/contracts/Context.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File contracts/dependencies/openzeppelin/contracts/Ownable.sol


pragma solidity 0.8.10;

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File contracts/dependencies/openzeppelin/contracts/EnumerableSet.sol


pragma solidity 0.8.10;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }
}


// File contracts/dependencies/openzeppelin/contracts/IERC20.sol

pragma solidity 0.8.10;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


// File contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol

pragma solidity 0.8.10;

interface IERC20Detailed is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}


// File contracts/dependencies/openzeppelin/contracts/IMintableERC20.sol

pragma solidity 0.8.10;

interface IMintableERC20 is IERC20Detailed {
    /**
     * @dev Function to mint tokens
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(uint256 value) external returns (bool);

    /**
     * @dev Function to mint tokens to address
     * @param account The account to mint tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address account, uint256 value) external returns (bool);
}


// File contracts/mocks/tokens/MockTokenFaucet.sol

pragma solidity 0.8.10;



interface ICryptoPunksMarket {
    // Transfer ownership of a punk to another user without requiring payment
    function transferPunk(address to, uint256 punkIndex) external;

    function getPunk(uint256 punkIndex) external;

    function punksRemainingToAssign() external returns (uint256);

    function punkIndexToAddress(uint256) external returns (address);

    function balanceOf(address user) external returns (uint256);
}

interface IMintERC721 {
    function mint(uint256 _count, address _to) external;
}

contract MockTokenFaucet is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Token {
        string name;
        address addr;
        uint256 mintValue; // based on token decimals
    }

    ICryptoPunksMarket public cryptoPunks;

    mapping(address => Token) public tokenInfo;

    EnumerableSet.AddressSet private _mockERC20Tokens;
    EnumerableSet.AddressSet private _mockERC721Tokens;

    constructor(
        Token[] memory erc20Tokens,
        Token[] memory erc721Tokens,
        Token memory punks
    ) {
        for (uint256 index = 0; index < erc20Tokens.length; index++) {
            Token memory t = erc20Tokens[index];
            _mockERC20Tokens.add(t.addr);
            tokenInfo[t.addr] = t;
        }

        for (uint256 index = 0; index < erc721Tokens.length; index++) {
            Token memory t = erc721Tokens[index];
            _mockERC721Tokens.add(t.addr);
            tokenInfo[t.addr] = t;
        }
        cryptoPunks = ICryptoPunksMarket(punks.addr);
        tokenInfo[punks.addr] = punks;
    }

    function allMockERC20Tokens() public view returns (Token[] memory) {
        uint256 len = _mockERC20Tokens.length();
        Token[] memory tokens = new Token[](len);
        for (uint256 index = 0; index < len; index++) {
            tokens[index] = tokenInfo[_mockERC20Tokens.at(index)];
        }
        return tokens;
    }

    function allMockERC721Tokens() public view returns (Token[] memory) {
        uint256 len = _mockERC721Tokens.length();
        Token[] memory tokens = new Token[](len + 1);
        for (uint256 index = 0; index < len; index++) {
            tokens[index] = tokenInfo[_mockERC721Tokens.at(index)];
        }
        tokens[len] = tokenInfo[address(cryptoPunks)];
        return tokens;
    }

    function addERC20(Token[] calldata _tokens) public onlyOwner {
        for (uint256 index = 0; index < _tokens.length; index++) {
            Token memory t = _tokens[index];
            tokenInfo[t.addr] = t;
            _mockERC20Tokens.add(t.addr);
        }
    }

    function removeERC20(address[] memory _tokens) public onlyOwner {
        for (uint256 index = 0; index < _tokens.length; index++) {
            address addr = _tokens[index];
            _mockERC20Tokens.remove(addr);
            delete tokenInfo[addr];
        }
    }

    function addERC721(Token[] calldata _tokens) public onlyOwner {
        for (uint256 index = 0; index < _tokens.length; index++) {
            Token memory t = _tokens[index];
            tokenInfo[t.addr] = t;
            _mockERC721Tokens.add(t.addr);
        }
    }

    function updatePunk(Token calldata punk) public onlyOwner {
        tokenInfo[punk.addr] = punk;
        cryptoPunks = ICryptoPunksMarket(punk.addr);
    }

    function removeERC721(address[] memory _tokens) public onlyOwner {
        for (uint256 index = 0; index < _tokens.length; index++) {
            address addr = _tokens[index];
            _mockERC721Tokens.remove(addr);
            delete tokenInfo[addr];
        }
    }

    function mintERC20(
        address token,
        address to,
        uint256 mintValue
    ) public {
        IMintableERC20 mintToken = IMintableERC20(token);
        uint256 decimals = mintToken.decimals();
        mintToken.mint(to, mintValue * 10**decimals);
    }

    function mintERC721(
        address token,
        address to,
        uint256 mintValue
    ) public {
        IMintERC721 mintToken = IMintERC721(token);
        try mintToken.mint(mintValue, to) {} catch {}
    }

    function mintERC20s(address to) internal {
        for (uint256 index = 0; index < _mockERC20Tokens.length(); index++) {
            Token memory token = tokenInfo[_mockERC20Tokens.at(index)];
            mintERC20(token.addr, to, token.mintValue);
        }
    }

    function mintERC721s(address to) internal {
        for (uint256 index = 0; index < _mockERC721Tokens.length(); index++) {
            Token memory token = tokenInfo[_mockERC721Tokens.at(index)];
            mintERC721(token.addr, to, token.mintValue);
        }
    }

    function mintPunks(address to) internal {
        if (address(cryptoPunks) == address(0)) return;

        Token memory punksToken = tokenInfo[address(cryptoPunks)];

        if (punksToken.mintValue == 0) return;

        for (uint256 count = 0; count < punksToken.mintValue; count++) {
            uint256 punksRemainingToAssign = cryptoPunks
                .punksRemainingToAssign();
            if (punksRemainingToAssign == 0) break;
            uint256 nextPunkIndex = punksRemainingToAssign - 1;

            for (uint256 index = 0; index < 10000; index++) {
                if (
                    cryptoPunks.punkIndexToAddress(nextPunkIndex) == address(0)
                ) {
                    cryptoPunks.getPunk(nextPunkIndex);
                    cryptoPunks.transferPunk(to, nextPunkIndex);
                    break;
                }

                if (nextPunkIndex > 0) {
                    nextPunkIndex--;
                } else {
                    break;
                }
            }
        }
    }

    function mint(address to) public {
        mintERC20s(to);
        mintERC721s(to);
        mintPunks(to);
    }
}