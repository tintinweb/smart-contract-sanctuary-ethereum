// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { ERC20Helper } from "../modules/erc20-helper/src/ERC20Helper.sol";

import { LiquidatorStorage } from "./LiquidatorStorage.sol";

contract LiquidatorInitializer is LiquidatorStorage {

    function decodeArguments(bytes calldata calldata_) public pure returns (address loanManager_, address collateralAsset_, address fundsAsset_) {
        ( loanManager_, collateralAsset_, fundsAsset_ ) = abi.decode(calldata_, (address, address, address));
    }

    function encodeArguments(address loanManager_, address collateralAsset_, address fundsAsset_) external pure returns (bytes memory calldata_) {
        calldata_ = abi.encode(loanManager_, collateralAsset_, fundsAsset_);
    }

    fallback() external {
        ( address loanManager_, address collateralAsset_, address fundsAsset_ ) = decodeArguments(msg.data);

        _initialize(loanManager_, collateralAsset_, fundsAsset_);
    }

    function _initialize(address loanManager_, address collateralAsset_, address fundsAsset_) internal {
        require(loanManager_ != address(0), "LIQI:I:ZERO_LM");

        loanManager     = loanManager_;
        collateralAsset = collateralAsset_;
        fundsAsset      = fundsAsset_;
        locked          = 1;
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { ILiquidatorStorage } from "./interfaces/ILiquidatorStorage.sol";

abstract contract LiquidatorStorage is ILiquidatorStorage {

    address public override collateralAsset;
    address public override fundsAsset;
    address public override loanManager;

    uint256 public override collateralRemaining;

    uint256 internal locked;

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface ILiquidatorStorage {

    /**
     *  @dev    Returns the address of the collateral asset.
     *  @return collateralAsset_ Address of the asset used as collateral.
     */
    function collateralAsset() external view returns (address collateralAsset_);

    /**
     *  @dev    Returns the amount of collateral yet to be liquidated.
     *  @return collateralRemaining_ Amunt of collateral remaining to be liquidated.
     */
    function collateralRemaining() external view returns (uint256 collateralRemaining_);

    /**
     *  @dev    Returns the address of the funding asset.
     *  @return fundsAsset_ Address of the asset used for providing funds.
     */
    function fundsAsset() external view returns (address fundsAsset_);

    /**
     *  @dev    Returns the address of the loan manager contract.
     *  @return loanManager_ Address of the loan manager.
     */
    function loanManager() external view returns (address loanManager_);


}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { IERC20Like } from "./interfaces/IERC20Like.sol";

/**
 * @title Small Library to standardize erc20 token interactions.
 */
library ERC20Helper {

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    function transfer(address token_, address to_, uint256 amount_) internal returns (bool success_) {
        return _call(token_, abi.encodeWithSelector(IERC20Like.transfer.selector, to_, amount_));
    }

    function transferFrom(address token_, address from_, address to_, uint256 amount_) internal returns (bool success_) {
        return _call(token_, abi.encodeWithSelector(IERC20Like.transferFrom.selector, from_, to_, amount_));
    }

    function approve(address token_, address spender_, uint256 amount_) internal returns (bool success_) {
        // If setting approval to zero fails, return false.
        if (!_call(token_, abi.encodeWithSelector(IERC20Like.approve.selector, spender_, uint256(0)))) return false;

        // If `amount_` is zero, return true as the previous step already did this.
        if (amount_ == uint256(0)) return true;

        // Return the result of setting the approval to `amount_`.
        return _call(token_, abi.encodeWithSelector(IERC20Like.approve.selector, spender_, amount_));
    }

    function _call(address token_, bytes memory data_) private returns (bool success_) {
        if (token_.code.length == uint256(0)) return false;

        bytes memory returnData;
        ( success_, returnData ) = token_.call(data_);

        return success_ && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

/// @title Interface of the ERC20 standard as needed by ERC20Helper.
interface IERC20Like {

    function approve(address spender_, uint256 amount_) external returns (bool success_);

    function transfer(address recipient_, uint256 amount_) external returns (bool success_);

    function transferFrom(address owner_, address recipient_, uint256 amount_) external returns (bool success_);

}