/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

pragma solidity >=0.8.4;

/// @notice Safe ETH and ERC-20 transfer library that gracefully handles missing return values
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// License-Identifier: AGPL-3.0-only
library SafeTransferLib {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error ETHtransferFailed();
    error TransferFailed();
    error TransferFromFailed();

    /// -----------------------------------------------------------------------
    /// ETH Logic
    /// -----------------------------------------------------------------------

    function _safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // transfer the ETH and store if it succeeded or not
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        if (!success) revert ETHtransferFailed();
    }

    /// -----------------------------------------------------------------------
    /// ERC-20 Logic
    /// -----------------------------------------------------------------------

    function _safeTransfer(
        address token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // get a pointer to some free memory
            let freeMemoryPointer := mload(0x40)
            // write the abi-encoded calldata into memory, beginning with the function selector
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // append the 'to' argument
            mstore(add(freeMemoryPointer, 36), amount) // append the 'amount' argument

            success := and(
                // set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // we use 68 because the length of our calldata totals up like so: 4 + 32 * 2
                // we use 0 and 32 to copy up to 32 bytes of return data into the scratch space
                // counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        if (!success) revert TransferFailed();
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // get a pointer to some free memory
            let freeMemoryPointer := mload(0x40)
            // write the abi-encoded calldata into memory, beginning with the function selector
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // append the 'from' argument
            mstore(add(freeMemoryPointer, 36), to) // append the 'to' argument
            mstore(add(freeMemoryPointer, 68), amount) // append the 'amount' argument

            success := and(
                // set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // we use 100 because the length of our calldata totals up like so: 4 + 32 * 3
                // we use 0 and 32 to copy up to 32 bytes of return data into the scratch space
                // counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        if (!success) revert TransferFromFailed();
    }
}

/// @notice Kali DAO access manager interface
interface IKaliAccessManager {
    function balanceOf(address account, uint256 id) external returns (uint256);

    function joinList(
        address account,
        uint256 id,
        bytes32[] calldata merkleProof
    ) external payable;
}

/// @notice Kali DAO share manager interface
interface IKaliShareManager {
    function mintShares(address to, uint256 amount) external payable;

    function burnShares(address from, uint256 amount) external payable;
}

/// @notice EIP-2612 interface
interface IERC20Permit {
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

/// @notice Single owner access control contract
abstract contract KaliOwnable {
    event OwnershipTransferred(address indexed from, address indexed to);
    event ClaimTransferred(address indexed from, address indexed to);

    error NotOwner();
    error NotPendingOwner();

    address public owner;
    address public pendingOwner;

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function _init(address owner_) internal {
        owner = owner_;
        emit OwnershipTransferred(address(0), owner_);
    }

    function claimOwner() external payable {
        if (msg.sender != pendingOwner) revert NotPendingOwner();

        emit OwnershipTransferred(owner, msg.sender);

        owner = msg.sender;
        delete pendingOwner;
    }

    function transferOwner(address to, bool direct) external payable onlyOwner {
        if (direct) {
            owner = to;
            emit OwnershipTransferred(msg.sender, to);
        } else {
            pendingOwner = to;
            emit ClaimTransferred(msg.sender, to);
        }
    }
}

/// @notice Helper utility that enables calling multiple local methods in a single call
/// @author Modified from Uniswap (https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol)
/// License-Identifier: GPL-2.0-or-later
abstract contract Multicall {
    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
        results = new bytes[](data.length);
        
        for (uint256 i; i < data.length; ) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                if (result.length < 68) revert();
                    
                assembly {
                    result := add(result, 0x04)
                }
                    
                revert(abi.decode(result, (string)));
            }

            results[i] = result;

            // cannot realistically overflow on human timescales
            unchecked {
                ++i;
            }
        }
    }
}

