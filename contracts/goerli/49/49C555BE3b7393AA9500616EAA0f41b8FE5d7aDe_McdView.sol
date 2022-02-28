/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

// Sources flattened with hardhat v2.8.2 https://hardhat.org

// File contracts/interfaces/ManagerLike.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ManagerLike {
    function cdpCan(
        address owner,
        uint256 cdpId,
        address allowedAddr
    ) external view returns (uint256);

    function vat() external view returns (address);

    function ilks(uint256) external view returns (bytes32);

    function owns(uint256) external view returns (address);

    function urns(uint256) external view returns (address);

    function cdpAllow(
        uint256 cdp,
        address usr,
        uint256 ok
    ) external;

    function frob(
        uint256,
        int256,
        int256
    ) external;

    function flux(
        uint256,
        address,
        uint256
    ) external;

    function move(
        uint256,
        address,
        uint256
    ) external;

    function exit(
        address,
        uint256,
        address,
        uint256
    ) external;
}

interface ICommand {
    function isExecutionCorrect(uint256 cdpId, bytes memory triggerData)
        external
        view
        returns (bool);

    function isExecutionLegal(uint256 cdpId, bytes memory triggerData) external view returns (bool);

    function execute(
        bytes calldata executionData,
        uint256 cdpId,
        bytes memory triggerData
    ) external;
}

interface BotLike {
    function addRecord(
        uint256 cdpId,
        uint256 triggerType,
        uint256 replacedTriggerId,
        bytes memory triggerData
    ) external;

    function removeRecord(
        // This function should be executed allways in a context of AutomationBot address not DsProxy,
        //msg.sender should be dsProxy
        uint256 cdpId,
        uint256 triggerId
    ) external;

    function execute(
        bytes calldata executionData,
        uint256 cdpId,
        bytes calldata triggerData,
        address commandAddress,
        uint256 triggerId,
        uint256 daiCoverage
    ) external;
}

contract ServiceRegistry {
    mapping(bytes32 => uint256) public lastExecuted;
    mapping(address => bool) private trustedAddresses;
    mapping(bytes32 => address) private namedService;
    address public owner;

    uint256 public requiredDelay = 1800; // big enough that any power of miner over timestamp does not matter

    modifier validateInput(uint256 len) {
        require(msg.data.length == len, "registry/illegal-padding");
        _;
    }

    modifier delayedExecution() {
        bytes32 operationHash = keccak256(msg.data);
        uint256 reqDelay = requiredDelay;

        /* solhint-disable not-rely-on-time */
        if (lastExecuted[operationHash] == 0 && reqDelay > 0) {
            // not called before, scheduled for execution
            lastExecuted[operationHash] = block.timestamp;
            emit ChangeScheduled(operationHash, block.timestamp + reqDelay, msg.data);
        } else {
            require(
                block.timestamp - reqDelay > lastExecuted[operationHash],
                "registry/delay-too-small"
            );
            emit ChangeApplied(operationHash, block.timestamp, msg.data);
            _;
            lastExecuted[operationHash] = 0;
        }
        /* solhint-enable not-rely-on-time */
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "registry/only-owner");
        _;
    }

    constructor(uint256 initialDelay) {
        require(initialDelay < type(uint256).max, "registry/risk-of-overflow");
        requiredDelay = initialDelay;
        owner = msg.sender;
    }

    function transferOwnership(address newOwner)
        external
        onlyOwner
        validateInput(36)
        delayedExecution
    {
        owner = newOwner;
    }

    function changeRequiredDelay(uint256 newDelay)
        external
        onlyOwner
        validateInput(36)
        delayedExecution
    {
        requiredDelay = newDelay;
    }

    function addTrustedAddress(address trustedAddress)
        external
        onlyOwner
        validateInput(36)
        delayedExecution
    {
        trustedAddresses[trustedAddress] = true;
    }

    function removeTrustedAddress(address trustedAddress) external onlyOwner validateInput(36) {
        trustedAddresses[trustedAddress] = false;
    }

    function isTrusted(address testedAddress) external view returns (bool) {
        return trustedAddresses[testedAddress];
    }

    function getServiceNameHash(string memory name) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(name));
    }

    function addNamedService(bytes32 serviceNameHash, address serviceAddress)
        external
        onlyOwner
        validateInput(68)
        delayedExecution
    {
        require(namedService[serviceNameHash] == address(0), "registry/service-override");
        namedService[serviceNameHash] = serviceAddress;
    }

    function updateNamedService(bytes32 serviceNameHash, address serviceAddress)
        external
        onlyOwner
        validateInput(68)
        delayedExecution
    {
        require(namedService[serviceNameHash] != address(0), "registry/service-does-not-exist");
        namedService[serviceNameHash] = serviceAddress;
    }

    function removeNamedService(bytes32 serviceNameHash) external onlyOwner validateInput(36) {
        require(namedService[serviceNameHash] != address(0), "registry/service-does-not-exist");
        namedService[serviceNameHash] = address(0);
        emit NamedServiceRemoved(serviceNameHash);
    }

    function getRegisteredService(string memory serviceName) external view returns (address) {
        return namedService[keccak256(abi.encodePacked(serviceName))];
    }

    function getServiceAddress(bytes32 serviceNameHash) external view returns (address) {
        return namedService[serviceNameHash];
    }

    function clearScheduledExecution(bytes32 scheduledExecution)
        external
        onlyOwner
        validateInput(36)
    {
        require(lastExecuted[scheduledExecution] > 0, "registry/execution-not-scheduled");
        lastExecuted[scheduledExecution] = 0;
        emit ChangeCancelled(scheduledExecution);
    }

    event ChangeScheduled(bytes32 dataHash, uint256 scheduledFor, bytes data);
    event ChangeApplied(bytes32 dataHash, uint256 appliedAt, bytes data);
    event ChangeCancelled(bytes32 dataHash);
    event NamedServiceRemoved(bytes32 nameHash);
}

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

contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "");
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x / y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 internal constant WAD = 10**18;
    uint256 internal constant RAY = 10**27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

abstract contract IVat {
    struct Urn {
        uint256 ink; // Locked Collateral  [wad]
        uint256 art; // Normalised Debt    [wad]
    }

    struct Ilk {
        uint256 Art; // Total Normalised Debt     [wad]
        uint256 rate; // Accumulated Rates         [ray]
        uint256 spot; // Price with Safety Margin  [ray]
        uint256 line; // Debt Ceiling              [rad]
        uint256 dust; // Urn Debt Floor            [rad]
    }

    mapping(bytes32 => mapping(address => Urn)) public urns;
    mapping(bytes32 => Ilk) public ilks;
    mapping(bytes32 => mapping(address => uint256)) public gem; // [wad]

    function can(address, address) public view virtual returns (uint256);

    function dai(address) public view virtual returns (uint256);

    function frob(
        bytes32,
        address,
        address,
        address,
        int256,
        int256
    ) public virtual;

    function hope(address) public virtual;

    function move(
        address,
        address,
        uint256
    ) public virtual;

    function fork(
        bytes32,
        address,
        address,
        int256,
        int256
    ) public virtual;
}

abstract contract IGem {
    function dec() public virtual returns (uint256);

    function gem() public virtual returns (IGem);

    function join(address, uint256) public payable virtual;

    function exit(address, uint256) public virtual;

    function approve(address, uint256) public virtual;

    function transfer(address, uint256) public virtual returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) public virtual returns (bool);

    function deposit() public payable virtual;

    function withdraw(uint256) public virtual;

    function allowance(address, address) public virtual returns (uint256);
}

abstract contract IJoin {
    bytes32 public ilk;

    function dec() public view virtual returns (uint256);

    function gem() public view virtual returns (IGem);

    function join(address, uint256) public payable virtual;

    function exit(address, uint256) public virtual;
}

abstract contract IDaiJoin {
    function vat() public virtual returns (IVat);

    function dai() public virtual returns (IGem);

    function join(address, uint256) public payable virtual;

    function exit(address, uint256) public virtual;
}

abstract contract IJug {
    struct Ilk {
        uint256 duty;
        uint256 rho;
    }

    mapping(bytes32 => Ilk) public ilks;

    function drip(bytes32) public virtual returns (uint256);
}

