// SPDX-License-Identifier: MIT

//$YOLK is NOT an investment and has NO economic value. 
//It will be earned by active holding within the Hatchlingz ecosystem. 


pragma solidity ^0.8.0;

// import "./ERC20.sol";
import "./Ownable.sol";
// import "./Context.sol";


interface IHatchlingz {
    function _walletBalanceOfLegendary(address owner) external view returns (uint256);
    function _walletBalanceOfRare(address owner) external view returns (uint256);
    function _walletBalanceOfCommon(address owner) external view returns (uint256);
    function _walletBalanceOfEggs(address owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IYolk {
    function transfer(address recipient, uint256 amount) external;
    function balanceOf(address account) external returns (uint256);
  
}

contract YolkAirdrop1 is Ownable {

    IHatchlingz public Hatchlingz;
    IYolk public Yolk;

    uint256 airdropAmount = 100 ether;

    mapping(address => bool) private receivedAirdrop;
  
    constructor(address HatchlingzAddress, address YolkAddress)  {
        Hatchlingz = IHatchlingz(HatchlingzAddress);
        Yolk = IYolk(YolkAddress);
    }
 

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        // Yolk.balanceOf(address(this));
        Yolk.transfer(msg.sender, Yolk.balanceOf(address(this)));
            }

    function YolkAirdropForMint() external onlyOwner {

        for(uint i=1 ; i <= Hatchlingz.totalSupply() ; i++){
            if( receivedAirdrop[Hatchlingz.ownerOf(i)] == false){
                Yolk.transfer(Hatchlingz.ownerOf(i), airdropAmount);
                receivedAirdrop[Hatchlingz.ownerOf(i)] = true;
            }

        }

    }
    function setYolk(address yolkAddress) external onlyOwner {
        Yolk = IYolk(yolkAddress);
    }
    
    function setHatchlingz(address hatchlingzAddress) external onlyOwner {
        Hatchlingz = IHatchlingz(hatchlingzAddress);
    }


 
}