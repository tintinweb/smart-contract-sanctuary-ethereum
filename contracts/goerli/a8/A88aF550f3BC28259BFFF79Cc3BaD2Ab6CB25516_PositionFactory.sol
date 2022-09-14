pragma solidity ^0.8.17;
import 'contracts/interfaces/position_trading/IPositionsController.sol';
import 'contracts/lib/ownable/OwnableSimple.sol';
import 'contracts/interfaces/assets/typed/IEthAssetFactory.sol';
import 'contracts/interfaces/assets/typed/IErc20AssetFactory.sol';
import 'contracts/interfaces/assets/typed/IErc721ItemAssetFactory.sol';
import 'contracts/lib/factories/ContractData.sol';
import 'contracts/interfaces/position_trading/algorithms/IPositionLockerAlgorithmInstaller.sol';
import 'contracts/interfaces/position_trading/algorithms/ISaleAlgorithm.sol';
import 'contracts/interfaces/position_trading/algorithms/IPositionTradingAlgorithm.sol';

/// @dev asset creation data
struct AssetCreationData {
    /// @dev asset codes:
    /// 0 - asset is missing
    /// 1 - EthAsset
    /// 2 - Erc20Asset
    /// 3 - Erc721ItemAsset
    uint256 assetTypeCode;
    address contractAddress;
    uint256 tokenId;
}

contract PositionFactory is OwnableSimple {
    IPositionsController public positionsController;
    IEthAssetFactory public ethAssetFactory; // assetType 1
    IErc20AssetFactory public erc20AssetFactory; // assetType 2
    IErc721ItemAssetFactory public erc721AssetFactory; // assetType 3
    IPositionLockerAlgorithmInstaller public positionLockerAlgorithm;
    ISaleAlgorithm public saleAlgorithm;

    constructor(
        address positionsController_,
        address ethAssetFactory_,
        address erc20AssetFactory_,
        address erc721AssetFactory_,
        address positionLockerAlgorithm_,
        address saleAlgorithm_
    ) OwnableSimple(msg.sender) {
        positionsController = IPositionsController(positionsController_);
        ethAssetFactory = IEthAssetFactory(ethAssetFactory_);
        erc20AssetFactory = IErc20AssetFactory(erc20AssetFactory_);
        erc721AssetFactory = IErc721ItemAssetFactory(erc721AssetFactory_);
        positionLockerAlgorithm = IPositionLockerAlgorithmInstaller(
            positionLockerAlgorithm_
        );
        saleAlgorithm = ISaleAlgorithm(saleAlgorithm_);
    }

    function setPositionsController(address positionsController_)
        external
        onlyOwner
    {
        positionsController = IPositionsController(positionsController_);
    }

    function setethAssetFactory(address ethAssetFactory_) external onlyOwner {
        ethAssetFactory = IEthAssetFactory(ethAssetFactory_);
    }

    function createPositionWithAssets(
        AssetCreationData calldata data1,
        AssetCreationData calldata data2
    ) external {
        // create a position
        positionsController.createPosition();
        uint256 positionId = _lastCreatedPositionId();

        // set assets
        _setAsset(positionId, 1, data1);
        _setAsset(positionId, 2, data2);

        // transfer ownership of the position
        positionsController.transferPositionOwnership(positionId, msg.sender);
    }

    function createPositionLockAlgorithm(AssetCreationData calldata data)
        external
    {
        // create a position
        positionsController.createPosition();
        uint256 positionId = _lastCreatedPositionId();

        // set assets
        _setAsset(positionId, 1, data);

        // set algorithm
        positionLockerAlgorithm.setAlgorithm(positionId);

        // transfer ownership of the position
        positionsController.transferPositionOwnership(positionId, msg.sender);
    }

    function createSaleAlgorithm(
        AssetCreationData calldata data1,
        AssetCreationData calldata data2,
        Price calldata price
    ) external {
        // create a position
        positionsController.createPosition();
        uint256 positionId = _lastCreatedPositionId();

        // set assets
        _setAsset(positionId, 1, data1);
        _setAsset(positionId, 2, data2);

        // set algorithm
        saleAlgorithm.setAlgorithm(positionId);

        // set price
        saleAlgorithm.setPrice(positionId, price);

        // transfer ownership of the position
        positionsController.transferPositionOwnership(positionId, msg.sender);
    }

    function _lastCreatedPositionId() internal view returns (uint256) {
        return
            positionsController.positionOfOwnerByIndex(
                address(this),
                positionsController.ownedPositionsCount(address(this)) - 1
            );
    }

    function _setAsset(
        uint256 positionId,
        uint256 assetCode,
        AssetCreationData calldata data
    ) internal {
        if (data.assetTypeCode == 1)
            ethAssetFactory.setAsset(positionId, assetCode);
        else if (data.assetTypeCode == 2)
            erc20AssetFactory.setAsset(
                positionId,
                assetCode,
                data.contractAddress
            );
        else if (data.assetTypeCode == 3)
            erc721AssetFactory.setAsset(
                positionId,
                assetCode,
                data.contractAddress,
                data.tokenId
            );
    }
}

