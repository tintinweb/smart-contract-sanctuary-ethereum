//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

import "./Controller.sol";
import "./MinterManagerInterface.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MintController is Controller {
    using SafeMath for uint256;

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
        uint256 newAllowance = currentAllowance.add(_allowanceIncrement);

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

        uint256 newAllowance = currentAllowance.sub(actualAllowanceDecrement);

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

pragma solidity ^0.8.0;

import {Ownable} from "../TokenContracts/Ownable.sol";
import {ControllerAdmin} from "./ControllerAdmin.sol";

/**
 * @title Controller
 * @notice Generic implementation of the owner-controller-worker model.
 * One owner manages many controllers. Each controller manages one worker.
 * Workers may be reused across different controllers.
 */
contract Controller is Ownable, ControllerAdmin {
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

    // onlyOwner functions

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

pragma solidity ^0.8.0;

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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @notice The Ownable contract has an owner address, and provides basic
 * authorization control functions
 */

contract Ownable {
    // Owner of the contract
    address private _owner;
    bool public initialized;

    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event OwnershipTransferred(address previousOwner, address newOwner);

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
    function owner() external view returns (address) {
        return _owner;
    }

    /**
     * @dev Sets a new owner address
     */
    function setOwner(address newOwner) internal {
        _owner = newOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "caller not owner");
        _;
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

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import {Ownable} from "../TokenContracts/Ownable.sol";

contract ControllerAdmin is Ownable {
    address public controllerAdmin;

    event controllerAdminChanged(address indexed admin);

    modifier onlyControllerAdmin() {
        require(msg.sender != address(0), "No zero addr");
        require(msg.sender == controllerAdmin, "caller not controller admin");
        _;
    }

    function getControllerAdmin() external view returns (address) {
        return controllerAdmin;
    }

    function setControllerAdmin(address _newAdmin) external onlyOwner {
        require(_newAdmin != address(0), "No zero addr");
        controllerAdmin = _newAdmin;
        emit controllerAdminChanged(controllerAdmin);
    }
}