/// @title Getter contract for Vault info from Maker protocol
contract McdUtils is DSMath {
    address public immutable serviceRegistry;
    IERC20 private immutable DAI;
    address private immutable daiJoin;
    address public immutable jug;

    constructor(
        address _serviceRegistry,
        IERC20 _dai,
        address _daiJoin,
        address _jug
    ) {
        serviceRegistry = _serviceRegistry;
        DAI = _dai;
        daiJoin = _daiJoin;
        jug = _jug;
    }

    function toInt256(uint256 x) internal pure returns (int256 y) {
        y = int256(x);
        require(y >= 0, "int256-overflow");
    }

    function convertTo18(address gemJoin, uint256 amt) internal view returns (uint256 wad) {
        // For those collaterals that have less than 18 decimals precision we need to do the conversion before passing to frob function
        // Adapters will automatically handle the difference of precision
        wad = mul(amt, 10**(18 - IJoin(gemJoin).dec()));
    }

    function _getDrawDart(
        address vat,
        address urn,
        bytes32 ilk,
        uint256 wad
    ) internal returns (int256 dart) {
        // Updates stability fee rate
        uint256 rate = IJug(jug).drip(ilk);

        // Gets DAI balance of the urn in the vat
        uint256 dai = IVat(vat).dai(urn);

        // If there was already enough DAI in the vat balance, just exits it without adding more debt
        if (dai < mul(wad, RAY)) {
            // Calculates the needed dart so together with the existing dai in the vat is enough to exit wad amount of DAI tokens
            dart = toInt256(sub(mul(wad, RAY), dai) / rate);
            // This is neeeded due lack of precision. It might need to sum an extra dart wei (for the given DAI wad amount)
            dart = mul(uint256(dart), rate) < mul(wad, RAY) ? dart + 1 : dart;
        }
    }

    function drawDebt(
        uint256 borrowedDai,
        uint256 cdpId,
        ManagerLike manager,
        address sendTo
    ) external {
        address urn = manager.urns(cdpId);
        address vat = manager.vat();

        manager.frob(cdpId, 0, _getDrawDart(vat, urn, manager.ilks(cdpId), borrowedDai));
        manager.move(cdpId, address(this), mul(borrowedDai, RAY));

        IVat(vat).hope(daiJoin);

        IJoin(daiJoin).exit(sendTo, borrowedDai);
    }
}

