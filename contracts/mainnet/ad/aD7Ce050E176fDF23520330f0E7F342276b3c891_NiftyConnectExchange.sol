/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// File: contracts/ArrayUtils.sol

pragma solidity 0.4.26;

library ArrayUtils {

    /**
     * Replace bytes in an array with bytes in another array, guarded by a bitmask
     * Efficiency of this function is a bit unpredictable because of the EVM's word-specific model (arrays under 32 bytes will be slower)
     *
     * @dev Mask must be the size of the byte array. A nonzero byte means the byte array can be changed.
     * @param array The original array
     * @param desired The target array
     * @param mask The mask specifying which bits can be changed
     * @return The updated byte array (the parameter will be modified inplace)
     */
    function guardedArrayReplace(bytes memory array, bytes memory desired, bytes memory mask)
    internal
    pure
    {
        require(array.length == desired.length);
        require(array.length == mask.length);

        uint words = array.length / 0x20;
        uint index = words * 0x20;
        assert(index / 0x20 == words);
        uint i;

        for (i = 0; i < words; i++) {
            /* Conceptually: array[i] = (!mask[i] && array[i]) || (mask[i] && desired[i]), bitwise in word chunks. */
            assembly {
                let commonIndex := mul(0x20, add(1, i))
                let maskValue := mload(add(mask, commonIndex))
                mstore(add(array, commonIndex), or(and(not(maskValue), mload(add(array, commonIndex))), and(maskValue, mload(add(desired, commonIndex)))))
            }
        }

        /* Deal with the last section of the byte array. */
        if (words > 0) {
            /* This overlaps with bytes already set but is still more efficient than iterating through each of the remaining bytes individually. */
            i = words;
            assembly {
                let commonIndex := mul(0x20, add(1, i))
                let maskValue := mload(add(mask, commonIndex))
                mstore(add(array, commonIndex), or(and(not(maskValue), mload(add(array, commonIndex))), and(maskValue, mload(add(desired, commonIndex)))))
            }
        } else {
            /* If the byte array is shorter than a word, we must unfortunately do the whole thing bytewise.
               (bounds checks could still probably be optimized away in assembly, but this is a rare case) */
            for (i = index; i < array.length; i++) {
                array[i] = ((mask[i] ^ 0xff) & array[i]) | (mask[i] & desired[i]);
            }
        }
    }

    /**
     * Test if two arrays are equal
     * @param a First array
     * @param b Second array
     * @return Whether or not all bytes in the arrays are equal
     */
    function arrayEq(bytes memory a, bytes memory b)
    internal
    pure
    returns (bool)
    {
        return keccak256(a) == keccak256(b);
    }

    /**
     * Unsafe write byte array into a memory location
     *
     * @param index Memory location
     * @param source Byte array to write
     * @return End memory index
     */
    function unsafeWriteBytes(uint index, bytes source)
    internal
    pure
    returns (uint)
    {
        if (source.length > 0) {
            assembly {
                let length := mload(source)
                let end := add(source, add(0x20, length))
                let arrIndex := add(source, 0x20)
                let tempIndex := index
                for { } eq(lt(arrIndex, end), 1) {
                    arrIndex := add(arrIndex, 0x20)
                    tempIndex := add(tempIndex, 0x20)
                } {
                    mstore(tempIndex, mload(arrIndex))
                }
                index := add(index, length)
            }
        }
        return index;
    }

    /**
     * Unsafe write address into a memory location
     *
     * @param index Memory location
     * @param source Address to write
     * @return End memory index
     */
    function unsafeWriteAddress(uint index, address source)
    internal
    pure
    returns (uint)
    {
        uint conv = uint(source) << 0x60;
        assembly {
            mstore(index, conv)
            index := add(index, 0x14)
        }
        return index;
    }

    /**
     * Unsafe write address into a memory location using entire word
     *
     * @param index Memory location
     * @param source uint to write
     * @return End memory index
     */
    function unsafeWriteAddressWord(uint index, address source)
    internal
    pure
    returns (uint)
    {
        assembly {
            mstore(index, source)
            index := add(index, 0x20)
        }
        return index;
    }

    /**
     * Unsafe write uint into a memory location
     *
     * @param index Memory location
     * @param source uint to write
     * @return End memory index
     */
    function unsafeWriteUint(uint index, uint source)
    internal
    pure
    returns (uint)
    {
        assembly {
            mstore(index, source)
            index := add(index, 0x20)
        }
        return index;
    }

    /**
     * Unsafe write uint8 into a memory location
     *
     * @param index Memory location
     * @param source uint8 to write
     * @return End memory index
     */
    function unsafeWriteUint8(uint index, uint8 source)
    internal
    pure
    returns (uint)
    {
        assembly {
            mstore8(index, source)
            index := add(index, 0x1)
        }
        return index;
    }

    /**
     * Unsafe write uint8 into a memory location using entire word
     *
     * @param index Memory location
     * @param source uint to write
     * @return End memory index
     */
    function unsafeWriteUint8Word(uint index, uint8 source)
    internal
    pure
    returns (uint)
    {
        assembly {
            mstore(index, source)
            index := add(index, 0x20)
        }
        return index;
    }

    /**
     * Unsafe write bytes32 into a memory location using entire word
     *
     * @param index Memory location
     * @param source uint to write
     * @return End memory index
     */
    function unsafeWriteBytes32(uint index, bytes32 source)
    internal
    pure
    returns (uint)
    {
        assembly {
            mstore(index, source)
            index := add(index, 0x20)
        }
        return index;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.4.24;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
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
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.4.24;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {

  using SafeMath for uint256;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    // safeApprove should only be called when setting an initial allowance, 
    // or when resetting it to zero. To increase and decrease it, use 
    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    require((value == 0) || (token.allowance(address(this), spender) == 0));
    require(token.approve(spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    require(token.approve(spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).sub(value);
    require(token.approve(spender, newAllowance));
  }
}

// File: contracts/TokenTransferProxy.sol

pragma solidity 0.4.26;



contract TokenTransferProxy {
    using SafeERC20 for IERC20;

    /* Whether initialized. */
    bool public initialized = false;

    address public exchangeAddress;

    function initialize (address _exchangeAddress)
    public
    {
        require(!initialized);
        initialized = true;
        exchangeAddress = _exchangeAddress;
    }
    /**
     * Call ERC20 `transferFrom`
     *
     * @dev Authenticated contract only
     * @param token IERC20 token address
     * @param from From address
     * @param to To address
     * @param amount Transfer amount
     */
    function transferFrom(address token, address from, address to, uint amount)
    public
    returns (bool)
    {
        require(msg.sender==exchangeAddress, "not authorized");
        IERC20(token).safeTransferFrom(from, to, amount);
        return true;
    }

}

// File: contracts/IERC2981.sol

pragma solidity 0.4.26;

///
/// @dev Interface for the NFT Royalty Standard
///

interface IERC2981 {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount);
}

// File: contracts/IRoyaltyRegisterHub.sol

pragma solidity 0.4.26;

///
/// @dev Interface for the NFT Royalty Standard
///

interface IRoyaltyRegisterHub {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _nftAddress - the NFT contract address
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(address _nftAddress, uint256 _salePrice)  external view returns (address receiver, uint256 royaltyAmount);
}

// File: contracts/ReentrancyGuarded.sol

pragma solidity 0.4.26;

contract ReentrancyGuarded {

    bool reentrancyLock = false;

    /* Prevent a contract function from being reentrant-called. */
    modifier reentrancyGuard {
        if (reentrancyLock) {
            revert();
        }
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

}

// File: contracts/Ownable.sol

pragma solidity 0.4.26;

contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}

// File: contracts/Governable.sol

pragma solidity 0.4.26;

contract Governable {
    address public governor;
    address public pendingGovernor;

    event GovernanceTransferred(
        address indexed previousGovernor,
        address indexed newGovernor
    );
    event NewPendingGovernor(address indexed newPendingGovernor);


    /**
     * @dev The Governable constructor sets the original `governor` of the contract to the sender
     * account.
     */
    constructor() public {
        governor = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the governor.
     */
    modifier onlyGovernor() {
        require(msg.sender == governor);
        _;
    }

    function acceptGovernance() external {
        require(msg.sender == pendingGovernor, "acceptGovernance: Call must come from pendingGovernor.");
        address previousGovernor = governor;
        governor = msg.sender;
        pendingGovernor = address(0);

        emit GovernanceTransferred(previousGovernor, governor);
    }

    function setPendingGovernor(address pendingGovernor_) external {
        require(msg.sender == governor, "setPendingGovernor: Call must come from governor.");
        pendingGovernor = pendingGovernor_;

        emit NewPendingGovernor(pendingGovernor);
    }
}

// File: contracts/SaleKindInterface.sol

pragma solidity 0.4.26;


library SaleKindInterface {

    /**
     * Side: buy or sell.
     */
    enum Side { Buy, Sell }

    /**
     * Currently supported kinds of sale: fixed price, Dutch auction.
     * English auctions cannot be supported without stronger escrow guarantees.
     * Future interesting options: Vickrey auction, nonlinear Dutch auctions.
     */
    enum SaleKind { FixedPrice, DutchAuction }

    /**
     * @dev Check whether the parameters of a sale are valid
     * @param saleKind Kind of sale
     * @param expirationTime Order expiration time
     * @return Whether the parameters were valid
     */
    function validateParameters(SaleKind saleKind, uint expirationTime)
    pure
    internal
    returns (bool)
    {
        /* Auctions must have a set expiration date. */
        return (saleKind == SaleKind.FixedPrice || expirationTime > 0);
    }

    /**
     * @dev Return whether or not an order can be settled
     * @dev Precondition: parameters have passed validateParameters
     * @param listingTime Order listing time
     * @param expirationTime Order expiration time
     */
    function canSettleOrder(uint listingTime, uint expirationTime)
    view
    internal
    returns (bool)
    {
        return (listingTime < now) && (expirationTime == 0 || now < expirationTime);
    }

    /**
     * @dev Calculate the settlement price of an order
     * @dev Precondition: parameters have passed validateParameters.
     * @param side Order side
     * @param saleKind Method of sale
     * @param basePrice Order base price
     * @param extra Order extra price data
     * @param listingTime Order listing time
     * @param expirationTime Order expiration time
     */
    function calculateFinalPrice(Side side, SaleKind saleKind, uint basePrice, uint extra, uint listingTime, uint expirationTime)
    view
    internal
    returns (uint finalPrice)
    {
        if (saleKind == SaleKind.FixedPrice) {
            return basePrice;
        } else if (saleKind == SaleKind.DutchAuction) {
            uint diff = SafeMath.div(SafeMath.mul(extra, SafeMath.sub(now, listingTime)), SafeMath.sub(expirationTime, listingTime));
            if (side == Side.Sell) {
                /* Sell-side - start price: basePrice. End price: basePrice - extra. */
                return SafeMath.sub(basePrice, diff);
            } else {
                /* Buy-side - start price: basePrice. End price: basePrice + extra. */
                return SafeMath.add(basePrice, diff);
            }
        }
    }

}

// File: contracts/ExchangeCore.sol

pragma solidity 0.4.26;









contract ExchangeCore is ReentrancyGuarded, Ownable, Governable {
    string public constant name = "NiftyConnect Exchange Contract";
    string public constant version = "1.0";

    // NOTE: these hashes are derived and verified in the constructor.
    bytes32 private constant _EIP_712_DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    bytes32 private constant _NAME_HASH = 0x97b3fae253daa304aa40063e4f71c3efec8d260848d7379fc623e35f84c73f47;
    bytes32 private constant _VERSION_HASH = 0xe6bbd6277e1bf288eed5e8d1780f9a50b239e86b153736bceebccf4ea79d90b3;
    bytes32 private constant _ORDER_TYPEHASH = 0xf446866267029076a71bb126e250b9480cd4ac2699baa745a582b10b361ec951;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a; // bytes4(keccak256("royaltyInfo(uint256,uint256)"));
    bytes4 private constant _EIP_165_SUPPORT_INTERFACE = 0x01ffc9a7; // bytes4(keccak256("supportsInterface(bytes4)"));

    //    // NOTE: chainId opcode is not supported in solidiy 0.4.x; here we hardcode as 56.
    // In order to protect against orders that are replayable across forked chains,
    // either the solidity version needs to be bumped up or it needs to be retrieved
    // from another contract.
    uint256 private constant _CHAIN_ID = 1;

    // Note: the domain separator is derived and verified in the constructor. */
    bytes32 public constant DOMAIN_SEPARATOR = 0x048b125515112cdaed03d1edbee453f1de399178750917e49ce82b75444d7a21;

    uint256 public constant MAXIMUM_EXCHANGE_RATE = 500; //5%

    /* Token transfer proxy. */
    TokenTransferProxy public tokenTransferProxy;

    /* Cancelled / finalized orders, by hash. */
    mapping(bytes32 => bool) public cancelledOrFinalized;

    /* Orders verified by on-chain approval (alternative to ECDSA signatures so that smart contracts can place orders directly). */
    /* Note that the maker's nonce at the time of approval **plus one** is stored in the mapping. */
    mapping(bytes32 => uint256) private _approvedOrdersByNonce;

    /* Track per-maker nonces that can be incremented by the maker to cancel orders in bulk. */
    // The current nonce for the maker represents the only valid nonce that can be signed by the maker
    // If a signature was signed with a nonce that's different from the one stored in nonces, it
    // will fail validation.
    mapping(address => uint256) public nonces;

    /* Required protocol taker fee, in basis points. Paid to takerRelayerFeeRecipient, makerRelayerFeeRecipient and protocol owner */
    /* Initial rate 2% */
    uint public exchangeFeeRate = 0;

    /* Share of exchangeFee which will be paid to takerRelayerFeeRecipient, in basis points. */
    /* Initial share 15% */
    uint public takerRelayerFeeShare = 1500;

    /* Share of exchangeFee which will be paid to makerRelayerFeeRecipient, in basis points. */
    /* Initial share 80% */
    uint public makerRelayerFeeShare = 8000;

    /* Share of exchangeFee which will be paid to protocolFeeRecipient, in basis points. */
    /* Initial share 5% */
    uint public protocolFeeShare = 500;

    /* Recipient of protocol fees. */
    address public protocolFeeRecipient;

    /* Inverse basis point. */
    uint public constant INVERSE_BASIS_POINT = 10000;

    /*  */
    address public merkleValidatorContract;

    /*  */
    address public royaltyRegisterHub;

    /* An order on the exchange. */
    struct Order {
        /* Exchange address, intended as a versioning mechanism. */
        address exchange;
        /* Order maker address. */
        address maker;
        /* Order taker address, if specified. */
        address taker;
        /*  Order fee recipient or zero address for taker order. */
        address makerRelayerFeeRecipient;
        /*  Taker order fee recipient */
        address takerRelayerFeeRecipient;
        /* Side (buy/sell). */
        SaleKindInterface.Side side;
        /* Kind of sale. */
        SaleKindInterface.SaleKind saleKind;
        /* nftAddress. */
        address nftAddress;
        /* nft tokenId. */
        uint tokenId;
        /* Calldata. */
        bytes calldata;
        /* Calldata replacement pattern, or an empty byte array for no replacement. */
        bytes replacementPattern;
        /* Static call target, zero-address for no static call. */
        address staticTarget;
        /* Static call extra data. */
        bytes staticExtradata;
        /* Token used to pay for the order, or the zero-address as a sentinel value for Ether. */
        address paymentToken;
        /* Base price of the order (in paymentTokens). */
        uint basePrice;
        /* Auction extra parameter - minimum bid increment for English auctions, starting/ending price difference. */
        uint extra;
        /* Listing timestamp. */
        uint listingTime;
        /* Expiration timestamp - 0 for no expiry. */
        uint expirationTime;
        /* Order salt, used to prevent duplicate hashes. */
        uint salt;
        /* NOTE: uint nonce is an additional component of the order but is read from storage */
    }

    event OrderApprovedPartOne    (bytes32 indexed hash, address exchange, address indexed maker, address taker, address indexed makerRelayerFeeRecipient, SaleKindInterface.Side side, SaleKindInterface.SaleKind saleKind, address nftAddress, uint256 tokenId, bytes32 ipfsHash);
    event OrderApprovedPartTwo    (bytes32 indexed hash, bytes calldata, bytes replacementPattern, address staticTarget, bytes staticExtradata, address paymentToken, uint basePrice, uint extra, uint listingTime, uint expirationTime, uint salt);
    event OrderCancelled          (bytes32 indexed hash);
    event OrdersMatched           (bytes32 buyHash, bytes32 sellHash, address indexed maker, address indexed taker, address makerRelayerFeeRecipient, address takerRelayerFeeRecipient, uint price, bytes32 indexed metadata);
    event NonceIncremented        (address indexed maker, uint newNonce);

    constructor () public {
        require(keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)") == _EIP_712_DOMAIN_TYPEHASH);
        require(keccak256(bytes(name)) == _NAME_HASH);
        require(keccak256(bytes(version)) == _VERSION_HASH);
        require(keccak256("Order(address exchange,address maker,address taker,address makerRelayerFeeRecipient,address takerRelayerFeeRecipient,uint8 side,uint8 saleKind,address nftAddress,uint tokenId,bytes32 merkleRoot,bytes calldata,bytes replacementPattern,address staticTarget,bytes staticExtradata,address paymentToken,uint256 basePrice,uint256 extra,uint256 listingTime,uint256 expirationTime,uint256 salt,uint256 nonce)") == _ORDER_TYPEHASH);
        require(DOMAIN_SEPARATOR == _deriveDomainSeparator());
    }

    /**
     * @dev Derive the domain separator for EIP-712 signatures.
     * @return The domain separator.
     */
    function _deriveDomainSeparator() private view returns (bytes32) {
        return keccak256(
            abi.encode(
            _EIP_712_DOMAIN_TYPEHASH, // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
            _NAME_HASH, // keccak256("NiftyConnect Exchange Contract")
            _VERSION_HASH, // keccak256(bytes("1.0"))
            _CHAIN_ID,
            address(this)
        )); // NOTE: this is fixed, need to use solidity 0.5+ or make external call to support!
    }

    function checkRoyalties(address _contract) internal returns (bool) {
        bool success;
        bytes memory data = abi.encodeWithSelector(_EIP_165_SUPPORT_INTERFACE, _INTERFACE_ID_ERC2981);
        bytes memory result = new bytes(32);
        assembly {
            success := call(
                gas,            // gas remaining
                _contract,      // destination address
                0,              // no ether
                add(data, 32),  // input buffer (starts after the first 32 bytes in the `data` array)
                mload(data),    // input length (loaded from the first 32 bytes in the `data` array)
                result,         // output buffer
                32              // output length
            )
        }
        if (!success) {
            return false;
        }
        bool supportERC2981;
        assembly {
            supportERC2981 := mload(result)
        }
        return supportERC2981;
    }

    /**
     * Increment a particular maker's nonce, thereby invalidating all orders that were not signed
     * with the original nonce.
     */
    function incrementNonce() external {
        uint newNonce = ++nonces[msg.sender];
        emit NonceIncremented(msg.sender, newNonce);
    }

    /**
     * @dev Change the exchange fee rate
     * @param newExchangeFeeRate New fee to set in basis points
     */
    function changeExchangeFeeRate(uint newExchangeFeeRate)
    public
    onlyGovernor
    {
        require(newExchangeFeeRate<=MAXIMUM_EXCHANGE_RATE, "invalid exchange fee rate");
        exchangeFeeRate = newExchangeFeeRate;
    }

    /**
     * @dev Change the taker fee paid to the taker relayer (owner only)
     * @param newTakerRelayerFeeShare New fee to set in basis points
     * @param newMakerRelayerFeeShare New fee to set in basis points
     * @param newProtocolFeeShare New fee to set in basis points
     */
    function changeTakerRelayerFeeShare(uint newTakerRelayerFeeShare, uint newMakerRelayerFeeShare, uint newProtocolFeeShare)
    public
    onlyGovernor
    {
        require(SafeMath.add(SafeMath.add(newTakerRelayerFeeShare, newMakerRelayerFeeShare), newProtocolFeeShare) == INVERSE_BASIS_POINT, "invalid new fee share");
        takerRelayerFeeShare = newTakerRelayerFeeShare;
        makerRelayerFeeShare = newMakerRelayerFeeShare;
        protocolFeeShare = newProtocolFeeShare;
    }

    /**
     * @dev Change the protocol fee recipient (owner only)
     * @param newProtocolFeeRecipient New protocol fee recipient address
     */
    function changeProtocolFeeRecipient(address newProtocolFeeRecipient)
    public
    onlyOwner
    {
        protocolFeeRecipient = newProtocolFeeRecipient;
    }

    /**
     * @dev Transfer tokens
     * @param token Token to transfer
     * @param from Address to charge fees
     * @param to Address to receive fees
     * @param amount Amount of protocol tokens to charge
     */
    function transferTokens(address token, address from, address to, uint amount)
    internal
    {
        if (amount > 0) {
            require(tokenTransferProxy.transferFrom(token, from, to, amount));
        }
    }

    /**
     * @dev Execute a STATICCALL (introduced with Ethereum Metropolis, non-state-modifying external call)
     * @param target Contract to call
     * @param calldata Calldata (appended to extradata)
     * @param extradata Base data for STATICCALL (probably function selector and argument encoding)
     * @return The result of the call (success or failure)
     */
    function staticCall(address target, bytes memory calldata, bytes memory extradata)
    public
    view
    returns (bool result)
    {
        bytes memory combined = new bytes(calldata.length + extradata.length);
        uint index;
        assembly {
            index := add(combined, 0x20)
        }
        index = ArrayUtils.unsafeWriteBytes(index, extradata);
        ArrayUtils.unsafeWriteBytes(index, calldata);
        assembly {
            result := staticcall(gas, target, add(combined, 0x20), mload(combined), mload(0x40), 0)
        }
        return result;
    }

    /**
     * @dev Hash an order, returning the canonical EIP-712 order hash without the domain separator
     * @param order Order to hash
     * @param nonce maker nonce to hash
     * @return Hash of order
     */
    function hashOrder(Order memory order, uint nonce)
    internal
    pure
    returns (bytes32 hash)
    {
        /* Unfortunately abi.encodePacked doesn't work here, stack size constraints. */
        uint size = 672;
        bytes memory array = new bytes(size);
        uint index;
        assembly {
            index := add(array, 0x20)
        }
        index = ArrayUtils.unsafeWriteBytes32(index, _ORDER_TYPEHASH);
        index = ArrayUtils.unsafeWriteAddressWord(index, order.exchange);
        index = ArrayUtils.unsafeWriteAddressWord(index, order.maker);
        index = ArrayUtils.unsafeWriteAddressWord(index, order.taker);
        index = ArrayUtils.unsafeWriteAddressWord(index, order.makerRelayerFeeRecipient);
        index = ArrayUtils.unsafeWriteAddressWord(index, order.takerRelayerFeeRecipient);
        index = ArrayUtils.unsafeWriteUint8Word(index, uint8(order.side));
        index = ArrayUtils.unsafeWriteUint8Word(index, uint8(order.saleKind));
        index = ArrayUtils.unsafeWriteAddressWord(index, order.nftAddress);
        index = ArrayUtils.unsafeWriteUint(index, order.tokenId);
        index = ArrayUtils.unsafeWriteBytes32(index, keccak256(order.calldata));
        index = ArrayUtils.unsafeWriteBytes32(index, keccak256(order.replacementPattern));
        index = ArrayUtils.unsafeWriteAddressWord(index, order.staticTarget);
        index = ArrayUtils.unsafeWriteBytes32(index, keccak256(order.staticExtradata));
        index = ArrayUtils.unsafeWriteAddressWord(index, order.paymentToken);
        index = ArrayUtils.unsafeWriteUint(index, order.basePrice);
        index = ArrayUtils.unsafeWriteUint(index, order.extra);
        index = ArrayUtils.unsafeWriteUint(index, order.listingTime);
        index = ArrayUtils.unsafeWriteUint(index, order.expirationTime);
        index = ArrayUtils.unsafeWriteUint(index, order.salt);
        index = ArrayUtils.unsafeWriteUint(index, nonce);
        assembly {
            hash := keccak256(add(array, 0x20), size)
        }
        return hash;
    }

    /**
     * @dev Hash an order, returning the hash that a client must sign via EIP-712 including the message prefix
     * @param order Order to hash
     * @param nonce Nonce to hash
     * @return Hash of message prefix and order hash per Ethereum format
     */
    function hashToSign(Order memory order, uint nonce)
    internal
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashOrder(order, nonce)));
    }

    /**
     * @dev Assert an order is valid and return its hash
     * @param order Order to validate
     * @param nonce Nonce to validate
     */
    function requireValidOrder(Order memory order, uint nonce)
    internal
    view
    returns (bytes32)
    {
        bytes32 hash = hashToSign(order, nonce);
        require(validateOrder(hash, order), "invalid order");
        return hash;
    }

    /**
     * @dev Validate order parameters
     * @param order Order to validate
     */
    function validateOrderParameters(Order memory order)
    internal
    view
    returns (bool)
    {
        /* Order must be targeted at this protocol version (this Exchange contract). */
        if (order.exchange != address(this)) {
            return false;
        }

        /* Order must have a maker. */
        if (order.maker == address(0)) {
            return false;
        }

        /* Order must possess valid sale kind parameter combination. */
        if (!SaleKindInterface.validateParameters(order.saleKind, order.expirationTime)) {
            return false;
        }

        return true;
    }

    /**
     * @dev Validate a provided previously approved / signed order, hash
     * @param hash Order hash (already calculated, passed to avoid recalculation)
     * @param order Order to validate
     */
    function validateOrder(bytes32 hash, Order memory order)
    internal
    view
    returns (bool)
    {
        /* Not done in an if-conditional to prevent unnecessary ecrecover evaluation, which seems to happen even though it should short-circuit. */

        /* Order must have valid parameters. */
        if (!validateOrderParameters(order)) {
            return false;
        }

        /* Order must have not been canceled or already filled. */
        if (cancelledOrFinalized[hash]) {
            return false;
        }

        /* Return true if order has been previously approved with the current nonce */
        uint approvedOrderNoncePlusOne = _approvedOrdersByNonce[hash];
        if (approvedOrderNoncePlusOne == 0) {
            return false;
        }
        return approvedOrderNoncePlusOne == nonces[order.maker] + 1;
    }

    /**
     * @dev Determine if an order has been approved. Note that the order may not still
     * be valid in cases where the maker's nonce has been incremented.
     * @param hash Hash of the order
     * @return whether or not the order was approved.
     */
    function approvedOrders(bytes32 hash) public view returns (bool approved) {
        return _approvedOrdersByNonce[hash] != 0;
    }

    /**
     * @dev Approve an order and optionally mark it for orderbook inclusion. Must be called by the maker of the order
     * @param order Order to approve
     * @param ipfsHash Order metadata on IPFS
     */
    function makeOrder(Order memory order, bytes32 ipfsHash)
    internal
    {
        /* CHECKS */

        /* Assert sender is authorized to approve order. */
        require(msg.sender == order.maker);

        /* Calculate order hash. */
        bytes32 hash = hashToSign(order, nonces[order.maker]);

        /* Assert order has not already been approved. */
        require(_approvedOrdersByNonce[hash] == 0, "duplicated order hash");

        /* EFFECTS */

        /* Mark order as approved. */
        _approvedOrdersByNonce[hash] = nonces[order.maker] + 1;

        /* Log approval event. Must be split in two due to Solidity stack size limitations. */
        {
            emit OrderApprovedPartOne(hash, order.exchange, order.maker, order.taker, order.makerRelayerFeeRecipient, order.side, order.saleKind, order.nftAddress, order.tokenId, ipfsHash);
        }
        {
            emit OrderApprovedPartTwo(hash, order.calldata, order.replacementPattern, order.staticTarget, order.staticExtradata, order.paymentToken, order.basePrice, order.extra, order.listingTime, order.expirationTime, order.salt);
        }
    }

    /**
     * @dev Cancel an order, preventing it from being matched. Must be called by the maker of the order
     * @param order Order to cancel
     * @param nonce Nonce to cancel
     */
    function cancelOrder(Order memory order, uint nonce)
    internal
    {
        /* CHECKS */

        /* Calculate order hash. */
        bytes32 hash = requireValidOrder(order, nonce);

        /* Assert sender is authorized to cancel order. */
        require(msg.sender == order.maker);

        /* EFFECTS */

        /* Mark order as cancelled, preventing it from being matched. */
        cancelledOrFinalized[hash] = true;

        /* Log cancel event. */
        emit OrderCancelled(hash);
    }

    /**
     * @dev Calculate the current price of an order (convenience function)
     * @param order Order to calculate the price of
     * @return The current price of the order
     */
    function calculateCurrentPrice (Order memory order)
    internal
    view
    returns (uint)
    {
        return SaleKindInterface.calculateFinalPrice(order.side, order.saleKind, order.basePrice, order.extra, order.listingTime, order.expirationTime);
    }

    /**
     * @dev Calculate the price two orders would match at, if in fact they would match (otherwise fail)
     * @param buy Buy-side order
     * @param sell Sell-side order
     * @return Match price
     */
    function calculateMatchPrice(Order memory buy, Order memory sell)
    view
    internal
    returns (uint)
    {
        /* Calculate sell price. */
        uint sellPrice = SaleKindInterface.calculateFinalPrice(sell.side, sell.saleKind, sell.basePrice, sell.extra, sell.listingTime, sell.expirationTime);

        /* Calculate buy price. */
        uint buyPrice = SaleKindInterface.calculateFinalPrice(buy.side, buy.saleKind, buy.basePrice, buy.extra, buy.listingTime, buy.expirationTime);

        /* Require price cross. */
        require(buyPrice >= sellPrice);

        /* Maker/taker priority. */
        return sell.makerRelayerFeeRecipient != address(0) ? sellPrice : buyPrice;
    }

    /**
     * @dev Execute all IERC20 token / Ether transfers associated with an order match (fees and buyer => seller transfer)
     * @param buy Buy-side order
     * @param sell Sell-side order
     */
    function executeFundsTransfer(Order memory buy, Order memory sell)
    internal
    returns (uint)
    {
        /* Only payable in the special case of unwrapped Ether. */
        if (sell.paymentToken != address(0)) {
            require(msg.value == 0);
        }

        /* Calculate match price. */
        uint price = calculateMatchPrice(buy, sell);

        /* If paying using a token (not Ether), transfer tokens. This is done prior to fee payments to that a seller will have tokens before being charged fees. */
        if (price > 0 && sell.paymentToken != address(0)) {
            transferTokens(sell.paymentToken, buy.maker, sell.maker, price);
        }

        /* Amount that will be received by seller (for Ether). */
        uint receiveAmount = price;

        /* Amount that must be sent by buyer (for Ether). */
        uint requiredAmount = price;

        uint exchangeFee = SafeMath.div(SafeMath.mul(exchangeFeeRate, price), INVERSE_BASIS_POINT);

        address royaltyReceiver = address(0x00);
        uint256 royaltyAmount;
        if (checkRoyalties(sell.nftAddress)) {
            (royaltyReceiver, royaltyAmount) = IERC2981(sell.nftAddress).royaltyInfo(buy.tokenId, price);
        } else {
            (royaltyReceiver, royaltyAmount) = IRoyaltyRegisterHub(royaltyRegisterHub).royaltyInfo(sell.nftAddress, price);
        }

        if (royaltyReceiver != address(0x00) && royaltyAmount != 0) {
            if (sell.paymentToken == address(0)) {
                receiveAmount = SafeMath.sub(receiveAmount, royaltyAmount);
                royaltyReceiver.transfer(royaltyAmount);
            } else {
                transferTokens(sell.paymentToken, sell.maker, royaltyReceiver, royaltyAmount);
            }
        }

        /* Determine maker/taker and charge fees accordingly. */
        if (sell.makerRelayerFeeRecipient != address(0) && exchangeFee != 0) {
            /* Sell-side order is maker. */

            /* Maker fees are deducted from the token amount that the maker receives. Taker fees are extra tokens that must be paid by the taker. */

            uint makerRelayerFee = SafeMath.div(SafeMath.mul(makerRelayerFeeShare, exchangeFee), INVERSE_BASIS_POINT);
            if (sell.paymentToken == address(0)) {
                receiveAmount = SafeMath.sub(receiveAmount, makerRelayerFee);
                sell.makerRelayerFeeRecipient.transfer(makerRelayerFee);
            } else {
                transferTokens(sell.paymentToken, sell.maker, sell.makerRelayerFeeRecipient, makerRelayerFee);
            }

            if (buy.takerRelayerFeeRecipient != address(0)) {
                uint takerRelayerFee = SafeMath.div(SafeMath.mul(takerRelayerFeeShare, exchangeFee), INVERSE_BASIS_POINT);
                if (sell.paymentToken == address(0)) {
                    receiveAmount = SafeMath.sub(receiveAmount, takerRelayerFee);
                    buy.takerRelayerFeeRecipient.transfer(takerRelayerFee);
                } else {
                    transferTokens(sell.paymentToken, sell.maker, buy.takerRelayerFeeRecipient, takerRelayerFee);
                }
            }

            uint protocolFee = SafeMath.div(SafeMath.mul(protocolFeeShare, exchangeFee), INVERSE_BASIS_POINT);
            if (sell.paymentToken == address(0)) {
                receiveAmount = SafeMath.sub(receiveAmount, protocolFee);
                protocolFeeRecipient.transfer(protocolFee);
            } else {
                transferTokens(sell.paymentToken, sell.maker, protocolFeeRecipient, protocolFee);
            }
        } else if (sell.makerRelayerFeeRecipient == address(0)){
            /* Buy-side order is maker. */

            /* The Exchange does not escrow Ether, so direct Ether can only be used to with sell-side maker / buy-side taker orders. */
            require(sell.paymentToken != address(0));

            if (exchangeFee != 0) {
                makerRelayerFee = SafeMath.div(SafeMath.mul(makerRelayerFeeShare, exchangeFee), INVERSE_BASIS_POINT);
                transferTokens(sell.paymentToken, sell.maker, buy.makerRelayerFeeRecipient, makerRelayerFee);

                if (sell.takerRelayerFeeRecipient != address(0)) {
                    takerRelayerFee = SafeMath.div(SafeMath.mul(takerRelayerFeeShare, exchangeFee), INVERSE_BASIS_POINT);
                    transferTokens(sell.paymentToken, sell.maker, sell.takerRelayerFeeRecipient, takerRelayerFee);
                }

                protocolFee = SafeMath.div(SafeMath.mul(protocolFeeShare, exchangeFee), INVERSE_BASIS_POINT);
                transferTokens(sell.paymentToken, sell.maker, protocolFeeRecipient, protocolFee);
            }
        }

        if (sell.paymentToken == address(0)) {
            /* Special-case Ether, order must be matched by buyer. */
            require(msg.value >= requiredAmount);
            sell.maker.transfer(receiveAmount);
            /* Allow overshoot for variable-price auctions, refund difference. */
            uint diff = SafeMath.sub(msg.value, requiredAmount);
            if (diff > 0) {
                buy.maker.transfer(diff);
            }
        }

        /* This contract should never hold Ether, however, we cannot assert this, since it is impossible to prevent anyone from sending Ether e.g. with selfdestruct. */

        return price;
    }

    /**
     * @dev Return whether or not two orders can be matched with each other by basic parameters (does not check order signatures / calldata or perform static calls)
     * @param buy Buy-side order
     * @param sell Sell-side order
     * @return Whether or not the two orders can be matched
     */
    function ordersCanMatch(Order memory buy, Order memory sell)
    internal
    view
    returns (bool)
    {
        return (
        /* Must be opposite-side. */
        (buy.side == SaleKindInterface.Side.Buy && sell.side == SaleKindInterface.Side.Sell) &&
        /* Must use same payment token. */
        (buy.paymentToken == sell.paymentToken) &&
        /* Must match maker/taker addresses. */
        (sell.taker == address(0) || sell.taker == buy.maker) &&
        (buy.taker == address(0) || buy.taker == sell.maker) &&
        /* One must be maker and the other must be taker (no bool XOR in Solidity). */
        ((sell.makerRelayerFeeRecipient == address(0) && buy.makerRelayerFeeRecipient != address(0)) || (sell.makerRelayerFeeRecipient != address(0) && buy.makerRelayerFeeRecipient == address(0))) &&
        /* Must match nftAddress. */
        (buy.nftAddress == sell.nftAddress) &&
        /* Buy-side order must be settleable. */
        SaleKindInterface.canSettleOrder(buy.listingTime, buy.expirationTime) &&
        /* Sell-side order must be settleable. */
        SaleKindInterface.canSettleOrder(sell.listingTime, sell.expirationTime)
        );
    }

    /**
     * @dev Atomically match two orders, ensuring validity of the match, and execute all associated state transitions. Protected against reentrancy by a contract-global lock.
     * @param buy Buy-side order
     * @param sell Sell-side order
     */
    function takeOrder(Order memory buy, Order memory sell, bytes32 metadata)
    internal
    reentrancyGuard
    {
        /* CHECKS */

        /* Ensure buy order validity and calculate hash if necessary. */
        bytes32 buyHash;
        if (buy.maker == msg.sender) {
            require(validateOrderParameters(buy), "invalid buy params");
        } else {
            buyHash = _requireValidOrderWithNonce(buy);
        }

        /* Ensure sell order validity and calculate hash if necessary. */
        bytes32 sellHash;
        if (sell.maker == msg.sender) {
            require(validateOrderParameters(sell), "invalid sell params");
        } else {
            sellHash = _requireValidOrderWithNonce(sell);
        }

        /* Must be matchable. */
        require(ordersCanMatch(buy, sell), "order can't match");

        /* Must match calldata after replacement, if specified. */
        if (buy.replacementPattern.length > 0) {
            ArrayUtils.guardedArrayReplace(buy.calldata, sell.calldata, buy.replacementPattern);
        }
        if (sell.replacementPattern.length > 0) {
            ArrayUtils.guardedArrayReplace(sell.calldata, buy.calldata, sell.replacementPattern);
        }
        require(ArrayUtils.arrayEq(buy.calldata, sell.calldata), "calldata doesn't equal");

        /* EFFECTS */

        /* Mark previously signed or approved orders as finalized. */
        if (msg.sender != buy.maker) {
            cancelledOrFinalized[buyHash] = true;
        }
        if (msg.sender != sell.maker) {
            cancelledOrFinalized[sellHash] = true;
        }

        /* INTERACTIONS */

        /* Execute funds transfer and pay fees. */
        uint price = executeFundsTransfer(buy, sell);

        require(merkleValidatorContract.delegatecall(sell.calldata), "order calldata failure");

        /* Static calls are intentionally done after the effectful call so they can check resulting state. */

        /* Handle buy-side static call if specified. */
        if (buy.staticTarget != address(0)) {
            require(staticCall(buy.staticTarget, sell.calldata, buy.staticExtradata));
        }

        /* Handle sell-side static call if specified. */
        if (sell.staticTarget != address(0)) {
            require(staticCall(sell.staticTarget, sell.calldata, sell.staticExtradata));
        }

        /* Log match event. */
        emit OrdersMatched(
            buyHash, sellHash,
            sell.makerRelayerFeeRecipient != address(0) ? sell.maker : buy.maker,
            sell.makerRelayerFeeRecipient != address(0) ? buy.maker : sell.maker,
            sell.makerRelayerFeeRecipient != address(0) ? sell.makerRelayerFeeRecipient : buy.makerRelayerFeeRecipient,
            sell.makerRelayerFeeRecipient != address(0) ? buy.takerRelayerFeeRecipient : sell.takerRelayerFeeRecipient,
            price, metadata);
    }

    function _requireValidOrderWithNonce(Order memory order) internal view returns (bytes32) {
        return requireValidOrder(order, nonces[order.maker]);
    }
}

// File: contracts/NiftyConnectExchange.sol

pragma solidity 0.4.26;




contract NiftyConnectExchange is ExchangeCore {

    enum MerkleValidatorSelector {
        MatchERC721UsingCriteria,
        MatchERC721WithSafeTransferUsingCriteria,
        MatchERC1155UsingCriteria
    }

    constructor (
        TokenTransferProxy tokenTransferProxyAddress,
        address protocolFeeAddress,
        address merkleValidatorAddress,
        address royaltyRegisterHubAddress)
    public {
        tokenTransferProxy = tokenTransferProxyAddress;
        protocolFeeRecipient = protocolFeeAddress;
        merkleValidatorContract = merkleValidatorAddress;
        royaltyRegisterHub = royaltyRegisterHubAddress;
    }

    function buildCallData(
        uint selector,
        address from,
        address to,
        address nftAddress,
        uint256 tokenId,
        uint256 amount,
        bytes32 merkleRoot,
        bytes32[] memory merkleProof)
    public view returns(bytes) {
        MerkleValidatorSelector merkleValidatorSelector = MerkleValidatorSelector(selector);
        if (merkleValidatorSelector == MerkleValidatorSelector.MatchERC721UsingCriteria) {
            return abi.encodeWithSignature("matchERC721UsingCriteria(address,address,address,uint256,bytes32,bytes32[])", from, to, nftAddress, tokenId, merkleRoot, merkleProof);
        } else if (merkleValidatorSelector == MerkleValidatorSelector.MatchERC721WithSafeTransferUsingCriteria) {
            return abi.encodeWithSignature("matchERC721WithSafeTransferUsingCriteria(address,address,address,uint256,bytes32,bytes32[])", from, to, nftAddress, tokenId, merkleRoot, merkleProof);
        } else if (merkleValidatorSelector == MerkleValidatorSelector.MatchERC1155UsingCriteria) {
            return abi.encodeWithSignature("matchERC1155UsingCriteria(address,address,address,uint256,uint256,bytes32,bytes32[])", from, to, nftAddress, tokenId, amount, merkleRoot, merkleProof);
        } else {
            return new bytes(0);
        }
    }

    function buildCallDataInternal(
        address from,
        address to,
        address nftAddress,
        uint[9] uints,
        bytes32 merkleRoot)
    internal view returns(bytes) {
        bytes32[] memory merkleProof;
        if (uints[8]==0) {
            require(merkleRoot==bytes32(0x00), "invalid merkleRoot");
            return buildCallData(uints[5],from,to,nftAddress,uints[6],uints[7],merkleRoot,merkleProof);
        }
        require(uints[8]>=2&&merkleRoot!=bytes32(0x00), "invalid merkle data");
        uint256 merkleProofLength;
        uint256 divResult = uints[8];
        bool hasMod = false;
        for(;divResult!=0;) {
            uint256 tempDivResult = divResult/2;
            if (SafeMath.mul(tempDivResult, 2)<divResult) {
                hasMod = true;
            }
            divResult=tempDivResult;
            merkleProofLength++;
        }
        if (!hasMod) {
            merkleProofLength--;
        }
        merkleProof = new bytes32[](merkleProofLength);
        return buildCallData(uints[5],from,to,nftAddress,uints[6],uints[7],merkleRoot,merkleProof);
    }

    function guardedArrayReplace(bytes array, bytes desired, bytes mask)
    public
    pure
    returns (bytes)
    {
        ArrayUtils.guardedArrayReplace(array, desired, mask);
        return array;
    }

    function calculateFinalPrice(SaleKindInterface.Side side, SaleKindInterface.SaleKind saleKind, uint basePrice, uint extra, uint listingTime, uint expirationTime)
    public
    view
    returns (uint)
    {
        return SaleKindInterface.calculateFinalPrice(side, saleKind, basePrice, extra, listingTime, expirationTime);
    }

    function hashToSign_(
        address[9] addrs,
        uint[9] uints,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        bytes replacementPattern,
        bytes staticExtradata,
        bytes32 merkleRoot)
    public
    view
    returns (bytes32)
    {
        bytes memory orderCallData = buildCallDataInternal(addrs[7],addrs[8],addrs[4],uints,merkleRoot);
        return hashToSign(
            Order(addrs[0], addrs[1], addrs[2], addrs[3], address(0x00), side, saleKind, addrs[4], uints[6], orderCallData, replacementPattern, addrs[5], staticExtradata, IERC20(addrs[6]), uints[0], uints[1], uints[2], uints[3], uints[4]),
            nonces[addrs[1]]
        );
    }

    function validateOrderParameters_ (
        address[9] addrs,
        uint[9] uints,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        bytes replacementPattern,
        bytes staticExtradata,
        bytes32 merkleRoot)
    view
    public
    returns (bool) {
        bytes memory orderCallData = buildCallDataInternal(addrs[7],addrs[8],addrs[4],uints,merkleRoot);
        Order memory order = Order(addrs[0], addrs[1], addrs[2], addrs[3], address(0x00), side, saleKind, addrs[4], uints[6], orderCallData, replacementPattern, addrs[5], staticExtradata, IERC20(addrs[6]), uints[0], uints[1], uints[2], uints[3], uints[4]);
        return validateOrderParameters(
            order
        );
    }

    function validateOrder_ (
        address[9] addrs,
        uint[9] uints,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        bytes replacementPattern,
        bytes staticExtradata,
        bytes32 merkleRoot)
    view
    public
    returns (bool)
    {
        bytes memory orderCallData = buildCallDataInternal(addrs[7],addrs[8],addrs[4],uints,merkleRoot);
        Order memory order = Order(addrs[0], addrs[1], addrs[2], addrs[3], address(0x00), side, saleKind, addrs[4], uints[6], orderCallData, replacementPattern, addrs[5], staticExtradata, IERC20(addrs[6]), uints[0], uints[1], uints[2], uints[3], uints[4]);
        return validateOrder(
            hashToSign(order, nonces[order.maker]),
            order
        );
    }

    function makeOrder_ (
        address[9] addrs,
        uint[9] uints,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        bytes replacementPattern,
        bytes staticExtradata,
        bytes32[2] merkleData)
    public
    {
        bytes memory orderCallData = buildCallDataInternal(addrs[7],addrs[8],addrs[4],uints,merkleData[0]);
        require(addrs[3]!=address(0x00), "makerRelayerFeeRecipient must not be zero");
        require(orderCallData.length==replacementPattern.length, "replacement pattern length mismatch");
        Order memory order = Order(addrs[0], addrs[1], addrs[2], addrs[3], address(0x00), side, saleKind, addrs[4], uints[6], orderCallData, replacementPattern, addrs[5], staticExtradata, IERC20(addrs[6]), uints[0], uints[1], uints[2], uints[3], uints[4]);
        return makeOrder(order, merkleData[1]);
    }

    function cancelOrder_(
        address[9] addrs,
        uint[9] uints,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        bytes replacementPattern,
        bytes staticExtradata,
        bytes32 merkleRoot)
    public
    {
        bytes memory orderCallData = buildCallDataInternal(addrs[7],addrs[8],addrs[4],uints,merkleRoot);
        Order memory order = Order(addrs[0], addrs[1], addrs[2], addrs[3], address(0x00), side, saleKind, addrs[4], uints[6], orderCallData, replacementPattern, addrs[5], staticExtradata, IERC20(addrs[6]), uints[0], uints[1], uints[2], uints[3], uints[4]);
        return cancelOrder(
            order,
            nonces[order.maker]
        );
    }

    function calculateCurrentPrice_(
        address[9] addrs,
        uint[9] uints,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        bytes replacementPattern,
        bytes staticExtradata,
        bytes32 merkleRoot)
    public
    view
    returns (uint)
    {
        bytes memory orderCallData = buildCallDataInternal(addrs[7],addrs[8],addrs[4],uints,merkleRoot);
        return calculateCurrentPrice(
            Order(addrs[0], addrs[1], addrs[2], addrs[3], address(0x00), side, saleKind, addrs[4], uints[6], orderCallData, replacementPattern, addrs[5], staticExtradata, IERC20(addrs[6]), uints[0], uints[1], uints[2], uints[3], uints[4])
        );
    }

    function ordersCanMatch_(
        address[16] addrs,
        uint[12] uints,
        uint8[4] sidesKinds,
        bytes calldataBuy,
        bytes calldataSell,
        bytes replacementPatternBuy,
        bytes replacementPatternSell,
        bytes staticExtradataBuy,
        bytes staticExtradataSell)
    public
    view
    returns (bool)
    {
        Order memory buy = Order(addrs[0], addrs[1], addrs[2], addrs[3], addrs[4], SaleKindInterface.Side(sidesKinds[0]), SaleKindInterface.SaleKind(sidesKinds[1]), addrs[5], uints[5], calldataBuy, replacementPatternBuy, addrs[6], staticExtradataBuy, IERC20(addrs[7]), uints[0], uints[1], uints[2], uints[3], uints[4]);
        Order memory sell = Order(addrs[8], addrs[9], addrs[10], addrs[11], addrs[12], SaleKindInterface.Side(sidesKinds[2]), SaleKindInterface.SaleKind(sidesKinds[3]), addrs[13], uints[11], calldataSell, replacementPatternSell, addrs[14], staticExtradataSell, IERC20(addrs[15]), uints[6], uints[7], uints[8], uints[9], uints[10]);
        return ordersCanMatch(
            buy,
            sell
        );
    }

    function orderCalldataCanMatch(bytes buyCalldata, bytes buyReplacementPattern, bytes sellCalldata, bytes sellReplacementPattern)
    public
    pure
    returns (bool)
    {
        if (buyReplacementPattern.length > 0) {
            ArrayUtils.guardedArrayReplace(buyCalldata, sellCalldata, buyReplacementPattern);
        }
        if (sellReplacementPattern.length > 0) {
            ArrayUtils.guardedArrayReplace(sellCalldata, buyCalldata, sellReplacementPattern);
        }
        return ArrayUtils.arrayEq(buyCalldata, sellCalldata);
    }

    function calculateMatchPrice_(
        address[16] addrs,
        uint[12] uints,
        uint8[4] sidesKinds,
        bytes calldataBuy,
        bytes calldataSell,
        bytes replacementPatternBuy,
        bytes replacementPatternSell,
        bytes staticExtradataBuy,
        bytes staticExtradataSell)
    public
    view
    returns (uint)
    {
        Order memory buy = Order(addrs[0], addrs[1], addrs[2], addrs[3], addrs[4], SaleKindInterface.Side(sidesKinds[0]), SaleKindInterface.SaleKind(sidesKinds[1]), addrs[5], uints[5], calldataBuy, replacementPatternBuy, addrs[6], staticExtradataBuy, IERC20(addrs[7]), uints[0], uints[1], uints[2], uints[3], uints[4]);
        Order memory sell = Order(addrs[8], addrs[9], addrs[10], addrs[11], addrs[12], SaleKindInterface.Side(sidesKinds[2]), SaleKindInterface.SaleKind(sidesKinds[3]), addrs[13], uints[11], calldataSell, replacementPatternSell, addrs[14], staticExtradataSell, IERC20(addrs[15]), uints[6], uints[7], uints[8], uints[9], uints[10]);
        return calculateMatchPrice(
            buy,
            sell
        );
    }

    function takeOrder_(
        address[16] addrs,
        uint[12] uints,
        uint8[4] sidesKinds,
        bytes calldataBuy,
        bytes calldataSell,
        bytes replacementPatternBuy,
        bytes replacementPatternSell,
        bytes staticExtradataBuy,
        bytes staticExtradataSell,
        bytes32 rssMetadata)
    public
    payable
    {

        return takeOrder(
            Order(addrs[0], addrs[1], addrs[2], addrs[3], addrs[4], SaleKindInterface.Side(sidesKinds[0]), SaleKindInterface.SaleKind(sidesKinds[1]), addrs[5], uints[5], calldataBuy, replacementPatternBuy, addrs[6], staticExtradataBuy, IERC20(addrs[7]), uints[0], uints[1], uints[2], uints[3], uints[4]),
            Order(addrs[8], addrs[9], addrs[10], addrs[11], addrs[12], SaleKindInterface.Side(sidesKinds[2]), SaleKindInterface.SaleKind(sidesKinds[3]), addrs[13], uints[11], calldataSell, replacementPatternSell, addrs[14], staticExtradataSell, IERC20(addrs[15]), uints[6], uints[7], uints[8], uints[9], uints[10]),
            rssMetadata
        );
    }

}