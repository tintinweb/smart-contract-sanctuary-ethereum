//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ActionContext.sol";

contract DotEarthRoyalty is ActionContext {
    event Received(address from, uint256 amount);

    uint96 public dotEarthTreasuryNumerator;
    uint96 public dotEarthFundNumerator;

    address payable public dotEarthTreasuryWallet;
    address payable public dotEarthFundWallet;

    constructor(
        uint96 dotEarthTreasuryNumerator_,
        uint96 dotEarthFundNumerator_,
        address payable dotEarthTreasuryWallet_,
        address payable dotEarthFundWallet_
    ) {
        _prevalidateRolaty(
            dotEarthTreasuryNumerator_,
            dotEarthFundNumerator_,
            dotEarthTreasuryWallet_,
            dotEarthFundWallet_
        );
        dotEarthTreasuryNumerator = dotEarthTreasuryNumerator_;
        dotEarthFundNumerator = dotEarthFundNumerator_;
        dotEarthTreasuryWallet = dotEarthTreasuryWallet_;
        dotEarthFundWallet = dotEarthFundWallet_;
    }

    function feeDenominator() public pure returns (uint96) {
        return 10000;
    }

    function _prevalidateNumeratorAssigment(
        uint96 dotEarthTreasuryNumerator_,
        uint96 dotEarthFundNumerator_
    ) internal pure {
        //solhint-disable-next-line reason-string
        require(
            dotEarthTreasuryNumerator_ + dotEarthFundNumerator_ <=
                feeDenominator(),
            "DotEarthRoyalty: sum of numerators greater than feeDenominator"
        );
    }

    function _prevalidateAddresses(
        address dotEarthTreasuryWallet_,
        address dotEarthFundWallet_
    ) internal pure {
        //solhint-disable-next-line reason-string
        require(
            dotEarthTreasuryWallet_ != address(0),
            "DotEarthRoyalty: dotEarthTreasuryWallet_ address cannot be zero"
        );
        //solhint-disable-next-line reason-string
        require(
            dotEarthFundWallet_ != address(0),
            "DotEarthRoyalty: dotEarthFundWallet_ address cannot be zero"
        );
    }

    function _prevalidateRolaty(
        uint96 dotEarthTreasuryNumerator_,
        uint96 dotEarthFundNumerator_,
        address dotEarthTreasuryWallet_,
        address dotEarthFundWallet_
    ) internal pure {
        _prevalidateAddresses(dotEarthTreasuryWallet_, dotEarthFundWallet_);
        _prevalidateNumeratorAssigment(
            dotEarthTreasuryNumerator_,
            dotEarthFundNumerator_
        );
    }

    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    function sumOfNumerators() public view returns (uint96) {
        return dotEarthFundNumerator + dotEarthTreasuryNumerator;
    }

    function splitBalance() public {
        uint256 balance_ = balance();
        //solhint-disable-next-line reason-string
        require(balance_ > 0, "DotEarthRoyalty: Cannot withdraw 0 balance");

        uint256 forTreasury = (balance_ * dotEarthTreasuryNumerator) /
            feeDenominator();
        uint256 forFund = (balance_ * dotEarthFundNumerator) / feeDenominator();

        dotEarthTreasuryWallet.transfer(forTreasury);
        dotEarthFundWallet.transfer(forFund);
    }

    receive() external payable {
        emit Received(_msgSender(), msg.value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

contract ActionContext is Context {
    address internal _sender;

    event ActionEvent(string actionType, string actionId, bytes actionArgs, string[] actionArgTypes);

    struct ActionParams {
        string actionType;
        string actionId;
        bytes actionArgs;
        string[] actionArgTypes;
    }

    modifier keepOriginalSender() {
        _sender = msg.sender;
        _;
        _sender = address(0);
    }

    function _msgSender() internal view virtual override returns (address) {
        if (_sender != address(0)) {
            return _sender;
        }

        return msg.sender;
    }

    function _getRevertMsg(bytes memory _returnData)
    internal
    pure
    returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Tx reverted silently";
        // solhint-disable-next-line no-inline-assembly
        assembly {
        // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string));
        // All that remains is the revert string
    }

    function executeAction(bytes calldata call_, ActionParams calldata actionParams_) external keepOriginalSender returns(bytes memory){
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = address(this).call(call_);
        if (success) {
            emit ActionEvent(actionParams_.actionType, actionParams_.actionId, actionParams_.actionArgs, actionParams_.actionArgTypes);
            return returnData;
        }

        require(false, _getRevertMsg(returnData));
        return bytes(string(""));
    }
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