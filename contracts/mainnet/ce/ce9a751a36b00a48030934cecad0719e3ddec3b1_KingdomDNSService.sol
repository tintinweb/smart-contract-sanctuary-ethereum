/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

// SPDX-License-Identifier: AGPL-3.0

  
pragma solidity ^0.8.4;

abstract contract Ownable {
    error Ownable_NotOwner();
    error Ownable_NewOwnerZeroAddress();

    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @dev Returns the address of the current owner.
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        if (owner() != msg.sender) revert Ownable_NotOwner();
        _;
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// Can only be called by the current owner.
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) revert Ownable_NewOwnerZeroAddress();
        _transferOwnership(newOwner);
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// Internal function without access restriction.
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        unchecked {
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}


/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall {
    function multicall(bytes[] calldata data)
        external
        payable
        returns (bytes[] memory results)
    {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(
                data[i]
            );

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}


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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
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

abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

contract KingdomDNSService is Ownable {
  /** USINGS */
  using SafeMath for uint256;
  using SafeTransferLib for ERC20;


  /** STRUCTS */
  struct DomainDetails {
    bytes name;
    bytes12 topLevel;
    address owner;
    bytes15 ip;
    uint256 expires;
  }

  struct Receipt {
    uint256 amountPaidFealty;
    uint256 timestamp;
    uint256 expires;
  }

  /** CONSTANTS */
  uint256 public constant DOMAIN_NAME_COST = 100000 * 10**18;
  uint256 public constant DOMAIN_NAME_COST_SHORT_ADDITION = 10000 * 10 ** 18;
  uint256 public constant DOMAIN_EXPIRATION_DATE = 365 days;
  uint8 public constant DOMAIN_NAME_MIN_LENGTH = 5;
  uint8 public constant DOMAIN_NAME_EXPENSIVE_LENGTH = 8;
  uint8 public constant TOP_LEVEL_DOMAIN_MIN_LENGTH = 1;
  bytes1 public constant BYTES_DEFAULT_VALUE = bytes1(0x00);

  /** STATE VARIABLES */
  mapping(bytes32 => DomainDetails) public domainNames;
  mapping(address => bytes32[]) public paymentReceipts;
  mapping(bytes32 => Receipt) public receiptDetails;
  address public fealtyContract;

  /**
   * MODIFIERS
   */
  modifier isAvailable(bytes memory domain, bytes12 topLevel) {
    bytes32 domainHash = getDomainHash(domain, topLevel);
    require(
        topLevel == bytes12("king") || topLevel == bytes12("lord") || topLevel == bytes12("lady"),
        'Top level domain is not supported.'
    );
    require(
      domainNames[domainHash].expires < block.timestamp,
      'Domain name is not available.'
    );
    _;
  }

  modifier collectDomainNamePayment(bytes memory domain) {
    uint256 domainPrice = getPrice(domain);
    ERC20(fealtyContract).safeTransferFrom(
        msg.sender,
        address(this),
        domainPrice
    );
    _;

  }

  modifier isDomainOwner(bytes memory domain, bytes12 topLevel) {
    bytes32 domainHash = getDomainHash(domain, topLevel);
    require(
      domainNames[domainHash].owner == msg.sender,
      'You are not the owner of this domain.'
    );
    _;
  }

  modifier isDomainNameLengthAllowed(bytes memory domain) {
    require(
      domain.length >= DOMAIN_NAME_MIN_LENGTH,
      'Domain name is too short.'
    );
    _;
  }

  modifier isTopLevelLengthAllowed(bytes12 topLevel) {
    require(
      topLevel.length >= TOP_LEVEL_DOMAIN_MIN_LENGTH,
      'The provided TLD is too short.'
    );
    _;
  }

  /**
   *  EVENTS
   */
  event LogDomainNameRegistered(
    uint256 indexed timestamp,
    bytes domainName,
    bytes12 topLevel
  );

  event LogDomainNameRenewed(
    uint256 indexed timestamp,
    bytes domainName,
    bytes12 topLevel,
    address indexed owner
  );

  event LogDomainNameEdited(
    uint256 indexed timestamp,
    bytes domainName,
    bytes12 topLevel,
    bytes15 newIp
  );

  event LogDomainNameTransferred(
    uint256 indexed timestamp,
    bytes domainName,
    bytes12 topLevel,
    address indexed owner,
    address newOwner
  );

  event LogPurchaseChangeReturned(
    uint256 indexed timestamp,
    address indexed _owner,
    uint256 amount
  );

  event LogReceipt(
    uint256 indexed timestamp,
    bytes domainName,
    uint256 amountInFealty,
    uint256 expires
  );

  /**
   * @dev - Constructor of the contract
   */
  constructor(address _fealtyContract) {
      fealtyContract = _fealtyContract;
  }

  /*
   * @dev - function to register domain name
   * @param domain - domain name to be registered
   * @param topLevel - domain top level (TLD)
   * @param ip - the ip of the host
   */
  function register(
    bytes memory domain,
    bytes12 topLevel,
    bytes15 ip
  )
    public
    isDomainNameLengthAllowed(domain)
    isTopLevelLengthAllowed(topLevel)
    isAvailable(domain, topLevel)
    collectDomainNamePayment(domain)
  {
    // calculate the domain hash
    bytes32 domainHash = getDomainHash(domain, topLevel);

    // create a new domain entry with the provided fn parameters
    DomainDetails memory newDomain = DomainDetails({
      name: domain,
      topLevel: topLevel,
      owner: msg.sender,
      ip: ip,
      expires: block.timestamp + DOMAIN_EXPIRATION_DATE
    });

    // save the domain to the storage
    domainNames[domainHash] = newDomain;
    

    // create an receipt entry for this domain purchase
    Receipt memory newReceipt = Receipt({
      amountPaidFealty: DOMAIN_NAME_COST,
      timestamp: block.timestamp,
      expires: block.timestamp + DOMAIN_EXPIRATION_DATE
    });

    // calculate the receipt hash/key
    bytes32 receiptKey = getReceiptKey(domain, topLevel);

    // save the receipt key for this `msg.sender` in storage
    paymentReceipts[msg.sender].push(receiptKey);

    // save the receipt entry/details in storage
    receiptDetails[receiptKey] = newReceipt;

    // log receipt issuance
    emit LogReceipt(
      block.timestamp,
      domain,
      DOMAIN_NAME_COST,
      block.timestamp + DOMAIN_EXPIRATION_DATE
    );

    // log domain name registered
    emit LogDomainNameRegistered(block.timestamp, domain, topLevel);
  }

  /*
   * @dev - function to extend domain expiration date
   * @param domain - domain name to be registered
   * @param topLevel - top level
   */
  function renewDomainName(bytes memory domain, bytes12 topLevel)
    public
    payable
    isDomainOwner(domain, topLevel)
    collectDomainNamePayment(domain)
  {
    // calculate the domain hash
    bytes32 domainHash = getDomainHash(domain, topLevel);

    // add 365 days (1 year) to the domain expiration date
    domainNames[domainHash].expires += 365 days;

    // create a receipt entity
    Receipt memory newReceipt = Receipt({
      amountPaidFealty: DOMAIN_NAME_COST,
      timestamp: block.timestamp,
      expires: block.timestamp + DOMAIN_EXPIRATION_DATE
    });

    // calculate the receipt key for this domain
    bytes32 receiptKey = getReceiptKey(domain, topLevel);

    // save the receipt id for this msg.sender
    paymentReceipts[msg.sender].push(receiptKey);

    // store the receipt details in storage
    receiptDetails[receiptKey] = newReceipt;

    // log domain name Renewed
    emit LogDomainNameRenewed(block.timestamp, domain, topLevel, msg.sender);

    // log receipt issuance
    emit LogReceipt(
      block.timestamp,
      domain,
      DOMAIN_NAME_COST,
      block.timestamp + DOMAIN_EXPIRATION_DATE
    );
  }

  /*
   * @dev - function to edit domain name
   * @param domain - the domain name to be editted
   * @param topLevel - tld of the domain
   * @param newIp - the new ip for the domain
   */
  function edit(
    bytes memory domain,
    bytes12 topLevel,
    bytes15 newIp
  ) public isDomainOwner(domain, topLevel) {
    // calculate the domain hash - unique id
    bytes32 domainHash = getDomainHash(domain, topLevel);

    // update the new ip
    domainNames[domainHash].ip = newIp;

    // log change
    emit LogDomainNameEdited(block.timestamp, domain, topLevel, newIp);
  }

  /*
   * @dev - Transfer domain ownership
   * @param domain - name of the domain
   * @param topLevel - tld of the domain
   * @param newOwner - address of the new owner
   */
  function transferDomain(
    bytes memory domain,
    bytes12 topLevel,
    address newOwner
  ) public isDomainOwner(domain, topLevel) {
    // prevent assigning domain ownership to the 0x0 address
    require(newOwner != address(0));

    // calculate the hash of the current domain
    bytes32 domainHash = getDomainHash(domain, topLevel);

    // assign the new owner of the domain
    domainNames[domainHash].owner = newOwner;

    // log the transfer of ownership
    emit LogDomainNameTransferred(
      block.timestamp,
      domain,
      topLevel,
      msg.sender,
      newOwner
    );
  }

  /*
   * @dev - Get ip of domain
   * @param domain
   * @param topLevel
   */
  function getIP(bytes memory domain, bytes12 topLevel)
    public
    view
    returns (bytes15)
  {
    // calculate the hash of the domain
    bytes32 domainHash = getDomainHash(domain, topLevel);

    // return the ip property of the domain from storage
    return domainNames[domainHash].ip;
  }

  /*
   * @dev - Get price of domain
   * @param domain
   */
  function getPrice(bytes memory domain) public pure returns (uint256) {
    // check if the domain name fits in the expensive or cheap categroy
    if (domain.length < DOMAIN_NAME_EXPENSIVE_LENGTH) {
      // if the domain is too short - its more expensive
      return DOMAIN_NAME_COST + DOMAIN_NAME_COST_SHORT_ADDITION;
    }

    // otherwise return the regular price
    return DOMAIN_NAME_COST;
  }

  /**
   * @dev - Get receipt list for the msg.sender
   */
  function getReceiptList() public view returns (bytes32[] memory) {
    return paymentReceipts[msg.sender];
  }

  /*
   * @dev - Get single receipt
   * @param receiptKey
   */
  function getReceipt(bytes32 receiptKey)
    public
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    return (
      receiptDetails[receiptKey].amountPaidFealty,
      receiptDetails[receiptKey].timestamp,
      receiptDetails[receiptKey].expires
    );
  }

  /*
   * @dev - Get (domain name + top level) hash used for unique identifier
   * @param domain
   * @param topLevel
   * @return domainHash
   */
  function getDomainHash(bytes memory domain, bytes12 topLevel)
    public
    pure
    returns (bytes32)
  {
    // @dev - tightly pack parameters in struct for keccak256
    return keccak256(abi.encodePacked(domain, topLevel));
  }

  /*
   * @dev - Get recepit key hash - unique identifier
   * @param domain
   * @param topLevel
   * @return receiptKey
   */
  function getReceiptKey(bytes memory domain, bytes12 topLevel)
    public
    view
    returns (bytes32)
  {
    // @dev - tightly pack parameters in struct for keccak256
    return
      keccak256(
        abi.encodePacked(domain, topLevel, msg.sender, block.timestamp)
      );
  }

  /**
   * @dev - Withdraw function
   */
  function withdraw() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }
}