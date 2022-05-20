// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@rari-capital/solmate/src/tokens/ERC20.sol";
import {RoilAccessControlled, IRoilAuthority} from "./types/RoilAccessControlled.sol";


/**
 * @title RoilNetworkToken
 * @author Nick Fragakis <[email protected]> (https://github.com/nfragakis)
 * @notice RoilNetworkToken is the contract behind the Roil Token Token (ROIL), an ERC20 token accounting for the offset emissions of electrical vehicles
 */

contract RoilERC20 is ERC20, RoilAccessControlled {

    constructor(address _authority) 
        ERC20("Roil Network", "ROIL", 18)
        RoilAccessControlled(IRoilAuthority(_authority)) {}

    function mint(address account_, uint256 amount_) external onlyDistributor {
        _mint(account_, amount_);
    }

    /// @notice modifier added to limit amount of funds treasury can withdraw 
    function transfer(
        address to, 
        uint256 amount
    ) public virtual override limitTreasuryActions(amount) returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    /// @notice modifier added to limit amount of funds treasury can approve for transfer
    function approve(
        address spender, 
        uint256 amount
    ) public virtual override limitTreasuryApprovals(spender, amount) returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    /// @notice modifier to update user balance in treasury after withdrawals
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override onTransferFrom(from, to, amount) returns (bool) {
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

    function burn(uint256 amount) external limitTreasuryActions(amount) {
        _burn(msg.sender, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
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
pragma solidity 0.8.10;

import {IRoilAuthority} from "../interfaces/IRoilAuthority.sol";
import {ITreasury} from "../interfaces/ITreasury.sol";

abstract contract RoilAccessControlled {

    /// EVENTS ///
    event AuthorityUpdated(IRoilAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas
    string OVERDRAFT = "AMOUNT LARGER THAN BALANCE";
    
    /// STATE VARIABLES ///

    IRoilAuthority public authority;

    /// Constructor ///

    constructor(IRoilAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }
    

    /// MODIFIERS ///
    /// @notice only governor can call function
    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }
    
    /// @notice only server can call function
    modifier onlyServer() {
        require(msg.sender == authority.server(), UNAUTHORIZED);
        _;
    }

    /// @notice only distributor can call function
    modifier onlyDistributor() {
        require(msg.sender == authority.distributor(), UNAUTHORIZED);
        _;
    }

    /// @notice only treasury can call function
    modifier onlyTreasury() {
        require(msg.sender == authority.treasury(), UNAUTHORIZED);
        _;
    }

    /**
     * @notice checks to ensure any transfers from the treasury are available
                in the royaltyTotal tracker and updates variable following transfer
       @param _amount amount of withdrawal in ERC-20 transaction
     */
    modifier limitTreasuryActions(uint256 _amount) {
        if (msg.sender == authority.treasury() ) {
            ITreasury treasury = ITreasury(authority.treasury()); 
            require(
                treasury.royaltyTotal() >= _amount,
                OVERDRAFT
            );
            treasury.royaltyWithdrawal(_amount);
        }
        _;
    }

    /**
     * @notice limits the amount the treasury is allowed to approve to _spender balance
     * @param _spender address we are allocating allowance to
     * @param _amount total tokens to be allocated
     */
    modifier limitTreasuryApprovals(address _spender, uint256 _amount) {
        if (msg.sender == authority.treasury() ) {
            ITreasury treasury = ITreasury(msg.sender);
            require(treasury.getUserAddressBalance(_spender) >= _amount, OVERDRAFT);
        }
        _;
    }

    /**
     * @notice when ERC20 TransferFrom is called this modifier updates user balance
     *          in the treasury (needed for funds allocated via App without verified adress) 
     * @param from address we're transferring funds from
     * @param to end recipient of funds
     * @param amount total ROIL tokens to be transferred
     */
    modifier onTransferFrom(address from, address to, uint256 amount) {
        if (from == address(authority.treasury())) {
            ITreasury treasury = ITreasury(authority.treasury());
            
            // verify that the user has funds available in treasury contract
            require(treasury.getUserAddressBalance(to) >= amount, OVERDRAFT);
            treasury.userWithdrawal(to, amount);
        }
        _;
    }

    
    /// GOV ONLY ///
    
    /// @notice update authority contract only governor can call function
    function setAuthority(IRoilAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

interface IRoilAuthority {
    /* ========== EVENTS ========== */
    
    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event ServerPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event DistributorPushed(address indexed from, address indexed to, bool _effectiveImmediately);   
    event TreasuryPushed(address indexed from , address indexed to, bool _effectiveImmediately); 

    event GovernorPulled(address indexed from, address indexed to);
    event ServerPulled(address indexed from, address indexed to);
    event DistributorPulled(address indexed from, address indexed to);
    event TreasuryPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */
    
    function governor() external view returns (address);
    function server() external view returns (address);
    function distributor() external view returns (address);
    function treasury() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ITreasury {
    event Withdrawal(address indexed _user, uint256 amount);

    function royaltyTotal() external returns (uint256 royalties);
    function increaseBalance(uint32 _to, uint256 _amount, uint256 _royalty) external;
    function approveForTransfer(uint32 _userId, uint256 _amount) external;
    function royaltyWithdrawal(uint256 _amount) external;
    function userWithdrawal(address _userAddress, uint256 _amount) external;
    function updateUserAddress(uint32 _userId, address _newUserAddress) external;
    function getUserIdBalance(uint32 _userId) external returns (uint256 balance);
    function getUserAddressBalance(address _userAddress) external returns (uint256 balance);
    function getUserAddress(uint32 _userId) external returns (address userAddress);
}