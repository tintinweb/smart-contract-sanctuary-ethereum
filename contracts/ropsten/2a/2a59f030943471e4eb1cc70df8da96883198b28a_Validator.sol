/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

contract Validator {
    address public contractToAttack;

    function validate(address _first, address _second) public {
        __validateSetters(_first);
        __validateVariables(_first);

        __validateSetters(_second);
        __validateVariables(_second);

        __validateFirst(_first, _second);
        __validateSecond(_second);
    }

    function validateAttacker(address _first, address _second, address _attacker) external {
        validate(_first, _second);

        _attacker.call{value: 0.0001 ether}(abi.encodeWithSignature("increaseBalance()"));

        uint256 _contractBalance = _second.balance;
        require(_contractBalance > 0.0001 ether, "Invalid contract balance");
        require(__getBalanceOnSecondContract(_second, _attacker) == 0.0001 ether, "balance() invalid, after increaseBalance()");

        contractToAttack = _second;

        (bool _callStatus, bytes memory _data) = _second.call(abi.encodeWithSignature("withdrawSafe(address)", address(this)));
        require(!_callStatus, "withdrawSafe() is not safe");

        uint256 _attackerBalanceBefore = _attacker.balance;
        _attacker.call(abi.encodeWithSignature("attack()"));
        require(_second.balance == 0, "`Second` contract balance is not a zero after attack");
        require(_attackerBalanceBefore + _contractBalance == _attacker.balance, "`Attacker` contract balance is invalid after attack");
        require(__getBalanceOnSecondContract(_second, _attacker) == 0, "balance() invalid, after attack()");
    }

    function __validateFirst(address _first, address _second) private {
        (bool _callStatus, bytes memory _data) = _first.call(abi.encodeWithSignature("sum()"));
        require(_callStatus, "sum() is failed");
        require(abi.decode(_data, (uint256)) == block.timestamp * 3 + 3, "sum() is invalid (1)");

        (_callStatus, _data) = _first.call(abi.encodeWithSignature("sumFromSecond(address)", _second));
        require(_callStatus, "sumFromSecond() is failed");
        require(abi.decode(_data, (uint256)) == block.timestamp * 2 + 2, "sumFromSecond() is invalid");

        // START callExternalReceive()
        (_callStatus,) = _first.call{value: 0.0005 ether}(abi.encodeWithSignature("callExternalReceive(address)", _second));
        require(!_callStatus, "callExternalReceive() is failed (1)");

        uint256 _contractBalanceBefore = _second.balance;
        uint256 _txOriginBalanceBefore = __getBalanceOnSecondContract(_second, msg.sender);

        (_callStatus,) = _first.call{value: 0.0001 ether}(abi.encodeWithSignature("callExternalReceive(address)", _second));
        require(_callStatus, "callExternalReceive() is failed (2)");
        require((_second.balance - _contractBalanceBefore) == 0.0001 ether, "callExternalReceive() invalid result balance");
        require(__getBalanceOnSecondContract(_second, msg.sender) - _txOriginBalanceBefore == 0.0001 ether, "balance() invalid, after callExternalReceive() call");
        // END

        // START callExternalFallback()
        (_callStatus,) = _first.call{value: 0.0005 ether}(abi.encodeWithSignature("callExternalFallback(address)", _second));
        require(!_callStatus, "callExternalFallback() is failed (1)");

        _contractBalanceBefore = _second.balance;
        uint256 _msgSenderBalanceBefore = __getBalanceOnSecondContract(_second, _first);

        (_callStatus,) = _first.call{value: 0.0002 ether}(abi.encodeWithSignature("callExternalFallback(address)", _second));
        require(_callStatus, "callExternalFallback() is failed (2)");
        require((_second.balance - _contractBalanceBefore) == 0.0002 ether, "callExternalFallback() invalid result balance");
        require(__getBalanceOnSecondContract(_second, _first) - _msgSenderBalanceBefore == 0.0002 ether, "balance() invalid, after callExternalReceive() call");
        // END

        (_callStatus, _data) = _first.call(abi.encodeWithSignature("getSelector()"));
        require(_callStatus, "getSelector() is failed");
        require((abi.decode(_data, (bytes))).length == 36, "getSelector() invalid result value");
    }

    function __validateSecond(address _second) private {
        (bool _callStatus, bytes memory _data) = _second.call(abi.encodeWithSignature("sum()"));
        require(_callStatus, "sum() is failed");
        require(abi.decode(_data, (uint256)) == block.timestamp * 2 + 2, "sum() is invalid (2)");
    }

    function __validateSetters(address _contract) private {
        bool _callStatus;

        (_callStatus,) = _contract.call(abi.encodeWithSignature("setPublic(uint256)", block.timestamp));
        require(_callStatus, "setPublic() is failed");

        (_callStatus,) = _contract.call(abi.encodeWithSignature("setPrivate(uint256)", block.timestamp + 1));
        require(_callStatus, "setPrivate() is failed");

        (_callStatus,) = _contract.call(abi.encodeWithSignature("setInternal(uint256)", block.timestamp + 2));
        require(_callStatus, "setInternal() is failed");
    }

    function __validateVariables(address _contract) private {
        (bool _callStatus, bytes memory _data) = _contract.call(abi.encodeWithSignature("ePublic()"));
        require(_callStatus, "ePublic() is failed");
        require(abi.decode(_data, (uint256)) == block.timestamp, "ePublic() is invalid");

        (_callStatus, _data) = _contract.call(abi.encodeWithSignature("ePrivate()"));
        require(_data.length == 0, "ePrivate - invalid visibility");

        (_callStatus, _data) = _contract.call(abi.encodeWithSignature("eInternal()"));
        require(_data.length == 0, "eInternal - invalid visibility");
    }

    function __getBalanceOnSecondContract(address _second, address _holder) private returns (uint256) {
        (bool _callStatus, bytes memory _data) = _second.call(abi.encodeWithSignature("balance(address)", _holder));
        require(_callStatus, "balance() is failed");

        return abi.decode(_data, (uint256));
    }

    receive() external payable {
        contractToAttack.call(abi.encodeWithSignature("withdrawSafe(address)", address(this)));
    }
}