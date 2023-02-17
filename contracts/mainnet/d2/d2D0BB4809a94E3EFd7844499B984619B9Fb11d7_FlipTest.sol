/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17;

contract FlipTest {

    bool public paused = true;

    function setPaused() external {
        paused = !paused;
    }

    function mintThunder() external {
        require(!paused, "Contract is paused!");
    }

    function mintGrabber() external {
        require(!paused, "Contract is paused!");
    }

    function mintMetaSniper() external {
        require(!paused, "Contract is paused!");
    }

    function mintSensei() external {
        require(!paused, "Contract is paused!");
    }

    function mintWaifu() external {
        require(!paused, "Contract is paused!");
    }

    function mintAstra() external {
        require(!paused, "Contract is paused!");
    }

    function mintTimith() external {
        require(!paused, "Contract is paused!");
    }

    function mintMintech() external {
        require(!paused, "Contract is paused!");
    }

    function mintBreeze() external {
        require(!paused, "Contract is paused!");
    }

}