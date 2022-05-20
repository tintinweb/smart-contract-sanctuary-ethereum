// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {RoilAccessControlled, IRoilAuthority} from "./types/RoilAccessControlled.sol";
import {ITreasury} from "./interfaces/ITreasury.sol";
import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import "@rari-capital/solmate/src/tokens/ERC20.sol";

contract RoilTreasury is RoilAccessControlled, ITreasury {
    using SafeTransferLib for ERC20;

    /// VARIABLES ///
    ERC20 private immutable roil;
    string FROM_ROIL = "ONLY AVAILABLE THROUGH ROIL ERC20 TRANSFER METHODS";

    /// @notice stores reward balance in ROIL for a given userId
    mapping(uint32 => uint256) public userBalance;

    /// @notice stores addresses for a given user uuid
    mapping(uint32 => address) public userToAddress;

    /// @notice reverse mapping of above to maintain balances
    mapping(address => uint32) public addressToUser;

    /// @notice amount of ROIL owned by treasury (not users) 
    uint256 public royaltyTotal;

    /// CONSTRUCTOR ///
    constructor(address _roil, address _authority) RoilAccessControlled(IRoilAuthority(_authority)) {
        require(_roil != address(0), "Zero Address: Roil");
        roil = ERC20(_roil);
    }

    /**
     * @notice updates user balance by uuid
     * @param _to user uuid
     * @param _reward amount minted to user
     * @param _royalty amount minted to treasury
     */
    function increaseBalance(uint32 _to, uint256 _reward, uint256 _royalty) public onlyDistributor {
        require(roil.balanceOf(address(this)) >= _reward + _royalty, "Not enough funds"); // TODO more precise check on unaccounted funds
        userBalance[_to] += _reward;
        royaltyTotal += _royalty;
    }

    /**
     * @notice Transfer user funds from Treasury to a
     * @param _userId uuid mapping to user
     * @param _amount amount to approve
     */
    function approveForTransfer(uint32 _userId, uint256 _amount) public userOrServer(_userId) {
        // grab users address
        address userAddress = userToAddress[_userId];
        uint256 userRewards = userBalance[_userId];

        // require address is defined and t(x) from server or user
        require(userAddress != address(0), "USER ADDRESS NOT DEFINED");

        // approve lesser of user provided amount or userRewardBalance
        roil.approve(
            userAddress,
            _amount > userRewards ? userRewards : _amount
        );
    }

    /**
     * @notice updates royalty total upon withdrawal from treasury
     * @param _amount withdrawn amount
     * @dev only available internally when transfer from Treasury is initiated
     */
    function royaltyWithdrawal(uint256 _amount) public {
        require(msg.sender == address(roil), FROM_ROIL);
        royaltyTotal -= _amount;

        emit Withdrawal(address(this), _amount);
    }

    /**
     * @notice updates user ROIL reward balance mapping upon transfer
     * @param _userAddress user address calling transferFrom function 
     * @param _amount amount transferred
     * @dev only callabe from the ROIL erc20 contract (triggered on transferFrom)
     */
    function userWithdrawal(address _userAddress, uint256 _amount) public {
        require(msg.sender == address(roil), FROM_ROIL);
        uint32 userId = addressToUser[_userAddress];
        userBalance[userId] -= _amount;

        emit Withdrawal(_userAddress, _amount);
    }

    /**
     * @notice updates user address mapping for withdrawal purposes
     * @param _userId uuid value for a given user
     * @param _newUserAddress user address to map
     * @dev only callable via ROIL server or current address mapping holder
     */
    function updateUserAddress(uint32 _userId, address _newUserAddress) public userOrServer(_userId) {
        userToAddress[_userId] = _newUserAddress;
        addressToUser[_newUserAddress] = _userId;
    }


    /**
     * @notice returns current reward balance of a given userId
     * @param _userId user id number 
     * @dev cannot allow userId to equal 0 as this is initial  
     *      state of mapping for all unidentified adresses
     */    
    function getUserIdBalance(uint32 _userId) public view returns (uint256 balance) {
        require(_userId != 0, "USER ID NOT INITIALIZED");
        balance = userBalance[_userId];
    }

    /**
     * @notice returns current reward balance of a given userAddress
     * @param _userAddress address to return balance of 
     */
    function getUserAddressBalance(address _userAddress) public view returns (uint256 balance) {
        uint32 userId = addressToUser[_userAddress];
        balance = getUserIdBalance(userId);
    }

    /**
     * @notice returns current users address
     * @param _userId user to return info for
     */
    function getUserAddress(uint32 _userId) public view returns (address userAddress) {
        userAddress = userToAddress[_userId];
    }

    /**xxw
     * @notice requires msg.sender to be ROIL server or user w/ claim to account
     * @param _userId user uuid to check
     */
    modifier userOrServer(uint32 _userId) {
        require(msg.sender == authority.server() || msg.sender == userToAddress[_userId], UNAUTHORIZED);
        _;
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    event Debug(bool one, bool two, uint256 retsize);

    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

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