/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

import {ID3MM} from "contracts/intf/ID3MM.sol";
import {InitializableOwnable} from "contracts/lib/InitializableOwnable.sol";
import {ICloneFactory} from "contracts/lib/CloneFactory.sol";
import {ID3Token} from "contracts/intf/ID3Token.sol";
import {ID3Oracle} from "contracts/intf/ID3Oracle.sol";
import {Errors} from "contracts/DODOV3MM/lib/Errors.sol";

/**
 * @title D3MMFactory
 * @author DODO Breeder
 *
 * @notice Register of All DODO
 */
contract D3MMFactory is InitializableOwnable {
    address public _D3_LOGIC_;
    address public _D3TOKEN_LOGIC_;
    address public _CLONE_FACTORY_;
    address public _ORACLE_;
    address public _MAINTAINER_;
    address public _FEE_RATE_MODEL_;

    mapping(address => address[]) internal _POOL_REGISTER_;
    mapping(address => bool) public _LIQUIDATOR_WHITELIST_;
    mapping(address => bool) public _ROUTER_WHITELIST_;
    mapping(address => bool) public _POOL_WHITELIST_;
    address[] internal _POOLS_;

    // ============ Events ============

    event D3Birth(address newD3, address creator);
    event AddLiquidator(address liquidator);
    event RemoveLiquidator(address liquidator);
    event AddRouter(address router);
    event RemoveRouter(address router);
    event AddD3(address d3Pool);
    event RemoveD3(address d3Pool);

    // ============ Constructor Function ============

    constructor(
        address d3Logic,
        address d3TokenLogic,
        address cloneFactory,
        address maintainer,
        address feeModel
    ) {
        _D3_LOGIC_ = d3Logic;
        _D3TOKEN_LOGIC_ = d3TokenLogic;
        _CLONE_FACTORY_ = cloneFactory;
        _FEE_RATE_MODEL_ = feeModel;
        _MAINTAINER_ = maintainer;
        initOwner(msg.sender);
    }

    // ============ Admin Function ============

    function setD3Logic(address d3Logic) external onlyOwner {
        _D3_LOGIC_ = d3Logic;
    }

    function setCloneFactory(address cloneFactory) external onlyOwner {
        _CLONE_FACTORY_ = cloneFactory;
    }

    function setOracle(address oracle) external onlyOwner {
        _ORACLE_ = oracle;
    }

    function setMaintainer(address maintainer) external onlyOwner {
        _MAINTAINER_ = maintainer;
    }

    function setFeeModel(address feeModel) external onlyOwner {
        _FEE_RATE_MODEL_ = feeModel;
    }

    function removeD3(address d3Pool) external onlyOwner {
        address creator = ID3MM(d3Pool).getCreator();
        address[] storage pools = _POOL_REGISTER_[creator];
        for (uint256 i = 0; i < pools.length; i++) {
            if (pools[i] == d3Pool) {
                pools[i] = pools[pools.length - 1];
                pools.pop();
                break;
            }
        }
        for (uint256 i = 0; i < _POOLS_.length; i++) {
            if (_POOLS_[i] == d3Pool) {
                _POOLS_[i] = _POOLS_[_POOLS_.length - 1];
                _POOLS_.pop();
                break;
            }
        }
        _POOL_WHITELIST_[d3Pool] = false;
        emit RemoveD3(d3Pool);
    }

    function addD3(address d3Pool) public onlyOwner {
        address creator = ID3MM(d3Pool).getCreator();
        _POOL_REGISTER_[creator].push(d3Pool);
        _POOLS_.push(d3Pool);
        _POOL_WHITELIST_[d3Pool] = true;
        emit AddD3(d3Pool);
    }

    function addLiquidator(address liquidator) external onlyOwner {
        _LIQUIDATOR_WHITELIST_[liquidator] = true;
        emit AddLiquidator(liquidator);
    }

    function removeLiquidator(address liquidator) external onlyOwner {
        _LIQUIDATOR_WHITELIST_[liquidator] = false;
        emit RemoveLiquidator(liquidator);
    }

    function addRouter(address router) external onlyOwner {
        _ROUTER_WHITELIST_[router] = true;
        emit AddRouter(router);
    }

    function removeRouter(address router) external onlyOwner {
        _ROUTER_WHITELIST_[router] = false;
        emit RemoveRouter(router);
    }

    // ============ Breed DODO Function ============

    function breedDODO(
        address creator,
        address[] calldata tokens,
        uint256 epochStartTime,
        uint256 epochDuration,
        uint256 IM,
        uint256 MM
    ) external onlyOwner returns (address newBornDODO) {
        require(epochStartTime < block.timestamp, Errors.INVALID_EPOCH_STARTTIME);
        newBornDODO = ICloneFactory(_CLONE_FACTORY_).clone(_D3_LOGIC_);
        address[] memory d3Tokens = new address[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            require(ID3Oracle(_ORACLE_).isFeasible(tokens[i]), Errors.TOKEN_NOT_ON_WHITELIST);
            address d3Token = createDToken(tokens[i], newBornDODO);
            d3Tokens[i] = d3Token;
        }
        bytes memory mixData = abi.encode(
            IM,
            MM,
            _MAINTAINER_,
            _FEE_RATE_MODEL_
        );
        ID3MM(newBornDODO).init(
            creator,
            address(this),
            _ORACLE_,
            epochStartTime,
            epochDuration,
            tokens,
            d3Tokens,
            mixData
        );

        addD3(newBornDODO);
        emit D3Birth(newBornDODO, creator);
        return newBornDODO;
    }

    function createDToken(address token, address pool)
        public
        returns (address)
    {
        address d3Token = ICloneFactory(_CLONE_FACTORY_).clone(_D3TOKEN_LOGIC_);
        ID3Token(d3Token).init(token, pool);
        return d3Token;
    }

    // ============ View Functions ============

    function getCreatorsDODOs(address creator)
        external
        view
        returns (address[] memory)
    {
        return _POOL_REGISTER_[creator];
    }

    function getPools() external view returns (address[] memory) {
        return _POOLS_;
    }
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

library Errors {
    string public constant NOT_ALLOWED_LIQUIDATOR = "D3MM_NOT_ALLOWED_LIQUIDATOR";
    string public constant NOT_ALLOWED_ROUTER = "D3MM_NOT_ALLOWED_ROUTER";
    string public constant POOL_NOT_ONGOING = "D3MM_POOL_NOT_ONGOING";
    string public constant POOL_NOT_LIQUIDATING = "D3MM_POOL_NOT_LIQUIDATING";
    string public constant POOL_NOT_END = "D3MM_POOL_NOT_END";
    string public constant TOKEN_NOT_EXIST = "D3MM_TOKEN_NOT_EXIST";
    string public constant TOKEN_ALREADY_EXIST = "D3MM_TOKEN_ALREADY_EXIST";
    string public constant EXCEED_DEPOSIT_LIMIT = "D3MM_EXCEED_DEPOSIT_LIMIT";
    string public constant EXCEED_QUOTA = "D3MM_EXCEED_QUOTA";
    string public constant BELOW_IM_RATIO = "D3MM_BELOW_IM_RATIO";
    string public constant TOKEN_NOT_ON_WHITELIST = "D3MM_TOKEN_NOT_ON_WHITELIST";
    string public constant LATE_TO_CHANGE_EPOCH = "D3MM_LATE_TO_CHANGE_EPOCH";
    string public constant POOL_ALREADY_CLOSED = "D3MM_POOL_ALREADY_CLOSED";
    string public constant BALANCE_NOT_ENOUGH = "D3MM_BALANCE_NOT_ENOUGH";
    string public constant TOKEN_IS_OFFLIST = "D3MM_TOKEN_IS_OFFLIST";
    string public constant ABOVE_MM_RATIO = "D3MM_ABOVE_MM_RATIO";
    string public constant WRONG_MM_RATIO = "D3MM_WRONG_MM_RATIO";
    string public constant WRONG_IM_RATIO = "D3MM_WRONG_IM_RATIO";
    string public constant NOT_IN_LIQUIDATING = "D3MM_NOT_IN_LIQUIDATING";
    string public constant NOT_PASS_DEADLINE = "D3MM_NOT_PASS_DEADLINE";
    string public constant DISCOUNT_EXCEED_5 = "D3MM_DISCOUNT_EXCEED_5";
    string public constant MINRES_NOT_ENOUGH = "D3MM_MINRESERVE_NOT_ENOUGH";
    string public constant MAXPAY_NOT_ENOUGH = "D3MM_MAXPAYAMOUNT_NOT_ENOUGH";
    string public constant LIQUIDATION_NOT_DONE = "D3MM_LIQUIDATION_NOT_DONE";
    string public constant ROUTE_FAILED = "D3MM_ROUTE_FAILED";
    string public constant TOKEN_NOT_MATCH = "D3MM_TOKEN_NOT_MATCH";
    string public constant ASK_AMOUNT_EXCEED = "D3MM_ASK_AMOUTN_EXCEED";
    string public constant K_LIMIT = "D3MM_K_LIMIT_ERROR";
    string public constant ARRAY_NOT_MATCH = "D3MM_ARRAY_NOT_MATCH";
    string public constant WRONG_EPOCH_DURATION = "D3MM_WRONG_EPOCH_DURATION";
    string public constant WRONG_EXCUTE_EPOCH_UPDATE_TIME = "D3MM_WRONG_EXCUTE_EPOCH_UPDATE_TIME";
    string public constant INVALID_EPOCH_STARTTIME = "D3MM_INVALID_EPOCH_STARTTIME";
    string public constant PRICE_UP_BELOW_PRICE_DOWN = "D3MM_PRICE_UP_BELOW_PRICE_DOWN";
    string public constant AMOUNT_TOO_SMALL = "D3MM_AMOUNT_TOO_SMALL";
    string public constant FROMAMOUNT_NOT_ENOUGH = "D3MM_FROMAMOUNT_NOT_ENOUGH";
    string public constant HEARTBEAT_CHECK_FAIL = "D3MM_HEARTBEAT_CHECK_FAIL";
    
    string public constant RO_ORACLE_PROTECTION = "PMMRO_ORACLE_PRICE_PROTECTION";
    string public constant RO_VAULT_RESERVE = "PMMRO_VAULT_RESERVE_NOT_ENOUGH";
    string public constant RO_AMOUNT_ZERO = "PMMRO_AMOUNT_ZERO";
    string public constant RO_PRICE_ZERO = "PMMRO_PRICE_ZERO";
    
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

interface ID3MM {
    function getCreator() external returns (address);

    function init(
        address creator,
        address factory,
        address oracle,
        uint256 epochStartTime,
        uint256 epochDuration,
        address[] calldata tokens,
        address[] calldata d3Tokens,
        bytes calldata mixData
        /*
        uint256 IM,
        uint256 MM,
        address maintainer,
        address feeRateModel
        */
    ) external;

    function sellToken(
        address to,
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minReceiveAmount,
        bytes calldata data
    ) external returns(uint256);

    function buyToken(
        address to,
        address fromToken,
        address toToken,
        uint256 quoteAmount,
        uint256 maxPayAmount,
        bytes calldata data
    ) external returns(uint256);

    function lpDeposit(address lp, address token) external;
    function ownerDeposit(address token) external;
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

interface ID3Oracle {
    function getMaxReceive(address fromToken, address toToken, uint256 fromAmount) external view returns(uint256);
    function getPrice(address base) external view returns (uint256);  
    function isFeasible(address base) external view returns (bool); 
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

interface ID3Token {
    function init(address, address) external;
    function mint(address, uint256) external;
    function burn(address, uint256) external;
    function lock(address, uint256) external;
    function unlock(address, uint256) external;
    function balanceOf(address) external view returns (uint256);
    function lockedOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

interface ICloneFactory {
    function clone(address prototype) external returns (address proxy);
}

// introduction of proxy mode design: https://docs.openzeppelin.com/upgrades/2.8/
// minimum implementation of transparent proxy: https://eips.ethereum.org/EIPS/eip-1167

contract CloneFactory is ICloneFactory {
    function clone(address prototype) external override returns (address proxy) {
        bytes20 targetBytes = bytes20(prototype);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            proxy := create(0, clone, 0x37)
        }
        return proxy;
    }
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

/**
 * @title Ownable
 * @author DODO Breeder
 *
 * @notice Ownership related functions
 */
contract InitializableOwnable {
    address public _OWNER_;
    address public _NEW_OWNER_;
    bool internal _INITIALIZED_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier notInitialized() {
        require(!_INITIALIZED_, "DODO_INITIALIZED");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    function initOwner(address newOwner) public notInitialized {
        _INITIALIZED_ = true;
        _OWNER_ = newOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}