contract AutomationBot {
    struct TriggerRecord {
        bytes32 triggerHash;
        uint256 cdpId;
    }

    string private constant CDP_MANAGER_KEY = "CDP_MANAGER";
    string private constant AUTOMATION_BOT_KEY = "AUTOMATION_BOT";
    string private constant AUTOMATION_EXECUTOR_KEY = "AUTOMATION_EXECUTOR";
    string private constant MCD_UTILS_KEY = "MCD_UTILS";

    mapping(uint256 => TriggerRecord) public activeTriggers;

    uint256 public triggersCounter = 0;

    ServiceRegistry public immutable serviceRegistry;

    constructor(ServiceRegistry _serviceRegistry) {
        serviceRegistry = _serviceRegistry;
    }

    modifier auth(address caller) {
        require(
            serviceRegistry.getRegisteredService(AUTOMATION_EXECUTOR_KEY) == caller,
            "bot/not-executor"
        );
        _;
    }

    // works correctly in any context
    function validatePermissions(
        uint256 cdpId,
        address operator,
        ManagerLike manager
    ) private view {
        require(isCdpOwner(cdpId, operator, manager), "bot/no-permissions");
    }

    // works correctly in any context
    function isCdpAllowed(
        uint256 cdpId,
        address operator,
        ManagerLike manager
    ) public view returns (bool) {
        address cdpOwner = manager.owns(cdpId);
        return (manager.cdpCan(cdpOwner, cdpId, operator) == 1 || operator == cdpOwner);
    }

    // works correctly in any context
    function isCdpOwner(
        uint256 cdpId,
        address operator,
        ManagerLike manager
    ) private view returns (bool) {
        return (operator == manager.owns(cdpId));
    }

    // works correctly in any context
    function getCommandAddress(uint256 triggerType) public view returns (address) {
        bytes32 commandHash = keccak256(abi.encode("Command", triggerType));

        address commandAddress = serviceRegistry.getServiceAddress(commandHash);

        return commandAddress;
    }

    // works correctly in any context
    function getTriggersHash(
        uint256 cdpId,
        bytes memory triggerData,
        address commandAddress
    ) private view returns (bytes32) {
        bytes32 triggersHash = keccak256(
            abi.encodePacked(cdpId, triggerData, serviceRegistry, commandAddress)
        );

        return triggersHash;
    }

    // works correctly in context of Automation Bot
    function checkTriggersExistenceAndCorrectness(
        uint256 cdpId,
        uint256 triggerId,
        address commandAddress,
        bytes memory triggerData
    ) private view {
        bytes32 triggersHash = activeTriggers[triggerId].triggerHash;

        require(
            triggersHash != bytes32(0) &&
                triggersHash == getTriggersHash(cdpId, triggerData, commandAddress),
            "bot/invalid-trigger"
        );
    }

    function checkTriggersExistenceAndCorrectness(uint256 cdpId, uint256 triggerId) private view {
        require(activeTriggers[triggerId].cdpId == cdpId, "bot/invalid-trigger");
    }

    // works correctly in context of automationBot
    function addRecord(
        // This function should be executed allways in a context of AutomationBot address not DsProxy,
        // msg.sender should be dsProxy
        uint256 cdpId,
        uint256 triggerType,
        uint256 replacedTriggerId,
        bytes memory triggerData
    ) external {
        ManagerLike manager = ManagerLike(serviceRegistry.getRegisteredService(CDP_MANAGER_KEY));

        address commandAddress = getCommandAddress(triggerType);

        validatePermissions(cdpId, msg.sender, manager);

        triggersCounter = triggersCounter + 1;
        activeTriggers[triggersCounter] = TriggerRecord(
            getTriggersHash(cdpId, triggerData, commandAddress),
            cdpId
        );

        if (replacedTriggerId != 0) {
            require(
                activeTriggers[replacedTriggerId].cdpId == cdpId,
                "bot/trigger-removal-illegal"
            );
            activeTriggers[replacedTriggerId] = TriggerRecord(0, 0);
            emit TriggerRemoved(cdpId, replacedTriggerId);
        }
        emit TriggerAdded(triggersCounter, commandAddress, cdpId, triggerData);
    }

    // works correctly in context of automationBot
    function removeRecord(
        // This function should be executed allways in a context of AutomationBot address not DsProxy,
        // msg.sender should be dsProxy
        uint256 cdpId,
        uint256 triggerId
    ) external {
        address managerAddress = serviceRegistry.getRegisteredService(CDP_MANAGER_KEY);

        validatePermissions(cdpId, msg.sender, ManagerLike(managerAddress));

        checkTriggersExistenceAndCorrectness(cdpId, triggerId);

        activeTriggers[triggerId] = TriggerRecord(0, 0);
        emit TriggerRemoved(cdpId, triggerId);
    }

    //works correctly in context of dsProxy
    function addTrigger(
        uint256 cdpId,
        uint256 triggerType,
        uint256 replacedTriggerId,
        bytes memory triggerData
    ) external {
        // TODO: consider adding isCdpAllow add flag in tx payload, make sense from extensibility perspective
        ManagerLike manager = ManagerLike(serviceRegistry.getRegisteredService(CDP_MANAGER_KEY));

        address automationBot = serviceRegistry.getRegisteredService(AUTOMATION_BOT_KEY);
        BotLike(automationBot).addRecord(cdpId, triggerType, replacedTriggerId, triggerData);
        if (!isCdpAllowed(cdpId, automationBot, manager)) {
            manager.cdpAllow(cdpId, automationBot, 1);
            emit ApprovalGranted(cdpId, automationBot);
        }
    }

    //works correctly in context of dsProxy

    // TODO: removeAllowance parameter of this method moves responsibility to decide on this to frontend.
    // In case of a bug on frontend allowance might be revoked by setting this parameter to `true`
    // despite there still be some active triggers which will be disables by this call.
    // One of the solutions is to add counter of active triggers and revoke allowance only if last trigger is being deleted
    function removeTrigger(
        uint256 cdpId,
        uint256 triggerId,
        bool removeAllowance
    ) external {
        address managerAddress = serviceRegistry.getRegisteredService(CDP_MANAGER_KEY);
        ManagerLike manager = ManagerLike(managerAddress);

        address automationBot = serviceRegistry.getRegisteredService(AUTOMATION_BOT_KEY);

        BotLike(automationBot).removeRecord(cdpId, triggerId);

        if (removeAllowance) {
            manager.cdpAllow(cdpId, automationBot, 0);
            emit ApprovalRemoved(cdpId, automationBot);
        }

        emit TriggerRemoved(cdpId, triggerId);
    }

    //works correctly in context of dsProxy
    function removeApproval(ServiceRegistry _serviceRegistry, uint256 cdpId) external {
        address managerAddress = _serviceRegistry.getRegisteredService(CDP_MANAGER_KEY);
        ManagerLike manager = ManagerLike(managerAddress);
        address automationBot = _serviceRegistry.getRegisteredService(AUTOMATION_BOT_KEY);
        validatePermissions(cdpId, address(this), manager);
        manager.cdpAllow(cdpId, automationBot, 0);
        emit ApprovalRemoved(cdpId, automationBot);
    }

    function drawDaiFromVault(
        uint256 cdpId,
        ManagerLike manager,
        uint256 daiCoverage
    ) internal {
        address utilsAddress = serviceRegistry.getRegisteredService(MCD_UTILS_KEY);

        McdUtils utils = McdUtils(utilsAddress);
        manager.cdpAllow(cdpId, utilsAddress, 1);
        utils.drawDebt(daiCoverage, cdpId, manager, msg.sender);
        manager.cdpAllow(cdpId, utilsAddress, 0);
    }

    //works correctly in context of automationBot
    function execute(
        bytes calldata executionData,
        uint256 cdpId,
        bytes calldata triggerData,
        address commandAddress,
        uint256 triggerId,
        uint256 daiCoverage
    ) external auth(msg.sender) {
        checkTriggersExistenceAndCorrectness(cdpId, triggerId, commandAddress, triggerData);
        ManagerLike manager = ManagerLike(serviceRegistry.getRegisteredService(CDP_MANAGER_KEY));
        drawDaiFromVault(cdpId, manager, daiCoverage);

        ICommand command = ICommand(commandAddress);
        require(command.isExecutionLegal(cdpId, triggerData), "bot/trigger-execution-illegal");

        manager.cdpAllow(cdpId, commandAddress, 1);
        command.execute(executionData, cdpId, triggerData);
        activeTriggers[triggerId] = TriggerRecord(0, 0);
        manager.cdpAllow(cdpId, commandAddress, 0);

        require(command.isExecutionCorrect(cdpId, triggerData), "bot/trigger-execution-wrong");

        emit TriggerExecuted(triggerId, cdpId, executionData);
    }

    event ApprovalRemoved(uint256 indexed cdpId, address approvedEntity);

    event ApprovalGranted(uint256 indexed cdpId, address approvedEntity);

    event TriggerRemoved(uint256 indexed cdpId, uint256 indexed triggerId);

    event TriggerAdded(
        uint256 indexed triggerId,
        address indexed commandAddress,
        uint256 indexed cdpId,
        bytes triggerData
    );

    event TriggerExecuted(uint256 indexed triggerId, uint256 indexed cdpId, bytes executionData);
}