/// @notice Gas optimized reentrancy protection for smart contracts
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// License-Identifier: AGPL-3.0-only
abstract contract ReentrancyGuard {
    error Reentrancy();
    
    uint256 private locked = 1;

    modifier nonReentrant() {
        if (locked != 1) revert Reentrancy();
        
        locked = 2;
        _;
        locked = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

/// @notice EIP-2612 interface
interface IERC20permit {
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

/// @notice Crowdsale contract that receives ETH or ERC-20 to mint registered DAO tokens, including merkle access lists
contract KaliDAOcrowdsale is KaliOwnable, Multicall, ReentrancyGuard {
    /// -----------------------------------------------------------------------
    /// Library Usage
    /// -----------------------------------------------------------------------

    using SafeTransferLib for address;

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event ExtensionSet(
        address indexed dao,
        uint256 listId,
        uint256 purchaseMultiplier,
        address purchaseAsset,
        uint32 saleEnds,
        uint96 purchaseLimit,
        uint96 personalLimit,
        string details
    );
    event ExtensionCalled(
        address indexed dao,
        address indexed purchaser,
        uint256 amountOut,
        address[] indexed purchasers
    );
    event KaliRateSet(uint8 kaliRate);

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error NullMultiplier();
    error SaleEnded();
    error NotListed();
    error PurchaseLimit();
    error PersonalLimit();
    error RateLimit();

    /// -----------------------------------------------------------------------
    /// Sale Storage
    /// -----------------------------------------------------------------------

    uint8 public kaliRate;
    IKaliAccessManager private immutable accessManager;
    address private immutable wETH;

    mapping(address => Crowdsale) public crowdsales;

    struct Crowdsale {
        uint256 listId;
        uint256 purchaseMultiplier;
        address purchaseAsset;
        uint32 saleEnds;
        uint96 purchaseLimit;
        uint96 personalLimit;
        uint256 purchaseTotal;
        string details;
        mapping(address => uint256) personalPurchased;
        address[] purchasers;
    }

    function checkPersonalPurchased(address account, address dao)
        external
        view
        returns (uint256)
    {
        return crowdsales[dao].personalPurchased[account];
    }

    function checkPurchasers(address dao)
        external
        view
        returns (address[] memory)
    {
        return crowdsales[dao].purchasers;
    }

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(IKaliAccessManager accessManager_, address wETH_) {
        accessManager = accessManager_;
        KaliOwnable._init(msg.sender);
        wETH = wETH_;
    }

    /// -----------------------------------------------------------------------
    /// Multicall Utilities
    /// -----------------------------------------------------------------------

    function joinList(uint256 id, bytes32[] calldata merkleProof)
        external
        payable
    {
        accessManager.joinList(msg.sender, id, merkleProof);
    }

    function setPermit(
        IERC20permit token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        token.permit(msg.sender, address(this), value, deadline, v, r, s);
    }

    /// -----------------------------------------------------------------------
    /// Sale Settings
    /// -----------------------------------------------------------------------

    function setExtension(bytes calldata extensionData) external payable {
        (
            uint256 listId,
            uint256 purchaseMultiplier,
            address purchaseAsset,
            uint32 saleEnds,
            uint96 purchaseLimit,
            uint96 personalLimit,
            string memory details
        ) = abi.decode(
                extensionData,
                (uint256, uint256, address, uint32, uint96, uint96, string)
            );

        if (purchaseMultiplier == 0) revert NullMultiplier();

        // caller is stored as `dao` target for sale
        Crowdsale storage sale = crowdsales[msg.sender];

        uint256 count = sale.purchasers.length;
        for (uint256 i; i < count; ) {
            sale.personalPurchased[sale.purchasers[i]] = 0;

            unchecked {
                i++;
            }
        }
        delete sale.purchasers;

        // we use this format as we have nested mapping
        sale.listId = listId;
        sale.purchaseMultiplier = purchaseMultiplier;
        sale.purchaseAsset = purchaseAsset;
        sale.saleEnds = saleEnds;
        sale.purchaseLimit = purchaseLimit;
        sale.personalLimit = personalLimit;
        sale.details = details;
        sale.purchaseTotal = 0;

        emit ExtensionSet(
            msg.sender,
            listId,
            purchaseMultiplier,
            purchaseAsset,
            saleEnds,
            purchaseLimit,
            personalLimit,
            details
        );
    }

    /// -----------------------------------------------------------------------
    /// Sale Logic
    /// -----------------------------------------------------------------------

    function callExtension(address dao, uint256 amount)
        external
        payable
        nonReentrant
        returns (uint256 amountOut)
    {
        Crowdsale storage sale = crowdsales[dao];

        if (block.timestamp > sale.saleEnds) revert SaleEnded();

        if (sale.listId != 0)
            if (accessManager.balanceOf(msg.sender, sale.listId) == 0)
                revert NotListed();

        uint256 total;
        uint256 payment;

        if (
            sale.purchaseAsset == address(0) ||
            sale.purchaseAsset == address(0xDead)
        ) {
            total = msg.value;
        } else {
            total = amount;
        }

        if (kaliRate != 0) {
            uint256 fee = (total * kaliRate) / 100;
            // cannot underflow since fee will be less than total
            unchecked {
                payment = total - fee;
            }
        } else {
            payment = total;
        }

        amountOut = total * sale.purchaseMultiplier;

        if (sale.purchaseTotal + amountOut > sale.purchaseLimit)
            revert PurchaseLimit();
        if (sale.personalPurchased[msg.sender] + amountOut > sale.personalLimit)
            revert PersonalLimit();

        if (sale.purchaseAsset == address(0)) {
            // send ETH to DAO
            dao._safeTransferETH(payment);
        } else if (sale.purchaseAsset == address(0xDead)) {
            // send ETH to wETH
            wETH._safeTransferETH(payment);
            // send wETH to DAO
            wETH._safeTransfer(dao, payment);
        } else {
            // send tokens to DAO
            sale.purchaseAsset._safeTransferFrom(msg.sender, dao, payment);
        }

        sale.purchasers.push(msg.sender);

        unchecked {
            sale.purchaseTotal += amountOut;
            sale.personalPurchased[msg.sender] += amountOut;
        }

        IKaliShareManager(dao).mintShares(msg.sender, amountOut);

        emit ExtensionCalled(dao, msg.sender, amountOut, sale.purchasers);
    }

    /// -----------------------------------------------------------------------
    /// Sale Management
    /// -----------------------------------------------------------------------

    function setKaliRate(uint8 kaliRate_) external payable onlyOwner {
        if (kaliRate_ > 100) revert RateLimit();
        kaliRate = kaliRate_;
        emit KaliRateSet(kaliRate_);
    }

    function claimKaliFees(
        address to,
        address asset,
        uint256 amount
    ) external payable onlyOwner {
        if (asset == address(0)) {
            to._safeTransferETH(amount);
        } else {
            asset._safeTransfer(to, amount);
        }
    }
}