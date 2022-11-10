/**
 *Submitted for verification at Etherscan.io on 2022-11-09
*/

pragma solidity 0.8.12;

interface ICauldron {
    function COLLATERIZATION_RATE() external view returns (uint256);
    function exchangeRate() external view returns (uint256);
    function oracle() external view returns (IOracle);
    function oracleData() external view returns (bytes memory);
    function updateExchangeRate() external returns (bool updated, uint256 rate);
    function masterContract() external view returns (address);
    function bentoBox() external view returns (address);
    function reduceSupply(uint256 amount) external;
}

interface IBentoBoxV1 {
    function balanceOf(address, address) external view returns (uint256);
    function toAmount(
        address token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);
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

interface ICheckForReduction {
    function updateCauldrons(ICauldron[] memory cauldrons_) external;
}

interface ICauldronOwner {
    function reduceSupply(ICauldron cauldron, uint256 amount) external;
}

contract CheckForReduction is ICheckForReduction {
    
    uint256 private constant EXCHANGERATE_PRECISION = 1e18;
    uint256 private constant COLLATERIZATION_RATE_PRECISION = 1e5;
    ICauldronOwner public constant owner = ICauldronOwner(0x30B9dE623C209A42BA8d5ca76384eAD740be9529);

    address private constant MIM = 0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3;

    ICauldron[] public cauldrons; 

    constructor(ICauldron[] memory cauldrons_) {
        cauldrons = cauldrons_;
    }

    function updateCauldrons(ICauldron[] memory cauldrons_) external override {
        for (uint i; i< cauldrons_.length; i++) {
            ICauldron cauldron = cauldrons_[i];
            IBentoBoxV1 bentoBox = IBentoBoxV1(cauldron.bentoBox());
            uint256 balance = bentoBox.balanceOf(MIM, address(cauldron));
            owner.reduceSupply(cauldron, bentoBox.toAmount(MIM, balance, false));
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
            IBentoBoxV1 bentoBox = IBentoBoxV1(cauldron.bentoBox());
            uint256 balance = bentoBox.balanceOf(MIM, address(cauldron));

            if (balance > 1000 * 1e18) {
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

        execPayload = abi.encodeCall(ICheckForReduction.updateCauldrons, (toBeUpdated));
    }
}