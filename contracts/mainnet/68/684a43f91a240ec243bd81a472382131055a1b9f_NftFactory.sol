/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * author: GCC
 * 
 * This contract is used to mint plenty of nfts via one tnx, saving more gas than most of other similar contracts.
 * 
 * Donating to this contract is welcomed.
 */

interface nft{
    function totalSupply() external view returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface erc20{
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract Minter{

    constructor(address destination, bytes memory data, uint256 amount, uint256 tokenId) payable {
        (bool success,) = payable(destination).call{value:msg.value}(data);
        require(success);
        for(uint i=0; i<amount; ){
            nft(destination).transferFrom(address(this), tx.origin, tokenId+i);
            unchecked{
                ++i;
            }
        }
        selfdestruct(payable(msg.sender));
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract MinterTo{

    constructor(address destination, bytes memory data) payable {
        (bool success,) = payable(destination).call{value:msg.value}(data);
        require(success);
        selfdestruct(payable(msg.sender));
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract NftFactory{

    address private _owner;

    constructor(){
        _owner = msg.sender;
    }

    function Owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _owner = newOwner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }

    /**
     * @param destination: mint contract
     * @param data: mint transaction payload
     * @param times: mint times
     * @param amount: mint amount per times (match data)
     */
    function mint(address destination, bytes calldata data, uint256 times, uint256 amount) external payable{
        uint256 _value = msg.value/times;
        uint256 tokenId = nft(destination).totalSupply();
        for(uint i=0; i<times; ){
            new Minter{value:_value}(destination, data, amount, tokenId);
            unchecked{
                ++i;
                tokenId += amount;
            }
        }
    }

    /**
     * @param destination: mint contract
     * @param data: mint transaction payload
     * @param times: mint times
     */
    function mintTo(address destination, bytes calldata data, uint256 times) external payable{
        uint256 _value = msg.value/times;
        for(uint i=0; i<times; ){
            new MinterTo{value:_value}(destination, data);
            unchecked{
                ++i;
            }
        }
    }

    receive() payable external {}

    function withdrawETH() public {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _withdrawERC20(address erc20address) private onlyOwner {
        uint256 balance = erc20(erc20address).balanceOf(address(this));
        erc20(erc20address).transfer(address(msg.sender), balance);
    }

    function withdrawERC20(address[] calldata erc20addresses) public onlyOwner {
        for(uint i=0; i<erc20addresses.length; ){
            _withdrawERC20(erc20addresses[i]);
            unchecked{
                ++i;
            }
        }
    }

    function _withdrawERC721(address erc721address, uint256 tokenId) private onlyOwner {
        nft(erc721address).transferFrom(address(this), address(tx.origin), tokenId);
    }
    
    function withdrawERC721(address[] calldata erc721addresses, uint256[] calldata tokenIds) public onlyOwner{
        for(uint i=0; i<erc721addresses.length; ){
            _withdrawERC721(erc721addresses[i], tokenIds[i]);
            unchecked{
                ++i;
            }
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}