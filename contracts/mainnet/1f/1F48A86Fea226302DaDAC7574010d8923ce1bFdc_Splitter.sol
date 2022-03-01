// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {Reentrancy} from "../lib/Reentrancy.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);
}

/// @title Splitter
/// @author MirrorXYZ
/// @notice Building on the work from the Uniswap team at https://github.com/Uniswap/merkle-distributor
contract Splitter is Reentrancy {
    /// @notice The TransferETH event is emitted after each eth transfer in the split is attempted.
    /// @param account The account to which the transfer was attempted.
    /// @param amount The amount for transfer that was attempted.
    /// @param success Whether or not the transfer succeeded.
    event TransferETH(
        address account,
        uint256 amount,
        bool success
    );

    /// @notice Emits when a window is incremented
    /// @param currentWindow The current window
    /// @param fundsAvailable Funds available in the split
    event WindowIncremented(uint256 currentWindow, uint256 fundsAvailable);

    /// @notice Merkle root containing split distribution
    bytes32 public merkleRoot;

    /// @notice Current split window
    uint256 public currentWindow;

    /// @notice Wrapped ether address
    address internal wethAddress;

    /// @notice Balances in a specific window
    uint256[] public balanceForWindow;

    /// @notice Mapping of claimed users
    mapping(bytes32 => bool) internal claimed;

    /// @notice Deposited amount in current window
    uint256 public depositedInWindow;

    /// @notice Scale for percentage
    uint256 public constant PERCENTAGE_SCALE = 10e5;

    /// @notice Factory that deploys clones
    address public immutable factory;

    /// @notice Creates the Splitter
    /// @param factory_ SplitFactory address
    constructor(address factory_) {
        factory = factory_;
    }

    /// @notice Initializes the split
    /// @param wethAddress_ Wrapped ether address
    /// @param merkleRoot_ Generated merkle root for this split
    function initialize(address wethAddress_, bytes32 merkleRoot_)
        external
        returns (address)
    {
        require(msg.sender == factory, "unauthorized caller");

        wethAddress = wethAddress_;
        merkleRoot = merkleRoot_;

        return address(this);
    }

    /// @notice Allows to claim for all windows
    /// @param account Address that is claiming for all windows
    /// @param percentageAllocation Allocated percentage amount
    /// @param merkleProof Generated merkle proof
    function claimForAllWindows(
        address account,
        uint256 percentageAllocation,
        bytes32[] calldata merkleProof
    ) external nonReentrant {
        // Make sure that the user has this allocation granted.
        require(
            verifyProof(
                merkleProof,
                merkleRoot,
                getNode(account, percentageAllocation)
            ),
            "Invalid proof"
        );

        uint256 amount = 0;
        for (uint256 i = 0; i < currentWindow; i++) {
            if (!isClaimed(i, account)) {
                setClaimed(i, account);

                amount += scaleAmountByPercentage(
                    balanceForWindow[i],
                    percentageAllocation
                );
            }
        }

        transferETHOrWETH(account, amount);
    }

    /// @notice Gets node for a given account and allocation
    /// @param account Address to get node for
    /// @param percentageAllocation Allocated percentage
    function getNode(address account, uint256 percentageAllocation)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, percentageAllocation));
    }

    /// @notice Scales an amount by scaledPercent
    /// @param amount The amount
    /// @param scaledPercent The scaled percent
    function scaleAmountByPercentage(uint256 amount, uint256 scaledPercent)
        public
        pure
        returns (uint256 scaledAmount)
    {
        /*
            Example:
                If there is 100 ETH in the account, and someone has 
                an allocation of 2%, we call this with 100 as the amount, and 200
                as the scaled percent.

                To find out the amount we use, for example: (100 * 200) / (100 * 100)
                which returns 2 -- i.e. 2% of the 100 ETH balance.
         */
        scaledAmount = (amount * scaledPercent) / (100 * PERCENTAGE_SCALE);
    }

    /// @notice claim - claim funds from split
    /// @param  window The window to claim for
    /// @param  account Account that is claiming
    /// @param  scaledPercentageAllocation  The users percentage allocation
    /// @param  merkleProof Proof generated to claim funds
    function claim(
        uint256 window,
        address account,
        uint256 scaledPercentageAllocation,
        bytes32[] calldata merkleProof
    ) external nonReentrant {
        require(currentWindow > window, "cannot claim for a future window");
        require(
            !isClaimed(window, account),
            "Account already claimed the given window"
        );

        require(
            verifyProof(
                merkleProof,
                merkleRoot,
                getNode(account, scaledPercentageAllocation)
            ),
            "Invalid proof"
        );

        setClaimed(window, account);

        transferETHOrWETH(
            account,
            // The absolute amount that's claimable.
            scaleAmountByPercentage(
                balanceForWindow[window],
                scaledPercentageAllocation
            )
        );
    }

    /// @notice increments window
    function incrementWindow() public {
        require(depositedInWindow > 0, "No additional funds for window");

        balanceForWindow.push(depositedInWindow);

        emit WindowIncremented(currentWindow++, depositedInWindow);

        depositedInWindow = 0;
    }

    /// @notice checks if claimed
    /// @param window The window to check for
    /// @param account The account to check for
    function isClaimed(uint256 window, address account)
        public
        view
        returns (bool)
    {
        return claimed[getClaimHash(window, account)];
    }

    //======== Private Functions ========//

    /// @notice Sets an accounts claim status to true for a specific window
    /// @param window Window to set status for
    /// @param account Address to set status for
    function setClaimed(uint256 window, address account) private {
        claimed[getClaimHash(window, account)] = true;
    }

    /// @notice Retrieves claim hash for an account at a specific window
    /// @param window Window to get hash for
    /// @param account Address to get claim hash for
    function getClaimHash(uint256 window, address account)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(window, account));
    }

    /// @notice Will attempt to transfer ETH, but will transfer WETH instead if it fails.
    /// @param to Address to send ETH to
    /// @param value Amount of ETH to send
    function transferETHOrWETH(address to, uint256 value)
        private
        returns (bool didSucceed) 
    {
        // Try to transfer ETH to the given recipient.
        didSucceed = attemptETHTransfer(to, value);
        if (!didSucceed) {
            // If the transfer fails, wrap and send as WETH, so that
            // the auction is not impeded and the recipient still
            // can claim ETH via the WETH contract (similar to escrow).
            IWETH(wethAddress).deposit{value: value}();
            IWETH(wethAddress).transfer(to, value);
            // At this point, the recipient can unwrap WETH.
        }

        emit TransferETH(to, value, didSucceed);
    }

    /// @notice Attempts to transfer ETH
    /// @param to Address to send ETH to
    /// @param value Amount of ETH to send
    function attemptETHTransfer(address to, uint256 value)
        private
        returns (bool)
    {
        // Here increase the gas limit a reasonable amount above the default, and try
        // to send ETH to the recipient.
        // NOTE: This might allow the recipient to attempt a limited reentrancy attack.
        (bool success, ) = to.call{value: value, gas: 30000}("");
        return success;
    }

    // From https://github.com/protofire/zeppelin-solidity/blob/master/contracts/MerkleProof.sol
    function verifyProof(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) private pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }

    /// @notice Receive plain ETH transfers.
    receive() external payable {
        depositedInWindow += msg.value;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

contract Reentrancy {
    // ============ Constants ============

    uint256 internal constant REENTRANCY_NOT_ENTERED = 1;
    uint256 internal constant REENTRANCY_ENTERED = 2;

    // ============ Mutable Storage ============

    uint256 internal reentrancyStatus;

    // ============ Modifiers ============

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(reentrancyStatus != REENTRANCY_ENTERED, "Reentrant call");
        // Any calls to nonReentrant after this point will fail
        reentrancyStatus = REENTRANCY_ENTERED;
        _;
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip2200)
        reentrancyStatus = REENTRANCY_NOT_ENTERED;
    }
}