// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC20.sol";
import "./Ownable.sol";

/// @title $UTIL Token
/// @author Hub3

/*
 /$$   /$$ /$$$$$$$$ /$$$$$$ /$$       /$$$$$$ /$$$$$$$$ /$$     /$$       /$$$$$$$$ /$$$$$$  /$$   /$$ /$$$$$$$$ /$$   /$$
| $$  | $$|__  $$__/|_  $$_/| $$      |_  $$_/|__  $$__/|  $$   /$$/      |__  $$__//$$__  $$| $$  /$$/| $$_____/| $$$ | $$
| $$  | $$   | $$     | $$  | $$        | $$     | $$    \  $$ /$$/          | $$  | $$  \ $$| $$ /$$/ | $$      | $$$$| $$
| $$  | $$   | $$     | $$  | $$        | $$     | $$     \  $$$$/           | $$  | $$  | $$| $$$$$/  | $$$$$   | $$ $$ $$
| $$  | $$   | $$     | $$  | $$        | $$     | $$      \  $$/            | $$  | $$  | $$| $$  $$  | $$__/   | $$  $$$$
| $$  | $$   | $$     | $$  | $$        | $$     | $$       | $$             | $$  | $$  | $$| $$\  $$ | $$      | $$\  $$$
|  $$$$$$/   | $$    /$$$$$$| $$$$$$$$ /$$$$$$   | $$       | $$             | $$  |  $$$$$$/| $$ \  $$| $$$$$$$$| $$ \  $$
 \______/    |__/   |______/|________/|______/   |__/       |__/             |__/   \______/ |__/  \__/|________/|__/  \__/
*/

contract UtilToken is ERC20, Ownable {
    mapping(address => bool) transferPrivileges;

    constructor() ERC20("Util Token", "UTIL", 18) {}

    uint256 TotalUtil = 1000000000 ether;

    function mintUtil(address recipient, uint256 amount) external {
        require(transferPrivileges[msg.sender], "Sender is not allowed to transfer $UTIL!");
        require(totalSupply + amount <= TotalUtil, "Total $UTIL amount reached");
        _mint(recipient, amount);
    }

    /*///////////////////////////////////////////////////////////////
							ADMIN UTILITIES
	//////////////////////////////////////////////////////////////*/

    function addTransferPrivileges(address contractAddress) public onlyOwner {
        transferPrivileges[contractAddress] = true;
    }

    function revokeTransferPrivileges(address contractAddress) public onlyOwner {
        transferPrivileges[contractAddress] = false;
    }

    /// @notice Allows the contract owner to burn $UTIL owned by the contract.
    function burn(uint256 amount) public onlyOwner {
        _burn(address(this), amount);
    }

    /// @notice Allows the contract owner to airdrop $UTIL owned by the contract.
    function airdrop(address[] calldata accounts, uint256[] calldata amounts) public onlyOwner {
        require(accounts.length == amounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            uint256 amount = amounts[i];
            balanceOf[address(this)] -= amount;

            // Cannot overflow because the sum of all user
            // balances can't exceed the max uint256 value.
            unchecked {
                balanceOf[accounts[i]] += amount;
            }

            emit Transfer(address(this), accounts[i], amount);
        }
    }

    /// @notice Allows the contract owner to mint $UTIL to the contract.
    function mint(uint256 amount) public onlyOwner {
        _mint(address(this), amount);
    }

    /// @notice Withdraw  $UTIL being held on this contract to the requested address.
    /// @param recipient The address to withdraw the funds to.
    /// @param amount The amount of $UTIL to withdraw
    function withdrawUTIL(address recipient, uint256 amount) public onlyOwner {
        balanceOf[address(this)] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[recipient] += amount;
        }

        emit Transfer(address(this), recipient, amount);
    }

    function updateTotalUtil(uint256 _totalUtil) public onlyOwner {
        TotalUtil = _totalUtil;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

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

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

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

    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        returns (bool)
    {
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

        if (allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amount;

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
                            PERMIT_TYPEHASH,
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

            require(
                recoveredAddress != address(0) && recoveredAddress == owner,
                "INVALID_SIGNER"
            );

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            block.chainid == INITIAL_CHAIN_ID
                ? INITIAL_DOMAIN_SEPARATOR
                : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

error NotOwner();

// https://github.com/m1guelpf/erc721-drop/blob/main/src/LilOwnable.sol
abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function transferOwnership(address _newOwner) external {
        if (msg.sender != _owner) revert NotOwner();

        _owner = _newOwner;
    }

    function renounceOwnership() public {
        if (msg.sender != _owner) revert NotOwner();

        _owner = address(0);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        returns (bool)
    {
        return interfaceId == 0x7f5828d0; // ERC165 Interface ID for ERC173
    }
}