//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

import "./MintController.sol";

/**
 * @title MasterMinter
 * @notice MasterMinter uses multiple controllers to manage minters for a
 * contract that implements the MinterManagerInterface.
 * @dev MasterMinter inherits all its functionality from MintController.
 */
contract MasterMinter is MintController {
    constructor(address _minterManager) MintController(_minterManager) {}
}

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

import "./Controller.sol";
import "./MinterManagerInterface.sol";

contract MintController is Controller {

    /*
     * @title MinterManagementInterface
     * @notice MintController calls the minterManager to execute/record minter
     * management tasks, as well as to query the status of a minter address.
     */
    MinterManagementInterface internal minterManager;
    mapping(address => uint256) internal minterAllowance;
    mapping(address => uint256) internal minterCap;
    mapping(address => uint256) internal maxPerTxn;

    event MinterManagerSet(
        address indexed _oldMinterManager,
        address indexed _newMinterManager
    );
    event MinterConfigured(
        address indexed _msgSender,
        address indexed _minter,
        uint256 _allowance
    );
    event MinterRemoved(address indexed _msgSender, address indexed _minter);
    event MinterAllowanceIncremented(
        address indexed _msgSender,
        address indexed _minter,
        uint256 _increment,
        uint256 _newAllowance
    );

    event MinterAllowanceDecremented(
        address indexed msgSender,
        address indexed minter,
        uint256 decrement,
        uint256 newAllowance
    );

    /*
     * @notice Initializes the minterManager.
     * @param _minterManager The address of the minterManager contract.
     */
    constructor(address _minterManager) {
        minterManager = MinterManagementInterface(_minterManager);
    }

    /*
     * @notice gets the minterManager
     */
    function getMinterManager()
        external
        view
        returns (MinterManagementInterface)
    {
        return minterManager;
    }

    // onlyOwner functions

    /**
     * @notice Sets the minterManager.
     * @param _newMinterManager The address of the new minterManager contract.
     */
    function setMinterManager(address _newMinterManager) public onlyOwner {
        emit MinterManagerSet(address(minterManager), _newMinterManager);
        minterManager = MinterManagementInterface(_newMinterManager);
    }

    // onlyController functions

    /**
     * @notice Removes the controller's own minter.
     */
    function removeMinter(address _minter)
        public
        onlyController
        returns (bool)
    {
        require(
            controllers[msg.sender][0] != address(0),
            "controller has no minters"
        );
        for (uint256 i; i < controllers[msg.sender].length; i++) {
            if (controllers[msg.sender][i] == _minter) {
                minterController[_minter] = address(0);
                delete controllers[msg.sender][i];
                isMinter[_minter] = false;
                emit MinterRemoved(msg.sender, _minter);
                return minterManager.removeMinter(_minter);
            }
        }
        return false;
    }

    /**
     * @notice Enables the minter and sets its allowance.
     * @param _newAllowance New allowance to be set for minter.
     */
    function configureMinter(
        address _minter,
        uint256 _newAllowance,
        uint256 _minterCap,
        uint256 _maxPerTxn
    ) public payable onlyController returns (bool) {
        require(_minter != address(0), "No zero addr");
        //total minted vs allowance
        if (minterController[_minter] == address(0)) {
            minterController[_minter] = msg.sender;

            if (controllers[msg.sender][0] == address(0)) {
                controllers[msg.sender][0] = _minter;
            } else {
                controllers[msg.sender].push(_minter);
            }
        }
        require(
            minterController[_minter] == msg.sender,
            "minter has controller"
        );
        isMinter[_minter] = true;
        minterCap[_minter] = _minterCap;
        emit MinterConfigured(msg.sender, _minter, _newAllowance);
        return
            internal_setMinterAllowance(
                _minter,
                _newAllowance,
                _minterCap,
                _maxPerTxn
            );
    }

    /**
     * @notice Increases the minter's allowance if and only if the minter is an
     * active minter.
     * @dev An minter is considered active if minterManager.isMinter(minter)
     * returns true.
     */
    function incrementMinterAllowance(
        uint256 _allowanceIncrement,
        address _minter
    ) public onlyController returns (bool) {
        require(_allowanceIncrement > 0, "increment too small");
        require(minterManager.isMinter(_minter), "only for minter allowance");

        uint256 currentAllowance = minterManager.getMinterAllowance(_minter);
        uint256 newAllowance = currentAllowance + _allowanceIncrement;

        emit MinterAllowanceIncremented(
            msg.sender,
            _minter,
            _allowanceIncrement,
            newAllowance
        );

        return
            internal_setMinterAllowance(
                _minter,
                newAllowance,
                minterCap[_minter],
                maxPerTxn[_minter]
            );
    }

    /**
     * @notice decreases the minter allowance if and only if the minter is
     * currently active. The controller can safely send a signed
     * decrementMinterAllowance() transaction to a minter and not worry
     * about it being used to undo a removeMinter() transaction.
     */
    function decrementMinterAllowance(
        uint256 _allowanceDecrement,
        address _minter
    ) public onlyController returns (bool) {
        require(_allowanceDecrement > 0, "allowance too small");
        require(
            minterController[_minter] == msg.sender,
            "not minter's controller"
        );
        require(minterManager.isMinter(_minter), "only for minter allowance");

        uint256 currentAllowance = minterManager.getMinterAllowance(_minter);

        uint256 actualAllowanceDecrement = (
            currentAllowance > _allowanceDecrement
                ? _allowanceDecrement
                : currentAllowance
        );

        uint256 newAllowance = currentAllowance - actualAllowanceDecrement;

        emit MinterAllowanceDecremented(
            msg.sender,
            _minter,
            actualAllowanceDecrement,
            newAllowance
        );
        return
            internal_setMinterAllowance(
                _minter,
                newAllowance,
                minterCap[_minter],
                maxPerTxn[_minter]
            );
    }

    // Internal functions

    /**
     * @notice Uses the MinterManagementInterface to enable the minter and
     * set its allowance.
     * @param _minter Minter to set new allowance of.
     * @param _newAllowance New allowance to be set for minter.
     */
    function internal_setMinterAllowance(
        address _minter,
        uint256 _newAllowance,
        uint256 _minterCap,
        uint256 _maxPerTxn
    ) internal returns (bool) {
        return
            minterManager.configureMinter(
                _minter,
                _newAllowance,
                _minterCap,
                _maxPerTxn
            );
    }
}

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

