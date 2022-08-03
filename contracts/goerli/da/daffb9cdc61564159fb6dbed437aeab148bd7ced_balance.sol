/**
 *Submitted for verification at Etherscan.io on 2022-08-02
*/

pragma solidity ^0.6;
contract balance {
    function getBalance(address _user, address _localToken, address[] memory _tokens) public view returns(uint256[] memory info){
        uint256 _tokenCount = _tokens.length;
        info = new uint256[](_tokenCount);
        for(uint256 i = 0; i< _tokenCount; i++){
            uint256 token_amount = 0;
            if(_localToken == _tokens[i]){
                token_amount = address(_user).balance;
            }else{
                ( bool success, bytes memory data) = _tokens[i].staticcall(abi.encodeWithSelector(0x70a08231, _user));
                token_amount = 0;
                if(data.length != 0){
                    token_amount = abi.decode(data,(uint256));
                }
            }
            info[i] = uint256(token_amount);
        }
    }
}