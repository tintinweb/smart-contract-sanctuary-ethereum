// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

interface ISpaceTimeOracle {
    function getTargetAssets() external view returns (string[] memory, uint256);
}

interface ISpaceTimeRebalancer {
    function createSellList(address _walletAddress)
        external
        returns (string[] memory);

    function createAdjustList(address _walletAddress)
        external
        returns (string[] memory);

    function createBuyList(address _walletAddress)
        external
        returns (string[] memory);
}

interface WBNB {
    function deposit() external payable;

    function withdraw(uint256 wad) external payable;

    function totalSupply() external returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);
}

contract Wallet {
    address public rebalancerAddress;
    address public oracleAddress;
    string public riskWeighting;
    address public wbnbAddress;
    string[] public ownedSymbols = ["A", "B", "Z", "D"];
    string[] public targetAssetsList = ["B", "Z", "Q"]; // should be memory, not stored
    uint256 wbnbBalance = 0; // should be memory, not stored
    uint256 bnbBalance = 0; // should be memory, not stored
    uint256 totalBalance; // should be memory, not stored
    uint256 public totalDeposited = 0; // track deposits

    struct Assets {
        string symbol;
        address assetAddress;
        uint256 price;
        uint256 targetPercentage;
    }

    Assets[] internal ownedAssets;
    mapping(string => address) internal ownedSymbolToAssetAddress;
    mapping(string => uint256) internal ownedSymbolToPrice;
    mapping(string => uint256) internal ownedSymbolToTargetPercentage;

    address payable depositFeeAddress;
    address payable performanceFeeAddress;
    uint256 depositFee;
    uint256 performanceFee;

    //using SafeERC20 for IERC20;
    //using SafeERC20 for WBNB;

    WBNB wbnbToken = WBNB(wbnbAddress);

    //IUniswapRouter uniswapRouter = IUniswapRouter(uinswapV3RouterAddress);

    constructor(address _STRebalancer) {
        rebalancerAddress = address(_STRebalancer);
        oracleAddress = address(0x359644eAF2C8dcb7fC708875cc673A149eEB6E4b); //* TO BE SET BY DEPLOYMENT FUNCTION *//
        riskWeighting = "rwMaxAssetCap"; //* TO BE SET BY DEPLOYMENT FUNCTION *//
        depositFee = 5; // 0.05% calculated as 5/1000
        performanceFee = 50; // 5.0% calculated as 50/1000
        depositFeeAddress = payable(0x5131da5D06C50262342802DeCFfC775A3A4DD66B);
        performanceFeeAddress = payable(
            0xc34185b9BF47e236c89b09DAb8091081cA8039EC
        );
        wbnbAddress = address(0xd0A1E359811322d97991E03f863a0C30C2cF029C); //Kovan testnet
    }

    // Allows the SpaceTimeRebalancer to call ownedSymbols from this wallet
    function getOwnedAssets() public view returns (string[] memory) {
        return ownedSymbols;
    }

    // Allows the SpaceTimeRebalancer to call targetAssetsList from this wallet
    //function getTargetAssets() external view returns (string[] memory) {
    //    return targetAssetsList;
    //}

    // Update targetAssets with the latest targets from the SpaceTimeOracle
    function getTargetAssets() public view returns (string[] memory) {
        (string[] memory targetAssets, ) = ISpaceTimeOracle(oracleAddress)
            .getTargetAssets();
        return targetAssets;
    }

    string[] public sellSymbolsList;

    function getSellList() internal {
        ISpaceTimeRebalancer STRebalancer = ISpaceTimeRebalancer(
            rebalancerAddress
        );
        string[] memory sellResult = STRebalancer.createSellList(address(this));
        require(sellResult.length > 0, "No assets in list");
        for (uint256 x = 0; x < sellResult.length; x++) {
            if (
                keccak256(abi.encodePacked(sellResult[x])) !=
                keccak256(abi.encodePacked(""))
            ) {
                sellSymbolsList.push(sellResult[x]);
            }
        }
    }

    string[] public adjustSymbolsList;

    function getAdjustList() internal {
        ISpaceTimeRebalancer STRebalancer = ISpaceTimeRebalancer(
            rebalancerAddress
        );
        string[] memory adjustResult = STRebalancer.createAdjustList(
            address(this)
        );
        require(adjustResult.length > 0, "No assets in list");
        for (uint256 x = 0; x < adjustResult.length; x++) {
            if (
                keccak256(abi.encodePacked(adjustResult[x])) !=
                keccak256(abi.encodePacked(""))
            ) {
                adjustSymbolsList.push(adjustResult[x]);
            }
        }
    }

    string[] public buySymbolsList;

    function getBuyList() internal {
        ISpaceTimeRebalancer STRebalancer = ISpaceTimeRebalancer(
            rebalancerAddress
        );
        string[] memory buyResult = STRebalancer.createBuyList(address(this));
        require(buyResult.length > 0, "No assets in list");
        for (uint256 x = 0; x < buyResult.length; x++) {
            if (
                keccak256(abi.encodePacked(buyResult[x])) !=
                keccak256(abi.encodePacked(""))
            ) {
                buySymbolsList.push(buyResult[x]);
            }
        }
    }

    function rebalance() public {
        getTargetAssets();
        getSellList();
        getAdjustList();
        getBuyList();
    }
}