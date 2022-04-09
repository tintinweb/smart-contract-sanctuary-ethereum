/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract introAndsmile{
    /* Yes, hello, average Jane here.

    In 2014, I went to the University of Illinois.
    For a Bachelor's in Electrical Engineering + Atmospheric Sciences.
    This led to the fondest of times at the Arecibo Observatory - brainchild of Carl Sagan.
    Where I used lidar and radar systems to look at electrons and Sodium in the sky.
    Prior to it getting demolished in 2019 #thxNSF.

    After graduation, I moved to Silicon Valley.
    Here, I worked on NFC in the Pixel 5 [Android Pay]
    + Bluetooth in the pixel buds for the next 3 years.
    However, my favorite thing ever, 
    was the ABC.XYZ "moonshot" bal-LOON [prior to its shutdown in 2020].
    Where I conducted experiments with a radar facility in Peru!
    to provide internet to remote and disaster stricken areas.

    Why do all good things come to an end ?

    Unfortunately or.. fortunately, in 2021 I was forced to leave the US 
    owing to US work visa lottery #thxP(X_h1b)=0.15.
    Current job: Compute at global scale [w Warszawie, Polska].
    Nodes, RPCs, automated billing in Fiat.
    
    Here we are. Here we are, it is April 2022.
    */
    address payable private owner;
    uint256 basePrice = 1000 gwei;

    event helloIam(
        string intro,
        address introTo,
        address introFrom,
        bool introducedMeSelf
    );
    
    event Ismiled (
        string smile,
        address smileTo,
        address smileFrom,
        bool smiled
    );

    constructor() {
        owner = payable(msg.sender);
    }

    function smile() public payable{
        require(msg.value >= basePrice, "Please pay at least the base price");
        basePrice += 100 gwei;
        payable(owner).transfer(msg.value);
        emit Ismiled(
            ':)',
            msg.sender,
            address(this),
            true
        );
    }

    function freebie() public {
        emit Ismiled(
            'Oh hi Mark --E --E',
            msg.sender,
            address(this),
            false
        );
    }

    function withdraw () public {
        require(msg.sender == owner);
        payable(msg.sender).transfer(address(this).balance);
    }

    function currentPrice() public view returns (uint256){
        return basePrice;
    }
}