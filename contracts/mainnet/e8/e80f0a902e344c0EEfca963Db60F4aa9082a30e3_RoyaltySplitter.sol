pragma solidity ^0.8.6;

contract RoyaltySplitter {

    mapping (address=>uint256) share;

    constructor () {
        share[0x1A0cAAb1AdDdbB12dd61B7f7873c69C18f80AACf] = 10;
        share[0x0515c23D04B3C078e40363B9b3142303004F343c] = 10;
        share[0x19F32B6D6912023c47BC0DF991d80CAAB52620a3] = 10;
        share[0xFC56e522504348833BCE63a6c15101d28E9BC1c2] = 10;
        share[0xbEB82e72F032631E6B3FF0b5Fa04aceA1D6bC0eb] = 60;
    }


    receive() external payable {}
    fallback() external payable {}

    function withdrawEth() public {
        uint256 total = address(this).balance;
        uint256 amt1 = total*share[0x1A0cAAb1AdDdbB12dd61B7f7873c69C18f80AACf]/100;
        uint256 amt3 = total*share[0x0515c23D04B3C078e40363B9b3142303004F343c]/100;
        uint256 amt4 = total*share[0x19F32B6D6912023c47BC0DF991d80CAAB52620a3]/100;
        uint256 amt5 = total*share[0xFC56e522504348833BCE63a6c15101d28E9BC1c2]/100;
        uint256 amt6 = total*share[0xbEB82e72F032631E6B3FF0b5Fa04aceA1D6bC0eb]/100;

        require(payable(0x1A0cAAb1AdDdbB12dd61B7f7873c69C18f80AACf).send(amt1));
        require(payable(0x0515c23D04B3C078e40363B9b3142303004F343c).send(amt3));
        require(payable(0x19F32B6D6912023c47BC0DF991d80CAAB52620a3).send(amt4));
        require(payable(0xFC56e522504348833BCE63a6c15101d28E9BC1c2).send(amt5));
        require(payable(0xbEB82e72F032631E6B3FF0b5Fa04aceA1D6bC0eb).send(amt6));
    }


}