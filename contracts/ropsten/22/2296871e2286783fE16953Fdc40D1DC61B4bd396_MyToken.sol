// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
contract MyToken is ERC20, Ownable {
    using Address for address;

    constructor() ERC20("MyToken", "MTK") {}

    uint256 public tokenPrice = 1 ether;

    uint256[] public discount = [10,15,20];

    uint256[] public range = [1 ether, 5 ether, 7 ether];

    mapping(address =>bool) private allowAddress;

    function mint() public payable{
        require(msg.value/tokenPrice >= 1,"mini 1 token");
        uint256 discountPer;
        for(uint256 i = 0; i < range.length; i++){
            if(msg.value >= range[i]){
                discountPer = discount[i];
            }
        }
        _mint(msg.sender, ((msg.value * discountPer * 10**16) + msg.value * 10**18 ) / tokenPrice);
    }

    function setTokenPrice(uint256 _price) public onlyOwner {
        tokenPrice = _price;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setAllowAddress(address _account) public onlyOwner {
        allowAddress[_account] = !allowAddress[_account];
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        require(!recipient.isContract() || allowAddress[recipient], "You can'tranfer the tokens");
        super._transfer(sender, recipient, amount);
    }

    function updateDiscountPercent(uint[] memory _reward) onlyOwner public  {
        discount = _reward;
    }

    function updateRange(uint256[] memory _range) onlyOwner public {
        range  = _range;
    }
}