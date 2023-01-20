/**
 *Submitted for verification at Etherscan.io on 2023-01-20
*/

pragma solidity ^0.8.0;

interface IERC721  {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract NFTTAX {

    uint private Fee;
    //uint private price;
    address private owner;
    address private jpyc;


    constructor() public {
        Fee = 0.003 ether;//3000000000000000
        
        owner = 0xf7096e32F2DA13A26C03419d068267e402871cA9;//goerli
        jpyc = 0x3E094b0B2cC32078eb8C16B30cacf08B88CD235B;//goerli
    }

    function nftpurchase(address nftcollection,uint nftid) public payable{
        IERC20 ierc20 = IERC20(jpyc);
        require(ierc20.balanceOf(address(this))!=0);
        
        IERC721 ierc721 = IERC721(nftcollection);
        require(ierc721.getApproved(nftid)==address(this));//nft操作権利がこちらに承認されてるとチェック

        require(msg.value == Fee);//料金請求
        ierc721.transferFrom(msg.sender, address(this), nftid);

        
        ierc20.transfer(msg.sender,1);

        //address payable guest = address(msg.sender);
        //from.transfer(price);


    }

    function withdraw(address payable to) external {

        require(owner == msg.sender);
        //address payable me = msg.sender;
        to.transfer(address(this).balance);
    }

    function changeowner(address next) external{
        require(owner == msg.sender);
        owner = next;
    }

    function changefee(uint f) external{
        require(owner == msg.sender);
        Fee = f;
        
    }

    function change_jpyc_address(address j) external{
        require(owner == msg.sender);
        jpyc = j;
    }


}