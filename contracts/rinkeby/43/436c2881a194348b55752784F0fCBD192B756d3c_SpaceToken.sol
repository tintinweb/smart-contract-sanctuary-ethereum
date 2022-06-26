pragma solidity ^0.8.0;

import "./ERC777.sol";
import "./SpaceMarketplace.sol";
import "./Ownable.sol";
contract SpaceToken is ERC777, Ownable {
    SpaceMarketplace private marketplace;
    constructor(uint256 initialSupply, address[] memory defaultOperators)
    ERC777("SpaceToken", "Space", defaultOperators)
    {
        uint256 supply=(initialSupply*5)*(10 ** 16);
        _mint(defaultOperators[0],supply, "", "");
        _mint(msg.sender, initialSupply*(10 ** 18)-supply, "", "");
    }
    function setMarketplace(SpaceMarketplace market) public onlyOwner{
        marketplace = market;

    }
    modifier checkNum(uint256 num){
        require(balanceOf(msg.sender) > num, "SpaceToken quantity not sufficient!");
        _;
    }
    function putAwayOrder(uint256 _num)
    checkNum(_num)
    external
    returns (uint256){
        transfer( address(marketplace), _num*(10 ** 18));
        uint256 newItemId = marketplace.putTokenForSale(_num,msg.sender);
        return newItemId;
    }

}