import {ControllerAdmin} from "./ControllerAdmin.sol";

/**
 * @title Controller
 * @notice Generic implementation of the owner-controller-worker model.
 * One owner manages many controllers. Each controller manages one worker.
 * Workers may be reused across different controllers.
 */
contract Controller is ControllerAdmin {
    /**
     * @notice A controller manages a single worker address.
     * controllers[controller] = worker
     */
    mapping(address => address[]) public controllers;
    mapping(address => address) public minterController;
    mapping(address => bool) public isController;
    mapping(address => bool) public isMinter;

    event ControllerConfigured(
        address indexed _controller,
        address indexed _minter
    );

    event ControllerRemoved(address indexed _controller);
    event SignerModified(address indexed _signer);

    /**
     * @notice Ensures that caller is the controller of a non-zero worker
     * address.
     */
    modifier onlyController() {
        require(
            controllers[msg.sender].length != 0,
            "controller has no minters"
        );

        _;
    }

    function configureController(address _controller, address _minter)
        public
        onlyControllerAdmin
    {
        require(_controller != address(0), "No zero addr");
        require(_minter != address(0), "No zero addr");
        if (minterController[_minter] == address(0)) {
            minterController[_minter] = _controller;
        }
        require(
            minterController[_minter] == _controller,
            "minter has controller"
        );
        controllers[_controller].push(_minter);
        isMinter[_minter] = true;
        isController[_controller] = true;
        emit ControllerConfigured(_controller, _minter);
    }

    /**
     * @notice Gets the minter at address _controller.
     */
    function getMinters(address _controller)
        external
        view
        returns (address[] memory)
    {
        require(
            controllers[_controller].length != 0,
            "unconfigured controller"
        );
        return controllers[_controller];
    }

    /**
     * @notice disables a controller by setting its worker to address(0).
     * @param _controller The controller to disable.
     */
    function removeController(address _controller) public onlyControllerAdmin {
        require(_controller != address(0), "No zero addr");
        require(
            controllers[_controller].length != 0,
            "controller has no minters"
        );
        isController[_controller] = false;
        delete controllers[_controller];
        emit ControllerRemoved(_controller);
    }
}

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

/**
 * @notice A contract that implements the MinterManagementInterface has external
 * functions for adding and removing minters and modifying their allowances.
 * An example is the FiatTokenV1 contract that implements USDC.
 */
interface MinterManagementInterface {
    function isMinter(address _account) external view returns (bool);

    function getMinterAllowance(address _minter) external view returns (uint256);

    function configureMinter(address _minter, uint256 _minterAllowedAmount, uint256 _minterCap, uint256 _maxPerTxn)
        external
        returns (bool);

    function removeMinter(address _minter) external returns (bool);
}

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

import {Ownable} from "../TokenContracts/Ownable.sol";

/**
* @notice Contract that lets owner set a controller admin that can add or remove
* controllers. Only the contract owner can modify the admin.
 */

contract ControllerAdmin is Ownable {
    address internal _controllerAdmin;

    event controllerAdminChanged(address indexed admin);

    modifier onlyControllerAdmin() {
        require(msg.sender != address(0), "No zero addr");
        require(msg.sender == _controllerAdmin, "caller not controller admin");
        _;
    }

    function getControllerAdmin() external view returns (address) {
        return _controllerAdmin;
    }

    function setControllerAdmin(address _newAdmin) external onlyOwner {
        require(_newAdmin != address(0), "No zero addr");
        _controllerAdmin = _newAdmin;
        emit controllerAdminChanged(_controllerAdmin);
    }
}

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

/**
 * @notice The Ownable contract has an owner address, and provides basic
 * authorization control functions
 */
contract Ownable {
    // Owner of the contract
    address private _owner;
    //bool public initialized;

    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event OwnershipTransferred(address previousOwner, address newOwner);

     /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "caller not owner");
        _;
    }

    /**
     * @dev The constructor sets the original owner of the contract to the sender account.
     */
    constructor() {
        setOwner(msg.sender);
    }

    /**
     * @dev Tells the address of the owner
     * @return the address of the owner
     */
    function getOwner() external view returns (address) {
        return _owner;
    }

    /**
     * @dev Sets a new owner address
     */
    function setOwner(address newOwner) internal {
        _owner = newOwner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(
            newOwner != address(0),
            "No zero addr"
        );
        emit OwnershipTransferred(_owner, newOwner);
        setOwner(newOwner);
    }
}