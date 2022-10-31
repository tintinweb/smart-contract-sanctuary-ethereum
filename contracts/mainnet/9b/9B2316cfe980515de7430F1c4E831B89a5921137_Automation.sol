// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import "../controller/IAccount.sol";
import "../verifier/IERC2612Verifier.sol";
import "../verifier/ITokenApprovalVerifier.sol";

contract Automation {
    address public immutable verifier;
    address public immutable tokenApprovalVerifier;
    address public immutable loanProvider;
    mapping(address => address) public customizedLoanProviders;

    event SetLoanProvider(address account, address loanProvider);

    constructor(
        address _verifier,
        address _tokenApprovalVerifier,
        address _loanProvider
    ) {
        verifier = _verifier;
        tokenApprovalVerifier = _tokenApprovalVerifier;
        loanProvider = _loanProvider;
    }

    function setLoanProvider(address account, address customizedLoanProvider)
        external
    {
        require(IAccount(account).owner() == msg.sender, "Owner check failed.");
        customizedLoanProviders[account] = customizedLoanProvider;
        emit SetLoanProvider(account, customizedLoanProvider);
    }

    function getLoanProvider(address account) public view returns (address) {
        return
            customizedLoanProviders[account] == address(0)
                ? loanProvider
                : customizedLoanProviders[account];
    }

    function _executeVerifyBasic(address account, uint256 operation)
        internal
        view
    {
        require(
            IERC2612Verifier(verifier).isTxPermitted(
                account,
                msg.sender,
                operation
            ),
            "denied"
        );
    }

    function _executeVerifyAdapter(address account, bytes memory callBytes)
        internal
        view
    {
        address adapter;
        assembly {
            adapter := mload(add(callBytes, 32))
        }
        require(
            IERC2612Verifier(verifier).isTxPermitted(
                account,
                msg.sender,
                adapter
            ),
            "denied"
        );
    }

    function _executeVerifyApproval(address account, address spender)
        internal
        view
    {
        require(
            ITokenApprovalVerifier(tokenApprovalVerifier).isWhitelisted(
                account,
                spender
            ),
            "denied"
        );
    }

    function _autoExecute(
        address account,
        bytes calldata callBytes,
        bool callType
    ) internal returns (bytes memory returnData) {
        _executeVerifyAdapter(account, callBytes);
        returnData = IAccount(account).executeOnAdapter(callBytes, callType);
    }

    function autoExecute(
        address account,
        bytes calldata callBytes,
        bool callType
    ) external returns (bytes memory) {
        return _autoExecute(account, callBytes, callType);
    }

    function autoExecuteWithPermit(
        address account,
        bytes calldata callBytes,
        bool callType,
        bytes32 approvalType,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bytes memory) {
        IERC2612Verifier(verifier).permit(
            account,
            msg.sender,
            approvalType,
            deadline,
            v,
            r,
            s
        );
        return _autoExecute(account, callBytes, callType);
    }

    function autoExecuteMultiCall(
        address account,
        bool[] memory callType,
        bytes[] memory callBytes,
        bool[] memory isNeedCallback
    ) external {
        require(
            callType.length == callBytes.length &&
                callBytes.length == isNeedCallback.length
        );
        for (uint256 i = 0; i < callType.length; i++) {
            _executeVerifyAdapter(account, callBytes[i]);
        }
        IAccount(payable(account)).multiCall(
            callType,
            callBytes,
            isNeedCallback
        );
    }

    function autoApprove(
        address account,
        address token,
        address spender,
        uint256 amount
    ) external {
        _executeVerifyBasic(account, 0);
        _executeVerifyApproval(account, spender);
        IAccount(payable(account)).approve(token, spender, amount);
    }

    function autoApproveWithPermit(
        address account,
        address[] memory tokens,
        address[] memory spenders,
        uint256[] memory amounts,
        address[] memory permitSpenders,
        bool enable,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(
            tokens.length == spenders.length &&
                spenders.length == amounts.length,
            "approve length error."
        );
        _executeVerifyBasic(account, 0);
        ITokenApprovalVerifier(tokenApprovalVerifier).permit(
            account,
            permitSpenders,
            enable,
            deadline,
            v,
            r,
            s
        );
        for (uint256 i = 0; i < spenders.length; i++) {
            _executeVerifyApproval(account, spenders[i]);
        }
        IAccount(payable(account)).approveTokens(tokens, spenders, amounts);
    }

    function doFlashLoan(
        address account,
        address token,
        uint256 amount,
        bytes calldata payload
    ) external {
        _executeVerifyBasic(account, 1);
        (
            bool[] memory _callType,
            bytes[] memory _callBytes,
            bool[] memory _isNeedCallback
        ) = abi.decode(payload, (bool[], bytes[], bool[]));
        require(
            _callType.length == _callBytes.length &&
                _callBytes.length == _isNeedCallback.length
        );
        for (uint256 i = 0; i < _callBytes.length; i++) {
            _executeVerifyAdapter(account, _callBytes[i]);
        }
        IERC3156FlashLender(getLoanProvider(account)).flashLoan(
            IERC3156FlashBorrower(account),
            token,
            amount,
            payload
        );
    }

    function autoExecuteOnSubAccount(
        address account,
        address subAccount,
        bytes calldata callArgs,
        uint256 amountETH
    ) external {
        _executeVerifyBasic(account, 2);
        require(Ownable(subAccount).owner() == account, "invalid account!");
        IAccount(payable(account)).callOnSubAccount(
            subAccount,
            callArgs,
            amountETH
        );
    }

    function doFlashLoanOnSubAccount(
        address account,
        address subAccount,
        address token,
        uint256 amount,
        bytes calldata payload
    ) external {
        _executeVerifyBasic(account, 3);
        require(Ownable(subAccount).owner() == account, "invalid account!");
        IERC3156FlashLender(getLoanProvider(account)).flashLoan(
            IERC3156FlashBorrower(subAccount),
            token,
            amount,
            payload
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC3156FlashLender.sol)

pragma solidity ^0.8.0;

import "./IERC3156FlashBorrower.sol";

/**
 * @dev Interface of the ERC3156 FlashLender, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IAccount {
    function owner() external view returns (address);

    function createSubAccount(bytes memory _data, uint256 _costETH)
        external
        payable
        returns (address newSubAccount);

    function executeOnAdapter(bytes calldata _callBytes, bool _callType)
        external
        payable
        returns (bytes memory);

    function multiCall(
        bool[] calldata _callType,
        bytes[] calldata _callArgs,
        bool[] calldata _isNeedCallback
    ) external;

    function setAdvancedOption(bool val) external;

    function callOnSubAccount(
        address _target,
        bytes calldata _callArgs,
        uint256 amountETH
    ) external;

    function withdrawAssets(
        address[] calldata _tokens,
        address _receiver,
        uint256[] calldata _amounts
    ) external;

    function approve(
        address tokenAddr,
        address to,
        uint256 amount
    ) external;

    function approveTokens(
        address[] calldata _tokens,
        address[] calldata _spenders,
        uint256[] calldata _amounts
    ) external;

    function isSubAccount(address subAccount) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IERC2612Verifier {
    event OperatorUpdate(
        address account,
        address operator,
        bytes32 approvalType
    );

    function approve(
        address account,
        address operator,
        bytes32 approvalType,
        uint256 deadline
    ) external;

    function permit(
        address account,
        address operator,
        bytes32 approvalType,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function isTxPermitted(
        address account,
        address operator,
        address adapter
    ) external view returns (bool);

    function isTxPermitted(
        address account,
        address operator,
        uint256 operation
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface ITokenApprovalVerifier {
    event ApprovalUpdate(address account, address[] spenders, bool isAllowed);

    function approve(
        address account,
        address[] memory spenders,
        bool enable,
        uint256 deadline
    ) external;

    function permit(
        address account,
        address[] memory spenders,
        bool enable,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function isWhitelisted(address account, address operator)
        external
        view
        returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC3156FlashBorrower.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC3156 FlashBorrower, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}