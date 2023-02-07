/**
 *Submitted for verification at Etherscan.io on 2023-02-07
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;


abstract contract Context {

    function _msgSender() internal view virtual returns (address)
    {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata)
    {
        return msg.data;
    }

}


abstract contract Ownable is Context {

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()
    {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner()
    {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address)
    {
        return _owner;
    }

    function _checkOwner() internal view virtual 
    {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function transferOwnership(address newOwner) public virtual onlyOwner
    {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual
    {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

}


interface IERC20 
{

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

}


contract SampleAirdrop is Ownable {

    function airdrop(IERC20 _token, address[] calldata _to, uint256[] calldata _value) public payable
    {       
        uint256 length = _to.length;
        
        require(msg.value >= 0.005 ether);
        require(length == _value.length, "Receivers and amounts are different length");

        uint256 totalValue = 0;

        for (uint256 i = 0; i < length; ++i)
        {
            totalValue += _value[i];
        }
        
        require(_token.transferFrom(msg.sender, address(this), totalValue));

        for (uint256 i = 0; i < length; ++i)
        {
            require(_token.transfer(_to[i], _value[i]));
        }
    }


    function withdraw() public onlyOwner
    {
        payable(msg.sender).transfer(address(this).balance);
    }
}