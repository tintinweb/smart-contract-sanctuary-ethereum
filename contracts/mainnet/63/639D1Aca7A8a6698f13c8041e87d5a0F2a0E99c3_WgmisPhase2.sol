//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IWgmisMerkleTreeWhitelist {
    function isValidMerkleProof(bytes32[] calldata _merkleProof, address _minter, uint96 _amount) external view returns (bool);
}

interface IWgmis {
  function transferFrom(address _from, address _to, uint256 _tokenId) external;
}

contract WgmisPhase2 is Ownable {
    using Strings for uint256;

    // Controlled variables
    uint16 public prevTokenId;
    uint256 public price;
    bool public isRandomnessRequested;
    bytes32 public randomNumberRequestId;
    uint256 public vrfResult;
    uint256 public foundationMinted = 0;
    uint256 public merkleWhitelistVersion = 0;
    mapping(address => mapping(uint256 => bool)) public merkleWhitelistToWhitelistVersionToClaimed;
    mapping(address => uint256) public merkleWhitelistEarlyAccessMintCount;

    // Config variables
    uint256 public supplyLimit;
    uint256 public mintingStartTimeUnix;
    uint256 public singleOrderLimit;
    address[] public payoutAddresses;
    uint16[] public payoutAddressBasisPoints;
    address public tokenPoolHolder;
    IWgmis public wgmis;
    uint16 public earlyAccessAllowance;
    // A merkle-proof-based whitelist for initial batch of whitelisted addresses
    // All whitelisted addresses must be defined at time of WgmisMerkleTreeWhitelist deployment
    IWgmisMerkleTreeWhitelist merkleProofWhitelist;

    constructor(
        uint256 _supplyLimit,
        uint256 _mintingStartTimeUnix,
        uint256 _singleOrderLimit,
        address[] memory _payoutAddresses,
        uint16[] memory _payoutAddressBasisPoints,
        address _merkleProofWhitelist,
        address _tokenPoolHolder,
        uint16 _startTokenId,
        address _wgmis
    ) {
        supplyLimit = _supplyLimit;
        mintingStartTimeUnix = _mintingStartTimeUnix;
        singleOrderLimit = _singleOrderLimit;
        uint256 totalBasisPoints;
        for(uint256 i = 0; i < _payoutAddresses.length; i++) {
            require((_payoutAddressBasisPoints[i] > 0) && (_payoutAddressBasisPoints[i] <= 10000)); // "BP_NOT_BETWEEN_0_AND_10000"
            totalBasisPoints += _payoutAddressBasisPoints[i];
        }
        require(totalBasisPoints == 10000); // "BP_MUST_ADD_TO_10000"
        payoutAddresses = _payoutAddresses;
        payoutAddressBasisPoints = _payoutAddressBasisPoints;
        merkleProofWhitelist = IWgmisMerkleTreeWhitelist(_merkleProofWhitelist);
        foundationMinted = 0;
        price = 0.01 ether;
        merkleWhitelistVersion = 0;
        tokenPoolHolder = _tokenPoolHolder;
        prevTokenId = _startTokenId;
        wgmis = IWgmis(_wgmis);
        earlyAccessAllowance = 10;
    }

    function mint(address _recipient, uint16 _quantity) external payable {
        require(isRandomnessRequested == false, "MINTING_OVER");
        require(_quantity > 0, "NO_ZERO_QUANTITY");
        require(block.timestamp >= mintingStartTimeUnix, "MINTING_PERIOD_NOT_STARTED");
        require(_quantity <= singleOrderLimit, "EXCEEDS_SINGLE_ORDER_LIMIT");
        require((prevTokenId + _quantity) <= supplyLimit, "EXCEEDS_MAX_SUPPLY");
        require((msg.value) == (price * _quantity), "INCORRECT_ETH_VALUE");

        handleSale(_recipient, _quantity);
    }

    function mintMerkleWhitelist(bytes32[] calldata _merkleProof, uint16 _quantity) external {
        require(isRandomnessRequested == false, "MINTING_OVER");
        require(block.timestamp >= (mintingStartTimeUnix - 1 hours), "EARLY_ACCESS_NOT_STARTED");
        require((prevTokenId + _quantity) <= supplyLimit, "EXCEEDS_MAX_SUPPLY");
        require(!merkleWhitelistToWhitelistVersionToClaimed[msg.sender][merkleWhitelistVersion], 'MERKLE_CLAIM_ALREADY_MADE');
        require(merkleProofWhitelist.isValidMerkleProof(_merkleProof, msg.sender, _quantity), 'INVALID_MERKLE_PROOF');

        merkleWhitelistToWhitelistVersionToClaimed[msg.sender][merkleWhitelistVersion] = true;

        handleSale(msg.sender, _quantity);
    }

    function mintMerkleWhitelistEarlyAccess(bytes32[] calldata _merkleProof, uint96 _merkleProofAmount, uint16 _mintAmount) external payable {
        require(merkleProofWhitelist.isValidMerkleProof(_merkleProof, msg.sender, _merkleProofAmount), 'INVALID_MERKLE_PROOF');
        require(isRandomnessRequested == false, "MINTING_OVER");
        require(block.timestamp >= (mintingStartTimeUnix - 1 hours), "EARLY_ACCESS_NOT_STARTED");
        require((prevTokenId + _mintAmount) <= supplyLimit, "EXCEEDS_MAX_SUPPLY");
        require((msg.value) == (price * _mintAmount), "INCORRECT_ETH_VALUE");

        merkleWhitelistEarlyAccessMintCount[msg.sender] += _mintAmount;

        require(merkleWhitelistEarlyAccessMintCount[msg.sender] <= earlyAccessAllowance, "EXCEEDS_EARLY_ACCESS_ALLOWANCE");

        handleSale(msg.sender, _mintAmount);
    }

    function handleSale(address _recipient, uint16 _quantity) internal {
      for(uint16 i = 1; i <= _quantity; i++) {
        wgmis.transferFrom(tokenPoolHolder, _recipient, prevTokenId + i);
      }
      prevTokenId += _quantity;
    }

    function totalSupply() public view returns(uint256) {
        return prevTokenId;
    }

    // Fee distribution logic below

    modifier onlyFeeRecipientOrOwner() {
        bool isFeeRecipient = false;
        for(uint256 i = 0; i < payoutAddresses.length; i++) {
            if(payoutAddresses[i] == msg.sender) {
                isFeeRecipient = true;
            }
        }
        require((isFeeRecipient == true) || (owner() == _msgSender()));
        _;
    }

    function getPercentageOf(
        uint256 _amount,
        uint16 _basisPoints
    ) internal pure returns (uint256 value) {
        value = (_amount * _basisPoints) / 10000;
    }

    function distributeFees() public onlyFeeRecipientOrOwner {
        uint256 feeCutsTotal;
        uint256 balance = address(this).balance;
        for(uint256 i = 0; i < payoutAddresses.length; i++) {
            uint256 feeCut;
            if(i < (payoutAddresses.length - 1)) {
                feeCut = getPercentageOf(balance, payoutAddressBasisPoints[i]);
            } else {
                feeCut = (balance - feeCutsTotal);
            }
            feeCutsTotal += feeCut;
            (bool feeCutDeliverySuccess, ) = payoutAddresses[i].call{value: feeCut}("");
            require(feeCutDeliverySuccess, "FEE_CUT_NO_DELIVERY");
        }
    }
    
    function updateFeePayoutScheme(
      address[] memory _payoutAddresses,
      uint16[] memory _payoutAddressBasisPoints
    ) public onlyOwner {
      payoutAddresses = _payoutAddresses;
      payoutAddressBasisPoints = _payoutAddressBasisPoints;
    }

    function setPrice(
      uint256 _price
    ) public onlyOwner {
      price = _price;
    }

    function setPrevTokenId(
      uint16 _prevTokenId
    ) public onlyOwner {
      prevTokenId = _prevTokenId;
    }

    function setStartTime(
      uint256 _mintingStartTimeUnix
    ) public onlyOwner {
      mintingStartTimeUnix = _mintingStartTimeUnix;
    }

    function setSingleOrderLimit(
      uint256 _singleOrderLimit
    ) public onlyOwner {
      singleOrderLimit = _singleOrderLimit;
    }

    function updateMerkleProofWhitelist(address _merkleProofWhitelist) external onlyOwner {
        require(isRandomnessRequested == false);
        merkleProofWhitelist = IWgmisMerkleTreeWhitelist(_merkleProofWhitelist);
        merkleWhitelistVersion++;
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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