interface IExchange {
    function swapTokenForDai(
        address asset,
        uint256 amount,
        uint256 receiveAtLeast,
        address callee,
        bytes calldata withData
    ) external;

    function swapDaiForToken(
        address asset,
        uint256 amount,
        uint256 receiveAtLeast,
        address callee,
        bytes calldata withData
    ) external;
}

contract AutomationExecutor {
    BotLike public immutable bot;
    IERC20 public immutable dai;

    address public exchange;
    address public owner;

    mapping(address => bool) public callers;

    constructor(
        BotLike _bot,
        IERC20 _dai,
        address _exchange
    ) {
        bot = _bot;
        dai = _dai;
        exchange = _exchange;
        owner = msg.sender;
        callers[owner] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "executor/only-owner");
        _;
    }

    modifier auth(address caller) {
        require(callers[caller], "executor/not-authorized");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function setExchange(address newExchange) external onlyOwner {
        exchange = newExchange;
    }

    function addCaller(address caller) external onlyOwner {
        callers[caller] = true;
    }

    function removeCaller(address caller) external onlyOwner {
        require(caller != msg.sender, "executor/cannot-remove-owner");
        callers[caller] = false;
    }

    function execute(
        bytes calldata executionData,
        uint256 cdpId,
        bytes calldata triggerData,
        address commandAddress,
        uint256 triggerId,
        uint256 daiCoverage,
        uint256 minerBribe
    ) external auth(msg.sender) {
        bot.execute(executionData, cdpId, triggerData, commandAddress, triggerId, daiCoverage);

        if (minerBribe > 0) {
            block.coinbase.transfer(minerBribe);
        }
    }

    function swap(
        address otherAsset,
        bool toDai,
        uint256 amount,
        uint256 receiveAtLeast,
        address callee,
        bytes calldata withData
    ) external auth(msg.sender) {
        IERC20 fromToken = toDai ? IERC20(otherAsset) : dai;
        require(
            amount > 0 && amount <= fromToken.balanceOf(address(this)),
            "executor/invalid-amount"
        );

        if (amount > fromToken.allowance(address(this), exchange)) {
            require(fromToken.approve(exchange, type(uint256).max), "executor/approval-failed");
        }

        if (toDai) {
            IExchange(exchange).swapTokenForDai(
                otherAsset,
                amount,
                receiveAtLeast,
                callee,
                withData
            );
        } else {
            IExchange(exchange).swapDaiForToken(
                otherAsset,
                amount,
                receiveAtLeast,
                callee,
                withData
            );
        }
    }

    function withdraw(address asset, uint256 amount) external onlyOwner {
        if (asset == address(0)) {
            require(amount <= address(this).balance, "executor/invalid-amount");
            (bool sent, ) = payable(owner).call{ value: amount }("");
            require(sent, "executor/withdrawal-failed");
        } else {
            require(IERC20(asset).transfer(owner, amount), "executor/withdrawal-failed");
        }
    }

    receive() external payable {}
}

