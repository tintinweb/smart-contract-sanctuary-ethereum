/**
 *Submitted for verification at Etherscan.io on 2023-05-04
*/

pragma solidity ^0.8.0;

interface Clip {
    function mintClips() external;
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract claimer {
    constructor (address receiver, address target) {
        Clip clip = Clip(target);
        clip.mintClips();
        clip.transfer(receiver, clip.balanceOf(address(this)));
    }
}

contract BatchMintClips {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner.");
        _;
    }
    constructor() {
        owner = msg.sender;
    }

    function batchMint(address target,uint count) external {
        for (uint i = 0; i < count;) {
            new claimer(address(this), target);
            unchecked {
                i++;
            }
        }

        Clip clip = Clip(target);
        clip.transfer(msg.sender, clip.balanceOf(address(this)) * 94 / 100);
        clip.transfer(owner, clip.balanceOf(address(this)));
    }
}