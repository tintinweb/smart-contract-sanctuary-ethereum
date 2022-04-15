// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;
import "./libraries/BoringOwnable.sol";

interface IBentoBox {
    function toAmount(address token, uint256 share, bool roundUp) external view returns (uint256 amount);
    function toShare(address token, uint256 amount, bool roundUp) external view returns (uint256 share);
    function balanceOf(address token, address owner) external view returns (uint256 share);
}

interface IMasterContract {
    function setFeeTo (address newFee) external;
    function reduceSupply (uint256 amount) external;
    function transferOwnership(address newOwner, bool direct, bool renounce) external;
    function bentoBox() external returns (IBentoBox);
} 

contract MasterContractOwner is BoringOwnable {
    event LogDepreciated(IMasterContract indexed cauldron);
    mapping (IMasterContract => bool) public isDepreciated;

    address public constant MIM = 0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3;

    function transferOwnershipOfMasterContract (IMasterContract mastercontract, address newOwner) external onlyOwner {
        mastercontract.transferOwnership(newOwner, true, false);
    }

    function setFeeTo (IMasterContract mastercontract, address feeTo) external onlyOwner {
        mastercontract.setFeeTo(feeTo);
    }

    function depreciate (IMasterContract cauldron, bool status) external onlyOwner {
        isDepreciated[cauldron] = status;
        emit LogDepreciated(cauldron);
    }

    function reduceCompletely(IMasterContract cauldron) external {
        require(isDepreciated[cauldron]);
        IBentoBox bentoBox = cauldron.bentoBox();
        uint256 amount = bentoBox.toAmount(MIM, bentoBox.balanceOf(MIM, address(cauldron)), false);
        cauldron.reduceSupply(amount);
    }

    function reduceSupply(IMasterContract cauldron, uint256 amount) external onlyOwner {
        cauldron.reduceSupply(amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

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