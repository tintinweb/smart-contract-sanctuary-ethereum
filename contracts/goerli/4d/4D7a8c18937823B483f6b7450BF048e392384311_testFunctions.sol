contract testFunctions {
    mapping (address=>uint256) map;

    function test(address _address, uint256 _num) external{
        map[_address] = _num;
    }
}