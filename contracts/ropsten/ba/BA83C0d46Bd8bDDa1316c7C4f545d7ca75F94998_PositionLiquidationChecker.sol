/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IBalanceManager {

    /**
    * @notice to get position collateral value
    * @param positionId position id
    * @return positionCollateralValue position value (collateral + unrealizedPnl+realizedPnl + funding payment )
     */
    function getPositionCollateralValue(uint positionId)
        external
        view 
        returns(int256 positionCollateralValue); 

    /**
    * @notice to get maintenance margin requirement for position
    * @param positionId position id
    * @return marginRequired margin required for the position
     */
     function getMarginRequirementForPositionLiquidation(uint256 positionId) external view returns(int256 marginRequired);

     function liquidatePosition(uint256 positionId,uint256 oppositeBoundAmount,uint256 deadline) external returns (uint256 baseAmount,uint256 quoteAmount);
}

interface IClearingHouseExtended {

    /**
    * @notice to liquidate the position
    * @param positionId: id of the position
    * @param oppositeBoundAmount: opposite bound amount
    * @param deadline: deadline of the transaction
     */
    function liquidatePosition(uint256 positionId,uint256 oppositeBoundAmount,uint256 deadline) external returns (uint256 baseAmount,uint256 quoteAmount);
}

contract PositionLiquidationChecker is Ownable{
    
    address public balanceManagerAddress;

    uint256[] internal positionIds;
     address public ClearingHOuse;

    mapping(uint256 => uint256) internal positionIdIndex;

    constructor(address _balanceManager, address _CH) {
        balanceManagerAddress = _balanceManager;
        ClearingHOuse = _CH;
    }


    /**
    * @notice to update the balance manager contract
    * @param _balanceManager: address of the balance manager contract
     */
    function updateBalanceManager(address _balanceManager) external onlyOwner {
        balanceManagerAddress = _balanceManager;
    }
    
    /**
    * @notice to add the position id in array
    * @param _positionIds: id of the positions
    */
    function addBulkPositionsIds(uint256[] memory _positionIds) external onlyOwner {
        for(uint8 i=0;i<_positionIds.length;i++){
            positionIds.push(_positionIds[i]);
            positionIdIndex[_positionIds[i]]= positionIds.length-1;
        }
    }


    /**
    * @notice to remove the position id in array
    * @param _positionIds: id of the positions
    */
    function removePosition(uint256[] memory _positionIds) external onlyOwner{
        uint length=positionIds.length;
        for(uint8 i=0;i<_positionIds.length;i++){
            uint256 index=positionIdIndex[_positionIds[i]];
            positionIds[index]=positionIds[length-1];
            positionIdIndex[positionIds[length-1]]=index;
            positionIds.pop();
            length=positionIds.length;
        }
    }


    /**
        * @notice to fetch all the position ids
     */
    function getAllpositionIds() external view returns (uint256[] memory) {
        return positionIds;
    }

    /**
    * @notice to liquidate the positions
    * @return canExec if this is true then liquidation function will be called
    * @return execPayload data for transaction
     */
    function checker() external view returns (bool canExec, bytes memory execPayload) {
        require(positionIds.length > 0, "No positions found");
        canExec = false;
        for (uint i = 0; i < positionIds.length; i++) {
            // fetching the position collatral value
            int256 positionColleteralValue = IBalanceManager(balanceManagerAddress).getPositionCollateralValue(positionIds[i]);
            int256 positionMarginValue = IBalanceManager(balanceManagerAddress).getMarginRequirementForPositionLiquidation(positionIds[i]);
            if (positionColleteralValue < positionMarginValue) {
                // call the autoliqidation function in clearing house extended contract
                canExec = true;
                execPayload = abi.encodeWithSelector(IClearingHouseExtended(ClearingHOuse).liquidatePosition.selector,uint256(positionIds[i]), uint256(0), uint256(block.timestamp + 600));
                break;
            }
        }
        
        return (canExec, execPayload);
    }
}