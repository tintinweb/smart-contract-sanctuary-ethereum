// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ECDSA.sol";
import "./Ownable.sol";

contract MultiSender is Ownable {
    // signer
    address public signer = 0xb3A2e75492a693EA119aE892690d508131caBb10;

    // change signer
    function setSigner(address _newSigner) public onlyOwner {
        signer = _newSigner;
    }

    // check signature
    function isSigValid(
        uint64 _ts, /* seconds */
        bytes memory _signature
    ) private view returns (bool) {
        require(block.timestamp <= _ts + 3600, "signature expired");
        bytes32 signedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n8", _ts)
        );
        return ECDSA.recover(signedHash, _signature) == signer;
    }

    // send coin, with different amount for each account
    function multiSendCoinDiffAmount(
        address _tokenAddress,
        address[] memory _addrList,
        uint256[] memory _amountList,
        uint64 _ts, /* seconds */
        bytes memory _signature
    ) external {
        require(isSigValid(_ts, _signature), "signature invalid");
        require(_addrList.length == _amountList.length, "length mismatch");

        Token token = Token(_tokenAddress);
        for (uint32 i = 0; i < _addrList.length; i++) {
            require(
                token.transferFrom(msg.sender, _addrList[i], _amountList[i]),
                "transfer failed"
            );
        }
    }

    // send coin, with same amount for each account
    function multiSendCoinSameAmount(
        address _tokenAddress,
        address[] memory _addrList,
        uint256 _amount,
        uint64 _ts, /* seconds */
        bytes memory _signature
    ) external {
        require(isSigValid(_ts, _signature), "signature invalid");
        require(_amount > 0, "_amount invalid");

        Token token = Token(_tokenAddress);
        for (uint32 i = 0; i < _addrList.length; i++) {
            require(
                token.transferFrom(msg.sender, _addrList[i], _amount),
                "transfer failed"
            );
        }
    }

    // send native coin, with different amount for each account
    function multiSendNativeCoinDiffAmount(
        address[] memory _addrList,
        uint256[] memory _amountList,
        uint64 _ts, /* seconds */
        bytes memory _signature
    ) external payable {
        require(isSigValid(_ts, _signature), "signature invalid");
        require(_addrList.length == _amountList.length, "length mismatch");

        // check total value
        uint256 totalAmount = 0;
        for (uint32 i = 0; i < _amountList.length; i++) {
            totalAmount += _amountList[i];
        }
        require(msg.value == totalAmount, "value invalid");

        for (uint32 i = 0; i < _addrList.length; i++) {
            payable(_addrList[i]).transfer(_amountList[i]);
        }
    }

    // send native coin, with same amount for each account
    function multiSendNativeCoinSameAmount(
        address[] memory _addrList,
        uint256 _amount,
        uint64 _ts,
        bytes memory _signature
    ) external payable {
        require(isSigValid(_ts, _signature), "signature invalid");
        require(_amount > 0, "_amount invalid");

        // check total value
        uint256 totalAmount = _amount * _addrList.length;
        require(msg.value == totalAmount, "value invalid");

        for (uint32 i = 0; i < _addrList.length; i++) {
            payable(_addrList[i]).transfer(_amount);
        }
    }
}

interface Token {
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);
}