/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

contract ValidatorV2 {
    address public contractToAttack;
    bool public validatorAttack = true;

    function sendEth() external payable {
        address(this).call{value: msg.value}("");
    }

    function validate(address _first, address _second) public {
        require(address(this).balance > 0.01 ether, "`Validator` balance to low");

        __validateSetters(_first);
        __validateVariables(_first);

        __validateSetters(_second);
        __validateVariables(_second);

        __validateFirst(_first, _second);
        __validateSecond(_second);
    }

    function validateWithAttacker(address _first, address _second, address _attacker) external {
        validate(_first, _second);

        contractToAttack = _second;

        // START check withdrawSafe()
        // Send ETH to Second contract as Validator.
        _second.call{value: 0.0001 ether}(abi.encodeWithSignature("a()"));
        // Second should have 0.0003 ETH + 0.0001 ETH

        uint256 _validatorBalanceOnSecondContractBefore = __getBalanceOnSecondContract(_second, address(this));
        uint256 _secondBalanceBefore = _second.balance;
        require(_validatorBalanceOnSecondContractBefore == 0.0001 ether, "Invalid Validator balance after Second fallback");
        require(_secondBalanceBefore >= 0.0004 ether, "Invalid Second contract balance");

        (bool _status,) = _second.call(abi.encodeWithSignature("withdrawSafe(address)", address(this)));
        if (!_status) {
            validatorAttack = false;
            (_status,) = _second.call(abi.encodeWithSignature("withdrawSafe(address)", address(this)));
            require(_status, "withdrawSafe() failed");
            validatorAttack = false;
        }

        require(__getBalanceOnSecondContract(_second, address(this)) == 0,
            "Invalid `Validator` balance after withdrawSafe(address) call");
        require(_secondBalanceBefore - _second.balance == _validatorBalanceOnSecondContractBefore,
            "Invalid `Second` balance after withdrawSafe(address) call");
        // END

        // START check withdrawUnsafe()
        _attacker.call{value: 0.0001 ether}(abi.encodeWithSignature("increaseBalance()"));

        uint256 _attackerBalanceOnSecondContractBefore = __getBalanceOnSecondContract(_second, _attacker);
        uint256 _attackerBalanceBefore = _attacker.balance;
        _secondBalanceBefore = _second.balance;
        require(_attackerBalanceOnSecondContractBefore == 0.0001 ether, "Invalid `Attacker` balance after increaseBalance()");

        _attacker.call(abi.encodeWithSignature("attack()"));

        require(_second.balance == 0, "`Second` contract balance is not a zero after attack()");
        require(_attackerBalanceBefore + _secondBalanceBefore == _attacker.balance, "`Attacker` contract balance is invalid after attack()");
        require(__getBalanceOnSecondContract(_second, _attacker) == 0, "Invalid `Attacker` balance after attack()");
        // END
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

        uint256 _secondBalanceBefore = _second.balance;
        uint256 _txOriginBalanceBefore = __getBalanceOnSecondContract(_second, msg.sender);

        (_callStatus,) = _first.call{value: 0.0001 ether}(abi.encodeWithSignature("callExternalReceive(address)", _second));
        require(_callStatus, "callExternalReceive() is failed (2)");
        require((_second.balance - _secondBalanceBefore) == 0.0001 ether, "callExternalReceive() invalid result balance");
        require(__getBalanceOnSecondContract(_second, msg.sender) - _txOriginBalanceBefore == 0.0001 ether, "balance() invalid, after callExternalReceive() call");
        // END

        // START callExternalFallback()
        (_callStatus,) = _first.call{value: 0.0005 ether}(abi.encodeWithSignature("callExternalFallback(address)", _second));
        require(!_callStatus, "callExternalFallback() is failed (1)");

        _secondBalanceBefore = _second.balance;
        uint256 _msgSenderBalanceBefore = __getBalanceOnSecondContract(_second, _first);

        (_callStatus,) = _first.call{value: 0.0002 ether}(abi.encodeWithSignature("callExternalFallback(address)", _second));
        require(_callStatus, "callExternalFallback() is failed (2)");
        require((_second.balance - _secondBalanceBefore) == 0.0002 ether, "callExternalFallback() invalid result balance");
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
        if (validatorAttack) contractToAttack.call(abi.encodeWithSignature("withdrawSafe(address)", address(this)));
    }
}