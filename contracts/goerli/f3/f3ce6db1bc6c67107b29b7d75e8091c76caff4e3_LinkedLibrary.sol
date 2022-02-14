/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

struct Data {
    uint origin;
}

library LinkedLibrary {
    uint constant OFFSET = 10;

    function addOffset(uint _origin) public pure returns (uint) {
        return _origin + OFFSET;
    }

    function addOffset(Data storage _data) public view returns (uint) {
        return _data.origin + OFFSET;
    }

    function subOffset(Data memory _data) public pure returns (uint) {
        return _data.origin - OFFSET;
    }

    function regulateWithOffset(Data storage _data) public {
        _data.origin += OFFSET;
    }
}