// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {DataTypes} from "../libraries/DataTypes.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Errors} from "../libraries/Errors.sol";
import {ILPToken} from "../interfaces/ILPToken.sol";
import {LPToken} from "../amm/LPToken.sol";
import {MathHelpers} from "../libraries/MathHelpers.sol";
import {IPoolFactory1155} from "../interfaces/IPoolFactory1155.sol";
import {IAccessManager} from "../interfaces/IAccessManager.sol";
import {IAddressesRegistry} from "../interfaces/IAddressesRegistry.sol";
import {IAccessNFT} from "../interfaces/IAccessNFT.sol";
import {IStablecoinYieldConnector} from "../interfaces/IStablecoinYieldConnector.sol";
import {IConnectorRouter} from "../interfaces/IConnectorRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title library for pool logic functions for the 1155 Pools with single collection
 * @author Souq
 * @notice Defines the pure functions used by the 1155 contracts of the Souq protocol
 */

library Pool1155Logic {
    using Math for uint256;

    /**
     * @dev Emitted when stablecoins in the pool are deposited to a yield generating protocol
     * @param _admin The admin that executed the function
     * @param _amount The amount of stablecoins
     * @param _yieldGeneratorAddress The address of the yield generating protocol
     */
    event YieldDeposited(address _admin, uint256 _amount, address _yieldGeneratorAddress);
    /**
     * @dev Emitted when stablecoins in the pool are deposited to a yield generating protocol. The AToken is 1:1 the stable amount
     * @param _admin The admin that executed the function
     * @param _amount The amount of stablecoins
     * @param _yieldGeneratorAddress The address of the yield generating protocol
     */
    event YieldWithdrawn(address _admin, uint256 _amount, address _yieldGeneratorAddress);
    /**
     * @dev Emitted when tokens different than the tokens used by the pool are rescued for receivers by the admin
     * @param _admin The admin that executed the function
     * @param _token The address of the token contract
     * @param _amount The amount of tokens
     * @param _receiver The address of the receiver
     */
    event Rescued(address _admin, address _token, uint256 _amount, address _receiver);

    /**
     * @dev Emitted when a new LP Token is deployed
     * @param _LPAddress The address of the LP Token
     * @param _poolAddress The address of the liquidity pool that deployed it
     * @param _tokens the addresses of the ERC1155 tokens that the liquidity pool utilizes
     * @param _symbol the symbol of the LP Token
     * @param _name the name of the LP Token
     * @param _decimals the decimals of the LP Token
     */
    event LPTokenDeployed(address _LPAddress, address _poolAddress, address[] _tokens, string _symbol, string _name, uint8 _decimals);
    /**
     * @dev Emitted when a new sub pool is added by the admin
     * @param _admin The admin that executed the function
     * @param _F the initial F of the new pool
     * @param _V the initial V of the new pool
     * @param _id the id of the new sub pool
     */
    event AddedSubPool(address _admin, uint256 _V, uint256 _F, uint256 _id);

    /**
     * @dev Emitted when the V is updated for several subPools
     * @param _admin The admin that executed the function
     * @param _poolIds the indecies of the subPools
     * @param _v the array of the new v's for the subPools
     */
    event UpdatedV(address _admin, uint256[] _poolIds, uint256[] _v);

    /**
     * @dev Emitted when shares of a token id range in a subpool are moved to a new sub pool
     * @param _admin The admin that executed the function
     * @param _startId the start index of the token ids of the shares
     * @param _endId the end index of the token ids of the shares
     * @param _newSubPoolId the index of the new sub pool to move the shares to
     */
    event MovedShares(address _admin, uint256 _startId, uint256 _endId, uint256 _newSubPoolId);

    /**
     * @dev Emitted when shares of a token id array are moved to a new sub pool
     * @param _admin The admin that executed the function
     * @param _newSubPoolId the index of the new sub pool to move the shares to
     * @param _ids the array of token ids
     */
    event MovedSharesList(address _admin, uint256 _newSubPoolId, uint256[] _ids);

    /**
     * @dev Emmitted when the status of specific subpools is modified
     * @param _admin The admin that executed the function
     * @param _subPoolIds The sub pool ids array
     * @param _newStatus The new status, enabled=true or disabled=false
     */
    event ChangedSubpoolStatus(address _admin, uint256[] _subPoolIds, bool _newStatus);

    /**
     * @dev Emitted when reserve is moved between subpools
     * @param _admin The admin that executed the function
     * @param _moverId the id of the subpool to move funds from
     * @param _movedId the id of the subpool to move funds to
     * @param _amount the amount of funds to move
     */
    event MovedReserve(address _admin, uint256 _moverId, uint256 _movedId, uint256 _amount);

    /**
     * @dev Emitted when the accumulated fee balances are withdrawn by the royalties and protocol wallet addresses
     * @param _user The sender of the transaction
     * @param _to the address to send the funds to
     * @param _amount the amount being withdrawn
     * @param _type: string - the type of fee being withdrawan
     */
    event WithdrawnFees(address _user, address _to, uint256 _amount, string _type);

    /**
     * @dev Function to calculate the total value of a sub pool
     * @param subPools The sub pools array
     * @param _subPoolId the sub pool id
     * @return uint256 The total value of a subpool
     */
    function calculateTotal(DataTypes.AMMSubPool1155[] storage subPools, uint256 _subPoolId) public view returns (uint256) {
        return
            subPools[_subPoolId].reserve +
            MathHelpers.convertFromWad(subPools[_subPoolId].totalShares * subPools[_subPoolId].V * subPools[_subPoolId].F);
    }

    /**
     * @dev Function to get the total TVL of the liquidity pool from its subpools
     * @param subPools The subpools array
     * @return uint256 The TVL
     */
    function getTVL(DataTypes.AMMSubPool1155[] storage subPools) public view returns (uint256) {
        uint256 _total = 0;
        for (uint256 i = 0; i < subPools.length; i++) {
            _total += calculateTotal(subPools, i);
        }
        return _total;
    }

    /**
     * @dev Function to get the LP Token price by dividing the TVL over the total minted tokens
     * @param subPools The subpools array
     * @param poolLPToken The address of the LP Token
     * @return uint256 The LP Price
     */
    function getLPPrice(DataTypes.AMMSubPool1155[] storage subPools, address poolLPToken) external view returns (uint256) {
        uint256 _total = ILPToken(poolLPToken).getTotal();
        uint256 _TVL = getTVL(subPools);
        if (_total == 0 || _TVL == 0) {
            return MathHelpers.convertToWad(1);
        }
        return MathHelpers.convertToWad(_TVL) / _total;
    }

    /**
     * @dev Function to get the TVL and LP Token price together which saves gas if we need both variables
     * @param subPools The subpools array
     * @param poolLPToken The address of the LP Token
     * @return (uint256,uint256) The TVL and LP Price
     */
    function getTVLAndLPPrice(DataTypes.AMMSubPool1155[] storage subPools, address poolLPToken) external view returns (uint256, uint256) {
        uint256 _total = ILPToken(poolLPToken).getTotal();
        uint256 _TVL = getTVL(subPools);
        if (_total == 0 || _TVL == 0) {
            return (_TVL, MathHelpers.convertToWad(1));
        }
        return (_TVL, (MathHelpers.convertToWad(_TVL) / _total));
    }

    /**
     * @dev Function to get the actual fee value structure depending on swap direction
     * @param _operation The direction of the swap
     * @param _value value of the amount to compute the fees for
     * @param fee The fee configuration of the liquidity pool
     * @return _fee The return fee structure that has the ratios
     */
    function calculateFees(
        DataTypes.OperationType _operation,
        uint256 _value,
        DataTypes.PoolFee storage fee
    ) public view returns (DataTypes.FeeReturn memory _fee) {
        uint256 actualValue;
        if (_operation == DataTypes.OperationType.buyShares) {
            actualValue = MathHelpers.convertFromWadPercentage(_value * (MathHelpers.convertToWadPercentage(1) - fee.lpBuyFee));
            _fee.royalties = MathHelpers.convertFromWadPercentage(fee.royaltiesBuyFee * actualValue);
            _fee.lpFee = MathHelpers.convertFromWadPercentage(fee.lpBuyFee * _value);
            _fee.protocolFee = MathHelpers.convertFromWadPercentage(fee.lpBuyFee * fee.protocolBuyRatio * actualValue) / 100;
        } else if (_operation == DataTypes.OperationType.sellShares) {
            actualValue = MathHelpers.convertToWadPercentage(_value) / (MathHelpers.convertToWadPercentage(1) - fee.lpBuyFee);
            _fee.royalties = MathHelpers.convertFromWadPercentage(fee.royaltiesSellFee * actualValue);
            _fee.lpFee = MathHelpers.convertFromWadPercentage(fee.lpSellFee * _value);
            _fee.protocolFee = MathHelpers.convertFromWadPercentage(fee.lpSellFee * fee.protocolSellRatio * actualValue) / 100;
        }
        _fee.swapFee = _fee.lpFee + _fee.protocolFee;
        _fee.totalFee = _fee.royalties + _fee.swapFee;
    }

    /**
     * @dev Function to add two feeReturn structures and output 1
     * @param x the first feeReturn struct
     * @param y the second feeReturn struct
     * @return z The return data structure
     */
    function addFees(DataTypes.FeeReturn memory x, DataTypes.FeeReturn memory y) public pure returns (DataTypes.FeeReturn memory z) {
        //Add all the fees together
        z.totalFee = x.totalFee + y.totalFee;
        z.royalties = x.royalties + y.royalties;
        z.protocolFee = x.protocolFee + y.protocolFee;
        z.lpFee = x.lpFee + y.lpFee;
        z.swapFee = x.swapFee + y.swapFee;
    }

    /**
     * @dev Function to calculate the price of a share in a sub pool\
     * @param _operation the operation direction
     * @param subPools The sub pools array
     * @param _subPoolId the sub pool id
     * @param poolData the pool data
     * @return _sharesReturn The return data structure
     */
    function CalculateShares(
        DataTypes.OperationType _operation,
        DataTypes.AMMSubPool1155[] storage subPools,
        uint256 _subPoolId,
        DataTypes.PoolData storage poolData,
        uint256 _shares,
        bool useFee
    ) external view returns (DataTypes.SharesCalculationReturn memory _sharesReturn) {
        require(
            subPools[_subPoolId].totalShares >= _shares || _operation != DataTypes.OperationType.buyShares,
            Errors.NOT_ENOUGH_SUBPOOL_SHARES
        );
        //Iterative approach
        DataTypes.SharesCalculationVars memory vars;
        //Initial values
        vars.V = subPools[_subPoolId].V;
        vars.PV_0 = MathHelpers.convertFromWad(vars.V * subPools[_subPoolId].F);
        _sharesReturn.PV = vars.PV_0;
        //Calculate steps
        vars.steps = _shares / poolData.iterativeLimit.maxBulkStepSize;
        //At first the stable = reserve
        vars.stable = subPools[_subPoolId].reserve;
        vars.shares = subPools[_subPoolId].totalShares;
        //Iterating step sizes for enhanced results. If amount = 50, and stepsize is 15, then we iterate 4 times 15,15,15,5
        for (vars.stepIndex = 0; vars.stepIndex < vars.steps + 1; vars.stepIndex++) {
            vars.stepAmount = vars.stepIndex == vars.steps
                ? (_shares - ((vars.stepIndex) * poolData.iterativeLimit.maxBulkStepSize))
                : poolData.iterativeLimit.maxBulkStepSize;
            if (vars.stepAmount == 0) break;
            //The value of the shares are priced first at last PV
            vars.value = vars.stepAmount * vars.PV_0;
            if (useFee) vars.fees = calculateFees(_operation, vars.value, poolData.fee);
            //Iterate the calculations while keeping PV_0 and stable the same and using the new PV to calculate the average and reiterate
            for (vars.i = 0; vars.i < poolData.iterativeLimit.iterations; vars.i++) {
                if (_operation == DataTypes.OperationType.buyShares) {
                    //if buying shares, the pool receives stable plus the swap fee and gives out shares
                    vars.newCash = vars.stable + vars.value + (useFee ? vars.fees.lpFee : 0);
                    vars.den =
                        vars.newCash +
                        ((poolData.coefficientB * (vars.shares - vars.stepAmount) * _sharesReturn.PV) / poolData.coefficientC);
                } else if (_operation == DataTypes.OperationType.sellShares) {
                    require(vars.stable >= vars.value, Errors.NOT_ENOUGH_SUBPOOL_RESERVE);
                    //if selling shares, the pool receives shares and gives out stable - total fees from the reserve
                    vars.newCash = vars.stable - vars.value + (useFee ? vars.fees.lpFee : 0);
                    vars.den =
                        vars.newCash +
                        ((poolData.coefficientB * (vars.shares + vars.stepAmount) * _sharesReturn.PV) / poolData.coefficientC);
                }
                //Calculate new PV and F
                _sharesReturn.F = vars.den == 0 ? 0 : (poolData.coefficientA * vars.newCash) / vars.den;
                _sharesReturn.PV = MathHelpers.convertFromWad(vars.V * _sharesReturn.F);
                //Swap PV is the price used for the swapping in the newCash
                vars.swapPV = vars.stepAmount > 1 ? ((_sharesReturn.PV + vars.PV_0) / 2) : (vars.stepAmount * _sharesReturn.PV);
                vars.value = vars.stepAmount > 1 ? vars.stepAmount * vars.swapPV : vars.stepAmount * _sharesReturn.PV;
                if (useFee) vars.fees = calculateFees(_operation, vars.value, poolData.fee);
            }
            //We add/subtract the shares to be used in the next stepsize iteration
            vars.shares = _operation == DataTypes.OperationType.buyShares ? vars.shares - vars.stepAmount : vars.shares + vars.stepAmount;
            //At the end of iterations, the stable is now the last cash value
            vars.stable = vars.newCash;
            //The starting PV is now the last PV value
            vars.PV_0 = _sharesReturn.PV;
            //Add the amounts to the return
            _sharesReturn.amount += vars.stepAmount;
        }
        //Calculate the actual value to return
        _sharesReturn.value = _operation == DataTypes.OperationType.buyShares
            ? vars.stable - subPools[_subPoolId].reserve
            : subPools[_subPoolId].reserve - vars.stable;
        //Calculate the final fees
        if (useFee) _sharesReturn.fees = calculateFees(_operation, _sharesReturn.value, poolData.fee);
        //Average the swap PV in the return
        _sharesReturn.swapPV = _sharesReturn.value / _sharesReturn.amount;
    }

    /**
     * @dev Function to update the price in a subpool
     * @param subPools The sub pools array
     * @param coefficientA the coefficient A of the equation
     * @param coefficientB the coefficient B of the equation
     * @param coefficientC the coefficient C of the equation
     * @param _subPoolId the sub pool id
     */
    function updatePrice(
        DataTypes.AMMSubPool1155[] storage subPools,
        uint256 coefficientA,
        uint256 coefficientB,
        uint256 coefficientC,
        uint256 _subPoolId
    ) public {
        //coef is converted to wad but we also need F to be converted to wad
        uint256 num = ((coefficientA * subPools[_subPoolId].reserve));
        uint256 den = (subPools[_subPoolId].reserve +
            (MathHelpers.convertFromWad(coefficientB * subPools[_subPoolId].totalShares * subPools[_subPoolId].F * subPools[_subPoolId].V) /
                coefficientC));
        subPools[_subPoolId].F = den == 0 ? 0 : num / den;
    }

    /**
     * @dev Function to add a new sub pool
     * @param _V The initial V value of the sub pool
     * @param _F The initial F value of the sub pool
     * @param subPools The subpools array
     */
    function addSubPool(uint256 _V, uint256 _F, DataTypes.AMMSubPool1155[] storage subPools) external {
        DataTypes.AMMSubPool1155 storage _newPool = subPools.push();
        _newPool.reserve = 0;
        _newPool.totalShares = 0;
        _newPool.V = _V;
        _newPool.F = _F;
        _newPool.status = true;
        emit AddedSubPool(msg.sender, _V, _F, subPools.length - 1);
    }

    /**
     *@dev Function to update the V of the subpools
     *@param _subPoolIds the array of subpool ids to update
     *@param _vs The array of V to update
     *@param subPools The subpools array
     */
    function updatePoolV(uint256[] calldata _subPoolIds, uint256[] calldata _vs, DataTypes.AMMSubPool1155[] storage subPools) external {
        require(_subPoolIds.length == _vs.length, Errors.ARRAY_NOT_SAME_LENGTH);
        for (uint256 i = 0; i < _subPoolIds.length; i++) {
            subPools[_subPoolIds[i]].V = _vs[i];
        }
        emit UpdatedV(msg.sender, _subPoolIds, _vs);
    }

    /**
     *@dev Function to move shares between sub pools
     *@param _startId The starting token id inside the subpool
     *@param _endId The ending token id inside the subpool
     *@param _newSubPoolId The id of the new subpool
     *@param subPools The subpools array
     *@param tokenDistribution The token distribution mapping of the liquidity pool
     */
    function moveShares(
        uint256 _startId,
        uint256 _endId,
        uint256 _newSubPoolId,
        DataTypes.AMMSubPool1155[] storage subPools,
        DataTypes.PoolData storage poolData,
        mapping(uint256 => uint256) storage tokenDistribution
    ) external {
        DataTypes.MoveSharesVars memory vars;
        for (vars.i = _startId; vars.i < _endId + 1; vars.i++) {
            vars.poolId = tokenDistribution[vars.i];
            if (subPools[_newSubPoolId].shares[vars.i] > 0) {
                subPools[_newSubPoolId].shares[vars.i] = subPools[vars.poolId].shares[vars.i];
                subPools[vars.poolId].shares[vars.i] = 0;
                updatePrice(subPools, poolData.coefficientA, poolData.coefficientB, poolData.coefficientC, vars.poolId);
            }
            tokenDistribution[vars.i] = _newSubPoolId;
        }
        emit MovedShares(msg.sender, _startId, _endId, _newSubPoolId);
    }

    /**
     *@dev Function to move shares between sub pools
     *@param _newSubPoolId The id of the new subpool
     *@param _ids The token ids array to move
     *@param subPools The subpools array
     *@param tokenDistribution The token distribution mapping of the liquidity pool
     */
    function moveSharesList(
        uint256 _newSubPoolId,
        uint256[] calldata _ids,
        DataTypes.AMMSubPool1155[] storage subPools,
        DataTypes.PoolData storage poolData,
        mapping(uint256 => uint256) storage tokenDistribution
    ) external {
        DataTypes.MoveSharesVars memory vars;
        for (vars.i = 0; vars.i < _ids.length; vars.i += 1) {
            vars.poolId = tokenDistribution[_ids[vars.i]];
            if (subPools[_newSubPoolId].shares[_ids[vars.i]] > 0) {
                subPools[_newSubPoolId].shares[_ids[vars.i]] = subPools[vars.poolId].shares[_ids[vars.i]];
                subPools[vars.poolId].shares[_ids[vars.i]] = 0;
                updatePrice(subPools, poolData.coefficientA, poolData.coefficientB, poolData.coefficientC, vars.poolId);
            }
            tokenDistribution[_ids[vars.i]] = _newSubPoolId;
        }
        emit MovedSharesList(msg.sender, _newSubPoolId, _ids);
    }

    /**
     * @dev Function to move enable or disable subpools by ids
     * @param _subPoolIds The sub pool ids array
     * @param _newStatus The new status, enabled=true or disabled=false
     * @param subPools The subpools array
     */
    function changeSubPoolStatus(uint256[] memory _subPoolIds, bool _newStatus, DataTypes.AMMSubPool1155[] storage subPools) external {
        for (uint256 i = 0; i < _subPoolIds.length; i++) {
            subPools[_subPoolIds[i]].status = _newStatus;
        }
        emit ChangedSubpoolStatus(msg.sender, _subPoolIds, _newStatus);
    }

    /**
     * @dev Function to move reserves between subpools
     * @param _moverId The sub pool that will move the funds from
     * @param _movedId The id of the sub pool that will move the funds to
     * @param _amount The amount to move
     * @param subPools The subpools array
     */
    function moveReserve(
        uint256 _moverId,
        uint256 _movedId,
        uint256 _amount,
        DataTypes.AMMSubPool1155[] storage subPools,
        DataTypes.PoolData storage poolData
    ) external {
        require(subPools[_moverId].reserve >= _amount, Errors.NOT_ENOUGH_SUBPOOL_RESERVE);
        require(subPools.length > _moverId && subPools.length > _movedId, Errors.NOT_ENOUGH_SUBPOOL_RESERVE);
        subPools[_moverId].reserve -= _amount;
        updatePrice(subPools, poolData.coefficientA, poolData.coefficientB, poolData.coefficientC, _moverId);
        subPools[_movedId].reserve += _amount;
        updatePrice(subPools, poolData.coefficientA, poolData.coefficientB, poolData.coefficientC, _movedId);
        emit MovedReserve(msg.sender, _moverId, _movedId, _amount);
    }

    function getSubPools(
        uint256[] memory _tokenIds,
        mapping(uint256 => uint256) storage tokenDistribution
    ) external view returns (uint256[] memory) {
        uint256[] memory _pools = new uint256[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _pools[i] = tokenDistribution[_tokenIds[i]];
        }
        return _pools;
    }

    function getSubPoolsSeq(
        uint256 _startTokenId,
        uint256 _endTokenId,
        mapping(uint256 => uint256) storage tokenDistribution
    ) external view returns (uint256[] memory _pools) {
        require(_startTokenId <= _endTokenId, "END_ID_LESS_THAN_START");
        _pools = new uint256[](_endTokenId - _startTokenId + 1);
        for (uint256 i = _startTokenId; i < _endTokenId + 1; i++) {
            _pools[i] = tokenDistribution[i];
        }
    }

    function deployLPToken(
        address _poolAddress,
        address _registry,
        address[] memory _tokens,
        string memory _symbol,
        string memory _name,
        uint8 _decimals
    ) external returns (address) {
        ILPToken _poolLPToken = new LPToken(_poolAddress, _registry, _tokens, _symbol, _name, _decimals);
        emit LPTokenDeployed(address(_poolLPToken), _poolAddress, _tokens, _symbol, _name, _decimals);
        return address(_poolLPToken);
    }

    //TODO: check if only admin can execute
    /**
     * @dev Function to rescue and send ERC20 tokens (different than the tokens used by the pool) to a receiver called by the admin
     * @param _token The address of the token contract
     * @param _amount The amount of tokens
     * @param _receiver The address of the receiver
     * @param _stableToken The address of the stablecoin to rescue
     * @param _poolLPToken The address of the pool LP Token
     */
    function RescueTokens(address _token, uint256 _amount, address _receiver, address _stableToken, address _poolLPToken) external {
        require(msg.sender != address(0), "INVALID_ADMIN");
        require(_token != _stableToken, Errors.CANNOT_RESCUE_POOL_TOKEN);
        ILPToken(_poolLPToken).RescueTokens(_token, _amount, _receiver);
        emit Rescued(msg.sender, _token, _amount, _receiver);
    }

    /**
     * @dev Function to deposit stablecoins from the pool to a yield generating protocol and getting synthetic tokens
     * @param _amount The amount of stablecoins
     * @param _addressesRegistry The addresses Registry contract address
     * @param _stableYieldAddress The stable yield contract address
     * @param _yieldReserve The old yield reserve
     */
    function depositIntoStableYield(
        uint256 _amount,
        address _addressesRegistry,
        address _stableYieldAddress,
        uint256 _yieldReserve
    ) external returns (uint256) {
        require(msg.sender != address(0), "INVALID_ADMIN");

        IStablecoinYieldConnector(
            IConnectorRouter(IAddressesRegistry(_addressesRegistry).getConnectorsRouter()).getStablecoinYieldConnectorContract(
                _stableYieldAddress
            )
        ).depositUSDC(_amount);

        emit YieldDeposited(msg.sender, _amount, _stableYieldAddress);

        // Return the updated yield reserve value
        return _yieldReserve + _amount;
    }

    /**
     * @dev Function to withdraw stablecoins from the yield generating protocol to the liquidity pool
     * @param _amount The amount of stablecoins
     * @param _addressesRegistry The addresses Registry contract address
     * @param _stableYieldAddress The stable yield contract address
     * @param _yieldReserve The old yield reserve
     */
    function withdrawFromStableYield(
        uint256 _amount,
        address _addressesRegistry,
        address _stableYieldAddress,
        uint256 _yieldReserve
    ) external returns (uint256) {
        require(msg.sender != address(0), "INVALID_ADMIN");
        IStablecoinYieldConnector _stableConnector = IStablecoinYieldConnector(
            IConnectorRouter(IAddressesRegistry(_addressesRegistry).getConnectorsRouter()).getStablecoinYieldConnectorContract(
                _stableYieldAddress
            )
        );
        address _aTokenAddress = _stableConnector.getATokenAddress();
        require(IERC20(_aTokenAddress).balanceOf(address(this)) >= _amount, Errors.INVALID_AMOUNT);
        IERC20(_aTokenAddress).approve(address(_stableConnector), _amount);
        _stableConnector.withdrawUSDC(_amount, _amount);
        emit YieldWithdrawn(msg.sender, _amount, _stableYieldAddress);

        // Return the updated yield reserve value
        return _yieldReserve - _amount;
    }

    //Withdraw fees by royalties or protocol addresses
    function withdrawFees(
        address _user,
        address _to,
        uint256 _amount,
        DataTypes.FeeType _feeType,
        DataTypes.PoolData storage poolData
    ) external {
        if (_feeType == DataTypes.FeeType.royalties && _user == poolData.fee.royaltiesAddress && _amount <= poolData.fee.royaltiesBalance) {
            poolData.fee.royaltiesBalance -= _amount;
            ILPToken(poolData.poolLPToken).setApproval20(poolData.stable, _amount);
            IERC20(poolData.stable).transferFrom(poolData.poolLPToken, _to, _amount);
            emit WithdrawnFees(_user, _to, _amount, "royalties");
        }
        if (_feeType == DataTypes.FeeType.protocol && _user == poolData.fee.protocolFeeAddress && _amount <= poolData.fee.protocolBalance) {
            poolData.fee.protocolBalance -= _amount;
            ILPToken(poolData.poolLPToken).setApproval20(poolData.stable, _amount);
            IERC20(poolData.stable).transferFrom(poolData.poolLPToken, _to, _amount);
            emit WithdrawnFees(_user, _to, _amount, "protocol");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IAddressesRegistry} from "../interfaces/IAddressesRegistry.sol";
import {Errors} from "../libraries/Errors.sol";
import {ILPToken} from "../interfaces/ILPToken.sol";

//import { console } from "../../node_modules/hardhat/console.sol";

contract LPToken is ILPToken, ERC20, ERC20Burnable, Pausable, Ownable {
    address internal _underlyingAsset;
    
    IAddressesRegistry internal immutable _addressesRegistry;
    address public immutable pool;
    uint8 public immutable tokenDecimals;

    constructor(
        address _pool,
        address _registry,
        address[] memory _tokens,
        string memory _symbol,
        string memory _name,
        uint8 _decimals
    ) ERC20(_name, _symbol) {
        tokenDecimals = _decimals;
        pool = _pool;
        _addressesRegistry = IAddressesRegistry(_registry);
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC1155(_tokens[i]).setApprovalForAll(address(pool), true);
        }
    }

    modifier onlyPool() {
        require(_msgSender() == address(pool), Errors.CALLER_MUST_BE_POOL);
        _;
    }

    function decimals() override public view returns (uint8) {
        return tokenDecimals;
    }

    /// @inheritdoc ILPToken
    function getTotal() external view returns (uint256) {
        return totalSupply();
    }

    function getBalanceOf(address _account) external view returns (uint256) {
        return balanceOf(_account);
    }

    function getDecimals() internal view returns (uint256) {
        return 10 ** decimals();
    }

    function pause() public onlyPool {
        _pause();
    }

    function unpause() public onlyPool {
        _unpause();
    }

    function checkPaused() public view returns(bool) {
        return paused();
    }

    //TODO: Function added so that we don't approve max stable. Can be replaced
    function setApproval20(address _token, uint256 _amount) external onlyPool {
        IERC20(_token).approve(pool, _amount);
    }

    function mint(address _to, uint256 _amount) external onlyPool {
        //_mint already emits a transfer event
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external onlyPool {
        //_burn already emits a transfer event
        _burn(_from, _amount);
    }

    function RescueTokens(address _token, uint256 _amount, address _receiver) external onlyPool {
        //event emitted in the pool
        IERC20(_token).transfer(_receiver, _amount);
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IAddressesRegistry} from "./IAddressesRegistry.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

/**
 * @title IAccessManager
 * @notice The interface for the Access Manager Contract
 */
interface IAccessManager is IAccessControl {
    /**
     * @notice Returns the contract address of the PoolAddressesProvider
     * @return The address of the PoolAddressesProvider
     */
    function ADDRESSES_PROVIDER() external view returns (IAddressesRegistry);

    /**
     * @notice Returns the identifier of the PoolAdmin role
     * @return The id of the PoolAdmin role
     */
    function POOL_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the EmergencyAdmin role
     * @return The id of the EmergencyAdmin role
     */
    function EMERGENCY_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the OracleAdmin role
     * @return The id of the Oracle role
     */
    function ORACLE_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the ConnectorRouterAdmin role
     * @return The id of the ConnectorRouterAdmin role
     */
    function CONNECTOR_ROUTER_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the StablecoinYieldConnectorAdmin role
     * @return The id of the StablecoinYieldConnectorAdmin role
     */
    function STABLECOIN_YIELD_CONNECTOR_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the StablecoinYieldConnectorLender role
     * @return The id of the StablecoinYieldConnectorLender role
     */
    function STABLECOIN_YIELD_CONNECTOR_LENDER_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the UpgraderAdmin role
     * @return The id of the UpgraderAdmin role
     */

    function UPGRADER_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the TimelockAdmin role
     * @return The id of the TimelockAdmin role
     */

    function TIMELOCK_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Set the role as admin of a specific role.
     * @dev By default the admin role for all roles is `DEFAULT_ADMIN_ROLE`.
     * @param role The role to be managed by the admin role
     * @param adminRole The admin role
     */

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

    /**
     * @notice Adds a new admin as PoolAdmin
     * @param admin The address of the new admin
     */
    function addPoolAdmin(address admin) external;

    /**
     * @notice Removes an admin as PoolAdmin
     * @param admin The address of the admin to remove
     */
    function removePoolAdmin(address admin) external;

    /**
     * @notice Returns true if the address is PoolAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is PoolAdmin, false otherwise
     */
    function isPoolAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new admin as EmergencyAdmin
     * @param admin The address of the new admin
     */
    function addEmergencyAdmin(address admin) external;

    /**
     * @notice Removes an admin as EmergencyAdmin
     * @param admin The address of the admin to remove
     */
    function removeEmergencyAdmin(address admin) external;

    /**
     * @notice Returns true if the address is EmergencyAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is EmergencyAdmin, false otherwise
     */
    function isEmergencyAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new admin as OracleAdmin
     * @param admin The address of the new admin
     */
    function addOracleAdmin(address admin) external;

    /**
     * @notice Removes an admin as OracleAdmin
     * @param admin The address of the admin to remove
     */
    function removeOracleAdmin(address admin) external;

    /**
     * @notice Returns true if the address is OracleAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is OracleAdmin, false otherwise
     */
    function isOracleAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new admin as ConnectorRouterAdmin
     * @param admin The address of the new admin
     */
    function addConnectorAdmin(address admin) external;

    /**
     * @notice Removes an admin as ConnectorRouterAdmin
     * @param admin The address of the admin to remove
     */
    function removeConnectorAdmin(address admin) external;

    /**
     * @notice Returns true if the address is ConnectorRouterAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is ConnectorRouterAdmin, false otherwise
     */
    function isConnectorAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new admin as StablecoinYieldConnectorAdmin
     * @param admin The address of the new admin
     */
    function addStablecoinYieldAdmin(address admin) external;

    /**
     * @notice Removes an admin as StablecoinYieldConnectorAdmin
     * @param admin The address of the admin to remove
     */
    function removeStablecoinYieldAdmin(address admin) external;

    /**
     * @notice Returns true if the address is StablecoinYieldConnectorAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is StablecoinYieldConnectorAdmin, false otherwise
     */
    function isStablecoinYieldAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new admin as StablecoinYieldLender
     * @param lender The address of the new lender
     */
    function addStablecoinYieldLender(address lender) external;

    /**
     * @notice Removes an lender as StablecoinYieldLender
     * @param lender The address of the lender to remove
     */
    function removeStablecoinYieldLender(address lender) external;

    /**
     * @notice Returns true if the address is StablecoinYieldLender, false otherwise
     * @param lender The address to check
     * @return True if the given address is StablecoinYieldLender, false otherwise
     */
    function isStablecoinYieldLender(address lender) external view returns (bool);

    /**
     * @notice Adds a new admin as UpgraderAdmin
     * @param admin The address of the new admin
     */
    function addUpgraderAdmin(address admin) external;

    /**
     * @notice Removes an admin as UpgraderAdmin
     * @param admin The address of the admin to remove
     */
    function removeUpgraderAdmin(address admin) external;

    /**
     * @notice Returns true if the address is UpgraderAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is UpgraderAdmin, false otherwise
     */
    function isUpgraderAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new admin as TimelockAdmin
     * @param admin The address of the new admin
     */
    function addTimelockAdmin(address admin) external;

    /**
     * @notice Removes an admin as TimelockAdmin
     * @param admin The address of the admin to remove
     */
    function removeTimelockAdmin(address admin) external;

    /**
     * @notice Returns true if the address is TimelockAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is TimelockAdmin, false otherwise
     */
    function isTimelockAdmin(address admin) external view returns (bool);
    
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

/**
 * @title IAccessNFT
 * @author Souq
 * @notice Defines the interface of the access NFT.
 */
interface IAccessNFT {

    event DeadlineSet(string functionName, bytes32 functionHash, uint256 deadline, uint256 tokenId);
    
    event ToggleDeadlines(bool deadlinesOn);

    function HasAccessNFT(address _user, uint256 tokenId, string calldata functionName) external view returns (bool);


}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

/**
 * @title IAddressesRegistry
 * @author Souq
 * @notice Defines the interface of the addresses registry.
 */
interface IAddressesRegistry {
    /**
     * @dev Emitted when the connectors router address is updated.
     * @param oldAddress The old address
     * @param newAddress The new address
     */
    event RouterUpdated(address indexed oldAddress, address indexed newAddress);
    /**
     * @dev Emitted when the Access manager address is updated.
     * @param oldAddress The old address
     * @param newAddress The new address
     */
    event AccessManagerUpdated(address indexed oldAddress, address indexed newAddress);
    /**
     * @dev Emitted when the access admin address is updated.
     * @param oldAddress The old address
     * @param newAddress The new address
     */
    event AccessAdminUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the collection connector address is updated.
     * @param oldAddress the old address
     * @param newAddress the new address
     */
    event CollectionConnectorUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when a specific pool factory address is updated.
     * @param id The short id of the pool factory.
     * @param oldAddress The old address
     * @param newAddress The new address
     */

    event PoolFactoryUpdated(bytes32 id, address indexed oldAddress, address indexed newAddress);
    /**
     * @dev Emitted when a specific pool factory address is added.
     * @param id The short id of the pool factory.
     * @param newAddress The new address
     */
    event PoolFactoryAdded(bytes32 id, address indexed newAddress);
    /**
     * @dev Emitted when a specific vault factory address is updated.
     * @param id The short id of the vault factory.
     * @param oldAddress The old address
     * @param newAddress The new address
     */
    event VaultFactoryUpdated(bytes32 id, address indexed oldAddress, address indexed newAddress);
    /**
     * @dev Emitted when a specific vault factory address is added.
     * @param id The short id of the vault factory.
     * @param newAddress The new address
     */
    event VaultFactoryAdded(bytes32 id, address indexed newAddress);
    /**
     * @dev Emitted when a any address is updated.
     * @param id The full id of the address.
     * @param oldAddress The old address
     * @param newAddress The new address
     */
    event AddressUpdated(bytes32 id, address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when a proxy is deployed for an implementation
     * @param id The full id of the address to be saved
     * @param logic The address of the implementation
     * @param proxy The address of the proxy deployed in that id slot
     */
    event ProxyDeployed(bytes32 id, address indexed logic, address indexed proxy);

    /**
     * @dev Emitted when a proxy is deployed for an implementation
     * @param id The full id of the address to be upgraded
     * @param newLogic The address of the new implementation
     * @param proxy The address of the proxy that was upgraded
     */
    event ProxyUpgraded(bytes32 id, address indexed newLogic, address indexed proxy);

    /**
     * @notice Returns the address of the identifier.
     * @param _id The id of the contract
     * @return The Pool proxy address
     */
    function getAddress(bytes32 _id) external view returns (address);

    /**
     * @notice Sets the address of the identifier.
     * @param _id The id of the contract
     * @param _add The address to set
     */
    function setAddress(bytes32 _id, address _add) external;

    /**
     * @notice Returns the address of the connectors router defined as: CONNECTORS_ROUTER
     * @return The address
     */
    function getConnectorsRouter() external view returns (address);

    /**
     * @notice Sets the address of the Connectors router.
     * @param _add The address to set
     */
    function setConnectorsRouter(address _add) external;

    /**
     * @notice Returns the address of access manager defined as: ACCESS_MANAGER
     * @return The address
     */
    function getAccessManager() external view returns (address);

    /**
     * @notice Sets the address of the Access Manager.
     * @param _add The address to set
     */
    function setAccessManager(address _add) external;

    /**
     * @notice Returns the address of access admin defined as: ACCESS_ADMIN
     * @return The address
     */
    function getAccessAdmin() external view returns (address);

    /**
     * @notice Sets the address of the Access Admin.
     * @param _add The address to set
     */
    function setAccessAdmin(address _add) external;

    /**
     * @notice Returns the address of the specific pool factory short id
     * @param _id The pool factory id such as "SVS"
     * @return The address
     */
    function getPoolFactoryAddress(bytes32 _id) external view returns (address);

    /**
     * @notice Returns the full id of pool factory short id
     * @param _id The pool factory id such as "SVS"
     * @return The full id
     */
    function getIdFromPoolFactory(bytes32 _id) external view returns (bytes32);

    /**
     * @notice Sets the address of a specific pool factory using short id.
     * @param _id the pool factory short id
     * @param _add The address to set
     */
    function setPoolFactory(bytes32 _id, address _add) external;

    /**
     * @notice adds a new pool factory with address and short id. The short id will be converted to full id and saved.
     * @param _id the pool factory short id
     * @param _add The address to add
     */
    function addPoolFactory(bytes32 _id, address _add) external;

    /**
     * @notice Returns the address of the specific vault factory short id
     * @param _id The vault id such as "SVS"
     * @return The address
     */
    function getVaultFactoryAddress(bytes32 _id) external view returns (address);

    /**
     * @notice Returns the full id of vault factory id
     * @param _id The vault factory id such as "SVS"
     * @return The full id
     */
    function getIdFromVaultFactory(bytes32 _id) external view returns (bytes32);

    /**
     * @notice Sets the address of a specific vault factory using short id.
     * @param _id the vault factory short id
     * @param _add The address to set
     */
    function setVaultFactory(bytes32 _id, address _add) external;

    /**
     * @notice adds a new vault factory with address and short id. The short id will be converted to full id and saved.
     * @param _id the vault factory short id
     * @param _add The address to add
     */
    function addVaultFactory(bytes32 _id, address _add) external;

    /**
     * @notice Deploys a proxy for an implimentation and initializes then saves in the registry.
     * @param _id the full id to be saved.
     * @param _logic The address of the implementation
     * @param _data The initialization low data
     */
    function updateImplementation(bytes32 _id, address _logic, bytes memory _data) external;

    /**
     * @notice Updates a proxy with a new implementation logic while keeping the store intact.
     * @param _id the full id to be saved.
     * @param _logic The address of the new implementation
     */
    function updateProxy(bytes32 _id, address _logic) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {DataTypes} from "../libraries/DataTypes.sol";
/**
 * @title IConnectorRouter
 * @author Souq
 * @notice Defines the interface of the connector router
 */
interface IConnectorRouter {

function initialize(address _timelock) external;
function getYieldDistributor(address vaultAddress) external view returns (address);
function setYieldDistributor(address vaultAddress, address yieldDistributorAddress) external;
function updateYieldDistributor(address vaultAddress, address yieldDistributorAddress) external;
function deleteYieldDistributor(address vaultAddress) external;
function getStakingContract(address tokenAddress) external view returns (address);
function setStakingContract(address tokenAddress, address stakingContractAddress) external;
function updateStakingContract(address tokenAddress, address stakingContractAddress) external;
function deleteStakingContract(address tokenAddress) external;
function getSwapContract(address tokenAddress) external view returns (address);
function setSwapContract(address tokenAddress, address swapContractAddress) external;
function updateSwapContract(address tokenAddress, address swapContractAddress) external;
function deleteSwapContract(address tokenAddress) external;
function getOracleConnectorContract(address tokenAddress) external view returns (address);
function setOracleConnectorContract(address tokenAddress, address oracleConnectorAddress) external;
function updateOracleConnectorContract(address tokenAddress, address oracleConnectorAddress) external;
function deleteOracleConnectorContract(address tokenAddress) external;
function getCollectionConnectorContract(address liquidityPool) external view returns (DataTypes.ERC1155Collection memory);
function setCollectionConnectorContract(address liquidityPool, address collectionConnectorAddress, uint tokenID) external;
function updateCollectionConnectorContract(address liquidityPool, address collectionConnectorAddress, uint tokenID) external;
function deleteCollectionConnectorContract(address liquidityPool) external;
function getStablecoinYieldConnectorContract(address tokenAddress) external view returns (address);
function setStablecoinYieldConnectorContract(address tokenAddress, address stablecoinYieldConnectorAddress) external;
function updateStablecoinYieldConnectorContract(address tokenAddress, address stablecoinYieldConnectorAddress) external;
function deleteStablecoinYieldConnectorContract(address tokenAddress) external;

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

/**
 * @title ILPToken
 * @author Souq
 * @notice Defines the interface of the LP token of 1155 MMEs
 */

interface ILPToken {
    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function unpause() external;

    function pause() external;

    function checkPaused() external view returns(bool);

    function getBalanceOf(address _account) external view returns (uint256);

    function setApproval20(address _token, uint256 _amount) external;

    /**
     * @dev Function to rescue and send ERC20 tokens (different than the tokens used by the pool) to a receiver called by the admin
     * @param _token The address of the token contract
     * @param _amount The amount of tokens
     * @param _receiver The address of the receiver
     */
    function RescueTokens(address _token, uint256 _amount, address _receiver) external;

    /**
     * @dev Function to get the the total LP tokens
     * @return uint256 The total number of LP tokens in circulation
     */
    function getTotal() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IAddressesRegistry} from "./IAddressesRegistry.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

/**
 * @title IPoolFactory1155
 * @author Souq
 * @notice Defines the interface of the factory for ERC1155 pools
 */

interface IPoolFactory1155 {
    event PoolDeployed(
        address _admin,
        address stable,
        address[] tokens,
        address _contract,
        uint256 index,
        string _symbol,
        string _name,
        uint256 _poolTvlLimit
    );
    event PoolsUpgraded(address _admin, address _newImplementation);
    event DeploymentByPoolAdminOnlySet(address _admin, bool _newStatus);
    function initialize(address _poolLogic, DataTypes.FactoryFeeConfig calldata _feeConfig) external;
    function getFeeConfig() external view returns (DataTypes.FactoryFeeConfig memory);
    function deployPool(
        DataTypes.PoolData memory _poolData,
        string memory _symbol,
        string memory _name
    ) external returns(address);
    function getPoolsCount() external view returns (uint256);
    function getPool(uint256 _index) external view returns (address);
    function upgradePools(address _newLogic) external;
    function getPoolsVersion() external view returns (uint256);
    function getVersion() external view returns (uint256);
    function setDeploymentByPoolAdminOnly(bool _status) external;

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {DataTypes} from "../libraries/DataTypes.sol";
/**
 * @title IStablecoinYieldConnector
 * @author Souq
 * @notice Defines the interface of the stablecoin yield connector
 */
 interface IStablecoinYieldConnector {
    function pause() external;
    function unpause() external;
    function getVersion() external pure returns (uint256);
    function getATokenAddress() external returns(address);
    function depositUSDC(uint256 amount) external;
    function withdrawUSDC(uint256 amount, uint256 aAmount) external;
    function setUSDCPool(address poolAddress) external;
    function getBalance() external view returns (uint256);
    function getReserveConfigurationData(address _reserve) external view returns (uint256, uint256, uint256, uint256, uint256, bool, bool, bool, bool, bool);
 }

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

/**
 * @title library for Data structures
 * @author Souq
 * @notice Defines the structures used by the contracts of the Souq protocol
 */
library DataTypes {
    struct ERC1155Collection {
        address tokenAddress;
        uint256 tokenID;
    }

    struct AMMShare1155 {
        uint256 tokenId;
        uint256 amount;
    }

    struct Shares1155Params {
        uint256[] amounts;
        uint256[] tokenIds;
    }

    struct ParamGroup {
        uint256 amount;
        uint256 tokenId;
        uint256 subPoolId;
    }

    struct SubPoolGroup {
        uint256 id;
        uint256 counter;
        uint256 total;
        AMMShare1155[] shares;
        SharesCalculationReturn sharesCal;
    }
    struct SharePrice {
        uint256 id;
        uint256 value;
    }
    struct MoveSharesVars {
        uint256 i;
        uint256 poolId;
    }
    struct Quotation {
        uint256 total;
        FeeReturn fees;
        SharePrice[] shares;
    }
    struct QuoteParams {
        bool buy;
        bool useFee;
    }
    struct LocalQuoteVars {
        uint256 i;
        uint256 y;
        uint256 total;
        uint256 poolId;
        uint256 counter;
        uint256 counterShares;
        FeeReturn fees;
        SubPoolGroup currentSubPool;
        AMMShare1155 currentShare;
        SubPoolGroup[] subPoolGroups;
    }
    struct LocalGroupVars {
        uint256 i;
        uint256 index;
        uint256 subPoolId;
        SharesCalculationReturn cal;
        ParamGroup[] paramGroups;
    }
    struct Withdraw1155Data {
        address to;
        uint256 unlockTimestamp;
        uint256 amount;
        AMMShare1155[] shares;
    }

    struct Queued1155Withdrawals {
        mapping(uint => Withdraw1155Data) withdrawals;
        //Head is for reading and next is for saving
        uint256 headId;
        uint256 nextId;
    }

    struct AMMSubPool1155 {
        uint256 reserve;
        uint256 totalShares;
        bool status;
        uint256 V;
        uint256 F;
        //tokenid -> amount
        mapping(uint256 => uint256) shares;
    }

    struct AMMSubPool1155Details {
        uint256 reserve;
        uint256 totalShares;
        uint256 V;
        uint256 F;
    }

    struct FactoryFeeConfig {
        uint256 lpBuyFee;
        uint256 lpSellFee;
        uint256 minLpFee;
        uint256 maxLpBuyFee;
        uint256 maxLpSellFee;
        uint256 protocolSellRatio;
        uint256 protocolBuyRatio;
        uint256 minProtocolRatio;
        uint256 maxProtocolRatio;
        uint256 royaltiesBuyFee;
        uint256 royaltiesSellFee;
        uint256 maxRoyaltiesFee;
    }
    struct PoolFee {
        uint256 lpBuyFee;
        uint256 lpSellFee;
        uint256 royaltiesBuyFee;
        uint256 royaltiesSellFee;
        uint256 protocolBuyRatio;
        uint256 protocolSellRatio;
        uint256 royaltiesBalance;
        uint256 protocolBalance;
        address royaltiesAddress;
        address protocolFeeAddress;
    }

    //cooldown between deposit and withdraw in seconds
    //percentage and multiplier are in wad and wadPercentage
    struct LiquidityLimit {
        uint256 poolTvlLimit;
        uint256 cooldown;
        uint256 maxDepositPercentage;
        uint256 maxWithdrawPercentage;
        uint256 minFeeMultiplier;
        uint256 maxFeeMultiplier;
        uint8 addLiqMode;
        uint8 removeLiqMode;
        bool onlyAdminProvisioning;
    }
    struct IterativeLimit {
        uint256 minimumF;
        uint16 maxBulkStepSize;
        uint16 iterations;
    }

    struct PoolData {
        bool useAccessToken;
        address accessToken;
        address poolLPToken;
        address stable;
        address[] tokens;
        address stableYieldAddress;
        uint256 coefficientA;
        uint256 coefficientB;
        uint256 coefficientC;
        PoolFee fee;
        LiquidityLimit liquidityLimit;
        IterativeLimit iterativeLimit;
    }

    struct FeeReturn {
        uint256 totalFee;
        uint256 swapFee;
        uint256 lpFee;
        uint256 royalties;
        uint256 protocolFee;
    }
    struct SharesCalculationVars {
        uint16 i;
        uint256 V;
        uint256 PV;
        uint256 PV_0;
        uint256 swapPV;
        uint256 shares;
        uint256 stable;
        uint256 value;
        uint256 den;
        uint256 newCash;
        uint256 newShares;
        uint256 steps;
        uint256 stepIndex;
        uint256 stepAmount;
        FeeReturn fees;
    }

    struct SharesCalculationReturn {
        uint256 PV;
        uint256 swapPV;
        uint256 amount;
        uint256 value;
        uint256 F;
        FeeReturn fees;
    }

    struct LiqLocalVars {
        uint256 TVL;
        uint256 LPPrice;
        uint256 LPAmount;
        uint256 stable;
        uint256 stableTotal;
        uint256 stableRemaining;
        uint256 weighted;
        uint256 poolId;
        uint256 maxLPPerShares;
        uint256 remainingLP;
        uint256 i;
        uint256 y;
        uint256 counter;
        AMMShare1155 currentShare;
        SubPoolGroup currentSubPool;
        SubPoolGroup[] subPoolGroups;
    }
    struct SwapLocalVars {
        uint256 stable;
        uint256 remaining;
        uint256 poolId;
        uint256 i;
        uint256 y;
        uint256 counter;
        AMMShare1155 currentShare;
        SubPoolGroup currentSubPool;
        SubPoolGroup[] subPoolGroups;
        FeeReturn fees;
    }
    enum FeeType {
        royalties,
        protocol
    }
    enum OperationType {
        buyShares,
        sellShares
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

/**
 * @title library for Errors mapping
 * @author Souq
 * @notice Defines the output of error messages reverted by the contracts of the Souq protocol
 */
library Errors {
    string public constant NOT_ENOUGH_USER_BALANCE = "NOT_ENOUGH_USER_BALANCE";
    string public constant NOT_ENOUGH_APPROVED = "NOT_ENOUGH_APPROVED";
    string public constant INVALID_AMOUNT = "INVALID_AMOUNT";
    string public constant AMM_PAUSED = "AMM_PAUSED";
    string public constant VAULT_PAUSED = "VAULT_PAUSED";
    string public constant FLASHLOAN_DISABLED = "FLASHLOAN_DISABLED";
    string public constant ADDRESSES_REGISTRY_NOT_SET = "ADDRESSES_REGISTRY_NOT_SET";
    string public constant UPGRADEABILITY_DISABLED = "UPGRADEABILITY_DISABLED";
    string public constant ADDRESS_NOT_UPGRADER = "ADDRESS_NOT_UPGRADER";
    string public constant ADDRESS_NOT_POOL_ADMIN = "ADDRESS_NOT_POOL_ADMIN";
    string public constant ADDRESS_IS_PROXY = "ADDRESS_IS_PROXY";
    string public constant ARRAY_NOT_SAME_LENGTH = "ARRAY_NOT_SAME_LENGTH";
    string public constant NO_SUB_POOL_AVAILABLE = "NO_SUB_POOL_AVAILABLE";
    string public constant LIQUIDITY_MODE_RESTRICTED = "LIQUIDITY_MODE_RESTRICTED";
    string public constant TVL_LIMIT_REACHED = "TVL_LIMIT_REACHED";
    string public constant CALLER_MUST_BE_POOL = "CALLER_MUST_BE_POOL";
    string public constant CANNOT_RESCUE_POOL_TOKEN = "CANNOT_RESCUE_POOL_TOKEN";
    string public constant CALLER_MUST_BE_STABLEYIELD_ADMIN = "CALLER_MUST_BE_STABLEYIELD_ADMIN";
    string public constant CALLER_MUST_BE_STABLEYIELD_LENDER = "CALLER_MUST_BE_STABLEYIELD_LENDER";
    string public constant FUNCTION_REQUIRES_ACCESS_NFT = "FUNCTION_REQUIRES_ACCESS_NFT";
    string public constant FEE_OUT_OF_BOUNDS = "FEE_OUT_OF_BOUNDS";
    string public constant ONLY_ADMIN_CAN_ADD_LIQUIDITY = "ONLY_ADMIN_CAN_ADD_LIQUIDITY";
    string public constant NOT_ENOUGH_SUBPOOL_RESERVE = "NOT_ENOUGH_SUBPOOL_RESERVE";
    string public constant NOT_ENOUGH_SUBPOOL_SHARES = "NOT_ENOUGH_SUBPOOL_SHARES";
    string public constant ADDRESS_NOT_CONNECTOR_ADMIN = "ADDRESS_NOT_CONNECTOR_ADMIN";
    string public constant WITHDRAW_LIMIT_REACHED = "WITHDRAW_LIMIT_REACHED";
    string public constant DEPOSIT_LIMIT_REACHED = "DEPOSIT_LIMIT_REACHED";
    string public constant ADDRESS_IS_ZERO = "ADDRESS_IS_ZERO";
    string public constant SHARES_VALUE_EXCEEDS_TARGET = "SHARES_VALUE_EXCEEDS_TARGET";
    string public constant SHARES_TARGET_EXCEEDS_RESERVE = "SHARES_TARGET_EXCEEDS_RESERVE";
    string public constant SELLING_SHARES_DISABLED_DUE_TO_LOW_CONDITIONS = "SELLING_SHARES_DISABLED_DUE_TO_LOW_CONDITIONS";
    string public constant UPGRADE_DISABLED = "UPGRADE_DISABLED";
    string public constant USER_CANNOT_BE_CONTRACT = "USER_CANNOT_BE_CONTRACT";
    string public constant DEADLINE_NOT_FOUND = "DEADLINE_NOT_FOUND";
    string public constant FLASHLOAN_PROTECTION_ENABLED = "FLASHLOAN_PROTECTION_ENABLED";
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title library for the math helper functions
 * @author Souq
 * @notice Defines the math helper functions common throughout the protocol
 */
library MathHelpers {
    using SafeMath for uint256;

    function convertToWad(uint256 x) internal pure returns (uint256 z) {
        z = x.mul(10 ** 18);
    }

    function convertFromWad(uint256 x) internal pure returns (uint256 z) {
        z = x.div(10 ** 18);
    }

    function convertFromWadSqrd(uint256 x) internal pure returns (uint256 z) {
        z = x.div(10 ** 36);
    }

    function convertToWadPercentage(uint256 x) internal pure returns (uint256 z) {
        z = x.mul(10 ** 20);
    }

    function convertFromWadPercentage(uint256 x) internal pure returns (uint256 z) {
        z = x.div(10 ** 20);
    }
}