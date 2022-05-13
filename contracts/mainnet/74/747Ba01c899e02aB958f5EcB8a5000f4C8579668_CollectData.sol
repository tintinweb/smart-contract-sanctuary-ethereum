//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

pragma experimental ABIEncoderV2;

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

abstract contract UniswapV2Factory  {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    function allPairsLength() external view virtual returns (uint);
}

interface INFTXVault{
    function manager() external view returns (address);
    function assetAddress() external view returns (address);

    function is1155() external view returns (bool);
    function allowAllItems() external view returns (bool);
    function enableMint() external view returns (bool);
    function enableRandomRedeem() external view returns (bool);
    function enableTargetRedeem() external view returns (bool);
    function enableRandomSwap() external view returns (bool);
    function enableTargetSwap() external view returns (bool);

    function vaultId() external view returns (uint256);
    function nftIdAt(uint256 holdingsIndex) external view returns (uint256);
    function allHoldings() external view returns (uint256[] memory);
    function totalHoldings() external view returns (uint256);
    function mintFee() external view returns (uint256);
    function randomRedeemFee() external view returns (uint256);
    function targetRedeemFee() external view returns (uint256);
    function randomSwapFee() external view returns (uint256);
    function targetSwapFee() external view returns (uint256);
    function vaultFees() external view returns (uint256, uint256, uint256, uint256, uint256);
}

interface NFTXFactory {
    function allVaults() external view returns (address[] memory);
}

struct VaultData { 
    address vaultAddress;
    address manager;
    address assetAddress;
    address vaultFactory;
    bool is1155;
    bool allowAllItems;
    bool enableMint;
    bool enableRandomRedeem;
    bool enableTargetRedeem;
    bool enableRandomSwap;
    bool enableTargetSwap;
    uint256 vaultId;
    uint256[] allHoldings;
    uint256 totalHoldings;
    uint256 mintFee;
    uint256 randomRedeemFee;
    uint256 targetRedeemFee;
    uint256 randomSwapFee;
    uint256 targetSwapFee;

    address sushiLPContractAddress;
    uint112 reserve0;
    uint112 reserve1;
}

contract CollectData {
    
    address private owner;
    address private WETHAddress;

    constructor() {
		owner = msg.sender;
        WETHAddress = address(0xc778417E063141139Fce010982780140Aa0cD5Ab);
    }

    function setWETHAddress(address weth) public{
        WETHAddress = weth;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address _o) onlyOwner external {
		owner = _o;
	}

    function getAllData(address[] calldata addresses) public view returns (VaultData[] memory) {
        NFTXFactory nftxFactory = NFTXFactory(addresses[0]);
        UniswapV2Factory uniswapFactory = UniswapV2Factory(addresses[1]);
        address[] memory nftxVaults = nftxFactory.allVaults();
        VaultData[] memory dataArray = new VaultData[](nftxVaults.length);
        uint256 count = 0;

        for (uint i = 0; i < nftxVaults.length; i++) {
            INFTXVault nftxVaultContract = INFTXVault(nftxVaults[i]);
            address pairAddress = uniswapFactory.getPair(nftxVaults[i],WETHAddress);
            if(pairAddress != address(0x0000000000000000000000000000000000000000)){
                IUniswapV2Pair pairContract = IUniswapV2Pair(pairAddress);
                uint112 reserve0 = 0;
                uint112 reserve1 = 0;
                uint32 blockTimestampLast = 0;

                (reserve0, reserve1, blockTimestampLast) = pairContract.getReserves();



                VaultData memory data = VaultData(nftxVaults[i],
                                            nftxVaultContract.manager(),
                                            nftxVaultContract.assetAddress(), 
                                            address(0x0000000000000000000000000000000000000000),
                                            nftxVaultContract.is1155(),
                                            nftxVaultContract.allowAllItems(),
                                            nftxVaultContract.enableMint(),
                                            nftxVaultContract.enableRandomRedeem(),
                                            nftxVaultContract.enableTargetRedeem(),
                                            nftxVaultContract.enableRandomSwap(),
                                            nftxVaultContract.enableTargetSwap(),
                                            nftxVaultContract.vaultId(),
                                            nftxVaultContract.allHoldings(),
                                            nftxVaultContract.totalHoldings(),
                                            nftxVaultContract.mintFee(),
                                            nftxVaultContract.randomRedeemFee(),
                                            nftxVaultContract.targetRedeemFee(),
                                            nftxVaultContract.randomSwapFee(),
                                            nftxVaultContract.targetSwapFee(),
                                            pairAddress,
                                            reserve0,
                                            reserve1);

                dataArray[count] = data;
                count++;
            }
        }
        VaultData[] memory returnArray = new VaultData[](count);
        for(uint i = 0; i < count; i++){
            returnArray[i] = dataArray[i];
        }
        
        return returnArray;
    }

    // function getVaultData()
}