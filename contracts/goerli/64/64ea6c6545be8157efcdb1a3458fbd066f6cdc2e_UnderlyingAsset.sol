// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {IOneLendAuth} from "../interfaces/IOneLendAuth.sol";

contract UnderlyingAsset is ERC20, Owned {

    address public oneLendAuth; // address of the OneLendAuth contract
    uint256 public resetBalance; // amount of underlying assets used to set account balances

    /*//////////////////////////////-////////////////////////////////
                                MODIFIERS
    //////////////////////////////-////////////////////////////////*/

    modifier onlyOwnerOrAdmin() {
        bool isAdmin = IOneLendAuth(oneLendAuth).isAdmin(msg.sender);
        require(msg.sender == owner|| isAdmin, "UnderlyingAsset: Caller is not the owner or admin");
        _;
    }

    /*//////////////////////////////-////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////-////////////////////////////////*/
    constructor(string memory _name, string memory _symbol) Owned(msg.sender) ERC20(_name, _symbol, 18) {
        resetBalance = 1_000_000_000_000 * 1e18;
    }

    /*//////////////////////////////-////////////////////////////////
                                MINT/BURN/RESET
    //////////////////////////////-////////////////////////////////*/

    // mint tokens
    function mint(address[] calldata _to, uint256 _amt) public onlyOwnerOrAdmin {
        for (uint256 i = 0; i < _to.length;) {
            _mint(_to[i], _amt);
            unchecked {
                i++;
            }
        }
    }

    // burn tokens
    function burn(address[] calldata _from, uint256 _amt) public onlyOwnerOrAdmin {
        for (uint256 i = 0; i < _from.length;) {
            _burn(_from[i], _amt);
            unchecked {
                i++;
            }
        }
    }

    function resetBalances() external onlyOwnerOrAdmin{
        // get all kyc users from the oneLendAuth contract
        address[] memory kycAccounts = IOneLendAuth(oneLendAuth).getKycAccounts();

        for (uint256 i = 0; i < kycAccounts.length; i++) {
            // burn the current balance of wallet
            _burn(kycAccounts[i], balanceOf[kycAccounts[i]]);

            // mint the reset balance to the wallet
            _mint(kycAccounts[i], resetBalance);
        }
    }

    /*//////////////////////////////-////////////////////////////////
                                SETTERS
    //////////////////////////////-////////////////////////////////*/

    // set oneLendAuth address
    function setOneLendAuth(address _oneLendAuth) public onlyOwner {
        oneLendAuth = _oneLendAuth;
    }

    function setResetBalance(uint256 _resetBalance) public onlyOwnerOrAdmin {
        resetBalance = _resetBalance;
    }


}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface IOneLendAuth {
    event AddAdmin(address indexed calller, address addr);
    event RemoveAdmin(address indexed calller, address addr);
    event AddKycAccount(address indexed calller, address kycAccount);
    event RemoveKycAccount(address indexed calller, address kycAccount);

    function isAdmin(address _addr) external view  returns (bool);
    function getAdmins() external view  returns (address[] memory);
    function isKyc(address _addr) external view  returns (bool);
    function getKycAccounts() external view  returns (address[] memory);
    function addKyc(address[] calldata _addr) external;
    function removeKyc(address[] calldata _addr) external;
    function addAdmin(address[] calldata _addr) external;
    function removeAdmin(address[] calldata _addr) external;
}