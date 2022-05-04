/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

contract TstLispDeploy2 {
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory symbol, uint8 decimals) public { //
        _symbol = symbol;
        _decimals = decimals;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }
    function decimals() external view returns (uint8) {
        return _decimals;
    }
 }