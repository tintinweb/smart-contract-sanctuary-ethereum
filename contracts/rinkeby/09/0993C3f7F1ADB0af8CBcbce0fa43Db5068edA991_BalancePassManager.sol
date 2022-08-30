// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

interface BalancePassNft {
    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);

    function getTokenType(uint256 _tokenId) external view returns (string memory);
}

interface BalancePassHolderStrategy {

    /// @notice return balance pass holder class
    /// @param _user user
    /// @return balance pass holder class, 'Undefined', 'Platinum', 'Silver', 'Gold'
    function getTokenType(address _user) external view returns (string memory);
}

contract OnChainBalancePassHolderStrategy is BalancePassHolderStrategy {

    BalancePassNft public balancePassNft;

    constructor(address _balancePassNft) {
        require(_balancePassNft != address(0));
        balancePassNft = BalancePassNft(_balancePassNft);
    }

    /// @notice return balance pass holder class
    /// @param _user user
    /// @return balance pass holder class, 'Undefined', 'Platinum', 'Silver', 'Gold'
    function getTokenType(address _user) external view returns (string memory) {
        uint[] memory tokens = balancePassNft.tokensOfOwner(_user);
        if (tokens.length == 0) return "Undefined";

        bool goldFound = false;
        bool silverFound = false;
        bool platinumFound = false;
        for (uint i = 0; i < tokens.length; i++) {
            string memory result = balancePassNft.getTokenType(tokens[i]);
            if (hash(result) == hash("Gold")) {
                goldFound = true;
                // we can skip as we found the best
                break;
            }
            else if (hash(result) == hash("Silver")) silverFound = true;
            else if (hash(result) == hash("Platinum")) platinumFound = true;
            // else undefined none of them found
        }

        if (goldFound) return "Gold";
        else if (silverFound) return "Silver";
        else if (platinumFound) return "Platinum";
        return "Undefined";
    }

    function hash(string memory _string) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_string));
    }

}

contract OffChainBalancePassHolderStrategy is BalancePassHolderStrategy, Ownable {

    address[] public users;
    /// mapping for user to list of tokenIds
    mapping(address => uint[]) public tokenIdSnapshot;
    /// unmodifiable mapping between tokenId and type
    mapping(uint => string) public tokenTypeSnapshot;

    /// @notice return balance pass holder class
    /// @param _user user
    /// @return balance pass holder class, 'Undefined', 'Platinum', 'Silver', 'Gold'
    function getTokenType(address _user) external view returns (string memory) {
        uint[] memory tokens = tokenIdSnapshot[_user];
        if (tokens.length == 0) return "Undefined";

        bool goldFound = false;
        bool silverFound = false;
        bool platinumFound = false;
        for (uint i = 0; i < tokens.length; i++) {
            string memory result = tokenTypeSnapshot[tokens[i]];
            if (hash(result) == hash("Gold")) {
                goldFound = true;
                // we can skip as we found the best
                break;
            }
            else if (hash(result) == hash("Silver")) silverFound = true;
            else if (hash(result) == hash("Platinum")) platinumFound = true;
            // else undefined none of them found
        }

        if (goldFound) return "Gold";
        else if (silverFound) return "Silver";
        else if (platinumFound) return "Platinum";
        return "Undefined";
    }

    function hash(string memory _string) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_string));
    }

    ///
    /// management
    ///

    function clearMappings() external onlyOwner {
        for (uint i = users.length; i >= 0; i--) {
            address user = users[i];
            uint[] memory tokens = tokenIdSnapshot[user];
            for (uint j = 0; j < tokens.length; j++) {
                delete tokenTypeSnapshot[tokens[j]];
            }

            delete tokenIdSnapshot[user];
            users.pop();
        }
    }

    function addMapping(address _user, uint[] calldata _tokenIds, string[] calldata _tokenTypes) external onlyOwner {
        require(_tokenIds.length == _tokenTypes.length, "ARRAY_LENGTH_NOT_SAME");

        users.push(_user);
        tokenIdSnapshot[_user] = _tokenIds;
        for (uint i = 0; i < _tokenTypes.length; i++) {
            tokenTypeSnapshot[_tokenIds[i]] = _tokenTypes[i];
        }
    }

}

/// @notice Manages balance pass holders
contract BalancePassManager is Ownable {

    address private strategy;

    /// discount in percent with 2 decimals, 10000 is 100%
    uint public discountGold;
    /// discount in percent with 2 decimals, 10000 is 100%
    uint public discountSilver;
    /// discount in percent with 2 decimals, 10000 is 100%
    uint public discountPlatinum;

    ///
    /// business logic
    ///

    /// @notice get amount and fee part from fee
    /// @param _user given user
    /// @param _fee fee to split
    /// @return amount and fee part from given fee
    function getDiscountFromFee(address _user, uint _fee) external view returns (uint, uint) {
        if (strategy == address(0)) return (0, _fee);
        string memory tokenType = BalancePassHolderStrategy(strategy).getTokenType(_user);

        // Undefined
        uint amount = 0;
        if (hash(tokenType) == hash("Gold")) {
            amount = _fee * discountGold / 10000;
        } else if (hash(tokenType) == hash("Silver")) {
            amount = _fee * discountSilver / 10000;
        } else if (hash(tokenType) == hash("Platinum")) {
            amount = _fee * discountPlatinum / 10000;
        }

        uint realFee = _fee - amount;
        return (amount, realFee);
    }

    function hash(string memory _string) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_string));
    }

    ///
    /// management
    ///

    function setStrategy(address _strategy) external onlyOwner {
        strategy = _strategy;
    }

    function setDiscountGold(uint _discountGold) external onlyOwner {
        require(_discountGold < 10000, "DISCOUNT_TOO_BIG");
        discountGold = _discountGold;
    }

    function setDiscountSilver(uint _discountSilver) external onlyOwner {
        require(discountSilver < 10000, "DISCOUNT_TOO_BIG");
        discountSilver = _discountSilver;
    }

    function setDiscountPlatinum(uint _discountPlatinum) external onlyOwner {
        require(discountPlatinum < 10000, "DISCOUNT_TOO_BIG");
        discountPlatinum = _discountPlatinum;
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