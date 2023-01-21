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

// SPDX-License-Identifier: AGPL-3.0-or-later

/// DPMAdapter.sol

// Copyright (C) 2023 Oazo Apps Limited

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.0;
import "../interfaces/ICommand.sol";
import "../interfaces/IAccountGuard.sol";
import "../interfaces/ManagerLike.sol";
import "../interfaces/BotLike.sol";
import "../interfaces/MPALike.sol";
import "../interfaces/IAdapter.sol";
import "../ServiceRegistry.sol";
import "../McdView.sol";
import "../McdUtils.sol";

contract DPMAdapter is ISecurityAdapter {
    ServiceRegistry public immutable serviceRegistry;
    string private constant CDP_MANAGER_KEY = "CDP_MANAGER";
    string private constant MCD_UTILS_KEY = "MCD_UTILS";
    address private immutable self;
    IAccountGuard public immutable accountGuard;

    modifier onlyDelegate() {
        require(address(this) != self, "dpm-adapter/only-delegate");
        _;
    }

    constructor(ServiceRegistry _serviceRegistry, IAccountGuard _accountGuard) {
        self = address(this);
        serviceRegistry = _serviceRegistry;
        accountGuard = _accountGuard; //hesitating if that should not be taken from serviceRegistry if needed, but this way it is immutable
    }

    function decode(
        bytes memory triggerData
    ) public pure returns (address proxyAddress, uint256 triggerType) {
        (proxyAddress, triggerType) = abi.decode(triggerData, (address, uint16));
    }

    function canCall(bytes memory triggerData, address operator) public view returns (bool) {
        (address proxyAddress, ) = decode(triggerData);
        address positionOwner = accountGuard.owners(proxyAddress);
        return accountGuard.canCall(proxyAddress, operator) || (operator == positionOwner);
    }

    function permit(bytes memory triggerData, address target, bool allowance) public onlyDelegate {
        require(canCall(triggerData, address(this)), "dpm-adapter/not-allowed-to-call"); //missing check to fail permit if msg.sender has no permissions

        (address proxyAddress, ) = decode(triggerData);

        if (allowance != accountGuard.canCall(proxyAddress, target)) {
            accountGuard.permit(target, proxyAddress, allowance);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

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

    uint256 internal constant WAD = 10 ** 18;
    uint256 internal constant RAY = 10 ** 27;

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface BotLike {
    function addRecord(
        uint256 triggerType,
        bool continuous,
        uint256 replacedTriggerId,
        bytes memory triggerData,
        bytes memory replacedTriggerData
    ) external;

    function removeRecord(
        // This function should be executed allways in a context of AutomationBot address not DsProxy,
        //msg.sender should be dsProxy
        bytes memory triggersData,
        uint256 triggerId
    ) external;

    function execute(
        bytes calldata executionData,
        bytes calldata triggerData,
        address commandAddress,
        uint256 triggerId,
        uint256 coverageAmount,
        address coverageToken
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface IAccountGuard {
    function owners(address) external view returns (address);

    function setWhitelist(address target, bool status) external;

    function canCall(address proxy, address operator) external view returns (bool);

    function permit(address caller, address target, bool allowance) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// CloseCommand.sol

// Copyright (C) 2021-2021 Oazo Apps Limited

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.0;

interface ISecurityAdapter {
    function canCall(bytes memory triggerData, address operator) external returns (bool);

    function permit(bytes memory triggerData, address target, bool allowance) external;
}

interface IExecutableAdapter {
    function getCoverage(
        bytes memory triggerData,
        address receiver,
        address token,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface ICommand {
    function isTriggerDataValid(
        bool continuous,
        bytes memory triggerData
    ) external view returns (bool);

    function isExecutionCorrect(bytes memory triggerData) external view returns (bool);

    function isExecutionLegal(bytes memory triggerData) external view returns (bool);

    function execute(bytes calldata executionData, bytes memory triggerData) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
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

    function open(bytes32 ilk, address usr) external returns (uint256);

    function cdpAllow(uint256 cdp, address usr, uint256 ok) external;

    function frob(uint256, int256, int256) external;

    function flux(uint256, address, uint256) external;

    function move(uint256, address, uint256) external;

    function exit(address, uint256, address, uint256) external;

    event NewCdp(address indexed usr, address indexed own, uint256 indexed cdp);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

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

    function frob(bytes32, address, address, address, int256, int256) public virtual;

    function hope(address) public virtual;

    function move(address, address, uint256) public virtual;

    function fork(bytes32, address, address, int256, int256) public virtual;
}

abstract contract IGem {
    function dec() public virtual returns (uint256);

    function gem() public virtual returns (IGem);

    function join(address, uint256) public payable virtual;

    function exit(address, uint256) public virtual;

    function approve(address, uint256) public virtual;

    function transfer(address, uint256) public virtual returns (bool);

    function transferFrom(address, address, uint256) public virtual returns (bool);

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

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

    function increaseMultiple(
        ExchangeData calldata exchangeData,
        CdpData memory cdpData,
        AddressRegistry calldata addressRegistry
    ) external;

    function decreaseMultiple(
        ExchangeData calldata exchangeData,
        CdpData memory cdpData,
        AddressRegistry calldata addressRegistry
    ) external;

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface OsmLike {
    function peep() external view returns (bytes32, bool);

    function bud(address) external view returns (uint256);

    function kiss(address a) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface OsmMomLike {
    function osms(bytes32) external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface IPipInterface {
    function read() external returns (bytes32);
}

interface SpotterLike {
    function ilks(bytes32) external view returns (IPipInterface pip, uint256 mat);

    function par() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface VatLike {
    function urns(bytes32, address) external view returns (uint256 ink, uint256 art);

    function ilks(
        bytes32
    )
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

    function frob(bytes32, address, address, address, int256, int256) external;

    function hope(address) external;

    function move(address, address, uint256) external;

    function fork(bytes32, address, address, int256, int256) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// McdUtils.sol

// Copyright (C) 2021-2021 Oazo Apps Limited

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./external/DSMath.sol";
import "./interfaces/ManagerLike.sol";
import "./interfaces/ICommand.sol";
import "./interfaces/Mcd.sol";
import "./interfaces/BotLike.sol";

import "./ServiceRegistry.sol";

/// @title Getter contract for Vault info from Maker protocol
contract McdUtils is DSMath {
    address public immutable serviceRegistry;
    IERC20 private immutable DAI;
    address private immutable daiJoin;
    address public immutable jug;

    constructor(address _serviceRegistry, IERC20 _dai, address _daiJoin, address _jug) {
        serviceRegistry = _serviceRegistry;
        DAI = _dai;
        daiJoin = _daiJoin;
        jug = _jug;
    }

    function toInt256(uint256 x) internal pure returns (int256 y) {
        y = int256(x);
        require(y >= 0, "int256-overflow");
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

        if (IVat(vat).can(address(this), daiJoin) == 0) {
            IVat(vat).hope(daiJoin);
        }

        IJoin(daiJoin).exit(sendTo, borrowedDai);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// McdView.sol

// Copyright (C) 2021-2021 Oazo Apps Limited

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.0;
import "./interfaces/ManagerLike.sol";
import "./ServiceRegistry.sol";

import "./interfaces/SpotterLike.sol";
import "./interfaces/VatLike.sol";
import "./interfaces/OsmMomLike.sol";
import "./interfaces/OsmLike.sol";
import "./external/DSMath.sol";

/// @title Getter contract for Vault info from Maker protocol
contract McdView is DSMath {
    ManagerLike public manager;
    VatLike public vat;
    SpotterLike public spotter;
    OsmMomLike public osmMom;
    address public owner;
    mapping(address => bool) public whitelisted;

    constructor(address _vat, address _manager, address _spotter, address _mom, address _owner) {
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

        return div(rmul(rmul(spot, spotter.par()), mat), 10 ** 9);
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
        (uint256 collateral, uint256 debt) = getVaultInfo(vaultId);
        if (debt == 0) return 0;
        return wdiv(wmul(collateral, price), debt);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// ServiceRegistry.sol

// Copyright (C) 2021-2021 Oazo Apps Limited

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.0;

contract ServiceRegistry {
    uint256 public constant MAX_DELAY = 30 days;

    mapping(bytes32 => uint256) public lastExecuted;
    mapping(bytes32 => address) private namedService;
    address public owner;
    uint256 public requiredDelay;

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
        require(initialDelay <= MAX_DELAY, "registry/invalid-delay");
        requiredDelay = initialDelay;
        owner = msg.sender;
    }

    function transferOwnership(
        address newOwner
    ) external onlyOwner validateInput(36) delayedExecution {
        owner = newOwner;
    }

    function changeRequiredDelay(
        uint256 newDelay
    ) external onlyOwner validateInput(36) delayedExecution {
        require(newDelay <= MAX_DELAY, "registry/invalid-delay");
        requiredDelay = newDelay;
    }

    function getServiceNameHash(string memory name) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(name));
    }

    function addNamedService(
        bytes32 serviceNameHash,
        address serviceAddress
    ) external onlyOwner validateInput(68) delayedExecution {
        require(namedService[serviceNameHash] == address(0), "registry/service-override");
        namedService[serviceNameHash] = serviceAddress;
    }

    function updateNamedService(
        bytes32 serviceNameHash,
        address serviceAddress
    ) external onlyOwner validateInput(68) delayedExecution {
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

    function clearScheduledExecution(
        bytes32 scheduledExecution
    ) external onlyOwner validateInput(36) {
        require(lastExecuted[scheduledExecution] > 0, "registry/execution-not-scheduled");
        lastExecuted[scheduledExecution] = 0;
        emit ChangeCancelled(scheduledExecution);
    }

    event ChangeScheduled(bytes32 dataHash, uint256 scheduledFor, bytes data);
    event ChangeApplied(bytes32 dataHash, uint256 appliedAt, bytes data);
    event ChangeCancelled(bytes32 dataHash);
    event NamedServiceRemoved(bytes32 nameHash);
}