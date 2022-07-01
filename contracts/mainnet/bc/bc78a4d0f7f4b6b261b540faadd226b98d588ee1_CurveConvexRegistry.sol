/**
 *Submitted for verification at Etherscan.io on 2022-07-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

/**
 * @title Represents an ownable resource.
 */
contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
     * Constructor
     * @param addr The owner of the smart contract
     */
    constructor (address addr) {
        require(addr != address(0), "non-zero address required");
        require(addr != address(1), "ecrecover address not allowed");
        _owner = addr;
        emit OwnershipTransferred(address(0), addr);
    }

    /**
     * @notice This modifier indicates that the function can only be called by the owner.
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "Only owner requirement");
        _;
    }

    /**
     * @notice Transfers ownership to the address specified.
     * @param addr Specifies the address of the new owner.
     * @dev Throws if called by any account other than the owner.
     */
    function transferOwnership (address addr) public onlyOwner {
        require(addr != address(0), "non-zero address required");
        emit OwnershipTransferred(_owner, addr);
        _owner = addr;
    }

    /**
     * @notice Destroys the smart contract.
     * @param addr The payable address of the recipient.
     */
    function destroy(address payable addr) public virtual onlyOwner {
        require(addr != address(0), "non-zero address required");
        require(addr != address(1), "ecrecover address not allowed");
        selfdestruct(addr);
    }

    /**
     * @notice Gets the address of the owner.
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @notice Indicates if the address specified is the owner of the resource.
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner(address addr) public view returns (bool) {
        return addr == _owner;
    }
}


/**
 * @notice This library provides stateless, general purpose functions.
 */
library Utils {
    // The code hash of any EOA
    bytes32 constant internal EOA_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    /**
     * @notice Indicates if the address specified represents a smart contract.
     * @dev Notice that this method returns TRUE if the address is a contract under construction
     * @param addr The address to evaluate
     * @return Returns true if the address represents a smart contract
     */
    function isContract (address addr) internal view returns (bool) {
        bytes32 eoaHash = EOA_HASH;

        bytes32 codeHash;

        // solhint-disable-next-line no-inline-assembly
        assembly { codeHash := extcodehash(addr) }

        return (codeHash != eoaHash && codeHash != 0x0);
    }

    /**
     * @notice Gets the code hash of the address specified
     * @param addr The address to evaluate
     * @return Returns a hash
     */
    function getCodeHash (address addr) internal view returns (bytes32) {
        bytes32 codeHash;

        // solhint-disable-next-line no-inline-assembly
        assembly { codeHash := extcodehash(addr) }

        return codeHash;
    }
}

