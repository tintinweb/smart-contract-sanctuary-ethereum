// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SwapFeeCharge is Ownable {
    address public treasury;
    mapping(address => uint256) public userFeeCharged;

    event FeePayed(address user, uint256 amount);
    event TreasuryChanged(address oldTreasury, address newTreasury);

    constructor(address _treasury) {
        require(_treasury != address(0), "Treasury address missing");
        treasury = _treasury;
    }

    /**
     * @dev Set treasury address
     * @param _treasury: treasury address
     **/
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Treasury address missing");

        address oldTreasury = treasury;
        treasury = _treasury;

        emit TreasuryChanged(oldTreasury, treasury);
    }

    /**
     * @dev Execute swap transaction
     * @param _data: swap data
     * @param _gasFee: gasfee to send treasury
     **/
    function executeSwap(
        address _target,
        bytes calldata _data,
        uint256 _gasFee
    ) external payable {
        require(msg.value >= _gasFee, "Not enough ETH fee");

        // exectue swap function
        (bool success, bytes memory returnData) = _target.delegatecall(_data);
        if (!success) {
            decodeRevert(returnData);
        }

        // charge ETH fee
        safeTransferETH(treasury, _gasFee);

        // refund dust eth, if any
        if (msg.value > _gasFee)
            safeTransferETH(msg.sender, msg.value - _gasFee);

        userFeeCharged[msg.sender] += _gasFee;

        emit FeePayed(msg.sender, _gasFee);
    }

    /**
     * @dev Decode bytes result
     * @param _result     receipnt address
     */
    function decodeRevert(bytes memory _result) internal pure {
        if (_result.length < 68) revert();
        assembly {
            _result := add(_result, 0x04)
        }
        revert(abi.decode(_result, (string)));
    }

    /**
     * @dev Transfer eth
     * @param _to     receipnt address
     * @param _value  amount
     */
    function safeTransferETH(address _to, uint256 _value) internal {
        (bool success, ) = _to.call{value: _value}(new bytes(0));
        require(success, "SafeTransferETH: ETH transfer failed");
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

pragma solidity ^0.8.0;

/*
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