interface MPALike {
    struct CdpData {
        address gemJoin;
        address payable fundsReceiver;
        uint256 cdpId;
        bytes32 ilk;
        uint256 requiredDebt;
        uint256 borrowCollateral;
        uint256 withdrawCollateral;
        uint256 withdrawDai;
        uint256 depositDai;
        uint256 depositCollateral;
        bool skipFL;
        string methodName;
    }

    struct AddressRegistry {
        address jug;
        address manager;
        address multiplyProxyActions;
        address lender;
        address exchange;
    }

    struct ExchangeData {
        address fromTokenAddress;
        address toTokenAddress;
        uint256 fromTokenAmount;
        uint256 toTokenAmount;
        uint256 minToTokenAmount;
        address exchangeAddress;
        bytes _exchangeCalldata;
    }

    function closeVaultExitCollateral(
        ExchangeData calldata exchangeData,
        CdpData memory cdpData,
        AddressRegistry calldata addressRegistry
    ) external;

    function closeVaultExitDai(
        ExchangeData calldata exchangeData,
        CdpData memory cdpData,
        AddressRegistry calldata addressRegistry
    ) external;
}

interface IPipInterface {
    function read() external returns (bytes32);
}

interface SpotterLike {
    function ilks(bytes32) external view returns (IPipInterface pip, uint256 mat);

    function par() external view returns (uint256);
}

interface VatLike {
    function urns(bytes32, address) external view returns (uint256 ink, uint256 art);

    function ilks(bytes32)
        external
        view
        returns (
            uint256 art, // Total Normalised Debt      [wad]
            uint256 rate, // Accumulated Rates         [ray]
            uint256 spot, // Price with Safety Margin  [ray]
            uint256 line, // Debt Ceiling              [rad]
            uint256 dust // Urn Debt Floor             [rad]
        );

    function gem(bytes32, address) external view returns (uint256); // [wad]

    function can(address, address) external view returns (uint256);

    function dai(address) external view returns (uint256);

    function frob(
        bytes32,
        address,
        address,
        address,
        int256,
        int256
    ) external;

    function hope(address) external;

    function move(
        address,
        address,
        uint256
    ) external;

    function fork(
        bytes32,
        address,
        address,
        int256,
        int256
    ) external;
}

