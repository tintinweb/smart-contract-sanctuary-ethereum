// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns(uint256);
    function transfer(address recipient, uint256 amount) external returns(bool);
    function allowance(address owner, address spender) external view returns(uint256);
    function approve(address spender, uint256 amount) external returns(bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ITornadoInstance {
    function token() external view returns (address);
    function denomination() external view returns (uint256);
    function deposit(bytes32 commitment) external payable;
    function withdraw(
        bytes calldata proof,
        bytes32 root,
        bytes32 nullifierHash,
        address payable recipient,
        address payable relayer,
        uint256 fee,
        uint256 refund
    ) external payable;
}

interface ITornadoRouter {
    function approveExactToken(
        IERC20 _token,
        address _spender,
        uint256 _amount
    ) external;
}

contract InstanceRegistry {

    enum InstanceState {
        DISABLED,
        ENABLED
    }

    struct Instance {
        bool isERC20;
        IERC20 token;
        InstanceState state;
        // the fee of the uniswap pool which will be used to get a TWAP
        uint24 uniswapPoolSwappingFee;
        // the fee the protocol takes from relayer, it should be multiplied by PROTOCOL_FEE_DIVIDER from FeeManager.sol
        uint32 protocolFeePercentage;
    }

    struct Tornado {
        ITornadoInstance addr;
        Instance instance;
    }

    address public governance;
    ITornadoRouter public router;
    bool public initialized = false;

    mapping(ITornadoInstance => Instance) public instances;
    ITornadoInstance[] public instanceIds;

    event InstanceStateUpdated(ITornadoInstance indexed instance, InstanceState state);
    event RouterRegistered(address tornadoRouter);

    modifier onlyGovernance() {
        require(msg.sender == governance, "Not authorized");
        _;
    }

    constructor(address _governance) public {
        governance = _governance;
    }

    function initialize(Tornado[] memory _instances, address _router) external onlyGovernance{
        // require(!initialized, 'Already initialized');
        router = ITornadoRouter(_router);
        for (uint256 i = 0; i < _instances.length; i++) {
            _updateInstance(_instances[i]);
            instanceIds.push(_instances[i].addr);
        }
        initialized = true;
    }

    /**
     * @dev Add or update an instance.
     */
    function updateInstance(Tornado calldata _tornado) external virtual onlyGovernance {
        require(_tornado.instance.state != InstanceState.DISABLED, "Use removeInstance() for remove");
        if (instances[_tornado.addr].state == InstanceState.DISABLED) {
            instanceIds.push(_tornado.addr);
        }
        _updateInstance(_tornado);
    }

    /**
     * @dev Remove an instance.
     * @param _instanceId The instance id in `instanceIds` mapping to remove.
     */
    function removeInstance(uint256 _instanceId) external virtual onlyGovernance {
        ITornadoInstance _instance = instanceIds[_instanceId];
        (bool isERC20, IERC20 token) = (instances[_instance].isERC20, instances[_instance].token);

        if (isERC20) {
            uint256 allowance = token.allowance(address(router), address(_instance));
            if (allowance != 0) {
                router.approveExactToken(token, address(_instance), 0);
            }
        }

        delete instances[_instance];
        instanceIds[_instanceId] = instanceIds[instanceIds.length - 1];
        instanceIds.pop();
        emit InstanceStateUpdated(_instance, InstanceState.DISABLED);
    }

    /**
     * @notice This function should allow governance to set a new protocol fee for relayers
     * @param instance the to update
     * @param newFee the new fee to use
     * */
    function setProtocolFee(ITornadoInstance instance, uint32 newFee) external onlyGovernance {
        instances[instance].protocolFeePercentage = newFee;
    }

    /**
     * @notice This function should allow governance to set a new tornado proxy address
     * @param routerAddress address of the new proxy
     * */
    function setTornadoRouter(address routerAddress) external onlyGovernance {
        router = ITornadoRouter(routerAddress);
        emit RouterRegistered(routerAddress);
    }

    function _updateInstance(Tornado memory _tornado) internal virtual {
        instances[_tornado.addr] = _tornado.instance;
        if (_tornado.instance.isERC20) {
            IERC20 token = IERC20(_tornado.addr.token());
            require(token == _tornado.instance.token, "Incorrect token");
            uint256 allowance = token.allowance(address(router), address(_tornado.addr));

            if (allowance == 0) {
                router.approveExactToken(token, address(_tornado.addr), type(uint256).max);
            }
        }
        emit InstanceStateUpdated(_tornado.addr, _tornado.instance.state);
    }

    /**
     * @dev Returns all instance configs
     */
    function getAllInstances() public view returns(Tornado[] memory result) {
        result = new Tornado[](instanceIds.length);
        for (uint256 i = 0; i < instanceIds.length; i++) {
            ITornadoInstance _instance = instanceIds[i];
            result[i] = Tornado({
                addr: _instance,
                instance: instances[_instance]
            });
        }
    }

    /**
     * @dev Returns all instance addresses
     */
    function getAllInstanceAddresses() public view returns(ITornadoInstance[] memory result) {
        result = new ITornadoInstance[](instanceIds.length);
        for (uint256 i = 0; i < instanceIds.length; i++) {
            result[i] = instanceIds[i];
        }
    }

    /// @notice get erc20 tornado instance token
    /// @param instance the interface (contract) key to the instance data
    function getPoolToken(ITornadoInstance instance) external view returns(address) {
        return address(instances[instance].token);
    }

    function transferGovernance(address _governance) external onlyGovernance {
        governance = _governance;
    }
}