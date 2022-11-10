/**
 *Submitted for verification at Etherscan.io on 2022-11-09
*/

pragma solidity 0.8.12;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Simplified by BoringCrypto

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

contract CheckForReduction is ICheckForReduction, BoringOwnable {
    error ErrNotOperator(address operator);
    
    uint256 private constant EXCHANGERATE_PRECISION = 1e18;
    uint256 private constant COLLATERIZATION_RATE_PRECISION = 1e5;
    ICauldronOwner public constant cauldronOwner = ICauldronOwner(0x30B9dE623C209A42BA8d5ca76384eAD740be9529);

    event LogOperatorChanged(address indexed operator, bool previous, bool current);

    address private constant MIM = 0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3;

    mapping(address => bool) public operators;

    ICauldron[] public cauldrons; 

    modifier onlyOperators() {
        if (!operators[msg.sender]) {
            revert ErrNotOperator(msg.sender);
        }
        _;
    }

    constructor(ICauldron[] memory cauldrons_) {
        cauldrons = cauldrons_;
    }

    function setOperator(address operator, bool enabled) external onlyOwner {
        emit LogOperatorChanged(operator, operators[operator], enabled);
        operators[operator] = true;
    }

    function updateCauldrons(ICauldron[] memory cauldrons_) external onlyOperators override {
        for (uint i; i < cauldrons_.length; i++) {
            ICauldron cauldron = cauldrons_[i];
            IBentoBoxV1 bentoBox = IBentoBoxV1(cauldron.bentoBox());
            uint256 balance = bentoBox.balanceOf(MIM, address(cauldron));
            cauldronOwner.reduceSupply(cauldron, bentoBox.toAmount(MIM, balance, false));
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