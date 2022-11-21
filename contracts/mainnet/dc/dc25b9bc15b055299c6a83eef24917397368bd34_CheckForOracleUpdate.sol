/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

pragma solidity 0.8.12;

interface ICauldron {
    function COLLATERIZATION_RATE() external view returns (uint256);
    function exchangeRate() external view returns (uint256);
    function oracle() external view returns (IOracle);
    function oracleData() external view returns (bytes memory);
    function updateExchangeRate() external returns (bool updated, uint256 rate);
    function masterContract() external view returns (address);
}

interface IOracle {
    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata data) external view returns (bool success, uint256 rate);
}

interface ICheckForOracleUpdate {
    function updateCauldrons(ICauldron[] memory cauldrons_) external;
}

contract CheckForOracleUpdate is ICheckForOracleUpdate {
    
    uint256 private constant EXCHANGERATE_PRECISION = 1e18;
    uint256 private constant COLLATERIZATION_RATE_PRECISION = 1e5;

    mapping(address => uint256) public oldCollaterization;
    mapping(address => bool) public masterContractv3;

    ICauldron[] public cauldrons; 

    constructor(ICauldron[] memory cauldrons_) {
        cauldrons = cauldrons_;
        oldCollaterization[0x469a991a6bB8cbBfEe42E7aB846eDEef1bc0B3d3] = 90000;
        oldCollaterization[0x4a9Cb5D0B755275Fd188f87c0A8DF531B0C7c7D2] = 75000;
        masterContractv3[0x3E2a2BC69E5C22A8DA4056B413621D1820Eb493E] = true;
        masterContractv3[0xE19B0D53B6416D139B2A447C3aE7fb9fe161A12c] = true;
    }

    function updateCauldrons(ICauldron[] memory cauldrons_) external override {
        for (uint i; i< cauldrons_.length; i++) {
            cauldrons_[i].updateExchangeRate();
        }
    }

    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        
        canExec = false;
        uint256 len;
        bool[] memory isToBeUpdated = new bool[](cauldrons.length);

        for (uint i; i < cauldrons.length; i++) {
            ICauldron cauldron = cauldrons[i];
            address masterContract = cauldron.masterContract();

            if(masterContractv3[masterContract]) {
                continue;
            }

            uint256 collaterization = oldCollaterization[masterContract] != 0 ? oldCollaterization[masterContract] : cauldron.COLLATERIZATION_RATE();
            uint256 collateralizationDelta = COLLATERIZATION_RATE_PRECISION - collaterization;

            ( ,uint256 currentRate) = cauldron.oracle().peek(cauldron.oracleData());

            uint256 staleRate = cauldron.exchangeRate();

            if (staleRate + staleRate * collateralizationDelta / COLLATERIZATION_RATE_PRECISION / 3 < currentRate) {
                canExec = true;
                isToBeUpdated[i] = true;
                len++;
            }
        }

        ICauldron[] memory toBeUpdated = new ICauldron[](len);

        for (uint i; i < cauldrons.length; i++) {
            if(isToBeUpdated[i]) {
                toBeUpdated[toBeUpdated.length - len] = cauldrons[i];
                len--;
            }
        }

        execPayload = abi.encodeCall(ICheckForOracleUpdate.updateCauldrons, (toBeUpdated));
    }
}