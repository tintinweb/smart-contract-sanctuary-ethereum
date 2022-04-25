// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./helper/BasicMetaTransaction.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


interface IMUSD {
    function isErc20() external view returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Deed is BasicMetaTransaction, Initializable, OwnableUpgradeable {
    modifier onlyPropertyOwner(uint256 __estateId) {
        require(
            msgSender() == agreements[__estateId].propertyOwnerAddress,
            "Message sender / agreement signer should be property owner"
        );
        _;
    }

    modifier deedRunning(uint256 __estateId) {
        require(
            agreements[__estateId].dealComplete == false,
            "Deed is already completed"
        );

        require(
            agreements[__estateId].initialized == true,
            "Deed is not initialized"
        );
        _;
    }

    function initialize() public initializer {
        __Ownable_init();
    }

    //string to store the legal document

    IMUSD public _erc20Address;
    uint256 public estateId;
    uint256 public platformFees;
    address private _mogulPayoutAddress;

    struct Agreement {
        uint256 propertyPrice;
        uint256 mogulPercentage;
        uint256 mogulTokenAmount;
        uint256 crowdsalePercentage;
        uint256 crowdsaleTokenAmount;
        uint256 propertyOwnerRetains;
        uint256 propertyOwnerTokenAmount;
        uint256 maxSupply;
        address propertyOwnerAddress;
        bool signedByPropertyOwner;
        bool signedByMogul;
        bool initialized;
        bool platfromFeePaid;
        bool dealComplete;
    }

    // struct for document
    struct AgreementDocument {
        string saleDeed;
        string tncLegalDoc;
        string propertyDocument;
    }

    // mapping for containg deeds
    mapping(uint256 => Agreement) public agreements;
    mapping(uint256 => AgreementDocument) public agreementDocuments;

    // events
    event agreementInitiated(
        uint256 indexed _estateId,
        address _propertyOwner,
        string _legalDoc,
        uint256 _maxSupply
    );
    event updatedPropertyDetails(
        uint256 indexed _estateId,
        string _propertyDocument,
        uint256 _propertyPrice,
        uint256 _propertyOwnerRetains
    );
    event assignedPropertyPercentage(
        uint256 indexed _estateId,
        uint256 _mogulPercentage,
        uint256 _crowdsalePercentage
    );
    event signedByPropertyOwner(
        uint256 indexed _estateId,
        address _propertyOwner
    );
    event signedByMogul(uint256 indexed _estateId, address _mogul);
    event updatedPropertyPrice(uint256 indexed _estateId, uint256 _price);
    event updatedPropertyDocument(
        uint256 indexed _estateId,
        string _propertyDocument
    );
    event updatedPropertyOwner(
        uint256 indexed _estateId,
        address indexed _propertyOwnerAddress
    );
    event deedCompleted(uint256 indexed _estateId);

    // function to initiaite agreement

    function initiateAgreement(
        address _propertyOwner,
        uint256 _maxSupply,
        string calldata _legaldoc
    ) external onlyOwner returns (uint256) {
        require(
            _propertyOwner != address(0),
            "Property owner address cannot be 0"
        );
        require(_maxSupply > 0, "Max supply should be greater than 0");
        require(bytes(_legaldoc).length > 0, "legaldoc not found");
        agreements[estateId].propertyOwnerAddress = _propertyOwner;
        agreements[estateId].initialized = true;
        agreementDocuments[estateId].tncLegalDoc = _legaldoc;
        agreements[estateId].maxSupply = _maxSupply;
        estateId++;

        emit agreementInitiated(
            estateId - 1,
            _propertyOwner,
            _legaldoc,
            _maxSupply
        );

        return estateId - 1;
    }

    //function to enter details of property by owner
    //NOTE: estate Id is required
    function enterPropertyDetails(
        string calldata _propertyDocument,
        uint256 _estateId,
        uint256 _propertyPrice,
        uint256 _propertyOwnerRetains
    ) external deedRunning(_estateId) onlyPropertyOwner(_estateId) {
        require(
            _propertyOwnerRetains < 10000,
            "Property owner retains should be less than 100 %"
        );
        require(_propertyPrice > 0, "Property price should be greater than 0");
        require(
            bytes(_propertyDocument).length > 0,
            "Property document not found"
        );

        agreementDocuments[_estateId].propertyDocument = _propertyDocument;
        agreements[_estateId].propertyPrice = _propertyPrice;
        agreements[_estateId].propertyOwnerRetains = _propertyOwnerRetains;

        emit updatedPropertyDetails(
            _estateId,
            _propertyDocument,
            _propertyPrice,
            _propertyOwnerRetains
        );
    }

    //function to set percentqage of mogul and crowdsale
    //NOTE: estate Id is required
    function setPercentage(
        uint256 _estateId,
        uint256 _mogulPercentage,
        uint256 _crowdsalePercentage
    ) external deedRunning(_estateId) onlyOwner {
        Agreement storage agr = agreements[_estateId];
        require(
            _mogulPercentage <= 10000,
            "Mogul percentage should be less than 100"
        );
        require(
            _crowdsalePercentage <= 10000,
            "Crowdsale percentage should be less than 100"
        );
        require(
            _crowdsalePercentage > 0,
            "Crowdsale percentage should be greater than 0"
        );
        agr.mogulPercentage = _mogulPercentage;
        agr.crowdsalePercentage = _crowdsalePercentage;
        require(
            agr.mogulPercentage +
                agr.crowdsalePercentage +
                agr.propertyOwnerRetains ==
                10000,
            "Percentage should be equal to 100"
        );
        //calculate token amount
        percentageToTokens(_estateId);
        agreements[_estateId].signedByPropertyOwner = false;

        emit assignedPropertyPercentage(
            _estateId,
            _mogulPercentage,
            _crowdsalePercentage
        );
    }

    //function to change percentage into tokens
    //NOTE: estate Id is required
    function percentageToTokens(uint256 __estateID) internal {
        Agreement storage _agreement = agreements[__estateID];

        _agreement.propertyOwnerTokenAmount =
            (_agreement.propertyOwnerRetains * _agreement.maxSupply) /
            10000; // divide by 10000 to convert percentage to tokens

        _agreement.mogulTokenAmount =
            (_agreement.mogulPercentage * _agreement.maxSupply) /
            10000;

        _agreement.crowdsaleTokenAmount =
            (_agreement.crowdsalePercentage * _agreement.maxSupply) /
            10000;

        require(
            _agreement.propertyOwnerTokenAmount +
                _agreement.mogulTokenAmount +
                _agreement.crowdsaleTokenAmount ==
                _agreement.maxSupply,
            "Tokens should be equal to max supply"
        );
    }

    // function to sign the agreement by the property owner
    // it will accept all the info present in struct of the specific tokenID
    function signByPropertyOwner(uint256 _estateId)
        external
        deedRunning(_estateId)
        onlyPropertyOwner(_estateId)
    {
        agreements[_estateId].signedByPropertyOwner = true;

        emit signedByPropertyOwner(_estateId, msg.sender);
    }

    function signByMogul(uint256 _estateId)
        external
        deedRunning(_estateId)
        onlyOwner
    {
        //address caller = msgSender();
        agreements[_estateId].signedByMogul = true;

        emit signedByMogul(_estateId, msg.sender);
    }

    // function to set mogul payout address
    function setMogulPayoutAddress(address __mogulPayoutAddress)
        external
        onlyOwner
    {
        require(
            __mogulPayoutAddress != address(0),
            "Mogul payout address cannot be 0"
        );
        _mogulPayoutAddress = __mogulPayoutAddress;
    }

    //function to set platform fees
    function setPlatformFees(uint256 __platformFees) external onlyOwner {
        require(__platformFees > 0, "Platform fees should be greater than 0");
        platformFees = __platformFees;
    }

    //function to set erc20 address
    function setERC20Address(IMUSD __erc20Address) external onlyOwner {
        require(
            address(__erc20Address) != address(0),
            "ERC20 address cannot be 0"
        );
        require(IMUSD(__erc20Address).isErc20(), "ERC20 address is not valid");
        _erc20Address = __erc20Address;
    }

    //function to update property price by owner
    function updatePriceByPropertyOwner(uint256 _estateId, uint256 _price)
        external
        deedRunning(_estateId)
        onlyPropertyOwner(_estateId)
    {
        require(_price > 0, "Price should be greater than 0");
        agreements[_estateId].propertyPrice = _price;
        agreements[_estateId].signedByMogul = false;

        emit updatedPropertyPrice(_estateId, _price);
    }

    //update property doc by owner
    function updatePropertyDocByPropertyOwner(
        uint256 _estateId,
        string calldata _propertyDocument
    ) external deedRunning(_estateId) onlyPropertyOwner(_estateId) {
        require(bytes(_propertyDocument).length > 0, "URI not found");
        agreementDocuments[_estateId].propertyDocument = _propertyDocument;
        agreements[_estateId].signedByMogul = false;

        emit updatedPropertyDocument(_estateId, _propertyDocument);
    }

    //function to update property owner retains by owner
    function updatePropertyOwnerRetainsByPropertyOwner(
        uint256 _estateId,
        uint256 _propertyOwnerRetains
    ) external deedRunning(_estateId) onlyPropertyOwner(_estateId) {
        require(
            _propertyOwnerRetains < 10000,
            "Property owner retains should be less than 100 %"
        );
        agreements[_estateId].propertyOwnerRetains = _propertyOwnerRetains;
        agreements[_estateId].signedByMogul = false;
    }

    //function to update property owner by mogul
    function updatePropertyOwnerByMogul(
        uint256 _estateId,
        address _propertyOwnerAddress
    ) external deedRunning(_estateId) onlyOwner {
        require(
            _propertyOwnerAddress != address(0),
            "Property owner address cannot be 0"
        );
        agreements[_estateId].propertyOwnerAddress = _propertyOwnerAddress;

        emit updatedPropertyOwner(_estateId, _propertyOwnerAddress);
    }

    // function to change the maxSupply of the token
    function updateMaxSupplyByMogul(uint256 _estateId, uint256 _maxSupply)
        external
        deedRunning(_estateId)
        onlyOwner
    {
        require(_maxSupply > 0, "Max supply should be greater than 0");
        agreements[_estateId].maxSupply = _maxSupply;
    }

    function uploadSaleDeedByOwner(uint256 _estateId, string calldata _saleDeed)
        external
        onlyOwner
    {
        require(
            agreements[_estateId].dealComplete == true,
            "deal is not complete yet !!"
        );
        require(bytes(_saleDeed).length > 0, "URI not found");
        agreementDocuments[_estateId].saleDeed = _saleDeed;
    }

    // transfer confirmation function
    //NOTE need to get approval from the erc20  contract first
    function transferPlatformFee(uint256 __estateId) external {
        require(
            agreements[__estateId].signedByPropertyOwner,
            "Property owner should sign the agreement"
        );
        require(
            agreements[__estateId].signedByMogul,
            "Mogul should sign the agreement"
        );
        IMUSD(_erc20Address).safeTransferFrom(
            msgSender(),
            _mogulPayoutAddress,
            platformFees
        );
        agreements[__estateId].platfromFeePaid = true;
    }

    // funtion to confirm the deal completion after crowdsale
    function confirmDeedCompletion(uint256 __estateId)
        external
        deedRunning(__estateId)
        onlyOwner
    {
        require(
            agreements[__estateId].signedByPropertyOwner,
            "Property owner should sign the agreement"
        );
        require(
            agreements[__estateId].signedByMogul,
            "Mogul should sign the agreement"
        );
        require(
            agreements[__estateId].platfromFeePaid,
            "Platform fee not paid"
        );
        agreements[__estateId].dealComplete = true;

        emit deedCompleted(__estateId);
    }

    // function
    function _msgSender() internal view virtual override returns (address) {
        return msgSender();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BasicMetaTransaction {
    using SafeMath for uint256;

    //overriden emit for mogul
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature,
        bytes returnData
    );
    mapping(address => uint256) private nonces;

    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Main function to be called when user wants to execute meta transaction.
     * The actual function to be called should be passed as param with name functionSignature
     * Here the basic signature recovery is being used. Signature is expected to be generated using
     * personal_sign method.
     * @param userAddress Address of user trying to do meta transaction
     * @param functionSignature Signature of the actual function to be called via meta transaction
     * @param sigR R part of the signature
     * @param sigS S part of the signature
     * @param sigV V part of the signature
     */
    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        require(
            verify(
                userAddress,
                nonces[userAddress],
                getChainID(),
                functionSignature,
                sigR,
                sigS,
                sigV
            ),
            "Signer and signature do not match"
        );
        nonces[userAddress] = nonces[userAddress].add(1);

        // Append userAddress at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );

        require(success, "Function call not successful");
        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature,
            returnData
        );
        return returnData;
    }

    function getNonce(address user) external view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function verify(
        address owner,
        uint256 nonce,
        uint256 chainID,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public view returns (bool) {
        bytes32 hash = prefixed(
            keccak256(abi.encodePacked(nonce, this, chainID, functionSignature))
        );
        address signer = ecrecover(hash, sigV, sigR, sigS);
        require(signer != address(0), "Invalid signature");
        return (owner == signer);
    }

    function msgSender() internal view returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            return msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity 0.8.2;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
   // uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}