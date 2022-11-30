// Sources flattened with hardhat v2.6.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]

// s

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File @openzeppelin/contracts/math/[email protected]

// s

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


// File contracts/interfaces/IERC721Collection.sol

// s

pragma solidity ^0.6.12;


interface IERC721Collection {
    function issueToken(address _beneficiary, string calldata _wearableId) external;
    function getWearableKey(string calldata _wearableId) external view returns (bytes32);
    function issued(bytes32 _wearableKey) external view returns (uint256);
    function maxIssuance(bytes32 _wearableKey) external view returns (uint256);
    function issueTokens(address[] calldata _beneficiaries, bytes32[] calldata _wearableIds) external;
    function owner() external view returns (address);
    function wearables(uint256 _index) external view returns (string memory);
    function wearablesCount() external view returns (uint256);
}


// File contracts/interfaces/Factory.sol

// s

pragma solidity ^0.6.12;

/**
 * This is a generic factory contract that can be used to mint tokens. The configuration
 * for minting is specified by an _optionId, which can be used to delineate various
 * ways of minting.
 */
interface Factory {
  /**
   * Returns the name of this factory.
   */
  function name() external view returns (string memory);

  /**
   * Returns the symbol for this factory.
   */
  function symbol() external view returns (string memory);

  /**
   * Number of options the factory supports.
   */
  function numOptions() external view returns (uint256);

  /**
   * @dev Returns whether the option ID can be minted. Can return false if the developer wishes to
   * restrict a total supply per option ID (or overall).
   */
  function canMint(uint256 _optionId) external view returns (bool);

  /**
   * @dev Returns a URL specifying some metadata about the option. This metadata can be of the
   * same structure as the ERC721 metadata.
   */
  function tokenURI(uint256 _optionId) external view returns (string memory);

  /**
   * Indicates that this is a factory contract. Ideally would use EIP 165 supportsInterface()
   */
  function supportsFactoryInterface() external view returns (bool);

  /**
    * @dev Mints asset(s) in accordance to a specific address with a particular "option". This should be
    * callable only by the contract owner or the owner's Wyvern Proxy (later universal login will solve this).
    * Options should also be delineated 0 - (numOptions() - 1) for convenient indexing.
    * @param _optionId the option id
    * @param _toAddress address of the future owner of the asset(s)
    */
  function mint(uint256 _optionId, address _toAddress) external;
}


// File contracts/factories/v1/ERC721CollectionFactory.sol

// s

pragma solidity ^0.6.12;


contract ERC721CollectionFactory is Ownable, Factory {
    using SafeMath for uint256;

    string public override name;
    string public override symbol;
    string public baseURI;
    IERC721Collection public erc721Collection;

    event BaseURI(string _oldBaseURI, string _newBaseURI);
    event Allowed(address indexed _oldAllowed, address indexed _newAllowed);

    /**
     * @dev Constructor of the contract.
     * @notice that 0xa5409ec958c83c3f309868babaca7c86dcb077c1 is the contract address for _proxyRegistryAddress at mainnet.
     * @param _name - name of the contract
     * @param _symbol - symbol of the contract
     * @param _baseURI - base URI for token URIs
     * @param _erc721Collection - Address of the collection
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        IERC721Collection _erc721Collection
      )
      public {
        name = _name;
        symbol = _symbol;
        erc721Collection = _erc721Collection;
        setBaseURI(_baseURI);

    }

    // modifier onlyAllowed() {
    //     require(address(proxyRegistry.proxies(owner())) == msg.sender, "Only `allowed` proxy can issue tokens");
    //     _;
    // }

     /**
     * @dev Mints asset(s) in accordance to a specific address with a particular "option". This should be
     * callable only by the contract owner or the owner's Wyvern Proxy (later universal login will solve this).
     * Options should also be delineated 0 - (numOptions() - 1) for convenient indexing.
     * @param _optionId the option id
     * @param _toAddress address of the future owner of the asset(s)
     */
    function mint(uint256 _optionId, address _toAddress) public override  {
        require(canMint(_optionId), "Exhausted wearable");

        string memory wearable = _wearableByOptionId(_optionId);
        erc721Collection.issueToken(_toAddress, wearable);
    }

    /**
    * @dev Set Base URI.
    * @param _baseURI - base URI for token URIs
    */
    function setBaseURI(string memory _baseURI) public onlyOwner {
        emit BaseURI(baseURI, _baseURI);
        baseURI = _baseURI;
    }

    /**
    * @dev Returns whether the option ID can be minted. Can return false if the developer wishes to
    * restrict a total supply per option ID (or overall).
    * @param _optionId the option id
    * @return whether an option can be minted
    */
    function canMint(uint256 _optionId) public view override returns (bool) {
        return balanceOf(_optionId) > 0;
    }

    /**
     * @dev Check if support factory interface.
     * @return always true
     */
    function supportsFactoryInterface() public view override returns (bool) {
        return true;
    }

    /**
     * @dev Return the number of options the factory supports.
     * @return supported options count
     */
    function numOptions() public view override returns (uint256) {
        return erc721Collection.wearablesCount();
    }

    /**
     * @dev Returns an URI for a given option ID.
     * Throws if the option ID does not exist. May return an empty string.
     * @param _optionId - uint256 ID of the token queried
     * @return token URI
     */
    function balanceOf(uint256 _optionId) public view returns (uint256) {
        string memory wearable = _wearableByOptionId(_optionId);
        bytes32 wearableKey = erc721Collection.getWearableKey(wearable);

        uint256 issued = erc721Collection.issued(wearableKey);
        uint256 maxIssuance = erc721Collection.maxIssuance(wearableKey);
        return maxIssuance.sub(issued);
    }

     /**
     * @dev Returns an URI for a given option ID.
     * Throws if the option ID does not exist. May return an empty string.
     * @param _optionId - uint256 ID of the token queried
     * @return token URI
     */
    function tokenURI(uint256 _optionId) public view override returns (string memory) {
        string memory wearable = _wearableByOptionId(_optionId);
        return string(abi.encodePacked(baseURI, wearable));
    }

    /**
     * @dev Get the proxy address used at OpenSea.
     * @notice that this address should be used at setAllowed method
     * to allow OpenSea to mint tokens.
     * OpenSea uses the Wyvern Protocol https://docs.opensea.io/docs/opensea-partners-program
     * @param _operator - Address allowed to issue tokens
     */
     // Should be used to return the address to be set as setAllowed
    // function proxies(address _operator) public view returns (address) {
    //     return address(proxyRegistry.proxies(_operator));
    // }

    /**
    * Hack to get things to work automatically on OpenSea.
    * Use transferFrom so the frontend doesn't have to worry about different method names.
    */
    function transferFrom(address /*_from*/, address _to, uint256 _tokenId) public {
        mint(_tokenId, _to);
    }


    /**
    * Hack to get things to work automatically on OpenSea.
    * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
    */
    function isApprovedForAll(
        address _owner,
        address _operator
    )
      public
      view
      returns (bool)
    {
        if (owner() == _owner && _owner == _operator) {
            return true;
        }

        return false;
    }

    /**
    * Hack to get things to work automatically on OpenSea.
    * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
    */
    function ownerOf(uint256 /*_tokenId*/) public view returns (address _owner) {
        return owner();
    }

    function _wearableByOptionId(uint256 _optionId) internal view returns (string memory){
       /* solium-disable-next-line */
        (bool success, bytes memory data) = address(erc721Collection).staticcall(
            abi.encodeWithSelector(
                erc721Collection.wearables.selector,
                _optionId
            )
        );

        require(success, "Invalid wearable");
        return abi.decode(data, (string));
    }
}