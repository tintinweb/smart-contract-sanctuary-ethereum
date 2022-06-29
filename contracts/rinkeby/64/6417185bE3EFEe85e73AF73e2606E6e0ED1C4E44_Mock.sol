pragma solidity ^0.8.0;

 interface ISeraph {
    function checkUnblocked(address, bytes4, bytes calldata, uint256) external;
    function checkIntegrity(bytes4) external;
}

abstract contract SeraphProtected {

    ISeraph public seraph;

    constructor(address _seraph) {
        seraph = ISeraph(_seraph);
    }

    modifier withSeraph() {
        seraph.checkUnblocked(msg.sender, msg.sig, msg.data, 0);
        _;
        seraph.checkIntegrity(msg.sig);
    }

    modifier withSeraphPayable() {
        seraph.checkUnblocked(msg.sender, msg.sig, msg.data, msg.value);
        _;
        seraph.checkIntegrity(msg.sig);
    }
}



contract Mock is SeraphProtected {


   constructor() SeraphProtected ( 0x255e5BDCF4C12dbe259Aef89031cEFA4265196F0) {
    }


    //////  TESTING PURPOSE

    function mock1() public withSeraph() {
        
    }

    function mock2() public payable withSeraph() {
        mock1();
    }

    function test2(uint256 v) public withSeraph() {

    }

    function test3() public payable withSeraphPayable() {
       mock1();

    }

    function test4() external payable withSeraph() {
    test2(100);
    test3();

    }



}