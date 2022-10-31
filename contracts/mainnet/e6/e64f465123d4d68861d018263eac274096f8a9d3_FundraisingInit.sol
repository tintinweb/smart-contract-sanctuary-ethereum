// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

// OpenZeppelin imports
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Diamond imports
import { LibDiamond } from "../../diamond/libraries/LibDiamond.sol";
import { IDiamondLoupe } from "../../diamond/interfaces/IDiamondLoupe.sol";
import { IDiamondCut } from "../../diamond/interfaces/IDiamondCut.sol";
import { IERC173 } from "../../diamond/interfaces/IERC173.sol";

// Local imports
import { AccessTypes } from "../structs/AccessTypes.sol";
import { LibAccessControl } from "../libraries/LibAccessControl.sol";
import { LibAppStorage } from "../libraries/LibAppStorage.sol";
import { IRaiseFacet } from "../interfaces/IRaiseFacet.sol";
import { IMilestoneFacet } from "../interfaces/IMilestoneFacet.sol";
import { IEquityBadge } from "../../interfaces/IEquityBadge.sol";

/**************************************

    Fundraising initializer

    ------------------------------

    Diamond deployment looks like this:
    - deploy diamond cutter
    - deploy main diamond
    - deploy initializer
    - deploy all facets
    - perform cut with facets and initializer

 **************************************/