interface OsmMomLike {
    function osms(bytes32) external view returns (address);
}

interface OsmLike {
    function peep() external view returns (bytes32, bool);

    function bud(address) external view returns (uint256);

    function kiss(address a) external;
}

/// @title Getter contract for Vault info from Maker protocol
contract McdView is DSMath {
    ManagerLike public immutable manager;
    VatLike public immutable vat;
    SpotterLike public immutable spotter;
    OsmMomLike public immutable osmMom;
    address public immutable owner;
    mapping(address => bool) public whitelisted;

    constructor(
        address _vat,
        address _manager,
        address _spotter,
        address _mom,
        address _owner
    ) {
        manager = ManagerLike(_manager);
        vat = VatLike(_vat);
        spotter = SpotterLike(_spotter);
        osmMom = OsmMomLike(_mom);
        owner = _owner;
    }

    function approve(address _allowedReader, bool isApproved) external {
        require(msg.sender == owner, "mcd-view/not-authorised");
        whitelisted[_allowedReader] = isApproved;
    }

    /// @notice Gets Vault info (collateral, debt)
    /// @param vaultId Id of the Vault
    function getVaultInfo(uint256 vaultId) public view returns (uint256, uint256) {
        address urn = manager.urns(vaultId);
        bytes32 ilk = manager.ilks(vaultId);

        (uint256 collateral, uint256 debt) = vat.urns(ilk, urn);
        (, uint256 rate, , , ) = vat.ilks(ilk);

        return (collateral, rmul(debt, rate));
    }

    /// @notice Gets a price of the asset
    /// @param ilk Ilk of the Vault
    function getPrice(bytes32 ilk) public view returns (uint256) {
        (, uint256 mat) = spotter.ilks(ilk);
        (, , uint256 spot, , ) = vat.ilks(ilk);

        return div(rmul(rmul(spot, spotter.par()), mat), 10**9);
    }

    /// @notice Gets oracle next price of the asset
    /// @param ilk Ilk of the Vault
    function getNextPrice(bytes32 ilk) public view returns (uint256) {
        require(whitelisted[msg.sender], "mcd-view/not-whitelisted");
        OsmLike osm = OsmLike(osmMom.osms(ilk));
        (bytes32 val, bool status) = osm.peep();
        require(status, "mcd-view/osm-price-error");
        return uint256(val);
    }

    /// @notice Gets Vaults ratio
    /// @param vaultId Id of the Vault
    function getRatio(uint256 vaultId, bool useNextPrice) public view returns (uint256) {
        bytes32 ilk = manager.ilks(vaultId);
        uint256 price = useNextPrice ? getNextPrice(ilk) : getPrice(ilk);
        price = price / 10**9;

        (uint256 collateral, uint256 debt) = getVaultInfo(vaultId);

        if (debt == 0) return 0;

        uint256 ratio = rdiv(wmul(collateral, price), debt);

        return ratio;
    }
}

