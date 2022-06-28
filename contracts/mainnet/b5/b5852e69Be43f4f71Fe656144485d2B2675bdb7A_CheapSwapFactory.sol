//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICheapSwapFactory.sol";
import "./lib/ISwapRouter.sol";
import "./lib/IWETH.sol";
import "./CheapSwapTokenOutAddress.sol";
import "./CheapSwapTargetAddress.sol";

contract CheapSwapFactory is ICheapSwapFactory, Ownable {
    ISwapRouter public Router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IWETH9 public WETH = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    mapping(address => bytes) public pathMap;
    mapping(address => uint256) public oneETHAmountOutMinMap;
    mapping(address => mapping(address => address)) public tokenOutAddressMap;
    mapping(address => mapping(address => address)) public targetAddressMap;

    uint256 public fee = 0.001 ether;

    constructor() {
        WETH.approve(address(Router), type(uint256).max);
    }

    /* ================ TRANSACTION FUNCTIONS ================ */

    function createTokenOutAddress(address tokenOut) external {
        CheapSwapTokenOutAddress cheapSwapTokenOutAddress = new CheapSwapTokenOutAddress(msg.sender, tokenOut);
        tokenOutAddressMap[msg.sender][tokenOut] = address(cheapSwapTokenOutAddress);
    }

    function createTargetAddress(
        address target,
        uint256 value,
        bytes calldata data
    ) external {
        CheapSwapTargetAddress cheapSwapTargetAddress = new CheapSwapTargetAddress(msg.sender, target, value, data);
        targetAddressMap[msg.sender][target] = address(cheapSwapTargetAddress);
    }

    function amountInETH_amountOutMin(address tokenOut, address recipient) external payable {
        require(msg.value > fee, "CheapSwapFactory: value too low");
        require(pathMap[tokenOut].length != 0, "CheapSwapFactory: empty path");
        uint256 amountIn = msg.value - fee;
        WETH.deposit{value: amountIn}();
        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: pathMap[tokenOut],
            recipient: recipient,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: (amountIn * oneETHAmountOutMinMap[tokenOut]) / 10**18
        });
        Router.exactInput(params);
    }

    /* ================ ADMIN FUNCTIONS ================ */

    function getFee(address to) external onlyOwner {
        payable(to).transfer(address(this).balance);
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function setPath(address tokenOut, bytes calldata path) external onlyOwner {
        pathMap[tokenOut] = path;
    }

    function setOneETHAmountOutMin(address tokenOut, uint256 oneETHAmountOutMin) external onlyOwner {
        oneETHAmountOutMinMap[tokenOut] = oneETHAmountOutMin;
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ICheapSwapFactory {
    /* ================ TRANSACTION FUNCTIONS ================ */

    function createTokenOutAddress(address tokenOut) external;

    function createTargetAddress(
        address target,
        uint256 value,
        bytes calldata data
    ) external;

    function amountInETH_amountOutMin(address tokenOut, address recipient) external payable;

    /* ================ ADMIN FUNCTIONS ================ */

    function getFee(address to) external;

    function setFee(uint256 _fee) external;

    function setPath(address tokenOut, bytes calldata path) external;

    function setOneETHAmountOutMin(address tokenOut, uint256 oneETHAmountOutMin) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

interface ISwapRouter {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

interface IWETH9 {
    function deposit() external payable;

    function approve(address spender, uint256 amount) external returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "./interfaces/ICheapSwapFactory.sol";

contract CheapSwapTokenOutAddress {
    address public recipient;
    address public tokenOut;
    ICheapSwapFactory public cheapSwapFactory;

    constructor(address _recipient, address _tokenOut) {
        recipient = _recipient;
        tokenOut = _tokenOut;
        cheapSwapFactory = ICheapSwapFactory(msg.sender);
    }

    /* ================ TRANSACTION FUNCTIONS ================ */

    receive() external payable {
        cheapSwapFactory.amountInETH_amountOutMin{value: msg.value}(tokenOut, recipient);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "./interfaces/ICheapSwapFactory.sol";

contract CheapSwapTargetAddress {
    address public owner;
    address public target;
    uint256 public value;
    bytes public data;

    constructor(
        address _owner,
        address _target,
        uint256 _value,
        bytes memory _data
    ) {
        owner = _owner;
        target = _target;
        value = _value;
        data = _data;
    }

    /* ================ TRANSACTION FUNCTIONS ================ */

    receive() external payable {
        (bool success, ) = target.call{value: value}(data);
        require(success, "CheapSwapTargetAddress: call error");
    }

    /* ================ ADMIN FUNCTIONS ================ */

    function call(
        address _target,
        uint256 _value,
        bytes calldata _data
    ) external payable {
        require(msg.sender == owner, "CheapSwapTargetAddress: not owner");
        (bool success, ) = _target.call{value: _value}(_data);
        require(success, "CheapSwapTargetAddress: call error");
    }

    function setData(uint256 _value, bytes calldata _data) external {
        require(msg.sender == owner, "CheapSwapTargetAddress: not owner");
        value = _value;
        data = _data;
    }
}

// SPDX-License-Identifier: MIT

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