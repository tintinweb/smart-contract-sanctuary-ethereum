// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./util/PausableUpgradeable.sol";
import "./util/SafeERC20Upgradeable.sol";
import "./util/Create2.sol";
import "./proxy/UpgradeableBeacon.sol";
import "./proxy/Create2BeaconProxy.sol";
import "./token/XTokenUpgradeable.sol";
import "./interface/INFTXInventoryStaking.sol";
import "./interface/INFTXVaultFactory.sol";
import "./interface/ITimelockExcludeList.sol";

// Author: 0xKiwi.

// Pausing codes for inventory staking are:
// 10: Deposit

contract NFTXInventoryStaking is
    PausableUpgradeable,
    UpgradeableBeacon,
    INFTXInventoryStaking
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Small locktime to prevent flash deposits.
    uint256 internal constant DEFAULT_LOCKTIME = 2;
    // bytes internal constant beaconCode = type(Create2BeaconProxy).creationCode;
    bytes internal constant beaconCode =
        hex"608060405261002f60017fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d51610451565b6000805160206107cf8339815191521461005957634e487b7160e01b600052600160045260246000fd5b610078336040518060200160405280600081525061007d60201b60201c565b6104a0565b6100908261023860201b6100291760201c565b6100ef5760405162461bcd60e51b815260206004820152602560248201527f426561636f6e50726f78793a20626561636f6e206973206e6f74206120636f6e6044820152641d1c9858dd60da1b60648201526084015b60405180910390fd5b610172826001600160a01b031663da5257166040518163ffffffff1660e01b815260040160206040518083038186803b15801561012b57600080fd5b505afa15801561013f573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061016391906103db565b61023860201b6100291760201c565b6101e45760405162461bcd60e51b815260206004820152603460248201527f426561636f6e50726f78793a20626561636f6e20696d706c656d656e7461746960448201527f6f6e206973206e6f74206120636f6e747261637400000000000000000000000060648201526084016100e6565b6000805160206107cf8339815191528281558151156102335761023161020861023e565b836040518060600160405280602181526020016107ef602191396102cb60201b61002f1760201c565b505b505050565b3b151590565b60006102566000805160206107cf8339815191525490565b6001600160a01b031663da5257166040518163ffffffff1660e01b815260040160206040518083038186803b15801561028e57600080fd5b505afa1580156102a2573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906102c691906103db565b905090565b6060833b61032a5760405162461bcd60e51b815260206004820152602660248201527f416464726573733a2064656c65676174652063616c6c20746f206e6f6e2d636f6044820152651b9d1c9858dd60d21b60648201526084016100e6565b600080856001600160a01b0316856040516103459190610402565b600060405180830381855af49150503d8060008114610380576040519150601f19603f3d011682016040523d82523d6000602084013e610385565b606091505b5090925090506103968282866103a2565b925050505b9392505050565b606083156103b157508161039b565b8251156103c15782518084602001fd5b8160405162461bcd60e51b81526004016100e6919061041e565b6000602082840312156103ec578081fd5b81516001600160a01b038116811461039b578182fd5b60008251610414818460208701610474565b9190910192915050565b602081526000825180602084015261043d816040850160208701610474565b601f01601f19169190910160400192915050565b60008282101561046f57634e487b7160e01b81526011600452602481fd5b500390565b60005b8381101561048f578181015183820152602001610477565b838111156102315750506000910152565b610320806104af6000396000f3fe60806040523661001357610011610017565b005b6100115b61002761002261012e565b6101da565b565b3b151590565b6060833b6100aa5760405162461bcd60e51b815260206004820152602660248201527f416464726573733a2064656c65676174652063616c6c20746f206e6f6e2d636f60448201527f6e7472616374000000000000000000000000000000000000000000000000000060648201526084015b60405180910390fd5b6000808573ffffffffffffffffffffffffffffffffffffffff16856040516100d2919061026b565b600060405180830381855af49150503d806000811461010d576040519150601f19603f3d011682016040523d82523d6000602084013e610112565b606091505b50915091506101228282866101fe565b925050505b9392505050565b60006101587fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d505490565b73ffffffffffffffffffffffffffffffffffffffff1663da5257166040518163ffffffff1660e01b815260040160206040518083038186803b15801561019d57600080fd5b505afa1580156101b1573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906101d59190610237565b905090565b3660008037600080366000845af43d6000803e8080156101f9573d6000f35b3d6000fd5b6060831561020d575081610127565b82511561021d5782518084602001fd5b8160405162461bcd60e51b81526004016100a19190610287565b600060208284031215610248578081fd5b815173ffffffffffffffffffffffffffffffffffffffff81168114610127578182fd5b6000825161027d8184602087016102ba565b9190910192915050565b60208152600082518060208401526102a68160408501602087016102ba565b601f01601f19169190910160400192915050565b60005b838110156102d55781810151838201526020016102bd565b838111156102e4576000848401525b5050505056fea2646970667358221220186f38c9868951054a26d8e78dfc388c93ba31dab42cd0982029e5f5f85fc42164736f6c63430008040033a3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50426561636f6e50726f78793a2066756e6374696f6e2063616c6c206661696c6564";
    // this code is used to determine xToken address while calling `directWithdraw()`
    bytes internal constant duplicateBeaconCode =
        hex"608060405261002f60017fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d51610451565b6000805160206107cf8339815191521461005957634e487b7160e01b600052600160045260246000fd5b610078336040518060200160405280600081525061007d60201b60201c565b6104a0565b6100908261023860201b6100291760201c565b6100ef5760405162461bcd60e51b815260206004820152602560248201527f426561636f6e50726f78793a20626561636f6e206973206e6f74206120636f6e6044820152641d1c9858dd60da1b60648201526084015b60405180910390fd5b610172826001600160a01b031663da5257166040518163ffffffff1660e01b815260040160206040518083038186803b15801561012b57600080fd5b505afa15801561013f573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061016391906103db565b61023860201b6100291760201c565b6101e45760405162461bcd60e51b815260206004820152603460248201527f426561636f6e50726f78793a20626561636f6e20696d706c656d656e7461746960448201527f6f6e206973206e6f74206120636f6e747261637400000000000000000000000060648201526084016100e6565b6000805160206107cf8339815191528281558151156102335761023161020861023e565b836040518060600160405280602181526020016107ef602191396102cb60201b61002f1760201c565b505b505050565b3b151590565b60006102566000805160206107cf8339815191525490565b6001600160a01b031663da5257166040518163ffffffff1660e01b815260040160206040518083038186803b15801561028e57600080fd5b505afa1580156102a2573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906102c691906103db565b905090565b6060833b61032a5760405162461bcd60e51b815260206004820152602660248201527f416464726573733a2064656c65676174652063616c6c20746f206e6f6e2d636f6044820152651b9d1c9858dd60d21b60648201526084016100e6565b600080856001600160a01b0316856040516103459190610402565b600060405180830381855af49150503d8060008114610380576040519150601f19603f3d011682016040523d82523d6000602084013e610385565b606091505b5090925090506103968282866103a2565b925050505b9392505050565b606083156103b157508161039b565b8251156103c15782518084602001fd5b8160405162461bcd60e51b81526004016100e6919061041e565b6000602082840312156103ec578081fd5b81516001600160a01b038116811461039b578182fd5b60008251610414818460208701610474565b9190910192915050565b602081526000825180602084015261043d816040850160208701610474565b601f01601f19169190910160400192915050565b60008282101561046f57634e487b7160e01b81526011600452602481fd5b500390565b60005b8381101561048f578181015183820152602001610477565b838111156102315750506000910152565b610320806104af6000396000f3fe60806040523661001357610011610017565b005b6100115b61002761002261012e565b6101da565b565b3b151590565b6060833b6100aa5760405162461bcd60e51b815260206004820152602660248201527f416464726573733a2064656c65676174652063616c6c20746f206e6f6e2d636f60448201527f6e7472616374000000000000000000000000000000000000000000000000000060648201526084015b60405180910390fd5b6000808573ffffffffffffffffffffffffffffffffffffffff16856040516100d2919061026b565b600060405180830381855af49150503d806000811461010d576040519150601f19603f3d011682016040523d82523d6000602084013e610112565b606091505b50915091506101228282866101fe565b925050505b9392505050565b60006101587fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d505490565b73ffffffffffffffffffffffffffffffffffffffff1663da5257166040518163ffffffff1660e01b815260040160206040518083038186803b15801561019d57600080fd5b505afa1580156101b1573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906101d59190610237565b905090565b3660008037600080366000845af43d6000803e8080156101f9573d6000f35b3d6000fd5b6060831561020d575081610127565b82511561021d5782518084602001fd5b8160405162461bcd60e51b81526004016100a19190610287565b600060208284031215610248578081fd5b815173ffffffffffffffffffffffffffffffffffffffff81168114610127578182fd5b6000825161027d8184602087016102ba565b9190910192915050565b60208152600082518060208401526102a68160408501602087016102ba565b601f01601f19169190910160400192915050565b60005b838110156102d55781810151838201526020016102bd565b838111156102e4576000848401525b5050505056fea26469706673582212207fa982cc2707bb3e77c4aa1e243fbbca2a5b4869b87391cdd12e6a56d1e36e9164736f6c63430008040033a3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50426561636f6e50726f78793a2066756e6374696f6e2063616c6c206661696c6564";

    INFTXVaultFactory public override nftxVaultFactory;

    uint256 public inventoryLockTimeErc20;
    ITimelockExcludeList public timelockExcludeList;

    event XTokenCreated(uint256 vaultId, address baseToken, address xToken);
    event Deposit(
        uint256 vaultId,
        uint256 baseTokenAmount,
        uint256 xTokenAmount,
        uint256 timelockUntil,
        address sender
    );
    event Withdraw(
        uint256 vaultId,
        uint256 baseTokenAmount,
        uint256 xTokenAmount,
        address sender
    );
    event DirectWithdraw(
        address xToken,
        uint256 baseTokenAmount,
        uint256 xTokenAmount,
        address sender
    );
    event FeesReceived(uint256 vaultId, uint256 amount);

    function __NFTXInventoryStaking_init(address _nftxVaultFactory)
        external
        virtual
        override
        initializer
    {
        __Ownable_init();
        nftxVaultFactory = INFTXVaultFactory(_nftxVaultFactory);
        address xTokenImpl = address(new XTokenUpgradeable());
        __UpgradeableBeacon__init(xTokenImpl);
    }

    modifier onlyAdmin() {
        require(
            msg.sender == owner() ||
                msg.sender == nftxVaultFactory.feeDistributor(),
            "LPStaking: Not authorized"
        );
        _;
    }

    function setTimelockExcludeList(address addr) external onlyOwner {
        timelockExcludeList = ITimelockExcludeList(addr);
    }

    function setInventoryLockTimeErc20(uint256 time) external onlyOwner {
        require(time <= 14 days, "Lock too long");
        inventoryLockTimeErc20 = time;
    }

    function isAddressTimelockExcluded(address addr, uint256 vaultId)
        public
        view
        returns (bool)
    {
        if (address(timelockExcludeList) == address(0)) {
            return false;
        } else {
            return timelockExcludeList.isExcluded(addr, vaultId);
        }
    }

    function deployXTokenForVault(uint256 vaultId) public virtual override {
        address baseToken = nftxVaultFactory.vault(vaultId);
        address deployedXToken = xTokenAddr(address(baseToken));

        if (isContract(deployedXToken)) {
            return;
        }

        address xToken = _deployXToken(baseToken);
        emit XTokenCreated(vaultId, baseToken, xToken);
    }

    function receiveRewards(uint256 vaultId, uint256 amount)
        external
        virtual
        override
        onlyAdmin
        returns (bool)
    {
        address baseToken = nftxVaultFactory.vault(vaultId);
        address deployedXToken = xTokenAddr(address(baseToken));

        // Don't distribute rewards unless there are people to distribute to.
        // Also added here if the distribution token is not deployed, just forfeit rewards for now.
        if (
            !isContract(deployedXToken) ||
            XTokenUpgradeable(deployedXToken).totalSupply() == 0
        ) {
            return false;
        }
        // We "pull" to the dividend tokens so the fee distributor only needs to approve this contract.
        IERC20Upgradeable(baseToken).safeTransferFrom(
            msg.sender,
            deployedXToken,
            amount
        );
        emit FeesReceived(vaultId, amount);
        return true;
    }

    // Enter staking. Staking, get minted shares and
    // locks base tokens and mints xTokens.
    function deposit(uint256 vaultId, uint256 _amount)
        external
        virtual
        override
    {
        onlyOwnerIfPaused(10);

        uint256 timelockTime = isAddressTimelockExcluded(msg.sender, vaultId)
            ? 0
            : inventoryLockTimeErc20;

        (
            IERC20Upgradeable baseToken,
            XTokenUpgradeable xToken,
            uint256 xTokensMinted
        ) = _timelockMintFor(vaultId, msg.sender, _amount, timelockTime);
        // Lock the base token in the xtoken contract
        baseToken.safeTransferFrom(msg.sender, address(xToken), _amount);
        emit Deposit(vaultId, _amount, xTokensMinted, timelockTime, msg.sender);
    }

    function timelockMintFor(
        uint256 vaultId,
        uint256 amount,
        address to,
        uint256 timelockLength
    ) external virtual override returns (uint256) {
        onlyOwnerIfPaused(10);
        require(nftxVaultFactory.zapContracts(msg.sender), "Not staking zap");
        require(
            nftxVaultFactory.excludedFromFees(msg.sender),
            "Not fee excluded"
        );

        (, , uint256 xTokensMinted) = _timelockMintFor(
            vaultId,
            to,
            amount,
            timelockLength
        );
        emit Deposit(vaultId, amount, xTokensMinted, timelockLength, to);
        return xTokensMinted;
    }

    // Leave the bar. Claim back your tokens.
    // Unlocks the staked + gained tokens and burns xTokens.
    function withdraw(uint256 vaultId, uint256 _share)
        external
        virtual
        override
    {
        IERC20Upgradeable baseToken = IERC20Upgradeable(
            nftxVaultFactory.vault(vaultId)
        );
        XTokenUpgradeable xToken = XTokenUpgradeable(
            xTokenAddr(address(baseToken))
        );

        uint256 baseTokensRedeemed = xToken.burnXTokens(msg.sender, _share);
        emit Withdraw(vaultId, baseTokensRedeemed, _share, msg.sender);
    }

    function directWithdraw(uint256 vaultId, uint256 _share) external {
        IERC20Upgradeable baseToken = IERC20Upgradeable(
            nftxVaultFactory.vault(vaultId)
        );
        bytes32 salt = keccak256(abi.encodePacked(baseToken));
        address xToken = Create2.computeAddress(
            salt,
            keccak256(duplicateBeaconCode)
        );
        uint256 baseTokensRedeemed = XTokenUpgradeable(xToken).burnXTokens(
            msg.sender,
            _share
        );

        emit DirectWithdraw(xToken, baseTokensRedeemed, _share, msg.sender);
    }

    function xTokenShareValue(uint256 vaultId)
        external
        view
        virtual
        override
        returns (uint256)
    {
        IERC20Upgradeable baseToken = IERC20Upgradeable(
            nftxVaultFactory.vault(vaultId)
        );
        XTokenUpgradeable xToken = XTokenUpgradeable(
            xTokenAddr(address(baseToken))
        );
        require(address(xToken) != address(0), "XToken not deployed");

        uint256 multiplier = 10**18;
        return
            xToken.totalSupply() > 0
                ? (multiplier * baseToken.balanceOf(address(xToken))) /
                    xToken.totalSupply()
                : multiplier;
    }

    function timelockUntil(uint256 vaultId, address who)
        external
        view
        returns (uint256)
    {
        XTokenUpgradeable xToken = XTokenUpgradeable(vaultXToken(vaultId));
        return xToken.timelockUntil(who);
    }

    function balanceOf(uint256 vaultId, address who)
        external
        view
        returns (uint256)
    {
        XTokenUpgradeable xToken = XTokenUpgradeable(vaultXToken(vaultId));
        return xToken.balanceOf(who);
    }

    // Note: this function does not guarantee the token is deployed, we leave that check to elsewhere to save gas.
    function xTokenAddr(address baseToken)
        public
        view
        virtual
        override
        returns (address)
    {
        bytes32 salt = keccak256(abi.encodePacked(baseToken));
        address tokenAddr = Create2.computeAddress(salt, keccak256(beaconCode));
        return tokenAddr;
    }

    function vaultXToken(uint256 vaultId)
        public
        view
        virtual
        override
        returns (address)
    {
        address baseToken = nftxVaultFactory.vault(vaultId);
        address xToken = xTokenAddr(baseToken);
        require(isContract(xToken), "XToken not deployed");
        return xToken;
    }

    function _timelockMintFor(
        uint256 vaultId,
        address account,
        uint256 _amount,
        uint256 timelockLength
    )
        internal
        returns (
            IERC20Upgradeable,
            XTokenUpgradeable,
            uint256
        )
    {
        deployXTokenForVault(vaultId);
        IERC20Upgradeable baseToken = IERC20Upgradeable(
            nftxVaultFactory.vault(vaultId)
        );
        XTokenUpgradeable xToken = XTokenUpgradeable(
            (xTokenAddr(address(baseToken)))
        );

        uint256 xTokensMinted = xToken.mintXTokens(
            account,
            _amount,
            timelockLength
        );
        return (baseToken, xToken, xTokensMinted);
    }

    function _deployXToken(address baseToken) internal returns (address) {
        string memory symbol = IERC20Metadata(baseToken).symbol();
        symbol = string(abi.encodePacked("x", symbol));
        bytes32 salt = keccak256(abi.encodePacked(baseToken));
        address deployedXToken = Create2.deploy(0, salt, beaconCode);
        XTokenUpgradeable(deployedXToken).__XToken_init(
            baseToken,
            symbol,
            symbol
        );
        return deployedXToken;
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size != 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./INFTXVaultFactory.sol";

interface INFTXInventoryStaking {
    function nftxVaultFactory() external view returns (INFTXVaultFactory);

    function vaultXToken(uint256 vaultId) external view returns (address);

    function xTokenAddr(address baseToken) external view returns (address);

    function xTokenShareValue(uint256 vaultId) external view returns (uint256);

    function __NFTXInventoryStaking_init(address nftxFactory) external;

    function deployXTokenForVault(uint256 vaultId) external;

    function receiveRewards(uint256 vaultId, uint256 amount)
        external
        returns (bool);

    function timelockMintFor(
        uint256 vaultId,
        uint256 amount,
        address to,
        uint256 timelockLength
    ) external returns (uint256);

    function deposit(uint256 vaultId, uint256 _amount) external;

    function withdraw(uint256 vaultId, uint256 _share) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../proxy/IBeacon.sol";

interface INFTXVaultFactory is IBeacon {
    // Read functions.
    function numVaults() external view returns (uint256);

    function zapContract() external view returns (address);

    function zapContracts(address addr) external view returns (bool);

    function feeDistributor() external view returns (address);

    function eligibilityManager() external view returns (address);

    function vault(uint256 vaultId) external view returns (address);

    function allVaults() external view returns (address[] memory);

    function vaultsForAsset(address asset)
        external
        view
        returns (address[] memory);

    function isLocked(uint256 id) external view returns (bool);

    function excludedFromFees(address addr) external view returns (bool);

    function factoryMintFee() external view returns (uint64);

    function factoryRandomRedeemFee() external view returns (uint64);

    function factoryTargetRedeemFee() external view returns (uint64);

    function factoryRandomSwapFee() external view returns (uint64);

    function factoryTargetSwapFee() external view returns (uint64);

    function vaultFees(uint256 vaultId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    event NewFeeDistributor(address oldDistributor, address newDistributor);
    event NewZapContract(address oldZap, address newZap);
    event UpdatedZapContract(address zap, bool excluded);
    event FeeExclusion(address feeExcluded, bool excluded);
    event NewEligibilityManager(address oldEligManager, address newEligManager);
    event NewVault(
        uint256 indexed vaultId,
        address vaultAddress,
        address assetAddress
    );
    event UpdateVaultFees(
        uint256 vaultId,
        uint256 mintFee,
        uint256 randomRedeemFee,
        uint256 targetRedeemFee,
        uint256 randomSwapFee,
        uint256 targetSwapFee
    );
    event DisableVaultFees(uint256 vaultId);
    event UpdateFactoryFees(
        uint256 mintFee,
        uint256 randomRedeemFee,
        uint256 targetRedeemFee,
        uint256 randomSwapFee,
        uint256 targetSwapFee
    );

    // Write functions.
    function __NFTXVaultFactory_init(
        address _vaultImpl,
        address _feeDistributor
    ) external;

    function createVault(
        string calldata name,
        string calldata symbol,
        address _assetAddress,
        bool is1155,
        bool allowAllItems
    ) external returns (uint256);

    function setFeeDistributor(address _feeDistributor) external;

    function setEligibilityManager(address _eligibilityManager) external;

    function setZapContract(address _zapContract, bool _excluded) external;

    function setFeeExclusion(address _excludedAddr, bool excluded) external;

    function setFactoryFees(
        uint256 mintFee,
        uint256 randomRedeemFee,
        uint256 targetRedeemFee,
        uint256 randomSwapFee,
        uint256 targetSwapFee
    ) external;

    function setVaultFees(
        uint256 vaultId,
        uint256 mintFee,
        uint256 randomRedeemFee,
        uint256 targetRedeemFee,
        uint256 randomSwapFee,
        uint256 targetSwapFee
    ) external;

    function disableVaultFees(uint256 vaultId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITimelockExcludeList {
    function isExcluded(address addr, uint256 vaultId)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../util/Address.sol";
import "./Proxy.sol";
import "./IBeacon.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from a {UpgradeableBeacon}.
 * Slightly modified to allow using beacon proxies with Create2.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract Create2BeaconProxy is Proxy {
    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 private constant _BEACON_SLOT =
        0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializating the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor() payable {
        assert(
            _BEACON_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1)
        );
        _setBeacon(msg.sender, "");
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address beacon) {
        bytes32 slot = _BEACON_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            beacon := sload(slot)
        }
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation()
        internal
        view
        virtual
        override
        returns (address)
    {
        return IBeacon(_beacon()).childImplementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        require(
            Address.isContract(beacon),
            "BeaconProxy: beacon is not a contract"
        );
        require(
            Address.isContract(IBeacon(beacon).childImplementation()),
            "BeaconProxy: beacon implementation is not a contract"
        );
        bytes32 slot = _BEACON_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, beacon)
        }

        if (data.length > 0) {
            Address.functionDelegateCall(
                _implementation(),
                data,
                "BeaconProxy: function call failed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function childImplementation() external view returns (address);

    function upgradeChildTo(address newImplementation) external;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(
            _initializing || !_initialized,
            "Initializable: contract is already initialized"
        );

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../util/Address.sol";
import "../util/OwnableUpgradeable.sol";

/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeacon is IBeacon, OwnableUpgradeable {
    address private _childImplementation;

    /**
     * @dev Emitted when the child implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed childImplementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    function __UpgradeableBeacon__init(address childImplementation_)
        public
        initializer
    {
        _setChildImplementation(childImplementation_);
    }

    /**
     * @dev Returns the current child implementation address.
     */
    function childImplementation()
        public
        view
        virtual
        override
        returns (address)
    {
        return _childImplementation;
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newChildImplementation` must be a contract.
     */
    function upgradeChildTo(address newChildImplementation)
        public
        virtual
        override
        onlyOwner
    {
        _setChildImplementation(newChildImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newChildImplementation` must be a contract.
     */
    function _setChildImplementation(address newChildImplementation) private {
        require(
            Address.isContract(newChildImplementation),
            "UpgradeableBeacon: child implementation is not a contract"
        );
        _childImplementation = newChildImplementation;
        emit Upgraded(newChildImplementation);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../proxy/Initializable.sol";
import "../util/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IERC20Metadata.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is
    Initializable,
    ContextUpgradeable,
    IERC20Upgradeable,
    IERC20Metadata
{
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_)
        internal
        initializer
    {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_)
        internal
        initializer
    {
        _name = name_;
        _symbol = symbol_;
    }

    function _setMetadata(string memory name_, string memory symbol_) internal {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../util/OwnableUpgradeable.sol";
import "../util/SafeERC20Upgradeable.sol";
import "../token/ERC20Upgradeable.sol";

// XTokens let uou come in with some vault tokens, and leave with more! The longer you stay, the more vault tokens you get.
//
// This contract handles swapping to and from xSushi, SushiSwap's staking token.
contract XTokenUpgradeable is OwnableUpgradeable, ERC20Upgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 internal constant MAX_TIMELOCK = 2592000;
    IERC20Upgradeable public baseToken;

    mapping(address => uint256) internal timelock;

    event Timelocked(address user, uint256 until);

    function __XToken_init(
        address _baseToken,
        string memory name,
        string memory symbol
    ) public initializer {
        __Ownable_init();
        // string memory _name = INFTXInventoryStaking(msg.sender).nftxVaultFactory().vault();
        __ERC20_init(name, symbol);
        baseToken = IERC20Upgradeable(_baseToken);
    }

    // Needs to be called BEFORE new base tokens are deposited.
    function mintXTokens(
        address account,
        uint256 _amount,
        uint256 timelockLength
    ) external onlyOwner returns (uint256) {
        // Gets the amount of Base Token locked in the contract
        uint256 totalBaseToken = baseToken.balanceOf(address(this));
        // Gets the amount of xTokens in existence
        uint256 totalShares = totalSupply();
        // If no xTokens exist, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalBaseToken == 0) {
            _timelockMint(account, _amount, timelockLength);
            return _amount;
        }
        // Calculate and mint the amount of xTokens the base tokens are worth. The ratio will change overtime, as xTokens are burned/minted and base tokens deposited + gained from fees / withdrawn.
        else {
            uint256 what = (_amount * totalShares) / totalBaseToken;
            _timelockMint(account, what, timelockLength);
            return what;
        }
    }

    function burnXTokens(address who, uint256 _share)
        external
        onlyOwner
        returns (uint256)
    {
        // Gets the amount of xToken in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of base tokens the xToken is worth
        uint256 what = (_share * baseToken.balanceOf(address(this))) /
            totalShares;
        _burn(who, _share);
        baseToken.safeTransfer(who, what);
        return what;
    }

    function timelockAccount(address account, uint256 timelockLength)
        public
        virtual
        onlyOwner
    {
        require(timelockLength < MAX_TIMELOCK, "Too long lock");
        uint256 timelockFinish = block.timestamp + timelockLength;
        if (timelockFinish > timelock[account]) {
            timelock[account] = timelockFinish;
            emit Timelocked(account, timelockFinish);
        }
    }

    function _burn(address who, uint256 amount) internal override {
        require(block.timestamp > timelock[who], "User locked");
        super._burn(who, amount);
    }

    function timelockUntil(address account) public view returns (uint256) {
        return timelock[account];
    }

    function _timelockMint(
        address account,
        uint256 amount,
        uint256 timelockLength
    ) internal virtual {
        timelockAccount(account, timelockLength);
        _mint(account, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal override {
        require(block.timestamp > timelock[from], "User locked");
        super._transfer(from, to, value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(
            address(this).balance >= amount,
            "Create2: insufficient balance"
        );
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash)
        internal
        view
        returns (address)
    {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)
        );
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../proxy/Initializable.sol";
import "./ContextUpgradeable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";

contract PausableUpgradeable is OwnableUpgradeable {
    function __Pausable_init() internal initializer {
        __Ownable_init();
    }

    event SetPaused(uint256 lockId, bool paused);
    event SetIsGuardian(address addr, bool isGuardian);

    mapping(address => bool) public isGuardian;
    mapping(uint256 => bool) public isPaused;

    // 0 : createVault
    // 1 : mint
    // 2 : redeem
    // 3 : swap
    // 4 : flashloan

    function onlyOwnerIfPaused(uint256 lockId) public view virtual {
        require(!isPaused[lockId] || msg.sender == owner(), "Paused");
    }

    function unpause(uint256 lockId) public virtual onlyOwner {
        isPaused[lockId] = false;
        emit SetPaused(lockId, false);
    }

    function pause(uint256 lockId) public virtual {
        require(isGuardian[msg.sender], "Can't pause");
        isPaused[lockId] = true;
        emit SetPaused(lockId, true);
    }

    function setIsGuardian(address addr, bool _isGuardian)
        public
        virtual
        onlyOwner
    {
        isGuardian[addr] = _isGuardian;
        emit SetIsGuardian(addr, _isGuardian);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Address.sol";
import "../token/IERC20Upgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using Address for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data)
        private
    {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}