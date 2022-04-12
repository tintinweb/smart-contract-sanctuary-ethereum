pragma solidity 0.8.10;

interface ICauldron {
    function collateral() external returns (IYearn);
}

interface IYearn {
    function pricePerShare() external returns (uint256);
}

// Audit on 5-Jan-2021 by Keno and BoringCrypto
// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

contract YearnCauldrons is BoringOwnable {
    // Returns All Cauldrons With Collateral in Yearn Vaults
    ICauldron[] public yearnCauldrons;

    event LogCauldronAdded(ICauldron indexed cauldron);

    constructor () {
    }

    function addCauldrons(ICauldron[] calldata cauldrons) external onlyOwner {
        uint256 length = yearnCauldrons.length;
        for(uint256 i=0; i < cauldrons.length; i++) {
            require(address(cauldrons[i]) != address(0), "invalid cauldron");
            require(cauldrons[i].collateral().pricePerShare() != 0, "invalid pricePerShare");
            for (uint256 j = 0; j < length; j++) {
                require(yearnCauldrons[j] != cauldrons[i], "already added");
            }
            yearnCauldrons.push(cauldrons[i]);
            emit LogCauldronAdded(cauldrons[i]);
        }
    }

    function addCauldronsInsecure(ICauldron[] calldata cauldrons) external onlyOwner {
        for(uint256 i=0; i < cauldrons.length; i++) {
            yearnCauldrons.push(cauldrons[i]);
            emit LogCauldronAdded(cauldrons[i]);
        }
    }
}