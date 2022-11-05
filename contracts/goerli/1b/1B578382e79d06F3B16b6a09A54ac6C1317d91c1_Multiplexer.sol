/**
 *Submitted for verification at Etherscan.io on 2022-11-05
*/

// File: multi3.sol

pragma solidity ^0.4.16;

//erc20 和trc20 都一样
contract ERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) returns (bool ok);
}

contract Multiplexer {

    function sendTrx(address[] _to, uint256 _value)
        payable
        returns (bool _success)
    {
        for (uint8 i = 0; i < _to.length; i++) {
            _to[i].send(_value);
        }
        return true;
    }

    function sendTrxV2(address[] _to, uint256[] _value)
        payable
        returns (bool _success)
    {
        assert(_to.length == _value.length);
        assert(_to.length <= 255);
        uint256 beforeValue = msg.value;
        uint256 afterValue = 0;
        for (uint8 i = 0; i < _to.length; i++) {
            afterValue = afterValue + _value[i];
            _to[i].send(_value[i]);
        }
        uint256 remainingValue = beforeValue - afterValue;
        if (remainingValue > 0) {
            msg.sender.send(remainingValue);
        }
        return true;
    }

    function sendToken(
        address _tokenAddress,
        address[] _to,
        uint256 _value
    ) returns (bool _success) {
        assert(_to.length <= 255);
        ERC20 token = ERC20(_tokenAddress);
        for (uint256 i = 0; i < _to.length; i++) {
            assert(token.transferFrom(msg.sender, _to[i], _value) == true);
        }
        return true;
    }

    function sendTokenV2(
        address _tokenAddress,
        address[] _to,
        uint256[] _value
    ) returns (bool _success) {
        assert(_to.length == _value.length);
        assert(_to.length <= 255); //这里长度做了一个限制，由于不同链gaslimit有不同的上限，可酌情调整
        ERC20 token = ERC20(_tokenAddress);
        for (uint256 i = 0; i < _to.length; i++) {
            assert(token.transferFrom(msg.sender, _to[i], _value[i]) == true);
            //这里需要注意，transferFrom的转账需要，调用者在代币合约（_tokenAddress）里调用approve方法，
            //也就是需要给批量转账合约（当前合约）授权，不然当前合约无法调用transferFrom，很多新手都会忽视这一点。
        }
        return true;
    }
}