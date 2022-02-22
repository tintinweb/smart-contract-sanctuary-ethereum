pragma solidity 0.8.10;

/***
 *@title PoolProxy
 *@author InsureDAO
 * SPDX-License-Identifier: MIT
 *@notice Ownership proxy for Insurance Pools
 */

//dao-contracts
import "./interfaces/dao/IDistributor.sol";

//pool-contracts
import "./interfaces/pool/ICDSTemplate.sol";
import "./interfaces/pool/IFactory.sol";
import "./interfaces/pool/IIndexTemplate.sol";
import "./interfaces/pool/IOwnership.sol";
import "./interfaces/pool/IParameters.sol";
import "./interfaces/pool/IPoolTemplate.sol";
import "./interfaces/pool/IPremiumModel.sol";
import "./interfaces/pool/IRegistry.sol";
import "./interfaces/pool/IUniversalMarket.sol";
import "./interfaces/pool/IVault.sol";

//libraries
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PoolProxy is ReentrancyGuard {
    using SafeERC20 for IERC20;

    event CommitAdmins(
        address ownership_admin,
        address parameter_admin,
        address emergency_admin
    );
    event ApplyAdmins(
        address ownership_admin,
        address parameter_admin,
        address emergency_admin
    );
    event CommitDefaultReportingAdmin(address default_reporting_admin);
    event AcceptDefaultReportingAdmin(address default_reporting_admin);
    event SetReportingAdmin(address pool, address reporter);

    event AddDistributor(address distributor);

    address public ownership_admin;
    address public parameter_admin;
    address public emergency_admin;
    address public default_reporting_admin; //default reporting module address when arbitrary reporting module is not set.
    mapping(address => address) public reporting_admin; //Pool => Payout Decision Maker's address. (ex. ReportingDAO)

    address parameters; //pool-contracts Parameters.sol

    address public future_ownership_admin;
    address public future_parameter_admin;
    address public future_emergency_admin;
    address public future_default_reporting_admin;

    struct Distributor {
        string name;
        address addr;
    }

    /***
    USDC
    id 0 = dev
    id 1 = buy back and burn
    id 2 = reporting member
    */

    mapping(address => mapping(uint256 => Distributor)) public distributors; // token distibutor contracts. token => ID => Distributor / (ex. USDC => 1 => FeeDistributorV1)
    mapping(address => uint256) public n_distributors; //token => distrobutor#
    mapping(address => mapping(uint256 => uint256)) public distributor_weight; // token => ID => weight
    mapping(address => mapping(uint256 => uint256)) public distributable; //distributor => allocated amount
    mapping(address => uint256) public total_weights; //token => total allocation point

    bool public distributor_kill;

    constructor(
        address _ownership_admin,
        address _parameter_admin,
        address _emergency_admin
    ) {
        ownership_admin = _ownership_admin;
        parameter_admin = _parameter_admin;
        emergency_admin = _emergency_admin;
    }

    //==================================[Fee Distributor]==================================//
    /***
     *@notice add new distributor.
     *@dev distributor weight is 0 at the moment of addition.
     *@param _token address of fee token
     *@param _name FeeDistributor name
     *@param _addr FeeDistributor address
     */
    function add_distributor(
        address _token,
        string memory _name,
        address _addr
    ) external returns(bool) {
        require(msg.sender == ownership_admin, "only ownership admin");
        require(_token != address(0), "_token cannot be zero address");

        Distributor memory new_distributor = Distributor({
            name: _name,
            addr: _addr
        });
        uint256 id = n_distributors[_token];
        distributors[_token][id] = new_distributor;
        n_distributors[_token] += 1;

        return true;
    }

    /***
     *@notice overwrites new distributor to distributor already existed;
     *@dev new distributor takes over the old distributor's weight and distributable state;
     */
    function _set_distributor(
        address _token,
        uint256 _id,
        Distributor memory _distributor
    ) internal {
        require(_id < n_distributors[_token], "distributor not added yet");

        //if Distributor set to ZERO_ADDRESS, set the weight to 0.
        if (_distributor.addr == address(0)) {
            _set_distributor_weight(_token, _id, 0);
        }

        distributors[_token][_id] = _distributor;
    }

    /***
     *@notice Set new distributor or name or both.
     *@dev id has to be added already.
     *@param _token Fee Token address
     *@param _id Distributor id
     *@param _name Distributor name
     *@param _distributor Distributor address
     */
    function set_distributor(
        address _token,
        uint256 _id,
        string memory _name,
        address _distributor
    ) external {
        require(msg.sender == ownership_admin, "only ownership admin");

        Distributor memory new_distributor = Distributor(_name, _distributor);

        _set_distributor(_token, _id, new_distributor);
    }

    /***
     *@notice set new weight to a distributor
     *@param _token fee token address
     *@param _id distributor id
     *@param _weight new weight of the distributor
     */
    function _set_distributor_weight(
        address _token,
        uint256 _id,
        uint256 _weight
    ) internal {
        require(_id < n_distributors[_token], "distributor not added yet");
        require(
            distributors[_token][_id].addr != address(0),
            "distributor not set"
        );

        uint256 new_weight = _weight;
        uint256 old_weight = distributor_weight[_token][_id];

        //update distibutor weight and total_weight
        distributor_weight[_token][_id] = new_weight;
        total_weights[_token] = total_weights[_token] + new_weight - old_weight;
    }

    /***
     *@notice set new weight to a distributor
     *@param _token fee token address
     *@param _id distributor id
     *@param _weight new weight of the distributor
     */
    function set_distributor_weight(
        address _token,
        uint256 _id,
        uint256 _weight
    ) external returns(bool) {
        require(msg.sender == parameter_admin, "only parameter admin");

        _set_distributor_weight(_token, _id, _weight);

        return true;
    }

    /***
     *@notice set new weights to distributors[20]
     *@param _tokens fee token addresses[20]
     *@param _ids distributor ids[20]
     *@param _weights new weights of the distributors[20]
     *@dev [20] 20 is ramdomly decided and has no meaning.
     */
    function set_distributor_weight_many(
        address[20] memory _tokens,
        uint256[20] memory _ids,
        uint256[20] memory _weights
    ) external {
        require(msg.sender == parameter_admin, "only parameter admin");

        for (uint256 i; i < 20;) {
            if (_tokens[i] == address(0)) {
                break;
            }
            _set_distributor_weight(_tokens[i], _ids[i], _weights[i]);
            unchecked {
                ++i;
            }
        }
    }

    /***
     *@notice Get Function for distributor's name
     *@param _token fee token address
     *@param _id distributor id
     */
    function get_distributor_name(address _token, uint256 _id)
    external
    view
    returns(string memory) {
        return distributors[_token][_id].name;
    }

    /***
     *@notice Get Function for distributor's address
     *@param _token fee token address
     *@param _id distributor id
     */
    function get_distributor_address(address _token, uint256 _id)
    external
    view
    returns(address) {
        return distributors[_token][_id].addr;
    }

    //==================================[Fee Distribution]==================================//
    /***
     *@notice Withdraw admin fees from `_vault`
     *@dev any account can execute this function
     *@param _token fee token address to withdraw and allocate to the token's distributors
     */
    function withdraw_admin_fee(address _token) external nonReentrant {
        require(_token != address(0), "_token cannot be zero address");

        address _vault = IParameters(parameters).getVault(_token); //dev: revert when parameters not set
        uint256 amount = IVault(_vault).withdrawAllAttribution(address(this));

        if (amount != 0) {
            //allocate the fee to corresponding distributors
            uint256 _distributors = n_distributors[_token];
            for (uint256 id; id < _distributors;) {
                uint256 aloc_point = distributor_weight[_token][id];

                uint256 aloc_amount = (amount * aloc_point) /
                    total_weights[_token]; //round towards zero.
                distributable[_token][id] += aloc_amount; //count up the allocated fee
                unchecked {
                    ++id;
                }
            }
        }
    }

    /***
     *@notice Re_allocate _token in this contract with the latest allocation. For token left after rounding down or switched to zero_address
     */
    /**
    function re_allocate(address _token)external{
        //re-allocate the all fee token in this contract with the current allocation.

        require(msg.sender == ownership_admin, "Access denied");

        uint256 amount = IERC20(_token).balanceOf(address(this));

        //allocate the fee to corresponding distributors
        for(uint256 id=0; id<n_distributors[_token]; id++){
            uint256 aloc_point = distributor_weight[_token][id];

            uint256 aloc_amount = amount.mul(aloc_point).div(total_weights[_token]); //round towards zero.
            distributable[_token][id] = aloc_amount;
        }
    }
    */

    /***
     *@notice distribute accrued `_token` via a preset distributor
     *@param _token fee token to be distributed
     *@param _id distributor id
     */
    function _distribute(address _token, uint256 _id) internal {
        require(_id < n_distributors[_token], "distributor not added yet");

        address _addr = distributors[_token][_id].addr;
        uint256 amount = distributable[_token][_id];
        distributable[_token][_id] = 0;

        IERC20(_token).safeApprove(_addr, amount);
        require(
            IDistributor(_addr).distribute(_token),
            "dev: should implement distribute()"
        );
    }

    /***
     *@notice distribute accrued `_token` via a preset distributor
     *@dev Only callable by an EOA to prevent
     *@param _token fee token to be distributed
     *@param _id distributor id
     */
    function distribute(address _token, uint256 _id) external nonReentrant {
        require(tx.origin == msg.sender); //only EOA
        require(!distributor_kill, "distributor is killed");

        _distribute(_token, _id);
    }

    /***
     *@notice distribute accrued admin fees from multiple coins
     *@dev Only callable by an EOA to prevent flashloan exploits
     *@param _id List of distributor id
     */
    function distribute_many(
        address[20] memory _tokens,
        uint256[20] memory _ids
    ) external nonReentrant {
        //any EOA
        require(tx.origin == msg.sender);
        require(!distributor_kill, "distribution killed");

        for (uint256 i; i < 20;) {
            if (_tokens[i] == address(0)) {
                break;
            }
            _distribute(_tokens[i], _ids[i]);
            unchecked {
                ++i;
            }
        }
    }

    /***
    @notice Kill or unkill `distribute` functionality
    @param _is_killed Distributor kill status
    */
    function set_distributor_kill(bool _is_killed) external {
        require(
            msg.sender == emergency_admin || msg.sender == ownership_admin,
            "Access denied"
        );
        distributor_kill = _is_killed;
    }

    //==================================[Configuration]==================================//
    // admins
    function commit_set_admins(
        address _o_admin,
        address _p_admin,
        address _e_admin
    ) external {
        /***
         *@notice Set ownership admin to `_o_admin`, parameter admin to `_p_admin` and emergency admin to `_e_admin`
         *@param _o_admin Ownership admin
         *@param _p_admin Parameter admin
         *@param _e_admin Emergency admin
         */
        require(msg.sender == ownership_admin, "Access denied");

        future_ownership_admin = _o_admin;
        future_parameter_admin = _p_admin;
        future_emergency_admin = _e_admin;

        emit CommitAdmins(_o_admin, _p_admin, _e_admin);
    }

    /***
     *@notice Accept the effects of `commit_set_admins`
     */
    function accept_set_admins() external {
        require(msg.sender == future_ownership_admin, "Access denied");

        ownership_admin = future_ownership_admin;
        parameter_admin = future_parameter_admin;
        emergency_admin = future_emergency_admin;

        emit ApplyAdmins(ownership_admin, parameter_admin, emergency_admin);
    }

    //==================================[Reporting Module]==================================//
    /***
     *@notice Set reporting admin to `_r_admin`
     *@param _pool Target address
     *@param _r_admin Reporting admin
     */
    function commit_set_default_reporting_admin(address _r_admin) external {
        require(msg.sender == ownership_admin, "Access denied");

        future_default_reporting_admin = _r_admin;

        emit CommitDefaultReportingAdmin(future_default_reporting_admin);
    }

    /***
     *@notice Accept the effects of `commit_set_default_reporting_admin`
     */
    function accept_set_default_reporting_admin() external {
        require(msg.sender == future_default_reporting_admin, "Access denied");

        default_reporting_admin = future_default_reporting_admin;

        emit AcceptDefaultReportingAdmin(default_reporting_admin);
    }

    /***
     *@notice set arbitrary reporting module for specific _pool.
     *@notice "ownership_admin" or "default_reporting_admin" can execute this function.
     */
    function set_reporting_admin(address _pool, address _reporter)
    external
    returns(bool) {
        require(
            address(msg.sender) == ownership_admin ||
            address(msg.sender) == default_reporting_admin,
            "Access denied"
        );

        reporting_admin[_pool] = _reporter;

        emit SetReportingAdmin(_pool, _reporter);

        return true;
    }

    /***
     *@notice get reporting module set for the _pool. If none is set, default_reporting_admin will be returned.
     *@dev public function
     */
    function get_reporter(address _pool) public view returns(address) {

        address reporter = reporting_admin[_pool] != address(0) ?
            reporting_admin[_pool] :
            default_reporting_admin;

        return reporter;
    }

    //==================================[Pool Contracts]==================================//
    /***
     * pool-contracts' owner is this contract.
     * For the detail of each function, see the pool-contracts repository.
     */
    //ownership
    function ownership_accept_transfer_ownership(address _ownership_contract)
    external {
        require(msg.sender == ownership_admin, "Access denied");

        IOwnership(_ownership_contract).acceptTransferOwnership();
    }

    function ownership_commit_transfer_ownership(
        address _ownership_contract,
        address newOwner
    ) external {
        require(msg.sender == ownership_admin, "Access denied");

        IOwnership(_ownership_contract).commitTransferOwnership(newOwner);
    }

    //Factory
    function factory_approve_template(
        address _factory,
        address _template_addr,
        bool _approval,
        bool _isOpen,
        bool _duplicate
    ) external {
        require(msg.sender == ownership_admin, "Access denied");
        IUniversalMarket _template = IUniversalMarket(_template_addr);

        IFactory(_factory).approveTemplate(
            _template,
            _approval,
            _isOpen,
            _duplicate
        );
    }

    function factory_approve_reference(
        address _factory,
        address _template_addr,
        uint256 _slot,
        address _target,
        bool _approval
    ) external {
        require(msg.sender == ownership_admin, "Access denied");
        IUniversalMarket _template = IUniversalMarket(_template_addr);

        IFactory(_factory).approveReference(
            _template,
            _slot,
            _target,
            _approval
        );
    }

    function factory_set_condition(
        address _factory,
        address _template_addr,
        uint256 _slot,
        uint256 _target
    ) external {
        require(msg.sender == ownership_admin, "Access denied");
        IUniversalMarket _template = IUniversalMarket(_template_addr);

        IFactory(_factory).setCondition(_template, _slot, _target);
    }

    function factory_create_market(
        address _factory,
        address _template_addr,
        string memory _metaData,
        uint256[] memory _conditions,
        address[] memory _references
    ) external returns(address) {
        require(msg.sender == ownership_admin, "Access denied");
        IUniversalMarket _template = IUniversalMarket(_template_addr);

        address _market = IFactory(_factory).createMarket(
            _template,
            _metaData,
            _conditions,
            _references
        );

        return _market;
    }

    //Premium model
    function pm_set_premium(
        address _premium,
        uint256 _multiplierPerYear,
        uint256 _initialBaseRatePerYear,
        uint256 _finalBaseRatePerYear,
        uint256 _goalTVL
    ) external {
        require(msg.sender == parameter_admin, "Access denied");
        IPremiumModel(_premium).setPremiumParameters(
            _multiplierPerYear,
            _initialBaseRatePerYear,
            _finalBaseRatePerYear,
            _goalTVL
        );
    }

    //Universal(Pool/Index/CDS)
    function pm_set_paused(address _pool, bool _state) external nonReentrant {
        require(
            msg.sender == emergency_admin || msg.sender == ownership_admin,
            "Access denied"
        );
        IUniversalMarket(_pool).setPaused(_state);
    }

    function pm_change_metadata(address _pool, string calldata _metadata)
    external {
        require(msg.sender == parameter_admin, "Access denied");
        IUniversalMarket(_pool).changeMetadata(_metadata);
    }

    //Pool
    function pool_apply_cover(
        address _pool,
        uint256 _pending,
        uint256 _payoutNumerator,
        uint256 _payoutDenominator,
        uint256 _incidentTimestamp,
        bytes32 _merkleRoot,
        string calldata _rawdata,
        string calldata _memo
    ) external {
        require(msg.sender == default_reporting_admin || msg.sender == reporting_admin[_pool], "Access denied");

        IPoolTemplate(_pool).applyCover(
            _pending,
            _payoutNumerator,
            _payoutDenominator,
            _incidentTimestamp,
            _merkleRoot,
            _rawdata,
            _memo
        );
    }

    function pool_apply_bounty(
        address _pool,
        uint256 _amount,
        address _contributor,
        uint256[] calldata _ids
    ) external {
        require(msg.sender == default_reporting_admin || msg.sender == reporting_admin[_pool], "Access denied");

        IPoolTemplate(_pool).applyBounty(
            _amount,
            _contributor,
            _ids
        );
    }

    //Index
    function index_set_leverage(address _index, uint256 _target) external {
        require(msg.sender == parameter_admin, "Access denied");

        IIndexTemplate(_index).setLeverage(_target);
    }

    function index_set(
        address _index_address,
        uint256 _indexA,
        uint256 _indexB,
        address _pool,
        uint256 _allocPoint
    ) external {
        require(msg.sender == parameter_admin, "Access denied");

        IIndexTemplate(_index_address).set(_indexA, _indexB, _pool, _allocPoint);
    }

    //CDS
    function defund(address _cds, address _to, uint256 _amount) external {
        require(msg.sender == ownership_admin, "Access denied");

        ICDSTemplate(_cds).defund(_to, _amount);
    }

    //Vault
    function vault_withdraw_redundant(
        address _vault,
        address _token,
        address _to
    ) external {
        require(msg.sender == ownership_admin, "Access denied");
        IVault(_vault).withdrawRedundant(_token, _to);
    }

    function vault_set_keeper(address _vault, address _keeper) external {
        require(msg.sender == ownership_admin, "Access denied");
        IVault(_vault).setKeeper(_keeper);
    }

    function vault_set_controller(address _vault, address _controller)
    external {
        require(msg.sender == ownership_admin, "Access denied");
        IVault(_vault).setController(_controller);
    }

    //Parameters
    function set_parameters(address _parameters) external {
        /***
         * @notice set parameter contract
         */

        require(msg.sender == ownership_admin, "Access denied");
        parameters = _parameters;
    }

    function parameters_set_vault(
        address _parameters,
        address _token,
        address _vault
    ) external {
        require(msg.sender == ownership_admin, "Access denied");

        IParameters(_parameters).setVault(_token, _vault);
    }

    function parameters_set_lockup(
        address _parameters,
        address _address,
        uint256 _target
    ) external {
        require(msg.sender == parameter_admin, "Access denied");

        IParameters(_parameters).setLockup(_address, _target);
    }

    function parameters_set_grace(
        address _parameters,
        address _address,
        uint256 _target
    ) external {
        require(msg.sender == parameter_admin, "Access denied");

        IParameters(_parameters).setGrace(_address, _target);
    }

    function parameters_set_mindate(
        address _parameters,
        address _address,
        uint256 _target
    ) external {
        require(msg.sender == parameter_admin, "Access denied");

        IParameters(_parameters).setMinDate(_address, _target);
    }

    function parameters_set_upper_slack(
        address _parameters,
        address _address,
        uint256 _target
    ) external {
        require(msg.sender == parameter_admin, "Access denied");

        IParameters(_parameters).setUpperSlack(_address, _target);
    }

    function parameters_set_lower_slack(
        address _parameters,
        address _address,
        uint256 _target
    ) external {
        require(msg.sender == parameter_admin, "Access denied");

        IParameters(_parameters).setLowerSlack(_address, _target);
    }

    function parameters_set_withdrawable(
        address _parameters,
        address _address,
        uint256 _target
    ) external {
        require(msg.sender == parameter_admin, "Access denied");

        IParameters(_parameters).setWithdrawable(_address, _target);
    }

    function parameters_set_premium_model(
        address _parameters,
        address _address,
        address _target
    ) external {
        require(msg.sender == parameter_admin, "Access denied");

        IParameters(_parameters).setPremiumModel(_address, _target);
    }

    function setFeeRate(
        address _parameters,
        address _address,
        uint256 _target
    ) external {
        require(msg.sender == parameter_admin, "Access denied");

        IParameters(_parameters).setFeeRate(_address, _target);
    }

    function parameters_set_max_list(
        address _parameters,
        address _address,
        uint256 _target
    ) external {
        require(msg.sender == parameter_admin, "Access denied");

        IParameters(_parameters).setMaxList(_address, _target);
    }

    function parameters_set_condition_parameters(
        address _parameters,
        bytes32 _reference,
        bytes32 _target
    ) external {
        require(msg.sender == parameter_admin, "Access denied");

        IParameters(_parameters).setCondition(_reference, _target);
    }

    //Registry
    function registry_set_factory(address _registry, address _factory)
    external {
        require(msg.sender == ownership_admin, "Access denied");

        IRegistry(_registry).setFactory(_factory);
    }

    function registry_support_market(address _registry, address _market)
    external {
        require(msg.sender == ownership_admin, "Access denied");

        IRegistry(_registry).supportMarket(_market);
    }

    function registry_set_existence(
        address _registry,
        address _template,
        address _target
    ) external {
        require(msg.sender == ownership_admin, "Access denied");

        IRegistry(_registry).setExistence(_template, _target);
    }

    function registry_set_cds(
        address _registry,
        address _address,
        address _target
    ) external {
        require(msg.sender == ownership_admin, "Access denied");

        IRegistry(_registry).setCDS(_address, _target);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IDistributor {
    function distribute(address _coin) external returns(bool);

}

pragma solidity 0.8.10;

interface ICDSTemplate {
    function compensate(uint256) external returns (uint256 _compensated);

    //onlyOwner
    function defund(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IUniversalMarket.sol";

interface IFactory {
    function approveTemplate(
        IUniversalMarket _template,
        bool _approval,
        bool _isOpen,
        bool _duplicate
    ) external;

    function approveReference(
        IUniversalMarket _template,
        uint256 _slot,
        address _target,
        bool _approval
    ) external;

    function setCondition(
        IUniversalMarket _template,
        uint256 _slot,
        uint256 _target
    ) external;

    function createMarket(
        IUniversalMarket _template,
        string memory _metaData,
        uint256[] memory _conditions,
        address[] memory _references
    ) external returns (address);
}

pragma solidity 0.8.10;

interface IIndexTemplate {
    function compensate(uint256) external returns (uint256 _compensated);

    function lock() external;

    function resume() external;

    //onlyOwner
    function setLeverage(uint256 _target) external;
    function set(
        uint256 _indexA,
        uint256 _indexB,
        address _pool,
        uint256 _allocPoint
    ) external;
}

pragma solidity 0.8.10;

//SPDX-License-Identifier: MIT

interface IOwnership {
    function owner() external view returns (address);

    function futureOwner() external view returns (address);

    function commitTransferOwnership(address newOwner) external;

    function acceptTransferOwnership() external;
}

pragma solidity 0.8.10;

abstract contract IParameters {
    function setVault(address _token, address _vault) external virtual;

    function setLockup(address _address, uint256 _target) external virtual;

    function setGrace(address _address, uint256 _target) external virtual;

    function setMinDate(address _address, uint256 _target) external virtual;

    function setUpperSlack(address _address, uint256 _target) external virtual;

    function setLowerSlack(address _address, uint256 _target) external virtual;

    function setWithdrawable(address _address, uint256 _target)
        external
        virtual;

    function setPremiumModel(address _address, address _target)
        external
        virtual;

    function setFeeRate(address _address, uint256 _target) external virtual;

    function setMaxList(address _address, uint256 _target) external virtual;

    function setCondition(bytes32 _reference, bytes32 _target) external virtual;

    function getOwner() external view virtual returns (address);

    function getVault(address _token) external view virtual returns (address);

    function getPremium(
        uint256 _amount,
        uint256 _term,
        uint256 _totalLiquidity,
        uint256 _lockedAmount,
        address _target
    ) external view virtual returns (uint256);

    function getFeeRate(address _target) external view virtual returns (uint256);

    function getUpperSlack(address _target)
        external
        view
        virtual
        returns (uint256);

    function getLowerSlack(address _target)
        external
        view
        virtual
        returns (uint256);

    function getLockup(address _target) external view virtual returns (uint256);

    function getWithdrawable(address _target)
        external
        view
        virtual
        returns (uint256);

    function getGrace(address _target) external view virtual returns (uint256);

    function getMinDate(address _target) external view virtual returns (uint256);

    function getMaxList(address _target)
        external
        view
        virtual
        returns (uint256);

    function getCondition(bytes32 _reference)
        external
        view
        virtual
        returns (bytes32);
}

pragma solidity 0.8.10;

abstract contract IPoolTemplate {

    enum MarketStatus {
        Trading,
        Payingout
    }
    function registerIndex(uint256 _index)external virtual;
    function allocateCredit(uint256 _credit)
        external
        virtual
        returns (uint256 _mintAmount);

    function pairValues(address _index)
        external
        view
        virtual
        returns (uint256, uint256);

    function withdrawCredit(uint256 _credit)
        external
        virtual
        returns (uint256 _retVal);

    function marketStatus() external view virtual returns(MarketStatus);
    function availableBalance() external view virtual returns (uint256 _balance);

    function utilizationRate() external view virtual returns (uint256 _rate);
    function totalLiquidity() public view virtual returns (uint256 _balance);
    function totalCredit() external view virtual returns (uint256);
    function lockedAmount() external view virtual returns (uint256);

    function valueOfUnderlying(address _owner)
        external
        view
        virtual
        returns (uint256);

    function pendingPremium(address _index)
        external
        view
        virtual
        returns (uint256);

    function paused() external view virtual returns (bool);

    //onlyOwner
    function applyCover(
        uint256 _pending,
        uint256 _payoutNumerator,
        uint256 _payoutDenominator,
        uint256 _incidentTimestamp,
        bytes32 _merkleRoot,
        string calldata _rawdata,
        string calldata _memo
    ) external virtual;

    function applyBounty(
        uint256 _amount,
        address _contributor,
        uint256[] calldata _ids
    )external virtual;
}

pragma solidity 0.8.10;

interface IPremiumModel {

    function getCurrentPremiumRate(
        uint256 _totalLiquidity,
        uint256 _lockedAmount
    ) external view returns (uint256);

    function getPremiumRate(
        uint256 _amount,
        uint256 _totalLiquidity,
        uint256 _lockedAmount
    ) external view returns (uint256);

    function getPremium(
        uint256 _amount,
        uint256 _term,
        uint256 _totalLiquidity,
        uint256 _lockedAmount
    ) external view returns (uint256);

    //onlyOwner
    function setPremiumParameters(
        uint256,
        uint256,
        uint256,
        uint256
    ) external;
}

pragma solidity 0.8.10;

interface IRegistry {
    function isListed(address _market) external view returns (bool);

    function getCDS(address _address) external view returns (address);

    function confirmExistence(address _template, address _target)
        external
        view
        returns (bool);

    //onlyOwner
    function setFactory(address _factory) external;

    function supportMarket(address _market) external;

    function setExistence(address _template, address _target) external;

    function setCDS(address _address, address _cds) external;
}

pragma solidity 0.8.10;

interface IUniversalMarket {
    function initialize(
        address _depositor,
        string calldata _metaData,
        uint256[] calldata _conditions,
        address[] calldata _references
    ) external;

    //onlyOwner
    function setPaused(bool state) external;
    function changeMetadata(string calldata _metadata) external;
}

pragma solidity 0.8.10;

interface IVault {
    function addValueBatch(
        uint256 _amount,
        address _from,
        address[2] memory _beneficiaries,
        uint256[2] memory _shares
    ) external returns (uint256[2] memory _allocations);

    function addValue(
        uint256 _amount,
        address _from,
        address _attribution
    ) external returns (uint256 _attributions);

    function withdrawValue(uint256 _amount, address _to)
        external
        returns (uint256 _attributions);

    function transferValue(uint256 _amount, address _destination)
        external
        returns (uint256 _attributions);

    function withdrawAttribution(uint256 _attribution, address _to)
        external
        returns (uint256 _retVal);

    function withdrawAllAttribution(address _to)
        external
        returns (uint256 _retVal);

    function transferAttribution(uint256 _amount, address _destination)
        external;

    function attributionOf(address _target) external view returns (uint256);

    function underlyingValue(address _target) external view returns (uint256);

    function attributionValue(uint256 _attribution)
        external
        view
        returns (uint256);

    function utilize() external returns (uint256 _amount);
    function valueAll() external view returns (uint256);


    function token() external returns (address);

    function borrowValue(uint256 _amount, address _to) external;

    /*
    function borrowAndTransfer(uint256 _amount, address _to)
        external
        returns (uint256 _attributions);
    */

    function offsetDebt(uint256 _amount, address _target)
        external
        returns (uint256 _attributions);

    function repayDebt(uint256 _amount, address _target) external;

    function debts(address _debtor) external view returns (uint256);

    function transferDebt(uint256 _amount) external;

    //onlyOwner
    function withdrawRedundant(address _token, address _to) external;

    function setController(address _controller) external;

    function setKeeper(address _keeper) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}