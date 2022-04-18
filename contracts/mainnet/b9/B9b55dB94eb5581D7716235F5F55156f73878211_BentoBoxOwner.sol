// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "./libraries/BoringOwnable.sol";

interface IBentoBox {
    function toAmount(address token, uint256 share, bool roundUp) external view returns (uint256 amount);
    function toShare(address token, uint256 amount, bool roundUp) external view returns (uint256 share);
    function balanceOf(address token, address owner) external view returns (uint256 share);
    function setStrategy(address token, address newStrategy) external;
    function setStrategyTargetPercentage(address token, uint64 targetPercentage_) external;
    function whitelistMasterContract(address masterContract, bool approved) external;
}

contract BentoBoxOwner is BoringOwnable {
    event LogAbraOwned (address indexed token, bool status);
    event LogAbraOwnerTransferred (address indexed oldOwner, address indexed newOwner);
    mapping (address => bool) public isAbraOwned;

    address public abraOwner;

    address public constant MIM_OPS = 0xDF2C270f610Dc35d8fFDA5B453E74db5471E126B;
    address public constant SUSHI_OPS = 0x19B3Eb3Af5D93b77a5619b047De0EED7115A19e7;

    IBentoBox private constant bentoBox = IBentoBox(0xF5BCE5077908a1b7370B9ae04AdC565EBd643966);

    constructor () {
        abraOwner = MIM_OPS;
        emit LogAbraOwnerTransferred(address(0), MIM_OPS);
        owner = SUSHI_OPS;

        address[15] memory ABRA_COINS = 
        [
            0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3, 
            0x4E15361FD6b4BB609Fa63C81A2be19d873717870, 
            0x27b7b1ad7288079A66d12350c828D3C00A6F07d7, 
            0xdCD90C7f6324cfa40d7169ef80b12031770B4325,
            0x5f18C75AbDAe578b483E5F43f12a39cF75b973a9,
            0x7Da96a3891Add058AdA2E826306D812C638D87a7,
            0xa258C4606Ca8206D8aA700cE2143D7db854D168c,
            0x5958A8DB7dfE0CC49382209069b00F54e17929C2,
            0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE,
            0xB65eDE134521F0EFD4E943c835F450137dC6E83e,
            0x50D1c9771902476076eCFc8B2A83Ad6b9355a4c9,
            0x090185f2135308BaD17527004364eBcC2D37e5F6,
            0x26FA3fFFB6EfE8c1E69103aCb4044C26B9A106a9,
            0x3Ba207c25A278524e1cC7FaAea950753049072A4,
            0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF
        ];

        uint256 length = ABRA_COINS.length;

        for (uint i; i < length; i++) {
            isAbraOwned[ABRA_COINS[i]] = true;
            emit LogAbraOwned(ABRA_COINS[i], true);
        }
    }

    modifier onlyAbra {
        require(msg.sender == abraOwner, "NOT ABRA");
        _;
    }

    function transferAbraOwner(address newOwner) external onlyAbra {
        address oldOwner = abraOwner;
        abraOwner = newOwner;
        emit LogAbraOwnerTransferred(oldOwner, newOwner);
    }

    function setStrategyAbraCoin(address token, address newStrategy) external onlyAbra {
        require(isAbraOwned[token], "Not Owned by Abra");
        bentoBox.setStrategy(token, newStrategy);
    }

    function setStrategyTargetPercentageAbraCoin(address token, uint64 targetPercentage) external onlyAbra {
        require(isAbraOwned[token], "Not Owned by Abra");
        bentoBox.setStrategyTargetPercentage(token, targetPercentage);
    }

    function relinquishToken(address token) external onlyAbra {
        isAbraOwned[token] = false;
        emit LogAbraOwned(token, false);
    }

    function handOverControl(address token) external onlyOwner {
        isAbraOwned[token] = true;
        emit LogAbraOwned(token, true);
    }

    function setStrategy(address token, address newStrategy) external onlyOwner {
        require(!isAbraOwned[token], "Token Owned by Abra");
        bentoBox.setStrategy(token, newStrategy);
    }

    function setStrategyTargetPercentage(address token, uint64 targetPercentage) external onlyOwner {
        require(!isAbraOwned[token], "Token Owned by Abra"); 
        bentoBox.setStrategyTargetPercentage(token, targetPercentage);
    }

    function whitelistMasterContract(address masterContract, bool approved) external onlyOwner {
        bentoBox.whitelistMasterContract(masterContract, approved);
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