interface IERC20NonCompliant {
    function transfer(address to, uint256 value) external;
    function transferFrom(address from, address to, uint256 value) external;
    function approve(address spender, uint256 value) external;
    function totalSupply() external view returns (uint256);
    function balanceOf(address addr) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface IMinLpToken {
    function transfer(address to, uint256 value) external;
    function transferFrom(address from, address to, uint256 value) external;
    function approve(address spender, uint256 value) external;
    function balanceOf(address addr) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract CurveConvexRegistry is Ownable {
    address constant internal ZERO_ADDRESS = address(0);
    bytes4 constant internal ADD_LIQUIDITY_2_POOL = 0x0b4c7e4d; // bytes4(keccak256("add_liquidity(uint256[2],uint256)"));
    bytes4 constant internal ADD_LIQUIDITY_2_ZAP  = 0x4fb92465; // bytes4(keccak256("add_liquidity(address,uint256[2],uint256,address)"));
    bytes4 constant internal ADD_LIQUIDITY_4_POOL = 0x029b2f34; // bytes4(keccak256("add_liquidity(uint256[4],uint256)"));
    bytes4 constant internal ADD_LIQUIDITY_4_ZAP  = 0xd0b951e8; // bytes4(keccak256("add_liquidity(address,uint256[4],uint256,address)"));

    struct Record {
        bytes32 curvePoolHash;
        address curvePoolAddress;
        address curveLpTokenAddress;
        address curveDepositAddress;
        address inputTokenAddress;
        address convexPoolAddress; 
        address convexRewardsAddress;
        uint256 convexPoolId; 
        uint8 totalParams;
        uint8 tokenPosition;
        bool useZap;
        bytes4 addLiquidityFnSig;
    }

    uint256 private _seed;
    mapping (uint256 => Record) internal _records;

    constructor (address newOwner) Ownable(newOwner) { // solhint-disable-line no-empty-blocks
    }

    /**
     * @notice Updates the maximum limit of the total supply.
     * @param poolName The human readable name of the pool
     * @param curvePoolAddr The address of the pool, per Curve
     * @param curveLpTokenAddr The address of the LP token, per Curve
     * @param curveDepositAddr The deposit address in Curve
     * @param useZap Indicates if the deposit address is a Zap address or not
     * @param totalParams The number of parameters expected when adding liquidity to the pool
     * @param convexPoolAddr The address of the Convex pool
     * @param convexRewardsAddr The address of the Convex rewards
     * @param convexPoolId The ID of the Convex pool
     * @param inputToken The token to deposit in Curve
     */
    function registerPool (
        string memory poolName, 
        address curvePoolAddr, 
        IMinLpToken curveLpTokenAddr, 
        address curveDepositAddr,
        bool useZap, 
        uint8 totalParams,
        address convexPoolAddr, 
        address convexRewardsAddr,
        uint256 convexPoolId,
        IERC20NonCompliant inputToken,
        uint8 tokenPosition
    ) public onlyOwner {
        // Checks
        require(curvePoolAddr != ZERO_ADDRESS, "non-zero address required");
        require(curveDepositAddr != ZERO_ADDRESS, "non-zero address required");
        require(convexPoolAddr != ZERO_ADDRESS, "non-zero address required");
        require(convexRewardsAddr != ZERO_ADDRESS, "non-zero address required");
        require(address(curveLpTokenAddr) != ZERO_ADDRESS, "non-zero address required");
        require(address(inputToken) != ZERO_ADDRESS, "non-zero address required");
        require((totalParams == 2) || (totalParams == 4), "Invalid number of parameters");
        require(tokenPosition < totalParams, "Invalid target index");

        // Make sure the deposit address is a smart contract.
        // Query the exact code hash of the deposit contract. We don't want to deposit funds in an unknown contract implementation.
        bytes32 depositContractCodeHash = Utils.getCodeHash(curveDepositAddr);
        bool depositAddrIsContract = (depositContractCodeHash != Utils.EOA_HASH && depositContractCodeHash != 0x0);
        require(depositAddrIsContract, "Invalid Deposit address");

        // Define the record
        _records[_seed] = Record(
                            keccak256(abi.encode(poolName)), 
                            curvePoolAddr, 
                            address(curveLpTokenAddr), 
                            curveDepositAddr, 
                            address(inputToken), 
                            convexPoolAddr,
                            convexRewardsAddr,
                            convexPoolId,
                            totalParams, 
                            tokenPosition,
                            useZap,
                            _getAddLiquiditySignature(useZap, totalParams)
                        );

        // Increase the seed
        _seed++;
    }

    function getCurveDepositInfo (uint256 recordId) public view returns (
        address curveDepositAddress, 
        address inputTokenAddress, 
        address curveLpTokenAddress
    ) {
        curveLpTokenAddress = _records[recordId].curveLpTokenAddress;
        curveDepositAddress = _records[recordId].curveDepositAddress;
        inputTokenAddress = _records[recordId].inputTokenAddress;
    }

    function getConvexDepositInfo (uint256 recordId) public view returns (
        uint256 convexPoolId,
        address curveLpTokenAddress, 
        address convexRewardsAddress
    ) {
        convexPoolId = _records[recordId].convexPoolId;
        curveLpTokenAddress = _records[recordId].curveLpTokenAddress;
        convexRewardsAddress = _records[recordId].convexRewardsAddress;
    }

    function getCurveAddLiquidityInfo (uint256 recordId) public view returns (
        uint8 totalParams,
        uint8 tokenPosition,
        bool useZap,
        address curveDepositAddress,
        bytes4 addLiquidityFnSig
    ) {
        totalParams = _records[recordId].totalParams;
        tokenPosition = _records[recordId].tokenPosition;
        useZap = _records[recordId].useZap;
        curveDepositAddress = _records[recordId].curveDepositAddress;
        addLiquidityFnSig = _records[recordId].addLiquidityFnSig;
    }

    function getRecord (uint256 recordId) public view returns (
        bytes32 curvePoolHash,
        address curvePoolAddress,
        address curveLpTokenAddress,
        address curveDepositAddress,
        address inputTokenAddress,
        address convexPoolAddress, 
        address convexRewardsAddress,
        uint8 totalParams,
        uint8 tokenPosition,
        bool useZap,
        bytes4 addLiquidityFnSig
    ) {
        curvePoolHash = _records[recordId].curvePoolHash;
        curvePoolAddress = _records[recordId].curvePoolAddress;
        curveLpTokenAddress = _records[recordId].curveLpTokenAddress;
        curveDepositAddress = _records[recordId].curveDepositAddress;
        inputTokenAddress = _records[recordId].inputTokenAddress;
        convexPoolAddress = _records[recordId].convexPoolAddress;
        convexRewardsAddress = _records[recordId].convexRewardsAddress;
        totalParams = _records[recordId].totalParams;
        tokenPosition = _records[recordId].tokenPosition;
        useZap = _records[recordId].useZap;
        addLiquidityFnSig = _records[recordId].addLiquidityFnSig;
    }

    function _getAddLiquiditySignature (bool useZap, uint8 totalParams) private pure returns (bytes4) {
        if (totalParams == 4) {
            return (useZap) ? ADD_LIQUIDITY_4_ZAP : ADD_LIQUIDITY_4_POOL;
        }
        else if (totalParams == 2) {
            return (useZap) ? ADD_LIQUIDITY_2_ZAP : ADD_LIQUIDITY_2_POOL;
        }
        else revert("Invalid parameters");
    }
}