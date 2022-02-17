pragma solidity 0.8.9;

contract Adapter {

    function getValue(address _token, bytes4 _functionSig, uint256 _coeff, address[] calldata _blacklist, address _account) external view returns(uint256) {
        
        for(uint256 i = 0; i < _blacklist.length; i ++) {
            if(_account == _blacklist[i]) {
                return 0;
            }
        }
        
        (bool success, bytes memory result) = _token.staticcall(abi.encodeWithSelector(_functionSig, _account));
        if(!success) {
            return 0;
        }
        
        uint256 uintResult = abi.decode(result, (uint256));
        return uintResult * _coeff / 1e18;
    }

}