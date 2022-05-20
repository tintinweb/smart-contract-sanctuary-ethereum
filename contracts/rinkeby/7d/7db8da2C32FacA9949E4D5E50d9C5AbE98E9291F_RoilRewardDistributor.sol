// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {FullMath} from "./lib/FullMath.sol";
import {IROIL} from "./interfaces/IRoil.sol";
import {ITreasury} from "./interfaces/ITreasury.sol";
import {RoilAccessControlled, IRoilAuthority} from "./types/RoilAccessControlled.sol";

/**
 * @title RoilRewardDistributor
 * @author Nick Fragakis <[email protected]> (https://github.com/nfragakis)
 * @notice RewardDistributor mints rewards to users upon receipt of emissions offset from vehicle charge
 */

contract RoilRewardDistributor is RoilAccessControlled {
    
    /// VARIABLES ///
    IROIL public immutable roil;
    ITreasury public treasury;

    /// @notice controls rate of reward given per carbon tonne
    uint8 public rewardConstant = 1;

    /// @notice percent royalty fee minted to treasury upon user charge
    uint8 public royaltyPercent = 2;

    /// DATA STRUCTS ///

    /**
     * @notice             Info from charge event 
     * @param userId       ROIL uid for user 
     * @param arweaveId    Arweave hash for reward data
     * @param reward       Reward amount in ROIL
     */
    enum rewardType{CHARGE, DATA, OTHER}
    struct rewardEvent {
        uint32 userId;
        string arweaveId;
        uint256 reward; // 18 digits
    }
    rewardEvent[] public rewards;

    /// EVENTS ///
    event RewardGenerated(uint256 indexed user, uint256 reward);

    /// CONSTRUCTOR ///
    /**
     * @notice sets contract, treasury, and authority interfaces
     * @param _roil address of Roil ERC20 token
     * @param _treasury address of Roil Treasury
     * @param _authority address of ROIL authority contract
     */
    constructor(
        address _roil,
        address _treasury,
        address _authority
    ) RoilAccessControlled(IRoilAuthority(_authority)) {
        require(_roil != address(0), "Zero Address: ROIL");
        roil = IROIL(_roil);
        require(_treasury != address(0), "Zero Address: Treasury");
        treasury = ITreasury(_treasury);
    }


    /// FUNCTIONS ///

    /**
     * @notice primary function call from go server to store reward
     *          and generate offset reward in ROIL tokens
     * @param _userId uuid of user generating charge event
     * @param _arweaveId arweave id of charge metadata
     * @param _rewardAmount offset value (18 decimals)
     * @dev onlyServer modify limits calls only from server address specified in authority
     */
    function newReward(
        uint32 _userId,
        string memory _arweaveId,
        uint256 _rewardAmount
    ) public onlyServer {

        // royalty fee
        uint256 royalty = FullMath.mulDiv(
            _rewardAmount,
            royaltyPercent,
            100);
        
        // mint charge reward to treasury an update user balance
        roil.mint(address(treasury), _rewardAmount + royalty);
        treasury.increaseBalance(_userId, _rewardAmount, royalty);

        emit RewardGenerated(_userId, _rewardAmount);

        // store charge data
        rewards.push( 
            rewardEvent({
                userId: _userId, 
                arweaveId: _arweaveId,
                reward: _rewardAmount
            }) 
        );
    }

    /**
     * @notice Allows batched call to self (this contract).
     * @param calls An array of inputs for each call.
     * @param revertOnFail If True then reverts after a failed call and stops doing further calls.
     */
    function batchRewards(bytes[] calldata calls, bool revertOnFail) external {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            if (!success && revertOnFail) {
                revert(_getRevertMsg(result));
            }
        }
    }


    /**
     * @notice update treasury if new upgrade is pushed
     * @dev only takes effect if new treasury account has been added to Authority
     */
    function pushTreasury() public onlyGovernor {
        require(address(authority.treasury()) != address(treasury), "TREASURY HAS NOT CHANGED");
        treasury = ITreasury(
            address(authority.treasury())
        );
    }

    /**
    * @notice allows governor to upgrade reward constant 
    * @param _constant new rewardConstant value
     */
    function setConstant(uint8 _constant) public onlyGovernor {
        rewardConstant = _constant;
    }

    /**
     * @notice allows governor to update royalty percentage
     * @param _royaltyPercent new royalty percent
     * @dev only integer percent values accepted 
     */
    function setRoyalty(uint8 _royaltyPercent) public onlyGovernor {
        require(_royaltyPercent <= 10, "Cant exceed 10%");
        royaltyPercent = _royaltyPercent;
    }

    /**
     * @dev Helper function to extract a useful revert message from a failed call.
     *  If the returned data is malformed or not correctly abi encoded then this call can fail itself.
     *  https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringBatchable.sol
     */
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IERC20.sol";

interface IROIL is IERC20 {
    function mint(address account, uint256 amount_) external;

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

interface IERC20 {
    function symbol() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    // Note this is non standard but nearly all ERC20 have exposed decimal functions
    function decimals() external view returns (uint8);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    
    function burn(uint256 _amount) external;

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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