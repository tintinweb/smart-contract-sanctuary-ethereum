// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../CloneBase.sol";
import "../Interface/INFT.sol";
import "../Interface/IFeeManager.sol";
import "../Interface/IReferralManager.sol";
import "../library/TransferHelper.sol";

contract NFTFactory is CloneBase, Ownable {
    event NFTCreated(uint256 _id, address _nft);
    event ImplementationLaunched(uint256 _id, address _newImplementation);
    event ImplementationUpdated(uint256 _id, address _newImplementation);

    mapping(uint256 => address) public implementationIdVsImplementation;

    bool public isFeeManagerEnabled;

    IFeeManager public feeManager;

    //Trigger for ReferralManager mode
    bool public isReferralManagerEnabled;

    IReferralManager public referralManager;

    uint256 nextId = uint256(0);

    function _handleFeeManager()
        private
        returns (uint256 feeAmount_, address feeToken_)
    {
        if (isFeeManagerEnabled) {
            (feeAmount_, feeToken_) = getFeeInfo();
            if (feeToken_ != address(0)) {
                TransferHelper.safeTransferFrom(
                    feeToken_,
                    msg.sender,
                    address(this),
                    feeAmount_
                );

                TransferHelper.safeApprove(
                    feeToken_,
                    address(feeManager),
                    feeAmount_
                );

                feeManager.fetchFees();
            } else {
                require(msg.value == feeAmount_, "Invalid value sent for fee");
                feeManager.fetchFees{value: msg.value}();
            }
        }

        return (feeAmount_, feeToken_);
    }

    function getFeeInfo() public view returns (uint256, address) {
        if (isFeeManagerEnabled) {
            return feeManager.getFactoryFeeInfo(address(this));
        }
    }

    function _handleReferral(address referrer, uint256 feeAmount) private {
        if (isReferralManagerEnabled && referrer != address(0)) {
            referralManager.handleReferralForUser(
                referrer,
                msg.sender,
                feeAmount
            );
        }
    }

    function addImplementation(address _newImplementation) external {
        require(_newImplementation != address(0));

        implementationIdVsImplementation[nextId] = _newImplementation;

        emit ImplementationLaunched(nextId, _newImplementation);
        nextId += nextId;

    }

    function updateImplementation(uint256 _id, address _newImplementation)
        external
    {
        address implementation = implementationIdVsImplementation[_id];
        require(implementation != address(0), "Invalid implementation");

        implementationIdVsImplementation[_id] = _newImplementation;

        emit ImplementationUpdated(_id, _newImplementation);
    }

    function _launchNFT(uint256 _id, bytes memory _encodedData) private {
        address implementation = implementationIdVsImplementation[_id];
        require(implementation != address(0), "Invalid implementation");

        address nftClone = createClone(implementation);

        INFT(nftClone).init(_encodedData);

        emit NFTCreated(_id, nftClone);
    }

    function launchNFT(uint256 _id, bytes memory _encodedData)
        external
        payable
    {
        _launchNFT(_id, _encodedData);
        _handleFeeManager();
    }

    function launchNFTWithReferral(
        uint256 _id,
        address referrer,
        bytes memory _encodedData
    ) external payable {
        _launchNFT(_id, _encodedData);
        (uint256 feeAmount, ) = _handleFeeManager();
        _handleReferral(referrer, feeAmount);
    }

    function updateFeeManagerMode(
        bool _isFeeManagerEnabled,
        address _feeManager
    ) external onlyOwner {
        require(_feeManager != address(0), "Fee Manager address cant be zero");
        isFeeManagerEnabled = _isFeeManagerEnabled;
        feeManager = IFeeManager(_feeManager);
    }

    function updateReferralManagerMode(
        bool _isReferralManagerEnabled,
        address _referralManager
    ) external onlyOwner {
        require(
            _referralManager != address(0),
            "Referral Manager address cant be zero"
        );
        isReferralManagerEnabled = _isReferralManagerEnabled;
        referralManager = IReferralManager(_referralManager);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

contract CloneBase {

    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
    }

    function isClone(address target, address query)
        internal
        view
        returns (bool result)
    {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000
            )
            mstore(add(clone, 0xa), targetBytes)
            mstore(
                add(clone, 0x1e),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)
            result := and(
                eq(mload(clone), mload(other)),
                eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
            )
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface INFT {
    function init(bytes memory _encodedData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IFeeManager {
    function fetchFees() external payable returns (uint256);

    function getFactoryFeeInfo(address _factoryAddress)
        external
        view
        returns (uint256, address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IReferralManager {
    function handleReferralForUser(
        address referrer,
        address user,
        uint256 amount
    ) external;
}

pragma solidity >=0.6.0 <0.8.0;

// helper methods for interacting with ERC20 tokens that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}