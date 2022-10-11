/**
 *Submitted for verification at Etherscan.io on 2022-10-10
*/

library MTMStrings {
    function onlyAllowedCharacters(string memory string_) public pure returns (bool) {
        bytes memory _strBytes = bytes(string_);
        for (uint i = 0; i < _strBytes.length; i++) {
            if (_strBytes[i] < 0x20 || _strBytes[i] > 0x7A || _strBytes[i] == 0x26 || _strBytes[i] == 0x22 || _strBytes[i] == 0x3C || _strBytes[i] == 0x3E) {
                return false;
            }     
        }
        return true;
    }
}