contract FundraisingInit {

    // args
    struct Arguments {
        address usdt;
        address signer;
        address badge;
    }

    // init
    function init(Arguments calldata _args) external {

        // owner
        address _owner = msg.sender;

        // access control
        LibAccessControl.createAdmin(_owner);
        LibAccessControl.grantRole(AccessTypes.SIGNER_ROLE, _args.signer);

        // app storage
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        s.usdt = IERC20(_args.usdt);
        s.equityBadge = IEquityBadge(_args.badge);

        // interfaces
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
        ds.supportedInterfaces[type(IRaiseFacet).interfaceId] = true;
        ds.supportedInterfaces[type(IMilestoneFacet).interfaceId] = true;

    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

// Local imports
import { BaseTypes } from "../structs/BaseTypes.sol";
import { RequestTypes } from "../structs/RequestTypes.sol";

/**************************************

    Raise facet interface

**************************************/

interface IRaiseFacet {

    // events
    event NewRaise(address sender, BaseTypes.Raise raise, BaseTypes.Milestone[] milestones, bytes32 message);
    event NewInvestment(address sender, string raiseId, uint256 investment, bytes32 message, uint256 data);

    // errors
    error NonceExpired(address sender, uint256 nonce);
    error RequestExpired(address sender, bytes request);
    error IncorrectSender(address sender);
    error IncorrectSigner(address signer);
    error InvalidRaiseId(string raiseId);
    error InvalidMilestoneCount(BaseTypes.Milestone[] milestones);
    error InvalidMilestoneStartEnd(uint256 start, uint256 end);
    error NotEnoughAllowance(address sender, address spender, uint256 amount);
    error IncorrectAmount(uint256 amount);
    error InvestmentOverLimit(uint256 existingInvestment, uint256 newInvestment, uint256 maxTicketSize);
    error InvestmentOverHardcap(uint256 existingInvestment, uint256 newInvestment, uint256 hardcap);
    error RaiseNotActive(string raiseId, uint256 currentTime);
    error RaiseNotFinished(string raiseId);
    error SoftcapAchieved(string raiseId);

    /**************************************

        Create new raise

     **************************************/

    function createRaise(
        RequestTypes.CreateRaiseRequest calldata _request,
        bytes32 _message,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /**************************************

        Invest

     **************************************/

    function invest(
        RequestTypes.InvestRequest calldata _request,
        bytes32 _message,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /**************************************

        Refund funds

     **************************************/

    function refundInvestment(string memory _raiseId) external;

    /**************************************

        View: Convert raise to badge

     **************************************/

    function convertRaiseToBadge(string memory _raiseId) external view
    returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Diamond imports
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

/**************************************

    Diamond library (EIP-2535)

    ------------------------------

    @author Nick Mudge

 **************************************/

library LibDiamond {

    // storage pointer
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    // structs: data containers
    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }
    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint16 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    // structs: lib storage
    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
        return ds;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    error CallerNotOwner(address owner, address caller);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        if (previousOwner != address(0) && previousOwner != msg.sender) {
            revert CallerNotOwner(previousOwner, msg.sender);
        }
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // uint16 selectorCount = uint16(diamondStorage().selectors.length);
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint16 selectorPosition = uint16(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
            ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }

        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(selector);
            ds.selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
            ds.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint16 selectorPosition = uint16(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
            ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(oldFacetAddress, selector);
            // add function
            ds.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(selector);
            ds.selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(oldFacetAddress, selector);
        }
    }

    function removeFunction(address _facetAddress, bytes4 _selector) internal {
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint16(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = uint16(facetAddressPosition);
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

import { IERC1155Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

/**************************************

    EquityBadge interface

 **************************************/

interface IEquityBadge is IERC1155Upgradeable {

    // mint from fundraising
    function mint(
        address _sender, uint256 _projectId, uint256 _amount, bytes memory _data
    ) external;

    // delegate on behalf from fundraising
    function delegateOnBehalf(
        address _account, address _delegatee, bytes memory _data
    ) external;

    // total supply
    function totalSupply(uint256 _projectId) external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    Diamond cut interface

    ------------------------------

    @author Nick Mudge

 **************************************/

interface IDiamondCut {

    // enum
    enum FacetCutAction { Add, Replace, Remove }

    // struct
    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    // event
    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    /**************************************

        Cut diamond

        ------------------------------

        @notice Add/replace/remove any number of functions and optionally execute a function with delegatecall
        @param _diamondCut Contains the facet addresses and function selectors
        @param _init The address of the contract or facet to execute _calldata
        @param _calldata A function call, including function selector and arguments, that is executed with delegatecall on _init

     **************************************/

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    Ownership interface

 **************************************/

interface IERC173 {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address owner_);

    function transferOwnership(address _newOwner) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

library AccessTypes {

    // roles
    bytes32 constant SIGNER_ROLE = keccak256("IS SIGNER");

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    Diamond loupe interface

    ------------------------------

    @author Nick Mudge

 **************************************/

interface IDiamondLoupe {

    // struct
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /**************************************

        Get facets

        ------------------------------

        @notice Gets all facet addresses and their four byte function selectors
        @return facets_ Facet

     **************************************/

    function facets() external view returns (Facet[] memory facets_);

    /**************************************

        Get facet function selectors

        ------------------------------

        @notice Gets all the function selectors supported by a specific facet
        @param _facet The facet address
        @return facetFunctionSelectors_

     **************************************/

    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /**************************************

        Get facet addresses

        ------------------------------

        @notice Get all the facet addresses used by a diamond
        @return facetAddresses_

     **************************************/

    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /**************************************

        Get facet address for selector

        ------------------------------

        @notice Gets the facet that supports the given selector
        @dev If facet is not found return address(0)
        @param _functionSelector The function selector
        @return facetAddress_ The facet address

     **************************************/

    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IEquityBadge } from "../../interfaces/IEquityBadge.sol";
import { IVestedGovernor } from "../../interfaces/IVestedGovernor.sol";

/**************************************

    AppStorage library

    ------------------------------

    A specialized version of Diamond Storage is AppStorage.
    This pattern is used to more conveniently and easily share state variables between facets.

 **************************************/

library LibAppStorage {

    // structs: data containers
    struct AppStorage {
        IERC20 usdt;
        IEquityBadge equityBadge;
        IVestedGovernor vestedGovernor;
    }

    // diamond storage getter
    function appStorage() internal pure
    returns (AppStorage storage s) {

        // set slot 0 and return
        assembly {
            s.slot := 0
        }

        // explicit return
        return s;

    }

    /**************************************

        Get USDT

     **************************************/

    function getUSDT() internal view
    returns (IERC20) {

        // return
        return appStorage().usdt;

    }

    /**************************************

        Get badge

     **************************************/

    function getBadge() internal view
    returns (IEquityBadge) {

        // return
        return appStorage().equityBadge;

    }

    /**************************************

        Get vested governor

     **************************************/

    function getGovernor() internal view
    returns (IVestedGovernor) {

        // return
        return appStorage().vestedGovernor;

    }

    /**************************************

        Get timelock

     **************************************/

    function getTimelock() internal view
    returns (address) {

        // return
        return appStorage().vestedGovernor.timelock();

    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

// OpenZeppelin imports
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

/**************************************

    AccessControl library

    ------------------------------

    Diamond storage containing access control data

 **************************************/

library LibAccessControl {

    // storage pointer
    bytes32 constant ACCESS_CONTROL_STORAGE_POSITION = keccak256("angelblock.access.control");
    bytes32 constant ADMIN_ROLE = 0x0;

    // structs: data containers
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }
    struct AccessControlStorage {
        mapping(bytes32 => RoleData) roles;
        bool initialized;
    }

    // diamond storage getter
    function accessStorage() internal pure
    returns (AccessControlStorage storage acs) {

        // declare position
        bytes32 position = ACCESS_CONTROL_STORAGE_POSITION;

        // set slot to position
        assembly {
            acs.slot := position
        }

        // explicit return
        return acs;

    }

    // events
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    // errors
    error CannotSetAdminForAdmin();
    error CanOnlyRenounceSelf();
    error OneTimeFunction();

    // modifiers
    modifier onlyRole(bytes32 _role) {

        // check role
        if (!hasRole(_role, msg.sender)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(msg.sender),
                        " is missing role ",
                        Strings.toHexString(uint256(_role), 32)
                    )
                )
            );
        }
        _;

    }
    modifier oneTime() {

        // storage
        AccessControlStorage storage acs = accessStorage();

        // initialize
        if (!acs.initialized) {
            acs.initialized = true;
            _;
        } else {
            revert OneTimeFunction();
        }

    }

    // diamond storage getter: has role
    function hasRole(bytes32 _role, address _account) internal view 
    returns (bool) {

        // return
        return accessStorage().roles[_role].members[_account];

    }

    // diamond storage setter: set role
    function createAdmin(address _account) internal oneTime() {

        // set role
        accessStorage().roles[ADMIN_ROLE].members[_account] = true;

    }

    // diamond storage getter: has admin role
    function getRoleAdmin(bytes32 _role) internal view 
    returns (bytes32) {

        // return
        return accessStorage().roles[_role].adminRole;

    }

    // diamond storage setter: set admin role
    function setRoleAdmin(bytes32 _role, bytes32 _adminRole) internal onlyRole(ADMIN_ROLE) {

        // accept each role except admin
        if (_role != ADMIN_ROLE) accessStorage().roles[_role].adminRole = _adminRole;
        else revert CannotSetAdminForAdmin();

    }

    /**************************************

        Grant role

     **************************************/

    function grantRole(bytes32 _role, address _account) internal onlyRole(getRoleAdmin(_role)) {

        // grant
        _grantRole(_role, _account);

    }

    /**************************************

        Revoke role

     **************************************/

    function revokeRole(bytes32 _role, address _account) internal onlyRole(getRoleAdmin(_role)) {

        // revoke
        _revokeRole(_role, _account);

    }

    /**************************************

        Renounce role

     **************************************/

    function renounceRole(bytes32 role, address account) internal {

        // check sender
        if (account != msg.sender) {
            revert CanOnlyRenounceSelf();
        }

        // revoke
        _revokeRole(role, account);

    }

    /**************************************

        Low level: grant

     **************************************/

    function _grantRole(bytes32 _role, address _account) private {

        // check if not have role already
        if (!hasRole(_role, _account)) {

            // grant role
            accessStorage().roles[_role].members[_account] = true;

            // event
            emit RoleGranted(_role, _account, msg.sender);

        }

    }

    /**************************************

        Low level: revoke

     **************************************/

    function _revokeRole(bytes32 _role, address _account) private {

        // check if have role
        if (hasRole(_role, _account)) {

            // revoke role
            accessStorage().roles[_role].members[_account] = false;

            // event
            emit RoleRevoked(_role, _account, msg.sender);

        }

    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

/**************************************

    Milestone facet interface

**************************************/

interface IMilestoneFacet {
    function postponeMilestones(
        string memory _raiseId,
        uint256 delay
    ) external;
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
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

library BaseTypes {

    // enums: low level
    enum SimpleVote {
        NO,
        YES
    }
    enum VotingStatus {
        ACCEPTED,
        REJECTED,
        NOT_RESOLVED
    }

    // structs: low level
    struct Raise {
        string raiseId;
        uint256 hardcap;
        uint256 softcap;
        uint256 start;
        uint256 end;
    }
    struct Vested {
        address erc20;
        uint256 amount;
    }
    struct Milestone {
        uint256 number;
        uint256 deadline;
        bytes32 hashedDescription;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

import { BaseTypes } from "./BaseTypes.sol";

library RequestTypes {

    // structs: requests
    struct BaseRequest {
        address sender;
        uint256 expiry;
        uint256 nonce;
    }
    struct CreateRaiseRequest {
        BaseTypes.Raise raise;
        BaseTypes.Vested vested;
        BaseTypes.Milestone[] milestones;
        BaseRequest base;
    }
    struct InvestRequest {
        string raiseId;
        uint256 investment;
        uint256 maxTicketSize;
        BaseRequest base;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
interface IERC165Upgradeable {
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
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

import { IGovernorTimelock } from "../oz/interfaces/IGovernorTimelock.sol";

/**************************************

    VestedGovernor interface

 **************************************/

abstract contract IVestedGovernor is IGovernorTimelock {}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    @dev AB: OZ override
    @dev Modification scope: inheriting from modified Governor

    ------------------------------

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

 **************************************/

import { IGovernor } from "./IGovernor.sol";

/**
 * @dev Extension of the {IGovernor} for timelock supporting modules.
 *
 * _Available since v4.3._
 */
abstract contract IGovernorTimelock is IGovernor {
    event ProposalQueued(uint256 proposalId, uint256 eta);

    function timelock() public view virtual returns (address);

    function proposalEta(uint256 proposalId) public view virtual returns (uint256);

    function queue(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public virtual returns (uint256 proposalId);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    @dev AB: OZ override
    @dev Modification scope: getVotes, propose, castVote, castVoteWithReason, castVoteBySig

    ------------------------------

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

 **************************************/

// OZ imports
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface of the {Governor} core.
 *
 * _Available since v4.3._
 */
abstract contract IGovernor is IERC165 {
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    /**
     * @dev Emitted when a proposal is created.
     */
    event ProposalCreated(
        uint256 proposalId,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );

    /**
     * @dev Emitted when a proposal is canceled.
     */
    event ProposalCanceled(uint256 proposalId);

    /**
     * @dev Emitted when a proposal is executed.
     */
    event ProposalExecuted(uint256 proposalId);

    /**
     * @dev Emitted when a vote is cast without params.
     *
     * Note: `support` values should be seen as buckets. Their interpretation depends on the voting module used.
     */
    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 weight, string reason);

    /**
     * @dev Emitted when a vote is cast with params.
     *
     * Note: `support` values should be seen as buckets. Their interpretation depends on the voting module used.
     * `params` are additional encoded parameters. Their intepepretation also depends on the voting module used.
     */
    event VoteCastWithParams(
        address indexed voter,
        uint256 proposalId,
        uint8 support,
        uint256 weight,
        string reason,
        bytes params
    );

    /**
     * @notice module:core
     * @dev Name of the governor instance (used in building the ERC712 domain separator).
     */
    function name() public view virtual returns (string memory);

    /**
     * @notice module:core
     * @dev Version of the governor instance (used in building the ERC712 domain separator). Default: "1"
     */
    function version() public view virtual returns (string memory);

    /**
     * @notice module:voting
     * @dev A description of the possible `support` values for {castVote} and the way these votes are counted, meant to
     * be consumed by UIs to show correct vote options and interpret the results. The string is a URL-encoded sequence of
     * key-value pairs that each describe one aspect, for example `support=bravo&quorum=for,abstain`.
     *
     * There are 2 standard keys: `support` and `quorum`.
     *
     * - `support=bravo` refers to the vote options 0 = Against, 1 = For, 2 = Abstain, as in `GovernorBravo`.
     * - `quorum=bravo` means that only For votes are counted towards quorum.
     * - `quorum=for,abstain` means that both For and Abstain votes are counted towards quorum.
     *
     * If a counting module makes use of encoded `params`, it should  include this under a `params` key with a unique
     * name that describes the behavior. For example:
     *
     * - `params=fractional` might refer to a scheme where votes are divided fractionally between for/against/abstain.
     * - `params=erc721` might refer to a scheme where specific NFTs are delegated to vote.
     *
     * NOTE: The string can be decoded by the standard
     * https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams[`URLSearchParams`]
     * JavaScript class.
     */
    // solhint-disable-next-line func-name-mixedcase
    function COUNTING_MODE() public pure virtual returns (string memory);

    /**
     * @notice module:core
     * @dev Hashing function used to (re)build the proposal id from the proposal details..
     */
    function hashProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public pure virtual returns (uint256);

    /**
     * @notice module:core
     * @dev Current state of a proposal, following Compound's convention
     */
    function state(uint256 proposalId) public view virtual returns (ProposalState);

    /**
     * @notice module:core
     * @dev Block number used to retrieve user's votes and quorum. As per Compound's Comp and OpenZeppelin's
     * ERC20Votes, the snapshot is performed at the end of this block. Hence, voting for this proposal starts at the
     * beginning of the following block.
     */
    function proposalSnapshot(uint256 proposalId) public view virtual returns (uint256);

    /**
     * @notice module:core
     * @dev Block number at which votes close. Votes close at the end of this block, so it is possible to cast a vote
     * during this block.
     */
    function proposalDeadline(uint256 proposalId) public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Delay, in number of block, between the proposal is created and the vote starts. This can be increased to
     * leave time for users to buy voting power, or delegate it, before the voting of a proposal starts.
     */
    function votingDelay() public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Delay, in number of blocks, between the vote start and vote ends.
     *
     * NOTE: The {votingDelay} can delay the start of the vote. This must be considered when setting the voting
     * duration compared to the voting delay.
     */
    function votingPeriod() public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Minimum number of cast voted required for a proposal to be successful.
     *
     * Note: The `blockNumber` parameter corresponds to the snapshot used for counting vote. This allows to scale the
     * quorum depending on values such as the totalSupply of a token at this block (see {ERC20Votes}).
     */
    function quorum(uint256 blockNumber) public view virtual returns (uint256);

    /**************************************

        @notice Override of OZ getVotes

        ------------------------------

        @dev AB: added data arg
        @dev Example usage for ERC20: empty (value: 0x0)
        @dev Example usage for ERC1155: tokenId (type: bytes<uint256>)

        ------------------------------

        @param account Target account to get votes for
        @param blockNumber Number of block to get votes for
        @param data Bytes encoding optional parameters

     **************************************/

    /**
     * @notice module:reputation
     * @dev Voting power of an `account` at a specific `blockNumber`.
     *
     * Note: this can be implemented in a number of ways, for example by reading the delegated balance from one (or
     * multiple), {ERC20Votes} tokens.
     */
    function getVotes(
        address account, 
        uint256 blockNumber, 
        bytes memory data
    ) public view virtual returns (uint256);

    /**
     * @notice module:reputation
     * @dev Voting power of an `account` at a specific `blockNumber` given additional encoded parameters.
     */
    function getVotesWithParams(
        address account,
        uint256 blockNumber,
        bytes memory params
    ) public view virtual returns (uint256);

    /**
     * @notice module:voting
     * @dev Returns either `account` has cast a vote on `proposalId`.
     */
    function hasVoted(uint256 proposalId, address account) public view virtual returns (bool);

    /**************************************

        @notice Override of OZ propose

        ------------------------------

        @dev AB: added data arg
        @dev Example usage for ERC20: empty (value: 0x0)
        @dev Example usage for ERC1155: tokenId (type: bytes<uint256>)

        ------------------------------

        @param targets List of addresses for delegatecalls
        @param values List of ether amounts for delegatecalls
        @param calldatas List of encoded functions with arguments
        @param description Description of proposal
        @param data Bytes encoding optional parameters

     **************************************/

    /**
     * @dev Create a new proposal. Vote start {IGovernor-votingDelay} blocks after the proposal is created and ends
     * {IGovernor-votingPeriod} blocks after the voting starts.
     *
     * Emits a {ProposalCreated} event.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description,
        bytes memory data
    ) public virtual returns (uint256 proposalId);

    /**
     * @dev Execute a successful proposal. This requires the quorum to be reached, the vote to be successful, and the
     * deadline to be reached.
     *
     * Emits a {ProposalExecuted} event.
     *
     * Note: some module can modify the requirements for execution, for example by adding an additional timelock.
     */
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public payable virtual returns (uint256 proposalId);

    /**************************************

        @notice Override of OZ castVote

        ------------------------------

        @dev AB: added data arg
        @dev Example usage for ERC20: empty (value: 0x0)
        @dev Example usage for ERC1155: tokenId (type: bytes<uint256>)

        ------------------------------

        @param proposalId Number of proposal
        @param support Decision of voting
        @param data Bytes encoding optional parameters

     **************************************/

    /**
     * @dev Cast a vote
     *
     * Emits a {VoteCast} event.
     */
    function castVote(uint256 proposalId, uint8 support, bytes memory data) public virtual returns (uint256 balance);

    /**************************************

        @notice Override of OZ castVoteWithReason

        ------------------------------

        @dev AB: added data arg
        @dev Example usage for ERC20: empty (value: 0x0)
        @dev Example usage for ERC1155: tokenId (type: bytes<uint256>)

        ------------------------------

        @param proposalId Number of proposal
        @param support Decision of voting
        @param reason String for the reason
        @param data Bytes encoding optional parameters

     **************************************/

    /**
     * @dev Cast a vote with a reason
     *
     * Emits a {VoteCast} event.
     */
    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory data
    ) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote with a reason and additional encoded parameters
     *
     * Emits a {VoteCast} or {VoteCastWithParams} event depending on the length of params.
     */
    function castVoteWithReasonAndParams(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory params
    ) public virtual returns (uint256 balance);

    /**************************************

        @notice Override of OZ castVoteBySig

        ------------------------------

        @dev AB: added data arg
        @dev Example usage for ERC20: empty (value: 0x0)
        @dev Example usage for ERC1155: tokenId (type: bytes<uint256>)

        ------------------------------

        @param proposalId Number of proposal
        @param support Decision of voting
        @param data Bytes encoding optional parameters
        @param v Part of signature
        @param r Part of signature
        @param s Part of signature

     **************************************/

    /**
     * @dev Cast a vote using the user's cryptographic signature.
     *
     * Emits a {VoteCast} event.
     */
    function castVoteBySig(
        uint256 proposalId,
        uint8 support,
        bytes memory data,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote with a reason and additional encoded parameters using the user's cryptographic signature.
     *
     * Emits a {VoteCast} or {VoteCastWithParams} event depending on the length of params.
     */
    function castVoteWithReasonAndParamsBySig(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory params,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual returns (uint256 balance);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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