/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

interface IFactory {
    function g (uint count) external;
    function d (uint count) external;
}

contract Factory is IFactory {
    address[] c;
    uint i = 0;
    uint di = 0;

    function g (uint count) external override {
        for (uint ind = i; ind< i+count; ind++) {
            address newContract = address(new Contract());
            c.push(newContract);
        }
        i = i + count;
    }

    function d (uint count) external override {
        for (uint ind = di; ind< di+count; ind++) {
            Contract(c[ind]).d();
        }
        di = di + count;
    }
}

contract Contract {
    function d() public {
        selfdestruct(msg.sender);
    }
}