/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

contract Bar {
    event Log(string message);

    function log() public {
        emit Log("Bar was called");
    }
}