// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ICErc20 {
    function symbol() external view returns (string memory);

    function underlying() external view returns (address);

    /*** User Interface ***/

    function transfer(address dst, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);

    function isCToken() external view returns (bool);
    function accrueInterest() external returns (uint);


    /*** User Interface ***/

    function mint(uint tokenId) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function mints(uint[] calldata tokenIds) external returns (uint[] memory);
    function redeems(uint[] calldata redeemTokenIds) external returns (uint[] memory);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, address cTokenCollateral) external returns (uint);
}

interface ICErc721 is ICErc20{
    /*** storage ***/
    function userTokens(address user, uint tokenIndex) external view returns (uint);
}

interface ICEther {
    function symbol() external view returns (string memory);

    function underlying() external view returns (address);

    function liquidateBorrow(address borrower, address cTokenCollateral) external payable;

    function repayBorrowBehalf(address borrower) external payable;

    function isCToken() external view returns (bool);

    function mint() external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IComptroller {
    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @return (possible error code (semi-opaque),
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
    function getAccountLiquidity(address) external view returns (uint, uint, uint);

    function oracle() external view returns (address);
    function liquidateCalculateSeizeTokensEx(address cTokenBorrowed, address cTokenExCollateral, uint repayAmount) external view returns (uint, uint, uint);
    
    function liquidationIncentiveMantissa() external view returns(uint256);
    function closeFactorMantissa() external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /**
      * @notice Get the total number of tokens in circulation
      * @return The supply of tokens
      */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return success Whether or not the transfer succeeded
      */
    function transfer(address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return success Whether or not the transfer succeeded
      */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return success Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return remaining The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IOracle {
    function getUnderlyingPriceView(address cToken) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./NFTLiquidationInterface.sol";
import "./NFTLiquidationStorage.sol";
import "./NFTLiquidationProxy.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IComptroller.sol";
import "./ICToken.sol";
import "./IOracle.sol";

/**
 * @title Drops's NFT Liquidation Proxy Contract
 * @author Drops
 */
contract NFTLiquidationG1 is NFTLiquidationV1Storage, NFTLiquidationInterface {
    using SafeMath for uint256;

    /// @notice Emitted when an admin set comptroller
    event NewComptroller(address oldComptroller, address newComptroller);

    /// @notice Emitted when an admin set the cether address
    event NewCEther(address cEther);

    /// @notice Emitted when an admin set the protocol fee recipient
    event NewProtocolFeeRecipient(address _protocolFeeRecipient);

    /// @notice Emitted when an admin set the protocol fee
    event NewProtocolFeeMantissa(uint256 _protocolFeeMantissa);

    /// @notice Emitted when emergency withdraw the underlying asset
    event EmergencyWithdraw(address to, address underlying, uint256 amount);

    /// @notice Emitted when emergency withdraw the NFT
    event EmergencyWithdrawNFT(address to, address underlying, uint256 tokenId);

    constructor() public {}

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin may call");
        _;
    }

    /*** Reentrancy Guard ***/

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }

    /*** Liquidator functions ***/

    /**
     * @notice Execute the proxy liquidation with single token repay
     */
    function liquidateWithSingleRepay(address payable borrower, address cTokenCollateral, address cTokenRepay, uint256 repayAmount) external payable nonReentrant {
        require(borrower != address(0), "invalid borrower address");

        (, , uint256 borrowerShortfall) = IComptroller(comptroller).getAccountLiquidity(borrower);
        require(borrowerShortfall > 0, "invalid borrower liquidity shortfall");
        liquidateWithSingleRepayFresh(borrower, cTokenCollateral, cTokenRepay, repayAmount);
        transferSeizedTokenFresh(borrower, cTokenCollateral, false);
    }

    /**
     * @notice Execute the proxy liquidation with single token repay and selected seize token value
     */
    function liquidateWithSingleRepayV2(address payable borrower, address cTokenCollateral, address cTokenRepay, uint256 repayAmount, uint256[] memory _seizeIndexes, bool claimDToken) external payable nonReentrant {
        require(borrower != address(0), "invalid borrower address");

        (, , uint256 borrowerShortfall) = IComptroller(comptroller).getAccountLiquidity(borrower);
        require(borrowerShortfall > 0, "invalid borrower liquidity shortfall");
        require(seizeIndexes_.length == 0, "invalid initial seize indexes");
        seizeIndexes_ = _seizeIndexes;
        liquidateWithSingleRepayFresh(borrower, cTokenCollateral, cTokenRepay, repayAmount);
        transferSeizedTokenFresh(borrower, cTokenCollateral, claimDToken);
    }

    function seizeIndexes() external view returns(uint256[] memory) {
        return seizeIndexes_;
    }

    function liquidateWithSingleRepayFresh(address payable borrower, address cTokenCollateral, address cTokenRepay, uint256 repayAmount) internal {
        require(extraRepayAmount == 0, "invalid initial extra repay amount");

        uint256 borrowedAmount = ICErc20(cTokenRepay).borrowBalanceCurrent(borrower);

        require(repayAmount >= borrowedAmount, "invalid token repay amount");
        extraRepayAmount = repayAmount.sub(borrowedAmount);

        if (cTokenRepay != cEther) {
            address underlying = ICErc20(cTokenRepay).underlying();

            IERC20(underlying).transferFrom(msg.sender, address(this), repayAmount);
            IERC20(underlying).approve(cTokenRepay, borrowedAmount);
            require(ICErc20(cTokenRepay).liquidateBorrow(borrower, borrowedAmount, cTokenCollateral) == 0, "liquidateBorrow failed");

            uint256 protocolFee = extraRepayAmount.mul(protocolFeeMantissa).div(1e18);
            uint256 remained = extraRepayAmount.sub(protocolFee);

            IERC20(underlying).approve(cTokenRepay, remained);
            require(ICErc20(cTokenRepay).mint(remained) == 0, "ctoken mint failed");
            IERC20(cTokenRepay).transfer(borrower, IERC20(cTokenRepay).balanceOf(address(this)));

            IERC20(underlying).transfer(protocolFeeRecipient, protocolFee);
        } else {
            require(msg.value == repayAmount, "incorrect ether amount");

            ICEther(cTokenRepay).liquidateBorrow{value: borrowedAmount}(borrower, cTokenCollateral);

            uint256 protocolFee = extraRepayAmount.mul(protocolFeeMantissa).div(1e18);
            uint256 remained = extraRepayAmount.sub(protocolFee);

            // borrower.transfer(remained);
            ICEther(cTokenRepay).mint{value: remained}();
            IERC20(cTokenRepay).transfer(borrower, IERC20(cTokenRepay).balanceOf(address(this)));

            protocolFeeRecipient.transfer(protocolFee);
        }

        // we ensure that all borrow balances are repaid fully
        require(ICErc20(cTokenRepay).borrowBalanceCurrent(borrower) == 0, "invalid token borrow balance");

        extraRepayAmount = 0;
    }

    function transferSeizedTokenFresh(address borrower, address cTokenCollateral, bool claimDToken) internal {
        uint256 seizedTokenAmount = ICErc721(cTokenCollateral).balanceOf(address(this));
        uint256 i;
        uint256 redeemTokenId;
        if (seizedTokenAmount > 0) {
            if (claimDToken) {
                for(; i < seizedTokenAmount; i++) {
                    ICErc721(cTokenCollateral).transfer(msg.sender, 0);
                }
            } else {
                ICErc721(cTokenCollateral).approve(cTokenCollateral, seizedTokenAmount);
                for(i = seizedTokenAmount - 1; i >= 0; i--) {
                    redeemTokenId = ICErc721(cTokenCollateral).userTokens(borrower, i);
                    ICErc721(cTokenCollateral).redeem(i);
                    IERC721(ICErc721(cTokenCollateral).underlying()).transferFrom(address(this), borrower, redeemTokenId);
                }
            }
        }

        // we ensure that all seized tokens transfered and all borrow balances are repaid fully
        require(ICErc721(cTokenCollateral).balanceOf(address(this)) == 0, "failed transfer all seized tokens");
        require(IERC721(ICErc721(cTokenCollateral).underlying()).balanceOf(address(this)) == 0, "failed transfer all seized tokens");

        delete seizeIndexes_;
    }

    // /**
    //  * @notice Execute the proxy liquidation with multiple tokens repay
    //  */
    // function liquidateWithMutipleRepay(address payable borrower, address cTokenCollateral, address cTokenRepay1, uint256 repayAmount1, address cTokenRepay2, uint256 repayAmount2) external nonReentrant {
    //     require(borrower != address(0), "invalid borrower address");

    //     (, , uint256 borrowerShortfall) = IComptroller(comptroller).getAccountLiquidity(borrower);
    //     require(borrowerShortfall > 0, "invalid borrower liquidity shortfall");

    //     // we do accrue interest before liquidation to ensure that repay will be done with full amount
    //     uint error = ICErc20(cTokenRepay1).accrueInterest();
    //     require(error == 0, "repay token accure interest failed");

    //     error = ICErc20(cTokenRepay2).accrueInterest();
    //     require(error == 0, "repay token accure interest failed");

    //     error = ICErc721(cTokenCollateral).accrueInterest();
    //     require(error == 0, "collateral token accure interest failed");

    //     liquidateWithMutipleRepayFresh(borrower, cTokenCollateral, cTokenRepay1, repayAmount1, cTokenRepay2, repayAmount2);
    // }

    // function liquidateWithMutipleRepayFresh(address payable borrower, address cTokenCollateral, address cTokenRepay1, uint256 repayAmount1, address cTokenRepay2, uint256 repayAmount2) internal {
    //     require(extraRepayAmount == 0, "invalid initial extra repay amount");

    //     uint256 seizeTokenBeforeBalance = ICErc721(cTokenCollateral).balanceOf(address(this));

    //     uint256 borrowedAmount1 = ICErc20(cTokenRepay1).borrowBalanceCurrent(borrower);
    //     uint256 borrowedAmount2 = ICErc20(cTokenRepay2).borrowBalanceCurrent(borrower);

    //     require(repayAmount1 >= borrowedAmount1, "invalid token1 repay amount");
    //     require(repayAmount2 >= borrowedAmount2, "invalid token2 repay amount");
    //     extraRepayAmount = repayAmount1.sub(borrowedAmount1).add(getExchangedAmount(cTokenRepay2, cTokenRepay1, repayAmount2));

    //     if (cTokenRepay1 != cEther) {
    //         require(msg.value == repayAmount2, "incorrect ether amount");

    //         address underlying = ICErc20(cTokenRepay1).underlying();

    //         require(ICErc20(cTokenRepay1).liquidateBorrow(borrower, borrowedAmount1, cTokenCollateral) == 0, "liquidateBorrow failed");
    //         ICEther(cTokenRepay2).repayBorrowBehalf{value: borrowedAmount2}(borrower);

    //         uint256 protocolFee = extraRepayAmount.mul(protocolFeeMantissa).div(1e18);
    //         uint256 remained = extraRepayAmount.sub(protocolFee);
    //         IERC20(underlying).transferFrom(msg.sender, borrower, remained);
    //         IERC20(underlying).transferFrom(msg.sender, protocolFeeRecipient, protocolFee);
    //     } else {
    //         require(msg.value == repayAmount1, "incorrect ether amount");

    //         ICEther(cTokenRepay1).liquidateBorrow{value: borrowedAmount1}(borrower, cTokenCollateral);
    //         require(ICErc20(cTokenRepay2).repayBorrowBehalf(borrower, borrowedAmount2) == 0,  "repayBorrowBehalf failed");

    //         uint256 protocolFee = extraRepayAmount.mul(protocolFeeMantissa).div(1e18);
    //         uint256 remained = extraRepayAmount.sub(protocolFee);
    //         borrower.transfer(remained);
    //         protocolFeeRecipient.transfer(protocolFee);
    //     }

    //     uint256 seizeTokenAfterBalance = ICErc721(cTokenCollateral).balanceOf(address(this));
    //     uint256 seizedTokenAmount = seizeTokenAfterBalance.sub(seizeTokenBeforeBalance);

    //     // require(possibleSeizeTokens == seizedTokenAmount, "invalid seized amount");

    //     if (seizedTokenAmount > 0) {
    //         for(uint256 i; i < seizedTokenAmount; i++) {
    //             ICErc721(cTokenCollateral).transfer(msg.sender, 0);
    //         }
    //         require(ICErc721(cTokenCollateral).balanceOf(address(this)) == 0, "failed transfer all seized tokens");
    //     }

    //     // we ensure all borrow balances are repaid fully
    //     require(ICErc20(cTokenRepay1).borrowBalanceCurrent(borrower) == 0, "invalid token1 borrow balance");
    //     require(ICErc20(cTokenRepay2).borrowBalanceCurrent(borrower) == 0, "invalid token2 borrow balance");

    //     extraRepayAmount = 0;
    // }

    struct GetExtraRepayLocalVars {
        uint256 cTokenCollateralBalance;
        uint256 cTokenCollateralExchangeRateMantissa;
        uint256 cTokenCollateralAmount;
        uint256 collateralValue;
        uint256 repayValue;
    }

    function getSingleTokenExtraRepayAmount(address payable borrower, address cTokenCollateral, address cTokenRepay, uint256 repayAmount) public view returns(uint256) {
        uint256 liquidationIncentiveMantissa = IComptroller(comptroller).liquidationIncentiveMantissa();

        GetExtraRepayLocalVars memory vars;

        (, vars.cTokenCollateralBalance, , vars.cTokenCollateralExchangeRateMantissa) = ICErc721(cTokenCollateral).getAccountSnapshot(borrower);
        vars.cTokenCollateralAmount = vars.cTokenCollateralBalance.mul(1e18).div(vars.cTokenCollateralExchangeRateMantissa);

        vars.collateralValue = getCTokenUnderlyingValue(cTokenCollateral, vars.cTokenCollateralAmount);
        vars.repayValue = (getCTokenUnderlyingValue(cTokenRepay, repayAmount)).mul(liquidationIncentiveMantissa).div(1e18);

        return vars.collateralValue.sub(vars.repayValue).div(getUnderlyingPrice(cTokenRepay));
    }

    function getBaseTokenExtraRepayAmount(address payable borrower, address cTokenCollateral, address cTokenRepay1, uint256 repayAmount1, address cTokenRepay2, uint256 repayAmount2) public view returns(uint256) {
        uint256 liquidationIncentiveMantissa = IComptroller(comptroller).liquidationIncentiveMantissa();

        GetExtraRepayLocalVars memory vars;

        (, vars.cTokenCollateralBalance, , vars.cTokenCollateralExchangeRateMantissa) = ICErc721(cTokenCollateral).getAccountSnapshot(borrower);
        vars.cTokenCollateralAmount = vars.cTokenCollateralBalance.mul(1e18).div(vars.cTokenCollateralExchangeRateMantissa);

        vars.collateralValue = getCTokenUnderlyingValue(cTokenCollateral, vars.cTokenCollateralAmount);
        vars.repayValue = (getCTokenUnderlyingValue(cTokenRepay1, repayAmount1).add(getCTokenUnderlyingValue(cTokenRepay2, repayAmount2)))
                                    .mul(liquidationIncentiveMantissa).div(1e18);

        return vars.collateralValue.sub(vars.repayValue).div(getUnderlyingPrice(cTokenRepay1));
    }

    function getCTokenUnderlyingValue(address cToken, uint256 underlyingAmount) public view returns (uint256) {
        address oracle = IComptroller(comptroller).oracle();
        uint256 underlyingPrice = IOracle(oracle).getUnderlyingPriceView(cToken);

        return underlyingPrice * underlyingAmount;
    }

    function getUnderlyingPrice(address cToken) public view returns (uint256) {
        address oracle = IComptroller(comptroller).oracle();
        return IOracle(oracle).getUnderlyingPriceView(cToken);
    }

    function getExchangedAmount(address cToken1, address cToken2, uint256 token1Amount) public view returns (uint256) {
        uint256 token1Price = getUnderlyingPrice(cToken1);
        uint256 token2Price = getUnderlyingPrice(cToken2);
        return token1Amount.mul(token1Price).div(token2Price);
    }

    /**
     * @dev Function to simply retrieve block number
     *  This exists mainly for inheriting test contracts to stub this result.
     */
    function getBlockNumber() internal view returns (uint) {
        return block.number;
    }

    /*** Admin functions ***/
    function initialize() onlyAdmin public {
        // The counter starts true to prevent changing it from zero to non-zero (i.e. smaller cost/refund)
        _notEntered = true;
    }

    function _become(NFTLiquidationProxy proxy) public {
        require(msg.sender == NFTLiquidationProxy(proxy).admin(), "only proxy admin can change brains");
        proxy._acceptImplementation();
    }

    function _setComptroller(address _comptroller) external onlyAdmin nonReentrant {
        require(_comptroller != address(0), "comptroller can not be zero");

        address oldComptroller = comptroller;
        comptroller = _comptroller;

        emit NewComptroller(oldComptroller, comptroller);
    }

    function setCEther(address _cEther) external onlyAdmin nonReentrant {
        require(_cEther != address(0), "invalid cToken address");
        require(ICEther(_cEther).isCToken() == true, "not cToken");

        cEther = _cEther;

        emit NewCEther(cEther);
    }

    function setProtocolFeeRecipient(address payable _protocolFeeRecipient) external onlyAdmin nonReentrant {
        require(_protocolFeeRecipient != address(0), "invalid recipient address");

        protocolFeeRecipient = _protocolFeeRecipient;

        emit NewProtocolFeeRecipient(protocolFeeRecipient);
    }

    function setProtocolFeeMantissa(uint256 _protocolFeeMantissa) external onlyAdmin nonReentrant {
        require(protocolFeeMantissa <= 1e18, "invalid fee");

        protocolFeeMantissa = _protocolFeeMantissa;

        emit NewProtocolFeeMantissa(protocolFeeMantissa);
    }

    /**
     * @notice Emergency withdraw the assets that the users have deposited
     * @param underlying The address of the underlying
     * @param withdrawAmount The amount of the underlying token to withdraw
     */
    function emergencyWithdraw(address underlying, uint256 withdrawAmount) external onlyAdmin nonReentrant {
        if (underlying == address(0)) {
            require(address(this).balance >= withdrawAmount);
            msg.sender.transfer(withdrawAmount);
        } else {
            require(IERC20(underlying).balanceOf(address(this)) >= withdrawAmount);
            IERC20(underlying).transfer(msg.sender, withdrawAmount);
        }

        emit EmergencyWithdraw(admin, underlying, withdrawAmount);
    }

    /**
     * @notice Emergency withdraw the NFTs
     * @param underlying The address of the underlying
     * @param tokenId The id of the underlying token to withdraw
     */
    function emergencyWithdrawNFT(address underlying, uint256 tokenId) external onlyAdmin nonReentrant {
        IERC721(underlying).transferFrom(address(this), msg.sender, tokenId);

        emit EmergencyWithdrawNFT(admin, underlying, tokenId);
    }

    /**
     * @notice payable function needed to receive ETH
     */
    fallback () payable external {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

abstract contract NFTLiquidationInterface {
    /// @notice Indicator that this is a NFTLiquidation contract (for inspection)
    bool public constant isNFTLiquidation = true;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./NFTLiquidationStorage.sol";
/**
 * @title NFTLiquidationCore
 * @dev Storage for the nft liquidation is at this address, while execution is delegated to the `nftLiquidationImplementation`.
 * CTokens should reference this contract as their nft liquidation.
 */
contract NFTLiquidationProxy is NFTLiquidationProxyStorage {

    /**
      * @notice Emitted when pendingNFTLiquidationImplementation is changed
      */
    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    /**
      * @notice Emitted when pendingNFTLiquidationImplementation is accepted, which means nft liquidation implementation is updated
      */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
      * @notice Emitted when pendingAdmin is changed
      */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
      * @notice Emitted when pendingAdmin is accepted, which means admin is updated
      */
    event NewAdmin(address oldAdmin, address newAdmin);

    constructor() public {
        // Set admin to caller
        admin = msg.sender;
    }

    /*** Admin Functions ***/
    function _setPendingImplementation(address newPendingImplementation) public {
        require(msg.sender == admin, "only admin");

        address oldPendingImplementation = pendingNFTLiquidationImplementation;

        pendingNFTLiquidationImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingNFTLiquidationImplementation);
    }

    /**
    * @notice Accepts new implementation of nft liquidation. msg.sender must be pendingImplementation
    * @dev Admin function for new implementation to accept it's role as implementation
    */
    function _acceptImplementation() public {
        // Check caller is pendingImplementation and pendingImplementation ≠ address(0)
        require(msg.sender == pendingNFTLiquidationImplementation && pendingNFTLiquidationImplementation != address(0), "only from pending implementation");

        // Save current values for inclusion in log
        address oldImplementation = nftLiquidationImplementation;
        address oldPendingImplementation = pendingNFTLiquidationImplementation;

        nftLiquidationImplementation = pendingNFTLiquidationImplementation;

        pendingNFTLiquidationImplementation = address(0);

        emit NewImplementation(oldImplementation, nftLiquidationImplementation);
        emit NewPendingImplementation(oldPendingImplementation, pendingNFTLiquidationImplementation);
    }

    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      */
    function _setPendingAdmin(address newPendingAdmin) public {
        // Check caller = admin
        require(msg.sender == admin, "only admin");

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    /**
      * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
      * @dev Admin function for pending admin to accept role and update admin
      */
    function _acceptAdmin() public returns (uint) {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(msg.sender == pendingAdmin && msg.sender != address(0), "only pending admin");

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

    /**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    fallback () payable external {
        // delegate all other functions to current implementation
        (bool success, ) = nftLiquidationImplementation.delegatecall(msg.data);

        assembly {
              let free_mem_ptr := mload(0x40)
              returndatacopy(free_mem_ptr, 0, returndatasize())

              switch success
              case 0 { revert(free_mem_ptr, returndatasize()) }
              default { return(free_mem_ptr, returndatasize()) }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract NFTLiquidationProxyStorage {
    /**
    * @notice Administrator for this contract
    */
    address public admin;

    /**
    * @notice Pending administrator for this contract
    */
    address public pendingAdmin;

    /**
    * @notice Active brains of NFTLiquidationProxy
    */
    address public nftLiquidationImplementation;

    /**
    * @notice Pending brains of NFTLiquidationProxy
    */
    address public pendingNFTLiquidationImplementation;
}

contract NFTLiquidationV1Storage is NFTLiquidationProxyStorage {
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
     * @notice Comptroller
     */
    address public comptroller;

    /**
     * @notice CEther
     */
    address public cEther;

    /**
     * @notice Protocol Fee Recipient
     */
    address payable public protocolFeeRecipient;

    /**
     * @notice Protocol Fee
     */
    uint256 public protocolFeeMantissa;

    /**
     * @notice Extra repay amount(unit is main repay token)
     */
    uint256 public extraRepayAmount;

    /**
     * @notice Requested seize NFT index array
     */
    uint256[] public seizeIndexes_;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}