pragma solidity ^0.8.17;
import 'contracts/lib/factories/ContractData.sol';
import 'contracts/fee/IFeeSettings.sol';

interface IPositionsController {
    /// @dev returns fee settings
    function getFeeSettings() external view returns(IFeeSettings);

    /// @dev returns the position owner
    function ownerOf(uint256 positionId) external view returns (address);

    /// @dev changes position owner
    function transferPositionOwnership(uint256 positionId, address newOwner)
        external;

    /// @dev returns the position of the asset to its address
    function getAssetPositionId(address assetAddress)
        external
        view
        returns (uint256);

    /// @dev returns an asset by its code in position 1 or 2
    function getAsset(uint256 positionId, uint256 assetCode)
        external
        view
        returns (ContractData memory);

    /// @dev creates a position
    function createPosition() external;

    /// @dev sets an asset to position
    /// @param positionId position ID
    /// @param assetCode asset code 1 - owner asset 2 - output asset
    /// @param data asset contract data
    function setAsset(
        uint256 positionId,
        uint256 assetCode,
        ContractData calldata data
    ) external;

    /// @dev sets the position algorithm
    function setAlgorithm(uint256 positionId, ContractData calldata data)
        external;

    /// @dev returns the position algorithm
    function getAlgorithm(uint256 positionId)
        external
        view
        returns (ContractData memory data);

    /// @dev disables position editing
    function disableEdit(uint256 positionId) external;

    /// @dev returns position from the account's list of positions
    function positionOfOwnerByIndex(address account, uint256 index)
        external
        view
        returns (uint256);

    /// @dev returns the number of positions the account owns
    function ownedPositionsCount(address account)
        external
        view
        returns (uint256);
}

pragma solidity ^0.8.17;
import 'contracts/interfaces/IOwnable.sol';

/// @dev owanble, optimized, for dynamically generated contracts
contract OwnableSimple is IOwnable {
    address internal _owner;

    constructor(address owner_) {
        _owner = owner_;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, 'caller is not the owner');
        _;
    }

    function owner() external virtual override returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        _owner = newOwner;
    }
}

pragma solidity ^0.8.17;
interface IEthAssetFactory {
    function setAsset(uint256 positionId, uint256 assetCode) external;
}

pragma solidity ^0.8.17;
interface IErc20AssetFactory {
    function setAsset(
        uint256 positionId,
        uint256 assetCode,
        address contractAddress
    ) external;
}

pragma solidity ^0.8.17;
interface IErc721ItemAssetFactory {
    function setAsset(
        uint256 positionId,
        uint256 assetCode,
        address contractAddress,
        uint256 tokenId
    ) external;
}

pragma solidity ^0.8.17;
/// @dev data is generated by factory of contract
struct ContractData {
    address factory; // factory
    address contractAddr; // contract
}

pragma solidity ^0.8.17;
interface IPositionLockerAlgorithmInstaller {
    /// @dev sets the position lock algorithm
    function setAlgorithm(uint256 positionId) external;
}

pragma solidity ^0.8.17;
/// @dev price
struct Price {
    uint256 nom; // numerator
    uint256 denom; // denominator
}

interface ISaleAlgorithm {
    function setAlgorithm(uint256 positionId) external;

    function setPrice(uint256 positionId, Price calldata price) external;
}



pragma solidity ^0.8.17;
interface IFeeSettings {
    function feeAddress() external returns (address); // address to pay fee

    function feePercent() external returns (uint256); // fee in 1/decimals for deviding values

    function feeDecimals() external view returns(uint256); // fee decimals

    function feeEth() external returns (uint256); // fee value for not dividing deal points
}

pragma solidity ^0.8.17;
interface IOwnable {
    function owner() external returns (address);

    function transferOwnership(address newOwner) external;
}