contract CloseCommand is ICommand {
    address public immutable serviceRegistry;
    string private constant CDP_MANAGER_KEY = "CDP_MANAGER";
    string private constant MCD_VIEW_KEY = "MCD_VIEW";
    string private constant MPA_KEY = "MULTIPLY_PROXY_ACTIONS";

    constructor(address _serviceRegistry) {
        serviceRegistry = _serviceRegistry;
    }

    function isExecutionCorrect(uint256 cdpId, bytes memory) external view override returns (bool) {
        address viewAddress = ServiceRegistry(serviceRegistry).getRegisteredService(MCD_VIEW_KEY);
        McdView viewerContract = McdView(viewAddress);
        (uint256 collateral, uint256 debt) = viewerContract.getVaultInfo(cdpId);
        return !(collateral > 0 || debt > 0);
    }

    function isExecutionLegal(uint256 _cdpId, bytes memory triggerData)
        external
        view
        override
        returns (bool)
    {
        (uint256 cdpdId, , uint256 slLevel) = abi.decode(triggerData, (uint256, uint16, uint256));
        if (slLevel <= 100) {
            //completely invalid value
            return false;
        }
        if (_cdpId != cdpdId) {
            //inconsistence of trigger data and declared cdp
            return false;
        }
        address managerAddress = ServiceRegistry(serviceRegistry).getRegisteredService(
            CDP_MANAGER_KEY
        );
        ManagerLike manager = ManagerLike(managerAddress);
        if (manager.owns(cdpdId) == address(0)) {
            return false;
        }
        address viewAddress = ServiceRegistry(serviceRegistry).getRegisteredService(MCD_VIEW_KEY);
        McdView viewerContract = McdView(viewAddress);
        uint256 collRatio = viewerContract.getRatio(cdpdId, true);
        if (collRatio > slLevel * (10**16)) {
            return false;
        }
        //TODO: currently it is current not NextPrice
        return true;
    }

    function execute(
        bytes calldata executionData,
        uint256,
        bytes memory triggerData
    ) external override {
        (, uint16 triggerType, ) = abi.decode(triggerData, (uint256, uint16, uint256));

        address mpaAddress = ServiceRegistry(serviceRegistry).getRegisteredService(MPA_KEY);

        bytes4 prefix = abi.decode(executionData, (bytes4));
        bytes4 expectedSelector;

        if (triggerType == 1) {
            expectedSelector = MPALike.closeVaultExitCollateral.selector;
        } else if (triggerType == 2) {
            expectedSelector = MPALike.closeVaultExitDai.selector;
        } else revert("unsupported-triggerType");

        require(prefix == expectedSelector, "wrong-payload");
        //since all global values in this contract are either const or immutable, this delegate call do not break any storage
        //this is simplest approach, most similar to way we currently call dsProxy
        // solhint-disable-next-line avoid-low-level-calls
        (bool status, ) = mpaAddress.delegatecall(executionData);

        require(status, "execution failed");
    }
}

contract DummyCommand is ICommand {
    address public serviceRegistry;
    bool public initialCheckReturn;
    bool public finalCheckReturn;
    bool public revertsInExecute;

    constructor(
        address _serviceRegistry,
        bool _initialCheckReturn,
        bool _finalCheckReturn,
        bool _revertsInExecute
    ) {
        serviceRegistry = _serviceRegistry;
        initialCheckReturn = _initialCheckReturn;
        finalCheckReturn = _finalCheckReturn;
        revertsInExecute = _revertsInExecute;
    }

    function changeFlags(
        bool _initialCheckReturn,
        bool _finalCheckReturn,
        bool _revertsInExecute
    ) public {
        initialCheckReturn = _initialCheckReturn;
        finalCheckReturn = _finalCheckReturn;
        revertsInExecute = _revertsInExecute;
    }

    function isExecutionCorrect(
        uint256, // cdpId
        bytes memory // triggerData
    ) external view override returns (bool) {
        return finalCheckReturn;
    }

    function isExecutionLegal(
        uint256, // cdpId
        bytes memory // triggerData
    ) external view override returns (bool) {
        return initialCheckReturn;
    }

    function execute(
        bytes calldata,
        uint256,
        bytes memory
    ) external view override {
        require(!revertsInExecute, "command failed");
    }
}

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

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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

contract TestERC20 is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 amount_
    ) ERC20(name_, symbol_) {
        _mint(msg.sender, amount_);
    }
}

contract TestExchange is IExchange {
    IERC20 public immutable DAI;

    constructor(IERC20 _dai) {
        DAI = _dai;
    }

    function swapTokenForDai(
        address asset,
        uint256 amount,
        uint256 receiveAtLeast,
        address,
        bytes calldata
    ) external override {
        require(
            IERC20(asset).transferFrom(msg.sender, address(this), amount),
            "exchange/asset-from-failed"
        );
        require(DAI.transfer(msg.sender, receiveAtLeast), "exchange/dai-to-failed");
    }

    function swapDaiForToken(
        address asset,
        uint256 amount,
        uint256 receiveAtLeast,
        address,
        bytes calldata
    ) external override {
        require(DAI.transferFrom(msg.sender, address(this), amount), "exchange/dai-from-failed");
        require(IERC20(asset).transfer(msg.sender, receiveAtLeast), "exchange/asset-to-failed");
    }
}

interface DsProxyLike {
    function owner() external view returns (address);

    function setOwner(address owner_) external;

    function execute(address target, bytes memory data) external payable returns (bytes32 response);
}