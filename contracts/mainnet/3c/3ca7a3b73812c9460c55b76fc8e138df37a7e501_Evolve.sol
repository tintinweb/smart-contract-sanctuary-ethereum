/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.12;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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
            bytes32 digest = keccak256(
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
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

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

    /*///////////////////////////////////////////////////////////////
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
/////////////////////////////////////////////////////////
///                                                   ///
///                 ,,ggddY888Ybbgg,,                 ///
///            ,agd8""'   .d8888888888bga,            ///
///         ,gdP""'     .d88888888888888888g,         ///
///       ,dP"        ,d888888888888888888888b,       ///
///     ,dP"         ,8888888888888888888888888b,     ///
///    ,8"          ,88888888P""88888888888888888,    ///
///   ,8'           I8888888(    )8888888888888888,   ///
///  ,8'            `88888888booo888888888888888888,  ///
///  d'              `88888888888888888888888888888b  ///
///  8                `"8888888888888888888888888888  ///
///  8                  `"88888888888888888888888888  ///
///  8                      `"8888888888888888888888  ///
///  Y,                        `8888888888888888888P  ///
///  `8,                         `88888888888888888'  ///
///   `8,              .oo.       `888888888888888'   ///
///    `8a            (8888)       88888888888888'    ///
///     `Yba           `""'       ,888888888888P'     ///
///       "Yba                   ,88888888888'        ///
///         `"Yba,             ,8888888888P"'         ///
///            `"Y8baa,      ,d88888888P"'            ///
///                 ``""YYba8888P888"'                ///
///                                                   ///
/////////////////////////////////////////////////////////

/// @title Evolve
/// @author [email protected]
contract Evolve is ERC20 {

  /// :::::::::::::::::::::::  ERRORS  ::::::::::::::::::::::: ///

  /// @notice Not enough tokens left to mint
  error InsufficientTokens();

  /// @notice Caller is not the contract owner
  error Unauthorized();

  /// @notice Thrown if the address has minted their available capacity
  error MintCapacityReached();

  /// :::::::::::::::::::::  IMMUTABLES  :::::::::::::::::::: ///

  /// @notice The maximum number of nfts to mint
  uint256 public immutable MAXIMUM_SUPPLY;

  /// @notice The Contract Warden
  address public immutable warden;

  /// ::::::::::::::::::::::  STORAGE  :::::::::::::::::::::: ///

  /// @notice Maps addresses to amount of tokens it can mint
  mapping(address => uint256) public mintable;

  /// @notice Maps addresses to amount of tokens it has minted
  mapping(address => uint256) public minted;

  /// :::::::::::::::::::::  CONSTRUCTOR  ::::::::::::::::::::: ///

  constructor() ERC20("Evolve", "VOLV", 18) {
    warden = msg.sender;
    MAXIMUM_SUPPLY = 1_000_000_000;
  }

  /// ::::::::::::::::::::::  MODIFIERS  :::::::::::::::::::::: ///

  modifier canMint() {
    if (mintable[msg.sender] - minted[msg.sender] == 0) {
      revert MintCapacityReached();
    }
    _;
  }

  modifier onlyWarden() {
    if (msg.sender != warden) {
      revert Unauthorized();
    }
    _;
  }

  /// :::::::::::::::::::::::  MINTING  ::::::::::::::::::::::: ///

  function mint(address to, uint256 value) public virtual canMint {
    minted[msg.sender] += value;
    _mint(to, value);
  }

  /// ::::::::::::::::::::::  PRIVILEGED  :::::::::::::::::::::: ///

  function setMintable(address minter, uint256 amount) public onlyWarden {
    mintable[minter] = amount;
  }
}